import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/screens/beginner/beginner_home.dart';
import 'package:awing_ai_learning/screens/medium/medium_home.dart';
import 'package:awing_ai_learning/screens/expert/expert_home.dart';
import 'package:awing_ai_learning/screens/profile_screen.dart';
import 'package:awing_ai_learning/screens/exam/teacher_setup_screen.dart';
import 'package:awing_ai_learning/screens/study_sets/study_set_list_screen.dart';
import 'package:awing_ai_learning/screens/exam/student_join_screen.dart';
import 'package:awing_ai_learning/screens/admin/developer_screen.dart';
import 'package:awing_ai_learning/screens/settings/feedback_screen.dart';
import 'package:awing_ai_learning/screens/settings/parent_settings_screen.dart';
import 'package:awing_ai_learning/screens/settings/backup_screen.dart';
import 'package:awing_ai_learning/screens/contribute/contribute_screen.dart';
import 'package:awing_ai_learning/components/parental_gate.dart';
import 'package:awing_ai_learning/screens/about_screen.dart';
import 'package:awing_ai_learning/services/analytics_service.dart';
import 'package:awing_ai_learning/services/notification_service.dart';
import 'package:awing_ai_learning/theme/app_colors.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/progress_service.dart';
import 'package:awing_ai_learning/models/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  /// v1.22.2 (Session 67): true when we've detected that the OS-level
  /// notification permission is CURRENTLY denied. Drives the amber
  /// nag banner at the top of Home. Refreshed on every mount and
  /// every resume (so if the user opens Settings, toggles it on, and
  /// switches back, the nag disappears immediately).
  bool _notificationsDenied = false;

  @override
  void initState() {
    super.initState();
    // v1.22.0 (Session 66): register for lifecycle so we can check the
    // notification pending-action flag on every resume. The flag is
    // set by NotificationService._onTap when the user taps the weekly
    // share reminder while the app is backgrounded.
    WidgetsBinding.instance.addObserver(this);
    // Also check on first mount — covers the cold-start case where the
    // user tapped the notification and it launched the app fresh.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingNotificationAction();
      // v1.22.1 (Session 67): first-run notification rationale. Show
      // a friendly Awing-flavored dialog ONCE before the OS permission
      // prompt fires so users understand why we want to send them
      // reminders. Deferred to post-frame so main.dart's ThemeProvider
      // + AuthGate have already resolved and the home screen has
      // painted at least once — the OS dialog then feels contextual,
      // not surprise-mugged.
      _maybeShowNotificationRationale();
      // v1.22.2 (Session 67): also refresh the "notifications denied"
      // nag state on mount so the amber banner shows immediately for
      // users who denied the OS prompt on a previous launch.
      _refreshNotificationPermissionStatus();
    });
    // Session 66 self-heal: re-run the scheduler on every HomeScreen
    // mount too. main.dart already calls it at cold start; this is
    // extra insurance for OEMs that wipe schedules mid-session.
    NotificationService.instance
        .scheduleAllReminders()
        .catchError((_) {/* non-fatal */});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingNotificationAction();
      // Reschedule again on resume — cheap and idempotent, and it
      // catches the "OEM killed the alarm while backgrounded" case.
      NotificationService.instance
          .scheduleAllReminders()
          .catchError((_) {/* non-fatal */});
      // v1.22.2 (Session 67): re-check the notification permission
      // status on every resume so the nag banner appears/disappears
      // if the user just visited Settings.
      _refreshNotificationPermissionStatus();
    }
  }

  /// v1.22.2 (Session 67): query the OS to see whether Awing is
  /// currently allowed to post notifications. Sets `_notificationsDenied`
  /// which drives the amber nag banner.
  Future<void> _refreshNotificationPermissionStatus() async {
    try {
      final status = await Permission.notification.status;
      final denied = status.isDenied || status.isPermanentlyDenied;
      if (mounted && denied != _notificationsDenied) {
        setState(() => _notificationsDenied = denied);
      }
    } catch (_) {/* platform not supported — treat as granted */}
  }

  /// v1.22.1 (Session 67): one-time in-app rationale shown before we
  /// invoke the OS notification permission prompt. If we've already
  /// shown it (regardless of whether the user granted or denied),
  /// this returns immediately — never ask twice.
  ///
  /// The pref key is versioned so we could re-prompt in a future
  /// release with different copy if acceptance is low, without
  /// re-nagging existing users right now.
  static const String _kRationaleShownKey =
      'notification_rationale_shown_v1_22_1';

  Future<void> _maybeShowNotificationRationale() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kRationaleShownKey) == true) {
      // Already shown. If the OS permission is granted, we're done.
      // If it was denied, that's the user's OS-level choice and we
      // respect it — no in-app nag.
      return;
    }
    // Mark shown BEFORE the async dialog so a double-mount can't
    // fire the dialog twice.
    await prefs.setBool(_kRationaleShownKey, true);
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.notifications_active,
            color: Colors.green, size: 40),
        title: const Text('Daily Awing reminders'),
        content: const Text(
          'Awing AI Learning sends you a few short reminders each week '
          'so your kids keep practicing:\n\n'
          '  🌅 A morning "word of the day"\n'
          '  🌇 A gentle evening nudge\n'
          '  📣 One Saturday reminder to share Awing with a friend\n\n'
          'These reminders are always on inside the app. On the next '
          'screen, please allow notifications so Awing can reach you.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            icon: const Icon(Icons.check),
            label: const Text('Got it — enable notifications'),
          ),
        ],
      ),
    );

    // Now trigger the OS-level prompt. If the user denies here they
    // can still re-enable via the persistent amber nag banner that
    // appears at the top of Home whenever notifications are off.
    if (!mounted) return;
    await NotificationService.instance.requestPermission();

    // v1.22.2 (Session 67): after notification permission (whether
    // granted or denied), request battery-optimization bypass on
    // Android. Doze mode / aggressive OEM battery managers (Samsung,
    // Xiaomi, Oppo) will DROP scheduled alarms overnight if we're
    // optimized. The OS system dialog gives the user a one-tap way
    // to whitelist Awing so exact alarms fire on time.
    try {
      final battStatus =
          await Permission.ignoreBatteryOptimizations.status;
      if (battStatus.isDenied || battStatus.isRestricted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (_) {/* iOS / desktop — no-op */}

    // Re-schedule now that permissions (may) have been granted.
    if (!mounted) return;
    await NotificationService.instance.scheduleAllReminders();
    // Refresh nag state.
    await _refreshNotificationPermissionStatus();
  }

  /// v1.22.2 (Session 67): open the OS Settings screen for Awing so
  /// the user can flip Notifications back on. Called from the amber
  /// nag banner. `openAppSettings()` comes from permission_handler.
  Future<void> _openAwingSettings() async {
    try {
      await openAppSettings();
    } catch (_) {/* platform not supported */}
  }

  /// v1.22.2 (Session 67): amber banner that shows at the top of
  /// Home while notification permission is denied at the OS level.
  /// Prompts the user to flip it back on so daily reminders work.
  Widget _buildNotificationDeniedBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade400, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_off,
              color: Colors.amber.shade800, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications are off',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your kids will miss their daily Awing reminders. '
                  'Tap to turn them back on.',
                  style: TextStyle(
                      fontSize: 12, color: Colors.amber.shade900),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _openAwingSettings,
            style: TextButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Fix'),
          ),
        ],
      ),
    );
  }

  /// v1.22.0 (Session 66): consume the pending-action flag left by a
  /// notification tap. Currently only 'share_app' is defined — routes
  /// to the platform share sheet with the Play Store URL.
  Future<void> _checkPendingNotificationAction() async {
    final action = await NotificationService.instance.consumePendingAction();
    if (action != 'share_app' || !mounted) return;
    await _shareApp();
  }

  Future<void> _shareApp() async {
    const shareText =
        'I use Awing AI Learning to help my kids learn Awing. '
        'It has games, quizzes, stories and even a teacher exam mode. '
        '📱 Android: https://play.google.com/store/apps/details?id=com.awing.learning\n'
        '🍎 iPhone: https://apps.apple.com/app/id6764426877';
    try {
      await Share.share(shareText, subject: 'Awing AI Learning');
      AnalyticsService.instance.logActivity(event: 'share_app_from_reminder');
    } catch (_) {/* user cancelled or platform unavailable */}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final profile = auth.currentProfile;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const SizedBox(height: 16),
            // v1.22.2 (Session 67): persistent amber nag banner when
            // OS notification permission is currently denied. Tapping
            // opens Awing's app settings screen so the user can flip
            // it back on. Disappears immediately on resume once they
            // toggle it (see didChangeAppLifecycleState → refresh).
            if (_notificationsDenied)
              _buildNotificationDeniedBanner(),
            // Title row with icon buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/app_icon.png',
                              width: 44,
                              height: 44,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Awing',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF006432),
                            ),
                          ),
                        ],
                      ),
                      if (profile != null)
                        Text(
                          // Awing greeting: cha'tô (from PDF-verified
                          // maŋ cha'tô = "I am greeting"; cha'tô alone
                          // is the salutation form, equivalent to
                          // "Greetings"). Verified by Dr. Sama directly
                          // on 2026-06-05 per Session 30 no-fabrication rule.
                          "cha'tô, ${profile.displayName}! ${profile.avatarEmoji}",
                          style: TextStyle(
                            fontSize: 18,
                            color: const Color(0xFFDAA520),
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        Text(
                          'Learn a Language!',
                          style: TextStyle(
                            fontSize: 20,
                            color: const Color(0xFFDAA520),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.person),
                      tooltip: 'Profile',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.swap_horiz),
                      tooltip: 'Switch Profile',
                      onPressed: () => auth.switchProfile(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.family_restroom),
                      tooltip: 'Parent Settings',
                      onPressed: () async {
                        final ok = await ParentalGate.verify(
                          context,
                          title: 'Parent Settings',
                          message: 'Only a parent or guardian should change settings.',
                        );
                        if (ok && context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ParentSettingsScreen(),
                            ),
                          );
                        }
                      },
                    ),
                    // Dark mode toggle hidden in v1.2.1 — re-enable after
                    // completing full dark-mode color audit across all screens.
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Spoken by 19,000 people in Cameroon',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            // Progress summary
            Consumer<ProgressService>(
              builder: (context, progress, _) {
                final hasStreak = progress.dailyStreak > 0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Level ${progress.level} • ${progress.xp} XP',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF006432),
                          ),
                        ),
                        if (hasStreak) ...[
                          const SizedBox(width: 12),
                          Text(
                            '🔥 ${progress.dailyStreak}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.xpToNextLevel > 0
                            ? progress.xpInCurrentLevel / progress.xpToNextLevel
                            : 0,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFFDAA520),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            // Mode selection cards
            Column(
              children: [
                      // Beginner — always unlocked
                      _ModeCard(
                        title: 'Beginner',
                        subtitle: 'Alphabet, basic words & tones',
                        icon: Icons.child_care,
                        color: AppColors.beginner, // Session 64 (C4)
                        locked: false,
                        onTap: () {
                          context.read<ProgressService>().markDifficultyLevelTried('Beginner');
                          AnalyticsService.instance.logActivity(
                            event: 'open_mode', level: 'beginner',
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BeginnerHome(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Medium — locked until beginner complete
                      _ModeCard(
                        title: 'Medium',
                        subtitle: 'Grammar, sentences & clusters',
                        icon: Icons.school,
                        color: AppColors.medium, // Session 64 (C4)
                        locked: !auth.isLevelUnlocked('medium'),
                        progressWidget: (!auth.isLevelUnlocked('medium') && profile != null)
                            ? _UnlockProgress(
                                lessonsCompleted: profile.beginnerLessonsCompleted(),
                                totalLessons: UserProfile.beginnerLessonIds.length,
                                quizzesPassed: profile.beginnerQuizzesPassed(),
                                totalQuizzes: UserProfile.beginnerQuizIds.length,
                              )
                            : null,
                        onTap: () {
                          if (!auth.isLevelUnlocked('medium')) {
                            final lDone = profile?.beginnerLessonsCompleted() ?? 0;
                            final lTotal = UserProfile.beginnerLessonIds.length;
                            final qDone = profile?.beginnerQuizzesPassed() ?? 0;
                            final qTotal = UserProfile.beginnerQuizIds.length;
                            final lRem = lTotal - lDone;
                            final qRem = qTotal - qDone;
                            final parts = <String>[];
                            if (lRem > 0) parts.add('$lRem more lesson${lRem == 1 ? "" : "s"}');
                            if (qRem > 0) parts.add('$qRem more quiz${qRem == 1 ? "" : "zes"} at 90%+');
                            final remaining = parts.isEmpty
                                ? 'Almost there!'
                                : 'You still need: ${parts.join(" and ")}.';
                            _showLockedDialog(context, 'Medium',
                                'Beginner progress: $lDone/$lTotal lessons done, $qDone/$qTotal quizzes passed.\n\n$remaining\n\nKeep going — you can do it!');
                            return;
                          }
                          context.read<ProgressService>().markDifficultyLevelTried('Medium');
                          AnalyticsService.instance.logActivity(
                            event: 'open_mode', level: 'medium',
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MediumHome(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Expert — locked until medium complete
                      _ModeCard(
                        title: 'Expert',
                        subtitle: 'Tone mastery, elision & conversations',
                        icon: Icons.emoji_events,
                        color: AppColors.expert, // Session 64 (C4)
                        locked: !auth.isLevelUnlocked('expert'),
                        progressWidget: (!auth.isLevelUnlocked('expert') && auth.isLevelUnlocked('medium') && profile != null)
                            ? _UnlockProgress(
                                lessonsCompleted: profile.mediumLessonsCompleted(),
                                totalLessons: UserProfile.mediumLessonIds.length,
                                quizzesPassed: profile.mediumQuizzesPassed(),
                                totalQuizzes: UserProfile.mediumQuizIds.length,
                              )
                            : null,
                        onTap: () {
                          if (!auth.isLevelUnlocked('expert')) {
                            if (!auth.isLevelUnlocked('medium')) {
                              _showLockedDialog(context, 'Expert',
                                  'You need to unlock Medium first by finishing all Beginner lessons and quizzes.');
                              return;
                            }
                            final lDone = profile?.mediumLessonsCompleted() ?? 0;
                            final lTotal = UserProfile.mediumLessonIds.length;
                            final qDone = profile?.mediumQuizzesPassed() ?? 0;
                            final qTotal = UserProfile.mediumQuizIds.length;
                            final lRem = lTotal - lDone;
                            final qRem = qTotal - qDone;
                            final parts = <String>[];
                            if (lRem > 0) parts.add('$lRem more Medium lesson${lRem == 1 ? "" : "s"}');
                            if (qRem > 0) parts.add('the writing quiz at 90%+');
                            final remaining = parts.isEmpty
                                ? 'Almost there!'
                                : 'You still need: ${parts.join(" and ")}.';
                            _showLockedDialog(context, 'Expert',
                                'Medium progress: $lDone/$lTotal lessons done, $qDone/$qTotal quizzes passed.\n\n$remaining\n\nKeep going — you can do it!');
                            return;
                          }
                          context.read<ProgressService>().markDifficultyLevelTried('Expert');
                          AnalyticsService.instance.logActivity(
                            event: 'open_mode', level: 'expert',
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ExpertHome(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // v1.16.0: "Today's Words/Sentences/Conversations" moved
                      // into each mode's lesson list so content matches level.
                      // Session 63: Translate lives inside each mode too
                      // (Beginner → Word Translate, Medium → Sentence
                      // Translate, Expert → Grade My Translation). No
                      // top-level Translate tile — keeps the home screen
                      // simple and forces users through their level.
                      // Contribute — parent-gated so kids can't submit
                      // random/inappropriate recordings to the webhook
                      // without an adult's knowledge. Uses the same
                      // ParentalGate pattern as Teacher Mode / Developer
                      // Mode. Once unlocked, the gate caches the
                      // verification for the session (per ParentalGate's
                      // existing behavior), so contributing several
                      // corrections in a row doesn't re-prompt the parent.
                      _ModeCard(
                        title: 'Contribute',
                        subtitle: 'Fix a word, record pronunciation (parent unlock)',
                        icon: Icons.volunteer_activism,
                        color: const Color(0xFF006432),
                        locked: false,
                        onTap: () async {
                          AnalyticsService.instance.logActivity(
                            event: 'open_contribute_attempt',
                          );
                          final ok = await ParentalGate.verify(
                            context,
                            title: 'Parent unlock',
                            message: 'Contributing sends recordings to '
                                'the developer for review. A parent or '
                                'teacher should approve each session.',
                          );
                          if (!ok || !context.mounted) {
                            AnalyticsService.instance.logActivity(
                              event: 'open_contribute_blocked',
                            );
                            return;
                          }
                          AnalyticsService.instance.logActivity(
                            event: 'open_contribute',
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ContributeScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Exam Mode
                      _ModeCard(
                        title: 'Exam & Study Sets',
                        subtitle: 'Take or create exams, study wordlists',
                        icon: Icons.quiz,
                        color: Colors.indigo,
                        locked: false,
                        onTap: () => _showExamRoleDialog(context),
                      ),
                      // Developer Mode — hidden unless developer account
                      if (auth.isDeveloper) ...[
                        const SizedBox(height: 12),
                        _ModeCard(
                          title: 'Developer',
                          subtitle: 'Admin panel & app settings',
                          icon: Icons.code,
                          color: Colors.grey.shade800,
                          locked: false,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DeveloperScreen(),
                              ),
                            );
                          },
                        ),
                      ],
              const SizedBox(height: 8),
            ],
            ),
            const SizedBox(height: 12),
            // About button
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
                icon: Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
                label: Text(
                  'About',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Developer credit
            Center(
              child: Text(
                'By Dr. Guidion Sama, DIT',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Version ${AboutScreen.appVersion}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
          ),
        ),
      ),
    );
  }

  void _showLockedDialog(BuildContext context, String level, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock, color: Colors.orange),
            const SizedBox(width: 8),
            Text('$level Locked'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Exam mode entry — two-step flow.
  ///
  /// Step 1: role picker (Student / Teacher). Students continue without
  /// any gate — they can Join an exam or browse Study Sets shared with
  /// them. Teachers pass through a parental gate first (creating an
  /// exam and editing wordlists are adult-only actions), then get a
  /// sub-menu to pick Study Sets vs Exam setup.
  void _showExamRoleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exam Mode'),
        content: const Text(
          'Are you a teacher creating an exam or study set, or '
          'a student joining or studying?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showStudentSubMenu(context);
            },
            child: const Text('Student'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ParentalGate.verify(
                context,
                title: 'Teacher Mode',
                message: 'Only a parent or teacher should set up exams '
                    'and study sets.',
              );
              if (ok && context.mounted) {
                _showTeacherSubMenu(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Teacher'),
          ),
        ],
      ),
    );
  }

  /// Student sub-menu — Join Exam or browse Study Sets shared with them.
  /// No gate; kids can freely study or join a live exam.
  void _showStudentSubMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('What would you like to do?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SubMenuChoice(
              icon: Icons.login,
              color: Colors.indigo,
              title: 'Join an Exam',
              subtitle: 'Your teacher will share a PIN',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentJoinScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _SubMenuChoice(
              icon: Icons.library_books,
              color: Colors.teal,
              title: 'My Study Sets',
              subtitle: 'Sets shared with you',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudySetListScreen(
                      role: StudySetRole.student,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Teacher sub-menu — after passing the parental gate, teachers pick
  /// between running an exam and managing study sets.
  void _showTeacherSubMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Teacher Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SubMenuChoice(
              icon: Icons.library_books,
              color: Colors.teal,
              title: 'Study Sets',
              subtitle: 'Curate wordlists to share with students',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudySetListScreen(
                      role: StudySetRole.teacher,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _SubMenuChoice(
              icon: Icons.quiz,
              color: Colors.indigo,
              title: 'Create / Run an Exam',
              subtitle: 'Live exam over WiFi or hotspot',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TeacherSetupScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

/// Reusable card-style choice tile used inside the exam sub-menus.
class _SubMenuChoice extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SubMenuChoice({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.35), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool locked;
  final VoidCallback onTap;
  final Widget? progressWidget;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.locked = false,
    this.progressWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: locked ? 1 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: locked
                  ? [Colors.grey.shade400, Colors.grey.shade500]
                  : [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(icon, size: 48, color: Colors.white.withOpacity(locked ? 0.6 : 1)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(locked ? 0.7 : 1),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(locked ? 0.5 : 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    locked ? Icons.lock : Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(locked ? 0.6 : 1),
                  ),
                ],
              ),
              if (progressWidget != null) ...[
                const SizedBox(height: 12),
                progressWidget!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows lesson and quiz progress toward unlocking the next level.
class _UnlockProgress extends StatelessWidget {
  final int lessonsCompleted;
  final int totalLessons;
  final int quizzesPassed;
  final int totalQuizzes;

  const _UnlockProgress({
    required this.lessonsCompleted,
    required this.totalLessons,
    required this.quizzesPassed,
    required this.totalQuizzes,
  });

  @override
  Widget build(BuildContext context) {
    final lessonsDone = lessonsCompleted >= totalLessons;
    final quizzesDone = quizzesPassed >= totalQuizzes;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            lessonsDone ? Icons.check_circle : Icons.menu_book,
            size: 16,
            color: lessonsDone ? Colors.greenAccent : Colors.white70,
          ),
          const SizedBox(width: 6),
          Text(
            'Lessons $lessonsCompleted/$totalLessons',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: lessonsDone ? Colors.greenAccent : Colors.white70,
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            quizzesDone ? Icons.check_circle : Icons.quiz,
            size: 16,
            color: quizzesDone ? Colors.greenAccent : Colors.white70,
          ),
          const SizedBox(width: 6),
          Text(
            'Quizzes $quizzesPassed/$totalQuizzes',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: quizzesDone ? Colors.greenAccent : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
