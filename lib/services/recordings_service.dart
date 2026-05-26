import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Session 61b — cross-device recording inventory.
///
/// Tracks which Awing words/phrases/letters/sentences/stories have been
/// recorded by whom across all signed-in devices. Backed by the Firestore
/// `/recordings` collection (rules in firestore.rules).
///
/// One document per (audio_key + recorded_by_email). When the same item is
/// re-recorded by the same user from a new device, the document is updated
/// in place (latest wins). When a different user records the same item, a
/// new document is created — both are valuable training data.
///
/// The actual audio file is uploaded via ContributionService (which stores
/// it in Drive via the Apps Script webhook). The Drive URL is then written
/// back to the Firestore document so the desktop sync script can download
/// every clip in one pass.
class RecordingsService extends ChangeNotifier {
  static const String _collection = 'recordings';

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _stream;
  final Map<String, RecordingDoc> _byId = {};

  // Index by audio_key → list of recordings of that item.
  // Multiple users recording the same item show up as separate entries.
  final Map<String, List<RecordingDoc>> _byAudioKey = {};

  bool _loaded = false;
  String? _error;

  bool get isLoaded => _loaded;
  String? get error => _error;
  int get totalCount => _byId.length;

  /// Distinct audio_keys that have at least one recording.
  Set<String> get recordedKeys => _byAudioKey.keys.toSet();

  /// All recordings, sorted newest first.
  List<RecordingDoc> get all {
    final list = _byId.values.toList();
    list.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return list;
  }

  /// All distinct emails that have contributed at least one recording.
  Set<String> get recorderEmails =>
      _byId.values.map((r) => r.recordedByEmail).toSet();

  /// All recordings for a given audio_key (may be empty).
  List<RecordingDoc> recordingsFor(String audioKey) =>
      List.unmodifiable(_byAudioKey[audioKey] ?? const []);

  /// True if at least one user has recorded this audio_key.
  bool hasRecording(String audioKey) =>
      (_byAudioKey[audioKey]?.isNotEmpty ?? false);

  /// True if THIS user has recorded this audio_key.
  bool recordedByCurrentUser(String audioKey) {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return false;
    final list = _byAudioKey[audioKey];
    if (list == null) return false;
    return list.any((r) => r.recordedByEmail == email);
  }

  /// Start listening to the Firestore /recordings collection. Idempotent:
  /// safe to call multiple times; only one stream is ever active.
  Future<void> initialize() async {
    if (_stream != null) return;
    try {
      _stream = FirebaseFirestore.instance
          .collection(_collection)
          .snapshots()
          .listen(_onSnapshot, onError: _onError);
    } catch (e) {
      _error = 'Failed to subscribe: $e';
      if (kDebugMode) print('RecordingsService.initialize: $e');
      notifyListeners();
    }
  }

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    _byId.clear();
    _byAudioKey.clear();
    for (final doc in snap.docs) {
      final r = RecordingDoc.fromFirestore(doc);
      _byId[r.id] = r;
      _byAudioKey.putIfAbsent(r.audioKey, () => []).add(r);
    }
    // Sort each per-key list newest first so UIs that show "latest by X"
    // can grab .first.
    for (final list in _byAudioKey.values) {
      list.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    }
    _loaded = true;
    _error = null;
    notifyListeners();
  }

  void _onError(Object e) {
    _error = e.toString();
    if (kDebugMode) print('RecordingsService stream error: $e');
    notifyListeners();
  }

  /// Write a new recording metadata document. Called BEFORE the audio
  /// upload completes, so the row exists immediately and other devices
  /// see the work-in-progress state. Pass the Drive URL via [updateDriveUrl]
  /// once the upload finishes.
  ///
  /// Returns the new document ID, or null on failure.
  Future<String?> recordSubmitted({
    required String awing,
    required String english,
    required String source,
    required String audioKey,
    String? category,
    String? device,
    int? durationMs,
    String? contributionId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) {
      if (kDebugMode) print('RecordingsService: not signed in, skipping');
      return null;
    }
    try {
      // Idempotency: if THIS user already has a recording for this
      // audio_key, update that doc instead of creating a duplicate.
      final existing = _byAudioKey[audioKey]
          ?.firstWhere(
            (r) => r.recordedByEmail == user!.email,
            orElse: () => RecordingDoc._empty(),
          );
      final isUpdate = existing != null && existing.id.isNotEmpty;

      final data = <String, dynamic>{
        'awing': awing,
        'english': english,
        'source': source,
        'audio_key': audioKey,
        'category': category,
        'recorded_by_email': user!.email,
        'recorded_by_name': user.displayName ?? user.email,
        'recorded_at': FieldValue.serverTimestamp(),
        'device': device,
        'duration_ms': durationMs,
        'contribution_id': contributionId,
      };

      if (isUpdate) {
        await FirebaseFirestore.instance
            .collection(_collection)
            .doc(existing.id)
            .set(data, SetOptions(merge: true));
        return existing.id;
      } else {
        final ref = await FirebaseFirestore.instance
            .collection(_collection)
            .add(data);
        return ref.id;
      }
    } catch (e) {
      if (kDebugMode) print('RecordingsService.recordSubmitted: $e');
      return null;
    }
  }

  /// Update an existing recording document with the Drive URL of the
  /// uploaded audio. Called after ContributionService finishes the upload.
  Future<void> updateDriveUrl(String recordingId, String driveUrl) async {
    try {
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(recordingId)
          .set({'drive_url': driveUrl}, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) print('RecordingsService.updateDriveUrl: $e');
    }
  }

  /// Developer-only deletion (server rules also enforce this).
  Future<bool> deleteRecording(String recordingId) async {
    try {
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(recordingId)
          .delete();
      return true;
    } catch (e) {
      if (kDebugMode) print('RecordingsService.deleteRecording: $e');
      return false;
    }
  }

  /// JSON snapshot of the current inventory — useful for the dev-side
  /// sync script (export → import to disk).
  String toJsonExport() {
    return jsonEncode({
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'count': _byId.length,
      'recordings': all.map((r) => r.toJson()).toList(),
    });
  }

  @override
  void dispose() {
    _stream?.cancel();
    super.dispose();
  }
}

