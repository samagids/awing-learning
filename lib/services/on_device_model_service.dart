import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

/// Download / lifecycle states for the on-device Gemma 3 1B model.
enum ModelStatus {
  /// Never downloaded on this device.
  notStarted,

  /// Waiting on a WiFi connection.
  awaitingWifi,

  /// Actively downloading.
  downloading,

  /// Model file present on disk, ready to load.
  ready,

  /// Something failed. See [OnDeviceModelService.lastError].
  failed,
}

/// Manages the on-device Gemma 3 1B model.
///
/// Responsibilities (Phase C2):
///   • Determine if a downloaded model file exists locally
///   • Stream-download the .task file from a configured URL when the
///     user taps "Download Offline AI"
///   • Enforce WiFi-only by default (a "download on cellular anyway"
///     toggle will land in a future iteration)
///   • Report progress + status via ChangeNotifier
///
/// Responsibilities (Phase C3 — inference):
///   • Lazy-load the model into flutter_gemma when first needed
///   • Provide [generateEnglishSentence] used by CloudAIService as a
///     drop-in offline replacement for the CloudFlare Worker's
///     English-sentence-generation call
///
/// Guard: never runs on ineligible devices (RAM check via
/// DeviceCapabilityService is the gate — CloudAIService is responsible
/// for consulting it before calling any method here).
class OnDeviceModelService extends ChangeNotifier {
  static final OnDeviceModelService instance = OnDeviceModelService._();
  OnDeviceModelService._();

  /// Public URL of the .task model file. This is a CONFIGURATION
  /// constant — the developer hosts the file on their own CloudFlare
  /// R2 bucket (or equivalent) and updates this string. The URL is
  /// visible in the APK so hosting must be free-tier-friendly.
  ///
  /// SMOKE-TEST DEFAULT (Session 62): whisper-tiny (~151 MB) is used
  /// to validate the download + progress + sanity-check pipeline
  /// end-to-end BEFORE the real 800 MB Gemma 3 1B file lands in the
  /// R2 bucket. Replace this URL with the real Gemma `.task` file
  /// URL before shipping to end users.
  ///
  /// Real model download URL will be:
  ///   `https://pub-<hash>.r2.dev/gemma-3-1b-it-int4.task`
  static const String modelUrl =
      'https://huggingface.co/openai/whisper-tiny/resolve/main/model.safetensors';

  /// Filename used on disk. Keep stable — the app checks for this
  /// specific name when detecting whether the model is already
  /// downloaded.
  static const String modelFileName = 'gemma_3_1b_it_int4.task';

  /// SharedPreferences key storing the "download completed at" ms
  /// timestamp. Presence + valid file at [_modelFile] path together
  /// mean the model is ready.
  static const String _keyDownloadedAt = 'on_device_model_downloaded_at';

  ModelStatus _status = ModelStatus.notStarted;
  double _progress = 0.0;
  String? _lastError;
  String? _modelFilePath;
  bool _initialized = false;

