// daily_words_screen.dart
// ---------------------------------------------------------------
// v1.15.0 — UI for the daily-word feature.
// Shows today's 3 suggested words with images + audio.
// Settings card: enable/disable notification + time picker +
// "show preview now" button + "reset seen words" button.
// ---------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/services/daily_suggestion_service.dart';
import 'package:awing_ai_learning/services/notification_service.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/components/pack_image.dart';

class DailyWordsScreen extends StatefulWidget {
  final DailyContentType contentType;
  final String? levelOverride;
  const DailyWordsScreen({
    super.key,
    this.contentType = DailyContentType.words,
    this.levelOverride,
  });

  @override
  State<DailyWordsScreen> createState() => _DailyWordsScreenState();
}

class _DailyWordsScreenState extends State<DailyWordsScreen> {
  List<DailyWord> _picks = [];
  int _learnedCount = 0;
  bool _loading = true;
  bool _notificationEnabled = false;
  int _hour = DailySuggestionService.defaultHour;
  int _minute = DailySuggestionService.defaultMinute;
  final PronunciationService _pronunciation = PronunciationService();

  @override
  void initState() {
    super.initState();
    _pronunciation.init();
    _load();
  }

  /// Resolve the currently-active profile id, with a stable fallback
  /// so the screen still works in edge cases (e.g. notification preview
  /// before sign-in, profile selection mid-render).
  String _profileId() {
    final auth = context.read<AuthService>();
    final id = auth.currentProfile?.id;
    if (id == null || id.isEmpty) {
      return DailySuggestionService.defaultProfileId;
    }
    return id;
  }

  Future<void> _load() async {
    final auth = context.read<AuthService>();
    final level = widget.levelOverride ??
        auth.currentProfile?.currentLevel ??
        'beginner';
    final profileId = _profileId();
    final picks = await DailySuggestionService.pickTodayItems(
      learnerLevel: level,
      contentType: widget.contentType,
      profileId: profileId,
    );

    // Opening this screen = the profile has VIEWED today's picks.
    // Record them so the wordsLearnedCount tracks engagement (Session
    // 60+ refactor — picks alone no longer count as "seen").
    await DailySuggestionService.recordViewed(
      profileId: profileId,
      contentType: widget.contentType,
      picks: picks,
    );

    final learnedCount = await DailySuggestionService.wordsLearnedCount(
      profileId: profileId,
      contentType: widget.contentType,
    );
    final enabled = await DailySuggestionService.isEnabled();
    final h = await DailySuggestionService.notificationHour();
    final m = await DailySuggestionService.notificationMinute();
    if (!mounted) return;
    setState(() {
      _picks = picks;
      _learnedCount = learnedCount;
      _notificationEnabled = enabled;
      _hour = h;
      _minute = m;
      _loading = false;
    });
  }

  String get _titleText {
    switch (widget.contentType) {
      case DailyContentType.words:
        return "Today's Words";
      case DailyContentType.sentences:
        return "Today's Sentences";
      case DailyContentType.conversations:
        return "Today's Conversations";
    }
  }

  String get _itemNoun {
    switch (widget.contentType) {
      case DailyContentType.words: return 'words';
      case DailyContentType.sentences: return 'sentences';
      case DailyContentType.conversations: return 'conversations';
    }
  }

  Color get _accentColor {
    switch (widget.contentType) {
      case DailyContentType.words: return Colors.green;
      case DailyContentType.sentences: return Colors.orange;
      case DailyContentType.conversations: return Colors.red;
    }
  }

  Future<void> _toggleEnabled(bool v) async {
    if (v) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Notification permission denied. Allow notifications in your phone Settings to use this feature.'),
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }
      await DailySuggestionService.setEnabled(true);
      await NotificationService.instance
          .scheduleDaily(hour: _hour, minute: _minute);
    } else {
      await DailySuggestionService.setEnabled(false);
      await NotificationService.instance.cancelDaily();
    }
    if (!mounted) return;
    setState(() => _notificationEnabled = v);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
      helpText: 'When should we send today\'s words?',
    );
    if (picked == null) return;
    await DailySuggestionService.setNotificationTime(
        picked.hour, picked.minute);
    if (_notificationEnabled) {
      await NotificationService.instance
          .scheduleDaily(hour: picked.hour, minute: picked.minute);
    }
    if (!mounted) return;
    setState(() {
      _hour = picked.hour;
      _minute = picked.minute;
    });
  }

  Future<void> _resetSeen() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset word history?'),
        content: const Text(
            'This will clear your "seen words" list so words you have already learned can be suggested again.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reset')),
        ],
      ),
    );
    if (ok != true) return;
    await DailySuggestionService.resetSeenWords(
      profileId: _profileId(),
      contentType: widget.contentType,
    );
    await _load();
  }

  Future<void> _previewNow() async {
    if (_picks.isEmpty) return;
    await NotificationService.instance.showPreview(_picks);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification sent — check your tray!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleText),
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _intro(),
                  const SizedBox(height: 12),
                  if (_picks.isEmpty)
                    Card(
                      color: Colors.amber.shade50,
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No suggestions yet — try opening a lesson first so we know your level.',
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    )
                  else
                    ..._picks.map((w) => _wordCard(w)),
                  const SizedBox(height: 20),
                  _settingsCard(),
                ],
              ),
            ),
    );
  }

  Widget _intro() {
    final season = DailySuggestionService.seasonFor(DateTime.now());
    final tod = DailySuggestionService.timeOfDayFor(DateTime.now());
    return Card(
      color: _accentColor.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your ${DailySuggestionService.picksPerDay} $_itemNoun for today',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _accentColor),
            ),
            const SizedBox(height: 4),
            Text(
              'Chosen for $tod, ${season == "wet" ? "rainy" : "dry"} season',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            // v1.17.4+ — per-profile learned counter. Increments when
            // the profile opens this screen (recordViewed in _load).
            // Pattern matches the games' seen-words coverage tracker
            // from Session 113.
            Row(
              children: [
                Icon(Icons.emoji_events, size: 18, color: _accentColor),
                const SizedBox(width: 6),
                Text(
                  '$_learnedCount $_itemNoun learned',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _accentColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _wordCard(DailyWord w) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: PackImage(
                  awingWord: w.awing,
                  english: w.english,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    w.awing,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    w.english,
                    style: TextStyle(
                        fontSize: 15, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    w.reason,
                    style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: _accentColor),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.volume_up, color: _accentColor),
              iconSize: 32,
              onPressed: () => _pronunciation.speakAwing(w.awing),
              tooltip: 'Hear it',
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsCard() {
    final time = TimeOfDay(hour: _hour, minute: _minute);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Daily notification'),
              subtitle: Text(
                  'Send 3 new words every day at ${time.format(context)}'),
              value: _notificationEnabled,
              onChanged: _toggleEnabled,
            ),
            if (_notificationEnabled)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text('Time'),
                subtitle: Text(time.format(context)),
                trailing: TextButton(
                  onPressed: _pickTime,
                  child: const Text('Change'),
                ),
              ),
            if (_notificationEnabled)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_active),
                title: const Text('Send preview now'),
                subtitle: const Text('See what the notification looks like'),
                onTap: _previewNow,
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.refresh),
              title: const Text('Reset word history'),
              subtitle: const Text(
                  'Allow already-seen words to appear in suggestions again'),
              onTap: _resetSeen,
            ),
          ],
        ),
      ),
    );
  }
}
