import 'package:flutter/foundation.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';

/// A single translation match returned by the dictionary lookup.
class LookupResult {
  final String awing;
  final String english;
  final String category;
  final int difficulty;

  /// How this match was scored:
  ///   1.0    = exact match on the whole gloss
  ///   0.95   = exact match on Awing diacritic-stripped form
  ///   0.85   = token match (word appears as a token in the gloss)
  ///   0.7    = substring / contained match
  ///   0.5-0.6 = fuzzy match (Levenshtein <= 2)
  final double score;

  /// 'awing' or 'english' — which side of the entry the match hit.
  final String matchedField;

  const LookupResult({
    required this.awing,
    required this.english,
    required this.category,
    required this.difficulty,
    required this.score,
    required this.matchedField,
  });
}

/// Fully-offline dictionary lookup service. Backs the Beginner
/// "Word Translate" feature.
///
/// Search strategy — CASCADING TIERS. Once a tier hits, later tiers are
/// skipped so the result list stays clean:
///   T1. Exact match on the FULL English (or Awing) gloss
///        - Includes ';' / ',' -separated sense variants:
///          "hear; understand" indexes under BOTH "hear" AND "understand"
///   T2. Token match (query word appears AS A WORD in a longer gloss)
///        - Only fires when T1 empty
///   T3. Substring / contained match — partial word
///        - Only fires when T1 + T2 empty
///   T4. Fuzzy match (Levenshtein <= 2) for typos
///        - Only fires when T1 + T2 + T3 empty
///
/// This gives clean word-to-word translation for anything in the
/// dictionary, with graceful fallback for typos/partials.
///
/// Data cost: 0 KB. Runs entirely on the bundled vocabulary.
class DictionaryLookup {
  static final DictionaryLookup _instance = DictionaryLookup._internal();
  static DictionaryLookup get instance => _instance;
  DictionaryLookup._internal();

  bool _built = false;

  /// Full-gloss exact match index: normalized English → entries.
  final Map<String, List<AwingWord>> _englishFullIndex = {};

  /// Token index: each individual word in a gloss → entries.
  /// Used only when full-gloss match is empty.
  final Map<String, List<AwingWord>> _englishTokenIndex = {};

  /// Awing full-form + stripped-diacritic index.
  final Map<String, List<AwingWord>> _awingIndex = {};

  /// Flat list — used for substring fallback.
  final List<AwingWord> _all = [];

  void build() {
    if (_built) return;
    for (final w in allVocabulary) {
      _all.add(w);

      final englishNorm = _normEnglish(w.english);
      _englishFullIndex.putIfAbsent(englishNorm, () => []).add(w);
      // Sense variants: "hear; understand" -> "hear" AND "understand"
      for (final sense in _senseSplit(englishNorm)) {
        if (sense != englishNorm) {
          _englishFullIndex.putIfAbsent(sense, () => []).add(w);
        }
      }
      // Token index for fallback.
      for (final tok in _tokenizeEnglish(w.english)) {
        _englishTokenIndex.putIfAbsent(tok, () => []).add(w);
      }

      final awingRaw = w.awing.toLowerCase();
      _awingIndex.putIfAbsent(awingRaw, () => []).add(w);
      final awingStripped = _stripAwingDiacritics(w.awing);
      if (awingStripped != awingRaw) {
        _awingIndex.putIfAbsent(awingStripped, () => []).add(w);
      }
    }
    _built = true;
    debugPrint('DictionaryLookup: indexed ${_all.length} entries '
        '(${_englishFullIndex.length} full, '
        '${_englishTokenIndex.length} token, '
        '${_awingIndex.length} Awing)');
  }

