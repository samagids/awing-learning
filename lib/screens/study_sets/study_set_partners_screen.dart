import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/models/study_set.dart';
import 'package:awing_ai_learning/services/study_set_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';

/// v1.21.4 (Session 65) — manage the co-owner teacher list on a Study
/// Set. Parallel to `StudySetRosterScreen` (students) but partners can
/// EDIT, RECORD, ADD WORDS — not just view. Only the creator can open
/// this screen for management; partners see themselves listed and can
/// leave via the button, but can't add or remove others.
///
/// Design:
///   - Creator view: text field to add a partner Google email,
///     list of current partners with delete buttons + info note
///   - Partner view: read-only list of teachers + "Leave this set"
///     button that removes the current user from partnerEmails
class StudySetPartnersScreen extends StatefulWidget {
  final String setId;
  const StudySetPartnersScreen({super.key, required this.setId});

  @override
  State<StudySetPartnersScreen> createState() =>
      _StudySetPartnersScreenState();
}

class _StudySetPartnersScreenState extends State<StudySetPartnersScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StudySetService.instance,
      builder: (context, _) {
        return FutureBuilder<StudySet?>(
          future: StudySetService.instance.byId(widget.setId),
          builder: (context, snap) {
            final set = snap.data;
            if (set == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return _buildScaffold(context, set);
          },
        );
      },
    );
  }

  Widget _buildScaffold(BuildContext context, StudySet set) {
    final auth = context.read<AuthService>();
    final currentEmail = auth.currentEmail;
    final isCreator = set.isCreator(currentEmail);
    final isPartner = set.isPartner(currentEmail);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher partners'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.teal.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.groups,
                          color: Colors.teal.shade700, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isCreator
                              ? 'Partner teachers can add words, record '
                                  'audio, edit meanings, and add students '
                                  '— just like you. Only you (the creator) '
                                  'can add or remove partners, or delete '
                                  'the whole set.'
                              : isPartner
                                  ? 'You are a partner teacher on this '
                                      'set. You can add words, record '
                                      'audio, edit meanings, and manage '
                                      'the student roster. Only the '
                                      'creator can add or remove '
                                      'partners.'
                                  : 'You are viewing this set as the '
                                      'creator or partner. If you are a '
                                      'student, ask your teacher to give '
                                      'you access.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.teal.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (isCreator) ...[
                _buildAddPartnerField(context),
                const SizedBox(height: 8),
              ],
              _buildCreatorTile(set),
              const SizedBox(height: 8),
              if (set.partnerEmails.isEmpty)
                _buildEmptyState()
              else
                ...set.partnerEmails.map(
                  (e) => _buildPartnerTile(
                    context,
                    set: set,
                    partnerEmail: e,
                    canRemove: isCreator,
                  ),
                ),
              if (isPartner) ...[
                const SizedBox(height: 24),
                _buildLeaveSetButton(context, set, currentEmail),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddPartnerField(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              labelText: 'Partner teacher Google email',
              hintText: 'teacher@example.com',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.person_add_alt_1),
            ),
            onSubmitted: (_) => _addPartner(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _addPartner,
          icon: const Icon(Icons.add),
          label: const Text('Add'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildCreatorTile(StudySet set) {
    return Card(
      elevation: 1,
      color: Colors.amber.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.amber.shade700,
          child: const Icon(Icons.workspace_premium,
              color: Colors.white),
        ),
        title: Text(
          set.teacherName.isNotEmpty
              ? '${set.teacherName} (creator)'
              : 'Set creator',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(set.teacherEmail),
        trailing: Text(
          'Creator',
          style: TextStyle(
            fontSize: 12,
            color: Colors.amber.shade900,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerTile(
    BuildContext context, {
    required StudySet set,
    required String partnerEmail,
    required bool canRemove,
  }) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.teal,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(partnerEmail),
        subtitle: Text(
          'Partner teacher',
          style: TextStyle(color: Colors.teal.shade700, fontSize: 12),
        ),
        trailing: canRemove
            ? IconButton(
                tooltip: 'Remove partner',
                icon: Icon(Icons.close, color: Colors.red.shade400),
                onPressed: () => _removePartner(set, partnerEmail),
              )
            : null,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Column(
        children: [
          Icon(
            Icons.groups_outlined,
            size: 56,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'No partner teachers yet.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add a fellow teacher\'s Google email above and they will '
            'get the same edit access you have.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveSetButton(
      BuildContext context, StudySet set, String currentEmail) {
    return OutlinedButton.icon(
      onPressed: () => _confirmLeave(context, set, currentEmail),
      icon: Icon(Icons.logout, color: Colors.red.shade400),
      label: Text(
        'Leave this set',
        style: TextStyle(color: Colors.red.shade400),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.red.shade200),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Future<void> _addPartner() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    await StudySetService.instance.addPartner(widget.setId, email);
    _emailController.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $email as a partner teacher.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _removePartner(StudySet set, String partnerEmail) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove partner?'),
        content: Text(
          '$partnerEmail will no longer be able to edit this set.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await StudySetService.instance
        .removePartner(widget.setId, partnerEmail);
  }

  Future<void> _confirmLeave(
      BuildContext context, StudySet set, String currentEmail) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave this set?'),
        content: Text(
          'You will no longer be able to edit "${set.name}". The '
          'creator can add you back later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await StudySetService.instance
        .leavePartneredSet(widget.setId, currentEmail);
    if (!mounted) return;
    // Self-audit fix: only ONE pop — the partners screen is a direct
    // child of the study-set list. Previously popped twice which
    // over-shot the list and landed on the app home screen.
    Navigator.pop(context);
  }
}
