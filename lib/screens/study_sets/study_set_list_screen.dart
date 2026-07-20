import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/models/study_set.dart';
import 'package:awing_ai_learning/services/study_set_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/screens/study_sets/study_set_editor_screen.dart';
import 'package:awing_ai_learning/screens/study_sets/study_set_roster_screen.dart';
import 'package:awing_ai_learning/screens/study_sets/study_set_browse_screen.dart';

/// Study Sets list screen. Session 63 Phase 2.
///
/// The screen renders differently for the two roles that reach it via
/// the Exam mode → sub-menu flow (home_screen.dart):
///
///   • [StudySetRole.teacher] — sees "My sets" section, a FAB to
///     create a new set, and empty-state "Create your first set" CTA.
///     Full CRUD.
///
///   • [StudySetRole.student] — read-only view of "Shared with me".
///     No FAB, no create button, no "My sets" section. Empty state
///     explains that a teacher must add their email to the roster.
///     Also shows a diagnostic panel with the signed-in email + last
///     sync + any error so we can debug why a shared set isn't
///     appearing.
enum StudySetRole { teacher, student }

class StudySetListScreen extends StatefulWidget {
  final StudySetRole role;
  const StudySetListScreen({super.key, this.role = StudySetRole.teacher});

  @override
  State<StudySetListScreen> createState() => _StudySetListScreenState();
}

class _StudySetListScreenState extends State<StudySetListScreen> {
  @override
  void initState() {
    super.initState();
    // Load persisted sets on first open, then attach Firestore streams.
    StudySetService.instance.load().then((_) {
      if (!mounted) return;
      final auth = context.read<AuthService>();
      final email = auth.currentEmail;
      if (email.isNotEmpty) {
        StudySetService.instance.attachToAccount(email);
      }
    });
  }

  bool get _isStudent => widget.role == StudySetRole.student;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isStudent ? 'Study Sets' : 'My Study Sets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh from cloud',
            onPressed: () async {
              final n = await StudySetService.instance
                  .refreshSharedFromCloud();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Cloud fetch complete — $n shared set${n == 1 ? '' : 's'} found.',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: StudySetService.instance,
        builder: (context, _) {
          final service = StudySetService.instance;
          if (!service.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          // Students never see the teacher's own sets — only "Shared
          // with me". Teachers see both sections.
          final ownSets = _isStudent
              ? <StudySet>[]
              : service.ownSets;
          final sharedSets = service.sharedWithMe
              .where((s) => !s.locallyDismissed)
              .toList();
          if (ownSets.isEmpty && sharedSets.isEmpty) {
            return _buildEmptyState(context, theme);
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (_isStudent) _syncDiagnostic(context, compact: true),
              if (ownSets.isNotEmpty) ...[
                _sectionHeader(context, 'My sets'),
                for (final s in ownSets) ...[
                  _buildSetCard(context, s, isOwn: true),
                  const SizedBox(height: 8),
                ],
              ],
              if (sharedSets.isNotEmpty) ...[
                if (ownSets.isNotEmpty) const SizedBox(height: 12),
                _sectionHeader(
                    context, _isStudent ? 'From your teacher' : 'Shared with me'),
                for (final s in sharedSets) ...[
                  _buildSetCard(context, s, isOwn: false),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          );
        },
      ),
      // Only teachers can create sets. Students see no FAB.
      floatingActionButton: _isStudent
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _createSetDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('New Set'),
            ),
    );
  }

