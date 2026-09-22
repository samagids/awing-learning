/**
 * Awing AI Learning — Analytics Web App (Google Apps Script)
 *
 * SETUP INSTRUCTIONS:
 * 1. Go to https://script.google.com and create a new project
 * 2. Paste this entire script into Code.gs
 * 3. Run setupSheets() once (it creates the Google Sheet with proper tabs)
 * 4. Deploy > New deployment > Web app
 *    - Execute as: Me (samagids@gmail.com)
 *    - Who has access: Anyone
 * 5. Copy the web app URL and paste it into:
 *    lib/services/analytics_service.dart → _webhookUrl
 *
 * The Sheet will be created in your Google Drive as "Awing Analytics"
 * with tabs: Activity, Quizzes, Feedback, Errors, Sessions
 */

// Sheet name — created automatically
var SHEET_NAME = 'Awing Analytics';

/**
 * Run this once to create the Google Sheet with all tabs and headers.
 */
function setupSheets() {
  var ss = SpreadsheetApp.create(SHEET_NAME);

  // Activity tab — lesson views, completions, audio plays
  var activity = ss.getSheetByName('Sheet1');
  activity.setName('Activity');
  activity.getRange(1, 1, 1, 8).setValues([[
    'Timestamp', 'Device ID', 'Event', 'Level', 'Lesson', 'Detail', 'Duration (sec)', 'App Version'
  ]]);
  activity.setFrozenRows(1);
  activity.getRange(1, 1, 1, 8).setFontWeight('bold');

  // Quizzes tab — quiz attempts with scores and wrong answers
  var quizzes = ss.insertSheet('Quizzes');
  quizzes.getRange(1, 1, 1, 9).setValues([[
    'Timestamp', 'Device ID', 'Quiz Type', 'Level', 'Score (%)', 'Correct', 'Total', 'Wrong Answers', 'Time (sec)'
  ]]);
  quizzes.setFrozenRows(1);
  quizzes.getRange(1, 1, 1, 9).setFontWeight('bold');

  // Feedback tab — user recommendations and ratings
  var feedback = ss.insertSheet('Feedback');
  feedback.getRange(1, 1, 1, 6).setValues([[
    'Timestamp', 'Device ID', 'Type', 'Rating', 'Message', 'Screen'
  ]]);
  feedback.setFrozenRows(1);
  feedback.getRange(1, 1, 1, 6).setFontWeight('bold');

  // Errors tab — app crashes and error reports
  var errors = ss.insertSheet('Errors');
  errors.getRange(1, 1, 1, 6).setValues([[
    'Timestamp', 'Device ID', 'Screen', 'Error', 'Stack Trace', 'App Version'
  ]]);
  errors.setFrozenRows(1);
  errors.getRange(1, 1, 1, 6).setFontWeight('bold');

  // Sessions tab — app open/close, daily usage
  var sessions = ss.insertSheet('Sessions');
  sessions.getRange(1, 1, 1, 7).setValues([[
    'Timestamp', 'Device ID', 'Event', 'Session Duration (min)', 'Lessons Done', 'Quizzes Done', 'App Version'
  ]]);
  sessions.setFrozenRows(1);
  sessions.getRange(1, 1, 1, 7).setFontWeight('bold');

  Logger.log('Sheet created: ' + ss.getUrl());
  Logger.log('Share this URL or find "Awing Analytics" in your Google Drive.');
}

/**
 * Handle POST requests from the app.
 * Each request contains a JSON body with { sheet, data } fields.
 */
// Session 64c - single destination for operational alerts. Defined as a
// constant because handleNewUser() mails it directly; the address in an
// inbound payload is CONTENT only and must never become a recipient,
// since this endpoint is unauthenticated (that would be an open relay).
var DEVELOPER_EMAIL = 'samagids@gmail.com';

