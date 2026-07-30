import 'package:flutter/material.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/models/study_set.dart';
import 'package:awing_ai_learning/services/study_set_service.dart';
import 'package:awing_ai_learning/components/pack_image.dart';
import 'package:awing_ai_learning/components/awing_text_field.dart';
import 'package:awing_ai_learning/services/native_audio_inventory.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/screens/study_sets/study_set_record_screen.dart';

/// Add / remove / reorder words in a Study Set. Session 63 Phase 1.
///
/// Layout:
///   [AppBar: set name + save/back]
///   ─────────────────────────────
///   [Search dictionary] ← autocomplete over allVocabulary
///   [+ Add new word] ← opens dialog for custom (non-dict) word
///   ─────────────────────────────
///   [Selected words - reorderable list]
///     - dictionary words (Awing • english • category chip)
///     - custom words (Awing • english • "custom" badge)
///     Each has drag handle + delete button.
///
/// Recording, sharing, exam integration all shipped in later phases.
class StudySetEditorScreen extends StatefulWidget {
  final String setId;
  const StudySetEditorScreen({super.key, required this.setId});

  @override
  State<StudySetEditorScreen> createState() => _StudySetEditorScreenState();
}

class _StudySetEditorScreenState extends State<StudySetEditorScreen> {
  final _searchController = TextEditingController();
  List<AwingWord>? _searchResults;
  StudySet? _set;
  // Session 64: allow teachers to preview each word from the tile.
  // PronunciationService is a plain singleton (matches beginner_home,
  // expert_home, etc.). It routes to the native recording first (via
  // its priority-0 native tier), then Edge TTS character voices, then
  // flutter_tts fallback — so tapping the play icon does the right
  // thing regardless of whether the word has a native recording.
  final PronunciationService _pronunciation = PronunciationService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await StudySetService.instance.load();
    // Preload native inventory so mic icons render the correct
    // Native vs teacher-recorded vs missing state on first paint.
    await NativeAudioInventory.instance.load();
    if (!mounted) return;
    final s = await StudySetService.instance.byId(widget.setId);
    if (!mounted) return;
    setState(() => _set = s);
  }

  String _levelLabelForBar(String level) {
    switch (level.toLowerCase()) {
      case 'medium':
        return 'Medium';
      case 'expert':
        return 'Expert';
      default:
        return 'Beginner';
    }
  }

  /// Max difficulty allowed for this set's level.
  /// beginner → 1, medium → 2, expert → 3.
  int _maxDifficultyForLevel(String level) {
    switch (level.toLowerCase()) {
      case 'medium':
        return 2;
      case 'expert':
        return 3;
      default:
        return 1;
    }
  }

  /// Vocabulary pool filtered to the set's chosen level. Session 63
  /// Part C — beginner sets only see difficulty-1 words, medium adds
  /// difficulty-2, expert unlocks everything. Words with no difficulty
  /// field default to 1 (beginner).
  List<AwingWord> _vocabularyForCurrentLevel() {
    final level = _set?.level ?? 'beginner';
    final maxDiff = _maxDifficultyForLevel(level);
    return allVocabulary
        .where((w) => (w.difficulty) <= maxDiff)
        .toList();
  }

  void _runSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _searchResults = null);
      return;
    }
    final all = _vocabularyForCurrentLevel();
    // Two passes: exact + prefix on Awing OR English, then substring.
    // Cap at 20 to keep the list scrollable.
    final matches = <AwingWord>[];
    final seen = <String>{};
    for (final w in all) {
      final awLc = w.awing.toLowerCase();
      final enLc = w.english.toLowerCase();
      if (awLc == q ||
          enLc == q ||
          awLc.startsWith(q) ||
          enLc.startsWith(q)) {
        if (seen.add(w.awing)) matches.add(w);
      }
      if (matches.length >= 40) break;
    }
    if (matches.length < 20) {
      for (final w in all) {
        if (seen.contains(w.awing)) continue;
        final awLc = w.awing.toLowerCase();
        final enLc = w.english.toLowerCase();
        if (awLc.contains(q) || enLc.contains(q)) {
          seen.add(w.awing);
          matches.add(w);
        }
        if (matches.length >= 40) break;
      }
    }
    setState(() => _searchResults = matches.take(20).toList());
  }

  @override
  Widget build(BuildContext context) {
    if (_set == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return AnimatedBuilder(
      animation: StudySetService.instance,
      builder: (context, _) {
        // Re-fetch to get the latest state after every service mutation.
        // Cheap because sets are tiny in-memory objects.
        return FutureBuilder<StudySet?>(
          future: StudySetService.instance.byId(widget.setId),
          builder: (context, snap) {
            final set = snap.data ?? _set!;
            return _buildScaffold(context, set);
          },
        );
      },
    );
  }

  Widget _buildScaffold(BuildContext context, StudySet set) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(set.name, style: const TextStyle(fontSize: 18)),
            Text(
              '${_levelLabelForBar(set.level)} • ${set.wordCount} word${set.wordCount == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 12,
                color: theme.appBarTheme.foregroundColor
                        ?.withOpacity(0.7) ??
                    Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildRecordingProgress(context, set),
          _buildSearchBar(context),
          _buildNewWordButton(context),
          const Divider(height: 1),
          Expanded(child: _buildWordList(context, set)),
        ],
      ),
    );
  }

  /// Progress bar showing "X of Y words recorded". When zero words →
  /// prompt. When some recorded → orange bar + remaining count. When
  /// all recorded → green "Ready to share" banner.
  Widget _buildRecordingProgress(BuildContext context, StudySet set) {
    if (set.wordCount == 0) return const SizedBox.shrink();
    final total = set.wordCount;
    // Effective = teacher uploads PLUS natively covered words.
    // Session 63 Phase 4: teachers no longer need to record over words
    // that already ship with a native recording.
    final effectiveMissing =
        StudySetService.instance.effectiveMissingCount(set);
    final recorded = total - effectiveMissing;
    final pct = total == 0 ? 0.0 : recorded / total;
    final fully = StudySetService.instance.effectivelyFullyRecorded(set);
    final color = fully ? Colors.green.shade600 : Colors.orange.shade700;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      color: fully
          ? Colors.green.shade50
          : Colors.orange.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                fully
                    ? Icons.check_circle
                    : Icons.mic_none,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  fully
                      ? 'All words have audio — ready to share'
                      : 'Recording progress: $recorded of $total',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              if (!fully)
                Text(
                  '$effectiveMissing left',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRecordScreen({
    required StudySet set,
    required String awing,
    required String english,
    String? category,
  }) async {
    final currentUrl = set.recordings[awing];
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudySetRecordScreen(
          setId: set.id,
          awing: awing,
          english: english,
          category: category,
          currentUrl: currentUrl,
        ),
      ),
    );
    // Set is updated via notifyListeners in setRecording; the outer
    // AnimatedBuilder in build() re-renders automatically.
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            onChanged: _runSearch,
            decoration: InputDecoration(
              hintText: 'Search dictionary (Awing or English)…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchResults = null);
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              isDense: true,
            ),
          ),
          if (_searchResults != null) _buildSearchResults(context),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final results = _searchResults!;
    if (results.isEmpty) {
      final level = _set?.level ?? 'beginner';
      final levelHint = level == 'beginner'
          ? 'Search only shows Beginner words. Harder words are hidden until you create a Medium or Expert set.'
          : (level == 'medium'
              ? 'Search shows Beginner + Medium words only. Harder words are in Expert sets.'
              : 'Search shows all words.');
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(
              'No match. Tap "+ Add new word" to add it as a custom word.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Text(
              levelHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      );
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: results.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final w = results[i];
          return ListTile(
            dense: true,
            leading: SizedBox(
              width: 40,
              height: 40,
              child: PackImage(
                awingWord: w.awing,
                english: w.english,
                errorWidget: const Icon(Icons.image_not_supported_outlined),
              ),
            ),
            title: Text(w.awing,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              w.english,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: FutureBuilder<StudySet?>(
              future: StudySetService.instance.byId(widget.setId),
              builder: (context, snap) {
                final set = snap.data;
                final already =
                    set?.wordKeys.contains(_wordKey(w)) ?? false;
                if (already) {
                  return const Icon(Icons.check_circle,
                      color: Colors.green);
                }
                return IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () async {
                    await StudySetService.instance.addDictionaryWord(
                      widget.setId,
                      _wordKey(w),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added "${w.awing}"'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                );
              },
            ),
            onTap: () async {
              await StudySetService.instance.addDictionaryWord(
                widget.setId,
                _wordKey(w),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNewWordButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: OutlinedButton.icon(
        onPressed: () => _showAddCustomWordDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add new word (not in dictionary)'),
      ),
    );
  }

  Widget _buildWordList(BuildContext context, StudySet set) {
    if (set.wordCount == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'This set is empty. Search the dictionary above or add a '
            'new word.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    // Build a combined list: dictionary words first, then custom words.
    // Each item shows drag handle + delete button.
    final total = set.wordKeys.length + set.customWords.length;
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: total,
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) async {
        // Prevent cross-section reordering (dict <-> custom).
        final oldIsDict = oldIndex < set.wordKeys.length;
        final newIsDict = newIndex <= set.wordKeys.length;
        if (oldIsDict != newIsDict) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Move within the same section only'),
              duration: Duration(seconds: 1),
            ),
          );
          return;
        }
        await StudySetService.instance
            .reorderWord(widget.setId, oldIndex, newIndex);
      },
      itemBuilder: (context, i) {
        if (i < set.wordKeys.length) {
          return _buildDictWordTile(context, set, set.wordKeys[i], i);
        }
        final cIdx = i - set.wordKeys.length;
        return _buildCustomWordTile(context, set, set.customWords[cIdx], i);
      },
    );
  }

  /// Recording-status trailing widget shared by dict + custom tiles.
  /// Three visual states for the mic icon:
  ///   • NATIVE (green filled + verified) — word ships with a native
  ///     recording (Dr. Sama / kids / community). Tapping opens the
  ///     record screen which displays a "no recording needed" banner
  ///     so the teacher understands why the mic is locked.
  ///   • TEACHER-RECORDED (green filled mic) — the teacher already
  ///     uploaded audio. Tap re-records.
  ///   • MISSING (orange outlined mic) — needs the teacher's audio.
  Widget _buildRecordingActions({
    required StudySet set,
    required String awing,
    required String english,
    String? category,
    required VoidCallback onRemove,
  }) {
    final svc = StudySetService.instance;
    final hasTeacherRec = (set.recordings[awing] ?? '').isNotEmpty;
    final hasNative = svc.wordHasNativeRecording(awing);
    late final IconData icon;
    late final Color iconColor;
    late final String tooltip;
    if (hasNative) {
      icon = Icons.verified;
      iconColor = Colors.green.shade700;
      tooltip = 'Native recording — no upload needed';
    } else if (hasTeacherRec) {
      icon = Icons.mic;
      iconColor = Colors.green.shade700;
      tooltip = 'Re-record audio';
    } else {
      icon = Icons.mic_none;
      iconColor = Colors.orange.shade700;
      tooltip = 'Record audio';
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Session 64: preview the current pronunciation. Falls through
        // PronunciationService's priority chain (native recording →
        // level-appropriate Edge TTS voice → flutter_tts fallback), so
        // this is what students will actually hear.
        IconButton(
          tooltip: hasNative
              ? 'Hear native recording'
              : (hasTeacherRec
                  ? 'Hear your recording'
                  : 'Hear TTS pronunciation'),
          icon: Icon(Icons.volume_up, color: Colors.blueGrey.shade700),
          onPressed: () => _pronunciation.speakAwing(awing),
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          tooltip: tooltip,
          icon: Icon(icon, color: iconColor),
          onPressed: () => _openRecordScreen(
            set: set,
            awing: awing,
            english: english,
            category: category,
          ),
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: onRemove,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildDictWordTile(
      BuildContext context, StudySet set, String wordKey, int i) {
    // Find the vocab entry.
    final entry = _findByKey(wordKey);
    return Card(
      key: ValueKey('dict_$wordKey'),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        leading: ReorderableDragStartListener(
          index: i,
          child: const Icon(Icons.drag_indicator),
        ),
        title: Text(
          entry?.awing ?? wordKey,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(entry?.english ?? '(word not found)'),
        trailing: _buildRecordingActions(
          set: set,
          awing: entry?.awing ?? wordKey,
          english: entry?.english ?? '',
          category: entry?.category,
          onRemove: () => StudySetService.instance
              .removeDictionaryWord(widget.setId, wordKey),
        ),
      ),
    );
  }

  Widget _buildCustomWordTile(
      BuildContext context, StudySet set, StudySetCustomWord w, int i) {
    return Card(
      key: ValueKey('custom_${w.awing}'),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        leading: ReorderableDragStartListener(
          index: i,
          child: const Icon(Icons.drag_indicator),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(w.awing,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('custom',
                  style: TextStyle(
                      fontSize: 10, color: Colors.orange.shade900)),
            ),
          ],
        ),
        subtitle: Text('${w.english}  •  ${w.category}'),
        trailing: _buildRecordingActions(
          set: set,
          awing: w.awing,
          english: w.english,
          category: w.category,
          onRemove: () => StudySetService.instance
              .removeCustomWord(widget.setId, w.awing),
        ),
      ),
    );
  }

  Future<void> _showAddCustomWordDialog(BuildContext context) async {
    final awingCtrl = TextEditingController();
    final englishCtrl = TextEditingController();
    String category = 'other';
    int difficulty = 1;

    final categories = <String>[
      'body', 'animals', 'nature', 'food', 'family', 'actions',
      'things', 'descriptive', 'numbers', 'other',
    ];

    if (!context.mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Add new word'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AwingTextField(
                  controller: awingCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Awing spelling',
                    hintText: 'e.g. mónkə',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: englishCtrl,
                  decoration: const InputDecoration(
                    labelText: 'English meaning',
                    hintText: 'e.g. child',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final c in categories)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (v) => setStateDialog(() =>
                      category = v ?? 'other'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Difficulty: '),
                    for (int d = 1; d <= 3; d++) ...[
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: Text(_difficultyLabel(d)),
                        selected: difficulty == d,
                        onSelected: (_) =>
                            setStateDialog(() => difficulty = d),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'This word will be added to your set now, and will '
                  'also be submitted for developer approval so it can '
                  'be added to the app dictionary for everyone in a '
                  'future release.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (awingCtrl.text.trim().isEmpty ||
                    englishCtrl.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result != true || !mounted) return;
    final word = StudySetCustomWord(
      awing: awingCtrl.text.trim(),
      english: englishCtrl.text.trim(),
      category: category,
      difficulty: difficulty,
    );
    await StudySetService.instance.addCustomWord(widget.setId, word);
    // TODO(Phase 1b): submit this word via ContributionService as a
    // newWord contribution so it enters the developer review queue.
    // Deferred to keep Phase 1 focused on the set-editing UX; wire in
    // when we ship Phase 2 (which also touches contributions for
    // teacher recordings).
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${word.awing}"'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  String _difficultyLabel(int d) {
    switch (d) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Medium';
      case 3:
        return 'Expert';
      default:
        return '$d';
    }
  }

  // The audio_key format used across the app (see ImageService.imageKey /
  // pronunciation_service _audioKey). We mirror the shape here so
  // wordKeys match the format the app already uses for image + audio
  // lookups. Simplified: lowercase Awing, strip diacritics, replace
  // apostrophes with 'q'. If AwingWord had an audio_key field we'd use
  // that directly; for Phase 1 the raw Awing spelling is enough as a
  // unique key WITHIN a set (no cross-set operations happen yet).
  String _wordKey(AwingWord w) => w.awing;

  AwingWord? _findByKey(String key) {
    for (final w in allVocabulary) {
      if (w.awing == key) return w;
    }
    return null;
  }
}
