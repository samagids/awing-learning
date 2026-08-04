import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awing_ai_learning/screens/medium/clusters_screen.dart';
import 'package:awing_ai_learning/screens/translate/sentence_translate.dart';
import 'package:awing_ai_learning/screens/medium/vowels_screen.dart';
import 'package:awing_ai_learning/screens/medium/noun_classes_screen.dart';
import 'package:awing_ai_learning/screens/medium/sentences_screen.dart';
import 'package:awing_ai_learning/screens/medium/writing_quiz_screen.dart';
import 'package:awing_ai_learning/screens/medium/numbers_medium_screen.dart';
import 'package:awing_ai_learning/screens/beginner/vocabulary_screen.dart';
import 'package:awing_ai_learning/screens/games/medium_sentence_build.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/daily_suggestion_service.dart';
import 'package:awing_ai_learning/screens/daily_words_screen.dart';
import 'package:awing_ai_learning/screens/stories_screen.dart';
import 'package:awing_ai_learning/components/mode_home_widgets.dart';

class MediumHome extends StatefulWidget {
  const MediumHome({Key? key}) : super(key: key);

  @override
  State<MediumHome> createState() => _MediumHomeState();
}

class _MediumHomeState extends State<MediumHome> {
  final PronunciationService _pronunciation = PronunciationService();
  bool _isFemaleVoice = false;
  // Session 64 (H3+M9): kid-voice override matching Beginner. Now with
  // SharedPreferences persistence so the pick survives app restart.
  String? _kidOverride;

  static const _kPrefsGender = 'medium_voice_is_female';
  static const _kPrefsKidMan = 'medium_voice_kid_man';
  static const _kPrefsKidWoman = 'medium_voice_kid_woman';

  @override
  void initState() {
    super.initState();
    _pronunciation.setVoiceForLevel('medium', alternate: _isFemaleVoice);
    _loadPersistedVoice();
  }

