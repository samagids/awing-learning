import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awing_ai_learning/screens/beginner/alphabet_screen.dart';
import 'package:awing_ai_learning/screens/translate/word_translate.dart';
import 'package:awing_ai_learning/screens/beginner/vocabulary_screen.dart';
import 'package:awing_ai_learning/screens/beginner/quiz_screen.dart';
import 'package:awing_ai_learning/screens/beginner/tone_screen.dart';
import 'package:awing_ai_learning/screens/beginner/pronunciation_screen.dart';
import 'package:awing_ai_learning/screens/beginner/phrases_screen.dart';
import 'package:awing_ai_learning/screens/beginner/numbers_screen.dart';
import 'package:awing_ai_learning/screens/beginner/vocabulary_review_screen.dart';
import 'package:awing_ai_learning/screens/games/beginner_picture_match.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/daily_suggestion_service.dart';
import 'package:awing_ai_learning/screens/daily_words_screen.dart';
import 'package:awing_ai_learning/screens/stories_screen.dart';

class BeginnerHome extends StatefulWidget {
  const BeginnerHome({Key? key}) : super(key: key);

  @override
  State<BeginnerHome> createState() => _BeginnerHomeState();
}

class _BeginnerHomeState extends State<BeginnerHome> {
  final PronunciationService _pronunciation = PronunciationService();
  bool _isFemaleVoice = false;
  // Optional kid-voice override. null = use the canonical native voice
  // ("My voice", which is Dr. Sama's recording for words he covered, or
  // the Edge TTS character voice otherwise). When set to a kid slug
  // (joel/janelle/joyce/jadyne), PronunciationService prefers that
  // kid's recording first, falling back to "My voice" silently when the
  // specific kid hasn't recorded that word.
  String? _kidOverride;

  // SharedPreferences keys — separate per gender so flipping Boy↔Girl
  // remembers each side's last kid pick.
  static const _kPrefsGender = 'beginner_voice_is_female';
  static const _kPrefsKidBoy = 'beginner_voice_kid_boy';
  static const _kPrefsKidGirl = 'beginner_voice_kid_girl';

  @override
  void initState() {
    super.initState();
    _pronunciation.setVoiceForLevel('beginner', alternate: _isFemaleVoice);
    _loadPersistedVoice();
  }

