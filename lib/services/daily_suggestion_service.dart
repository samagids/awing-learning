// daily_suggestion_service.dart
// ---------------------------------------------------------------
// v1.15.0 — On-device, rule-based "AI" that picks 3 Awing words to
// suggest to the learner each day and schedules a local
// notification reminding them.
//
// No actual machine-learning model is shipped — the rules below are
// hand-crafted heuristics tuned for kids learning a Cameroon
// Grassfields Bantu language. The result is deterministic and
// debuggable; nothing leaves the device.
//
// Scoring inputs:
//   1. CURRENT LEVEL — picks only from words the learner can see in
//      their current mode (Beginner / Medium / Expert). So a kid in
//      Beginner mode never gets suggested an Expert-only word.
//   2. SEASON — Awing region (Cameroon NW) has two seasons:
//        - Dry: November-March (cool, harmattan winds)
//        - Wet/rainy: April-October (peak May-September)
//      Words tagged with seasonal categories get +season boost.
//   3. TIME OF DAY — different categories suit different times:
//        Morning (5-11): greetings, body parts, food (breakfast)
//        Midday  (11-14): food, things, meals
//        Afternoon (14-18): actions, family, school
//        Evening (18-22): family, animals, home
//   4. NOT SEEN BEFORE — words already shown to this learner get a
//      heavy penalty so daily suggestions surface variety.
//   5. CATEGORY ROTATION — within a week, try to cover different
//      categories so the kid hears greetings on Monday, food on
//      Tuesday, etc.
//
// Persistence:
//   - SharedPreferences key `daily_seen_words` — list of base keys
//     already suggested to this learner.
//   - SharedPreferences key `daily_last_suggestion` — yesterday's 3
//     picks + the date they were shown (to avoid re-running scoring
//     if the user re-opens the app on the same day).
//   - SharedPreferences key `daily_notification_enabled` — bool.
//   - SharedPreferences key `daily_notification_hour` — 0-23.
//   - SharedPreferences key `daily_notification_minute` — 0-59.
// ---------------------------------------------------------------

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/services/image_service.dart';

class DailyWord {
  final String awing;
  final String english;
  final String category;
  final int difficulty;
  final String reason; // human-readable explanation for debug / UI tooltip

  DailyWord({
    required this.awing,
    required this.english,
    required this.category,
    required this.difficulty,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'awing': awing,
        'english': english,
        'category': category,
        'difficulty': difficulty,
        'reason': reason,
      };

  factory DailyWord.fromJson(Map<String, dynamic> j) => DailyWord(
        awing: j['awing'] as String? ?? '',
        english: j['english'] as String? ?? '',
        category: j['category'] as String? ?? '',
        difficulty: (j['difficulty'] as num?)?.toInt() ?? 1,
        reason: j['reason'] as String? ?? '',
      );
}

class DailySuggestionService {
  static const _kSeenWords = 'daily_seen_words';
  static const _kLastSuggestion = 'daily_last_suggestion';
  static const _kEnabled = 'daily_notification_enabled';
  static const _kHour = 'daily_notification_hour';
  static const _kMinute = 'daily_notification_minute';

  /// Default time for daily notification (8:00 AM local).
  static const int defaultHour = 8;
  static const int defaultMinute = 0;

  /// Category → which time-of-day buckets this category fits.
  static const _categoryTimeAffinity = <String, Set<String>>{
    'family': {'morning', 'afternoon', 'evening'},
    'body': {'morning'},
    'food': {'morning', 'midday'},
    'things': {'midday', 'afternoon'},
    'actions': {'afternoon'},
    'animals': {'morning', 'evening'},
    'nature': {'morning', 'afternoon'},
    'descriptive': {'midday', 'afternoon'},
    'numbers': {'midday'},
    'pronouns': {'morning', 'afternoon'},
    'classroom': {'morning', 'midday', 'afternoon'},
    'daily': {'morning', 'afternoon', 'evening'},
    'question': {'morning', 'afternoon'},
    'time': {'morning', 'evening'},
    'tones': {'midday'},
  };

