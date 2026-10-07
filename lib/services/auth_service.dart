import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awing_ai_learning/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awing_ai_learning/services/cloud_backup_service.dart';
import 'package:awing_ai_learning/services/fcm_service.dart';
import 'package:awing_ai_learning/services/analytics_service.dart';
import 'package:awing_ai_learning/services/user_registry_service.dart';

/// Authentication and user management service.
///
/// Enforces Google Sign-In only. Stores accounts locally via SharedPreferences.
/// Each Google email can hold multiple user profiles (e.g. siblings sharing
/// one device — parent signs in, creates child profiles).
class AuthService extends ChangeNotifier {
  static const String _keyAccounts = 'auth_accounts';
  static const String _keyCurrentEmail = 'auth_current_email';
  static const String _keyCurrentProfileId = 'auth_current_profile_id';
  static const String _developerEmail = 'samagids@gmail.com';
  static const String _keyDevMode = 'auth_dev_mode_enabled';
  static const String _keyDevCode = 'auth_dev_pending_code';
  static const String _keyDevCodeExpiry = 'auth_dev_code_expiry';

  late SharedPreferences _prefs;
  bool _initialized = false;
  bool _devModeManuallyEnabled = false;

  /// Auto-disable developer mode after 20 minutes of inactivity.
  static const Duration _devModeTimeout = Duration(minutes: 20);
  Timer? _devModeTimer;

  Map<String, UserAccount> _accounts = {}; // email → account
  UserAccount? _currentAccount;
  UserProfile? _currentProfile;

  /// Optional callback invoked whenever user data changes (lessons, quizzes, etc.).
  void Function()? onDataChanged;

  /// Optional callback invoked after a successful cloud restore.
  /// Used to refresh ProgressService from the restored SharedPreferences data.
  void Function()? onCloudRestoreComplete;

  /// Fired the FIRST time a lesson is completed, with the child's display
  /// name and the lesson id.
  ///
  /// v1.23.6 (Session 65c) — `ParentNotificationService.recordLessonCompleted`
  /// existed but had no caller anywhere, so the weekly parent report's
  /// "Lessons completed" line was structurally incapable of showing anything
  /// but 0. This is the missing wire.
  ///
  /// Deliberately first-completion only: `completeLesson` is called every
  /// time a lesson screen opens, so firing unconditionally would count a
  /// child re-reading the alphabet as new progress.
  void Function(String childName, String lessonId)? onLessonCompleted;

  // ==================== Getters ====================

  bool get isLoggedIn => _currentAccount != null && _currentProfile != null;
  bool get hasAccount => _currentAccount != null;
  bool get hasProfile => _currentProfile != null;
  UserAccount? get currentAccount => _currentAccount;
  UserProfile? get currentProfile => _currentProfile;

  /// Developer mode requires:
  /// 1. Signed in with developer Gmail (samagids@gmail.com)
  /// 2. 2FA verified via email code
  bool get isDeveloper =>
      _devModeManuallyEnabled &&
      (_currentAccount?.email.toLowerCase() == _developerEmail);
  String get currentEmail => _currentAccount?.email ?? '';
  List<UserProfile> get profiles => _currentAccount?.profiles ?? [];

  /// Check if current account is the developer email (for 2FA eligibility).
  bool get isDeveloperEmail =>
      _currentAccount?.email.toLowerCase() == _developerEmail;

