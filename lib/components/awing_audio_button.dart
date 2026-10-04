import 'package:flutter/material.dart';

import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/screens/contribute/record_audio_screen.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';

/// The audio control for an Awing word: a speaker when a human has recorded
/// it, an invitation to record when nobody has.
///
/// ## Why this exists (v1.24.0, NACDA DMV feedback)
///
/// Until now every word had a speaker button, because a Swahili neural voice
/// would synthesize anything. That voice cannot produce Awing tone, so for
/// the ~95% of the dictionary with no human recording the app was teaching
/// children a confidently wrong pronunciation. Synthetic Awing is now gone
/// (see [PronunciationService.speakAwing]).
///
/// That leaves a choice about the silent majority. A dead speaker button is
/// the worst answer — it looks broken and tells the user nothing. So a word
/// with no recording asks for one instead, which turns the gap into the
/// thing that closes it: tapping goes straight to the recorder with the word
/// already selected, where the contributor can record the audio AND
/// photograph the item.
///
/// ## Reading the state
///
/// The existence check is asynchronous (it asks the asset pack), so there
/// are three visual states, not two. While checking, the control is shown
/// disabled rather than guessed at — flashing a speaker and then swapping it
/// for a microphone reads as a bug.
class AwingAudioButton extends StatefulWidget {
  /// The Awing text to play, or to record if there is nothing to play.
  final String awing;

  /// Supply when the caller already has the full entry; otherwise it is
  /// looked up by spelling so a bare String call site still gets the
  /// recorder pre-filled.
  final AwingWord? word;

  final double iconSize;

  /// Colour of the speaker when audio exists. The record state uses its own
  /// colour on purpose — it is a different action and should not masquerade
  /// as a play button.
  final Color? color;

  /// Set false on surfaces where being sent off to the recorder would derail
  /// what the user is doing — mid-quiz, mid-game. Those stay silent.
  final bool offerToRecord;

  const AwingAudioButton({
    Key? key,
    required this.awing,
    this.word,
    this.iconSize = 24,
    this.color,
    this.offerToRecord = true,
  }) : super(key: key);

  @override
  State<AwingAudioButton> createState() => _AwingAudioButtonState();
}

class _AwingAudioButtonState extends State<AwingAudioButton> {
  static const Color _kGreen = Color(0xFF006432);

  /// null while the check is in flight.
  bool? _hasAudio;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void didUpdateWidget(AwingAudioButton old) {
    super.didUpdateWidget(old);
    // Flashcards and quiz screens reuse one widget for a stream of words.
    // Without this the second word inherits the first word's answer.
    if (old.awing != widget.awing) {
      setState(() => _hasAudio = null);
      _check();
    }
  }

  Future<void> _check() async {
    final target = widget.awing;
    final has = await PronunciationService().hasNativeAudio(target);
    // The word may have moved on while the pack was being read.
    if (!mounted || target != widget.awing) return;
    setState(() => _hasAudio = has);
  }

  AwingWord? _resolveWord() {
    if (widget.word != null) return widget.word;
    final needle = widget.awing.trim();
    for (final w in allVocabulary) {
      if (w.awing == needle) return w;
    }
    return null;
  }

  Future<void> _openRecorder() async {
    final word = _resolveWord();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecordAudioScreen(preSelectedWord: word),
      ),
    );
    // A contribution does not become playable until it has been approved and
    // shipped in a build, so re-checking on return will almost always still
    // say "no". Re-check anyway: it costs nothing and it is correct if the
    // word happened to arrive in the meantime.
    if (mounted) _check();
  }

  @override
  Widget build(BuildContext context) {
    final has = _hasAudio;

    if (has == null) {
      return IconButton(
        iconSize: widget.iconSize,
        onPressed: null,
        icon: Icon(Icons.volume_up, size: widget.iconSize, color: Colors.grey.shade300),
        tooltip: 'Checking for a recording…',
      );
    }

    if (has) {
      return IconButton(
        iconSize: widget.iconSize,
        color: widget.color ?? _kGreen,
        icon: Icon(Icons.volume_up, size: widget.iconSize),
        tooltip: 'Play ${widget.awing}',
        onPressed: () => PronunciationService().speakAwing(widget.awing),
      );
    }

    if (!widget.offerToRecord) {
      // Silent and unclickable, but visibly so — not a button that does
      // nothing when pressed.
      return IconButton(
        iconSize: widget.iconSize,
        onPressed: null,
        icon: Icon(Icons.volume_off, size: widget.iconSize, color: Colors.grey.shade400),
        tooltip: 'No recording yet',
      );
    }

    return IconButton(
      iconSize: widget.iconSize,
      color: Colors.orange.shade800,
      icon: Icon(Icons.mic_none, size: widget.iconSize),
      tooltip: 'No recording yet — tap to record ${widget.awing}',
      onPressed: _openRecorder,
    );
  }
}