  /// Diagnostic card explaining the current cloud-sync state. Shown
  /// in the student's empty state (full form) and above their list
  /// when they have sets (compact form). Helps debug why a share
  /// isn't showing up — is the email wrong? Firestore denied? etc.
  Widget _syncDiagnostic(BuildContext context, {required bool compact}) {
    final theme = Theme.of(context);
    final service = StudySetService.instance;
    final auth = context.read<AuthService>();
    final signedInEmail = auth.currentEmail ?? '(not signed in)';
    final attachedEmail = service.attachedEmail ?? '(none)';
    final err = service.lastSharedError;
    final lastEvent = service.lastSharedEvent;
    final eventCount = service.sharedEventCount;
    final foundCount = service.sharedWithMe.length;

    // Compact form: tiny status pill, not a whole card.
    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(
              err == null ? Icons.cloud_done_outlined : Icons.error_outline,
              size: 16,
              color: err == null
                  ? Colors.green.shade600
                  : Colors.red.shade600,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                err == null
                    ? 'Signed in as $signedInEmail • $foundCount shared set${foundCount == 1 ? '' : 's'}'
                    : 'Sync error — tap ⓘ',
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, size: 18),
              tooltip: 'Sync details',
              onPressed: () => _showFullDiagnostic(context),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      );
    }

    // Full form: labelled key/value card.
    return Card(
      color: (err != null)
          ? Colors.red.shade50
          : theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_sync_outlined,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text('Sync details',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            _diagRow('Signed in as', signedInEmail),
            _diagRow('Watching for shares to', attachedEmail),
            _diagRow('Cloud updates received', '$eventCount'),
            _diagRow('Last update at',
                lastEvent == null ? 'never' : _fmtTime(lastEvent)),
            _diagRow('Shared sets visible', '$foundCount'),
            if (err != null) ...[
              const SizedBox(height: 6),
              Text('Error: $err',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry from cloud'),
                    onPressed: () async {
                      final n = await StudySetService.instance
                          .refreshSharedFromCloud();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            n == 0
                                ? 'No shared sets found for $attachedEmail. Ask your teacher to check the roster.'
                                : 'Found $n set${n == 1 ? '' : 's'}.',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _diagRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return t.toIso8601String().substring(0, 16);
  }

  Future<void> _showFullDiagnostic(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sync details'),
        content: SingleChildScrollView(
          child: _syncDiagnostic(context, compact: false),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    if (_isStudent) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Icon(
              Icons.school_outlined,
              size: 72,
              color: theme.colorScheme.primary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No study sets yet',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'When your teacher adds your Google email to a Study Set '
              'roster, it will show up here. Tap "Retry from cloud" '
              'below to check again.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _syncDiagnostic(context, compact: false),
          ],
        ),
      );
    }
    // Teacher empty state — original CTA.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 72,
              color: theme.colorScheme.primary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No Study Sets yet',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'A Study Set is a curated list of words you build for '
              'your class. Add words from the dictionary or create '
              'new ones. Once you record audio for every word, you '
              'can share the set with your students.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _createSetDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create your first set'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSetCard(BuildContext context, StudySet set,
      {required bool isOwn}) {
    final theme = Theme.of(context);
    final wordCount = set.wordCount;
    final missing = set.missingRecordingsCount;
    final fullyRecorded = set.isFullyRecorded;
    final rosterCount = set.sharedWithEmails.length;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => isOwn
            ? _openEditor(context, set)
            : _openBrowse(context, set),
        onLongPress: () => isOwn
            ? _setActionSheet(context, set)
            : _sharedActionSheet(context, set),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      set.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Only teachers get the per-set action menu (rename,
                  // roster, delete). Students long-press for the
                  // "dismiss" action on shared cards.
                  if (isOwn)
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _setActionSheet(context, set),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              if (set.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  set.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _chip(
                    context,
                    icon: Icons.text_snippet_outlined,
                    label: '$wordCount word${wordCount == 1 ? '' : 's'}',
                  ),
                  if (wordCount > 0)
                    _chip(
                      context,
                      icon: fullyRecorded
                          ? Icons.mic
                          : Icons.mic_none,
                      label: fullyRecorded
                          ? 'All recorded'
                          : '$missing to record',
                      color: fullyRecorded
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  _chip(
                    context,
                    icon: Icons.group_outlined,
                    label: rosterCount == 0
                        ? 'Not shared yet'
                        : '$rosterCount student${rosterCount == 1 ? '' : 's'}',
                    color: rosterCount > 0
                        ? Colors.blue.shade700
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: c)),
        ],
      ),
    );
  }

  Future<void> _createSetDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final auth = context.read<AuthService>();

    final teacherEmail = auth.currentEmail ?? '';
    final teacherName = auth.currentProfile?.displayName ?? 'Teacher';

    if (teacherEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in with Google before creating a Study Set.'),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Study Set'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Set name',
                hintText: 'e.g. Grade 3 Unit 2',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'What this set is for, level, focus…',
                border: OutlineInputBorder(),
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
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != true || !mounted) return;
    final set = await StudySetService.instance.create(
      teacherEmail: teacherEmail,
      teacherName: teacherName,
      name: nameController.text,
      description: descController.text,
    );
    if (!mounted) return;
    _openEditor(context, set);
  }

  void _openEditor(BuildContext context, StudySet set) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => StudySetEditorScreen(setId: set.id),
    ));
  }

  void _openRoster(BuildContext context, StudySet set) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => StudySetRosterScreen(setId: set.id),
    ));
  }

  void _openBrowse(BuildContext context, StudySet set) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => StudySetBrowseScreen(setId: set.id),
    ));
  }

  Future<void> _sharedActionSheet(
      BuildContext context, StudySet set) async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.book_outlined),
              title: const Text('Browse this set'),
              onTap: () {
                Navigator.pop(ctx);
                _openBrowse(context, set);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('Not for me — dismiss'),
              subtitle: const Text(
                'Hide from this profile only. Other profiles on this '
                'device still see it.',
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await StudySetService.instance.toggleDismiss(set.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setActionSheet(BuildContext context, StudySet set) async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.group_add_outlined),
              title: const Text('Manage class roster'),
              subtitle: Text(
                set.sharedWithEmails.isEmpty
                    ? 'Add student Google emails'
                    : '${set.sharedWithEmails.length} student(s) on roster',
              ),
              onTap: () {
                Navigator.pop(ctx);
                _openRoster(context, set);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename or edit notes'),
              onTap: () async {
                Navigator.pop(ctx);
                await _renameDialog(context, set);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete this set',
                  style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dctx) => AlertDialog(
                    title: const Text('Delete Study Set?'),
                    content: Text('"${set.name}" will be permanently '
                        'removed. This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await StudySetService.instance.deleteSet(set.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameDialog(BuildContext context, StudySet set) async {
    final nameCtrl = TextEditingController(text: set.name);
    final descCtrl = TextEditingController(text: set.description);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Study Set'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Set name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == true) {
      await StudySetService.instance.updateMetadata(
        set.id,
        name: nameCtrl.text,
        description: descCtrl.text,
      );
    }
  }
}