  ModelStatus get status => _status;
  double get progress => _progress;
  String? get lastError => _lastError;
  bool get isReady => _status == ModelStatus.ready && _modelFilePath != null;
  bool get isConfigured => !modelUrl.endsWith('CONFIGURE_MODEL_URL');

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$modelFileName');
      if (await file.exists()) {
        final size = await file.length();
        // Sanity — a partially-downloaded file might exist but be
        // truncated. Require at least 100 MB to consider it complete.
        if (size > 100 * 1024 * 1024) {
          _modelFilePath = file.path;
          _status = ModelStatus.ready;
          debugPrint(
              'OnDeviceModelService: found ${size ~/ 1024 ~/ 1024} MB model at ${file.path}');
        } else {
          // Stale/partial file — delete so a fresh download starts clean.
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
  }

  /// Start downloading the model. WiFi-only by default; if [allowCellular]
  /// is true the caller has confirmed with the user (data warning).
  Future<void> startDownload({bool allowCellular = false}) async {
    await initialize();
    if (_status == ModelStatus.downloading) return;
    if (!isConfigured) {
      _fail(
          'Model URL is not configured yet. See OnDeviceModelService.modelUrl.');
      return;
    }

    // Check network type.
    final result = await Connectivity().checkConnectivity();
    final onWifi = result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet);
    if (!onWifi && !allowCellular) {
      _status = ModelStatus.awaitingWifi;
      _lastError = 'Connect to WiFi to download the offline AI model '
          '(~800 MB). You can override this and use cellular data '
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

      // Clean up any prior partial download.
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

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
            // Only notify every ~1% so the UI doesn't get hammered.
            if ((_progress * 100).floor() !=
                ((received - chunk.length) / total * 100).floor()) {
              notifyListeners();
            }
          }
          if (_status != ModelStatus.downloading) {
            // User cancelled mid-stream.
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

      // Rename .partial → final. If a previous file existed, replace it.
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await tempFile.rename(finalFile.path);

      _modelFilePath = finalFile.path;
      _status = ModelStatus.ready;
      _progress = 1.0;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _keyDownloadedAt, DateTime.now().millisecondsSinceEpoch);
      notifyListeners();
      debugPrint('OnDeviceModelService: download complete → ${finalFile.path}');
    } catch (e) {
      _fail('Download failed: $e');
    }
  }

  /// User-visible "Cancel download" — safe to call any time.
  void cancelDownload() {
    if (_status == ModelStatus.downloading) {
      _status = ModelStatus.notStarted;
      _progress = 0.0;
      notifyListeners();
    }
  }

  /// Delete the downloaded model to free ~800 MB of storage.
  Future<void> deleteModel() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$modelFileName');
      if (await file.exists()) {
        await file.delete();
      }
      final partial = File('${dir.path}/$modelFileName.partial');
      if (await partial.exists()) {
        await partial.delete();
      }
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
  // Phase C3 — flutter_gemma inference
  // ============================================================

  InferenceModel? _inferenceModel;
  bool _inferenceLoaded = false;
  bool _inferenceLoadFailed = false;

  Future<String?> generateEnglishSentence({
    required String word,
    required String category,
    String level = 'beginner',
  }) async {
    if (!isReady) return null;
    final ready = await _ensureInferenceLoaded();
    if (!ready || _inferenceModel == null) return null;

    try {
      final prompt = 'Write a short, simple English sentence (5-8 words) '
          'that naturally uses the word "$word". '
          'Category: $category. Level: $level. '
          'Reply with only the sentence — no quotes, no explanation.';

      final session = await _inferenceModel!.createSession(
        temperature: 0.7,
        topK: 40,
      );
      try {
        await session.addQueryChunk(Message.text(text: prompt, isUser: true));
        final response = await session.getResponse();
        var cleaned = response.trim();
        while (cleaned.startsWith('"') || cleaned.startsWith("'")) {
          cleaned = cleaned.substring(1);
        }
        while (cleaned.endsWith('"') || cleaned.endsWith("'")) {
          cleaned = cleaned.substring(0, cleaned.length - 1);
        }
        cleaned = cleaned.trim();
        if (cleaned.isEmpty) return null;
        return cleaned;
      } finally {
        try {
          await session.close();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('OnDeviceModelService generation failed: $e');
      return null;
    }
  }

  Future<bool> _ensureInferenceLoaded() async {
    if (_inferenceLoaded) return true;
    if (_inferenceLoadFailed) return false;
    if (_modelFilePath == null) return false;

    try {
      final gemma = FlutterGemmaPlugin.instance;
      await gemma.modelManager.setModelPath(_modelFilePath!);
      _inferenceModel = await gemma.createModel(
        modelType: ModelType.gemmaIt,
        preferredBackend: PreferredBackend.cpu,
        maxTokens: 256,
      );
      _inferenceLoaded = true;
      debugPrint('OnDeviceModelService: inference model loaded');
      notifyListeners();
      return true;
    } catch (e) {
      _inferenceLoadFailed = true;
      debugPrint('OnDeviceModelService inference load failed: $e');
      notifyListeners();
      return false;
    }
  }

  bool get isInferenceReady =>
      _status == ModelStatus.ready && _inferenceLoaded && _inferenceModel != null;

  void _fail(String msg) {
    _status = ModelStatus.failed;
    _lastError = msg;
    _progress = 0.0;
    debugPrint('OnDeviceModelService failed: $msg');
    notifyListeners();
  }
}
