import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/components/awing_keyboard.dart';
import 'package:awing_ai_learning/services/awing_keyboard_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:awing_ai_learning/modules/beginner/beginner_module.dart';
import 'package:awing_ai_learning/screens/home_screen.dart';
import 'package:awing_ai_learning/widgets/update_gate.dart';
import 'package:awing_ai_learning/screens/auth/login_screen.dart';
import 'package:awing_ai_learning/screens/auth/profile_select_screen.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/analytics_service.dart';
import 'package:awing_ai_learning/services/contribution_service.dart';
import 'package:awing_ai_learning/services/parent_notification_service.dart';
import 'package:awing_ai_learning/services/progress_service.dart';
import 'package:awing_ai_learning/services/cloud_backup_service.dart';
import 'package:awing_ai_learning/services/recordings_service.dart';
import 'package:awing_ai_learning/services/image_service.dart';
import 'package:awing_ai_learning/services/native_audio_inventory.dart';
import 'package:awing_ai_learning/services/notification_service.dart';
import 'package:awing_ai_learning/services/fcm_service.dart';
import 'package:awing_ai_learning/services/vocab_embeddings.dart';
import 'package:awing_ai_learning/services/ai_toggle_service.dart';
import 'package:awing_ai_learning/services/device_capability_service.dart';
import 'package:awing_ai_learning/services/on_device_model_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async' show unawaited;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase under a 10s timeout. On iOS we've seen the iPhone
  // hang on a blank white screen here when the network is flaky or
  // Firestore takes too long to bootstrap — without timeout protection,
  // the entire app launch is stuck before runApp() is ever called and
  // the user sees nothing but the launch screen forever. Fall back to a
  // degraded-mode launch (cloud sync becomes a no-op, local features
  // still work) rather than blocking.
  try {
    await Firebase.initializeApp().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        // Re-throw as a regular exception so the catch block runs.
        throw Exception('Firebase.initializeApp timed out after 10s');
      },
    );
  } catch (e, st) {
    debugPrint('Firebase init failed: $e\n$st');
    // Continue without Firebase — auth + cloud sync will degrade to local.
  }

  // Session 61 — V3+G10 security hardening (ACTIVATED).
  //
  // Firebase App Check: every request to Firebase services (Firestore,
  // Auth, future Storage) carries a per-request attestation token proving
  // it came from this app on a non-tampered device. The token is minted
  // by Play Integrity API on Android, App Attest on iOS 14+ (falling back
  // to DeviceCheck on older iOS).
  //
  // Console setup confirmed (verified 2026-05-25):
  //   • Android app "Awing AI Learning" (com.awing.learning) → Play Integrity → Registered
  //   • iOS app "Awing AI Learning iOS" (com.awing.awingAiLearning) → App Attest → Registered
  //   • Cloud Firestore: Unenforced (collecting metrics)
  //   • Authentication: Unenforced (collecting metrics)
  //   • Release keystore SHA-256 already in Project Settings: 6E:11:9D:26:BC:BE:...
  //
  // Enforcement plan: ship v1.13.0 with App Check enabled in unenforced mode.
  // Monitor Firebase Console → App Check → APIs → Cloud Firestore for the
  // "Verified requests %" metric. Once it stabilizes above 99% (typically 1
  // week of real-world traffic), flip the Enforce toggle on Firestore AND
  // Authentication. From that point, any non-attested request fails closed.
  //
  // Debug builds use the DEBUG provider which prints a token to logcat on
  // first launch. To use a debug build during dev: copy the token from
  // logcat and add it under App Check → Manage debug tokens.
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.appAttestWithDeviceCheckFallback,
    ).timeout(
      const Duration(seconds: 5),
      onTimeout: () =>
          debugPrint('App Check activate timed out — continuing'),
    );
  } catch (e) {
    debugPrint('App Check activate failed: $e');
    // Continue without App Check. Firestore calls will still work in
    // unenforced mode; once enforcement is flipped on the server, they
    // will start failing with permission-denied for unattested clients.
  }

  // Set global audio context so all audio plays on the MUSIC stream.
  // This ensures device volume buttons control app audio volume.
  try {
    final AudioContext audioContext = AudioContext(
      android: AudioContextAndroid(
        audioMode: AndroidAudioMode.normal,
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {AVAudioSessionOptions.mixWithOthers},
      ),
    );
    AudioPlayer.global.setAudioContext(audioContext);
  } catch (e) {
    debugPrint('AudioContext setup failed: $e');
  }

  // Analytics init also wrapped — it can make a network call to flush
  // queued events on startup, which can hang if the webhook endpoint
  // is slow.
  try {
    await AnalyticsService.instance.initialize().timeout(
      const Duration(seconds: 5),
      onTimeout: () => debugPrint('Analytics init timed out — continuing'),
    );
  } catch (e) {
    debugPrint('Analytics init failed: $e');
  }

  // Session 61c — load the image manifest so games / quizzes / exams can
  // synchronously filter their vocab selection to entries with a
  // bundled illustration. Without this, rounds occasionally surface
  // words whose tile renders as the green "missing image" placeholder.
  // The manifest is ~200 KB JSON, loads in ~50ms from the main bundle.
  try {
    await ImageService.instance.initialize().timeout(
      const Duration(seconds: 3),
      onTimeout: () => debugPrint('ImageService manifest init timed out'),
    );
  } catch (e) {
    debugPrint('ImageService manifest init failed: $e');
  }

  // v1.13.4 — load the native audio inventory so the Dev Mode Record tab
  // can show per-item per-recorder status badges and power the "Missing
  // from [active recorder]" filter. Tiny JSON (<50 KB typical), loads in
  // a few ms. Safe to fail: queries return empty/false, badges just
  // don't render until next build.
  try {
    await NativeAudioInventory.instance.load().timeout(
      const Duration(seconds: 2),
      onTimeout: () =>
          debugPrint('NativeAudioInventory load timed out'),
    );
  } catch (e) {
    debugPrint('NativeAudioInventory load failed: $e');
  }

  // v1.15.0 — Initialize local-notifications plugin so the daily-word
  // suggestion notification can fire even when the app isn't running.
  // Safe to fail: feature is opt-in via Daily Words settings card, and
  // a failed init just means notifications won't schedule (the in-app
  // Today's Words screen still works).
  try {
    await NotificationService.instance.initialize().timeout(
      const Duration(seconds: 3),
      onTimeout: () => debugPrint('NotificationService init timed out'),
    );
    // v1.22.3 (Session 68): AlarmManager scheduling is GONE. Local
    // scheduled alarms drop silently on Samsung/Xiaomi/Oppo/Huawei
    // (Session 67 postmortem: 3-day silence on S24 Ultra even with
    // exact alarms + battery-opt bypass + rationale dialog).
    // Daily reminders are now Firebase Cloud Messaging PUSH — sent
    // server-side by scripts/fcm_daily_push.gs at 08:00 and 19:00
    // WAT, delivered to devices via Google Play Services (bypasses
    // Doze / App Standby / battery optimization — same architecture
    // WhatsApp uses). NotificationService.initialize() is retained
    // so the "Send preview now" button on Daily Words still works
    // (immediate notifications via flutter_local_notifications are
    // reliable — only scheduled ones are the problem).
  } catch (e) {
    debugPrint('NotificationService init failed: $e');
  }

  // v1.22.3 (Session 68): initialize FCM. Requests POST_NOTIFICATIONS
  // permission (Android 13+) / iOS alert permission, fetches the
  // device FCM token, saves it to Firestore users/{email}/data/settings
  // so the daily-push Apps Script cron can reach this device.
  // Idempotent and cheap (~200 ms first launch, ~20 ms after).
  try {
    await FcmService.instance.initialize().timeout(
      const Duration(seconds: 5),
      onTimeout: () => debugPrint('FcmService init timed out'),
    );
  } catch (e) {
    debugPrint('FcmService init failed: $e');
  }

  // v1.16.0 — Background load of the precomputed vocab embeddings.
  // Fire-and-forget: the daily suggester checks `isLoaded` at scoring
  // time and gracefully falls back to rules-only if the blob isn't
  // ready yet or the PAD pack is missing it. Doesn't block app start.
  // The full sentence-transformer model itself (43 MB) is loaded
  // LAZILY only when explicitly requested (e.g. "Find similar words"
  // button). Most kids will never need it; the embeddings blob is
  // enough for the daily-suggester semantic boost.
  unawaited(VocabEmbeddings.instance.load().catchError((e) {
    debugPrint('VocabEmbeddings load failed (non-fatal): $e');
  }));

  runApp(const AwingApp());
}

