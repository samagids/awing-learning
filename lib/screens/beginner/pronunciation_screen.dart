import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/components/pack_image.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/pronunciation_grader.dart';
import 'package:awing_ai_learning/services/native_audio_inventory.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/utils/wav_decoder.dart';

/// Pronunciation practice — kid-friendly flow:
///
///   1. See the word + picture + English meaning.
///   2. Tap "Hear it" to listen to the correct Awing pronunciation.
///   3. Tap the big mic to record yourself saying it.
///   4. Tap again to stop. The on-device grader runs automatically.
///   5. Tap "Play mine" to hear your own recording, "Hear it" to compare.
///   6. See the star rating + percentage + friendly feedback.
///   7. Tap "Try again" to re-record, or "Next word" to move on.
///
/// Grading is pure-Dart DTW + MFCC against a bundled native-speaker
/// WAV reference for THIS word. Cross-platform (every Android ABI,
/// iOS, desktop), 100% offline. The on-device grader replaced an
/// earlier speech-to-text approach that was producing meaningless
/// scores by guessing English words that "sounded like" the kid's
/// Awing pronunciation.
///
/// Word selection is filtered to words that actually have a native
/// reference recording — kids never see a word the grader can't
/// score against. As more family members record more words, the
/// available pool grows automatically.
class PronunciationScreen extends StatefulWidget {
  const PronunciationScreen({Key? key}) : super(key: key);

  @override
  State<PronunciationScreen> createState() => _PronunciationScreenState();
}

