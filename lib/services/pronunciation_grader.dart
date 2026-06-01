import 'dart:math' as math;
import 'dart:typed_data';

import 'package:awing_ai_learning/utils/dtw.dart';
import 'package:awing_ai_learning/utils/mfcc.dart';
import 'package:awing_ai_learning/utils/silence_trim.dart';
import 'package:awing_ai_learning/utils/wav_decoder.dart';

/// Pure-Dart pronunciation grader for the Awing AI Learning app.
///
/// Compares a kid's recording against a bundled native-speaker reference
/// (Dr. Sama's recording for the same word) via MFCC + Dynamic Time
/// Warping. Returns a 0-100 percent score, a 1-5 star rating, and the
/// raw DTW cost.
///
/// Architecture:
///   - Zero native dependencies. Runs on every Flutter target — every
///     Android ABI (arm64, armv7, x86_64), iOS, desktop, web.
///   - 100% offline. Reference audio is already bundled in the
///     install-time PAD pack as audio/native/{category}/{key}.mp3.
///   - Zero new app size. Code is ~500 lines of pure Dart.
///   - Tonal-aware. MFCC captures spectral envelope; if Awing tone
///     contrasts matter for grading, we can layer F0 (pitch) as a
///     second cost channel in a later iteration.
///
/// Replaces the abandoned MMS-FA ONNX approach which (a) had no
/// x86_64 Android binary in the upstream package, (b) shipped a
/// 605 MB model too big to bundle offline, (c) required server or
/// on-demand-download fallback that doesn't fit the audience's
/// connectivity constraints.
class PronunciationGrader {
  PronunciationGrader._();
  static final PronunciationGrader instance = PronunciationGrader._();

  /// Grade a kid's recording against a reference. Both must be mono
  /// Float32 at 16 kHz (use [WavDecoder] to load from disk).
  ///
  /// Returns a [GradeResult] with:
  ///   - cost:    raw DTW mean per-frame cost (lower = better match)
  ///   - stars:   1-5 rating mapped from cost via empirical thresholds
  ///   - percent: 0-100 score (smooth exponential decay of cost)
  ///   - elapsed: wall-clock grading time
  Future<GradeResult> grade({
    required Float32List kidAudio,
    required Float32List referenceAudio,
    bool trimSilence = true,
  }) async {
    final sw = Stopwatch()..start();

    if (kidAudio.isEmpty || referenceAudio.isEmpty) {
      sw.stop();
      return GradeResult._empty(sw.elapsed);
    }

    // Trim leading/trailing silence so DTW doesn't waste path-cost on
    // dead-air-vs-speech mismatches. Single biggest accuracy win when
    // kids (or anyone) record with finger-on-button latency.
    final kidTrim = trimSilence
        ? SilenceTrim.trim(kidAudio)
        : TrimResult(
            trimmed: kidAudio,
            originalSamples: kidAudio.length,
            trimmedSamples: kidAudio.length,
            sampleRate: 16000,
            thresholdUsed: 0.0,
          );
    final refTrim = trimSilence
        ? SilenceTrim.trim(referenceAudio)
        : TrimResult(
            trimmed: referenceAudio,
            originalSamples: referenceAudio.length,
            trimmedSamples: referenceAudio.length,
            sampleRate: 16000,
            thresholdUsed: 0.0,
          );

    final kidMfcc = Mfcc.compute(kidTrim.trimmed);
    final refMfcc = Mfcc.compute(refTrim.trimmed);

    if (kidMfcc.isEmpty || refMfcc.isEmpty) {
      sw.stop();
      return GradeResult(
        cost: double.infinity,
        stars: 0,
        percent: 0.0,
        elapsed: sw.elapsed,
        kidFrames: kidMfcc.length,
        referenceFrames: refMfcc.length,
        kidOriginalSec: kidTrim.originalSec,
        kidTrimmedSec: kidTrim.trimmedSec,
        referenceOriginalSec: refTrim.originalSec,
        referenceTrimmedSec: refTrim.trimmedSec,
        kidAllSilent: kidTrim.allSilent,
      );
    }

    final cost = Dtw.meanCost(kidMfcc, refMfcc);
    sw.stop();

    return GradeResult(
      cost: cost,
      stars: _costToStars(cost),
      percent: _costToPercent(cost),
      elapsed: sw.elapsed,
      kidFrames: kidMfcc.length,
      referenceFrames: refMfcc.length,
      kidOriginalSec: kidTrim.originalSec,
      kidTrimmedSec: kidTrim.trimmedSec,
      referenceOriginalSec: refTrim.originalSec,
      referenceTrimmedSec: refTrim.trimmedSec,
      kidAllSilent: kidTrim.allSilent,
    );
  }

