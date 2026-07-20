import 'dart:convert';

/// A curated wordlist a teacher builds for their class. Session 63
/// (2026-07-10) — see design/study_sets.md.
///
/// Lifecycle:
///   1. Teacher creates set → Phase 1 (LOCAL ONLY, this file)
///   2. Teacher records audio for every word → Phase 3
///   3. Teacher shares with student roster → Phase 2 (Firestore sync)
///   4. Teacher runs exam sourced from set → Phase 4
///
/// Fields are shaped to match the target Firestore document
/// (study_sets/{setId}) so Phase 2 can drop it in cleanly without a
/// migration.
class StudySet {
  /// Client-generated UUID. Set once at creation; never changes.
  final String id;

  /// Teacher's Google email (identity anchor for ownership + sharing).
  final String teacherEmail;

  /// Display name for teacher's UI (e.g. "Grade 3 Unit 2").
  final String teacherName;

  /// Human-readable name of the set.
  String name;

  /// Optional description — teacher notes about focus, level, etc.
  String description;

  /// Awing keys (audio_key format) of words drawn from the existing
  /// app dictionary. Order preserved.
  List<String> wordKeys;

  /// Words the teacher created that don't exist in the app dictionary
  /// yet. These also get submitted through the standard Contribute
  /// pipeline for developer approval → app-wide inclusion in the
  /// future. Order preserved.
  List<StudySetCustomWord> customWords;

  /// Emails of student Google accounts on this set's roster. All
  /// profiles under each email see the set (with per-profile dismiss).
  /// Populated in Phase 2.
  List<String> sharedWithEmails;

  /// Map from Awing key → downloaded audio URL. Populated in Phase 3.
  /// Empty until teacher records + uploads. Used by student browse
  /// view AND by set-share-gate ("all words must have audio").
  Map<String, String> recordings;

  /// Timestamps (ms since epoch, UTC).
  final int createdAt;
  int updatedAt;

  /// Locally-dismissed sets per profile (Phase 2). Not serialized to
  /// Firestore — this is a per-device UI preference layer.
  bool locallyDismissed;

  StudySet({
    required this.id,
    required this.teacherEmail,
    required this.teacherName,
    required this.name,
    this.description = '',
    List<String>? wordKeys,
    List<StudySetCustomWord>? customWords,
    List<String>? sharedWithEmails,
    Map<String, String>? recordings,
    int? createdAt,
    int? updatedAt,
    this.locallyDismissed = false,
  })  : wordKeys = wordKeys ?? [],
        customWords = customWords ?? [],
        sharedWithEmails = sharedWithEmails ?? [],
        recordings = recordings ?? {},
        createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  /// Total words in set (dictionary + custom).
  int get wordCount => wordKeys.length + customWords.length;

  /// True if every word has an audio recording — the gate for sharing
  /// with students in Phase 3.
  bool get isFullyRecorded {
    if (wordCount == 0) return false;
    for (final k in wordKeys) {
      if ((recordings[k] ?? '').isEmpty) return false;
    }
    for (final w in customWords) {
      if ((recordings[w.awing] ?? '').isEmpty) return false;
    }
    return true;
  }

  /// How many words are still missing a recording.
  int get missingRecordingsCount {
    int missing = 0;
    for (final k in wordKeys) {
      if ((recordings[k] ?? '').isEmpty) missing++;
    }
    for (final w in customWords) {
      if ((recordings[w.awing] ?? '').isEmpty) missing++;
    }
    return missing;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'teacherEmail': teacherEmail,
        'teacherName': teacherName,
        'name': name,
        'description': description,
        'wordKeys': wordKeys,
        'customWords': customWords.map((w) => w.toJson()).toList(),
        'sharedWithEmails': sharedWithEmails,
        'recordings': recordings,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'locallyDismissed': locallyDismissed,
      };

  factory StudySet.fromJson(Map<String, dynamic> j) => StudySet(
        id: j['id'] as String,
        teacherEmail: j['teacherEmail'] as String,
        teacherName: j['teacherName'] as String? ?? '',
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
        wordKeys: (j['wordKeys'] as List?)?.cast<String>() ?? [],
        customWords: ((j['customWords'] as List?) ?? [])
            .map((w) => StudySetCustomWord.fromJson(
                  (w as Map).cast<String, dynamic>(),
                ))
            .toList(),
        sharedWithEmails:
            (j['sharedWithEmails'] as List?)?.cast<String>() ?? [],
        recordings:
            ((j['recordings'] as Map?) ?? const {}).cast<String, String>(),
        createdAt: j['createdAt'] as int?,
        updatedAt: j['updatedAt'] as int?,
        locallyDismissed: j['locallyDismissed'] as bool? ?? false,
      );

  String toJsonString() => jsonEncode(toJson());

  factory StudySet.fromJsonString(String s) =>
      StudySet.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

/// A word the teacher added that wasn't in the app's dictionary yet.
/// Also gets submitted through the Contribute > newWord pipeline for
/// developer approval → app-wide inclusion.
class StudySetCustomWord {
  final String awing;
  final String english;
  final String category; // matches vocabulary categories in awing_vocabulary.dart
  final int difficulty; // 1=beginner, 2=medium, 3=expert

  const StudySetCustomWord({
    required this.awing,
    required this.english,
    this.category = 'other',
    this.difficulty = 1,
  });

  Map<String, dynamic> toJson() => {
        'awing': awing,
        'english': english,
        'category': category,
        'difficulty': difficulty,
      };

  factory StudySetCustomWord.fromJson(Map<String, dynamic> j) =>
      StudySetCustomWord(
        awing: j['awing'] as String,
        english: j['english'] as String,
        category: j['category'] as String? ?? 'other',
        difficulty: (j['difficulty'] as int?) ?? 1,
      );
}
