import 'dart:math' as math;
import 'dart:typed_data';

/// Energy-based silence trimmer for 16 kHz mono PCM Float32 audio.
///
/// Removes leading and trailing low-energy windows so downstream MFCC +
/// DTW doesn't waste alignment path-cost on silence-vs-speech mismatches.
/// This is the single biggest accuracy win for grading kid recordings,
/// because kids (and adults) routinely tap Record, pause, speak, pause,
/// tap Stop — leaving 1-2 seconds of dead air around the actual word.
///
/// Algorithm (mirrored exactly in scripts/trim_silence.py so the on-device
/// grader and the family-recording ingestion pipeline behave identically):
///   1. Split signal into 10 ms windows (160 samples at 16 kHz)
///   2. Compute RMS energy per window
///   3. Threshold = max(peak * 5%, 0.005 absolute floor)
///   4. Trim leading + trailing windows below threshold
///   5. Pad result by 20 ms on each side so plosives aren't clipped
///
/// Returns a [TrimResult] so callers can show diagnostics ("removed 1.4
/// sec of silence") and detect pathological cases (all-silent recording).
class SilenceTrim {
  static const int defaultSampleRate = 16000;
  static const int defaultWindowMs = 10;
  static const double defaultRelativeThreshold = 0.05;
  static const double defaultHardFloor = 0.005;
  static const int defaultPadMs = 20;

  /// Trim leading + trailing silence. Returns a [TrimResult] with the
  /// trimmed audio (a zero-copy view of the input where possible) plus
  /// diagnostic metrics.
  static TrimResult trim(
    Float32List signal, {
    int sampleRate = defaultSampleRate,
    int windowMs = defaultWindowMs,
    double relativeThreshold = defaultRelativeThreshold,
    double hardFloor = defaultHardFloor,
    int padMs = defaultPadMs,
  }) {
    if (signal.isEmpty) {
      return TrimResult(
        trimmed: signal,
        originalSamples: 0,
        trimmedSamples: 0,
        sampleRate: sampleRate,
        thresholdUsed: 0.0,
      );
    }
    final windowSize = (sampleRate * windowMs / 1000).round();
    final numWindows = signal.length ~/ windowSize;
    if (numWindows < 3) {
      // Too short to meaningfully trim
      return TrimResult(
        trimmed: signal,
        originalSamples: signal.length,
        trimmedSamples: signal.length,
        sampleRate: sampleRate,
        thresholdUsed: 0.0,
      );
    }

    // RMS energy per window
    final energies = Float32List(numWindows);
    var peak = 0.0;
    for (var w = 0; w < numWindows; w++) {
      var sumSq = 0.0;
      final base = w * windowSize;
      for (var i = 0; i < windowSize; i++) {
        final s = signal[base + i];
        sumSq += s * s;
      }
      final rms = math.sqrt(sumSq / windowSize);
      energies[w] = rms;
      if (rms > peak) peak = rms;
    }

    final threshold = math.max(peak * relativeThreshold, hardFloor);

    // First window above threshold
    var firstActive = 0;
    while (firstActive < numWindows && energies[firstActive] < threshold) {
      firstActive++;
    }
    // Last window above threshold
    var lastActive = numWindows - 1;
    while (lastActive > firstActive && energies[lastActive] < threshold) {
      lastActive--;
    }

    if (firstActive >= lastActive) {
      // All silence (or one active window) — leave it alone
      return TrimResult(
        trimmed: signal,
        originalSamples: signal.length,
        trimmedSamples: signal.length,
        sampleRate: sampleRate,
        thresholdUsed: threshold,
        allSilent: true,
      );
    }

    // Add padding so plosive onsets/releases aren't clipped
    final padWindows = (padMs / windowMs).round();
    firstActive = math.max(0, firstActive - padWindows);
    lastActive = math.min(numWindows - 1, lastActive + padWindows);

    final startSample = firstActive * windowSize;
    final endSample = math.min(signal.length, (lastActive + 1) * windowSize);

    // Zero-copy view into the original buffer.
    final trimmed = Float32List.sublistView(signal, startSample, endSample);

    return TrimResult(
      trimmed: trimmed,
      originalSamples: signal.length,
      trimmedSamples: trimmed.length,
      sampleRate: sampleRate,
      thresholdUsed: threshold,
    );
  }
}

/// Result of [SilenceTrim.trim] — trimmed audio plus diagnostics.
class TrimResult {
  /// Trimmed signal (or original if no trim happened).
  final Float32List trimmed;

  /// Sample count of the original (untrimmed) input.
  final int originalSamples;

  /// Sample count after trimming.
  final int trimmedSamples;

  /// Sample rate (Hz) of the audio. Used to convert sample counts to
  /// seconds in [originalSec] / [trimmedSec] / [removedSec].
  final int sampleRate;

  /// RMS threshold the trimmer used. Surfaced for debugging cases where
  /// the trim was too aggressive (high threshold → cut speech) or too
  /// permissive (low threshold → kept noise).
  final double thresholdUsed;

  /// True if every window was below threshold — recording was entirely
  /// silent or sub-noise-floor. Caller should treat this as "no speech."
  final bool allSilent;

  const TrimResult({
    required this.trimmed,
    required this.originalSamples,
    required this.trimmedSamples,
    required this.sampleRate,
    required this.thresholdUsed,
    this.allSilent = false,
  });

  double get originalSec => originalSamples / sampleRate;
  double get trimmedSec => trimmedSamples / sampleRate;
  double get removedSec => originalSec - trimmedSec;
  double get keepRatio =>
      originalSamples == 0 ? 1.0 : trimmedSamples / originalSamples;
}
