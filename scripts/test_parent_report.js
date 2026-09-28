// Harness for the v1.23.6 parent-report endpoints.
// Loads the real Code.js with Apps Script globals stubbed, then asserts the
// properties that actually matter: who can be mailed, and who cannot.
const fs = require('fs');
const vm = require('vm');

const src = fs.readFileSync(process.argv[2], 'utf8');

let store = {};
let sent = [];        // {to, subject, body}
let tokenTable = {};  // idToken -> verified email

const sandbox = {
  console,
  Date,
  JSON,
  Math,
  encodeURIComponent,
  RegExp,
  String,
  Logger: { log: () => {} },
  PropertiesService: {
    getScriptProperties: () => ({
      getProperty: (k) => (k in store ? store[k] : null),
      setProperty: (k, v) => { store[k] = v; },
      getProperties: () => Object.assign({}, store),
      deleteProperty: (k) => { delete store[k]; },
    }),
  },
  Utilities: { getUuid: () => 'uuid-' + (Object.keys(store).length + Math.random()) },
  ScriptApp: { getService: () => ({ getUrl: () => 'https://script.example/exec' }) },
  HtmlService: {
    createHtmlOutput: (h) => ({ __html: h, getContent: () => h }),
  },
  ContentService: {
    MimeType: { JSON: 'json' },
    createTextOutput: (t) => ({ __text: t, setMimeType() { return this; } }),
  },
  MailApp: { sendEmail: () => {} },
  UrlFetchApp: { fetch: () => ({ getResponseCode: () => 201, getContentText: () => '' }) },
  SpreadsheetApp: {}, DriveApp: {}, Session: {},
};
sandbox.globalThis = sandbox;
vm.createContext(sandbox);
vm.runInContext(src, sandbox, { filename: 'Code.js' });

// Replace the two seams we must control.
sandbox.verifyFirebaseIdToken_ = (t) => tokenTable[t] || null;
sandbox._sendEmail = (to, subject, body) => { sent.push({ to, subject, body }); };

const reply = (r) => JSON.parse(r.__text);
const reset = () => { store = {}; sent = []; };

let pass = 0, fail = 0;
function check(name, cond, extra) {
  if (cond) { pass++; console.log('  PASS  ' + name); }
  else { fail++; console.log('  FAIL  ' + name + (extra ? '  -> ' + JSON.stringify(extra) : '')); }
}

tokenTable['good'] = 'mother@example.com';
tokenTable['other'] = 'stranger@example.com';

console.log('\n--- handleParentReport ---');

reset();
let r = reply(sandbox.handleParentReport({ idToken: 'bad', kind: 'daily', body: 'x' }));
check('rejects an unverifiable token', r.status === 'error' && r.message === 'unauthorized', r);
check('  ...and sends nothing', sent.length === 0);

reset();
r = reply(sandbox.handleParentReport({ idToken: 'good', kind: 'daily', body: 'hello' }));
check('mails the token owner', r.status === 'success' && sent.length === 1 && sent[0].to === 'mother@example.com', { r, sent });

reset();
r = reply(sandbox.handleParentReport({
  idToken: 'good', kind: 'daily', body: 'hello',
  recipients: ['attacker@evil.invalid', 'mother@example.com'],
}));
check('DROPS an unconfirmed third-party address', sent.length === 1 && sent[0].to === 'mother@example.com', { sent });
check('  ...and reports it as dropped', r.dropped === 1, r);

reset();
r = reply(sandbox.handleParentReport({
  idToken: 'good', kind: 'daily', body: 'hi', recipients: ['attacker@evil.invalid'],
}));
check('refuses when every recipient is unconfirmed', r.status === 'error' && sent.length === 0, { r, sent });

reset();
r = reply(sandbox.handleParentReport({ idToken: 'good', kind: 'pwned', body: 'x' }));
check('rejects an unknown report kind', r.status === 'error', r);

reset();
r = reply(sandbox.handleParentReport({ idToken: 'good', kind: 'daily', body: '   ' }));
check('rejects an empty body', r.status === 'error' && sent.length === 0, r);

