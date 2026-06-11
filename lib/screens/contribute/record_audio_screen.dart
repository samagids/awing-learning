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

class RecordAudioScreen extends StatefulWidget {
  const RecordAudioScreen({super.key});

  @override
  State<RecordAudioScreen> createState() => _RecordAudioScreenState();
}

class _RecordAudioScreenState extends State<RecordAudioScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final PronunciationService _pronunciation = PronunciationService();

  AwingWord? _selected;
  String? _recordingPath;
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
    // v1.17.4+ — Session 60+ block-duplicate-recordings rule. Ensure the
    // native-audio inventory is loaded so `_alreadyRecorded` can answer
    // synchronously when the user picks a word from the autocomplete.
    NativeAudioInventory.instance.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  /// True if the currently-selected word has an approved canonical
  /// native recording shipped in the AAB. Used to block duplicate
  /// contributions per Session 60+ rule: "users cannot contribute for
  /// words or sentences that already have a native recording and
  /// approved."
  bool get _alreadyRecorded {
    if (_selected == null) return false;
    final key = PronunciationService.audioKey(_selected!.awing);
    return NativeAudioInventory.instance.hasCanonical(key);
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
    if (_alreadyRecorded) {
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
    if (_alreadyRecorded) {
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
    );

    bool emailSuccess = false;
    if (id != null) {
      final c = contribService.contributions.firstWhere((c) => c.id == id);
      emailSuccess = await contribService.emailContribution(
        c,
        senderName: auth.currentProfile?.displayName ?? "Anonymous",
        senderEmail: auth.currentEmail ?? "no-reply@awing-app.local",
      );
    }

    AnalyticsService.instance.logFeedback(
      type: "record_audio",
      message: _selected!.awing,
      screen: "record_audio_screen",
    );

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _submitted = true;
    });

    final msg = emailSuccess
        ? "Thanks! Your recording is on its way."
        : "Saved locally — will sync when online.";
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
            const Text(
              "Pick a word, then record it.",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              "Your recording becomes the fallback when no native voice is on file.",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            _buildPicker(),
            const SizedBox(height: 16),
            if (_selected != null) _buildSelectedCard(),
            const SizedBox(height: 16),
            // Session 60+ — block duplicate recordings. When the picked
            // word already has an approved native recording in the AAB
            // (NativeAudioInventory.hasCanonical), we hide the record
            // controls and show a clear "already recorded" panel
            // instead. Users can pick a different word from the picker.
            if (_selected != null && _alreadyRecorded)
              _buildAlreadyRecordedBanner(),
            if (_selected != null && !_alreadyRecorded)
              _buildRecordControls(),
            const SizedBox(height: 24),
            if (_selected != null &&
                !_alreadyRecorded &&
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
        for (final w in allVocabulary) {
          if (matches.length >= 30) break;
          final key = "${w.awing}|${w.english}";
          if (seen.contains(key)) continue;
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
                    "Already recorded",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "This word already has an approved native recording. "
                    "Please pick a different word from the search above.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber.shade900,
                    ),
                  ),
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