  /// Category → which seasons this category fits.
  /// Cameroon NW: dry Nov-Mar, wet Apr-Oct.
  static const _categorySeasonAffinity = <String, Set<String>>{
    // Wet season topics: planting, growing, farming
    'food': {'wet'},
    'nature': {'wet'},
    'animals': {'wet', 'dry'},
    // Dry season topics: indoor activities, festivals, family gatherings
    'family': {'dry'},
    'classroom': {'dry'}, // dry season aligns with school year peak
    // Neutral
    'body': {'wet', 'dry'},
    'things': {'wet', 'dry'},
    'actions': {'wet', 'dry'},
    'descriptive': {'wet', 'dry'},
    'numbers': {'wet', 'dry'},
    'pronouns': {'wet', 'dry'},
    'daily': {'wet', 'dry'},
    'question': {'wet', 'dry'},
    'time': {'wet', 'dry'},
    'tones': {'wet', 'dry'},
  };

  /// Day-of-week → preferred category for that day (rotation).
  /// Mon = greetings (phrases/pronouns), Tue = food, Wed = body,
  /// Thu = animals/nature, Fri = family, Sat = actions, Sun = numbers/time
  static const _weeklyRotation = <int, String>{
    DateTime.monday: 'pronouns',
    DateTime.tuesday: 'food',
    DateTime.wednesday: 'body',
    DateTime.thursday: 'nature',
    DateTime.friday: 'family',
    DateTime.saturday: 'actions',
    DateTime.sunday: 'numbers',
  };

  /// Return the season label for `when` ('wet' or 'dry').
  static String seasonFor(DateTime when) {
    final m = when.month;
    // Wet: April-October; Dry: November-March
    return (m >= 4 && m <= 10) ? 'wet' : 'dry';
  }

  /// Return the time-of-day label for `when`.
  static String timeOfDayFor(DateTime when) {
    final h = when.hour;
    if (h >= 5 && h < 11) return 'morning';
    if (h >= 11 && h < 14) return 'midday';
    if (h >= 14 && h < 18) return 'afternoon';
    return 'evening';
  }

  /// Pick 3 daily words. Deterministic for a given (date, learnerLevel,
  /// seen-set) combination so the same kid sees the same 3 words if they
  /// re-open the app within a day.
  ///
  /// [learnerLevel] is one of 'beginner', 'medium', 'expert'.
  /// [now] defaults to DateTime.now(); pass-in for tests.
  static Future<List<DailyWord>> pickToday({
    required String learnerLevel,
    DateTime? now,
  }) async {
    final clock = now ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();

    // Check if we already picked today
    final lastRaw = prefs.getString(_kLastSuggestion);
    if (lastRaw != null) {
      try {
        final j = jsonDecode(lastRaw) as Map<String, dynamic>;
        final dateStr = j['date'] as String?;
        final today = '${clock.year}-${clock.month}-${clock.day}';
        if (dateStr == today) {
          final picksJson = j['picks'] as List?;
          if (picksJson != null && picksJson.isNotEmpty) {
            return picksJson
                .map((p) => DailyWord.fromJson(p as Map<String, dynamic>))
                .toList();
          }
        }
      } catch (_) {/* fall through to re-pick */}
    }

    // Build pool: all words at or below learner's level, with images.
    final maxDifficulty = _levelToMaxDifficulty(learnerLevel);
    final imageSvc = ImageService.instance;
    final pool = allVocabulary
        .where((w) =>
            w.difficulty <= maxDifficulty &&
            w.awing.isNotEmpty &&
            w.english.isNotEmpty &&
            imageSvc.hasImageSync(w.awing, w.english))
        .toList();

    if (pool.isEmpty) return [];

    final seenJson = prefs.getStringList(_kSeenWords) ?? const [];
    final seen = seenJson.toSet();
    final season = seasonFor(clock);
    final tod = timeOfDayFor(clock);
    final weekdayCat = _weeklyRotation[clock.weekday] ?? '';

    // Score every candidate, then pick top 3 distinct by category to vary.
    final scored = <_ScoredWord>[];
    for (final w in pool) {
      var score = 0;
      var reasons = <String>[];

      // Time-of-day match (+3)
      final todSet = _categoryTimeAffinity[w.category];
      if (todSet != null && todSet.contains(tod)) {
        score += 3;
        reasons.add('$tod time');
      }

      // Season match (+2)
      final seasonSet = _categorySeasonAffinity[w.category];
      if (seasonSet != null && seasonSet.contains(season)) {
        score += 2;
        reasons.add('$season season');
      }

      // Weekly rotation match (+4)
      if (w.category == weekdayCat) {
        score += 4;
        reasons.add('${_weekdayName(clock.weekday)} word');
      }

      // Not yet seen (+5) — strongly prefer new words
      final key = '${w.awing}|${w.english}';
      if (!seen.contains(key)) {
        score += 5;
        reasons.add('new for you');
      } else {
        score -= 3; // penalty for already-seen
      }

      // Pseudo-random tie-breaker seeded by date + word so the same
      // day always picks the same word from a tied set.
      final seed = clock.day * 31 + clock.month * 257 + w.awing.hashCode;
      score += (seed & 0x3); // 0..3 noise

      scored.add(_ScoredWord(w, score, reasons.join(', ')));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));

