import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:awing_ai_learning/services/pronunciation_grader.dart';
import 'package:awing_ai_learning/utils/wav_decoder.dart';

/// Smoke test for the pure-Dart pronunciation grader.
///
/// Validates the MFCC + DTW pipeline before wiring into the Beginner
/// pronunciation screen in Phase 1C.
///
/// Three tests:
///   1. **Sanity** — Grade the reference WAV against itself. Cost should
///      be ~0 (the grader is reflexive). If this fails, MFCC or DTW is
///      broken.
///   2. **Live recording** — Capture mic audio, grade against the
///      reference. This is the production code path.
///   3. **Timing** — Reports wall-clock grading time so we know mobile
///      CPU is fast enough (target < 500 ms per word; anything above
///      that needs optimization).
///
/// Sideload (one-time per device):
///   adb shell mkdir -p /sdcard/awing_grader
///   adb push training_data\recordings\apo.wav /sdcard/awing_grader/
///
/// (any 16 kHz mono PCM WAV works — try sama__apo.wav for Dr. Sama's
/// actual reference.)
class GraderSmokeTestScreen extends StatefulWidget {
  const GraderSmokeTestScreen({super.key});

  @override
  State<GraderSmokeTestScreen> createState() => _GraderSmokeTestScreenState();
}

class _GraderSmokeTestScreenState extends State<GraderSmokeTestScreen> {
  // Resolved at runtime via getExternalStorageDirectory() because Android 11+
  // blocks apps from reading arbitrary /sdcard/ paths (errno 13 / Permission
  // denied). The app-owned external-files dir IS accessible via `adb push`
  // without root, and the app can read it without runtime permission.
  // Typical resolved value:
  //   /storage/emulated/0/Android/data/com.awing.learning/files/awing_grader/apo.wav
  String? _referencePath;

  final AudioRecorder _recorder = AudioRecorder();

  String _status = 'Resolving reference path ...';
  bool _busy = false;
  bool _isRecording = false;
  GradeResult? _selfResult;
  GradeResult? _liveResult;

  @override
  void initState() {
    super.initState();
    _resolveReferencePath();
  }

  Future<void> _resolveReferencePath() async {
    try {
      final extDir = await getExternalStorageDirectory();
      final base = extDir?.path ?? (await getApplicationSupportDirectory()).path;
      final dir = '$base/awing_grader';
      // Ensure the dir exists so the adb push target works first try
      try {
        await Directory(dir).create(recursive: true);
      } catch (_) {}
      setState(() {
        _referencePath = '$dir/apo.wav';
        _status = 'Idle. Sideload the reference WAV, then tap "Sanity test".';
      });
    } catch (e) {
      setState(() {
        _status = '✗ Could not resolve reference dir: $e';
      });
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _selfTest() async {
    final refPath = _referencePath;
    if (refPath == null) {
      setState(() {
        _status = '✗ Reference path not resolved yet. Reopen this screen.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _status = 'Loading reference WAV from $refPath ...';
      _selfResult = null;
    });
    try {
      final f = File(refPath);
      if (!await f.exists()) {
        setState(() {
          _busy = false;
          _status = '✗ Reference WAV not found at $refPath\n\n'
              'Sideload from your dev machine:\n'
              '  adb push training_data\\recordings\\apo.wav $refPath';
        });
        return;
      }
      final audio = await WavDecoder.decodeFile(refPath);
      final durationSec = audio.length / 16000;
      setState(() {
        _status = 'Decoded ${audio.length} samples '
            '(${durationSec.toStringAsFixed(2)} sec @ 16 kHz). '
            'Running self-comparison ...';
      });
      final result = await PronunciationGrader.instance.grade(
        kidAudio: audio,
        referenceAudio: audio,
      );
      setState(() {
        _selfResult = result;
        _busy = false;
        _status = '✓ Sanity test complete. '
            'Cost should be ~0 if the MFCC + DTW pipeline is correct.';
      });
    } catch (e, st) {
      setState(() {
        _busy = false;
        _status = '✗ Sanity test failed: $e\n\n$st';
      });
    }
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        setState(() {
          _status = '✗ Microphone permission denied. '
              'Grant in system settings and try again.';
        });
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/grader_live.wav';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 256000,
        ),
        path: path,
      );
      setState(() {
        _isRecording = true;
        _liveResult = null;
        _status = '🎤 Recording... Speak the same word as the reference, '
            'then tap "Stop & grade".';
      });
    } catch (e, st) {
      setState(() {
        _isRecording = false;
        _status = '✗ Failed to start recording: $e\n\n$st';
      });
    }
  }

