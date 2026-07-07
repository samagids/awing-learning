import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global toggle between on-device AI and cloud AI.
///
/// Default: OFF (on-device).
///   - On-device = offline retrieval + dictionary lookup (Phase A)
///     Later: falls back to on-device LLM (Gemma 3 1B) once Phase C ships.
///   - Cloud = CloudFlare Workers AI (Phase B, uses internet data).
///
/// Applies globally to ALL AI features: translation, Word of the Day,
/// grade-my-attempt, story generation, and every future AI use case.
/// One toggle to rule them all — set in Settings, quick-switched from
/// the Translate page.
///
/// The `firstCloudDialogShown` flag tracks whether the user has already
/// seen the "Cloud AI uses internet data" dialog. It's shown once when
/// they first flip to Cloud, then a persistent banner replaces it on
/// AI feature pages (translation, etc.).
class AIToggleService extends ChangeNotifier {
  static const String _keyCloudEnabled = 'ai_cloud_enabled';
  static const String _keyFirstCloudDialogShown = 'ai_first_cloud_dialog_shown';

  bool _cloudEnabled = false;
  bool _firstCloudDialogShown = false;
  bool _initialized = false;

  /// Whether cloud AI is enabled. Default: false (on-device).
  bool get cloudEnabled => _cloudEnabled;

  /// Convenience opposite of cloudEnabled.
  bool get onDeviceEnabled => !_cloudEnabled;

  /// Whether the one-time "Cloud AI uses data" dialog has been shown.
  bool get firstCloudDialogShown => _firstCloudDialogShown;

  bool get initialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cloudEnabled = prefs.getBool(_keyCloudEnabled) ?? false;
      _firstCloudDialogShown =
          prefs.getBool(_keyFirstCloudDialogShown) ?? false;
    } catch (e) {
      debugPrint('AIToggleService init failed: $e');
    }
    _initialized = true;
    notifyListeners();
  }

  /// Set cloud enabled/disabled. Persists immediately.
  Future<void> setCloudEnabled(bool enabled) async {
    if (_cloudEnabled == enabled) return;
    _cloudEnabled = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyCloudEnabled, enabled);
    } catch (e) {
      debugPrint('AIToggleService setCloudEnabled persist failed: $e');
    }
  }

  /// Mark the first-flip dialog as having been shown so it doesn't fire
  /// again. Called from the dialog's "Continue" handler.
  Future<void> markFirstCloudDialogShown() async {
    if (_firstCloudDialogShown) return;
    _firstCloudDialogShown = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyFirstCloudDialogShown, true);
    } catch (e) {
      debugPrint(
          'AIToggleService markFirstCloudDialogShown persist failed: $e');
    }
  }

  /// For testing / dev reset.
  Future<void> resetForTesting() async {
    _cloudEnabled = false;
    _firstCloudDialogShown = false;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyCloudEnabled);
      await prefs.remove(_keyFirstCloudDialogShown);
    } catch (e) {
      debugPrint('AIToggleService reset failed: $e');
    }
  }
}