  /// ENGLISH → matching Awing translations (cascading tiers).
  /// [strict] mode skips T2 (token match), T3 (substring), and T4
  /// (fuzzy) — returns only exact and stemmed-exact matches. Used in
  /// sentence gloss to avoid picking arbitrary long-gloss entries that
  /// happen to CONTAIN the query word as a token.
  List<LookupResult> lookupEnglish(String query, {int maxResults = 10, bool strict = false}) {
    build();
    final q = _normEnglish(query);
    if (q.isEmpty) return const [];

    final results = <LookupResult>[];
    final seen = <String>{};

    void addWord(AwingWord w, double score) {
      final key = '${w.awing}|${w.english}';
      if (seen.contains(key)) return;
      seen.add(key);
      results.add(LookupResult(
        awing: w.awing,
        english: w.english,
        category: w.category,
        difficulty: w.difficulty,
        score: score,
        matchedField: 'english',
      ));
    }

    List<LookupResult> _finish() {
      results.sort((a, b) => b.score.compareTo(a.score));
      if (results.length > maxResults) {
        return results.sublist(0, maxResults);
      }
      return results;
    }

    // T1 — Exact full-gloss match. User types "hand" -> get "hand".
    final exact = _englishFullIndex[q];
    if (exact != null && exact.isNotEmpty) {
      for (final w in exact) {
        addWord(w, 1.0);
      }
      return _finish();
    }

    // T1b — Exact full-gloss match on STEMMED form. Handles verb -ing/
    // -ed/-s and plural noun -s. "going" -> "go" (ghɛnɔ), "houses" ->
    // "house", "walked" -> "walk". Only fires if T1 missed AND the
    // stemmed form is DIFFERENT from the original.
    final stemmed = _englishStem(q);
    if (stemmed != null && stemmed != q) {
      final stemExact = _englishFullIndex[stemmed];
      if (stemExact != null && stemExact.isNotEmpty) {
        for (final w in stemExact) {
          addWord(w, 0.92);
        }
        return _finish();
      }
    }

    // T2 — Token match. User types "palm" -> get "palm (of hand)".
    // Skipped entirely in strict mode (used by sentence gloss).
    if (strict) return _finish();
    final tokenMatches = _englishTokenIndex[q];
    if (tokenMatches != null && tokenMatches.isNotEmpty) {
      final sorted = List.of(tokenMatches);
      sorted.sort((a, b) => a.english.length.compareTo(b.english.length));
      for (final w in sorted) {
        if (results.length >= maxResults) break;
        addWord(w, 0.85);
      }
      if (results.isNotEmpty) return _finish();
    }

    // T3 — Substring / contained match.
    if (q.length >= 3) {
      final queryTokens = q.split(RegExp(r'\s+'));
      for (final w in _all) {
        if (results.length >= maxResults) break;
        final norm = _normEnglish(w.english);
        for (final t in queryTokens) {
          if (t.length >= 3 && norm.contains(t)) {
            addWord(w, 0.7);
            break;
          }
        }
      }
      if (results.isNotEmpty) return _finish();
    }

    // T4 — Fuzzy match for single-word typos.
    if (q.split(' ').length == 1) {
      for (final entry in _englishFullIndex.entries) {
        if (results.length >= maxResults) break;
        final d = _levenshtein(q, entry.key);
        if (d > 0 && d <= 2 && (q.length - d).abs() < 4) {
          for (final w in entry.value) {
            addWord(w, 0.6 - (d * 0.1));
          }
        }
      }
    }

    return _finish();
  }

