import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Session 64 (M1+M2): single source of truth for per-difficulty-level
/// UI metadata (color, icon, label, max difficulty). Previously this data
/// was inlined into `_levelIcon`/`_levelColor`/`_levelLabelForBar`/
/// `_maxDifficultyForLevel`/`_difficultyLabel`/`_difficultyColor` across
/// study_set_list_screen.dart, study_set_editor_screen.dart, and
/// translate/word_translate.dart — every new level meant N-file edits.
///
/// USAGE
/// -----
///   `LevelInfo.beginner`         → info for a specific level
///   `LevelInfo.forName('medium')` → info by string ('beginner' /
///                                  'medium' / 'expert' — case-
///                                  insensitive)
///   `LevelInfo.forDifficulty(2)`  → info by difficulty integer
///                                  (1=beginner, 2=medium, 3=expert)
///
/// Colors reference AppColors so a theme migration touches one file.
class LevelInfo {
  final String name;
  final String label;
  final IconData icon;
  final Color color;
  final Color tint;

  /// Highest AwingWord.difficulty (int) content that this level should
  /// surface. Beginner: 1 (only difficulty=1). Medium: 2 (≤2). Expert:
  /// 3 (all).
  final int maxDifficulty;

  const LevelInfo._({
    required this.name,
    required this.label,
    required this.icon,
    required this.color,
    required this.tint,
    required this.maxDifficulty,
  });

  static const beginner = LevelInfo._(
    name: 'beginner',
    label: 'Beginner',
    icon: Icons.child_care,
    color: AppColors.beginner,
    tint: AppColors.beginnerTint,
    maxDifficulty: 1,
  );

  static const medium = LevelInfo._(
    name: 'medium',
    label: 'Medium',
    icon: Icons.school,
    color: AppColors.medium,
    tint: AppColors.mediumTint,
    maxDifficulty: 2,
  );

  static const expert = LevelInfo._(
    name: 'expert',
    label: 'Expert',
    icon: Icons.emoji_events,
    color: AppColors.expert,
    tint: AppColors.expertTint,
    maxDifficulty: 3,
  );

  static const List<LevelInfo> all = [beginner, medium, expert];

  /// Look up by level string. Falls back to Beginner for unknown input
  /// so callers never get a null. Case-insensitive.
  static LevelInfo forName(String name) {
    switch (name.toLowerCase()) {
      case 'medium':
        return medium;
      case 'expert':
        return expert;
      case 'beginner':
      default:
        return beginner;
    }
  }

  /// Look up by AwingWord.difficulty integer.
  static LevelInfo forDifficulty(int difficulty) {
    if (difficulty <= 1) return beginner;
    if (difficulty == 2) return medium;
    return expert;
  }
}
