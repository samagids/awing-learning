import 'package:flutter/material.dart';

/// Semantic color tokens for the Awing app. Session 64 (C4) introduces
/// this as the FOUNDATION for a future dark-mode migration — right now
/// dark mode is intentionally disabled in main.dart because ~750
/// hardcoded `Colors.green.shade400`-style calls make it unreadable.
/// The plan is: (1) ship this token file, (2) migrate high-traffic
/// screens (home + mode homes + quiz) to reference these tokens instead
/// of raw Colors, (3) when enough is migrated we flip dark mode back
/// on and add a `.dark` variant of each token.
///
/// USAGE
/// -----
///   Instead of:   `Colors.green.shade400`   (Beginner accent)
///   Write:        `AppColors.beginner`
///
///   Instead of:   `Colors.orange`           (Medium accent)
///   Write:        `AppColors.medium`
///
///   Instead of:   `Colors.red.shade600`     (Expert dark accent)
///   Write:        `AppColors.expertDark`
///
/// Screens that already reference the raw Colors continue to work.
/// Migration is opt-in and incremental. Any new code MUST use these
/// tokens.
class AppColors {
  AppColors._();

  // ─── Level identity ───
  //
  // These are the mode's "primary" accent — used for AppBar backgrounds,
  // primary buttons, mode-card gradients, and voice-picker selected chip.
  // Each has a lighter shade for accents/tints and a darker shade for
  // pressed / hover states.

  /// Beginner mode. Green.
  static const Color beginner = Color(0xFF43A047); // green.shade600
  static const Color beginnerLight = Color(0xFF66BB6A); // green.shade400
  static const Color beginnerDark = Color(0xFF2E7D32); // green.shade800
  static const Color beginnerTint = Color(0xFFE8F5E9); // green.shade50

  /// Medium mode. Orange.
  static const Color medium = Color(0xFFF57C00); // orange.shade700
  static const Color mediumLight = Color(0xFFFB8C00); // orange.shade600
  static const Color mediumDark = Color(0xFFE65100); // orange.shade900
  static const Color mediumTint = Color(0xFFFFF3E0); // orange.shade50

  /// Expert mode. Red.
  static const Color expert = Color(0xFFE53935); // red.shade600
  static const Color expertLight = Color(0xFFEF5350); // red.shade400
  static const Color expertDark = Color(0xFFC62828); // red.shade800
  static const Color expertTint = Color(0xFFFFEBEE); // red.shade50

  // ─── Native-recording status ───
  //
  // Used by Study Set editor mic-icon states, Contribute record picker,
  // and the About screen contributors section. `native` = verified
  // green (native recording exists), `teacherRecorded` = matched green
  // (teacher uploaded their own), `missing` = amber alert (needs
  // recording). Sessions 46 + 63 established these three states.

  static const Color native = Color(0xFF2E7D32); // green.shade800
  static const Color teacherRecorded = Color(0xFF43A047); // green.shade600
  static const Color missingRecording = Color(0xFFF57C00); // orange.shade700

  // ─── Quiz result feedback ───
  //
  // Used by every quiz answer button and result card. `correct` /
  // `incorrect` / `neutral` (unpicked). Keep in sync with what
  // ConfettiController expects (correct triggers celebration).

  static const Color correct = Color(0xFF43A047); // green.shade600
  static const Color incorrect = Color(0xFFE53935); // red.shade600
  static const Color neutral = Color(0xFF9E9E9E); // grey.shade500

  /// Ranked-answer badges used in the live exam leaderboard. Gold /
  /// silver / bronze — matches emoji 🥇🥈🥉.
  static const Color gold = Color(0xFFFFC107); // amber.shade500
  static const Color silver = Color(0xFF9E9E9E); // grey.shade500
  static const Color bronze = Color(0xFFA1887F); // brown.shade300

  // ─── Text semantics ───

  /// Muted / secondary text (subtitles, timestamps, hints).
  static const Color textMuted = Color(0xFF757575); // grey.shade600

  /// The Awing brand green — used for the app's own primary chrome
  /// (login gate icons, Awing keyboard title, Contribute CTA).
  static const Color awingBrand = Color(0xFF006432);

  /// Returns the level's primary color by string name. Convenience for
  /// screens that route by level string ('beginner' / 'medium' /
  /// 'expert') — e.g. Study Set list, exam setup, translate screen.
  static Color forLevel(String level) {
    switch (level.toLowerCase()) {
      case 'medium':
        return medium;
      case 'expert':
        return expert;
      case 'beginner':
      default:
        return beginner;
    }
  }

  /// Returns the level's tint (subtle background) by string name.
  static Color tintForLevel(String level) {
    switch (level.toLowerCase()) {
      case 'medium':
        return mediumTint;
      case 'expert':
        return expertTint;
      case 'beginner':
      default:
        return beginnerTint;
    }
  }
}