class _PronunciationScreenState extends State<PronunciationScreen>
    with TickerProviderStateMixin {
  final PronunciationService _pronunciation = PronunciationService();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  late AnimationController _pulseController;
  late AwingWord _currentWord;
  late List<AwingWord> _vocabulary;

  static const int _maxRecordSeconds = 10;
  bool _isRecording = false;
  bool _isPlayingMine = false;
  bool _isGrading = false;
  bool _noReference = false; // ref WAV missing — show honest "coming soon"
  String? _gradeError;        // any other grader failure — surface it
  String? _myRecordingPath;
  int _wordsPracticed = 0;
  Timer? _recordingTimer;
  int _recordingSecondsLeft = _maxRecordSeconds;
  GradeResult? _lastGrade;

  @override
  void initState() {
    super.initState();
    _vocabulary = allVocabulary;
    _currentWord = _getRandomWord();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pronunciation.init();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlayingMine = false);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().completeLesson('beginner_pronunciation');
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _pulseController.dispose();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  AwingWord _getRandomWord() {
    // Beginner difficulty + the word MUST have a native-speaker reference
    // recording so the grader has something to compare against.
    //
    // Three filters layered:
    //   1. difficulty <= 1   (beginner vocabulary only)
    //   2. audio_key length >= 3 chars (skips grammatical particles like
    //      "á" / "a" / "tə" — single-character keys collide with many
    //      Awing words and aren't real practice content)
    //   3. NativeAudioInventory.hasCanonical(key) — Dr. Sama (or family)
    //      has a recording for this word
    //
    // NativeAudioInventory is loaded at app startup from
    // assets/native_audio_manifest.json (bundled in the base APK, NOT
    // the PAD pack, so we can filter synchronously here).
    final inv = NativeAudioInventory.instance;
    final pool = _vocabulary.where((w) {
      if (w.difficulty > 1) return false;
      final key = PronunciationService.audioKey(w.awing);
      if (key.length < 3) return false;
      return inv.hasCanonical(key);
    }).toList();
    if (pool.isEmpty) {
      // Fallback: any beginner word with a usable key length (still
      // excludes grammatical particles). Grader card will show a friendly
      // "no reference yet" message if the WAV is missing from the PAD
      // pack — kid still gets the listen-and-compare flow.
      final any = _vocabulary.where((w) {
        if (w.difficulty > 1) return false;
        return PronunciationService.audioKey(w.awing).length >= 3;
      }).toList();
      if (any.isEmpty) return _vocabulary.first;
      return any[math.Random().nextInt(any.length)];
    }
    return pool[math.Random().nextInt(pool.length)];
  }

  Future<void> _startRecording() async {
    try {
      final hasPerm = await _recorder.hasPermission();
      if (!hasPerm) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Microphone permission is needed to record yourself.'),
            ),
          );
        }
        return;
      }

      final dir = await getTemporaryDirectory();
      // WAV (PCM-16) so the on-device grader can decode the recording
      // without an MP3/AAC decoder native lib. Mono at 16 kHz matches
      // the grader's MFCC pipeline exactly — no resampling needed.
      final path =
          '${dir.path}/awing_practice_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );

      _pulseController.repeat();
      _recordingSecondsLeft = _maxRecordSeconds;
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _recordingSecondsLeft--;
        });
        if (_recordingSecondsLeft <= 0) {
          timer.cancel();
          _stopRecording();
        }
      });
      setState(() {
        _isRecording = true;
        _myRecordingPath = null;
        _lastGrade = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    try {
      final path = await _recorder.stop();
      _pulseController.stop();
      _pulseController.value = 0;
      setState(() {
        _isRecording = false;
        _myRecordingPath = path;
        if (path != null) _wordsPracticed++;
      });
      // Auto-grade as soon as the recording stops — kids shouldn't have
      // to remember a separate "Grade" button. Async so the UI updates
      // first (mic visibly stops, playback row appears) and the grader
      // result lands a moment later in the bottom card.
      if (path != null) {
        unawaited(_gradePronunciation());
      }
    } catch (e) {
      _pulseController.stop();
      _pulseController.value = 0;
      setState(() {
        _isRecording = false;
      });
    }
  }

  /// Run the on-device pronunciation grader against the kid's recording
  /// vs the bundled native-speaker reference for the current word.
  ///
  /// Pure-Dart DTW + MFCC, ~30-50 ms on a mid-range Android. Cross-
  /// platform, offline. The reference WAV lives in the PAD pack at
  /// audio/native/<category>/<key>.wav and is resolved via
  /// PronunciationService.referenceWavPathForGrading().
  Future<void> _gradePronunciation() async {
    final myPath = _myRecordingPath;
    if (myPath == null) return;

    setState(() {
      _isGrading = true;
      _noReference = false;
      _gradeError = null;
    });

    try {
      // Try to find the reference WAV. NativeAudioInventory said the
      // canonical recording exists (otherwise the word wouldn't be in
      // the pool), but the WAV side-car may be missing on devices
      // running an APK that was built BEFORE the v2 PAD pack pipeline
      // landed (Phase 1C — Session 60+). Show an honest message in
      // that case instead of silently hiding the card.
      final refPath = await _pronunciation.referenceWavPathForGrading(
        awingWord: _currentWord.awing,
        category: 'vocabulary',
      );
      if (refPath == null) {
        if (!mounted) return;
        setState(() {
          _isGrading = false;
          _noReference = true;
          _lastGrade = null;
        });
        return;
      }

      // Decode both WAVs to Float32 mono @ 16 kHz, then grade.
      final myAudio = await WavDecoder.decodeFile(myPath);
      final refAudio = await WavDecoder.decodeFile(refPath);
      final result = await PronunciationGrader.instance.grade(
        kidAudio: myAudio,
        referenceAudio: refAudio,
      );

      if (!mounted) return;
      setState(() {
        _isGrading = false;
        _lastGrade = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGrading = false;
        _lastGrade = null;
        _gradeError = e.toString();
      });
    }
  }

  Future<void> _playMyRecording() async {
    final path = _myRecordingPath;
    if (path == null) return;
    try {
      setState(() => _isPlayingMine = true);
      await _player.play(DeviceFileSource(path));
    } catch (_) {
      if (mounted) setState(() => _isPlayingMine = false);
    }
  }

  Future<void> _hearReference() async {
    await _pronunciation.speakAwing(_currentWord.awing);
  }

  void _nextWord() {
    setState(() {
      _currentWord = _getRandomWord();
      _myRecordingPath = null;
      _lastGrade = null;
      _noReference = false;
      _gradeError = null;
    });
  }

  /// Kid-friendly message + emoji for each star rating. Keeps the tone
  /// encouraging — even 1 star says "try again" not "wrong."
  ({String message, Color color, IconData icon}) _feedbackFor(int stars) {
    switch (stars) {
      case 5:
        return (
          message: 'Excellent! You sound like a native speaker!',
          color: Colors.green.shade700,
          icon: Icons.celebration,
        );
      case 4:
        return (
          message: 'Great job! Very close to the reference.',
          color: Colors.green.shade600,
          icon: Icons.thumb_up,
        );
      case 3:
        return (
          message: 'Good try! Listen again and try once more.',
          color: Colors.blue.shade700,
          icon: Icons.lightbulb,
        );
      case 2:
        return (
          message: 'Almost there! Listen carefully to the reference.',
          color: Colors.orange.shade700,
          icon: Icons.hearing,
        );
      default:
        return (
          message: 'Tap "Hear it" first, then try recording again.',
          color: Colors.deepOrange.shade700,
          icon: Icons.replay,
        );
    }
  }

  Widget _gradeCard() {
    if (_isGrading) {
      return Card(
        color: Colors.amber.shade50,
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(width: 12),
              Text(
                'Listening to your pronunciation...',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    // No reference WAV found for this word. Either the device is running
    // an APK built before the v2 PAD pack pipeline (no WAV side-cars
    // yet), or the audio_key has no actual recording on disk despite
    // matching the manifest. Either way, be honest about it.
    if (_noReference) {
      return Card(
        color: Colors.blueGrey.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.blueGrey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blueGrey.shade700),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'No reference recording for this word yet. Listen and '
                  'compare by ear, or tap Next word.',
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Grader threw — surface a quiet diagnostic so we can find the bug.
    if (_gradeError != null) {
      return Card(
        color: Colors.red.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.red.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Couldn\'t grade this attempt. Tap Try again.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.red.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final r = _lastGrade;
    if (r == null) return const SizedBox.shrink();

    final fb = _feedbackFor(r.stars);
    final ratio = r.durationRatio;
    // Friendly hint when the kid's recording is much longer than the
    // reference, meaning they hesitated or stayed silent. We trim
    // silence automatically so the score isn't deflated, but it's
    // worth telling them about it.
    final paceHint = (ratio > 1.5)
        ? 'Tip: try to say it a little quicker, like the reference.'
        : (ratio > 0 && ratio < 0.65)
            ? 'Tip: say the full word a little slower.'
            : null;

    return Card(
      color: fb.color.withOpacity(0.07),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: fb.color.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  Icon(
                    i <= r.stars ? Icons.star : Icons.star_border,
                    color: Colors.amber.shade600,
                    size: 38,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${r.percent.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: fb.color,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(fb.icon, color: fb.color, size: 22),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    fb.message,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: fb.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            if (paceHint != null) ...[
              const SizedBox(height: 8),
              Text(
                paceHint,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pronunciation Practice'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Session stat — just a positive count, no fake score.
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Words practiced: $_wordsPracticed',
                      style: TextStyle(
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Picture of the current word — responsive to device width.
              Builder(
                builder: (context) {
                  final imageSize = (MediaQuery.of(context).size.width * 0.5)
                      .clamp(120.0, 200.0);
                  return Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        width: imageSize,
                        height: imageSize,
                        child: PackImage(
                          awingWord: _currentWord.awing,
                          english: _currentWord.english,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Awing word (big) — auto-shrink to fit narrow phones.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _currentWord.awing,
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _currentWord.english,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Step 1: Hear the reference.
              ElevatedButton.icon(
                onPressed: _isRecording ? null : _hearReference,
                icon: const Icon(Icons.volume_up),
                label: const Text('Hear it'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 26, vertical: 12),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Step 2: Big mic — tap to start/stop recording.
              Center(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isRecording
                          ? 1.0 + (_pulseController.value * 0.12)
                          : 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (_isRecording)
                              BoxShadow(
                                color: Colors.red.withOpacity(
                                    0.3 + (_pulseController.value * 0.3)),
                                blurRadius:
                                    20 + (_pulseController.value * 10),
                                spreadRadius:
                                    8 + (_pulseController.value * 5),
                              ),
                          ],
                        ),
                        child: SizedBox(
                          width: 96,
                          height: 96,
                          child: FloatingActionButton(
                            heroTag: 'mic',
                            backgroundColor: _isRecording
                                ? Colors.red.shade600
                                : Colors.blue.shade600,
                            onPressed:
                                _isRecording ? _stopRecording : _startRecording,
                            child: Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              size: 42,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isRecording
                    ? 'Recording… $_recordingSecondsLeft s left'
                    : _myRecordingPath == null
                        ? 'Tap the mic and say the word'
                        : 'Recorded! Listen to yourself below.',
                style: TextStyle(color: _isRecording && _recordingSecondsLeft <= 3 ? Colors.red.shade700 : Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Step 3: Playback controls — appear once there's a recording.
              if (_myRecordingPath != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Compare the two:',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _hearReference,
                            icon: const Icon(Icons.volume_up),
                            label: const Text('Hear it'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isPlayingMine ? null : _playMyRecording,
                            icon: Icon(_isPlayingMine
                                ? Icons.graphic_eq
                                : Icons.play_circle),
                            label: Text(_isPlayingMine ? 'Playing…' : 'Play mine'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Listen to both — your stars below show how close they sound.',
                        style: TextStyle(
                            fontSize: 14, color: Colors.blue.shade900),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // On-device grade card (DTW + MFCC) — appears once the
                // grader finishes processing the recording.
                _gradeCard(),
                const SizedBox(height: 14),

                // Action row.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _startRecording,
                      icon: const Icon(Icons.replay),
                      label: const Text('Try again'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade700,
                        side: BorderSide(color: Colors.orange.shade300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _nextWord,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next word'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
