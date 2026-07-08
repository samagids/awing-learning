import 'dart:async';
import 'package:flutter/foundation.dart';
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
  static const String modelSlug = 'gemma3-270m';

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

    try {
      await _lm.downloadModel(
        model: modelSlug,
        downloadProcessCallback: (double? progress, String status, bool isError) {
          if (isError) {
            debugPrint('OnDeviceModelService download err: $status');
            _lastError = status;
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

      // cactus 1.3 doesn't expose a per-slug delete API. Reset only in-memory
      // state; the user can clear the download from OS-level storage settings.
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
      final prompt = 'Write ONE short English sentence (5 to 8 words) '
          'that naturally uses the word "$word". '
          'Category: $category. Level: $level. '
          'Reply with only the sentence itself, no quotes, no explanation.';

      final result = await _lm.generateCompletion(
        messages: [ChatMessage(content: prompt, role: 'user')],
        params: CactusCompletionParams(
          maxTokens: 64,
          temperature: 0.7,
        ),
      );

      if (!result.success) return null;
      var cleaned = result.response.trim();
      while (cleaned.startsWith('"') || cleaned.startsWith("'")) {
        cleaned = cleaned.substring(1);
      }
      while (cleaned.endsWith('"') || cleaned.endsWith("'")) {
        cleaned = cleaned.substring(0, cleaned.length - 1);
      }
      cleaned = cleaned.trim();
      if (cleaned.isEmpty) return null;
      return cleaned;
    } catch (e) {
      debugPrint('OnDeviceModelService generation failed: $e');
      return null;
    }
  }

  Future<bool> _ensureLmLoaded() async {
    if (_lmLoaded) return true;
    if (_lmLoadFailed) return false;
    try {
      await _lm.initializeModel(
        params: CactusInitParams(model: modelSlug, contextSize: 1024),
      );
      _lmLoaded = true;
      notifyListeners();
      return true;
    } catch (e) {
      _lmLoadFailed = true;
      debugPrint('OnDeviceModelService init model failed: $e');
      notifyListeners();
      return false;
    }
  }

  bool get isInferenceReady => isReady && _lmLoaded;

  void _fail(String msg) {
    _status = ModelStatus.failed;
    _lastError = msg;
    _progress = 0.0;
    debugPrint('OnDeviceModelService failed: $msg');
    notifyListeners();
  }
}