/// Plain Dart model of a /recordings/{recId} Firestore document.
class RecordingDoc {
  final String id;
  final String awing;
  final String english;
  final String source;      // word | phrase | letter | sentence | story
  final String audioKey;
  final String? category;
  final String recordedByEmail;
  final String recordedByName;
  final DateTime recordedAt;
  final String? device;
  final String? driveUrl;
  final int? durationMs;
  final String? contributionId;

  const RecordingDoc({
    required this.id,
    required this.awing,
    required this.english,
    required this.source,
    required this.audioKey,
    required this.category,
    required this.recordedByEmail,
    required this.recordedByName,
    required this.recordedAt,
    required this.device,
    required this.driveUrl,
    required this.durationMs,
    required this.contributionId,
  });

  RecordingDoc._empty()
      : id = '',
        awing = '',
        english = '',
        source = '',
        audioKey = '',
        category = null,
        recordedByEmail = '',
        recordedByName = '',
        recordedAt = DateTime.fromMillisecondsSinceEpoch(0),
        device = null,
        driveUrl = null,
        durationMs = null,
        contributionId = null;

  factory RecordingDoc.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data();
    DateTime ts;
    final raw = d['recorded_at'];
    if (raw is Timestamp) {
      ts = raw.toDate();
    } else if (raw is String) {
      ts = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      ts = DateTime.now();
    }
    return RecordingDoc(
      id: doc.id,
      awing: (d['awing'] ?? '') as String,
      english: (d['english'] ?? '') as String,
      source: (d['source'] ?? '') as String,
      audioKey: (d['audio_key'] ?? '') as String,
      category: d['category'] as String?,
      recordedByEmail: (d['recorded_by_email'] ?? '') as String,
      recordedByName: (d['recorded_by_name'] ?? '') as String,
      recordedAt: ts,
      device: d['device'] as String?,
      driveUrl: d['drive_url'] as String?,
      durationMs: (d['duration_ms'] as num?)?.toInt(),
      contributionId: d['contribution_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'awing': awing,
        'english': english,
        'source': source,
        'audio_key': audioKey,
        'category': category,
        'recorded_by_email': recordedByEmail,
        'recorded_by_name': recordedByName,
        'recorded_at': recordedAt.toUtc().toIso8601String(),
        'device': device,
        'drive_url': driveUrl,
        'duration_ms': durationMs,
        'contribution_id': contributionId,
      };
}
