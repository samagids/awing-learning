import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:awing_ai_learning/services/device_capability_service.dart';
import 'package:awing_ai_learning/services/on_device_model_service.dart';

/// Phase C — Offline AI settings + eligibility check.
///
/// The on-device TinyLlama model needs ~1.2 GB RAM to run. Many
/// budget phones common in Cameroon have 2-3 GB total. We check the
/// device's actual RAM before allowing the download, so users on
/// underpowered phones never see a crash — they just get a friendly
/// "your device isn't ready for Offline AI" message.
///
/// Download flow (Phase C2):
///   • On WiFi: silent download starts immediately.
///   • On mobile data: shows a data-cost warning first ("this will use
///     ~500 MB of your mobile data plan"); user has to explicitly
///     confirm before the download starts. This matters because most
///     Awing-speaking users in Cameroon don't have reliable WiFi and
///     mobile data is metered, but we still want to give them the
///     choice rather than refuse to download.
///   • No connection: friendly snackbar prompt.
class OfflineAISettingsScreen extends StatelessWidget {
  const OfflineAISettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline AI')),
      body: Consumer<DeviceCapabilityService>(
        builder: (context, device, _) {
          if (!device.initialized) {
            return const Center(child: CircularProgressIndicator());
          }
          final eligible = device.isEligibleForOnDeviceModel;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _statusHeader(context, device, eligible),
              const SizedBox(height: 16),
              _memoryCard(context, device),
              const SizedBox(height: 16),
              _downloadCard(context, device, eligible),
              const SizedBox(height: 16),
              _explanationCard(context),
            ],
          );
        },
      ),
    );
  }

  Widget _statusHeader(BuildContext context, DeviceCapabilityService d, bool eligible) {
    final color = eligible ? Colors.green : Colors.orange;
    final icon = eligible ? Icons.check_circle : Icons.warning;
    final label = eligible
        ? 'Your device can run Offline AI'
        : 'Your device is not ready for Offline AI';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color.shade700, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color.shade900,
                  ),
                ),
                if (!eligible && d.reasonIneligible != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    d.reasonIneligible!,
                    style: TextStyle(fontSize: 13, color: color.shade900),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _memoryCard(BuildContext context, DeviceCapabilityService d) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.memory, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Device memory',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => d.refresh(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _row('Total RAM',
                '${(d.totalRamMb / 1024).toStringAsFixed(1)} GB (${d.totalRamMb} MB)'),
            _row('Available RAM',
                '${(d.availableRamMb / 1024).toStringAsFixed(1)} GB (${d.availableRamMb} MB)'),
            _row('Low memory mode',
                d.lowMemory ? 'YES — device is under memory pressure' : 'No'),
            const Divider(height: 24),
            Text(
              'Requirements: '
              '${(DeviceCapabilityService.minTotalRamMb / 1024).toStringAsFixed(1)} GB total, '
              '${DeviceCapabilityService.minAvailableRamMb} MB free.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _downloadCard(BuildContext context, DeviceCapabilityService d, bool eligible) {
    if (!eligible) {
      return Card(
        color: Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.download_for_offline_outlined,
                  color: Colors.grey.shade500, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Offline AI download is disabled on this device.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Consumer<OnDeviceModelService>(
      builder: (context, model, _) {
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_iconForStatus(model.status),
                        color: _colorForStatus(model.status)),
                    const SizedBox(width: 8),
                    Text(
                      _titleForStatus(model.status),
                      style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _subtitleForStatus(model),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                _downloadActions(context, model),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _iconForStatus(ModelStatus s) {
    switch (s) {
      case ModelStatus.ready:
        return Icons.check_circle;
      case ModelStatus.downloading:
        return Icons.downloading;
      case ModelStatus.awaitingWifi:
        return Icons.wifi_off;
      case ModelStatus.failed:
        return Icons.error_outline;
      case ModelStatus.notStarted:
        return Icons.download;
    }
  }

  Color _colorForStatus(ModelStatus s) {
    switch (s) {
      case ModelStatus.ready:
        return Colors.green.shade700;
      case ModelStatus.downloading:
        return Colors.blue.shade700;
      case ModelStatus.awaitingWifi:
        return Colors.orange.shade700;
      case ModelStatus.failed:
        return Colors.red.shade700;
      case ModelStatus.notStarted:
        return Colors.blue.shade700;
    }
  }

  String _titleForStatus(ModelStatus s) {
    switch (s) {
      case ModelStatus.ready:
        return 'Offline AI is ready';
      case ModelStatus.downloading:
        return 'Downloading offline AI…';
      case ModelStatus.awaitingWifi:
        return 'Waiting for WiFi';
      case ModelStatus.failed:
        return 'Download failed';
      case ModelStatus.notStarted:
        return 'Download Offline AI';
    }
  }

  String _subtitleForStatus(OnDeviceModelService m) {
    switch (m.status) {
      case ModelStatus.ready:
        return 'The offline AI language model model is on your device. Offline AI features '
            'will work without an internet connection.';
      case ModelStatus.downloading:
        final pct = (m.progress * 100).toStringAsFixed(0);
        return 'Downloading offline AI language model (~500 MB). $pct% done. '
            'You can use the app while it downloads.';
      case ModelStatus.awaitingWifi:
        return m.lastError ??
            'Connect to WiFi (recommended) or tap again to use mobile data.';
      case ModelStatus.failed:
        return m.lastError ?? 'Something went wrong. Please try again.';
      case ModelStatus.notStarted:
        return 'Downloads the offline AI language model language model (~500 MB, one-time). '
            'WiFi is recommended, but mobile data works too — you\'ll get '
            'a warning about data cost first. Runs in the background.';
    }
  }

  /// Detect current connection type and start the download. On WiFi we
  /// start silently. On mobile data we show a data-cost warning first —
  /// the user has to explicitly confirm before ~500 MB gets pulled over
  /// their data plan.
  Future<void> _startDownloadFlow(
      BuildContext context, OnDeviceModelService m) async {
    final result = await Connectivity().checkConnectivity();
    final onWifi = result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet);
    final onMobile = result.contains(ConnectivityResult.mobile);

    if (onWifi) {
      // Silent WiFi download — no warning needed.
      await m.startDownload();
      return;
    }
    if (onMobile) {
      final confirm = await _showMobileDataWarning(context);
      if (confirm == true) {
        await m.startDownload(allowCellular: true);
      }
      return;
    }
    // No connection at all.
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection. Connect to WiFi or '
              'mobile data first.'),
        ),
      );
    }
  }

  Future<bool?> _showMobileDataWarning(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(child: Text('Use mobile data?')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'You\'re not on WiFi. Downloading Offline AI will use about '
              '500 MB of your mobile data plan.',
              style: TextStyle(fontSize: 15),
            ),
            SizedBox(height: 12),
            Text(
              'Recommended: wait until you\'re on WiFi.\n\n'
              'If you have a good data plan, you can continue now. This '
              'is a one-time download — after that, Offline AI works '
              'with no data at all.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Wait for WiFi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Use mobile data'),
          ),
        ],
      ),
    );
  }

  Widget _downloadActions(BuildContext context, OnDeviceModelService m) {
    switch (m.status) {
      case ModelStatus.notStarted:
      case ModelStatus.awaitingWifi:
      case ModelStatus.failed:
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: m.isConfigured ? () => _startDownloadFlow(context, m) : null,
            icon: const Icon(Icons.download),
            label: Text(m.isConfigured
                ? 'Download offline AI (~500 MB)'
                : 'Not configured yet'),
          ),
        );
      case ModelStatus.downloading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: m.progress > 0 ? m.progress : null,
              backgroundColor: Colors.blue.shade50,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: m.cancelDownload,
                icon: const Icon(Icons.stop_circle),
                label: const Text('Cancel download'),
              ),
            ),
          ],
        );
      case ModelStatus.ready:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Offline AI?'),
                  content: const Text(
                      'This frees ~500 MB of storage. You can download it '
                      'again later when you have WiFi.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await m.deleteModel();
              }
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete model to free space'),
          ),
        );
    }
  }

  Widget _explanationCard(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'What is Offline AI?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Offline AI lets Cloud AI features (generating example '
              'sentences, translating with the AI toggle ON) work '
              'without an internet connection. It uses a small language '
              'model that runs on your device.\n\n'
              'The app checks your device\'s memory first to make sure '
              'the model can run smoothly. Devices with less than '
              '${(DeviceCapabilityService.minTotalRamMb / 1024).toStringAsFixed(1)} GB '
              'RAM would crash or slow down — so we don\'t offer the '
              'download on those.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
