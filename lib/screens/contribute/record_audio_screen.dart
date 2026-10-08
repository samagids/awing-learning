// record_audio_screen.dart
// ---------------------------------------------------------------
// v1.17.x — Dedicated "Record Audio" screen for the Contribute
// flow. Modeled after Dev Mode → Record tab.
//
// Flow:
//   1. Autocomplete picker over allVocabulary + phrases
//   2. Selected item card with reference audio playback
//   3. Big record button (tap to start, tap to stop)
//   4. Playback controls: Play mine + Delete
//   5. Submit via ContributionService as pronunciationFix
//
// Audio routing (after sync):
//   profileName = "default <FirstName>" → audio/community/ tier
//   (NEVER overwrites Dr. Sama's audio/native/ recording)
// ---------------------------------------------------------------

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/contribution_service.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/analytics_service.dart';
import 'package:awing_ai_learning/services/native_audio_inventory.dart';
import 'package:awing_ai_learning/services/local_pending_service.dart';
import 'package:awing_ai_learning/components/image_attachment_picker.dart';

class RecordAudioScreen extends StatefulWidget {
  /// v1.18.0+ — When set, the screen opens already-locked on this word
  /// and the autocomplete picker is hidden. Used by RecordPickerScreen
  /// so tapping a word in the unrecorded-list goes straight into the
  /// record flow without re-typing.
  final AwingWord? preSelectedWord;

  const RecordAudioScreen({super.key, this.preSelectedWord});

  @override
  State<RecordAudioScreen> createState() => _RecordAudioScreenState();
}

