// study_set_audio_service.dart
// ---------------------------------------------------------------
// Session 63 Phase 3 — Study Set teacher-audio upload via the
// existing Apps Script + Google Drive pipeline. NO Firebase Storage
// (which would require the Blaze paid plan).
//
// Flow mirrors the Contribute > Record Audio pipeline:
//   1. Client records m4a to a local file.
//   2. Client base64-encodes the file bytes.
//   3. Client POSTs { action:'study_set_upload_audio', ...base64,
//      idToken } to the contributions Apps Script webhook.
//   4. Apps Script verifies the Google idToken matches teacherEmail,
//      decodes base64, writes to Google Drive under
//      StudySets/{setId}/{audioKey}.m4a, sets ANYONE_WITH_LINK
//      sharing, returns the Drive download URL.
//   5. Client writes URL into set.recordings[awing] and syncs to
//      Firestore.
//
// Reuses ContributionService's webhook URL + idToken auth pattern —
// no new deployment surface, no billing account required.
// ---------------------------------------------------------------
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';

class StudySetAudioService {
  StudySetAudioService._();
  static final StudySetAudioService instance = StudySetAudioService._();

  static const int _maxBytesPreEncode = 1500 * 1024; // 1.5 MB — mirrors ContributionService.

  /// The webhook URL loaded from config/webhooks.json (same file the
  /// ContributionService reads). Cached after first fetch.
  String? _webhookUrl;

