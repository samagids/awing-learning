import 'dart:async';
import 'package:flutter/material.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:awing_ai_learning/services/contribution_service.dart';
import 'package:awing_ai_learning/services/analytics_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/native_audio_inventory.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/screens/contribute/record_picker_screen.dart';
import 'package:awing_ai_learning/components/awing_text_field.dart';
import 'package:awing_ai_learning/components/image_attachment_picker.dart';

/// User-facing screen for submitting contributions.
///
/// v1.18.0+ — 5 top-level tabs, one per contribution mode:
///   1. Record           → discovery-first picker (RecordPickerScreen)
///   2. Fix spelling     → existing-word picker + correction
///   3. Fix pronunciation→ existing-word picker + pronunciation guide
///   4. Add new word     → free-form Awing + English + category
///   5. Add new sentence → free-form Awing + English translation
///
/// Each form tab pre-selects the matching ContributionType, so users
/// don't need to pick the type with chips anymore — the tab IS the type.
class ContributeScreen extends StatefulWidget {
  /// Optional pre-filled word (when user taps "Report" on a specific word)
  final String? prefillWord;
  final String? prefillCategory;

  const ContributeScreen({Key? key, this.prefillWord, this.prefillCategory})
      : super(key: key);

  @override
  State<ContributeScreen> createState() => _ContributeScreenState();
}

class _ContributeScreenState extends State<ContributeScreen> {
  final _wordController = TextEditingController();
  final _correctionController = TextEditingController();
  final _englishController = TextEditingController();
  final _pronunciationController = TextEditingController();
  final _notesController = TextEditingController();

  String _category = 'body';
  bool _submitted = false;
  // Session 64 (M12): flipped to true once NativeAudioInventory.load
  // completes. `_alreadyRecorded` returns false until then, so we use
  // this to disable the record UI meanwhile (see _startRecording).
  bool _nativeInventoryLoaded = false;
  /// Set to true once a submission has been posted to the webhook.
  /// Drives the "Sent to Developer" success message. No longer means
  /// "email app opened" -- the webhook sends the email server-side now.

  /// The type of the most recent submission — used by the thank-you
  /// screen to copy back the right reset state.
  ContributionType _submittedType = ContributionType.spellingCorrection;

  // Audio recording
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _isRecording = false;
  bool _hasRecording = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  /// v1.22.0 (Session 66): optional photo attached to the contribution.
  /// Users tap the ImageAttachmentPicker to pick from camera or gallery;
  /// image_picker compresses at pick time to 1024x1024 JPEG q80. Path
  /// is passed to ContributionService.submit which base64-encodes and
  /// inlines it in the webhook payload.
  String? _imagePath;

  static const _categories = [
    'body', 'animals', 'nature', 'actions', 'things', 'family', 'numbers',
    'greeting', 'question', 'classroom', 'farewell', 'grammar', 'other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.prefillWord != null) {
      _wordController.text = widget.prefillWord!;
    }
    if (widget.prefillCategory != null) {
      _category = widget.prefillCategory!;
    }
    // v1.17.4+ — Session 60+ block-duplicate-recordings rule.
    // Session 64 (M12): track the load state so we can disable the record
    // button until the inventory is available. Without this a fast-typing
    // user could tap Record before the async load returns and slip past
    // the `_alreadyRecorded` guard.
    NativeAudioInventory.instance.load().then((_) {
      if (mounted) setState(() => _nativeInventoryLoaded = true);
    });
    // Rebuild whenever the word changes so the "already recorded"
    // warning + record-button disable react live.
    _wordController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  /// True if the currently-typed Awing word already has ANY approved
  /// native recording shipped in the AAB — canonical adult OR any kid.
  bool get _alreadyRecorded {
    final word = _wordController.text.trim();
    if (word.isEmpty) return false;
    return NativeAudioInventory.instance
        .hasAnyRecording(PronunciationService.audioKey(word));
  }

