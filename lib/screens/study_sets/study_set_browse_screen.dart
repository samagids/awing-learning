import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/models/study_set.dart';
import 'package:awing_ai_learning/services/study_set_service.dart';
import 'package:awing_ai_learning/components/pack_image.dart';

/// Student-facing read-only browse of a shared Study Set. Session 63
/// Phase 2.
///
/// Shows:
///   - Set name + teacher name in the AppBar
///   - Word count + how many have audio ready (Phase 3 populates
///     recordings; for now shows "audio coming soon")
///   - Word list: Awing • English • image • audio button (disabled
///     until Phase 3 wires the audio player)
///
/// Kids CANNOT edit or reorder — this is a study reference. Exam-day
/// questions will be sourced from these words (Phase 4).
class StudySetBrowseScreen extends StatelessWidget {
  final String setId;
  const StudySetBrowseScreen({super.key, required this.setId});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StudySetService.instance,
      builder: (context, _) {
        return FutureBuilder<StudySet?>(
          future: StudySetService.instance.byId(setId),
          builder: (context, snap) {
            final set = snap.data;
            if (set == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return _buildScaffold(context, set);
          },
        );
      },
    );
  }

  Widget _buildScaffold(BuildContext context, StudySet set) {
    final theme = Theme.of(context);
    final totalWords = set.wordCount;
    final withAudio = totalWords - set.missingRecordingsCount;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(set.name, style: const TextStyle(fontSize: 18)),
            Text(
              'From ${set.teacherName.isEmpty ? set.teacherEmail : set.teacherName}',
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            child: Text(
              '$totalWords word${totalWords == 1 ? '' : 's'}  •  '
              '$withAudio with audio ready',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildWordList(context, set)),
        ],
      ),
    );
  }

  Widget _buildWordList(BuildContext context, StudySet set) {
    // Merge dict + custom words into one flat list for display.
    final items = <_BrowseItem>[];
    for (final key in set.wordKeys) {
      final entry = _findByKey(key);
      items.add(_BrowseItem.fromDictionary(entry, key));
    }
    for (final w in set.customWords) {
      items.add(_BrowseItem.fromCustom(w));
    }
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'This set is empty. The teacher will add words soon.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) =>
          _buildTile(context, set, items[i]),
    );
  }

  Widget _buildTile(BuildContext context, StudySet set, _BrowseItem item) {
    final theme = Theme.of(context);
    final hasAudio =
        (set.recordings[item.awing] ?? '').isNotEmpty;
    return ListTile(
      leading: SizedBox(
        width: 44,
        height: 44,
        child: item.isCustom
            ? Container(
                color: Colors.orange.shade100,
                child: Icon(
                  Icons.new_releases_outlined,
                  color: Colors.orange.shade700,
                ),
              )
            : PackImage(
                awingWord: item.awing,
                english: item.english,
                errorWidget:
                    const Icon(Icons.image_not_supported_outlined),
              ),
      ),
      title: Text(
        item.awing,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(item.english),
      trailing: hasAudio
          ? _CloudPlayButton(url: set.recordings[item.awing]!)
          : Tooltip(
              message: 'No recording yet',
              child: Icon(
                Icons.volume_off,
                color: theme.disabledColor,
              ),
            ),
    );
  }

  AwingWord? _findByKey(String key) {
    for (final w in allVocabulary) {
      if (w.awing == key) return w;
    }
    return null;
  }
}

class _BrowseItem {
  final String awing;
  final String english;
  final bool isCustom;

  const _BrowseItem({
    required this.awing,
    required this.english,
    required this.isCustom,
  });

  factory _BrowseItem.fromDictionary(AwingWord? w, String fallbackKey) {
    if (w == null) {
      return _BrowseItem(
        awing: fallbackKey,
        english: '(word not found)',
        isCustom: false,
      );
    }
    return _BrowseItem(awing: w.awing, english: w.english, isCustom: false);
  }

  factory _BrowseItem.fromCustom(StudySetCustomWord w) {
    return _BrowseItem(awing: w.awing, english: w.english, isCustom: true);
  }
}

/// Play button that streams a cloud-recorded m4a URL. Owns its own
/// AudioPlayer so multiple rows can be played independently (each
/// button toggles its own playback state).
class _CloudPlayButton extends StatefulWidget {
  final String url;
  const _CloudPlayButton({required this.url});

  @override
  State<_CloudPlayButton> createState() => _CloudPlayButtonState();
}

class _CloudPlayButtonState extends State<_CloudPlayButton> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.stop();
      if (!mounted) return;
      setState(() => _playing = false);
      return;
    }
    setState(() => _loading = true);
    try {
      await _player.play(UrlSource(widget.url));
      if (!mounted) return;
      setState(() {
        _loading = false;
        _playing = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not play recording: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      );
    }
    return IconButton(
      tooltip: _playing ? 'Stop' : 'Play recording',
      icon: Icon(
        _playing ? Icons.stop_circle_outlined : Icons.volume_up,
        color: Colors.green.shade700,
      ),
      onPressed: _toggle,
    );
  }
}
