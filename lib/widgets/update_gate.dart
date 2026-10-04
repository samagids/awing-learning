import 'package:flutter/material.dart';

import 'package:awing_ai_learning/screens/about_screen.dart';
import 'package:awing_ai_learning/services/app_update_service.dart';

/// Wraps the app and surfaces update prompts.
///
/// Session 64b. Two behaviours, deliberately very different in weight:
///
///   • shouldSuggestUpdate → a dismissible dialog, shown at most once every
///     few days. "Later" is always available.
///   • mustUpdate → a full blocking screen with no way past it.
///
/// Both are driven entirely by AppUpdateService, which fails open: if the
/// config could not be read (offline, timeout, permission), NEITHER fires
/// and the child renders untouched. That is the property that keeps an
/// offline child in Cameroon out of a dead end.
class UpdateGate extends StatefulWidget {
  const UpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> with WidgetsBindingObserver {
  final _service = AppUpdateService.instance;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service.addListener(_onServiceChanged);
    // Fire and forget — never blocks first paint.
    WidgetsBinding.instance.addPostFrameCallback((_) => _service.check());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check on resume: catches the case where a release goes out while
    // the app sits backgrounded for days. Throttled inside the service.
    if (state == AppLifecycleState.resumed) {
      _service.check();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (!mounted) return;
    setState(() {});
    if (_service.shouldSuggestUpdate && !_dialogOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrompt());
    }
  }

  Future<void> _maybePrompt() async {
    if (!mounted || _dialogOpen || !_service.shouldSuggestUpdate) return;
    _dialogOpen = true;
    // Snooze FIRST. If the user backgrounds the app instead of answering,
    // we still respect the cooldown rather than re-prompting on next launch.
    await _service.snoozePrompt();
    if (!mounted) {
      _dialogOpen = false;
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.system_update, size: 32),
        title: const Text('A newer version is available'),
        content: Text(
          _service.message ??
              'Update to get the latest Awing words, voices and fixes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _startUpdate();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
    _dialogOpen = false;
  }

  /// Prefer Play's native in-app flow on Android; fall back to the store
  /// listing everywhere else (and whenever the native flow is unavailable,
  /// which is normal for sideloaded or bundletool builds).
  Future<void> _startUpdate() async {
    final handled = await _service.tryAndroidFlexibleUpdate();
    if (!handled) {
      await _service.openStore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_service.mustUpdate) {
      return _BlockingUpdateScreen(
        message: _service.message,
        currentBuild: _service.currentBuild,
        requiredBuild: _service.minSupportedBuild,
        onUpdate: _startUpdate,
      );
    }
    return widget.child;
  }
}

class _BlockingUpdateScreen extends StatelessWidget {
  const _BlockingUpdateScreen({
    required this.message,
    required this.currentBuild,
    required this.requiredBuild,
    required this.onUpdate,
  });

  final String? message;
  final int currentBuild;
  final int requiredBuild;
  final Future<void> Function() onUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // NOTE: no MaterialApp here. UpdateGate is installed as the `home:` of
    // the app's existing MaterialApp, so this renders inside it and
    // inherits theme, locale and navigator. Nesting a second MaterialApp
    // would create a detached Navigator and break back handling.
    return PopScope(
        canPop: false,
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.system_update, size: 72),
                    const SizedBox(height: 24),
                    Text(
                      'Please update Awing',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message ??
                          'This version of Awing Learning is no longer '
                              'supported. Please update to keep learning.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => onUpdate(),
                      icon: const Icon(Icons.download),
                      label: const Text('Update now'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(220, 52),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'You have version ${AboutScreen.appVersion} '
                      '(build $currentBuild).\n'
                      'Build $requiredBuild or newer is required.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }
}
