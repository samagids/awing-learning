import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/services/ai_toggle_service.dart';
import 'package:awing_ai_learning/screens/settings/offline_ai_settings_screen.dart';

/// A reusable Cloud ↔ On-device toggle widget.
///
/// Used at the top of AI feature pages (Translate, Word of the Day, etc.)
/// and in Settings. State lives in [AIToggleService] via Provider.
///
/// The FIRST time a user flips from On-device → Cloud, a data-usage dialog
/// is shown explaining the tradeoff. After that, only a small banner
/// [CloudDataBanner] reminds them cloud is active.
class AIModeToggle extends StatelessWidget {
  /// If true, renders as a compact pill at the top of a screen.
  /// If false, renders as a full-width Settings-style tile.
  final bool compact;

  const AIModeToggle({Key? key, this.compact = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AIToggleService>(
      builder: (context, toggle, _) {
        if (compact) return _buildCompact(context, toggle);
        return _buildFull(context, toggle);
      },
    );
  }

  Widget _buildCompact(BuildContext context, AIToggleService toggle) {
    final on = toggle.cloudEnabled;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: on ? Colors.blue.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: on ? Colors.blue.shade200 : Colors.green.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            on ? Icons.cloud : Icons.smartphone,
            size: 20,
            color: on ? Colors.blue.shade700 : Colors.green.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            on ? 'Cloud AI' : 'On-device AI',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: on ? Colors.blue.shade900 : Colors.green.shade900,
            ),
          ),
          const SizedBox(width: 4),
          Switch(
            value: on,
            activeColor: Colors.blue.shade700,
            onChanged: (v) => _handleChange(context, toggle, v),
          ),
          IconButton(
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            tooltip: 'Offline AI settings',
            icon: Icon(Icons.info_outline,
                color: on ? Colors.blue.shade700 : Colors.green.shade700),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OfflineAISettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFull(BuildContext context, AIToggleService toggle) {
    final on = toggle.cloudEnabled;
    return Card(
      margin: const EdgeInsets.all(12),
      child: ListTile(
        leading: Icon(
          on ? Icons.cloud : Icons.smartphone,
          color: on ? Colors.blue.shade700 : Colors.green.shade700,
          size: 32,
        ),
        title: Text(
          on ? 'Cloud AI' : 'On-device AI',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          on
              ? 'Higher quality answers, uses internet data.'
              : 'Free — works offline, no internet data used.',
          style: const TextStyle(fontSize: 13),
        ),
        trailing: Switch(
          value: on,
          activeColor: Colors.blue.shade700,
          onChanged: (v) => _handleChange(context, toggle, v),
        ),
      ),
    );
  }

  Future<void> _handleChange(
    BuildContext context,
    AIToggleService toggle,
    bool newValue,
  ) async {
    // Turning OFF — just do it.
    if (!newValue) {
      await toggle.setCloudEnabled(false);
      return;
    }
    // Turning ON for the first time → show the data-usage dialog.
    if (!toggle.firstCloudDialogShown) {
      final proceed = await _showFirstFlipDialog(context);
      if (!proceed) return; // user cancelled — leave toggle OFF
      await toggle.markFirstCloudDialogShown();
    }
    await toggle.setCloudEnabled(true);
  }

  Future<bool> _showFirstFlipDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.cloud, color: Colors.blue),
            SizedBox(width: 8),
            Text('Turn on Cloud AI?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Cloud AI gives better answers for long sentences and '
              'creative tasks — but every question uses a small amount '
              'of your internet data.',
              style: TextStyle(fontSize: 15),
            ),
            SizedBox(height: 12),
            Text(
              'How much data?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text(
              '• About 5–10 KB per question\n'
              '• 100 questions ≈ 1 MB of data',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              'You can turn it back OFF anytime.',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Turn on Cloud AI'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

/// Persistent banner shown at the top of AI feature pages when the
/// Cloud toggle is ON. Reminds the user that data is being used.
/// Non-dismissible — only goes away when the user turns Cloud OFF.
class CloudDataBanner extends StatelessWidget {
  const CloudDataBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AIToggleService>(
      builder: (context, toggle, _) {
        if (!toggle.cloudEnabled) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              Icon(Icons.cloud, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Using Cloud AI — every question uses internet data (~5 KB each).',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
