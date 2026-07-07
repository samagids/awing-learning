import 'package:awing_ai_learning/data/awing_vocabulary.dart';

/// A context bundle to send with a Cloud AI request.
///
/// Contains the dictionary excerpts and example sentences most likely to
/// be relevant to the target query. The LLM is prompted to use ONLY
/// these Awing words, which sharply reduces hallucination.
class RetrievalBundle {
  /// English → Awing map. Small and flat so it fits in the LLM context
  /// window without ballooning the request size.
  final List<Map<String, String>> dictionary;

  /// English example sentences ↔ Awing translations.
  final List<Map<String, String>> examples;

  /// The FULL allowed Awing word set — used by the caller to validate
  /// the LLM's output for hallucinated (invented) words.
  final Set<String> allowedAwingWords;

  const RetrievalBundle({
    required this.dictionary,
    required this.examples,
    required this.allowedAwingWords,
  });
}

/// Builds a retrieval-augmented context bundle for a target word/phrase.
///
/// Strategy:
///   1. Include all vocab in the SAME category as the target word
///      (e.g. "chin" → all body-part entries)
///   2. Include high-utility beginner-difficulty verbs, pronouns,
///      descriptive words, common nouns — the glue words needed to
///      form a short sentence
///   3. Include all curated example phrases (~50 short sentences from
///      the orthography PDF) — the LLM uses these as pattern examples
///   4. Cap total dictionary payload at ~150 entries so the request
///      stays under ~5 KB
///
/// Also returns the FULL allowed word set so callers can flag output
/// tokens the LLM invented.
class RetrievalService {
  static final RetrievalService instance = RetrievalService._();
  RetrievalService._();

  RetrievalBundle buildForWord({
    required String targetAwing,
    required String targetEnglish,
    required String targetCategory,
    int maxDictionary = 150,
  }) {
    final chosen = <AwingWord>[];
    final seen = <String>{};

    void add(AwingWord w) {
      final key = '${w.awing}|${w.english}';
      if (seen.contains(key)) return;
      seen.add(key);
      chosen.add(w);
    }

    // 1) Same category as the target — very likely relevant to a
    // sentence about the target word.
    for (final w in allVocabulary) {
      if (chosen.length >= maxDictionary) break;
      if (w.category == targetCategory) add(w);
    }

    // 2) High-utility beginner glue — pronouns, common verbs,
    // descriptive words, articles. Any short sentence about a body
    // part / animal / thing likely needs some of these.
    if (chosen.length < maxDictionary) {
      for (final w in allVocabulary) {
        if (chosen.length >= maxDictionary) break;
        if (w.difficulty != 1) continue;
        if (w.category == 'pronouns' ||
            w.category == 'actions' ||
            w.category == 'descriptive' ||
            w.category == 'time') {
          add(w);
        }
      }
    }

    final dictionaryPayload = chosen
        .map((w) => {'english': w.english, 'awing': w.awing})
        .toList(growable: false);

    // 3) All curated example phrases — small (~50) so ship all.
    final examplesPayload = awingPhrases
        .map((p) => {'english': p.english, 'awing': p.awing})
        .toList(growable: false);

    // 4) Allowed word set — every Awing word (including multi-word
    // entries broken into tokens) plus tokens from every example
    // phrase. Used to guard against hallucinated words in the output.
    final allowed = <String>{};
    // Include EVERY vocab entry's awing string, not just the chosen
    // slice, since a legitimate LLM output could reasonably pull in
    // any real Awing word.
    for (final w in allVocabulary) {
      for (final tok in _tokenize(w.awing)) {
        allowed.add(_normalize(tok));
      }
    }
    for (final p in awingPhrases) {
      for (final tok in _tokenize(p.awing)) {
        allowed.add(_normalize(tok));
      }
    }
    // Always allow the target word itself.
    for (final tok in _tokenize(targetAwing)) {
      allowed.add(_normalize(tok));
    }

    return RetrievalBundle(
      dictionary: dictionaryPayload,
      examples: examplesPayload,
      allowedAwingWords: allowed,
    );
  }

  /// Check whether the given Awing output contains any words NOT in
  /// the allowed set. Returns the list of unknown words.
  List<String> findHallucinatedWords(
    String awingOutput,
    Set<String> allowedAwingWords,
  ) {
    final unknown = <String>[];
    for (final tok in _tokenize(awingOutput)) {
      final norm = _normalize(tok);
      if (norm.length < 2) continue; // skip trivial tokens
      if (!allowedAwingWords.contains(norm)) {
        unknown.add(tok);
      }
    }
    return unknown;
  }

  /// Break an Awing string into word tokens (skip punctuation).
  List<String> _tokenize(String s) {
    return RegExp(
      r"[A-Za-zÀ-ÿɛɔəɨŋɣ'’‘ʼ̀-ͯ]+",
      unicode: true,
    ).allMatches(s).map((m) => m.group(0)!).toList();
  }

  /// Normalize by lowercasing and stripping combining marks so
  /// "ghɛnɔ́" and "GHENO" (a lazy typist's version) both match.
  String _normalize(String s) {
    final buf = StringBuffer();
    final lower = s.toLowerCase();
    for (int i = 0; i < lower.length; i++) {
      final c = lower[i];
      final code = c.codeUnitAt(0);
      if (code >= 0x0300 && code <= 0x036F) continue; // combining mark
      buf.write(c);
    }
    return buf.toString();
  }
}
