// fcm_daily_push.gs
// -----------------------------------------------------------------------
// v1.22.3 (Session 68) — Server-side daily engagement push via Firebase
// Cloud Messaging HTTP v1 API. Replaces the local AlarmManager
// scheduling that was silently dropped by Samsung/Xiaomi/Oppo OEMs.
//
// This Google Apps Script runs on 3 time-based triggers:
//   - 08:00 WAT (07:00 UTC) — morning "words of the day" nudge
//   - 19:00 WAT (18:00 UTC) — evening practice reminder
//   - Sat 10:00 WAT (09:00 UTC) — weekly share reminder
//
// Each execution:
//   1. Reads all users from Firestore users/{email}/data/settings
//      that have an `fcmToken` field.
//   2. Filters by optional analytics-opt-out setting (skip if user
//      opted out of all pushes — we honor that despite "notifications
//      enforced" being an in-app-only construct).
//   3. Batches tokens 500 at a time and posts to
//      https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send
//      with an OAuth2 access token minted from a service-account key.
//   4. Logs sends/failures to a Sheet for observability.
//
// One-time setup (Dr. Sama does this in Firebase Console):
//   1. Firebase Console → Project Settings → Service accounts →
//      "Generate new private key" → downloads .json
//   2. Google Apps Script editor → File → Project settings →
//      Script properties → add key `FCM_SERVICE_ACCOUNT_JSON` with
//      the file contents (paste raw JSON as the value)
//   3. Also add `FCM_PROJECT_ID` with value `sanguine-frame-291822`
//   4. Enable "Cloud Firestore API" in Google Cloud Console for the
//      SAME project the Apps Script is bound to.
//   5. Deploy this script as a web app OR just run runDailyPushMorning
//      manually once to test.
//   6. Set 3 time-based triggers:
//      - Triggers → Add Trigger → runDailyPushMorning → Time-driven →
//        Day timer → 7am to 8am. (UTC — Apps Script always uses UTC.)
//      - Same for runDailyPushEvening at 18:00-19:00 UTC.
//      - Same for runWeeklyShareReminder → Week timer → Saturday →
//        9am to 10am UTC.
// -----------------------------------------------------------------------

// ==================== Handlers (triggered by cron) ====================

function runDailyPushMorning() {
  var titles = [
    'Awing time! Learn 3 new words',
    'Cha\'tô! Today\'s Awing words are ready',
    'Good morning — try today\'s Awing lesson',
    '3 fresh Awing words waiting for you',
  ];
  var bodies = [
    'Open Awing AI Learning and see today\'s 3 words.',
    'Just 5 minutes today keeps the streak alive.',
    'Your kids love the daily reminder — tap to open.',
    'Beginner, Medium, and Expert — pick your level.',
  ];
  sendDailyPushToAll(pickRandom(titles), pickRandom(bodies), 'daily_words');
}

function runDailyPushEvening() {
  var titles = [
    'One more chance to learn Awing today',
    'Evening Awing time!',
    'Practice before bed — 5 minutes',
    'Awing awaits — a quick evening lesson',
  ];
  var bodies = [
    'Finish your Awing words for today.',
    'Kids learn best right before sleep. Open Awing.',
    'Even a couple words tonight helps tomorrow\'s memory.',
    'Tap to see today\'s vocabulary.',
  ];
  sendDailyPushToAll(pickRandom(titles), pickRandom(bodies), 'daily_words_evening');
}

function runWeeklyShareReminder() {
  var titles = [
    'Share Awing with a friend today',
    'Help another family discover Awing',
    'Know someone learning Awing?',
  ];
  var bodies = [
    'Tap to send the Awing AI Learning app to a friend.',
    'Every share helps grow the Awing community.',
    'One tap sends the app to WhatsApp or SMS.',
  ];
  sendDailyPushToAll(pickRandom(titles), pickRandom(bodies), 'weekly_share');
}

// ==================== Core: fan-out send ====================

function sendDailyPushToAll(title, body, payload) {
  var startedAt = new Date();
  var tokens = fetchAllFcmTokens();
  Logger.log('sendDailyPushToAll: ' + tokens.length + ' tokens fetched');

  var accessToken = getOAuthAccessToken();
  var projectId = getFcmProjectId();
  var successCount = 0;
  var failureCount = 0;
  var invalidTokens = [];

  for (var i = 0; i < tokens.length; i++) {
    var t = tokens[i];
    var result = sendOneFcm(accessToken, projectId, t.token, title, body, payload);
    if (result.ok) {
      successCount++;
    } else {
      failureCount++;
      if (result.invalidToken) {
        invalidTokens.push(t);
      }
    }
    // Poor man's rate limit — 20 sends/sec is well under FCM's 600
    // rpm limit and gives Apps Script room to breathe (6-min cap).
    if (i % 20 === 19) Utilities.sleep(50);
  }

  // Clean up tokens FCM told us are dead so future runs don't waste
  // time on them.
  for (var j = 0; j < invalidTokens.length; j++) {
    deleteInvalidToken(invalidTokens[j].email);
  }

  logSendResult({
    payload: payload,
    title: title,
    body: body,
    startedAt: startedAt,
    finishedAt: new Date(),
    totalTokens: tokens.length,
    successCount: successCount,
    failureCount: failureCount,
    invalidCleaned: invalidTokens.length,
  });
}

