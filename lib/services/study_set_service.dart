import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awing_ai_learning/models/study_set.dart';
import 'package:awing_ai_learning/services/study_set_firestore_service.dart';
import 'package:awing_ai_learning/services/study_set_audio_service.dart';
import 'package:awing_ai_learning/services/native_audio_inventory.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';

/// Manages the teacher's collection of StudySets. Session 63 Phase 1:
/// LOCAL ONLY via SharedPreferences. Phase 2 will add Firestore sync
/// alongside — same API from the widget's perspective, sync happens
/// under the hood.
///
/// Storage key: `study_sets_v1` → JSON array of StudySet objects.
class StudySetService extends ChangeNotifier {
  StudySetService._();
  static final StudySetService instance = StudySetService._();

  static const String _prefsKey = 'study_sets_v1';

  final List<StudySet> _sets = [];
  final List<StudySet> _sharedWithMe = [];
  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// Immutable view of the teacher's own sets (sets they created).
  List<StudySet> get ownSets => List.unmodifiable(_sets);

  /// Sets shared with the current user's Google email (student view).
  /// Populated by Firestore stream in refreshSharedFromCloud().
  List<StudySet> get sharedWithMe => List.unmodifiable(_sharedWithMe);

  StreamSubscription<List<StudySet>>? _sharedSub;
  StreamSubscription<List<StudySet>>? _ownSub;

  // ---- Sync diagnostics (surfaced in list screen when empty) ----
  String? _attachedEmail;
  DateTime? _lastSharedEvent;
  DateTime? _lastOwnEvent;
  int _sharedEventCount = 0;
  int _ownEventCount = 0;
  String? _lastSharedError;
  String? _lastOwnError;

  /// Email currently subscribed for Firestore streams. Null if not
  /// attached (student view can display "not signed in").
  String? get attachedEmail => _attachedEmail;
  DateTime? get lastSharedEvent => _lastSharedEvent;
  DateTime? get lastOwnEvent => _lastOwnEvent;
  int get sharedEventCount => _sharedEventCount;
  int get ownEventCount => _ownEventCount;
  String? get lastSharedError => _lastSharedError;
  String? get lastOwnError => _lastOwnError;

