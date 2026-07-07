import 'package:flutter/foundation.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';

/// A single Awing/English example sentence containing a target word.
class ExampleSentence {
  final String awing;
  final String english;
  final String source; // 'phrases', 'orthography', etc.
  const ExampleSentence({
    required this.awing,
    required this.english,
    required this.source,
  });
}

/// Offline example-sentence service.
///
/// Searches the curated `awingPhrases` list (~50 PDF-verified short
/// sentences) for phrases containing a given Awing word. Zero data
/// cost — everything is bundled in the app.
///
/// Coverage is limited: only words that appear in the phrase list will
/// find examples. Cloud AI (Phase B) is what fills the gap for arbitrary
/// dictionary words — when the toggle is ON, `SentenceService` will
/// call the LLM to generate an example for any word.
class ExampleSentenceService {
  static final ExampleSentenceService instance =
      ExampleSentenceService._();
  ExampleSentenceService._();

  bool _built = false;

  /// Maps normalized Awing word → list of phrases containing it.
  final Map<String, List<ExampleSentence>> _byAwingWord = {};

  void _build() {
    if (_built) return;
    for (final p in awingPhrases) {
      final example = ExampleSentence(
        awing: p.awing,
        english: p.english,
        source: 'orthography',
      );
      // Tokenize the Awing side. Case-insensitive match. Also index
      // each word's diacritic-stripped form so users searching without
      // tone marks still see hits.
      final words = _tokenizeAwing(p.awing);
      for (final w in words) {
        final norm = w.toLowerCase();
        _byAwingWord.putIfAbsent(norm, () => []).add(example);
        final stripped = _stripDiacritics(w);
        if (stripped != norm) {
          _byAwingWord.putIfAbsent(stripped, () => []).add(example);
        }
      }
    }
    _built = true;
    debugPrint('ExampleSentenceService: indexed ${awingPhrases.length} '
        'phrases into ${_byAwingWord.length} word keys');
  }

  /// Return example sentences that contain the given Awing word.
  /// Returns at most `maxResults` sentences, ordered shortest first
  /// (short sentences make better learning examples).
  List<ExampleSentence> findByAwing(String awingWord, {int maxResults = 2}) {
    _build();
    if (awingWord.trim().isEmpty) return const [];
    final norm = awingWord.toLowerCase().trim();
    final stripped = _stripDiacritics(awingWord);

    final seen = <String>{}; // dedup by awing sentence
    final hits = <ExampleSentence>[];

    // Try exact-form match first.
    for (final s in (_byAwingWord[norm] ?? const [])) {
      if (seen.add(s.awing)) hits.add(s);
    }
    // Then stripped-form match.
    if (stripped != norm) {
      for (final s in (_byAwingWord[stripped] ?? const [])) {
        if (seen.add(s.awing)) hits.add(s);
      }
    }

    // Sort shortest awing first — better example for a learner.
    hits.sort((a, b) => a.awing.length.compareTo(b.awing.length));
    if (hits.length > maxResults) {
      return hits.sublist(0, maxResults);
    }
    return hits;
  }

  List<String> _tokenizeAwing(String s) {
    // Match runs of letters (including Awing special chars) — skip
    // punctuation.
    return RegExp(
      r"[A-Za-zÀ-ÿɛɔəɨŋɣ'’‘ʼ̀-ͯ]+",
      unicode: true,
    ).allMatches(s).map((m) => m.group(0)!).toList();
  }

  String _stripDiacritics(String s) {
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
            // combining diacritic
          } else {
            buf.write(c);
          }
      }
    }
    return buf.toString();
  }
}
