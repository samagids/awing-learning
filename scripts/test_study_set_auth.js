// scripts/test_study_set_auth.js
//
// Offline unit tests for requireStudySetAuth() in
// scripts/clasp_contributions/Code.js — the gate that decides whether a
// caller may upload or delete study-set audio and images.
//
// Written in Session 64 (v1.23.3) alongside the fix that taught that
// gate to accept Firebase ID tokens, so Sign in with Apple teachers stop
// silently failing every upload.
//
// WHY THIS FILE EXISTS: the Apple bug shipped because a provider was
// added in one place and the code that gates on identity was never
// re-checked. Apps Script cannot be unit-tested in place, so this file
// extracts the auth functions into a Node sandbox with stubbed
// UrlFetchApp / Logger / SCRIPT_PROPS and asserts the full matrix —
// including the negative cases that matter more than the positive ones.
//
//   RUN:  node scripts/test_study_set_auth.js
//   Exit 0 = all pass. Run it before every `clasp push`.
//
// It reads Code.js (the file clasp actually deploys). Session 49b rule:
// contributions_webapp.gs must stay byte-identical to it —
//   diff -q scripts/contributions_webapp.gs scripts/clasp_contributions/Code.js

const fs = require('fs');
const path = require('path');
const CODE_JS = path.join(__dirname, 'clasp_contributions', 'Code.js');
const src = fs.readFileSync(CODE_JS, 'utf8');

// Extract just the three auth functions into an isolated sandbox.
function grab(name) {
  const i = src.indexOf('function ' + name + '(');
  if (i < 0) throw new Error('missing ' + name);
  let d = 0, j = src.indexOf('{', i);
  for (let k = j; k < src.length; k++) {
    if (src[k] === '{') d++;
    else if (src[k] === '}') { d--; if (d === 0) return src.slice(i, k + 1); }
  }
  throw new Error('unbalanced ' + name);
}
const code = [grab('verifyGoogleIdToken_'), grab('verifyFirebaseIdToken_'),
              grab('requireStudySetAuth'), grab('requireDevAuth')].join('\n\n');

let SCENARIO = {};
const logs = [];
const sandbox = {
  Logger: { log: m => logs.push(m) },
  SCRIPT_PROPS: { getProperty: k => SCENARIO.props?.[k] ?? null },
  UrlFetchApp: {
    fetch: (url, opts) => {
      if (url.includes('oauth2.googleapis.com/tokeninfo')) {
        const r = SCENARIO.google ?? { code: 400, body: {} };
        return { getResponseCode: () => r.code,
                 getContentText: () => JSON.stringify(r.body) };
      }
      if (url.includes('identitytoolkit.googleapis.com')) {
        if (!url.includes('key=')) throw new Error('no api key in url');
        const r = SCENARIO.firebase ?? { code: 400, body: {} };
        return { getResponseCode: () => r.code,
                 getContentText: () => JSON.stringify(r.body) };
      }
      throw new Error('unexpected fetch: ' + url);
    }
  }
};
const DEVELOPER_EMAIL = 'samagids@gmail.com';
const fn = new Function('Logger','SCRIPT_PROPS','UrlFetchApp','DEVELOPER_EMAIL',
  code + '\nreturn { requireStudySetAuth: requireStudySetAuth, requireDevAuth: requireDevAuth };');
const api = fn(sandbox.Logger, sandbox.SCRIPT_PROPS, sandbox.UrlFetchApp, DEVELOPER_EMAIL);
const requireStudySetAuth = api.requireStudySetAuth;
const requireDevAuth = api.requireDevAuth;

const APIKEY = { FIREBASE_API_KEY: 'AIzaFAKE' };
const gOK  = { code: 200, body: { email: 'Teacher@Example.com', email_verified: 'true' } };
const fbUser = (over = {}) => ({ code: 200, body: { users: [Object.assign({
  email: 'teacher@example.com', disabled: false,
  providerUserInfo: [{ providerId: 'apple.com' }] }, over)] } });

