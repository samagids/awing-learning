import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Answers one narrow question: "has this email ever signed in to Awing?"
///
/// Session 64c. Study-set rosters let a teacher type a student's Google
/// address by hand, and a typo silently produces a roster entry that will
/// never match anyone. This service backs the green/amber indicator that
/// catches that.
///
/// === Why a separate collection instead of reading /users ===
///
/// firestore.rules deliberately forbids reading another user's document
/// (`userId == emailKey() || isDeveloper()`), so a teacher cannot look at
/// /users to answer this. Loosening THAT rule would expose every child's
/// progress to any signed-in user, which is far too high a price.
///
/// Instead `registry/{emailKey}` holds a marker document containing NO
/// personal data — just a timestamp. Rules allow:
///   get   — any signed-in user (confirm an address you already know)
///   list  — developer only (so the collection cannot be harvested)
///   write — only your own key
///
/// === The disclosure this accepts, stated plainly ===
///
/// A signed-in user can confirm whether an address they ALREADY KNOW uses
/// Awing. They cannot enumerate or discover addresses. That is the minimum
/// capability the feature needs. If that trade is ever unwanted, delete the
/// `match /registry/...` block from firestore.rules: every lookup then
/// fails, `isKnownUser` returns null, and the UI falls back to a neutral
/// icon with no behaviour change anywhere else.
class UserRegistryService {
  UserRegistryService._();
  static final UserRegistryService instance = UserRegistryService._();

  static const String _collection = 'registry';

  /// MUST mirror CloudBackupService._userDocPath() and firestore.rules
  /// emailKey(). If one changes, all three change together.
  static String emailKey(String email) =>
      email.trim().toLowerCase().replaceAll('.', '_dot_');

  /// Per-session memo. Keeps a roster of 30 students to 30 reads, not 30
  /// reads per rebuild.
  final Map<String, bool> _cache = {};

  /// Record that the signed-in user uses this app.
  ///
  /// Called on every sign-in, not just the first, so the registry
  /// backfills naturally as existing users return. Silent on failure —
  /// this is a convenience index, never load-bearing.
  Future<void> registerSelf(String email) async {
    final key = emailKey(email);
    if (key.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(key)
          .set({
            'lastSeen': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 8));
      _cache[key] = true;
    } catch (e) {
      debugPrint('UserRegistry: registerSelf failed ($e) — ignoring.');
    }
  }

  /// true  = this address has signed in to Awing
  /// false = it has not
  /// null  = we could not tell (offline, timeout, rules denied)
  ///
  /// null is NOT the same as false and callers must not render it as
  /// "unknown user" — see EmailKnownIcon.
  Future<bool?> isKnownUser(String email) async {
    final key = emailKey(email);
    if (key.isEmpty) return null;
    final memo = _cache[key];
    if (memo != null) return memo;
    try {
      final snap = await FirebaseFirestore.instance
          .collection(_collection)
          .doc(key)
          .get()
          .timeout(const Duration(seconds: 8));
      final exists = snap.exists;
      _cache[key] = exists;
      return exists;
    } catch (e) {
      debugPrint('UserRegistry: lookup failed for $key ($e)');
      return null; // unknown, deliberately not false
    }
  }

  /// Developer-only backfill.
  ///
  /// Existing users only enter the registry when they next sign in, so
  /// until then a perfectly valid address shows amber. The developer can
  /// read /users (rules allow it) and seed the registry from it, which
  /// makes the indicator accurate immediately.
  ///
  /// Returns the number of registry documents written.
  Future<int> backfillFromUsers() async {
    try {
      final users =
          await FirebaseFirestore.instance.collection('users').get();
      if (users.docs.isEmpty) return 0;
      var written = 0;
      // Firestore caps a batch at 500 writes.
      var batch = FirebaseFirestore.instance.batch();
      var inBatch = 0;
      for (final d in users.docs) {
        final key = d.id; // already the sanitized email key
        if (key.isEmpty) continue;
        batch.set(
          FirebaseFirestore.instance.collection(_collection).doc(key),
          {'lastSeen': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
        inBatch++;
        written++;
        if (inBatch >= 400) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          inBatch = 0;
        }
      }
      if (inBatch > 0) await batch.commit();
      _cache.clear();
      debugPrint('UserRegistry: backfilled $written entries.');
      return written;
    } catch (e) {
      debugPrint('UserRegistry: backfill failed ($e)');
      return -1;
    }
  }

  void clearCache() => _cache.clear();
}