/// ThemeNotifier manages light/dark mode theme switching with persistence.
///
/// NOTE: Dark mode is temporarily disabled in v1.2.1 because many screens
/// have hardcoded colors that become invisible on dark backgrounds. The
/// toggle is a no-op until we complete a full dark-mode color audit. The
/// getter always returns `false` so the UI shows the light-mode icon.
class ThemeNotifier extends ChangeNotifier {
  // ignore: unused_field
  static const String _themeKey = 'isDarkMode';

  bool get isDarkMode => false;

  /// Initialize — no-op while dark mode is disabled.
  Future<void> initialize() async {}

  /// Toggle — no-op while dark mode is disabled.
  Future<void> toggle() => toggleTheme();

  Future<void> toggleTheme() async {
    // Dark mode is disabled until full color audit is complete.
    notifyListeners();
  }

  /// Get light theme
  // Awing brand colors — inspired by Cameroon Grassfields & Toghu cloth
  static const Color awingGreen = Color(0xFF006432);       // Deep forest green (Mezam highlands)
  static const Color awingGold = Color(0xFFDAA520);         // Gold (Toghu cloth / royalty)
  static const Color awingAmber = Color(0xFFF5AF19);        // Warm amber (Cameroon sun)
  static const Color awingDarkGreen = Color(0xFF004623);    // Darker green for depth
  static const Color awingCream = Color(0xFFFFF8E6);        // Warm cream

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      primarySwatch: Colors.green,
      brightness: Brightness.light,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: awingCream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: awingGreen,
        brightness: Brightness.light,
        primary: awingGreen,
        secondary: awingGold,
        tertiary: awingAmber,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFFE8F5E9),
        foregroundColor: awingDarkGreen,
      ),
      cardColor: Colors.white,
      dividerColor: Colors.grey.shade300,
      textTheme: TextTheme(
        bodyLarge: const TextStyle(color: Colors.black87),
        bodyMedium: const TextStyle(color: Colors.black87),
        bodySmall: const TextStyle(color: Colors.black87),
        titleLarge: TextStyle(color: awingDarkGreen),
        titleMedium: TextStyle(color: awingDarkGreen),
        titleSmall: const TextStyle(color: Colors.black87),
      ),
      iconTheme: IconThemeData(color: awingDarkGreen),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: awingGreen,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  /// Get dark theme — used by MaterialApp
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      primarySwatch: Colors.green,
      brightness: Brightness.dark,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      colorScheme: ColorScheme.fromSeed(
        seedColor: awingGreen,
        brightness: Brightness.dark,
        primary: const Color(0xFF4CAF50),
        secondary: awingGold,
        tertiary: awingAmber,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFF1E2E1E),
        foregroundColor: Colors.grey.shade100,
      ),
      cardColor: const Color(0xFF252525),
      dividerColor: Colors.grey.shade700,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.grey.shade100),
        bodyMedium: TextStyle(color: Colors.grey.shade100),
        bodySmall: TextStyle(color: Colors.grey.shade200),
        titleLarge: const TextStyle(color: Color(0xFF81C784)),
        titleMedium: const TextStyle(color: Color(0xFF81C784)),
        titleSmall: TextStyle(color: Colors.grey.shade200),
      ),
      iconTheme: IconThemeData(color: Colors.grey.shade100),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

