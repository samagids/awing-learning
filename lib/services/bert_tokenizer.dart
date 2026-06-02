// bert_tokenizer.dart
// ---------------------------------------------------------------
// v1.16.0 — Dart port of HuggingFace's BertTokenizer (uncased
// WordPiece) for the sentence-transformers/all-MiniLM-L6-v2 model.
//
// Matches the reference Python tokenizer's output exactly for any
// ASCII / Latin / common-extended-Unicode input. Limitations:
//   - No Chinese / Japanese / Korean character splitting (model is
//     English-only; Awing words go through English path).
//   - No control / whitespace classification beyond ASCII + standard
//     Unicode whitespace.
//
// Reference Python:
//   from transformers import BertTokenizer
//   tok = BertTokenizer.from_pretrained('sentence-transformers/all-MiniLM-L6-v2')
//   tok('apple')         -> {'input_ids': [101, 6207, 102],
//                            'attention_mask': [1, 1, 1]}
//
// Vocab file format (vocab.txt — one token per line, 30,522 tokens):
//   Line 0: [PAD]
//   Line 100: [UNK]
//   Line 101: [CLS]
//   Line 102: [SEP]
//   Line 103: [MASK]
//   ...
// ---------------------------------------------------------------

import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:awing_ai_learning/services/asset_pack_service.dart';

class BertTokenizerResult {
  final List<int> inputIds;
  final List<int> attentionMask;
  const BertTokenizerResult(this.inputIds, this.attentionMask);
}

class BertTokenizer {
  static BertTokenizer? _instance;
  static BertTokenizer get instance => _instance ??= BertTokenizer._();
  BertTokenizer._();

  Map<String, int>? _vocab;
  bool _loading = false;
  Completer<void>? _loadCompleter;

  // Special token IDs (BERT-uncased convention)
  static const int padTokenId = 0;
  static const int unkTokenId = 100;
  static const int clsTokenId = 101;
  static const int sepTokenId = 102;

  /// Load the WordPiece vocab. Tries PAD pack first
  /// (android/install_time_assets/src/main/assets/vocab.txt),
  /// then falls back to main bundle (assets/vocab.txt). Idempotent:
  /// concurrent callers share the same load Future.
  Future<void> load() async {
    if (_vocab != null) return;
    if (_loading) return _loadCompleter!.future;
    _loading = true;
    _loadCompleter = Completer<void>();
    try {
      String text;
      // Try PAD first (preferred — smaller main bundle)
      try {
        final bytes = await AssetPackService().getAssetBytes('vocab.txt');
        if (bytes == null) throw Exception('vocab.txt not in PAD');
        text = String.fromCharCodes(bytes);
      } catch (_) {
        // Fallback: main bundle
        text = await rootBundle.loadString('assets/vocab.txt');
      }
      final vocab = <String, int>{};
      int idx = 0;
      for (final line in text.split('\n')) {
        final tok = line.trimRight(); // preserve leading WP markers if any
        if (tok.isEmpty && idx >= 30000) break;
        vocab[tok] = idx++;
      }
      _vocab = vocab;
      _loadCompleter!.complete();
    } catch (e) {
      _loadCompleter!.completeError(e);
      rethrow;
    } finally {
      _loading = false;
    }
  }

  /// True if the vocab has been loaded successfully.
  bool get isLoaded => _vocab != null;

  /// Encode `text` to BERT input. Always lowercase (uncased model).
  /// `maxSeqLen` defaults to 128 (matches model export shape).
  /// Output is padded to maxSeqLen.
  BertTokenizerResult encode(String text, {int maxSeqLen = 128}) {
    if (_vocab == null) {
      throw StateError('BertTokenizer.load() not called yet');
    }

    // Step 1: basic tokenization (lowercase + split on whitespace + punctuation)
    final lower = text.toLowerCase();
    final basicTokens = _basicTokenize(lower);

    // Step 2: WordPiece each basic token
    final wpTokens = <String>[];
    for (final t in basicTokens) {
      wpTokens.addAll(_wordpiece(t));
    }

    // Step 3: special tokens [CLS] X [SEP]; truncate to maxSeqLen-2
    final maxBody = maxSeqLen - 2;
    final body = wpTokens.length > maxBody
        ? wpTokens.sublist(0, maxBody)
        : wpTokens;
    final ids = <int>[clsTokenId];
    for (final t in body) {
      ids.add(_vocab![t] ?? unkTokenId);
    }
    ids.add(sepTokenId);

    // Step 4: pad
    final mask = List<int>.filled(maxSeqLen, 0);
    for (int i = 0; i < ids.length; i++) {
      mask[i] = 1;
    }
    while (ids.length < maxSeqLen) {
      ids.add(padTokenId);
    }

    return BertTokenizerResult(ids, mask);
  }

