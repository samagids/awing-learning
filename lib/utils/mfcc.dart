import 'dart:math' as math;
import 'dart:typed_data';

/// Pure-Dart MFCC (Mel-Frequency Cepstral Coefficient) extraction.
///
/// Used by [PronunciationGrader] to convert 16 kHz mono PCM audio into a
/// compact spectral representation that DTW can align against a native
/// speaker reference.
///
/// Why this implementation:
///   - Zero native dependencies — works on every Flutter target (every
///     Android ABI, iOS arm64, desktop, web). The ONNX runtime had no
///     x86_64 Android binary; pure Dart sidesteps that entirely.
///   - Fully offline — no model file to load, no network.
///   - Tiny — ~250 lines of code, ~10 KB compiled. App size impact ≈ 0.
///   - Self-contained — inline radix-2 Cooley-Tukey FFT so we don't need
///     to add the `fftea` dependency.
///
/// Defaults are standard speech-processing values for 16 kHz audio:
///   25 ms frame, 10 ms hop, 26 mel filters, 13 MFCC coefficients.
class Mfcc {
  static const int sampleRate = 16000;
  static const int frameLength = 400; // 25 ms @ 16 kHz
  static const int frameShift = 160; // 10 ms @ 16 kHz
  static const int fftSize = 512; // next pow2 ≥ frameLength
  static const int numMelFilters = 26;
  static const int numMfcc = 13;
  static const double preEmphasisCoeff = 0.97;
  static const double melLowHz = 0.0;
  static const double melHighHz = 8000.0;

  // Pre-computed once and cached. Computing the mel filterbank + DCT
  // matrix is ~5ms; reusing across calls keeps grading near-instant.
  static List<Float64List>? _melFilters;
  static List<Float64List>? _dctMatrix;
  static Float64List? _hamming;