class AwingApp extends StatelessWidget {
  const AwingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()..initialize()),
        ChangeNotifierProvider(create: (_) => BeginnerModule()),
        ChangeNotifierProvider(
          create: (_) => ProgressService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => ContributionService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => CloudBackupService()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => RecordingsService()..initialize(),
        ),
        // Session 63 — Global AI toggle. Default OFF (on-device).
        // Applies to translation, Word of the Day, and all future AI features.
        ChangeNotifierProvider(
          create: (_) => AIToggleService()..initialize(),
        ),
        // Session 63 Phase C — RAM check for on-device Gemma 3 1B.
        // If the device doesn't have enough memory (~3 GB total), the
        // service reports isEligibleForOnDeviceModel=false and offline
        // AI falls back to dictionary-only mode.
        ChangeNotifierProvider(
          create: (_) => DeviceCapabilityService()..initialize(),
        ),
        // Session 63 Phase C2/C3 — Gemma 3 1B model download + inference.
        // Singleton service (OnDeviceModelService.instance) so the same
        // download state survives navigation. .initialize() checks disk
        // for an already-downloaded model file.
        ChangeNotifierProvider.value(
          value: OnDeviceModelService.instance..initialize(),
        ),
        ProxyProvider2<AuthService, ProgressService, ParentNotificationService>(
          update: (_, auth, progress, previous) {
            if (previous != null) return previous;
            final service = ParentNotificationService(
              auth: auth,
              progress: progress,
            )..initialize();
            // Try to send weekly summary on app launch
            service.sendWeeklySummaryIfDue();
            return service;
          },
        ),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, _) {
          return MaterialApp(
            title: 'Awing AI Learning',
            debugShowCheckedModeBanner: false,
            theme: ThemeNotifier.lightTheme(),
            darkTheme: ThemeNotifier.darkTheme(),
            themeMode:
                themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            // Session 64b: UpdateGate sits OUTSIDE _AuthGate on purpose.
            // A user on a retired build must see the update screen even if
            // they cannot get past sign-in, so the gate must not depend on
            // auth state. It fails open when offline, so it costs an
            // offline child nothing.
            home: const UpdateGate(child: _AuthGate()),
            // Awing on-screen keyboard overlay. Renders at the app root
            // so it can float above any screen. Only appears when an
            // AwingTextField gains focus (see AwingKeyboardController).
            builder: (context, child) {
              // Session 64: wrap the app's routes in a SelectionArea so
              // every Text widget becomes tap-and-hold selectable. Users
              // asked for this so they can copy Awing words out of
              // vocabulary, alphabet, stories, sentences, etc. into
              // WhatsApp / notes / a browser search.
              //
              // IMPORTANT (Session 64 bugfix): SelectionArea wraps ONLY
              // the route content, NOT the AwingKeyboard overlay. Wrapping
              // the whole Stack (including the keyboard) routed every key
              // tap through SelectionArea's gesture handling, which
              // stole focus from the AwingTextField and dismissed the
              // keyboard after every letter. Keep the keyboard OUTSIDE
              // SelectionArea so its own onTap gesture recognizers win
              // the arena cleanly.
              return Stack(
                children: [
                  SelectionArea(
                    child: child ?? const SizedBox.shrink(),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AnimatedBuilder(
                      animation: AwingKeyboardController.instance,
                      builder: (context, _) {
                        if (!AwingKeyboardController.instance.isVisible) {
                          return const SizedBox.shrink();
                        }
                        return const AwingKeyboard();
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Authentication gate — routes the user to the appropriate screen based on
/// their auth state: LoginScreen → ProfileSelectScreen → HomeScreen.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _wired = false;
  bool _autoRestoreAttempted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_wired) {
      // Wire auth data changes → cloud backup auto-sync
      final auth = context.read<AuthService>();
      final cloud = context.read<CloudBackupService>();
      auth.onDataChanged = () => cloud.onDataChanged();

      // When cloud restore completes (from login or app launch),
      // refresh ProgressService so XP/streaks/badges are up to date.
      auth.onCloudRestoreComplete = () {
        if (mounted) {
          context.read<ProgressService>().refreshFromPrefs();
          debugPrint('ProgressService refreshed after cloud restore');
        }
      };
      _wired = true;

      // Auto-restore on app launch for returning users who have cloud backup
      _tryAutoRestoreOnLaunch(auth, cloud);
    }
  }

  /// On app launch, if the user is already logged in and has cloud backup
  /// enabled, silently check if cloud has data and restore it. This covers
  /// the case where the user synced from another device.
  Future<void> _tryAutoRestoreOnLaunch(
    AuthService auth,
    CloudBackupService cloud,
  ) async {
    if (_autoRestoreAttempted) return;
    _autoRestoreAttempted = true;

    // Only auto-restore if user already has an account locally AND cloud sync is on
    if (!auth.hasAccount || !cloud.autoSync) return;

    try {
      debugPrint('App launch auto-restore: checking cloud for updates...');
      final ok = await cloud.tryAutoRestore();
      if (ok && mounted) {
        // Reload auth + progress from restored SharedPreferences
        auth.refreshFromPrefs();
        try {
          context.read<ProgressService>().refreshFromPrefs();
        } catch (_) {}
        debugPrint('App launch auto-restore: success, auth + progress refreshed');
      }
    } catch (e) {
      debugPrint('App launch auto-restore error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        // Not logged in → show login screen
        if (!auth.hasAccount) {
          return const LoginScreen();
        }

        // Logged in but no profile selected → show profile picker
        // PIN protection is on the profile select screen itself (for switching)
        // and on sensitive actions (sign out, parent settings) — NOT here.
        // This lets kids open the app and go straight to learning.
        if (!auth.hasProfile) {
          return const ProfileSelectScreen();
        }

        // Fully authenticated → show home (PopScope prevents accidental back-exit)
        return const PopScope(
          canPop: false,
          child: HomeScreen(),
        );
      },
    );
  }
}
