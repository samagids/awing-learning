import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cactus/cactus.dart';

/// Download / lifecycle states for the on-device TinyLlama-1.1B model.
enum ModelStatus {
  notStarted,
  awaitingWifi,
  downloading,
  ready,
  failed,
}

/// Manages the on-device TinyLlama-1.1B-Chat Q4_K_M model (~668 MB).
///
/// C2 (download):
///   * Silent background download on WiFi after app start
///   * Manual download button in Settings with mobile-data warning dialog
///   * Progress reporting + cancel/delete via ChangeNotifier
///
/// C3 (inference via cactus / llama.cpp):
///   * Lazy-loads model into `cactus` on first `generateEnglishSentence` call
///   * CloudAIService.generateExample routes here when `preferOffline=true`.
///     Returns null on any failure — upstream falls back to dictionary mode.
///
/// Guard: never runs on ineligible devices (RAM check via
/// DeviceCapabilityService is the gate — CloudAIService is responsible
/// for consulting it before calling any method here).
class OnDeviceModelService extends ChangeNotifier {
  static final OnDeviceModelService instance = OnDeviceModelService._();
  OnDeviceModelService._();

  /// Public URL of the GGUF model file. Update to R2 URL when uploaded.
  /// Currently HuggingFace so testers can install and it just works.
  static const String modelUrl =
      'https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf';

  static const String modelFileName = 'tinyllama-chat-q4.gguf';

  /// Minimum valid file size — anything smaller is treated as partial and
  /// deleted on init. TinyLlama Q4_K_M is ~668 MB, so 500 MB is safe floor.
  static const int minValidSizeBytes = 500 * 1024 * 1024;

  static const String _keyDownloadedAt = 'on_device_model_downloaded_at';
  static const String _keyAutoDownloadDisabled = 'on_device_model_auto_disabled';

  ModelStatus _status = ModelStatus.notStarted;
  double _progress = 0.0;
  String? _lastError;
  String? _modelFilePath;
  bool _initialized = false;

