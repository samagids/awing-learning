// study_set_record_screen.dart
// ---------------------------------------------------------------
// Session 63 Phase 3 — Record audio for a single word in a Study
// Set. Modeled after RecordAudioScreen (contribute flow) but the
// output goes to Firebase Storage instead of the contribution
// email pipeline.
//
// Flow:
//   1. Show the target word (Awing + English + image).
//   2. "Hear reference" button plays the app's built-in pronunciation
//      so the teacher can compare before recording.
//   3. Big mic button: tap to record, tap again to stop (10-sec max).
//   4. After stop: "Play mine" + "Re-record" + "Save & Upload".
//   5. Save & Upload: uploads m4a → Firebase Storage → writes URL
//      into set.recordings via StudySetService.setRecording → pop
//      back to the editor with a snackbar.
//
// Uses the same `record` + `audioplayers` packages the rest of the
// app uses so there's no new dependency footprint. Uses
// PronunciationService for reference playback.
// ---------------------------------------------------------------
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:awing_ai_learning/components/pack_image.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/models/study_set.dart';
import 'package:awing_ai_learning/services/analytics_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/contribution_service.dart';
import 'package:awing_ai_learning/services/native_audio_inventory.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/study_set_audio_service.dart';
import 'package:awing_ai_learning/services/study_set_service.dart';

class StudySetRecordScreen extends StatefulWidget {
  final String setId;
  final String awing;
  final String english;
  final String? category;
  /// The URL of the existing recording, if any — displayed as
  /// "Current recording" with a play button so the teacher can hear
  /// what students will hear before deciding to re-record.
  final String? currentUrl;

  const StudySetRecordScreen({
    super.key,
    required this.setId,
    required this.awing,
    required this.english,
    this.category,
    this.currentUrl,
  });

  @override
  State<StudySetRecordScreen> createState() => _StudySetRecordScreenState();
}

