// daily_suggestion_service.dart
// ---------------------------------------------------------------
// v1.15.0 — On-device, rule-based "AI" that picks Awing words to
// suggest to the learner each day and schedules a local
// notification reminding them.
//
// v1.17.4+ refactor (Session 60+):
//   - PER-PROFILE state. Picks, seen-words list, and learned-count
//     are scoped by AuthService profile ID, so two kids on the same
//     account (and the same device) each get their own daily words.
//   - STRICT NO-REPEAT. Once a word is in the profile's seen set,
//     it never returns until the profile resets history OR the pool
//     is exhausted (then we re-roll).
//   - OPEN-GATED COUNTER. Picks no longer count as "seen" until the
//     profile actually opens the daily-words screen
//     (recordViewed()). Then the wordsLearnedCount() returns the
//     size of the seen set — matches the games' coverage tracker
//     pattern from Session 113.
//   - Notification settings (enable/time) remain DEVICE-GLOBAL —
//     one daily reminder per device, not per profile.
//
// Scoring inputs (unchanged):
//   1. CURRENT LEVEL, 2. SEASON, 3. TIME OF DAY, 4. NOT-SEEN BIAS,
//   5. WEEKLY CATEGORY ROTATION, 6. AI semantic boost when
//   embeddings blob is loaded.
//
// Persistence (per profile, keys built via _profileKey()):
//   - `daily_seen_words__<profileId>` — list of (awing|english)
//     keys this profile has actually VIEWED (not just been picked).
//   - `daily_seen_sentences__<profileId>` / `..._conversations__...`
//   - `daily_last_suggestion_words__<profileId>` — today's picks +
//     pick date (so re-opening the screen on the same day shows the
//     same words rather than re-rolling).
//   - `daily_last_suggestion_sentences__...` / `..._conversations...`
//
// Device-global (no profile suffix):
//   - `daily_notification_enabled` — bool
//   - `daily_notification_hour` — 0-23
//   - `daily_notification_minute` — 0-59
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
  // ===== Per-profile storage key BASES (profileId is appended via
  // _profileKey()). Old non-scoped keys preserved at end for one-time
  // migration in pickTodayItems().
  static const _kSeenWordsBase = 'daily_seen_words';
  static const _kSeenSentencesBase = 'daily_seen_sentences';
  static const _kSeenConversationsBase = 'daily_seen_conversations';

  static const _kLastSuggestionWordsBase = 'daily_last_suggestion_words';
  static const _kLastSuggestionSentencesBase =
      'daily_last_suggestion_sentences';
  static const _kLastSuggestionConversationsBase =
      'daily_last_suggestion_conversations';

  // ===== Device-global keys (one notification setting per device).
  static const _kEnabled = 'daily_notification_enabled';
  static const _kHour = 'daily_notification_hour';
  static const _kMinute = 'daily_notification_minute';
  // v1.22.0 (Session 66) — engagement reminders.
  static const _kEveningEnabled = 'evening_notification_enabled';
  static const _kEveningHour = 'evening_notification_hour';
  static const _kEveningMinute = 'evening_notification_minute';
  static const _kWeeklyShareEnabled = 'weekly_share_enabled';
  static const _kWeeklyShareWeekday = 'weekly_share_weekday';
  static const _kWeeklyShareHour = 'weekly_share_hour';
  static const _kWeeklyShareMinute = 'weekly_share_minute';
  // Sentinel key that tells us whether the "on by default" flip has
  // already run for this install. Without it, users who explicitly
  // OPTED OUT before v1.22.0 would get flipped back on by the new
  // default = true logic. See isEnabled() for the migration guard.
  static const _kEnabledDefaultsApplied = 'reminders_defaults_v122_applied';

  /// Default profile id used when caller does not pass one (e.g. the
  /// notification scheduler runs outside any profile context). Keeps the
  /// pre-refactor data accessible until the first opened-with-profile
  /// run migrates it.
  static const String defaultProfileId = '_default';

  /// Default time for daily notification (8:00 AM local).
  static const int defaultHour = 8;
  static const int defaultMinute = 0;

  /// How many items to pick per day. v1.16.0+: bumped 3 → 10 per Dr. Sama.
  static const int picksPerDay = 10;

  /// Build a profile-scoped SharedPreferences key.
  /// Format: `<base>__<profileId>` — double underscore avoids collisions
  /// with any underscored content type names.
  static String _profileKey(String base, String profileId) =>
      '${base}__$profileId';

  static String _seenKeyFor(DailyContentType t, String profileId) {
    switch (t) {
      case DailyContentType.words:
        return _profileKey(_kSeenWordsBase, profileId);
      case DailyContentType.sentences:
        return _profileKey(_kSeenSentencesBase, profileId);
      case DailyContentType.conversations:
        return _profileKey(_kSeenConversationsBase, profileId);
    }
  }

  static String _lastSuggestionKeyFor(
      DailyContentType t, String profileId) {
    switch (t) {
      case DailyContentType.words:
        return _profileKey(_kLastSuggestionWordsBase, profileId);
      case DailyContentType.sentences:
        return _profileKey(_kLastSuggestionSentencesBase, profileId);
      case DailyContentType.conversations:
        return _profileKey(_kLastSuggestionConversationsBase, profileId);
    }
  }

  /// One-time migration: copy data from the OLD non-profile-scoped keys
  /// into the given profile's scope, then delete the old keys. Only
  /// runs if the profile-scoped key has no data yet AND the old key has
  /// data. Safe to call multiple times — becomes a no-op after migration.
  static Future<void> _maybeMigrateLegacyKeys(
      SharedPreferences prefs, DailyContentType t, String profileId) async {
    // Old "seen" key
    final newSeenKey = _seenKeyFor(t, profileId);
    if (!prefs.containsKey(newSeenKey)) {
      // Pick the legacy key matching this content type
      String? legacySeen;
      switch (t) {
        case DailyContentType.words:
          legacySeen = _kSeenWordsBase; break;
        case DailyContentType.sentences:
          legacySeen = _kSeenSentencesBase; break;
        case DailyContentType.conversations:
          legacySeen = _kSeenConversationsBase; break;
      }
      if (prefs.containsKey(legacySeen)) {
        final legacy = prefs.getStringList(legacySeen) ?? const [];
        if (legacy.isNotEmpty) {
          await prefs.setStringList(newSeenKey, legacy);
        }
        // Only delete legacy if migrating into the FIRST profile that
        // ever runs — a fresh second profile shouldn't inherit the
        // first profile's data. To stay safe we keep the legacy key
        // around; new profiles start empty.
      }
    }
    // Old "last suggestion" key — same deal
    final newLastKey = _lastSuggestionKeyFor(t, profileId);
    if (!prefs.containsKey(newLastKey)) {
      String? legacyLast;
      switch (t) {
        case DailyContentType.words:
          legacyLast = _kLastSuggestionWordsBase; break;
        case DailyContentType.sentences:
          legacyLast = _kLastSuggestionSentencesBase; break;
        case DailyContentType.conversations:
          legacyLast = _kLastSuggestionConversationsBase; break;
      }
      if (prefs.containsKey(legacyLast)) {
        final legacy = prefs.getString(legacyLast);
        if (legacy != null && legacy.isNotEmpty) {
          await prefs.setString(newLastKey, legacy);
        }
      }
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
    String profileId = defaultProfileId,
    DateTime? now,
  }) =>
      pickTodayItems(
        learnerLevel: learnerLevel,
        contentType: DailyContentType.words,
        profileId: profileId,
        now: now,
      );

  /// Pick today's 10 items for the given content type AND profile.
  /// Deterministic for a given (date, learnerLevel, seen-set, type,
  /// profileId).
  ///
  /// `profileId` MUST identify the currently-active profile (typically
  /// `AuthService.currentProfile?.id`). If callers omit it, picks fall
  /// back to a "default" profile bucket so the feature still works in
  /// edge cases (e.g. notification preview before sign-in).
  ///
  /// IMPORTANT — Session 60+ behavior change:
  /// This method NO LONGER auto-adds the picks to the profile's
  /// "seen" set. Callers MUST invoke [recordViewed] after the picks
  /// have actually been displayed to the user. This ensures the
  /// "words learned" counter only counts what the profile actually
  /// engaged with.
  ///
  /// Content types:
  /// - `words`: 10 vocab AwingWord entries
  /// - `sentences`: 10 short AwingPhrase entries (≤8 awing tokens)
  /// - `conversations`: 10 longer AwingPhrase entries (≥4 awing tokens)
  static Future<List<DailyWord>> pickTodayItems({
    required String learnerLevel,
    required DailyContentType contentType,
    String profileId = defaultProfileId,
    DateTime? now,
  }) async {
    final clock = now ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();

    // Migrate legacy (pre-refactor) non-scoped data into this profile
    // on first access. Idempotent.
    await _maybeMigrateLegacyKeys(prefs, contentType, profileId);

    final lastKey = _lastSuggestionKeyFor(contentType, profileId);
    final seenKey = _seenKeyFor(contentType, profileId);

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

    // STRICT NO-REPEAT: if there are enough unseen candidates to fill a
    // full day's pick, exclude already-seen words from the pool entirely.
    // Only when the profile has nearly exhausted the level's vocabulary
    // do we fall back to allowing repeats (the existing -3 penalty
    // applies in that case).
    if (seen.isNotEmpty) {
      final unseen = pool
          .where((c) => !seen.contains('${c.awing}|${c.english}'))
          .toList();
      if (unseen.length >= picksPerDay) {
        pool
          ..clear()
          ..addAll(unseen);
      }
      // else: too few unseen — keep full pool, let scoring penalize seen
    }

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

    // NOTE: we deliberately do NOT mutate the seen-set here. The
    // profile has only had words PICKED — not necessarily seen.
    // `recordViewed()` is the explicit gate for that, called by the
    // UI after the user actually opens the daily-words screen.
    //
    // We DO cache today's picks so re-opening the screen the same day
    // shows the same picks (rather than re-rolling and showing
    // different words to a confused kid).
    await prefs.setString(
      lastKey,
      jsonEncode({
        'date': '${clock.year}-${clock.month}-${clock.day}',
        'picks': picked.map((p) => p.toJson()).toList(),
      }),
    );

    return picked;
  }

  /// Record that the given profile has actually OPENED the daily-words
  /// screen and seen these picks. This is what increments the
  /// "words learned" counter — picking alone does not.
  ///
  /// Idempotent: re-calling with the same picks is a no-op.
  static Future<void> recordViewed({
    required String profileId,
    required DailyContentType contentType,
    required List<DailyWord> picks,
  }) async {
    if (picks.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await _maybeMigrateLegacyKeys(prefs, contentType, profileId);
    final seenKey = _seenKeyFor(contentType, profileId);
    final existing = (prefs.getStringList(seenKey) ?? const []).toSet();
    final before = existing.length;
    for (final p in picks) {
      existing.add('${p.awing}|${p.english}');
    }
    if (existing.length == before) return; // nothing new
    await prefs.setStringList(seenKey, existing.toList());
  }

  /// How many items of the given content type this profile has VIEWED
  /// across all days. Mirrors the games' seen-words coverage tracker
  /// from Session 113.
  static Future<int> wordsLearnedCount({
    required String profileId,
    DailyContentType contentType = DailyContentType.words,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _maybeMigrateLegacyKeys(prefs, contentType, profileId);
    final seenKey = _seenKeyFor(contentType, profileId);
    return (prefs.getStringList(seenKey) ?? const []).length;
  }

  /// Get today's persisted picks for re-display without re-scoring.
  static Future<List<DailyWord>> getCachedTodayPicks({
    String profileId = defaultProfileId,
    DailyContentType contentType = DailyContentType.words,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _maybeMigrateLegacyKeys(prefs, contentType, profileId);
    final raw = prefs.getString(_lastSuggestionKeyFor(contentType, profileId));
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

  /// Reset the seen-words history for the given content type AND profile.
  /// Only clears the calling profile's state — other profiles on the
  /// same account/device keep theirs.
  static Future<void> resetSeenWords({
    required String profileId,
    DailyContentType contentType = DailyContentType.words,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seenKeyFor(contentType, profileId));
    await prefs.remove(_lastSuggestionKeyFor(contentType, profileId));
  }

  /// Settings: notification enabled?
  ///
  /// v1.22.0 (Session 66): default flipped from `false` → `true` for
  /// new installs so users get engagement reminders out of the box
  /// (the audit found users were "not getting notifications" mostly
  /// because they never toggled the setting on). Migration is
  /// guarded by `_kEnabledDefaultsApplied` so pre-1.22 installs that
  /// explicitly opted out don't get their choice overridden.
  /// v1.22.1 (Session 67): notifications are ENFORCED. Always returns
  /// true regardless of stored pref. Setter is a no-op. UI must not
  /// expose an enable/disable toggle. The only way to silence Awing
  /// notifications is at the OS Settings level (per-app notification
  /// permission), which we can't override — but by removing the
  /// in-app toggle we stop users from accidentally opting themselves
  /// out and then complaining "notifications don't work."
  static Future<bool> isEnabled() async => true;

  /// Idempotent one-time migration: sets the three reminder-enabled
  /// keys to `true` ONLY if they've never been touched, guarded by a
  /// sentinel so users who explicitly opted out on an older build
  /// keep their opt-out choice.
  static Future<void> _applyRemindersDefaultsOnce(
      SharedPreferences prefs) async {
    if (prefs.getBool(_kEnabledDefaultsApplied) == true) return;
    // Only initialize keys that have NEVER been set. If a user
    // previously toggled a value (even to false), preserve it.
    if (!prefs.containsKey(_kEnabled)) {
      await prefs.setBool(_kEnabled, true);
    }
    if (!prefs.containsKey(_kEveningEnabled)) {
      await prefs.setBool(_kEveningEnabled, true);
    }
    if (!prefs.containsKey(_kWeeklyShareEnabled)) {
      await prefs.setBool(_kWeeklyShareEnabled, true);
    }
    await prefs.setBool(_kEnabledDefaultsApplied, true);
  }

  /// v1.22.1 (Session 67): no-op. Notifications are enforced — see
  /// isEnabled(). Signature kept so old callers compile.
  static Future<void> setEnabled(bool v) async {/* enforced */}

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

  // ─── v1.22.0 (Session 66) engagement reminders ───

  /// Default evening WOD reminder time (7:00 PM local).
  static const int defaultEveningHour = 19;
  static const int defaultEveningMinute = 0;

  /// Default weekly-share reminder (Saturday 10 AM local).
  /// DateTime.weekday: Mon=1..Sun=7.
  static const int defaultWeeklyShareWeekday = 6; // Saturday
  static const int defaultWeeklyShareHour = 10;
  static const int defaultWeeklyShareMinute = 0;

  // v1.22.1 (Session 67): enforced — see isEnabled().
  static Future<bool> eveningEnabled() async => true;
  static Future<void> setEveningEnabled(bool v) async {/* enforced */}

  static Future<int> eveningHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kEveningHour) ?? defaultEveningHour;
  }

  static Future<int> eveningMinute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kEveningMinute) ?? defaultEveningMinute;
  }

  static Future<void> setEveningTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kEveningHour, hour);
    await prefs.setInt(_kEveningMinute, minute);
  }

  // v1.22.1 (Session 67): enforced — see isEnabled().
  static Future<bool> weeklyShareEnabled() async => true;
  static Future<void> setWeeklyShareEnabled(bool v) async {/* enforced */}

  static Future<int> weeklyShareWeekday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kWeeklyShareWeekday) ?? defaultWeeklyShareWeekday;
  }

  static Future<int> weeklyShareHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kWeeklyShareHour) ?? defaultWeeklyShareHour;
  }

  static Future<int> weeklyShareMinute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kWeeklyShareMinute) ?? defaultWeeklyShareMinute;
  }

  static Future<void> setWeeklyShareTime(
      int weekday, int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kWeeklyShareWeekday, weekday);
    await prefs.setInt(_kWeeklyShareHour, hour);
    await prefs.setInt(_kWeeklyShareMinute, minute);
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
