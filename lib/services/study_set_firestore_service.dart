import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:awing_ai_learning/models/study_set.dart';

/// Firestore layer for Study Sets. Session 63 Phase 2.
///
/// Collection: `study_sets/{setId}` (top-level, not nested under user)
/// so a student can query "sets where sharedWithEmails contains me"
/// with a single arrayContains query.
///
/// Security model (rules must be published to Firebase Console):
///
///   match /study_sets/{setId} {
///     allow read: if request.auth != null &&
///       (resource.data.teacherEmail == request.auth.token.email ||
///        request.auth.token.email in resource.data.sharedWithEmails);
///     allow create: if request.auth != null &&
///       request.resource.data.teacherEmail == request.auth.token.email;
///     allow update, delete: if request.auth != null &&
///       resource.data.teacherEmail == request.auth.token.email;
///   }
///
/// Deployment: paste those rules into Firebase Console → Firestore →
/// Rules. Deployment is a manual step after v1.20 ships — see
/// CLAUDE.md Session 63.
class StudySetFirestoreService {
  StudySetFirestoreService._();
  static final StudySetFirestoreService instance =
      StudySetFirestoreService._();

  static const String _collection = 'study_sets';

  CollectionReference<Map<String, dynamic>> get _coll =>
      FirebaseFirestore.instance.collection(_collection);

  /// Upsert a set. Overwrites the entire document (fine because sets
  /// are small — a few hundred words max, well under Firestore's 1MB
  /// document limit).
  Future<void> saveSet(StudySet set) async {
    try {
      final data = set.toJson();
      // Firestore doesn't need the locally-scoped `locallyDismissed`
      // field — that's per-device UI state.
      data.remove('locallyDismissed');
      await _coll.doc(set.id).set(data, SetOptions(merge: false));
    } catch (e) {
      debugPrint('StudySetFirestoreService saveSet failed: $e');
      rethrow;
    }
  }

  /// Delete a set from Firestore. Only owner can call (rules enforce).
  Future<void> deleteSet(String setId) async {
    try {
      await _coll.doc(setId).delete();
    } catch (e) {
      debugPrint('StudySetFirestoreService deleteSet failed: $e');
      rethrow;
    }
  }

  /// Sets the current user owns (they're the teacher). Used to hydrate
  /// the local cache on a fresh install / new device.
  Future<List<StudySet>> loadOwnSets(String teacherEmail) async {
    try {
      final snap = await _coll
          .where('teacherEmail', isEqualTo: teacherEmail)
          .get();
      return snap.docs
          .map((d) => StudySet.fromJson(d.data()))
          .toList();
    } catch (e) {
      debugPrint('StudySetFirestoreService loadOwnSets failed: $e');
      return [];
    }
  }

  /// Sets shared WITH the given email (student view). arrayContains
  /// is case-sensitive so we lowercase both the query and (client-side)
  /// the roster values. Rules ALSO lowercase both sides.
  Future<List<StudySet>> loadSharedSets(String studentEmail) async {
    final email = studentEmail.trim().toLowerCase();
    try {
      final snap = await _coll
          .where('sharedWithEmails', arrayContains: email)
          .get();
      return snap.docs
          .map((d) => StudySet.fromJson(d.data()))
          .toList();
    } catch (e) {
      debugPrint('StudySetFirestoreService loadSharedSets failed: $e');
      return [];
    }
  }

  /// Live stream of sets shared with the given email. arrayContains
  /// is case-sensitive; roster is stored lowercased by
  /// StudySetService.addToRoster so we mirror that here.
  Stream<List<StudySet>> watchSharedSets(String studentEmail) {
    final email = studentEmail.trim().toLowerCase();
    try {
      return _coll
          .where('sharedWithEmails', arrayContains: email)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => StudySet.fromJson(d.data()))
              .toList());
    } catch (e) {
      debugPrint('StudySetFirestoreService watchSharedSets failed: $e');
      return Stream.value(<StudySet>[]);
    }
  }

  /// Live stream of sets owned by the given teacher email. Keeps the
  /// teacher's own list in sync across their devices. Lowercased for
  /// the same case-sensitivity reason as the roster query.
  Stream<List<StudySet>> watchOwnSets(String teacherEmail) {
    final email = teacherEmail.trim().toLowerCase();
    try {
      return _coll
          .where('teacherEmail', isEqualTo: email)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => StudySet.fromJson(d.data()))
              .toList());
    } catch (e) {
      debugPrint('StudySetFirestoreService watchOwnSets failed: $e');
      return Stream.value(<StudySet>[]);
    }
  }

  /// v1.21.4 (Session 65): sets where this email is a partner teacher
  /// (co-owner). Mirrors watchOwnSets structure so the service can
  /// merge both into a single "my sets" list.
  Stream<List<StudySet>> watchPartneredSets(String partnerEmail) {
    final email = partnerEmail.trim().toLowerCase();
    try {
      return _coll
          .where('partnerEmails', arrayContains: email)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => StudySet.fromJson(d.data()))
              .toList());
    } catch (e) {
      debugPrint('StudySetFirestoreService watchPartneredSets failed: $e');
      return Stream.value(<StudySet>[]);
    }
  }

  /// One-shot load of partnered sets (Session 65) — used for the
  /// "Retry from cloud" affordance in the list screen.
  Future<List<StudySet>> loadPartneredSets(String partnerEmail) async {
    final email = partnerEmail.trim().toLowerCase();
    try {
      final snap = await _coll
          .where('partnerEmails', arrayContains: email)
          .get();
      return snap.docs
          .map((d) => StudySet.fromJson(d.data()))
          .toList();
    } catch (e) {
      debugPrint('StudySetFirestoreService loadPartneredSets failed: $e');
      return [];
    }
  }
}
