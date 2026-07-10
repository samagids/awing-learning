import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cactus/cactus.dart';

/// Lifecycle states of the on-device LLM.
enum ModelStatus {
  notStarted,
  awaitingWifi,
  downloading,
  ready,
  failed,
}

/// Manages the on-device gemma3-270m model (~270 MB) via cactus 1.3+.
///
/// C2 (download):
///   * cactus handles the download itself — we just pass a progress callback
///     that pushes updates into the ChangeNotifier.
///   * Auto-download on ANY network (WiFi or mobile) after app start, unless
///     the user has opted out via setAutoDownloadEnabled(false).
///   * Manual download button in Settings triggers the same flow.
///
/// C3 (inference):
///   * Lazy-loads the model on first generateEnglishSentence call.
///   * Uses cactus's generateCompletion with a short prompt.
///   * Returns null on failure — CloudAIService falls back to dictionary.
///
/// Model choice: gemma3-270m — smallest available, ~270 MB. If quality is
/// poor we can switch to qwen3-0.6 (~600 MB) later.
class OnDeviceModelService extends ChangeNotifier {
  static final OnDeviceModelService instance = OnDeviceModelService._();
  OnDeviceModelService._();

  /// Cactus model slug. See lm.getModels() for the current list.
  ///   gemma3-270m — 270 MB, tiny but decent
  ///   qwen3-0.6   — 600 MB, better quality
  // Switched from 'gemma3-270m' -> 'qwen3-0.6' 2026-07-08 (Session 63):
  // cactus 1.3's downloadModel for gemma3-270m completed without error
  // but initializeModel then failed with "Failed to initialize model
  // context with model at .../models/gemma3-270m" and the file itself
  // was missing from disk. qwen3-0.6 is cactus's own documented default
  // (see pub.dev/packages/cactus README) and is the most likely to
  // actually work through their storage layer.
  static const String modelSlug = 'qwen3-0.6';

  static const String _keyAutoDownloadDisabled = 'on_device_model_auto_disabled';
  static const String _keyDownloadedAt = 'on_device_model_downloaded_at';

  final CactusLM _lm = CactusLM();
  ModelStatus _status = ModelStatus.notStarted;
  double _progress = 0.0;
  String? _lastError;
  bool _initialized = false;
  bool _lmLoaded = false;
  bool _lmLoadFailed = false;

  ModelStatus get status => _status;
  double get progress => _progress;
  String? get lastError => _lastError;
  bool get isReady => _status == ModelStatus.ready;
  bool get isConfigured => true;

