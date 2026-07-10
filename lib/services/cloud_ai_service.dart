import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awing_ai_learning/services/on_device_model_service.dart';

/// A generated example sentence returned by the cloud LLM.
///
/// [awing] is now built CLIENT-SIDE by word-by-word gloss against the
/// local dictionary — the LLM only returns [english]. This guarantees
/// every Awing word displayed is a real dictionary entry (never
/// hallucinated).
class CloudExampleSentence {
  final String awing;
  final String english;
  const CloudExampleSentence({required this.awing, required this.english});

  static CloudExampleSentence? tryParse(dynamic raw) {
    // The Worker returns { example: "<LLM text>", raw: {...}, model: "..." }
    // The LLM's text is USUALLY JSON with {"awing":"...","english":"..."}
    // but can also come wrapped in ```json fences, prefixed by prose,
    // have extra fields, or be plain text like "Awing: ... English: ...".
    // Be very forgiving.
    if (raw is! Map) return null;
    final example = raw['example'];
    if (example == null) return null;
    final text = example.toString();
    debugPrint('CloudAI raw example response: \$text');

    // Strategy 1 — pull JSON out of any ```json ... ``` block.
    final fenceMatch = RegExp(
      r'```(?:json)?\s*(\{[\s\S]*?\})\s*```',
      caseSensitive: false,
    ).firstMatch(text);
    final candidate1 = fenceMatch?.group(1);
    final parsed1 = candidate1 == null ? null : _tryDecodeExample(candidate1);
    if (parsed1 != null) return parsed1;

    // Strategy 2 — find any balanced { ... } block containing both
    // "awing" and "english" keys (in any order, nested braces OK).
    for (final block in _findJsonBlocks(text)) {
      final parsed = _tryDecodeExample(block);
      if (parsed != null) return parsed;
    }

    // Strategy 3 — plain-text fallback like "Awing: X\nEnglish: Y".
    final awingMatch = RegExp(r'(?:^|\n)\s*awing\s*[:=]\s*(.+)',
            caseSensitive: false)
        .firstMatch(text);
    final englishMatch = RegExp(r'(?:^|\n)\s*english\s*[:=]\s*(.+)',
            caseSensitive: false)
        .firstMatch(text);
    if (awingMatch != null && englishMatch != null) {
      final awing = awingMatch.group(1)!.trim().replaceAll(
          RegExp(r'["\.]+\$'), '');
      final english = englishMatch.group(1)!.trim().replaceAll(
          RegExp(r'["\.]+\$'), '');
      if (awing.isNotEmpty && english.isNotEmpty) {
        return CloudExampleSentence(awing: awing, english: english);
      }
    }

    return null;
  }

  static CloudExampleSentence? _tryDecodeExample(String jsonText) {
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map) return null;
      String? awing;
      String? english;
      decoded.forEach((k, v) {
        final key = k.toString().toLowerCase();
        if (key == 'awing' || key == 'aw') awing = v?.toString();
        if (key == 'english' || key == 'en' || key == 'sentence') {
          english = v?.toString();
        }
      });
      // English-only response is the new normal — client will fill in
      // Awing via word-by-word gloss.
      if (english != null && english!.isNotEmpty) {
        return CloudExampleSentence(
          awing: awing ?? '', // empty; client will replace via gloss
          english: english!,
        );
      }
    } catch (_) {}
    return null;
  }

  /// Yield every balanced {...} block in the text, ordered by position.
  static Iterable<String> _findJsonBlocks(String text) sync* {
    int depth = 0;
    int start = -1;
    for (int i = 0; i < text.length; i++) {
      final c = text[i];
      if (c == '{') {
        if (depth == 0) start = i;
        depth++;
      } else if (c == '}') {
        depth--;
        if (depth == 0 && start != -1) {
          yield text.substring(start, i + 1);
          start = -1;
        } else if (depth < 0) {
          depth = 0;
          start = -1;
        }
      }
    }
  }
}

/// A cloud-generated translation returned by the /translate endpoint.
class CloudTranslation {
  final String translation;
  final double? confidence;
  final String? notes;
  const CloudTranslation({
    required this.translation,
    this.confidence,
    this.notes,
  });

