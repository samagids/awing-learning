import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:awing_ai_learning/services/contribution_service.dart';

/// Developer review screen — shows all user contributions
/// with approve/reject workflow. Fully local, no backend.
///
/// Flow:
/// 1. Developer taps "Import" to load a JSON file received from users
/// 2. Reviews each contribution (listen to audio, read corrections)
/// 3. Approves or rejects
/// 4. Taps "Export Approved" → shares JSON via platform share
/// 5. Places the JSON in the project's contributions/ folder
/// 6. Runs build_and_run.bat to apply changes and rebuild the APK
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({Key? key}) : super(key: key);

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AudioPlayer _player = AudioPlayer();
  bool _isFetching = false;

  /// Drive-hosted audio URLs keyed by contribution id. Populated by
  /// _fetchAudioUrlsForVisible() so the play button can stream audio
  /// for contributions submitted from a DIFFERENT device (where the
  /// local audioPath doesn't exist on this Samsung).
  final Map<String, String> _audioUrls = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Auto-fetch from webhook when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchFromCloud());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _fetchFromCloud({bool showSnackbar = false}) async {
    final service = context.read<ContributionService>();
    if (!service.hasWebhook) return;

    setState(() => _isFetching = true);
    try {
      final count = await service.fetchFromWebhook();
      if (mounted && (showSnackbar || count > 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count > 0
                ? 'Fetched $count new contributions'
                : 'No new contributions'),
            backgroundColor: count > 0 ? Colors.green : Colors.grey,
          ),
        );
      }
      // After fetching the contribution rows themselves, ask the
      // webhook for the Drive-hosted audio URLs for every pending
      // contribution that has an audio recording but whose audioPath
      // doesn't exist locally (i.e. submitted from another device).
      await _fetchAudioUrlsForVisible();
    } catch (_) {
      // Silently fail on auto-fetch
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  /// Asks the webhook for {contributionId -> audioUrl} for every
  /// pending contribution that (a) claims to have audio, (b) doesn't
  /// have a local file on THIS device, and (c) we haven't already
  /// resolved a URL for. Batched into one network call.
  Future<void> _fetchAudioUrlsForVisible() async {
    final service = context.read<ContributionService>();
    if (!service.hasWebhook) return;
    final pending = service.pendingContributions;
    final needIds = <String>[];
    for (final c in pending) {
      if (_audioUrls.containsKey(c.id)) continue;
      // If audioPath IS set and the file exists locally, we're on the
      // submitter's own device -- no URL needed, the local file plays.
      if (c.audioPath != null) {
        final f = File(c.audioPath!);
        if (await f.exists()) continue;
      }
      // Either no audioPath (cross-device case) or audioPath but the
      // file is missing on this device -- ask the webhook for the
      // Drive URL. The webhook returns empty for contributions without
      // any audio (text-only spelling fixes, etc.), so this is safe to
      // batch over ALL pending IDs.
      needIds.add(c.id);
    }
    if (needIds.isEmpty) return;
    try {
      final urls = await service.fetchAudioUrls(needIds);
      if (mounted && urls.isNotEmpty) {
        setState(() => _audioUrls.addAll(urls));
      }
    } catch (_) {
      // Silently fail -- play button will surface a clearer error if
      // the user actually taps a contribution whose URL we couldn't fetch
    }
  }

  Future<void> _importContributions() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: true,
      );
      if (result == null || result.files.isEmpty) return;

      int totalImported = 0;
      final service = context.read<ContributionService>();

      for (final file in result.files) {
        if (file.path == null) continue;
        final count = await service.importFromFile(file.path!);
        totalImported += count;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $totalImported new contributions'),
            backgroundColor: totalImported > 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text == null || data!.text!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Clipboard is empty')),
          );
        }
        return;
      }

      final count = await context
          .read<ContributionService>()
          .importFromJson(data.text!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count > 0
                ? 'Imported $count contributions from clipboard'
                : 'No new contributions found in clipboard'),
            backgroundColor: count > 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Clipboard import error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportApproved() async {
    final service = context.read<ContributionService>();
    if (service.approvedContributions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No approved contributions to export')),
      );
      return;
    }

    await service.shareApproved();
  }

  void _showImportMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_open, color: const Color(0xFF006432)),
              title: const Text('Import from JSON file'),
              subtitle: const Text('Pick a .json contribution file'),
              onTap: () {
                Navigator.pop(ctx);
                _importContributions();
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_paste, color: const Color(0xFF006432)),
              title: const Text('Import from clipboard'),
              subtitle: const Text('Paste JSON text from clipboard'),
              onTap: () {
                Navigator.pop(ctx);
                _importFromClipboard();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Contributions'),
        centerTitle: true,
        backgroundColor: const Color(0xFF003d1f),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isFetching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.cloud_download),
            onPressed: _isFetching
                ? null
                : () => _fetchFromCloud(showSnackbar: true),
            tooltip: 'Fetch from cloud',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _showImportMenu,
            tooltip: 'Import from file',
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: _exportApproved,
            tooltip: 'Export approved',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Pending', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Approved', icon: Icon(Icons.check_circle)),
            Tab(text: 'Rejected', icon: Icon(Icons.cancel)),
          ],
        ),
      ),
      body: Consumer<ContributionService>(
        builder: (context, service, _) {
          final pending = service.contributions
              .where((c) => c.status == ContributionStatus.pending)
              .toList();
          final approved = service.contributions
              .where((c) => c.status == ContributionStatus.approved)
              .toList();
          final rejected = service.contributions
              .where((c) => c.status == ContributionStatus.rejected)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(pending, showActions: true),
              _buildApprovedList(approved),
              _buildList(rejected),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<Contribution> items, {bool showActions = false}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No contributions here',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
            if (showActions) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isFetching
                    ? null
                    : () => _fetchFromCloud(showSnackbar: true),
                icon: _isFetching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_download),
                label: Text(_isFetching ? 'Checking...' : 'Fetch from Cloud'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006432),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _showImportMenu,
                icon: const Icon(Icons.file_download),
                label: const Text('Or import from file'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _ContributionCard(
          contribution: items[index],
          showActions: showActions,
          player: _player,
          audioUrl: _audioUrls[items[index].id],
          onApprove: () => _approveDialog(items[index]),
          onReject: () => _rejectDialog(items[index]),
        );
      },
    );
  }

  Future<void> _syncToCloud() async {
    final service = context.read<ContributionService>();
    if (!service.hasWebhook) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No webhook configured. Deploy with deploy_apps_script.bat first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Syncing to Google Sheet...')),
    );

    final count = await service.syncApprovedToWebhook();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(count > 0
              ? 'Synced $count contributions to Google Sheet'
              : 'All contributions already synced'),
          backgroundColor: count > 0 ? Colors.green : Colors.grey,
        ),
      );
    }
  }

  Widget _buildApprovedList(List<Contribution> items) {
    final service = context.read<ContributionService>();

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No approved contributions',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Cloud sync banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.green.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    service.hasWebhook ? Icons.cloud_done : Icons.cloud_off,
                    color: service.hasWebhook
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      service.hasWebhook
                          ? '${items.length} approved. Approvals auto-sync to Google Sheet. '
                            'Run build_and_run.bat to download and apply.'
                          : '${items.length} approved. Export manually or deploy '
                            'the webhook for auto-sync.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (service.hasWebhook) ...[
                    ElevatedButton.icon(
                      onPressed: _syncToCloud,
                      icon: const Icon(Icons.cloud_upload, size: 18),
                      label: const Text('Sync Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton.icon(
                    onPressed: _exportApproved,
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Export JSON'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _ContributionCard(
                contribution: items[index],
                player: _player,
                audioUrl: _audioUrls[items[index].id],
              );
            },
          ),
        ),
      ],
    );
  }

  void _approveDialog(Contribution c) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Contribution?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  const TextSpan(
                    text: 'This will approve ',
                    style: TextStyle(fontSize: 14),
                  ),
                  TextSpan(
                    text: '"${c.targetWord}"',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: c.type == ContributionType.spellingCorrection
                        ? ' → "${c.correction}". Export and run '
                          'build_and_run.bat to apply the change.'
                        : '. Export and run build_and_run.bat to apply.',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Review notes (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<ContributionService>().approve(
                    c.id,
                    reviewNotes: notesController.text.isNotEmpty
                        ? notesController.text
                        : null,
                  );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Approved: "${c.targetWord}" → "${c.correction}"'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _rejectDialog(Contribution c) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Contribution?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject "${c.targetWord}" correction from ${c.profileName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason for rejection',
                hintText: 'e.g. Spelling is already correct',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<ContributionService>().reject(
                    c.id,
                    reason: reasonController.text.isNotEmpty
                        ? reasonController.text
                        : 'Not applicable',
                  );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Rejected: "${c.targetWord}"'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.close),
            label: const Text('Reject'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributionCard extends StatelessWidget {
  final Contribution contribution;
  final bool showActions;
  final AudioPlayer player;

  /// Optional Drive-hosted audio URL. Used as a fallback when the
  /// contribution's audioPath points to a file that doesn't exist on
  /// THIS device (i.e. the submission came from someone else's phone).
  final String? audioUrl;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _ContributionCard({
    required this.contribution,
    this.showActions = false,
    required this.player,
    this.audioUrl,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final c = contribution;
    final typeLabel = switch (c.type) {
      ContributionType.spellingCorrection => 'Spelling Fix',
      ContributionType.pronunciationFix => 'Pronunciation',
      ContributionType.newWord => 'New Word',
      ContributionType.newSentence => 'New Sentence',
      ContributionType.newPhrase => 'New Phrase',
      ContributionType.generalFeedback => 'Feedback',
      ContributionType.translationCorrection => 'Wrong Translation',
    };
    final typeColor = switch (c.type) {
      ContributionType.spellingCorrection => Colors.orange,
      ContributionType.pronunciationFix => Colors.blue,
      ContributionType.newWord => Colors.green,
      ContributionType.newSentence => Colors.teal,
      ContributionType.newPhrase => Colors.purple,
      ContributionType.generalFeedback => Colors.grey,
      ContributionType.translationCorrection => Colors.deepOrange,
    };
    final typeIcon = switch (c.type) {
      ContributionType.spellingCorrection => Icons.spellcheck,
      ContributionType.pronunciationFix => Icons.record_voice_over,
      ContributionType.newWord => Icons.add_circle,
      ContributionType.newSentence => Icons.short_text,
      ContributionType.newPhrase => Icons.chat_bubble,
      ContributionType.generalFeedback => Icons.feedback,
      ContributionType.translationCorrection => Icons.flag,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: type badge + contributor name + time
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(typeIcon, size: 14, color: typeColor),
                      const SizedBox(width: 4),
                      Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: typeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  c.profileName,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 8),
                Text(
                  _timeAgo(c.submittedAt),
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Target word
            Row(
              children: [
                const Text('Word: ',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                Expanded(
                  child: Text(
                    c.targetWord,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Correction (if applicable)
            if (c.correction.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.arrow_forward, size: 16,
                      color: Colors.green.shade700),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      c.correction,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // English meaning
            if (c.englishMeaning != null && c.englishMeaning!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'English: ${c.englishMeaning}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            // Pronunciation guide
            if (c.pronunciationGuide != null &&
                c.pronunciationGuide!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.record_voice_over,
                      size: 14, color: Colors.purple.shade400),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Sounds like: ${c.pronunciationGuide}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Category
            if (c.category != null) ...[
              const SizedBox(height: 4),
              Text(
                'Category: ${c.category}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],

            // Audio recording -- show if EITHER a local file path is set
            // (submitter's own device) OR a Drive URL was fetched by the
            // review screen (cross-device review on the developer's phone).
            if (c.audioPath != null ||
                (audioUrl != null && audioUrl!.isNotEmpty)) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.audiotrack,
                        color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Audio recording attached')),
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill,
                          color: Colors.blue, size: 32),
                      onPressed: () async {
                        // 1. Try local file first (works when reviewing
                        //    a contribution submitted from THIS device).
                        if (c.audioPath != null) {
                          final file = File(c.audioPath!);
                          if (await file.exists()) {
                            try {
                              await player
                                  .play(DeviceFileSource(c.audioPath!));
                              return;
                            } catch (_) {
                              // fall through to URL fallback
                            }
                          }
                        }
                        // 2. Fall back to Drive-hosted URL (works when
                        //    the contribution was submitted from a
                        //    different device — common case on the
                        //    developer's reviewing phone).
                        if (audioUrl != null && audioUrl!.isNotEmpty) {
                          try {
                            await player.play(UrlSource(audioUrl!));
                            return;
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Streaming error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            return;
                          }
                        }
                        // 3. Neither local file nor URL -- truly missing.
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Audio not available. Try Fetch from Cloud first.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],

            // Notes
            if (c.notes != null && c.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  c.notes!,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade700),
                ),
              ),
            ],

            // Review notes (for approved/rejected)
            if (c.reviewNotes != null && c.reviewNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.status == ContributionStatus.approved
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Review: ${c.reviewNotes}',
                  style: TextStyle(
                    fontSize: 13,
                    color: c.status == ContributionStatus.approved
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ),
            ],

            // Action buttons (only for pending in developer mode)
            if (showActions) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