  /// Convenience: load a reference WAV from disk and grade against it.
  /// Useful for the smoke test and for the future Phase 1C integration
  /// where the reference path comes from a recorder slug lookup.
  Future<GradeResult> gradeAgainstReferenceFile({
    required Float32List kidAudio,
    required String referenceWavPath,
  }) async {
    final ref = await WavDecoder.decodeFile(referenceWavPath);
    return grade(kidAudio: kidAudio, referenceAudio: ref);
  }

  // ------------------------------------------------------------------
  // Score mapping
  // ------------------------------------------------------------------
  //
  // Thresholds are empirical for 13-dim MFCC + L2 distance + the
  // mel-normalized DTW path. They'll need calibration once we have
  // a few hundred (kid recording, expert-judged star rating) pairs
  // from real users. Until then these defaults are conservative —
  // self-comparison hits 5 stars, modest variations land at 3-4,
  // wrong-word recordings drop below 2.
  // ------------------------------------------------------------------

  int _costToStars(double cost) {
    if (cost < 8.0) return 5;
    if (cost < 12.0) return 4;
    if (cost < 18.0) return 3;
    if (cost < 25.0) return 2;
    return 1;
  }

  /// Exponential decay: cost = 0 → 100%, cost = ~30 → ~13%, cost = ∞ → 0%.
  double _costToPercent(double cost) {
    if (cost.isInfinite || cost.isNaN) return 0.0;
    final pct = 100.0 * math.exp(-cost / 15.0);
    return pct.clamp(0.0, 100.0);
  }
}

class GradeResult {
  /// Raw DTW mean per-frame cost. Lower = more similar.
  final double cost;

  /// 1-5 star rating, mapped from [cost] via empirical thresholds.
  final int stars;

  /// 0-100 percentage score for display.
  final double percent;

  /// Wall-clock time to grade.
  final Duration elapsed;

  /// Number of MFCC frames extracted from the kid's recording AFTER trim.
  final int kidFrames;

  /// Number of MFCC frames extracted from the reference recording AFTER trim.
  final int referenceFrames;

  /// Duration of the kid's recording before silence trimming (sec).
  final double kidOriginalSec;

  /// Duration of the kid's recording after silence trimming (sec).
  final double kidTrimmedSec;

  /// Duration of the reference recording before silence trimming (sec).
  final double referenceOriginalSec;

  /// Duration of the reference recording after silence trimming (sec).
  final double referenceTrimmedSec;

  /// True when the kid's recording was entirely below noise floor — i.e.
  /// no speech was captured at all. UI should suggest retry.
  final bool kidAllSilent;

  const GradeResult({
    required this.cost,
    required this.stars,
    required this.percent,
    required this.elapsed,
    required this.kidFrames,
    required this.referenceFrames,
    required this.kidOriginalSec,
    required this.kidTrimmedSec,
    required this.referenceOriginalSec,
    required this.referenceTrimmedSec,
    this.kidAllSilent = false,
  });

  /// Empty result for the degenerate "no input" case.
  factory GradeResult._empty(Duration elapsed) => GradeResult(
        cost: double.infinity,
        stars: 0,
        percent: 0.0,
        elapsed: elapsed,
        kidFrames: 0,
        referenceFrames: 0,
        kidOriginalSec: 0,
        kidTrimmedSec: 0,
        referenceOriginalSec: 0,
        referenceTrimmedSec: 0,
      );

  /// Kid / reference duration ratio (post-trim). 1.0 = same length;
  /// > 1.5 or < 0.65 is a yellow flag (probably wrong word or extra
  /// noise the trimmer didn't catch).
  double get durationRatio {
    if (referenceTrimmedSec <= 0) return 0;
    return kidTrimmedSec / referenceTrimmedSec;
  }

  /// How many seconds of silence the trimmer removed from the kid's
  /// recording. Useful to surface so the kid learns to record cleanly.
  double get kidSilenceRemovedSec => kidOriginalSec - kidTrimmedSec;

  @override
  String toString() =>
      'GradeResult(cost: ${cost.toStringAsFixed(2)}, stars: $stars, '
      'percent: ${percent.toStringAsFixed(1)}%, '
      'elapsed: ${elapsed.inMilliseconds}ms, '
      'kidFrames: $kidFrames, refFrames: $referenceFrames, '
      'kidSec: ${kidOriginalSec.toStringAsFixed(2)}→${kidTrimmedSec.toStringAsFixed(2)}, '
      'refSec: ${referenceOriginalSec.toStringAsFixed(2)}→${referenceTrimmedSec.toStringAsFixed(2)}, '
      'ratio: ${durationRatio.toStringAsFixed(2)})';
}