const cases = [
  // --- regression: Google path must behave exactly as before ---
  ['Google token, matching email',            {props:APIKEY, google:gOK},
   {idToken:'g', teacherEmail:'teacher@example.com'}, true],
  ['Google token, case-insensitive match',    {props:APIKEY, google:gOK},
   {idToken:'g', teacherEmail:'TEACHER@EXAMPLE.COM'}, true],
  ['Google token, WRONG email',               {props:APIKEY, google:gOK},
   {idToken:'g', teacherEmail:'someone@else.com'}, false],
  ['Google token, email_verified=false',      {props:APIKEY,
    google:{code:200, body:{email:'teacher@example.com', email_verified:'false'}}},
   {idToken:'g', teacherEmail:'teacher@example.com'}, false],
  ['Google token, tokeninfo 400',             {props:APIKEY, google:{code:400,body:{}}},
   {idToken:'g', teacherEmail:'teacher@example.com'}, false],
  ['Google path works with NO api key set',   {props:{}, google:gOK},
   {idToken:'g', teacherEmail:'teacher@example.com'}, true],

  // --- the fix: Apple via Firebase token ---
  ['Apple/Firebase token, matching email',    {props:APIKEY, firebase:fbUser()},
   {firebaseIdToken:'f', teacherEmail:'teacher@example.com'}, true],
  ['Firebase token, google.com provider',     {props:APIKEY,
    firebase:fbUser({providerUserInfo:[{providerId:'google.com'}]})},
   {firebaseIdToken:'f', teacherEmail:'teacher@example.com'}, true],
  ['Firebase token, WRONG email',             {props:APIKEY, firebase:fbUser()},
   {firebaseIdToken:'f', teacherEmail:'someone@else.com'}, false],
  ['Firebase privaterelay address matches',   {props:APIKEY,
    firebase:fbUser({email:'abc123@privaterelay.appleid.com'})},
   {firebaseIdToken:'f', teacherEmail:'abc123@privaterelay.appleid.com'}, true],

  // --- security: must fail closed ---
  ['NO FIREBASE_API_KEY -> fail closed',      {props:{}, firebase:fbUser()},
   {firebaseIdToken:'f', teacherEmail:'teacher@example.com'}, false],
  ['password-only account REJECTED',          {props:APIKEY,
    firebase:fbUser({providerUserInfo:[{providerId:'password'}]})},
   {firebaseIdToken:'f', teacherEmail:'teacher@example.com'}, false],
  ['disabled account REJECTED',               {props:APIKEY,
    firebase:fbUser({disabled:true})},
   {firebaseIdToken:'f', teacherEmail:'teacher@example.com'}, false],
  ['invalid token (lookup 400)',              {props:APIKEY, firebase:{code:400,body:{}}},
   {firebaseIdToken:'f', teacherEmail:'teacher@example.com'}, false],
  ['empty users[] from lookup',               {props:APIKEY,
    firebase:{code:200, body:{users:[]}}},
   {firebaseIdToken:'f', teacherEmail:'teacher@example.com'}, false],
  ['no email on firebase user',               {props:APIKEY,
    firebase:fbUser({email:undefined})},
   {firebaseIdToken:'f', teacherEmail:'teacher@example.com'}, false],
  ['no tokens at all',                        {props:APIKEY},
   {teacherEmail:'teacher@example.com'}, false],
  ['no teacherEmail',                         {props:APIKEY, google:gOK},
   {idToken:'g'}, false],
  ['empty teacherEmail',                      {props:APIKEY, google:gOK},
   {idToken:'g', teacherEmail:'   '}, false],
  ['null payload',                            {props:APIKEY}, null, false],
  ['oversized token rejected before fetch',   {props:APIKEY, google:gOK},
   {idToken:'x'.repeat(9000), teacherEmail:'teacher@example.com'}, false],

  // --- both tokens present ---
  ['both sent, Google wins',                  {props:APIKEY, google:gOK, firebase:fbUser()},
   {idToken:'g', firebaseIdToken:'f', teacherEmail:'teacher@example.com'}, true],
  ['both sent, Google bad -> Firebase saves',  {props:APIKEY,
    google:{code:400,body:{}}, firebase:fbUser()},
   {idToken:'g', firebaseIdToken:'f', teacherEmail:'teacher@example.com'}, true],
  ['both sent, both wrong email',             {props:APIKEY,
    google:{code:200,body:{email:'a@b.com',email_verified:'true'}},
    firebase:fbUser({email:'c@d.com'})},
   {idToken:'g', firebaseIdToken:'f', teacherEmail:'teacher@example.com'}, false],
];

