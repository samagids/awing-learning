import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/contribution_service.dart';

/// Parental gate that protects destructive actions from kids.
///
/// Two modes:
/// 1. If the account has a PIN set → asks for the account PIN (at least 6 digits)
/// 2. If no PIN set → asks a simple math problem (e.g. "What is 7 + 5?")
///
/// Use [ParentalGate.verify] to show the gate and get a bool result.
class ParentalGate {
  /// Session 64 (H14): 5-minute cache. Without this, home_screen.dart's
  /// contribute/teacher/developer flows re-prompted on every tap and
  /// parents got annoyed enough to give kids the math answer. With this,
  /// one successful unlock keeps the session flowing for 5 minutes then
  /// re-locks. Static so it survives across widget rebuilds inside a
  /// single app session; NOT persisted to disk — restarting the app or
  /// backgrounding for >5 minutes forces a fresh unlock.
  static DateTime? _lastVerifiedAt;
  static const Duration _cacheTtl = Duration(minutes: 5);

  static bool get _cacheStillValid {
    final at = _lastVerifiedAt;
    if (at == null) return false;
    return DateTime.now().difference(at) < _cacheTtl;
  }

  /// Called by the auth service on sign-out and profile switch so the
  /// cache doesn't survive a change of hands.
  static void invalidateCache() {
    _lastVerifiedAt = null;
  }

  /// Show a parental gate dialog. Returns true if the parent/adult passes.
  static Future<bool> verify(
    BuildContext context, {
    String title = 'Parent Verification',
    String message = 'This action requires a parent or guardian.',
  }) async {
    // Session 64 (H14): 5-minute cache. Skip the dialog entirely if the
    // parent recently unlocked.
    if (_cacheStillValid) return true;

    final auth = context.read<AuthService>();
    final ok = auth.hasAccountPin
        ? await _showPinGate(context, auth, title: title, message: message)
        : await _showMathGate(context, title: title, message: message);
    if (ok) {
      _lastVerifiedAt = DateTime.now();
    }
    return ok;
  }