function doPost(e) {
  try {
    var payload = JSON.parse(e.postData.contents);

    // Handle developer 2FA verification code email
    if (payload.action === 'send_dev_code') {
      return handleSendDevCode(payload);
    }

    // Session 64c - a brand-new account signed in for the first time.
    if (payload.action === 'new_user') {
      return handleNewUser(payload);
    }

    var sheetName = payload.sheet || 'Activity';
    var rows = payload.data || [];

    if (!Array.isArray(rows) || rows.length === 0) {
      return ContentService.createTextOutput(JSON.stringify({
        status: 'error',
        message: 'No data provided'
      })).setMimeType(ContentService.MimeType.JSON);
    }

    // Find the sheet
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    if (!ss) {
      // If no active spreadsheet, find by name
      var files = DriveApp.getFilesByName(SHEET_NAME);
      if (files.hasNext()) {
        ss = SpreadsheetApp.open(files.next());
      } else {
        return ContentService.createTextOutput(JSON.stringify({
          status: 'error',
          message: 'Analytics sheet not found. Run setupSheets() first.'
        })).setMimeType(ContentService.MimeType.JSON);
      }
    }

    var sheet = ss.getSheetByName(sheetName);
    if (!sheet) {
      return ContentService.createTextOutput(JSON.stringify({
        status: 'error',
        message: 'Sheet tab "' + sheetName + '" not found'
      })).setMimeType(ContentService.MimeType.JSON);
    }

    // Append rows
    for (var i = 0; i < rows.length; i++) {
      sheet.appendRow(rows[i]);
    }

    return ContentService.createTextOutput(JSON.stringify({
      status: 'ok',
      rowsAdded: rows.length
    })).setMimeType(ContentService.MimeType.JSON);

  } catch (err) {
    return ContentService.createTextOutput(JSON.stringify({
      status: 'error',
      message: err.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

/**
 * Send a 6-digit developer verification code via email.
 * This is the 2FA step for activating Developer Mode in the app.
 */
function handleSendDevCode(payload) {
  var code = payload.code || '000000';
  var email = payload.email || 'samagids@gmail.com';

  // Only allow sending to the developer email
  if (email !== 'samagids@gmail.com') {
    return ContentService.createTextOutput(JSON.stringify({
      status: 'error',
      message: 'Unauthorized email'
    })).setMimeType(ContentService.MimeType.JSON);
  }

  try {
    var subject = '[Awing] Developer Mode Verification Code: ' + code;
    var body = 'Your Awing AI Learning developer verification code is:\n\n' +
      '    ' + code + '\n\n' +
      'This code expires in 10 minutes.\n\n' +
      'If you did not request this code, you can safely ignore this email.\n\n' +
      '-- Awing AI Learning App';

    MailApp.sendEmail(email, subject, body);

    return ContentService.createTextOutput(JSON.stringify({
      status: 'ok',
      message: 'Verification code sent'
    })).setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    return ContentService.createTextOutput(JSON.stringify({
      status: 'error',
      message: 'Failed to send email: ' + err.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

/**
 * Session 64c - email the developer when a new account appears.
 *
 * Fired once per address by AuthService when it creates a local account
 * for an email it has not seen. Deliberately deduplicated SERVER-side as
 * well: the endpoint is unauthenticated (like the rest of this webhook's
 * analytics intake), so a client bug, a reinstall, or someone poking the
 * URL could otherwise spam the inbox. We keep a seen-list in Script
 * Properties and mail at most once per address, ever.
 *
 * The alert always goes to DEVELOPER_EMAIL - the address in the payload is
 * only ever used as CONTENT, never as a destination. That matters: this
 * endpoint takes unauthenticated input, and echoing a caller-supplied
 * address into sendEmail's recipient would turn it into an open relay.
 */
function handleNewUser(payload) {
  var email = String(payload.email || '').trim().toLowerCase();
  if (!email || email.length > 320 || email.indexOf('@') < 1) {
    return ContentService.createTextOutput(JSON.stringify({
      status: 'error', message: 'invalid email'
    })).setMimeType(ContentService.MimeType.JSON);
  }

  var props = PropertiesService.getScriptProperties();
  var key = 'seen_user_' + email.replace(/[^a-z0-9]/g, '_').substring(0, 80);
  if (props.getProperty(key)) {
    // Already announced. Silent success so the client never retries.
    return ContentService.createTextOutput(JSON.stringify({
      status: 'ok', message: 'already announced'
    })).setMimeType(ContentService.MimeType.JSON);
  }

  try {
    // Strip CR/LF from anything that reaches the subject line - MailApp
    // mis-parses headers containing them.
    function clean(v, max) {
      return String(v || '').replace(/[\r\n]+/g, ' ').substring(0, max || 120);
    }
    var name = clean(payload.displayName, 80);
    var how = clean(payload.authMethod, 20);
    var ver = clean(payload.appVersion, 20);
    var plat = clean(payload.platform, 20);

    var subject = '[Awing] New user: ' + clean(email, 120);
    var body =
      'A new account just signed in to Awing AI Learning.\n\n' +
      '  Email    : ' + email + '\n' +
      '  Name     : ' + (name || '(not provided)') + '\n' +
      '  Sign-in  : ' + (how || '(unknown)') + '\n' +
      '  Platform : ' + (plat || '(unknown)') + '\n' +
      '  App      : ' + (ver || '(unknown)') + '\n' +
      '  Seen at  : ' + new Date().toISOString() + '\n\n' +
      'You are receiving this because you are the developer of the app.\n' +
      'See Developer Mode > Users for the full list.\n\n' +
      '-- Awing AI Learning';

    MailApp.sendEmail(DEVELOPER_EMAIL, subject, body);
    props.setProperty(key, String(Date.now()));

    return ContentService.createTextOutput(JSON.stringify({
      status: 'ok', message: 'alert sent'
    })).setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    return ContentService.createTextOutput(JSON.stringify({
      status: 'error', message: 'Failed to send: ' + err.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

/**
 * Handle GET requests (health check).
 */
function doGet(e) {
  return ContentService.createTextOutput(JSON.stringify({
    status: 'ok',
    service: 'Awing Analytics',
    timestamp: new Date().toISOString()
  })).setMimeType(ContentService.MimeType.JSON);
}
