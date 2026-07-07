import 'package:awing_ai_learning/services/dictionary_lookup.dart';

/// A single word in a sentence-level gloss.
class GlossToken {
  final String source;
  final String? translation;
  bool get inDictionary => translation != null;
  final double? score;
  final String? category;
  final String? awing;

  /// True for English grammar particles (the, a, an, of, to, and, ...)
  /// that were intentionally not looked up — they have no direct Awing
  /// equivalent and shouldn't count against coverage or render as chips.
  final bool isStopword;

  /// True if this token is pure punctuation (e.g. "." at sentence end).
  final bool isPunctuation;

  const GlossToken({
    required this.source,
    this.translation,
    this.score,
    this.category,
    this.awing,
    this.isStopword = false,
    this.isPunctuation = false,
  });
}

/// The complete gloss result for a sentence-level input.
class GlossResult {
  /// Per-word gloss in the same order as the input.
  final List<GlossToken> tokens;

  /// Convenience: the input sentence.
  final String source;

  /// Content tokens — excludes stopwords and pure-punctuation tokens
  /// so counts and coverage are honest.
  Iterable<GlossToken> get _contentTokens =>
      tokens.where((t) => !t.isStopword && !t.isPunctuation);

  /// Reconstructed word-by-word translation joined with spaces.
  /// - Punctuation is skipped.
  /// - Stopwords + proper nouns render as the SOURCE word (kept
  ///   in place so the sentence structure is preserved).
  /// - Content words with a translation → the Awing word.
  /// - Content words WITHOUT a translation → em-dash so gaps are
  ///   visible without introducing bogus tokens.
  String get wordByWord {
    final parts = <String>[];
    for (final t in tokens) {
      if (t.isPunctuation) continue;
      // Stopwords + proper nouns keep the source word in position.
      if (t.isStopword) {
        parts.add(t.source);
        continue;
      }
      // Real content words: translation or em-dash.
      parts.add((t.translation != null && t.translation!.isNotEmpty)
          ? t.translation!
          : '—');
    }
    return parts.join(' ');
  }

  /// Number of content tokens that were successfully looked up.
  int get matched => _contentTokens.where((t) => t.inDictionary).length;

  /// Total number of content tokens (used as coverage denominator).
  int get totalContent => _contentTokens.length;

  /// Fraction 0.0-1.0 of content tokens matched.
  double get coverage {
    final total = totalContent;
    if (total == 0) return 0;
    return matched / total;
  }

  const GlossResult({required this.tokens, required this.source});
}

/// Word-by-word gloss engine — the shared backbone for Medium
/// "Sentence Translate" and Expert "Grade My Translation".
///
/// Takes an English or Awing sentence, splits into words, looks up
/// each in the dictionary, and returns a per-word gloss so callers
/// can render inline colored feedback.
class WordGloss {
  static final WordGloss instance = WordGloss._();
  WordGloss._();

  /// English grammar particles that don't have direct Awing word-by-word
  /// equivalents. These are returned as tokens with no translation so
  /// they render as gray-neutral chips instead of matching some random
  /// dictionary entry that happens to contain them.
  ///
  /// NOT included (they DO have Awing equivalents): pronouns (I, he,
  /// she, they, we, you), possessives (my, your, our), copulas
  /// (is, am, are, was, were), and other content words.
  static const Set<String> _englishStopwords = {
    'the', 'a', 'an',
    'of', 'to', 'at', 'by', 'in', 'on', 'from', 'for', 'with',
    'and', 'or', 'but', 'so',
    'that', 'this', 'these', 'those',
  };

  /// English sentence → per-word Awing translations.
  GlossResult glossEnglish(String sentence) {
    final tokens = <GlossToken>[];
    final words = _splitWords(sentence);
    for (int idx = 0; idx < words.length; idx++) {
      final w = words[idx];
      if (RegExp(r'^[\s\p{P}]+\$', unicode: true).hasMatch(w)) {
        tokens.add(GlossToken(source: w, isPunctuation: true));
        continue;
      }
      // Stopwords render as-is (no dictionary lookup). The word stays
      // in the output so the sentence structure is preserved.
      if (_englishStopwords.contains(w.toLowerCase())) {
        tokens.add(GlossToken(
          source: w,
          translation: w, // keep source as-is in output
          isStopword: true,
        ));
        continue;
      }
      // Strict lookup — no token/substring/fuzzy fallbacks so we don't
      // guess wrong translations for words that aren't in the dict.
      final hits = DictionaryLookup.instance
          .lookupEnglish(w, maxResults: 1, strict: true);
      if (hits.isNotEmpty) {
        final h = hits.first;
        tokens.add(GlossToken(
          source: w,
          translation: h.awing,
          score: h.score,
          category: h.category,
          awing: h.awing,
        ));
        continue;
      }
      // No dict hit. If the word is capitalized, treat it as a proper
      // noun (name / place / brand) and keep as-is. Sentence-initial
      // common words like "The", "This", "How" are already caught by
      // the stopword filter above so this path only sees genuine
      // capital-letter content words like "James", "Paris", "Ford".
      final firstChar = w.isNotEmpty ? w[0] : '';
      final isCapital =
          firstChar.toUpperCase() == firstChar &&
          firstChar.toLowerCase() != firstChar;
      if (isCapital) {
        tokens.add(GlossToken(
          source: w,
          translation: w, // keep name as-is
          isStopword: true, // reuse "keep-as-is" bucket for counts
        ));
        continue;
      }
      // Genuinely missing — no translation, will render as em-dash.
      tokens.add(GlossToken(source: w));
    }
    return GlossResult(tokens: tokens, source: sentence);
  }

  /// Awing sentence → per-word English translations.
  GlossResult glossAwing(String sentence) {
    final tokens = <GlossToken>[];
    final words = _splitWords(sentence);
    for (final w in words) {
      if (RegExp(r'^[\s\p{P}]+$', unicode: true).hasMatch(w)) {
        tokens.add(GlossToken(source: w, isPunctuation: true));
        continue;
      }
      final hits = DictionaryLookup.instance.lookupAwing(w, maxResults: 1);
      if (hits.isEmpty) {
        tokens.add(GlossToken(source: w));
      } else {
        final h = hits.first;
        tokens.add(GlossToken(
          source: w,
          translation: h.english,
          score: h.score,
          category: h.category,
          awing: h.awing,
        ));
      }
    }
    return GlossResult(tokens: tokens, source: sentence);
  }

  /// Split into words, preserving punctuation as separate tokens
  /// (so "hand." shows both "hand" and "." — the "." falls through
  /// as a null token which the UI can skip).
  List<String> _splitWords(String sentence) {
    // Match: run of letters (including Awing special chars) OR punctuation.
    final re = RegExp(
      r"[A-Za-zÀ-ÿɛɔəɨŋɣ'’‘ʼ̀-ͯ]+|[^\w\s]",
      unicode: true,
    );
    return re.allMatches(sentence).map((m) => m.group(0)!).toList();
  }
}