  /// PIN-based gate — asks for the account PIN (at least 6 digits).
  static Future<bool> _showPinGate(
    BuildContext context,
    AuthService auth, {
    required String title,
    required String message,
  }) async {
    final controller = TextEditingController();
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock, color: const Color(0xFF006432)),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 8,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, letterSpacing: 8),
              decoration: InputDecoration(
                labelText: 'Enter PIN (at least 6 digits)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.pin),
              ),
            ),
          ],
        ),
        actions: [
          // v1.23.6 (Session 64e): a forgotten PIN used to be an absolute
          // lockout — the gate guards PIN Settings, changing the PIN needs
          // the old PIN, and signing out needs it too. And because
          // accountPin round-trips through the cloud backup, reinstalling
          // restored the PIN along with everything else.
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx, false);
              await _showForgotPinFlow(context, auth);
            },
            child: const Text('Forgot PIN?'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (auth.verifyAccountPin(controller.text)) {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Incorrect PIN'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Math-based gate — asks an arithmetic question that young kids
  /// typically can't solve but adults can.
  /// Session 64 (H14): bumped from single-digit addition (8-26 range,
  /// most 8-year-olds solve this) to 2-digit × 1-digit multiplication.
  /// A typical 8-year-old cannot do this quickly; a parent can.
  static Future<bool> _showMathGate(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final random = Random();
    final a = random.nextInt(20) + 11; // 11-30
    final b = random.nextInt(8) + 2;   // 2-9
    final answer = a * b;
    final controller = TextEditingController();

    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.calculate, color: const Color(0xFF006432)),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 12),
            Text(
              'To continue, solve this:',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              'What is $a × $b?',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24),
              decoration: InputDecoration(
                hintText: '?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim() == answer.toString()) {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Incorrect answer, try again'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Show a dialog to set or change the account PIN.
  /// If a PIN already exists, the user must enter the current PIN first.

  /// Forgot-PIN recovery (v1.23.6, Session 64e).
  ///
  /// Emails a 6-digit code to the address Google/Apple says owns this
  /// account, then clears the PIN when it is entered back. The app never
  /// tells the server WHERE to send — it sends a Firebase ID token and
  /// the server mails the verified owner, so this cannot be pointed at
  /// anyone else's inbox.
  static Future<void> _showForgotPinFlow(
    BuildContext context,
    AuthService auth,
  ) async {
    final code = (100000 + Random.secure().nextInt(900000)).toString();
    final contrib = context.read<ContributionService>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Sending reset code…')),
          ],
        ),
      ),
    );

    final reply = await contrib.requestPinReset(code);
    if (!context.mounted) return;
    Navigator.pop(context); // dismiss spinner

    final status = reply == null ? null : reply['status'];
    final msg = reply == null ? '' : (reply['message']?.toString() ?? '');
    // v1.24.1: the server now says WHERE it sent, masked. Without this the
    // dialog said "the address this account is signed in with", which an
    // Apple "Hide My Email" user cannot act on — their address is a
    // relay they have never seen. First real report of this was a parent
    // saying the app kept claiming a code was sent and nothing arrived.
    final sentTo = reply == null ? '' : (reply['sentTo']?.toString() ?? '');
    final viaRelay = reply != null && reply['privateRelay'] == true;

    if (reply != null && msg == 'not-signed-in') {
      await _info(context, 'Sign in first',
          'To reset the PIN we need to confirm you own this account. '
          'Sign in with Google or Apple, then try again.');
      return;
    }
    if (reply != null && status == 'error' && msg == 'too many requests') {
      await _info(context, 'Too many attempts',
          'Several reset codes have already been sent in the last hour. '
          'Please check your email, or wait and try again.');
      return;
    }
    if (reply != null && status == 'error') {
      await _info(context, 'Could not send',
          'The reset code could not be sent ($msg). Please try again.');
      return;
    }
    // reply == null means we could not READ the answer. The mail may well
    // have gone out, so do NOT claim failure — offer the code entry.
    if (reply == null) {
      await _info(context, 'Check your email',
          'We could not confirm the send, but the code was most likely '
          'emailed to you. Check your inbox, then enter it on the next '
          'screen.');
    }

    if (!context.mounted) return;
    final entered = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter reset code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sentTo.isEmpty
                  ? 'We emailed a 6-digit code to the address this account '
                      'is signed in with. Enter it to clear the parent PIN.'
                  : 'We emailed a 6-digit code to $sentTo. Enter it to '
                      'clear the parent PIN.',
            ),
            if (viaRelay) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Text(
                  'That is an Apple "Hide My Email" address. Apple forwards '
                  'it to your real inbox — check there, including spam. If '
                  'nothing arrives, open Settings > your name > Sign in '
                  'with Apple > Awing Learning and check the forwarding '
                  'address is one you still read.',
                  style: TextStyle(fontSize: 12.5),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: entered,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, letterSpacing: 8),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (entered.text.trim() == code) {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Incorrect code'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Clear PIN'),
          ),
        ],
      ),
    );
    entered.dispose();

    if (ok == true) {
      auth.removeAccountPin();
      invalidateCache();
      if (!context.mounted) return;
      await _info(context, 'PIN cleared',
          'The parent PIN has been removed. You can set a new one from '
          'the profile screen.');
    }
  }

  static Future<void> _info(
      BuildContext context, String title, String body) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Future<void> showSetPinDialog(BuildContext context) async {
    final auth = context.read<AuthService>();

    // If changing an existing PIN, verify the current one first
    if (auth.hasAccountPin) {
      final currentPinController = TextEditingController();
      final verified = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock, color: Color(0xFF006432)),
              SizedBox(width: 8),
              Text('Verify Current PIN'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your current PIN to change it.'),
              const SizedBox(height: 16),
              TextField(
                controller: currentPinController,
                keyboardType: TextInputType.number,
                maxLength: 8,
                obscureText: true,
                textAlign: TextAlign.center,
                autofocus: true,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  labelText: 'Current PIN',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (auth.verifyAccountPin(currentPinController.text)) {
                  Navigator.pop(ctx, true);
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Incorrect PIN'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (verified != true || !context.mounted) return;
    }

    final controller = TextEditingController();
    final confirmController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.pin, color: Color(0xFF006432)),
            const SizedBox(width: 8),
            Text(auth.hasAccountPin ? 'New PIN' : 'Set PIN'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              auth.hasAccountPin
                  ? 'Enter your new PIN (at least 6 digits).'
                  : 'Set a PIN (at least 6 digits) to protect sign-out and profile deletion. '
                    'Only share this with parents/guardians.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 8,
              obscureText: true,
              textAlign: TextAlign.center,
              autofocus: true,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                labelText: 'New PIN',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              keyboardType: TextInputType.number,
              maxLength: 8,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                labelText: 'Confirm PIN',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (auth.hasAccountPin)
            TextButton(
              onPressed: () async {
                // Confirm removal — require current PIN first
                final pinController = TextEditingController();
                final confirmed = await showDialog<bool>(
                  context: ctx,
                  builder: (ctx2) => AlertDialog(
                    title: const Text('Remove PIN?'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Enter your current PIN to remove it.'),
                        const SizedBox(height: 16),
                        TextField(
                          controller: pinController,
                          keyboardType: TextInputType.number,
                          maxLength: 8,
                          obscureText: true,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, letterSpacing: 8),
                          decoration: InputDecoration(
                            labelText: 'Current PIN',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx2, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          if (auth.verifyAccountPin(pinController.text)) {
                            Navigator.pop(ctx2, true);
                          } else {
                            ScaffoldMessenger.of(ctx2).showSnackBar(
                              const SnackBar(
                                content: Text('Incorrect PIN'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  auth.removeAccountPin();
                  if (ctx.mounted) Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN removed')),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove PIN'),
            ),
          ElevatedButton(
            onPressed: () {
              final pin = controller.text.trim();
              final confirm = confirmController.text.trim();
              if (pin.length < 6) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('PIN must be at least 6 digits'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (pin != confirm) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('PINs do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              auth.setAccountPin(pin);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PIN set successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
