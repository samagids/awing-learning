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
import 'package:awing_ai_learning/services/vocab_embeddings.dart';

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

/// What kind of daily content to suggest. Each mode has its own
/// independent "seen" set so a kid learning sentences in Medium doesn't
/// affect the Beginner words counter.
enum DailyContentType { words, sentences, conversations }

class DailySuggestionService {
  static const _kSeenWordsKey = 'daily_seen_words';
  static const _kSeenSentencesKey = 'daily_seen_sentences';
  static const _kSeenConversationsKey = 'daily_seen_conversations';

  static const _kLastSuggestionWordsKey = 'daily_last_suggestion_words';
  static const _kLastSuggestionSentencesKey =
      'daily_last_suggestion_sentences';
  static const _kLastSuggestionConversationsKey =
      'daily_last_suggestion_conversations';

  // Old keys (back-compat with v1.15.0 single-content version)
  static const _kSeenWords = 'daily_seen_words';
  static const _kLastSuggestion = 'daily_last_suggestion';

  static const _kEnabled = 'daily_notification_enabled';
  static const _kHour = 'daily_notification_hour';
  static const _kMinute = 'daily_notification_minute';

  /// Default time for daily notification (8:00 AM local).
  static const int defaultHour = 8;
  static const int defaultMinute = 0;

  /// How many items to pick per day. v1.16.0+: bumped 3 → 10 per Dr. Sama.
  static const int picksPerDay = 10;

  static String _seenKeyFor(DailyContentType t) {
    switch (t) {
      case DailyContentType.words: return _kSeenWordsKey;
      case DailyContentType.sentences: return _kSeenSentencesKey;
      case DailyContentType.conversations: return _kSeenConversationsKey;
    }
  }
  static String _lastSuggestionKeyFor(DailyContentType t) {
    switch (t) {
      case DailyContentType.words: return _kLastSuggestionWordsKey;
      case DailyContentType.sentences: return _kLastSuggestionSentencesKey;
      case DailyContentType.conversations:
        return _kLastSuggestionConversationsKey;
    }
  }

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

  /// Backwards-compatible alias for the old beginner-only API.
  /// New callers should use [pickTodayItems] with an explicit type.
  static Future<List<DailyWord>> pickToday({
    required String learnerLevel,
    DateTime? now,
  }) =>
      pickTodayItems(
        learnerLevel: learnerLevel,
        contentType: DailyContentType.words,
        now: now,
      );

  /// Pick today's 10 items for the given content type.
  /// Deterministic for a given (date, learnerLevel, seen-set, type).
  ///
  /// - `words`: 10 vocab AwingWord entries
  /// - `sentences`: 10 short AwingPhrase entries (≤8 awing tokens)
  /// - `conversations`: 10 longer AwingPhrase entries (≥4 awing tokens)
  static Future<List<DailyWord>> pickTodayItems({
    required String learnerLevel,
    required DailyContentType contentType,
    DateTime? now,
  }) async {
    final clock = now ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final lastKey = _lastSuggestionKeyFor(contentType);
    final seenKey = _seenKeyFor(contentType);

    // Check if we already picked today
    final lastRaw = prefs.getString(lastKey);
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

    // Build pool depending on content type.
    final maxDifficulty = _levelToMaxDifficulty(learnerLevel);
    final imageSvc = ImageService.instance;
    final pool = <_PickCandidate>[];

    if (contentType == DailyContentType.words) {
      for (final w in allVocabulary) {
        if (w.difficulty > maxDifficulty) continue;
        if (w.awing.isEmpty || w.english.isEmpty) continue;
        if (!imageSvc.hasImageSync(w.awing, w.english)) continue;
        pool.add(_PickCandidate(
          awing: w.awing, english: w.english,
          category: w.category, difficulty: w.difficulty,
        ));
      }
    } else {
      // Sentences / conversations come from awingPhrases.
      for (final p in awingPhrases) {
        if (p.awing.isEmpty || p.english.isEmpty) continue;
        final tokenCount = p.awing.trim().split(RegExp(r'\s+')).length;
        if (contentType == DailyContentType.sentences) {
          // Medium: short to medium phrases (1-8 tokens)
          if (tokenCount > 8) continue;
        } else {
          // Expert conversations: longer constructions (4+ tokens)
          if (tokenCount < 4) continue;
        }
        pool.add(_PickCandidate(
          awing: p.awing, english: p.english,
          category: p.category, difficulty: 1,
        ));
      }
    }

    if (pool.isEmpty) return [];

    final seenJson = prefs.getStringList(seenKey) ?? const [];
    final seen = seenJson.toSet();
    final season = seasonFor(clock);
    final tod = timeOfDayFor(clock);
    final weekdayCat = _weeklyRotation[clock.weekday] ?? '';

    // v1.16.0 — AI semantic boost. If the embeddings blob is loaded,
    // build a "recently-engaged" centroid from the last 5 seen words
    // and boost any candidate whose embedding lies near it.
    // This is the real ML-powered signal layered on top of the rules.
    List<double>? recentCentroid;
    final vocabEmbeds = VocabEmbeddings.instance;
    if (vocabEmbeds.isLoaded && seen.isNotEmpty) {
      final recent = seen.toList().reversed.take(5).toList();
      final accum = List<double>.filled(384, 0.0);
      int hit = 0;
      for (final key in recent) {
        final parts = key.split('|');
        if (parts.length != 2) continue;
        final vec = vocabEmbeds.getEmbedding(parts[0], parts[1]);
        if (vec == null) continue;
        for (int d = 0; d < 384; d++) {
          accum[d] += vec[d];
        }
        hit++;
      }
      if (hit > 0) {
        for (int d = 0; d < 384; d++) {
          accum[d] /= hit;
        }
        // Re-normalize so cosine math stays clean
        double n = 0.0;
        for (final v in accum) { n += v * v; }
        n = n > 1e-9 ? n : 1.0;
        final norm = n;
        for (int d = 0; d < 384; d++) {
          accum[d] /= norm;
        }
        recentCentroid = accum;
      }
    }

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
        score -= 3;
      }