  Future<void> _loadPersistedVoice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final female = prefs.getBool(_kPrefsGender) ?? false;
      final key = female ? _kPrefsKidWoman : _kPrefsKidMan;
      final kid = prefs.getString(key);
      if (!mounted) return;
      setState(() {
        _isFemaleVoice = female;
        _kidOverride = kid;
      });
      _pronunciation.setVoiceForLevel('medium', alternate: female);
      _pronunciation.setKidOverride(kid);
    } catch (_) {/* fall back to defaults */}
  }

  Future<void> _persistGender(bool female) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPrefsGender, female);
    } catch (_) {}
  }

  Future<void> _persistKid(String? slug, bool female) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = female ? _kPrefsKidWoman : _kPrefsKidMan;
      if (slug == null) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, slug);
      }
    } catch (_) {}
  }

  void _toggleVoice(bool female) {
    setState(() {
      _isFemaleVoice = female;
      _kidOverride = null;
    });
    _pronunciation.setVoiceForLevel('medium', alternate: female);
    _pronunciation.setKidOverride(null);
    _persistGender(female);
    _restoreKidForGender(female);
  }

  Future<void> _restoreKidForGender(bool female) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = female ? _kPrefsKidWoman : _kPrefsKidMan;
      final saved = prefs.getString(key);
      if (saved == null || !mounted) return;
      setState(() => _kidOverride = saved);
      _pronunciation.setKidOverride(saved);
    } catch (_) {}
  }

  void _pickKid(String? slug) {
    setState(() => _kidOverride = slug);
    _pronunciation.setKidOverride(slug);
    _persistKid(slug, _isFemaleVoice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medium'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Voice selector
            Card(
              color: Colors.orange.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                // Session 64 (M8): overflow protection for narrow phones.
                child: Row(
                  children: [
                    const Icon(Icons.record_voice_over, color: Colors.orange),
                    const SizedBox(width: 12),
                    const Text(
                      'Voice:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          VoiceOption(
                            label: 'Young Man',
                            icon: Icons.face,
                            selected: !_isFemaleVoice,
                            color: Colors.orange,
                            onTap: () => _toggleVoice(false),
                          ),
                          VoiceOption(
                            label: 'Young Woman',
                            icon: Icons.face_3,
                            selected: _isFemaleVoice,
                            color: Colors.orange,
                            onTap: () => _toggleVoice(true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Session 64 (H3): kid-voice picker now on Medium too.
            KidVoicePicker(
              isFemaleVoice: _isFemaleVoice,
              activeKid: _kidOverride,
              onChanged: _pickKid,
              accentColor: Colors.orange.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose a lesson:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            // Session 64 (H1): section headers reduce cognitive load.
            const SectionHeader('Daily'),
            LessonTile(
              title: "Today's Sentences",
              subtitle: '10 new everyday sentences picked for you 🧠',
              icon: Icons.wb_sunny,
              color: Colors.deepPurple.shade300,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DailyWordsScreen(
                    contentType: DailyContentType.sentences,
                    levelOverride: 'medium',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            LessonTile(
              title: 'Translate Sentences',
              subtitle: 'Type a sentence, get word-by-word Awing',
              icon: Icons.translate,
              color: Colors.teal.shade400,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SentenceTranslateScreen()),
              ),
            ),
            const SizedBox(height: 12),
            LessonTile(
              title: 'Stories',
              subtitle: 'Read & listen to medium-level Awing stories',
              icon: Icons.auto_stories,
              color: Colors.teal.shade300,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StoriesScreen(
                    maxDifficulty: 2,
                    titleOverride: 'Medium Stories',
                  ),
                ),
              ),
            ),
            const SectionHeader('Learn'),
            LessonTile(
              title: 'Short Sentences',
              subtitle: 'Learn everyday Awing sentences',
              icon: Icons.short_text,
              color: Colors.orange.shade300,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SentencesScreen()),
              ),
            ),
            const SizedBox(height: 12),
            LessonTile(
              title: 'Consonant Clusters',
              subtitle: 'Prenasalized, palatalized & labialized sounds',
              icon: Icons.record_voice_over,
              color: const Color(0xFFFF9800),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ClustersScreen()),
              ),
            ),
            const SizedBox(height: 12),
            LessonTile(
              title: 'Vowels & Syllables',
              subtitle: '9 vowels, long vowels & syllable types',
              icon: Icons.circle_outlined,
              color: Colors.orange.shade400,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VowelsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            LessonTile(
              title: 'Noun Classes',
              subtitle: 'Singular & plural patterns',
              icon: Icons.category,
              color: Colors.orange.shade500,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NounClassesScreen()),
              ),
            ),
            const SizedBox(height: 12),
            LessonTile(
              title: 'Sentence Building',
              subtitle: 'Build your own Awing sentences',
              icon: Icons.chat_bubble_outline,
              color: const Color(0xFFEF6C00),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SentencesScreen()),
              ),
            ),
            const SizedBox(height: 12),
            LessonTile(
              title: 'Difficult Words',
              subtitle: 'Learn more challenging vocabulary',
              icon: Icons.menu_book,
              color: const Color(0xFFE65100),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  // Medium "Difficult Words" shows ONLY difficulty-2 words.
                  // Beginner words (difficulty 1) are excluded — kids using
                  // Medium have already learned those in the Beginner mode
                  // "Words" tile and shouldn't see them mixed in here.
                  // Expert words (difficulty 3) are also excluded.
                  builder: (_) => const VocabularyScreen(
                    difficultyFilter: 2,
                    lessonId: 'medium_difficult_words',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            LessonTile(
              title: 'Numbers 11-100',
              subtitle: 'Teens, tens & big numbers',
              icon: Icons.pin,
              color: const Color(0xFFE65100),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NumbersMediumScreen()),
              ),
            ),
            const SectionHeader('Test & Play'),
            LessonTile(
              title: 'Writing Quiz',
              subtitle: 'Fill in the blank sentences',
              icon: Icons.edit_note,
              color: Colors.orange.shade600,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WritingQuizScreen()),
              ),
            ),
            const SizedBox(height: 12),
            LessonTile(
              title: 'Games',
              subtitle: 'Sentence Build - arrange words in order',
              icon: Icons.extension,
              color: Colors.orange.shade800,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MediumSentenceBuild()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

