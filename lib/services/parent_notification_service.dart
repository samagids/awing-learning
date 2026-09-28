import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:awing_ai_learning/models/user_model.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/contribution_service.dart';
import 'package:awing_ai_learning/services/progress_service.dart';

/// Outcome of a delivery attempt.
///
/// THREE outcomes, never two. `unknown` means the request left the device but
/// no readable answer came back. Collapsing it into either `sent` or
/// `notSent` is what broke the previous version of this class: it treated a
/// browser opening WhatsApp's download page as proof of delivery, stamped the
/// watermark, and deleted the week's statistics.
enum ReportResult { sent, notSent, unknown }

/// Sends activity reports to the parents/guardians on the account.
///
/// ## What changed in v1.23.6 (Session 65a)
///
/// The previous implementation built a `https://wa.me/<number>?text=<msg>`
/// link and called `launchUrl` from inside the child's quiz screen. That had
/// four defects, all fixed here:
///
///  1. **It required WhatsApp on the device.** Without it, Android handed the
///     https link to a browser, which showed WhatsApp's download page.
///  2. **It reported success anyway.** `launchUrl` returns true when *any*
///     handler takes the intent, so the weekly summary stamped
///     `parent_last_weekly_sent` and wiped the stats without sending.
///  3. **It interrupted the child.** Finishing a quiz — or merely cold-starting
///     the app — threw the child out of the app into WhatsApp, where a human
///     then had to press Send.
///  4. **It supported one number.** A family with two parents could not use it.
///
/// Delivery is now server-side, through the contributions web app, which
/// already holds a verified Brevo sender. Nothing is launched on the child's
/// device. WhatsApp survives only as an explicit, parent-initiated share from
/// Parent Settings, and only when WhatsApp is genuinely installed.
///
/// ## Why reports are batched
///
/// Brevo's free tier allows 300 emails per DAY for the whole app. One email
/// per quiz would exhaust that with a couple of dozen active families — the
/// same failure mode that took out the developer mail quota in Session 64e.
/// Quiz results therefore accumulate locally and go out as one daily report.
class ParentNotificationService {
  static const String _keyPendingEvents = 'parent_pending_events';
  static const String _keyLastDailySent = 'parent_last_daily_sent';
  static const String _keyLastWeeklySent = 'parent_last_weekly_sent';
  static const String _keyWeeklyStats = 'parent_weekly_stats';

  /// A daily report is due once this much time has passed. Deliberately under
  /// 24h so a family that opens the app at roughly the same hour each day
  /// still gets one, instead of skipping a day on a few minutes' drift.
  static const Duration _dailyInterval = Duration(hours: 20);
  static const Duration _weeklyInterval = Duration(days: 7);

  /// Cap on events listed in one report, so a heavy practice day cannot
  /// produce an unreadable (or oversized) email.
  static const int _maxListedEvents = 40;

  final AuthService _auth;
  final ProgressService _progress;
  final ContributionService _contributions;

  SharedPreferences? _prefs;
  Completer<void>? _initializing;

  List<Map<String, dynamic>> _pendingEvents = [];

  ParentNotificationService({
    required AuthService auth,
    required ProgressService progress,
    required ContributionService contributions,
  })  : _auth = auth,
        _progress = progress,
        _contributions = contributions;

  /// Events recorded but not yet included in a delivered report.
  int get pendingEventCount => _pendingEvents.length;

  /// Kept under the old name so Parent Settings keeps compiling.
  int get pendingMessageCount => pendingEventCount;

  /// True when at least one contact can actually be delivered to today.
  bool get canDeliverReports => _auth.currentAccount?.canDeliverReports ?? false;

  Future<void> initialize() async {
    if (_prefs != null) return;
    // Guard against two callers racing initialize(); main.dart kicks off a
    // report immediately after constructing the service.
    final inFlight = _initializing;
    if (inFlight != null) return inFlight.future;
    final completer = Completer<void>();
    _initializing = completer;
    try {
      _prefs = await SharedPreferences.getInstance();
      _loadPendingEvents();
    } finally {
      _initializing = null;
      completer.complete();
    }
  }

  // ==================== Recording ====================

