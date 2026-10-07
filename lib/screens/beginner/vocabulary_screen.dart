import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/data/awing_vocabulary.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/screens/find_similar_sheet.dart';
import 'package:awing_ai_learning/components/pack_image.dart';
import 'package:awing_ai_learning/services/image_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/components/awing_audio_button.dart';
import 'package:awing_ai_learning/services/progress_service.dart';

class VocabularyScreen extends StatefulWidget {
  /// If set, restrict the word pool to words at this exact difficulty.
  /// Beginner mode passes 1 → only "easy" words. Medium passes 2 → only
  /// "difficult" words (NOT also showing Beginner words). Expert passes 3.
  /// When null (legacy callers), shows all vocabulary regardless of
  /// difficulty — kept for backward compatibility with the old "all words"
  /// flashcard entry point.
  final int? difficultyFilter;

  /// Lesson-completion ID. Passed through to AuthService.completeLesson so
  /// the progress-tracking system can distinguish "user opened beginner
  /// vocab" from "user opened medium difficult-words" from "user opened
  /// expert vocab". Defaults to 'beginner_vocabulary' when null.
  final String? lessonId;

  const VocabularyScreen({
    Key? key,
    this.difficultyFilter,
    this.lessonId,
  }) : super(key: key);

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  final PronunciationService _pronunciation = PronunciationService();
  String _selectedCategory = 'all';
  int _currentCard = 0;
  bool _showEnglish = false;

  static const _categories = {
    'all': 'All Words',
    'body': 'Body Parts',
    'animals': 'Animals',
    'nature': 'Nature',
    'food': 'Food & Drink',
    'actions': 'Actions',
    'things': 'Things',
    'family': 'Family & Places',
    'descriptive': 'Descriptive',
    'numbers': 'Numbers',
    'pronouns': 'Pronouns',
  };