class _StudySetRecordScreenState extends State<StudySetRecordScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final PronunciationService _pronunciation = PronunciationService();

  String? _localPath;
  bool _isRecording = false;
  bool _hasRecording = false;
  int _seconds = 0;
  Timer? _ticker;
  bool _uploading = false;

  bool _nativeInventoryLoaded = false;

  @override
  void initState() {
    super.initState();
    _pronunciation.init();
    // Preload the native inventory so `_alreadyNative` answers
    // synchronously in the build (same pattern as record_audio_screen).
    NativeAudioInventory.instance.load().then((_) {
      if (mounted) setState(() => _nativeInventoryLoaded = true);
    });
  }

  /// Whether the target word already has an approved native recording
  /// (Dr. Sama / kids / community-approved). If yes, we HARD-BLOCK
  /// re-recording: kids will always hear the native audio via the
  /// PronunciationService fall-through, so a teacher upload would be
  /// redundant AND could accidentally override higher-quality
  /// native audio downstream if a bug slipped through.
  bool get _alreadyNative {
    if (!_nativeInventoryLoaded) return false;
    final key = PronunciationService.audioKey(widget.awing);
    return NativeAudioInventory.instance.hasAnyRecording(key);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    // Defensive: the UI hides the record button when a native recording
    // exists, but check again here in case the inventory finished
    // loading between build and tap.
    if (_alreadyNative) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This word already has a native recording. Students will '
            'hear that instead — no need to record.',
          ),
        ),
      );
      return;
    }
    if (!await _recorder.hasPermission()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission denied')),
      );
      return;
    }
    final path = await StudySetAudioService.instance.localRecordingPath(
      setId: widget.setId,
      awing: widget.awing,
    );
    _localPath = path;
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _hasRecording = false;
      _seconds = 0;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds++);
      if (_seconds >= 10) _stopRecording();
    });
  }

  Future<void> _stopRecording() async {
    _ticker?.cancel();
    if (!_isRecording) return;
    final path = await _recorder.stop();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _hasRecording = path != null;
    });
  }

  Future<void> _playMine() async {
    if (_localPath == null) return;
    await _player.play(DeviceFileSource(_localPath!));
  }

  Future<void> _playCurrent() async {
    final url = widget.currentUrl;
    if (url == null || url.isEmpty) return;
    await _player.play(UrlSource(url));
  }

  Future<void> _playReference() async {
    await _pronunciation.speakAwing(widget.awing);
  }

  Future<void> _saveAndUpload() async {
    if (_localPath == null || !_hasRecording) return;
    // Resolve the set to get teacherEmail — needed for the Drive path
    // owner check on the webhook side.
    final set = await StudySetService.instance.byId(widget.setId);
    if (set == null || set.teacherEmail.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set not found — try again.')),
      );
      return;
    }
    setState(() => _uploading = true);

    // Step 1 — upload to the Study Set's Drive folder so the set works
    // immediately for the teacher's students.
    final url = await StudySetAudioService.instance.uploadRecording(
      teacherEmail: set.teacherEmail,
      setId: widget.setId,
      awing: widget.awing,
      localPath: _localPath!,
    );
    if (!mounted) return;
    if (url == null) {
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Upload failed. Check your connection and try again.',
          ),
        ),
      );
      return;
    }
    await StudySetService.instance
        .setRecording(widget.setId, widget.awing, url);

    // Step 2 — ALSO submit through the standard Contribute pipeline so
    // the developer gets a notification email AND the recording shows
    // up in the Review tab for approval → global inclusion in the next
    // app build (Session 63 Phase 3 — Dr. Sama's original spec:
    // "It follows the workflow in contribute-record and I approve it").
    //
    // Fire-and-forget: even if the contribution submit fails, the set
    // is still functional because Step 1 succeeded.
    await _submitAsContribution(set);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Recorded "${widget.awing}" ✓  •  Sent for developer review',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
    Navigator.pop(context, true);
  }

  /// Submit the local recording as a Contribute pipeline entry so the
  /// developer sees it in their Review tab and gets the standard
  /// notification email. Type = pronunciationFix if the word exists in
  /// the app dictionary; newWord otherwise (custom teacher-added words).
  Future<void> _submitAsContribution(StudySet set) async {
    if (_localPath == null) return;
    try {
      final contribService = context.read<ContributionService>();
      final auth = context.read<AuthService>();

      // Distinguish dictionary words (pronunciationFix) from custom
      // words the teacher added themselves (newWord). Custom words
      // aren't in allVocabulary yet, so they carry the vocabulary
      // metadata (english/category/difficulty) via the contribution
      // for developer inclusion in the next release.
      bool isDictWord = false;
      for (final w in allVocabulary) {
        if (w.awing == widget.awing) {
          isDictWord = true;
          break;
        }
      }
      final type = isDictWord
          ? ContributionType.pronunciationFix
          : ContributionType.newWord;

      await contribService.submit(
        deviceId: AnalyticsService.instance.isOptedOut
            ? 'anonymous'
            : 'study_set_teacher',
        profileName: _firstNameForSubmission(
            auth.currentProfile?.displayName),
        type: type,
        targetWord: widget.awing,
        correction: '',
        englishMeaning: widget.english,
        category: widget.category ?? '',
        audioPath: _localPath,
        notes: 'From Study Set "${set.name}" (id: ${set.id})',
      );

      AnalyticsService.instance.logFeedback(
        type: 'study_set_record',
        message: '${widget.awing} (set: ${set.name})',
        screen: 'study_set_record_screen',
      );
    } catch (e) {
      // Don't block the study set upload if the contribution submit
      // fails — the audio is already usable in the set.
      debugPrint('StudySetRecordScreen contribution submit failed: $e');
    }
  }

  /// Same first-name-with-prefix logic as record_audio_screen.dart so
  /// the audio_key resolves to audio/community/<firstname>/... on the
  /// developer side after approval.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Record word')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Target word card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: PackImage(
                          awingWord: widget.awing,
                          english: widget.english,
                          errorWidget:
                              const Icon(Icons.image_not_supported_outlined),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.awing,
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(widget.english,
                                style: theme.textTheme.bodyMedium),
                            if (widget.category != null &&
                                widget.category!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  widget.category!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Reference + current recording playback row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _playReference,
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Hear reference'),
                  ),
                  if ((widget.currentUrl ?? '').isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: _playCurrent,
                      icon: const Icon(Icons.cloud_done_outlined,
                          color: Colors.green),
                      label: const Text('Play current recording'),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              // Native-covered banner OR mic button.
              if (_alreadyNative)
                _buildNativeBanner(context, theme)
              else
                _buildMicButton(context, theme),
              const SizedBox(height: 8),
              if (_isRecording)
                Text(
                  '${_seconds}s / 10s',
                  style: TextStyle(color: Colors.red.shade600),
                )
              else if (_hasRecording)
                Text('${_seconds}s recorded — review below',
                    style: TextStyle(color: Colors.green.shade700)),
              const SizedBox(height: 24),
              // Playback + upload row
              if (_hasRecording) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _uploading ? null : _playMine,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play mine'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _uploading
                            ? null
                            : () {
                                setState(() {
                                  _hasRecording = false;
                                  _localPath = null;
                                });
                              },
                        icon: const Icon(Icons.replay),
                        label: const Text('Re-record'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _uploading ? null : _saveAndUpload,
                    icon: _uploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: Text(
                        _uploading ? 'Uploading…' : 'Save & Upload'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                'Tip: speak clearly, in a quiet room. Kids will hear this '
                'recording every time they open the set.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNativeBanner(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.verified,
            color: Colors.green.shade700,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'Already recorded',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.green.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This word has a native recording shipped with the app. '
            'Your students will hear that automatically — you don\'t '
            'need to record it.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.green.shade900,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _playReference,
            icon: const Icon(Icons.volume_up),
            label: const Text('Hear the native recording'),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton(BuildContext context, ThemeData theme) {
    final active = _isRecording;
    return GestureDetector(
      onTap: active ? _stopRecording : _startRecording,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? Colors.red.shade600 : theme.colorScheme.primary,
          boxShadow: [
            BoxShadow(
              color: (active ? Colors.red : theme.colorScheme.primary)
                  .withOpacity(0.35),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          active ? Icons.stop : Icons.mic,
          color: Colors.white,
          size: 44,
        ),
      ),
    );
  }
}
