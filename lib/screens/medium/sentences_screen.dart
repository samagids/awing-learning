import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';

/// Simple Awing sentences for the Medium module
class AwingSentence {
  final String awing;
  final String english;
  final List<AwingWord> words; // word-by-word breakdown

  const AwingSentence({
    required this.awing,
    required this.english,
    required this.words,
  });
}

class AwingWord {
  final String word;
  final String english;

  const AwingWord(this.word, this.english);
}

/// Sentences sourced from AwingOrthography2005.pdf examples (pages 9, 11, 12).
/// Ordered from simplest (2 words) to more complex.
// Sentences verified from AwingOrthography2005.pdf.
// Individual words verified from orthography page 8 tone chart and page 9 noun classes.
const List<AwingSentence> awingSentences = [
  // AUDIT 2026-04-29: 4 short 2-word sentences removed — they used
  // 'yə' as "He/she" but Session 51 audit confirmed yə is actually
  // a grammatical/possessive marker, not a pronoun. The combinations
  // 'Mǎ ko' / 'Mǎ nô nkǐə' were also fabricated 2-word sentences
  // not present in any source PDF. Per project rule, all Awing must
  // be PDF-verified. The 7 longer sentences below ARE PDF-verified
  // (orthography pages 9, 11, 12) and stay.
  //
  // PDF-verified sentences from AwingOrthography2005.pdf:
  // Page 11: "Móonə a tə nonnɔ́ a əkwunɔ́." (formal PDF form)
  // Corrected by Dr. Sama (native speaker) to the natural spoken form:
  // Awing drops "a tə" progressive auxiliary and the locative "a".
  AwingSentence(
    awing: "Móonə nonnɔ́ əkwunɔ́.",
    english: 'The baby is lying on the bed.',
    words: [
      AwingWord('Móonə', 'Baby'),
      AwingWord('nonnɔ́', 'lying'),
      AwingWord('əkwunɔ́', 'bed'),
    ],
  ),
  // Page 9: "A kə ghɛnɔ́ məteenɔ́."
  AwingSentence(
    awing: "A kə ghɛnɔ́ məteenɔ́.",
    english: 'He went to the market.',
    words: [
      AwingWord('A', 'He'),
      AwingWord('kə', '(past tense)'),
      AwingWord('ghɛnɔ́', 'go'),
      AwingWord('məteenɔ́', 'market'),
    ],
  ),
  // Page 12: "Po zí nóolə."
  AwingSentence(
    awing: "Po zí nóolə.",
    english: 'They have seen a snake.',
    words: [
      AwingWord('Po', 'They'),
      AwingWord('zí', 'have seen'),
      AwingWord('nóolə', 'snake'),
    ],
  ),
  // Page 12: "Ghǒ ghɛnɔ́ lə əfó?" (from quotation marks section)
  AwingSentence(
    awing: "Ghǒ ghɛnɔ́ lə əfó?",
    english: 'Where are you going?',
    words: [
      AwingWord('Ghǒ', 'You'),
      AwingWord('ghɛnɔ́', 'going'),
      AwingWord('lə', 'to'),
      AwingWord('əfó', 'where'),
    ],
  ),
  // Page 11: "Po ma ngyǐə lə əfê, po ghɛnɔ́ lə nkǐə."
  AwingSentence(
    awing: "Po ma ngyǐə lə əfê, po ghɛnɔ́ lə nkǐə.",
    english: 'They are not coming here, they are going to the stream.',
    words: [
      AwingWord('Po', 'They'),
      AwingWord('ma', 'not'),
      AwingWord('ngyǐə', 'come'),
      AwingWord('lə', 'to'),
      AwingWord('əfê', 'here'),
      AwingWord('po', 'they'),
      AwingWord('ghɛnɔ́', 'go'),
      AwingWord('lə', 'to'),
      AwingWord('nkǐə', 'river'),
    ],
  ),
  // Page 10: "Lɛ̌ nəpɔ'ɔ́."
  AwingSentence(
    awing: "Lɛ̌ nəpɔ'ɔ́.",
    english: 'This is a pumpkin.',
    words: [
      AwingWord('Lɛ̌', 'This is'),
      AwingWord("nəpɔ'ɔ́", 'pumpkin'),
    ],
  ),

  // ====================================================================
  // BIBLE NT UNIVERSAL SENTENCES — extracted from CABTAL Awing NT.
  // Verses where the English itself is a universal proverb or
  // imperative (no religious narrative context). Added Session 60.
  // ====================================================================
  // JHN.7.53 — extracted from Bible NT (universal proverb/imperative)
  AwingSentence(
    awing: 'Ŋwu ntsəmə a fɛ́d ńtíʼ ńkwə̂ á ngyaʼə́ yə́.',
    english: 'Everyone went to his own house.',
    words: [
      AwingWord('Ŋwu', 'person'),
      AwingWord('ntsəmə', 'every'),
      AwingWord('a', '(subject)'),
      AwingWord('fɛ́d', 'left'),
      AwingWord('ńtíʼ', 'and'),
      AwingWord('ńkwə̂', 'went'),
      AwingWord('á', 'to'),
      AwingWord('ngyaʼə́', 'house'),
      AwingWord('yə́', 'his'),
    ],
  ),
  // ACT.8.8 — extracted from Bible NT (universal proverb/imperative)
  AwingSentence(
    awing: 'Ńdaŋ ə́lɨ́d mbɨ ngaŋ tə́kɔʼ tɔ̂ŋ yi wɨ́.',
    english: 'There was great joy in that city.',
    words: [
      AwingWord('Ńdaŋ', 'then'),
      AwingWord('ə́lɨ́d', 'there'),
      AwingWord('mbɨ', 'was'),
      AwingWord('ngaŋ', 'great'),
      AwingWord('tə́kɔʼ', 'joy'),
      AwingWord('tɔ̂ŋ', 'city'),
      AwingWord('yi', 'in'),
      AwingWord('wɨ́', 'that'),
    ],
  ),
  // PHP.2.14 — extracted from Bible NT (universal proverb/imperative)
  AwingSentence(
    awing: 'Faʼə̂ anuə atsəm tsɔʼə tə ŋwuntə̂.',
    english: 'Do all things without complaining.',
    words: [
      AwingWord('Faʼə̂', 'do'),
      AwingWord('anuə', 'things'),
      AwingWord('atsəm', 'all'),
      AwingWord('tsɔʼə', 'without'),
      AwingWord('tə', 'to'),
      AwingWord('ŋwuntə̂', 'complain'),
    ],
  ),
  // 1TH.5.21 — extracted from Bible NT (universal proverb/imperative)
  AwingSentence(
    awing: 'Jwə́ʼ nə́ mənu mətsəm.',
    english: 'Test all things.',
    words: [
      AwingWord('Jwə́ʼ', 'test'),
      AwingWord('nə́', 'of'),
      AwingWord('mənu', 'things'),
      AwingWord('mətsəm', 'all'),
    ],
  ),
  // ROM.12.21 — extracted from Bible NT (universal proverb/imperative)
  AwingSentence(
    awing: 'Kɔ gho pí təpɔŋə á tsɛɛlə̂ gho.',
    english: "Don't let bad things defeat you.",
    words: [
      AwingWord('Kɔ', 'do not'),
      AwingWord('gho', 'you'),
      AwingWord('pí', 'let'),
      AwingWord('təpɔŋə', 'bad'),
      AwingWord('á', 'to'),
      AwingWord('tsɛɛlə̂', 'defeat'),
      AwingWord('gho', 'you'),
    ],
  ),
  // 1TH.5.22 — extracted from Bible NT (universal proverb/imperative)
  AwingSentence(
    awing: 'Lə́ʼ nə́ ndzaŋ təpɔŋ ntsəmə.',
    english: 'Stay away from every kind of bad thing.',
    words: [
      AwingWord('Lə́ʼ', 'stay away'),
      AwingWord('nə́', 'from'),
      AwingWord('ndzaŋ', 'kind'),
      AwingWord('təpɔŋ', 'bad'),
      AwingWord('ntsəmə', 'every'),
    ],
  ),
  // COL.3.21 — extracted from Bible NT (universal proverb/imperative)
  AwingSentence(
    awing: 'Pətǎ, kɔ nə́ tə́ ńjwaʼə̂ pɔ́ pə́ənə́.',
    english: "Fathers, don't anger your children.",
    words: [
      AwingWord('Pətǎ', 'fathers'),
      AwingWord('kɔ', 'do not'),
      AwingWord('nə́', 'to'),
      AwingWord('tə́', 'be'),
      AwingWord('ńjwaʼə̂', 'angering'),
      AwingWord('pɔ́', 'children'),
      AwingWord('pə́ənə́', 'your'),
    ],
  ),

  // ====================================================================
  // DICTIONARY EXAMPLE SENTENCES — extracted from the 2007 Awing English
  // Dictionary (Alomofor Christian, CABTAL), Format B entries pages
  // 101-139. Filtered for kid-appropriate content (no death/graveyard/
  // thieves/dirty/enemy/evil omen).
  // ====================================================================
  AwingSentence(
    awing: 'Mənumə á tə́ ńtê.',
    english: 'The sun is shining.',
    words: [
      AwingWord('Mənumə', 'sun'),
      AwingWord('á', '(subject)'),
      AwingWord('tə́', 'is'),
      AwingWord('ńtê', 'shining'),
    ],
  ),
  AwingSentence(
    awing: 'A tə́ ńgenə afoonə.',
    english: 'He is going to the farm.',
    words: [
      AwingWord('A', 'He'),
      AwingWord('tə́', 'is'),
      AwingWord('ńgenə', 'going'),
      AwingWord('afoonə', 'farm'),
    ],
  ),
  AwingSentence(
    awing: 'A kə soŋ ńga tə ghenə.',
    english: 'He told us to go.',
    words: [
      AwingWord('A', 'He'),
      AwingWord('kə', '(past)'),
      AwingWord('soŋ', 'told'),
      AwingWord('ńga', 'us'),
      AwingWord('tə', 'to'),
      AwingWord('ghenə', 'go'),
    ],
  ),
  AwingSentence(
    awing: 'Ŋwu yî lə tä mə.',
    english: 'That man is my father.',
    words: [
      AwingWord('Ŋwu', 'man'),
      AwingWord('yî', 'that'),
      AwingWord('lə', 'is'),
      AwingWord('tä', 'father'),
      AwingWord('mə', 'my'),
    ],
  ),
  AwingSentence(
    awing: 'Maŋ yî ghenə̂.',
    english: 'I will go.',
    words: [
      AwingWord('Maŋ', 'I'),
      AwingWord('yî', 'will'),
      AwingWord('ghenə̂', 'go'),
    ],
  ),
  AwingSentence(
    awing: 'Maŋ yó ghenə̂.',
    english: 'I shall go.',
    words: [
      AwingWord('Maŋ', 'I'),
      AwingWord('yó', 'shall'),
      AwingWord('ghenə̂', 'go'),
    ],
  ),
  AwingSentence(
    awing: 'Ajú zə̂ á pəgə.',
    english: 'That thing is spoilt.',
    words: [
      AwingWord('Ajú', 'thing'),
      AwingWord('zə̂', 'that'),
      AwingWord('á', 'is'),
      AwingWord('pəgə', 'spoilt'),
    ],
  ),
  AwingSentence(
    awing: 'A tô akoolə ajîə.',
    english: 'He has stubbed his foot.',
    words: [
      AwingWord('A', 'He'),
      AwingWord('tô', 'has stubbed'),
      AwingWord('akoolə', 'foot'),
      AwingWord('ajîə', 'his'),
    ],
  ),
  AwingSentence(
    awing: "Ayonə á toonô atsa'á ma.",
    english: 'The iron has burned my dress.',
    words: [
      AwingWord('Ayonə', 'iron'),
      AwingWord('á', '(subject)'),
      AwingWord('toonô', 'has burned'),
      AwingWord("atsa'á", 'dress'),
      AwingWord('ma', 'my'),
    ],
  ),
  AwingSentence(
    awing: 'Mənətalásə á pwódnə tə́ ńga tâb.',
    english: 'The mattress is so soft.',
    words: [
      AwingWord('Mənətalásə', 'mattress'),
      AwingWord('á', '(subject)'),
      AwingWord('pwódnə', 'is soft'),
      AwingWord('tə́', '—'),
      AwingWord('ńga', 'so'),
      AwingWord('tâb', '(softness)'),
    ],
  ),
  AwingSentence(
    awing: 'Tséeba á ndəŋndəŋɔ́.',
    english: 'Speak the truth.',
    words: [
      AwingWord('Tséeba', 'speak'),
      AwingWord('á', 'the'),
      AwingWord('ndəŋndəŋɔ́', 'truth'),
    ],
  ),
  AwingSentence(
    awing: 'Yîə á ndzəŋ mənumə.',
    english: 'Come in the afternoon.',
    words: [
      AwingWord('Yîə', 'come'),
      AwingWord('á', 'in'),
      AwingWord('ndzəŋ', 'afternoon'),
      AwingWord('mənumə', '—'),
    ],
  ),
  AwingSentence(
    awing: 'A tsɔ́ ntso ndê nə́ kíə.',
    english: 'He has opened the door with a key.',
    words: [
      AwingWord('A', 'He'),
      AwingWord('tsɔ́', 'has opened'),
      AwingWord('ntso', 'door'),
      AwingWord('ndê', '—'),
      AwingWord('nə́', 'with'),
      AwingWord('kíə', 'key'),
    ],
  ),
  AwingSentence(
    awing: "Nətó' zô ná əfó.",
    english: 'Where is your potato?',
    words: [
      AwingWord("Nətó'", 'potato'),
      AwingWord('zô', 'your'),
      AwingWord('ná', 'is'),
      AwingWord('əfó', 'where'),
    ],
  ),
  AwingSentence(
    awing: 'Ngaŋnaghéenə a yî yîə.',
    english: 'A guest will come.',
    words: [
      AwingWord('Ngaŋnaghéenə', 'guest'),
      AwingWord('a', '(subject)'),
      AwingWord('yî', 'will'),
      AwingWord('yîə', 'come'),
    ],
  ),
  AwingSentence(
    awing: 'Ngəsáŋ yi njúbtə á pɔŋə á mɔ́ káŋ nə̀.',
    english: 'Dry corn is good for popping.',
    words: [
      AwingWord('Ngəsáŋ', 'corn'),
      AwingWord('yi', '—'),
      AwingWord('njúbtə', 'dry'),
      AwingWord('á', 'is'),
      AwingWord('pɔŋə', 'good'),
      AwingWord('á', 'for'),
      AwingWord('mɔ́', '—'),
      AwingWord('káŋ', 'popping'),
      AwingWord('nə̀', '—'),
    ],
  ),
  AwingSentence(
    awing: 'Ngǎn Ndawálé tséeba lɔ́ Flénchə.',
    english: 'People from Douala speak French.',
    words: [
      AwingWord('Ngǎn', 'people'),
      AwingWord('Ndawálé', 'Douala'),
      AwingWord('tséeba', 'speak'),
      AwingWord('lɔ́', '—'),
      AwingWord('Flénchə', 'French'),
    ],
  ),
  AwingSentence(
    awing: 'Pi pə́ wiŋ pó chîə á Ndəwálə̌ náənə.',
    english: 'There are many great people in Douala.',
    words: [
      AwingWord('Pi', '—'),
      AwingWord('pə́', 'are'),
      AwingWord('wiŋ', 'great'),
      AwingWord('pó', 'people'),
      AwingWord('chîə', '—'),
      AwingWord('á', 'in'),
      AwingWord('Ndəwálə̌', 'Douala'),
      AwingWord('náənə', '—'),
    ],
  ),
  AwingSentence(
    awing: 'Mənə mə́ záənə sáambaŋ lə́ mə́ shamnə̂ ńgá yêe.',
    english: 'When cattle see a lion, they scatter away.',
    words: [
      AwingWord('Mənə', 'cattle'),
      AwingWord('mə́', '(plural)'),
      AwingWord('záənə', 'see'),
      AwingWord('sáambaŋ', 'lion'),
      AwingWord('lə́', 'when'),
      AwingWord('mə́', 'they'),
      AwingWord('shamnə̂', 'scatter'),
      AwingWord('ńgá', 'away'),
      AwingWord('yêe', '(scattering)'),
    ],
  ),
  AwingSentence(
    awing: 'Á mé məsanə á aghá alu apú atsəm nwâ lə́ ńga tsóg.',
    english: 'Early morning in the dry season everything is so cold.',
    words: [
      AwingWord('Á', 'In'),
      AwingWord('mé', 'early'),
      AwingWord('məsanə', 'morning'),
      AwingWord('á', 'of'),
      AwingWord('aghá', 'season'),
      AwingWord('alu', 'dry'),
      AwingWord('apú', 'everything'),
      AwingWord('atsəm', 'all'),
      AwingWord('nwâ', 'cold'),
      AwingWord('lə́', '—'),
      AwingWord('ńga', 'so'),
      AwingWord('tsóg', '(coldness)'),
    ],
  ),
  AwingSentence(
    awing: 'Á kè poŋə mə́ túg ná wélə á ńi tóshú pô.',
    english: 'It is not good to carry a lot of weight.',
    words: [
      AwingWord('Á', 'It'),
      AwingWord('kè', 'is not'),
      AwingWord('poŋə', 'good'),
      AwingWord('mə́', 'to'),
      AwingWord('túg', 'carry'),
      AwingWord('ná', '—'),
      AwingWord('wélə', 'weight'),
      AwingWord('á', '—'),
      AwingWord('ńi', '—'),
      AwingWord('tóshú', 'a lot'),
      AwingWord('pô', '—'),
    ],
  ),
  AwingSentence(
    awing: "O kə pe' pə́ səŋ ná maŋ zá'ə a poŋə yîə.",
    english: 'You were supposed to tell me before he comes.',
    words: [
      AwingWord('O', 'You'),
      AwingWord('kə', '(past)'),
      AwingWord("pe'", 'were'),
      AwingWord('pə́', '—'),
      AwingWord('səŋ', 'tell'),
      AwingWord('ná', 'me'),
      AwingWord('maŋ', '—'),
      AwingWord("zá'ə", 'before'),
      AwingWord('a', 'he'),
      AwingWord('poŋə', 'comes'),
      AwingWord('yîə', '—'),
    ],
  ),
  AwingSentence(
    awing: 'Á tati məgha o laŋə ali\'á atsəm o zó\'ə ándó məŋki mə́ zəd ná ńgá wûu.',
    english: 'In the heart of the rainy season one hears the streams rumbling.',
    words: [
      AwingWord('Á', 'In'),
      AwingWord('tati', 'heart'),
      AwingWord('məgha', '—'),
      AwingWord('o', 'one'),
      AwingWord('laŋə', '—'),
      AwingWord("ali'á", '—'),
      AwingWord('atsəm', 'all'),
      AwingWord('o', 'one'),
      AwingWord("zó'ə", 'hears'),
      AwingWord('ándó', '—'),
      AwingWord('məŋki', 'streams'),
      AwingWord('mə́', '(plural)'),
      AwingWord('zəd', 'rumbling'),
      AwingWord('ná', '—'),
      AwingWord('ńgá', '—'),
      AwingWord('wûu', '(rumble)'),
    ],
  ),
  AwingSentence(
    awing: "Mənə mə́ akəb mə́ tə́ ńkwa'ə á ndu kəŋ ńdzaənə ŋwu lə́ mə́ méla akəb ńga tsô.",
    english: 'Wild animals disappear into the bush when they see human beings.',
    words: [
      AwingWord('Mənə', 'animals'),
      AwingWord('mə́', '(plural)'),
      AwingWord('akəb', 'wild'),
      AwingWord('mə́', '(they)'),
      AwingWord('tə́', '—'),
      AwingWord("ńkwa'ə", 'disappear'),
      AwingWord('á', 'into'),
      AwingWord('ndu', '—'),
      AwingWord('kəŋ', 'bush'),
      AwingWord('ńdzaənə', 'see'),
      AwingWord('ŋwu', 'humans'),
      AwingWord('lə́', 'when'),
      AwingWord('mə́', 'they'),
      AwingWord('méla', '—'),
      AwingWord('akəb', '—'),
      AwingWord('ńga', '—'),
      AwingWord('tsô', '(disappear)'),
    ],
  ),
];