  /// AWING → matching English translations (cascading tiers).
  List<LookupResult> lookupAwing(String query, {int maxResults = 10}) {
    build();
    final qRaw = query.trim().toLowerCase();
    final qStripped = _stripAwingDiacritics(query);
    if (qRaw.isEmpty && qStripped.isEmpty) return const [];

    final results = <LookupResult>[];
    final seen = <String>{};

    void addWord(AwingWord w, double score) {
      final key = '${w.awing}|${w.english}';
      if (seen.contains(key)) return;
      seen.add(key);
      results.add(LookupResult(
        awing: w.awing,
        english: w.english,
        category: w.category,
        difficulty: w.difficulty,
        score: score,
        matchedField: 'awing',
      ));
    }

    List<LookupResult> _finish() {
      results.sort((a, b) => b.score.compareTo(a.score));
      if (results.length > maxResults) {
        return results.sublist(0, maxResults);
      }
      return results;
    }

    // T1 — Exact on raw form (all tone marks correct).
    final rawExact = _awingIndex[qRaw];
    if (rawExact != null && rawExact.isNotEmpty) {
      for (final w in rawExact) {
        addWord(w, 1.0);
      }
      return _finish();
    }

    // T2 — Exact on stripped form (user typed without tone marks).
    if (qStripped.isNotEmpty && qStripped != qRaw) {
      final strippedExact = _awingIndex[qStripped];
      if (strippedExact != null && strippedExact.isNotEmpty) {
        for (final w in strippedExact) {
          if (results.length >= maxResults) break;
          addWord(w, 0.95);
        }
        if (results.isNotEmpty) return _finish();
      }
    }

    // T3 — Substring on stripped form.
    if (qStripped.length >= 2) {
      for (final w in _all) {
        if (results.length >= maxResults) break;
        final stripped = _stripAwingDiacritics(w.awing);
        if (stripped.contains(qStripped)) {
          addWord(w, 0.7);
        }
      }
      if (results.isNotEmpty) return _finish();
    }

    // T4 — Fuzzy match on stripped form.
    if (qStripped.length >= 3) {
      for (final entry in _awingIndex.entries) {
        if (results.length >= maxResults) break;
        final d = _levenshtein(qStripped, entry.key);
        if (d > 0 && d <= 2 && (qStripped.length - d).abs() < 4) {
          for (final w in entry.value) {
            addWord(w, 0.6 - (d * 0.1));
          }
        }
      }
    }

    return _finish();
  }

  // ================= internals =================