  @override
  void dispose() {
    _wordController.dispose();
    _correctionController.dispose();
    _englishController.dispose();
    _pronunciationController.dispose();
    _notesController.dispose();
    _recorder.dispose();
    _player.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  // ==================== Audio Recording ====================

  Future<void> _startRecording() async {
    // Session 64 (M12): defensive check — if the native inventory hasn't
    // loaded yet, block the record entirely rather than let a fast user
    // slip past `_alreadyRecorded` while it still reads as `false`.
    if (!_nativeInventoryLoaded) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Still checking the native recordings list. Please wait a '
              'second and try again.',
            ),
          ),
        );
      }
      return;
    }
    if (_alreadyRecorded) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This word already has an approved native recording. '
              'Please pick a different word.',
            ),
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
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    _recordingPath = await contribService.getRecordingPath(tempId);

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _recordingPath!,
    );

    _recordingDuration = Duration.zero;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _recordingDuration += const Duration(seconds: 1);
      });
    });

    setState(() {
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
    await _player.play(DeviceFileSource(_recordingPath!));
  }

  Future<void> _deleteRecording() async {
    // Session 64 (M7): confirmation before wiping the recording. The
    // delete icon sits right next to the play icon in a compact row —
    // easy to fat-finger for kids. Confirming prevents accidental
    // loss of a good recording.
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete recording?'),
        content: const Text(
          'Are you sure you want to delete your recording? '
          'You will need to record again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() {
      _hasRecording = false;
      _recordingPath = null;
      _recordingDuration = Duration.zero;
    });
  }

  /// Always prefixed with literal 'default ' so the sync pipeline
  /// (sync_recordings.py::_recorder_to_kid_slug) routes audio into
  /// audio/native/ regardless of whether the submitter's first name
  /// matches a registered kid slug.
  String _firstNameForSubmission(String? displayName) {
    String firstName = '';
    if (displayName != null) {
      final trimmed = displayName.trim();
      if (trimmed.isNotEmpty) {
        final parts = trimmed.split(RegExp(r'\s+'));
        const titles = {
          'dr', 'dr.', 'mr', 'mr.', 'mrs', 'mrs.', 'ms', 'ms.',
          'prof', 'prof.', 'rev', 'rev.',
        };
        for (final p in parts) {
          if (p.isEmpty) continue;
          if (titles.contains(p.toLowerCase())) continue;
          firstName = p;
          break;
        }
      }
    }
    return firstName.isEmpty ? 'default' : 'default $firstName';
  }

  // ==================== Submit ====================


  Future<void> _submit(ContributionType type) async {
    if (_wordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the Awing word')),
      );
      return;
    }
    final needsTextCorrection =
        type == ContributionType.spellingCorrection ||
        type == ContributionType.newWord ||
        type == ContributionType.newSentence;
    if (needsTextCorrection && _correctionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            type == ContributionType.spellingCorrection
                ? 'Please enter the correct spelling'
                : type == ContributionType.newSentence
                    ? 'Please enter the English translation'
                    : 'Please enter the Awing word',
          ),
        ),
      );
      return;
    }
    if (type == ContributionType.pronunciationFix &&
        !_hasRecording &&
        _pronunciationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please record audio OR write a pronunciation guide',
          ),
        ),
      );
      return;
    }
    // Block duplicate recordings — only for audio paths.
    final isAudioContribution =
        _hasRecording || type == ContributionType.pronunciationFix;
    if (isAudioContribution && _alreadyRecorded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This word already has an approved native recording — '
            'audio contributions blocked. Please pick a different word.',
          ),
        ),
      );
      return;
    }

    final auth = context.read<AuthService>();
    final contribService = context.read<ContributionService>();
    final analytics = AnalyticsService.instance;

    await contribService.submit(
      deviceId: analytics.isOptedOut ? 'anonymous' : 'contributor',
      profileName: _firstNameForSubmission(
          auth.currentProfile?.displayName),
      type: type,
      targetWord: _wordController.text.trim(),
      correction: _correctionController.text.trim(),
      englishMeaning: _englishController.text.trim().isNotEmpty
          ? _englishController.text.trim()
          : null,
      category: _category,
      pronunciationGuide: _pronunciationController.text.trim().isNotEmpty
          ? _pronunciationController.text.trim()
          : null,
      audioPath: _hasRecording ? _recordingPath : null,
      imagePath: _imagePath,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    analytics.logFeedback(
      type: 'contribution_${type.name}',
      message: '${_wordController.text} → ${_correctionController.text}',
      screen: 'contribute_screen',
    );

    // No client-side email-app prompt anymore. The submission posted
    // directly to the contributions webhook above; the webhook
    // server-side sends a notification email to the developer
    // (contributions_webapp.gs handleSubmit -> MailApp.sendEmail).
    // Contributors just see "Submitted!" -- they don't have to pick
    // an email or share app.
    if (!mounted) return;
    setState(() {
      _submitted = true;
      _submittedType = type;
    });
  }

  @override
  Widget build(BuildContext context) {
    // v1.18.0+ — 5 top-level tabs. Each non-Record tab is dedicated
    // to ONE ContributionType, so the user doesn't have to pick the
    // type with chips. Tabs are scrollable to fit narrow phones.
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Contribute'),
          centerTitle: true,
          backgroundColor: const Color(0xFF006432),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.mic), text: 'Record'),
              Tab(icon: Icon(Icons.spellcheck), text: 'Spelling'),
              Tab(icon: Icon(Icons.record_voice_over),
                  text: 'Pronunciation'),
              Tab(icon: Icon(Icons.add_circle_outline),
                  text: 'New word'),
              Tab(icon: Icon(Icons.short_text), text: 'New sentence'),
            ],
          ),
        ),
        body: TabBarView(
          // Lock swipes — accidental swipes destroy in-progress text /
          // recording. The TabBar at the top is the explicit switcher.
          physics: const NeverScrollableScrollPhysics(),
          children: [
            const RecordPickerScreen(),
            _wrapTab(ContributionType.spellingCorrection),
            _wrapTab(ContributionType.pronunciationFix),
            _wrapTab(ContributionType.newWord),
            _wrapTab(ContributionType.newSentence),
          ],
        ),
      ),
    );
  }

  /// If the user just submitted via this tab's type, render the
  /// thank-you screen. Otherwise render the form for this type.
  Widget _wrapTab(ContributionType type) {
    if (_submitted && _submittedType == type) {
      return _buildThankYou();
    }
    return _buildForm(type);
  }

  Widget _buildAlreadyRecordedBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade400, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle,
              color: Colors.amber.shade800, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Already recorded',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '"${_wordController.text.trim()}" already has an '
                  'approved native recording. Pick a different word, '
                  'or switch to a text-only tab (Spelling / New word).',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.amber.shade900,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThankYou() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mark_email_read,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'Sent to Developer!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your contribution has been sent to the developer for '
              'review. Thank you for helping grow the Awing language '
              'app!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _submitted = false;
                      _wordController.clear();
                      _correctionController.clear();
                      _englishController.clear();
                      _pronunciationController.clear();
                      _notesController.clear();
                      _hasRecording = false;
                      _recordingPath = null;
                      _recordingDuration = Duration.zero;
                      // v1.22.0 (Session 66): also reset the attached photo
                      // so "Submit Another" doesn't accidentally re-send
                      // last submission's image with the new form data.
                      _imagePath = null;
                    });
                  },
                  child: const Text('Submit Another'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Type-specific form. Hides irrelevant fields per tab.
  ///
  /// Field matrix:
  ///   spellingCorrection : autocomplete picker + correction
  ///   pronunciationFix   : autocomplete picker + audio recorder +
  ///                        optional pronunciation guide
  ///   newWord            : free-form awing + english + category +
  ///                        optional pronunciation guide
  ///   newSentence        : free-form awing + english translation +
  ///                        optional pronunciation guide
  Widget _buildForm(ContributionType type) {
    final isExistingWordTab =
        type == ContributionType.spellingCorrection ||
        type == ContributionType.pronunciationFix;
    final isPronunciation = type == ContributionType.pronunciationFix;
    final isNewWord = type == ContributionType.newWord;
    final isNewSentence = type == ContributionType.newSentence;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTabHeader(type),
          const SizedBox(height: 16),

          // Word picker / free-form field
          if (isExistingWordTab)
            _buildExistingWordPicker()
          else
            AwingTextField(
              controller: _wordController,
              decoration: InputDecoration(
                labelText: isNewSentence
                    ? 'Awing sentence'
                    : 'Awing word',
                hintText: isNewSentence
                    ? 'e.g. Ko akwe pə nəgoomɔ́'
                    : 'e.g. apô',
                prefixIcon: const Icon(Icons.translate),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Correction field
          if (type == ContributionType.spellingCorrection) ...[
            AwingTextField(
              controller: _correctionController,
              decoration: InputDecoration(
                labelText: 'Correct spelling',
                hintText: 'How should it actually be written?',
                prefixIcon: const Icon(Icons.edit),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (isNewWord) ...[
            TextField(
              controller: _englishController,
              decoration: InputDecoration(
                labelText: 'English meaning',
                hintText: 'e.g. hand',
                prefixIcon: const Icon(Icons.language),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Reuses _correctionController as a hidden "category"
            // sentinel? No — newWord stores english separately. Keep
            // the correction field optional for additional context.
            AwingTextField(
              controller: _correctionController,
              decoration: InputDecoration(
                labelText: 'Alternate forms / plural (optional)',
                hintText: 'e.g. plural form, related variant…',
                prefixIcon: const Icon(Icons.format_list_bulleted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _categories.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(c[0].toUpperCase() + c.substring(1)),
                );
              }).toList(),
              onChanged: (v) =>
                  setState(() => _category = v ?? 'other'),
            ),
            const SizedBox(height: 16),
          ],

          if (isNewSentence) ...[
            TextField(
              controller: _correctionController,
              decoration: InputDecoration(
                labelText: 'English translation',
                hintText: 'What does the sentence mean?',
                prefixIcon: const Icon(Icons.translate),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (isPronunciation || isNewWord || isNewSentence) ...[
            TextField(
              controller: _pronunciationController,
              decoration: InputDecoration(
                labelText: isPronunciation
                    ? 'Pronunciation guide (optional)'
                    : 'How to pronounce it (optional)',
                hintText: isNewSentence
                    ? 'e.g. koh ah-kweh puh nuh-goh-maw'
                    : 'e.g. ah-POH (describe the sounds)',
                helperText: 'Use CAPS for the stressed/high-tone '
                    'syllable.',
                helperMaxLines: 2,
                prefixIcon: const Icon(Icons.record_voice_over),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Audio recorder: ONLY on the pronunciation-fix tab. Recording
          // a brand-new word should happen via the Record tab (which
          // routes through RecordPickerScreen → RecordAudioScreen).
          if (isPronunciation) ...[
            if (_alreadyRecorded)
              _buildAlreadyRecordedBanner()
            else
              _buildAudioRecorder(),
            const SizedBox(height: 16),
          ],

          // Notes (universal optional field)
          TextField(
            controller: _notesController,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              labelText: 'Additional notes (optional)',
              hintText: 'Any context or explanation…',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // v1.22.0 (Session 66) — optional photo attached to any
          // contribution type. Especially useful for new-word or
          // spelling contributions where a photo of the real thing
          // (a cane, a market fruit) is worth 1000 English glosses.
          ImageAttachmentPicker(
            imagePath: _imagePath,
            onChanged: (path) => setState(() => _imagePath = path),
            label: 'Add a photo (optional)',
            hint: 'Show us what the word means — e.g. a picture of the '
                'object, action, or scene. Great for kids learning.',
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () => _submit(type),
            icon: const Icon(Icons.send),
            label: const Text(
              'Submit Contribution',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006432),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The developer will review and approve your submission.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  /// Per-tab short blurb at the top of each form, so users know which
  /// flow they're in even mid-scroll.
  Widget _buildTabHeader(ContributionType type) {
    String title;
    String blurb;
    IconData icon;
    switch (type) {
      case ContributionType.spellingCorrection:
        title = 'Fix a spelling';
        blurb = 'Found a typo? Pick the word and write the correct '
            'spelling.';
        icon = Icons.spellcheck;
        break;
      case ContributionType.pronunciationFix:
        title = 'Fix a pronunciation';
        blurb = 'Hear how a word is pronounced today, then record a '
            'better version or write a guide.';
        icon = Icons.record_voice_over;
        break;
      case ContributionType.newWord:
        title = 'Add a new word';
        blurb = 'Share an Awing word the app is missing. Include its '
            'English meaning and category.';
        icon = Icons.add_circle_outline;
        break;
      case ContributionType.newSentence:
        title = 'Add a new sentence';
        blurb = 'Share a useful Awing sentence and its English '
            'translation.';
        icon = Icons.short_text;
        break;
      default:
        title = 'Contribute';
        blurb = '';
        icon = Icons.help_outline;
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF006432).withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF006432).withOpacity(0.15)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF006432),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006432),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  blurb,
                  style: TextStyle(
                      fontSize: 12.5, color: Colors.grey.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Autocomplete picker over the full vocabulary for "fix existing
  /// word" tabs. Tap-to-select sets _wordController.text and optionally
  /// auto-fills English.
  Widget _buildExistingWordPicker() {
    final inv = NativeAudioInventory.instance;
    return Autocomplete<AwingWord>(
      displayStringForOption: (w) => '${w.awing} → ${w.english}',
      optionsBuilder: (TextEditingValue tv) {
        final q = tv.text.trim().toLowerCase();
        if (q.isEmpty) return const Iterable<AwingWord>.empty();
        final matches = <AwingWord>[];
        final seenKeys = <String>{};
        for (final w in allVocabulary) {
          if (matches.length >= 30) break;
          final key = '${w.awing}|${w.english}';
          if (seenKeys.contains(key)) continue;
          // Hide words that already have ANY native recording (canonical
          // adult OR any kid). Same rule as RecordPickerScreen -- a word
          // covered by SOMEONE shouldn't be re-recordable through the
          // Pronunciation/Spelling autocomplete either. Prevents
          // contributors from re-recording apô, agha, etc. that are
          // already in the native_audio_manifest.json.
          final audioKey = PronunciationService.audioKey(w.awing);
          if (inv.hasAnyRecording(audioKey)) continue;
          if (w.awing.toLowerCase().contains(q) ||
              w.english.toLowerCase().contains(q)) {
            matches.add(w);
            seenKeys.add(key);
          }
        }
        return matches;
      },
      onSelected: (AwingWord picked) {
        _wordController.text = picked.awing;
        if (_englishController.text.trim().isEmpty) {
          _englishController.text = picked.english;
        }
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        controller.addListener(() {
          if (_wordController.text != controller.text) {
            _wordController.text = controller.text;
          }
        });
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Pick the word',
            hintText: 'Type a few letters (Awing or English)…',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 280,
                maxWidth: 340,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final w = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    title: Text(w.awing,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(w.english,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => onSelected(w),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// Self-contained audio-recorder block (only shown on the
  /// pronunciation-fix tab when the word doesn't already have an
  /// approved native recording).
  Widget _buildAudioRecorder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isRecording
            ? Colors.red.shade50
            : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isRecording
              ? Colors.red.shade200
              : const Color(0xFFA5D6A7),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Record the correct pronunciation',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF006432),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap the mic to record. Tap again to stop.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _isRecording ? _stopRecording : _startRecording,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording
                        ? Colors.red
                        : const Color(0xFF006432),
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording
                                ? Colors.red
                                : const Color(0xFF006432))
                            .withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              if (_hasRecording) ...[
                const SizedBox(width: 16),
                IconButton(
                  tooltip: 'Play',
                  onPressed: _playRecording,
                  icon: const Icon(Icons.play_circle_fill),
                  iconSize: 48,
                  color: const Color(0xFF006432),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: _deleteRecording,
                  icon: const Icon(Icons.delete),
                  iconSize: 32,
                  color: Colors.red.shade400,
                ),
              ],
            ],
          ),
          if (_isRecording) ...[
            const SizedBox(height: 8),
            Text(
              _formatDuration(_recordingDuration),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ],
          if (_hasRecording && !_isRecording) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle,
                    color: Colors.green, size: 18),
                const SizedBox(width: 4),
                Text(
                  'Recording saved (${_formatDuration(_recordingDuration)})',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