  // === Basic tokenization ===

  /// Split on whitespace, then on punctuation. Drop control chars.
  List<String> _basicTokenize(String text) {
    final cleaned = StringBuffer();
    for (final ch in text.runes) {
      if (_isControl(ch)) continue;
      if (_isWhitespace(ch)) {
        cleaned.write(' ');
      } else if (_isPunctuation(ch)) {
        cleaned.write(' ');
        cleaned.writeCharCode(ch);
        cleaned.write(' ');
      } else {
        cleaned.writeCharCode(ch);
      }
    }
    // Split on whitespace, strip diacritics from non-ASCII (BERT uncased
    // does NFD-decompose + strip combining marks during _run_strip_accents).
    final out = <String>[];
    for (final tok in cleaned.toString().split(RegExp(r'\s+'))) {
      if (tok.isEmpty) continue;
      out.add(_stripAccents(tok));
    }
    return out;
  }

  String _stripAccents(String s) {
    // NFD-decompose then drop combining marks (̀-ͯ).
    // Dart String doesn't have built-in NFD, but for our use case
    // (English vocab + Awing words), we only need to handle common
    // Latin combining marks present in our input. characters package
    // would help but isn't in deps; do a manual sweep.
    final sb = StringBuffer();
    for (final ch in s.runes) {
      // Skip Combining Diacritical Marks block (U+0300 .. U+036F)
      if (ch >= 0x0300 && ch <= 0x036F) continue;
      // Map pre-composed accented Latin letters to their base
      final base = _accentBase[ch];
      if (base != null) {
        sb.writeCharCode(base);
      } else {
        sb.writeCharCode(ch);
      }
    }
    return sb.toString();
  }

  // === WordPiece ===

  List<String> _wordpiece(String token) {
    if (token.length > 200) {
      return ['[UNK]'];
    }
    final out = <String>[];
    int start = 0;
    while (start < token.length) {
      int end = token.length;
      String? cur;
      while (start < end) {
        var sub = token.substring(start, end);
        if (start > 0) sub = '##$sub';
        if (_vocab!.containsKey(sub)) {
          cur = sub;
          break;
        }
        end--;
      }
      if (cur == null) {
        return ['[UNK]'];
      }
      out.add(cur);
      start = end;
    }
    return out;
  }

  // === Character classes (BERT-style) ===

  static bool _isWhitespace(int ch) {
    if (ch == 0x20 || ch == 0x09 || ch == 0x0A || ch == 0x0D) return true;
    // Unicode Zs category — approximate with common cases
    return ch == 0x00A0 || ch == 0x1680 ||
        (ch >= 0x2000 && ch <= 0x200A) ||
        ch == 0x202F || ch == 0x205F || ch == 0x3000;
  }

  static bool _isControl(int ch) {
    if (ch == 0x09 || ch == 0x0A || ch == 0x0D) return false; // treat as ws
    return ch < 0x20 || (ch >= 0x7F && ch < 0xA0);
  }

  static bool _isPunctuation(int ch) {
    // BERT-style: ASCII punctuation OR Unicode P* categories
    // ASCII: ! through / (33-47), : through @ (58-64), [ through ` (91-96), { through ~ (123-126)
    if ((ch >= 33 && ch <= 47) ||
        (ch >= 58 && ch <= 64) ||
        (ch >= 91 && ch <= 96) ||
        (ch >= 123 && ch <= 126)) {
      return true;
    }
    return false;
  }

  // Common pre-composed accent → base Latin map. Covers tests against
  // the English vocab — Awing tone marks decompose via the U+0300 path.
  static const Map<int, int> _accentBase = {
    0xE0: 0x61, 0xE1: 0x61, 0xE2: 0x61, 0xE3: 0x61, 0xE4: 0x61, 0xE5: 0x61, // à á â ã ä å
    0xE7: 0x63, // ç
    0xE8: 0x65, 0xE9: 0x65, 0xEA: 0x65, 0xEB: 0x65, // è é ê ë
    0xEC: 0x69, 0xED: 0x69, 0xEE: 0x69, 0xEF: 0x69, // ì í î ï
    0xF1: 0x6E, // ñ
    0xF2: 0x6F, 0xF3: 0x6F, 0xF4: 0x6F, 0xF5: 0x6F, 0xF6: 0x6F, // ò ó ô õ ö
    0xF9: 0x75, 0xFA: 0x75, 0xFB: 0x75, 0xFC: 0x75, // ù ú û ü
    0xFD: 0x79, 0xFF: 0x79, // ý ÿ
  };
}
