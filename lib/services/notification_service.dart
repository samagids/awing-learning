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
import 'package:shared_preferences/shared_preferences.dart';
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

  // v1.22.0 (Session 66) — engagement reminders.
  //
  // Two-times-a-day nudge on WOD + weekly "share the app" reminder
  // both proven to lift user retention in language-learning apps.
  //   1001 = evening WOD reminder (default 7 PM local)
  //   2000 = weekly share reminder (default Saturday 10 AM local)
  //
  // Share channel is separate so users can mute one without losing
  // the other — muting shares should not silence learning reminders.
  static const int _eveningReminderId = 1001;
  static const int _weeklyShareId = 2000;
  static const String _shareChannelId = 'awing_share_reminder';
  static const String _shareChannelName = 'Sharing Reminders';
  static const String _shareChannelDescription =
      'Weekly nudge to share Awing with a friend or family member';

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
    await _plugin.initialize(
      initSettings,
      // v1.22.0 (Session 66): route notification taps. The weekly-share
      // notification sets a pending-action flag that home_screen picks
      // up on next foreground → auto-opens the share sheet.
      onDidReceiveNotificationResponse: _onTap,
    );

    // v1.22.5 (Session 68): PROACTIVELY create both notification
    // channels on Android. Before this fix, flutter_local_notifications
    // only created channels lazily the first time a notification was
    // SHOWN. But v1.22.3 removed all local AlarmManager scheduling in
    // favor of FCM push — so the channel never got created and every
    // incoming FCM push referencing `awing_daily_words` was silently
    // dropped by the Samsung/Android OS ("channel unknown, drop
    // notification"). Explicit creation via createNotificationChannel
    // fixes this on both Android 8+ (channel-required) and older.
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.high,
          ),
        );
        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            _shareChannelId,
            _shareChannelName,
            description: _shareChannelDescription,
            importance: Importance.defaultImportance,
          ),
        );
      }
    } catch (e) {
      debugPrint('createNotificationChannel failed (non-fatal): $e');
    }

    _initialized = true;
  }

  /// v1.22.0 (Session 66) — SharedPreferences key for tap-side effects
  /// (currently: 'share_app' when the weekly reminder is tapped).
  static const String pendingActionKey = 'pending_notification_action';

  /// v1.22.6 (Session 68b) — bump this whenever a notification tap
  /// writes a new pending action. HomeScreen listens and re-checks
  /// the pref on any bump.
  ///
  /// WHY: `_checkPendingNotificationAction` was only called on
  /// initState + didChangeAppLifecycleState.resumed. Both are one-
  /// shot on cold-start / background→foreground. If the user was
  /// already in the app when the FCM push arrived (foreground), OR
  /// tapped a locally-shown notification without ever backgrounding
  /// the app, NO lifecycle event fired → the pref sat unread → the
  /// tap appeared to do nothing. This notifier closes that gap.
  static final ValueNotifier<int> tapCounter = ValueNotifier<int>(0);

  /// Static tap handler so it can be passed as a callback pointer
  /// without depending on the singleton instance. Runs on the app's
  /// main isolate after the OS wakes it — safe to touch SharedPreferences.
  ///
  /// v1.22.6 (Session 68b): route the two daily-words FCM payloads
  /// (`daily_words` = morning, `daily_words_evening` = evening) to
  /// the "open_daily_words" pending action. HomeScreen picks it up
  /// on the next foreground and pushes DailyWordsScreen so the user
  /// lands on today's picks.
  static Future<void> _onTap(NotificationResponse resp) async {
    final payload = resp.payload ?? '';
    // v1.22.6 (Session 68b): EVERY tap must lead the user into a
    // meaningful screen inside the app. Known payloads route to their
    // specific destination; anything else falls through to
    // 'open_daily_words' as a safe default so the user never taps a
    // notification and ends up looking at nothing.
    String action;
    if (payload == 'weekly_share') {
      action = 'share_app';
    } else if (payload == 'daily_words' ||
        payload == 'daily_words_evening') {
      action = 'open_daily_words';
    } else {
      action = 'open_daily_words';
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(pendingActionKey, action);
      // Wake HomeScreen so foreground taps route immediately.
      tapCounter.value++;
    } catch (_) {/* best-effort; home screen falls back if unset */}
  }

  /// Consume-once accessor for the pending-action flag. home_screen
  /// calls this on initState + on didChangeAppLifecycleState.resumed.
  Future<String?> consumePendingAction() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(pendingActionKey);
      if (v != null) await prefs.remove(pendingActionKey);
      return v;
    } catch (_) {
      return null;
    }
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

  // ─── v1.22.0 (Session 66) engagement reminders ───

  /// Schedule a SECOND daily reminder in the evening. Twice-a-day
  /// nudges are proven to lift Words-of-the-Day completion rates —
  /// morning catches you before work/school, evening catches you
  /// before bed. Independent on/off + time from the morning one.
  Future<void> scheduleEveningReminder({
    required int hour,
    required int minute,
  }) async {
    await initialize();
    await _plugin.cancel(_eveningReminderId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId, _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true, presentBadge: true, presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails, iOS: iosDetails,
    );

    Future<void> doSchedule(AndroidScheduleMode mode) {
      return _plugin.zonedSchedule(
        _eveningReminderId,
        'One more chance to learn today',
        'Tap to see your Awing words for today.',
        scheduled,
        details,
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'daily_words_evening',
      );
    }

    try {
      await doSchedule(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (e) {
      if (kDebugMode) {
        print('Evening reminder: exact refused ($e), falling back.');
      }
      await doSchedule(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> cancelEveningReminder() async {
    await initialize();
    await _plugin.cancel(_eveningReminderId);
  }

  /// Schedule a WEEKLY reminder to share the app with a friend.
  /// [weekday] uses Dart's DateTime.weekday convention: Mon=1..Sun=7.
  /// Default caller uses Saturday (6) at 10 AM local.
  ///
  /// Tap payload is 'weekly_share' which _onTap catches and sets
  /// pendingActionKey → 'share_app'. home_screen picks it up on next
  /// foreground and opens the platform share sheet with the app's
  /// Play/App Store URL.
  Future<void> scheduleWeeklyShareReminder({
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    await initialize();
    await _plugin.cancel(_weeklyShareId);

    // Compute the next matching weekday+time.
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    // Advance to the target weekday. weekday is 1..7 in DateTime.
    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      _shareChannelId, _shareChannelName,
      channelDescription: _shareChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true, presentBadge: true, presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails, iOS: iosDetails,
    );

    Future<void> doSchedule(AndroidScheduleMode mode) {
      return _plugin.zonedSchedule(
        _weeklyShareId,
        'Share Awing with a friend',
        'Awing grows when families share it. Tap to send a friend the app link.',
        scheduled,
        details,
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // Repeat weekly at same day-of-week + time.
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'weekly_share',
      );
    }

    try {
      await doSchedule(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (e) {
      if (kDebugMode) {
        print('Weekly share reminder: exact refused ($e), falling back.');
      }
      await doSchedule(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> cancelWeeklyShareReminder() async {
    await initialize();
    await _plugin.cancel(_weeklyShareId);
  }

  /// Orchestrator: read all reminder settings from SharedPreferences
  /// and schedule/cancel each accordingly. Idempotent — safe to call
  /// on every app cold start + on every resume. Fixes the "OEM wiped
  /// my alarms" self-heal loop.
  Future<void> scheduleAllReminders() async {
    // Morning WOD (existing).
    if (await DailySuggestionService.isEnabled()) {
      final h = await DailySuggestionService.notificationHour();
      final m = await DailySuggestionService.notificationMinute();
      await scheduleDaily(hour: h, minute: m);
    } else {
      await cancelDaily();
    }
    // Evening WOD (new, on by default).
    if (await DailySuggestionService.eveningEnabled()) {
      final h = await DailySuggestionService.eveningHour();
      final m = await DailySuggestionService.eveningMinute();
      await scheduleEveningReminder(hour: h, minute: m);
    } else {
      await cancelEveningReminder();
    }
    // Weekly share (new, on by default).
    if (await DailySuggestionService.weeklyShareEnabled()) {
      final wd = await DailySuggestionService.weeklyShareWeekday();
      final h = await DailySuggestionService.weeklyShareHour();
      final m = await DailySuggestionService.weeklyShareMinute();
      await scheduleWeeklyShareReminder(weekday: wd, hour: h, minute: m);
    } else {
      await cancelWeeklyShareReminder();
    }
  }

  /// v1.22.0 (Session 66) diagnostic: list every notification currently
  /// scheduled with the OS. Used by settings screen "diagnostics" pane
  /// so users / devs can confirm the reminders ARE queued (vs "I never
  /// got one" being permission or scheduling failure).
  Future<List<PendingNotificationRequest>> pendingRequests() async {
    await initialize();
    return _plugin.pendingNotificationRequests();
  }

  /// v1.22.0 (Session 66) diagnostic: fire a test notification NOW so
  /// users can verify their permissions + notification channel are
  /// working before trusting the app with day-later scheduling. Uses
  /// a temporary id (999) so it doesn't collide with the real ones.
  Future<void> fireTestNotification() async {
    await initialize();
    const androidDetails = AndroidNotificationDetails(
      _channelId, _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true, presentBadge: true, presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails, iOS: iosDetails,
    );
    await _plugin.show(
      999,
      'Test notification',
      'If you see this, notifications are working.',
      details,
    );
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
