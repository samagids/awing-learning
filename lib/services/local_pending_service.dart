// local_pending_service.dart
// ---------------------------------------------------------------
// v1.18.0+ — Tracks contributions the current device has SUBMITTED
// recently, so the Record picker (RecordPickerScreen) can hide
// words this person already submitted from their own "still need
// a voice" list.
//
// Why local? The webhook doesn't expose a public "what's currently
// pending review?" endpoint — that would either require auth (which
// kid contributors don't have) or leak other contributors' pending
// work. Local-only tracking solves the immediate UX problem:
// "I already submitted this, don't show it again" — without any
// privacy cost.
//
// Storage: SharedPreferences key `local_pending_submissions` ->
// JSON map of {audio_key: timestamp_ms}. Entries auto-expire after
// 30 days on read (assumes lost / rejected / forgotten if not
// approved within a month — re-appears on the list so the user can
// re-record if they want).
// ---------------------------------------------------------------
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';

class LocalPendingService {
  static const String _kKey = 'local_pending_submissions';

  /// How long a "pending" mark survives in local storage before
  /// expiring. After this window the word reappears on the user's
  /// Record picker — either because review approved it (and it now
  /// has canonical audio, filtered out separately by hasCanonical),
  /// or because the submission was rejected/lost and the user can
  /// re-record if they want.
  static const Duration ttl = Duration(days: 30);

  /// Build the storage key for a word. Uses the same audioKey()
  /// transform as the rest of the audio pipeline so two spellings
  /// of the same word (with vs. without tones) collapse to one
  /// entry.
  static String _keyFor(String awing) =>
      PronunciationService.audioKey(awing);

  /// Mark a word as "I submitted this". Call after a successful
  /// submission from the Record flow. Idempotent — re-marking the
  /// same word just refreshes the timestamp.
  static Future<void> markSubmitted(String awing) async {
    if (awing.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final map = _loadMap(prefs);
    map[_keyFor(awing)] = DateTime.now().millisecondsSinceEpoch;
    await prefs.setString(_kKey, jsonEncode(map));
  }

  /// True if the user submitted this word within the TTL window.
  /// Used by the Record picker to filter the "still needs a voice"
  /// list.
  static Future<bool> isPending(String awing) async {
    if (awing.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final map = _loadMap(prefs);
    final ts = map[_keyFor(awing)];
    if (ts == null) return false;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    return age >= 0 && age < ttl.inMilliseconds;
  }

  /// Return the full set of `audio_key` strings the user has
  /// submitted within the TTL window. Used by RecordPickerScreen to
  /// build the unrecorded filter without N+1 awaits.
  /// Side-effect: prunes expired entries from storage on read.
  static Future<Set<String>> getPendingKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _loadMap(prefs);
    final now = DateTime.now().millisecondsSinceEpoch;
    final cutoff = ttl.inMilliseconds;
    final alive = <String, int>{};
    map.forEach((k, ts) {
      if (ts is int && (now - ts) < cutoff) alive[k] = ts;
    });
    // Prune expired entries persistently.
    if (alive.length != map.length) {
      await prefs.setString(_kKey, jsonEncode(alive));
    }
    return alive.keys.toSet();
  }

  /// Total count of currently-pending submissions by this user.
  static Future<int> pendingCount() async =>
      (await getPendingKeys()).length;

  /// Forget all pending marks. Mostly for testing / Dev Mode reset.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKey);
  }

  static Map<String, dynamic> _loadMap(SharedPreferences prefs) {
    final raw = prefs.getString(_kKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {/* fall through to empty */}
    return {};
  }
}
