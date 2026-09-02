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
 * Weekly feature tour — set as a time-based trigger so testers get a
 * different one-paragraph tip every week. Rotates through FEATURES
 * in order, remembering position across runs via ScriptProperties.
 *
 * Setup: Triggers → Add Trigger → runWeeklyFeatureTour →
 *        Time-driven → Week timer → e.g. Wednesday 09:00-10:00 UTC
 *        (10:00-11:00 WAT — mid-morning, not competing with the
 *        Saturday share reminder).
 *
 * To add a new feature, append to the FEATURES array below and
 * re-paste this file into the Apps Script editor. The rotation
 * picks up the new entry automatically on its natural turn.
 */
function runWeeklyFeatureTour() {
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
  var feature = {
    subject: t.subject.replace(re, word),
    body: t.body.replace(re, word),
  };
  var emails = fetchAllUserEmails();
  Logger.log('runWeeklyFeatureTour: word=' + word + ' template=' + templateIdx +
      ' (idx ' + idx + ' of ' + WORDS.length + '), ' + emails.length + ' users');
  var sent = 0, failed = 0;
  for (var i = 0; i < emails.length; i++) {
    try {
      MailApp.sendEmail(emails[i], feature.subject, feature.body);
      sent++;
      Utilities.sleep(200);
    } catch (err) {
      Logger.log('Email to ' + emails[i] + ' failed: ' + err);
      failed++;
    }
  }
  props.setProperty('LAST_FEATURE_IDX', String(idx));
  Logger.log('runWeeklyFeatureTour done — idx=' + idx +
      ' word=' + word + ' sent=' + sent + ' failed=' + failed);
}