  Future<bool> get autoDownloadEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_keyAutoDownloadDisabled) ?? false);
  }

  Future<void> setAutoDownloadEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoDownloadDisabled, !enabled);
    notifyListeners();
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      // Ask cactus which models are already downloaded.
      final models = await _lm.getModels();
      final match = models.firstWhere(
        (m) => m.slug == modelSlug,
        orElse: () => CactusModel(
          createdAt: DateTime.now(),
          slug: modelSlug,
          downloadUrl: '',
          sizeMb: 0,
          supportsToolCalling: false,
          supportsVision: false,
          name: modelSlug,
          isDownloaded: false,
        ),
      );
      if (match.isDownloaded) {
        _status = ModelStatus.ready;
        debugPrint('OnDeviceModelService: model $modelSlug already on disk');
      }
    } catch (e) {
      debugPrint('OnDeviceModelService init failed: $e');
    }
    notifyListeners();
    unawaited(_maybeAutoDownload());
  }

  /// Silent background download if any network is available (WiFi OR mobile).
  Future<void> _maybeAutoDownload() async {
    if (isReady) return;
    if (_status == ModelStatus.downloading) return;
    if (!await autoDownloadEnabled) return;
    try {
      final result = await Connectivity().checkConnectivity();
      final hasNetwork = result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet) ||
          result.contains(ConnectivityResult.mobile);
      if (!hasNetwork) {
        debugPrint('OnDeviceModelService: auto-download waiting for network');
        return;
      }
      final onWifi = result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet);
      debugPrint(
          'OnDeviceModelService: auto-download starting (${onWifi ? "WiFi" : "mobile"})');
      await startDownload(allowCellular: true);
    } catch (e) {
      debugPrint('OnDeviceModelService auto-download failed: $e');
    }
  }

  Future<void> startDownload({bool allowCellular = false}) async {
    await initialize();
    if (_status == ModelStatus.downloading) return;
    if (isReady) return;

    final result = await Connectivity().checkConnectivity();
    final onWifi = result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet);
    if (!onWifi && !allowCellular) {
      _status = ModelStatus.awaitingWifi;
      _lastError = 'Connect to WiFi to download the offline AI model, '
          'or tap again to use mobile data.';
      notifyListeners();
      return;
    }

    _status = ModelStatus.downloading;
    _progress = 0.0;
    _lastError = null;
    notifyListeners();

    // Track whether the callback saw any error during the download.
    // Previously we only logged callback errors — the outer flow still
    // set status = ready even after cactus reported a mid-download
    // failure. That's why "97% done" transitioned to "ready" while the
    // file was never fully written to disk.
    var callbackReportedError = false;
    String? callbackError;

    try {
      await _lm.downloadModel(
        model: modelSlug,
        downloadProcessCallback: (double? progress, String status, bool isError) {
          if (isError) {
            callbackReportedError = true;
            callbackError = status;
            debugPrint('OnDeviceModelService download err: $status');
          } else {
            if (progress != null) {
              _progress = progress;
              notifyListeners();
            }
            debugPrint('OnDeviceModelService download: $status'
                '${progress != null ? " (${(progress * 100).toStringAsFixed(0)}%)" : ""}');
          }
        },
      );
      if (callbackReportedError) {
        _fail('Download reported error: ${callbackError ?? "unknown"}');
        return;
      }
      _status = ModelStatus.ready;
      _progress = 1.0;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyDownloadedAt, DateTime.now().millisecondsSinceEpoch);
      notifyListeners();
    } catch (e) {
      _fail('Download failed: $e');
    }
  }

  void cancelDownload() {
    if (_status == ModelStatus.downloading) {
      _status = ModelStatus.notStarted;
      _progress = 0.0;
      notifyListeners();
      // Note: cactus doesn't expose a cancel API; the download continues in
      // the background. Best we can do is stop reflecting progress in the UI.
    }
  }

  Future<void> deleteModel() async {
    try {
      try {
        _lm.unload();
      } catch (_) {}
      _lmLoaded = false;
      _lmLoadFailed = false;
      _lastError = null;

      // cactus 1.3 doesn't expose a per-slug delete API. We delete the
      // model file directly from disk so a subsequent downloadModel call
      // pulls fresh bytes instead of trusting an existing (possibly-
      // corrupted or wrong-format) file. Without this the "delete + re-
      // download" cycle appears too fast because cactus sees the file
      // already exists and skips the network fetch, reusing the same
      // broken bytes. Path shape came from the cactus initializeModel
      // error message: /data/user/0/<pkg>/app_flutter/models/<slug>
      // which is Flutter's getApplicationDocumentsDirectory() on
      // Android.
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final modelFile = File('${docsDir.path}/models/$modelSlug');
        if (await modelFile.exists()) {
          final sizeBytes = await modelFile.length();
          debugPrint(
              'OnDeviceModelService: deleting model file '
              '(${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB) at '
              '${modelFile.path}');
          await modelFile.delete();
        } else {
          debugPrint(
              'OnDeviceModelService: no model file at ${modelFile.path}');
        }
      } catch (e) {
        debugPrint('OnDeviceModelService: file delete failed: $e');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyDownloadedAt);
      _status = ModelStatus.notStarted;
      _progress = 0.0;
      notifyListeners();
    } catch (e) {
      debugPrint('OnDeviceModelService delete failed: $e');
    }
  }

  Future<String?> generateEnglishSentence({
    required String word,
    required String category,
    String level = 'beginner',
  }) async {
    if (!isReady) return null;
    final ok = await _ensureLmLoaded();
    if (!ok) return null;

    try {
      // Prompt is calibrated for Qwen3 and similar small chat models.
      // Word passed is the ENGLISH gloss - the model has no knowledge of
      // Awing so we ask it to write in its native language and let the
      // dictionary layer above translate token-by-token.
      // "/no_think" is Qwen3's official switch to skip chain-of-thought
      // output - without it the model emits <think>...</think> blocks
      // full of reasoning that we'd have to filter.
      final prompt = '/no_think Write ONE short English sentence '
          '(5 to 8 words, simple grammar suitable for a $level learner) '
          'that naturally uses the word "$word". '
          'Category: $category. '
          'Reply with ONLY the sentence itself. '
          'No quotes, no explanation, no thinking, no <think> tags.';

      final result = await _lm.generateCompletion(
        messages: [ChatMessage(content: prompt, role: 'user')],
        params: CactusCompletionParams(
          maxTokens: 96,
          temperature: 0.7,
        ),
      );

      if (!result.success) return null;
      final extracted = _extractSentence(result.response, word);
      if (extracted == null || extracted.trim().isEmpty) return null;
      return extracted;
    } catch (e) {
      debugPrint('OnDeviceModelService generation failed: $e');
      return null;
    }
  }

  /// Salvage a usable example sentence from qwen3-0.6's rambling output.
  ///
  /// Qwen3-0.6 (a 0.6B chat model) mostly ignores /no_think and
  /// instructions to reply with only a sentence. It writes chain-of-
  /// thought reasoning, uses em-dash bullet points, quotes the prompt
  /// verbatim, and occasionally emits pseudo-reasoning as natural
  /// language ("Okay, let's see. The user wants..."). Rather than
  /// trust the model to obey the prompt, we extract candidate sentences
  /// from whatever it produced and pick the first one that looks like
  /// a real English sentence:
  ///
  ///   1. Split on sentence-ending punctuation (. ! ?)
  ///   2. Reject anything containing meta-reasoning tokens
  ///      ("user", "the word", "let's", "reasoning", "sentence", etc.)
  ///   3. Reject anything shorter than 3 or longer than 15 words
  ///   4. Prefer sentences that mention the target [word] naturally
  ///   5. Fall back to any valid-looking sentence
  ///
  /// Returns null if nothing salvageable.
  String? _extractSentence(String raw, String targetWord) {
    var text = raw.trim();

    // Strip any <think>...</think> blocks first (belt + suspenders,
    // some Qwen3 fine-tunes DO emit these tags).
    text = text.replaceAll(
      RegExp(r'<think>.*?</think>', dotAll: true),
      ' ',
    );
    text = text.replaceAll(RegExp(r'</?think>'), ' ');

    // Strip surrounding markdown quote markers.
    // Use double-quoted non-raw string so the apostrophe is safe;
    // \" escapes the double-quote delimiter, \$ escapes Dart interpolation.
    text = text.replaceAll(RegExp("^[\"'`]+"), '');
    text = text.replaceAll(RegExp("[\"'`]+\$"), '');

    // Split on sentence enders while keeping the terminal punctuation.
    final chunks = RegExp(r'[^.!?\n]+[.!?]')
        .allMatches(text)
        .map((m) => m.group(0)!.trim())
        .toList();

    final metaTokens = RegExp(
      r'\b(user|users|the word|thinking|reasoning|let me|let\x27s|'
      r'first,? i|first,? we|first,? let|okay,? let|okay,? so|'
      r'here\x27s a|here is a|sure,?|alright|as an ai|instructions?|'
      r'i need to|i should|i can|i will|as requested|as asked)\b',
      caseSensitive: false,
    );
    final targetLc = targetWord.toLowerCase();
    String? fallback;

    for (final chunk in chunks) {
      var s = chunk.replaceAll(RegExp(r'^[\s—–\-]+'), '').trim();
      if (s.isEmpty) continue;
      // Must start with a capital letter (real sentence).
      if (!RegExp(r'^[A-Z]').hasMatch(s)) continue;
      // Reject reasoning.
      if (metaTokens.hasMatch(s)) continue;
      // Length window.
      final words = s.split(RegExp(r'\s+')).length;
      if (words < 3 || words > 18) continue;
      // Reject if it's basically a list of em-dashes and single letters.
      final dashCount = RegExp(r'—|--').allMatches(s).length;
      if (dashCount > 1) continue;
      // Prefer sentences containing the target word.
      if (s.toLowerCase().contains(targetLc)) return s;
      fallback ??= s;
    }
    return fallback;
  }

  Future<bool> _ensureLmLoaded() async {
    if (_lmLoaded) return true;
    if (_lmLoadFailed) return false;
    try {
      // Call initializeModel WITHOUT params - cactus's own docs show
      // this pattern (auto-picks the most-recently-downloaded model).
      // Passing CactusInitParams(model: slug) previously caused cactus
      // to look up a path derived from the slug string, which didn't
      // match where cactus actually stored the download - hence the
      // "Failed to initialize model context with model at .../gemma3-
      // 270m" error even though downloadModel completed. Let cactus
      // resolve the path from its own internal state.
      await _lm.initializeModel();
      _lmLoaded = true;
      notifyListeners();
      return true;
    } catch (e) {
      _lmLoadFailed = true;
      // Surface the actual cactus error so diagnosticSummary can
      // display it. Without this the user sees 'Last error: unknown'
      // and we have no idea whether it's a slug mismatch, corrupted
      // GGUF file, insufficient RAM, unsupported quantization, etc.
      _lastError = e.toString();
      debugPrint('OnDeviceModelService init model failed: $e');
      notifyListeners();
      return false;
    }
  }

  bool get isInferenceReady => isReady && _lmLoaded;

  /// Human-readable one-line description of what state on-device AI is
  /// currently in. Used by UI to tell the user WHY offline generation
  /// didn't produce anything, instead of a generic "Cloud AI did not
  /// return..." message that confuses users who have Cloud OFF.
  String get diagnosticSummary {
    if (_lmLoadFailed) {
      return 'Offline AI is downloaded but failed to load. '
          'Model: $modelSlug. Last error: ${_lastError ?? "unknown"}. '
          'Try deleting the model in Settings and re-downloading.';
    }
    switch (_status) {
      case ModelStatus.notStarted:
        return 'Offline AI is not downloaded yet. '
            'Open Cloud AI toggle → info icon → download the model.';
      case ModelStatus.awaitingWifi:
        return 'Offline AI is waiting for Wi-Fi to download automatically. '
            'Open Cloud AI toggle → info icon to force download on mobile data.';
      case ModelStatus.downloading:
        return 'Offline AI is still downloading (${(_progress * 100).toStringAsFixed(0)}%). '
            'Wait for it to finish.';
      case ModelStatus.failed:
        return 'Offline AI download failed: ${_lastError ?? "unknown error"}. '
            'Open Cloud AI toggle → info icon and try again.';
      case ModelStatus.ready:
        if (!_lmLoaded) {
          return 'Offline AI is downloaded but hasn\'t loaded yet. '
              'Tap Generate again in a few seconds.';
        }
        return 'Offline AI is ready.';
    }
  }

  void _fail(String msg) {
    _status = ModelStatus.failed;
    _lastError = msg;
    _progress = 0.0;
    debugPrint('OnDeviceModelService failed: $msg');
    notifyListeners();
  }
}