class _RecordAudioScreenState extends State<RecordAudioScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final PronunciationService _pronunciation = PronunciationService();

  AwingWord? _selected;
  String? _recordingPath;
  /// v1.22.0 (Session 66): optional photo attached to this pronunciation
  /// contribution. Ships with the audio in the same webhook submit call.
  String? _imagePath;
  bool _isRecording = false;
  bool _hasRecording = false;
  int _seconds = 0;
  Timer? _ticker;
  bool _submitting = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _pronunciation.init();
    // v1.18.0+ — accept pre-selected word from RecordPickerScreen.
    if (widget.preSelectedWord != null) {
      _selected = widget.preSelectedWord;
    }
    // v1.17.4+ — Session 60+ block-duplicate-recordings rule. Ensure the
    // native-audio inventory is loaded so `_alreadyRecorded` can answer
    // synchronously when the user picks a word from the autocomplete.
    NativeAudioInventory.instance.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  /// True if the currently-selected word has ANY approved native
  /// recording shipped in the AAB — canonical adult (Dr. Sama /
  /// Berlin) OR any kid (Joel / Janelle / Joyce / Jadyne / etc.).
  /// Used to block duplicate contributions: "users cannot contribute
  /// audio for words or sentences that already have a native recording."
  bool get _alreadyRecorded {
    if (_selected == null) return false;
    final key = PronunciationService.audioKey(_selected!.awing);
    return NativeAudioInventory.instance.hasAnyRecording(key);
  }

  /// The duplicate-contribution block, with one exception.
  ///
  /// The rule is for contributors: nobody should spend their time
  /// recording a word a native speaker has already covered, and nobody
  /// should be able to record over Dr. Sama's canonical clip.
  ///
  /// But a clip can be WRONG - mispronounced, clipped, the wrong word for
  /// the gloss - and then the block protects the mistake. The only person
  /// who can judge that is the one it locks out. So in developer mode the
  /// block lifts and a new recording replaces the old one.
  ///
  /// [_alreadyRecorded] still answers the factual question, so the UI can
  /// say "this already has a recording" while allowing the replacement.
  bool get _blockedAsDuplicate {
    if (!_alreadyRecorded) return false;
    return !context.read<AuthService>().isDeveloper;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_selected == null) return;
    // Hard guard: refuse to record over a word that already has an
    // approved native recording (Session 60+ block-duplicates rule).
    // The UI also hides the record button in this case, but we
    // defensively check here in case the build state was stale.
    if (_blockedAsDuplicate) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This word already has a native recording approved. '
            'Please pick a different word.',
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
    final contribService = context.read<ContributionService>();
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    _recordingPath = await contribService.getRecordingPath(tempId);
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _recordingPath!,
    );
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
    if (_recordingPath == null) return;
    await _player.play(DeviceFileSource(_recordingPath!));
  }

  Future<void> _playReference() async {
    if (_selected == null) return;
    await _pronunciation.speakAwing(_selected!.awing);
  }

  void _deleteRecording() {
    setState(() {
      _hasRecording = false;
      _recordingPath = null;
    });
  }

  String _firstNameForSubmission(String? displayName) {
    String firstName = "";
    if (displayName != null) {
      final trimmed = displayName.trim();
      if (trimmed.isNotEmpty) {
        final parts = trimmed.split(RegExp(r"\s+"));
        const titles = {
          "dr", "dr.", "mr", "mr.", "mrs", "mrs.", "ms", "ms.",
          "prof", "prof.", "rev", "rev.",
        };
        for (final p in parts) {
          if (p.isEmpty) continue;
          if (titles.contains(p.toLowerCase())) continue;
          firstName = p;
          break;
        }
      }
    }
    return firstName.isEmpty ? "default" : "default $firstName";
  }

  Future<void> _submit() async {
    if (_selected == null || !_hasRecording || _submitting) return;
    // Defensive: if somehow the user got past the UI and recorded over
    // a canonical-recorded word, bail before hitting the server.
    if (_blockedAsDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This word already has a native recording — submission blocked.',
          ),
        ),
      );
      return;
    }
    setState(() => _submitting = true);

    final auth = context.read<AuthService>();
    final contribService = context.read<ContributionService>();

    final id = await contribService.submit(
      deviceId: AnalyticsService.instance.isOptedOut ? "anonymous" : "contributor",
      profileName: _firstNameForSubmission(auth.currentProfile?.displayName),
      type: ContributionType.pronunciationFix,
      targetWord: _selected!.awing,
      correction: "",
      englishMeaning: _selected!.english,
      category: _selected!.category,
      audioPath: _recordingPath,
      imagePath: _imagePath,
    );

    bool emailSuccess = false;
    if (id != null) {
      final c = contribService.contributions.firstWhere((c) => c.id == id);
      emailSuccess = await contribService.emailContribution(
        c,
        senderName: auth.currentProfile?.displayName ?? "Anonymous",
        // currentEmail returns '' (never null) when signed out, so the
        // old `?? "no-reply@..."` fallback never fired and we posted an
        // empty sender. Session 63: check isNotEmpty instead.
        senderEmail: auth.currentEmail.isNotEmpty
            ? auth.currentEmail
            : "no-reply@awing-app.local",
      );
    }

    AnalyticsService.instance.logFeedback(
      type: "record_audio",
      message: _selected!.awing,
      screen: "record_audio_screen",
    );

    // v1.18.0+ — mark locally as pending so RecordPickerScreen filters
    // this word out of "still needs a voice" for the next 30 days.
    await LocalPendingService.markSubmitted(_selected!.awing);

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _submitted = true;
    });

    final msg = emailSuccess
        ? "Thanks! Your recording is on its way."
        : "Saved locally — will sync when online.";
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

    // v1.18.0+ — if we got here from RecordPickerScreen (preSelectedWord
    // was set), pop back automatically so the user lands on the picker
    // and can chain more recordings without tapping Back.
    if (widget.preSelectedWord != null && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  void _reset() {
    setState(() {
      _selected = null;
      _recordingPath = null;
      _hasRecording = false;
      _isRecording = false;
      _seconds = 0;
      _submitted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Record"),
        backgroundColor: const Color(0xFF006432),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.preSelectedWord != null
                  ? "Record this word."
                  : "Pick a word, then record it.",
              style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              "Your recording becomes the fallback when no native voice is on file.",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            // v1.18.0+ — hide the autocomplete picker when a word was
            // pre-selected by RecordPickerScreen; the selected card +
            // record controls below are all the user needs.
            if (widget.preSelectedWord == null) _buildPicker(),
            if (widget.preSelectedWord == null) const SizedBox(height: 16),
            if (_selected != null) _buildSelectedCard(),
            const SizedBox(height: 16),
            // Session 60+ — block duplicate recordings. When the picked
            // word already has an approved native recording in the AAB
            // (NativeAudioInventory.hasCanonical), we hide the record
            // controls and show a clear "already recorded" panel
            // instead. Users can pick a different word from the picker.
            //
            // Developer mode is the exception: the banner still appears,
            // because knowing a clip exists is exactly the point when you
            // are about to replace it, but the controls stay on under it.
            if (_selected != null && _alreadyRecorded)
              _buildAlreadyRecordedBanner(),
            if (_selected != null && !_blockedAsDuplicate)
              _buildRecordControls(),
            // v1.22.0 (Session 66) — optional photo alongside the
            // recording. Visible whenever a word is selected + not
            // already natively recorded; independent of whether the
            // user has captured the audio yet, so they can attach
            // the photo before or after recording.
            if (_selected != null && !_blockedAsDuplicate && !_submitted) ...[
              const SizedBox(height: 16),
              ImageAttachmentPicker(
                imagePath: _imagePath,
                onChanged: (p) => setState(() => _imagePath = p),
                label: 'Add a photo (optional)',
                hint: 'Show us what "${_selected!.awing}" looks like — '
                    'e.g. a picture of the object or scene.',
              ),
            ],
            const SizedBox(height: 24),
            if (_selected != null &&
                !_blockedAsDuplicate &&
                _hasRecording &&
                !_submitted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: const Icon(Icons.cloud_upload),
                  label: Text(_submitting ? "Sending…" : "Submit"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006432),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            if (_submitted)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Record another word"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPicker() {
    return Autocomplete<AwingWord>(
      displayStringForOption: (w) => "${w.awing} → ${w.english}",
      optionsBuilder: (tv) {
        final q = tv.text.trim().toLowerCase();
        if (q.isEmpty) return const Iterable<AwingWord>.empty();
        final matches = <AwingWord>[];
        final seen = <String>{};
        final inv = NativeAudioInventory.instance;
        final devSearch = context.read<AuthService>().isDeveloper;
        for (final w in allVocabulary) {
          if (matches.length >= 30) break;
          final key = "${w.awing}|${w.english}";
          if (seen.contains(key)) continue;
          // Skip words with any existing native recording -- per
          // Dr. Sama, words already covered by SOMEONE (canonical adult
          // or kid) should not be re-recordable.
          //
          // Except in developer mode, where the whole point of the search
          // is to FIND the already-recorded word whose clip is wrong. A
          // search that hides it is a search that cannot fix it.
          final audioKey = PronunciationService.audioKey(w.awing);
          if (!devSearch && inv.hasAnyRecording(audioKey)) continue;
          if (w.awing.toLowerCase().contains(q) ||
              w.english.toLowerCase().contains(q)) {
            matches.add(w);
            seen.add(key);
          }
        }
        return matches;
      },
      onSelected: (w) => setState(() {
        _selected = w;
        _hasRecording = false;
        _recordingPath = null;
      }),
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: "Search a word (Awing or English)",
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
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
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 360),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final w = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    title: Text(w.awing,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _buildSelectedCard() {
    final w = _selected!;
    return Card(
      color: Colors.green.shade50,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(w.awing,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(w.english, style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.volume_up,
                  color: Color(0xFFDAA520), size: 30),
              onPressed: _playReference,
              tooltip: "Hear current pronunciation",
            ),
          ],
        ),
      ),
    );
  }

  /// Shown in place of the record controls when the selected word
  /// already has an approved native recording (Session 60+ rule).
  Widget _buildAlreadyRecordedBanner() {
    final isDev = context.watch<AuthService>().isDeveloper;
    return Card(
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.amber.shade400, width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle, color: Colors.amber.shade800, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDev ? "Already recorded — replacing it"
                          : "Already recorded",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isDev
                        ? "A native recording for this word already exists. "
                          "Listen to it first — what you record next will "
                          "replace it."
                        : "This word already has an approved native "
                          "recording. Please pick a different word from the "
                          "search above.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber.shade900,
                    ),
                  ),
                  if (isDev && _selected != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => PronunciationService()
                            .speakAwing(_selected!.awing),
                        icon: const Icon(Icons.volume_up, size: 18),
                        label: const Text('Play the current recording'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber.shade900,
                          side: BorderSide(color: Colors.amber.shade400),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordControls() {
    return Column(
      children: [
        if (_isRecording)
          Column(
            children: [
              Text("${_seconds}s",
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: _seconds / 10.0),
              const SizedBox(height: 6),
              Text("Tap to stop (max 10s)",
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
          )
        else if (_hasRecording)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _playMine,
                icon: const Icon(Icons.play_arrow),
                label: const Text("Play mine"),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _deleteRecording,
                icon: const Icon(Icons.delete_outline),
                label: const Text("Delete"),
              ),
            ],
          )
        else
          Text("Tap the mic to record",
              style: TextStyle(color: Colors.grey.shade700)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _isRecording ? _stopRecording : _startRecording,
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRecording ? Colors.red : const Color(0xFF006432),
              boxShadow: [
                BoxShadow(
                  color: (_isRecording ? Colors.red : const Color(0xFF006432))
                      .withOpacity(0.4),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _isRecording ? Icons.stop : Icons.mic,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      ],
    );
  }
}