  String _normEnglish(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[^\sa-z0-9;,]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Iterable<String> _tokenizeEnglish(String s) {
    // Split on whitespace AND on ';' / ',' so senses become tokens too.
    return _normEnglish(s)
        .split(RegExp(r'[\s;,]+'))
        .where((t) => t.length >= 2);
  }

  Iterable<String> _senseSplit(String normEnglish) sync* {
    for (final s in normEnglish.split(RegExp(r'[;,]'))) {
      final trimmed = s.trim();
      if (trimmed.isNotEmpty) yield trimmed;
    }
  }

  String _stripAwingDiacritics(String s) {
    final buf = StringBuffer();
    final lower = s.toLowerCase();
    for (int i = 0; i < lower.length; i++) {
      final c = lower[i];
      switch (c) {
        case 'á':
        case 'à':
        case 'â':
        case 'ǎ':
        case 'ā':
          buf.write('a');
          break;
        case 'é':
        case 'è':
        case 'ê':
        case 'ě':
        case 'ē':
        case 'ɛ':
          buf.write('e');
          break;
        case 'í':
        case 'ì':
        case 'î':
        case 'ǐ':
        case 'ī':
        case 'ɨ':
          buf.write('i');
          break;
        case 'ó':
        case 'ò':
        case 'ô':
        case 'ǒ':
        case 'ō':
        case 'ɔ':
          buf.write('o');
          break;
        case 'ú':
        case 'ù':
        case 'û':
        case 'ǔ':
        case 'ū':
          buf.write('u');
          break;
        case 'ə':
          buf.write('e');
          break;
        case 'ŋ':
          buf.write('ng');
          break;
        case "'":
        case '’':
        case '‘':
        case 'ʼ':
          break;
        default:
          final code = c.codeUnitAt(0);
          if (code >= 0x0300 && code <= 0x036F) {
            // combining diacritic — skip
          } else {
            buf.write(c);
          }
      }
    }
    return buf.toString();
  }

  /// Very small English stemmer:
  ///   -ing  -> strip (going -> go, running -> runn, then optional doubled cons drop)
  ///   -ies  -> -y (parties -> party)
  ///   -es   -> strip (churches -> church)
  ///   -ed   -> strip (walked -> walk)
  ///   -s    -> strip (dogs -> dog), only if length >= 4
  /// Returns null if no rule applied.
  /// English irregular verb + copula normalization. Handles the
  /// mismatch where English has multiple forms (has/have/had/having,
  /// is/am/are/was/were, does/did/done) but Awing typically has one
  /// word. Called BEFORE the regex-based -ing/-ed/-s rules so it wins.
  static const Map<String, String> _englishIrregulars = {
    // to have
    'has': 'have', 'had': 'have', 'having': 'have',
    // to be
    'is': 'be', 'am': 'be', 'are': 'be',
    'was': 'be', 'were': 'be',
    'been': 'be', 'being': 'be',
    // to do
    'does': 'do', 'did': 'do', 'done': 'do', 'doing': 'do',
    // to go
    'goes': 'go', 'went': 'go', 'gone': 'go', 'going': 'go',
    // to see
    'sees': 'see', 'saw': 'see', 'seen': 'see', 'seeing': 'see',
    // to say
    'says': 'say', 'said': 'say', 'saying': 'say',
    // to come
    'comes': 'come', 'came': 'come', 'coming': 'come',
    // to eat
    'eats': 'eat', 'ate': 'eat', 'eaten': 'eat', 'eating': 'eat',
    // to give
    'gives': 'give', 'gave': 'give', 'given': 'give', 'giving': 'give',
    // to make
    'makes': 'make', 'made': 'make', 'making': 'make',
    // to take
    'takes': 'take', 'took': 'take', 'taken': 'take', 'taking': 'take',
    // to know
    'knows': 'know', 'knew': 'know', 'known': 'know', 'knowing': 'know',
    // to get
    'gets': 'get', 'got': 'get', 'gotten': 'get', 'getting': 'get',
    // to think
    'thinks': 'think', 'thought': 'think', 'thinking': 'think',
    // pronouns (subject/object forms → base)
    'me': 'i', 'my': 'i', 'mine': 'i',
    'him': 'he', 'his': 'he',
    'her': 'she', 'hers': 'she',
    'us': 'we', 'our': 'we', 'ours': 'we',
    'them': 'they', 'their': 'they', 'theirs': 'they',
  };

  String? _englishStem(String w) {
    // Irregular-form lookup wins before regex rules.
    final irregular = _englishIrregulars[w];
    if (irregular != null) return irregular;
    if (w.length < 3) return null;
    // -ing (going -> go, running -> run) — drop -ing, then if the result
    // ends in a doubled consonant, drop one.
    if (w.endsWith('ing') && w.length >= 5) {
      String s = w.substring(0, w.length - 3);
      if (s.length >= 2) {
        final last = s[s.length - 1];
        final prev = s[s.length - 2];
        if (last == prev && 'bcdfghjklmnpqrstvwxz'.contains(last)) {
          s = s.substring(0, s.length - 1);
        }
      }
      // If original was 'go' + 'ing' the stem is 'go'.
      // If original was 'goe' + 'ing' after doubling drop is 'go'.
      return s;
    }
    // -ies -> -y (parties -> party)
    if (w.endsWith('ies') && w.length >= 5) {
      return '${w.substring(0, w.length - 3)}y';
    }
    // -ed (walked -> walk)
    if (w.endsWith('ed') && w.length >= 4) {
      return w.substring(0, w.length - 2);
    }
    // -es (churches -> church, dishes -> dish)
    if (w.endsWith('es') && w.length >= 4) {
      return w.substring(0, w.length - 2);
    }
    // -s (dogs -> dog) — only if it's clearly a plural, not a stem
    if (w.endsWith('s') && !w.endsWith('ss') && !w.endsWith('us') && w.length >= 4) {
      return w.substring(0, w.length - 1);
    }
    return null;
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final n = a.length;
    final m = b.length;
    List<int> prev = List<int>.filled(m + 1, 0);
    List<int> curr = List<int>.filled(m + 1, 0);
    for (int j = 0; j <= m; j++) {
      prev[j] = j;
    }
    for (int i = 1; i <= n; i++) {
      curr[0] = i;
      for (int j = 1; j <= m; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        curr[j] = [
          curr[j - 1] + 1,
          prev[j] + 1,
          prev[j - 1] + cost,
        ].reduce((v, e) => v < e ? v : e);
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[m];
  }
}