/// Inline row form for places with space for a sentence of explanation —
/// a word's detail panel rather than a dense list.
class AwingAudioRow extends StatelessWidget {
  final String awing;
  final AwingWord? word;

  const AwingAudioRow({Key? key, required this.awing, this.word})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: PronunciationService().hasNativeAudio(awing),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(height: 48);
        }
        if (snap.data == true) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AwingAudioButton(awing: awing, word: word),
              Text('Recorded by a native speaker',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AwingAudioButton(awing: awing, word: word),
            Expanded(
              child: Text(
                'Nobody has recorded this word yet. Tap the microphone to say '
                'it and add a photo.',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Prominent labelled form, for a flashcard's main call to action where the
/// button carries text as well as an icon.
///
/// The label changes with the state — "Hear it" when there is a recording,
/// "Record it" when there is not. A button that said "Hear it" and then did
/// nothing is exactly the dead end this release is removing.
class AwingAudioActionButton extends StatefulWidget {
  final String awing;
  final AwingWord? word;

  /// Colour when audio exists. The record state uses amber regardless, so
  /// the two actions never look interchangeable.
  final Color playColor;

  const AwingAudioActionButton({
    Key? key,
    required this.awing,
    this.word,
    this.playColor = const Color(0xFFDAA520),
  }) : super(key: key);

  @override
  State<AwingAudioActionButton> createState() => _AwingAudioActionButtonState();
}

class _AwingAudioActionButtonState extends State<AwingAudioActionButton> {
  bool? _hasAudio;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void didUpdateWidget(AwingAudioActionButton old) {
    super.didUpdateWidget(old);
    if (old.awing != widget.awing) {
      setState(() => _hasAudio = null);
      _check();
    }
  }

  Future<void> _check() async {
    final target = widget.awing;
    final has = await PronunciationService().hasNativeAudio(target);
    if (!mounted || target != widget.awing) return;
    setState(() => _hasAudio = has);
  }

  AwingWord? _resolveWord() {
    if (widget.word != null) return widget.word;
    final needle = widget.awing.trim();
    for (final w in allVocabulary) {
      if (w.awing == needle) return w;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final has = _hasAudio;
    final style = ElevatedButton.styleFrom(
      backgroundColor: has == true
          ? widget.playColor
          : (has == null ? Colors.grey.shade300 : Colors.orange.shade800),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );

    if (has == null) {
      return ElevatedButton.icon(
        onPressed: null,
        style: style,
        icon: const Icon(Icons.volume_up, size: 24),
        label: const Text('Hear it', style: TextStyle(fontSize: 17)),
      );
    }

    if (has) {
      return ElevatedButton.icon(
        onPressed: () => PronunciationService().speakAwing(widget.awing),
        style: style,
        icon: const Icon(Icons.volume_up, size: 24),
        label: const Text('Hear it', style: TextStyle(fontSize: 17)),
      );
    }

    return ElevatedButton.icon(
      onPressed: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RecordAudioScreen(preSelectedWord: _resolveWord()),
          ),
        );
        if (mounted) _check();
      },
      style: style,
      icon: const Icon(Icons.mic_none, size: 24),
      label: const Text('Record it', style: TextStyle(fontSize: 17)),
    );
  }
}