// ---------------------------------------------------------------------
// Suite 2 - requireDevAuth. Gates approve / reject / fetch_pending /
// fetch_all / fetch_audio. v1.23.3 added a Firebase token path so a
// developer signed in with Apple can use Developer Mode > Review; the
// email bar (DEVELOPER_EMAIL) is unchanged, and these tests exist to
// prove the widening grants nothing extra.
// ---------------------------------------------------------------------
const SECRET = { SCRIPT_SECRET: 's3cr3t-value', FIREBASE_API_KEY: 'AIzaFAKE' };
const gDev   = { code: 200, body: { email: 'samagids@gmail.com', email_verified: 'true' } };
const gOther = { code: 200, body: { email: 'someone@else.com',   email_verified: 'true' } };
const fbDev   = (over = {}) => ({ code: 200, body: { users: [Object.assign({
  email: 'samagids@gmail.com', disabled: false,
  providerUserInfo: [{ providerId: 'apple.com' }] }, over)] } });

const devCases = [
  // scriptSecret path - unchanged
  ['secret: correct',                    {props:SECRET}, {action:'fetch_all', scriptSecret:'s3cr3t-value'}, true],
  ['secret: wrong',                      {props:SECRET}, {action:'fetch_all', scriptSecret:'nope'}, false],
  // Google path - unchanged
  ['google: developer email',            {props:SECRET, google:gDev},   {idToken:'g'}, true],
  ['google: NON-developer REJECTED',     {props:SECRET, google:gOther}, {idToken:'g'}, false],
  ['google: unverified email REJECTED',  {props:SECRET,
     google:{code:200, body:{email:'samagids@gmail.com', email_verified:'false'}}}, {idToken:'g'}, false],
  // Firebase path - NEW in v1.23.3
  ['firebase: developer via Apple',      {props:SECRET, firebase:fbDev()}, {firebaseIdToken:'f'}, true],
  ['firebase: developer via Google',     {props:SECRET,
     firebase:fbDev({providerUserInfo:[{providerId:'google.com'}]})}, {firebaseIdToken:'f'}, true],
  ['firebase: NON-developer REJECTED',   {props:SECRET,
     firebase:fbDev({email:'someone@else.com'})}, {firebaseIdToken:'f'}, false],
  ['firebase: password acct REJECTED',   {props:SECRET,
     firebase:fbDev({providerUserInfo:[{providerId:'password'}]})}, {firebaseIdToken:'f'}, false],
  ['firebase: disabled acct REJECTED',   {props:SECRET, firebase:fbDev({disabled:true})}, {firebaseIdToken:'f'}, false],
  ['firebase: no API key -> closed',     {props:{SCRIPT_SECRET:'s3cr3t-value'}, firebase:fbDev()}, {firebaseIdToken:'f'}, false],
  ['firebase: lookup 400',               {props:SECRET, firebase:{code:400, body:{}}}, {firebaseIdToken:'f'}, false],
  // no credentials at all
  ['no tokens, no secret',               {props:SECRET}, {action:'fetch_all'}, false],
  ['null payload',                       {props:SECRET}, null, false],
];

let pass = 0, fail = 0;
for (const [name, scen, payload, want] of devCases) {
  SCENARIO = scen;
  let got;
  try { got = requireDevAuth(payload); }
  catch (e) { got = 'THREW: ' + e.message; }
  const ok = got === want;
  ok ? pass++ : fail++;
  console.log(`${ok ? 'PASS' : 'FAIL'}  [dev ] ${name.padEnd(36)} want=${want} got=${got}`);
}

for (const [name, scen, payload, want] of cases) {
  SCENARIO = scen;
  let got;
  try { got = requireStudySetAuth(payload); }
  catch (e) { got = 'THREW: ' + e.message; }
  const ok = got === want;
  ok ? pass++ : fail++;
  console.log(`${ok ? 'PASS' : 'FAIL'}  [set ] ${name.padEnd(36)} want=${want} got=${got}`);
}
console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
