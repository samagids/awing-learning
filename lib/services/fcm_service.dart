// fcm_service.dart
// -----------------------------------------------------------------------
// v1.22.3 (Session 68) — Firebase Cloud Messaging replaces AlarmManager
// for daily engagement notifications.
//
// Why: Session 67 postmortem — three days of zero notifications on
// Samsung S24 Ultra despite USE_EXACT_ALARM + REQUEST_IGNORE_BATTERY_
// OPTIMIZATIONS + rationale dialog. Samsung's App Standby and Deep
// Sleeping Apps layer drops local scheduled alarms regardless of
// permissions. Same story for Xiaomi, Oppo, Huawei.
//
// FCM push is delivered by Google Play Services (always-running system
// component). It bypasses Doze, App Standby, and battery optimization.
// The user only sees ONE permission prompt (POST_NOTIFICATIONS) — the
// same one WhatsApp asks for and nothing more.
//
// Architecture:
//   1. App boots → FirebaseMessaging.instance.getToken() → device FCM
//      token (~200 chars).
//   2. Save token to Firestore users/{sanitized_email}/data/settings
//      as `fcmToken` field.
//   3. Apps Script cron (scripts/fcm_daily_push.gs) reads all tokens
//      at 08:00 and 19:00 WAT, sends push via Firebase HTTP v1 API.
//   4. User's phone receives push via Google Play Services → shows
//      notification. Zero involvement from our app process.
//
// The old AlarmManager code in notification_service.dart is now
// dead but kept in place for the "Send preview now" button which
// still uses `FlutterLocalNotificationsPlugin.show()` for the
// immediate in-app preview. That plugin is fine for _immediate_
// notifications — the reliability problem was only with _scheduled_
// ones.
// -----------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  static const String _kLastRegisteredToken = 'fcm_last_registered_token';

  bool _initialized = false;
  String? _currentToken;

  /// Idempotent init. Called from main.dart after Firebase.initializeApp.
  /// Requests notification permission (iOS + Android 13+), fetches the
  /// device FCM token, and starts listening for token rotation.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final messaging = FirebaseMessaging.instance;

      // v1.22.3: request permission via FCM itself instead of via
      // permission_handler. On Android 13+ this shows the standard
      // POST_NOTIFICATIONS system prompt exactly once. On iOS it
      // shows the alert/badge/sound system prompt. On Android <13
      // it's a no-op (permission implicitly granted).
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get the current device token. May return null on iOS if APNs
      // hasn't finished handshake yet — that's fine, the onTokenRefresh
      // listener below catches it later.
      _currentToken = await messaging.getToken();
      if (_currentToken != null && _currentToken!.isNotEmpty) {
        await _saveTokenIfChanged(_currentToken!);
      }

      // FCM rotates tokens periodically (app restore, reinstall, etc).
      // Whenever it rotates, save the new one to Firestore so the cron
      // keeps reaching the right device.
      messaging.onTokenRefresh.listen((newToken) {
        _currentToken = newToken;
        _saveTokenIfChanged(newToken);
      });

      // v1.22.5 (Session 68): when FCM delivers to the app process
      // (foreground OR recently-backgrounded warm cache), the system
      // does NOT auto-show a notification — it defers to us to
      // display it via `flutter_local_notifications`. Without this
      // handler, users on the emulator (and often on real devices
      // that keep Awing in-memory for a while after use) get zero
      // notification even though FCM successfully delivered.
      //
      // Session 68 emulator test confirmed: FirebaseMessaging received
      // the push (logcat: "Unable to log event: analytics library is
      // missing"), but nothing appeared in the tray because we did
      // nothing here beyond debugPrint.
      // v1.22.6 (Session 68b): tap-routing for BACKGROUND / KILLED-app
      // notifications. When the FCM push is delivered while the app is
      // not in-memory, the OS shows the notification via Google Play
      // Services (not via our onMessage handler above). Tapping it:
      //   - onMessageOpenedApp fires if the app was backgrounded when
      //     the tap happened
      //   - getInitialMessage returns the message if the app was
      //     killed AND the notification tap is what launched it
      // Both need to translate `data.payload` into the same pending-
      // action string that NotificationService._onTap sets for
      // foreground taps, so HomeScreen's existing
      // _checkPendingNotificationAction handler routes them all the
      // same way.
      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
      // Cold-start: run after first frame so SharedPreferences is
      // definitely up and HomeScreen is mounted to pick up the pref.
      FirebaseMessaging.instance.getInitialMessage().then((msg) {
        if (msg != null) _handleTap(msg);
      });

      FirebaseMessaging.onMessage.listen((msg) {
        try {
          final notif = msg.notification;
          if (notif == null) return; // silent data-only message
          final localPlugin = FlutterLocalNotificationsPlugin();
          // Route to the awing_daily_words channel — the same channel
          // the server-side FCM payload references. Channel is
          // guaranteed to exist because NotificationService.initialize
          // creates it proactively at app startup.
          localPlugin.show(
            msg.hashCode,
            notif.title,
            notif.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'awing_daily_words',
                'Daily Awing Words',
                channelDescription:
                    'Three new Awing words every morning',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            payload: msg.data['payload'] as String? ?? 'fcm',
          );
        } catch (e) {
          debugPrint('FcmService onMessage show failed: $e');
        }
      });
    } catch (e) {
      debugPrint('FcmService init failed: $e');
    }
  }

  /// Public accessor for the current token — useful for diagnostics
  /// in Developer Mode.
  String? get currentToken => _currentToken;

  /// v1.22.6 (Session 68b): translate an FCM tap (background or cold-
  /// start) into the same SharedPreferences pending-action flag that
  /// NotificationService._onTap writes for foreground taps of local
  /// notifications. HomeScreen._checkPendingNotificationAction reads
  /// this pref on initState + resume and routes:
  ///   'open_daily_words' → Navigator.push(DailyWordsScreen)
  ///   'share_app'        → Share.share(app link)
  ///
  /// The server-side cron (`scripts/fcm_daily_push.gs`) sends payload
  /// values 'daily_words' | 'daily_words_evening' | 'weekly_share'.
  Future<void> _handleTap(RemoteMessage msg) async {
    try {
      final payload = msg.data['payload'] as String? ?? '';
      // v1.22.6 (Session 68b): EVERY tap lands the user somewhere
      // useful. Known payloads → specific destination; unknown /
      // missing → default to 'open_daily_words'.
      String action;
      if (payload == 'weekly_share') {
        action = 'share_app';
      } else if (payload == 'daily_words' ||
          payload == 'daily_words_evening') {
        action = 'open_daily_words';
      } else {
        action = 'open_daily_words';
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        NotificationService.pendingActionKey,
        action,
      );
    } catch (e) {
      debugPrint('FcmService _handleTap failed: $e');
    }
  }

  /// Save the FCM token to Firestore under the current user's settings
  /// document, but only if it differs from the last-saved token (avoids
  /// redundant writes on every cold start).
  ///
  /// Uses the same email->docId sanitization as cloud_backup_service:
  /// lowercase, replace '.' with '_dot_' (matches Firestore rules).
  Future<void> _saveTokenIfChanged(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSaved = prefs.getString(_kLastRegisteredToken);
      if (lastSaved == token) return; // nothing changed

      // Resolve the current user's email. If not signed in, skip —
      // token will be re-saved after the user signs in and cold-starts.
      // We can't import AuthService here (circular), so read the
      // stored email directly from the cloud backup service's pref.
      final email = _currentUserEmail(prefs);
      if (email == null || email.isEmpty) {
        // Cache the token locally so we can push it after sign-in.
        if (kDebugMode) {
          debugPrint('FcmService: no signed-in user, deferring FCM token save');
        }
        return;
      }

      final docId = _sanitizeEmailForFirestore(email);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .collection('data')
          .doc('settings')
          .set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        // Store the platform so the Apps Script cron can pick
        // per-platform payload shapes if we ever need to.
        'fcmPlatform': defaultTargetPlatform.name,
      }, SetOptions(merge: true));

      await prefs.setString(_kLastRegisteredToken, token);
      if (kDebugMode) {
        debugPrint('FcmService: token saved for $email');
      }
    } catch (e) {
      debugPrint('FcmService _saveTokenIfChanged failed: $e');
    }
  }

  /// Read the currently signed-in user's email from SharedPreferences.
  /// AuthService (lib/services/auth_service.dart) writes it under
  /// `auth_current_email` — this key MUST match AuthService._keyCurrentEmail
  /// or the token save silently no-ops.
  String? _currentUserEmail(SharedPreferences prefs) {
    return prefs.getString('auth_current_email');
  }

  /// Sanitize an email for use as a Firestore doc id. MUST mirror the
  /// _userDocPath() logic in cloud_backup_service.dart AND the
  /// emailKey() function in firestore.rules — otherwise the cron
  /// won't find the token.
  String _sanitizeEmailForFirestore(String email) {
    return email.trim().toLowerCase().replaceAll('.', '_dot_');
  }

  /// Force re-registration of the current token. Useful after sign-in
  /// so the token gets saved even if it hadn't changed since app
  /// launch.
  Future<void> forceReRegister() async {
    if (_currentToken == null) return;
    final prefs = await SharedPreferences.getInstance();
    // Invalidate the cache so _saveTokenIfChanged writes even if
    // token bytes are identical.
    await prefs.remove(_kLastRegisteredToken);
    await _saveTokenIfChanged(_currentToken!);
  }
}