class SentencesScreen extends StatefulWidget {
  const SentencesScreen({Key? key}) : super(key: key);

  @override
  State<SentencesScreen> createState() => _SentencesScreenState();
}

class _SentencesScreenState extends State<SentencesScreen> {
  final PronunciationService _pronunciation = PronunciationService();
  int _selectedMode = 0; // 0 = Reading, 1 = Building

  @override
  void initState() {
    super.initState();
    _pronunciation.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().completeLesson('medium_sentences');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sentence Building'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Mode tabs
          Container(
            color: Colors.orange.shade100,
            child: Row(
              children: [
                Expanded(
                  child: _ModeTab(
                    label: 'Reading',
                    isSelected: _selectedMode == 0,
                    onTap: () => setState(() => _selectedMode = 0),
                  ),
                ),
                Expanded(
                  child: _ModeTab(
                    label: 'Building',
                    isSelected: _selectedMode == 1,
                    onTap: () => setState(() => _selectedMode = 1),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _selectedMode == 0
                ? _ReadingMode(pronunciation: _pronunciation)
                : _BuildingMode(pronunciation: _pronunciation),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.orange : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.orange : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

class _ReadingMode extends StatefulWidget {
  final PronunciationService pronunciation;

  const _ReadingMode({required this.pronunciation});

  @override
  State<_ReadingMode> createState() => _ReadingModeState();
}

class _ReadingModeState extends State<_ReadingMode> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Page indicator
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              awingSentences.length,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: CircleAvatar(
                  radius: 5,
                  backgroundColor: _currentIndex == index
                      ? Colors.orange
                      : Colors.orange.shade200,
                ),
              ),
            ),
          ),
        ),
        // Sentences
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: awingSentences.length,
            itemBuilder: (context, index) => _SentenceCard(
              sentence: awingSentences[index],
              pronunciation: widget.pronunciation,
            ),
          ),
        ),
      ],
    );
  }
}