  ModelStatus get status => _status;
  double get progress => _progress;
  String? get lastError => _lastError;
  bool get isReady => _status == ModelStatus.ready && _modelFilePath != null;
  bool get isConfigured => true; // Real URL is baked in.

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
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$modelFileName');
      if (await file.exists()) {
        final size = await file.length();
        if (size >= minValidSizeBytes) {
          _modelFilePath = file.path;
          _status = ModelStatus.ready;
          debugPrint(
              'OnDeviceModelService: found ${size ~/ 1024 ~/ 1024} MB model at ${file.path}');
        } else {
          try {
            await file.delete();
          } catch (_) {}
          debugPrint('OnDeviceModelService: deleted stale/partial model file');
        }
      }
    } catch (e) {
      debugPrint('OnDeviceModelService init failed: $e');
    }
    notifyListeners();
    // Kick off background auto-download check.
    unawaited(_maybeAutoDownload());
  }

  /// Silently start a background download if any network is available
  /// (WiFi OR mobile data). We use mobile data because most Awing-speaking
  /// users in Cameroon don't have reliable WiFi. The user can:
  ///   * cancel from Settings while it's in progress, or
  ///   * turn off auto-download entirely via setAutoDownloadEnabled(false).
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
        debugPrint('OnDeviceModelService: auto-download waiting for any network');
        return;
      }
      final onWifi = result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet);
      debugPrint(
          'OnDeviceModelService: auto-download starting (${onWifi ? "WiFi" : "mobile"})');
      // Bypass the WiFi-only guard inside startDownload — user has already
      // consented to auto-download via the (default-on) autoDownloadEnabled
      // preference. If they don't want cellular data used, they turn off
      // auto-download in Settings.
      await startDownload(allowCellular: true);
    } catch (e) {
      debugPrint('OnDeviceModelService auto-download check failed: $e');
    }
  }

  /// Start downloading the model. WiFi-only by default; if [allowCellular]
  /// is true the caller has confirmed with the user (data warning).
  Future<void> startDownload({bool allowCellular = false}) async {
    await initialize();
    if (_status == ModelStatus.downloading) return;

    final result = await Connectivity().checkConnectivity();
    final onWifi = result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet);
    if (!onWifi && !allowCellular) {
      _status = ModelStatus.awaitingWifi;
      _lastError = 'Connect to WiFi to download the offline AI model '
          '(~670 MB). You can override this and use cellular data '
          'from Settings.';
      notifyListeners();
      return;
    }

    _status = ModelStatus.downloading;
    _progress = 0.0;
    _lastError = null;
    notifyListeners();

    try {
      final dir = await getApplicationDocumentsDirectory();
      final tempFile = File('${dir.path}/$modelFileName.partial');
      final finalFile = File('${dir.path}/$modelFileName');
      if (await tempFile.exists()) await tempFile.delete();

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(modelUrl));
      final response = await client.send(request);
      if (response.statusCode != 200) {
        client.close();
        _fail('Server returned HTTP ${response.statusCode}');
        return;
      }

      final total = response.contentLength ?? 0;
      final sink = tempFile.openWrite();
      int received = 0;
      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) {
            _progress = received / total;
            if ((_progress * 100).floor() !=
                ((received - chunk.length) / total * 100).floor()) {
              notifyListeners();
            }
          }
          if (_status != ModelStatus.downloading) {
            await sink.close();
            client.close();
            await tempFile.delete();
            return;
          }
        }
      } finally {
        await sink.close();
        client.close();
      }

      if (await finalFile.exists()) await finalFile.delete();
      await tempFile.rename(finalFile.path);

      _modelFilePath = finalFile.path;
      _status = ModelStatus.ready;
      _progress = 1.0;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyDownloadedAt, DateTime.now().millisecondsSinceEpoch);
      notifyListeners();
      debugPrint('OnDeviceModelService: download complete -> ${finalFile.path}');
    } catch (e) {
      _fail('Download failed: $e');
    }
  }

  void cancelDownload() {
    if (_status == ModelStatus.downloading) {
      _status = ModelStatus.notStarted;
      _progress = 0.0;
      notifyListeners();
    }
  }

  /// Delete the downloaded model to free ~668 MB of storage. Also unloads
  /// the LM from memory. User can toggle auto-download off to prevent
  /// re-download on next app start.
  Future<void> deleteModel() async {
    try {
      try {
        await _lm?.dispose();
      } catch (_) {}
      _lm = null;
      _lmLoaded = false;
      _lmLoadFailed = false;
      _lmLoadStarted = false;

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$modelFileName');
      if (await file.exists()) await file.delete();
      final partial = File('${dir.path}/$modelFileName.partial');
      if (await partial.exists()) await partial.delete();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyDownloadedAt);
      _modelFilePath = null;
      _status = ModelStatus.notStarted;
      _progress = 0.0;
      notifyListeners();
      debugPrint('OnDeviceModelService: model deleted');
    } catch (e) {
      debugPrint('OnDeviceModelService delete failed: $e');
    }
  }

  // ============================================================
  // Phase C3 — Inference via cactus (llama.cpp wrapper)
  // ============================================================

  CactusLM? _lm;
  bool _lmLoaded = false;
  bool _lmLoadFailed = false;
  final Completer<void> _lmLoadLock = Completer<void>();
  bool _lmLoadStarted = false;

  /// Generate a short English example sentence using on-device TinyLlama.
  /// Returns null on any failure — caller falls back to dictionary mode.
  Future<String?> generateEnglishSentence({
    required String word,
    required String category,
    String level = 'beginner',
  }) async {
    if (!isReady) return null;
    final ok = await _ensureLmLoaded();
    if (!ok || _lm == null) return null;

    try {
      final prompt = 'Write ONE short English sentence (5 to 8 words) '
          'that naturally uses the word "$word". '
          'Category: $category. Level: $level. '
          'Reply with only the sentence itself — no quotes, no explanation.';

      final result = await _lm!.completion(
        [ChatMessage(role: 'user', content: prompt)],
        maxTokens: 64,
        temperature: 0.7,
        topK: 40,
      );

      final text = result.result;
      if (text.trim().isEmpty) return null;

      var cleaned = text.trim();
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
      debugPrint('OnDeviceModelService cactus generation failed: $e');
      return null;
    }
  }

  Future<bool> _ensureLmLoaded() async {
    if (_lmLoaded) return true;
    if (_lmLoadFailed) return false;
    if (_modelFilePath == null) return false;

    if (_lmLoadStarted) {
      await _lmLoadLock.future;
      return _lmLoaded;
    }
    _lmLoadStarted = true;

    try {
      final lm = await CactusLM.init(
        modelPath: _modelFilePath!,
        contextSize: 2048,
        threads: 4,
        gpuLayers: 0,
      );
      _lm = lm;
      _lmLoaded = true;
      debugPrint('OnDeviceModelService: cactus LM loaded');
      if (!_lmLoadLock.isCompleted) _lmLoadLock.complete();
      notifyListeners();
      return true;
    } catch (e) {
      _lmLoadFailed = true;
      debugPrint('OnDeviceModelService cactus load failed: $e');
      if (!_lmLoadLock.isCompleted) _lmLoadLock.complete();
      notifyListeners();
      return false;
    }
  }

  bool get isInferenceReady =>
      _status == ModelStatus.ready && _lmLoaded && _lm != null;

  void _fail(String msg) {
    _status = ModelStatus.failed;
    _lastError = msg;
    _progress = 0.0;
    debugPrint('OnDeviceModelService failed: $msg');
    notifyListeners();
  }
}
