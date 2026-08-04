import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awing_ai_learning/services/analytics_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/cloud_backup_service.dart';
import 'package:awing_ai_learning/services/contribution_service.dart';
import 'package:awing_ai_learning/services/progress_service.dart';
import 'package:awing_ai_learning/services/recordings_service.dart';
import 'package:awing_ai_learning/services/native_audio_inventory.dart';
import 'package:awing_ai_learning/models/user_model.dart';
import 'package:awing_ai_learning/data/awing_alphabet.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/data/awing_tones.dart' hide awingVowels;
import 'package:awing_ai_learning/screens/admin/review_screen.dart';
import 'package:awing_ai_learning/screens/admin/grader_smoke_test_screen.dart';
import 'package:awing_ai_learning/screens/about_screen.dart';
import 'package:awing_ai_learning/screens/medium/sentences_screen.dart'
    show awingSentences;
import 'package:awing_ai_learning/screens/stories_screen.dart'
    show awingStories;
import 'package:awing_ai_learning/components/parental_gate.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

/// Developer Mode — full admin panel.
/// Only accessible when logged in as samagids@gmail.com.
/// Resets the 5-minute inactivity timer on every tab switch.
class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({Key? key}) : super(key: key);

  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AuthService>().resetDevModeActivity();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (!auth.isDeveloper) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Developer mode deactivated due to inactivity'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
    }

    return DefaultTabController(
      length: 6,
      child: Builder(builder: (ctx) {
        DefaultTabController.of(ctx).addListener(() {
          auth.resetDevModeActivity();
        });
        // Reset inactivity timer on ANY touch/interaction within developer mode
        return Listener(
          onPointerDown: (_) => auth.resetDevModeActivity(),
          child: Scaffold(
          appBar: AppBar(
            title: const Text('Developer Mode'),
            backgroundColor: Colors.black87,
            foregroundColor: Colors.greenAccent,
            actions: [
              TextButton.icon(
                onPressed: () async {
                  final ok = await ParentalGate.verify(
                    context,
                    title: 'Exit Developer Mode',
                    message: 'Only the developer should exit developer mode.',
                  );
                  if (!ok || !context.mounted) return;
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Deactivate Developer Mode?'),
                      content: const Text(
                        'You will need to re-enter the access code and verify via email to reactivate.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            auth.disableDevMode();
                            Navigator.pop(ctx);
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Developer mode deactivated'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                          child: const Text('Deactivate'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout,
                    color: Colors.redAccent, size: 18),
                label: const Text('Exit Dev',
                    style: TextStyle(color: Colors.redAccent)),
              ),
            ],
            bottom: const TabBar(
              labelColor: Colors.greenAccent,
              unselectedLabelColor: Colors.white54,
              indicatorColor: Colors.greenAccent,
              isScrollable: true,
              tabs: [
                Tab(text: 'Review', icon: Icon(Icons.rate_review)),
                Tab(text: 'Record', icon: Icon(Icons.mic)),
                Tab(text: 'Users', icon: Icon(Icons.people)),
                Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
                Tab(text: 'Content', icon: Icon(Icons.edit_note)),
                Tab(text: 'Settings', icon: Icon(Icons.settings)),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              _ReviewTab(),
              _RecordTab(),
              _UsersTab(),
              _AnalyticsTab(),
              _ContentTab(),
              _SettingsTab(),
            ],
          ),
        ),
        );
      }),
    );
  }
}

// =====================================================================
//  REVIEW TAB — live server sync
// =====================================================================

class _ReviewTab extends StatefulWidget {
  const _ReviewTab();

  @override
  State<_ReviewTab> createState() => _ReviewTabState();
}

class _ReviewTabState extends State<_ReviewTab> {
  Timer? _refreshTimer;
  bool _isFetching = false;
  DateTime? _lastSyncedAt;
  String? _lastError;
  FetchAllResult? _lastResult;

  @override
  void initState() {
    super.initState();
    // Kick off first fetch after the widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncFromServer(showSnack: false);
    });
    // Auto-refresh every 30 seconds while Dev Mode is open
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && !_isFetching) _syncFromServer(showSnack: false);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _syncFromServer({required bool showSnack}) async {
    if (_isFetching) return;
    if (!mounted) return;

    setState(() {
      _isFetching = true;
      _lastError = null;
    });

    final service = context.read<ContributionService>();
    final result = await service.fetchAllFromWebhook();

    if (!mounted) return;

    setState(() {
      _isFetching = false;
      _lastResult = result;
      if (result.success) {
        _lastSyncedAt = DateTime.now();
        _lastError = null;
      } else {
        _lastError = result.error;
      }
    });

    if (showSnack) {
      final msg = result.success
          ? (result.added > 0 || result.updated > 0
              ? 'Synced — +${result.added} new, ${result.updated} updated'
              : 'Up to date (${result.serverTotal} on server)')
          : 'Sync failed: ${result.error ?? "unknown error"}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 3),
          backgroundColor: result.success ? Colors.green : Colors.red.shade800,
        ),
      );
    }
  }

  String _syncedAgo() {
    if (_lastSyncedAt == null) return 'Never synced';
    final diff = DateTime.now().difference(_lastSyncedAt!);
    if (diff.inSeconds < 10) return 'Synced just now';
    if (diff.inSeconds < 60) return 'Synced ${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return 'Synced ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Synced ${diff.inHours}h ago';
    return 'Synced ${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContributionService>(
      builder: (context, service, _) {
        // Prefer server counts when available, fall back to local counts.
        // This avoids showing "0 pending" right after boot before the first
        // fetch completes — we'd rather show the locally known numbers.
        final localPending = service.pendingContributions.length;
        final localApproved = service.approvedContributions.length;
        final localTotal = service.contributions.length;

        final serverAvailable = _lastResult?.success ?? false;
        final pendingCount =
            serverAvailable ? _lastResult!.serverPending : localPending;
        final approvedCount =
            serverAvailable ? _lastResult!.serverApproved : localApproved;
        final totalCount =
            serverAvailable ? _lastResult!.serverTotal : localTotal;

        final pendingForList = service.pendingContributions;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: const Color(0xFF003d1f),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Contribution Queue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purpleAccent.shade100,
                          ),
                        ),
                        const Spacer(),
                        // Manual refresh with spinner while fetching
                        if (_isFetching)
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white70),
                            ),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.refresh,
                                color: Colors.white70),
                            tooltip: 'Refresh from server',
                            onPressed: () => _syncFromServer(showSnack: true),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatBox(
                            label: 'Pending',
                            value: '$pendingCount',
                            color: Colors.orange),
                        _StatBox(
                            label: 'Approved',
                            value: '$approvedCount',
                            color: Colors.green),
                        _StatBox(
                            label: 'Total',
                            value: '$totalCount',
                            color: Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _lastError != null
                              ? Icons.cloud_off
                              : (serverAvailable
                                  ? Icons.cloud_done
                                  : Icons.cloud_queue),
                          size: 14,
                          color: _lastError != null
                              ? Colors.red.shade300
                              : Colors.white54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _lastError != null
                              ? 'Sync error — tap refresh'
                              : _syncedAgo(),
                          style: TextStyle(
                            fontSize: 12,
                            color: _lastError != null
                                ? Colors.red.shade300
                                : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ReviewScreen()));
              },
              icon: const Icon(Icons.rate_review),
              label: Text(
                pendingCount == 0
                    ? 'Review Contributions'
                    : 'Review $pendingCount Pending',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: pendingCount == 0
                    ? Colors.grey.shade700
                    : const Color(0xFF006432),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            if (pendingForList.isNotEmpty) ...[
              Text('Recent Pending',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade300)),
              const SizedBox(height: 8),
              ...pendingForList.take(5).map((c) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        c.type == ContributionType.pronunciationFix
                            ? Icons.record_voice_over
                            : c.type == ContributionType.newWord
                                ? Icons.add_circle
                                : Icons.spellcheck,
                        color: Colors.orange,
                      ),
                      title: Text(c.targetWord),
                      subtitle: Text(
                        '${c.type.name} by ${c.profileName}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: c.audioPath != null
                          ? const Icon(Icons.audiotrack, color: Colors.blue)
                          : null,
                    ),
                  )),
            ],
          ],
        );
      },
    );
  }
}

// =====================================================================
//  RECORD TAB — family-recorder-style native-speaker capture
// =====================================================================
//
// Session 61b rewrite. Behaviour change vs the previous Autocomplete +
// single-item dropdown:
//   • Browse the WHOLE catalog as a scrollable list — words, phrases,
//     letters, sentences, and story lines — like the family recorder
//     HTML page. Filter chips and a search box narrow it down.
//   • Each row has a status badge sourced from the /recordings Firestore
//     collection (RecordingsService). Any device signed in as the same
//     Google account (or any tester contributor) sees the same inventory
//     in real time. No more "wait, did I already record that?".
//   • Three filter axes: source (Words/Phrases/...), status (Not recorded
//     / Recorded by me / Recorded by others), recorder (filter to one
//     contributor's email).
//   • Recording is inline per row — tap the mic on the card you want.
//   • Submit is auto-apply: the audio is uploaded to Drive via the
//     existing contributions webhook AND a row is written to the
//     /recordings Firestore collection. The desktop build pipeline pulls
//     them with scripts/sync_recordings.py and lands them in
//     training_data/recordings/. No Review tab step required.

