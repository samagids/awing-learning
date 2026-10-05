import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/cloud_backup_service.dart';
import 'package:awing_ai_learning/services/contribution_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _error;

  /// Whether to show the Sign in with Apple button on this platform.
  ///
  /// REQUIRED on iOS by App Store Review Guideline 4.8 since we also offer
  /// Google Sign-In. Hidden on Android and other platforms where the
  /// `sign_in_with_apple` package falls back to a web-based flow that we
  /// don't support.
  bool get _showAppleSignIn {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Request both name and email scopes — Apple only returns these on the
      // FIRST sign-in for any given Apple ID + app combination, so capturing
      // them now is the only chance to get the user's display name.
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Exchange Apple credential for Firebase ID token. Firebase resolves the
      // user's email to either their real address or an @privaterelay.appleid.com
      // forwarder if they chose Hide My Email. Either form is stable per user.
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      final firebaseResult = await FirebaseAuth.instance
          .signInWithCredential(oauthCredential);
      final firebaseUser = firebaseResult.user;
      final email = firebaseUser?.email ?? appleCredential.email;
      if (email == null || email.isEmpty) {
        setState(() {
          _error = 'Apple Sign-In did not return an email. Please try again.';
          _isLoading = false;
        });
        return;
      }
      debugPrint('Firebase Auth: signed in via Apple as $email');

      if (!mounted) return;

      // Display name — only present on first sign-in, then null forever after
      // (Apple's design). On second+ sign-ins our existing AuthService account
      // already has the name from before, so this falls through fine.
      final givenName = appleCredential.givenName;
      final familyName = appleCredential.familyName;
      // Not final: when Apple gives us nothing and Firebase has nothing
      // stored, we ask the parent below and fill it in.
      var displayName = [givenName, familyName]
          .where((p) => p != null && p.isNotEmpty)
          .join(' ')
          .trim();

      final auth = context.read<AuthService>();
      final cloud = context.read<CloudBackupService>();

      // v1.23.3 (Session 64): persist the Apple display name onto the
      // Firebase user. Apple returns fullName ONLY on the very first
      // sign-in, and until now we dropped it on the floor — leaving
      // FirebaseAuth.currentUser.displayName permanently null for every
      // Apple account, which broke contributor crediting downstream.
      final existingFbName = firebaseUser?.displayName?.trim() ?? '';
      if (displayName.isNotEmpty && existingFbName.isEmpty) {
        try {
          await firebaseUser?.updateDisplayName(displayName);
        } catch (e) {
          debugPrint('Apple: updateDisplayName failed: $e');
        }
      }

      // v1.23.3 (Session 64): THE fix for "no Apple users in Firestore".
      // CloudBackupService only ever learned about a user through
      // loginGoogleSignIn, which can never see an Apple session. Hand it
      // the session we just created so _isSignedIn / _connectedEmail get
      // set and every sync path stops silently no-op'ing.
      //
      // Must run BEFORE loginWithApple(), because that call triggers
      // _tryCloudRestore() for brand-new accounts and the restore needs
      // _connectedEmail already populated.
      await cloud.adoptFirebaseSession(email: email);

      // v1.24.1 — ask an Apple user for an address we can actually reach,
      // BEFORE the account and its first profile exist.
      //
      // Apple's Hide My Email gives us <random>@privaterelay.appleid.com
      // and no way to resolve it to a real inbox. That address is also the
      // one firestore.rules evaluates as request.auth.token.email, so it
      // MUST stay the identity key — re-keying anything on a typed
      // address would make every write permission-denied. What we collect
      // here is a CONTACT address, used for mail only.
      //
      // Runs before loginWithApple() so a parent who closes the app at the
      // profile screen has still given us a way to reach them.
      if (mounted && _looksLikePrivateRelay(email)) {
        await _promptForContactEmail(context, accountEmail: email);
      }

      // v1.24.2 (Session 66p) — ask for a name when we have none.
      //
      // Apple returns fullName ONLY on the very first authorization. The
      // v1.23.3 code above captures it, but anyone who signed in before
      // that shipped has an empty Firebase displayName and Apple will
      // never hand it over again. The contribution client then falls back
      // to the local profileName, and that is how 'Monto’oh' — a device
      // profile, submitted as 'default Monto’oh' — ended up credited by
      // name on the public About screen.
      //
      // Asking is the only way to recover it for those accounts. Skipping
      // is fine: apply_contributions.py now queues any non-full name for
      // review instead of publishing it.
      if (mounted &&
          displayName.isEmpty &&
          (firebaseUser?.displayName?.trim() ?? '').isEmpty) {
        final typed = await _promptForContributorName(context);
        if (typed != null && typed.isNotEmpty) {
          displayName = typed;
          try {
            await firebaseUser?.updateDisplayName(typed);
          } catch (e) {
            debugPrint('Apple: updateDisplayName (prompted) failed: $e');
          }
        }
      }

      // NOTE: deliberately NO `if (!mounted) return;` here. Returning
      // between adopting the session and creating the local account
      // would leave the user authenticated with Apple but with no
      // AuthService account — they'd be bounced straight back to this
      // screen with no way to tell why. `auth` and `cloud` are already
      // captured, so neither call needs a live BuildContext; only the
      // setState below does, and it is guarded.
      final error = auth.loginWithApple(
        email,
        displayName: displayName.isEmpty ? null : displayName,
        cloudBackup: cloud,
      );

      if (error != null && mounted) {
        setState(() {
          _error = error;
          _isLoading = false;
        });
      }
      // AuthService notifies listeners -> app rebuilds
    } on SignInWithAppleAuthorizationException catch (e) {
      // User cancelled or platform refused (e.g. Apple ID not configured)
      debugPrint('Apple Sign-In authorization error: ${e.code} ${e.message}');
      if (e.code == AuthorizationErrorCode.canceled) {
        setState(() => _isLoading = false);
        return;
      }
      setState(() {
        _error = 'Apple Sign-In failed: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Apple Sign-In error: $e');
      setState(() {
        _error = 'Apple Sign-In failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final gsi = CloudBackupService.loginGoogleSignIn;

      // Try silent sign-in first — picks up existing device account
      // without showing the account picker (no "Add account" option).
      GoogleSignInAccount? account = await gsi.signInSilently();

      // Only show the picker if no account was found silently
      account ??= await gsi.signIn();

      if (account == null) {
        // User cancelled sign-in
        setState(() => _isLoading = false);
        return;
      }

      // Sign into Firebase Auth (required for Firestore security rules)
      final GoogleSignInAuthentication googleAuth =
          await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      debugPrint('Firebase Auth: signed in as ${account.email}');

      if (!mounted) return;

      // Register with our local AuthService
      final auth = context.read<AuthService>();
      final cloud = context.read<CloudBackupService>();

      // v1.23.3 (Session 64): the Google path had the same latent defect
      // as Apple, just better hidden. Nothing here ever told
      // CloudBackupService who had signed in — `_connectedEmail` only
      // got set as a SIDE EFFECT of tryAutoRestore(), which
      // AuthService._loginWithProvider() calls exclusively for
      // brand-new accounts. A returning user who signed out and back in
      // therefore had a null `_connectedEmail` for the rest of that app
      // run, so every backupAll() early-returned until the next cold
      // start. Adopt explicitly on both providers so the state is the
      // same however you signed in.
      await cloud.adoptFirebaseSession(email: account.email);

      // See the note on the Apple path: no early-return here, or we can
      // authenticate the user and then never create their account.
      final error = auth.loginWithGoogle(
        account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
        cloudBackup: cloud,
      );

      if (error != null && mounted) {
        setState(() {
          _error = error;
          _isLoading = false;
        });
      }
      // AuthService notifies listeners -> app rebuilds
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      setState(() {
        _error = 'Google Sign-In failed: $e';
        _isLoading = false;
      });
    }
  }


  /// Did Apple hand us a forwarder instead of a real inbox?
  static bool _looksLikePrivateRelay(String email) =>
      email.toLowerCase().trim().endsWith('@privaterelay.appleid.com');

  /// Ask an Apple "Hide My Email" user for an address we can reach.
  ///
  /// WHY THIS DOES NOT REPLACE THE ACCOUNT EMAIL
  /// firestore.rules derives every document key from
  /// `request.auth.token.email`, which is the relay address. Re-keying
  /// anything on a typed address would make every read and write
  /// permission-denied. So the relay stays the IDENTITY and this is the
  /// CONTACT address — what the server actually mails.
  ///
  /// WHY IT IS VERIFIED RATHER THAN TRUSTED
  /// It is sent through the existing parent-contact flow, which emails a
  /// one-time link and only records the address once its owner clicks it.
  /// Without that, anyone with a minute of access to an unlocked phone
  /// could point this at their own inbox and collect the parent's PIN
  /// reset codes later. The click is what makes it safe to mail secrets
  /// there.
  ///
  /// Skippable on purpose. A parent who dismisses it still gets an
  /// account; they just keep the relay-only delivery they already had,
  /// and Parent Settings can add one later.
  /// Ask an Apple contributor for the name we should credit them under.
  ///
  /// Returns the trimmed name, or null if they skipped. Requires two name
  /// tokens for the same reason apply_contributions.py does: a credit on
  /// the About screen should be a person's name, not a one-word handle.
  Future<String?> _promptForContributorName(BuildContext context) async {
    final controller = TextEditingController();
    final entered = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('What name should we use?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Signing in with Apple did not share your name with us, and '
              'Apple only offers it once, so we cannot ask them again.',
              style: TextStyle(fontSize: 13.5),
            ),
            const SizedBox(height: 10),
            const Text(
              'If you record Awing words for the app, this is the name you '
              'will be credited under on the About screen.',
              style: TextStyle(fontSize: 13.5),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.words,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Your full name',
                hintText: 'Guidion Sama',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = controller.text.trim();
              // Two name tokens, matching _looks_like_a_full_name() in
              // apply_contributions.py. A single word would just be
              // queued for review and never published.
              final parts = v
                  .split(RegExp(r'\s+'))
                  .where((p) => p.replaceAll(RegExp(r'[^A-Za-z]'), '').length > 1);
              if (parts.length >= 2) Navigator.pop(ctx, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final value = entered?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<void> _promptForContactEmail(
    BuildContext context, {
    required String accountEmail,
  }) async {
    final controller = TextEditingController();
    final entered = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Where should we email you?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You signed in with Apple using Hide My Email, so all we have '
              'is $accountEmail — a forwarding address we cannot read.',
              style: const TextStyle(fontSize: 13.5),
            ),
            const SizedBox(height: 10),
            const Text(
              'Give us an address you actually read. We use it for parent '
              'PIN reset codes and activity reports — nothing else.',
              style: TextStyle(fontSize: 13.5),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Your email',
                hintText: 'you@example.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'We will send a short confirmation link to check it works.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = controller.text.trim();
              // Deliberately loose. A real check is the confirmation mail
              // actually arriving; rejecting odd-but-valid addresses here
              // would only lock out the people this exists to help.
              if (v.contains('@') && v.contains('.') && v.length >= 5) {
                Navigator.pop(ctx, v);
              }
            },
            child: const Text('Send link'),
          ),
        ],
      ),
    );

    final value = entered?.trim();
    if (value == null || value.isEmpty) return;

    try {
      final contrib = context.read<ContributionService>();
      final reply = await contrib.requestContactVerification(value);
      if (!context.mounted) return;
      final ok = reply != null && reply['status'] == 'success';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Check $value for a confirmation link.'
              : 'Could not send the confirmation to $value. You can add it '
                  'later under Parent Settings.'),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint('Contact email prompt failed: $e');
      // Never block sign-in on this.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                // Logo area
                Center(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          width: 120,
                          height: 120,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Awing Learning',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF006432),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Learn the Awing Language',
                        style: TextStyle(
                          fontSize: 18,
                          color: const Color(0xFFDAA520),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Spoken by 19,000 people in Cameroon',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                // Error message
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                // Google Sign-In button
                SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        // Session 64 (H5): was Image.network to
                        // developers.google.com/identity/images/g-logo.png.
                        // That hit the network on EVERY app launch, costing
                        // metered data for Cameroonian users and left the
                        // login screen half-broken on flaky first-launches.
                        // Now uses an offline-safe Material icon. If we
                        // ever need brand-perfect Google G branding, drop
                        // assets/images/google_g.png in and switch to
                        // Image.asset.
                        : const Icon(
                            Icons.account_circle,
                            size: 24,
                            color: Color(0xFF4285F4), // Google brand blue
                          ),
                    label: Text(
                      _isLoading ? 'Signing in...' : 'Sign in with Google',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                  ),
                ),
                if (_showAppleSignIn) ...[
                  const SizedBox(height: 12),
                  // Sign in with Apple — required by App Store Review Guideline
                  // 4.8 since Google Sign-In is also offered. Apple HIG also
                  // requires this exact button styling: black background, white
                   // logo + text, "Sign in with Apple" wording.
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _signInWithApple,
                      icon: const Icon(Icons.apple, size: 28, color: Colors.white),
                      label: const Text(
                        'Sign in with Apple',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Parent: sign in with your Google account.\nThen create profiles for your kids to use.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
