import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/models/user_model.dart';
import 'package:awing_ai_learning/components/parental_gate.dart';
import 'package:awing_ai_learning/components/parent_contacts_editor.dart';
import 'package:awing_ai_learning/utils/pin_text_controller.dart';

class ProfileSelectScreen extends StatefulWidget {
  const ProfileSelectScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSelectScreen> createState() => _ProfileSelectScreenState();
}

class _ProfileSelectScreenState extends State<ProfileSelectScreen> {
  // Rule: every human avatar must be black or brown. Bare emoji (no skin-tone
  // modifier) render yellow/light on most platforms, so each human figure
  // carries an explicit U+1F3FE (medium-dark) or U+1F3FF (dark) modifier.
  static const _avatars = ['🧒🏾', '👧🏾', '👦🏾', '🧒🏿', '👧🏿', '👦🏿', '🧑🏾', '👩🏾', '👨🏾', '🦸🏿', '🧙🏿', '🐯'];

  void _createProfile() {
    final nameController = TextEditingController();
    String selectedAvatar = _avatars[0];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setDialogState) {
            return AlertDialog(
              title: const Text('Add a Learner'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // v1.24.5 — App Review rejected 1.24.4 under
                    // Guideline 4 (Sign in with Apple), reporting that the
                    // app "required users to provide their name after using
                    // Sign in with Apple". The reviewer had signed in with
                    // Hide My Email, landed here, opened this dialog and
                    // read a required field labelled "Name" with the hint
                    // "Enter your name" sitting under their relay address.
                    // From outside the app that is indistinguishable from
                    // being asked to finish setting up an account.
                    //
                    // It is not. It is a learner profile - one per child -
                    // and it is never pre-filled from, written to, or
                    // matched against the Apple account. The account's name
                    // and email come from Authentication Services and are
                    // never asked for again.
                    //
                    // Nothing about the flow changed; the words did. Say on
                    // the dialog itself whose name this is and what it is
                    // for, so no reader has to infer it.
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Add one profile for each child who uses this app. '
                        'Their progress and lessons are kept separately.',
                        style: TextStyle(fontSize: 13.5, height: 1.35),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: "Child's name or nickname",
                        hintText: 'e.g. Ayafor',
                        helperText: 'Shown on their card. Not your account name.',
                        helperMaxLines: 2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Choose a picture for them:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _avatars.map((emoji) {
                        final isSelected = emoji == selectedAvatar;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() => selectedAvatar = emoji);
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? const Color(0xFFE8F5E9)
                                  : Colors.grey.shade100,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF006432)
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: Center(
                              child: Text(emoji, style: const TextStyle(fontSize: 24)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final auth = context.read<AuthService>();
                    final error = auth.createProfile(
                      nameController.text,
                      selectedAvatar,
                    );
                    if (error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error)),
                      );
                    } else {
                      Navigator.pop(ctx);
                      // v1.23.6 — first profile only. This is the one moment
                      // a parent is definitely the one holding the device, so
                      // it is where contact details are asked for. Skippable,
                      // and never shown twice (see the prefs flag inside).
                      if (auth.profiles.length == 1) {
                        maybeShowParentContactsSetup(context);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006432),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create Profile'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        final profiles = auth.profiles;
        final email = auth.currentEmail;

        return PopScope(
          canPop: false,
          child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      'Who is learning today?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF006432),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // "Signed in as" matters more than it looks. A bare
                  // email address printed above a screen with a required
                  // Name field reads as a half-finished account form - which
                  // is how 1.24.4 was rejected. Labelled, it reads as what it
                  // is: the account is already complete, this is who it is.
                  Center(
                    child: Text(
                      'Signed in as $email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Profile grid
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: profiles.length + 1, // +1 for "Add" button
                      itemBuilder: (context, index) {
                        if (index < profiles.length) {
                          return _ProfileCard(
                            profile: profiles[index],
                            onTap: () async {
                              final target = profiles[index];
                              // Only ask for PIN if the target profile has its own PIN set
                              // This lets profiles without a PIN switch freely
                              if (target.hasPin) {
                                final ok = await _showProfilePinDialog(target);
                                if (!ok) return;
                              }
                              if (!context.mounted) return;
                              auth.selectProfile(target.id);
                            },
                            onDelete: profiles.length > 0
                                ? () => _confirmDelete(profiles[index])
                                : null,
                          );
                        } else {
                          return _AddProfileCard(onTap: () async {
                            // Only parents should create new profiles
                            final ok = await ParentalGate.verify(
                              context,
                              title: 'Add a Learner',
                              message: 'Only a parent or guardian should add a child profile.',
                            );
                            if (ok && context.mounted) {
                              _createProfile();
                            }
                          });
                        }
                      },
                    ),
                  ),
                  // PIN + Logout buttons
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            // Parent must verify before accessing PIN settings
                            final ok = await ParentalGate.verify(
                              context,
                              title: 'PIN Settings',
                              message: 'Only a parent or guardian should change the PIN.',
                            );
                            if (ok && context.mounted) {
                              ParentalGate.showSetPinDialog(context);
                            }
                          },
                          icon: Icon(
                            auth.hasAccountPin ? Icons.pin : Icons.pin_outlined,
                            color: const Color(0xFF006432),
                          ),
                          label: Text(
                            auth.hasAccountPin ? 'Change PIN' : 'Set PIN',
                            style: const TextStyle(color: const Color(0xFF006432)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        TextButton.icon(
                          onPressed: () async {
                            final ok = await ParentalGate.verify(
                              context,
                              title: 'Sign Out',
                              message: 'Only a parent or guardian should sign out.',
                            );
                            if (ok && context.mounted) {
                              auth.logout();
                            }
                          },
                          icon: const Icon(Icons.logout, color: Colors.grey),
                          label: const Text(
                            'Sign out',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        );
      },
    );
  }

  Future<bool> _showProfilePinDialog(UserProfile profile) async {
    final controller = PinTextController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Text(profile.avatarEmoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(child: Text('${profile.displayName}\'s PIN')),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 8,
          // Masked by PinTextController, not obscureText: that reveals
          // each character for ~10 frames, which a screen recording keeps.
          autocorrect: false,
          enableSuggestions: false,
          enableIMEPersonalizedLearning: false,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, letterSpacing: 8),
          decoration: InputDecoration(
            labelText: 'Enter PIN (at least 6 digits)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (profile.verifyPin(controller.text)) {
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
            child: const Text('Enter'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _confirmDelete(UserProfile profile) async {
    // Parental gate first
    final ok = await ParentalGate.verify(
      context,
      title: 'Delete Profile',
      message: 'Deleting a profile removes all progress permanently.',
    );
    if (!ok || !mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Profile?'),
        content: Text(
          'Delete "${profile.displayName}"? All progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthService>().deleteProfile(profile.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _ProfileCard({
    required this.profile,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final levelColor = switch (profile.currentLevel) {
      'medium' => Colors.orange,
      'expert' => Colors.red,
      _ => Colors.green,
    };

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profile.avatarEmoji,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 12),
              Text(
                profile.displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  profile.currentLevel.substring(0, 1).toUpperCase() +
                      profile.currentLevel.substring(1),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: levelColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${profile.totalXP} XP',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddProfileCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddProfileCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade300, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Add a Learner',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