class _SentenceCard extends StatelessWidget {
  final AwingSentence sentence;
  final PronunciationService pronunciation;

  const _SentenceCard({
    required this.sentence,
    required this.pronunciation,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main sentence
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange, width: 2),
            ),
            child: Column(
              children: [
                Text(
                  sentence.awing,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  sentence.english,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  child: FloatingActionButton.extended(
                    backgroundColor: Colors.orange,
                    onPressed: () => pronunciation.speakAwing(sentence.awing),
                    icon: const Icon(Icons.volume_up, color: Colors.white),
                    label: const Text(
                      'Hear It',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Word-by-word breakdown
          const Text(
            'Word by Word:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...sentence.words.asMap().entries.map((entry) {
            final idx = entry.key;
            final word = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${idx + 1}. ${word.word}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            word.english,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    FloatingActionButton.small(
                      backgroundColor: Colors.blue,
                      onPressed: () => pronunciation.speakAwing(word.word),
                      child: const Icon(Icons.volume_up, color: Colors.white),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BuildingMode extends StatefulWidget {
  final PronunciationService pronunciation;

  const _BuildingMode({required this.pronunciation});

  @override
  State<_BuildingMode> createState() => _BuildingModeState();
}

class _BuildingModeState extends State<_BuildingMode> {
  final _random = Random();
  late List<AwingSentence> _buildingExercises;
  int _currentIndex = 0;
  late List<AwingWord> _shuffledWords;
  late List<AwingWord> _selectedOrder;

  @override
  void initState() {
    super.initState();
    _buildingExercises = List.from(awingSentences)..shuffle(_random);
    _initializeSentence();
  }

  void _initializeSentence() {
    final current = _buildingExercises[_currentIndex];
    _shuffledWords = List.from(current.words)..shuffle(_random);
    _selectedOrder = [];
  }

  void _selectWord(AwingWord word) {
    setState(() {
      _shuffledWords.remove(word);
      _selectedOrder.add(word);
    });
  }

  void _deselectWord(int index) {
    setState(() {
      final word = _selectedOrder[index];
      _selectedOrder.removeAt(index);
      _shuffledWords.add(word);
      _shuffledWords.sort(
        (a, b) => _buildingExercises[_currentIndex]
            .words
            .indexOf(a)
            .compareTo(_buildingExercises[_currentIndex].words.indexOf(b)),
      );
    });
  }

  void _checkAnswer() {
    final current = _buildingExercises[_currentIndex];
    final isCorrect =
        _selectedOrder.map((w) => w.word).join(' ') == current.awing;

    String message;
    Color bgColor;
    if (isCorrect) {
      message = 'Perfect! You got it right!';
      bgColor = Colors.green;
    } else {
      message = 'Not quite. Try again!';
      bgColor = Colors.red;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        duration: const Duration(seconds: 2),
      ),
    );

    if (isCorrect) {
      Future.delayed(const Duration(seconds: 2), () {
        if (_currentIndex + 1 < _buildingExercises.length) {
          setState(() {
            _currentIndex++;
            _initializeSentence();
          });
        } else {
          _showResults();
        }
      });
    }
  }

  void _showResults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Great Work!'),
        content: const Text('You completed all sentence building exercises!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _buildingExercises = List.from(awingSentences)..shuffle(_random);
                _currentIndex = 0;
                _initializeSentence();
              });
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _buildingExercises[_currentIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions
          const Text(
            'Arrange the words to form the sentence:',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          // Target sentence (for reference)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              current.english,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Selected order
          const Text(
            'Your sentence:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: _selectedOrder.isEmpty
                ? const Text(
                    'Tap words below to build your sentence...',
                    style: TextStyle(color: Colors.grey),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedOrder.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final word = entry.value;
                      return InkWell(
                        onTap: () => _deselectWord(idx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            word.word,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 24),
          // Available words
          const Text(
            'Available words:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _shuffledWords.map((word) {
              return InkWell(
                onTap: () => _selectWord(word),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        word.word,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        word.english,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // Check button
          Center(
            child: ElevatedButton(
              onPressed: _selectedOrder.length == current.words.length
                  ? _checkAnswer
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text(
                'Check Answer',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Question ${_currentIndex + 1}/${_buildingExercises.length}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