  /// Record a completed quiz.
  ///
  /// Returns true when the result was recorded. It deliberately does NOT
  /// return "was a message sent" — nothing is sent from a child's screen any
  /// more, and no caller should be able to make that happen by accident.
  Future<bool> notifyQuizCompleted({
    required String childName,
    required String quizName,
    required int score,
    required int totalQuestions,
    required int correctAnswers,
  }) async {
    await initialize();
    final account = _auth.currentAccount;
    if (account == null) return false;

    _recordWeeklyStat('quiz', {
      'name': quizName,
      'child': childName,
      'score': score,
      'correct': correctAnswers,
      'total': totalQuestions,
      'date': DateTime.now().toIso8601String(),
    });

    if (account.sendQuizNotifications) {
      _queueEvent({
        'type': 'quiz',
        'child': childName,
        'name': quizName,
        'score': score,
        'correct': correctAnswers,
        'total': totalQuestions,
        'at': DateTime.now().toIso8601String(),
      });
    }
    return true;
  }

  /// Record a completed lesson (counts toward the weekly report).
  ///
  /// Wired to `AuthService.onLessonCompleted` in main.dart. Returns void
  /// because the caller is a plain callback, so the SharedPreferences wait
  /// is done here rather than silently dropping the stat when a lesson is
  /// finished before the service has finished initialising.
  void recordLessonCompleted(String childName, String lessonName) {
    unawaited(() async {
      try {
        await initialize();
        _recordWeeklyStat('lesson', {
          'name': lessonName,
          'child': childName,
          'date': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        if (kDebugMode) {
          debugPrint('ParentNotification: could not record lesson ($e)');
        }
      }
    }());
  }

  // ==================== Daily report ====================

  /// Send the daily report if one is due and there is something to say.
  Future<ReportResult> sendDailyReportIfDue() async {
    await initialize();
    final account = _auth.currentAccount;
    if (account == null ||
        !account.sendQuizNotifications ||
        !account.canDeliverReports) {
      return ReportResult.notSent;
    }
    if (_pendingEvents.isEmpty) return ReportResult.notSent;
    if (!_isDue(_keyLastDailySent, _dailyInterval)) return ReportResult.notSent;
    return sendDailyReport();
  }

  /// Build and send the daily report now.
  ///
  /// The queue is cleared and the watermark advanced ONLY on a confirmed
  /// send. An unknown outcome leaves both untouched, so at worst a parent
  /// receives the same day twice — never loses it.
  Future<ReportResult> sendDailyReport() async {
    await initialize();
    final account = _auth.currentAccount;
    if (account == null) return ReportResult.notSent;
    if (_pendingEvents.isEmpty) return ReportResult.notSent;

    final events = List<Map<String, dynamic>>.from(_pendingEvents);
    final body = _buildDailyBody(events);
    final result = await _deliver(
      kind: 'daily',
      subject: 'Awing Learning — daily report',
      body: body,
    );

    if (result == ReportResult.sent) {
      // Only drop the events that were actually in this report; anything
      // recorded while the request was in flight survives.
      final reported = events.map((e) => e['at']).toSet();
      _pendingEvents.removeWhere((e) => reported.contains(e['at']));
      _savePendingEvents();
      _prefs?.setString(_keyLastDailySent, DateTime.now().toIso8601String());
    }
    return result;
  }

  String _buildDailyBody(List<Map<String, dynamic>> events) {
    final quizzes = events.where((e) => e['type'] == 'quiz').toList();
    final scores = quizzes
        .map((e) => e['score'])
        .whereType<int>()
        .toList();
    final avg = scores.isEmpty
        ? 0
        : (scores.reduce((a, b) => a + b) / scores.length).round();

    final buf = StringBuffer()
      ..writeln('Awing Learning — daily report')
      ..writeln('')
      ..writeln('Quizzes completed: ${quizzes.length}');
    if (scores.isNotEmpty) buf.writeln('Average score: $avg%');
    buf.writeln('');

    final listed = quizzes.take(_maxListedEvents);
    for (final q in listed) {
      final child = q['child'] ?? 'Learner';
      final name = q['name'] ?? 'Quiz';
      final correct = q['correct'] ?? 0;
      final total = q['total'] ?? 0;
      final score = q['score'] ?? 0;
      buf.writeln('• $child — $name: $correct/$total ($score%)');
    }
    if (quizzes.length > _maxListedEvents) {
      buf.writeln('… and ${quizzes.length - _maxListedEvents} more.');
    }

    buf
      ..writeln('')
      ..writeln(_scoreAdvice(avg, quizzes.length))
      ..writeln('')
      ..writeln('— Awing AI Learning');
    return buf.toString();
  }

  String _scoreAdvice(int avg, int count) {
    if (count == 0) return 'No quizzes today.';
    if (avg >= 90) return 'Excellent work today. Your child is doing amazing!';
    if (avg >= 70) return 'Good progress today. Keep encouraging them!';
    if (avg >= 50) return 'Getting there. Practice makes perfect.';
    return 'Needs more practice — try reviewing the lessons together.';
  }

  // ==================== Weekly summary ====================

  Future<ReportResult> sendWeeklySummaryIfDue() async {
    await initialize();
    final account = _auth.currentAccount;
    if (account == null ||
        !account.sendWeeklySummary ||
        !account.canDeliverReports) {
      return ReportResult.notSent;
    }
    if (!_isDue(_keyLastWeeklySent, _weeklyInterval)) {
      return ReportResult.notSent;
    }
    return sendWeeklySummary();
  }

  /// Build and send the weekly summary now.
  ///
  /// As with the daily report, statistics are cleared only on a confirmed
  /// send. The previous version cleared them on an unverified launch and
  /// destroyed the week's data.
  Future<ReportResult> sendWeeklySummary() async {
    await initialize();
    final account = _auth.currentAccount;
    if (account == null) return ReportResult.notSent;

    final stats = _getWeeklyStats();
    final childNames = account.profiles.isEmpty
        ? 'your child'
        : account.profiles.map((p) => p.displayName).join(', ');

    final lessons = (stats['lessons'] as List?) ?? [];
    final quizzes = (stats['quizzes'] as List?) ?? [];
    final avgScore = quizzes.isEmpty
        ? 0
        : (quizzes.fold<int>(
                    0, (sum, q) => sum + ((q is Map ? q['score'] : 0) as int? ?? 0)) /
                quizzes.length)
            .round();

    final streak = _progress.dailyStreak;
    final buf = StringBuffer()
      ..writeln('Awing Learning — weekly report')
      ..writeln('')
      ..writeln('Children: $childNames')
      ..writeln('Period: last 7 days')
      ..writeln('')
      ..writeln('Lessons completed: ${lessons.length}')
      ..writeln(
          'Quizzes taken: ${quizzes.length}${quizzes.isEmpty ? '' : ' (average $avgScore%)'}')
      ..writeln('Daily streak: $streak day${streak == 1 ? '' : 's'}')
      ..writeln('Level ${_progress.level} • ${_progress.xp} XP')
      ..writeln('')
      ..writeln(_weeklyAdvice(lessons.length, quizzes.length, streak))
      ..writeln('')
      ..writeln('— Awing AI Learning');

    final result = await _deliver(
      kind: 'weekly',
      subject: 'Awing Learning — weekly report',
      body: buf.toString(),
    );

    if (result == ReportResult.sent) {
      _prefs?.setString(_keyLastWeeklySent, DateTime.now().toIso8601String());
      _clearWeeklyStats();
    }
    return result;
  }

  String _weeklyAdvice(int lessons, int quizzes, int streak) {
    if (lessons == 0 && quizzes == 0) {
      return 'No practice recorded this week. A short daily session goes a long way.';
    }
    if (streak >= 7) return 'A full week streak — wonderful consistency!';
    if (streak >= 3) return 'A good habit is forming. Encourage daily practice.';
    if (quizzes >= 3) return 'Plenty of quiz practice. Try some new lessons too.';
    return 'A good start. A little each day is the goal.';
  }

  // ==================== Delivery ====================

  /// Hand a report to the server for delivery.
  ///
  /// Recipients are only ever a hint: the server keeps the account address
  /// behind the verified ID token and drops any address that has not been
  /// confirmed for this account.
  Future<ReportResult> _deliver({
    required String kind,
    required String subject,
    required String body,
  }) async {
    final account = _auth.currentAccount;
    if (account == null) return ReportResult.notSent;

    final recipients = account.deliverableContacts
        .map((c) => c.email!)
        .toSet()
        .toList();
    if (recipients.isEmpty) return ReportResult.notSent;

    final reply = await _contributions.sendParentReport(
      kind: kind,
      subject: subject,
      body: body,
      recipients: recipients,
    );

    // null means the reply could not be read — NOT that nothing was sent.
    if (reply == null) {
      if (kDebugMode) {
        debugPrint('ParentNotification: $kind delivery outcome unknown.');
      }
      return ReportResult.unknown;
    }
    if (reply['status'] == 'success') return ReportResult.sent;
    if (kDebugMode) {
      debugPrint('ParentNotification: $kind refused — ${reply['message']}');
    }
    return ReportResult.notSent;
  }

  // ==================== WhatsApp (parent-initiated only) ====================

  /// Whether WhatsApp is actually installed.
  ///
  /// Checked against the `whatsapp:` scheme, not `https://wa.me/...`. An https
  /// probe is answered by any browser and so always says yes — the mistake
  /// that made the old implementation claim it had sent messages it had not.
  Future<bool> isWhatsAppInstalled() async {
    try {
      return await canLaunchUrl(Uri.parse('whatsapp://send?text=test'));
    } catch (_) {
      return false;
    }
  }

  /// Open WhatsApp with a report pre-filled, for the parent to send.
  ///
  /// Only ever called from Parent Settings, behind the parental gate, by a
  /// parent who tapped Share. It is never triggered by a child's activity.
  /// Returns false when WhatsApp is not installed, instead of dumping the
  /// user into a browser and calling it a success.
  Future<bool> shareViaWhatsApp({
    required ParentContact contact,
    required String message,
  }) async {
    if (!contact.hasPlausibleWhatsApp) return false;
    if (!await isWhatsAppInstalled()) return false;

    final uri = Uri.parse(
      'whatsapp://send?phone=${contact.whatsappDigits}'
      '&text=${Uri.encodeComponent(message)}',
    );
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (kDebugMode) debugPrint('ParentNotification: WhatsApp launch: $e');
      return false;
    }
  }

  /// Text of the most recent report, for sharing by hand.
  String composeShareableReport() {
    if (_pendingEvents.isNotEmpty) return _buildDailyBody(_pendingEvents);
    return 'Awing Learning\n\nNo new activity to report yet.\n\n— Awing AI Learning';
  }

  // ==================== Queue ====================

  void _queueEvent(Map<String, dynamic> event) {
    _pendingEvents.add(event);
    // Bound the queue: a device that never delivers must not grow without
    // limit in SharedPreferences.
    const cap = 500;
    if (_pendingEvents.length > cap) {
      _pendingEvents = _pendingEvents.sublist(_pendingEvents.length - cap);
    }
    _savePendingEvents();
  }

  void _loadPendingEvents() {
    final json = _prefs?.getString(_keyPendingEvents);
    if (json == null) return;
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) {
        _pendingEvents = decoded
            .whereType<Map>()
            .map((j) => Map<String, dynamic>.from(j))
            .toList();
      }
    } catch (_) {
      _pendingEvents = [];
    }
  }

  void _savePendingEvents() {
    _prefs?.setString(_keyPendingEvents, jsonEncode(_pendingEvents));
  }

  void clearPendingMessages() {
    _pendingEvents.clear();
    _savePendingEvents();
  }

  /// Retained so Parent Settings keeps compiling. Sending the queue now is
  /// exactly "send the daily report", so it delegates rather than keeping a
  /// second, subtly different path.
  Future<int> flushPendingMessages() async {
    final before = _pendingEvents.length;
    final result = await sendDailyReport();
    if (result != ReportResult.sent) return 0;
    return before - _pendingEvents.length;
  }

  // ==================== Weekly stats ====================

  bool _isDue(String key, Duration interval) {
    final last = _prefs?.getString(key);
    if (last == null) return true;
    final parsed = DateTime.tryParse(last);
    if (parsed == null) return true;
    return DateTime.now().difference(parsed) >= interval;
  }

  void _recordWeeklyStat(String type, Map<String, dynamic> data) {
    final stats = _getWeeklyStats();
    final key = type == 'quiz' ? 'quizzes' : 'lessons';
    final list = (stats[key] as List?) ?? [];
    list.add(data);
    stats[key] = list;
    _prefs?.setString(_keyWeeklyStats, jsonEncode(stats));
  }

  Map<String, dynamic> _getWeeklyStats() {
    final json = _prefs?.getString(_keyWeeklyStats);
    if (json == null) return {'quizzes': [], 'lessons': []};
    try {
      final decoded = jsonDecode(json);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return {'quizzes': [], 'lessons': []};
  }

  void _clearWeeklyStats() {
    _prefs?.setString(_keyWeeklyStats, jsonEncode({'quizzes': [], 'lessons': []}));
  }
}