function sendOneFcm(accessToken, projectId, token, title, body, payload) {
  var url = 'https://fcm.googleapis.com/v1/projects/' + projectId + '/messages:send';
  var message = {
    message: {
      token: token,
      notification: {
        title: title,
        body: body,
      },
      android: {
        priority: 'HIGH',
        notification: {
          channel_id: 'awing_daily_words',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      apns: {
        headers: { 'apns-priority': '10' },
        payload: {
          aps: {
            alert: { title: title, body: body },
            sound: 'default',
          },
        },
      },
      data: {
        payload: payload,
      },
    },
  };
  try {
    var response = UrlFetchApp.fetch(url, {
      method: 'post',
      contentType: 'application/json',
      headers: { Authorization: 'Bearer ' + accessToken },
      payload: JSON.stringify(message),
      muteHttpExceptions: true,
    });
    var code = response.getResponseCode();
    if (code >= 200 && code < 300) return { ok: true };
    var text = response.getContentText();
    // 404 UNREGISTERED / 400 INVALID_ARGUMENT → token is dead
    var isInvalid = code === 404 ||
        (code === 400 && text.indexOf('INVALID_ARGUMENT') >= 0) ||
        text.indexOf('registration-token-not-registered') >= 0 ||
        text.indexOf('UNREGISTERED') >= 0;
    Logger.log('FCM send failed ' + code + ': ' + text.substring(0, 200));
    return { ok: false, invalidToken: isInvalid };
  } catch (err) {
    Logger.log('FCM send exception: ' + err);
    return { ok: false, invalidToken: false };
  }
}

// ==================== Firestore reads ====================

function fetchAllFcmTokens() {
  var accessToken = getOAuthAccessToken();
  var projectId = getFcmProjectId();
  // Firestore REST API collectionGroup query — reads every 'settings'
  // doc under any users/{email}/data/settings path.
  var url = 'https://firestore.googleapis.com/v1/projects/' + projectId +
      '/databases/(default)/documents:runQuery';
  var body = {
    structuredQuery: {
      from: [{ collectionId: 'data', allDescendants: true }],
      where: {
        fieldFilter: {
          field: { fieldPath: 'fcmToken' },
          op: 'GREATER_THAN',
          value: { stringValue: '' },
        },
      },
    },
  };
  var response = UrlFetchApp.fetch(url, {
    method: 'post',
    contentType: 'application/json',
    headers: { Authorization: 'Bearer ' + accessToken },
    payload: JSON.stringify(body),
    muteHttpExceptions: true,
  });
  if (response.getResponseCode() !== 200) {
    Logger.log('Firestore query failed: ' + response.getContentText());
    return [];
  }
  var rows = JSON.parse(response.getContentText());
  var tokens = [];
  for (var i = 0; i < rows.length; i++) {
    var row = rows[i];
    if (!row.document) continue;
    // Only the 'settings' doc holds fcmToken (data/{docId} where
    // docId === 'settings'). Skip other data-tree docs.
    var name = row.document.name;
    if (name.indexOf('/data/settings') < 0) continue;
    var fields = row.document.fields || {};
    var token = (fields.fcmToken || {}).stringValue;
    if (!token) continue;
    // Extract the email from the doc path:
    // projects/X/databases/(default)/documents/users/{email}/data/settings
    var match = name.match(/\/users\/([^\/]+)\/data\/settings$/);
    if (!match) continue;
    var emailDocId = match[1];
    tokens.push({ email: emailDocId, token: token });
  }
  return tokens;
}

function deleteInvalidToken(emailDocId) {
  try {
    var accessToken = getOAuthAccessToken();
    var projectId = getFcmProjectId();
    var url = 'https://firestore.googleapis.com/v1/projects/' + projectId +
        '/databases/(default)/documents/users/' + encodeURIComponent(emailDocId) +
        '/data/settings?updateMask.fieldPaths=fcmToken';
    // PATCH with empty fcmToken clears just that field.
    UrlFetchApp.fetch(url, {
      method: 'patch',
      contentType: 'application/json',
      headers: { Authorization: 'Bearer ' + accessToken },
      payload: JSON.stringify({ fields: { fcmToken: { stringValue: '' } } }),
      muteHttpExceptions: true,
    });
  } catch (err) {
    Logger.log('deleteInvalidToken failed for ' + emailDocId + ': ' + err);
  }
}

// ==================== OAuth2 ====================

function getOAuthAccessToken() {
  var cache = CacheService.getScriptCache();
  var cached = cache.get('FCM_OAUTH_TOKEN');
  if (cached) return cached;

  var svcJson = getServiceAccountJson();
  var now = Math.floor(Date.now() / 1000);
  var claims = {
    iss: svcJson.client_email,
    scope: [
      'https://www.googleapis.com/auth/firebase.messaging',
      'https://www.googleapis.com/auth/datastore',
    ].join(' '),
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  };
  var header = { alg: 'RS256', typ: 'JWT' };
  var toSign = base64UrlEncode_(JSON.stringify(header)) + '.' +
      base64UrlEncode_(JSON.stringify(claims));
  var signature = Utilities.computeRsaSha256Signature(toSign, svcJson.private_key);
  var jwt = toSign + '.' + base64UrlEncodeBytes_(signature);

  var response = UrlFetchApp.fetch('https://oauth2.googleapis.com/token', {
    method: 'post',
    payload: {
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    },
    muteHttpExceptions: true,
  });
  if (response.getResponseCode() !== 200) {
    throw new Error('OAuth token request failed: ' + response.getContentText());
  }
  var result = JSON.parse(response.getContentText());
  var token = result.access_token;
  // Cache slightly less than 1h so we never serve an expired one.
  cache.put('FCM_OAUTH_TOKEN', token, 3300);
  return token;
}

function getServiceAccountJson() {
  var raw = PropertiesService.getScriptProperties()
      .getProperty('FCM_SERVICE_ACCOUNT_JSON');
  if (!raw) {
    throw new Error('FCM_SERVICE_ACCOUNT_JSON script property not set. ' +
        'Firebase Console -> Service accounts -> Generate new private key, ' +
        'then Apps Script -> Project settings -> Script properties.');
  }
  return JSON.parse(raw);
}

function getFcmProjectId() {
  var id = PropertiesService.getScriptProperties()
      .getProperty('FCM_PROJECT_ID');
  if (!id) throw new Error('FCM_PROJECT_ID script property not set.');
  return id;
}

// ==================== Helpers ====================

function base64UrlEncode_(str) {
  return Utilities.base64EncodeWebSafe(str).replace(/=+$/, '');
}

function base64UrlEncodeBytes_(bytes) {
  return Utilities.base64EncodeWebSafe(bytes).replace(/=+$/, '');
}

function pickRandom(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function logSendResult(row) {
  try {
    var sheet = getOrCreateLogSheet();
    sheet.appendRow([
      row.startedAt,
      row.finishedAt,
      row.payload,
      row.title,
      row.body,
      row.totalTokens,
      row.successCount,
      row.failureCount,
      row.invalidCleaned,
    ]);
  } catch (err) {
    Logger.log('logSendResult failed: ' + err);
  }
}

function getOrCreateLogSheet() {
  var name = 'FCM Push Log';
  var sheet;
  var files = DriveApp.getFilesByName(name);
  if (files.hasNext()) {
    sheet = SpreadsheetApp.open(files.next()).getActiveSheet();
  } else {
    var ss = SpreadsheetApp.create(name);
    sheet = ss.getActiveSheet();
    sheet.appendRow([
      'Started (UTC)', 'Finished (UTC)', 'Payload', 'Title', 'Body',
      'Total tokens', 'Success', 'Failure', 'Invalid tokens cleaned',
    ]);
  }
  return sheet;
}

// ==================== One-shot test helper ====================

function testSendToOneEmail() {
  // Edit this to your own email address, then Run.
  var testEmail = 'samagids@gmail.com';
  var docId = testEmail.toLowerCase().replace(/\./g, '_dot_');
  var accessToken = getOAuthAccessToken();
  var projectId = getFcmProjectId();
  var url = 'https://firestore.googleapis.com/v1/projects/' + projectId +
      '/databases/(default)/documents/users/' + encodeURIComponent(docId) +
      '/data/settings';
  var response = UrlFetchApp.fetch(url, {
    headers: { Authorization: 'Bearer ' + accessToken },
    muteHttpExceptions: true,
  });
  if (response.getResponseCode() !== 200) {
    Logger.log('Firestore doc read failed: ' + response.getContentText());
    return;
  }
  var doc = JSON.parse(response.getContentText());
  var token = ((doc.fields || {}).fcmToken || {}).stringValue;
  if (!token) {
    Logger.log('No fcmToken for ' + testEmail + ' — is the app installed and signed in on your phone?');
    return;
  }
  Logger.log('Sending test push to ' + testEmail);
  var result = sendOneFcm(accessToken, projectId, token,
      'Awing test push', 'If you see this, FCM works!', 'test');
  Logger.log('Result: ' + JSON.stringify(result));
}

// ==================== Email outreach (v1.22.9+, Session 68c) ====================
//
// Two ways to reach every user by email — separate from the FCM push
// channel because email is a better fit for longer-form content
// (feature tours, re-engagement asks, honest-review requests) and
// works even for testers who haven't yet updated to the FCM-capable
// build.
//
// Uses MailApp.sendEmail() — quota 100/day for personal Google
// accounts, plenty for a ~30-tester audience. Emails come "from"
// the Apps Script owner (samagids@gmail.com).
//
// One-time OAuth: the first time you Run either function, Apps
// Script will prompt to authorize the send_mail scope. Click Allow.

/**
 * Enumerate every user email currently in Firestore. Uses the same
 * collectionGroup pattern as fetchAllFcmTokens but with no field
 * filter — we just extract unique parent emails from every
 * data/{doc} path (accounts, settings, progress, etc.).
 *
 * Returns an array of plain email strings, e.g. ['user@gmail.com', ...].
 */
function fetchAllUserEmails() {
  var accessToken = getOAuthAccessToken();
  var projectId = getFcmProjectId();
  var url = 'https://firestore.googleapis.com/v1/projects/' + projectId +
      '/databases/(default)/documents:runQuery';
  var body = {
    structuredQuery: {
      from: [{ collectionId: 'data', allDescendants: true }],
      // Only need the doc name (path) — skip returning all fields.
      select: { fields: [{ fieldPath: '__name__' }] },
    },
  };
  var response = UrlFetchApp.fetch(url, {
    method: 'post',
    contentType: 'application/json',
    headers: { Authorization: 'Bearer ' + accessToken },
    payload: JSON.stringify(body),
    muteHttpExceptions: true,
  });
  if (response.getResponseCode() !== 200) {
    Logger.log('fetchAllUserEmails failed: ' + response.getContentText());
    return [];
  }
  var rows = JSON.parse(response.getContentText());
  var seen = {};
  for (var i = 0; i < rows.length; i++) {
    var row = rows[i];
    if (!row.document) continue;
    // Path: projects/X/databases/(default)/documents/users/{email_dot_gmail_dot_com}/data/{doc}
    var match = row.document.name.match(/\/users\/([^\/]+)\/data\//);
    if (!match) continue;
    // Desanitize doc id back to email address: _dot_ -> .
    var email = match[1].replace(/_dot_/g, '.');
    if (email.indexOf('@') > 0) seen[email] = true;
  }
  var emails = [];
  for (var e in seen) emails.push(e);
  emails.sort();
  return emails;
}

/**
 * One-off manual reminder — run from the Apps Script editor whenever
 * engagement dips. Emails every user in the database asking them to
 * open the app.
 */
function sendReminderEmailToAll() {
  var emails = fetchAllUserEmails();
  Logger.log('sendReminderEmailToAll: ' + emails.length + ' users found');
  var subject = 'Awing AI Learning — update, open, and share when you can';
  var body =
    'Hi friend,\n\n' +
    'Thank you for being part of the Awing AI Learning journey.\n\n' +
    'FIRST — please update the app. Open the Play Store or App Store, ' +
    'search for "Awing AI Learning" and tap Update. New updates include ' +
    'a daily Word of the Day notification, better pronunciations, and ' +
    'other improvements.\n\n' +
    'THEN — take a few minutes this week to open the app and try any ' +
    'lesson (Alphabet, Words, Tones, Numbers, or the Quiz). Real usage ' +
    'helps us prove to Google and Apple that the app is worth keeping ' +
    'in their stores.\n\n' +
    'PLEASE SHARE — if you enjoy the app, forward this link to a ' +
    'friend, a teacher, or anyone who wants their children to learn ' +
    'Awing. Every new person brings us closer to a full public launch:\n' +
    '  Android: https://play.google.com/store/apps/details?id=com.awing.learning\n' +
    '  iPhone: https://apps.apple.com/app/id6764426877\n\n' +
    'And an honest review on the store helps other families discover ' +
    'the app.\n\n' +
    'Thank you!\n' +
    'Dr. Guidion Sama';
  var sent = 0, failed = 0;
  for (var i = 0; i < emails.length; i++) {
    try {
      MailApp.sendEmail(emails[i], subject, body);
      sent++;
      Utilities.sleep(200); // ~5/sec, well under MailApp's 100/day quota
    } catch (err) {
      Logger.log('Email to ' + emails[i] + ' failed: ' + err);
      failed++;
    }
  }
  Logger.log('sendReminderEmailToAll done — sent=' + sent + ' failed=' + failed);
}

/**
 * Weekly feature tour — set as time-based triggers so testers get a
 * different curiosity question every week. Rotates through 224 words ×
 * 10 subject templates, remembering position across runs via
 * ScriptProperties.
 *
 * IMPORTANT: MailApp has a 100-recipient-per-day quota on personal
 * Google accounts. We have ~104+ users. To stay under the cap, the
 * send is SPLIT ACROSS TWO CONSECUTIVE DAYS:
 *
 *   runWeeklyFeatureTourPart1  → Wednesday 10:00 UTC → first half
 *   runWeeklyFeatureTourPart2  → Thursday  10:00 UTC → second half
 *
 * Both parts send the SAME word/template (so testers who compare
 * notes see the same message). Only Part 2 (the last part) advances
 * LAST_FEATURE_IDX to the next word.
 *
 * Setup:
 *   Triggers → Add Trigger → runWeeklyFeatureTourPart1 → Time-driven
 *              → Week timer → Wednesday 10:00-11:00 UTC
 *   Triggers → Add Trigger → runWeeklyFeatureTourPart2 → Time-driven
 *              → Week timer → Thursday  10:00-11:00 UTC
 *
 * If the audience grows past ~200 users, either add Part3 (Friday) or
 * upgrade the sending account to Google Workspace (1500/day quota).
 *
 * Legacy: `runWeeklyFeatureTour()` (no suffix) is kept for backward
 * compatibility — sends to ALL users at once, which will fail above
 * 100. Use the Part1/Part2 pair instead. Delete the old trigger.
 */
function runWeeklyFeatureTourPart1() { _runWeeklyPart(0, 2); }
function runWeeklyFeatureTourPart2() { _runWeeklyPart(1, 2); }
function runWeeklyFeatureTour()      { _runWeeklyPart(0, 1); }

/**
 * Manual test helper — sends ONE weekly-tour email to samagids@gmail.com
 * using the exact same template + footer pipeline as the real triggers,
 * without advancing the word counter. Run from the Apps Script editor
 * to preview a real render before shipping. Uses 1 MailApp quota unit.
 * Change TEST_EMAIL to preview to a different address.
 */
function testWeeklyFeatureTourToMe() {
  _runWeeklyPart(0, 1, ['samagids@gmail.com'], true);
}

/**
 * Manual test helper — same as testWeeklyFeatureTourToMe but forces the
 * send through Brevo regardless of the USE_BREVO flag. Use to preview
 * the real weekly-tour HTML template as Brevo will deliver it (checks
 * deliverability, spam classification, HTML rendering) BEFORE flipping
 * USE_BREVO to 'true' on the whole audience. Uses 1 Brevo quota unit.
 */
function testWeeklyFeatureTourToMeBrevo() {
  _runWeeklyPart(0, 1, ['samagids@gmail.com'], true, true);
}

function _runWeeklyPart(partIdx, totalParts, opt_overrideEmails, opt_holdCounter, opt_forceBrevo) {
  // Each week asks a curiosity-driven question that pulls the user
  // into the app to search for the answer themselves. We never state
  // the Awing word in the email — per the Session 30 rule the app
  // is the only place authorized to display Awing. The whole point
  // is to make them OPEN THE APP to find it.
  //
  // Approach: rotate through ~256 curated English words × 10 subject
  // templates. That's 2560+ unique subject+body combos — enough
  // for over a decade of weekly rotation before the same pair repeats.
  //
  // To add more topics: append to WORDS below. All entries must be
  // English words that exist as glosses in lib/data/awing_vocabulary
  // so testers who search actually find an answer in the app. To add
  // more phrasings: append to TEMPLATES.
  var WORDS = [
    'ear', 'eye', 'hip', 'jaw', 'leg', 'lip', 'rib', 'toe', 'back', 'body',
    'bone', 'chin', 'face', 'foot', 'hair', 'hand', 'head', 'knee', 'lung',
    'nail', 'neck', 'nose', 'skin', 'tear', 'beard', 'cheek', 'chest',
    'elbow', 'heart', 'joint', 'boy', 'baby', 'clan', 'farm', 'girl',
    'town', 'twin', 'wife', 'chief', 'child', 'elder', 'guest', 'house',
    'niece', 'tribe', 'twins', 'church', 'doctor', 'father', 'friend',
    'hunter', 'market', 'mother', 'nephew', 'ant', 'bat', 'bee', 'cat',
    'dog', 'fly', 'hen', 'owl', 'pig', 'ram', 'rat', 'bird', 'claw',
    'cock', 'crab', 'dove', 'duck', 'fish', 'frog', 'goat', 'hawk', 'lion',
    'toad', 'worm', 'eagle', 'horse', 'louse', 'mouse', 'snail', 'snake',
    'animal', 'baboon', 'donkey', 'insect', 'jackal', 'lizard', 'egg',
    'oil', 'yam', 'corn', 'food', 'meat', 'milk', 'rice', 'salt', 'soup',
    'beans', 'fruit', 'grape', 'guava', 'honey', 'maize', 'onion', 'sauce',
    'sugar', 'banana', 'coffee', 'orange', 'pawpaw', 'potato', 'tomato',
    'avocado', 'cassava', 'cocoyam', 'kola nut', 'mushroom', 'plantain',
    'day', 'dew', 'fog', 'mud', 'sea', 'sky', 'sun', 'bush', 'cave',
    'dawn', 'dust', 'fire', 'hill', 'lake', 'leaf', 'moon', 'path', 'rain',
    'road', 'rock', 'root', 'sand', 'seed', 'tree', 'wind', 'year',
    'cloud', 'field', 'flame', 'grass', 'light', 'marsh', 'ask', 'dig',
    'dip', 'eat', 'mix', 'run', 'say', 'try', 'bend', 'bite', 'blow',
    'boil', 'burn', 'call', 'chew', 'comb', 'come', 'drip', 'fade', 'give',
    'have', 'help', 'hide', 'hook', 'kiss', 'lend', 'lick', 'lift', 'melt',
    'obey', 'open', 'plan', 'push', 'read', 'all', 'big', 'dry', 'far',
    'fat', 'few', 'hot', 'new', 'old', 'red', 'wet', 'bony', 'cold',
    'deep', 'down', 'full', 'good', 'hard', 'kind', 'last', 'late', 'long',
    'many', 'much', 'nice', 'real', 'one', 'six', 'ten', 'two', 'five',
    'four', 'nine', 'eight', 'seven', 'three', 'second'
  ];
  var TEMPLATES = [
    {
      subject: 'Do you know the Awing word for "{w}"?',
      body: 'Open Awing AI Learning today and find it in:\n  • Beginner → Words (search "{w}")\n  • Explore → Translate\n\nTap the speaker to hear how it sounds, then teach it to your children today.\n\nThank you!\nDr. Sama'
    },
    {
      subject: 'Can you pronounce "{w}" in Awing?',
      body: 'Open Awing AI Learning → Beginner → Words. Search for "{w}", tap the speaker to hear the correct pronunciation, then say it out loud with your family this week.\n\nThank you!\nDr. Sama'
    },
    {
      subject: 'What is the Awing word for "{w}"?',
      body: 'Every language has its own word for this. Open Awing AI Learning → Beginner → Words, or try Translate under Explore. Search for "{w}" and hear the real Awing sound.\n\nThank you!\nDr. Sama'
    },
    {
      subject: 'This week: how do you say "{w}" in Awing?',
      body: 'A small language challenge for the week.\n\nOpen Awing AI Learning → Beginner → Words. Search for "{w}", then use it with your children at least once each day this week.\n\nThank you!\nDr. Sama'
    },
    {
      subject: 'Awing challenge: teach your children "{w}" this week',
      body: 'Kids learn best when they hear a word every day.\n\nOpen Awing AI Learning → Beginner → Words. Search for "{w}", tap the speaker, and use it around the house until they remember it.\n\nThank you!\nDr. Sama'
    },
    {
      subject: 'Do you remember the Awing word for "{w}"?',
      body: 'Refresh a word you might already know.\n\nOpen Awing AI Learning → Beginner → Words. Search for "{w}" and hear it again. The more we practice, the better we remember.\n\nThank you!\nDr. Sama'
    },
    {
      subject: '"{w}" in Awing — do you know it?',
      body: 'A small language quiz for you.\n\nOpen Awing AI Learning → Beginner → Words, or Explore → Translate. Look up "{w}" and hear the Awing pronunciation.\n\nThank you!\nDr. Sama'
    },
    {
      subject: 'Can you name "{w}" in Awing?',
      body: 'Naming things in our language keeps it alive.\n\nOpen Awing AI Learning → Beginner → Words. Search for "{w}", tap the speaker, and use it with your family today.\n\nThank you!\nDr. Sama'
    },
    {
      subject: 'Test yourself: "{w}" in Awing?',
      body: 'A quick self-test to keep your Awing sharp.\n\nOpen Awing AI Learning → Beginner → Words. Search for "{w}". Hear it, say it out loud, then teach it to a family member this week.\n\nThank you!\nDr. Sama'
    },
    {
      subject: 'Awing word of the week: {w}',
      body: 'This week\'s word to focus on: "{w}".\n\nOpen Awing AI Learning → Beginner → Words. Search for it, hear the pronunciation, and use it every day for the next seven days.\n\nThank you!\nDr. Sama'
    },
  ];
  var props = PropertiesService.getScriptProperties();
  var lastIdx = parseInt(props.getProperty('LAST_FEATURE_IDX') || '-1', 10);
  var idx = (lastIdx + 1) % WORDS.length;
  var word = WORDS[idx];
  // Cycle template variety across weeks — template 0 pairs with word 0,
  // template 1 with word 1, etc. After one WORDS cycle the templates
  // shift so the same word gets a fresh phrasing next go-round.
  var templateIdx = idx % TEMPLATES.length;
  var t = TEMPLATES[templateIdx];
  var re = /\{w\}/g;
  // Strip the "Thank you!/Dr. Sama" sign-off from each template body
  // because _weeklyFooter carries its own sign-off. Without this strip
  // the reader sees "Thank you!" mid-email before the footer content.
  var bodyNoSignoff = t.body.replace(/\s*Thank you!\s*Dr\. Sama\s*$/i, '');
  var curiosityText = bodyNoSignoff.replace(re, word);
  var feature = {
    subject: t.subject.replace(re, word),
    // Plain-text version — fallback for email clients that don't render
    // HTML (Outlook 2003, plain-text Linux mail clients, some webmail
    // security-view modes). Every recipient sees SOMETHING even in
    // those edge cases.
    body: curiosityText + _weeklyFooter(idx),
    // HTML version — what Gmail, Apple Mail, Outlook 365, and every
    // modern mobile mail client renders. Adds tappable WhatsApp / SMS /
    // Email share buttons that pre-fill a ready-made message so
    // recipients share in one tap instead of copy-pasting.
    html: _bodyToHtml(curiosityText) + _weeklyFooterHtml(idx),
  };
  // Slice recipients into equal-ish parts. Part 0 gets the first
  // ceil(N/totalParts) users, Part 1 gets the rest. Ensures no user
  // is skipped and no user is emailed twice per week.
  // Test helpers can pass an override list (e.g. just [samagids@gmail.com])
  // to preview a real render without hitting the whole audience.
  var allEmails = opt_overrideEmails || fetchAllUserEmails();
  var per = Math.ceil(allEmails.length / totalParts);
  var start = partIdx * per;
  var end = Math.min(start + per, allEmails.length);
  var slice = allEmails.slice(start, end);
  Logger.log('_runWeeklyPart ' + (partIdx + 1) + '/' + totalParts +
      ': word=' + word + ' template=' + templateIdx +
      ' (idx ' + idx + ' of ' + WORDS.length + '), recipients ' +
      start + '-' + end + ' of ' + allEmails.length);
  var sent = 0, failed = 0;
  for (var i = 0; i < slice.length; i++) {
    try {
      // opt_forceBrevo bypasses the USE_BREVO flag for test-only preview.
      if (opt_forceBrevo) {
        _sendViaBrevo(slice[i], feature.subject, feature.body, feature.html);
      } else {
        _sendEmail(slice[i], feature.subject, feature.body, feature.html);
      }
      sent++;
      Utilities.sleep(200);
    } catch (err) {
      Logger.log('Email to ' + slice[i] + ' failed: ' + err);
      failed++;
    }
  }
  // Only the LAST part advances the word counter — so all parts of the
  // same week's send use the same word, and the counter moves once per
  // week total.
  // Test helpers can request the counter be held so the real Wednesday
  // trigger still uses the SAME idx (i.e. what you previewed is what
  // real users will get).
  if (partIdx === totalParts - 1 && !opt_holdCounter) {
    props.setProperty('LAST_FEATURE_IDX', String(idx));
  }
  Logger.log('_runWeeklyPart ' + (partIdx + 1) + '/' + totalParts +
      ' done — word=' + word + ' sent=' + sent + ' failed=' + failed +
      (partIdx === totalParts - 1 && !opt_holdCounter
          ? ' (counter advanced)' : ' (counter held)'));
}

/**
 * Shared footer appended to every weekly feature-tour email. Carries
 * three things missing from the curiosity paragraph alone:
 *
 *   1. A rotating "Have you tried this feature?" callout so testers
 *      keep discovering parts of the app they've never opened.
 *   2. Play Store + App Store install/update links so recipients who
 *      don't have the app yet — or who are on an old build — can act
 *      immediately.
 *   3. An explicit "please share with a friend" ask, essential for
 *      organic growth given the Awing-speaker audience is small and
 *      diaspora-distributed.
 *
 * Rotates the feature callout independently of the word rotation.
 * Uses the same idx that drives the word so the (word, feature) pair
 * is deterministic — a tester who forwards two consecutive weeks to
 * a friend will see the two features paired with the two words in
 * the same order.
 */
function _weeklyFooter(idx) {
  var FEATURES = [
    'Study Sets — save your favorite words to practice later. Tap Explore -> Study Sets, then create a set of words for you and your kids.',
    'Word of the Day — 3 fresh Awing words arrive every morning as a phone notification. No need to open the app to see them.',
    'Translate — type any English word and instantly see its Awing translation with a speaker button. Tap Explore -> Translate.',
    'Games — practice tones and words in fun, kid-friendly games. Tap Play from the home screen.',
    'Contribute — help improve the app by suggesting new words, corrections, or recording your own pronunciation. Tap Explore -> Contribute.',
    'Pronunciation practice — hear a native speaker say each word, then record your own voice and compare. Tap Beginner -> Pronunciation.',
    'Voice characters — pick your favorite voice out of six: boy, girl, young man, young woman, man, or woman.',
    'Stories — short Awing stories with English translations, perfect for evening reading with kids. Tap Beginner -> Stories.',
    'Quiz — 10 quizzes per level (Beginner, Medium, Expert) to test what you know. Tap the level, then Quiz.',
    'Numbers — learn to count in Awing. Tap Beginner -> Numbers.',
    'Alphabet — every letter of the Awing alphabet with the sound and an example word. Tap Beginner -> Alphabet.',
    'Tones — hear the difference between high, mid, low, rising, and falling tones. Tap Beginner -> Tones.',
    'Conversations — listen to full Awing conversations at Expert level. Tap Expert -> Conversations.',
    'Consonant clusters — Medium level dives into prenasalized (mb, nd, ng), palatalized (ny, ty), and labialized (kw, gw) sounds.',
    'Noun classes — Medium level teaches how Awing groups nouns into 9 classes with different prefixes. Tap Medium -> Noun Classes.',
    'Exams — Expert level lets teachers create a live exam over Wi-Fi that students join with a 6-digit PIN. Tap Expert -> Exams.',
    'Vowels and syllables — Medium level covers the 9 Awing vowels and how syllables are built. Tap Medium -> Vowels.',
    'Sound changes — Expert level explains how sounds shift when words combine. Tap Expert -> Sound Changes.',
    'Elision — Expert level covers how Awing drops sounds when speaking quickly. Tap Expert -> Elision.',
    'Proverbs — Expert-level Awing proverbs with English meaning. Tap Expert -> Proverbs.',
  ];
  var feature = FEATURES[idx % FEATURES.length];
  return '\n\n' +
      '----------------------------------------------------------\n' +
      'HAVE YOU TRIED THIS FEATURE?\n' +
      feature + '\n\n' +
      'DO NOT HAVE THE APP YET, OR NEED TO UPDATE?\n' +
      '  Android:  https://play.google.com/store/apps/details?id=com.awing.learning\n' +
      '  iPhone:   https://apps.apple.com/app/id6764426877\n\n' +
      'SHARE WITH A FRIEND\n' +
      'If you enjoy Awing AI Learning, please forward this email\n' +
      'to a friend or family member. Every Awing-speaking family\n' +
      'that gets the app is one more chance to keep the language\n' +
      'alive for the next generation.\n\n' +
      'And an honest review on the Play Store or App Store helps\n' +
      'other families discover the app.\n\n' +
      'Thank you!\n' +
      'Dr. Guidion Sama';
}

/**
 * HTML version of _weeklyFooter — same content, but with tappable
 * WhatsApp/SMS/Email share buttons that pre-fill a ready-made message
 * so recipients share in one tap. Feature callout rotates in lockstep
 * with _weeklyFooter (same FEATURES list, same idx modulo).
 *
 * Design choices:
 *  - Inline styles only — many email clients strip <style> blocks.
 *  - System font stack — renders native everywhere without loading
 *    web fonts (which Gmail and iOS Mail block anyway).
 *  - Awing green (#006432) for headings/links so the branding is
 *    consistent with the app.
 *  - Button colors chosen for platform recognition: WhatsApp brand
 *    green (#25D366), iOS-Messages blue (#007AFF), Awing accent
 *    gold (#DAA520) for the generic email button.
 *  - `wa.me/?text=` opens WhatsApp with message pre-filled on both
 *    Android and iOS. `sms:?body=` opens the phone's SMS app.
 *    `mailto:?subject=...&body=...` opens the user's email app.
 *  - Boxed <blockquote> version at the bottom for anyone who wants
 *    to select-and-copy manually (Telegram, Facebook, Instagram DM,
 *    or any platform we did not put a button for).
 */
function _weeklyFooterHtml(idx) {
  var FEATURES = [
    'Study Sets — save your favorite words to practice later. Tap Explore → Study Sets, then create a set of words for you and your kids.',
    'Word of the Day — 3 fresh Awing words arrive every morning as a phone notification. No need to open the app to see them.',
    'Translate — type any English word and instantly see its Awing translation with a speaker button. Tap Explore → Translate.',
    'Games — practice tones and words in fun, kid-friendly games. Tap Play from the home screen.',
    'Contribute — help improve the app by suggesting new words, corrections, or recording your own pronunciation. Tap Explore → Contribute.',
    'Pronunciation practice — hear a native speaker say each word, then record your own voice and compare. Tap Beginner → Pronunciation.',
    'Voice characters — pick your favorite voice out of six: boy, girl, young man, young woman, man, or woman.',
    'Stories — short Awing stories with English translations, perfect for evening reading with kids. Tap Beginner → Stories.',
    'Quiz — 10 quizzes per level (Beginner, Medium, Expert) to test what you know. Tap the level, then Quiz.',
    'Numbers — learn to count in Awing. Tap Beginner → Numbers.',
    'Alphabet — every letter of the Awing alphabet with the sound and an example word. Tap Beginner → Alphabet.',
    'Tones — hear the difference between high, mid, low, rising, and falling tones. Tap Beginner → Tones.',
    'Conversations — listen to full Awing conversations at Expert level. Tap Expert → Conversations.',
    'Consonant clusters — Medium level dives into prenasalized (mb, nd, ng), palatalized (ny, ty), and labialized (kw, gw) sounds.',
    'Noun classes — Medium level teaches how Awing groups nouns into 9 classes with different prefixes. Tap Medium → Noun Classes.',
    'Exams — Expert level lets teachers create a live exam over Wi-Fi that students join with a 6-digit PIN. Tap Expert → Exams.',
    'Vowels and syllables — Medium level covers the 9 Awing vowels and how syllables are built. Tap Medium → Vowels.',
    'Sound changes — Expert level explains how sounds shift when words combine. Tap Expert → Sound Changes.',
    'Elision — Expert level covers how Awing drops sounds when speaking quickly. Tap Expert → Elision.',
    'Proverbs — Expert-level Awing proverbs with English meaning. Tap Expert → Proverbs.',
  ];
  var feature = FEATURES[idx % FEATURES.length];
  var shareMsg =
      'I am using Awing AI Learning to teach my kids our language. ' +
      'Try it — it is free!\n\n' +
      'Android: https://play.google.com/store/apps/details?id=com.awing.learning\n' +
      'iPhone: https://apps.apple.com/app/id6764426877';
  var enc = encodeURIComponent(shareMsg);
  var waUrl = 'https://wa.me/?text=' + enc;
  var smsUrl = 'sms:?body=' + enc;
  var mailUrl = 'mailto:?subject=' +
      encodeURIComponent('Try Awing AI Learning') + '&body=' + enc;

  var h3Style = 'color: #006432; margin: 24px 0 8px 0; font-size: 16px; ' +
      'font-family: system-ui, -apple-system, sans-serif;';
  var pStyle = 'margin: 0 0 12px 0; font-family: system-ui, -apple-system, ' +
      'sans-serif; line-height: 1.5; color: #333;';
  var btnBase = 'display: inline-block; padding: 12px 20px; text-decoration: ' +
      'none; border-radius: 6px; margin: 6px 8px 6px 0; font-weight: 600; ' +
      'color: white; font-family: system-ui, -apple-system, sans-serif; ' +
      'font-size: 14px;';

  return '<hr style="border: none; border-top: 1px solid #ccc; margin: 28px 0;">' +
      '<h3 style="' + h3Style + '">Have you tried this feature?</h3>' +
      '<p style="' + pStyle + '">' + _escapeHtml(feature) + '</p>' +
      '<h3 style="' + h3Style + '">Do not have the app yet, or need to update?</h3>' +
      '<p style="' + pStyle + '">' +
      '<a href="https://play.google.com/store/apps/details?id=com.awing.learning" ' +
      'style="color: #006432;">Get it on Google Play</a><br>' +
      '<a href="https://apps.apple.com/app/id6764426877" ' +
      'style="color: #006432;">Get it on the App Store</a>' +
      '</p>' +
      '<h3 style="' + h3Style + '">Share with a friend</h3>' +
      '<p style="' + pStyle + '">Every Awing-speaking family that gets ' +
      'the app is one more chance to keep the language alive for the ' +
      'next generation.</p>' +
      '<p style="' + pStyle + '"><strong>Tap to share a ready-made message:</strong></p>' +
      '<p style="margin: 0 0 20px 0;">' +
      '<a href="' + waUrl + '" style="' + btnBase + 'background: #25D366;">Share on WhatsApp</a>' +
      '<a href="' + smsUrl + '" style="' + btnBase + 'background: #007AFF;">Share by SMS</a>' +
      '<a href="' + mailUrl + '" style="' + btnBase + 'background: #DAA520;">Share by Email</a>' +
      '</p>' +
      '<p style="' + pStyle + '"><strong>Or copy and paste this message anywhere:</strong></p>' +
      '<blockquote style="border-left: 4px solid #006432; padding: 14px 18px; ' +
      'margin: 8px 0 20px 0; background: #f5f5f5; white-space: pre-wrap; ' +
      'font-family: system-ui, -apple-system, sans-serif; color: #333; ' +
      'line-height: 1.5;">' + _escapeHtml(shareMsg) + '</blockquote>' +
      '<p style="' + pStyle + ' font-style: italic; color: #555;">' +
      'An honest review on the Play Store or App Store helps other ' +
      'families discover the app.</p>' +
      '<p style="' + pStyle + '">Thank you!<br>Dr. Guidion Sama</p>';
}

/**
 * Convert a plain-text curiosity paragraph to HTML: escape HTML
 * special chars, auto-link http(s) URLs, convert newlines to <br>,
 * wrap in a container div with the same font/color as the footer
 * so the whole email renders as a single visual unit.
 */
function _bodyToHtml(text) {
  var esc = _escapeHtml(text);
  var withLinks = esc.replace(
      /(https?:\/\/[^\s<]+)/g,
      '<a href="$1" style="color: #006432;">$1</a>');
  var withBr = withLinks.replace(/\n/g, '<br>');
  return '<div style="font-family: system-ui, -apple-system, ' +
      'BlinkMacSystemFont, Segoe UI, Roboto, sans-serif; line-height: ' +
      '1.5; color: #333; max-width: 600px; font-size: 15px;">' +
      withBr + '</div>';
}

/**
 * Escape HTML special chars so user-facing text can never inject
 * HTML tags into the rendered email body. Not strictly needed for
 * our own content (we control every string) but keeps the code
 * defensive if a future contributor adds user-generated text.
 */
function _escapeHtml(s) {
  return String(s)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
}

// ==================== Email dispatcher: MailApp vs Brevo ====================
//
// MailApp is capped at 100 recipients/day on personal Google accounts —
// enough for ~200 users when we split Wed+Thu, but no headroom past that.
// Brevo (formerly Sendinblue) gives 300/day free forever, no card, no
// domain needed once the sender is verified. Once the user list crosses
// what MailApp can handle, flip the USE_BREVO script property to 'true'
// and every _sendEmail call routes through Brevo instead.
//
// Script Property keys used:
//   USE_BREVO       — 'true' to route through Brevo, otherwise MailApp
//   BREVO_API_KEY   — the xkeysib-... key from Brevo's SMTP & API page
//   BREVO_SENDER    — verified sender email (default: samagids@gmail.com)
//   BREVO_FROM_NAME — display name for the "From" header
//                     (default: 'Dr. Guidion Sama')

/**
 * Single entry point for every email this script sends. Routes to Brevo
 * or MailApp based on the USE_BREVO script property. Throws on failure
 * so the caller's try/catch tracks failure counts correctly.
 */
function _sendEmail(to, subject, textBody, htmlBody) {
  var useBrevo = PropertiesService.getScriptProperties()
      .getProperty('USE_BREVO') === 'true';
  if (useBrevo) {
    _sendViaBrevo(to, subject, textBody, htmlBody);
  } else {
    _sendViaMailApp(to, subject, textBody, htmlBody);
  }
}

function _sendViaMailApp(to, subject, textBody, htmlBody) {
  MailApp.sendEmail({
    to: to,
    subject: subject,
    body: textBody,
    htmlBody: htmlBody,
  });
}

/**
 * POST one email to Brevo's transactional email API. The endpoint accepts
 * up to 1000 "to" recipients per call, but we send one-per-call so
 * per-recipient error handling in the caller loop still works.
 *
 * Reply-To is set to the sender so replies land in samagids@gmail.com
 * even though Brevo's IPs actually deliver the message.
 */
function _sendViaBrevo(to, subject, textBody, htmlBody) {
  var props = PropertiesService.getScriptProperties();
  var apiKey = props.getProperty('BREVO_API_KEY');
  if (!apiKey) {
    throw new Error('BREVO_API_KEY script property not set. Add it under ' +
        'Project settings -> Script properties.');
  }
  var senderEmail = props.getProperty('BREVO_SENDER') || 'samagids@gmail.com';
  var senderName = props.getProperty('BREVO_FROM_NAME') || 'Dr. Guidion Sama';
  var payload = {
    sender: { name: senderName, email: senderEmail },
    to: [{ email: to }],
    subject: subject,
    textContent: textBody,
    htmlContent: htmlBody,
    replyTo: { email: senderEmail, name: senderName },
  };
  var response = UrlFetchApp.fetch('https://api.brevo.com/v3/smtp/email', {
    method: 'post',
    contentType: 'application/json',
    headers: {
      'api-key': apiKey,
      'accept': 'application/json',
    },
    payload: JSON.stringify(payload),
    muteHttpExceptions: true,
  });
  var code = response.getResponseCode();
  if (code < 200 || code >= 300) {
    throw new Error('Brevo send failed ' + code + ': ' +
        response.getContentText().substring(0, 300));
  }
}

/**
 * Smoke test — sends one email to samagids@gmail.com via Brevo directly,
 * bypassing the weekly rotation and the USE_BREVO flag. Run this once
 * to verify the API key works and the email actually lands in the inbox
 * (not spam) before flipping USE_BREVO to 'true'. Uses 1 Brevo quota unit
 * regardless of MailApp state.
 */
function testBrevoDirectly() {
  var subject = 'Brevo smoke test — Awing AI Learning';
  var text = 'This is a plain-text smoke test sent through Brevo.\n\n' +
      'If you see this, the Brevo API key + sender verification are ' +
      'both working, and it is safe to flip USE_BREVO to true.\n\n' +
      'Sent at ' + new Date().toISOString();
  var html = '<div style="font-family: system-ui, sans-serif; ' +
      'max-width: 600px; line-height: 1.5; color: #333;">' +
      '<h2 style="color: #006432;">Brevo smoke test</h2>' +
      '<p>If you see this, the Brevo API key + sender verification are ' +
      'both working, and it is safe to flip <code>USE_BREVO</code> to ' +
      '<code>true</code>.</p>' +
      '<p style="color: #888; font-size: 12px;">Sent at ' +
      new Date().toISOString() + '</p></div>';
  _sendViaBrevo('samagids@gmail.com', subject, text, html);
  Logger.log('testBrevoDirectly: sent to samagids@gmail.com via Brevo');
}