  Future<void> _loadPersistedVoice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final female = prefs.getBool(_kPrefsGender) ?? false;
      final kidKey = female ? _kPrefsKidGirl : _kPrefsKidBoy;
      final kid = prefs.getString(kidKey);
      if (!mounted) return;
      setState(() {
        _isFemaleVoice = female;
        _kidOverride = kid;
      });
      _pronunciation.setVoiceForLevel('beginner', alternate: female);
      _pronunciation.setKidOverride(kid);
    } catch (_) {/* fall back to defaults */}
  }

  Future<void> _persistGender(bool female) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPrefsGender, female);
    } catch (_) {/* prefs unavailable */}
  }

  Future<void> _persistKid(String? slug, bool female) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = female ? _kPrefsKidGirl : _kPrefsKidBoy;
      if (slug == null) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, slug);
      }
    } catch (_) {/* prefs unavailable */}
  }

  void _toggleVoice(bool female) {
    setState(() {
      _isFemaleVoice = female;
      // Reset kid override when switching gender — the previous kid
      // belongs to the other gender (Joel/Janelle are boys; Joyce/
      // Jadyne are girls). Restore last-saved pick for the new side
      // asynchronously via SharedPreferences below.
      _kidOverride = null;
    });
    _pronunciation.setVoiceForLevel('beginner', alternate: female);
    _pronunciation.setKidOverride(null);
    _persistGender(female);
    // Async-restore the last-saved kid pick for the new gender.
    _restoreKidForGender(female);
  }

  Future<void> _restoreKidForGender(bool female) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = female ? _kPrefsKidGirl : _kPrefsKidBoy;
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
        title: const Text('Beginner'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Voice selector — gender (Boy / Girl) controls the TTS
            // character voice + which kids the next picker offers.
            Card(
              color: Colors.green.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.record_voice_over, color: Colors.green),
                    const SizedBox(width: 12),
                    const Text(
                      'Voice:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    _VoiceOption(
                      label: 'Boy',
                      icon: Icons.face,
                      selected: !_isFemaleVoice,
                      color: Colors.green,
                      onTap: () => _toggleVoice(false),
                    ),
                    const SizedBox(width: 8),
                    _VoiceOption(
                      label: 'Girl',
                      icon: Icons.face_3,
                      selected: _isFemaleVoice,
                      color: Colors.green,
                      onTap: () => _toggleVoice(true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Whose voice — "My voice" (Dr. Sama / canonical) is the
            // default. When a kid is picked, words THEY recorded play
            // in their voice; words they didn't record still play in
            // "My voice" silently.
            _KidVoicePicker(
              isFemaleVoice: _isFemaleVoice,
              activeKid: _kidOverride,
              onChanged: _pickKid,
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose a lesson:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _LessonTile(
              title: "Today's Words",
              subtitle: '10 new words picked for you every day 🧠',
              icon: Icons.wb_sunny,
              color: Colors.deepPurple.shade300,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DailyWordsScreen(
                    contentType: DailyContentType.words,
                    levelOverride: 'beginner',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Translate Words',
              subtitle: 'English ↔ Awing word lookup with pronunciation',
              icon: Icons.translate,
              color: Colors.teal.shade400,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WordTranslateScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Stories',
              subtitle: 'Read & listen to simple Awing stories',
              icon: Icons.auto_stories,
              color: Colors.teal.shade300,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StoriesScreen(
                    maxDifficulty: 1,
                    titleOverride: 'Beginner Stories',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Alphabet',
              subtitle: 'Learn the 22 consonants and 9 vowels',
              icon: Icons.abc,
              color: Colors.green.shade300,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AlphabetScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Words',
              subtitle: 'Learn common Awing words',
              icon: Icons.menu_book,
              color: Colors.green.shade400,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  // Beginner shows ONLY difficulty-1 words. Difficulty 2/3
                  // entries are reserved for Medium "Difficult Words" and
                  // future Expert vocabulary respectively, so kids never
                  // see advanced words mixed into the beginner flashcards.
                  builder: (_) => const VocabularyScreen(
                    difficultyFilter: 1,
                    lessonId: 'beginner_vocabulary',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Phrases & Greetings',
              subtitle: 'Say hello, ask questions & more',
              icon: Icons.chat,
              color: Colors.green.shade500,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PhrasesScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Tones',
              subtitle: 'Hear how tone changes meaning',
              icon: Icons.music_note,
              color: const Color(0xFF66BB6A),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ToneScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Numbers',
              subtitle: 'Learn to count 1-10 in Awing',
              icon: Icons.looks_one,
              color: const Color(0xFF43A047),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NumbersScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Pronunciation',
              subtitle: 'Practice speaking Awing words',
              icon: Icons.mic,
              color: const Color(0xFF388E3C),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PronunciationScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Quiz',
              subtitle: 'Test what you have learned!',
              icon: Icons.quiz,
              color: Colors.green.shade600,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuizScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Review',
              subtitle: 'Practice words you are still learning',
              icon: Icons.replay,
              color: Colors.green.shade700,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VocabularyReviewScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _LessonTile(
              title: 'Games',
              subtitle: 'Picture Match - drag words to pictures',
              icon: Icons.extension,
              color: Colors.green.shade800,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BeginnerPictureMatch()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _VoiceOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: selected ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _LessonTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: color,
          radius: 28,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// Sub-picker for "Whose voice should we use?". Sits directly below
/// the Boy/Girl card on the Beginner home screen.
///
/// When Boy is selected (isFemaleVoice=false): My voice / Joel / Janelle.
/// When Girl is selected (isFemaleVoice=true):  My voice / Joyce / Jadyne.
///
/// "My voice" is null override — plays Dr. Sama's recording where
/// available, or the Edge TTS character voice otherwise. Picking a
/// specific kid plays THEIR recording when present, silently falling
/// back to "My voice" for words they haven't recorded yet.
class _KidVoicePicker extends StatelessWidget {
  final bool isFemaleVoice;
  final String? activeKid;
  final ValueChanged<String?> onChanged;

  const _KidVoicePicker({
    required this.isFemaleVoice,
    required this.activeKid,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final character = isFemaleVoice ? 'girl' : 'boy';
    final kids =
        PronunciationService.kidVoicesByCharacter[character] ?? const [];

    return Card(
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.person_pin_circle_outlined,
                color: Colors.green),
            const SizedBox(width: 12),
            const Text(
              'Whose voice?',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true, // keep the "My voice" chip visible
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _KidChip(
                      label: 'My voice',
                      selected: activeKid == null,
                      onTap: () => onChanged(null),
                    ),
                    for (final kid in kids) ...[
                      const SizedBox(width: 6),
                      _KidChip(
                        label:
                            PronunciationService.kidDisplayNames[kid] ??
                                kid,
                        selected: activeKid == kid,
                        onTap: () => onChanged(kid),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KidChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _KidChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.green : Colors.grey.shade400,
            width: 1.6,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
