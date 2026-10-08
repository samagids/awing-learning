// record_picker_screen.dart
// ---------------------------------------------------------------
// v1.18.0+ — The "still needs a native voice" picker.
//
// v1.18.0 (Session 60 continuation):
//   • Difficulty chips now respect AuthService.isLevelUnlocked():
//     chips for locked modes are hidden. Default _maxDifficulty
//     is the user's highest unlocked level so contributors land on
//     content they actually have access to.
//   • Category grid → denser horizontal list (more visible per
//     screen, easier to scan).
//
// Hides:
//   1. Words that already have an approved native recording
//      (NativeAudioInventory.hasCanonical).
//   2. Words the current device has submitted within the last
//      30 days (LocalPendingService).
//
// Tapping a word pushes RecordAudioScreen with the word
// pre-selected, so the contributor goes straight into recording.
// ---------------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/components/pack_image.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/native_audio_inventory.dart';
import 'package:awing_ai_learning/services/local_pending_service.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/screens/contribute/record_audio_screen.dart';

const Color _kGreen = Color(0xFF006432);
const Color _kGreenLight = Color(0xFFE8F5E9);

const Map<String, _CategoryMeta> _kCategories = {
  'body':         _CategoryMeta('Body', '👤'),
  'food':         _CategoryMeta('Food', '🍎'),
  'animals':      _CategoryMeta('Animals', '🐐'),
  'nature':       _CategoryMeta('Nature', '🌳'),
  'family':       _CategoryMeta('Family', '👪'),
  'actions':      _CategoryMeta('Actions', '🏃'),
  'things':       _CategoryMeta('Things', '🧺'),
  'descriptive':  _CategoryMeta('Descriptive', '✨'),
  'numbers':      _CategoryMeta('Numbers', '🔢'),
  'pronouns':     _CategoryMeta('Pronouns', '🙋🏾'),
  'time':         _CategoryMeta('Time', '⏰'),
  'classroom':    _CategoryMeta('Classroom', '🏫'),
  'daily':        _CategoryMeta('Daily', '📅'),
  'question':     _CategoryMeta('Question', '❓'),
  'greeting':     _CategoryMeta('Greetings', '👋🏾'),
};

class _CategoryMeta {
  final String label;
  final String emoji;
  const _CategoryMeta(this.label, this.emoji);
}

class RecordPickerScreen extends StatefulWidget {
  const RecordPickerScreen({super.key});

  @override
  State<RecordPickerScreen> createState() => _RecordPickerScreenState();
}

class _RecordPickerScreenState extends State<RecordPickerScreen> {
  int _maxDifficulty = 1;
  bool _loading = true;
  bool _showMediumChip = false;
  bool _showExpertChip = false;

  Set<String> _pendingKeys = {};
  Map<String, List<AwingWord>> _unrecordedByCategory = {};

  // ---- developer re-record search ----------------------------------
  //
  // The picker's whole job is to HIDE words that already have a native
  // voice, so a contributor is never sent to re-record something that is
  // done. That is right for a contributor and wrong for Dr. Sama: when a
  // clip is simply wrong - mispronounced, clipped, the wrong word - the
  // one person who can replace it is the one person the filter stops.
  //
  // So in developer mode only, a search box over the WHOLE vocabulary,
  // recorded or not, with the existing clip playable from the row so the
  // bad one can be heard before it is replaced.
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  static const int _kMaxSearchResults = 80;