  @override
  void initState() {
    super.initState();
    _pronunciation.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().completeLesson(
            widget.lessonId ?? 'beginner_vocabulary',
          );
    });
  }

  /// Returns the vocabulary pool the user can browse here.
  ///
  /// Difficulty-filtered modes (Beginner=1, Medium=2, Expert=3) show ONLY
  /// words at exactly that difficulty. That guarantees the Medium
  /// "Difficult Words" screen never shows words the user already learned
  /// in Beginner, and the Expert screen never shows words from Medium/
  /// Beginner. Words without an explicit `difficulty:` field default to 1
  /// in the data layer, so they appear in Beginner only.
  List<AwingWord> get _words {
    Iterable<AwingWord> pool = allVocabulary;
    if (widget.difficultyFilter != null) {
      pool = pool.where((w) => w.difficulty == widget.difficultyFilter);
    }
    if (_selectedCategory != 'all') {
      pool = pool.where((w) => w.category == _selectedCategory);
    }
    return pool.toList();
  }

  void _nextCard() {
    setState(() {
      _showEnglish = false;
      _currentCard = (_currentCard + 1) % _words.length;
    });
  }

  void _prevCard() {
    setState(() {
      _showEnglish = false;
      _currentCard =
          _currentCard > 0 ? _currentCard - 1 : _words.length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final words = _words;
    if (_currentCard >= words.length) _currentCard = 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Category chips
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: _categories.entries.map((entry) {
                final isSelected = _selectedCategory == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    selectedColor: Colors.green.shade200,
                    onSelected: (_) => setState(() {
                      _selectedCategory = entry.key;
                      _currentCard = 0;
                      _showEnglish = false;
                    }),
                  ),
                );
              }).toList(),
            ),
          ),
          // Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '${_currentCard + 1} / ${words.length}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 16),
          // Flashcard
          Expanded(
            child: words.isEmpty
                // Session 64 (M4): friendlier empty state matching the
                // word_translate.dart pattern — icon + explanation + hint
                // so kids landing on an empty category know to switch.
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No words in this category yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try a different category from the chips above ⬆',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      setState(() => _showEnglish = !_showEnglish);
                      // v1.23.6 (Session 65c) — ProgressService.markWordViewed
                      // had no caller anywhere, so `viewed_words` stayed empty
                      // and the "Word Collector" (10 words) and "Vocabulary
                      // Champion" (67 words) badges could never unlock.
                      //
                      // Counted on the flip to English rather than on mere
                      // display: swiping past a card is not learning a word,
                      // and the badges say "Learn". Idempotent per word.
                      if (_showEnglish) {
                        context
                            .read<ProgressService>()
                            .markWordViewed(words[_currentCard].awing);
                      }
                    },
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity != null) {
                        if (details.primaryVelocity! < 0) {
                          _nextCard();
                        } else if (details.primaryVelocity! > 0) {
                          _prevCard();
                        }
                      }
                    },
                    child: _FlashCard(
                      word: words[_currentCard],
                      showEnglish: _showEnglish,
                      pronunciation: _pronunciation,
                    ),
                  ),
          ),
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _prevCard,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade300,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      setState(() => _showEnglish = !_showEnglish),
                  icon: Icon(_showEnglish
                      ? Icons.visibility_off
                      : Icons.visibility),
                  label: Text(_showEnglish ? 'Hide' : 'Show'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _nextCard,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlashCard extends StatelessWidget {
  final AwingWord word;
  final bool showEnglish;
  final PronunciationService pronunciation;

  const _FlashCard({
    required this.word,
    required this.showEnglish,
    required this.pronunciation,
  });

  /// v1.24.4 — the card used to be a hardcoded Row: image on the left at
  /// BoxFit.cover, text on the right, on every screen size. Two problems,
  /// both reported from a Galaxy S24 Ultra:
  ///
  ///   * `cover` fills the half-width box by cropping, so on a tall phone
  ///     most of a square illustration was cut away.
  ///   * half a phone's width is not enough for a 40pt Awing word plus a
  ///     pronunciation guide plus two buttons, so the right side was
  ///     cramped while the left side showed a sliver of picture.
  ///
  /// Now the layout follows the shape of the screen: a phone stacks the
  /// word above the whole picture, a tablet keeps picture-left/word-right.
  /// `contain` everywhere, so an illustration is never cut.
  static const double _tabletBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    // 319 of the 6,417 live words have no illustration on purpose — there
    // is no honest picture of "you (singular)" or "not (negative
    // particle)", and generate_images.py leaves those blank rather than
    // drawing a decorative child in a field. Asking first means those cards
    // show a well-centred word instead of a grey broken-image box.
    final hasImage = ImageService().hasImageSync(word.awing, word.english);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.green.shade50],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= _tabletBreakpoint;
              if (!hasImage) {
                return _details(context, centred: true);
              }
              return wide
                  ? _wideLayout(context)
                  : _tallLayout(context, constraints);
            },
          ),
        ),
      ),
    );
  }

  /// Tablet and landscape: picture on the left, word on the right.
  Widget _wideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _image(
            const BorderRadius.only(
              topLeft: Radius.circular(24),
              bottomLeft: Radius.circular(24),
            ),
          ),
        ),
        Expanded(child: _details(context, centred: true)),
      ],
    );
  }

  /// Phone: the word and its controls on top, the whole picture below.
  ///
  /// The text block is measured first and the picture takes what is left,
  /// rather than splitting 50/50 — revealing the English grows the text and
  /// the picture should yield, not overflow. The floor stops the picture
  /// collapsing to a sliver on a short screen; past that the card scrolls.
  Widget _tallLayout(BuildContext context, BoxConstraints constraints) {
    // A fixed share for the picture and the remainder for the text, rather
    // than Flexible on both: revealing the English grows the text block, and
    // a text block that can push the picture to nothing is worse than one
    // that scrolls. 42% leaves a square illustration comfortably whole on a
    // 20:9 phone while still showing the word, guide and both buttons.
    final imageHeight = constraints.maxHeight * 0.42;
    return Column(
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: _details(context),
        ),
        SizedBox(
          height: imageHeight,
          width: double.infinity,
          child: _image(
            const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
        ),
      ],
    );
  }

  /// BoxFit.contain, always: a cropped illustration teaches the wrong thing
  /// when the cropped-out part is the thing being named.
  Widget _image(BorderRadius radius) {
    return ClipRRect(
      borderRadius: radius,
      child: PackImage(
        awingWord: word.awing,
        english: word.english,
        fit: BoxFit.contain,
      ),
    );
  }

  /// Always scrollable: on a short phone with the English revealed this
  /// block is taller than the space it gets, and scrolling beats a yellow
  /// overflow stripe across a child's flashcard.
  ///
  /// [centred] vertically centres the content when there is room — the
  /// minHeight is what lets Center do anything inside a scroll view.
  Widget _details(BuildContext context, {bool centred = false}) {
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Category badge
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            word.category.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Awing word — auto-shrink to fit narrow phones
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              word.awing,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Pronunciation guide
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            PronunciationService.getPronunciationGuide(
                word.awing),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 14),
        // Hear it + Find similar (v1.17.0 AI)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // v1.24.0: was a plain "Hear it" button that
            // spoke synthetic Awing for any word. Now it
            // reads "Record it" and opens the recorder when
            // nobody has recorded the word.
            AwingAudioActionButton(
              awing: word.awing,
              word: word,
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () => showFindSimilarSheet(
                context,
                awing: word.awing,
                english: word.english,
              ),
              icon: Icon(Icons.psychology_alt,
                  size: 22, color: Colors.deepPurple.shade400),
              label: Text('AI similar',
                  style: TextStyle(
                      fontSize: 15,
                      color: Colors.deepPurple.shade700)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: Colors.deepPurple.shade300),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
        // English translation (shown/hidden)
        AnimatedOpacity(
          opacity: showEnglish ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              children: [
                const Divider(),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        word.english,
                        style: TextStyle(
                          fontSize: 26,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (showEnglish)
                      IconButton(
                        onPressed: () => pronunciation
                            .speakEnglish(word.english),
                        icon: Icon(
                          Icons.volume_up,
                          color: Colors.green.shade600,
                        ),
                        tooltip: 'Hear English',
                        iconSize: 24,
                      ),
                  ],
                ),
                if (word.pluralForm != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Plural: ${word.pluralForm}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (!showEnglish) ...[
          const SizedBox(height: 16),
          Text(
            'Tap to reveal!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade400,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: centred && c.maxHeight.isFinite
                ? (c.maxHeight - 32).clamp(0.0, double.infinity)
                : 0,
          ),
          child: centred ? Center(child: column) : column,
        ),
      ),
    );
  }
}