  /// Compute MFCC frames for the given mono Float32 audio at 16 kHz.
  /// Returns a list of [numMfcc]-dim vectors, one per analysis frame.
  /// Empty list if the signal is shorter than one frame.
  static List<Float32List> compute(Float32List signal) {
    if (signal.length < frameLength) return const [];

    final preEmph = _preEmphasis(signal);
    final melFilters = _melFilterbankCached();
    final dct = _dctMatrixCached();
    final ham = _hammingCached();

    final numFrames = 1 + ((preEmph.length - frameLength) ~/ frameShift);
    final out = <Float32List>[];

    final fftRe = Float64List(fftSize);
    final fftIm = Float64List(fftSize);
    final power = Float64List(fftSize ~/ 2 + 1);
    final mel = Float64List(numMelFilters);

    for (var f = 0; f < numFrames; f++) {
      final start = f * frameShift;

      // Window into FFT buffer (pad-zero tail)
      for (var i = 0; i < frameLength; i++) {
        fftRe[i] = preEmph[start + i] * ham[i];
        fftIm[i] = 0.0;
      }
      for (var i = frameLength; i < fftSize; i++) {
        fftRe[i] = 0.0;
        fftIm[i] = 0.0;
      }

      _fft(fftRe, fftIm);

      // Power spectrum (first half + DC)
      for (var i = 0; i < power.length; i++) {
        power[i] = (fftRe[i] * fftRe[i] + fftIm[i] * fftIm[i]) / fftSize;
      }

      // Mel filterbank → log energies
      for (var m = 0; m < numMelFilters; m++) {
        var sum = 0.0;
        final filter = melFilters[m];
        for (var i = 0; i < power.length; i++) {
          sum += power[i] * filter[i];
        }
        mel[m] = math.log(math.max(sum, 1e-10));
      }

      // DCT-II → MFCC
      final mfcc = Float32List(numMfcc);
      for (var c = 0; c < numMfcc; c++) {
        var sum = 0.0;
        final row = dct[c];
        for (var k = 0; k < numMelFilters; k++) {
          sum += mel[k] * row[k];
        }
        mfcc[c] = sum;
      }
      out.add(mfcc);
    }
    return out;
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  static Float32List _preEmphasis(Float32List signal) {
    final out = Float32List(signal.length);
    out[0] = signal[0];
    for (var i = 1; i < signal.length; i++) {
      out[i] = signal[i] - preEmphasisCoeff * signal[i - 1];
    }
    return out;
  }

  static Float64List _hammingCached() {
    var w = _hamming;
    if (w != null) return w;
    w = Float64List(frameLength);
    for (var i = 0; i < frameLength; i++) {
      w[i] = 0.54 - 0.46 * math.cos(2 * math.pi * i / (frameLength - 1));
    }
    _hamming = w;
    return w;
  }

  static double _hzToMel(double hz) =>
      2595.0 * math.log(1 + hz / 700.0) / math.ln10;

  static double _melToHz(double mel) =>
      700.0 * (math.pow(10, mel / 2595.0) - 1).toDouble();

  static List<Float64List> _melFilterbankCached() {
    var fb = _melFilters;
    if (fb != null) return fb;

    final lowMel = _hzToMel(melLowHz);
    final highMel = _hzToMel(melHighHz);
    final melPoints = List<double>.generate(
      numMelFilters + 2,
      (i) => lowMel + (highMel - lowMel) * i / (numMelFilters + 1),
    );
    final hzPoints = melPoints.map(_melToHz).toList();
    final binPoints =
        hzPoints.map((hz) => (hz * fftSize / sampleRate).floor()).toList();

    final powerLen = fftSize ~/ 2 + 1;
    fb = List.generate(numMelFilters, (_) => Float64List(powerLen));
    for (var m = 0; m < numMelFilters; m++) {
      final left = binPoints[m];
      final center = binPoints[m + 1];
      final right = binPoints[m + 2];
      if (center != left) {
        for (var k = left; k < center; k++) {
          if (k >= 0 && k < powerLen) {
            fb[m][k] = (k - left) / (center - left);
          }
        }
      }
      if (right != center) {
        for (var k = center; k < right; k++) {
          if (k >= 0 && k < powerLen) {
            fb[m][k] = (right - k) / (right - center);
          }
        }
      }
    }
    _melFilters = fb;
    return fb;
  }

  static List<Float64List> _dctMatrixCached() {
    var m = _dctMatrix;
    if (m != null) return m;
    m = List.generate(numMfcc, (_) => Float64List(numMelFilters));
    final norm0 = math.sqrt(1.0 / numMelFilters);
    final norm = math.sqrt(2.0 / numMelFilters);
    for (var c = 0; c < numMfcc; c++) {
      final n = c == 0 ? norm0 : norm;
      for (var k = 0; k < numMelFilters; k++) {
        m[c][k] = n * math.cos(math.pi * c * (k + 0.5) / numMelFilters);
      }
    }
    _dctMatrix = m;
    return m;
  }

  /// In-place iterative radix-2 Cooley-Tukey FFT. Length must be a
  /// power of 2. Pure Dart, no external dependency.
  static void _fft(Float64List re, Float64List im) {
    final n = re.length;

    // Bit-reversal permutation
    for (var i = 1, j = 0; i < n; i++) {
      var bit = n >> 1;
      for (; (j & bit) != 0; bit >>= 1) {
        j ^= bit;
      }
      j ^= bit;
      if (i < j) {
        final tr = re[i];
        re[i] = re[j];
        re[j] = tr;
        final ti = im[i];
        im[i] = im[j];
        im[j] = ti;
      }
    }

    // Butterflies
    for (var len = 2; len <= n; len <<= 1) {
      final half = len >> 1;
      final angle = -2 * math.pi / len;
      final wnr = math.cos(angle);
      final wni = math.sin(angle);
      for (var i = 0; i < n; i += len) {
        var wr = 1.0, wi = 0.0;
        for (var k = 0; k < half; k++) {
          final aRe = re[i + k];
          final aIm = im[i + k];
          final bRe = re[i + k + half] * wr - im[i + k + half] * wi;
          final bIm = re[i + k + half] * wi + im[i + k + half] * wr;
          re[i + k] = aRe + bRe;
          im[i + k] = aIm + bIm;
          re[i + k + half] = aRe - bRe;
          im[i + k + half] = aIm - bIm;
          final newWr = wr * wnr - wi * wni;
          wi = wr * wni + wi * wnr;
          wr = newWr;
        }
      }
    }
  }
}