  /// Initialize the service — must be called before anything else.
  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _loadAccounts();
    _restoreSession();
    _devModeManuallyEnabled = _prefs.getBool(_keyDevMode) ?? false;
    if (_devModeManuallyEnabled) {
      _resetDevModeTimer(); // start countdown even if persisted from last session
    }
    _initialized = true;
    notifyListeners();
  }

  /// Reload accounts and session from SharedPreferences.
  /// Call after cloud restore writes new data to prefs.
  void refreshFromPrefs() {
    _loadAccounts();
    _restoreSession();
    notifyListeners();
  }

  // ==================== Google Sign-In ====================

  /// Login with Google account. Creates account if new.
  /// [displayName] and [photoUrl] are optional metadata from Google.
  /// Set [cloudBackup] to attempt restoring from Google Drive if
  /// the account has no local data (e.g. after reinstall).
  String? loginWithGoogle(
    String googleEmail, {
    String? displayName,
    String? photoUrl,
    CloudBackupService? cloudBackup,
  }) {
    return _loginWithProvider(
      googleEmail,
      authMethod: 'google',
      displayName: displayName,
      cloudBackup: cloudBackup,
    );
  }

  // ==================== Apple Sign-In ====================

  /// Login with Apple ID. Creates account if new.
  ///
  /// Required by App Store Review Guideline 4.8 because the app also offers
  /// Google Sign-In as a third-party identity provider. Uses Firebase Auth's
  /// resolved email — which is either the user's real email, or Apple's
  /// @privaterelay.appleid.com forwarder if the user chose to hide their
  /// email. Either form is stable per user per app, so it's safe to use as
  /// the account key.
  ///
  /// On the first sign-in only, [displayName] is supplied (Apple does NOT
  /// return name/email on subsequent sign-ins). On later sign-ins, the
  /// existing account is reused via the stable email.
  String? loginWithApple(
    String appleEmail, {
    String? displayName,
    CloudBackupService? cloudBackup,
  }) {
    return _loginWithProvider(
      appleEmail,
      authMethod: 'apple',
      displayName: displayName,
      cloudBackup: cloudBackup,
    );
  }

  /// Shared provider login — extracted so Google and Apple flows stay in sync.
  String? _loginWithProvider(
    String email, {
    required String authMethod,
    String? displayName,
    CloudBackupService? cloudBackup,
  }) {
    final e = email.trim().toLowerCase();
    if (e.isEmpty) return 'Sign-in failed';

    if (!_accounts.containsKey(e)) {
      // Create new account for this email (Google or Apple)
      _accounts[e] = UserAccount(
        email: e,
        authMethod: authMethod,
        parentName: displayName,
      );
      _saveAccounts();

      // Try to restore from cloud backup (runs async, updates UI when done)
      if (cloudBackup != null) {
        _tryCloudRestore(e, cloudBackup);
      }

      // Session 64c: a brand-new account on this device. Email the
      // developer so new installs are visible without polling Firestore.
      // Guarded by `!_accounts.containsKey(e)` above, so it fires once per
      // address. Fire-and-forget - never blocks sign-in.
      unawaited(AnalyticsService.instance.notifyNewUser(
        email: e,
        displayName: displayName,
        authMethod: authMethod,
      ));
    } else if (displayName != null) {
      // Update display name if provided
      final account = _accounts[e]!;
      if (account.parentName == null || account.parentName!.isEmpty) {
        account.parentName = displayName;
        _saveAccounts();
      }
    }

    // Session 64c: record this address in the registry that powers the
    // green/amber badge on study-set rosters. Runs on EVERY sign-in, not
    // just the first, so pre-existing users backfill as they return.
    // Fire-and-forget; a failure only means a roster shows grey.
    unawaited(UserRegistryService.instance.registerSelf(e));

    final account = _accounts[e]!;
    _currentAccount = account;
    _prefs.setString(_keyCurrentEmail, e);

    // v1.22.8 (Session 68b): sign-in just wrote auth_current_email.
    // FcmService.initialize() ran on cold-start BEFORE we had an
    // email, so it deferred the token save. Trigger re-register now
    // so this device shows up in the Apps Script cron's collection-
    // group query — fire-and-forget, no need to block sign-in on it.
    FcmService.instance.forceReRegister();

    if (account.profiles.length == 1) {
      selectProfile(account.profiles.first.id);
    } else {
      _currentProfile = null;
      _prefs.remove(_keyCurrentProfileId);
    }

    notifyListeners();
    return null;
  }

  /// Attempt to restore data from Google Drive after a fresh install.
  /// Uses silent Drive sign-in — never prompts the user. If Drive scope was
  /// previously granted (on any device with this Google account), it restores
  /// automatically. If not, it skips gracefully.
  Future<void> _tryCloudRestore(String email, CloudBackupService cloud) async {
    try {
      debugPrint('Auto-restore: checking cloud for $email...');
      final ok = await cloud.tryAutoRestore();
      if (ok) {
        // Reload accounts from SharedPreferences (restoreAll wrote them)
        _loadAccounts();
        if (_accounts.containsKey(email)) {
          _currentAccount = _accounts[email];
          final account = _currentAccount!;
          if (account.profiles.length == 1) {
            selectProfile(account.profiles.first.id);
          }
          debugPrint('Auto-restore succeeded: ${account.profiles.length} profiles');
        }
        // Notify UI to rebuild with restored data
        notifyListeners();
        // Refresh ProgressService with restored progress data
        onCloudRestoreComplete?.call();
      } else {
        debugPrint('Auto-restore: no cloud backup found or Drive scope not granted');
      }
    } catch (e) {
      debugPrint('Auto-restore error: $e');
    }
  }

  // ==================== Profile Management ====================

  /// Create a new user profile under the current account.
  String? createProfile(String displayName, String avatarEmoji) {
    if (_currentAccount == null) return 'Not logged in';
    if (displayName.trim().isEmpty) return 'Name is required';

    final profile = UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      displayName: displayName.trim(),
      avatarEmoji: avatarEmoji,
    );

    _currentAccount!.profiles.add(profile);
    _saveAccounts();

    // Auto-select the new profile
    selectProfile(profile.id);
    return null;
  }

  /// Select an existing profile by ID.
  void selectProfile(String profileId) {
    if (_currentAccount == null) return;
    try {
      _currentProfile = _currentAccount!.profiles.firstWhere(
        (p) => p.id == profileId,
      );
      _currentProfile!.lastActiveAt = DateTime.now();
      _prefs.setString(_keyCurrentProfileId, profileId);
      _saveAccounts();
      notifyListeners();
    } catch (_) {
      // Profile not found
    }
  }

  /// Delete a profile by ID.
  void deleteProfile(String profileId) {
    if (_currentAccount == null) return;
    _currentAccount!.profiles.removeWhere((p) => p.id == profileId);
    if (_currentProfile?.id == profileId) {
      _currentProfile = null;
      _prefs.remove(_keyCurrentProfileId);
    }
    _saveAccounts();
    notifyListeners();
  }

  // ==================== Level Progression ====================

  /// Mark a lesson as completed for the current profile.
  void completeLesson(String lessonId) {
    if (_currentProfile == null) return;
    final alreadyCompleted = _currentProfile!.lessonsCompleted[lessonId] == true;
    _currentProfile!.lessonsCompleted[lessonId] = true;
    _checkLevelUnlocks();
    _saveAccounts();
    notifyListeners();
    onDataChanged?.call();
    if (!alreadyCompleted) {
      onLessonCompleted?.call(_currentProfile!.displayName, lessonId);
    }
  }

  /// Save a quiz score for the current profile.
  void saveQuizScore(String quizId, int score) {
    if (_currentProfile == null) return;
    final current = _currentProfile!.quizBestScores[quizId] ?? 0;
    if (score > current) {
      _currentProfile!.quizBestScores[quizId] = score;
      _checkLevelUnlocks();
      _saveAccounts();
      notifyListeners();
      onDataChanged?.call();
    }
  }

  /// Check and unlock levels based on completion.
  void _checkLevelUnlocks() {
    if (_currentProfile == null) return;
    final p = _currentProfile!;

    if (!p.mediumUnlocked && p.canUnlockMedium) {
      p.mediumUnlocked = true;
    }
    if (!p.expertUnlocked && p.canUnlockExpert) {
      p.expertUnlocked = true;
    }
  }

  /// Is a given level unlocked for the current profile?
  /// Developer has ALL levels unlocked.
  bool isLevelUnlocked(String level) {
    // Developer always has full access
    if (isDeveloper) return true;

    if (_currentProfile == null) return false;
    switch (level.toLowerCase()) {
      case 'beginner':
        return true; // always unlocked
      case 'medium':
        return _currentProfile!.mediumUnlocked;
      case 'expert':
        return _currentProfile!.expertUnlocked;
      default:
        return false;
    }
  }

  // ==================== PIN Management ====================

  /// Set or update the account-level PIN (protects sign out, delete profile).
  void setAccountPin(String pin) {
    if (_currentAccount == null) return;
    _currentAccount!.setAccountPin(pin);
    _saveAccounts();
    notifyListeners();
    onDataChanged?.call();
  }

  /// Remove the account-level PIN.
  void removeAccountPin() {
    if (_currentAccount == null) return;
    _currentAccount!.setAccountPin(null);
    _saveAccounts();
    notifyListeners();
    onDataChanged?.call();
  }

  /// Whether the current account has a PIN set.
  bool get hasAccountPin => _currentAccount?.hasAccountPin ?? false;

  /// Verify the account PIN. Returns true if correct or no PIN set.
  bool verifyAccountPin(String pin) {
    if (_currentAccount == null) return false;
    return _currentAccount!.verifyAccountPin(pin);
  }

  /// Set or update a profile-level PIN.
  void setProfilePin(String profileId, String pin) {
    if (_currentAccount == null) return;
    try {
      final profile = _currentAccount!.profiles.firstWhere(
        (p) => p.id == profileId,
      );
      profile.setPin(pin);
      _saveAccounts();
      notifyListeners();
      onDataChanged?.call();
    } catch (_) {}
  }

  /// Remove a profile-level PIN.
  void removeProfilePin(String profileId) {
    if (_currentAccount == null) return;
    try {
      final profile = _currentAccount!.profiles.firstWhere(
        (p) => p.id == profileId,
      );
      profile.setPin(null);
      _saveAccounts();
      notifyListeners();
      onDataChanged?.call();
    } catch (_) {}
  }

  // ==================== Parent Reset ====================

  /// Reset a child profile's learning progress — zeros lessons, quizzes,
  /// XP, and level unlocks so the child starts over as Beginner.
  /// Caller MUST verify the account PIN before invoking this.
  void resetProfileProgress(String profileId) {
    if (_currentAccount == null) return;
    try {
      final profile = _currentAccount!.profiles.firstWhere(
        (p) => p.id == profileId,
      );
      profile.lessonsCompleted.clear();
      profile.quizBestScores.clear();
      profile.totalXP = 0;
      profile.mediumUnlocked = false;
      profile.expertUnlocked = false;
      profile.currentLevel = 'beginner';
      profile.lastActiveAt = DateTime.now();
      _saveAccounts();
      notifyListeners();
      onDataChanged?.call();
    } catch (_) {}
  }

  // ==================== Session / Logout ====================

  /// Logout — clears current session. Caller must verify account PIN first.
  Future<void> logout() async {
    _currentAccount = null;
    _currentProfile = null;
    _prefs.remove(_keyCurrentEmail);
    _prefs.remove(_keyCurrentProfileId);
    // Sign out of Google so the login screen shows the account picker next time
    try {
      await CloudBackupService.loginGoogleSignIn.signOut();
    } catch (_) {}
    // v1.23.3 (Session 64): ALSO drop the Firebase Auth session.
    //
    // Before this, logout() cleared only the Google plugin's cache. For
    // Google users the stale Firebase session happened to be swept up by
    // CloudBackupService.initialize()'s orphan check on the next cold
    // start, so the leak was invisible. For Apple users nothing cleared
    // it at all.
    //
    // This line is REQUIRED by the initialize() fix in the same release:
    // now that a healthy Apple session is ADOPTED rather than signed out,
    // omitting this would leave a logged-out Apple user still
    // authenticated to Firestore as themselves on the next launch.
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    notifyListeners();
  }

  void switchProfile() {
    _currentProfile = null;
    _prefs.remove(_keyCurrentProfileId);
    notifyListeners();
  }

  // ==================== Parent Settings ====================

  /// Update the parent WhatsApp number for the current account.
  void updateWhatsAppNumber(String? number) {
    if (_currentAccount == null) return;
    _currentAccount!.whatsappNumber = _normalizePhone(number);
    _saveAccounts();
    notifyListeners();
  }

  /// Update the parent name for the current account.
  void updateParentName(String? name) {
    if (_currentAccount == null) return;
    _currentAccount!.parentName = name?.trim().isNotEmpty == true ? name!.trim() : null;
    _saveAccounts();
    notifyListeners();
  }

  /// Toggle quiz notification preference.
  void setQuizNotifications(bool enabled) {
    if (_currentAccount == null) return;
    _currentAccount!.sendQuizNotifications = enabled;
    _saveAccounts();
    notifyListeners();
  }

  /// Toggle weekly summary preference.
  void setWeeklySummary(bool enabled) {
    if (_currentAccount == null) return;
    _currentAccount!.sendWeeklySummary = enabled;
    _saveAccounts();
    notifyListeners();
  }

  // ==================== Parent Contacts (v1.23.6) ====================

  /// Default country code used when a parent types a bare local number.
  /// Cameroon. A number that already carries `+` or an international `00`
  /// prefix is never touched.
  static const String defaultCountryCode = '+237';

  /// Read-only view of the account's parent/guardian contacts.
  List<ParentContact> get parentContacts =>
      List<ParentContact>.unmodifiable(_currentAccount?.parentContacts ?? const []);

  /// Add a contact. Returns an error message, or null on success.
  String? addParentContact({
    required String label,
    String? whatsappNumber,
    String? email,
  }) {
    final account = _currentAccount;
    if (account == null) return 'Not signed in';
    if (account.parentContacts.length >= UserAccount.maxParentContacts) {
      return 'You can add up to ${UserAccount.maxParentContacts} contacts';
    }

    final phone = normalizeParentPhone(whatsappNumber);
    final mail = _normalizeEmail(email);
    final err = _validateContact(phone, mail);
    if (err != null) return err;

    if (phone != null &&
        account.parentContacts.any((c) => c.whatsappNumber == phone)) {
      return 'That number is already on the list';
    }
    if (mail != null &&
        account.parentContacts.any((c) => c.email == mail)) {
      return 'That email is already on the list';
    }

    account.parentContacts.add(ParentContact(
      label: label.trim().isEmpty ? 'Parent' : label.trim(),
      whatsappNumber: phone,
      email: mail,
    ));
    _saveAccounts();
    notifyListeners();
    return null;
  }

  /// Edit an existing contact. Returns an error message, or null on success.
  ///
  /// Changing the email address clears [ParentContact.emailConfirmed] — a
  /// confirmation belongs to one address, never to the row.
  String? updateParentContact(
    int index, {
    String? label,
    String? whatsappNumber,
    String? email,
  }) {
    final account = _currentAccount;
    if (account == null) return 'Not signed in';
    if (index < 0 || index >= account.parentContacts.length) {
      return 'Contact not found';
    }

    final phone = normalizeParentPhone(whatsappNumber);
    final mail = _normalizeEmail(email);
    final err = _validateContact(phone, mail);
    if (err != null) return err;

    for (var i = 0; i < account.parentContacts.length; i++) {
      if (i == index) continue;
      final other = account.parentContacts[i];
      if (phone != null && other.whatsappNumber == phone) {
        return 'That number is already on the list';
      }
      if (mail != null && other.email == mail) {
        return 'That email is already on the list';
      }
    }

    final c = account.parentContacts[index];
    if (label != null && label.trim().isNotEmpty) c.label = label.trim();
    c.whatsappNumber = phone;
    if (c.email != mail) {
      c.email = mail;
      c.emailConfirmed = false;
    }
    _saveAccounts();
    notifyListeners();
    return null;
  }

  void removeParentContact(int index) {
    final account = _currentAccount;
    if (account == null) return;
    if (index < 0 || index >= account.parentContacts.length) return;
    account.parentContacts.removeAt(index);
    _saveAccounts();
    notifyListeners();
  }

  /// Mark an address as confirmed by the server. Matched on the address, not
  /// on position, so a reordered or re-edited list cannot confirm the wrong row.
  void markContactEmailConfirmed(String email, {bool confirmed = true}) {
    final account = _currentAccount;
    if (account == null) return;
    final target = _normalizeEmail(email);
    if (target == null) return;
    var changed = false;
    for (final c in account.parentContacts) {
      if (c.email == target && c.emailConfirmed != confirmed) {
        c.emailConfirmed = confirmed;
        changed = true;
      }
    }
    if (!changed) return;
    _saveAccounts();
    notifyListeners();
  }

  String? _validateContact(String? phone, String? mail) {
    if (phone == null && mail == null) {
      return 'Enter a WhatsApp number or an email address';
    }
    if (phone != null) {
      final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
      if (!phone.startsWith('+')) {
        return 'Include the country code, e.g. $defaultCountryCode 6 12 34 56 78';
      }
      if (digits.length < 8 || digits.length > 15) {
        return 'That WhatsApp number does not look complete';
      }
    }
    if (mail != null && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(mail)) {
      return 'That email address does not look valid';
    }
    return null;
  }

  String? _normalizeEmail(String? raw) {
    final v = raw?.trim().toLowerCase();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  /// Normalize a phone number for WhatsApp.
  ///
  /// WhatsApp deep links and the Cloud API both require a full international
  /// number. A bare local number silently fails at send time, so it is
  /// upgraded here rather than left to fail later:
  ///   `+237 6 12 34 56 78` -> `+237612345678`  (kept as typed)
  ///   `00237612345678`     -> `+237612345678`  (international prefix)
  ///   `612345678`          -> `+237612345678`  (assumed local)
  ///   `0612345678`         -> `+237612345678`  (local trunk zero dropped)
  /// Anything else is returned stripped but unchanged, and `_validateContact`
  /// rejects it so the parent sees the problem at entry.
  String? normalizeParentPhone(String? raw) {
    if (raw == null) return null;
    var v = raw.trim().replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    if (v.isEmpty) return null;

    if (v.startsWith('+')) {
      final digits = v.substring(1).replaceAll(RegExp(r'[^\d]'), '');
      return '+$digits';
    }
    v = v.replaceAll(RegExp(r'[^\d]'), '');
    if (v.isEmpty) return null;

    if (v.startsWith('00') && v.length > 4) return '+${v.substring(2)}';
    // Local Cameroon formats: 9 digits, optionally with a trunk 0.
    if (v.length == 9) return '$defaultCountryCode$v';
    if (v.length == 10 && v.startsWith('0')) {
      return '$defaultCountryCode${v.substring(1)}';
    }
    return v; // rejected by _validateContact
  }

  /// Legacy single-number normalizer, kept for [updateWhatsAppNumber].
  String? _normalizePhone(String? raw) => normalizeParentPhone(raw);

  // ==================== Developer Mode (2FA) ====================

  /// Generate a 6-digit verification code for developer mode activation.
  /// Returns the code (to be sent via webhook email).
  String generateDevVerificationCode() {
    final code = (100000 + Random().nextInt(900000)).toString();
    // Store code + 10-minute expiry
    _prefs.setString(_keyDevCode, code);
    _prefs.setInt(
      _keyDevCodeExpiry,
      DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch,
    );
    return code;
  }

  /// Verify the 6-digit code and enable developer mode if correct.
  /// Returns null on success, error string on failure.
  String? verifyDevCode(String inputCode) {
    final storedCode = _prefs.getString(_keyDevCode);
    final expiryMs = _prefs.getInt(_keyDevCodeExpiry) ?? 0;

    if (storedCode == null) return 'No verification code pending';

    if (DateTime.now().millisecondsSinceEpoch > expiryMs) {
      _prefs.remove(_keyDevCode);
      _prefs.remove(_keyDevCodeExpiry);
      return 'Verification code expired. Try again.';
    }

    if (inputCode.trim() != storedCode) {
      return 'Incorrect verification code';
    }

    // Success — enable dev mode
    _devModeManuallyEnabled = true;
    _prefs.setBool(_keyDevMode, true);
    _prefs.remove(_keyDevCode);
    _prefs.remove(_keyDevCodeExpiry);
    notifyListeners();
    return null;
  }

  /// Disable developer mode and cancel the inactivity timer.
  void disableDevMode() {
    _devModeTimer?.cancel();
    _devModeTimer = null;
    _devModeManuallyEnabled = false;
    _prefs.setBool(_keyDevMode, false);
    debugPrint('Developer mode deactivated');
    notifyListeners();
  }

  /// Enable developer mode directly (used after 2FA verification).
  /// Starts the 20-minute inactivity auto-disable timer.
  void enableDevMode() {
    _devModeManuallyEnabled = true;
    _prefs.setBool(_keyDevMode, true);
    _resetDevModeTimer();
    debugPrint('Developer mode activated (auto-disables after 20 min inactivity)');
    notifyListeners();
  }

  /// Reset the developer mode inactivity timer.
  /// Call this whenever the developer interacts with a developer-only feature.
  void resetDevModeActivity() {
    if (_devModeManuallyEnabled) {
      _resetDevModeTimer();
    }
  }

  void _resetDevModeTimer() {
    _devModeTimer?.cancel();
    _devModeTimer = Timer(_devModeTimeout, () {
      debugPrint('Developer mode auto-disabled after 20 min inactivity');
      disableDevMode();
    });
  }

  /// Get all accounts (developer only).
  List<UserAccount> getAllAccounts() {
    if (!isDeveloper) return [];
    return _accounts.values.toList();
  }

  /// Get total user count across all accounts.
  int get totalProfileCount =>
      _accounts.values.fold(0, (sum, a) => sum + a.profiles.length);

  /// Unlock a level manually (developer only).
  void devUnlockLevel(String profileId, String level) {
    if (!isDeveloper) return;
    for (final account in _accounts.values) {
      for (final profile in account.profiles) {
        if (profile.id == profileId) {
          switch (level) {
            case 'medium':
              profile.mediumUnlocked = true;
              break;
            case 'expert':
              profile.expertUnlocked = true;
              break;
          }
          _saveAccounts();
          notifyListeners();
          return;
        }
      }
    }
  }

  /// Forget an account whose remote data has already been destroyed.
  ///
  /// v1.24.4 (Session 66r) — the local half of the account deletion
  /// required by App Store guideline 5.1.1(v).
  ///
  /// Why this lives here and not in AccountDeletionService: this class
  /// owns `auth_accounts`, and keeps the decoded map in memory. A second
  /// writer touching SharedPreferences directly would leave `_accounts`
  /// holding the deleted account until the next cold start — the same
  /// stale-after-restore bug that `reloadAccountsFromStorage` exists to
  /// fix. One owner, one writer.
  ///
  /// Deliberately narrower than wiping preferences: the offline-AI model
  /// bookkeeping, asset-pack version and other app-wide settings belong
  /// to the device, not to this person, and a reinstall-sized download is
  /// not part of what the parent asked for.
  ///
  /// Clearing the session fires notifyListeners(), so the Consumer in
  /// main.dart drops to the login screen without anyone navigating.
  void forgetDeletedAccount(String email) {
    _accounts.remove(email);
    _accounts.remove(email.toLowerCase());
    _saveAccounts();
    _currentAccount = null;
    _currentProfile = null;
    _prefs.remove(_keyCurrentEmail);
    _prefs.remove(_keyCurrentProfileId);
    notifyListeners();
  }

  // ==================== Persistence ====================

  void _loadAccounts() {
    final json = _prefs.getString(_keyAccounts);
    if (json == null) return;
    try {
      final Map<String, dynamic> decoded = jsonDecode(json);
      _accounts = decoded.map(
        (k, v) => MapEntry(k, UserAccount.fromJson(v)),
      );
      _purgeLegacyPlaintextSecrets();
    } catch (e) {
      if (kDebugMode) print('Error loading accounts: $e');
    }
  }

  /// Re-read accounts from storage after something else rewrote them.
  ///
  /// `CloudBackupService.restoreAll()` writes the `auth_accounts` key
  /// directly, so without this the service keeps serving the pre-restore
  /// objects until the next cold start. Two consequences, both fixed here:
  /// the UI showed stale profiles after a manual restore, and — since
  /// v1.23.6 — a restore that pulled down a PIN written as plain text by an
  /// older device would have left it readable on disk until the next launch.
  ///
  /// `_currentAccount` and `_currentProfile` are re-pointed by identity
  /// (email, profile id) rather than kept, because `_loadAccounts` builds
  /// fresh objects and the old pointers would silently write to a map nobody
  /// reads. Anything that no longer exists becomes null, which is the same
  /// state a cold start would produce.
  void reloadAccountsFromStorage() {
    _loadAccounts();

    final email = _prefs.getString(_keyCurrentEmail);
    _currentAccount = email == null ? null : _accounts[email];

    final profileId = _prefs.getString(_keyCurrentProfileId);
    _currentProfile = null;
    if (_currentAccount != null && profileId != null) {
      for (final p in _currentAccount!.profiles) {
        if (p.id == profileId) {
          _currentProfile = p;
          break;
        }
      }
    }
    notifyListeners();
  }

  /// Rewrite storage once if any PIN arrived as plain text.
  ///
  /// v1.23.6 (Session 65b). `UserAccount.fromJson` has already hashed the
  /// value in memory; this is what removes the readable copy from disk, and
  /// — because the same blob is what `CloudBackupService` uploads — from
  /// `users/{emailKey}/data/accounts` on the next sync.
  ///
  /// Called from every path that replaces `_accounts`, including cloud
  /// restore, because that is where plaintext written by an older device
  /// comes back down.
  void _purgeLegacyPlaintextSecrets() {
    final affected =
        _accounts.values.where((a) => a.migratedLegacySecret).toList();
    if (affected.isEmpty) return;
    for (final a in affected) {
      a.migratedLegacySecret = false;
      for (final p in a.profiles) {
        p.migratedLegacySecret = false;
      }
    }
    _saveAccounts();
    if (kDebugMode) {
      print('AuthService: hashed ${affected.length} legacy plaintext PIN '
          'record(s) and removed the readable copy.');
    }
  }

  void _saveAccounts() {
    final map = _accounts.map((k, v) => MapEntry(k, v.toJson()));
    _prefs.setString(_keyAccounts, jsonEncode(map));
  }

  void _restoreSession() {
    final email = _prefs.getString(_keyCurrentEmail);
    if (email == null) return;

    _currentAccount = _accounts[email];
    if (_currentAccount == null) return;

    final profileId = _prefs.getString(_keyCurrentProfileId);
    if (profileId != null) {
      try {
        _currentProfile = _currentAccount!.profiles.firstWhere(
          (p) => p.id == profileId,
        );
      } catch (_) {
        // Profile deleted
      }
    }
  }
}
