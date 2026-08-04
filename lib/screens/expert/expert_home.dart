import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awing_ai_learning/screens/expert/tone_mastery_screen.dart';
import 'package:awing_ai_learning/screens/translate/grade_attempt.dart';
import 'package:awing_ai_learning/screens/expert/allophones_screen.dart';
import 'package:awing_ai_learning/screens/expert/elision_screen.dart';
import 'package:awing_ai_learning/screens/expert/conversation_screen.dart';
import 'package:awing_ai_learning/screens/expert/expert_proverbs_screen.dart';
import 'package:awing_ai_learning/screens/expert/expert_quiz_screen.dart';
import 'package:awing_ai_learning/screens/expert/numbers_expert_screen.dart';
import 'package:awing_ai_learning/screens/games/expert_tone_hunt.dart';
import 'package:awing_ai_learning/screens/beginner/vocabulary_screen.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/daily_suggestion_service.dart';
import 'package:awing_ai_learning/screens/daily_words_screen.dart';
import 'package:awing_ai_learning/screens/stories_screen.dart';
import 'package:awing_ai_learning/components/mode_home_widgets.dart';

class ExpertHome extends StatefulWidget {
  const ExpertHome({Key? key}) : super(key: key);

  @override
  State<ExpertHome> createState() => _ExpertHomeState();
}

class _ExpertHomeState extends State<ExpertHome> {
  final PronunciationService _pronunciation = PronunciationService();
  bool _isFemaleVoice = false;
  // Session 64 (H3+M9): kid-voice override matching Beginner. Now with
  // SharedPreferences persistence so the pick survives app restart.
  String? _kidOverride;

  static const _kPrefsGender = 'expert_voice_is_female';
  static const _kPrefsKidMan = 'expert_voice_kid_man';
  static const _kPrefsKidWoman = 'expert_voice_kid_woman';

  @override
  void initState() {
    super.initState();
    _pronunciation.setVoiceForLevel('expert', alternate: _isFemaleVoice);
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
      _pronunciation.setVoiceForLevel('expert', alternate: female);
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
    _pronunciation.setVoiceForLevel('expert', alternate: female);
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
        title: const Text('Expert'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Voice selector
            Card(
              color: Colors.red.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                // Session 64 (M8): overflow protection for narrow phones.
                child: Row(
                  children: [
                    const Icon(Icons.record_voice_over, color: Colors.red),
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
                            label: 'Man',
                            icon: Icons.face,
                            selected: !_isFemaleVoice,
                            color: Colors.red,
                            onTap: () => _toggleVoice(false),
                          ),
                          VoiceOption(
                            label: 'Woman',
                            icon: Icons.face_3,
                            selected: _isFemaleVoice,
                            color: Colors.red,
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
            // Session 64 (H3): kid-voice picker now on Expert too.
            KidVoicePicker(
              isFemaleVoice: _isFemaleVoice,
              activeKid: _kidOverride,
              onChanged: _pickKid,
              accentColor: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose a lesson:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            // Session 64 (H1): section headers reduce cognitive load.
            const SectionHeader('Daily'),
            LessonTile(
              title: "Today's Conversations",
              subtitle: '10 new advanced sentences picked for you 🧠',
              icon: Icons.wb_sunny,
              color: Colors.deepPurple.shade300,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DailyWordsScreen(
                    contentType: DailyContentType.conversations,
                    levelOverride: 'expert',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            LessonTile(
              title: 'Grade My Translation',
              subtitle: 'Type your Awing translation, get instant feedback',
              icon: Icons.translate,
              color: Colors.teal.shade400,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const GradeAttemptScreen()),
              ),
            ),
            const SizedBox(height: 12),
            LessonTile(
              title: 'Stories',
              subtitle: 'Read & listen to all Awing stories',
              icon: Icons.auto_stories,
              color: Colors.teal.shade300,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StoriesScreen(
                    maxDifficulty: 3,
                    titleOverride: 'Expert Stories',
                  ),
                ),
              ),
            ),
            const SectionHeader('Learn'),
            LessonTile(
              title: 'Tone Mastery',
              subtitle: 'Advanced tone patterns in sentences',
              icon: Icons.graphic_eq,
              color: Colors.red.shade300,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ToneMasteryScreen()),
              ),
            ),
            const SizedBox(height: 12),
            LessonTile(
              title: 'Sound Changes',
              subtitle: 'How consonants change in different positions',
              icon: Icons.swap_horiz,
              color: const Color(0xFFE53935),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AllophonesScreen()),
              ),
            ),
            const SizedBox(height: 12),
            LessonTile(
              title: 'Elision Rules',
              subtitle: 'Long/short forms & vowel dropping',
              icon: Icons.edit,
              color: Colors.red.shade400,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ElisionScreen()),
              ),
            ),
            const SizedBox(height: 12),
            LessonTile(
              title: 'Conversations',
              subtitle: 'Real Awing dialogues & long sentences',
              icon: Icons.chat_bubble,
              color: Colors.red.shade500,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConversationScreen()),
              ),
            ),
            const SizedBox(height: 12),
            LessonTile(
              title: 'Awing Proverbs',
              subtitle: '44 long-form proverbs from the dictionary 📜',
              icon: Icons.format_quote,
              color: Colors.deepOrange.shade400,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ExpertProverbsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            LessonTile(
              title: 'Advanced Words',
              subtitle: 'Abstract concepts, proper nouns & rare vocabulary',
              icon: Icons.menu_book,
              color: Colors.red.shade500,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  // Expert "Advanced Words" shows ONLY difficulty-3 words.
                  // Beginner (1) and Medium (2) words are excluded — the
                  // user has already encountered those in earlier tiles.
                  // Contents: abstract/religious vocabulary, proper nouns
                  // (Bible names, places), occupations (priest, scribe,
                  // centurion…), and some mature/historical concepts.
                  builder: (_) => const VocabularyScreen(
                    difficultyFilter: 3,
                    lessonId: 'expert_advanced_words',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            LessonTile(
              title: 'Advanced Numbers',
              subtitle: 'Hundreds, thousands & number patterns',
              icon: Icons.pin,
              color: Colors.red.shade500,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NumbersExpertScreen()),
              ),
            ),
            const SectionHeader('Test & Play'),
            LessonTile(
              title: 'Expert Quiz',
              subtitle: 'Paragraph fill-in-the-blank challenge!',
              icon: Icons.emoji_events,
              color: Colors.red.shade600,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpertQuizScreen()),
              ),
            ),
            const SizedBox(height: 12),
            LessonTile(
              title: 'Games',
              subtitle: 'Tone Hunt - identify the correct tone',
              icon: Icons.extension,
              color: Colors.red.shade800,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpertToneHunt()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

