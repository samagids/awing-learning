// notification_service.dart
// ---------------------------------------------------------------
// v1.15.0 — Schedules the daily word-suggestion local notification.
// Pure local (no FCM, no network). Uses flutter_local_notifications
// + timezone.
//
// Permission handling:
//   - Android 13+ requires POST_NOTIFICATIONS at runtime
//   - iOS requires Notification.requestPermission()
//   - Older Android: no runtime permission, just works
//
// Schedule strategy:
//   - cancel + schedule a single repeating daily notification at the
//     user's chosen time. The OS handles re-firing across reboots
//     (Android: BOOT_COMPLETED hooks in the plugin's
//     ScheduledNotificationBootReceiver; iOS: persisted by the
//     UNUserNotificationCenter).
//   - The notification PAYLOAD is the date string; the actual word
//     picks are re-computed when the app opens (so they reflect
//     current learner level + seen-words state).
// ---------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:permission_handler/permission_handler.dart';
import 'package:awing_ai_learning/services/daily_suggestion_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const int _dailyNotificationId = 1000;
  static const String _channelId = 'awing_daily_words';
  static const String _channelName = 'Daily Awing Words';
  static const String _channelDescription =
      'Three new Awing words every morning';

  /// Initialize the plugin. Safe to call multiple times.
  Future<void> initialize() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      // Best-effort: use the device's local timezone. On Android this is
      // automatic; iOS needs a small native helper but we fall back to
      // UTC if the lookup fails — daily notifications will still fire
      // but may drift up to an hour at DST boundaries.
      tz.setLocalLocation(tz.local);
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  /// Request notification permission. Returns true if granted.
  /// Caller should explain why first (a settings screen with toggle).
  Future<bool> requestPermission() async {
    await initialize();
    try {
      // Android 13+
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        if (granted == true) return true;
        // Fallback via permission_handler for older Android with quirks
        final status = await Permission.notification.request();
        return status.isGranted;
      }
      // iOS
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      return true; // desktop / web — no-op
    } catch (e) {
      if (kDebugMode) print('Notification permission error: $e');
      return false;
    }
  }

  /// Schedule the daily notification at [hour]:[minute] local time.
  /// Cancels any existing schedule first.
  ///
  /// v1.18.3 fix: use exactAllowWhileIdle (not inexact). Inexact alarms
  /// get coalesced and drifted by hours on modern Android Doze mode and
  /// are silently dropped by aggressive-battery OEMs (Samsung, Xiaomi,
  /// Oppo) — exactly Dr. Sama's report on S24 Ultra. Exact requires
  /// the USE_EXACT_ALARM (Android 14+) or SCHEDULE_EXACT_ALARM
  /// (Android 12-13) permission, both now declared in AndroidManifest.
  /// If the exact schedule throws (e.g. user revoked the permission on
  /// Android 12-13), we fall back to inexact so the user at least gets
  /// SOMETHING rather than complete silence.
  Future<void> scheduleDaily({required int hour, required int minute}) async {
    await initialize();
    await _plugin.cancel(_dailyNotificationId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    Future<void> doSchedule(AndroidScheduleMode mode) {
      return _plugin.zonedSchedule(
        _dailyNotificationId,
        "Today's Awing Words",
        'Open the app to learn 3 new words today!',
        scheduled,
        details,
        androidScheduleMode: mode,
        // iOS requires this even though Android ignores it — plugin
        // enforces it at compile time on flutter_local_notifications 17.x.
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // repeats daily
        payload: 'daily_words',
      );
    }

    try {
      await doSchedule(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (e) {
      if (kDebugMode) {
        print(
            'Exact alarm refused ($e); falling back to inexact. User may '
            'need to grant "Alarms & reminders" in Android Settings for '
            'reliable daily timing.');
      }
      await doSchedule(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  /// Cancel the daily notification.
  Future<void> cancelDaily() async {
    await initialize();
    await _plugin.cancel(_dailyNotificationId);
  }

  /// Show today's pre-fetched words in a notification body (for "show now"
  /// preview from settings, etc.). Independent of the scheduled daily one.
  Future<void> showPreview(List<DailyWord> words) async {
    await initialize();
    if (words.isEmpty) return;
    final body = words
        .map((w) => '• ${w.awing} = ${w.english}')
        .take(3)
        .join('\n');
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(
      _dailyNotificationId + 1,
      "Today's Awing Words",
      body,
      details,
      payload: 'daily_words_preview',
    );
  }
}