  static CloudTranslation? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final text = raw['translation']?.toString();
    if (text == null || text.trim().isEmpty) return null;
    // Try to extract inner JSON if the LLM wrapped its answer.
    final jsonMatch = RegExp(r'\{[^{}]*"translation"[^{}]*\}',
            dotAll: true, caseSensitive: false)
        .firstMatch(text);
    if (jsonMatch != null) {
      try {
        final decoded = jsonDecode(jsonMatch.group(0)!);
        if (decoded is Map) {
          return CloudTranslation(
            translation:
                decoded['translation']?.toString() ?? text,
            confidence: (decoded['confidence'] as num?)?.toDouble(),
            notes: decoded['notes']?.toString(),
          );
        }
      } catch (_) {}
    }
    return CloudTranslation(translation: text);
  }
}

/// Cloud AI client — talks to the CloudFlare Worker deployed at
/// [_workerUrl]. Every request carries a Firebase Auth ID token in the
/// Authorization header so the Worker can verify the user is a
/// legitimate app installer (not a scraper with the URL).
///
/// Only called when [AIToggleService.cloudEnabled] is true. Guards are
/// enforced at the callsite so this class doesn't need to know about
/// the toggle — it just makes network calls when asked.
///
/// Cost per call: ~5-10 KB of user data. Cached responses hit local
/// [SharedPreferences] and never hit the network again.
class CloudAIService {
  static final CloudAIService instance = CloudAIService._();
  CloudAIService._();

  /// URL of the deployed CloudFlare Worker. Placeholder until the user
  /// deploys the Worker and gives us the resulting *.workers.dev URL.
  ///
  /// After deployment, edit this constant to match the real URL, e.g.:
  ///   https://awing-ai.samagids.workers.dev
  static const String _workerUrl =
      'https://awing-ai.awingai.workers.dev';

  /// True once the URL constant has been updated away from the
  /// placeholder — used by callers to bail out cleanly before making
  /// a doomed network request.
  bool get isConfigured =>
      _workerUrl.startsWith('https://awing-ai.') && !_workerUrl.contains('REPLACE');

  /// 30-second global timeout for any cloud call. If the user is on a
  /// bad connection we'd rather fail fast and fall back to on-device
  /// than block their UI.
  static const Duration _timeout = Duration(seconds: 30);

  /// Generate an example sentence for a given Awing word.
  ///
  /// The Worker holds the full vocab and does retrieval server-side —
  /// the client only sends the target metadata. Payload per request is
  /// ~200 bytes (was ~5 KB when we sent retrieval from the client).
  Future<CloudExampleSentence?> generateExample({
    required String awingWord,
    required String english,
    required String category,
    String level = 'beginner',
    /// When true, callers who have the AI toggle OFF prefer the local
    /// Gemma 3 1B model over the CloudFlare Worker. If the local model
    /// isn't ready, callers get null (dictionary-only mode kicks in
    /// upstream in the UI).
    bool preferOffline = false,
  }) async {
    // Path C3: use the on-device model when the user's toggle prefers
    // offline. We call generateEnglishSentence unconditionally when
    // preferOffline is true - that method internally checks
    // isReady (model file present) and lazy-loads the cactus runtime
    // via _ensureLmLoaded on first call. Previously this wrapper
    // guarded the call behind isInferenceReady (isReady && _lmLoaded),
    // which was a chicken-and-egg: _lmLoaded only flips inside
    // _ensureLmLoaded, and _ensureLmLoaded only runs when
    // generateEnglishSentence is called, so the guard prevented the
    // guarded call from ever running.
    if (preferOffline) {
      final onDevice = OnDeviceModelService.instance;
      // IMPORTANT: pass the ENGLISH translation, not the Awing word.
      // Qwen3 (or any general-purpose LLM) has zero knowledge of Awing.
      // If we hand it the Awing spelling "mónkə" it makes up plausible-
      // sounding nonsense ("It sounds like Scottish..."). We give it the
      // English gloss "child" and let WordGloss upstream translate each
      // English token back to Awing where possible.
      //
      // Some dictionary entries have long descriptive glosses like
      // "relation's (father, mother, grand mother, ...) hair, worshipped
      // periodically for appeasement". Qwen3-0.6 can't use a 20-word
      // definition as "the target word" for a 5-8 word sentence. Extract
      // the primary noun/verb by cutting at first parenthesis, comma, or
      // semicolon, then capping at 40 chars.
      String primaryWord = english.trim();
      final firstParen = primaryWord.indexOf('(');
      if (firstParen > 0) {
        primaryWord = primaryWord.substring(0, firstParen).trim();
      }
      final firstComma = primaryWord.indexOf(',');
      if (firstComma > 0) {
        primaryWord = primaryWord.substring(0, firstComma).trim();
      }
      final firstSemi = primaryWord.indexOf(';');
      if (firstSemi > 0) {
        primaryWord = primaryWord.substring(0, firstSemi).trim();
      }
      // Strip trailing possessive 's so "relation's" -> "relation".
      primaryWord = primaryWord.replaceAll(RegExp(r"'s$"), '');
      if (primaryWord.length > 40) {
        primaryWord = primaryWord.substring(0, 40).trim();
      }
      if (primaryWord.isEmpty) primaryWord = english;

      final englishText = await onDevice.generateEnglishSentence(
        word: primaryWord,
        category: category,
        level: level,
      );
      if (englishText != null && englishText.trim().isNotEmpty) {
        // On-device returns English only, just like the Worker.
        // WordGloss on the widget side turns it into a word-by-word
        // Awing translation the same way it does for cloud responses.
        return CloudExampleSentence(awing: '', english: englishText);
      }
      // Model isn't ready OR generation failed. Don't secretly call
      // the Cloud when the user picked Offline - return null so the
      // UI shows the diagnostic message.
      return null;
    }

    if (!isConfigured) return null;
    final body = <String, dynamic>{
      'word': awingWord,
      'english': english,
      'category': category,
      'level': level,
    };
    final raw = await _post('/example', body);
    if (raw == null) return null;
    return CloudExampleSentence.tryParse(raw);
  }

