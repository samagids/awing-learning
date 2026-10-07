import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:awing_ai_learning/services/cloud_backup_service.dart';
import 'package:awing_ai_learning/services/user_registry_service.dart';

/// Permanently deletes a parent account and everything attached to it.
///
/// WHY THIS EXISTS
/// ---------------
/// App Store Review guideline 5.1.1(v): an app that supports account
/// creation must offer account deletion from inside the app. Version
/// 1.24.3 was rejected on 2026-10-07 for not having it. Offering only to
/// deactivate, or telling the user to email someone, does not satisfy the
/// guideline.
///
/// WHAT A PARENT ACCOUNT ACTUALLY TOUCHES
/// --------------------------------------
/// Every surface below was found by reading the code and firestore.rules,
/// not assumed. If a new per-user collection is ever added, it belongs in
/// this list too, or deletion silently stops being complete.
///
///   Firestore
///     users/{emailKey}/data/accounts   profiles, hashed PINs
///     users/{emailKey}/data/progress   XP, lessons, quizzes, streaks
///     users/{emailKey}/data/settings   preferences AND the FCM push token
///     users/{emailKey}                 the parent doc itself
///     registry/{emailKey}              "this address uses Awing" marker
///     study_sets/*                     sets this user created
///     study_sets/*                     OTHER people's sets whose roster
///                                      or partner list names this user
///     recordings/*                     clips this user donated, which
///                                      carry recorded_by_email and
///                                      recorded_by_name
///
///   Firebase Auth                      the user record itself
///   SharedPreferences                  the local account, profiles and
///                                      session pointers
///
/// THE TWO DONATED-RECORDING PATHS
/// -------------------------------
/// Recordings are different from everything else here: they are a
/// contribution to a language with a few thousand speakers, and the clip
/// itself is not really "the user's data" in the way their child's quiz
/// scores are. So the dialog asks, and BOTH answers remove the personal
/// data:
///
///   keep    -> the clip stays in the corpus, but recorded_by_email and
///              recorded_by_name are cleared. Nothing identifying survives.
///   remove  -> the documents are deleted outright.
///
/// Leaving the email on a "kept" clip was never an option. The choice the
/// parent is making is about the audio, not about their identity.
///
/// ORDER MATTERS
/// -------------
/// Every Firestore rule in this app keys off request.auth.token.email, so
/// all remote deletion happens while still signed in. The Firebase Auth
/// user is destroyed LAST. If the process dies halfway the user is still
/// signed in and can run it again; destroying auth first would strand the
/// remaining documents with no one on earth able to delete them.
class AccountDeletionService {
  AccountDeletionService._();
  static final AccountDeletionService instance = AccountDeletionService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Deletes the signed-in account.
  ///
  /// [keepRecordings] true leaves the donated clips in the corpus with
  /// their attribution stripped; false deletes those documents.
  ///
  /// [onProgress] is called with a short human sentence before each stage
  /// so the dialog can show what is happening. Deletion of a large account
  /// is a dozen round trips and a silent spinner looks broken.
  ///
  /// [reauthenticate] is called only if Firebase refuses the final step
  /// with `requires-recent-login`. It must re-run the provider sign-in and
  /// return the fresh credential, or null if the user backed out.
  Future<AccountDeletionResult> deleteAccount({
    required bool keepRecordings,
    void Function(String message)? onProgress,
    Future<AuthCredential?> Function()? reauthenticate,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      return AccountDeletionResult.failure(
        'You are not signed in, so there is no account to delete.',
      );
    }

    final emailKey = UserRegistryService.emailKey(email);
    final lower = email.toLowerCase();
    final failures = <String>[];

    // --- 1. Study sets this user created -------------------------------
    // Deleted outright. firestore.rules allows delete only to the creator,
    // which is exactly who is standing here.
    onProgress?.call('Removing your study sets…');
    try {
      final owned = await _db
          .collection('study_sets')
          .where('teacherEmail', isEqualTo: lower)
          .get();
      for (final doc in owned.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      failures.add('study sets you created ($e)');
    }

    // --- 2. Other people's sets that name this user ---------------------
    // A teacher's roster holds student addresses verbatim. Those are this
    // user's personal data sitting in someone else's document, so they
    // come out too. Only the caller's own address is touched.
    onProgress?.call('Taking you off other teachers\' class lists…');
    for (final field in const ['sharedWithEmails', 'partnerEmails']) {
      try {
        final snap = await _db
            .collection('study_sets')
            .where(field, arrayContains: lower)
            .get();
        for (final doc in snap.docs) {
          await doc.reference.update({
            field: FieldValue.arrayRemove([lower]),
          });
        }
      } catch (e) {
        failures.add('class lists you were on ($e)');
      }
    }

    // --- 3. Donated recordings -----------------------------------------
    onProgress?.call(keepRecordings
        ? 'Removing your name from your recordings…'
        : 'Deleting your recordings…');
    try {
      final mine = await _db
          .collection('recordings')
          .where('recorded_by_email', isEqualTo: email)
          .get();
      for (final doc in mine.docs) {
        if (keepRecordings) {
          // Keep the audio, drop the person. The update rule checks the
          // EXISTING doc's recorded_by_email against the caller, so
          // clearing the field is allowed; a second pass would not be,
          // which is fine because there is nothing left to clear.
          await doc.reference.update({
            'recorded_by_email': '',
            'recorded_by_name': 'Anonymous contributor',
            'anonymised_at': FieldValue.serverTimestamp(),
          });
        } else {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      failures.add('your recordings ($e)');
    }

    // --- 4. The sign-in registry marker ---------------------------------
    onProgress?.call('Clearing your sign-in record…');
    try {
      await _db.collection('registry').doc(emailKey).delete();
    } catch (e) {
      failures.add('your sign-in record ($e)');
    }

    // --- 5. Cloud backup ------------------------------------------------
    // The data subcollection first, then the parent doc. Firestore does
    // not cascade: deleting users/{emailKey} on its own would orphan the
    // three documents underneath it, where the profiles, the progress and
    // the push token actually live.
    onProgress?.call('Deleting your profiles and progress…');
    try {
      final base = _db.collection('users').doc(emailKey);
      for (final docType in const ['accounts', 'progress', 'settings']) {
        await base.collection('data').doc(docType).delete();
      }
      await base.delete();
    } catch (e) {
      failures.add('your backed-up profiles and progress ($e)');
    }

    // --- 6. The Firebase Auth user --------------------------------------
    // Last, and the only step whose failure stops the whole thing being
    // reported as done: everything above is gone, but the account could
    // still be signed into.
    onProgress?.call('Closing your account…');
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login' && reauthenticate != null) {
        // Firebase refuses to delete a user whose session is more than a
        // few minutes old. This is not an error to report - it is a
        // normal, expected branch, and the only correct response is to
        // ask the provider for a fresh credential and try once more.
        onProgress?.call('Please confirm it is you…');
        try {
          final fresh = await reauthenticate();
          if (fresh == null) {
            return AccountDeletionResult.failure(
              'Your data has been deleted, but closing the account needs '
              'you to sign in once more. Sign in again and tap Delete '
              'Account to finish.',
            );
          }
          await user.reauthenticateWithCredential(fresh);
          await user.delete();
        } catch (e2) {
          return AccountDeletionResult.failure(
            'Your data has been deleted, but the account itself could not '
            'be closed ($e2). Sign in again and tap Delete Account to '
            'finish.',
          );
        }
      } else {
        return AccountDeletionResult.failure(
          'Your data has been deleted, but the account itself could not be '
          'closed (${e.code}). Sign in again and tap Delete Account to '
          'finish.',
        );
      }
    }

    // --- 7. This device --------------------------------------------------
    // Local state is NOT touched here. AuthService owns `auth_accounts`
    // and holds the decoded map in memory; a second writer would be the
    // same two-sources-of-truth bug that made a cloud restore show stale
    // profiles until the next cold start. The caller finishes with
    // AuthService.forgetDeletedAccount(), which removes the entry, drops
    // the session and notifies, so the Consumer in main.dart falls back
    // to the login screen on its own.
    onProgress?.call('Clearing this device…');
    try {
      await CloudBackupService.loginGoogleSignIn.signOut();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    if (failures.isNotEmpty) {
      // debugPrint, not print: the analyzer's avoid_print fires on the
      // latter, and debugPrint is already a no-op in release builds, so
      // the kDebugMode guard is redundant too.
      debugPrint('AccountDeletionService: partial failures: $failures');
    }

    return AccountDeletionResult.success(partialFailures: failures);
  }

}

/// Outcome of a deletion attempt.
///
/// `partialFailures` is not the same as failure. If the study-set sweep
/// threw but the account itself was closed, the user IS deleted and must
/// be told so; the stragglers are named so a support reply can be
/// specific rather than apologetic.
class AccountDeletionResult {
  final bool deleted;
  final String? message;
  final List<String> partialFailures;

  const AccountDeletionResult._({
    required this.deleted,
    this.message,
    this.partialFailures = const [],
  });

  factory AccountDeletionResult.success({
    List<String> partialFailures = const [],
  }) =>
      AccountDeletionResult._(deleted: true, partialFailures: partialFailures);

  factory AccountDeletionResult.failure(String message) =>
      AccountDeletionResult._(deleted: false, message: message);
}

/// Re-runs the provider sign-in to satisfy Firebase's recent-login rule.
///
/// Lives here rather than in the login screen because deletion is the only
/// caller that needs a credential WITHOUT also establishing a session.
class ReauthHelper {
  static Future<AuthCredential?> forProvider(String providerId) async {
    if (providerId.contains('google')) {
      final gsi = CloudBackupService.loginGoogleSignIn;
      final GoogleSignInAccount? account = await gsi.signIn();
      if (account == null) return null;
      final auth = await account.authentication;
      return GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
    }
    if (providerId.contains('apple')) {
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email],
      );
      return OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        accessToken: apple.authorizationCode,
      );
    }
    return null;
  }
}