reset();
r = reply(sandbox.handleParentReport({
  idToken: 'good', kind: 'daily', body: 'a', subject: 'URGENT: your bank needs you',
}));
check('ignores a client-supplied subject', sent[0].subject.indexOf('bank') === -1, sent[0]);

reset();
sandbox.handleParentReport({ idToken: 'good', kind: 'daily', body: '<b>x</b><script>' });
check('strips angle brackets from the body', sent[0].body.indexOf('<') === -1, sent[0].body);

reset();
let ok = 0;
for (let i = 0; i < 10; i++) {
  if (reply(sandbox.handleParentReport({ idToken: 'good', kind: 'daily', body: 'n' + i })).status === 'success') ok++;
}
check('rate-limits to PARENT_REPORT_MAX_PER_DAY', ok === sandbox.PARENT_REPORT_MAX_PER_DAY, { ok, cap: sandbox.PARENT_REPORT_MAX_PER_DAY });

console.log('\n--- handleParentContactVerify + confirmation ---');

reset();
r = reply(sandbox.handleParentContactVerify({ idToken: 'good', email: 'mother@example.com' }));
check('own address needs no confirmation', r.status === 'success' && r.confirmed === true && sent.length === 0, { r, sent });

reset();
r = reply(sandbox.handleParentContactVerify({ idToken: 'good', email: 'Father@Example.com' }));
check('a second parent is mailed a confirmation', r.status === 'success' && r.confirmed === false && sent.length === 1, { r, sent });
check('  ...addressed to the normalized address', sent[0].to === 'father@example.com', sent[0]);
check('  ...naming who asked', sent[0].body.indexOf('mother@example.com') !== -1);

// Not deliverable until the link is opened.
const before = sent.length;
r = reply(sandbox.handleParentReport({
  idToken: 'good', kind: 'daily', body: 'x', recipients: ['father@example.com'],
}));
// Nothing is sent, and the owner is NOT silently substituted: asking to mail
// an unconfirmed address must not quietly mail somebody else instead.
check('report to an UNCONFIRMED second parent sends nothing',
  r.status === 'error' && sent.length === before, { r, added: sent.slice(before) });

// Open the link.
const link = sent[0].body.match(/t=([^&\s]+)&o=([^\s]+)/);
const page = sandbox._confirmParentContactPage(decodeURIComponent(link[1]), decodeURIComponent(link[2]));
check('confirmation page acknowledges', /confirmed/i.test(page.__html), page.__html.slice(0, 120));

sent = [];
r = reply(sandbox.handleParentReport({
  idToken: 'good', kind: 'daily', body: 'x', recipients: ['mother@example.com', 'father@example.com'],
}));
check('AFTER confirming, both parents are mailed',
  sent.length === 2 && sent.map(s => s.to).sort().join(',') === 'father@example.com,mother@example.com',
  sent.map(s => s.to));

const page2 = sandbox._confirmParentContactPage(decodeURIComponent(link[1]), decodeURIComponent(link[2]));
check('the confirmation link is single-use', /already used|expired|not recognised/i.test(page2.__html));

// A different account must not inherit the confirmation.
sent = [];
r = reply(sandbox.handleParentReport({
  idToken: 'other', kind: 'daily', body: 'x', recipients: ['father@example.com'],
}));
check('another account cannot reuse that confirmation',
  r.status === 'error' && sent.length === 0, { r, sent });

console.log('\n--- handleParentContactStatus ---');
r = reply(sandbox.handleParentContactStatus({ idToken: 'good' }));
check('reports the confirmed list', r.status === 'success' && r.confirmed.indexOf('father@example.com') !== -1, r);
r = reply(sandbox.handleParentContactStatus({ idToken: 'bad' }));
check('status requires a valid token', r.status === 'error', r);

console.log('\n' + pass + ' passed, ' + fail + ' failed\n');
process.exit(fail === 0 ? 0 : 1);