  @override
  void initState() {
    super.initState();
    _initUnlockState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Every vocabulary entry matching [_query], ignoring the recorded and
  /// pending filters entirely. Developer mode only.
  List<AwingWord> get _searchResults {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final out = <AwingWord>[];
    for (final w in allVocabulary) {
      if (w.awing.isEmpty || w.english.isEmpty) continue;
      if (w.awing.toLowerCase().contains(q) ||
          w.english.toLowerCase().contains(q) ||
          PronunciationService.audioKey(w.awing).contains(q)) {
        out.add(w);
        if (out.length >= _kMaxSearchResults) break;
      }
    }
    out.sort((a, b) =>
        a.english.toLowerCase().compareTo(b.english.toLowerCase()));
    return out;
  }

  Future<void> _reRecord(AwingWord w) async {
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RecordAudioScreen(preSelectedWord: w),
      ),
    );
    if (done == true) {
      await _refreshPending();
      _rebuild();
      if (mounted) setState(() {});
    }
  }

  void _initUnlockState() {
    final auth = context.read<AuthService>();
    _showMediumChip = auth.isLevelUnlocked('medium');
    _showExpertChip = auth.isLevelUnlocked('expert');
    if (_showExpertChip) {
      _maxDifficulty = 3;
    } else if (_showMediumChip) {
      _maxDifficulty = 2;
    } else {
      _maxDifficulty = 1;
    }
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait<void>([
      NativeAudioInventory.instance.load(),
      _refreshPending(),
    ]);
    _rebuild();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refreshPending() async {
    _pendingKeys = await LocalPendingService.getPendingKeys();
  }

  void _rebuild() {
    final inv = NativeAudioInventory.instance;
    final result = <String, List<AwingWord>>{};
    for (final w in allVocabulary) {
      if (w.awing.isEmpty || w.english.isEmpty) continue;
      if (w.difficulty > _maxDifficulty) continue;
      final key = PronunciationService.audioKey(w.awing);
      // Hide words that ANY native speaker has already recorded —
      // canonical adult (Dr. Sama / Berlin) OR any kid (Joel /
      // Janelle / Joyce / Jadyne / etc.). Per Dr. Sama: a word that's
      // covered by ANY native voice should not be re-recorded.
      if (inv.hasAnyRecording(key)) continue;
      if (_pendingKeys.contains(key)) continue;
      result.putIfAbsent(w.category, () => []).add(w);
    }
    for (final list in result.values) {
      list.sort((a, b) =>
          a.english.toLowerCase().compareTo(b.english.toLowerCase()));
    }
    _unrecordedByCategory = result;
  }

  int get _totalUnrecorded =>
      _unrecordedByCategory.values.fold<int>(0, (s, l) => s + l.length);

  Future<void> _openCategory(String catId) async {
    final words = _unrecordedByCategory[catId];
    if (words == null || words.isEmpty) return;
    final meta = _kCategories[catId] ??
        _CategoryMeta(catId[0].toUpperCase() + catId.substring(1), '📂');
    final picked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _WordListScreen(
          title: '${meta.emoji} ${meta.label}',
          words: words,
        ),
      ),
    );
    if (picked == true) {
      await _refreshPending();
      _rebuild();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDev = context.watch<AuthService>().isDeveloper;
    final searching = isDev && _query.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        if (isDev) _buildDevSearchBar(),
        const Divider(height: 1),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (searching)
          Expanded(child: _buildSearchResults())
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAll,
              child: _buildCategoryList(),
            ),
          ),
      ],
    );
  }

  Widget _buildDevSearchBar() {
    return Container(
      color: Colors.amber.shade50,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.build, size: 15, color: Color(0xFF8A6D00)),
              const SizedBox(width: 6),
              Text(
                'Developer: re-record any word',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
            autocorrect: false,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search Awing or English — recorded words included',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      tooltip: 'Clear',
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = _searchResults;
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No word matches "${_query.trim()}".',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ),
      );
    }
    final inv = NativeAudioInventory.instance;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length + 1,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        if (i == results.length) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Text(
              results.length >= _kMaxSearchResults
                  ? 'Showing the first $_kMaxSearchResults matches. '
                      'Type more to narrow it down.'
                  : '${results.length} match'
                      '${results.length == 1 ? '' : 'es'}.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          );
        }
        final w = results[i];
        final key = PronunciationService.audioKey(w.awing);
        final recorded = inv.hasAnyRecording(key);
        final pending = _pendingKeys.contains(key);
        return ListTile(
          leading: SizedBox(
            width: 48,
            height: 48,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: PackImage(
                awingWord: w.awing,
                english: w.english,
                fit: BoxFit.cover,
              ),
            ),
          ),
          title: Text(
            w.awing,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(w.english, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 2),
              Text(
                pending
                    ? 'Submitted from this device — recording again replaces it'
                    : recorded
                        ? 'Has a native recording — recording again replaces it'
                        : 'No recording yet',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: (recorded || pending)
                      ? Colors.orange.shade800
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          isThreeLine: true,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hear the bad clip before replacing it. Without this the
              // only way to tell which of five near-spellings is the one
              // that sounds wrong is to record all five.
              if (recorded)
                IconButton(
                  icon: const Icon(Icons.volume_up, color: _kGreen),
                  tooltip: 'Play the current recording',
                  onPressed: () => PronunciationService().speakAwing(w.awing),
                ),
              IconButton(
                icon: const Icon(Icons.mic, color: _kGreen),
                tooltip: recorded ? 'Re-record' : 'Record',
                onPressed: () => _reRecord(w),
              ),
            ],
          ),
          onTap: () => _reRecord(w),
        );
      },
    );
  }

  Widget _buildHeader() {
    final showLevelRow = _showMediumChip || _showExpertChip;
    return Container(
      color: _kGreenLight,
      padding: EdgeInsets.fromLTRB(16, 12, 16, showLevelRow ? 12 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_totalUnrecorded words still need a native voice',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _kGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pick a category, then tap a word to record it.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          if (showLevelRow) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Level:', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                _difficultyChip('Beginner', 1),
                if (_showMediumChip) ...[
                  const SizedBox(width: 6),
                  _difficultyChip('+ Medium', 2),
                ],
                if (_showExpertChip) ...[
                  const SizedBox(width: 6),
                  _difficultyChip('+ Expert', 3),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _difficultyChip(String label, int level) {
    final selected = _maxDifficulty == level;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) {
        if (_maxDifficulty == level) return;
        setState(() {
          _maxDifficulty = level;
          _rebuild();
        });
      },
      selectedColor: _kGreen,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildCategoryList() {
    if (_unrecordedByCategory.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 64, color: _kGreen),
                  const SizedBox(height: 16),
                  Text(
                    'Nothing left to record at this level!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (_showMediumChip || _showExpertChip)
                    Text(
                      'Try a higher difficulty above to find more '
                      'words that need a voice.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    )
                  else
                    Text(
                      'Keep learning Beginner lessons — Medium will '
                      'unlock more words to record!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final sortedEntries = _unrecordedByCategory.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: sortedEntries.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (_, i) {
        final entry = sortedEntries[i];
        final meta = _kCategories[entry.key] ??
            _CategoryMeta(
              entry.key.isEmpty
                  ? 'Other'
                  : entry.key[0].toUpperCase() + entry.key.substring(1),
              '📂',
            );
        final remaining = entry.value.length;
        return ListTile(
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: _kGreenLight,
            child: Text(meta.emoji,
                style: const TextStyle(fontSize: 22)),
          ),
          title: Text(
            meta.label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '$remaining word${remaining == 1 ? "" : "s"} need a voice',
            style: TextStyle(
                fontSize: 12.5, color: Colors.grey.shade700),
          ),
          trailing: const Icon(Icons.chevron_right, color: _kGreen),
          onTap: () => _openCategory(entry.key),
        );
      },
    );
  }
}

class _WordListScreen extends StatefulWidget {
  final String title;
  final List<AwingWord> words;
  const _WordListScreen({required this.title, required this.words});

  @override
  State<_WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<_WordListScreen> {
  bool _anyRecorded = false;
  late List<AwingWord> _words;

  @override
  void initState() {
    super.initState();
    _words = List.of(widget.words);
  }

  Future<void> _recordWord(AwingWord w) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RecordAudioScreen(preSelectedWord: w),
      ),
    );
    if (result == true) {
      _anyRecorded = true;
      setState(() => _words.remove(w));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_anyRecorded);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: _kGreen,
          foregroundColor: Colors.white,
        ),
        body: _words.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 48, color: _kGreen),
                      const SizedBox(height: 12),
                      Text(
                        'All done in this category!',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _words.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final w = _words[i];
                  return ListTile(
                    leading: SizedBox(
                      width: 48,
                      height: 48,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: PackImage(
                          awingWord: w.awing,
                          english: w.english,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    title: Text(
                      w.awing,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(w.english,
                        style: const TextStyle(fontSize: 13)),
                    trailing: const Icon(Icons.mic, color: _kGreen),
                    onTap: () => _recordWord(w),
                  );
                },
              ),
      ),
    );
  }
}