  /// Translate a sentence (either direction).
  ///
  /// [dictionary] and [examples] give the model retrieval-augmented
  /// context — typically the top-100 most-relevant dictionary entries
  /// and top-20 nearest example sentences from the local corpus.
  /// Callers assemble these before calling.
  Future<CloudTranslation?> translate({
    required String text,
    required String direction, // 'en_to_aw' | 'aw_to_en'
    String level = 'beginner',
    List<Map<String, String>>? dictionary,
    List<Map<String, String>>? examples,
  }) async {
    if (!isConfigured) return null;
    final body = <String, dynamic>{
      'text': text,
      'direction': direction,
      'level': level,
      if (dictionary != null) 'dictionary': dictionary,
      if (examples != null) 'examples': examples,
    };
    final raw = await _post('/translate', body);
    if (raw == null) return null;
    return CloudTranslation.tryParse(raw);
  }

  /// Grade an Awing translation attempt.
  Future<String?> grade({
    required String english,
    required String attempt,
    List<Map<String, String>>? dictionary,
  }) async {
    if (!isConfigured) return null;
    final body = <String, dynamic>{
      'english': english,
      'attempt': attempt,
      if (dictionary != null) 'dictionary': dictionary,
    };
    final raw = await _post('/grade', body);
    if (raw == null) return null;
    return raw['feedback']?.toString();
  }

  /// Health check — hits the Worker's /health endpoint. Useful in a
  /// Developer Mode diagnostic tile. No auth required.
  Future<bool> isHealthy() async {
    if (!isConfigured) return false;
    try {
      final resp = await http
          .get(Uri.parse('$_workerUrl/health'))
          .timeout(const Duration(seconds: 5));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // internals
  // ============================================================

  Future<Map<String, dynamic>?> _post(String path, Map<String, dynamic> body) async {
    final idToken = await _getIdToken();
    if (idToken == null) {
      debugPrint('CloudAI: no Firebase ID token — user not signed in');
      return null;
    }
    try {
      final resp = await http
          .post(
            Uri.parse('$_workerUrl$path'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      debugPrint(
          'CloudAI: $path returned ${resp.statusCode}: ${resp.body.substring(0, resp.body.length > 200 ? 200 : resp.body.length)}');
      return null;
    } on TimeoutException {
      debugPrint('CloudAI: $path timed out');
      return null;
    } catch (e) {
      debugPrint('CloudAI: $path threw $e');
      return null;
    }
  }

  Future<String?> _getIdToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return await user.getIdToken();
    } catch (e) {
      debugPrint('CloudAI: getIdToken failed: $e');
      return null;
    }
  }
}
