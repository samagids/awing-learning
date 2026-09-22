import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:awing_ai_learning/screens/about_screen.dart';

/// Keeps users on a current build — without ever locking out a child who
/// happens to be offline.
///
/// Session 64b. Two independent thresholds, both read from ONE Firestore
/// document (`config/app_version`) so they can be changed from the Firebase
/// console in seconds with no release:
///
///   latestBuild        → a DISMISSIBLE "update available" nudge
///   minSupportedBuild  → a BLOCKING screen (ships as 0 = nobody blocked)
///
/// === Why the config lives in Firestore and not in the app ===
///
/// If the block threshold were compiled in, undoing a mistake would need a
/// new release — which the blocked users cannot install, because they are
/// blocked. Keeping it server-side means setting `minSupportedBuild` back
/// to 0 unblocks everyone immediately.
///
/// === THE STAGED-ROLLOUT TRAP (read before raising minSupportedBuild) ===
///
/// `.github/workflows/promote-alpha-to-production.yml` promotes at
/// PROMOTE_ROLLOUT = 20%. If minSupportedBuild is raised to a build that
/// Play is only serving to 20% of users, the other 80% get a blocking
/// screen telling them to install something Play will not give them. There
/// is no way out for them.
///
/// RULE: only ever raise minSupportedBuild to a build that has reached
/// 100% rollout on BOTH stores. The nudge (latestBuild) is safe at any
/// time because it is dismissible.
///
/// === Fail-open is deliberate ===
///
/// This app is offline-first and its users are often on intermittent
/// mobile data in Cameroon. Every gate below is gated on `_fetched`, which
/// is true ONLY after a successful read. A failed, timed-out or offline
/// check therefore shows nothing at all and the child goes straight to
/// their lesson. We never gate on cached values for the same reason: a
/// stale cached threshold must not strand someone who is offline.
class AppUpdateService extends ChangeNotifier {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  static const String _collection = 'config';
  static const String _docId = 'app_version';

  static const String _kLastCheck = 'update_last_check_ms';
  static const String _kLastPrompt = 'update_last_prompt_ms';

  /// How often to re-read the config. Cheap (one small doc) but no reason
  /// to do it on every resume.
  static const Duration _checkInterval = Duration(hours: 6);

  /// How long to stay quiet after the user dismisses the soft nudge, so it
  /// never becomes nagging.
  static const Duration _promptCooldown = Duration(days: 3);

  /// Fallbacks used only if the Firestore doc omits them. Both are
  /// overridable from the console so a wrong link can be fixed without a
  /// release.
  static const String _fallbackAndroidUrl =
      'https://play.google.com/store/apps/details?id=com.awing.learning';
  static const String _fallbackIosUrl =
      'https://apps.apple.com/app/id6764426877';

  SharedPreferences? _prefs;
  bool _fetched = false;
  bool _inFlight = false;

  int _latestBuild = 0;
  int _minSupportedBuild = 0;
  String? _message;
  String _androidUrl = _fallbackAndroidUrl;
  String _iosUrl = _fallbackIosUrl;

  /// The running build, parsed from the single source of truth used
  /// everywhere else in the app (AboutScreen). Returns 0 if it cannot be
  /// parsed, which disables every gate below — fail open.
  int get currentBuild => int.tryParse(AboutScreen.buildNumber) ?? 0;

  int get latestBuild => _latestBuild;
  int get minSupportedBuild => _minSupportedBuild;
  String? get message => _message;

  /// Blocking. False unless a fresh read succeeded AND the threshold was
  /// deliberately raised above this build.
  bool get mustUpdate =>
      _fetched && currentBuild > 0 && currentBuild < _minSupportedBuild;

  /// Dismissible nudge, suppressed during the cooldown window.
  bool get shouldSuggestUpdate {
    if (!_fetched || currentBuild <= 0) return false;
    if (currentBuild >= _latestBuild) return false;
    if (mustUpdate) return false; // the blocking screen supersedes it
    final last = _prefs?.getInt(_kLastPrompt) ?? 0;
    final elapsed =
        DateTime.now().millisecondsSinceEpoch - last;
    return elapsed >= _promptCooldown.inMilliseconds;
  }