  Future<void> _stopAndGrade() async {
    String? path;
    try {
      path = await _recorder.stop();
    } catch (e) {
      setState(() {
        _isRecording = false;
        _status = '✗ Failed to stop recording: $e';
      });
      return;
    }
    if (path == null) {
      setState(() {
        _isRecording = false;
        _status = '✗ Recording stopped but no file was produced.';
      });
      return;
    }
    setState(() {
      _isRecording = false;
      _busy = true;
      _status = 'Recording saved to $path\nDecoding + grading ...';
    });
    try {
      final refPath = _referencePath;
      if (refPath == null) {
        setState(() {
          _busy = false;
          _status = '✗ Reference path not resolved.';
        });
        return;
      }
      final refFile = File(refPath);
      if (!await refFile.exists()) {
        setState(() {
          _busy = false;
          _status = '✗ Reference WAV not found at $refPath\n'
              'Sideload it first (see instructions above).';
        });
        return;
      }
      final liveFile = File(path);
      final liveBytes = await liveFile.length();
      if (liveBytes < 1024) {
        setState(() {
          _busy = false;
          _status = '✗ Recording too short ($liveBytes bytes). '
              'Try again — hold the button longer.';
        });
        return;
      }
      final ref = await WavDecoder.decodeFile(refPath);
      final live = await WavDecoder.decodeFile(path);
      final result = await PronunciationGrader.instance.grade(
        kidAudio: live,
        referenceAudio: ref,
      );
      setState(() {
        _liveResult = result;
        _busy = false;
        _status = '✓ Live grade complete. '
            'Recording: ${(live.length / 16000).toStringAsFixed(2)} sec, '
            'Reference: ${(ref.length / 16000).toStringAsFixed(2)} sec.';
      });
    } catch (e, st) {
      setState(() {
        _busy = false;
        _status = '✗ Grading failed: $e\n\n$st';
      });
    }
  }

  Widget _resultCard(String title, GradeResult? r, {bool expectZero = false}) {
    if (r == null) return const SizedBox.shrink();
    final cost = r.cost.isFinite ? r.cost.toStringAsFixed(3) : '∞';
    final zeroNote = expectZero
        ? (r.cost < 0.5 ? '  (≈ 0  ✓)' : '  (expected ≈ 0  ⚠)')
        : '';

    final ratio = r.durationRatio;
    final ratioWarning = (ratio > 0 && (ratio < 0.65 || ratio > 1.5))
        ? '  ⚠ off (probably wrong word or noisy)'
        : (ratio > 0 ? '  ✓' : '');

    final silenceNote = r.kidSilenceRemovedSec > 0.1
        ? '  ✂ trimmed ${r.kidSilenceRemovedSec.toStringAsFixed(2)} sec silence'
        : '';

    final silentFlag = r.kidAllSilent
        ? '\n⚠ Recording appears entirely silent — no speech detected.'
        : '';

    return Card(
      color: r.cost < 18.0 ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            SelectableText(
              'DTW cost:        $cost$zeroNote\n'
              'Stars:           ${'⭐' * r.stars}${'☆' * (5 - r.stars)}  (${r.stars}/5)\n'
              'Score:           ${r.percent.toStringAsFixed(1)}%\n'
              'Elapsed:         ${r.elapsed.inMilliseconds} ms\n'
              'Kid duration:    ${r.kidOriginalSec.toStringAsFixed(2)}s → ${r.kidTrimmedSec.toStringAsFixed(2)}s$silenceNote\n'
              'Ref duration:    ${r.referenceOriginalSec.toStringAsFixed(2)}s → ${r.referenceTrimmedSec.toStringAsFixed(2)}s\n'
              'Duration ratio:  ${ratio.toStringAsFixed(2)}x$ratioWarning\n'
              'Kid frames:      ${r.kidFrames}\n'
              'Ref frames:      ${r.referenceFrames}'
              '$silentFlag',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
              ),
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
        title: const Text('Grader smoke test'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'On-device pronunciation grader — DTW + MFCC',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pure-Dart grader. Compares kid recording against a '
                'native-speaker reference via MFCC + Dynamic Time Warping. '
                'Zero native dependencies — works on every Android ABI, '
                'iOS, desktop, web — fully offline. Validate here, then '
                'wire into the Beginner pronunciation screen in Phase 1C.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sideload reference (one-time per device):',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        _referencePath == null
                            ? '(resolving path...)'
                            : 'adb push training_data\\recordings\\apo.wav $_referencePath',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Any 16 kHz mono PCM WAV works. We use the app-owned '
                        'external dir so Android 11+ scoped storage doesn\'t '
                        'block the read (errno 13). Sideloaded files persist '
                        'until the app is uninstalled.',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: (_busy || _isRecording) ? null : _selfTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  '1. Sanity test (compare reference to itself)',
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _busy
                    ? null
                    : (_isRecording ? _stopAndGrade : _startRecording),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _isRecording
                      ? '⏹  Stop & grade'
                      : '2. Record live and grade vs reference',
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    _status,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _resultCard(
                'Sanity (self-comparison)',
                _selfResult,
                expectZero: true,
              ),
              const SizedBox(height: 8),
              _resultCard('Live recording vs reference', _liveResult),
            ],
          ),
        ),
      ),
    );
  }
}
