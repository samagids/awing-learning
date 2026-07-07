import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Gates the Phase C on-device Gemma 3 1B model.
///
/// The model needs ~1.2 GB RAM to load and run comfortably. Low-end
/// phones common in Cameroon (Tecno, Redmi, Samsung A-series) often
/// ship with 2-3 GB total, of which the OS eats ~600-800 MB. Trying to
/// run Gemma on those devices either OOMs or slows everything else
/// down to a crawl.
///
/// This service reads memory info from the native platform channel
/// (`com.awing.learning/device_capability`) and exposes:
///
///   • [totalRamMb] — device's physical RAM
///   • [availableRamMb] — currently free RAM (Android only; iOS returns
///                        total)
///   • [isEligibleForOnDeviceModel] — true if device passes the RAM gate
///   • [reasonIneligible] — human-readable message if not eligible
///
/// The AI toggle service consults this before allowing the on-device
/// path. If ineligible, on-device mode falls back to dictionary-only
/// gloss (which works on any device with zero extra RAM).
class DeviceCapabilityService extends ChangeNotifier {
  static const _channel = MethodChannel('com.awing.learning/device_capability');

  /// Minimum total RAM required to enable the on-device model.
  /// Gemma 3 1B fp16 needs ~1.5 GB active memory; Q4 quantized needs
  /// ~1.0 GB. We require 3 GB total to leave headroom for the OS + other
  /// apps + the model's context window.
  static const int minTotalRamMb = 3000;

  /// Minimum available RAM at load time. If free memory dips below
  /// this we refuse to load the model even if eligibility was granted
  /// at app start.
  static const int minAvailableRamMb = 1200;

  int _totalRamMb = 0;
  int _availableRamMb = 0;
  bool _lowMemory = false;
  bool _initialized = false;
  String? _initError;

  int get totalRamMb => _totalRamMb;
  int get availableRamMb => _availableRamMb;
  bool get lowMemory => _lowMemory;
  bool get initialized => _initialized;
  String? get initError => _initError;

  /// True if this device passes both the total-RAM and available-RAM
  /// thresholds to run Gemma 3 1B on-device.
  bool get isEligibleForOnDeviceModel {
    if (!_initialized) return false;
    if (_totalRamMb < minTotalRamMb) return false;
    if (_availableRamMb < minAvailableRamMb) return false;
    if (_lowMemory) return false;
    return true;
  }

  /// Human-readable reason the device isn't eligible, or null if it is.
  String? get reasonIneligible {
    if (!_initialized) {
      return _initError != null
          ? 'Could not read device memory: $_initError'
          : 'Checking device capabilities...';
    }
    if (_totalRamMb < minTotalRamMb) {
      return 'This device has ${_gb(_totalRamMb)} GB total RAM. '
          'Offline AI needs at least ${_gb(minTotalRamMb)} GB.';
    }
    if (_availableRamMb < minAvailableRamMb) {
      return 'Only ${_availableRamMb} MB RAM is currently free. '
          'Close other apps and try again.';
    }
    if (_lowMemory) {
      return 'Device is low on memory right now. '
          'Close other apps and try again.';
    }
    return null;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('getMemoryInfo');
      if (result != null) {
        _totalRamMb = (result['totalRamMb'] as num?)?.toInt() ?? 0;
        _availableRamMb = (result['availableRamMb'] as num?)?.toInt() ?? 0;
        _lowMemory = (result['lowMemory'] as bool?) ?? false;
        _initialized = true;
        debugPrint(
            'DeviceCapability: total=${_totalRamMb} MB, avail=${_availableRamMb} MB, low=$_lowMemory, eligible=$isEligibleForOnDeviceModel');
      }
    } catch (e) {
      _initError = e.toString();
      _initialized = true; // still mark ready so UI unblocks
      debugPrint('DeviceCapability init failed: $e');
    }
    notifyListeners();
  }

  /// Refresh available RAM. Call this right before trying to load the
  /// model — free memory can change dramatically between app start and
  /// the user's first use of offline AI.
  Future<void> refresh() async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('getMemoryInfo');
      if (result != null) {
        _availableRamMb = (result['availableRamMb'] as num?)?.toInt() ?? _availableRamMb;
        _lowMemory = (result['lowMemory'] as bool?) ?? false;
        notifyListeners();
      }
    } catch (_) {}
  }

  String _gb(int mb) => (mb / 1024).toStringAsFixed(1);
}