  String get storeUrl {
    if (kIsWeb) return _androidUrl;
    try {
      return Platform.isIOS ? _iosUrl : _androidUrl;
    } catch (_) {
      return _androidUrl;
    }
  }

  /// Read the config. Safe to call often — throttled, single-flight, and
  /// silent on every failure.
  Future<void> check({bool force = false}) async {
    if (_inFlight) return;
    _prefs ??= await SharedPreferences.getInstance();

    if (!force) {
      final last = _prefs?.getInt(_kLastCheck) ?? 0;
      final elapsed = DateTime.now().millisecondsSinceEpoch - last;
      if (_fetched && elapsed < _checkInterval.inMilliseconds) return;
    }

    _inFlight = true;
    try {
      final snap = await FirebaseFirestore.instance
          .collection(_collection)
          .doc(_docId)
          .get()
          .timeout(const Duration(seconds: 8));

      final data = snap.data();
      if (data == null) {
        debugPrint('AppUpdate: config/app_version missing — no gate shown.');
        return;
      }

      int asInt(Object? v) {
        if (v is int) return v;
        if (v is num) return v.toInt();
        return int.tryParse('$v') ?? 0;
      }

      _latestBuild = asInt(data['latestBuild']);
      _minSupportedBuild = asInt(data['minSupportedBuild']);
      final msg = (data['message'] as String?)?.trim();
      _message = (msg == null || msg.isEmpty) ? null : msg;
      final a = (data['androidUrl'] as String?)?.trim();
      final i = (data['iosUrl'] as String?)?.trim();
      if (a != null && a.isNotEmpty) _androidUrl = a;
      if (i != null && i.isNotEmpty) _iosUrl = i;

      // Guard against a fat-fingered console edit locking everyone out:
      // a minSupportedBuild ABOVE the newest build that exists cannot be
      // satisfied by anyone, so refuse to honour it.
      if (_minSupportedBuild > _latestBuild) {
        debugPrint('AppUpdate: minSupportedBuild ($_minSupportedBuild) is '
            'above latestBuild ($_latestBuild) — refusing to block, since '
            'no user could satisfy it.');
        _minSupportedBuild = 0;
      }

      _fetched = true;
      _prefs?.setInt(_kLastCheck, DateTime.now().millisecondsSinceEpoch);
      debugPrint('AppUpdate: current=$currentBuild latest=$_latestBuild '
          'minSupported=$_minSupportedBuild');
      notifyListeners();
    } catch (e) {
      // Offline, timeout, permission, anything: show NOTHING. An offline
      // child must never be stopped from reaching a lesson.
      debugPrint('AppUpdate: check failed ($e) — failing open.');
    } finally {
      _inFlight = false;
    }
  }

  /// Record that the user dismissed the nudge, starting the cooldown.
  Future<void> snoozePrompt() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setInt(_kLastPrompt, DateTime.now().millisecondsSinceEpoch);
    notifyListeners();
  }

  /// Android only: Play's native flexible update — downloads in the
  /// background while the user keeps using the app, then asks to restart.
  ///
  /// Returns true if the native flow ran. Throws nothing: it fails for
  /// entirely normal reasons (sideloaded build, bundletool --local-testing
  /// install, emulator without Play, no update published yet) and every one
  /// of those should silently fall through to the plain store-link dialog.
  Future<bool> tryAndroidFlexibleUpdate() async {
    if (kIsWeb) return false;
    try {
      if (!Platform.isAndroid) return false;
    } catch (_) {
      return false;
    }
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return false;
      }
      if (info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
        return true;
      }
      if (info.immediateUpdateAllowed && mustUpdate) {
        // Only escalate to Play's blocking flow when we were going to
        // block anyway.
        await InAppUpdate.performImmediateUpdate();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('AppUpdate: Play in-app update unavailable ($e) — '
          'falling back to the store link.');
      return false;
    }
  }

  /// Open the store listing. Used on iOS, and on Android whenever the
  /// native flow is unavailable.
  Future<void> openStore() async {
    final uri = Uri.parse(storeUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('AppUpdate: could not open $uri ($e)');
    }
  }
}