    // Pick 3 with distinct categories where possible
    final picked = <DailyWord>[];
    final usedCategories = <String>{};
    for (final s in scored) {
      if (picked.length >= 3) break;
      if (usedCategories.contains(s.word.category) && picked.length < 2) {
        // Allow same category if we're really short on candidates, but
        // prefer variety for the first two picks.
        continue;
      }
      picked.add(DailyWord(
        awing: s.word.awing,
        english: s.word.english,
        category: s.word.category,
        difficulty: s.word.difficulty,
        reason: s.reason.isEmpty ? 'good fit for today' : s.reason,
      ));
      usedCategories.add(s.word.category);
    }

    // Persist today's picks and the new "seen" set.
    final newSeen = {...seen, for (final p in picked) '${p.awing}|${p.english}'};
    await prefs.setStringList(_kSeenWords, newSeen.toList());
    await prefs.setString(
        _kLastSuggestion,
        jsonEncode({
          'date': '${clock.year}-${clock.month}-${clock.day}',
          'picks': picked.map((p) => p.toJson()).toList(),
        }));

    return picked;
  }

  /// Get yesterday's persisted picks for re-display without re-scoring.
  /// Returns empty list if nothing saved or not today.
  static Future<List<DailyWord>> getCachedTodayPicks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLastSuggestion);
    if (raw == null) return [];
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final dateStr = j['date'] as String?;
      final now = DateTime.now();
      final today = '${now.year}-${now.month}-${now.day}';
      if (dateStr != today) return [];
      final picksJson = j['picks'] as List?;
      if (picksJson == null) return [];
      return picksJson
          .map((p) => DailyWord.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Reset the seen-words history (e.g. for "show me everything again").
  static Future<void> resetSeenWords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSeenWords);
    await prefs.remove(_kLastSuggestion);
  }

  /// Settings: notification enabled?
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabled) ?? false; // off by default
  }

  static Future<void> setEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, v);
  }

  static Future<int> notificationHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kHour) ?? defaultHour;
  }

  static Future<int> notificationMinute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kMinute) ?? defaultMinute;
  }

  static Future<void> setNotificationTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kHour, hour);
    await prefs.setInt(_kMinute, minute);
  }

  // === Helpers ===

  static int _levelToMaxDifficulty(String level) {
    switch (level.toLowerCase()) {
      case 'beginner': return 1;
      case 'medium': return 2;
      case 'expert': return 3;
      default: return 1;
    }
  }

  static String _weekdayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (weekday < 1 || weekday > 7) return '';
    return names[weekday - 1];
  }
}

class _ScoredWord {
  final AwingWord word;
  final int score;
  final String reason;
  _ScoredWord(this.word, this.score, this.reason);
}
