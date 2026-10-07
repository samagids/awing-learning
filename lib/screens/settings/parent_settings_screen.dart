import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/contribution_service.dart';
import 'package:awing_ai_learning/services/parent_notification_service.dart';
import 'package:awing_ai_learning/services/progress_service.dart';
import 'package:awing_ai_learning/models/user_model.dart';
import 'package:awing_ai_learning/components/parent_contacts_editor.dart';
import 'package:awing_ai_learning/screens/settings/backup_screen.dart';
import 'package:awing_ai_learning/services/account_deletion_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awing_ai_learning/utils/pin_text_controller.dart';

/// Settings screen for parents to manage WhatsApp notifications,
/// update their contact info, and send test/weekly summary messages.
class ParentSettingsScreen extends StatefulWidget {
  const ParentSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> {
  late TextEditingController _nameController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final account = context.read<AuthService>().currentAccount;
    _nameController = TextEditingController(text: account?.parentName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    // v1.23.6 — the WhatsApp number moved onto the contact rows, which
    // validate themselves in AuthService. Only the parent's name is left
    // here, so there is nothing to reject.
    context.read<AuthService>().updateParentName(_nameController.text);
    setState(() => _hasChanges = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ==================== Report actions (v1.23.6) ====================
  //
  // Every one of these renders THREE outcomes. The previous version had two,
  // and treated "a browser opened WhatsApp's download page" as delivery.

  void _reportOutcome(ReportResult result, String noun) {
    if (!mounted) return;
    late final String text;
    late final Color colour;
    switch (result) {
      case ReportResult.sent:
        text = 'The $noun was sent.';
        colour = Colors.green;
        break;
      case ReportResult.notSent:
        text = 'The $noun was not sent. Check that a contact has a '
            'confirmed email address.';
        colour = Colors.orange;
        break;
      case ReportResult.unknown:
        // Not an error. Saying "failed" here invites a second send and a
        // duplicate email.
        text = 'We could not confirm whether the $noun went out. '
            'Check the inbox before sending again.';
        colour = Colors.blueGrey;
        break;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: colour,
        duration: const Duration(seconds: 5),
      ),
    );
    setState(() {});
  }

  Future<void> _sendTestReport() async {
    final contrib = context.read<ContributionService>();
    final auth = context.read<AuthService>();
    final account = auth.currentAccount;
    if (account == null) return;

    final child = auth.currentProfile?.displayName ?? 'your child';
    final reply = await contrib.sendParentReport(
      kind: 'test',
      subject: 'test',
      body: 'This is a test report from Awing Learning.\n\n'
          'If you can read this, activity reports for $child will reach '
          'this address.\n\n-- Awing Learning',
      recipients: account.deliverableContacts.map((c) => c.email!).toList(),
    );
    if (!mounted) return;
    if (reply == null) {
      _reportOutcome(ReportResult.unknown, 'test report');
    } else if (reply['status'] == 'success') {
      _reportOutcome(ReportResult.sent, 'test report');
    } else {
      _reportOutcome(ReportResult.notSent, 'test report');
    }
  }

  Future<void> _sendWeeklyNow() async {
    final notifier = context.read<ParentNotificationService>();
    final result = await notifier.sendWeeklySummary();
    _reportOutcome(result, 'weekly summary');
  }

  Future<void> _sendDailyNow() async {
    final notifier = context.read<ParentNotificationService>();
    final result = await notifier.sendDailyReport();
    _reportOutcome(result, 'daily report');
  }

  Future<void> _shareViaWhatsApp(ParentContact contact) async {
    final notifier = context.read<ParentNotificationService>();
    final ok = await notifier.shareViaWhatsApp(
      contact: contact,
      message: notifier.composeShareableReport(),
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'WhatsApp is not installed on this device, so nothing was sent. '
            'The emailed report still works.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  // ==================== Parent Controls ====================

  /// Show a dialog to set or change the parent PIN.
  /// PIN must be at least 6 digits.
  Future<void> _showPinSetupDialog(AuthService auth, bool isChange) async {
    final currentPinController = PinTextController();
    final newPinController = PinTextController();
    final confirmPinController = PinTextController();
    String? errorText;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(isChange ? 'Change Parent PIN' : 'Set Parent PIN'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isChange
                          ? 'Enter your current PIN, then choose a new 6+ digit PIN.'
                          : 'Choose a 6+ digit PIN. You\'ll need it to reset your child\'s progress.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isChange) ...[
                      TextField(
                        controller: currentPinController,
                        keyboardType: TextInputType.number,
                        // Masked by PinTextController, not obscureText: that reveals
                        // each character for ~10 frames, which a screen recording keeps.
                        autocorrect: false,
                        enableSuggestions: false,
                        enableIMEPersonalizedLearning: false,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(12),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Current PIN',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: newPinController,
                      keyboardType: TextInputType.number,
                      // Masked by PinTextController, not obscureText: that reveals
                      // each character for ~10 frames, which a screen recording keeps.
                      autocorrect: false,
                      enableSuggestions: false,
                      enableIMEPersonalizedLearning: false,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(12),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'New PIN (6+ digits)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPinController,
                      keyboardType: TextInputType.number,
                      // Masked by PinTextController, not obscureText: that reveals
                      // each character for ~10 frames, which a screen recording keeps.
                      autocorrect: false,
                      enableSuggestions: false,
                      enableIMEPersonalizedLearning: false,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(12),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Confirm new PIN',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorText!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006432),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final newPin = newPinController.text.trim();
                    final confirmPin = confirmPinController.text.trim();

                    if (isChange) {
                      final currentPin = currentPinController.text.trim();
                      if (!auth.verifyAccountPin(currentPin)) {
                        setDialogState(() {
                          errorText = 'Current PIN is incorrect.';
                        });
                        return;
                      }
                    }
                    if (newPin.length < 6) {
                      setDialogState(() {
                        errorText = 'PIN must be at least 6 digits.';
                      });
                      return;
                    }
                    if (newPin != confirmPin) {
                      setDialogState(() {
                        errorText = 'PINs do not match.';
                      });
                      return;
                    }
                    auth.setAccountPin(newPin);
                    Navigator.pop(ctx, true);
                  },
                  child: Text(isChange ? 'Change PIN' : 'Set PIN'),
                ),
              ],
            );
          },
        );
      },
    );

    currentPinController.dispose();
    newPinController.dispose();
    confirmPinController.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isChange ? 'Parent PIN updated' : 'Parent PIN set'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Verify the parent PIN and, on success, confirm + reset child progress.
  // ==================== Account deletion (5.1.1(v)) ====================

  /// Three screens: what will go, confirm by typing, then progress.
  ///
  /// The parent PIN is required first when one is set, for the same reason
  /// Reset Child Progress requires it — a child who picks up an unlocked
  /// tablet must not be able to destroy the family's account. When no PIN
  /// is set we do NOT force the parent to create one: Apple's guideline
  /// says confirmation steps are fine but customer-service detours are
  /// not, and making someone invent a PIN to leave is a detour. The typed
  /// DELETE confirmation carries that case.
  Future<void> _showDeleteAccountFlow(AuthService auth) async {
    final email = FirebaseAuth.instance.currentUser?.email ?? auth.currentEmail;
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not signed in.')),
      );
      return;
    }

    if (auth.hasAccountPin) {
      final ok = await _verifyParentPin(
        auth,
        'Enter your parent PIN to delete the account.',
      );
      if (ok != true || !mounted) return;
    }

    final profileCount = auth.currentAccount?.profiles.length ?? 0;
    bool keepRecordings = true;

    final confirmController = TextEditingController();
    String? confirmError;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Delete your account?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This permanently deletes the account for $email.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  'What goes:\n'
                  '•  ${profileCount == 1 ? '1 child profile' : '$profileCount child profiles'}, '
                  'with their XP, lessons, quizzes and levels\n'
                  '•  Your parent PIN, guardian contacts and settings\n'
                  '•  Your cloud backup\n'
                  '•  Study sets you created, and your place on any class '
                  'list you were added to',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                // The one genuine choice in this dialog. A donated clip is
                // a contribution to a language with a few thousand
                // speakers, so it is worth asking rather than assuming.
                // Both answers remove the name and address from the
                // recording; the question is only whether the audio stays.
                CheckboxListTile(
                  value: !keepRecordings,
                  onChanged: (v) => setDialogState(() {
                    keepRecordings = !(v ?? false);
                  }),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  title: const Text(
                    'Also delete my recordings from the Awing corpus',
                    style: TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    keepRecordings
                        ? 'Leave this off and your recordings stay to help '
                          'others learn Awing, with your name and email '
                          'removed from them.'
                        : 'Your recordings will be deleted. They will no '
                          'longer be available to anyone learning Awing.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Type DELETE to confirm.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'DELETE',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    if (confirmError != null) {
                      setDialogState(() => confirmError = null);
                    }
                  },
                ),
                if (confirmError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    confirmError!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep my account'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (confirmController.text.trim().toUpperCase() != 'DELETE') {
                  setDialogState(() => confirmError = 'Type DELETE to confirm.');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
    confirmController.dispose();
    if (confirmed != true || !mounted) return;

    // --- run it, showing each stage -------------------------------------
    // Deleting a large account is a dozen round trips. A bare spinner on
    // a destructive action reads as a hang, and a parent who force-quits
    // halfway leaves the job half done.
    String status = 'Starting…';
    // Nullable, not `late`: the first onProgress callback can fire before
    // the dialog's builder has run, and reading an unset `late` throws.
    StateSetter? setProgress;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setter) {
          setProgress = setter;
          return AlertDialog(
            content: Row(
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(status)),
              ],
            ),
          );
        },
      ),
    );

    final result = await AccountDeletionService.instance.deleteAccount(
      keepRecordings: keepRecordings,
      onProgress: (m) {
        status = m;
        try {
          setProgress?.call(() {});
        } catch (_) {
          // Dialog already dismissed; nothing to update.
        }
      },
      reauthenticate: () async {
        final providerId =
            FirebaseAuth.instance.currentUser?.providerData.isNotEmpty == true
                ? FirebaseAuth.instance.currentUser!.providerData.first.providerId
                : '';
        return ReauthHelper.forProvider(providerId);
      },
    );

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // close progress

    if (!result.deleted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Not finished'),
          content: Text(result.message ?? 'The account could not be deleted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Local state last, and through AuthService so there is one writer.
    // This clears the session, which drops the Consumer in main.dart back
    // to the login screen on its own — no navigation from here.
    auth.forgetDeletedAccount(email);

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Account deleted'),
        content: Text(
          result.partialFailures.isEmpty
              ? 'Your account and all of its data have been deleted. '
                'Thank you for helping your family learn Awing.'
              : 'Your account has been deleted. A few items could not be '
                'reached and will be cleared shortly: '
                '${result.partialFailures.join('; ')}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Parent PIN check, shared by deletion. Returns true only on a match.
  Future<bool?> _verifyParentPin(AuthService auth, String reason) async {
    final controller = PinTextController();
    String? error;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Enter Parent PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                reason,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                // Masked by PinTextController, not obscureText: that reveals
                // each character for ~10 frames, which a screen recording keeps.
                autocorrect: false,
                enableSuggestions: false,
                enableIMEPersonalizedLearning: false,
                autofocus: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
                decoration: const InputDecoration(
                  labelText: 'Parent PIN',
                  border: OutlineInputBorder(),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!auth.verifyAccountPin(controller.text)) {
                  setDialogState(() => error = 'Incorrect PIN.');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return ok;
  }

  Future<void> _showResetFlow(AuthService auth) async {
    final profile = auth.currentProfile;
    if (profile == null) return;

    // If no PIN is set, require the parent to set one first.
    if (!auth.hasAccountPin) {
      final setNow = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Set Parent PIN First'),
          content: const Text(
            'You need a parent PIN before resetting a child\'s progress. '
            'Would you like to set one now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not now'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006432),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Set PIN'),
            ),
          ],
        ),
      );
      if (setNow != true || !mounted) return;
      await _showPinSetupDialog(auth, false);
      if (!auth.hasAccountPin) return;
    }

    // Verify the PIN.
    final pinController = PinTextController();
    String? pinError;
    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Enter Parent PIN'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enter your parent PIN to reset ${profile.displayName}\'s progress.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    // Masked by PinTextController, not obscureText: that reveals
                    // each character for ~10 frames, which a screen recording keeps.
                    autocorrect: false,
                    enableSuggestions: false,
                    enableIMEPersonalizedLearning: false,
                    autofocus: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(12),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Parent PIN',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (pinError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      pinError!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (auth.verifyAccountPin(pinController.text.trim())) {
                      Navigator.pop(ctx, true);
                    } else {
                      setDialogState(() {
                        pinError = 'Incorrect PIN.';
                      });
                    }
                  },
                  child: const Text('Verify'),
                ),
              ],
            );
          },
        );
      },
    );
    pinController.dispose();
    if (verified != true || !mounted) return;

    // Destructive confirmation — require typing RESET.
    final confirmController = TextEditingController();
    String? confirmError;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  const Text('Reset Progress?'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This will wipe ${profile.displayName}\'s XP, completed '
                    'lessons, quiz scores, streaks, badges, and level unlocks. '
                    'This cannot be undone.',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Type RESET to confirm:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'RESET',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      if (confirmError != null) {
                        setDialogState(() {
                          confirmError = null;
                        });
                      }
                    },
                  ),
                  if (confirmError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      confirmError!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (confirmController.text.trim().toUpperCase() ==
                        'RESET') {
                      Navigator.pop(ctx, true);
                    } else {
                      setDialogState(() {
                        confirmError = 'Please type RESET exactly.';
                      });
                    }
                  },
                  child: const Text('Reset'),
                ),
              ],
            );
          },
        );
      },
    );
    confirmController.dispose();
    if (confirmed != true || !mounted) return;

    // Perform the reset.
    auth.resetProfileProgress(profile.id);
    await context.read<ProgressService>().resetChildProgress();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${profile.displayName}\'s progress has been reset.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        final account = auth.currentAccount;
        if (account == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Parent Settings')),
            body: const Center(child: Text('Not logged in')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Parent Settings'),
            centerTitle: true,
            backgroundColor: const Color(0xFF006432),
            foregroundColor: Colors.white,
            actions: [
              if (_hasChanges)
                TextButton(
                  onPressed: _save,
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Contact info card
                _SectionCard(
                  title: 'Your Contact Info',
                  icon: Icons.person,
                  child: TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() => _hasChanges = true),
                    decoration: InputDecoration(
                      labelText: 'Parent Name',
                      prefixIcon: const Icon(Icons.person_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _SectionCard(
                  title: 'Who gets the reports',
                  icon: Icons.family_restroom,
                  child: const ParentContactsEditor(
                    introText:
                        'Add up to 3 parents or guardians. Reports are emailed '
                        'to them, so WhatsApp does not need to be installed on '
                        'this device — and the same details can be used on '
                        'every child\'s device.',
                  ),
                ),
                const SizedBox(height: 20),

                // Notification preferences
                _SectionCard(
                  title: 'Notification Preferences',
                  icon: Icons.notifications,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Daily quiz report'),
                        // Deliberately "daily", not "after each quiz". One
                        // email per quiz would exhaust the whole app's mail
                        // allowance within a couple of dozen families.
                        subtitle: const Text(
                          'One email a day listing the quizzes your child '
                          'finished and their scores',
                        ),
                        value: account.sendQuizNotifications,
                        onChanged: account.canDeliverReports
                            ? (v) => auth.setQuizNotifications(v)
                            : null,
                        activeColor: const Color(0xFF006432),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Weekly Summary'),
                        subtitle: const Text(
                          'A weekly report of lessons, quizzes, and streaks',
                        ),
                        value: account.sendWeeklySummary,
                        onChanged: account.canDeliverReports
                            ? (v) => auth.setWeeklySummary(v)
                            : null,
                        activeColor: const Color(0xFF006432),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (!account.canDeliverReports) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.orange.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  account.parentContacts.isEmpty
                                      ? 'Add a parent or guardian above to '
                                          'turn these on.'
                                      : 'Reports start once a contact above '
                                          'has a confirmed email address.',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Actions
                if (account.canDeliverReports) ...[
                  _SectionCard(
                    title: 'Actions',
                    icon: Icons.send,
                    child: Column(
                      children: [
                        ListTile(
                          leading:
                              Icon(Icons.mark_email_read_outlined,
                                  color: Colors.green.shade700),
                          title: const Text('Send a test report'),
                          subtitle: const Text(
                            'Emails a short test to every confirmed contact',
                          ),
                          contentPadding: EdgeInsets.zero,
                          onTap: _sendTestReport,
                        ),
                        const Divider(),
                        ListTile(
                          leading: Icon(Icons.summarize,
                              color: Colors.blue.shade700),
                          title: const Text('Send weekly summary now'),
                          subtitle: const Text(
                            "Send this week's activity report right away",
                          ),
                          contentPadding: EdgeInsets.zero,
                          onTap: _sendWeeklyNow,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Unsent activity. This is no longer a WhatsApp outbox — it
                // is simply the activity recorded since the last delivered
                // daily report.
                Builder(
                  builder: (context) {
                    final notifier = context.read<ParentNotificationService>();
                    if (notifier.pendingEventCount == 0) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionCard(
                          title: 'Not yet reported',
                          icon: Icons.schedule_send,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '${notifier.pendingEventCount} quiz result(s) '
                                'recorded since the last report was delivered.',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: account.canDeliverReports
                                          ? _sendDailyNow
                                          : null,
                                      icon: const Icon(Icons.send),
                                      label: const Text('Send now'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF006432),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton(
                                    onPressed: () {
                                      notifier.clearPendingMessages();
                                      setState(() {});
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('Cleared')),
                                      );
                                    },
                                    child: const Text('Clear'),
                                  ),
                                ],
                              ),
                              if (account.parentContacts
                                  .any((c) => c.hasPlausibleWhatsApp)) ...[
                                const Divider(height: 28),
                                Text(
                                  'Share by WhatsApp instead',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Opens WhatsApp on this device with the '
                                  'report ready to send. Only available where '
                                  'WhatsApp is installed.',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 10),
                                for (final c in account.parentContacts)
                                  if (c.hasPlausibleWhatsApp)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        onPressed: () => _shareViaWhatsApp(c),
                                        icon: const Icon(Icons.share, size: 18),
                                        label: Text(
                                            '${c.label} — ${c.whatsappNumber}'),
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFF006432),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),

                // Parent Controls — PIN + reset child progress
                _SectionCard(
                  title: 'Parent Controls',
                  icon: Icons.shield_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Protect settings with a parent PIN and reset your child\'s learning progress when needed.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: Icon(
                          account.hasAccountPin
                              ? Icons.lock
                              : Icons.lock_open_outlined,
                          color: account.hasAccountPin
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                        title: Text(
                          account.hasAccountPin
                              ? 'Change Parent PIN'
                              : 'Set Parent PIN',
                        ),
                        subtitle: Text(
                          account.hasAccountPin
                              ? 'PIN is set — required to reset progress.'
                              : 'No PIN set — tap to create one.',
                        ),
                        contentPadding: EdgeInsets.zero,
                        onTap: () => _showPinSetupDialog(auth, account.hasAccountPin),
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(
                          Icons.restart_alt,
                          color: Colors.red.shade700,
                        ),
                        title: const Text(
                          'Reset Child Progress',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          auth.currentProfile == null
                              ? 'No profile selected.'
                              : 'Wipe ${auth.currentProfile!.displayName}\'s XP, lessons, quizzes, and level unlocks.',
                        ),
                        contentPadding: EdgeInsets.zero,
                        onTap: auth.currentProfile == null
                            ? null
                            : () => _showResetFlow(auth),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Cloud Backup
                _SectionCard(
                  title: 'Cloud Backup',
                  icon: Icons.cloud_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Back up profiles and progress to your Awing account so data is safe if the app is reinstalled.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BackupScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.cloud_outlined),
                          label: const Text('Manage Cloud Backup'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Delete Account — App Store guideline 5.1.1(v).
                //
                // Must be reachable from inside the app, must actually
                // delete rather than deactivate, and must not route the
                // parent to email or a phone call. It sits last and in red
                // so nobody meets it by accident, but it is a plain button
                // on a screen the parent already visits, not buried.
                _SectionCard(
                  title: 'Delete Account',
                  icon: Icons.person_remove_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Permanently delete your Awing account, every child '
                        'profile on it, and all progress, PINs and settings '
                        'stored for you. This cannot be undone.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showDeleteAccountFlow(auth),
                          icon: const Icon(Icons.delete_forever_outlined),
                          label: const Text('Delete My Account'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Info footer
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    // v1.24.4 — the old line read "No data is stored on
                    // any server", directly above a card offering cloud
                    // backup. Profiles and progress ARE stored, in this
                    // app's cloud database, which is what the Delete
                    // Account button below removes.
                    'Reports are emailed to the guardians you add. '
                    'Profiles and progress are backed up to your Awing '
                    'account and can be deleted at any time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF006432)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