/// Represents a single content item that can be recorded.
class _RecordableItem {
  final String awing;
  final String english;
  final String source; // word | phrase | letter | sentence | story
  final String? category;
  final String audioKey;

  _RecordableItem({
    required this.awing,
    required this.english,
    required this.source,
    this.category,
  }) : audioKey = PronunciationService.audioKey(awing);

  String get displayLabel => '$awing — $english';

  String get sourceLabel {
    switch (source) {
      case 'word':
        return category == null ? 'Word' : 'Word ($category)';
      case 'phrase':
        return 'Phrase';
      case 'letter':
        return 'Letter';
      case 'sentence':
        return 'Sentence';
      case 'story':
        return category == null ? 'Story' : 'Story · $category';
      default:
        return source;
    }
  }

  Color get sourceColor {
    switch (source) {
      case 'word':
        return Colors.blue;
      case 'phrase':
        return Colors.teal;
      case 'letter':
        return Colors.orange;
      case 'sentence':
        return Colors.purple;
      case 'story':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  IconData get sourceIcon {
    switch (source) {
      case 'word':
        return Icons.abc;
      case 'phrase':
        return Icons.chat_bubble_outline;
      case 'letter':
        return Icons.text_fields;
      case 'sentence':
        return Icons.format_quote;
      case 'story':
        return Icons.menu_book;
      default:
        return Icons.fiber_manual_record;
    }
  }
}

class _RecordTab extends StatefulWidget {
  const _RecordTab();

  @override
  State<_RecordTab> createState() => _RecordTabState();
}

class _RecordTabState extends State<_RecordTab> {
  // Full catalog (built once)
  late List<_RecordableItem> _allItems;

  // Filters
  String _filterSource = 'All';
  String _filterStatus = 'All';
  String _filterRecorder = 'Anyone';
  final _searchController = TextEditingController();

  // Active recorder (whose voice is in the next submission).
  // Mirrors scripts/build_family_recorder.py FAMILY list — same names so
  // recordings are attributed consistently across the family HTML recorder
  // and the in-app Dev Mode Record tab. "Other…" opens a free-text prompt
  // for guests. Persisted in SharedPreferences across app restarts.
  static const List<String> _familyRecorders = [
    'Dr. Guidion Sama',
    'Berlin Sama',
    'Joel',
    'Janelle',
    'Joyce',
    'Jadyne',
  ];
  static const String _kRecorderPrefsKey = 'record_tab_active_recorder';
  String _activeRecorder = 'Dr. Guidion Sama';

  // Inline recording state
  String? _recordingForKey; // audioKey of the item being recorded
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _isRecording = false;
  bool _hasRecording = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  bool _isPlaying = false;
  String? _playingForKey;       // audioKey of item whose recording is playing
  bool _submitting = false;

  static const int _maxRecordSeconds = 10;

  @override
  void initState() {
    super.initState();
    _buildItemList();
    _searchController.addListener(() => setState(() {}));
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _playingForKey = null;
        });
      }
    });
    _loadActiveRecorder();
  }

  Future<void> _loadActiveRecorder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kRecorderPrefsKey);
      if (!mounted) return;
      if (saved != null && saved.isNotEmpty) {
        setState(() => _activeRecorder = saved);
      } else {
        // First run: default to current profile name if it matches a
        // family member; otherwise stay on Dr. Guidion Sama (the
        // typical Dev-Mode operator).
        final auth = context.read<AuthService>();
        final name = auth.currentProfile?.displayName;
        if (name != null && _familyRecorders.contains(name)) {
          setState(() => _activeRecorder = name);
        }
      }
    } catch (_) {/* fall back to default */}
  }

  Future<void> _setActiveRecorder(String name) async {
    if (!mounted) return;
    setState(() => _activeRecorder = name);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kRecorderPrefsKey, name);
    } catch (_) {/* prefs unavailable — keep in-memory only */}
  }

  /// Returns the lowercase kid slug (joel/janelle/joyce/jadyne) for the
  /// active recorder, or null if it's Dr. Sama / Berlin / guest. Used
  /// by the "Missing from active recorder" filter to look up coverage
  /// in NativeAudioInventory.
  String? _activeRecorderKidSlug() {
    const knownKids = {'joel', 'janelle', 'joyce', 'jadyne'};
    final norm = _activeRecorder.trim().toLowerCase();
    if (norm.isEmpty) return null;
    if (knownKids.contains(norm)) return norm;
    final first = norm.split(RegExp(r'\s+')).first;
    return knownKids.contains(first) ? first : null;
  }

  Future<String?> _promptCustomRecorder() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Who is recording?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Name (e.g. Aunt Mary)',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _buildItemList() {
    final items = <_RecordableItem>[];

    // Letters (alphabet)
    for (final letter in awingAlphabet) {
      items.add(_RecordableItem(
        awing: letter.letter,
        english: '${letter.phoneme} (${letter.type})',
        source: 'letter',
      ));
    }

    // Vocabulary words
    for (final word in allVocabulary) {
      items.add(_RecordableItem(
        awing: word.awing,
        english: word.english,
        source: 'word',
        category: word.category,
      ));
    }

    // Phrases
    for (final phrase in awingPhrases) {
      items.add(_RecordableItem(
        awing: phrase.awing,
        english: phrase.english,
        source: 'phrase',
        category: phrase.category,
      ));
    }

    // Sentences from medium module
    for (final sent in awingSentences) {
      items.add(_RecordableItem(
        awing: sent.awing,
        english: sent.english,
        source: 'sentence',
      ));
    }

    // Story lines from stories screen
    for (final story in awingStories) {
      for (final s in story.sentences) {
        items.add(_RecordableItem(
          awing: s.awing,
          english: s.english,
          source: 'story',
          category: story.titleEnglish,
        ));
      }
    }

    // Dedup by audio_key (a sentence and a story line might collide).
    // Keep the first occurrence — letters/words come before sentences/
    // stories so the more specific source label wins.
    final seen = <String>{};
    _allItems = items.where((item) => seen.add(item.audioKey)).toList();
  }

  List<_RecordableItem> _applyFilters(RecordingsService recordings) {
    final q = _searchController.text.toLowerCase().trim();
    final currentEmail = FirebaseAuth.instance.currentUser?.email;

    return _allItems.where((item) {
      // Source
      if (_filterSource != 'All') {
        final wanted = _filterSource == 'Words'
            ? 'word'
            : _filterSource == 'Phrases'
                ? 'phrase'
                : _filterSource == 'Letters'
                    ? 'letter'
                    : _filterSource == 'Sentences'
                        ? 'sentence'
                        : _filterSource == 'Stories'
                            ? 'story'
                            : _filterSource;
        if (item.source != wanted) return false;
      }

      final recs = recordings.recordingsFor(item.audioKey);
      final byMe =
          recs.any((r) => r.recordedByEmail == currentEmail);

      // Status
      switch (_filterStatus) {
        case 'NotRecorded':
          if (recs.isNotEmpty) return false;
          break;
        case 'ByMe':
          if (!byMe) return false;
          break;
        case 'ByOthers':
          if (recs.isEmpty) return false;
          if (recs.length == 1 && byMe) return false;
          break;
        case 'MissingFromActive':
          // v1.13.4 — show items the currently-picked recorder hasn't
          // covered in the last-built audio inventory. Useful for
          // tracking down kids' missing words (e.g. Joel's 12 untaped
          // words after the dedup fix surfaced his real coverage count).
          // For non-kid active recorders (Dr. Sama / Berlin / guest),
          // fall back to canonical coverage.
          final inv = NativeAudioInventory.instance;
          final kidSlug = _activeRecorderKidSlug();
          final covered = kidSlug != null
              ? inv.hasKidRecording(item.audioKey, kidSlug)
              : inv.hasCanonical(item.audioKey);
          if (covered) return false;
          break;
      }

      // Recorder
      if (_filterRecorder != 'Anyone') {
        if (!recs.any((r) => r.recordedByEmail == _filterRecorder)) {
          return false;
        }
      }

      // Search
      if (q.isNotEmpty) {
        return item.awing.toLowerCase().contains(q) ||
            item.english.toLowerCase().contains(q) ||
            (item.category?.toLowerCase().contains(q) ?? false);
      }

      return true;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _recorder.dispose();
    _player.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  // ==================== Recording ====================

  Future<void> _startRecording(_RecordableItem item) async {
    // Session 60+ block-duplicate-recordings rule. Refuse to record
    // over a word that already has an approved canonical native
    // recording in the AAB. Dev Mode users (developer/admins) follow
    // the same rule as public Contribute screen — if a re-record is
    // genuinely needed, replace the file in assets/audio/native/
    // directly and rebuild.
    if (NativeAudioInventory.instance.hasCanonical(item.audioKey)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '"${item.awing}" already has an approved native '
              'recording. To replace it, swap the file in '
              'assets/audio/native/ and rebuild.',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }
    if (!await _recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required')),
        );
      }
      return;
    }
    final contribService = context.read<ContributionService>();
    final tempId =
        '${item.audioKey}_${DateTime.now().millisecondsSinceEpoch}';
    _recordingPath = await contribService.getRecordingPath(tempId);
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _recordingPath!,
    );
    _recordingDuration = Duration.zero;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_recordingDuration.inSeconds >= _maxRecordSeconds) {
        _stopRecording();
        return;
      }
      setState(() {
        _recordingDuration += const Duration(seconds: 1);
      });
    });
    setState(() {
      _recordingForKey = item.audioKey;
      _isRecording = true;
      _hasRecording = false;
    });
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _hasRecording = path != null;
      if (path != null) _recordingPath = path;
    });
  }

  Future<void> _playRecording() async {
    if (_recordingPath == null) return;
    setState(() => _isPlaying = true);
    await _player.play(DeviceFileSource(_recordingPath!));
  }

  Future<void> _playReference(_RecordableItem item) async {
    final pron = PronunciationService();
    await pron.speakAwing(item.awing);
  }

  /// v1.13.3 — play back a recording the user previously submitted.
  /// Fetches the Drive URL via the contributions webhook (privileged
  /// fetch_audio call), downloads the m4a to the temp dir, and plays it
  /// via AudioPlayer. UI tracks per-key playback state so the button
  /// can show a spinner while loading.
  Future<void> _playUserRecording(
      _RecordableItem item, RecordingDoc rec) async {
    if (rec.contributionId == null) return;
    setState(() {
      _isPlaying = true;
      _playingForKey = item.audioKey;
    });
    try {
      final contribService = context.read<ContributionService>();
      final urls = await contribService
          .fetchAudioUrls([rec.contributionId!]);
      final url = urls[rec.contributionId!];
      if (url == null || url.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No audio on file for that recording yet'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      // Stream the audio directly from the URL. AudioPlayer's UrlSource
      // handles range requests and streaming, no temp file needed.
      await _player.play(UrlSource(url));
    } catch (e) {
      debugPrint('Play user recording failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playback failed: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // _isPlaying is reset to false by the player's onPlayerComplete
      // listener set up in initState. But if we errored before play
      // even started, manually reset.
      if (mounted && _player.state != PlayerState.playing) {
        setState(() {
          _isPlaying = false;
          _playingForKey = null;
        });
      }
    }
  }

  void _cancelRecording() {
    if (_isRecording) {
      _recorder.stop();
    }
    _recordingTimer?.cancel();
    setState(() {
      _recordingForKey = null;
      _isRecording = false;
      _hasRecording = false;
      _recordingPath = null;
      _recordingDuration = Duration.zero;
    });
  }

  // ==================== Submit ====================

  Future<void> _submitRecording(_RecordableItem item) async {
    if (!_hasRecording) return;
    setState(() => _submitting = true);

    final contribService = context.read<ContributionService>();
    final recordings = context.read<RecordingsService>();
    final analytics = AnalyticsService.instance;

    // 1. Push Firestore metadata immediately so other devices see it.
    final device = Platform.isAndroid
        ? 'Android'
        : Platform.isIOS
            ? 'iOS'
            : 'Other';
    final recId = await recordings.recordSubmitted(
      awing: item.awing,
      english: item.english,
      source: item.source,
      audioKey: item.audioKey,
      category: item.category,
      device: device,
      durationMs: _recordingDuration.inMilliseconds,
    );

    // 2. Upload audio via existing contributions webhook (Drive storage).
    //    profileName is the picker's _activeRecorder — that's the *voice*
    //    in the recording. The audit trail (recordedByEmail in Firestore)
    //    is the signed-in account that did the upload; those are
    //    deliberately separate so we can attribute "whose voice this is"
    //    even when one device does the recording for many family members.
    final contribId = await contribService.submit(
      deviceId: analytics.isOptedOut ? 'anonymous' : 'developer',
      profileName: _activeRecorder,
      type: ContributionType.pronunciationFix,
      targetWord: item.awing,
      correction: item.awing,
      englishMeaning: item.english,
      category: item.category ?? item.source,
      pronunciationGuide: null,
      audioPath: _recordingPath,
      notes:
          'Native recording (${item.sourceLabel}) — auto-apply',
    );

    // 3. Link the Firestore /recordings row to the contribution_id so
    //    the desktop sync script can fetch the Drive URL.
    if (recId != null && contribId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('recordings')
            .doc(recId)
            .set({'contribution_id': contribId},
                SetOptions(merge: true));
      } catch (e) {
        debugPrint('Failed to link recording → contribution: $e');
      }
    }

    analytics.logActivity(
      event: 'dev_record',
      level: 'developer',
      lesson: 'record_${item.source}',
    );

    if (mounted) {
      setState(() {
        _submitting = false;
        _hasRecording = false;
        _recordingPath = null;
        _recordingDuration = Duration.zero;
        _recordingForKey = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Saved "${item.awing}" — will ship in next build'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    return Consumer<RecordingsService>(
      builder: (context, recordings, _) {
        final filtered = _applyFilters(recordings);
        final currentEmail =
            FirebaseAuth.instance.currentUser?.email;
        final anyCount = _allItems
            .where((i) => recordings.hasRecording(i.audioKey))
            .length;
        final myCount = _allItems
            .where((i) => recordings
                .recordingsFor(i.audioKey)
                .any((r) => r.recordedByEmail == currentEmail))
            .length;

        return Column(
          children: [
            _buildHeader(recordings, anyCount, myCount),
            _buildRecorderPicker(),
            _buildFilters(recordings),
            _buildSearch(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} of ${_allItems.length} shown',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                  ),
                  const Spacer(),
                  Text(
                    '${recordings.recorderEmails.length} contributor(s)',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) =>
                          _buildItemCard(filtered[i], recordings),
                    ),
            ),
            if (_recordingForKey != null) _buildRecordingPanel(),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
      RecordingsService recordings, int anyCount, int myCount) {
    return Container(
      width: double.infinity,
      color: Colors.deepPurple.shade900,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mic, color: Colors.purpleAccent),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Native recordings',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (!recordings.isLoaded)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.purpleAccent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$anyCount of ${_allItems.length} recorded'
            ' • $myCount by you'
            ' • synced across signed-in devices',
            style: TextStyle(
                color: Colors.purpleAccent.shade100, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildRecorderPicker() {
    // "Recording as: <name>" strip — sits directly under the purple header
    // so it's the first thing the dev sees. Tapping the dropdown lets the
    // dev attribute the next recording to any family member, matching the
    // family_recorder.html workflow. "Other…" opens a free-text prompt for
    // guests / one-off contributors. Persisted in SharedPreferences.
    final bool isFamily = _familyRecorders.contains(_activeRecorder);
    return Container(
      width: double.infinity,
      color: Colors.deepPurple.shade700,
      padding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
      child: Row(
        children: [
          const Icon(Icons.person_outline,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          const Text(
            'Recording as:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                canvasColor: Colors.deepPurple.shade800,
              ),
              child: DropdownButton<String>(
                value: isFamily ? _activeRecorder : '__custom__',
                isExpanded: true,
                isDense: true,
                iconEnabledColor: Colors.white,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                underline: Container(
                  height: 1,
                  color: Colors.purpleAccent.shade100,
                ),
                items: [
                  for (final name in _familyRecorders)
                    DropdownMenuItem(
                      value: name,
                      child: Text(name),
                    ),
                  if (!isFamily)
                    DropdownMenuItem(
                      value: '__custom__',
                      child: Text('$_activeRecorder (guest)'),
                    ),
                  const DropdownMenuItem(
                    value: '__new_custom__',
                    child: Text('Other…'),
                  ),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  if (v == '__new_custom__') {
                    final custom = await _promptCustomRecorder();
                    if (custom != null && custom.isNotEmpty) {
                      await _setActiveRecorder(custom);
                    }
                  } else if (v == '__custom__') {
                    // No-op — picker already shows the guest name.
                  } else {
                    await _setActiveRecorder(v);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(RecordingsService recordings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final s in [
                  'All',
                  'Words',
                  'Phrases',
                  'Letters',
                  'Sentences',
                  'Stories'
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(s,
                          style: const TextStyle(fontSize: 11)),
                      selected: _filterSource == s,
                      selectedColor: Colors.purpleAccent,
                      onSelected: (_) =>
                          setState(() => _filterSource = s),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final tuple in const [
                  ('All', 'All', null),
                  ('NotRecorded', '⬜ To do', Colors.orange),
                  ('ByMe', '✅ By me', Colors.green),
                  ('ByOthers', '👥 By others', Colors.blue),
                  // v1.13.4 — shows only items the currently-picked
                  // recorder hasn't covered in the SHIPPED audio
                  // inventory. Pick "Joel" + this filter to see exactly
                  // which words Joel needs to (re-)record.
                  ('MissingFromActive', '🎯 Missing from picker', Colors.red),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(tuple.$2,
                          style: const TextStyle(fontSize: 11)),
                      selected: _filterStatus == tuple.$1,
                      selectedColor:
                          tuple.$3 ?? Colors.purpleAccent,
                      onSelected: (_) =>
                          setState(() => _filterStatus = tuple.$1),
                    ),
                  ),
                const SizedBox(width: 12),
                _recorderDropdown(recordings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recorderDropdown(RecordingsService recordings) {
    final emails = ['Anyone', ...recordings.recorderEmails];
    return DropdownButton<String>(
      value: emails.contains(_filterRecorder)
          ? _filterRecorder
          : 'Anyone',
      isDense: true,
      underline: const SizedBox.shrink(),
      style: const TextStyle(fontSize: 12, color: Colors.white),
      dropdownColor: Colors.grey.shade900,
      items: emails.map((e) {
        final label = e == 'Anyone' ? 'Anyone' : e.split('@').first;
        return DropdownMenuItem(
          value: e,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('👤 $label',
                style: const TextStyle(fontSize: 12)),
          ),
        );
      }).toList(),
      onChanged: (v) {
        if (v != null) setState(() => _filterRecorder = v);
      },
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search Awing or English…',
          isDense: true,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                tooltip: 'Clear',
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => _searchController.clear(),
                ),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off,
                size: 64, color: Colors.grey.shade700),
            const SizedBox(height: 12),
            Text(
              'No items match these filters',
              style: TextStyle(
                  color: Colors.grey.shade400, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Clear filters'),
              onPressed: () {
                setState(() {
                  _filterSource = 'All';
                  _filterStatus = 'All';
                  _filterRecorder = 'Anyone';
                  _searchController.clear();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(
      _RecordableItem item, RecordingsService recordings) {
    final recs = recordings.recordingsFor(item.audioKey);
    final currentEmail =
        FirebaseAuth.instance.currentUser?.email;
    final byMe =
        recs.any((r) => r.recordedByEmail == currentEmail);
    final isActive = _recordingForKey == item.audioKey;

    // Find this user's most recent recording for this item (used for the
    // "Play my recording" button below).
    final myRec = byMe
        ? recs.firstWhere((r) => r.recordedByEmail == currentEmail)
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isActive
          ? Colors.purple.shade50
          : (byMe ? Colors.green.shade50 : null),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Icon(item.sourceIcon, color: item.sourceColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.awing,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade900)),
                  Text(item.english,
                      // v1.13.3 fix: was Colors.white70 (invisible on the
                      // app's cream background). Now uses black54 — high
                      // enough contrast to read at fontSize: 12.
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700)),
                  const SizedBox(height: 2),
                  _statusLine(item, recs, byMe),
                  // v1.13.4 — per-recorder coverage badges. Pulls from
                  // NativeAudioInventory (last-built audio tree) so the
                  // dev can see at a glance which kids have a clip for
                  // this word. Active recorder's badge is highlighted.
                  _inventoryBadges(item),
                ],
              ),
            ),
            const SizedBox(width: 2),
            // v1.13.3: Play YOUR recording (only shown when byMe).
            // Calls fetch_audio webhook for the contribution_id, downloads
            // from Drive, plays via AudioPlayer. Disabled while another
            // playback is in progress.
            if (myRec != null && myRec.contributionId != null)
              IconButton(
                tooltip: 'Play your recording',
                icon: Icon(
                  _isPlaying && _playingForKey == item.audioKey
                      ? Icons.hourglass_bottom
                      : Icons.play_circle_outline,
                  color: Colors.blue.shade700,
                ),
                iconSize: 24,
                onPressed: _isPlaying
                    ? null
                    : () => _playUserRecording(item, myRec),
              ),
            IconButton(
              tooltip: 'Hear reference TTS',
              icon: Icon(Icons.volume_up,
                  color: Colors.green.shade700),
              iconSize: 22,
              onPressed: () => _playReference(item),
            ),
            IconButton(
              tooltip:
                  isActive ? 'Cancel recording' : 'Record this',
              icon: Icon(
                isActive ? Icons.close : Icons.mic,
                color: isActive
                    ? Colors.redAccent
                    : Colors.deepPurple,
              ),
              iconSize: 26,
              onPressed: isActive
                  ? _cancelRecording
                  : () => _startRecording(item),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusLine(_RecordableItem item, List<RecordingDoc> recs,
      bool byMe) {
    if (recs.isEmpty) {
      return Row(
        children: [
          Icon(Icons.radio_button_unchecked,
              size: 11, color: Colors.orange.shade700),
          const SizedBox(width: 4),
          Text('Not recorded',
              style: TextStyle(
                  fontSize: 10, color: Colors.orange.shade700)),
        ],
      );
    }
    final latest = recs.first;
    final age = _agoLabel(latest.recordedAt);
    final name = latest.recordedByName.contains('@')
        ? latest.recordedByName.split('@').first
        : latest.recordedByName;
    final more = recs.length > 1 ? ' (+${recs.length - 1} more)' : '';
    // v1.13.3 fix: status text/icon colors now use darker shades that
    // read on the app's cream background (was greenAccent/lightBlueAccent
    // which only worked on a dark theme).
    final fg = byMe ? Colors.green.shade700 : Colors.blue.shade700;
    return Row(
      children: [
        Icon(
          byMe ? Icons.check_circle : Icons.people_alt_outlined,
          size: 11,
          color: fg,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            byMe && recs.length == 1
                ? 'You · $age'
                : '$name · $age$more',
            style: TextStyle(fontSize: 10, color: fg),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// One-row strip of small badges showing which recorders have a
  /// shipped clip for this item. Pulls from NativeAudioInventory
  /// (build-time snapshot of audio/native/ + audio/native_kids/).
  /// Returns SizedBox.shrink when the inventory hasn't loaded yet
  /// (graceful — the line just doesn't render).
  ///
  /// Active recorder's badge gets a colored fill so the dev sees at a
  /// glance: "this row needs MY recording" vs "this row is covered for
  /// me but missing for other kids" vs "fully covered".
  Widget _inventoryBadges(_RecordableItem item) {
    final inv = NativeAudioInventory.instance;
    if (!inv.isLoaded) return const SizedBox.shrink();

    final activeSlug = _activeRecorderKidSlug();
    final activeAdultSlug = _activeRecorderAdultSlug();
    final canonicalOwner = inv.canonicalRecorderFor(item.audioKey);

    // S dot is filled when Dr. Sama owns the canonical recording.
    // B dot is filled when Berlin owns it. They're mutually exclusive
    // because canonical is single-slot — whoever recorded last wins.
    // If canonical exists but ownership is null (manifest v1 or
    // unknown contributor), neither dot fills.
    final samaCovered = canonicalOwner == 'samagids';
    final berlinCovered = canonicalOwner == 'berlin';

    // Order: boy team (joel/janelle), girl team (joyce/jadyne),
    // then adults (S / B). Active recorder's badge gets the
    // orange highlight ring.
    const kids = [
      ('joel', 'J'),
      ('janelle', 'N'),
      ('joyce', 'Y'),
      ('jadyne', 'D'),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          for (final (slug, initial) in kids)
            _CoverageDot(
              initial: initial,
              tooltip: PronunciationService.kidDisplayNames[slug] ?? slug,
              covered: inv.hasKidRecording(item.audioKey, slug),
              active: slug == activeSlug,
            ),
          const SizedBox(width: 6),
          // Dr. Sama (canonical, when recorder=samagids)
          _CoverageDot(
            initial: 'S',
            tooltip: 'Dr. Guidion Sama (canonical)',
            covered: samaCovered,
            active: activeAdultSlug == 'samagids',
            isAdult: true,
          ),
          // Berlin Sama (canonical, when recorder=berlin)
          _CoverageDot(
            initial: 'B',
            tooltip: 'Berlin Sama (canonical)',
            covered: berlinCovered,
            active: activeAdultSlug == 'berlin',
            isAdult: true,
          ),
        ],
      ),
    );
  }

  /// Returns 'samagids' / 'berlin' if the active recorder picker is one
  /// of the adults, or null when it's a kid / guest. Mirrors the
  /// _activeRecorderKidSlug helper but for the adult-tier badges.
  String? _activeRecorderAdultSlug() {
    final norm = _activeRecorder.trim().toLowerCase();
    if (norm.isEmpty) return null;
    if (norm == 'berlin' || norm.startsWith('berlin ')) return 'berlin';
    if (norm == 'sama' || norm == 'samagids' || norm.contains('guidion')) {
      return 'samagids';
    }
    return null;
  }

  String _agoLabel(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inDays > 1) return '${d.inDays}d ago';
    if (d.inHours > 1) return '${d.inHours}h ago';
    if (d.inMinutes > 1) return '${d.inMinutes}m ago';
    return 'just now';
  }

  Widget _buildRecordingPanel() {
    final item = _allItems.firstWhere(
      (i) => i.audioKey == _recordingForKey,
      orElse: () => _RecordableItem(
          awing: '', english: '', source: 'word'),
    );
    // SafeArea pushes the panel above the phone's gesture nav / 3-button
    // nav bar so Play / Save / Re-record buttons aren't clipped by the
    // home indicator on Android 10+ phones and on iOS.
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          border: const Border(
              top: BorderSide(color: Colors.purpleAccent)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.fiber_manual_record,
                  color: Colors.redAccent, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.awing,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                  '${_recordingDuration.inSeconds}/${_maxRecordSeconds}s',
                  style: TextStyle(
                      fontSize: 12,
                      color: _isRecording
                          ? Colors.redAccent
                          : Colors.white54)),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close,
                    color: Colors.white54),
                onPressed: _cancelRecording,
                iconSize: 20,
              ),
            ],
          ),
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: LinearProgressIndicator(
                value:
                    _recordingDuration.inSeconds / _maxRecordSeconds,
                backgroundColor: Colors.grey.shade800,
                color: Colors.redAccent,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_hasRecording) ...[
                GestureDetector(
                  onTap: _isRecording
                      ? _stopRecording
                      : () => _startRecording(item),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording
                          ? Colors.red
                          : Colors.purpleAccent,
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _isPlaying ? null : _playRecording,
                  icon: Icon(_isPlaying
                      ? Icons.hourglass_bottom
                      : Icons.play_arrow),
                  label:
                      Text(_isPlaying ? 'Playing' : 'Play mine'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _startRecording(item),
                  icon: const Icon(Icons.refresh,
                      color: Colors.orangeAccent),
                  label: const Text('Redo',
                      style:
                          TextStyle(color: Colors.orangeAccent)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _submitting
                      ? null
                      : () => _submitRecording(item),
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white))
                      : const Icon(Icons.cloud_upload),
                  label: Text(
                      _submitting ? 'Saving…' : 'Save & ship'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small circular badge showing whether a recorder has covered an item.
/// Filled green = covered, hollow grey = not covered, with a colored
/// outline when this is the active recorder (so the dev sees at a glance
/// "the kid I'm picked as still needs this one"). Used in
/// _RecordTabState._inventoryBadges to render the 4 kid badges + Dr.
/// Sama canonical badge per item card.
class _CoverageDot extends StatelessWidget {
  final String initial;
  final String tooltip;
  final bool covered;
  final bool active;
  final bool isAdult;

  const _CoverageDot({
    required this.initial,
    required this.tooltip,
    required this.covered,
    required this.active,
    this.isAdult = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = 18.0;
    final coveredFill = isAdult ? Colors.indigo : Colors.green.shade600;
    final hollowFill = Colors.grey.shade300;
    final activeBorder = Colors.deepOrange;

    return Tooltip(
      message: covered
          ? '$tooltip — recorded${active ? " (active)" : ""}'
          : '$tooltip — missing${active ? " (active, you should record this)" : ""}',
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.only(right: 3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: covered ? coveredFill : hollowFill,
          border: active
              ? Border.all(color: activeBorder, width: 2)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: covered ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

// =====================================================================
//  USERS TAB — local accounts + Firebase cloud users
// =====================================================================

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  List<Map<String, dynamic>>? _cloudUsers;
  bool _loadingCloud = false;
  String? _cloudError;

  @override
  void initState() {
    super.initState();
    _fetchCloudUsers();
  }

  /// Session 61 — G6 security hardening.
  ///
  /// Write an append-only audit entry recording that the developer account
  /// performed a privileged cross-user read. Failure to write the audit
  /// entry is non-fatal (we still let the read proceed) but is logged to
  /// the debug console so regressions surface during testing.
  ///
  /// The Firestore rule (firestore.rules `match /audit/{auditId}`) enforces
  /// that:
  ///   - email field MUST equal request.auth.token.email (no impersonation)
  ///   - action is a string, userCount is an int
  ///   - update + delete are rejected (log is immutable)
  Future<void> _writeAuditLog({
    required String action,
    required int userCount,
    List<String>? userIds,
  }) async {
    try {
      final email = FirebaseAuth.instance.currentUser?.email;
      if (email == null) {
        debugPrint('Audit log: no Firebase auth user — skipping');
        return;
      }
      final entry = <String, dynamic>{
        'email': email,
        'action': action,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'userCount': userCount,
      };
      if (userIds != null && userIds.isNotEmpty && userIds.length <= 20) {
        // Cap list size to keep doc small (Firestore doc limit is 1 MiB
        // but we want to avoid runaway log entries on huge user sets).
        entry['userIds'] = userIds;
      }
      await FirebaseFirestore.instance.collection('audit').add(entry);
    } catch (e) {
      // Non-fatal — audit logging failures must not block the read itself.
      // But we log loudly so dev notices regressions (e.g. rule changes).
      debugPrint('Audit log write failed: $e');
    }
  }

  Future<void> _fetchCloudUsers() async {
    setState(() {
      _loadingCloud = true;
      _cloudError = null;
    });
    try {
      // Use collectionGroup('data') to find ALL user subcollection docs,
      // since many parent /users/{id} documents don't exist (phantom parents).
      final dataSnapshot =
          await FirebaseFirestore.instance.collectionGroup('data').get();

      // Session 61 — G6: record this privileged bulk read in the audit log.
      // We log the unique user count (number of distinct userIds touched),
      // not the doc count, since one user yields multiple data docs
      // (accounts, progress, settings).
      final uniqueUserIds = <String>{};
      for (final doc in dataSnapshot.docs) {
        final parts = doc.reference.path.split('/');
        if (parts.length >= 2 && parts[0] == 'users') {
          uniqueUserIds.add(parts[1]);
        }
      }
      // Fire-and-forget; the audit write is non-blocking.
      unawaited(_writeAuditLog(
        action: 'bulk_read_users',
        userCount: uniqueUserIds.length,
      ));

      // Extract unique user IDs from document paths: users/{userId}/data/{docType}
      final userDataMap = <String, Map<String, Map<String, dynamic>?>>{};
      for (final doc in dataSnapshot.docs) {
        final pathParts = doc.reference.path.split('/');
        // Expect: users / {userId} / data / {docType}
        if (pathParts.length >= 4 && pathParts[0] == 'users') {
          final userId = pathParts[1];
          final docType = pathParts[3]; // accounts, progress, or settings
          userDataMap.putIfAbsent(userId, () => {});
          userDataMap[userId]![docType] = doc.data();
        }
      }

      // Also try reading parent documents for those that exist
      final users = <Map<String, dynamic>>[];
      for (final entry in userDataMap.entries) {
        final userId = entry.key;
        final docs = entry.value;

        // Try to read parent doc (may not exist for older users)
        Map<String, dynamic>? parentData;
        try {
          final parentDoc = await FirebaseFirestore.instance
              .doc('users/$userId')
              .get();
          if (parentDoc.exists) {
            parentData = parentDoc.data();
          }
        } catch (_) {}

        users.add({
          'docId': userId,
          'email': parentData?['email'] ?? userId.replaceAll('_dot_', '.'),
          'appVersion': parentData?['app_version'],
          'profileCount': parentData?['profile_count'],
          'accounts': docs['accounts'],
          'progress': docs['progress'],
          'settings': docs['settings'],
          'updatedAt': parentData?['updated_at'] ??
              docs['accounts']?['updated_at'] ??
              docs['progress']?['updated_at'],
        });
      }

      if (mounted) {
        setState(() {
          _cloudUsers = users;
          _loadingCloud = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cloudError = e.toString();
          _loadingCloud = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        final accounts = auth.getAllAccounts();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Local summary
            Card(
              color: Colors.grey.shade900,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Local Users',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent.shade200)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _UserStatBox(
                            label: 'Accounts',
                            value: '${accounts.length}'),
                        _UserStatBox(
                            label: 'Profiles',
                            value: '${auth.totalProfileCount}'),
                        _UserStatBox(
                            label: 'Beginner',
                            value:
                                '${_countAtLevel(accounts, 'beginner')}'),
                        _UserStatBox(
                            label: 'Medium',
                            value:
                                '${_countAtLevel(accounts, 'medium')}'),
                        _UserStatBox(
                            label: 'Expert',
                            value:
                                '${_countAtLevel(accounts, 'expert')}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Local account list
            ...accounts
                .map((account) => _AccountCard(account: account)),

            const SizedBox(height: 24),

            // Firebase Cloud Users section
            Row(
              children: [
                const Icon(Icons.cloud, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text('Firebase Cloud Users',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_loadingCloud)
                  const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                else
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _fetchCloudUsers,
                    tooltip: 'Refresh cloud users',
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (_cloudError != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Error: $_cloudError',
                      style: const TextStyle(
                          color: Colors.red, fontSize: 12)),
                ),
              ),

            if (_cloudUsers != null && _cloudUsers!.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No cloud users found.',
                      style: TextStyle(color: Colors.grey.shade600)),
                ),
              ),

            if (_cloudUsers != null)
              ...(_cloudUsers!.map((user) => _CloudUserCard(user: user))),
          ],
        );
      },
    );
  }

  static int _countAtLevel(List<UserAccount> accounts, String level) {
    int count = 0;
    for (final a in accounts) {
      for (final p in a.profiles) {
        if (p.currentLevel == level) count++;
      }
    }
    return count;
  }
}

class _CloudUserCard extends StatelessWidget {
  final Map<String, dynamic> user;

  const _CloudUserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final email = user['email'] ?? 'Unknown';
    final updatedAt = user['updatedAt'] as String?;
    final appVersion = user['appVersion'] as String?;
    final accountsData = user['accounts']?['data'];
    final progressData = user['progress']?['data'];
    final settingsData = user['settings']?['data'];

    int profileCount = 0;
    int totalXP = 0;
    List<Map<String, dynamic>> profileDetails = [];

    if (accountsData is Map) {
      for (final entry in accountsData.values) {
        if (entry is Map && entry['profiles'] is List) {
          for (final p in entry['profiles']) {
            profileCount++;
            final xp = (p['totalXP'] as int?) ?? 0;
            totalXP += xp;
            profileDetails.add({
              'name': p['displayName'] ?? 'Unknown',
              'level': p['currentLevel'] ?? '?',
              'xp': xp,
              'mediumUnlocked': p['mediumUnlocked'] == true,
              'expertUnlocked': p['expertUnlocked'] == true,
              'lessonsCompleted': p['lessonsCompleted'] is Map
                  ? (p['lessonsCompleted'] as Map).length
                  : 0,
            });
          }
        }
      }
    }

    if (progressData is Map) {
      final xp = progressData['total_xp'];
      if (xp is int && totalXP == 0) totalXP = xp;
    }

    String lastSync = 'Never';
    if (updatedAt != null) {
      try {
        final dt = DateTime.parse(updatedAt);
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) {
          lastSync = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          lastSync = '${diff.inHours}h ago';
        } else {
          lastSync = '${diff.inDays}d ago';
        }
      } catch (_) {
        lastSync = updatedAt;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading:
            const Icon(Icons.cloud_circle, color: Colors.blue),
        title: Text(email,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '$profileCount profiles | XP: $totalXP | Synced: $lastSync',
            style: const TextStyle(fontSize: 12)),
        children: [
          // App version & sync info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                if (appVersion != null)
                  Chip(
                    label: Text('v$appVersion',
                        style: const TextStyle(fontSize: 11)),
                    backgroundColor: Colors.blue.shade50,
                    visualDensity: VisualDensity.compact,
                  ),
                const SizedBox(width: 8),
                Text('Last sync: $lastSync',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),

          // Profile details
          if (profileDetails.isNotEmpty)
            ...profileDetails.map((p) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.person, size: 18),
                  title: Text(p['name'] as String),
                  subtitle: Text(
                    'Level: ${p['level']} | XP: ${p['xp']} | '
                    'Lessons: ${p['lessonsCompleted']}'
                    '${p['mediumUnlocked'] == true ? ' | Medium ✓' : ''}'
                    '${p['expertUnlocked'] == true ? ' | Expert ✓' : ''}',
                    style: const TextStyle(fontSize: 11),
                  ),
                )),

          // Cloud progress data
          if (progressData is Map) ...[
            const Divider(),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cloud Progress',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  if (progressData['daily_streak'] != null)
                    Text(
                        'Daily streak: ${progressData['daily_streak']}',
                        style: const TextStyle(fontSize: 12)),
                  if (progressData['total_xp'] != null)
                    Text('Total XP: ${progressData['total_xp']}',
                        style: const TextStyle(fontSize: 12)),
                  if (progressData['words_learned'] != null)
                    Text(
                        'Words learned: ${_summarizeJson(progressData['words_learned'])}',
                        style: const TextStyle(fontSize: 12)),
                  if (progressData['completed_lessons'] != null)
                    Text(
                        'Lessons: ${_summarizeJson(progressData['completed_lessons'])}',
                        style: const TextStyle(fontSize: 12)),
                  if (progressData['quiz_scores'] != null)
                    Text(
                        'Quizzes: ${_summarizeJson(progressData['quiz_scores'])}',
                        style: const TextStyle(fontSize: 12)),
                  if (progressData['badges'] != null)
                    Text(
                        'Badges: ${_summarizeJson(progressData['badges'])}',
                        style: const TextStyle(fontSize: 12)),
                  if (progressData['spaced_repetition'] != null)
                    Text(
                        'Spaced rep: ${_summarizeJson(progressData['spaced_repetition'])}',
                        style: const TextStyle(fontSize: 12)),
                  if (progressData['viewed_letters'] != null)
                    Text(
                        'Viewed letters: ${_summarizeJson(progressData['viewed_letters'])}',
                        style: const TextStyle(fontSize: 12)),
                  if (progressData['viewed_words'] != null)
                    Text(
                        'Viewed words: ${_summarizeJson(progressData['viewed_words'])}',
                        style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],

          // Settings data
          if (settingsData is Map) ...[
            const Divider(),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('User Settings',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                      'Dark mode: ${settingsData['isDarkMode'] == true ? 'ON' : 'OFF'}',
                      style: const TextStyle(fontSize: 12)),
                  Text(
                      'Auto-sync: ${settingsData['cloud_auto_sync'] == true ? 'ON' : 'OFF'}',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static String _summarizeJson(dynamic data) {
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is List) return '${decoded.length} items';
        if (decoded is Map) return '${decoded.length} entries';
      } catch (_) {}
      return data.length > 40 ? '${data.substring(0, 40)}...' : data;
    }
    if (data is List) return '${data.length} items';
    if (data is Map) return '${data.length} entries';
    return data.toString();
  }
}

// =====================================================================
//  ANALYTICS TAB — all activity from local + Firebase
// =====================================================================

class _AnalyticsTab extends StatefulWidget {
  const _AnalyticsTab();

  @override
  State<_AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<_AnalyticsTab> {
  String _selectedCategory = 'All';
  bool _showEventDetail = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        final accounts = auth.getAllAccounts();
        final allProfiles =
            accounts.expand((a) => a.profiles).toList();

        // Compute quiz stats from all profiles
        final quizScores = <String, List<int>>{};
        for (final p in allProfiles) {
          for (final entry in p.quizBestScores.entries) {
            quizScores.putIfAbsent(entry.key, () => []);
            quizScores[entry.key]!.add(entry.value);
          }
        }

        // Compute lesson stats
        final lessonCounts = <String, int>{};
        for (final p in allProfiles) {
          for (final lessonId in p.lessonsCompleted.keys) {
            if (p.lessonsCompleted[lessonId] == true) {
              lessonCounts[lessonId] =
                  (lessonCounts[lessonId] ?? 0) + 1;
            }
          }
        }

        // Local analytics events
        final analytics = AnalyticsService.instance;
        final activityEvents = analytics.getEvents('Activity');
        final quizEvents = analytics.getEvents('Quizzes');
        final feedbackEvents = analytics.getEvents('Feedback');
        final errorEvents = analytics.getEvents('Errors');
        final sessionEvents = analytics.getEvents('Sessions');

        // Progress service data
        final progress = context.watch<ProgressService>();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Overview card
            Card(
              color: Colors.grey.shade900,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Overview',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent.shade200)),
                    const SizedBox(height: 12),
                    _AnalyticRow(
                        label: 'Total accounts',
                        value: '${accounts.length}'),
                    _AnalyticRow(
                        label: 'Total profiles',
                        value: '${allProfiles.length}'),
                    _AnalyticRow(
                        label: 'Total XP earned',
                        value:
                            '${allProfiles.fold(0, (sum, p) => sum + p.totalXP)}'),
                    _AnalyticRow(
                        label: 'Total lessons completed',
                        value:
                            '${allProfiles.fold(0, (sum, p) => sum + p.lessonsCompleted.length)}'),
                    _AnalyticRow(
                        label: 'Medium unlocked',
                        value:
                            '${allProfiles.where((p) => p.mediumUnlocked).length}'),
                    _AnalyticRow(
                        label: 'Expert unlocked',
                        value:
                            '${allProfiles.where((p) => p.expertUnlocked).length}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Progress service stats
            Card(
              color: Colors.teal.shade900,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Device Progress',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.tealAccent.shade100)),
                    const SizedBox(height: 12),
                    _AnalyticRow(
                        label: 'Level',
                        value: '${progress.currentLevel}'),
                    _AnalyticRow(
                        label: 'Total XP', value: '${progress.totalXP}'),
                    _AnalyticRow(
                        label: 'Daily streak',
                        value: '${progress.dailyStreak} days'),
                    _AnalyticRow(
                        label: 'Badges unlocked',
                        value:
                            '${progress.getUnlockedBadges().length} / ${progress.getAllBadges().length}'),
                    _AnalyticRow(
                        label: 'Words in review',
                        value:
                            '${progress.getWordsToReview().length} due'),
                    _AnalyticRow(
                        label: 'Lessons completed',
                        value:
                            '${progress.getCompletedLessons().length}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Event log summary
            Card(
              color: Colors.indigo.shade900,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Event Log',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    Colors.lightBlueAccent.shade100)),
                        const Spacer(),
                        Text(
                            '${analytics.totalEventCount} total',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _EventCountRow(
                        label: 'Activities',
                        count: activityEvents.length,
                        icon: Icons.touch_app,
                        color: Colors.blue),
                    _EventCountRow(
                        label: 'Quizzes',
                        count: quizEvents.length,
                        icon: Icons.quiz,
                        color: Colors.green),
                    _EventCountRow(
                        label: 'Feedback',
                        count: feedbackEvents.length,
                        icon: Icons.feedback,
                        color: Colors.amber),
                    _EventCountRow(
                        label: 'Errors',
                        count: errorEvents.length,
                        icon: Icons.error,
                        color: Colors.red),
                    _EventCountRow(
                        label: 'Sessions',
                        count: sessionEvents.length,
                        icon: Icons.timer,
                        color: Colors.purple),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showEventDetail = !_showEventDetail;
                          });
                        },
                        icon: Icon(_showEventDetail
                            ? Icons.expand_less
                            : Icons.expand_more),
                        label: Text(_showEventDetail
                            ? 'Hide Event Details'
                            : 'Show Event Details'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Detailed event list (expandable)
            if (_showEventDetail) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['All', 'Activity', 'Quizzes', 'Feedback', 'Errors', 'Sessions']
                    .map((cat) => ChoiceChip(
                          label: Text(cat, style: const TextStyle(fontSize: 12)),
                          selected: _selectedCategory == cat,
                          onSelected: (_) {
                            setState(() => _selectedCategory = cat);
                          },
                          selectedColor: Colors.greenAccent,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              ..._buildEventList(analytics),
            ],

            const SizedBox(height: 16),

            // Quiz performance
            if (quizScores.isNotEmpty) ...[
              const Text('Quiz Performance',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...quizScores.entries.map((entry) {
                final avg = entry.value.reduce((a, b) => a + b) /
                    entry.value.length;
                final best =
                    entry.value.reduce((a, b) => a > b ? a : b);
                return Card(
                  child: ListTile(
                    leading: Icon(
                      best == 100
                          ? Icons.star
                          : best >= 80
                              ? Icons.star_half
                              : Icons.star_border,
                      color: best == 100
                          ? Colors.amber
                          : best >= 80
                              ? Colors.orange
                              : Colors.grey,
                    ),
                    title: Text(entry.key),
                    subtitle: Text(
                      'Avg: ${avg.toStringAsFixed(1)}% | Best: $best% | Taken: ${entry.value.length}x',
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 16),

            // Lesson completion breakdown
            if (lessonCounts.isNotEmpty) ...[
              const Text('Lesson Completion',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...lessonCounts.entries.map((entry) => Card(
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                      title: Text(entry.key),
                      trailing: Text(
                          '${entry.value} user${entry.value > 1 ? "s" : ""}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                    ),
                  )),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _buildEventList(AnalyticsService analytics) {
    final categories = _selectedCategory == 'All'
        ? ['Activity', 'Quizzes', 'Feedback', 'Errors', 'Sessions']
        : [_selectedCategory];

    final allEvents = <Map<String, dynamic>>[];
    for (final cat in categories) {
      final events = analytics.getEvents(cat);
      for (final event in events) {
        allEvents.add({'category': cat, 'data': event});
      }
    }

    // Sort by timestamp descending (first element is timestamp)
    allEvents.sort((a, b) {
      final aTime = (a['data'] as List).isNotEmpty
          ? (a['data'] as List)[0].toString()
          : '';
      final bTime = (b['data'] as List).isNotEmpty
          ? (b['data'] as List)[0].toString()
          : '';
      return bTime.compareTo(aTime);
    });

    if (allEvents.isEmpty) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No events in this category.',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
        ),
      ];
    }

    return allEvents.take(50).map((item) {
      final cat = item['category'] as String;
      final data = item['data'] as List;
      final timestamp =
          data.isNotEmpty ? data[0].toString() : 'Unknown';

      String title = cat;
      String subtitle = '';

      // Format based on category
      if (cat == 'Activity' && data.length >= 5) {
        title = data[2]?.toString() ?? 'Activity';
        subtitle =
            'Level: ${data[3]} | Lesson: ${data[4]}';
      } else if (cat == 'Quizzes' && data.length >= 7) {
        title = '${data[2]} (${data[3]})';
        subtitle =
            'Score: ${data[4]}% | ${data[5]}/${data[6]} correct';
      } else if (cat == 'Feedback' && data.length >= 5) {
        title = 'Feedback: ${data[2]}';
        subtitle = data[4]?.toString() ?? '';
      } else if (cat == 'Errors' && data.length >= 4) {
        title = 'Error: ${data[2]}';
        subtitle = data[3]?.toString() ?? '';
      } else if (cat == 'Sessions' && data.length >= 6) {
        title = 'Session ${data[2]}';
        subtitle =
            '${data[3]} min | ${data[4]} lessons | ${data[5]} quizzes';
      }

      // Format timestamp
      String timeStr = timestamp;
      try {
        final dt = DateTime.parse(timestamp);
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) {
          timeStr = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          timeStr = '${diff.inHours}h ago';
        } else {
          timeStr = '${diff.inDays}d ago';
        }
      } catch (_) {}

      IconData icon;
      Color iconColor;
      switch (cat) {
        case 'Activity':
          icon = Icons.touch_app;
          iconColor = Colors.blue;
          break;
        case 'Quizzes':
          icon = Icons.quiz;
          iconColor = Colors.green;
          break;
        case 'Feedback':
          icon = Icons.feedback;
          iconColor = Colors.amber;
          break;
        case 'Errors':
          icon = Icons.error;
          iconColor = Colors.red;
          break;
        case 'Sessions':
          icon = Icons.timer;
          iconColor = Colors.purple;
          break;
        default:
          icon = Icons.circle;
          iconColor = Colors.grey;
      }

      return Card(
        margin: const EdgeInsets.only(bottom: 4),
        child: ListTile(
          dense: true,
          leading: Icon(icon, color: iconColor, size: 20),
          title: Text(title,
              style: const TextStyle(fontSize: 13)),
          subtitle: subtitle.isNotEmpty
              ? Text(subtitle,
                  style: const TextStyle(fontSize: 11))
              : null,
          trailing: Text(timeStr,
              style: const TextStyle(
                  fontSize: 10, color: Colors.grey)),
        ),
      );
    }).toList();
  }
}

class _EventCountRow extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _EventCountRow({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Text('$count',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

// =====================================================================
//  CONTENT TAB — vocabulary, phrases, stories, alphabet stats
// =====================================================================

class _ContentTab extends StatelessWidget {
  const _ContentTab();

  @override
  Widget build(BuildContext context) {
    // Compute stats from data files
    final vocabWords = allVocabulary;
    final phrases = awingPhrases;
    final letters = awingAlphabet;
    final toneTypes = awingTones;
    final clusters = [
      ...prenasalizedClusters,
      ...palatalizedClusters,
      ...labializedClusters,
    ];

    // Category breakdown
    final categoryCount = <String, int>{};
    for (final w in vocabWords) {
      categoryCount[w.category] =
          (categoryCount[w.category] ?? 0) + 1;
    }
    final sortedCategories = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Difficulty breakdown
    int beginner = 0, medium = 0, expert = 0;
    for (final w in vocabWords) {
      final d = w.difficulty;
      if (d == 1) {
        beginner++;
      } else if (d == 2) {
        medium++;
      } else {
        expert++;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Content summary card
        Card(
          color: Colors.grey.shade900,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Content Summary',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent.shade200)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatBox(
                        label: 'Words',
                        value: '${vocabWords.length}',
                        color: Colors.blue),
                    _StatBox(
                        label: 'Phrases',
                        value: '${phrases.length}',
                        color: Colors.purple),
                    _StatBox(
                        label: 'Letters',
                        value: '${letters.length}',
                        color: Colors.orange),
                    _StatBox(
                        label: 'Tones',
                        value: '${toneTypes.length}',
                        color: Colors.teal),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Difficulty breakdown
        Card(
          color: Colors.blueGrey.shade900,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Vocabulary by Difficulty',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 12),
                _DifficultyBar(
                    label: 'Beginner (1)',
                    count: beginner,
                    total: vocabWords.length,
                    color: Colors.green),
                const SizedBox(height: 6),
                _DifficultyBar(
                    label: 'Medium (2)',
                    count: medium,
                    total: vocabWords.length,
                    color: Colors.orange),
                const SizedBox(height: 6),
                _DifficultyBar(
                    label: 'Expert (3)',
                    count: expert,
                    total: vocabWords.length,
                    color: Colors.red),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Category breakdown
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Words by Category',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...sortedCategories.map((entry) => Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(
                              width: 100,
                              child: Text(entry.key,
                                  style: const TextStyle(
                                      fontSize: 13))),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: entry.value /
                                  (sortedCategories.first.value),
                              backgroundColor:
                                  Colors.grey.shade200,
                              color: _categoryColor(entry.key),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                              width: 35,
                              child: Text('${entry.value}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: 13))),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Language features
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Language Features',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _AnalyticRow(
                    label: 'Tone types', value: '${toneTypes.length}'),
                _AnalyticRow(
                    label: 'Consonant clusters',
                    value: '${clusters.length}'),
                _AnalyticRow(
                    label: 'Vowels',
                    value:
                        '${letters.where((l) => l.type == "vowel").length}'),
                _AnalyticRow(
                    label: 'Consonants',
                    value:
                        '${letters.where((l) => l.type == "consonant").length}'),
                _AnalyticRow(
                    label: 'Syllable types',
                    value: '${syllableTypes.length}'),
                _AnalyticRow(
                    label: 'Verb suffixes',
                    value: '${verbSuffixes.length}'),
                _AnalyticRow(
                    label: 'Allophonic rules',
                    value: '${allophonicRules.length}'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Color _categoryColor(String cat) {
    switch (cat) {
      case 'things':
        return Colors.blue;
      case 'actions':
        return Colors.orange;
      case 'descriptive':
        return Colors.purple;
      case 'family':
        return Colors.pink;
      case 'body':
        return Colors.red;
      case 'animals':
        return Colors.brown;
      case 'nature':
        return Colors.green;
      case 'food':
        return Colors.amber;
      case 'numbers':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}

class _DifficultyBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _DifficultyBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
            width: 100,
            child: Text(label,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 12))),
        Expanded(
          child: LinearProgressIndicator(
            value: total > 0 ? count / total : 0,
            backgroundColor: Colors.grey.shade700,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 55,
          child: Text('$count',
              textAlign: TextAlign.right,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
      ],
    );
  }
}

// =====================================================================
//  SETTINGS TAB — debug info, export, Firebase status, security
// =====================================================================

class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final cloud = context.watch<CloudBackupService>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('App Info',
            style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading:
                const Icon(Icons.bug_report, color: Colors.orange),
            title: const Text('Debug Info'),
            subtitle: Text(
                'Version ${AboutScreen.appVersion} | Build ${AboutScreen.buildNumber}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDebugInfo(context),
          ),
        ),
        const SizedBox(height: 16),

        // Firebase status
        const Text('Cloud & Firebase',
            style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          color: cloud.isSignedIn
              ? Colors.green.shade50
              : Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      cloud.isSignedIn
                          ? Icons.cloud_done
                          : Icons.cloud_off,
                      color: cloud.isSignedIn
                          ? Colors.green
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cloud.isSignedIn
                          ? 'Firebase Connected'
                          : 'Firebase Not Connected',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (cloud.connectedEmail != null)
                  Text('Email: ${cloud.connectedEmail}',
                      style: const TextStyle(fontSize: 13)),
                if (cloud.lastBackupTime != null)
                  Text('Last backup: ${_formatTime(cloud.lastBackupTime!)}',
                      style: const TextStyle(fontSize: 13)),
                Text(
                    'Auto-sync: ${cloud.autoSync ? "ON" : "OFF"}',
                    style: const TextStyle(fontSize: 13)),
                if (cloud.syncError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Error: ${cloud.syncError}',
                        style: const TextStyle(
                            color: Colors.red, fontSize: 12)),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: cloud.isSyncing
                          ? null
                          : () async {
                              await cloud.backupAll();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(cloud.syncError ??
                                      'Backup complete'),
                                ));
                              }
                            },
                      icon: cloud.isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                          : const Icon(Icons.backup, size: 18),
                      label: const Text('Backup Now'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: cloud.isSyncing
                          ? null
                          : () async {
                              await cloud.restoreAll();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(cloud.syncError ??
                                      'Restore complete'),
                                ));
                              }
                            },
                      icon:
                          const Icon(Icons.cloud_download, size: 18),
                      label: const Text('Restore'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Data export
        const Text('Data Management',
            style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading:
                const Icon(Icons.download, color: Colors.green),
            title: const Text('Export All Data'),
            subtitle: const Text(
                'Export accounts, progress, analytics as JSON'),
            trailing: _exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right),
            onTap: _exporting ? null : () => _exportData(context),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.analytics_outlined,
                color: Colors.blue),
            title: const Text('Export Analytics Events'),
            subtitle: const Text('Export local event log as JSON'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportAnalytics(context),
          ),
        ),
        const SizedBox(height: 24),

        // ML — Phase 1B grader smoke test entry
        const Text('Machine learning',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          color: Colors.deepPurple.shade50,
          child: ListTile(
            leading: const Icon(Icons.science_outlined,
                color: Colors.deepPurple),
            title: const Text('Pronunciation grader smoke test'),
            subtitle: const Text(
                'Phase 1B: load FP16 MMS-FA ONNX model from /sdcard/awing_grader/ '
                'and run inference on a sideloaded WAV. Verifies on-device feasibility.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GraderSmokeTestScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // Security
        const Text('Security',
            style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          color: Colors.red.shade50,
          child: ListTile(
            leading: const Icon(Icons.lock, color: Colors.red),
            title: const Text('Deactivate Developer Mode'),
            subtitle:
                const Text('Auto-disables after 5 min of inactivity'),
            trailing:
                const Icon(Icons.exit_to_app, color: Colors.red),
            onTap: () async {
              final ok = await ParentalGate.verify(
                context,
                title: 'Deactivate Developer Mode',
                message:
                    'Only the developer should deactivate developer mode.',
              );
              if (!ok || !context.mounted) return;
              final auth = context.read<AuthService>();
              auth.disableDevMode();
              Navigator.of(context)
                  .popUntil((route) => route.isFirst);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Developer mode deactivated'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.delete_forever,
                color: Colors.red),
            title: const Text('Clear Local Progress'),
            subtitle: const Text(
                'Reset all progress data on this device'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _confirmClearProgress(context),
          ),
        ),
      ],
    );
  }

  void _showDebugInfo(BuildContext context) {
    final cloud = context.read<CloudBackupService>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Debug Info'),
        content: Text(
          'Awing AI Learning v1.6.1+28\n'
          'Flutter SDK: 3.22+\n'
          'Dart SDK: 3.4+\n'
          'Auth: Google Sign-In + SharedPreferences\n'
          'Cloud: Firebase Firestore (Spark plan)\n'
          'Exam: TCP sockets + mDNS (LAN)\n'
          'TTS: Edge TTS (6 Swahili voices)\n'
          'Firebase signed in: ${cloud.isSignedIn}\n'
          'Cloud email: ${cloud.connectedEmail ?? "none"}\n'
          'Auto-sync: ${cloud.autoSync}\n'
          'Analytics events: ${AnalyticsService.instance.totalEventCount}',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    setState(() => _exporting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final auth = context.read<AuthService>();
      final accounts = auth.getAllAccounts();

      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'appVersion': '${AboutScreen.appVersion}+${AboutScreen.buildNumber}',
        'accounts': accounts.map((a) => a.toJson()).toList(),
        'progress': {
          'completed_lessons':
              prefs.getString('completed_lessons'),
          'quiz_scores': prefs.getString('quiz_scores'),
          'daily_streak': prefs.getInt('daily_streak'),
          'total_xp': prefs.getInt('total_xp'),
          'badges': prefs.getString('badges'),
          'viewed_letters': prefs.getString('viewed_letters'),
          'viewed_words': prefs.getString('viewed_words'),
          'spaced_repetition':
              prefs.getString('spaced_repetition'),
        },
        'analytics': {
          'activity':
              AnalyticsService.instance.getEvents('Activity'),
          'quizzes':
              AnalyticsService.instance.getEvents('Quizzes'),
          'feedback':
              AnalyticsService.instance.getEvents('Feedback'),
          'errors':
              AnalyticsService.instance.getEvents('Errors'),
          'sessions':
              AnalyticsService.instance.getEvents('Sessions'),
        },
      };

      final jsonStr =
          const JsonEncoder.withIndent('  ').convert(exportData);
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/awing_export_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonStr);

      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
    if (mounted) setState(() => _exporting = false);
  }

  Future<void> _exportAnalytics(BuildContext context) async {
    try {
      final analytics = AnalyticsService.instance;
      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'totalEvents': analytics.totalEventCount,
        'activity': analytics.getEvents('Activity'),
        'quizzes': analytics.getEvents('Quizzes'),
        'feedback': analytics.getEvents('Feedback'),
        'errors': analytics.getEvents('Errors'),
        'sessions': analytics.getEvents('Sessions'),
      };

      final jsonStr =
          const JsonEncoder.withIndent('  ').convert(exportData);
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/awing_analytics_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonStr);

      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _confirmClearProgress(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Progress?'),
        content: const Text(
          'This will reset all progress data on this device: '
          'lessons, quiz scores, XP, badges, streaks, and spaced repetition. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final progress = context.read<ProgressService>();
              await progress.clearAllProgress();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Progress cleared'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return isoString;
    }
  }
}

// =====================================================================
//  SHARED WIDGETS
// =====================================================================

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style:
                const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _UserStatBox extends StatelessWidget {
  final String label;
  final String value;

  const _UserStatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent)),
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: Colors.white54)),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  final UserAccount account;

  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(
          account.authMethod == 'google'
              ? Icons.g_mobiledata
              : Icons.email,
          color: account.isDeveloper ? Colors.greenAccent : null,
        ),
        title: Text(account.email,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: account.isDeveloper
                    ? Colors.greenAccent
                    : null)),
        subtitle: Text(
            '${account.profiles.length} profiles | ${account.authMethod}'),
        children: account.profiles.map((profile) {
          return ListTile(
            leading: Text(profile.avatarEmoji,
                style: const TextStyle(fontSize: 28)),
            title: Text(profile.displayName),
            subtitle: Text(
              'Level: ${profile.currentLevel} | '
              'XP: ${profile.totalXP} | '
              'Lessons: ${profile.lessonsCompleted.length} | '
              'Medium: ${profile.mediumUnlocked ? "Y" : "N"} | '
              'Expert: ${profile.expertUnlocked ? "Y" : "N"}\n'
              'Created: ${_formatDate(profile.createdAt)} | '
              'Active: ${_formatDate(profile.lastActiveAt)}',
              style: const TextStyle(fontSize: 11),
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (action) {
                final auth = context.read<AuthService>();
                if (action == 'unlock_medium') {
                  auth.devUnlockLevel(profile.id, 'medium');
                } else if (action == 'unlock_expert') {
                  auth.devUnlockLevel(profile.id, 'expert');
                }
              },
              itemBuilder: (_) => [
                if (!profile.mediumUnlocked)
                  const PopupMenuItem(
                      value: 'unlock_medium',
                      child: Text('Unlock Medium')),
                if (!profile.expertUnlocked)
                  const PopupMenuItem(
                      value: 'unlock_expert',
                      child: Text('Unlock Expert')),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _AnalyticRow extends StatelessWidget {
  final String label;
  final String value;

  const _AnalyticRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent)),
        ],
      ),
    );
  }
}
