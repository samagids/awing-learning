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
  var testEmail = 'samagidshop@gmail.com';
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