  /// The Google Sign-In singleton used to fetch idToken on privileged
  /// study-set writes. Uses the same clientId scope the rest of the
  /// app already asks for (see cloud_backup_service.dart).
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'openid', 'profile'],
  );

  /// Build the audio filename stem for an Awing word — matches the
  /// convention used everywhere else in the app.
  String audioKey(String awing) => PronunciationService.audioKey(awing);

  /// Local file path for a fresh recording (pre-upload).
  Future<String> localRecordingPath({
    required String setId,
    required String awing,
  }) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/study_set_recordings/$setId');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return '${dir.path}/${audioKey(awing)}.m4a';
  }

  Future<String?> _loadWebhookUrl() async {
    if (_webhookUrl != null && _webhookUrl!.isNotEmpty) return _webhookUrl;
    try {
      final raw = await rootBundle.loadString('config/webhooks.json');
      final map = jsonDecode(raw) as Map<String, dynamic>;
      // Contributions webhook — same host that handles submit / approve.
      final url = map['contributions_url'] as String?;
      if (url != null && url.isNotEmpty) {
        _webhookUrl = url;
      }
    } catch (e) {
      debugPrint('StudySetAudioService _loadWebhookUrl failed: $e');
    }
    return _webhookUrl;
  }

  /// Fetch the current Google OAuth idToken (NOT Firebase idToken) —
  /// the Apps Script webhook validates this against Google's tokeninfo
  /// endpoint. Matches the pattern in ContributionService for privileged
  /// endpoints (see Session 58 notes in CLAUDE.md).
  Future<String?> _idToken() async {
    try {
      final acc = _googleSignIn.currentUser ??
          await _googleSignIn.signInSilently();
      if (acc == null) return null;
      final auth = await acc.authentication;
      return auth.idToken;
    } catch (e) {
      debugPrint('StudySetAudioService _idToken failed: $e');
      return null;
    }
  }

  /// POST a payload to the Apps Script webhook and follow the
  /// 302→GET pattern (Session 26 lesson — Apps Script always redirects
  /// POST to a GET on script.googleusercontent.com for the JSON body).
  Future<Map<String, dynamic>?> _post(Map<String, dynamic> payload) async {
    final url = await _loadWebhookUrl();
    if (url == null) {
      debugPrint('StudySetAudioService _post: no webhook URL configured');
      return null;
    }
    final client = HttpClient();
    try {
      // Phase 1: POST — server processes, returns 302
      final req = await client.postUrl(Uri.parse(url));
      req.headers.set('Content-Type', 'application/json; charset=utf-8');
      req.followRedirects = false;
      req.add(utf8.encode(jsonEncode(payload)));
      final resp = await req.close();
      if (resp.statusCode == 200) {
        // No redirect — read directly.
        final body = await utf8.decoder.bind(resp).join();
        return jsonDecode(body) as Map<String, dynamic>;
      }
      if (resp.statusCode != 302 && resp.statusCode != 301) {
        debugPrint('StudySetAudioService _post: unexpected status ${resp.statusCode}');
        return null;
      }
      // Phase 2: follow 302 → GET
      var next = resp.headers.value('location');
      for (int hop = 0; hop < 5 && next != null; hop++) {
        final getReq = await client.getUrl(Uri.parse(next));
        getReq.followRedirects = false;
        final getResp = await getReq.close();
        if (getResp.statusCode == 200) {
          final body = await utf8.decoder.bind(getResp).join();
          return jsonDecode(body) as Map<String, dynamic>;
        }
        next = getResp.headers.value('location');
      }
      return null;
    } catch (e) {
      debugPrint('StudySetAudioService _post failed: $e');
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// Upload a locally-recorded m4a via Apps Script → Google Drive.
  /// Returns the Drive download URL, or null on failure.
  Future<String?> uploadRecording({
    required String teacherEmail,
    required String setId,
    required String awing,
    required String localPath,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) {
      debugPrint('StudySetAudioService uploadRecording: file not found '
          '$localPath');
      return null;
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > _maxBytesPreEncode) {
      debugPrint('StudySetAudioService uploadRecording: file too large '
          '(${bytes.length} bytes, cap ${_maxBytesPreEncode})');
      return null;
    }
    final idToken = await _idToken();
    if (idToken == null) {
      debugPrint('StudySetAudioService uploadRecording: no idToken '
          '— caller must be signed in with Google');
      return null;
    }
    final result = await _post({
      'action': 'study_set_upload_audio',
      'setId': setId,
      'teacherEmail': teacherEmail.trim().toLowerCase(),
      'awing': awing,
      'audioKey': audioKey(awing),
      'audioBase64': base64Encode(bytes),
      'idToken': idToken,
    });
    if (result == null) return null;
    if (result['status'] != 'ok') {
      debugPrint('StudySetAudioService uploadRecording error: '
          '${result['message']}');
      return null;
    }
    return result['audioUrl'] as String?;
  }

  // ────────────────────────────────────────────────────────────────
  // v1.22.0 (Session 66) — Study Set pictures. Parallel to audio.
  // Reuses the same Apps Script webhook + Google Drive folder pattern.
  // ────────────────────────────────────────────────────────────────

  /// Cap for image uploads: 2 MB before base64 encoding.
  /// image_picker in ImageAttachmentPicker already compresses to
  /// 1024x1024 @ quality 80, which lands well under this.
  static const int _maxImageBytesPreEncode = 2 * 1024 * 1024;

  /// Upload a picture via Apps Script → Google Drive.
  /// Returns the Drive download URL, or null on failure.
  Future<String?> uploadImage({
    required String teacherEmail,
    required String setId,
    required String awing,
    required String localPath,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) {
      debugPrint('StudySetAudioService uploadImage: file not found '
          '$localPath');
      return null;
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > _maxImageBytesPreEncode) {
      debugPrint('StudySetAudioService uploadImage: file too large '
          '(${bytes.length} bytes, cap $_maxImageBytesPreEncode)');
      return null;
    }
    final idToken = await _idToken();
    if (idToken == null) {
      debugPrint('StudySetAudioService uploadImage: no idToken '
          '— caller must be signed in with Google');
      return null;
    }
    // Guess the extension from the path — image_picker gives us .jpg
    // or .png depending on source.
    final ext = localPath.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    final result = await _post({
      'action': 'study_set_upload_image',
      'setId': setId,
      'teacherEmail': teacherEmail.trim().toLowerCase(),
      'awing': awing,
      'imageKey': audioKey(awing),
      'imageExt': ext,
      'imageBase64': base64Encode(bytes),
      'idToken': idToken,
    });
    if (result == null) return null;
    if (result['status'] != 'ok') {
      debugPrint('StudySetAudioService uploadImage error: '
          '${result['message']}');
      return null;
    }
    return result['imageUrl'] as String?;
  }

  /// Best-effort delete of a single cloud image via webhook.
  Future<void> deleteImage({
    required String teacherEmail,
    required String setId,
    required String awing,
  }) async {
    final idToken = await _idToken();
    if (idToken == null) return;
    await _post({
      'action': 'study_set_delete_image',
      'setId': setId,
      'teacherEmail': teacherEmail.trim().toLowerCase(),
      'awing': awing,
      'imageKey': audioKey(awing),
      'idToken': idToken,
    });
  }

  /// Best-effort delete of a single cloud recording via webhook. If it
  /// fails we still zero out the client-side recordings map — a stale
  /// Drive file is harmless (no client references it).
  Future<void> deleteRecording({
    required String teacherEmail,
    required String setId,
    required String awing,
  }) async {
    final idToken = await _idToken();
    if (idToken == null) return;
    await _post({
      'action': 'study_set_delete_audio',
      'setId': setId,
      'teacherEmail': teacherEmail.trim().toLowerCase(),
      'awing': awing,
      'audioKey': audioKey(awing),
      'idToken': idToken,
    });
  }

  /// Best-effort delete of every audio file for a set. Called when the
  /// teacher deletes the whole set.
  Future<void> deleteAllForSet({
    required String teacherEmail,
    required String setId,
  }) async {
    final idToken = await _idToken();
    if (idToken == null) return;
    await _post({
      'action': 'study_set_delete_set_audio',
      'setId': setId,
      'teacherEmail': teacherEmail.trim().toLowerCase(),
      'idToken': idToken,
    });
  }
}
