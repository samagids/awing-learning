import 'package:flutter/material.dart';
import 'package:awing_ai_learning/models/study_set.dart';
import 'package:awing_ai_learning/services/study_set_service.dart';
import 'package:awing_ai_learning/widgets/email_known_icon.dart';

/// Manage the roster of student Google emails on a Study Set.
/// Session 63 Phase 2.
///
/// Design:
///   - Text field to add one email at a time
///   - Or "Paste bulk emails" area (comma / newline separated)
///   - List of current roster with delete swipes
///   - Info: multi-profile families see the set on every kid's
///     profile; each kid can dismiss individually
class StudySetRosterScreen extends StatefulWidget {
  final String setId;
  const StudySetRosterScreen({super.key, required this.setId});

  @override
  State<StudySetRosterScreen> createState() => _StudySetRosterScreenState();
}

class _StudySetRosterScreenState extends State<StudySetRosterScreen> {
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Roster'),
      ),
      body: Column(
        children: [
          _buildHeader(context, set, theme),
          _buildAudioGate(context, set),
          const Divider(height: 1),
          _buildAddBar(context, set),
          Expanded(child: _buildRosterList(context, set)),
        ],
      ),
    );
  }

  /// Share-gate warning banner. Students will see the set as soon as
  /// their email is on the roster, but until every word has audio the
  /// experience is incomplete. Warn the teacher but don't block them —
  /// they may want to add the roster in advance and record later.
  Widget _buildAudioGate(BuildContext context, StudySet set) {
    if (set.wordCount == 0) return const SizedBox.shrink();
    final svc = StudySetService.instance;
    if (svc.effectivelyFullyRecorded(set)) {
      return Container(
        width: double.infinity,
        color: Colors.green.shade50,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.check_circle,
                color: Colors.green.shade700, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Every word has audio — students will hear each one.',
                style: TextStyle(
                    fontSize: 12, color: Colors.green.shade800),
              ),
            ),
          ],
        ),
      );
    }
    final missing = svc.effectiveMissingCount(set);
    return Container(
      width: double.infinity,
      color: Colors.orange.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.orange.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$missing word${missing == 1 ? '' : 's'} still need audio. '
              'Students on the roster can already see the set, but they '
              'won\'t hear those words until you record them.',
              style: TextStyle(
                  fontSize: 12, color: Colors.orange.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, StudySet set, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(set.name, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '${set.sharedWithEmails.length} student${set.sharedWithEmails.length == 1 ? '' : 's'} '
            'on roster',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add student Google emails one at a time or paste a list. '
            'Multi-profile families see the set on every kid\'s profile — '
            'each kid can dismiss individually.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddBar(BuildContext context, StudySet set) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) => _addFromField(set),
              decoration: InputDecoration(
                labelText: 'Student Google email',
                hintText: 'e.g. kid.parent@gmail.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: () => _addFromField(set),
            icon: const Icon(Icons.add),
            tooltip: 'Add to roster',
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => _pasteBulkDialog(context, set),
            icon: const Icon(Icons.paste),
            tooltip: 'Paste multiple emails',
          ),
        ],
      ),
    );
  }

  Widget _buildRosterList(BuildContext context, StudySet set) {
    if (set.sharedWithEmails.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No students on the roster yet.\n\nAdd a student Google '
            'email above to start.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: set.sharedWithEmails.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final email = set.sharedWithEmails[i];
        return ListTile(
          leading: CircleAvatar(
            child: Text(
              email.isNotEmpty ? email[0].toUpperCase() : '?',
            ),
          ),
          title: Text(email),
          // Session 64c: green = this address has signed in to Awing,
          // amber = it has not (usually a typo, sometimes a student who
          // just has not installed yet), grey = could not check. Purely
          // informational - it never blocks adding or keeping an entry.
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmailKnownIcon(email: email),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                tooltip: 'Remove',
                onPressed: () async {
                  await StudySetService.instance
                      .removeFromRoster(set.id, email);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addFromField(StudySet set) async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    await StudySetService.instance.addToRoster(set.id, email);
    if (!mounted) return;
    _emailController.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _pasteBulkDialog(
      BuildContext context, StudySet set) async {
    final bulkController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paste multiple emails'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paste a list of Google emails separated by comma, '
              'space, or newline. Invalid entries are ignored.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bulkController,
              minLines: 4,
              maxLines: 10,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'a@gmail.com\nb@gmail.com\nc@gmail.com',
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
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add all'),
          ),
        ],
      ),
    );
    if (result != true) return;
    final raw = bulkController.text;
    final emails = raw.split(RegExp(r'[\s,;]+'));
    for (final e in emails) {
      await StudySetService.instance.addToRoster(set.id, e);
    }
  }
}