  /// Load from SharedPreferences on first call. Idempotent — subsequent
  /// calls return immediately.
  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        _sets
          ..clear()
          ..addAll(
            decoded.map(
              (e) => StudySet.fromJson((e as Map).cast<String, dynamic>()),
            ),
          );
      }
    } catch (e) {
      debugPrint('StudySetService load failed: $e');
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_sets.map((s) => s.toJson()).toList());
      await prefs.setString(_prefsKey, raw);
    } catch (e) {
      debugPrint('StudySetService persist failed: $e');
    }
  }

  /// Create a new set. Returns the created object. Auto-generates
  /// a UUID-like id from timestamp + random-ish suffix (no dependency
  /// on the uuid package to keep the change small).
  Future<StudySet> create({
    required String teacherEmail,
    required String teacherName,
    required String name,
    String description = '',
    String level = 'beginner',
  }) async {
    await load();
    final id = _generateId();
    final set = StudySet(
      id: id,
      // Lowercase the teacher's email so it matches roster convention
      // and case-insensitive Firestore queries/rules.
      teacherEmail: teacherEmail.trim().toLowerCase(),
      teacherName: teacherName,
      name: name.trim(),
      description: description.trim(),
      level: level,
    );
    _sets.add(set);
    await _persist();
    unawaited(_syncOne(set));
    notifyListeners();
    return set;
  }

  Future<StudySet?> byId(String id) async {
    await load();
    for (final s in _sets) {
      if (s.id == id) return s;
    }
    for (final s in _sharedWithMe) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Subscribe to Firestore streams for the given account email. Call
  /// on login and whenever the active account changes. Both streams
  /// keep _sets (own) and _sharedWithMe (shared) hot-synced. Also
  /// captures diagnostic state (event counts + errors) so the UI can
  /// surface why a student's "Shared with me" list is empty.
  Future<void> attachToAccount(String accountEmail) async {
    if (accountEmail.isEmpty) return;
    await load();
    final normalized = accountEmail.trim().toLowerCase();
    _attachedEmail = normalized;
    _lastSharedError = null;
    _lastOwnError = null;
    _sharedEventCount = 0;
    _ownEventCount = 0;
    // Cancel any previous subscriptions.
    await _sharedSub?.cancel();
    await _ownSub?.cancel();
    _sharedSub = StudySetFirestoreService.instance
        .watchSharedSets(normalized)
        .listen(
      (sets) {
        _sharedEventCount++;
        _lastSharedEvent = DateTime.now();
        _sharedWithMe
          ..clear()
          ..addAll(sets);
        notifyListeners();
      },
      onError: (e) {
        _lastSharedError = e.toString();
        debugPrint('StudySetService shared stream error: $e');
        notifyListeners();
      },
    );
    _ownSub = StudySetFirestoreService.instance
        .watchOwnSets(normalized)
        .listen(
      (sets) {
        _ownEventCount++;
        _lastOwnEvent = DateTime.now();
        // Merge cloud sets into local _sets by id. Cloud is source of
        // truth for shared fields; local edits are applied client-side
        // and then synced up.
        for (final cloudSet in sets) {
          final idx = _sets.indexWhere((s) => s.id == cloudSet.id);
          if (idx >= 0) {
            // Preserve locally-scoped fields like locallyDismissed.
            cloudSet.locallyDismissed = _sets[idx].locallyDismissed;
            _sets[idx] = cloudSet;
          } else {
            _sets.add(cloudSet);
          }
        }
        _persist();
        notifyListeners();
      },
      onError: (e) {
        _lastOwnError = e.toString();
        debugPrint('StudySetService own stream error: $e');
        notifyListeners();
      },
    );
    notifyListeners();
  }

  /// One-shot refresh of "Shared with me" sets. Used by the student
  /// "Retry" button on the list screen when the stream hasn't produced
  /// any results. Returns the count of sets seen (0 if none — check
  /// lastSharedError to distinguish "roster empty" from "permission
  /// denied").
  Future<int> refreshSharedFromCloud() async {
    final email = _attachedEmail;
    if (email == null || email.isEmpty) return 0;
    _lastSharedError = null;
    try {
      final sets = await StudySetFirestoreService.instance
          .loadSharedSets(email);
      _sharedEventCount++;
      _lastSharedEvent = DateTime.now();
      _sharedWithMe
        ..clear()
        ..addAll(sets);
      notifyListeners();
      return sets.length;
    } catch (e) {
      _lastSharedError = e.toString();
      notifyListeners();
      return 0;
    }
  }

  Future<void> detachAccount() async {
    await _sharedSub?.cancel();
    await _ownSub?.cancel();
    _sharedSub = null;
    _ownSub = null;
    _attachedEmail = null;
    _sharedWithMe.clear();
    notifyListeners();
  }

  /// Push a single set to Firestore. Fire-and-forget from callers -
  /// failures don't block the local write path. Local is always the
  /// author of truth for the caller's own writes; cloud gets updated
  /// asynchronously.
  Future<void> _syncOne(StudySet set) async {
    try {
      await StudySetFirestoreService.instance.saveSet(set);
    } catch (e) {
      // Already logged inside the Firestore service. Don't rethrow -
      // we don't want a network failure to block the UI.
    }
  }

  /// Rename + description update.
  Future<void> updateMetadata(String setId,
      {String? name, String? description}) async {
    final set = await byId(setId);
    if (set == null) return;
    if (name != null && name.trim().isNotEmpty) set.name = name.trim();
    if (description != null) set.description = description.trim();
    set.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _persist();
    unawaited(_syncOne(set));
    notifyListeners();
  }

  Future<void> deleteSet(String setId) async {
    final removed = _sets.firstWhere(
      (s) => s.id == setId,
      orElse: () => StudySet(
        id: setId,
        teacherEmail: '',
        teacherName: '',
        name: '',
      ),
    );
    _sets.removeWhere((s) => s.id == setId);
    await _persist();
    final teacherEmail = removed.teacherEmail;
    unawaited(() async {
      try {
        await StudySetFirestoreService.instance.deleteSet(setId);
      } catch (_) {}
      // Also wipe cloud audio for the set. Best-effort — a stale
      // storage file is harmless (client only reads what's in
      // set.recordings, and the doc is gone by this point).
      if (teacherEmail.isNotEmpty) {
        try {
          await StudySetAudioService.instance.deleteAllForSet(
            teacherEmail: teacherEmail,
            setId: setId,
          );
        } catch (_) {}
      }
    }());
    notifyListeners();
  }

  // ---- Phase 3: audio recording metadata ----

  /// Record that a word in the set now has an uploaded audio URL.
  /// Called after StudySetAudioService.uploadRecording completes with
  /// a non-null URL. Sync propagates to Firestore automatically so
  /// the student's Firestore stream will see the new recording appear
  /// within a couple of seconds.
  Future<void> setRecording(
      String setId, String awing, String url) async {
    final set = await byId(setId);
    if (set == null) return;
    set.recordings[awing] = url;
    set.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _persist();
    unawaited(_syncOne(set));
    notifyListeners();
  }

  /// Remove a word's recording (used when the teacher re-records to
  /// clear the old URL before uploading, or when a word is removed
  /// from the set).
  Future<void> clearRecording(String setId, String awing) async {
    final set = await byId(setId);
    if (set == null) return;
    set.recordings.remove(awing);
    set.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _persist();
    unawaited(_syncOne(set));
    // Best-effort delete from Firebase Storage.
    if (set.teacherEmail.isNotEmpty) {
      unawaited(StudySetAudioService.instance.deleteRecording(
        teacherEmail: set.teacherEmail,
        setId: setId,
        awing: awing,
      ));
    }
    notifyListeners();
  }

  /// Add a word from the app's dictionary. Silently no-ops if the
  /// key is already in the set (dedup).
  Future<void> addDictionaryWord(String setId, String wordKey) async {
    final set = await byId(setId);
    if (set == null) return;
    if (set.wordKeys.contains(wordKey)) return;
    set.wordKeys.add(wordKey);
    set.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _persist();
    unawaited(_syncOne(set));
    notifyListeners();
  }

  Future<void> removeDictionaryWord(String setId, String wordKey) async {
    final set = await byId(setId);
    if (set == null) return;
    set.wordKeys.remove(wordKey);
    // Removing a word also invalidates its recording. Drop from the
    // map + best-effort delete the Storage object.
    if (set.recordings.remove(wordKey) != null &&
        set.teacherEmail.isNotEmpty) {
      unawaited(StudySetAudioService.instance.deleteRecording(
        teacherEmail: set.teacherEmail,
        setId: setId,
        awing: wordKey,
      ));
    }
    set.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _persist();
    unawaited(_syncOne(set));
    notifyListeners();
  }

  /// Add a custom word (not in app dictionary). Dedup by Awing spelling.
  Future<void> addCustomWord(String setId, StudySetCustomWord word) async {
    final set = await byId(setId);
    if (set == null) return;
    if (set.customWords.any((w) => w.awing == word.awing)) return;
    set.customWords.add(word);
    set.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _persist();
    unawaited(_syncOne(set));
    notifyListeners();
  }

  Future<void> removeCustomWord(String setId, String awing) async {
    final set = await byId(setId);
    if (set == null) return;
    set.customWords.removeWhere((w) => w.awing == awing);
    if (set.recordings.remove(awing) != null &&
        set.teacherEmail.isNotEmpty) {
      unawaited(StudySetAudioService.instance.deleteRecording(
        teacherEmail: set.teacherEmail,
        setId: setId,
        awing: awing,
      ));
    }
    set.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _persist();
    unawaited(_syncOne(set));
    notifyListeners();
  }

  /// Reorder a word within a set. `newIndex` is the target position
  /// AFTER removal of the moved item (standard reorderable list API).
  Future<void> reorderWord(
      String setId, int oldIndex, int newIndex) async {
    final set = await byId(setId);
    if (set == null) return;
    // Words are stored as two arrays: wordKeys followed by customWords.
    // We treat them as a combined logical list for reorder purposes.
    // For Phase 1 simplicity, only support reorder WITHIN wordKeys or
    // WITHIN customWords, not across. Widget prevents cross-drag.
    if (oldIndex < set.wordKeys.length && newIndex <= set.wordKeys.length) {
      final adj = newIndex > oldIndex ? newIndex - 1 : newIndex;
      final item = set.wordKeys.removeAt(oldIndex);
      set.wordKeys.insert(adj, item);
    } else {
      // Custom word reorder (indices relative to customWords).
      final oi = oldIndex - set.wordKeys.length;
      final ni = newIndex - set.wordKeys.length;
      if (oi < 0 || ni < 0) return;
      final adj = ni > oi ? ni - 1 : ni;
      final item = set.customWords.removeAt(oi);
      set.customWords.insert(adj, item);
    }
    set.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _persist();
    unawaited(_syncOne(set));
    notifyListeners();
  }

  /// Set the entire roster of student Google emails on a set.
  /// Duplicates and empty strings filtered out. Emails lowercased so
  /// arrayContains queries match consistently.
  Future<void> setRoster(String setId, List<String> emails) async {
    final set = await byId(setId);
    if (set == null) return;
    final cleaned = <String>{};
    for (final e in emails) {
      final trimmed = e.trim().toLowerCase();
      if (trimmed.isNotEmpty && _looksLikeEmail(trimmed)) {
        cleaned.add(trimmed);
      }
    }
    set.sharedWithEmails
      ..clear()
      ..addAll(cleaned);
    set.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _persist();
    unawaited(_syncOne(set));
    notifyListeners();
  }

  /// Add a single student to the roster.
  Future<void> addToRoster(String setId, String email) async {
    final e = email.trim().toLowerCase();
    if (e.isEmpty || !_looksLikeEmail(e)) return;
    final set = await byId(setId);
    if (set == null) return;
    if (set.sharedWithEmails.contains(e)) return;
    set.sharedWithEmails.add(e);
    set.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _persist();
    unawaited(_syncOne(set));
    notifyListeners();
  }

  /// Remove a single student from the roster.
  Future<void> removeFromRoster(String setId, String email) async {
    final set = await byId(setId);
    if (set == null) return;
    set.sharedWithEmails.remove(email.trim().toLowerCase());
    set.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _persist();
    unawaited(_syncOne(set));
    notifyListeners();
  }

  /// Toggle local dismissal of a shared set on THIS device (for
  /// multi-profile families where one kid isn't in the class this
  /// set is for). Doesn't propagate to Firestore — purely local.
  Future<void> toggleDismiss(String setId) async {
    final all = [..._sets, ..._sharedWithMe];
    StudySet? match;
    for (final s in all) {
      if (s.id == setId) {
        match = s;
        break;
      }
    }
    if (match == null) return;
    match.locallyDismissed = !match.locallyDismissed;
    await _persist();
    notifyListeners();
  }

  // ---- Phase 4: native-audio-aware "effective" recording state ----
  //
  // Words that already have a native recording (Dr. Sama / kids /
  // approved community) are considered "recorded" for a Study Set —
  // students will hear the native audio, and the teacher does NOT
  // need to record over it. These helpers give the UI a single
  // source of truth for "does this word need the teacher to record".

  /// Whether this specific word in a set still needs a recording
  /// from the teacher. False if:
  ///   • teacher already uploaded (set.recordings[awing] non-empty), OR
  ///   • the app ships a native recording for this word.
  bool wordNeedsRecording(StudySet set, String awing) {
    if ((set.recordings[awing] ?? '').isNotEmpty) return false;
    final key = PronunciationService.audioKey(awing);
    if (NativeAudioInventory.instance.hasAnyRecording(key)) return false;
    return true;
  }

  /// True if the word is covered by a native recording (not the
  /// teacher's own upload). Used to render a "Native" badge on the
  /// editor tile so teachers understand why the mic is locked.
  bool wordHasNativeRecording(String awing) {
    final key = PronunciationService.audioKey(awing);
    return NativeAudioInventory.instance.hasAnyRecording(key);
  }

  /// Set is effectively ready to share if every word is either
  /// teacher-uploaded OR natively recorded.
  bool effectivelyFullyRecorded(StudySet set) {
    if (set.wordCount == 0) return false;
    for (final k in set.wordKeys) {
      if (wordNeedsRecording(set, k)) return false;
    }
    for (final w in set.customWords) {
      if (wordNeedsRecording(set, w.awing)) return false;
    }
    return true;
  }

  /// Count of words still needing the teacher to record (excludes
  /// natively covered words).
  int effectiveMissingCount(StudySet set) {
    int missing = 0;
    for (final k in set.wordKeys) {
      if (wordNeedsRecording(set, k)) missing++;
    }
    for (final w in set.customWords) {
      if (wordNeedsRecording(set, w.awing)) missing++;
    }
    return missing;
  }

  bool _looksLikeEmail(String s) {
    // Loose check - just needs one @ and one . after it. Firestore
    // itself will fail on completely bogus strings.
    final at = s.indexOf('@');
    if (at <= 0 || at == s.length - 1) return false;
    return s.substring(at).contains('.');
  }

  String _generateId() {
    final t = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final r = (DateTime.now().millisecond * 1103515245 + 12345)
        .abs()
        .toRadixString(36);
    return 'ss_${t}_$r';
  }
}
