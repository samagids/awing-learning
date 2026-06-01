import 'dart:math' as math;
import 'dart:typed_data';

/// Dynamic Time Warping (DTW) alignment over MFCC feature sequences.
///
/// DTW is the classic algorithm for measuring similarity between two
/// time series that may vary in speed. We use it to compare a kid's
/// pronunciation recording against a native-speaker reference for the
/// same word, even when the two recordings differ in duration (kids
/// speak slower / faster than adults). Returns mean cost per matched
/// frame pair so the score is independent of recording length.
///
/// Pure Dart, no external dependencies — runs on every Flutter target.
class Dtw {
  /// Align two MFCC sequences and return mean Euclidean cost along the
  /// optimal warping path. Lower = more similar.
  ///
  /// Uses standard 3-transition DP (insert / delete / match diagonal).
  /// Memory: O(N × M). For typical word-length audio (1-3 seconds →
  /// ~100-300 frames), that's a few hundred KB — fine for mobile.
  static double meanCost(List<Float32List> a, List<Float32List> b) {
    if (a.isEmpty || b.isEmpty) return double.infinity;
    final n = a.length;
    final m = b.length;

    // Cumulative cost table. Row 0 / col 0 are sentinels = infinity
    // except [0][0] = 0 — classic DTW base case.
    final dp = List.generate(n + 1, (_) => Float64List(m + 1));
    for (var i = 0; i <= n; i++) {
      for (var j = 0; j <= m; j++) {
        dp[i][j] = double.infinity;
      }
    }
    dp[0][0] = 0.0;

    for (var i = 1; i <= n; i++) {
      final ai = a[i - 1];
      for (var j = 1; j <= m; j++) {
        final cost = _euclid(ai, b[j - 1]);
        final best = math.min(
          dp[i - 1][j - 1],
          math.min(dp[i - 1][j], dp[i][j - 1]),
        );
        dp[i][j] = cost + best;
      }
    }

    // Normalize by the longer sequence length so different word
    // durations don't bias the score.
    final pathLen = math.max(n, m);
    return dp[n][m] / pathLen;
  }

  static double _euclid(Float32List a, Float32List b) {
    var sum = 0.0;
    final n = math.min(a.length, b.length);
    for (var i = 0; i < n; i++) {
      final d = a[i] - b[i];
      sum += d * d;
    }
    return math.sqrt(sum);
  }
}