      // AI semantic similarity boost (up to +6)
      if (recentCentroid != null) {
        final candVec = vocabEmbeds.getEmbedding(w.awing, w.english);
        if (candVec != null) {
          double dot = 0.0;
          for (int d = 0; d < 384; d++) {
            dot += recentCentroid[d] * candVec[d];
          }
          final boost = ((dot + 1.0) * 3.0).round();
          if (boost > 0) {
            score += boost;
            if (dot > 0.5) reasons.add('AI ★ semantic match');
          }
        }
      }

      // Pseudo-random tie-breaker
      final seed = clock.day * 31 + clock.month * 257 + w.awing.hashCode;
      score += (seed & 0x3);

      scored.add(_ScoredWord(w, score, reasons.join(', ')));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));

    // Pick `picksPerDay` (10). Variety for the first half.
    final picked = <DailyWord>[];
    final usedCategories = <String>{};
    for (final s in scored) {
      if (picked.length >= picksPerDay) break;
      final wantVariety = picked.length < (picksPerDay ~/ 2);
      if (wantVariety && usedCategories.contains(s.word.category)) continue;
      picked.add(DailyWord(
        awing: s.word.awing,
        english: s.word.english,
        category: s.word.category,
        difficulty: s.word.difficulty,
        reason: s.reason.isEmpty ? 'good fit for today' : s.reason,
      ));
      usedCategories.add(s.word.category);
    }

    final newSeen = {
      ...seen,
      for (final p in picked) '${p.awing}|${p.english}',
    };
    await prefs.setStringList(seenKey, newSeen.toList());
    await prefs.setString(
      lastKey,
      jsonEncode({
        'date': '${clock.year}-${clock.month}-${clock.day}',
        'picks': picked.map((p) => p.toJson()).toList(),
      }),
    );

    return picked;
  }

  /// Get yesterday's persisted picks for re-display without re-scoring.
  static Future<List<DailyWord>> getCachedTodayPicks({
    DailyContentType contentType = DailyContentType.words,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastSuggestionKeyFor(contentType));
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

  /// Reset the seen-words history for the given content type.
  static Future<void> resetSeenWords({
    DailyContentType contentType = DailyContentType.words,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seenKeyFor(contentType));
    await prefs.remove(_lastSuggestionKeyFor(contentType));
  }

  /// Settings: notification enabled?
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabled) ?? false;
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

class _PickCandidate {
  final String awing;
  final String english;
  final String category;
  final int difficulty;
  const _PickCandidate({
    required this.awing,
    required this.english,
    required this.category,
    required this.difficulty,
  });
}

class _ScoredWord {
  final _PickCandidate word;
  final int score;
  final String reason;
  _ScoredWord(this.word, this.score, this.reason);
}
