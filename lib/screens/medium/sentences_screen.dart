import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/components/awing_audio_button.dart';

/// Simple Awing sentences for the Medium module
class AwingSentence {
  final String awing;
  final String english;
  final List<AwingWord> words; // word-by-word breakdown
  final int difficulty; // 1=beginner, 2=medium (default), 3=expert

  const AwingSentence({
    required this.awing,
    required this.english,
    required this.words,
    this.difficulty = 2,
  });
}

class AwingWord {
  final String word;
  final String english;

  const AwingWord(this.word, this.english);
}

/// Beginner mode gets ONLY difficulty=1 sentences (short everyday phrases).
List<AwingSentence> get beginnerSentences =>
    awingSentences.where((s) => s.difficulty == 1).toList();

/// Medium mode gets ONLY difficulty=2 sentences (short-medium sentences).
List<AwingSentence> get mediumSentences =>
    awingSentences.where((s) => s.difficulty == 2).toList();

/// Expert mode gets ONLY difficulty=3 sentences (long proverbs from dict).
List<AwingSentence> get expertSentences =>
    awingSentences.where((s) => s.difficulty == 3).toList();

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
    difficulty: 1,
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
    difficulty: 1,
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
    difficulty: 1,
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
    difficulty: 1,
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
    difficulty: 2,
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
    difficulty: 1,
    words: [
      AwingWord('Lɛ̌', 'This is'),
      AwingWord("nəpɔ'ɔ́", 'pumpkin'),
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
    difficulty: 1,
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
    difficulty: 1,
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
    difficulty: 2,
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
    difficulty: 1,
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
    difficulty: 1,
    words: [
      AwingWord('Maŋ', 'I'),
      AwingWord('yî', 'will'),
      AwingWord('ghenə̂', 'go'),
    ],
  ),
  AwingSentence(
    awing: 'Maŋ yó ghenə̂.',
    english: 'I shall go.',
    difficulty: 1,
    words: [
      AwingWord('Maŋ', 'I'),
      AwingWord('yó', 'shall'),
      AwingWord('ghenə̂', 'go'),
    ],
  ),
  AwingSentence(
    awing: 'Ajú zə̂ á pəgə.',
    english: 'That thing is spoilt.',
    difficulty: 1,
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
    difficulty: 1,
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
    difficulty: 1,
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
    difficulty: 2,
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
    difficulty: 1,
    words: [
      AwingWord('Tséeba', 'speak'),
      AwingWord('á', 'the'),
      AwingWord('ndəŋndəŋɔ́', 'truth'),
    ],
  ),
  AwingSentence(
    awing: 'Yîə á ndzəŋ mənumə.',
    english: 'Come in the afternoon.',
    difficulty: 1,
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
    difficulty: 2,
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
    difficulty: 1,
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
    difficulty: 1,
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
    difficulty: 2,
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
    difficulty: 1,
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
    difficulty: 2,
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
    difficulty: 2,
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
    difficulty: 3,
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
    difficulty: 3,
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
    difficulty: 3,
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
    difficulty: 2,
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
    difficulty: 3,
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
  // DICT p15 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Pə lɔgə achilə ajú ntséd əpú ləba pó pə pipə atəənə.",
    english: 'Stoppers are used to patch both plastic and metal containers.',
    difficulty: 3,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('lɔgə', '_'),
      AwingWord('achilə', '_'),
      AwingWord('ajú', '_'),
      AwingWord('ntséd', '_'),
      AwingWord('əpú', '_'),
      AwingWord('ləba', '_'),
      AwingWord('pó', '_'),
      AwingWord('pə', '_'),
      AwingWord('pipə', '_'),
    ],
  ),

  // DICT p16 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Pá chú'ə achú' ló əlè ɛtsəmə alá' Mbɨwɨŋə.",
    english: 'Achu is prepared daily in Awing.',
    difficulty: 2,
    words: [
      AwingWord('Pá', '_'),
      AwingWord('chú\'ə', '_'),
      AwingWord('achú\'', '_'),
      AwingWord('ló', '_'),
      AwingWord('əlè', '_'),
      AwingWord('ɛtsəmə', '_'),
      AwingWord('alá\'', '_'),
      AwingWord('Mbɨwɨŋə', '_'),
    ],
  ),

  // DICT p16 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Pí pá kwéŋə ló pá' achwí'nə á chí ná á təti pó.",
    english: 'People prosper when there is unity amongst them.',
    difficulty: 3,
    words: [
      AwingWord('Pí', '_'),
      AwingWord('pá', '_'),
      AwingWord('kwéŋə', '_'),
      AwingWord('ló', '_'),
      AwingWord('pá\'', '_'),
      AwingWord('achwí\'nə', '_'),
      AwingWord('á', '_'),
      AwingWord('chí', '_'),
      AwingWord('ná', '_'),
      AwingWord('á', '_'),
    ],
  ),

  // DICT p16 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Á pɔŋə mə fa' nə afa'ə ɔsè.",
    english: 'It pays to work for God.',
    difficulty: 2,
    words: [
      AwingWord('Á', '_'),
      AwingWord('pɔŋə', '_'),
      AwingWord('mə', '_'),
      AwingWord('fa\'', '_'),
      AwingWord('nə', '_'),
      AwingWord('afa\'ə', '_'),
      AwingWord('ɔsè', '_'),
    ],
  ),

  // DICT p16 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Lá tɔ'ə nda' ɔsè mbɔ'ə a fógə afankónuə á məm mbɨə.",
    english: 'Only God alone can rid the world of errors.',
    difficulty: 3,
    words: [
      AwingWord('Lá', '_'),
      AwingWord('tɔ\'ə', '_'),
      AwingWord('nda\'', '_'),
      AwingWord('ɔsè', '_'),
      AwingWord('mbɔ\'ə', '_'),
      AwingWord('a', '_'),
      AwingWord('fógə', '_'),
      AwingWord('afankónuə', '_'),
      AwingWord('á', '_'),
      AwingWord('məm', '_'),
    ],
  ),

  // DICT p16 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Afeelákwú'ə neemə á ləmkə.",
    english: 'The small of back of a cow is very tasty.',
    difficulty: 1,
    words: [
      AwingWord('Afeelákwú\'ə', '_'),
      AwingWord('neemə', '_'),
      AwingWord('á', '_'),
      AwingWord('ləmkə', '_'),
    ],
  ),

  // DICT p17 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Fəələ mó nó afəələ.",
    english: 'Put water into the child\'s bowel using a water bag.',
    difficulty: 1,
    words: [
      AwingWord('Fəələ', '_'),
      AwingWord('mó', '_'),
      AwingWord('nó', '_'),
      AwingWord('afəələ', '_'),
    ],
  ),

  // DICT p17 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Pá zó'ə məngyè lá pó ndú əyí əfɛlə afoonə ndzɔ'ə.",
    english: 'When a man gets a new bride, both of them go through the shaving ceremony.',
    difficulty: 2,
    words: [
      AwingWord('Pá', '_'),
      AwingWord('zó\'ə', '_'),
      AwingWord('məngyè', '_'),
      AwingWord('lá', '_'),
      AwingWord('pó', '_'),
      AwingWord('ndú', '_'),
      AwingWord('əyí', '_'),
      AwingWord('əfɛlə', '_'),
      AwingWord('afoonə', '_'),
      AwingWord('ndzɔ\'ə', '_'),
    ],
  ),


  // DICT p19 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Ndɔŋ mó nkə a laŋə aŋwa'lə lá tso'ə aghabnə.",
    english: 'A lazy child succeeds only averagely in school.',
    difficulty: 2,
    words: [
      AwingWord('Ndɔŋ', '_'),
      AwingWord('mó', '_'),
      AwingWord('nkə', '_'),
      AwingWord('a', '_'),
      AwingWord('laŋə', '_'),
      AwingWord('aŋwa\'lə', '_'),
      AwingWord('lá', '_'),
      AwingWord('tso\'ə', '_'),
      AwingWord('aghabnə', '_'),
    ],
  ),

  // DICT p19 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Máchisə mée lá pá mya'ə aghaglə.",
    english: 'When match gets finished the empty box is thrown away.',
    difficulty: 2,
    words: [
      AwingWord('Máchisə', '_'),
      AwingWord('mée', '_'),
      AwingWord('lá', '_'),
      AwingWord('pá', '_'),
      AwingWord('mya\'ə', '_'),
      AwingWord('aghaglə', '_'),
    ],
  ),

  // DICT p19 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Mbɔ' ŋwunə ghenə asəg ntso a kə aghaglətúə ŋwu pón pó.",
    english: 'One can never lack a human skull on a battle field.',
    difficulty: 3,
    words: [
      AwingWord('Mbɔ\'', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('ghenə', '_'),
      AwingWord('asəg', '_'),
      AwingWord('ntso', '_'),
      AwingWord('a', '_'),
      AwingWord('kə', '_'),
      AwingWord('aghaglətúə', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('pón', '_'),
    ],
  ),

  // DICT p19 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Aghántə ghelə mbi zaŋkə, ŋwunə kə ntyantə.",
    english: 'Physical exercise makes the body lighter and strong Pl.',
    difficulty: 2,
    words: [
      AwingWord('Aghántə', '_'),
      AwingWord('ghelə', '_'),
      AwingWord('mbi', '_'),
      AwingWord('zaŋkə', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('kə', '_'),
      AwingWord('ntyantə', '_'),
    ],
  ),

  // DICT p19 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Agheŋə ntsoolə məkálə á kəg ntseelə yə shí ŋwunə.",
    english: 'A white man\'s lip is smaller than that of a black man.',
    difficulty: 2,
    words: [
      AwingWord('Agheŋə', '_'),
      AwingWord('ntsoolə', '_'),
      AwingWord('məkálə', '_'),
      AwingWord('á', '_'),
      AwingWord('kəg', '_'),
      AwingWord('ntseelə', '_'),
      AwingWord('yə', '_'),
      AwingWord('shí', '_'),
      AwingWord('ŋwunə', '_'),
    ],
  ),

  // DICT p23 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Nchindê ntsəmə alá' Mbíiwíŋ á túgə akeelə kwúneemə.",
    english: 'Every compound in Awing has a pig sty.',
    difficulty: 2,
    words: [
      AwingWord('Nchindê', '_'),
      AwingWord('ntsəmə', '_'),
      AwingWord('alá\'', '_'),
      AwingWord('Mbíiwíŋ', '_'),
      AwingWord('á', '_'),
      AwingWord('túgə', '_'),
      AwingWord('akeelə', '_'),
      AwingWord('kwúneemə', '_'),
    ],
  ),

  // DICT p23 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Pəŋgyé pətsə pá túgə akəféŋəntso təshunə.",
    english: 'Some women utter a lot of obscene words.',
    difficulty: 2,
    words: [
      AwingWord('Pəŋgyé', '_'),
      AwingWord('pətsə', '_'),
      AwingWord('pá', '_'),
      AwingWord('túgə', '_'),
      AwingWord('akəféŋəntso', '_'),
      AwingWord('təshunə', '_'),
    ],
  ),

  // DICT p23 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Ná'ə akəghan ə pəŋ nə ngaalə.",
    english: 'Okro soup is good for garri.',
    difficulty: 2,
    words: [
      AwingWord('Ná\'ə', '_'),
      AwingWord('akəghan', '_'),
      AwingWord('ə', '_'),
      AwingWord('pəŋ', '_'),
      AwingWord('nə', '_'),
      AwingWord('ngaalə', '_'),
    ],
  ),

  // DICT p23 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Akəghə atséebə á pəŋ pí pətsə təshubə.",
    english: 'Some people are too interested in foolish talk.',
    difficulty: 2,
    words: [
      AwingWord('Akəghə', '_'),
      AwingWord('atséebə', '_'),
      AwingWord('á', '_'),
      AwingWord('pəŋ', '_'),
      AwingWord('pí', '_'),
      AwingWord('pətsə', '_'),
      AwingWord('təshubə', '_'),
    ],
  ),

  // DICT p24 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Mbɨwɨŋ zá mbá' əkəká' ló aghá akyé akəfɛ.",
    english: 'Awing people usually weave baskets during the coffee harvesting period.',
    difficulty: 2,
    words: [
      AwingWord('Mbɨwɨŋ', '_'),
      AwingWord('zá', '_'),
      AwingWord('mbá\'', '_'),
      AwingWord('əkəká\'', '_'),
      AwingWord('ló', '_'),
      AwingWord('aghá', '_'),
      AwingWord('akyé', '_'),
      AwingWord('akəfɛ', '_'),
    ],
  ),

  // DICT p24 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Akəkógə á kɔŋə má nid ná mətəənə.",
    english: 'A fool likes to demonstrate his capability.',
    difficulty: 2,
    words: [
      AwingWord('Akəkógə', '_'),
      AwingWord('á', '_'),
      AwingWord('kɔŋə', '_'),
      AwingWord('má', '_'),
      AwingWord('nid', '_'),
      AwingWord('ná', '_'),
      AwingWord('mətəənə', '_'),
    ],
  ),

  // DICT p24 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Á aghá apɨəpú ŋwu ntsəmə a néŋə akə'lɔ á ndɛ kwúna əyɨə.",
    english: 'During the planting season every body puts a hedge round his pig\'s neck.',
    difficulty: 3,
    words: [
      AwingWord('Á', '_'),
      AwingWord('aghá', '_'),
      AwingWord('apɨəpú', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('ntsəmə', '_'),
      AwingWord('a', '_'),
      AwingWord('néŋə', '_'),
      AwingWord('akə\'lɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('ndɛ', '_'),
    ],
  ),

  // DICT p24 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Mbɔ' tɔ tɔŋə anu o peg fɛ akəmə atsáb ntɛ.",
    english: 'If you want to say anything, first give an introduction.',
    difficulty: 2,
    words: [
      AwingWord('Mbɔ\'', '_'),
      AwingWord('tɔ', '_'),
      AwingWord('tɔŋə', '_'),
      AwingWord('anu', '_'),
      AwingWord('o', '_'),
      AwingWord('peg', '_'),
      AwingWord('fɛ', '_'),
      AwingWord('akəmə', '_'),
      AwingWord('atsáb', '_'),
      AwingWord('ntɛ', '_'),
    ],
  ),

  // DICT p24 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Akəmə mbaŋə á chɨ ló ándó məkɔŋ má ntsoolə.",
    english: 'A throwing stick is like a weapon of war.',
    difficulty: 2,
    words: [
      AwingWord('Akəmə', '_'),
      AwingWord('mbaŋə', '_'),
      AwingWord('á', '_'),
      AwingWord('chɨ', '_'),
      AwingWord('ló', '_'),
      AwingWord('ándó', '_'),
      AwingWord('məkɔŋ', '_'),
      AwingWord('má', '_'),
      AwingWord('ntsoolə', '_'),
    ],
  ),

  // DICT p24 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Akəmátɔgɨə ló ŋwu pá' a kɛ nɛ ɨlɨ' tɔ ndzó'ə pɔ.",
    english: 'A deaf is a person who does not hear.',
    difficulty: 3,
    words: [
      AwingWord('Akəmátɔgɨə', '_'),
      AwingWord('ló', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('pá\'', '_'),
      AwingWord('a', '_'),
      AwingWord('kɛ', '_'),
      AwingWord('nɛ', '_'),
      AwingWord('ɨlɨ\'', '_'),
      AwingWord('tɔ', '_'),
      AwingWord('ndzó\'ə', '_'),
    ],
  ),

  // DICT p24 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Ndɛ tə akəŋ á chɨ ló ándó mɛtɛɛnə.",
    english: 'A house without a covering is like a market.',
    difficulty: 2,
    words: [
      AwingWord('Ndɛ', '_'),
      AwingWord('tə', '_'),
      AwingWord('akəŋ', '_'),
      AwingWord('á', '_'),
      AwingWord('chɨ', '_'),
      AwingWord('ló', '_'),
      AwingWord('ándó', '_'),
      AwingWord('mɛtɛɛnə', '_'),
    ],
  ),

  // DICT p26 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "A fɛ ɔkwa'lɔ pɛn pɛ nɔ maŋɔ.",
    english: 'He gave me two questions.',
    difficulty: 2,
    words: [
      AwingWord('A', '_'),
      AwingWord('fɛ', '_'),
      AwingWord('ɔkwa\'lɔ', '_'),
      AwingWord('pɛn', '_'),
      AwingWord('pɛ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('maŋɔ', '_'),
    ],
  ),

  // DICT p26 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Akwa'lɔ sɔtɔnɔ ɔ nɔ tɔshɔnɔ.",
    english: 'Satan\'s temptation is so much.',
    difficulty: 1,
    words: [
      AwingWord('Akwa\'lɔ', '_'),
      AwingWord('sɔtɔnɔ', '_'),
      AwingWord('ɔ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('tɔshɔnɔ', '_'),
    ],
  ),

  // DICT p28 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Pɔ lɔgɔ ɔkyɔglɔ nɔgɔlɔ ɔfɔ ɔwɔ.",
    english: 'A sort of garden egg- like fruit is used in making medicines.',
    difficulty: 2,
    words: [
      AwingWord('Pɔ', '_'),
      AwingWord('lɔgɔ', '_'),
      AwingWord('ɔkyɔglɔ', '_'),
      AwingWord('nɔgɔlɔ', '_'),
      AwingWord('ɔfɔ', '_'),
      AwingWord('ɔwɔ', '_'),
    ],
  ),


  // DICT p33 — added Session 63 Part H 2026-07-22
  AwingSentence(
    awing: "Ali'átsəmə á ndu mbi ló ali' mbɔ' ŋwunə kwéŋ ówá.",
    english: 'One can prosper anywhere in the world.',
    difficulty: 2,
    words: [
      AwingWord('Ali\'átsəmə', '_'),
      AwingWord('á', '_'),
      AwingWord('ndu', '_'),
      AwingWord('mbi', '_'),
      AwingWord('ló', '_'),
      AwingWord('ali\'', '_'),
      AwingWord('mbɔ\'', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('kwéŋ', '_'),
      AwingWord('ówá', '_'),
    ],
  ),

  // DICT p15 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "ə əshi'nə 14 achílə ajúmə yə ngaalə.",
    english: 'Sieves are of different kinds; that of corn fufu, that of sand and that of garri.',
    difficulty: 2,
    words: [
      AwingWord('ə', '_'),
      AwingWord('əshi\'nə', '_'),
      AwingWord('14', '_'),
      AwingWord('achílə', '_'),
      AwingWord('ajúmə', '_'),
      AwingWord('yə', '_'),
      AwingWord('ngaalə', '_'),
    ],
  ),

  // DICT p15 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "ə əshi'nə [atʃi yə ʃiʔnə] n 7/8.",
    english: 'Good sign, happening when blood twitches somebody\'s eye in a particular spot depending on the person.',
    difficulty: 2,
    words: [
      AwingWord('ə', '_'),
      AwingWord('əshi\'nə', '_'),
      AwingWord('atʃi', '_'),
      AwingWord('yə', '_'),
      AwingWord('ʃiʔnə', '_'),
      AwingWord('n', '_'),
      AwingWord('7', '_'),
      AwingWord('8', '_'),
    ],
  ),

  // DICT p15 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Achikə ŋwunə a pó'tə nchɪə mbɪ lə chi nə.",
    english: 'A person who is old and irresponsive to emotions only lives for living sake.',
    difficulty: 2,
    words: [
      AwingWord('Achikə', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('pó\'tə', '_'),
      AwingWord('nchɪə', '_'),
      AwingWord('mbɪ', '_'),
      AwingWord('lə', '_'),
      AwingWord('chi', '_'),
      AwingWord('nə', '_'),
    ],
  ),

  // DICT p15 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Pə zá mbɪəə lə əchi'lə nəyɛŋə nə azá yə fɪə.",
    english: 'Turfs of grass are usually planted on a newly dug play ground.',
    difficulty: 2,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('zá', '_'),
      AwingWord('mbɪəə', '_'),
      AwingWord('lə', '_'),
      AwingWord('əchi\'lə', '_'),
      AwingWord('nəyɛŋə', '_'),
      AwingWord('nə', '_'),
      AwingWord('azá', '_'),
      AwingWord('yə', '_'),
      AwingWord('fɪə', '_'),
    ],
  ),

  // DICT p16 — added Session 63 Part H batch 2
  // AwingSentence(
  // awing: "Pá chú'ə achú' ló əlè ɛtsəmə alá' Mbɨwɨŋə.",
  // english: 'Achu is prepared daily in Awing.',
  // difficulty: 2,
  // words: [
  // AwingWord('Pá', '_'),
  // AwingWord('chú\'ə', '_'),
  // AwingWord('achú\'', '_'),
  // AwingWord('ló', '_'),
  // AwingWord('əlè', '_'),
  // AwingWord('ɛtsəmə', '_'),
  // AwingWord('alá\'', '_'),
  // AwingWord('Mbɨwɨŋə', '_'),
  // ],
  // ),  // REMOVED Session 66u similar-spelling: same English as the block at line 484 (Pá chú'ə achú' ló əlè ɛtsəmə a)

  // DICT p16 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "ə [àtʃwínə] n 7/8.",
    english: 'Act of provocation or threat, done by twitching each other\'s fingers Sg.',
    difficulty: 1,
    words: [
      AwingWord('ə', '_'),
      AwingWord('àtʃwínə', '_'),
      AwingWord('n', '_'),
      AwingWord('7', '_'),
      AwingWord('8', '_'),
    ],
  ),

  // DICT p16 — added Session 63 Part H batch 2
  // AwingSentence(
  // awing: "Pí pá kwéŋə ló pá' achwí'nə á chí ná á təti pó.",
  // english: 'People prosper when there is unity amongst them.',
  // difficulty: 3,
  // words: [
  // AwingWord('Pí', '_'),
  // AwingWord('pá', '_'),
  // AwingWord('kwéŋə', '_'),
  // AwingWord('ló', '_'),
  // AwingWord('pá\'', '_'),
  // AwingWord('achwí\'nə', '_'),
  // AwingWord('á', '_'),
  // AwingWord('chí', '_'),
  // AwingWord('ná', '_'),
  // AwingWord('á', '_'),
  // ],
  // ),  // REMOVED Session 66u similar-spelling: same English as the block at line 501 (Pí pá kwéŋə ló pá' achwí'nə á )

  // DICT p16 — added Session 63 Part H batch 2
  // AwingSentence(
  // awing: "Á pɔŋə mə fa' nə afa'ə ɔsè.",
  // english: 'It pays to work for God.',
  // difficulty: 2,
  // words: [
  // AwingWord('Á', '_'),
  // AwingWord('pɔŋə', '_'),
  // AwingWord('mə', '_'),
  // AwingWord('fa\'', '_'),
  // AwingWord('nə', '_'),
  // AwingWord('afa\'ə', '_'),
  // AwingWord('ɔsè', '_'),
  // ],
  // ),  // REMOVED Session 66u similar-spelling: same English as the block at line 520 (Á pɔŋə mə fa' nə afa'ə ɔsè.)

  // DICT p16 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "ə a zoomə tá əyɨ ló á pá ló chigə afanə.",
    english: 'Insulting one\'s father is taboo.',
    difficulty: 3,
    words: [
      AwingWord('ə', '_'),
      AwingWord('a', '_'),
      AwingWord('zoomə', '_'),
      AwingWord('tá', '_'),
      AwingWord('əyɨ', '_'),
      AwingWord('ló', '_'),
      AwingWord('á', '_'),
      AwingWord('pá', '_'),
      AwingWord('ló', '_'),
      AwingWord('chigə', '_'),
    ],
  ),

  // DICT p16 — added Session 63 Part H batch 2
  // AwingSentence(
  // awing: "Lá tɔ'ə nda' ɔsè mbɔ'ə a fógə afankónuə á məm mbɨə.",
  // english: 'Only God alone can rid the world of errors.',
  // difficulty: 3,
  // words: [
  // AwingWord('Lá', '_'),
  // AwingWord('tɔ\'ə', '_'),
  // AwingWord('nda\'', '_'),
  // AwingWord('ɔsè', '_'),
  // AwingWord('mbɔ\'ə', '_'),
  // AwingWord('a', '_'),
  // AwingWord('fógə', '_'),
  // AwingWord('afankónuə', '_'),
  // AwingWord('á', '_'),
  // AwingWord('məm', '_'),
  // ],
  // ),  // REMOVED Session 66u similar-spelling: same English as the block at line 536 (Lá tɔ'ə nda' ɔsè mbɔ'ə a fógə )

  // DICT p16 — added Session 63 Part H batch 2
  // AwingSentence(
  // awing: "Afeelákwú'ə neemə á ləmkə.",
  // english: 'The small of back of a cow is very tasty.',
  // difficulty: 1,
  // words: [
  // AwingWord('Afeelákwú\'ə', '_'),
  // AwingWord('neemə', '_'),
  // AwingWord('á', '_'),
  // AwingWord('ləmkə', '_'),
  // ],
  // ),  // REMOVED Session 66u similar-spelling: same English as the block at line 555 (Afeelákwú'ə neemə á ləmkə.)

  // DICT p16 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Mbɔ' afélə ɲwunə a mə áfa'ə ándó mbyáb.",
    english: 'A physically powerless person cannot work as a guard.',
    difficulty: 2,
    words: [
      AwingWord('Mbɔ\'', '_'),
      AwingWord('afélə', '_'),
      AwingWord('ɲwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('mə', '_'),
      AwingWord('áfa\'ə', '_'),
      AwingWord('ándó', '_'),
      AwingWord('mbyáb', '_'),
    ],
  ),

  // DICT p17 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Á pá Afédngón lá pi pá jwitá, ńgen ńgá pəlim póobá.",
    english: 'On the third day of the week people rest and visit their relatives.',
    difficulty: 3,
    words: [
      AwingWord('Á', '_'),
      AwingWord('pá', '_'),
      AwingWord('Afédngón', '_'),
      AwingWord('lá', '_'),
      AwingWord('pi', '_'),
      AwingWord('pá', '_'),
      AwingWord('jwitá', '_'),
      AwingWord('ńgen', '_'),
      AwingWord('ńgá', '_'),
      AwingWord('pəlim', '_'),
    ],
  ),

  // DICT p17 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "əələ neemə [afə:lə nɛ:mə] n 7/6.",
    english: 'A female pig that has passed the stage of crossing.',
    difficulty: 2,
    words: [
      AwingWord('əələ', '_'),
      AwingWord('neemə', '_'),
      AwingWord('afə', '_'),
      AwingWord('lə', '_'),
      AwingWord('nɛ', '_'),
      AwingWord('mə', '_'),
      AwingWord('n', '_'),
      AwingWord('7', '_'),
      AwingWord('6', '_'),
    ],
  ),

  // DICT p17 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "əməlá'ə [əfəməláʔə] n 7/3.",
    english: 'Land where forefathers settled and lived for quite sometime, then moved to another settlement still within the Awing clan.',
    difficulty: 1,
    words: [
      AwingWord('əməlá\'ə', '_'),
      AwingWord('əfəməláʔə', '_'),
      AwingWord('n', '_'),
      AwingWord('7', '_'),
      AwingWord('3', '_'),
    ],
  ),

  // DICT p17 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Mó mbéŋə nə ńdá' ńtə əfi'nə nkaŋ mbə' ndóŋ əjɪə.",
    english: 'A goat once tried to imitate and broke its horn.',
    difficulty: 2,
    words: [
      AwingWord('Mó', '_'),
      AwingWord('mbéŋə', '_'),
      AwingWord('nə', '_'),
      AwingWord('ńdá\'', '_'),
      AwingWord('ńtə', '_'),
      AwingWord('əfi\'nə', '_'),
      AwingWord('nkaŋ', '_'),
      AwingWord('mbə\'', '_'),
      AwingWord('ndóŋ', '_'),
      AwingWord('əjɪə', '_'),
    ],
  ),

  // DICT p17 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Mbyáŋnə á ghenə afo lá á təmə neemə, pəngyè pá ghenə mə lí' nə məjɪə.",
    english: 'When men go hunting, it is for game and when women go to the farm it is to bring food.',
    difficulty: 3,
    words: [
      AwingWord('Mbyáŋnə', '_'),
      AwingWord('á', '_'),
      AwingWord('ghenə', '_'),
      AwingWord('afo', '_'),
      AwingWord('lá', '_'),
      AwingWord('á', '_'),
      AwingWord('təmə', '_'),
      AwingWord('neemə', '_'),
      AwingWord('pəngyè', '_'),
      AwingWord('pá', '_'),
    ],
  ),

  // DICT p17 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Məngyè a chi nə alá' ńkè afo ghenə pá lɔgə yí lá ándó ndɔŋ məngyè.",
    english: 'A woman who lives in the village and does not do farm work is looked upon as a lazy woman.',
    difficulty: 3,
    words: [
      AwingWord('Məngyè', '_'),
      AwingWord('a', '_'),
      AwingWord('chi', '_'),
      AwingWord('nə', '_'),
      AwingWord('alá\'', '_'),
      AwingWord('ńkè', '_'),
      AwingWord('afo', '_'),
      AwingWord('ghenə', '_'),
      AwingWord('pá', '_'),
      AwingWord('lɔgə', '_'),
    ],
  ),

  // DICT p17 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "ə ndzɔ'ə [afo:nə ndzɔʔə] n 7/8.",
    english: 'A ceremony in which the bride and groom are shaven, of their private parts.',
    difficulty: 2,
    words: [
      AwingWord('ə', '_'),
      AwingWord('ndzɔ\'ə', '_'),
      AwingWord('afo', '_'),
      AwingWord('nə', '_'),
      AwingWord('ndzɔʔə', '_'),
      AwingWord('n', '_'),
      AwingWord('7', '_'),
      AwingWord('8', '_'),
    ],
  ),

  // DICT p17 — added Session 63 Part H batch 2
  // AwingSentence(
  // awing: "Pá zó'ə məngyè lá pó ndú əyí əfɛlə afoonə ndzɔ'ə.",
  // english: 'When a man gets a new bride, both of them go through the shaving ceremony.',
  // difficulty: 2,
  // words: [
  // AwingWord('Pá', '_'),
  // AwingWord('zó\'ə', '_'),
  // AwingWord('məngyè', '_'),
  // AwingWord('lá', '_'),
  // AwingWord('pó', '_'),
  // AwingWord('ndú', '_'),
  // AwingWord('əyí', '_'),
  // AwingWord('əfɛlə', '_'),
  // AwingWord('afoonə', '_'),
  // AwingWord('ndzɔ\'ə', '_'),
  // ],
  // ),  // REMOVED Session 66u similar-spelling: same English as the block at line 581 (Pá zó'ə məngyè lá pó ndú əyí ə)

  // DICT p17 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Səmə á kó' lá məfũ mə atí mə kwɛdnə.",
    english: 'When the wind blows, leaves get littered everywhere.',
    difficulty: 2,
    words: [
      AwingWord('Səmə', '_'),
      AwingWord('á', '_'),
      AwingWord('kó\'', '_'),
      AwingWord('lá', '_'),
      AwingWord('məfũ', '_'),
      AwingWord('mə', '_'),
      AwingWord('atí', '_'),
      AwingWord('mə', '_'),
      AwingWord('kwɛdnə', '_'),
    ],
  ),

  // DICT p18 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "One thousand francs CFA note (colloquial).",
    english: 'Afa\'a alé mbĩ ali\' pətsə lá afũa atĩa.',
    difficulty: 2,
    words: [
      AwingWord('One', '_'),
      AwingWord('thousand', '_'),
      AwingWord('francs', '_'),
      AwingWord('CFA', '_'),
      AwingWord('note', '_'),
      AwingWord('colloquial', '_'),
    ],
  ),

  // DICT p18 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Pi pətsə pó løgə lá məfũ mə azán əfeŋ ndē əzəb əwə.",
    english: 'Some people use palm leaves to roof their houses.',
    difficulty: 3,
    words: [
      AwingWord('Pi', '_'),
      AwingWord('pətsə', '_'),
      AwingWord('pó', '_'),
      AwingWord('løgə', '_'),
      AwingWord('lá', '_'),
      AwingWord('məfũ', '_'),
      AwingWord('mə', '_'),
      AwingWord('azán', '_'),
      AwingWord('əfeŋ', '_'),
      AwingWord('ndē', '_'),
    ],
  ),

  // DICT p18 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Afũa fóola á kə njwĩtə ŋwunə.",
    english: 'Rat poison can also kill a human being.',
    difficulty: 2,
    words: [
      AwingWord('Afũa', '_'),
      AwingWord('fóola', '_'),
      AwingWord('á', '_'),
      AwingWord('kə', '_'),
      AwingWord('njwĩtə', '_'),
      AwingWord('ŋwunə', '_'),
    ],
  ),

  // DICT p18 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Pá kə li'ə yə a pə njĩə afũa ndi'ə.",
    english: 'He was poisoned and as a result he took anti-poison.',
    difficulty: 2,
    words: [
      AwingWord('Pá', '_'),
      AwingWord('kə', '_'),
      AwingWord('li\'ə', '_'),
      AwingWord('yə', '_'),
      AwingWord('a', '_'),
      AwingWord('pə', '_'),
      AwingWord('njĩə', '_'),
      AwingWord('afũa', '_'),
      AwingWord('ndi\'ə', '_'),
    ],
  ),

  // DICT p18 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Afũa ngəsánə á chi lá mbə lá chigə məjĩ mə kwüneemə.",
    english: 'Corn husk is delicious food for pigs.',
    difficulty: 3,
    words: [
      AwingWord('Afũa', '_'),
      AwingWord('ngəsánə', '_'),
      AwingWord('á', '_'),
      AwingWord('chi', '_'),
      AwingWord('lá', '_'),
      AwingWord('mbə', '_'),
      AwingWord('lá', '_'),
      AwingWord('chigə', '_'),
      AwingWord('məjĩ', '_'),
      AwingWord('mə', '_'),
    ],
  ),

  // DICT p18 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Ngwubə afunə á chiə á ntə' mbĩwiŋə.",
    english: 'The leopard\'s skin is found in the Awing palace.',
    difficulty: 2,
    words: [
      AwingWord('Ngwubə', '_'),
      AwingWord('afunə', '_'),
      AwingWord('á', '_'),
      AwingWord('chiə', '_'),
      AwingWord('á', '_'),
      AwingWord('ntə\'', '_'),
      AwingWord('mbĩwiŋə', '_'),
    ],
  ),

  // DICT p19 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "ə' chíə a alá' Mbíwíŋ tə náənə.",
    english: 'There are many caves in Awing.',
    difficulty: 2,
    words: [
      AwingWord('ə\'', '_'),
      AwingWord('chíə', '_'),
      AwingWord('a', '_'),
      AwingWord('alá\'', '_'),
      AwingWord('Mbíwíŋ', '_'),
      AwingWord('tə', '_'),
      AwingWord('náənə', '_'),
    ],
  ),

  // DICT p20 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Ajíə mə́ ghóg nə́ á kɛ́ pɔŋ pɔ́.",
    english: 'It is not good to be shortsighted.',
    difficulty: 2,
    words: [
      AwingWord('Ajíə', '_'),
      AwingWord('mə', '_'),
      AwingWord('ghóg', '_'),
      AwingWord('nə', '_'),
      AwingWord('á', '_'),
      AwingWord('kɛ', '_'),
      AwingWord('pɔŋ', '_'),
      AwingWord('pɔ', '_'),
    ],
  ),

  // DICT p21 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Tso'ə akəkɔgə a kə ɲkwəŋə ɲgə yĩ lə ajĩəməgə.",
    english: 'Even a fool thinks that he is all knowing.',
    difficulty: 2,
    words: [
      AwingWord('Tso\'ə', '_'),
      AwingWord('akəkɔgə', '_'),
      AwingWord('a', '_'),
      AwingWord('kə', '_'),
      AwingWord('ɲkwəŋə', '_'),
      AwingWord('ɲgə', '_'),
      AwingWord('yĩ', '_'),
      AwingWord('lə', '_'),
      AwingWord('ajĩəməgə', '_'),
    ],
  ),

  // DICT p21 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Iɲwu tə ajĩənuə a chĩə yĩ lə ándó na neyeŋə.",
    english: 'A person who lacks knowledge is like a beast.',
    difficulty: 2,
    words: [
      AwingWord('Iɲwu', '_'),
      AwingWord('tə', '_'),
      AwingWord('ajĩənuə', '_'),
      AwingWord('a', '_'),
      AwingWord('chĩə', '_'),
      AwingWord('yĩ', '_'),
      AwingWord('lə', '_'),
      AwingWord('ándó', '_'),
      AwingWord('na', '_'),
      AwingWord('neyeŋə', '_'),
    ],
  ),

  // DICT p21 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Pə pə yunivəsti pə tũgə ajĩənu mbɔŋə ághɔb nkáb pə ɲə' əli' məfa'ə.",
    english: 'University students have the know how, but lack the capital to invest.',
    difficulty: 3,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('pə', '_'),
      AwingWord('yunivəsti', '_'),
      AwingWord('pə', '_'),
      AwingWord('tũgə', '_'),
      AwingWord('ajĩənu', '_'),
      AwingWord('mbɔŋə', '_'),
      AwingWord('ághɔb', '_'),
      AwingWord('nkáb', '_'),
      AwingWord('pə', '_'),
    ],
  ),

  // DICT p21 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "əŋwa'lə pə ajĩəla' lə kẽ pəlaŋ pə.",
    english: 'Literacy and wisdom can never be compared.',
    difficulty: 2,
    words: [
      AwingWord('əŋwa\'lə', '_'),
      AwingWord('pə', '_'),
      AwingWord('ajĩəla\'', '_'),
      AwingWord('lə', '_'),
      AwingWord('kẽ', '_'),
      AwingWord('pəlaŋ', '_'),
      AwingWord('pə', '_'),
    ],
  ),

  // DICT p21 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Ajú yə pá' nə á pəŋə á mə saŋ nə säntẽ.",
    english: 'Wickerwork is good for drying wed pepper.',
    difficulty: 3,
    words: [
      AwingWord('Ajú', '_'),
      AwingWord('yə', '_'),
      AwingWord('pá\'', '_'),
      AwingWord('nə', '_'),
      AwingWord('á', '_'),
      AwingWord('pəŋə', '_'),
      AwingWord('á', '_'),
      AwingWord('mə', '_'),
      AwingWord('saŋ', '_'),
      AwingWord('nə', '_'),
    ],
  ),

  // DICT p21 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Mə Pita lə chĩgə ajubə tə əyĩə.",
    english: 'Peters child is a replica of his father.',
    difficulty: 2,
    words: [
      AwingWord('Mə', '_'),
      AwingWord('Pita', '_'),
      AwingWord('lə', '_'),
      AwingWord('chĩgə', '_'),
      AwingWord('ajubə', '_'),
      AwingWord('tə', '_'),
      AwingWord('əyĩə', '_'),
    ],
  ),

  // DICT p21 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Ajúblə á chĩ lə á mbi pə nkə.",
    english: 'Foolish excitement is common with children.',
    difficulty: 2,
    words: [
      AwingWord('Ajúblə', '_'),
      AwingWord('á', '_'),
      AwingWord('chĩ', '_'),
      AwingWord('lə', '_'),
      AwingWord('á', '_'),
      AwingWord('mbi', '_'),
      AwingWord('pə', '_'),
      AwingWord('nkə', '_'),
    ],
  ),

  // DICT p23 — added Session 63 Part H batch 2
  // AwingSentence(
  // awing: "Nchindê ntsəmə alá' Mbíiwíŋ á túgə akeelə kwúneemə.",
  // english: 'Every compound in Awing has a pig sty.',
  // difficulty: 2,
  // words: [
  // AwingWord('Nchindê', '_'),
  // AwingWord('ntsəmə', '_'),
  // AwingWord('alá\'', '_'),
  // AwingWord('Mbíiwíŋ', '_'),
  // AwingWord('á', '_'),
  // AwingWord('túgə', '_'),
  // AwingWord('akeelə', '_'),
  // AwingWord('kwúneemə', '_'),
  // ],
  // ),  // REMOVED Session 66u similar-spelling: same English as the block at line 687 (Nchindê ntsəmə alá' Mbíiwíŋ á )

  // DICT p23 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "A fē akə ná manə?",
    english: 'What has he given me?',
    difficulty: 1,
    words: [
      AwingWord('A', '_'),
      AwingWord('fē', '_'),
      AwingWord('akə', '_'),
      AwingWord('ná', '_'),
      AwingWord('manə', '_'),
    ],
  ),

  // DICT p23 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Kəyé məna yitsə á chì əwə, mbub ngód nə akəblə ndəsē ńchìə əwə.",
    english: 'There are some little animals that make their hole in a clod.',
    difficulty: 3,
    words: [
      AwingWord('Kəyé', '_'),
      AwingWord('məna', '_'),
      AwingWord('yitsə', '_'),
      AwingWord('á', '_'),
      AwingWord('chì', '_'),
      AwingWord('əwə', '_'),
      AwingWord('mbub', '_'),
      AwingWord('ngód', '_'),
      AwingWord('nə', '_'),
      AwingWord('akəblə', '_'),
    ],
  ),

  // DICT p23 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Mbíiwíŋ chígé ńtúgə akəfé á mənká' pó.",
    english: 'Awing people really have coffee in their farms.',
    difficulty: 2,
    words: [
      AwingWord('Mbíiwíŋ', '_'),
      AwingWord('chígé', '_'),
      AwingWord('ńtúgə', '_'),
      AwingWord('akəfé', '_'),
      AwingWord('á', '_'),
      AwingWord('mənká\'', '_'),
      AwingWord('pó', '_'),
    ],
  ),

  // DICT p23 — added Session 63 Part H batch 2
  // AwingSentence(
  // awing: "Ná'ə akəghan ə pəŋ nə ngaalə.",
  // english: 'Okro soup is good for garri.',
  // difficulty: 2,
  // words: [
  // AwingWord('Ná\'ə', '_'),
  // AwingWord('akəghan', '_'),
  // AwingWord('ə', '_'),
  // AwingWord('pəŋ', '_'),
  // AwingWord('nə', '_'),
  // AwingWord('ngaalə', '_'),
  // ],
  // ),  // REMOVED Session 66u similar-spelling: same English as the block at line 719 (Ná'ə akəghan ə pəŋ nə ngaalə.)

  // DICT p23 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Mó ŋwunə a pá akəghə lə nganə a fē atsəmə á mbó Əsə.",
    english: 'Parents usually leave everything in the hands of God if their child turns out to be an imbecile.',
    difficulty: 3,
    words: [
      AwingWord('Mó', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('pá', '_'),
      AwingWord('akəghə', '_'),
      AwingWord('lə', '_'),
      AwingWord('nganə', '_'),
      AwingWord('a', '_'),
      AwingWord('fē', '_'),
      AwingWord('atsəmə', '_'),
    ],
  ),

  // DICT p23 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Mbɔ'ə ajumə á kənə akəghooləmiə ŋwu nganə shib ńkwuə.",
    english: 'When something hits someones nape of neck, the person will certainly die.',
    difficulty: 2,
    words: [
      AwingWord('Mbɔ\'ə', '_'),
      AwingWord('ajumə', '_'),
      AwingWord('á', '_'),
      AwingWord('kənə', '_'),
      AwingWord('akəghooləmiə', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('nganə', '_'),
      AwingWord('shib', '_'),
      AwingWord('ńkwuə', '_'),
    ],
  ),

  // DICT p24 — added Session 63 Part H batch 2
  // AwingSentence(
  // awing: "Mbɨwɨŋ zá mbá' əkəká' ló aghá akyé akəfɛ.",
  // english: 'Awing people usually weave baskets during the coffee harvesting period.',
  // difficulty: 2,
  // words: [
  // AwingWord('Mbɨwɨŋ', '_'),
  // AwingWord('zá', '_'),
  // AwingWord('mbá\'', '_'),
  // AwingWord('əkəká\'', '_'),
  // AwingWord('ló', '_'),
  // AwingWord('aghá', '_'),
  // AwingWord('akyé', '_'),
  // AwingWord('akəfɛ', '_'),
  // ],
  // ),  // REMOVED Session 66u similar-spelling: same English as the block at line 750 (Mbɨwɨŋ zá mbá' əkəká' ló aghá )

  // DICT p24 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "ə mbə ə əkəmə ajúmə kwúna məntú gho, o wúə.",
    english: 'Walk with care because a sliver can pass between your legs and you fall.',
    difficulty: 2,
    words: [
      AwingWord('ə', '_'),
      AwingWord('mbə', '_'),
      AwingWord('ə', '_'),
      AwingWord('əkəmə', '_'),
      AwingWord('ajúmə', '_'),
      AwingWord('kwúna', '_'),
      AwingWord('məntú', '_'),
      AwingWord('gho', '_'),
      AwingWord('o', '_'),
      AwingWord('wúə', '_'),
    ],
  ),

  // DICT p24 — added Session 63 Part H batch 2
  // AwingSentence(
  // awing: "Akəmátɔgɨə ló ŋwu pá' a kɛ nɛ ɨlɨ' tɔ ndzó'ə pɔ.",
  // english: 'A deaf is a person who does not hear.',
  // difficulty: 3,
  // words: [
  // AwingWord('Akəmátɔgɨə', '_'),
  // AwingWord('ló', '_'),
  // AwingWord('ŋwu', '_'),
  // AwingWord('pá\'', '_'),
  // AwingWord('a', '_'),
  // AwingWord('kɛ', '_'),
  // AwingWord('nɛ', '_'),
  // AwingWord('ɨlɨ\'', '_'),
  // AwingWord('tɔ', '_'),
  // AwingWord('ndzó\'ə', '_'),
  // ],
  // ),  // REMOVED Session 66u similar-spelling: same English as the block at line 839 (Akəmátɔgɨə ló ŋwu pá' a kɛ nɛ )

  // DICT p25 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Aghā alu lə akəpóglə á nəənə.",
    english: 'During the dry season there is a lot of dust.',
    difficulty: 2,
    words: [
      AwingWord('Aghā', '_'),
      AwingWord('alu', '_'),
      AwingWord('lə', '_'),
      AwingWord('akəpóglə', '_'),
      AwingWord('á', '_'),
      AwingWord('nəənə', '_'),
    ],
  ),

  // DICT p26 — added Session 63 Part H batch 2
  // AwingSentence(
  // awing: "A fɛ ɔkwa'lɔ pɛn pɛ nɔ maŋɔ.",
  // english: 'He gave me two questions.',
  // difficulty: 2,
  // words: [
  // AwingWord('A', '_'),
  // AwingWord('fɛ', '_'),
  // AwingWord('ɔkwa\'lɔ', '_'),
  // AwingWord('pɛn', '_'),
  // AwingWord('pɛ', '_'),
  // AwingWord('nɔ', '_'),
  // AwingWord('maŋɔ', '_'),
  // ],
  // ),  // REMOVED Session 66u similar-spelling: same English as the block at line 875 (A fɛ ɔkwa'lɔ pɛn pɛ nɔ maŋɔ.)

  // DICT p27 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "ɛlɔ́lɔ' pɔ́' a kɛ̀ nɔ́ akwɛlɔ̀ mbɛ́ŋ tʋ́gɔ̀ a kɔ́ ɔ́wɔ̀ chɨ́ pɔ́.",
    english: 'There is no Bororo man without a flock of sheep.',
    difficulty: 3,
    words: [
      AwingWord('ɛlɔ', '_'),
      AwingWord('lɔ\'', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('\'', '_'),
      AwingWord('a', '_'),
      AwingWord('kɛ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('akwɛlɔ', '_'),
      AwingWord('mbɛ', '_'),
      AwingWord('ŋ', '_'),
    ],
  ),

  // DICT p27 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Mbɨ́wɨŋ yɨ́ nɨ́ nɔ́ tʋ́g ɔkwɛlɔ̀ mɔneɛmɔ̀.",
    english: 'A good number of Awing people have herds of cattle.',
    difficulty: 2,
    words: [
      AwingWord('Mbɨ', '_'),
      AwingWord('wɨŋ', '_'),
      AwingWord('yɨ', '_'),
      AwingWord('nɨ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('tʋ', '_'),
      AwingWord('g', '_'),
      AwingWord('ɔkwɛlɔ', '_'),
      AwingWord('mɔneɛmɔ', '_'),
    ],
  ),

  // DICT p27 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Akwɔŋɔ̀ ɔshúɔ̀ á chɨ́ mbɔ'ɔ̀ á jwɨ́tɔ̀ ɲwunɔ.",
    english: 'A fish bone can kill somebody.',
    difficulty: 2,
    words: [
      AwingWord('Akwɔŋɔ', '_'),
      AwingWord('ɔshúɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('chɨ', '_'),
      AwingWord('mbɔ\'ɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('jwɨ', '_'),
      AwingWord('tɔ', '_'),
      AwingWord('ɲwunɔ', '_'),
    ],
  ),

  // DICT p27 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Pɨ pɔtsɔ́ pɔ́ lɔgɔ̀ akwubɔ̀ ɔshú́ ńgɛlɔ̀ afú́ ɔ́wɔ̀.",
    english: 'Some people use fish-scale to prepare medicine.',
    difficulty: 2,
    words: [
      AwingWord('Pɨ', '_'),
      AwingWord('pɔtsɔ', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('lɔgɔ', '_'),
      AwingWord('akwubɔ', '_'),
      AwingWord('ɔshú', '_'),
      AwingWord('ńgɛlɔ', '_'),
      AwingWord('afú', '_'),
      AwingWord('ɔ', '_'),
      AwingWord('wɔ', '_'),
    ],
  ),

  // DICT p27 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Akwubɔ̀ mɔ́ndzɔ̀ á tyantɔ̀ á mɔ́ lɔ́ nɔ́.",
    english: 'It is difficult for groundnut shells to get rotten.',
    difficulty: 2,
    words: [
      AwingWord('Akwubɔ', '_'),
      AwingWord('mɔ', '_'),
      AwingWord('ndzɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('tyantɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('mɔ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('nɔ', '_'),
    ],
  ),

  // DICT p30 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Alib lə chigə aghɔ yə tyantə nə.",
    english: 'A growth is a serious disease.',
    difficulty: 2,
    words: [
      AwingWord('Alib', '_'),
      AwingWord('lə', '_'),
      AwingWord('chigə', '_'),
      AwingWord('aghɔ', '_'),
      AwingWord('yə', '_'),
      AwingWord('tyantə', '_'),
      AwingWord('nə', '_'),
    ],
  ),

  // DICT p34 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "əməkálə [amúʔəməkálə] n 7/8.",
    english: 'A kind of banana that is kept to ripe and is then eaten as food.',
    difficulty: 1,
    words: [
      AwingWord('əməkálə', '_'),
      AwingWord('amúʔəməkálə', '_'),
      AwingWord('n', '_'),
      AwingWord('7', '_'),
      AwingWord('8', '_'),
    ],
  ),

  // DICT p34 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Anua chi əwə mbə ndyəŋə.",
    english: 'There is something but hidden.',
    difficulty: 1,
    words: [
      AwingWord('Anua', '_'),
      AwingWord('chi', '_'),
      AwingWord('əwə', '_'),
      AwingWord('mbə', '_'),
      AwingWord('ndyəŋə', '_'),
    ],
  ),

  // DICT p34 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "O tʊgə anu o fʊgə zəələ.",
    english: 'If you have an idea, bring it out.',
    difficulty: 2,
    words: [
      AwingWord('O', '_'),
      AwingWord('tʊgə', '_'),
      AwingWord('anu', '_'),
      AwingWord('o', '_'),
      AwingWord('fʊgə', '_'),
      AwingWord('zəələ', '_'),
    ],
  ),

  // DICT p34 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "Anua əshunə á pɔŋə.",
    english: 'Partnership is good.',
    difficulty: 1,
    words: [
      AwingWord('Anua', '_'),
      AwingWord('əshunə', '_'),
      AwingWord('á', '_'),
      AwingWord('pɔŋə', '_'),
    ],
  ),

  // DICT p40 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "ə atāgātsō'ə [atāgātsō'ə] n 7/2.",
    english: 'A stiff and unrelenting person.',
    difficulty: 1,
    words: [
      AwingWord('ə', '_'),
      AwingWord('atāgātsō\'ə', '_'),
      AwingWord('atāgātsō\'ə', '_'),
      AwingWord('n', '_'),
      AwingWord('7', '_'),
      AwingWord('2', '_'),
    ],
  ),

  // DICT p40 — added Session 63 Part H batch 2
  AwingSentence(
    awing: "əəmə [atāsəmə] n 7/2.",
    english: 'A person who is wild and animal in nature.',
    difficulty: 1,
    words: [
      AwingWord('əəmə', '_'),
      AwingWord('atāsəmə', '_'),
      AwingWord('n', '_'),
      AwingWord('7', '_'),
      AwingWord('2', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Paul Mbangwana, Dr.",
    english: 'Samuel Atechi, Mbatu Alex and Polote Gideon who worked with me as a team in the early stages of the project.',
    difficulty: 1,
    words: [
      AwingWord('Paul', '_'),
      AwingWord('Mbangwana', '_'),
      AwingWord('Dr', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mô wê a zoomê tâ əyîə.",
    english: 'That child has insulted his father.',
    difficulty: 2,
    words: [
      AwingWord('Mô', '_'),
      AwingWord('wê', '_'),
      AwingWord('a', '_'),
      AwingWord('zoomê', '_'),
      AwingWord('tâ', '_'),
      AwingWord('əyîə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mɛngyɛnjia a jí ɛnuə, a lɔgɔ́ lɔ́ fɔ́sɔ əghà ɛtsɔmɔ.",
    english: 'Mengyenji is intelligent, she is always first.',
    difficulty: 2,
    words: [
      AwingWord('Mɛngyɛnjia', '_'),
      AwingWord('a', '_'),
      AwingWord('jí', '_'),
      AwingWord('ɛnuə', '_'),
      AwingWord('a', '_'),
      AwingWord('lɔgɔ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('fɔ', '_'),
      AwingWord('sɔ', '_'),
      AwingWord('əghà', '_'),
      AwingWord('ɛtsɔmɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Tú'ɔ á sɛn lɔ́ pì pɔ́ tɔpɔŋ pɔ́ chìa á apɛ́ŋɔ.",
    english: 'When it is night, evil men thrive.',
    difficulty: 3,
    words: [
      AwingWord('Tú\'ɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('sɛn', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('pì', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('tɔpɔŋ', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('chìa', '_'),
      AwingWord('á', '_'),
      AwingWord('apɛ', '_'),
      AwingWord('ŋɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Á pɔ́ŋ ńgɔ́ pɔ́ nkɔ́ pɔ́ zaŋkɔ́ ńgɛnɔ́ á aŋwa'ɔ́.",
    english: 'It is advisable that children should start attending school early.',
    difficulty: 2,
    words: [
      AwingWord('Á', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('ŋ', '_'),
      AwingWord('ńgɔ', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('nkɔ', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('zaŋkɔ', '_'),
      AwingWord('ńgɛnɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('aŋwa\'ɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pɔ múto pá' pɔ́ jú nɔ́ á alá'ɔ akálɔ́ lɔ́ chigɔ pípɔ́ ɔshí'nɔ.",
    english: 'Cars bought from the Western world are the best quality.',
    difficulty: 3,
    words: [
      AwingWord('Pɔ', '_'),
      AwingWord('múto', '_'),
      AwingWord('pá\'', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('jú', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('alá\'ɔ', '_'),
      AwingWord('akálɔ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('chigɔ', '_'),
      AwingWord('pípɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Á pɔŋɔ́ á mɔ́ chì nɔ́ nɔ́ ɔpɔ'ɔ.",
    english: 'It is good to live an innocent life.',
    difficulty: 2,
    words: [
      AwingWord('Á', '_'),
      AwingWord('pɔŋɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('mɔ', '_'),
      AwingWord('chì', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('ɔpɔ\'ɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Apɛ́lɔ atɔsɔmɔ á túgɔ achábtɔ á atɔs' yí pɔ́ pɔ mbí ɔjìa.",
    english: 'Every mad person has layers of dirt both on the body and dresses.',
    difficulty: 3,
    words: [
      AwingWord('Apɛ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('atɔsɔmɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('túgɔ', '_'),
      AwingWord('achábtɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('atɔs\'', '_'),
      AwingWord('yí', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('mbí', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Achánɔ á kɛ́ pɔŋ pɔ́.",
    english: 'Turning away from somebody in disgust is not good.',
    difficulty: 1,
    words: [
      AwingWord('Achánɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('kɛ', '_'),
      AwingWord('pɔŋ', '_'),
      AwingWord('pɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Acha'tɔ́sɛ á pe' ńchìa mɔ́ chì nɔ́ lɔ́ ándɔ́ mɔjìa á mbɔ́ ŋwu ɔ̀sɛ.",
    english: 'Prayers is suppose to be as food to a man of God.',
    difficulty: 3,
    words: [
      AwingWord('Acha\'tɔ', '_'),
      AwingWord('sɛ', '_'),
      AwingWord('á', '_'),
      AwingWord('pe\'', '_'),
      AwingWord('ńchìa', '_'),
      AwingWord('mɔ', '_'),
      AwingWord('chì', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('ándɔ', '_'),
      AwingWord('mɔjìa', '_'),
      AwingWord('á', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Acha'tɔ́sɛnjì lɔ́ atyánta acha'tɔ́sɛ.",
    english: 'Fasting is a powerful form of prayers.',
    difficulty: 1,
    words: [
      AwingWord('Acha\'tɔ', '_'),
      AwingWord('sɛnjì', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('atyánta', '_'),
      AwingWord('acha\'tɔ', '_'),
      AwingWord('sɛ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Káyé ɲwunə a tá ńtəmə adɔcheŋə.",
    english: 'Children are playing adocheng.',
    difficulty: 2,
    words: [
      AwingWord('Káyé', '_'),
      AwingWord('ɲwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('tá', '_'),
      AwingWord('ńtəmə', '_'),
      AwingWord('adɔcheŋə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Afa'ə á kè ndɔŋ pɔŋ pó, ajú yə ɛshí'nə pá mbɔŋə yá.",
    english: 'A lazy man does not like hardwork but likes to enjoy the proceeds thereof.',
    difficulty: 3,
    words: [
      AwingWord('Afa\'ə', '_'),
      AwingWord('á', '_'),
      AwingWord('kè', '_'),
      AwingWord('ndɔŋ', '_'),
      AwingWord('pɔŋ', '_'),
      AwingWord('pó', '_'),
      AwingWord('ajú', '_'),
      AwingWord('yə', '_'),
      AwingWord('ɛshí\'nə', '_'),
      AwingWord('pá', '_'),
      AwingWord('mbɔŋə', '_'),
      AwingWord('yá', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pá tá mbĩ ẽpũ lá afũa á féd néŋ mbwódnə afoona.",
    english: 'During the planting season, a traditional juju goes out to bless the farm.',
    difficulty: 3,
    words: [
      AwingWord('Pá', '_'),
      AwingWord('tá', '_'),
      AwingWord('mbĩ', '_'),
      AwingWord('ẽpũ', '_'),
      AwingWord('lá', '_'),
      AwingWord('afũa', '_'),
      AwingWord('á', '_'),
      AwingWord('féd', '_'),
      AwingWord('néŋ', '_'),
      AwingWord('mbwódnə', '_'),
      AwingWord('afoona', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Afa'a alé mbĩ ali' pətsə lá afũa atĩa.",
    english: 'In some places, a day\'s job is a thousand francs CFA Sg.',
    difficulty: 2,
    words: [
      AwingWord('Afa\'a', '_'),
      AwingWord('alé', '_'),
      AwingWord('mbĩ', '_'),
      AwingWord('ali\'', '_'),
      AwingWord('pətsə', '_'),
      AwingWord('lá', '_'),
      AwingWord('afũa', '_'),
      AwingWord('atĩa', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Afũa əghəmə lō mbō əfo.",
    english: 'A message has come from the fon.',
    difficulty: 1,
    words: [
      AwingWord('Afũa', '_'),
      AwingWord('əghəmə', '_'),
      AwingWord('lō', '_'),
      AwingWord('mbō', '_'),
      AwingWord('əfo', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  // AwingSentence(
  // awing: "Ndɔŋ mó nkə a laŋə aŋwa'lə lá tso'ə aghabnə.",
  // english: 'A lazy child succeeds only averagely in school.',
  // difficulty: 2,
  // words: [
  // AwingWord('Ndɔŋ', '_'),
  // AwingWord('mó', '_'),
  // AwingWord('nkə', '_'),
  // AwingWord('a', '_'),
  // AwingWord('laŋə', '_'),
  // AwingWord('aŋwa\'lə', '_'),
  // AwingWord('lá', '_'),
  // AwingWord('tso\'ə', '_'),
  // AwingWord('aghabnə', '_'),
  // ],
  // ),  // REMOVED Session 66u similar-spelling: same English as the block at line 601 (Ndɔŋ mó nkə a laŋə aŋwa'lə lá )

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  // AwingSentence(
  // awing: "Máchisə mée lá pá mya'ə aghaglə.",
  // english: 'When match gets finished the empty box is thrown away.',
  // difficulty: 2,
  // words: [
  // AwingWord('Máchisə', '_'),
  // AwingWord('mée', '_'),
  // AwingWord('lá', '_'),
  // AwingWord('pá', '_'),
  // AwingWord('mya\'ə', '_'),
  // AwingWord('aghaglə', '_'),
  // ],
  // ),  // REMOVED Session 66u similar-spelling: same English as the block at line 619 (Máchisə mée lá pá mya'ə aghagl)

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  // AwingSentence(
  // awing: "Mbɔ' ŋwunə ghenə asəg ntso a kə aghaglətúə ŋwu pón pó.",
  // english: 'One can never lack a human skull on a battle field.',
  // difficulty: 3,
  // words: [
  // AwingWord('Mbɔ\'', '_'),
  // AwingWord('ŋwunə', '_'),
  // AwingWord('ghenə', '_'),
  // AwingWord('asəg', '_'),
  // AwingWord('ntso', '_'),
  // AwingWord('a', '_'),
  // AwingWord('kə', '_'),
  // AwingWord('aghaglətúə', '_'),
  // AwingWord('ŋwu', '_'),
  // AwingWord('pón', '_'),
  // AwingWord('pó', '_'),
  // ],
  // ),  // REMOVED Session 66u similar-spelling: same English as the block at line 634 (Mbɔ' ŋwunə ghenə asəg ntso a k)

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Aghóobə á pɔŋ pi pətsə́ tə́shúnə́.",
    english: 'Some people delight so much in cunning and deceit.',
    difficulty: 2,
    words: [
      AwingWord('Aghóobə', '_'),
      AwingWord('á', '_'),
      AwingWord('pɔŋ', '_'),
      AwingWord('pi', '_'),
      AwingWord('pətsə', '_'),
      AwingWord('tə', '_'),
      AwingWord('shúnə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Aghoolə́ atúə məngyɛ́ atú yitsə́ lə́ mé nkéebə́.",
    english: 'A dowry in some countries is a lot of money.',
    difficulty: 2,
    words: [
      AwingWord('Aghoolə', '_'),
      AwingWord('atúə', '_'),
      AwingWord('məngyɛ', '_'),
      AwingWord('atú', '_'),
      AwingWord('yitsə', '_'),
      AwingWord('lə', '_'),
      AwingWord('mé', '_'),
      AwingWord('nkéebə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Aghoonə́ á pə́'tə́ ŋwu tə́shúnə́.",
    english: 'Illness weakens one a lot.',
    difficulty: 1,
    words: [
      AwingWord('Aghoonə', '_'),
      AwingWord('á', '_'),
      AwingWord('pə', '_'),
      AwingWord('\'tə', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('tə', '_'),
      AwingWord('shúnə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Aghoonə́ mə́ghabə lə́ aghoonə́ əsə́ənə.",
    english: 'Diseases contracted through sex are shameful.',
    difficulty: 1,
    words: [
      AwingWord('Aghoonə', '_'),
      AwingWord('mə', '_'),
      AwingWord('ghabə', '_'),
      AwingWord('lə', '_'),
      AwingWord('aghoonə', '_'),
      AwingWord('əsə', '_'),
      AwingWord('ənə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Aghógtə lə́ ajúmə apéna.",
    english: 'A rattle is a musical instrument.',
    difficulty: 1,
    words: [
      AwingWord('Aghógtə', '_'),
      AwingWord('lə', '_'),
      AwingWord('ajúmə', '_'),
      AwingWord('apéna', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Aghɔ́kə á ghelə́ ndɛ́ ŋwu sednə́.",
    english: 'Vomit makes one to lose appetite.',
    difficulty: 2,
    words: [
      AwingWord('Aghɔ', '_'),
      AwingWord('kə', '_'),
      AwingWord('á', '_'),
      AwingWord('ghelə', '_'),
      AwingWord('ndɛ', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('sednə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pi pə́ awatə́ pɔ́ zə́ənə ajã'kə əghã ətsəmə́.",
    english: 'People in the hospital see vomit very often.',
    difficulty: 2,
    words: [
      AwingWord('Pi', '_'),
      AwingWord('pə', '_'),
      AwingWord('awatə', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('zə', '_'),
      AwingWord('ənə', '_'),
      AwingWord('ajã\'kə', '_'),
      AwingWord('əghã', '_'),
      AwingWord('ətsəmə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mɔ́ nkə́ ajíə a ghelə́ tə́ əyíə a təələ́.",
    english: 'An intelligent child makes the father proud.',
    difficulty: 2,
    words: [
      AwingWord('Mɔ', '_'),
      AwingWord('nkə', '_'),
      AwingWord('ajíə', '_'),
      AwingWord('a', '_'),
      AwingWord('ghelə', '_'),
      AwingWord('tə', '_'),
      AwingWord('əyíə', '_'),
      AwingWord('a', '_'),
      AwingWord('təələ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ajĩəmbə́glə́ lə́ chigə anuə təpɔŋə.",
    english: 'Corruption is a bad practice.',
    difficulty: 1,
    words: [
      AwingWord('Ajĩəmbə', '_'),
      AwingWord('glə', '_'),
      AwingWord('lə', '_'),
      AwingWord('chigə', '_'),
      AwingWord('anuə', '_'),
      AwingWord('təpɔŋə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Á pɔŋɔ́ á mɔ́ túg nɔ́ ajúmɔ́tsɔ́, mbo' ɲwunɔ tɔ́ ɲɔ́ɲɔ́ á mɔ́m mɔ́numɔ.",
    english: 'It is good to have a handkerchief when one is walking in the sun.',
    difficulty: 3,
    words: [
      AwingWord('Á', '_'),
      AwingWord('pɔŋɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('mɔ', '_'),
      AwingWord('túg', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('ajúmɔ', '_'),
      AwingWord('tsɔ', '_'),
      AwingWord('mbo\'', '_'),
      AwingWord('ɲwunɔ', '_'),
      AwingWord('tɔ', '_'),
      AwingWord('ɲɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ali'ɔ́ nɔ́ mɔ́lo'ɔ́ atɔ́mɔ́ chi lɔ́ nɔ́túgɔ́ ajwa'áli'ɔ́.",
    english: 'Every drinking spot has noise.',
    difficulty: 2,
    words: [
      AwingWord('Ali\'ɔ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('mɔ', '_'),
      AwingWord('lo\'ɔ', '_'),
      AwingWord('atɔ', '_'),
      AwingWord('mɔ', '_'),
      AwingWord('chi', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('túgɔ', '_'),
      AwingWord('ajwa\'áli\'ɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ajwelɔ́ á fɛ́lɔ́ á mɔ́m nɔ́yɛnɔ́ á mɛ́ mɔ́sɔ́nɔ.",
    english: 'Vapour rises from the grass early in the morning.',
    difficulty: 2,
    words: [
      AwingWord('Ajwelɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('fɛ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('mɔ', '_'),
      AwingWord('m', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('yɛnɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('mɛ', '_'),
      AwingWord('mɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ajwiɔ ɲwu lɔ́ ali' pa' á yɔ́ nɔ́ ghenɔ́ á mbɔ́ ɔ̀sɛ́.",
    english: 'One\'s spirit is the part that will go to God.',
    difficulty: 3,
    words: [
      AwingWord('Ajwiɔ', '_'),
      AwingWord('ɲwu', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('ali\'', '_'),
      AwingWord('pa\'', '_'),
      AwingWord('á', '_'),
      AwingWord('yɔ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('ghenɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('mbɔ', '_'),
      AwingWord('ɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "ɔ a kwú lɔ́ ajwiɔ ɔ̀sɛ́ á fɛ́lɔ́ yɔ́ mbi yɔ́.",
    english: 'When a man dies the spirit of God departs from him.',
    difficulty: 3,
    words: [
      AwingWord('ɔ', '_'),
      AwingWord('a', '_'),
      AwingWord('kwú', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('ajwiɔ', '_'),
      AwingWord('ɔ', '_'),
      AwingWord('sɛ', '_'),
      AwingWord('á', '_'),
      AwingWord('fɛ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('yɔ', '_'),
      AwingWord('mbi', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ndɛ́ tɔ́ ajwikɔ mbɔ' ɔ́ fɔ́mkɔ́ ɲwunɔ.",
    english: 'A house without a window can suffocate one.',
    difficulty: 2,
    words: [
      AwingWord('Ndɛ', '_'),
      AwingWord('tɔ', '_'),
      AwingWord('ajwikɔ', '_'),
      AwingWord('mbɔ\'', '_'),
      AwingWord('ɔ', '_'),
      AwingWord('fɔ', '_'),
      AwingWord('mkɔ', '_'),
      AwingWord('ɲwunɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Aka'nɔ á pɔŋ lɔ́ pɔ́' pɔ́ ghed nɔ́ nɔ́ mbwɔ́dnɔ.",
    english: 'Competition is good when it is healthy.',
    difficulty: 2,
    words: [
      AwingWord('Aka\'nɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('pɔŋ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('\'', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('ghed', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('mbwɔ', '_'),
      AwingWord('dnɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A kɛ́ pɔ́ŋ ɲɔ́gɔ́ ɲwunɔ a ghenɔ́ chɔ́sɔ tɔ́ akɔ́nɔ́sɛ́ pɔ́.",
    english: 'It is not good to go to church without offering.',
    difficulty: 3,
    words: [
      AwingWord('A', '_'),
      AwingWord('kɛ', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('ŋ', '_'),
      AwingWord('ɲɔ', '_'),
      AwingWord('gɔ', '_'),
      AwingWord('ɲwunɔ', '_'),
      AwingWord('a', '_'),
      AwingWord('ghenɔ', '_'),
      AwingWord('chɔ', '_'),
      AwingWord('sɔ', '_'),
      AwingWord('tɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "ɔ a kɔ́lɔ́ sɔ́kɔ tɔ́ akɔ́nɔ́tɔ́ lɔ́ á kɛ́ pɔ́ŋ pɔ́.",
    english: 'It\'s wrong to ride a motto bike without a helmet.',
    difficulty: 3,
    words: [
      AwingWord('ɔ', '_'),
      AwingWord('a', '_'),
      AwingWord('kɔ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('sɔ', '_'),
      AwingWord('kɔ', '_'),
      AwingWord('tɔ', '_'),
      AwingWord('akɔ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('tɔ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('á', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Á kə pəŋə mə tũg nə mə pá' a pə nə akətũ pō.",
    english: 'It is not good to have a child who is a deaf.',
    difficulty: 3,
    words: [
      AwingWord('Á', '_'),
      AwingWord('kə', '_'),
      AwingWord('pəŋə', '_'),
      AwingWord('mə', '_'),
      AwingWord('tũg', '_'),
      AwingWord('nə', '_'),
      AwingWord('mə', '_'),
      AwingWord('pá\'', '_'),
      AwingWord('a', '_'),
      AwingWord('pə', '_'),
      AwingWord('nə', '_'),
      AwingWord('akətũ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Akibnə nəzeŋə ŋwunə.",
    english: 'A person with a high forehead.',
    difficulty: 1,
    words: [
      AwingWord('Akibnə', '_'),
      AwingWord('nəzeŋə', '_'),
      AwingWord('ŋwunə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Akō'nə ləəmə á pəŋ ntseelə təkə'ə.",
    english: 'A colt is preferable to a full grown horse.',
    difficulty: 2,
    words: [
      AwingWord('Akō\'nə', '_'),
      AwingWord('ləəmə', '_'),
      AwingWord('á', '_'),
      AwingWord('pəŋ', '_'),
      AwingWord('ntseelə', '_'),
      AwingWord('təkə\'ə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ntso wũə alá' lə akō'nə mbyāŋnə atsəmə fēlə.",
    english: 'When war breaks out in the clan every young man has to stand up for it.',
    difficulty: 2,
    words: [
      AwingWord('Ntso', '_'),
      AwingWord('wũə', '_'),
      AwingWord('alá\'', '_'),
      AwingWord('lə', '_'),
      AwingWord('akō\'nə', '_'),
      AwingWord('mbyāŋnə', '_'),
      AwingWord('atsəmə', '_'),
      AwingWord('fēlə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Akō'nə məngyē lə mbō pá' mbyāŋnə kəŋ nə mə zō' nə.",
    english: 'Men like to marry a young woman instead.',
    difficulty: 3,
    words: [
      AwingWord('Akō\'nə', '_'),
      AwingWord('məngyē', '_'),
      AwingWord('lə', '_'),
      AwingWord('mbō', '_'),
      AwingWord('pá\'', '_'),
      AwingWord('mbyāŋnə', '_'),
      AwingWord('kəŋ', '_'),
      AwingWord('nə', '_'),
      AwingWord('mə', '_'),
      AwingWord('zō\'', '_'),
      AwingWord('nə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pə chīə á məm chōsə lə, lə pō'ə kəyē ŋwu mbō' əkō'nə nkeelə.",
    english: 'During church service it is the little children who play the medium sized drums.',
    difficulty: 3,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('chīə', '_'),
      AwingWord('á', '_'),
      AwingWord('məm', '_'),
      AwingWord('chōsə', '_'),
      AwingWord('lə', '_'),
      AwingWord('lə', '_'),
      AwingWord('pō\'ə', '_'),
      AwingWord('kəyē', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('mbō\'', '_'),
      AwingWord('əkō\'nə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Akoobə á kē alá' Mbiwiŋ ní pō.",
    english: 'Forest is not plentiful in Awing.',
    difficulty: 2,
    words: [
      AwingWord('Akoobə', '_'),
      AwingWord('á', '_'),
      AwingWord('kē', '_'),
      AwingWord('alá\'', '_'),
      AwingWord('Mbiwiŋ', '_'),
      AwingWord('ní', '_'),
      AwingWord('pō', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Akoobə əfəgə mə mbī mbēlə alá' Mbiwiŋ.",
    english: 'There is not more an indian bamboo bush in Awing.',
    difficulty: 2,
    words: [
      AwingWord('Akoobə', '_'),
      AwingWord('əfəgə', '_'),
      AwingWord('mə', '_'),
      AwingWord('mbī', '_'),
      AwingWord('mbēlə', '_'),
      AwingWord('alá\'', '_'),
      AwingWord('Mbiwiŋ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  // AwingSentence(
  // awing: "Akwa'lɔ sɔtɔnɔ ɔ nɔ tɔshɔnɔ.",
  // english: 'Satan\'s temptation is so much.',
  // difficulty: 1,
  // words: [
  // AwingWord('Akwa\'lɔ', '_'),
  // AwingWord('sɔtɔnɔ', '_'),
  // AwingWord('ɔ', '_'),
  // AwingWord('nɔ', '_'),
  // AwingWord('tɔshɔnɔ', '_'),
  // ],
  // ),  // REMOVED Session 66u similar-spelling: same English as the block at line 891 (Akwa'lɔ sɔtɔnɔ ɔ nɔ tɔshɔnɔ.)

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "ɔ ɔ fɔ'ɔ anu yɔ fɔ mɔm mbɔ lɔ ɔ tɔgɔ akwa'lɔ ɔ nɔɔnɔ.",
    english: 'People who do new things face a lot of criticism.',
    difficulty: 3,
    words: [
      AwingWord('ɔ', '_'),
      AwingWord('ɔ', '_'),
      AwingWord('fɔ\'ɔ', '_'),
      AwingWord('anu', '_'),
      AwingWord('yɔ', '_'),
      AwingWord('fɔ', '_'),
      AwingWord('mɔm', '_'),
      AwingWord('mbɔ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('ɔ', '_'),
      AwingWord('tɔgɔ', '_'),
      AwingWord('akwa\'lɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "ɔkwu'lɔ atɪɔ á tɔɔmɔ alɪ' lɔ á nɔɔlɔ lɔ nɔgɔ atɪɔ á kɔ chɪ ɔwɔ.",
    english: 'The base of a tree trunk is a sign that a tree had grown in the place.',
    difficulty: 3,
    words: [
      AwingWord('ɔkwu\'lɔ', '_'),
      AwingWord('atɪɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('tɔɔmɔ', '_'),
      AwingWord('alɪ\'', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('nɔɔlɔ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('nɔgɔ', '_'),
      AwingWord('atɪɔ', '_'),
      AwingWord('á', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "ɔkwu'lɔ atɪɔ á chɪ lɔ mbɔŋ mbɔ' pɔ sɔ nɔ nkwɔŋɔ.",
    english: 'The stump of a tree is good for splitting as wood.',
    difficulty: 3,
    words: [
      AwingWord('ɔkwu\'lɔ', '_'),
      AwingWord('atɪɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('chɪ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('mbɔŋ', '_'),
      AwingWord('mbɔ\'', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('sɔ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('nkwɔŋɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "ɔkya'ɔshɪɔ lɔ ajú pɔ' á ŋwa' nɔ.",
    english: 'A mirror is something that shines.',
    difficulty: 2,
    words: [
      AwingWord('ɔkya\'ɔshɪɔ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('ajú', '_'),
      AwingWord('pɔ\'', '_'),
      AwingWord('á', '_'),
      AwingWord('ŋwa\'', '_'),
      AwingWord('nɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pɔ nkɔ pɔ kɛ nɔ ɔkwub sogɔ, ɔkyɔglɔ á nɔɔlɔ á mbɪ pɔ.",
    english: 'Children who do not bath have dirty marks exhibiting in their bodies.',
    difficulty: 3,
    words: [
      AwingWord('Pɔ', '_'),
      AwingWord('nkɔ', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('kɛ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('ɔkwub', '_'),
      AwingWord('sogɔ', '_'),
      AwingWord('ɔkyɔglɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('nɔɔlɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('mbɪ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pɔ́ pɔ́ Mbɩ́wɩŋ pɩ́pɔ́ nɩ́ nɔ́ pɔ́ kɛ́ alá'ə akɔb kɔŋ pɔ́.",
    english: 'Most Awing children do not like to live in the rural area.',
    difficulty: 3,
    words: [
      AwingWord('Pɔ', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('Mbɩ', '_'),
      AwingWord('wɩŋ', '_'),
      AwingWord('pɩ', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('nɩ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('kɛ', '_'),
      AwingWord('alá\'ə', '_'),
      AwingWord('akɔb', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbɩ́wɩŋ nə mbegə nchɩə lə Alá'əmətiə.",
    english: 'Awing people were first staying in Ala- amiti quarter.',
    difficulty: 2,
    words: [
      AwingWord('Mbɩ', '_'),
      AwingWord('wɩŋ', '_'),
      AwingWord('nə', '_'),
      AwingWord('mbegə', '_'),
      AwingWord('nchɩə', '_'),
      AwingWord('lə', '_'),
      AwingWord('Alá\'əmətiə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Alaŋənkɩə á chɩə ali' pətsɩ mbə lə alaŋə múto nkɩə.",
    english: 'Channels are used in some places for sea transport Pl.',
    difficulty: 2,
    words: [
      AwingWord('Alaŋənkɩə', '_'),
      AwingWord('á', '_'),
      AwingWord('chɩə', '_'),
      AwingWord('ali\'', '_'),
      AwingWord('pətsɩ', '_'),
      AwingWord('mbə', '_'),
      AwingWord('lə', '_'),
      AwingWord('alaŋə', '_'),
      AwingWord('múto', '_'),
      AwingWord('nkɩə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "ɛlɔ' Mbɪɪwɪŋ lə afɛdngɔn pɔ nchwɪə.",
    english: 'Non working days in Awing are the third and fourth days of the week.',
    difficulty: 2,
    words: [
      AwingWord('ɛlɔ\'', '_'),
      AwingWord('Mbɪɪwɪŋ', '_'),
      AwingWord('lə', '_'),
      AwingWord('afɛdngɔn', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('nchwɪə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "ɔ' a naanə nə ə nkaɲ mɔg nɔəgnə mbi əji, mbɔ' alɔəməmɔgə ə toonə yə.",
    english: 'If one sits by the fire absent- mindedly, he can be burned by the flames.',
    difficulty: 3,
    words: [
      AwingWord('ɔ\'', '_'),
      AwingWord('a', '_'),
      AwingWord('naanə', '_'),
      AwingWord('nə', '_'),
      AwingWord('ə', '_'),
      AwingWord('nkaɲ', '_'),
      AwingWord('mɔg', '_'),
      AwingWord('nɔəgnə', '_'),
      AwingWord('mbi', '_'),
      AwingWord('əji', '_'),
      AwingWord('mbɔ\'', '_'),
      AwingWord('alɔəməmɔgə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Məngyɛ Mbɪɪwɪŋ ntsəmə ə chɪ nə alɔ'ə, ə tʊgə aləgəməfʊə.",
    english: 'Every Awing woman resident in the village has a sickle.',
    difficulty: 2,
    words: [
      AwingWord('Məngyɛ', '_'),
      AwingWord('Mbɪɪwɪŋ', '_'),
      AwingWord('ntsəmə', '_'),
      AwingWord('ə', '_'),
      AwingWord('chɪ', '_'),
      AwingWord('nə', '_'),
      AwingWord('alɔ\'ə', '_'),
      AwingWord('ə', '_'),
      AwingWord('tʊgə', '_'),
      AwingWord('aləgəməfʊə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Aləgənətwɛ lə məjɪ mə məsənə.",
    english: 'Breakfast is a meal taken in the morning.',
    difficulty: 1,
    words: [
      AwingWord('Aləgənətwɛ', '_'),
      AwingWord('lə', '_'),
      AwingWord('məjɪ', '_'),
      AwingWord('mə', '_'),
      AwingWord('məsənə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Aləŋələŋənəfoonə á ghə nəənə lə á aghə alumə.",
    english: 'Praying mantis are numerous in the dry season.',
    difficulty: 2,
    words: [
      AwingWord('Aləŋələŋənəfoonə', '_'),
      AwingWord('á', '_'),
      AwingWord('ghə', '_'),
      AwingWord('nəənə', '_'),
      AwingWord('lə', '_'),
      AwingWord('á', '_'),
      AwingWord('aghə', '_'),
      AwingWord('alumə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Məŋgə pə' aləŋəmóonə ajīə á tūg nə ngə'ə, məŋgə yī wə a kə pīə pō.",
    english: 'A woman who has problems with her womb cannot give birth.',
    difficulty: 3,
    words: [
      AwingWord('Məŋgə', '_'),
      AwingWord('pə\'', '_'),
      AwingWord('aləŋəmóonə', '_'),
      AwingWord('ajīə', '_'),
      AwingWord('á', '_'),
      AwingWord('tūg', '_'),
      AwingWord('nə', '_'),
      AwingWord('ngə\'ə', '_'),
      AwingWord('məŋgə', '_'),
      AwingWord('yī', '_'),
      AwingWord('wə', '_'),
      AwingWord('a', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Aləŋənəfoonəsə á chī lə nəpóolə.",
    english: 'God\'s throne is in heaven.',
    difficulty: 1,
    words: [
      AwingWord('Aləŋənəfoonəsə', '_'),
      AwingWord('á', '_'),
      AwingWord('chī', '_'),
      AwingWord('lə', '_'),
      AwingWord('nəpóolə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ali' yə noŋnə nə á pəŋə á mə pə nə ndē.",
    english: 'An open place is good for construction of a home.',
    difficulty: 3,
    words: [
      AwingWord('Ali\'', '_'),
      AwingWord('yə', '_'),
      AwingWord('noŋnə', '_'),
      AwingWord('nə', '_'),
      AwingWord('á', '_'),
      AwingWord('pəŋə', '_'),
      AwingWord('á', '_'),
      AwingWord('mə', '_'),
      AwingWord('pə', '_'),
      AwingWord('nə', '_'),
      AwingWord('ndē', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Kə yīə ali'ə nə, ghenə a ali' yīə.",
    english: 'Do not come here, go there.',
    difficulty: 2,
    words: [
      AwingWord('Kə', '_'),
      AwingWord('yīə', '_'),
      AwingWord('ali\'ə', '_'),
      AwingWord('nə', '_'),
      AwingWord('ghenə', '_'),
      AwingWord('a', '_'),
      AwingWord('ali\'', '_'),
      AwingWord('yīə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ali'əmətēenə ŋwu ntsəm lə ali' á zəg nə ndē əji əwə.",
    english: 'Each person\'s shop is where he gets food for his family.',
    difficulty: 3,
    words: [
      AwingWord('Ali\'əmətēenə', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('ntsəm', '_'),
      AwingWord('lə', '_'),
      AwingWord('ali\'', '_'),
      AwingWord('á', '_'),
      AwingWord('zəg', '_'),
      AwingWord('nə', '_'),
      AwingWord('ndē', '_'),
      AwingWord('əji', '_'),
      AwingWord('əwə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ali'əmətseŋnə á zá nchīə ndēməlo' ntsəmə.",
    english: 'There is always a latrine in every bar.',
    difficulty: 2,
    words: [
      AwingWord('Ali\'əmətseŋnə', '_'),
      AwingWord('á', '_'),
      AwingWord('zá', '_'),
      AwingWord('nchīə', '_'),
      AwingWord('ndēməlo\'', '_'),
      AwingWord('ntsəmə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ali'ənəfoonəsē á chī lə nəpəolə.",
    english: 'The throne of God is in heaven.',
    difficulty: 1,
    words: [
      AwingWord('Ali\'ənəfoonəsē', '_'),
      AwingWord('á', '_'),
      AwingWord('chī', '_'),
      AwingWord('lə', '_'),
      AwingWord('nəpəolə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ali'ətəŋwunə á chī lə lə chīə məna mə nəyenə əwə.",
    english: 'In any desolate place wild animals inhabit it.',
    difficulty: 2,
    words: [
      AwingWord('Ali\'ətəŋwunə', '_'),
      AwingWord('á', '_'),
      AwingWord('chī', '_'),
      AwingWord('lə', '_'),
      AwingWord('lə', '_'),
      AwingWord('chīə', '_'),
      AwingWord('məna', '_'),
      AwingWord('mə', '_'),
      AwingWord('nəyenə', '_'),
      AwingWord('əwə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ali'ətwīəleemə á chīə alā' Mbiwiŋə.",
    english: 'There is a forge in Awing.',
    difficulty: 1,
    words: [
      AwingWord('Ali\'ətwīəleemə', '_'),
      AwingWord('á', '_'),
      AwingWord('chīə', '_'),
      AwingWord('alā\'', '_'),
      AwingWord('Mbiwiŋə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ali'ətsəb zə á kē pəŋ pə.",
    english: 'That statement is not good.',
    difficulty: 2,
    words: [
      AwingWord('Ali\'ətsəb', '_'),
      AwingWord('zə', '_'),
      AwingWord('á', '_'),
      AwingWord('kē', '_'),
      AwingWord('pəŋ', '_'),
      AwingWord('pə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  // AwingSentence(
  // awing: "Ali'átsəmə á ndu mbi ló ali' mbɔ' ŋwunə kwéŋ ówá.",
  // english: 'One can prosper anywhere in the world.',
  // difficulty: 2,
  // words: [
  // AwingWord('Ali\'átsəmə', '_'),
  // AwingWord('á', '_'),
  // AwingWord('ndu', '_'),
  // AwingWord('mbi', '_'),
  // AwingWord('ló', '_'),
  // AwingWord('ali\'', '_'),
  // AwingWord('mbɔ\'', '_'),
  // AwingWord('ŋwunə', '_'),
  // AwingWord('kwéŋ', '_'),
  // AwingWord('ówá', '_'),
  // ],
  // ),  // REMOVED Session 66u similar-spelling: same English as the block at line 921 (Ali'átsəmə á ndu mbi ló ali' m)

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ambêməlo'ə á zá ńchìə ló á məmə atɔ'ə.",
    english: 'Palm rats are usually found in palm bushes.',
    difficulty: 2,
    words: [
      AwingWord('Ambêməlo\'ə', '_'),
      AwingWord('á', '_'),
      AwingWord('zá', '_'),
      AwingWord('ńchìə', '_'),
      AwingWord('ló', '_'),
      AwingWord('á', '_'),
      AwingWord('məmə', '_'),
      AwingWord('atɔ\'ə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Nəwʊə á alə' Mbɪwɪŋ lə anuə ɲwu ntsəmə.",
    english: 'A death in Awing is an event that involves everybody.',
    difficulty: 2,
    words: [
      AwingWord('Nəwʊə', '_'),
      AwingWord('á', '_'),
      AwingWord('alə\'', '_'),
      AwingWord('Mbɪwɪŋ', '_'),
      AwingWord('lə', '_'),
      AwingWord('anuə', '_'),
      AwingWord('ɲwu', '_'),
      AwingWord('ntsəmə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Anuəməghabə á nəənə á məm mbɪ əghə nə.",
    english: 'There is a lot of adultery in the world today.',
    difficulty: 2,
    words: [
      AwingWord('Anuəməghabə', '_'),
      AwingWord('á', '_'),
      AwingWord('nəənə', '_'),
      AwingWord('á', '_'),
      AwingWord('məm', '_'),
      AwingWord('mbɪ', '_'),
      AwingWord('əghə', '_'),
      AwingWord('nə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A tsid ntsid pə tə sɔŋə á sɔŋə anúənda'ə.",
    english: 'He lied, but when asked he responded falsely.',
    difficulty: 2,
    words: [
      AwingWord('A', '_'),
      AwingWord('tsid', '_'),
      AwingWord('ntsid', '_'),
      AwingWord('pə', '_'),
      AwingWord('tə', '_'),
      AwingWord('sɔŋə', '_'),
      AwingWord('á', '_'),
      AwingWord('sɔŋə', '_'),
      AwingWord('anúənda\'ə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Anúəsê á nəənə alá' Mbíiwíŋə.",
    english: 'Christianity is widespread in Awing.',
    difficulty: 1,
    words: [
      AwingWord('Anúəsê', '_'),
      AwingWord('á', '_'),
      AwingWord('nəənə', '_'),
      AwingWord('alá\'', '_'),
      AwingWord('Mbíiwíŋə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ndzaŋ mbí zi chí nə́ ló chigə anuətə́jɪə.",
    english: 'It is really a mystery the way the world functions.',
    difficulty: 2,
    words: [
      AwingWord('Ndzaŋ', '_'),
      AwingWord('mbí', '_'),
      AwingWord('zi', '_'),
      AwingWord('chí', '_'),
      AwingWord('nə', '_'),
      AwingWord('ló', '_'),
      AwingWord('chigə', '_'),
      AwingWord('anuətə', '_'),
      AwingWord('jɪə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Anuyə́fɪə á yí ló pə́ mya'ə́ yə lenə.",
    english: 'When something fashionable comes up the old one is abandoned.',
    difficulty: 2,
    words: [
      AwingWord('Anuyə', '_'),
      AwingWord('fɪə', '_'),
      AwingWord('á', '_'),
      AwingWord('yí', '_'),
      AwingWord('ló', '_'),
      AwingWord('pə', '_'),
      AwingWord('mya\'ə', '_'),
      AwingWord('yə', '_'),
      AwingWord('lenə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Anuyə́fɪə á yí ló pə́ mya'ə́ anuyəlenə.",
    english: 'When something fashionable comes up the old one is abandoned.',
    difficulty: 2,
    words: [
      AwingWord('Anuyə', '_'),
      AwingWord('fɪə', '_'),
      AwingWord('á', '_'),
      AwingWord('yí', '_'),
      AwingWord('ló', '_'),
      AwingWord('pə', '_'),
      AwingWord('mya\'ə', '_'),
      AwingWord('anuyəlenə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Anyíŋə apó á ghelə́ ŋwunə ŋwa'ə́.",
    english: 'A finger nail beautifies somebody.',
    difficulty: 2,
    words: [
      AwingWord('Anyíŋə', '_'),
      AwingWord('apó', '_'),
      AwingWord('á', '_'),
      AwingWord('ghelə', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('ŋwa\'ə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ijwunə a túg ná móonə a túgə apadtəmóonə ajíə.",
    english: 'He who has a baby has a its sling.',
    difficulty: 2,
    words: [
      AwingWord('Ijwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('túg', '_'),
      AwingWord('ná', '_'),
      AwingWord('móonə', '_'),
      AwingWord('a', '_'),
      AwingWord('túgə', '_'),
      AwingWord('apadtəmóonə', '_'),
      AwingWord('ajíə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Apɛlə nkɪə atsəmə á nchɪndɛ á fɛ lúmɔ.",
    english: 'Every waterhole around the compound breads mosquitoes.',
    difficulty: 2,
    words: [
      AwingWord('Apɛlə', '_'),
      AwingWord('nkɪə', '_'),
      AwingWord('atsəmə', '_'),
      AwingWord('á', '_'),
      AwingWord('nchɪndɛ', '_'),
      AwingWord('á', '_'),
      AwingWord('fɛ', '_'),
      AwingWord('lúmɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Apɛlə nkɪ pá' á kɛ nɔ shɪ, mbɔ' nkɪ əyí á fɛ aghɔ nɔ ŋwunə.",
    english: 'Water from a shallow well can infect one with a disease.',
    difficulty: 3,
    words: [
      AwingWord('Apɛlə', '_'),
      AwingWord('nkɪ', '_'),
      AwingWord('pá\'', '_'),
      AwingWord('á', '_'),
      AwingWord('kɛ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('shɪ', '_'),
      AwingWord('mbɔ\'', '_'),
      AwingWord('nkɪ', '_'),
      AwingWord('əyí', '_'),
      AwingWord('á', '_'),
      AwingWord('fɛ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Apô yɔ kwab lɔ̀ kɛ̀ apô afa' pô.",
    english: 'The left hand is not often used for activities.',
    difficulty: 2,
    words: [
      AwingWord('Apô', '_'),
      AwingWord('yɔ', '_'),
      AwingWord('kwab', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('kɛ', '_'),
      AwingWord('apô', '_'),
      AwingWord('afa\'', '_'),
      AwingWord('pô', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Apô yɔ ti lɔ̀ apô afa'ɔ.",
    english: 'The right hand is often used for activities.',
    difficulty: 2,
    words: [
      AwingWord('Apô', '_'),
      AwingWord('yɔ', '_'),
      AwingWord('ti', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('apô', '_'),
      AwingWord('afa\'ɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Apó'ɔ́móonɔ á kɛ̀ pɪ mbéd mbá anu yɔ ɔshí'nɔ á ndu mbí pô.",
    english: 'Circumcision is no longer an acceptable thing in the world today.',
    difficulty: 3,
    words: [
      AwingWord('Apó\'ɔ', '_'),
      AwingWord('móonɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('kɛ', '_'),
      AwingWord('pɪ', '_'),
      AwingWord('mbéd', '_'),
      AwingWord('mbá', '_'),
      AwingWord('anu', '_'),
      AwingWord('yɔ', '_'),
      AwingWord('ɔshí\'nɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('ndu', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Á mɔ́mɔ alá' Mbíiwíŋ, apu'ɔ mɔ́jɔ ntɔŋkaŋ lɔ́ jɔ́ mɔ́ nkɔ́.",
    english: 'In Awing, food leftovers of an elder is eaten by a child.',
    difficulty: 3,
    words: [
      AwingWord('Á', '_'),
      AwingWord('mɔ', '_'),
      AwingWord('mɔ', '_'),
      AwingWord('alá\'', '_'),
      AwingWord('Mbíiwíŋ', '_'),
      AwingWord('apu\'ɔ', '_'),
      AwingWord('mɔ', '_'),
      AwingWord('jɔ', '_'),
      AwingWord('ntɔŋkaŋ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('jɔ', '_'),
      AwingWord('mɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Gho lɔ́ nɔ́ ntogɔ́ o kwú nɔ́ asaambɛ.",
    english: 'When you leave six you go to seven.',
    difficulty: 2,
    words: [
      AwingWord('Gho', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('ntogɔ', '_'),
      AwingWord('o', '_'),
      AwingWord('kwú', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('asaambɛ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Nkáb lɔ́ alɛ́ pa' asá'ɔ́nuɔ á chì nɔ́ alá' Mbíiwíŋɔ.",
    english: 'Nkab is a day that announcements are made in Awing.',
    difficulty: 2,
    words: [
      AwingWord('Nkáb', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('alɛ', '_'),
      AwingWord('pa\'', '_'),
      AwingWord('asá\'ɔ', '_'),
      AwingWord('nuɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('chì', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('alá\'', '_'),
      AwingWord('Mbíiwíŋɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Asɛlɔ́ á waamɔ́ lɔ́ tɔ́gndɛ́ ɲwunə.",
    english: 'Sore throat attacks the throat.',
    difficulty: 2,
    words: [
      AwingWord('Asɛlɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('waamɔ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('tɔ', '_'),
      AwingWord('gndɛ', '_'),
      AwingWord('ɲwunə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ashǎdnə akáŋə á kě pɔŋə á mé néŋ né ná' pō.",
    english: 'A plate is not good for dishing soup.',
    difficulty: 3,
    words: [
      AwingWord('Ashǎdnə', '_'),
      AwingWord('akáŋə', '_'),
      AwingWord('á', '_'),
      AwingWord('kě', '_'),
      AwingWord('pɔŋə', '_'),
      AwingWord('á', '_'),
      AwingWord('mé', '_'),
      AwingWord('néŋ', '_'),
      AwingWord('né', '_'),
      AwingWord('ná\'', '_'),
      AwingWord('pō', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Lě chigə ashwěnuə.",
    english: 'This act is really a failure.',
    difficulty: 1,
    words: [
      AwingWord('Lě', '_'),
      AwingWord('chigə', '_'),
      AwingWord('ashwěnuə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A disease that makes babies to grow pale.",
    english: 'It is very much like malnutrition.',
    difficulty: 2,
    words: [
      AwingWord('A', '_'),
      AwingWord('disease', '_'),
      AwingWord('that', '_'),
      AwingWord('makes', '_'),
      AwingWord('babies', '_'),
      AwingWord('to', '_'),
      AwingWord('grow', '_'),
      AwingWord('pale', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ataŋəmóonə á jwíta mó lə tsɔ'ə əghá áwə.",
    english: 'A kind of disease like malnutrition kills children very fast.',
    difficulty: 2,
    words: [
      AwingWord('Ataŋəmóonə', '_'),
      AwingWord('á', '_'),
      AwingWord('jwíta', '_'),
      AwingWord('mó', '_'),
      AwingWord('lə', '_'),
      AwingWord('tsɔ\'ə', '_'),
      AwingWord('əghá', '_'),
      AwingWord('áwə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Atéelə ako lə ali' pá' ŋwunə a tóg né á ndəsə.",
    english: 'The foot is the part that we put on the ground.',
    difficulty: 3,
    words: [
      AwingWord('Atéelə', '_'),
      AwingWord('ako', '_'),
      AwingWord('lə', '_'),
      AwingWord('ali\'', '_'),
      AwingWord('pá\'', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('tóg', '_'),
      AwingWord('né', '_'),
      AwingWord('á', '_'),
      AwingWord('ndəsə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Atəənə akóolə əshúə á chī lə ali' nkí á chī né áwə.",
    english: 'Afish trap is found where there is water.',
    difficulty: 3,
    words: [
      AwingWord('Atəənə', '_'),
      AwingWord('akóolə', '_'),
      AwingWord('əshúə', '_'),
      AwingWord('á', '_'),
      AwingWord('chī', '_'),
      AwingWord('lə', '_'),
      AwingWord('ali\'', '_'),
      AwingWord('nkí', '_'),
      AwingWord('á', '_'),
      AwingWord('chī', '_'),
      AwingWord('né', '_'),
      AwingWord('áwə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbɔ' o zəə atāsəəmə o lyāŋə.",
    english: 'If you see a wild man, you should hide.',
    difficulty: 2,
    words: [
      AwingWord('Mbɔ\'', '_'),
      AwingWord('o', '_'),
      AwingWord('zəə', '_'),
      AwingWord('atāsəəmə', '_'),
      AwingWord('o', '_'),
      AwingWord('lyāŋə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A tūgə atāsəəmə ako yə.",
    english: 'He has an unhealing wound on his leg Pl.',
    difficulty: 1,
    words: [
      AwingWord('A', '_'),
      AwingWord('tūgə', '_'),
      AwingWord('atāsəəmə', '_'),
      AwingWord('ako', '_'),
      AwingWord('yə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Atīə akwamnə á fōgə lā azoomə.",
    english: 'A plum tree produces plum.',
    difficulty: 2,
    words: [
      AwingWord('Atīə', '_'),
      AwingWord('akwamnə', '_'),
      AwingWord('á', '_'),
      AwingWord('fōgə', '_'),
      AwingWord('lā', '_'),
      AwingWord('azoomə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Atīə awaglə lā atī yə əshī'nə.",
    english: 'A boundary stick is a nice stick Pl.',
    difficulty: 2,
    words: [
      AwingWord('Atīə', '_'),
      AwingWord('awaglə', '_'),
      AwingWord('lā', '_'),
      AwingWord('atī', '_'),
      AwingWord('yə', '_'),
      AwingWord('əshī\'nə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Atīə awagləpənēmə á chī lā Pənēmə.",
    english: 'A Baminyam boundary stick is found in Baminyam.',
    difficulty: 2,
    words: [
      AwingWord('Atīə', '_'),
      AwingWord('awagləpənēmə', '_'),
      AwingWord('á', '_'),
      AwingWord('chī', '_'),
      AwingWord('lā', '_'),
      AwingWord('Pənēmə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Atɪə əghəmə á chɪ lɔ mbɔ lɔ ɲwɪŋə alɪ' pɔtsɔ.",
    english: 'A fig tree is a tree god in some places.',
    difficulty: 2,
    words: [
      AwingWord('Atɪə', '_'),
      AwingWord('əghəmə', '_'),
      AwingWord('á', '_'),
      AwingWord('chɪ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('mbɔ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('ɲwɪŋə', '_'),
      AwingWord('alɪ\'', '_'),
      AwingWord('pɔtsɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pɔ lɔgɔ atɪə fɔŋəfɔŋə ndɔgɔ sɔɔlə lɔ pɔlɔŋ ɔwɔ.",
    english: 'A plank tree is used for sawing plank.',
    difficulty: 2,
    words: [
      AwingWord('Pɔ', '_'),
      AwingWord('lɔgɔ', '_'),
      AwingWord('atɪə', '_'),
      AwingWord('fɔŋəfɔŋə', '_'),
      AwingWord('ndɔgɔ', '_'),
      AwingWord('sɔɔlə', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('pɔlɔŋ', '_'),
      AwingWord('ɔwɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Atɪə kokonɔlə á kɛ alɔ' Mbɪwɪŋ chɪ pɔ.",
    english: 'There is no coconut tree in Awing.',
    difficulty: 2,
    words: [
      AwingWord('Atɪə', '_'),
      AwingWord('kokonɔlə', '_'),
      AwingWord('á', '_'),
      AwingWord('kɛ', '_'),
      AwingWord('alɔ\'', '_'),
      AwingWord('Mbɪwɪŋ', '_'),
      AwingWord('chɪ', '_'),
      AwingWord('pɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Atɪə məghɔd lɔ atɪ pɔ' mɔtɔnə mɔ məghɔd mɔ fɛd nɔ ɔwɔ.",
    english: 'Oil palms are palms that produce palm nuts.',
    difficulty: 3,
    words: [
      AwingWord('Atɪə', '_'),
      AwingWord('məghɔd', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('atɪ', '_'),
      AwingWord('pɔ\'', '_'),
      AwingWord('mɔtɔnə', '_'),
      AwingWord('mɔ', '_'),
      AwingWord('məghɔd', '_'),
      AwingWord('mɔ', '_'),
      AwingWord('fɛd', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('ɔwɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "ɔ a kɛ kɔŋə á mɔ kɔ' nɔ atɪə məsɔbtə pɔ.",
    english: 'Nobody likes climbing a thorn tree.',
    difficulty: 3,
    words: [
      AwingWord('ɔ', '_'),
      AwingWord('a', '_'),
      AwingWord('kɛ', '_'),
      AwingWord('kɔŋə', '_'),
      AwingWord('á', '_'),
      AwingWord('mɔ', '_'),
      AwingWord('kɔ\'', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('atɪə', '_'),
      AwingWord('məsɔbtə', '_'),
      AwingWord('pɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Atɪə nɔpɪə á zəmə lɔ nɔpɪə.",
    english: 'A cola nut tree bears colanuts.',
    difficulty: 2,
    words: [
      AwingWord('Atɪə', '_'),
      AwingWord('nɔpɪə', '_'),
      AwingWord('á', '_'),
      AwingWord('zəmə', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('nɔpɪə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Atɪə nɔpɪəmbɛŋə lɔ atɪə mbwɔdnə.",
    english: 'A quiny tree is a peaceful tree.',
    difficulty: 1,
    words: [
      AwingWord('Atɪə', '_'),
      AwingWord('nɔpɪəmbɛŋə', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('atɪə', '_'),
      AwingWord('mbwɔdnə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Atɪə nɔtɔnə á fɛ məghɔd mimɔ paŋ nɔ.",
    english: 'A palm tree produces red oil.',
    difficulty: 2,
    words: [
      AwingWord('Atɪə', '_'),
      AwingWord('nɔtɔnə', '_'),
      AwingWord('á', '_'),
      AwingWord('fɛ', '_'),
      AwingWord('məghɔd', '_'),
      AwingWord('mimɔ', '_'),
      AwingWord('paŋ', '_'),
      AwingWord('nɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbɪwɪŋə a pɔ ndɛ ɔjɪ lɔ, a nɛŋə atɪə ndɛ pɔ atɪə apɛŋə.",
    english: 'The traditional Awing man builds his house with a first and second floor ceiling.',
    difficulty: 3,
    words: [
      AwingWord('Mbɪwɪŋə', '_'),
      AwingWord('a', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('ndɛ', '_'),
      AwingWord('ɔjɪ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('a', '_'),
      AwingWord('nɛŋə', '_'),
      AwingWord('atɪə', '_'),
      AwingWord('ndɛ', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('atɪə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "ɔŋɔtɔŋɔ 41 atúɔnɔ́pe Ató'nɔ́ŋkɔnɔ na mbelɔ́lɔ́' á pɔŋɔ́ mɔ́ kɔ́d nɔ́.",
    english: 'The hunchback of cattle is very tasty.',
    difficulty: 3,
    words: [
      AwingWord('ɔŋɔtɔŋɔ', '_'),
      AwingWord('41', '_'),
      AwingWord('atúɔnɔ', '_'),
      AwingWord('pe', '_'),
      AwingWord('Ató\'nɔ', '_'),
      AwingWord('ŋkɔnɔ', '_'),
      AwingWord('na', '_'),
      AwingWord('mbelɔ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('\'', '_'),
      AwingWord('á', '_'),
      AwingWord('pɔŋɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Atɔ́gɔ ɔkwu lɔ atɔ́g pɔ́' ɲwu ntsɔmɔ kɛ nɔ́ ɔwɔ́ kwunɔ pɔ́.",
    english: 'The bedroom is private.',
    difficulty: 3,
    words: [
      AwingWord('Atɔ', '_'),
      AwingWord('gɔ', '_'),
      AwingWord('ɔkwu', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('atɔ', '_'),
      AwingWord('g', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('\'', '_'),
      AwingWord('ɲwu', '_'),
      AwingWord('ntsɔmɔ', '_'),
      AwingWord('kɛ', '_'),
      AwingWord('nɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Atú yɔ pɔ́' nɔ́ á ghɔ́ zá nɔ́ɔnɔ aghɔ́ alumɔ.",
    english: 'Headache is frequent in the dry season.',
    difficulty: 2,
    words: [
      AwingWord('Atú', '_'),
      AwingWord('yɔ', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('\'', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('ghɔ', '_'),
      AwingWord('zá', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('ɔnɔ', '_'),
      AwingWord('aghɔ', '_'),
      AwingWord('alumɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Chigɔ mɛ anuɔ a chí nɔ nɔ atúɔ ndɛ lɔ zɛ́ŋɔ.",
    english: 'The most important thing for the roof of a house is the zinc.',
    difficulty: 3,
    words: [
      AwingWord('Chigɔ', '_'),
      AwingWord('mɛ', '_'),
      AwingWord('anuɔ', '_'),
      AwingWord('a', '_'),
      AwingWord('chí', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('atúɔ', '_'),
      AwingWord('ndɛ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('zɛ', '_'),
      AwingWord('ŋɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Atúɔnɔ́pe lɔ aghoonɔ atúənáséná 42 atsa'ənákəŋə pətəkaŋə.",
    english: 'Side pain is an illness of elderly people.',
    difficulty: 2,
    words: [
      AwingWord('Atúɔnɔ', '_'),
      AwingWord('pe', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('aghoonɔ', '_'),
      AwingWord('atúənáséná', '_'),
      AwingWord('42', '_'),
      AwingWord('atsa\'ənákəŋə', '_'),
      AwingWord('pətəkaŋə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pó fya' ətúəsɛ alá' Mbɪwɪŋə.",
    english: 'The hair of dead men is appeased in Awing.',
    difficulty: 1,
    words: [
      AwingWord('Pó', '_'),
      AwingWord('fya\'', '_'),
      AwingWord('ətúəsɛ', '_'),
      AwingWord('alá\'', '_'),
      AwingWord('Mbɪwɪŋə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Atsá'ə amú'ə á chibə á alá' Mbɪwɪŋ ɪtse ətú ətsəmə.",
    english: 'A regime of banana is much cheaper in Awing than in all other places.',
    difficulty: 2,
    words: [
      AwingWord('Atsá\'ə', '_'),
      AwingWord('amú\'ə', '_'),
      AwingWord('á', '_'),
      AwingWord('chibə', '_'),
      AwingWord('á', '_'),
      AwingWord('alá\'', '_'),
      AwingWord('Mbɪwɪŋ', '_'),
      AwingWord('ɪtse', '_'),
      AwingWord('ətú', '_'),
      AwingWord('ətsəmə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Atsa'ə mbɔ nəkəŋə á zá nchɪə lə á nkaŋ nkyɪə.",
    english: 'The potters clay is usually found near the stream.',
    difficulty: 2,
    words: [
      AwingWord('Atsa\'ə', '_'),
      AwingWord('mbɔ', '_'),
      AwingWord('nəkəŋə', '_'),
      AwingWord('á', '_'),
      AwingWord('zá', '_'),
      AwingWord('nchɪə', '_'),
      AwingWord('lə', '_'),
      AwingWord('á', '_'),
      AwingWord('nkaŋ', '_'),
      AwingWord('nkyɪə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pó lɔgə lə atsa'ə ndəsɛ mbɔ ndɛ əwə á alá' Mbɪwɪŋə.",
    english: 'We use mud blocks to build houses in Awing.',
    difficulty: 3,
    words: [
      AwingWord('Pó', '_'),
      AwingWord('lɔgə', '_'),
      AwingWord('lə', '_'),
      AwingWord('atsa\'ə', '_'),
      AwingWord('ndəsɛ', '_'),
      AwingWord('mbɔ', '_'),
      AwingWord('ndɛ', '_'),
      AwingWord('əwə', '_'),
      AwingWord('á', '_'),
      AwingWord('alá\'', '_'),
      AwingWord('Mbɪwɪŋə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Atséebənəmú' ló kē ŋwu ntsəm zó'ə pō.",
    english: 'Not anybody understands parables.',
    difficulty: 2,
    words: [
      AwingWord('Atséebənəmú\'', '_'),
      AwingWord('ló', '_'),
      AwingWord('kē', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('ntsəm', '_'),
      AwingWord('zó\'ə', '_'),
      AwingWord('pō', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Atsə'ə məkə'nə lə zá ŋgwē mbyáŋnə.",
    english: 'Shirts are usually worn by men.',
    difficulty: 2,
    words: [
      AwingWord('Atsə\'ə', '_'),
      AwingWord('məkə\'nə', '_'),
      AwingWord('lə', '_'),
      AwingWord('zá', '_'),
      AwingWord('ŋgwē', '_'),
      AwingWord('mbyáŋnə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbəəmə mə ntsəm tə ndzogə.",
    english: 'My whole body is itching.',
    difficulty: 1,
    words: [
      AwingWord('Mbəəmə', '_'),
      AwingWord('mə', '_'),
      AwingWord('ntsəm', '_'),
      AwingWord('tə', '_'),
      AwingWord('ndzogə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Zəələ atsəmo lə əlé.",
    english: 'The total of it is what.',
    difficulty: 1,
    words: [
      AwingWord('Zəələ', '_'),
      AwingWord('atsəmo', '_'),
      AwingWord('lə', '_'),
      AwingWord('əlé', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Lə kə anuə atsəmo á pəŋ nə mə fa' nə pə.",
    english: 'Everything is good to do.',
    difficulty: 3,
    words: [
      AwingWord('Lə', '_'),
      AwingWord('kə', '_'),
      AwingWord('anuə', '_'),
      AwingWord('atsəmo', '_'),
      AwingWord('á', '_'),
      AwingWord('pəŋ', '_'),
      AwingWord('nə', '_'),
      AwingWord('mə', '_'),
      AwingWord('fa\'', '_'),
      AwingWord('nə', '_'),
      AwingWord('pə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Atsəmətsəm lə əlé.",
    english: 'The total is what.',
    difficulty: 1,
    words: [
      AwingWord('Atsəmətsəm', '_'),
      AwingWord('lə', '_'),
      AwingWord('əlé', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pə nkə pə kə atso jí mə təŋ nə pə.",
    english: 'Children do not know how to play the musical instrument that is made from a horn.',
    difficulty: 2,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('nkə', '_'),
      AwingWord('pə', '_'),
      AwingWord('kə', '_'),
      AwingWord('atso', '_'),
      AwingWord('jí', '_'),
      AwingWord('mə', '_'),
      AwingWord('təŋ', '_'),
      AwingWord('nə', '_'),
      AwingWord('pə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbə' o pɪə atso'ə ngəsəŋə á fə o nə apeemə ngəsəŋə.",
    english: 'One can plant a cob of corn and it produces a bag full.',
    difficulty: 3,
    words: [
      AwingWord('Mbə\'', '_'),
      AwingWord('o', '_'),
      AwingWord('pɪə', '_'),
      AwingWord('atso\'ə', '_'),
      AwingWord('ngəsəŋə', '_'),
      AwingWord('á', '_'),
      AwingWord('fə', '_'),
      AwingWord('o', '_'),
      AwingWord('nə', '_'),
      AwingWord('apeemə', '_'),
      AwingWord('ngəsəŋə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Á tyantə mə tug nə awa'ə pəənə.",
    english: 'It is difficult to manage groups of people.',
    difficulty: 2,
    words: [
      AwingWord('Á', '_'),
      AwingWord('tyantə', '_'),
      AwingWord('mə', '_'),
      AwingWord('tug', '_'),
      AwingWord('nə', '_'),
      AwingWord('awa\'ə', '_'),
      AwingWord('pəənə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Awɔgɔfɔgɔ á pɔŋ lɔ ɔghɔ ɔli' tɔ nɔ ndumɔ.",
    english: 'A fan is necessary when there is heat.',
    difficulty: 2,
    words: [
      AwingWord('Awɔgɔfɔgɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('pɔŋ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('ɔghɔ', '_'),
      AwingWord('ɔli\'', '_'),
      AwingWord('tɔ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('ndumɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Azɛɛmɔ azoomɔ á ɔfɔ?",
    english: 'Where is my own plum?',
    difficulty: 1,
    words: [
      AwingWord('Azɛɛmɔ', '_'),
      AwingWord('azoomɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('ɔfɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pi pətsə pō chīə bā tə tú'ə sēnə.",
    english: 'Some people stay in the bar for the whole day.',
    difficulty: 2,
    words: [
      AwingWord('Pi', '_'),
      AwingWord('pətsə', '_'),
      AwingWord('pō', '_'),
      AwingWord('chīə', '_'),
      AwingWord('bā', '_'),
      AwingWord('tə', '_'),
      AwingWord('tú\'ə', '_'),
      AwingWord('sēnə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pə fōŋə aŋwa'lə Əsə lə nə bāabəələ.",
    english: 'The word of God is called a Bible.',
    difficulty: 2,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('fōŋə', '_'),
      AwingWord('aŋwa\'lə', '_'),
      AwingWord('Əsə', '_'),
      AwingWord('lə', '_'),
      AwingWord('nə', '_'),
      AwingWord('bāabəələ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Təfāŋfāŋ ŋwunə a wūə əse lə ngə bīm.",
    english: 'When a fat person falls on the ground, he falls thump.',
    difficulty: 2,
    words: [
      AwingWord('Təfāŋfāŋ', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('wūə', '_'),
      AwingWord('əse', '_'),
      AwingWord('lə', '_'),
      AwingWord('ngə', '_'),
      AwingWord('bīm', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Bishəb lə chigə təkə' ŋwunə á məm chəsə.",
    english: 'A bishop is a high ranking person in the church.',
    difficulty: 2,
    words: [
      AwingWord('Bishəb', '_'),
      AwingWord('lə', '_'),
      AwingWord('chigə', '_'),
      AwingWord('təkə\'', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('á', '_'),
      AwingWord('məm', '_'),
      AwingWord('chəsə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Anəmə á chāabə á mbi ngwū.",
    english: 'Lice are tightly clustered on the dog\'s body.',
    difficulty: 2,
    words: [
      AwingWord('Anəmə', '_'),
      AwingWord('á', '_'),
      AwingWord('chāabə', '_'),
      AwingWord('á', '_'),
      AwingWord('mbi', '_'),
      AwingWord('ngwū', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Məngyə a tə ndzə'ə lə pə ghen nchaakə yə á ndə ndū yə.",
    english: 'When a woman is marrying she is escorted to her new home.',
    difficulty: 3,
    words: [
      AwingWord('Məngyə', '_'),
      AwingWord('a', '_'),
      AwingWord('tə', '_'),
      AwingWord('ndzə\'ə', '_'),
      AwingWord('lə', '_'),
      AwingWord('pə', '_'),
      AwingWord('ghen', '_'),
      AwingWord('nchaakə', '_'),
      AwingWord('yə', '_'),
      AwingWord('á', '_'),
      AwingWord('ndə', '_'),
      AwingWord('ndū', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pi pə chī nə ndi yi əse pə chaakə əpūmə alā' lə chaakə nə.",
    english: 'People who stay far away from the village send things to the village through other people.',
    difficulty: 3,
    words: [
      AwingWord('Pi', '_'),
      AwingWord('pə', '_'),
      AwingWord('chī', '_'),
      AwingWord('nə', '_'),
      AwingWord('ndi', '_'),
      AwingWord('yi', '_'),
      AwingWord('əse', '_'),
      AwingWord('pə', '_'),
      AwingWord('chaakə', '_'),
      AwingWord('əpūmə', '_'),
      AwingWord('alā\'', '_'),
      AwingWord('lə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Anuə chaakə məngyə alā' Mbīwīŋ lə chigə mé anuə.",
    english: 'The act of escorting a bride to her groom in Awing is a great event.',
    difficulty: 2,
    words: [
      AwingWord('Anuə', '_'),
      AwingWord('chaakə', '_'),
      AwingWord('məngyə', '_'),
      AwingWord('alā\'', '_'),
      AwingWord('Mbīwīŋ', '_'),
      AwingWord('lə', '_'),
      AwingWord('chigə', '_'),
      AwingWord('mé', '_'),
      AwingWord('anuə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pi pə' pə zə nə nkéebə alā' pə tūgə ape' tə zəlāə chaanə.",
    english: 'People who steal public property have abundant wealth.',
    difficulty: 3,
    words: [
      AwingWord('Pi', '_'),
      AwingWord('pə\'', '_'),
      AwingWord('pə', '_'),
      AwingWord('zə', '_'),
      AwingWord('nə', '_'),
      AwingWord('nkéebə', '_'),
      AwingWord('alā\'', '_'),
      AwingWord('pə', '_'),
      AwingWord('tūgə', '_'),
      AwingWord('ape\'', '_'),
      AwingWord('tə', '_'),
      AwingWord('zəlāə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Akəfə pə pəm nə nə afūə á chābtə məm əwə lə ándə ajūmə kətaŋə.",
    english: 'Coffee that is sprayed with insecticide is tightly clustered in the branches as wild fruits.',
    difficulty: 3,
    words: [
      AwingWord('Akəfə', '_'),
      AwingWord('pə', '_'),
      AwingWord('pəm', '_'),
      AwingWord('nə', '_'),
      AwingWord('nə', '_'),
      AwingWord('afūə', '_'),
      AwingWord('á', '_'),
      AwingWord('chābtə', '_'),
      AwingWord('məm', '_'),
      AwingWord('əwə', '_'),
      AwingWord('lə', '_'),
      AwingWord('ándə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ngāŋ ngo' kə chīə mbī tə ncha'ə.",
    english: 'The ancient people lived very long lives.',
    difficulty: 2,
    words: [
      AwingWord('Ngāŋ', '_'),
      AwingWord('ngo\'', '_'),
      AwingWord('kə', '_'),
      AwingWord('chīə', '_'),
      AwingWord('mbī', '_'),
      AwingWord('tə', '_'),
      AwingWord('ncha\'ə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pi pə lə əsə á əkwu lə məg məb mə cha'ə.",
    english: 'When people wake up from bed they realise their eyes bear a white substance.',
    difficulty: 3,
    words: [
      AwingWord('Pi', '_'),
      AwingWord('pə', '_'),
      AwingWord('lə', '_'),
      AwingWord('əsə', '_'),
      AwingWord('á', '_'),
      AwingWord('əkwu', '_'),
      AwingWord('lə', '_'),
      AwingWord('məg', '_'),
      AwingWord('məb', '_'),
      AwingWord('mə', '_'),
      AwingWord('cha\'ə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Nəkād nə mūto nə chagə lə mbə ajū ntsəmə.",
    english: 'The tyres of a car smashes all sorts of things.',
    difficulty: 2,
    words: [
      AwingWord('Nəkād', '_'),
      AwingWord('nə', '_'),
      AwingWord('mūto', '_'),
      AwingWord('nə', '_'),
      AwingWord('chagə', '_'),
      AwingWord('lə', '_'),
      AwingWord('mbə', '_'),
      AwingWord('ajū', '_'),
      AwingWord('ntsəmə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ngaŋəŋwa'lə zá nchāg əli' lə nə əpag əŋwa'lə.",
    english: 'School children usually dirty places with pieces of papers.',
    difficulty: 2,
    words: [
      AwingWord('Ngaŋəŋwa\'lə', '_'),
      AwingWord('zá', '_'),
      AwingWord('nchāg', '_'),
      AwingWord('əli\'', '_'),
      AwingWord('lə', '_'),
      AwingWord('nə', '_'),
      AwingWord('əpag', '_'),
      AwingWord('əŋwa\'lə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Cha'təsê pá' mbɔ' o tá ɲdoonə ɲgá mənu mó mó nyinə.",
    english: 'Pray, if you want to succeed in all your endeavours.',
    difficulty: 3,
    words: [
      AwingWord('Cha\'təsê', '_'),
      AwingWord('pá\'', '_'),
      AwingWord('mbɔ\'', '_'),
      AwingWord('o', '_'),
      AwingWord('tá', '_'),
      AwingWord('ɲdoonə', '_'),
      AwingWord('ɲgá', '_'),
      AwingWord('mənu', '_'),
      AwingWord('mó', '_'),
      AwingWord('mó', '_'),
      AwingWord('nyinə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ngwú ə zó' əli' lá pá' á chi ná mám chénə.",
    english: 'A dog is properly controlled when it is in chains.',
    difficulty: 3,
    words: [
      AwingWord('Ngwú', '_'),
      AwingWord('ə', '_'),
      AwingWord('zó\'', '_'),
      AwingWord('əli\'', '_'),
      AwingWord('lá', '_'),
      AwingWord('pá\'', '_'),
      AwingWord('á', '_'),
      AwingWord('chi', '_'),
      AwingWord('ná', '_'),
      AwingWord('mám', '_'),
      AwingWord('chénə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A kě pɔŋə má chi' ná əli' pá' pɪ pá náanə ná mbwódna pó.",
    english: 'It is not good to raise false alarm in peace time.',
    difficulty: 3,
    words: [
      AwingWord('A', '_'),
      AwingWord('kě', '_'),
      AwingWord('pɔŋə', '_'),
      AwingWord('má', '_'),
      AwingWord('chi\'', '_'),
      AwingWord('ná', '_'),
      AwingWord('əli\'', '_'),
      AwingWord('pá\'', '_'),
      AwingWord('pɪ', '_'),
      AwingWord('pá', '_'),
      AwingWord('náanə', '_'),
      AwingWord('ná', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ajūmə chiə apa ŋwu lā a chi' mbi yā á mbi ngaŋəko yā.",
    english: 'When somebody has a little money he starts puffing up amongst his friends.',
    difficulty: 3,
    words: [
      AwingWord('Ajūmə', '_'),
      AwingWord('chiə', '_'),
      AwingWord('apa', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('lā', '_'),
      AwingWord('a', '_'),
      AwingWord('chi\'', '_'),
      AwingWord('mbi', '_'),
      AwingWord('yā', '_'),
      AwingWord('á', '_'),
      AwingWord('mbi', '_'),
      AwingWord('ngaŋəko', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mətū mǎ alā' mətsī mǎ chiə ághǒb lā chigə mbō kətaŋə.",
    english: 'The leaders of some countries are really powerless.',
    difficulty: 3,
    words: [
      AwingWord('Mətū', '_'),
      AwingWord('mǎ', '_'),
      AwingWord('alā\'', '_'),
      AwingWord('mətsī', '_'),
      AwingWord('mǎ', '_'),
      AwingWord('chiə', '_'),
      AwingWord('ághǒb', '_'),
      AwingWord('lā', '_'),
      AwingWord('chigə', '_'),
      AwingWord('mbō', '_'),
      AwingWord('kətaŋə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbɔ' ŋwunə chi nǎ apǒgə a kě chi mbɔ' a fa'ǎ chigə anu pō.",
    english: 'He who lives in fear cannot do any great thing.',
    difficulty: 3,
    words: [
      AwingWord('Mbɔ\'', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('chi', '_'),
      AwingWord('nǎ', '_'),
      AwingWord('apǒgə', '_'),
      AwingWord('a', '_'),
      AwingWord('kě', '_'),
      AwingWord('chi', '_'),
      AwingWord('mbɔ\'', '_'),
      AwingWord('a', '_'),
      AwingWord('fa\'ǎ', '_'),
      AwingWord('chigə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Lá chigə anuə təpǭŋ mbɔ' ŋwunə a chi nǎ əpo' yí pó néŋə yá atsáŋə.",
    english: 'It is a grievous evil for a man to be imprisoned innocently.',
    difficulty: 3,
    words: [
      AwingWord('Lá', '_'),
      AwingWord('chigə', '_'),
      AwingWord('anuə', '_'),
      AwingWord('təpǭŋ', '_'),
      AwingWord('mbɔ\'', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('chi', '_'),
      AwingWord('nǎ', '_'),
      AwingWord('əpo\'', '_'),
      AwingWord('yí', '_'),
      AwingWord('pó', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Apo'ə nkáb lá ŋwunə a fa' nǎ nkáb mbi nchí nǎ njiə.",
    english: 'A slave is he who has enough, yet remains hungry.',
    difficulty: 3,
    words: [
      AwingWord('Apo\'ə', '_'),
      AwingWord('nkáb', '_'),
      AwingWord('lá', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('fa\'', '_'),
      AwingWord('nǎ', '_'),
      AwingWord('nkáb', '_'),
      AwingWord('mbi', '_'),
      AwingWord('nchí', '_'),
      AwingWord('nǎ', '_'),
      AwingWord('njiə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ngǎŋ ngo' nǎ nchí ntǎblə lá ntě ŋgá pó nǎ mbóŋ ətsə'á.",
    english: 'The earlymen were naked because they lacked dresses.',
    difficulty: 3,
    words: [
      AwingWord('Ngǎŋ', '_'),
      AwingWord('ngo\'', '_'),
      AwingWord('nǎ', '_'),
      AwingWord('nchí', '_'),
      AwingWord('ntǎblə', '_'),
      AwingWord('lá', '_'),
      AwingWord('ntě', '_'),
      AwingWord('ŋgá', '_'),
      AwingWord('pó', '_'),
      AwingWord('nǎ', '_'),
      AwingWord('mbóŋ', '_'),
      AwingWord('ətsə\'á', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Máŋgələ á péd yi mbág lā pó nkā pó ká nkyé tso'ə kye ná.",
    english: 'When mangoes are still unripe children still harvest it.',
    difficulty: 3,
    words: [
      AwingWord('Máŋgələ', '_'),
      AwingWord('á', '_'),
      AwingWord('péd', '_'),
      AwingWord('yi', '_'),
      AwingWord('mbág', '_'),
      AwingWord('lā', '_'),
      AwingWord('pó', '_'),
      AwingWord('nkā', '_'),
      AwingWord('pó', '_'),
      AwingWord('ká', '_'),
      AwingWord('nkyé', '_'),
      AwingWord('tso\'ə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Á əghá mbəŋ lā fú məlo'ə á chibə alá' mbíwíŋə.",
    english: 'During the rainy season raffia palm is less expensive in Awing.',
    difficulty: 2,
    words: [
      AwingWord('Á', '_'),
      AwingWord('əghá', '_'),
      AwingWord('mbəŋ', '_'),
      AwingWord('lā', '_'),
      AwingWord('fú', '_'),
      AwingWord('məlo\'ə', '_'),
      AwingWord('á', '_'),
      AwingWord('chibə', '_'),
      AwingWord('alá\'', '_'),
      AwingWord('mbíwíŋə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Á pɔŋə má chib ná ɔtsə' pɔŋə sogə.",
    english: 'It is good to soak dresses before washing.',
    difficulty: 2,
    words: [
      AwingWord('Á', '_'),
      AwingWord('pɔŋə', '_'),
      AwingWord('má', '_'),
      AwingWord('chib', '_'),
      AwingWord('ná', '_'),
      AwingWord('ɔtsə\'', '_'),
      AwingWord('pɔŋə', '_'),
      AwingWord('sogə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A kē pɔŋə má chibkə ná ajumə ŋwu ntê ńgá azó pɔŋ pɔ.",
    english: 'It is not good to devalue somebody\'s property because you don\'t have yours.',
    difficulty: 3,
    words: [
      AwingWord('A', '_'),
      AwingWord('kē', '_'),
      AwingWord('pɔŋə', '_'),
      AwingWord('má', '_'),
      AwingWord('chibkə', '_'),
      AwingWord('ná', '_'),
      AwingWord('ajumə', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('ntê', '_'),
      AwingWord('ńgá', '_'),
      AwingWord('azó', '_'),
      AwingWord('pɔŋ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pá chi'ə sán áseŋ ndé áwá lā á ŋwa'ə.",
    english: 'When sand is sifted before use for cementing, the cemented house will look smooth.',
    difficulty: 2,
    words: [
      AwingWord('Pá', '_'),
      AwingWord('chi\'ə', '_'),
      AwingWord('sán', '_'),
      AwingWord('áseŋ', '_'),
      AwingWord('ndé', '_'),
      AwingWord('áwá', '_'),
      AwingWord('lā', '_'),
      AwingWord('á', '_'),
      AwingWord('ŋwa\'ə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Afúə atúənsénə á chî lā pá chí'ə lā chí' ná á mbiə atúə.",
    english: 'Medicine for frontal headache is rubbed on the forehead.',
    difficulty: 3,
    words: [
      AwingWord('Afúə', '_'),
      AwingWord('atúənsénə', '_'),
      AwingWord('á', '_'),
      AwingWord('chî', '_'),
      AwingWord('lā', '_'),
      AwingWord('pá', '_'),
      AwingWord('chí\'ə', '_'),
      AwingWord('lā', '_'),
      AwingWord('chí\'', '_'),
      AwingWord('ná', '_'),
      AwingWord('á', '_'),
      AwingWord('mbiə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbɔ' ŋwu mbyáŋnə a chîa məngyé zó' pá fóŋə yí lā ná nkweŋə.",
    english: 'If a man does not marry, he is called a bachelor.',
    difficulty: 3,
    words: [
      AwingWord('Mbɔ\'', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('mbyáŋnə', '_'),
      AwingWord('a', '_'),
      AwingWord('chîa', '_'),
      AwingWord('məngyé', '_'),
      AwingWord('zó\'', '_'),
      AwingWord('pá', '_'),
      AwingWord('fóŋə', '_'),
      AwingWord('yí', '_'),
      AwingWord('lā', '_'),
      AwingWord('ná', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbeláló' ə chîa lā á mém məndé má pəŋə.",
    english: 'Bororo people live in thatched houses.',
    difficulty: 2,
    words: [
      AwingWord('Mbeláló\'', '_'),
      AwingWord('ə', '_'),
      AwingWord('chîa', '_'),
      AwingWord('lā', '_'),
      AwingWord('á', '_'),
      AwingWord('mém', '_'),
      AwingWord('məndé', '_'),
      AwingWord('má', '_'),
      AwingWord('pəŋə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Á pɔŋ ŋgɔ́ ŋwunɔ tsóokɔ mbí əjí ńchĩa ɔsɛ́ á mǎm pɔtɔ́ pĩa.",
    english: 'It is good for a man to humble himself and be low amongst his fathers.',
    difficulty: 3,
    words: [
      AwingWord('Á', '_'),
      AwingWord('pɔŋ', '_'),
      AwingWord('ŋgɔ', '_'),
      AwingWord('ŋwunɔ', '_'),
      AwingWord('tsóokɔ', '_'),
      AwingWord('mbí', '_'),
      AwingWord('əjí', '_'),
      AwingWord('ńchĩa', '_'),
      AwingWord('ɔsɛ', '_'),
      AwingWord('á', '_'),
      AwingWord('mǎm', '_'),
      AwingWord('pɔtɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Móonɔ á chĩa mbô.",
    english: 'The baby is expected soon.',
    difficulty: 1,
    words: [
      AwingWord('Móonɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('chĩa', '_'),
      AwingWord('mbô', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Lə chikə mbəkə a məm ndə zəənə?",
    english: 'Who are the people staying in this house?',
    difficulty: 2,
    words: [
      AwingWord('Lə', '_'),
      AwingWord('chikə', '_'),
      AwingWord('mbəkə', '_'),
      AwingWord('a', '_'),
      AwingWord('məm', '_'),
      AwingWord('ndə', '_'),
      AwingWord('zəənə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "ɔ a chúbnɔ lɔ́ ńtsɛ́ebɔ ali'ɔ́ ɔnɔ pɔ́ kɛ́ zɔ́' pɔ́.",
    english: 'When an individual is less important people tend not to listen to him.',
    difficulty: 3,
    words: [
      AwingWord('ɔ', '_'),
      AwingWord('a', '_'),
      AwingWord('chúbnɔ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('ńtsɛ', '_'),
      AwingWord('ebɔ', '_'),
      AwingWord('ali\'ɔ', '_'),
      AwingWord('ɔnɔ', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('kɛ', '_'),
      AwingWord('zɔ', '_'),
      AwingWord('\'', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbɩ́wɩŋ ɔ́ zá ńchú'ɔ achú' lɔ́ alɛ́ alá'ɔ.",
    english: 'Awing people usually pound achu on resting days.',
    difficulty: 2,
    words: [
      AwingWord('Mbɩ', '_'),
      AwingWord('wɩŋ', '_'),
      AwingWord('ɔ', '_'),
      AwingWord('zá', '_'),
      AwingWord('ńchú\'ɔ', '_'),
      AwingWord('achú\'', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('alɛ', '_'),
      AwingWord('alá\'ɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Tú'ɔ á ɔ́sɛn lɔ́ pɔ́ chú' nkya'ɔ.",
    english: 'When it is night, lights are put on.',
    difficulty: 2,
    words: [
      AwingWord('Tú\'ɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('ɔ', '_'),
      AwingWord('sɛn', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('chú\'', '_'),
      AwingWord('nkya\'ɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbɔŋ tɔ́ ńdɔ́ lɔ́ kɔ́yɛ́ ɲwunɔ alá'ɔ á tí'ɔ ńchú'tɔ atɔ́tsɔ́' nɔ́ mɔ́ko mɔ́obɔ.",
    english: 'When it is raining rural children keep smashing mud with their feet.',
    difficulty: 3,
    words: [
      AwingWord('Mbɔŋ', '_'),
      AwingWord('tɔ', '_'),
      AwingWord('ńdɔ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('kɔ', '_'),
      AwingWord('yɛ', '_'),
      AwingWord('ɲwunɔ', '_'),
      AwingWord('alá\'ɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('tí\'ɔ', '_'),
      AwingWord('ńchú\'tɔ', '_'),
      AwingWord('atɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mɔ́ chwáakɔ nɔ́ anuɔ atɔ́m mɔ́ chí lɔ́ ńtyantɔ́.",
    english: 'It is always difficult to begin everything.',
    difficulty: 2,
    words: [
      AwingWord('Mɔ', '_'),
      AwingWord('chwáakɔ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('anuɔ', '_'),
      AwingWord('atɔ', '_'),
      AwingWord('m', '_'),
      AwingWord('mɔ', '_'),
      AwingWord('chí', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('ńtyantɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mɔ́ chwáakɔ nɔ́ nkyeetɔ mɔ́ tyantɔ́.",
    english: 'It is difficult to start an association.',
    difficulty: 2,
    words: [
      AwingWord('Mɔ', '_'),
      AwingWord('chwáakɔ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('nkyeetɔ', '_'),
      AwingWord('mɔ', '_'),
      AwingWord('tyantɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Á tyantə mé chwa nó afa' əzəənə alá' áfənə.",
    english: 'It is difficult to find a job in this country.',
    difficulty: 2,
    words: [
      AwingWord('Á', '_'),
      AwingWord('tyantə', '_'),
      AwingWord('mé', '_'),
      AwingWord('chwa', '_'),
      AwingWord('nó', '_'),
      AwingWord('afa\'', '_'),
      AwingWord('əzəənə', '_'),
      AwingWord('alá\'', '_'),
      AwingWord('áfənə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Kwuneemə á tá ńchwaalə ndú ló á zá ńkyéŋə.",
    english: 'When a pig is ready for crossing it cries often V.',
    difficulty: 2,
    words: [
      AwingWord('Kwuneemə', '_'),
      AwingWord('á', '_'),
      AwingWord('tá', '_'),
      AwingWord('ńchwaalə', '_'),
      AwingWord('ndú', '_'),
      AwingWord('ló', '_'),
      AwingWord('á', '_'),
      AwingWord('zá', '_'),
      AwingWord('ńkyéŋə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pó chìa ntso ló ńchwáanə ŋwu ló ándó pó chwáanə na ló.",
    english: 'In war human beings are cut with such cruelty as if they were beasts.',
    difficulty: 3,
    words: [
      AwingWord('Pó', '_'),
      AwingWord('chìa', '_'),
      AwingWord('ntso', '_'),
      AwingWord('ló', '_'),
      AwingWord('ńchwáanə', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('ló', '_'),
      AwingWord('ándó', '_'),
      AwingWord('pó', '_'),
      AwingWord('chwáanə', '_'),
      AwingWord('na', '_'),
      AwingWord('ló', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mó Əsə a kə kwú ló mé chwádkə nó ŋwu məsəŋ ntsəmə.",
    english: 'The son of God died in order to save all human beings.',
    difficulty: 3,
    words: [
      AwingWord('Mó', '_'),
      AwingWord('Əsə', '_'),
      AwingWord('a', '_'),
      AwingWord('kə', '_'),
      AwingWord('kwú', '_'),
      AwingWord('ló', '_'),
      AwingWord('mé', '_'),
      AwingWord('chwádkə', '_'),
      AwingWord('nó', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('məsəŋ', '_'),
      AwingWord('ntsəmə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Chwántə nkīə á chìa əlá' pətsí mbə ló əsə.",
    english: 'In some villages a stream is a god.',
    difficulty: 2,
    words: [
      AwingWord('Chwántə', '_'),
      AwingWord('nkīə', '_'),
      AwingWord('á', '_'),
      AwingWord('chìa', '_'),
      AwingWord('əlá\'', '_'),
      AwingWord('pətsí', '_'),
      AwingWord('mbə', '_'),
      AwingWord('ló', '_'),
      AwingWord('əsə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbə' ŋwunə tá ńdzé'ə á mé kó nó atúə a shib ńchwá'tə.",
    english: 'A learner in the field of hair cuts always shaves improperly.',
    difficulty: 3,
    words: [
      AwingWord('Mbə\'', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('tá', '_'),
      AwingWord('ńdzé\'ə', '_'),
      AwingWord('á', '_'),
      AwingWord('mé', '_'),
      AwingWord('kó', '_'),
      AwingWord('nó', '_'),
      AwingWord('atúə', '_'),
      AwingWord('a', '_'),
      AwingWord('shib', '_'),
      AwingWord('ńchwá\'tə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbə' ló chwéŋtə tsə'ə akəkóg ńchwéŋtə nkīə á məm kyíbə.",
    english: 'Only an imbecile can pour water in a basket.',
    difficulty: 2,
    words: [
      AwingWord('Mbə\'', '_'),
      AwingWord('ló', '_'),
      AwingWord('chwéŋtə', '_'),
      AwingWord('tsə\'ə', '_'),
      AwingWord('akəkóg', '_'),
      AwingWord('ńchwéŋtə', '_'),
      AwingWord('nkīə', '_'),
      AwingWord('á', '_'),
      AwingWord('məm', '_'),
      AwingWord('kyíbə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Alɔ'ɔ ɔ tɔ ngɛnɔ ɔ ntso lɔ ɔ peg nchwig ɔshĩ'nɔ ɔɔ'ɔ.",
    english: 'Before a nation goes to war it has to spy properly first.',
    difficulty: 3,
    words: [
      AwingWord('Alɔ\'ɔ', '_'),
      AwingWord('ɔ', '_'),
      AwingWord('tɔ', '_'),
      AwingWord('ngɛnɔ', '_'),
      AwingWord('ɔ', '_'),
      AwingWord('ntso', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('ɔ', '_'),
      AwingWord('peg', '_'),
      AwingWord('nchwig', '_'),
      AwingWord('ɔshĩ\'nɔ', '_'),
      AwingWord('ɔɔ\'ɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mɔ pɔ' mɔ ɔyĩɔ a kɛ nɔ yĩ chwigɔ pɔ a kɛ ɔshĩ'nɔ kwɛŋɔ pɔ.",
    english: 'A child that does not enjoy the embrace of the mother doesn\'t have proper growth.',
    difficulty: 3,
    words: [
      AwingWord('Mɔ', '_'),
      AwingWord('pɔ\'', '_'),
      AwingWord('mɔ', '_'),
      AwingWord('ɔyĩɔ', '_'),
      AwingWord('a', '_'),
      AwingWord('kɛ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('yĩ', '_'),
      AwingWord('chwigɔ', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('a', '_'),
      AwingWord('kɛ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Nganɔŋwa'lɔ ɔ ɔ nchwĩ'nɔ ɔghɔb lɔ nɔ tɔ'ɔ atɔgɔ ndɛ.",
    english: 'Students usually get themselves tight together in a single room.',
    difficulty: 2,
    words: [
      AwingWord('Nganɔŋwa\'lɔ', '_'),
      AwingWord('ɔ', '_'),
      AwingWord('ɔ', '_'),
      AwingWord('nchwĩ\'nɔ', '_'),
      AwingWord('ɔghɔb', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('tɔ\'ɔ', '_'),
      AwingWord('atɔgɔ', '_'),
      AwingWord('ndɛ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Lɔmɔsɔ yĩ ntsɔg nɔ ɔ ghelɔ ɔwunɔ chwĩŋɔ.",
    english: 'Limes makes one to grow thin.',
    difficulty: 2,
    words: [
      AwingWord('Lɔmɔsɔ', '_'),
      AwingWord('yĩ', '_'),
      AwingWord('ntsɔg', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('ɔ', '_'),
      AwingWord('ghelɔ', '_'),
      AwingWord('ɔwunɔ', '_'),
      AwingWord('chwĩŋɔ', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbɔ' ŋwunə a náanə ndəsə kətaŋə a dɔtə atsə'ə yá.",
    english: 'If one sits on bear ground he dirties his dresses.',
    difficulty: 2,
    words: [
      AwingWord('Mbɔ\'', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('náanə', '_'),
      AwingWord('ndəsə', '_'),
      AwingWord('kətaŋə', '_'),
      AwingWord('a', '_'),
      AwingWord('dɔtə', '_'),
      AwingWord('atsə\'ə', '_'),
      AwingWord('yá', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pi pə sónə ngə əfag ndú pá' ə ghen nə nəpó ə səəkə.",
    english: 'The road to heaven is slippery, so do people say.',
    difficulty: 3,
    words: [
      AwingWord('Pi', '_'),
      AwingWord('pə', '_'),
      AwingWord('sónə', '_'),
      AwingWord('ngə', '_'),
      AwingWord('əfag', '_'),
      AwingWord('ndú', '_'),
      AwingWord('pá\'', '_'),
      AwingWord('ə', '_'),
      AwingWord('ghen', '_'),
      AwingWord('nə', '_'),
      AwingWord('nəpó', '_'),
      AwingWord('ə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mətú mə Aflika lə chigə pəfi pə ngəŋə.",
    english: 'African leaders are really traitors.',
    difficulty: 2,
    words: [
      AwingWord('Mətú', '_'),
      AwingWord('mə', '_'),
      AwingWord('Aflika', '_'),
      AwingWord('lə', '_'),
      AwingWord('chigə', '_'),
      AwingWord('pəfi', '_'),
      AwingWord('pə', '_'),
      AwingWord('ngəŋə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Məjī mə kó'ə á əfó' nki ńtse əli' ətsəmə.",
    english: 'Food grows on dry riverbed than other places.',
    difficulty: 2,
    words: [
      AwingWord('Məjī', '_'),
      AwingWord('mə', '_'),
      AwingWord('kó\'ə', '_'),
      AwingWord('á', '_'),
      AwingWord('əfó\'', '_'),
      AwingWord('nki', '_'),
      AwingWord('ńtse', '_'),
      AwingWord('əli\'', '_'),
      AwingWord('ətsəmə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pi pətsə pō sōŋə ńgə əfooghəəmə á pyáb nə Mbīwīŋə.",
    english: 'Some people believe that it is Lake Awing which protects Awing people.',
    difficulty: 2,
    words: [
      AwingWord('Pi', '_'),
      AwingWord('pətsə', '_'),
      AwingWord('pō', '_'),
      AwingWord('sōŋə', '_'),
      AwingWord('ńgə', '_'),
      AwingWord('əfooghəəmə', '_'),
      AwingWord('á', '_'),
      AwingWord('pyáb', '_'),
      AwingWord('nə', '_'),
      AwingWord('Mbīwīŋə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "O yī yī lə əghâ akə?",
    english: 'When will you come?',
    difficulty: 2,
    words: [
      AwingWord('O', '_'),
      AwingWord('yī', '_'),
      AwingWord('yī', '_'),
      AwingWord('lə', '_'),
      AwingWord('əghâ', '_'),
      AwingWord('akə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pi pə ní nə pō kə əghâ məgha kəŋ nńtə ńgə əli' ə nwā tšshunə.",
    english: 'Most people do not like the rainy season because it is often too cold.',
    difficulty: 3,
    words: [
      AwingWord('Pi', '_'),
      AwingWord('pə', '_'),
      AwingWord('ní', '_'),
      AwingWord('nə', '_'),
      AwingWord('pō', '_'),
      AwingWord('kə', '_'),
      AwingWord('əghâ', '_'),
      AwingWord('məgha', '_'),
      AwingWord('kəŋ', '_'),
      AwingWord('nńtə', '_'),
      AwingWord('ńgə', '_'),
      AwingWord('əli\'', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbɔ' ŋwunə sɔŋə anuə á ko'nə, pə sɔŋ ŋgə, \"á ə́lə́ələ\".",
    english: 'If somebody says something that is right, we answer yes or it is so.',
    difficulty: 2,
    words: [
      AwingWord('Mbɔ\'', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('sɔŋə', '_'),
      AwingWord('anuə', '_'),
      AwingWord('á', '_'),
      AwingWord('ko\'nə', '_'),
      AwingWord('pə', '_'),
      AwingWord('sɔŋ', '_'),
      AwingWord('ŋgə', '_'),
      AwingWord('á', '_'),
      AwingWord('ə', '_'),
      AwingWord('lə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pəzə́ pə́ mə́ ɲkɔŋ əli' pipə́ ŋwa' nə́.",
    english: 'Thieves do not like daylight.',
    difficulty: 2,
    words: [
      AwingWord('Pəzə', '_'),
      AwingWord('pə', '_'),
      AwingWord('mə', '_'),
      AwingWord('ɲkɔŋ', '_'),
      AwingWord('əli\'', '_'),
      AwingWord('pipə', '_'),
      AwingWord('ŋwa\'', '_'),
      AwingWord('nə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Chigə ngaŋə afa' ntsəmə a ghenə lə əsa'mənumə.",
    english: 'Every serious worker leaves for work at sunrise.',
    difficulty: 2,
    words: [
      AwingWord('Chigə', '_'),
      AwingWord('ngaŋə', '_'),
      AwingWord('afa\'', '_'),
      AwingWord('ntsəmə', '_'),
      AwingWord('a', '_'),
      AwingWord('ghenə', '_'),
      AwingWord('lə', '_'),
      AwingWord('əsa\'mənumə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Akôfo a kôd ndzô əza t' mbêla.",
    english: 'Akofo has eaten beans and mine is left.',
    difficulty: 2,
    words: [
      AwingWord('Akôfo', '_'),
      AwingWord('a', '_'),
      AwingWord('kôd', '_'),
      AwingWord('ndzô', '_'),
      AwingWord('əza', '_'),
      AwingWord('t\'', '_'),
      AwingWord('mbêla', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ndzô əzo təəmə á məmə akəŋə.",
    english: 'Your beans is in the pan.',
    difficulty: 2,
    words: [
      AwingWord('Ndzô', '_'),
      AwingWord('əzo', '_'),
      AwingWord('təəmə', '_'),
      AwingWord('á', '_'),
      AwingWord('məmə', '_'),
      AwingWord('akəŋə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ngwub əzô əfô.",
    english: 'Where is your shoes.',
    difficulty: 1,
    words: [
      AwingWord('Ngwub', '_'),
      AwingWord('əzô', '_'),
      AwingWord('əfô', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mô məngyē ä fablə nə a kē ndú zəənə pô.",
    english: 'A girl who is fastidious hardly finds a husband.',
    difficulty: 2,
    words: [
      AwingWord('Mô', '_'),
      AwingWord('məngyē', '_'),
      AwingWord('ä', '_'),
      AwingWord('fablə', '_'),
      AwingWord('nə', '_'),
      AwingWord('a', '_'),
      AwingWord('kē', '_'),
      AwingWord('ndú', '_'),
      AwingWord('zəənə', '_'),
      AwingWord('pô', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ngəb kyé'tə pə lə ə chî ngab teelə ki nəkwa əfag pónə.",
    english: 'When a fowl hatches, it weans the chickens in three or four weeks.',
    difficulty: 3,
    words: [
      AwingWord('Ngəb', '_'),
      AwingWord('kyé\'tə', '_'),
      AwingWord('pə', '_'),
      AwingWord('lə', '_'),
      AwingWord('ə', '_'),
      AwingWord('chî', '_'),
      AwingWord('ngab', '_'),
      AwingWord('teelə', '_'),
      AwingWord('ki', '_'),
      AwingWord('nəkwa', '_'),
      AwingWord('əfag', '_'),
      AwingWord('pónə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mɔjī mə tūg nə məghəd tōshū mə ghelə ɣwunə fāŋə.",
    english: 'Food that contains much oil makes one to grow fat.',
    difficulty: 2,
    words: [
      AwingWord('Mɔjī', '_'),
      AwingWord('mə', '_'),
      AwingWord('tūg', '_'),
      AwingWord('nə', '_'),
      AwingWord('məghəd', '_'),
      AwingWord('tōshū', '_'),
      AwingWord('mə', '_'),
      AwingWord('ghelə', '_'),
      AwingWord('ɣwunə', '_'),
      AwingWord('fāŋə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ndɔŋə a fa'tə mə afa' ló a chū'ə mə fē nə ngə'ə.",
    english: 'When a lazy person works a little, he starts complaining.',
    difficulty: 3,
    words: [
      AwingWord('Ndɔŋə', '_'),
      AwingWord('a', '_'),
      AwingWord('fa\'tə', '_'),
      AwingWord('mə', '_'),
      AwingWord('afa\'', '_'),
      AwingWord('ló', '_'),
      AwingWord('a', '_'),
      AwingWord('chū\'ə', '_'),
      AwingWord('mə', '_'),
      AwingWord('fē', '_'),
      AwingWord('nə', '_'),
      AwingWord('ngə\'ə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pə kwūlə akeelə kwūna ló pə fēelə zīd nə kəyə əkəm əpūmə.",
    english: 'When people make a pig sty, they fasten it with little sticks.',
    difficulty: 3,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('kwūlə', '_'),
      AwingWord('akeelə', '_'),
      AwingWord('kwūna', '_'),
      AwingWord('ló', '_'),
      AwingWord('pə', '_'),
      AwingWord('fēelə', '_'),
      AwingWord('zīd', '_'),
      AwingWord('nə', '_'),
      AwingWord('kəyə', '_'),
      AwingWord('əkəm', '_'),
      AwingWord('əpūmə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Achū'ə á chī ló pə feŋə ló feŋ nə mbɔŋə ta'ə.",
    english: 'Achu is often unwrapped before boiling a hoe for soap.',
    difficulty: 3,
    words: [
      AwingWord('Achū\'ə', '_'),
      AwingWord('á', '_'),
      AwingWord('chī', '_'),
      AwingWord('ló', '_'),
      AwingWord('pə', '_'),
      AwingWord('feŋə', '_'),
      AwingWord('ló', '_'),
      AwingWord('feŋ', '_'),
      AwingWord('nə', '_'),
      AwingWord('mbɔŋə', '_'),
      AwingWord('ta\'ə', '_'),
    ],
  ),

  // DICT batch 3 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Anuə afeŋə ndē á tyantə á əghā məghā ló ntə ngə pəŋ kē ní pə.",
    english: 'It is much difficult to roof a house in the rainy season because there is not enough grass.',
    difficulty: 3,
    words: [
      AwingWord('Anuə', '_'),
      AwingWord('afeŋə', '_'),
      AwingWord('ndē', '_'),
      AwingWord('á', '_'),
      AwingWord('tyantə', '_'),
      AwingWord('á', '_'),
      AwingWord('əghā', '_'),
      AwingWord('məghā', '_'),
      AwingWord('ló', '_'),
      AwingWord('ntə', '_'),
      AwingWord('ngə', '_'),
      AwingWord('pəŋ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  // AwingSentence(
  // awing: "Mbɔ' tɔ tɔŋə anu o peg fɛ akəmə atsáb ntɛ.",
  // english: 'If you want to say anything, first give an introduction.',
  // difficulty: 2,
  // words: [
  // AwingWord('Mbɔ\'', '_'),
  // AwingWord('tɔ', '_'),
  // AwingWord('tɔŋə', '_'),
  // AwingWord('anu', '_'),
  // AwingWord('o', '_'),
  // AwingWord('peg', '_'),
  // AwingWord('fɛ', '_'),
  // AwingWord('akəmə', '_'),
  // AwingWord('atsáb', '_'),
  // AwingWord('ntɛ', '_'),
  // ],
  // ),  // REMOVED Session 66u similar-spelling: same English as the block at line 802 (Mbɔ' tɔ tɔŋə anu o peg fɛ akəm)

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mɔjī mə fēŋ ló pə jī mə mə mbɔŋ əshī'nə.",
    english: 'Food which is cold does not have a good flavour.',
    difficulty: 2,
    words: [
      AwingWord('Mɔjī', '_'),
      AwingWord('mə', '_'),
      AwingWord('fēŋ', '_'),
      AwingWord('ló', '_'),
      AwingWord('pə', '_'),
      AwingWord('jī', '_'),
      AwingWord('mə', '_'),
      AwingWord('mə', '_'),
      AwingWord('mbɔŋ', '_'),
      AwingWord('əshī\'nə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Á əghā məghā ló əpū fēŋtə.",
    english: 'During the rainy season plants are fresh.',
    difficulty: 2,
    words: [
      AwingWord('Á', '_'),
      AwingWord('əghā', '_'),
      AwingWord('məghā', '_'),
      AwingWord('ló', '_'),
      AwingWord('əpū', '_'),
      AwingWord('fēŋtə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pə əfē atsāŋ nə ɣwu ló pá' a ghed nə anuə təpɔŋə.",
    english: 'A person is only punished when he does something wrong.',
    difficulty: 3,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('əfē', '_'),
      AwingWord('atsāŋ', '_'),
      AwingWord('nə', '_'),
      AwingWord('ɣwu', '_'),
      AwingWord('ló', '_'),
      AwingWord('pá\'', '_'),
      AwingWord('a', '_'),
      AwingWord('ghed', '_'),
      AwingWord('nə', '_'),
      AwingWord('anuə', '_'),
      AwingWord('təpɔŋə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbɔ' əsə a kɔŋə ɣwunə a fē mbwōdnə nə yə.",
    english: 'If God is pleased with somebody, he gives him peace.',
    difficulty: 2,
    words: [
      AwingWord('Mbɔ\'', '_'),
      AwingWord('əsə', '_'),
      AwingWord('a', '_'),
      AwingWord('kɔŋə', '_'),
      AwingWord('ɣwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('fē', '_'),
      AwingWord('mbwōdnə', '_'),
      AwingWord('nə', '_'),
      AwingWord('yə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Á pɔŋ ŋgɔ́ ŋwu ntsɔmɔ a fɛ̀ ntɔ̀gɔ́ nɔ́ pɔ́ pɔ́.",
    english: 'It is proper for every man to counsel his siblings.',
    difficulty: 3,
    words: [
      AwingWord('Á', '_'),
      AwingWord('pɔŋ', '_'),
      AwingWord('ŋgɔ', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('ntsɔmɔ', '_'),
      AwingWord('a', '_'),
      AwingWord('fɛ', '_'),
      AwingWord('ntɔ', '_'),
      AwingWord('gɔ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('pɔ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbɔ' ŋwɔŋɔ a fɛ́lɔ á chɔ́sɔ a pɔ́ ŋgɔ́ a kɔ ɔ̀sɛ́.",
    english: 'If a person leaves the church it means he has abandoned God.',
    difficulty: 3,
    words: [
      AwingWord('Mbɔ\'', '_'),
      AwingWord('ŋwɔŋɔ', '_'),
      AwingWord('a', '_'),
      AwingWord('fɛ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('chɔ', '_'),
      AwingWord('sɔ', '_'),
      AwingWord('a', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('ŋgɔ', '_'),
      AwingWord('a', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbelɔlɔ́ á fɛ́lɔ ali' lɔ́ pɔ́' nɔyeŋɔ́ mɔna ɔghoobɔ́ á mɛ̀e nɔ́.",
    english: 'Bororo people migrate when there is no grass for their cattle.',
    difficulty: 3,
    words: [
      AwingWord('Mbelɔlɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('fɛ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('ali\'', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('\'', '_'),
      AwingWord('nɔyeŋɔ', '_'),
      AwingWord('mɔna', '_'),
      AwingWord('ɔghoobɔ', '_'),
      AwingWord('á', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mɔngyɛ́ a fɛ́lɔ ndzɔ'ɔ́ lɔ́ a chibɔ́.",
    english: 'When a woman divorces she loses her charm.',
    difficulty: 2,
    words: [
      AwingWord('Mɔngyɛ', '_'),
      AwingWord('a', '_'),
      AwingWord('fɛ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('ndzɔ\'ɔ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('a', '_'),
      AwingWord('chibɔ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Fɔ̀gɔ́ á kwɔ́nɔ lɔ́ nɔ́ akɔfɛ́ pɔ́' pɔ́ kɛ́ nɔ́ pɔ́m pɔ́.",
    english: 'Blight attacks coffee that is not sprayed with insecticide.',
    difficulty: 3,
    words: [
      AwingWord('Fɔ', '_'),
      AwingWord('gɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('kwɔ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('akɔfɛ', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('\'', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('kɛ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mɔkɔ́lɔ́ a kɔŋɔ́ mɔ́ pɔ́ nɔ́ fɔ̀lɔ́wa á ngya'ɔ́ yɔ́.",
    english: 'Whites like planting flowers in their compounds.',
    difficulty: 2,
    words: [
      AwingWord('Mɔkɔ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('a', '_'),
      AwingWord('kɔŋɔ', '_'),
      AwingWord('mɔ', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('fɔ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('wa', '_'),
      AwingWord('á', '_'),
      AwingWord('ngya\'ɔ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ngɔ́ŋ Nɔ́wɔ́lɔ́ tɔ̀ɛ́bɔ́ lɔ́ Fɔ̀lɛ́nchɔ.",
    english: 'People who live in Douala speak French.',
    difficulty: 1,
    words: [
      AwingWord('Ngɔ', '_'),
      AwingWord('ŋ', '_'),
      AwingWord('Nɔ', '_'),
      AwingWord('wɔ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('tɔ', '_'),
      AwingWord('ɛ', '_'),
      AwingWord('bɔ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('Fɔ', '_'),
      AwingWord('lɛ', '_'),
      AwingWord('nchɔ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Nɔ́' pɔ́' ɔ́ pɔ́g nɔ́ lɔ́ yɔ́ pɔ́' fɔ̀m nɔ́ mbɔ́ á mɔ́m ɔ́wɔ́.",
    english: 'Soap that gets bad is that which fingers have been deeped into it.',
    difficulty: 3,
    words: [
      AwingWord('Nɔ', '_'),
      AwingWord('\'', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('\'', '_'),
      AwingWord('ɔ', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('g', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('yɔ', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('\'', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pɔ́ chɔ́ á ntɔ́ lɔ́ pɔ́ pɔ́ fɔ́mkɔ ngaŋkɔ́pa ɔzɔ́obɔ́ á nkɔ́.",
    english: 'In war people drown their enemies in water as a way of punishing them.',
    difficulty: 3,
    words: [
      AwingWord('Pɔ', '_'),
      AwingWord('chɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('ntɔ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('fɔ', '_'),
      AwingWord('mkɔ', '_'),
      AwingWord('ngaŋkɔ', '_'),
      AwingWord('pa', '_'),
      AwingWord('ɔzɔ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Lə ghelə akə ɲwunə a fəmnə a nkyi, əshü ə pə ɲkɛ fəmnə pə.",
    english: 'Why is it that humans drown under water, while fish do not.',
    difficulty: 3,
    words: [
      AwingWord('Lə', '_'),
      AwingWord('ghelə', '_'),
      AwingWord('akə', '_'),
      AwingWord('ɲwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('fəmnə', '_'),
      AwingWord('a', '_'),
      AwingWord('nkyi', '_'),
      AwingWord('əshü', '_'),
      AwingWord('ə', '_'),
      AwingWord('pə', '_'),
      AwingWord('ɲkɛ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbəto fi'ə akwʊə ɲwu ɲbɔgə məsɛ.",
    english: 'Baminnyam people unearth a corpse for fear of witchcraft.',
    difficulty: 2,
    words: [
      AwingWord('Mbəto', '_'),
      AwingWord('fi\'ə', '_'),
      AwingWord('akwʊə', '_'),
      AwingWord('ɲwu', '_'),
      AwingWord('ɲbɔgə', '_'),
      AwingWord('məsɛ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A jʊnə mʊto yɪ fiə.",
    english: 'He has bought a new car.',
    difficulty: 1,
    words: [
      AwingWord('A', '_'),
      AwingWord('jʊnə', '_'),
      AwingWord('mʊto', '_'),
      AwingWord('yɪ', '_'),
      AwingWord('fiə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mə ɲtsəmə a zá fiə mə yə.",
    english: 'Every child mostly resembles the mother.',
    difficulty: 2,
    words: [
      AwingWord('Mə', '_'),
      AwingWord('ɲtsəmə', '_'),
      AwingWord('a', '_'),
      AwingWord('zá', '_'),
      AwingWord('fiə', '_'),
      AwingWord('mə', '_'),
      AwingWord('yə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ndəɲə a fə'ə yə afə' kəkəɲ lə a filə ajʊmə afə'ə.",
    english: 'A lazy person always blames his tool for a job badly done.',
    difficulty: 3,
    words: [
      AwingWord('Ndəɲə', '_'),
      AwingWord('a', '_'),
      AwingWord('fə\'ə', '_'),
      AwingWord('yə', '_'),
      AwingWord('afə\'', '_'),
      AwingWord('kəkəɲ', '_'),
      AwingWord('lə', '_'),
      AwingWord('a', '_'),
      AwingWord('filə', '_'),
      AwingWord('ajʊmə', '_'),
      AwingWord('afə\'ə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mənu mətsi mə chĩ áwə pá' mbo' ŋwunə ghelə mid pó fidkə yə məmə alá'ə.",
    english: 'There are certain crimes that are punishable by expelling the individual from the village.',
    difficulty: 3,
    words: [
      AwingWord('Mənu', '_'),
      AwingWord('mətsi', '_'),
      AwingWord('mə', '_'),
      AwingWord('chĩ', '_'),
      AwingWord('áwə', '_'),
      AwingWord('pá\'', '_'),
      AwingWord('mbo\'', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('ghelə', '_'),
      AwingWord('mid', '_'),
      AwingWord('pó', '_'),
      AwingWord('fidkə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Məjĩ mĩmə fĩ mə kə' lā mə fi' pəənə.",
    english: 'New crops usually cause a running stomach.',
    difficulty: 2,
    words: [
      AwingWord('Məjĩ', '_'),
      AwingWord('mĩmə', '_'),
      AwingWord('fĩ', '_'),
      AwingWord('mə', '_'),
      AwingWord('kə\'', '_'),
      AwingWord('lā', '_'),
      AwingWord('mə', '_'),
      AwingWord('fi\'', '_'),
      AwingWord('pəənə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Nganəŋwa'lə pó pó nə pəzə pó figə pətā pəb ńkwə nkéebə.",
    english: 'Some bad students deceive their peasant parents to get money.',
    difficulty: 3,
    words: [
      AwingWord('Nganəŋwa\'lə', '_'),
      AwingWord('pó', '_'),
      AwingWord('pó', '_'),
      AwingWord('nə', '_'),
      AwingWord('pəzə', '_'),
      AwingWord('pó', '_'),
      AwingWord('figə', '_'),
      AwingWord('pətā', '_'),
      AwingWord('pəb', '_'),
      AwingWord('ńkwə', '_'),
      AwingWord('nkéebə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pi pətsə pó figtə pó nkə ntē ngə pó kə ənu jĩ pō.",
    english: 'Some people deceive children because they are ignorant.',
    difficulty: 3,
    words: [
      AwingWord('Pi', '_'),
      AwingWord('pətsə', '_'),
      AwingWord('pó', '_'),
      AwingWord('figtə', '_'),
      AwingWord('pó', '_'),
      AwingWord('nkə', '_'),
      AwingWord('ntē', '_'),
      AwingWord('ngə', '_'),
      AwingWord('pó', '_'),
      AwingWord('kə', '_'),
      AwingWord('ənu', '_'),
      AwingWord('jĩ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Kə figtə pəənə.",
    english: 'Do not deceive people.',
    difficulty: 1,
    words: [
      AwingWord('Kə', '_'),
      AwingWord('figtə', '_'),
      AwingWord('pəənə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ncha'təsə a fógə ŋwunə á məm ngə'ə.",
    english: 'A spiritual healer deliever somebody from trouble.',
    difficulty: 2,
    words: [
      AwingWord('Ncha\'təsə', '_'),
      AwingWord('a', '_'),
      AwingWord('fógə', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('á', '_'),
      AwingWord('məm', '_'),
      AwingWord('ngə\'ə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pó kə təpəŋ lōgə áfógə təpəŋ áwə pō.",
    english: 'Evil cannot be used to ward off evil.',
    difficulty: 2,
    words: [
      AwingWord('Pó', '_'),
      AwingWord('kə', '_'),
      AwingWord('təpəŋ', '_'),
      AwingWord('lōgə', '_'),
      AwingWord('áfógə', '_'),
      AwingWord('təpəŋ', '_'),
      AwingWord('áwə', '_'),
      AwingWord('pō', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbəŋ ə lō lā əpū foŋə afoona.",
    english: 'When it rains, crops flourish in the farm.',
    difficulty: 2,
    words: [
      AwingWord('Mbəŋ', '_'),
      AwingWord('ə', '_'),
      AwingWord('lō', '_'),
      AwingWord('lā', '_'),
      AwingWord('əpū', '_'),
      AwingWord('foŋə', '_'),
      AwingWord('afoona', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Fu' mbéle** á zá ńchiə ló á mám mbéd má neemə.",
    english: 'Dung beetles are usually found in cow dung.',
    difficulty: 3,
    words: [
      AwingWord('Fu\'', '_'),
      AwingWord('mbéle', '_'),
      AwingWord('á', '_'),
      AwingWord('zá', '_'),
      AwingWord('ńchiə', '_'),
      AwingWord('ló', '_'),
      AwingWord('á', '_'),
      AwingWord('mám', '_'),
      AwingWord('mbéd', '_'),
      AwingWord('má', '_'),
      AwingWord('neemə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Fú məlo'ə** á náənə á alá' Mbíwiŋə.",
    english: 'There is much palm wine in Awing village.',
    difficulty: 2,
    words: [
      AwingWord('Fú', '_'),
      AwingWord('məlo\'ə', '_'),
      AwingWord('á', '_'),
      AwingWord('náənə', '_'),
      AwingWord('á', '_'),
      AwingWord('alá\'', '_'),
      AwingWord('Mbíwiŋə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Fú mənɔŋə** á nəələ ló ńgə ŋwunə a tá ńdenə.",
    english: 'Grey hair is an indication that one is aging.',
    difficulty: 2,
    words: [
      AwingWord('Fú', '_'),
      AwingWord('mənɔŋə', '_'),
      AwingWord('á', '_'),
      AwingWord('nəələ', '_'),
      AwingWord('ló', '_'),
      AwingWord('ńgə', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('tá', '_'),
      AwingWord('ńdenə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Nəkəŋ** ná tá fu'ə á nəkyelə.",
    english: 'A pot is boiling on fire.',
    difficulty: 2,
    words: [
      AwingWord('Nəkəŋ', '_'),
      AwingWord('ná', '_'),
      AwingWord('tá', '_'),
      AwingWord('fu\'ə', '_'),
      AwingWord('á', '_'),
      AwingWord('nəkyelə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Machínə** afwə'ə atíə á chí əwə.",
    english: 'There is a machine for hollowing out trees.',
    difficulty: 2,
    words: [
      AwingWord('Machínə', '_'),
      AwingWord('afwə\'ə', '_'),
      AwingWord('atíə', '_'),
      AwingWord('á', '_'),
      AwingWord('chí', '_'),
      AwingWord('əwə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbə'** ŋwunə a jwítə ŋwu atsəŋə yə pá yə tá mée.",
    english: 'If one kills his punishment will be life imprisonment.',
    difficulty: 3,
    words: [
      AwingWord('Mbə\'', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('jwítə', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('atsəŋə', '_'),
      AwingWord('yə', '_'),
      AwingWord('pá', '_'),
      AwingWord('yə', '_'),
      AwingWord('tá', '_'),
      AwingWord('mée', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "In some ## fyáalə communities people key their doors even when they are just nearby.",
    english: 'This is due to a very high level of theft that is prevalent.',
    difficulty: 3,
    words: [
      AwingWord('In', '_'),
      AwingWord('some', '_'),
      AwingWord('fyáalə', '_'),
      AwingWord('communities', '_'),
      AwingWord('people', '_'),
      AwingWord('key', '_'),
      AwingWord('their', '_'),
      AwingWord('doors', '_'),
      AwingWord('even', '_'),
      AwingWord('when', '_'),
      AwingWord('they', '_'),
      AwingWord('are', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbəŋ** á ló ló pí pá fwəŋə atətsə' ná məko mób téshúnə.",
    english: 'When it rains people lift a lot of mud with their feet.',
    difficulty: 3,
    words: [
      AwingWord('Mbəŋ', '_'),
      AwingWord('á', '_'),
      AwingWord('ló', '_'),
      AwingWord('ló', '_'),
      AwingWord('pí', '_'),
      AwingWord('pá', '_'),
      AwingWord('fwəŋə', '_'),
      AwingWord('atətsə\'', '_'),
      AwingWord('ná', '_'),
      AwingWord('məko', '_'),
      AwingWord('mób', '_'),
      AwingWord('téshúnə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Chípó'ə** a fwəɔtə ló fwəɔtə ná.",
    english: 'A dumb mumbles instead.',
    difficulty: 2,
    words: [
      AwingWord('Chípó\'ə', '_'),
      AwingWord('a', '_'),
      AwingWord('fwəɔtə', '_'),
      AwingWord('ló', '_'),
      AwingWord('fwəɔtə', '_'),
      AwingWord('ná', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Na məyəŋə** á fyáalə ŋwunə.",
    english: 'A wild animal pursues human beings to attack.',
    difficulty: 1,
    words: [
      AwingWord('Na', '_'),
      AwingWord('məyəŋə', '_'),
      AwingWord('á', '_'),
      AwingWord('fyáalə', '_'),
      AwingWord('ŋwunə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Saddám Husséna a kə fyá'á tə əyí mbəŋə ghenə aŋwa'lə.",
    english: 'Saddam Hussein forced his father before going to school.',
    difficulty: 2,
    words: [
      AwingWord('Saddám', '_'),
      AwingWord('Husséna', '_'),
      AwingWord('a', '_'),
      AwingWord('kə', '_'),
      AwingWord('fyá\'á', '_'),
      AwingWord('tə', '_'),
      AwingWord('əyí', '_'),
      AwingWord('mbəŋə', '_'),
      AwingWord('ghenə', '_'),
      AwingWord('aŋwa\'lə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Fyá'áə afanə zə o lóbtə nə lə.",
    english: 'Nip that bad idea in the bud.',
    difficulty: 2,
    words: [
      AwingWord('Fyá\'áə', '_'),
      AwingWord('afanə', '_'),
      AwingWord('zə', '_'),
      AwingWord('o', '_'),
      AwingWord('lóbtə', '_'),
      AwingWord('nə', '_'),
      AwingWord('lə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbeləló' ə pómə məndə mób lə nə atətsá', ńtí'ə fyá'amə nə mbə'əmə.",
    english: 'Bororo people build their houses with mud, and then daub with whitewash.',
    difficulty: 3,
    words: [
      AwingWord('Mbeləló\'', '_'),
      AwingWord('ə', '_'),
      AwingWord('pómə', '_'),
      AwingWord('məndə', '_'),
      AwingWord('mób', '_'),
      AwingWord('lə', '_'),
      AwingWord('nə', '_'),
      AwingWord('atətsá\'', '_'),
      AwingWord('ńtí\'ə', '_'),
      AwingWord('fyá\'amə', '_'),
      AwingWord('nə', '_'),
      AwingWord('mbə\'əmə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Fyá'dtə mbó təpəŋ wə.",
    english: 'Nip that bad character in the bud.',
    difficulty: 1,
    words: [
      AwingWord('Fyá\'dtə', '_'),
      AwingWord('mbó', '_'),
      AwingWord('təpəŋ', '_'),
      AwingWord('wə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pó fya'ə anuə alá' Mbíiwíŋ lə pənchwíə.",
    english: 'People pour libation on the fourth day of the Awing week.',
    difficulty: 2,
    words: [
      AwingWord('Pó', '_'),
      AwingWord('fya\'ə', '_'),
      AwingWord('anuə', '_'),
      AwingWord('alá\'', '_'),
      AwingWord('Mbíiwíŋ', '_'),
      AwingWord('lə', '_'),
      AwingWord('pənchwíə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pi pó fya'ətʊə á alá' Mbíiwíŋə, ńgelə əlíd lə mbəŋtə lə atseébə Əsə.",
    english: 'People worship the dead in Awing and this against the word of God.',
    difficulty: 3,
    words: [
      AwingWord('Pi', '_'),
      AwingWord('pó', '_'),
      AwingWord('fya\'ətʊə', '_'),
      AwingWord('á', '_'),
      AwingWord('alá\'', '_'),
      AwingWord('Mbíiwíŋə', '_'),
      AwingWord('ńgelə', '_'),
      AwingWord('əlíd', '_'),
      AwingWord('lə', '_'),
      AwingWord('mbəŋtə', '_'),
      AwingWord('lə', '_'),
      AwingWord('atseébə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Á tyantə mə fyag nə ŋwu pó ngaŋəko əyíə.",
    english: 'It is difficult to dislodge two friends from each other.',
    difficulty: 2,
    words: [
      AwingWord('Á', '_'),
      AwingWord('tyantə', '_'),
      AwingWord('mə', '_'),
      AwingWord('fyag', '_'),
      AwingWord('nə', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('pó', '_'),
      AwingWord('ngaŋəko', '_'),
      AwingWord('əyíə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Á pəŋə á mə fyagtə nə məla'ə.",
    english: 'It is normal to separate two people fighting.',
    difficulty: 2,
    words: [
      AwingWord('Á', '_'),
      AwingWord('pəŋə', '_'),
      AwingWord('á', '_'),
      AwingWord('mə', '_'),
      AwingWord('fyagtə', '_'),
      AwingWord('nə', '_'),
      AwingWord('məla\'ə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Fyamtə ətsə' pá á pantə nə á nked lə.",
    english: 'Remove those dresses hanging on the line.',
    difficulty: 2,
    words: [
      AwingWord('Fyamtə', '_'),
      AwingWord('ətsə\'', '_'),
      AwingWord('pá', '_'),
      AwingWord('á', '_'),
      AwingWord('pantə', '_'),
      AwingWord('nə', '_'),
      AwingWord('á', '_'),
      AwingWord('nked', '_'),
      AwingWord('lə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbəŋ ə tə fyá'mtə.",
    english: 'The rain is drizzling.',
    difficulty: 1,
    words: [
      AwingWord('Mbəŋ', '_'),
      AwingWord('ə', '_'),
      AwingWord('tə', '_'),
      AwingWord('fyá\'mtə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A **ghabkɔ ńgenɔ**.",
    english: 'He has suddenly left.',
    difficulty: 1,
    words: [
      AwingWord('A', '_'),
      AwingWord('ghabkɔ', '_'),
      AwingWord('ńgenɔ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pó ghabnɔ ape'ɔ azóobɔ**.",
    english: 'They have shared their property.',
    difficulty: 1,
    words: [
      AwingWord('Pó', '_'),
      AwingWord('ghabnɔ', '_'),
      AwingWord('ape\'ɔ', '_'),
      AwingWord('azóobɔ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A **ghabtɔ ɔpú ɔpóobɔ**.",
    english: 'He has shared their belongings.',
    difficulty: 1,
    words: [
      AwingWord('A', '_'),
      AwingWord('ghabtɔ', '_'),
      AwingWord('ɔpú', '_'),
      AwingWord('ɔpóobɔ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mɔŋgyɛ pâ' a ghâglɔ nɔ a pɔŋɔ**.",
    english: 'A smart woman is more pleasing to people.',
    difficulty: 2,
    words: [
      AwingWord('Mɔŋgyɛ', '_'),
      AwingWord('pâ\'', '_'),
      AwingWord('a', '_'),
      AwingWord('ghâglɔ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('a', '_'),
      AwingWord('pɔŋɔ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A **ghagtɔ akɔ'ɔ ndɔŋ zɔ tɔɔ'ɔ ghagtɔ nɔ**.",
    english: 'He has made that bamboo chair poorly.',
    difficulty: 2,
    words: [
      AwingWord('A', '_'),
      AwingWord('ghagtɔ', '_'),
      AwingWord('akɔ\'ɔ', '_'),
      AwingWord('ndɔŋ', '_'),
      AwingWord('zɔ', '_'),
      AwingWord('tɔɔ\'ɔ', '_'),
      AwingWord('ghagtɔ', '_'),
      AwingWord('nɔ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Apɛlɔmɔlɔ'ɔ a nyinɔ ńgánɔ lɔ lɔ ghɛlɔ mɔlɔ'ɔ**.",
    english: 'A drunk walks staggering because of the wine he has taken.',
    difficulty: 2,
    words: [
      AwingWord('Apɛlɔmɔlɔ\'ɔ', '_'),
      AwingWord('a', '_'),
      AwingWord('nyinɔ', '_'),
      AwingWord('ńgánɔ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('ghɛlɔ', '_'),
      AwingWord('mɔlɔ\'ɔ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A **ghánkɔ ɲwu ma'ɔ ɔsɛ**.",
    english: 'He has made somebody to stagger and fall.',
    difficulty: 1,
    words: [
      AwingWord('A', '_'),
      AwingWord('ghánkɔ', '_'),
      AwingWord('ɲwu', '_'),
      AwingWord('ma\'ɔ', '_'),
      AwingWord('ɔsɛ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mɔ ngwúɔ a ghántɔ ɔli' pɔ ní nɔ á nɔtú'ɔ**.",
    english: 'A lose dog frequents many places at night.',
    difficulty: 2,
    words: [
      AwingWord('Mɔ', '_'),
      AwingWord('ngwúɔ', '_'),
      AwingWord('a', '_'),
      AwingWord('ghántɔ', '_'),
      AwingWord('ɔli\'', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('ní', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('nɔtú\'ɔ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "O ghéenɔ** ghed məjìə 73 ghôo ŋwunə á ntínumnə ló á kě pǝŋ pô.",
    english: 'It is not good to visit somebody at mid-day.',
    difficulty: 3,
    words: [
      AwingWord('O', '_'),
      AwingWord('ghéenɔ', '_'),
      AwingWord('ghed', '_'),
      AwingWord('məjìə', '_'),
      AwingWord('73', '_'),
      AwingWord('ghôo', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('á', '_'),
      AwingWord('ntínumnə', '_'),
      AwingWord('ló', '_'),
      AwingWord('á', '_'),
      AwingWord('kě', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A ghedtə mó ajúmə.",
    english: 'He has done a little thing.',
    difficulty: 1,
    words: [
      AwingWord('A', '_'),
      AwingWord('ghedtə', '_'),
      AwingWord('mó', '_'),
      AwingWord('ajúmə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A ghelə ajúmə.",
    english: 'He has done something.',
    difficulty: 1,
    words: [
      AwingWord('A', '_'),
      AwingWord('ghelə', '_'),
      AwingWord('ajúmə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pó ghelə akya'áshi ló á fóomə.",
    english: 'A mirror is made to be very smooth.',
    difficulty: 2,
    words: [
      AwingWord('Pó', '_'),
      AwingWord('ghelə', '_'),
      AwingWord('akya\'áshi', '_'),
      AwingWord('ló', '_'),
      AwingWord('á', '_'),
      AwingWord('fóomə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Sóŋ ŋgə a ghelə á kakə.",
    english: 'Tell him to make it rough.',
    difficulty: 2,
    words: [
      AwingWord('Sóŋ', '_'),
      AwingWord('ŋgə', '_'),
      AwingWord('a', '_'),
      AwingWord('ghelə', '_'),
      AwingWord('á', '_'),
      AwingWord('kakə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ghen nə mbi nə afa'ə azó yə ashi'na.",
    english: 'Go ahead with your good work.',
    difficulty: 2,
    words: [
      AwingWord('Ghen', '_'),
      AwingWord('nə', '_'),
      AwingWord('mbi', '_'),
      AwingWord('nə', '_'),
      AwingWord('afa\'ə', '_'),
      AwingWord('azó', '_'),
      AwingWord('yə', '_'),
      AwingWord('ashi\'na', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Twáamə ŋwu ghen ŋgen nə yə awatə.",
    english: 'Carry this man to the hospital.',
    difficulty: 2,
    words: [
      AwingWord('Twáamə', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('ghen', '_'),
      AwingWord('ŋgen', '_'),
      AwingWord('nə', '_'),
      AwingWord('yə', '_'),
      AwingWord('awatə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Kə ghenkə ndelə.",
    english: 'Do not waist time.',
    difficulty: 1,
    words: [
      AwingWord('Kə', '_'),
      AwingWord('ghenkə', '_'),
      AwingWord('ndelə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pó pətsə pó lǝgə yunivásiti ló ándó ali'ə ghenkə ndelə.",
    english: 'Some students consider a university as a place to wind time.',
    difficulty: 2,
    words: [
      AwingWord('Pó', '_'),
      AwingWord('pətsə', '_'),
      AwingWord('pó', '_'),
      AwingWord('lǝgə', '_'),
      AwingWord('yunivásiti', '_'),
      AwingWord('ló', '_'),
      AwingWord('ándó', '_'),
      AwingWord('ali\'ə', '_'),
      AwingWord('ghenkə', '_'),
      AwingWord('ndelə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ngwú á ghəəbə akwəŋə.",
    english: 'A dog crunches a bone.',
    difficulty: 1,
    words: [
      AwingWord('Ngwú', '_'),
      AwingWord('á', '_'),
      AwingWord('ghəəbə', '_'),
      AwingWord('akwəŋə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Móonə á ghəəkə mə əyi táshúnə.",
    english: 'A baby disturbs the mother so much.',
    difficulty: 2,
    words: [
      AwingWord('Móonə', '_'),
      AwingWord('á', '_'),
      AwingWord('ghəəkə', '_'),
      AwingWord('mə', '_'),
      AwingWord('əyi', '_'),
      AwingWord('táshúnə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbə' ŋwunə a pə akəkóg mbia mó əyi a kə ŋgəənə.",
    english: 'If a man is foolish his child will also be stupid.',
    difficulty: 3,
    words: [
      AwingWord('Mbə\'', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('pə', '_'),
      AwingWord('akəkóg', '_'),
      AwingWord('mbia', '_'),
      AwingWord('mó', '_'),
      AwingWord('əyi', '_'),
      AwingWord('a', '_'),
      AwingWord('kə', '_'),
      AwingWord('ŋgəənə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Maŋ sóŋ ŋgə o ghəglə.",
    english: 'I have asked you to hurry.',
    difficulty: 1,
    words: [
      AwingWord('Maŋ', '_'),
      AwingWord('sóŋ', '_'),
      AwingWord('ŋgə', '_'),
      AwingWord('o', '_'),
      AwingWord('ghəglə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ghidntǝŋə á waamə mə.",
    english: 'I am attacked by hiccough.',
    difficulty: 1,
    words: [
      AwingWord('Ghidntǝŋə', '_'),
      AwingWord('á', '_'),
      AwingWord('waamə', '_'),
      AwingWord('mə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ghó'kə Əsə nə ntseembia alə á məm ngeebə (ŋgab mbia).",
    english: 'Honour God on the first day of the week.',
    difficulty: 2,
    words: [
      AwingWord('Ghó\'kə', '_'),
      AwingWord('Əsə', '_'),
      AwingWord('nə', '_'),
      AwingWord('ntseembia', '_'),
      AwingWord('alə', '_'),
      AwingWord('á', '_'),
      AwingWord('məm', '_'),
      AwingWord('ngeebə', '_'),
      AwingWord('ŋgab', '_'),
      AwingWord('mbia', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbɔ' ɣwunə a kɛ̀ məngyɛ̀ zɔ' tə ghoolə atū pō.",
    english: 'One cannot marry without dowrying the woman.',
    difficulty: 2,
    words: [
      AwingWord('Mbɔ\'', '_'),
      AwingWord('ɣwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('kɛ', '_'),
      AwingWord('məngyɛ', '_'),
      AwingWord('zɔ\'', '_'),
      AwingWord('tə', '_'),
      AwingWord('ghoolə', '_'),
      AwingWord('atū', '_'),
      AwingWord('pō', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "O yī ghoonə.",
    english: 'You will be sick.',
    difficulty: 1,
    words: [
      AwingWord('O', '_'),
      AwingWord('yī', '_'),
      AwingWord('ghoonə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Kɔ ghɔdkə mə.",
    english: 'Do not frighten me.',
    difficulty: 1,
    words: [
      AwingWord('Kɔ', '_'),
      AwingWord('ghɔdkə', '_'),
      AwingWord('mə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Múto á tə ɲkəəlɔ̀ nə ndɔ̀ lə á chī mbɔ' á ghɔ'ə ɣwunə.",
    english: 'If a car is speeding, it risks crushing somebody.',
    difficulty: 3,
    words: [
      AwingWord('Múto', '_'),
      AwingWord('á', '_'),
      AwingWord('tə', '_'),
      AwingWord('ɲkəəlɔ', '_'),
      AwingWord('nə', '_'),
      AwingWord('ndɔ', '_'),
      AwingWord('lə', '_'),
      AwingWord('á', '_'),
      AwingWord('chī', '_'),
      AwingWord('mbɔ\'', '_'),
      AwingWord('á', '_'),
      AwingWord('ghɔ\'ə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Məngyɛ̀ nəpəmə a zá ŋgɔ'kə.",
    english: 'A pregnant woman always vomits.',
    difficulty: 1,
    words: [
      AwingWord('Məngyɛ', '_'),
      AwingWord('nəpəmə', '_'),
      AwingWord('a', '_'),
      AwingWord('zá', '_'),
      AwingWord('ŋgɔ\'kə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A ghɔ'tə ɔpúmə.",
    english: 'He has ground many things.',
    difficulty: 1,
    words: [
      AwingWord('A', '_'),
      AwingWord('ghɔ\'tə', '_'),
      AwingWord('ɔpúmə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ajúmə á lwɛ̀nkə tɔ̀shú lə pɔ̀ jáabə.",
    english: 'If something is overful, it has to be reduced.',
    difficulty: 2,
    words: [
      AwingWord('Ajúmə', '_'),
      AwingWord('á', '_'),
      AwingWord('lwɛ', '_'),
      AwingWord('nkə', '_'),
      AwingWord('tɔ', '_'),
      AwingWord('shú', '_'),
      AwingWord('lə', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('jáabə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pə nə ŋjábtə ngəsɔŋ á ngɔ' ghen ɲtɛ̀ ŋgɔ̀ mbəŋ nə ɲkɛ̀ tə ndɔ̀ pɔ̀.",
    english: 'Corn was replanted this year because rain was not falling.',
    difficulty: 3,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('nə', '_'),
      AwingWord('ŋjábtə', '_'),
      AwingWord('ngəsɔŋ', '_'),
      AwingWord('á', '_'),
      AwingWord('ngɔ\'', '_'),
      AwingWord('ghen', '_'),
      AwingWord('ɲtɛ', '_'),
      AwingWord('ŋgɔ', '_'),
      AwingWord('mbəŋ', '_'),
      AwingWord('nə', '_'),
      AwingWord('ɲkɛ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ngwɛ kwuneemə á tə ɲchwaalɔ ndú lə á já' ɲkɔ'ə.",
    english: 'When a female pig wants to be crossed it skips through the fence in search of a male.',
    difficulty: 2,
    words: [
      AwingWord('Ngwɛ', '_'),
      AwingWord('kwuneemə', '_'),
      AwingWord('á', '_'),
      AwingWord('tə', '_'),
      AwingWord('ɲchwaalɔ', '_'),
      AwingWord('ndú', '_'),
      AwingWord('lə', '_'),
      AwingWord('á', '_'),
      AwingWord('já\'', '_'),
      AwingWord('ɲkɔ\'ə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Móonə a já'kə.",
    english: 'A child has vomited.',
    difficulty: 1,
    words: [
      AwingWord('Móonə', '_'),
      AwingWord('a', '_'),
      AwingWord('já\'kə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pi pə kamalún pó jì mbəglə tšshúnə.",
    english: 'Cameroonian people are very corrupt.',
    difficulty: 2,
    words: [
      AwingWord('Pi', '_'),
      AwingWord('pə', '_'),
      AwingWord('kamalún', '_'),
      AwingWord('pó', '_'),
      AwingWord('jì', '_'),
      AwingWord('mbəglə', '_'),
      AwingWord('tšshúnə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Kə jì ntũ məjì tə ghə o nid Əsə əwə.",
    english: 'Do not eat first of new fruit without dedicating it to God.',
    difficulty: 2,
    words: [
      AwingWord('Kə', '_'),
      AwingWord('jì', '_'),
      AwingWord('ntũ', '_'),
      AwingWord('məjì', '_'),
      AwingWord('tə', '_'),
      AwingWord('ghə', '_'),
      AwingWord('o', '_'),
      AwingWord('nid', '_'),
      AwingWord('Əsə', '_'),
      AwingWord('əwə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pi pə jì mənu mətsə ńkə mətsə jì pə.",
    english: 'People know certain things and are ignorant of others.',
    difficulty: 2,
    words: [
      AwingWord('Pi', '_'),
      AwingWord('pə', '_'),
      AwingWord('jì', '_'),
      AwingWord('mənu', '_'),
      AwingWord('mətsə', '_'),
      AwingWord('ńkə', '_'),
      AwingWord('mətsə', '_'),
      AwingWord('jì', '_'),
      AwingWord('pə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pi pətsə pó mə ńkəŋə ághóobə á mə jì nə ndə.",
    english: 'Some people do not like to inherit their parent\'s house.',
    difficulty: 3,
    words: [
      AwingWord('Pi', '_'),
      AwingWord('pətsə', '_'),
      AwingWord('pó', '_'),
      AwingWord('mə', '_'),
      AwingWord('ńkəŋə', '_'),
      AwingWord('ághóobə', '_'),
      AwingWord('á', '_'),
      AwingWord('mə', '_'),
      AwingWord('jì', '_'),
      AwingWord('nə', '_'),
      AwingWord('ndə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Maŋ kəŋ lə jìə ajumə, lə kə jì pə.",
    english: 'I like that thing instead of this.',
    difficulty: 2,
    words: [
      AwingWord('Maŋ', '_'),
      AwingWord('kəŋ', '_'),
      AwingWord('lə', '_'),
      AwingWord('jìə', '_'),
      AwingWord('ajumə', '_'),
      AwingWord('lə', '_'),
      AwingWord('kə', '_'),
      AwingWord('jì', '_'),
      AwingWord('pə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Bamilikə a ji'tə nə nkáb tšshúnə.",
    english: 'A Bamilike man is too greedy for money.',
    difficulty: 2,
    words: [
      AwingWord('Bamilikə', '_'),
      AwingWord('a', '_'),
      AwingWord('ji\'tə', '_'),
      AwingWord('nə', '_'),
      AwingWord('nkáb', '_'),
      AwingWord('tšshúnə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pó jínə məmbí móobə.",
    english: 'They have seen each other.',
    difficulty: 1,
    words: [
      AwingWord('Pó', '_'),
      AwingWord('jínə', '_'),
      AwingWord('məmbí', '_'),
      AwingWord('móobə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mə pá' a júblə nə ä tũg ngə' lə əghə ətsəmə.",
    english: 'A child who is too excited runs into problems very often.',
    difficulty: 3,
    words: [
      AwingWord('Mə', '_'),
      AwingWord('pá\'', '_'),
      AwingWord('a', '_'),
      AwingWord('júblə', '_'),
      AwingWord('nə', '_'),
      AwingWord('ä', '_'),
      AwingWord('tũg', '_'),
      AwingWord('ngə\'', '_'),
      AwingWord('lə', '_'),
      AwingWord('əghə', '_'),
      AwingWord('ətsəmə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Á pə əghə alu lə nki júmə.",
    english: 'During the dry season water evaporates.',
    difficulty: 2,
    words: [
      AwingWord('Á', '_'),
      AwingWord('pə', '_'),
      AwingWord('əghə', '_'),
      AwingWord('alu', '_'),
      AwingWord('lə', '_'),
      AwingWord('nki', '_'),
      AwingWord('júmə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A fa' tə ńjúmə.",
    english: 'So much work has made him to lose weight.',
    difficulty: 1,
    words: [
      AwingWord('A', '_'),
      AwingWord('fa\'', '_'),
      AwingWord('tə', '_'),
      AwingWord('ńjúmə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Kɔ tə ɲjwábtə mǝ.",
    english: 'Do not be provoking me.',
    difficulty: 1,
    words: [
      AwingWord('Kɔ', '_'),
      AwingWord('tə', '_'),
      AwingWord('ɲjwábtə', '_'),
      AwingWord('mǝ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "O tə ɲjwa'ə mǝ.",
    english: 'You are disturbing me.',
    difficulty: 1,
    words: [
      AwingWord('O', '_'),
      AwingWord('tə', '_'),
      AwingWord('ɲjwa\'ə', '_'),
      AwingWord('mǝ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pə tə ɲjwó'ə Jənə.",
    english: 'John is being tested.',
    difficulty: 1,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('tə', '_'),
      AwingWord('ɲjwó\'ə', '_'),
      AwingWord('Jənə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Á pǝŋə mǝ jwó'tə nǝ pǝŋə tséebɔ.",
    english: 'It is good to listen before speaking.',
    difficulty: 2,
    words: [
      AwingWord('Á', '_'),
      AwingWord('pǝŋə', '_'),
      AwingWord('mǝ', '_'),
      AwingWord('jwó\'tə', '_'),
      AwingWord('nǝ', '_'),
      AwingWord('pǝŋə', '_'),
      AwingWord('tséebɔ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pə jwĩ'kə ndzē əsaŋ lə ə zaŋkə ɲjúmǝ.",
    english: 'When vegetable is boiled a little it makes for easy preservation by drying.',
    difficulty: 2,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('jwĩ\'kə', '_'),
      AwingWord('ndzē', '_'),
      AwingWord('əsaŋ', '_'),
      AwingWord('lə', '_'),
      AwingWord('ə', '_'),
      AwingWord('zaŋkə', '_'),
      AwingWord('ɲjúmǝ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Jwĩ'lə á chĩə á mǝm mǝjĩ mǝ.",
    english: 'There are flies in the food.',
    difficulty: 2,
    words: [
      AwingWord('Jwĩ\'lə', '_'),
      AwingWord('á', '_'),
      AwingWord('chĩə', '_'),
      AwingWord('á', '_'),
      AwingWord('mǝm', '_'),
      AwingWord('mǝjĩ', '_'),
      AwingWord('mǝ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "O fa' o jwitə.",
    english: 'When you work have a rest.',
    difficulty: 1,
    words: [
      AwingWord('O', '_'),
      AwingWord('fa\'', '_'),
      AwingWord('o', '_'),
      AwingWord('jwitə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ntso ə jwĩtə pi tǝshúnə.",
    english: 'War kills people a lot.',
    difficulty: 1,
    words: [
      AwingWord('Ntso', '_'),
      AwingWord('ə', '_'),
      AwingWord('jwĩtə', '_'),
      AwingWord('pi', '_'),
      AwingWord('tǝshúnə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ká ɲwunə á nchĩndē.",
    english: 'There is nobody in the compound.',
    difficulty: 1,
    words: [
      AwingWord('Ká', '_'),
      AwingWord('ɲwunə', '_'),
      AwingWord('á', '_'),
      AwingWord('nchĩndē', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pə pegə ɲkǎa ali' lə kǎa nǝ mbǝŋə kwáŋə.",
    english: 'Usually farm beds are first of all cleaned roughly, before they are thoroughly cleaned.',
    difficulty: 2,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('pegə', '_'),
      AwingWord('ɲkǎa', '_'),
      AwingWord('ali\'', '_'),
      AwingWord('lə', '_'),
      AwingWord('kǎa', '_'),
      AwingWord('nǝ', '_'),
      AwingWord('mbǝŋə', '_'),
      AwingWord('kwáŋə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Káatə yĩ nǝ nǝfyǎnə.",
    english: 'Threaten him with a slap or spank.',
    difficulty: 1,
    words: [
      AwingWord('Káatə', '_'),
      AwingWord('yĩ', '_'),
      AwingWord('nǝ', '_'),
      AwingWord('nǝfyǎnə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Achĩə á ká'ə ká'ə 77 kéelə ako ɲwunə.",
    english: 'Blood clots on a person\'s leg.',
    difficulty: 2,
    words: [
      AwingWord('Achĩə', '_'),
      AwingWord('á', '_'),
      AwingWord('ká\'ə', '_'),
      AwingWord('ká\'ə', '_'),
      AwingWord('77', '_'),
      AwingWord('kéelə', '_'),
      AwingWord('ako', '_'),
      AwingWord('ɲwunə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ndǝŋə́ ə́ ka'ə́ anuə ají lǝ tso'ə́ ka' nə́, mbo' a kě fa' pǝ.",
    english: 'A lazy person only plans but cannot get into action V.',
    difficulty: 3,
    words: [
      AwingWord('Ndǝŋə', '_'),
      AwingWord('ə', '_'),
      AwingWord('ka\'ə', '_'),
      AwingWord('anuə', '_'),
      AwingWord('ají', '_'),
      AwingWord('lǝ', '_'),
      AwingWord('tso\'ə', '_'),
      AwingWord('ka\'', '_'),
      AwingWord('nə', '_'),
      AwingWord('mbo\'', '_'),
      AwingWord('a', '_'),
      AwingWord('kě', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A kagə̂ mə.",
    english: 'He has threatened me.',
    difficulty: 1,
    words: [
      AwingWord('A', '_'),
      AwingWord('kagə', '_'),
      AwingWord('mə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A kagtə̂ gho lǝ ngā́ ə́shí'ə́.",
    english: 'How many times has he threatened you?',
    difficulty: 2,
    words: [
      AwingWord('A', '_'),
      AwingWord('kagtə', '_'),
      AwingWord('gho', '_'),
      AwingWord('lǝ', '_'),
      AwingWord('ngā', '_'),
      AwingWord('ə', '_'),
      AwingWord('shí\'ə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbində́ ə́ yí kakə̂, pá' mbo' pǝ chí fya' pǝ.",
    english: 'The floor will be rough if it is not watered.',
    difficulty: 2,
    words: [
      AwingWord('Mbində', '_'),
      AwingWord('ə', '_'),
      AwingWord('yí', '_'),
      AwingWord('kakə', '_'),
      AwingWord('pá\'', '_'),
      AwingWord('mbo\'', '_'),
      AwingWord('pǝ', '_'),
      AwingWord('chí', '_'),
      AwingWord('fya\'', '_'),
      AwingWord('pǝ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Məshínə́ ə́ chí ə́wə́ mbo' ɲkwə̀nə́ ghá'ə́ pǝ ə́lé ə́ kam ɲkwelə́ ə́ ndəsə̂.",
    english: 'No matter how big a hill is, machines do exist that can lift it in lumps and throw down.',
    difficulty: 3,
    words: [
      AwingWord('Məshínə', '_'),
      AwingWord('ə', '_'),
      AwingWord('chí', '_'),
      AwingWord('ə', '_'),
      AwingWord('wə', '_'),
      AwingWord('mbo\'', '_'),
      AwingWord('ɲkwə', '_'),
      AwingWord('nə', '_'),
      AwingWord('ghá\'ə', '_'),
      AwingWord('pǝ', '_'),
      AwingWord('ə', '_'),
      AwingWord('lé', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "O yí kanə́ apélə́, mbo' o tə́ nyinə́ ə́ nǝtú' tə́ ɲkya'ə́.",
    english: 'You will jump into a pit if you are walking in the night without a touch.',
    difficulty: 3,
    words: [
      AwingWord('O', '_'),
      AwingWord('yí', '_'),
      AwingWord('kanə', '_'),
      AwingWord('apélə', '_'),
      AwingWord('mbo\'', '_'),
      AwingWord('o', '_'),
      AwingWord('tə', '_'),
      AwingWord('nyinə', '_'),
      AwingWord('ə', '_'),
      AwingWord('nǝtú\'', '_'),
      AwingWord('tə', '_'),
      AwingWord('ɲkya\'ə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "O kaɲtə́ kǝ wúə́.",
    english: 'If you stumble, do not fall.',
    difficulty: 1,
    words: [
      AwingWord('O', '_'),
      AwingWord('kaɲtə', '_'),
      AwingWord('kǝ', '_'),
      AwingWord('wúə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Nəfaɲ tə́shúnə́ ə́ kě pǝɲ pǝ.",
    english: 'It is not good to carry so much wet.',
    difficulty: 2,
    words: [
      AwingWord('Nəfaɲ', '_'),
      AwingWord('tə', '_'),
      AwingWord('shúnə', '_'),
      AwingWord('ə', '_'),
      AwingWord('kě', '_'),
      AwingWord('pǝɲ', '_'),
      AwingWord('pǝ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "O fa' tšshɪ lə o kéenə.",
    english: 'When you work a lot you get tired.',
    difficulty: 2,
    words: [
      AwingWord('O', '_'),
      AwingWord('fa\'', '_'),
      AwingWord('tšshɪ', '_'),
      AwingWord('lə', '_'),
      AwingWord('o', '_'),
      AwingWord('kéenə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A wũə á móg mbi əji kédkə tə əli' nəənə.",
    english: 'He fell in fire and got seriously burnt on many spots.',
    difficulty: 2,
    words: [
      AwingWord('A', '_'),
      AwingWord('wũə', '_'),
      AwingWord('á', '_'),
      AwingWord('móg', '_'),
      AwingWord('mbi', '_'),
      AwingWord('əji', '_'),
      AwingWord('kédkə', '_'),
      AwingWord('tə', '_'),
      AwingWord('əli\'', '_'),
      AwingWord('nəənə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Móg tə nkélə á ndu kɔŋ yi njũbtə.",
    english: 'Fire is burning on dry savana.',
    difficulty: 2,
    words: [
      AwingWord('Móg', '_'),
      AwingWord('tə', '_'),
      AwingWord('nkélə', '_'),
      AwingWord('á', '_'),
      AwingWord('ndu', '_'),
      AwingWord('kɔŋ', '_'),
      AwingWord('yi', '_'),
      AwingWord('njũbtə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Qwunə a ghelə anu fankə lə a kə ngelə tso'ə ghed nə tə ngyũ njia.",
    english: 'If one makes a mistake he keeps on trying until success comes.',
    difficulty: 3,
    words: [
      AwingWord('Qwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('ghelə', '_'),
      AwingWord('anu', '_'),
      AwingWord('fankə', '_'),
      AwingWord('lə', '_'),
      AwingWord('a', '_'),
      AwingWord('kə', '_'),
      AwingWord('ngelə', '_'),
      AwingWord('tso\'ə', '_'),
      AwingWord('ghed', '_'),
      AwingWord('nə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pi pi pə fɔŋə ághəb lə nə pə pigmia.",
    english: 'There are some bushes where animals live, people also live there as if they are animals.',
    difficulty: 2,
    words: [
      AwingWord('Pi', '_'),
      AwingWord('pi', '_'),
      AwingWord('pə', '_'),
      AwingWord('fɔŋə', '_'),
      AwingWord('ághəb', '_'),
      AwingWord('lə', '_'),
      AwingWord('nə', '_'),
      AwingWord('pə', '_'),
      AwingWord('pigmia', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pə kə' ngaalə məta lə ndɔŋ pə nə tá' nkelə.",
    english: 'Garri is measured two cups four one hundred francs in the market.',
    difficulty: 2,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('kə\'', '_'),
      AwingWord('ngaalə', '_'),
      AwingWord('məta', '_'),
      AwingWord('lə', '_'),
      AwingWord('ndɔŋ', '_'),
      AwingWord('pə', '_'),
      AwingWord('nə', '_'),
      AwingWord('tá\'', '_'),
      AwingWord('nkelə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Maŋ kə'ə apó mə.",
    english: 'I have cut my hand.',
    difficulty: 1,
    words: [
      AwingWord('Maŋ', '_'),
      AwingWord('kə\'ə', '_'),
      AwingWord('apó', '_'),
      AwingWord('mə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Qwunə a kəə lə á kə pɔŋ pɔ.",
    english: 'It is not good for somebody to be deaf.',
    difficulty: 2,
    words: [
      AwingWord('Qwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('kəə', '_'),
      AwingWord('lə', '_'),
      AwingWord('á', '_'),
      AwingWord('kə', '_'),
      AwingWord('pɔŋ', '_'),
      AwingWord('pɔ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A tə nkəəbə məndzɔ.",
    english: 'He is shelling groundnuts.',
    difficulty: 1,
    words: [
      AwingWord('A', '_'),
      AwingWord('tə', '_'),
      AwingWord('nkəəbə', '_'),
      AwingWord('məndzɔ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A kəələ lə ntsoola.",
    english: 'He is running away from war.',
    difficulty: 1,
    words: [
      AwingWord('A', '_'),
      AwingWord('kəələ', '_'),
      AwingWord('lə', '_'),
      AwingWord('ntsoola', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Kəənə a ələ yi yi, n kə ji pɔ.",
    english: 'I do not know wether he will come.',
    difficulty: 2,
    words: [
      AwingWord('Kəənə', '_'),
      AwingWord('a', '_'),
      AwingWord('ələ', '_'),
      AwingWord('yi', '_'),
      AwingWord('yi', '_'),
      AwingWord('n', '_'),
      AwingWord('kə', '_'),
      AwingWord('ji', '_'),
      AwingWord('pɔ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A kəənə nnaŋə lə afũə aghoonə yə.",
    english: 'He is running about looking for a cure to his disease.',
    difficulty: 2,
    words: [
      AwingWord('A', '_'),
      AwingWord('kəənə', '_'),
      AwingWord('nnaŋə', '_'),
      AwingWord('lə', '_'),
      AwingWord('afũə', '_'),
      AwingWord('aghoonə', '_'),
      AwingWord('yə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Tá a kě kǎgə pō.",
    english: 'A father is never small.',
    difficulty: 1,
    words: [
      AwingWord('Tá', '_'),
      AwingWord('a', '_'),
      AwingWord('kě', '_'),
      AwingWord('kǎgə', '_'),
      AwingWord('pō', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Móonə a chī ngo' pē, nkǎ kǎglə tsɔ'ə á ndəsē.",
    english: 'The child is two years old, and is still crawling.',
    difficulty: 2,
    words: [
      AwingWord('Móonə', '_'),
      AwingWord('a', '_'),
      AwingWord('chī', '_'),
      AwingWord('ngo\'', '_'),
      AwingWord('pē', '_'),
      AwingWord('nkǎ', '_'),
      AwingWord('kǎglə', '_'),
      AwingWord('tsɔ\'ə', '_'),
      AwingWord('á', '_'),
      AwingWord('ndəsē', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Á məm pō pə pē, tá'ə kǎgtə.",
    english: 'Amongst the two of them, one is a little smaller.',
    difficulty: 2,
    words: [
      AwingWord('Á', '_'),
      AwingWord('məm', '_'),
      AwingWord('pō', '_'),
      AwingWord('pə', '_'),
      AwingWord('pē', '_'),
      AwingWord('tá\'ə', '_'),
      AwingWord('kǎgtə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Kəm ndəsē nə mbéd mə ngəb mə.",
    english: 'Sprinkle some ground on the fowl\'s droppings.',
    difficulty: 2,
    words: [
      AwingWord('Kəm', '_'),
      AwingWord('ndəsē', '_'),
      AwingWord('nə', '_'),
      AwingWord('mbéd', '_'),
      AwingWord('mə', '_'),
      AwingWord('ngəb', '_'),
      AwingWord('mə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A yī kəm ndē əjlə.",
    english: 'He will bring down his house.',
    difficulty: 1,
    words: [
      AwingWord('A', '_'),
      AwingWord('yī', '_'),
      AwingWord('kəm', '_'),
      AwingWord('ndē', '_'),
      AwingWord('əjlə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Á kě pɔŋə mə tǎg nə anu pī kəm pō.",
    english: 'It is not good to set a programme and put it off again.',
    difficulty: 2,
    words: [
      AwingWord('Á', '_'),
      AwingWord('kě', '_'),
      AwingWord('pɔŋə', '_'),
      AwingWord('mə', '_'),
      AwingWord('tǎg', '_'),
      AwingWord('nə', '_'),
      AwingWord('anu', '_'),
      AwingWord('pī', '_'),
      AwingWord('kəm', '_'),
      AwingWord('pō', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pə tə nkəmɔ̄ nəwú nə təkɔ' ɲwu lə əloŋ pēn nəənə.",
    english: 'During the celebration of a powerful man\'s death many dance groups perform.',
    difficulty: 3,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('tə', '_'),
      AwingWord('nkəmɔ', '_'),
      AwingWord('nəwú', '_'),
      AwingWord('nə', '_'),
      AwingWord('təkɔ\'', '_'),
      AwingWord('ɲwu', '_'),
      AwingWord('lə', '_'),
      AwingWord('əloŋ', '_'),
      AwingWord('pēn', '_'),
      AwingWord('nəənə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Kəmú'ntəŋə á zá nkɔ'ə ŋwu lə ami yə.",
    english: 'A goiter usually grows at the neck.',
    difficulty: 2,
    words: [
      AwingWord('Kəmú\'ntəŋə', '_'),
      AwingWord('á', '_'),
      AwingWord('zá', '_'),
      AwingWord('nkɔ\'ə', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('lə', '_'),
      AwingWord('ami', '_'),
      AwingWord('yə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "O nyaanə ándó kónáŋə.",
    english: 'You are moving slowly as a chameleon.',
    difficulty: 1,
    words: [
      AwingWord('O', '_'),
      AwingWord('nyaanə', '_'),
      AwingWord('ándó', '_'),
      AwingWord('kónáŋə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Kə tə nkəŋə mə.",
    english: 'Do not be shading me.',
    difficulty: 1,
    words: [
      AwingWord('Kə', '_'),
      AwingWord('tə', '_'),
      AwingWord('nkəŋə', '_'),
      AwingWord('mə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Móonə a pēlə nkəŋə.",
    english: 'The child is still crawling.',
    difficulty: 1,
    words: [
      AwingWord('Móonə', '_'),
      AwingWord('a', '_'),
      AwingWord('pēlə', '_'),
      AwingWord('nkəŋə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Kə'təti lə səŋ pə' á kə'tə nə atiə.",
    english: 'A kingfisher is a bird that makes a cutting sound on a tree.',
    difficulty: 2,
    words: [
      AwingWord('Kə\'təti', '_'),
      AwingWord('lə', '_'),
      AwingWord('səŋ', '_'),
      AwingWord('pə\'', '_'),
      AwingWord('á', '_'),
      AwingWord('kə\'tə', '_'),
      AwingWord('nə', '_'),
      AwingWord('atiə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Kəyé pə nkə kə āghóobə təpəŋ jī pə.",
    english: 'Little children do not know sin.',
    difficulty: 2,
    words: [
      AwingWord('Kəyé', '_'),
      AwingWord('pə', '_'),
      AwingWord('nkə', '_'),
      AwingWord('kə', '_'),
      AwingWord('āghóobə', '_'),
      AwingWord('təpəŋ', '_'),
      AwingWord('jī', '_'),
      AwingWord('pə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbə' ŋwunə a chiə anu əjī, əfa' nkī mbī mbéŋə a jīə.",
    english: 'If one does something repeatedly, he will surely know.',
    difficulty: 3,
    words: [
      AwingWord('Mbə\'', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('chiə', '_'),
      AwingWord('anu', '_'),
      AwingWord('əjī', '_'),
      AwingWord('əfa\'', '_'),
      AwingWord('nkī', '_'),
      AwingWord('mbī', '_'),
      AwingWord('mbéŋə', '_'),
      AwingWord('a', '_'),
      AwingWord('jīə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "O kībə nə nəzeŋə zō ándó yī nə apīb.",
    english: 'Your forehead is as high as that of a he-goat.',
    difficulty: 2,
    words: [
      AwingWord('O', '_'),
      AwingWord('kībə', '_'),
      AwingWord('nə', '_'),
      AwingWord('nəzeŋə', '_'),
      AwingWord('zō', '_'),
      AwingWord('ándó', '_'),
      AwingWord('yī', '_'),
      AwingWord('nə', '_'),
      AwingWord('apīb', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "O tə ɲkɪ'ə mə.",
    english: 'You are obstructing me.',
    difficulty: 1,
    words: [
      AwingWord('O', '_'),
      AwingWord('tə', '_'),
      AwingWord('ɲkɪ\'ə', '_'),
      AwingWord('mə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Kɔ tə ɲkɪ'tə pəənə.",
    english: 'Do not be screening people from view.',
    difficulty: 1,
    words: [
      AwingWord('Kɔ', '_'),
      AwingWord('tə', '_'),
      AwingWord('ɲkɪ\'tə', '_'),
      AwingWord('pəənə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ko fɛ nə Tata.",
    english: 'Take this and give to Tata.',
    difficulty: 1,
    words: [
      AwingWord('Ko', '_'),
      AwingWord('fɛ', '_'),
      AwingWord('nə', '_'),
      AwingWord('Tata', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Á kɛ pɔŋ ɲgə ɲwunə a kɔ əsɪ ɲjɪ ndɪ' pɔ.",
    english: 'It is not good for somebody to be too timid and do wrong.',
    difficulty: 3,
    words: [
      AwingWord('Á', '_'),
      AwingWord('kɛ', '_'),
      AwingWord('pɔŋ', '_'),
      AwingWord('ɲgə', '_'),
      AwingWord('ɲwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('kɔ', '_'),
      AwingWord('əsɪ', '_'),
      AwingWord('ɲjɪ', '_'),
      AwingWord('ndɪ\'', '_'),
      AwingWord('pɔ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbɔ' ɲwunə a lɔ alə' Mbɪwɪŋ ɲnyɪnə məko ɲko'ə Atəsɔŋə.",
    english: 'Somebody can leave Awing and move on foot to Bamenda.',
    difficulty: 2,
    words: [
      AwingWord('Mbɔ\'', '_'),
      AwingWord('ɲwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('alə\'', '_'),
      AwingWord('Mbɪwɪŋ', '_'),
      AwingWord('ɲnyɪnə', '_'),
      AwingWord('məko', '_'),
      AwingWord('ɲko\'ə', '_'),
      AwingWord('Atəsɔŋə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Na məyenə á kógə mó ntseelə ɲwu məsəŋ yitsə.",
    english: 'A wild animal brings up it\'s young in a much more caring way than some human beings.',
    difficulty: 2,
    words: [
      AwingWord('Na', '_'),
      AwingWord('məyenə', '_'),
      AwingWord('á', '_'),
      AwingWord('kógə', '_'),
      AwingWord('mó', '_'),
      AwingWord('ntseelə', '_'),
      AwingWord('ɲwu', '_'),
      AwingWord('məsəŋ', '_'),
      AwingWord('yitsə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Á ko'nə á mó ghó'kə ná əsə.",
    english: 'It is right and proper to worship God.',
    difficulty: 2,
    words: [
      AwingWord('Á', '_'),
      AwingWord('ko\'nə', '_'),
      AwingWord('á', '_'),
      AwingWord('mó', '_'),
      AwingWord('ghó\'kə', '_'),
      AwingWord('ná', '_'),
      AwingWord('əsə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pá koŋə ndzə lá á lá' mmə mbī fī'.",
    english: 'If a thief is yelled at he will never go back to stealing again.',
    difficulty: 2,
    words: [
      AwingWord('Pá', '_'),
      AwingWord('koŋə', '_'),
      AwingWord('ndzə', '_'),
      AwingWord('lá', '_'),
      AwingWord('á', '_'),
      AwingWord('lá\'', '_'),
      AwingWord('mmə', '_'),
      AwingWord('mbī', '_'),
      AwingWord('fī\'', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Móonə a kóŋə á nkīə.",
    english: 'A child has been swept away by the river current.',
    difficulty: 1,
    words: [
      AwingWord('Móonə', '_'),
      AwingWord('a', '_'),
      AwingWord('kóŋə', '_'),
      AwingWord('á', '_'),
      AwingWord('nkīə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Nki tá nkóŋə á ndo.",
    english: 'Water is flowing on the river-bed.',
    difficulty: 1,
    words: [
      AwingWord('Nki', '_'),
      AwingWord('tá', '_'),
      AwingWord('nkóŋə', '_'),
      AwingWord('á', '_'),
      AwingWord('ndo', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Móonə a ghenə á mó tó' ná nki nkóŋkə atəəmə ajia.",
    english: 'A child went to carry water and caused his water container to be carried away by water.',
    difficulty: 3,
    words: [
      AwingWord('Móonə', '_'),
      AwingWord('a', '_'),
      AwingWord('ghenə', '_'),
      AwingWord('á', '_'),
      AwingWord('mó', '_'),
      AwingWord('tó\'', '_'),
      AwingWord('ná', '_'),
      AwingWord('nki', '_'),
      AwingWord('nkóŋkə', '_'),
      AwingWord('atəəmə', '_'),
      AwingWord('ajia', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Məŋgye a kē ɲwu mbyāŋnə a kōo ná koŋ pō.",
    english: 'A woman does not like a man who snores in bed.',
    difficulty: 2,
    words: [
      AwingWord('Məŋgye', '_'),
      AwingWord('a', '_'),
      AwingWord('kē', '_'),
      AwingWord('ɲwu', '_'),
      AwingWord('mbyāŋnə', '_'),
      AwingWord('a', '_'),
      AwingWord('kōo', '_'),
      AwingWord('ná', '_'),
      AwingWord('koŋ', '_'),
      AwingWord('pō', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ndzəla a zə lá pə waamə yə a kóokə ná njia.",
    english: 'When a thief is caught he shifts the blame to hunger.',
    difficulty: 3,
    words: [
      AwingWord('Ndzəla', '_'),
      AwingWord('a', '_'),
      AwingWord('zə', '_'),
      AwingWord('lá', '_'),
      AwingWord('pə', '_'),
      AwingWord('waamə', '_'),
      AwingWord('yə', '_'),
      AwingWord('a', '_'),
      AwingWord('kóokə', '_'),
      AwingWord('ná', '_'),
      AwingWord('njia', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Kəyə ɲwunə a koolə ngwapa tso'ə yi mbəgə.",
    english: 'Children have harvested raw guava with impunity.',
    difficulty: 2,
    words: [
      AwingWord('Kəyə', '_'),
      AwingWord('ɲwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('koolə', '_'),
      AwingWord('ngwapa', '_'),
      AwingWord('tso\'ə', '_'),
      AwingWord('yi', '_'),
      AwingWord('mbəgə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ndim ɲwunə a kwū lá a koolə atū tso'ə atsəmə.",
    english: 'When one\'s relative dies he has to clean off his hair thoroughly.',
    difficulty: 2,
    words: [
      AwingWord('Ndim', '_'),
      AwingWord('ɲwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('kwū', '_'),
      AwingWord('lá', '_'),
      AwingWord('a', '_'),
      AwingWord('koolə', '_'),
      AwingWord('atū', '_'),
      AwingWord('tso\'ə', '_'),
      AwingWord('atsəmə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Kóomə atûə ándó pá kóomə atûə nəwûə.",
    english: 'Shave as if one is mourning.',
    difficulty: 2,
    words: [
      AwingWord('Kóomə', '_'),
      AwingWord('atûə', '_'),
      AwingWord('ándó', '_'),
      AwingWord('pá', '_'),
      AwingWord('kóomə', '_'),
      AwingWord('atûə', '_'),
      AwingWord('nəwûə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Kó ndɔtí pɛntə zâ á mbí ndê néŋə yí fîə.",
    english: 'Scrub that dirty paint from the wall and put a new one.',
    difficulty: 2,
    words: [
      AwingWord('Kó', '_'),
      AwingWord('ndɔtí', '_'),
      AwingWord('pɛntə', '_'),
      AwingWord('zâ', '_'),
      AwingWord('á', '_'),
      AwingWord('mbí', '_'),
      AwingWord('ndê', '_'),
      AwingWord('néŋə', '_'),
      AwingWord('yí', '_'),
      AwingWord('fîə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Akofé á koonə ntê lá ngá pá kê ná afû pám pô.",
    english: 'The coffee grains are falling off because they are not being sprayed with insecticide.',
    difficulty: 3,
    words: [
      AwingWord('Akofé', '_'),
      AwingWord('á', '_'),
      AwingWord('koonə', '_'),
      AwingWord('ntê', '_'),
      AwingWord('lá', '_'),
      AwingWord('ngá', '_'),
      AwingWord('pá', '_'),
      AwingWord('kê', '_'),
      AwingWord('ná', '_'),
      AwingWord('afû', '_'),
      AwingWord('pám', '_'),
      AwingWord('pô', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Atəənə ashûə á kóotə məshûə.",
    english: 'The fishtrap traps fish.',
    difficulty: 1,
    words: [
      AwingWord('Atəənə', '_'),
      AwingWord('ashûə', '_'),
      AwingWord('á', '_'),
      AwingWord('kóotə', '_'),
      AwingWord('məshûə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pí pətsə pó nô kosham lá ándó məjìə.",
    english: 'Some people drink kosham as if it is food.',
    difficulty: 2,
    words: [
      AwingWord('Pí', '_'),
      AwingWord('pətsə', '_'),
      AwingWord('pó', '_'),
      AwingWord('nô', '_'),
      AwingWord('kosham', '_'),
      AwingWord('lá', '_'),
      AwingWord('ándó', '_'),
      AwingWord('məjìə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "O lá' nchîə mbí kɔ fa'ə anu pá' á yí ná néŋə á gho ndzô.",
    english: 'When one lives in this world he should not do the sort of things that will lead him into trouble.',
    difficulty: 3,
    words: [
      AwingWord('O', '_'),
      AwingWord('lá\'', '_'),
      AwingWord('nchîə', '_'),
      AwingWord('mbí', '_'),
      AwingWord('kɔ', '_'),
      AwingWord('fa\'ə', '_'),
      AwingWord('anu', '_'),
      AwingWord('pá\'', '_'),
      AwingWord('á', '_'),
      AwingWord('yí', '_'),
      AwingWord('ná', '_'),
      AwingWord('néŋə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Kɔdtə mó ajú mbɔŋə tá fa'ə.",
    english: 'Eat a little thing before going to work.',
    difficulty: 2,
    words: [
      AwingWord('Kɔdtə', '_'),
      AwingWord('mó', '_'),
      AwingWord('ajú', '_'),
      AwingWord('mbɔŋə', '_'),
      AwingWord('tá', '_'),
      AwingWord('fa\'ə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ali'ə á pɔŋ lá məjì mə kɔ' əwə.",
    english: 'When land is fertile crops grows well.',
    difficulty: 2,
    words: [
      AwingWord('Ali\'ə', '_'),
      AwingWord('á', '_'),
      AwingWord('pɔŋ', '_'),
      AwingWord('lá', '_'),
      AwingWord('məjì', '_'),
      AwingWord('mə', '_'),
      AwingWord('kɔ\'', '_'),
      AwingWord('əwə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A kóga apó yá á mbí ndé.",
    english: 'He has scrubbed his hand on the wall.',
    difficulty: 2,
    words: [
      AwingWord('A', '_'),
      AwingWord('kóga', '_'),
      AwingWord('apó', '_'),
      AwingWord('yá', '_'),
      AwingWord('á', '_'),
      AwingWord('mbí', '_'),
      AwingWord('ndé', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbɛ́ŋ á kwə́ nətú' lā á kə́ nkɔ́lə tsɔ'ə nɔyeŋə́.",
    english: 'During the night a goat keeps on ruminating.',
    difficulty: 2,
    words: [
      AwingWord('Mbɛ', '_'),
      AwingWord('ŋ', '_'),
      AwingWord('á', '_'),
      AwingWord('kwə', '_'),
      AwingWord('nətú\'', '_'),
      AwingWord('lā', '_'),
      AwingWord('á', '_'),
      AwingWord('kə', '_'),
      AwingWord('nkɔ', '_'),
      AwingWord('lə', '_'),
      AwingWord('tsɔ\'ə', '_'),
      AwingWord('nɔyeŋə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Kɔ pi nkɔ́mtə mə.",
    english: 'Do not scratch me again.',
    difficulty: 1,
    words: [
      AwingWord('Kɔ', '_'),
      AwingWord('pi', '_'),
      AwingWord('nkɔ', '_'),
      AwingWord('mtə', '_'),
      AwingWord('mə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A kə́ pɔŋ ŋgə́ ŋwunə́ á kɔnə́ ŋgwə́ əyɪə́ ándó pə́ kɔnə́ na pɔ́.",
    english: 'It is bad for somebody to hit his wife as if she is an animal.',
    difficulty: 3,
    words: [
      AwingWord('A', '_'),
      AwingWord('kə', '_'),
      AwingWord('pɔŋ', '_'),
      AwingWord('ŋgə', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('á', '_'),
      AwingWord('kɔnə', '_'),
      AwingWord('ŋgwə', '_'),
      AwingWord('əyɪə', '_'),
      AwingWord('ándó', '_'),
      AwingWord('pə', '_'),
      AwingWord('kɔnə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pɔ́ nkə́ pɔ́ kə́ kɔ́'nə́ nə́ Yéso lā́ ándó ŋwu pɔ́ pə́ pɔ́ pɪə́.",
    english: 'Children were scrambling on Jesus as if he was their father.',
    difficulty: 3,
    words: [
      AwingWord('Pɔ', '_'),
      AwingWord('nkə', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('kə', '_'),
      AwingWord('kɔ', '_'),
      AwingWord('\'nə', '_'),
      AwingWord('nə', '_'),
      AwingWord('Yéso', '_'),
      AwingWord('lā', '_'),
      AwingWord('ándó', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('pɔ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Kɔŋ məŋkwə́'lə á chí lā́ ajúmə kə́ əwí kɔ́'ə pɔ́.",
    english: 'Nothing grows in a desert.',
    difficulty: 2,
    words: [
      AwingWord('Kɔŋ', '_'),
      AwingWord('məŋkwə', '_'),
      AwingWord('\'lə', '_'),
      AwingWord('á', '_'),
      AwingWord('chí', '_'),
      AwingWord('lā', '_'),
      AwingWord('ajúmə', '_'),
      AwingWord('kə', '_'),
      AwingWord('əwí', '_'),
      AwingWord('kɔ', '_'),
      AwingWord('\'ə', '_'),
      AwingWord('pɔ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Kɔŋ nɔyeŋə́ lā́ ŋjí məneemə.",
    english: 'Grassland is feeding ground for cattle.',
    difficulty: 1,
    words: [
      AwingWord('Kɔŋ', '_'),
      AwingWord('nɔyeŋə', '_'),
      AwingWord('lā', '_'),
      AwingWord('ŋjí', '_'),
      AwingWord('məneemə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ndzɔ'ə́ á íti' ńchí əghə́ nə́ pɪ pə́ kɔ̀ŋə́ pə́ nkɛ́ebə́.",
    english: 'In marriage nowadays people are more interested in money.',
    difficulty: 3,
    words: [
      AwingWord('Ndzɔ\'ə', '_'),
      AwingWord('á', '_'),
      AwingWord('íti\'', '_'),
      AwingWord('ńchí', '_'),
      AwingWord('əghə', '_'),
      AwingWord('nə', '_'),
      AwingWord('pɪ', '_'),
      AwingWord('pə', '_'),
      AwingWord('kɔ', '_'),
      AwingWord('ŋə', '_'),
      AwingWord('pə', '_'),
      AwingWord('nkɛ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A tə́ nkɔ́ŋkə ashə́'kə múto ají zə́ ndaŋə́.",
    english: 'He is rolling pass with that his broken car.',
    difficulty: 2,
    words: [
      AwingWord('A', '_'),
      AwingWord('tə', '_'),
      AwingWord('nkɔ', '_'),
      AwingWord('ŋkə', '_'),
      AwingWord('ashə', '_'),
      AwingWord('\'kə', '_'),
      AwingWord('múto', '_'),
      AwingWord('ají', '_'),
      AwingWord('zə', '_'),
      AwingWord('ndaŋə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mənó mə tə nkɔŋnə á mə m nkɔ'ə.",
    english: 'Snakes are slithering in the farm.',
    difficulty: 2,
    words: [
      AwingWord('Mənó', '_'),
      AwingWord('mə', '_'),
      AwingWord('tə', '_'),
      AwingWord('nkɔŋnə', '_'),
      AwingWord('á', '_'),
      AwingWord('mə', '_'),
      AwingWord('m', '_'),
      AwingWord('nkɔ\'ə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pə sogə atsə' əshɪ'nə lə á ɲwa'ə lə ɲgə kwɑŋ.",
    english: 'When a dress is thoroughly washed, it becomes perfectly clean.',
    difficulty: 2,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('sogə', '_'),
      AwingWord('atsə\'', '_'),
      AwingWord('əshɪ\'nə', '_'),
      AwingWord('lə', '_'),
      AwingWord('á', '_'),
      AwingWord('ɲwa\'ə', '_'),
      AwingWord('lə', '_'),
      AwingWord('ɲgə', '_'),
      AwingWord('kwɑŋ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pə lɔgə kwɑŋə nkɔɔmə lə nəkwɔ' nə achu əwə.",
    english: 'A piece of metal cleaner is often used to clean an achu mortar.',
    difficulty: 2,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('lɔgə', '_'),
      AwingWord('kwɑŋə', '_'),
      AwingWord('nkɔɔmə', '_'),
      AwingWord('lə', '_'),
      AwingWord('nəkwɔ\'', '_'),
      AwingWord('nə', '_'),
      AwingWord('achu', '_'),
      AwingWord('əwə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mə nkə a tə ńtyantə atú lə pə kwumə yí nə mbə á zó' əli'ə**.",
    english: 'A stubborn child needs to be taught a lesson with the hands before he changes.',
    difficulty: 3,
    words: [
      AwingWord('Mə', '_'),
      AwingWord('nkə', '_'),
      AwingWord('a', '_'),
      AwingWord('tə', '_'),
      AwingWord('ńtyantə', '_'),
      AwingWord('atú', '_'),
      AwingWord('lə', '_'),
      AwingWord('pə', '_'),
      AwingWord('kwumə', '_'),
      AwingWord('yí', '_'),
      AwingWord('nə', '_'),
      AwingWord('mbə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pə lɔgə nəfə nə kwúna ńtsɔŋkə asogə**.",
    english: 'Pig fat is used for making soap.',
    difficulty: 2,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('lɔgə', '_'),
      AwingWord('nəfə', '_'),
      AwingWord('nə', '_'),
      AwingWord('kwúna', '_'),
      AwingWord('ńtsɔŋkə', '_'),
      AwingWord('asogə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pəngyɛ pə kwú'tə afo ńtə ńdí'ə ali'ə**.",
    english: 'Women stoop in the farm hoeing.',
    difficulty: 2,
    words: [
      AwingWord('Pəngyɛ', '_'),
      AwingWord('pə', '_'),
      AwingWord('kwú\'tə', '_'),
      AwingWord('afo', '_'),
      AwingWord('ńtə', '_'),
      AwingWord('ńdí\'ə', '_'),
      AwingWord('ali\'ə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pó pó'ə mó yitsə ló a kyê mbi əjìə.",
    english: 'When some children are disciplined, they throw down themselves in rejection as if they have been desecrated.',
    difficulty: 2,
    words: [
      AwingWord('Pó', '_'),
      AwingWord('pó\'ə', '_'),
      AwingWord('mó', '_'),
      AwingWord('yitsə', '_'),
      AwingWord('ló', '_'),
      AwingWord('a', '_'),
      AwingWord('kyê', '_'),
      AwingWord('mbi', '_'),
      AwingWord('əjìə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Móonə ä kyikə.",
    english: 'The child is stubborn.',
    difficulty: 1,
    words: [
      AwingWord('Móonə', '_'),
      AwingWord('ä', '_'),
      AwingWord('kyikə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "O yǒ lá' ghen śwí ló əghā akə?",
    english: 'When shall you ever go there.',
    difficulty: 2,
    words: [
      AwingWord('O', '_'),
      AwingWord('yǒ', '_'),
      AwingWord('lá\'', '_'),
      AwingWord('ghen', '_'),
      AwingWord('śwí', '_'),
      AwingWord('ló', '_'),
      AwingWord('əghā', '_'),
      AwingWord('akə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ghen ńda'ə móonə.",
    english: 'Go and announce the birth of a child.',
    difficulty: 1,
    words: [
      AwingWord('Ghen', '_'),
      AwingWord('ńda\'ə', '_'),
      AwingWord('móonə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "O la'ə ló ńgə akə əló!",
    english: 'What are you saying!',
    difficulty: 2,
    words: [
      AwingWord('O', '_'),
      AwingWord('la\'ə', '_'),
      AwingWord('ló', '_'),
      AwingWord('ńgə', '_'),
      AwingWord('akə', '_'),
      AwingWord('əló', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Lə túg tɔ'ə mbelɔlɔ' ńtúg pələəmə alá' mbíwíŋə.",
    english: 'Only fulanis have horses in Awing.',
    difficulty: 2,
    words: [
      AwingWord('Lə', '_'),
      AwingWord('túg', '_'),
      AwingWord('tɔ\'ə', '_'),
      AwingWord('mbelɔlɔ\'', '_'),
      AwingWord('ńtúg', '_'),
      AwingWord('pələəmə', '_'),
      AwingWord('alá\'', '_'),
      AwingWord('mbíwíŋə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A **tǝ sǝbnǝ anuǝ lǝzámǝ ajíǝ**.",
    english: 'He is worried about his exam.',
    difficulty: 2,
    words: [
      AwingWord('A', '_'),
      AwingWord('tǝ', '_'),
      AwingWord('sǝbnǝ', '_'),
      AwingWord('anuǝ', '_'),
      AwingWord('lǝzámǝ', '_'),
      AwingWord('ajíǝ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbênə, a jwíta afunə, o sóŋə lə anu?",
    english: 'He has killed a leopard!',
    difficulty: 2,
    words: [
      AwingWord('Mbênə', '_'),
      AwingWord('a', '_'),
      AwingWord('jwíta', '_'),
      AwingWord('afunə', '_'),
      AwingWord('o', '_'),
      AwingWord('sóŋə', '_'),
      AwingWord('lə', '_'),
      AwingWord('anu', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ngwè mbəəmə apəəmə a kələ na lə alə atsəmə.",
    english: 'A hunter\'s wife eats meat everyday.',
    difficulty: 2,
    words: [
      AwingWord('Ngwè', '_'),
      AwingWord('mbəəmə', '_'),
      AwingWord('apəəmə', '_'),
      AwingWord('a', '_'),
      AwingWord('kələ', '_'),
      AwingWord('na', '_'),
      AwingWord('lə', '_'),
      AwingWord('alə', '_'),
      AwingWord('atsəmə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Məkwú mə mə kwɛdnə.",
    english: 'That rice has spilt.',
    difficulty: 1,
    words: [
      AwingWord('Məkwú', '_'),
      AwingWord('mə', '_'),
      AwingWord('mə', '_'),
      AwingWord('kwɛdnə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbɔ o jwítə mɔpɔŋə mɔ á pə ŋgə o jwítə ŋwunə.",
    english: 'If you kill a foetus it means you have killed a human being.',
    difficulty: 3,
    words: [
      AwingWord('Mbɔ', '_'),
      AwingWord('o', '_'),
      AwingWord('jwítə', '_'),
      AwingWord('mɔpɔŋə', '_'),
      AwingWord('mɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('pə', '_'),
      AwingWord('ŋgə', '_'),
      AwingWord('o', '_'),
      AwingWord('jwítə', '_'),
      AwingWord('ŋwunə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Kɔ kwum məkwú míə.",
    english: 'Do not touch that rice.',
    difficulty: 1,
    words: [
      AwingWord('Kɔ', '_'),
      AwingWord('kwum', '_'),
      AwingWord('məkwú', '_'),
      AwingWord('míə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mó Əsẽ ló nda' nchwádkə ŋwu məsəŋə.",
    english: 'The son of God is the only saviour for humanity.',
    difficulty: 2,
    words: [
      AwingWord('Mó', '_'),
      AwingWord('Əsẽ', '_'),
      AwingWord('ló', '_'),
      AwingWord('nda\'', '_'),
      AwingWord('nchwádkə', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('məsəŋə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ajú zi ló ndenə.",
    english: 'This thing is an old one Pl.',
    difficulty: 1,
    words: [
      AwingWord('Ajú', '_'),
      AwingWord('zi', '_'),
      AwingWord('ló', '_'),
      AwingWord('ndenə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pə túmə mə pá' a zó'nə nə a nyi ló nə ndə.",
    english: 'When an obedient child is commissioned, he does not walk slowly, he goes running.',
    difficulty: 3,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('túmə', '_'),
      AwingWord('mə', '_'),
      AwingWord('pá\'', '_'),
      AwingWord('a', '_'),
      AwingWord('zó\'nə', '_'),
      AwingWord('nə', '_'),
      AwingWord('a', '_'),
      AwingWord('nyi', '_'),
      AwingWord('ló', '_'),
      AwingWord('nə', '_'),
      AwingWord('ndə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pen yi tsáb ɔghá nda'ɔ, ndi' chiɔ ndɛ.",
    english: 'There is smoke in the house, we will speak another time.',
    difficulty: 2,
    words: [
      AwingWord('Pen', '_'),
      AwingWord('yi', '_'),
      AwingWord('tsáb', '_'),
      AwingWord('ɔghá', '_'),
      AwingWord('nda\'ɔ', '_'),
      AwingWord('ndi\'', '_'),
      AwingWord('chiɔ', '_'),
      AwingWord('ndɛ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  // AwingSentence(
  // awing: "Yis á ndzəŋ mənumə.",
  // english: 'Come in the afternoon.',
  // difficulty: 1,
  // words: [
  // AwingWord('Yis', '_'),
  // AwingWord('á', '_'),
  // AwingWord('ndzəŋ', '_'),
  // AwingWord('mənumə', '_'),
  // ],
  // ),  // REMOVED Session 66u similar-spelling: same English as the block at line 257 (Yîə á ndzəŋ mənumə.)

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A kwúna á ndzɔ̃.",
    english: 'He has got into problems.',
    difficulty: 1,
    words: [
      AwingWord('A', '_'),
      AwingWord('kwúna', '_'),
      AwingWord('á', '_'),
      AwingWord('ndzɔ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "It only involves feeding of guests.",
    english: 'This practice is unpopular.',
    difficulty: 2,
    words: [
      AwingWord('It', '_'),
      AwingWord('only', '_'),
      AwingWord('involves', '_'),
      AwingWord('feeding', '_'),
      AwingWord('of', '_'),
      AwingWord('guests', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A tsɔ̃' ntso ndɛ nə kɪə.",
    english: 'He has opened the door with a key.',
    difficulty: 2,
    words: [
      AwingWord('A', '_'),
      AwingWord('tsɔ', '_'),
      AwingWord('\'', '_'),
      AwingWord('ntso', '_'),
      AwingWord('ndɛ', '_'),
      AwingWord('nə', '_'),
      AwingWord('kɪə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pə wē nəfed nə ngo' lə nə ŋwunə a fa' nə n̄təənə anuə.",
    english: 'Titled feathers are given to people who do great things.',
    difficulty: 3,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('wē', '_'),
      AwingWord('nəfed', '_'),
      AwingWord('nə', '_'),
      AwingWord('ngo\'', '_'),
      AwingWord('lə', '_'),
      AwingWord('nə', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('fa\'', '_'),
      AwingWord('nə', '_'),
      AwingWord('n', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Nənta nə́ nəpiəmbə́ŋ lə́ afuə.",
    english: 'The fruit of a quiny tree is used as medicine.',
    difficulty: 1,
    words: [
      AwingWord('Nənta', '_'),
      AwingWord('nə', '_'),
      AwingWord('nəpiəmbə', '_'),
      AwingWord('ŋ', '_'),
      AwingWord('lə', '_'),
      AwingWord('afuə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "N **ńkɛ́ lɔ́ ngaŋəfa' əgho pɔ́*.",
    english: 'Am not your servant Pl.',
    difficulty: 2,
    words: [
      AwingWord('N', '_'),
      AwingWord('ńkɛ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('ngaŋəfa\'', '_'),
      AwingWord('əgho', '_'),
      AwingWord('pɔ', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pita **lɔ́ ngaŋkəpeenə** **mə**.",
    english: 'Peter is my enemy.',
    difficulty: 1,
    words: [
      AwingWord('Pita', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('ngaŋkəpeenə', '_'),
      AwingWord('mə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ngaŋnəghéenə a **yĩ yĩə**.",
    english: 'A guest will come.',
    difficulty: 1,
    words: [
      AwingWord('Ngaŋnəghéenə', '_'),
      AwingWord('a', '_'),
      AwingWord('yĩ', '_'),
      AwingWord('yĩə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pi pə yíə ali'ə nə, lə ngwaŋ yí ngwíŋ pə ŋeŋə**.",
    english: 'People have come here but a greater part of them have gone.',
    difficulty: 3,
    words: [
      AwingWord('Pi', '_'),
      AwingWord('pə', '_'),
      AwingWord('yíə', '_'),
      AwingWord('ali\'ə', '_'),
      AwingWord('nə', '_'),
      AwingWord('lə', '_'),
      AwingWord('ngwaŋ', '_'),
      AwingWord('yí', '_'),
      AwingWord('ngwíŋ', '_'),
      AwingWord('pə', '_'),
      AwingWord('ŋeŋə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Only men and boys of Njom participate in this dance.",
    english: 'They wear masks and meet on the fourth day of the week.',
    difficulty: 2,
    words: [
      AwingWord('Only', '_'),
      AwingWord('men', '_'),
      AwingWord('and', '_'),
      AwingWord('boys', '_'),
      AwingWord('of', '_'),
      AwingWord('Njom', '_'),
      AwingWord('participate', '_'),
      AwingWord('in', '_'),
      AwingWord('this', '_'),
      AwingWord('dance', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A yīə á nkyakəpeŋə.",
    english: 'He has come at dawn.',
    difficulty: 1,
    words: [
      AwingWord('A', '_'),
      AwingWord('yīə', '_'),
      AwingWord('á', '_'),
      AwingWord('nkyakəpeŋə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbə' ŋwunə jī n̩t̩d yə, á pə ŋgə lə akəkɔgə.",
    english: 'When one consumes his working capital know that he is a fool.',
    difficulty: 2,
    words: [
      AwingWord('Mbə\'', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('jī', '_'),
      AwingWord('n', '_'),
      AwingWord('t', '_'),
      AwingWord('d', '_'),
      AwingWord('yə', '_'),
      AwingWord('á', '_'),
      AwingWord('pə', '_'),
      AwingWord('ŋgə', '_'),
      AwingWord('lə', '_'),
      AwingWord('akəkɔgə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbə' ŋwunə tə ńdoonə ŋgə əsə a zó'ə anuə ajī, a ghelə n̩təənə acha't̩s̩ə.",
    english: 'If one wants God to hear his prayers he should do a fast.',
    difficulty: 3,
    words: [
      AwingWord('Mbə\'', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('tə', '_'),
      AwingWord('ńdoonə', '_'),
      AwingWord('ŋgə', '_'),
      AwingWord('əsə', '_'),
      AwingWord('a', '_'),
      AwingWord('zó\'ə', '_'),
      AwingWord('anuə', '_'),
      AwingWord('ajī', '_'),
      AwingWord('a', '_'),
      AwingWord('ghelə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbo' o zó' ntso ndê ghé nyâ', jî ngə ajú tsə kwúna.",
    english: 'When the door makes a scratching sound know something has come in.',
    difficulty: 3,
    words: [
      AwingWord('Mbo\'', '_'),
      AwingWord('o', '_'),
      AwingWord('zó\'', '_'),
      AwingWord('ntso', '_'),
      AwingWord('ndê', '_'),
      AwingWord('ghé', '_'),
      AwingWord('nyâ\'', '_'),
      AwingWord('jî', '_'),
      AwingWord('ngə', '_'),
      AwingWord('ajú', '_'),
      AwingWord('tsə', '_'),
      AwingWord('kwúna', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbəŋ tə ndō nyanya'nya' lə kəyé ŋwunə kəŋə mə kwa' nə məm əwə.",
    english: 'When the rain is drizzling children like playing in it.',
    difficulty: 3,
    words: [
      AwingWord('Mbəŋ', '_'),
      AwingWord('tə', '_'),
      AwingWord('ndō', '_'),
      AwingWord('nyanya\'nya\'', '_'),
      AwingWord('lə', '_'),
      AwingWord('kəyé', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('kəŋə', '_'),
      AwingWord('mə', '_'),
      AwingWord('kwa\'', '_'),
      AwingWord('nə', '_'),
      AwingWord('məm', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A pīə́ ŋwu mbyàŋnə.",
    english: 'She has given birth to a male child.',
    difficulty: 1,
    words: [
      AwingWord('A', '_'),
      AwingWord('pīə', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('mbyàŋnə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pábánduuŋgɔ'ə́ á zá nchíə́ á ndu məŋgwúbə.",
    english: 'The lizard is often found on rocks.',
    difficulty: 2,
    words: [
      AwingWord('Pábánduuŋgɔ\'ə', '_'),
      AwingWord('á', '_'),
      AwingWord('zá', '_'),
      AwingWord('nchíə', '_'),
      AwingWord('á', '_'),
      AwingWord('ndu', '_'),
      AwingWord('məŋgwúbə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Maŋ tə́ mbábtə mbó mə́ á nəkyelə́.",
    english: 'Am keeping my hands by the fire for a little warmth.',
    difficulty: 2,
    words: [
      AwingWord('Maŋ', '_'),
      AwingWord('tə', '_'),
      AwingWord('mbábtə', '_'),
      AwingWord('mbó', '_'),
      AwingWord('mə', '_'),
      AwingWord('á', '_'),
      AwingWord('nəkyelə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "O lítə́ ándó pámtə 121 péŋə pá'mághéemá.",
    english: 'You are as jumpy as a flee.',
    difficulty: 2,
    words: [
      AwingWord('O', '_'),
      AwingWord('lítə', '_'),
      AwingWord('ándó', '_'),
      AwingWord('pámtə', '_'),
      AwingWord('121', '_'),
      AwingWord('péŋə', '_'),
      AwingWord('pá\'mághéemá', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "O sog ətsə' o panə á məm mənumə ə jūmə.",
    english: 'Hang up washed dresses in the sun so they get dry.',
    difficulty: 2,
    words: [
      AwingWord('O', '_'),
      AwingWord('sog', '_'),
      AwingWord('ətsə\'', '_'),
      AwingWord('o', '_'),
      AwingWord('panə', '_'),
      AwingWord('á', '_'),
      AwingWord('məm', '_'),
      AwingWord('mənumə', '_'),
      AwingWord('ə', '_'),
      AwingWord('jūmə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pánkə akə' ghenə á əfó.",
    english: 'Where is the stool that accompanied this chair.',
    difficulty: 1,
    words: [
      AwingWord('Pánkə', '_'),
      AwingWord('akə\'', '_'),
      AwingWord('ghenə', '_'),
      AwingWord('á', '_'),
      AwingWord('əfó', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbīwiŋə a jīə yī lā təs'ə paŋ səntē pə shishīə.",
    english: 'An Awing man knows only red and black pepper.',
    difficulty: 2,
    words: [
      AwingWord('Mbīwiŋə', '_'),
      AwingWord('a', '_'),
      AwingWord('jīə', '_'),
      AwingWord('yī', '_'),
      AwingWord('lā', '_'),
      AwingWord('təs\'ə', '_'),
      AwingWord('paŋ', '_'),
      AwingWord('səntē', '_'),
      AwingWord('pə', '_'),
      AwingWord('shishīə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pə fōŋə yī nə paŋ səŋ lā ntē ŋgə á paŋə.",
    english: 'A weaver bird is called, red bird, because it is red.',
    difficulty: 3,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('fōŋə', '_'),
      AwingWord('yī', '_'),
      AwingWord('nə', '_'),
      AwingWord('paŋ', '_'),
      AwingWord('səŋ', '_'),
      AwingWord('lā', '_'),
      AwingWord('ntē', '_'),
      AwingWord('ŋgə', '_'),
      AwingWord('á', '_'),
      AwingWord('paŋə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ndē pá' ə paŋ nə əfó.",
    english: 'Where is a red house.',
    difficulty: 2,
    words: [
      AwingWord('Ndē', '_'),
      AwingWord('pá\'', '_'),
      AwingWord('ə', '_'),
      AwingWord('paŋ', '_'),
      AwingWord('nə', '_'),
      AwingWord('əfó', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Amú'ə á paŋnə á nkā' maŋə.",
    english: 'Bananas are ripe in my farm.',
    difficulty: 2,
    words: [
      AwingWord('Amú\'ə', '_'),
      AwingWord('á', '_'),
      AwingWord('paŋnə', '_'),
      AwingWord('á', '_'),
      AwingWord('nkā\'', '_'),
      AwingWord('maŋə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pə péebə lā ngəsāŋ pá' á nyá' nə ŋjūmə.",
    english: 'You bake maize that is a little dry.',
    difficulty: 2,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('péebə', '_'),
      AwingWord('lā', '_'),
      AwingWord('ngəsāŋ', '_'),
      AwingWord('pá\'', '_'),
      AwingWord('á', '_'),
      AwingWord('nyá\'', '_'),
      AwingWord('nə', '_'),
      AwingWord('ŋjūmə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Peelə móonə á nkadtə.",
    english: 'Carry the child on the back.',
    difficulty: 1,
    words: [
      AwingWord('Peelə', '_'),
      AwingWord('móonə', '_'),
      AwingWord('á', '_'),
      AwingWord('nkadtə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbə' o peenə mə ŋwu mbī əgho á kwūə.",
    english: 'If you hate another\'s child and give birth to yours it will die.',
    difficulty: 2,
    words: [
      AwingWord('Mbə\'', '_'),
      AwingWord('o', '_'),
      AwingWord('peenə', '_'),
      AwingWord('mə', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('mbī', '_'),
      AwingWord('əgho', '_'),
      AwingWord('á', '_'),
      AwingWord('kwūə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A pe'ə əfa'ə lā akə.",
    english: 'What was he doing.',
    difficulty: 1,
    words: [
      AwingWord('A', '_'),
      AwingWord('pe\'ə', '_'),
      AwingWord('əfa\'ə', '_'),
      AwingWord('lā', '_'),
      AwingWord('akə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pə sōŋ ŋgə ŋwunə a péŋə á məmə akoobə.",
    english: 'Rumours are that somebody is missing in the forest.',
    difficulty: 2,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('sōŋ', '_'),
      AwingWord('ŋgə', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('péŋə', '_'),
      AwingWord('á', '_'),
      AwingWord('məmə', '_'),
      AwingWord('akoobə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pə sɔŋ ŋgə móonə əŋwa'lə ə péŋə ə əfooghəəmə.",
    english: 'People say a school child is missing in lake Awing.',
    difficulty: 2,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('sɔŋ', '_'),
      AwingWord('ŋgə', '_'),
      AwingWord('móonə', '_'),
      AwingWord('əŋwa\'lə', '_'),
      AwingWord('ə', '_'),
      AwingWord('péŋə', '_'),
      AwingWord('ə', '_'),
      AwingWord('əfooghəəmə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Maŋ péŋkə nkoŋə əŋwa'lə mə.",
    english: 'I have lost my pen.',
    difficulty: 1,
    words: [
      AwingWord('Maŋ', '_'),
      AwingWord('péŋkə', '_'),
      AwingWord('nkoŋə', '_'),
      AwingWord('əŋwa\'lə', '_'),
      AwingWord('mə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pə nɔŋkə nki təpɔŋ nə ŋwu tsi lə ə péŋkə əŋwiə yə.",
    english: 'There are some people who lose their breath on hearing any bad news.',
    difficulty: 3,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('nɔŋkə', '_'),
      AwingWord('nki', '_'),
      AwingWord('təpɔŋ', '_'),
      AwingWord('nə', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('tsi', '_'),
      AwingWord('lə', '_'),
      AwingWord('ə', '_'),
      AwingWord('péŋkə', '_'),
      AwingWord('əŋwiə', '_'),
      AwingWord('yə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbɔŋə ŋwunə ə chĩə mbí mbé mbɔŋə ə kwũə.",
    english: 'Rather than stay alive and be mad, one be dead rather.',
    difficulty: 2,
    words: [
      AwingWord('Mbɔŋə', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('ə', '_'),
      AwingWord('chĩə', '_'),
      AwingWord('mbí', '_'),
      AwingWord('mbé', '_'),
      AwingWord('mbɔŋə', '_'),
      AwingWord('ə', '_'),
      AwingWord('kwũə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Gho nə fi'tə ə yí lə ə pə sɔŋ ŋgə əkə?",
    english: 'You told him, what then did he say?',
    difficulty: 3,
    words: [
      AwingWord('Gho', '_'),
      AwingWord('nə', '_'),
      AwingWord('fi\'tə', '_'),
      AwingWord('ə', '_'),
      AwingWord('yí', '_'),
      AwingWord('lə', '_'),
      AwingWord('ə', '_'),
      AwingWord('pə', '_'),
      AwingWord('sɔŋ', '_'),
      AwingWord('ŋgə', '_'),
      AwingWord('əkə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pəkwúna pə lə pipə əwə.",
    english: 'Those pigs are whose own.',
    difficulty: 1,
    words: [
      AwingWord('Pəkwúna', '_'),
      AwingWord('pə', '_'),
      AwingWord('lə', '_'),
      AwingWord('pipə', '_'),
      AwingWord('əwə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pəmənu pɛn nəŋhəmə ə nətú' ko' lə pəlám pə pəgnə ŋgə pəb.",
    english: 'When it is ten pm, all the bush lamps go off.',
    difficulty: 3,
    words: [
      AwingWord('Pəmənu', '_'),
      AwingWord('pɛn', '_'),
      AwingWord('nəŋhəmə', '_'),
      AwingWord('ə', '_'),
      AwingWord('nətú\'', '_'),
      AwingWord('ko\'', '_'),
      AwingWord('lə', '_'),
      AwingWord('pəlám', '_'),
      AwingWord('pə', '_'),
      AwingWord('pəgnə', '_'),
      AwingWord('ŋgə', '_'),
      AwingWord('pəb', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Pəg yi nə pətā pəgə, sōŋ nə pó ngə pó yi nə pəpóobə.",
    english: 'We have brought our fathers, tell them to come along with theirs.',
    difficulty: 3,
    words: [
      AwingWord('Pəg', '_'),
      AwingWord('yi', '_'),
      AwingWord('nə', '_'),
      AwingWord('pətā', '_'),
      AwingWord('pəgə', '_'),
      AwingWord('sōŋ', '_'),
      AwingWord('nə', '_'),
      AwingWord('pó', '_'),
      AwingWord('ngə', '_'),
      AwingWord('pó', '_'),
      AwingWord('yi', '_'),
      AwingWord('nə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ajumə mə lə fē pī pīə.",
    english: 'My thing has been given by those people.',
    difficulty: 2,
    words: [
      AwingWord('Ajumə', '_'),
      AwingWord('mə', '_'),
      AwingWord('lə', '_'),
      AwingWord('fē', '_'),
      AwingWord('pī', '_'),
      AwingWord('pīə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Sóŋ ná pó ńgə pó yīə.",
    english: 'Tell them to come.',
    difficulty: 2,
    words: [
      AwingWord('Sóŋ', '_'),
      AwingWord('ná', '_'),
      AwingWord('pó', '_'),
      AwingWord('ńgə', '_'),
      AwingWord('pó', '_'),
      AwingWord('yīə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Sáambanə á tyantə.",
    english: 'A lion is strong.',
    difficulty: 1,
    words: [
      AwingWord('Sáambanə', '_'),
      AwingWord('á', '_'),
      AwingWord('tyantə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Sá'ə anuə á məteenə.",
    english: 'Give a public announcement in the market.',
    difficulty: 1,
    words: [
      AwingWord('Sá\'ə', '_'),
      AwingWord('anuə', '_'),
      AwingWord('á', '_'),
      AwingWord('məteenə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Sóokə fɪə apɔ́ á nətɔglə.",
    english: 'Put a finger into the ear V.',
    difficulty: 1,
    words: [
      AwingWord('Sóokə', '_'),
      AwingWord('fɪə', '_'),
      AwingWord('apɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('nətɔglə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Ngwú áfyád mbɛ́ á sóolə á ngɔlə.",
    english: 'A dog pursued a mole and it went into the hole.',
    difficulty: 2,
    words: [
      AwingWord('Ngwú', '_'),
      AwingWord('áfyád', '_'),
      AwingWord('mbɛ', '_'),
      AwingWord('á', '_'),
      AwingWord('sóolə', '_'),
      AwingWord('á', '_'),
      AwingWord('ngɔlə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "A tə sɔbnə anuə ləzəmə ají zə.",
    english: 'He is worried about his exam.',
    difficulty: 2,
    words: [
      AwingWord('A', '_'),
      AwingWord('tə', '_'),
      AwingWord('sɔbnə', '_'),
      AwingWord('anuə', '_'),
      AwingWord('ləzəmə', '_'),
      AwingWord('ají', '_'),
      AwingWord('zə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Nden **məngyə** a wə **əpú** **məg** lə **ə** **shwaalə**.",
    english: 'It is odd for an old woman to wear eye glasses.',
    difficulty: 2,
    words: [
      AwingWord('Nden', '_'),
      AwingWord('məngyə', '_'),
      AwingWord('a', '_'),
      AwingWord('wə', '_'),
      AwingWord('əpú', '_'),
      AwingWord('məg', '_'),
      AwingWord('lə', '_'),
      AwingWord('ə', '_'),
      AwingWord('shwaalə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbɔ' o fê **shwa'** nə **móonə** a **nèŋ** **məfəŋ** **əwə** **mbi** **yə**.",
    english: 'If you give a razor blade to a child he will wound himself with.',
    difficulty: 3,
    words: [
      AwingWord('Mbɔ\'', '_'),
      AwingWord('o', '_'),
      AwingWord('fê', '_'),
      AwingWord('shwa\'', '_'),
      AwingWord('nə', '_'),
      AwingWord('móonə', '_'),
      AwingWord('a', '_'),
      AwingWord('nèŋ', '_'),
      AwingWord('məfəŋ', '_'),
      AwingWord('əwə', '_'),
      AwingWord('mbi', '_'),
      AwingWord('yə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "O **shwáŋtə** **ŋwu** **nə** **atsáb** **yə** **əshí'nə** **lə** a **zó'ə** **anuə** **azó**.",
    english: 'If you persuade somebody with good words he listens to you.',
    difficulty: 3,
    words: [
      AwingWord('O', '_'),
      AwingWord('shwáŋtə', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('nə', '_'),
      AwingWord('atsáb', '_'),
      AwingWord('yə', '_'),
      AwingWord('əshí\'nə', '_'),
      AwingWord('lə', '_'),
      AwingWord('a', '_'),
      AwingWord('zó\'ə', '_'),
      AwingWord('anuə', '_'),
      AwingWord('azó', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mbɔ' **ŋwunə** a **ma'ə** **anu** **əshwée** a **pɔŋ** **ńgə** a **pi** **moomə**.",
    english: 'If one misses something it is good to try again.',
    difficulty: 3,
    words: [
      AwingWord('Mbɔ\'', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('ma\'ə', '_'),
      AwingWord('anu', '_'),
      AwingWord('əshwée', '_'),
      AwingWord('a', '_'),
      AwingWord('pɔŋ', '_'),
      AwingWord('ńgə', '_'),
      AwingWord('a', '_'),
      AwingWord('pi', '_'),
      AwingWord('moomə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mónumə á tə ńtē.",
    english: 'The sun is shinning.',
    difficulty: 1,
    words: [
      AwingWord('Mónumə', '_'),
      AwingWord('á', '_'),
      AwingWord('tə', '_'),
      AwingWord('ńtē', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  // AwingSentence(
  // awing: "A tá ńgenə afoona.",
  // english: 'He is going to the farm.',
  // difficulty: 1,
  // words: [
  // AwingWord('A', '_'),
  // AwingWord('tá', '_'),
  // AwingWord('ńgenə', '_'),
  // AwingWord('afoona', '_'),
  // ],
  // ),  // REMOVED Session 66u similar-spelling: same English as the block at line 144 (A tə́ ńgenə afoonə.)

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Məntəlásə á pwódnə ló ńgá tāb.",
    english: 'Matress is so soft.',
    difficulty: 2,
    words: [
      AwingWord('Məntəlásə', '_'),
      AwingWord('á', '_'),
      AwingWord('pwódnə', '_'),
      AwingWord('ló', '_'),
      AwingWord('ńgá', '_'),
      AwingWord('tāb', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Mó nkə a jí ná ənuə a kwúnə aŋwa'lə a kə ńgenə ló ńgá təə.",
    english: 'When an intelligent child starts schooling, he keeps going non-stop.',
    difficulty: 3,
    words: [
      AwingWord('Mó', '_'),
      AwingWord('nkə', '_'),
      AwingWord('a', '_'),
      AwingWord('jí', '_'),
      AwingWord('ná', '_'),
      AwingWord('ənuə', '_'),
      AwingWord('a', '_'),
      AwingWord('kwúnə', '_'),
      AwingWord('aŋwa\'lə', '_'),
      AwingWord('a', '_'),
      AwingWord('kə', '_'),
      AwingWord('ńgenə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  // AwingSentence(
  // awing: "Ayənə á toonə atsə'ə mə.",
  // english: 'The iron has singed my dress.',
  // difficulty: 1,
  // words: [
  // AwingWord('Ayənə', '_'),
  // AwingWord('á', '_'),
  // AwingWord('toonə', '_'),
  // AwingWord('atsə\'ə', '_'),
  // AwingWord('mə', '_'),
  // ],
  // ),  // REMOVED Session 66u similar-spelling: same English as the block at line 222 (Ayonə á toonô atsa'á ma.)

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  // AwingSentence(
  // awing: "Á kə pəŋə mə túg nə wələ á ní téshú pō.",
  // english: 'It is not good to carry a lot of weight.',
  // difficulty: 3,
  // words: [
  // AwingWord('Á', '_'),
  // AwingWord('kə', '_'),
  // AwingWord('pəŋə', '_'),
  // AwingWord('mə', '_'),
  // AwingWord('túg', '_'),
  // AwingWord('nə', '_'),
  // AwingWord('wələ', '_'),
  // AwingWord('á', '_'),
  // AwingWord('ní', '_'),
  // AwingWord('téshú', '_'),
  // AwingWord('pō', '_'),
  // ],
  // ),  // REMOVED Session 66u similar-spelling: same English as the block at line 381 (Á kè poŋə mə́ túg ná wélə á ńi)

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Kwúna wə lə yī əwə.",
    english: 'That pig is whose own.',
    difficulty: 1,
    words: [
      AwingWord('Kwúna', '_'),
      AwingWord('wə', '_'),
      AwingWord('lə', '_'),
      AwingWord('yī', '_'),
      AwingWord('əwə', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Kwúneemə á pe' ńchīə ali' ghenə, wəələ á áfó?",
    english: 'There was a pig here, where is it.',
    difficulty: 2,
    words: [
      AwingWord('Kwúneemə', '_'),
      AwingWord('á', '_'),
      AwingWord('pe\'', '_'),
      AwingWord('ńchīə', '_'),
      AwingWord('ali\'', '_'),
      AwingWord('ghenə', '_'),
      AwingWord('wəələ', '_'),
      AwingWord('á', '_'),
      AwingWord('áfó', '_'),
    ],
  ),

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  // AwingSentence(
  // awing: "Pi pə wiŋ pó chīə á Ndəwálə nǝənə.",
  // english: 'There are many great people in Douala.',
  // difficulty: 2,
  // words: [
  // AwingWord('Pi', '_'),
  // AwingWord('pə', '_'),
  // AwingWord('wiŋ', '_'),
  // AwingWord('pó', '_'),
  // AwingWord('chīə', '_'),
  // AwingWord('á', '_'),
  // AwingWord('Ndəwálə', '_'),
  // AwingWord('nǝənə', '_'),
  // ],
  // ),  // REMOVED Session 66u similar-spelling: same English as the block at line 331 (Pi pə́ wiŋ pó chîə á Ndəwálə̌ )

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  // AwingSentence(
  // awing: "Dwu yi lā tā mə.",
  // english: 'That man is my father.',
  // difficulty: 1,
  // words: [
  // AwingWord('Dwu', '_'),
  // AwingWord('yi', '_'),
  // AwingWord('lā', '_'),
  // AwingWord('tā', '_'),
  // AwingWord('mə', '_'),
  // ],
  // ),  // REMOVED Session 66u similar-spelling: same English as the block at line 168 (Ŋwu yî lə tä mə.)

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  // AwingSentence(
  // awing: "O kə pe' pə sōŋ nə maŋ zá'ə a pəŋə yía.",
  // english: 'You were suppose to tell me before he comes.',
  // difficulty: 3,
  // words: [
  // AwingWord('O', '_'),
  // AwingWord('kə', '_'),
  // AwingWord('pe\'', '_'),
  // AwingWord('pə', '_'),
  // AwingWord('sōŋ', '_'),
  // AwingWord('nə', '_'),
  // AwingWord('maŋ', '_'),
  // AwingWord('zá\'ə', '_'),
  // AwingWord('a', '_'),
  // AwingWord('pəŋə', '_'),
  // AwingWord('yía', '_'),
  // ],
  // ),  // REMOVED Session 66u similar-spelling: same English as the block at line 399 (O kə pe' pə́ səŋ ná maŋ zá'ə a)

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  // AwingSentence(
  // awing: "Ajú zə̃ á pə̃gə.",
  // english: 'That thing is spoilt.',
  // difficulty: 1,
  // words: [
  // AwingWord('Ajú', '_'),
  // AwingWord('zə', '_'),
  // AwingWord('á', '_'),
  // AwingWord('pə', '_'),
  // AwingWord('gə', '_'),
  // ],
  // ),  // REMOVED Session 66u similar-spelling: same English as the block at line 200 (Ajú zə̂ á pəgə.)

  // DICT batch 4 — added Session 63 Part H (fresh Mistral OCR)
  AwingSentence(
    awing: "Proper nouns: Mbá'chi, Apənə ná Mbyáb tá nkó'ə atíə.",
    english: 'Mbachi, Apene and Mbyabe PROG climb tree Mbachi, Apene and Mbyabe are climbing a tree.',
    difficulty: 2,
    words: [
      AwingWord('Proper', '_'),
      AwingWord('nouns', '_'),
      AwingWord('Mbá\'chi', '_'),
      AwingWord('Apənə', '_'),
      AwingWord('ná', '_'),
      AwingWord('Mbyáb', '_'),
      AwingWord('tá', '_'),
      AwingWord('nkó\'ə', '_'),
      AwingWord('atíə', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Mbó chigə ɲwu mbɨwɨŋə á chí ló á kè yá afanŋə á ndɔ'ə alá' kɔŋ pó.",
    english: 'The traditional Awing man does not accept embrace in public.',
    difficulty: 3,
    words: [
      AwingWord('Mbó', '_'),
      AwingWord('chigə', '_'),
      AwingWord('ɲwu', '_'),
      AwingWord('mbɨwɨŋə', '_'),
      AwingWord('á', '_'),
      AwingWord('chí', '_'),
      AwingWord('ló', '_'),
      AwingWord('á', '_'),
      AwingWord('kè', '_'),
      AwingWord('yá', '_'),
      AwingWord('afanŋə', '_'),
      AwingWord('á', '_'),
      AwingWord('ndɔ\'ə', '_'),
      AwingWord('alá\'', '_'),
      AwingWord('kɔŋ', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Á pɔŋə á mə túg nə afo'ə, lá mbə ńchígə mbɔŋə á mə túg nə mbwódnə.",
    english: 'It is good to have riches, but even better to have peace.',
    difficulty: 3,
    words: [
      AwingWord('Á', '_'),
      AwingWord('pɔŋə', '_'),
      AwingWord('á', '_'),
      AwingWord('mə', '_'),
      AwingWord('túg', '_'),
      AwingWord('nə', '_'),
      AwingWord('afo\'ə', '_'),
      AwingWord('lá', '_'),
      AwingWord('mbə', '_'),
      AwingWord('ńchígə', '_'),
      AwingWord('mbɔŋə', '_'),
      AwingWord('á', '_'),
      AwingWord('mə', '_'),
      AwingWord('túg', '_'),
      AwingWord('nə', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Pi pətsə pó kwanə azəb ngə mbə' ŋwunə ghed lá tsə'ə afya'á anu mbəŋə chiə mbĩə.",
    english: 'Some people believe that one must make a sacrifice before having a chance to live.',
    difficulty: 3,
    words: [
      AwingWord('Pi', '_'),
      AwingWord('pətsə', '_'),
      AwingWord('pó', '_'),
      AwingWord('kwanə', '_'),
      AwingWord('azəb', '_'),
      AwingWord('ngə', '_'),
      AwingWord('mbə\'', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('ghed', '_'),
      AwingWord('lá', '_'),
      AwingWord('tsə\'ə', '_'),
      AwingWord('afya\'á', '_'),
      AwingWord('anu', '_'),
      AwingWord('mbəŋə', '_'),
      AwingWord('chiə', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Pí patsə pó kə agheələ məfáɡə azób əghá ná táɡə pó, nté ngə pó pí Əsə.",
    english: 'Some people do not keep the twin\'s gourd nowadays because of their believe in God.',
    difficulty: 3,
    words: [
      AwingWord('Pí', '_'),
      AwingWord('patsə', '_'),
      AwingWord('pó', '_'),
      AwingWord('kə', '_'),
      AwingWord('agheələ', '_'),
      AwingWord('məfáɡə', '_'),
      AwingWord('azób', '_'),
      AwingWord('əghá', '_'),
      AwingWord('ná', '_'),
      AwingWord('táɡə', '_'),
      AwingWord('pó', '_'),
      AwingWord('nté', '_'),
      AwingWord('ngə', '_'),
      AwingWord('pó', '_'),
      AwingWord('pí', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Mbɔ' ŋwu mbyáŋnə tə́ ndzɔ́'ə məngyɛ́ alá'ə atúmə ándó Cháína, lə́ tû əlá pə məngyɛ́ ńtúə aghoolə́ atúə.",
    english: 'If a man is marrying in a country like China, the dowry is paid by the woman\'s family.',
    difficulty: 3,
    words: [
      AwingWord('Mbɔ\'', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('mbyáŋnə', '_'),
      AwingWord('tə', '_'),
      AwingWord('ndzɔ', '_'),
      AwingWord('\'ə', '_'),
      AwingWord('məngyɛ', '_'),
      AwingWord('alá\'ə', '_'),
      AwingWord('atúmə', '_'),
      AwingWord('ándó', '_'),
      AwingWord('Cháína', '_'),
      AwingWord('lə', '_'),
      AwingWord('tû', '_'),
      AwingWord('əlá', '_'),
      AwingWord('pə', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Anuə atsəmə á laŋ nə məm mbĩə á tũgə ajĩənuə, ki ɲwu mbĩə a jĩ ki ɲkẽ jĩ.",
    english: 'Everything that happens on earth has a significance whether human beings know or do not know.',
    difficulty: 3,
    words: [
      AwingWord('Anuə', '_'),
      AwingWord('atsəmə', '_'),
      AwingWord('á', '_'),
      AwingWord('laŋ', '_'),
      AwingWord('nə', '_'),
      AwingWord('məm', '_'),
      AwingWord('mbĩə', '_'),
      AwingWord('á', '_'),
      AwingWord('tũgə', '_'),
      AwingWord('ajĩənuə', '_'),
      AwingWord('ki', '_'),
      AwingWord('ɲwu', '_'),
      AwingWord('mbĩə', '_'),
      AwingWord('a', '_'),
      AwingWord('jĩ', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Mɔjɔ́ mɔ́ tɔ́ nɔ́nɔ́ lɔ́ pɔ́ nɛ́ŋ nɔ́ akɔ́ŋ yɔ́ shɔ́ nɔ́, ɲɔ́j ɲɔ́gɔ́ mɔ́ zaɲkɔ́ ɔ́fɛ́ŋɔ.",
    english: 'When food is still hot we put in a bowl so the heat reduces quickly.',
    difficulty: 3,
    words: [
      AwingWord('Mɔjɔ', '_'),
      AwingWord('mɔ', '_'),
      AwingWord('tɔ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('nɛ', '_'),
      AwingWord('ŋ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('akɔ', '_'),
      AwingWord('ŋ', '_'),
      AwingWord('yɔ', '_'),
      AwingWord('shɔ', '_'),
      AwingWord('nɔ', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Mbɔ' o tə ndoonə mə wam nə pəsɔŋ o noŋkə aleeməmɔsɔŋə ali' pɔ' pɔ' naanə nə əwə.",
    english: 'If one wants to trap birds, he puts birdlime on the place that the birds frequent.',
    difficulty: 3,
    words: [
      AwingWord('Mbɔ\'', '_'),
      AwingWord('o', '_'),
      AwingWord('tə', '_'),
      AwingWord('ndoonə', '_'),
      AwingWord('mə', '_'),
      AwingWord('wam', '_'),
      AwingWord('nə', '_'),
      AwingWord('pəsɔŋ', '_'),
      AwingWord('o', '_'),
      AwingWord('noŋkə', '_'),
      AwingWord('aleeməmɔsɔŋə', '_'),
      AwingWord('ali\'', '_'),
      AwingWord('pɔ\'', '_'),
      AwingWord('pɔ\'', '_'),
      AwingWord('naanə', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Atsa'ənəkəŋə á taŋə.",
    english: 'Clay is sticky.',
    difficulty: 1,
    words: [
      AwingWord('Atsa\'ənəkəŋə', '_'),
      AwingWord('á', '_'),
      AwingWord('taŋə', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Á pəŋ ngə mbə' móonə a pəd nkəg pə zɛ'kə yí ndzən pə yúsə nə atso'əməsəŋə.",
    english: 'It is good that if a child is still young they teach him or her how to use a toothbrush.',
    difficulty: 3,
    words: [
      AwingWord('Á', '_'),
      AwingWord('pəŋ', '_'),
      AwingWord('ngə', '_'),
      AwingWord('mbə\'', '_'),
      AwingWord('móonə', '_'),
      AwingWord('a', '_'),
      AwingWord('pəd', '_'),
      AwingWord('nkəg', '_'),
      AwingWord('pə', '_'),
      AwingWord('zɛ\'kə', '_'),
      AwingWord('yí', '_'),
      AwingWord('ndzən', '_'),
      AwingWord('pə', '_'),
      AwingWord('yúsə', '_'),
      AwingWord('nə', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Mbɔ' ɲwunə a chi kɔŋ ɲgá ɲwu nda'ə a zó'ə anu pá' a sɔŋ ná pó, a chámtə.",
    english: 'If one does not want another person to here what he is saying, he whispers.',
    difficulty: 3,
    words: [
      AwingWord('Mbɔ\'', '_'),
      AwingWord('ɲwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('chi', '_'),
      AwingWord('kɔŋ', '_'),
      AwingWord('ɲgá', '_'),
      AwingWord('ɲwu', '_'),
      AwingWord('nda\'ə', '_'),
      AwingWord('a', '_'),
      AwingWord('zó\'ə', '_'),
      AwingWord('anu', '_'),
      AwingWord('pá\'', '_'),
      AwingWord('a', '_'),
      AwingWord('sɔŋ', '_'),
      AwingWord('ná', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "A kě pǭŋ ŋgá ŋwunə a tǭgə mbó yi əshí'nə pó pí pó pó nchí ndzaŋ yi nda' pō.",
    english: 'It is not good that a man should have a good character and his children be different from him.',
    difficulty: 3,
    words: [
      AwingWord('A', '_'),
      AwingWord('kě', '_'),
      AwingWord('pǭŋ', '_'),
      AwingWord('ŋgá', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('tǭgə', '_'),
      AwingWord('mbó', '_'),
      AwingWord('yi', '_'),
      AwingWord('əshí\'nə', '_'),
      AwingWord('pó', '_'),
      AwingWord('pí', '_'),
      AwingWord('pó', '_'),
      AwingWord('pó', '_'),
      AwingWord('nchí', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Móonə a péd yi mbwód lā pá chib nətɔŋ yī tə ná yó ńjum zá' pá pɔŋə medtə.",
    english: 'When a baby is still very young they keep applying oil on the navel until it gets dry.',
    difficulty: 3,
    words: [
      AwingWord('Móonə', '_'),
      AwingWord('a', '_'),
      AwingWord('péd', '_'),
      AwingWord('yi', '_'),
      AwingWord('mbwód', '_'),
      AwingWord('lā', '_'),
      AwingWord('pá', '_'),
      AwingWord('chib', '_'),
      AwingWord('nətɔŋ', '_'),
      AwingWord('yī', '_'),
      AwingWord('tə', '_'),
      AwingWord('ná', '_'),
      AwingWord('yó', '_'),
      AwingWord('ńjum', '_'),
      AwingWord('zá\'', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Múto pá' á wú ná á məmə apéd mbɔ' pá chî chî pó á kē féd pó.",
    english: 'When a car gets into a hole and is not pushed, it it cannot come out.',
    difficulty: 3,
    words: [
      AwingWord('Múto', '_'),
      AwingWord('pá\'', '_'),
      AwingWord('á', '_'),
      AwingWord('wú', '_'),
      AwingWord('ná', '_'),
      AwingWord('á', '_'),
      AwingWord('məmə', '_'),
      AwingWord('apéd', '_'),
      AwingWord('mbɔ\'', '_'),
      AwingWord('pá', '_'),
      AwingWord('chî', '_'),
      AwingWord('chî', '_'),
      AwingWord('pó', '_'),
      AwingWord('á', '_'),
      AwingWord('kē', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Mbɔ́’ ŋwu mɔ́ɔŋɔ́ á chígɔ́ ɔ́fɛ́ nchĩmbí əjí nɔ́ Ɔsɛ́, a kwáalɔ yɔ́ á mǎm ngɔ́’ əjíɔ́.",
    english: 'If men truly surrender their lives to God, he will deliver them from their troubles.',
    difficulty: 3,
    words: [
      AwingWord('Mbɔ', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('mɔ', '_'),
      AwingWord('ɔŋɔ', '_'),
      AwingWord('á', '_'),
      AwingWord('chígɔ', '_'),
      AwingWord('ɔ', '_'),
      AwingWord('fɛ', '_'),
      AwingWord('nchĩmbí', '_'),
      AwingWord('əjí', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('Ɔsɛ', '_'),
      AwingWord('a', '_'),
      AwingWord('kwáalɔ', '_'),
      AwingWord('yɔ', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Pə tə nchú' əshu lə a tyantə, lə mə pə nə sha'tə mə pə anuə tə'ə alə.",
    english: 'It is difficult to start a relationship, but to destroy it takes only a single day.',
    difficulty: 3,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('tə', '_'),
      AwingWord('nchú\'', '_'),
      AwingWord('əshu', '_'),
      AwingWord('lə', '_'),
      AwingWord('a', '_'),
      AwingWord('tyantə', '_'),
      AwingWord('lə', '_'),
      AwingWord('mə', '_'),
      AwingWord('pə', '_'),
      AwingWord('nə', '_'),
      AwingWord('sha\'tə', '_'),
      AwingWord('mə', '_'),
      AwingWord('pə', '_'),
      AwingWord('anuə', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Pí pətsí pó chwaŋkə ló ńtə ńgə pó fa'ə téshú, mbí ńkə məjī əshí'nə jíə pó.",
    english: 'Some people grow lankily because they work a lot and eat unhealthily.',
    difficulty: 3,
    words: [
      AwingWord('Pí', '_'),
      AwingWord('pətsí', '_'),
      AwingWord('pó', '_'),
      AwingWord('chwaŋkə', '_'),
      AwingWord('ló', '_'),
      AwingWord('ńtə', '_'),
      AwingWord('ńgə', '_'),
      AwingWord('pó', '_'),
      AwingWord('fa\'ə', '_'),
      AwingWord('téshú', '_'),
      AwingWord('mbí', '_'),
      AwingWord('ńkə', '_'),
      AwingWord('məjī', '_'),
      AwingWord('əshí\'nə', '_'),
      AwingWord('jíə', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Alí' pó chwə' nó mbəŋə pí məjī əwə á chì ló chwĩ' 56 chwĩŋtɔ maji mɔ kɔ'ɔ ɔwĩ ɔshĩ'nɔ.",
    english: 'Ground that is tilled before planting usually produces a high yield.',
    difficulty: 3,
    words: [
      AwingWord('Alí\'', '_'),
      AwingWord('pó', '_'),
      AwingWord('chwə\'', '_'),
      AwingWord('nó', '_'),
      AwingWord('mbəŋə', '_'),
      AwingWord('pí', '_'),
      AwingWord('məjī', '_'),
      AwingWord('əwə', '_'),
      AwingWord('á', '_'),
      AwingWord('chì', '_'),
      AwingWord('ló', '_'),
      AwingWord('chwĩ\'', '_'),
      AwingWord('56', '_'),
      AwingWord('chwĩŋtɔ', '_'),
      AwingWord('maji', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "ɔyeŋnɔ ɔ lwĩɔɔ lɔ ngɔ chwĩ', mbɔ' pĩ pɔ sogɔ wĩd ɔshĩ'nɔ ɔ mɔ mbĩ ndwĩ.",
    english: 'Bitter leave is very bitter, but when thoroughly washed will no longer be bitter.',
    difficulty: 3,
    words: [
      AwingWord('ɔyeŋnɔ', '_'),
      AwingWord('ɔ', '_'),
      AwingWord('lwĩɔɔ', '_'),
      AwingWord('lɔ', '_'),
      AwingWord('ngɔ', '_'),
      AwingWord('chwĩ\'', '_'),
      AwingWord('mbɔ\'', '_'),
      AwingWord('pĩ', '_'),
      AwingWord('pɔ', '_'),
      AwingWord('sogɔ', '_'),
      AwingWord('wĩd', '_'),
      AwingWord('ɔshĩ\'nɔ', '_'),
      AwingWord('ɔ', '_'),
      AwingWord('mɔ', '_'),
      AwingWord('mbĩ', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "ɔ' a kɛ nɔ ngwud chwĩ', ndelɔ afo'ɔ ɔkwu' ɔ ko' a kɔ nɔanɔ ntɔ nɔŋɔ.",
    english: 'He who does not plant cocoyams does not participate in harvesting.',
    difficulty: 3,
    words: [
      AwingWord('ɔ\'', '_'),
      AwingWord('a', '_'),
      AwingWord('kɛ', '_'),
      AwingWord('nɔ', '_'),
      AwingWord('ngwud', '_'),
      AwingWord('chwĩ\'', '_'),
      AwingWord('ndelɔ', '_'),
      AwingWord('afo\'ɔ', '_'),
      AwingWord('ɔkwu\'', '_'),
      AwingWord('ɔ', '_'),
      AwingWord('ko\'', '_'),
      AwingWord('a', '_'),
      AwingWord('kɔ', '_'),
      AwingWord('nɔanɔ', '_'),
      AwingWord('ntɔ', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Pi pətsə pó kó'ə á mbí ló pó kə ńchwí'tə tso'ə ape' tə á yó ńkó' náənə a kwúə yá.",
    english: 'Some people come into the world and keep on accumulating wealth, until when it is piled they die.',
    difficulty: 3,
    words: [
      AwingWord('Pi', '_'),
      AwingWord('pətsə', '_'),
      AwingWord('pó', '_'),
      AwingWord('kó\'ə', '_'),
      AwingWord('á', '_'),
      AwingWord('mbí', '_'),
      AwingWord('ló', '_'),
      AwingWord('pó', '_'),
      AwingWord('kə', '_'),
      AwingWord('ńchwí\'tə', '_'),
      AwingWord('tso\'ə', '_'),
      AwingWord('ape\'', '_'),
      AwingWord('tə', '_'),
      AwingWord('á', '_'),
      AwingWord('yó', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Ajú pá' á noŋnə́ nə́ á ntso ŋwɪŋə́ á chɪə lə́ tsɔ'ə́ ə́lə́ələ, mbɔ' ŋwunə́ a kə́ kwum pɔ́.",
    english: 'Any thing kept by a tree god remains the same until the owner comes for it.',
    difficulty: 3,
    words: [
      AwingWord('Ajú', '_'),
      AwingWord('pá\'', '_'),
      AwingWord('á', '_'),
      AwingWord('noŋnə', '_'),
      AwingWord('nə', '_'),
      AwingWord('á', '_'),
      AwingWord('ntso', '_'),
      AwingWord('ŋwɪŋə', '_'),
      AwingWord('á', '_'),
      AwingWord('chɪə', '_'),
      AwingWord('lə', '_'),
      AwingWord('tsɔ\'ə', '_'),
      AwingWord('ə', '_'),
      AwingWord('lə', '_'),
      AwingWord('ələ', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "A kə yî əzoonə.",
    english: 'He came yesterday.',
    difficulty: 1,
    words: [
      AwingWord('A', '_'),
      AwingWord('kə', '_'),
      AwingWord('yî', '_'),
      AwingWord('əzoonə', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Mɔ nkə pá' á zɔ nə má əyə kí tá əyí á fanə ló fan nə.",
    english: 'A child who insults his father or mother is doing something terrible.',
    difficulty: 3,
    words: [
      AwingWord('Mɔ', '_'),
      AwingWord('nkə', '_'),
      AwingWord('pá\'', '_'),
      AwingWord('á', '_'),
      AwingWord('zɔ', '_'),
      AwingWord('nə', '_'),
      AwingWord('má', '_'),
      AwingWord('əyə', '_'),
      AwingWord('kí', '_'),
      AwingWord('tá', '_'),
      AwingWord('əyí', '_'),
      AwingWord('á', '_'),
      AwingWord('fanə', '_'),
      AwingWord('ló', '_'),
      AwingWord('fan', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Ngaɡtsəɡpə ɲtsəmə a pɪmə anuə atsəɡ lə tso'ə ɲgə fəɡ, ɲbə ɲkɛ chə mə fə' nə tə' pə.",
    english: 'A dishonest person will accept \'feng\' to every thing but will never put one into action.',
    difficulty: 3,
    words: [
      AwingWord('Ngaɡtsəɡpə', '_'),
      AwingWord('ɲtsəmə', '_'),
      AwingWord('a', '_'),
      AwingWord('pɪmə', '_'),
      AwingWord('anuə', '_'),
      AwingWord('atsəɡ', '_'),
      AwingWord('lə', '_'),
      AwingWord('tso\'ə', '_'),
      AwingWord('ɲgə', '_'),
      AwingWord('fəɡ', '_'),
      AwingWord('ɲbə', '_'),
      AwingWord('ɲkɛ', '_'),
      AwingWord('chə', '_'),
      AwingWord('mə', '_'),
      AwingWord('fə\'', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Pə ɲkə pə zaɲkə ɲdzɛ'ə anu lə ɲtə ɲgə ɲwunə a tə fə'ə anuə atsəɡ lə pə tə fi'kə.",
    english: 'Children learn faster because they imitate everything they see one doing.',
    difficulty: 3,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('ɲkə', '_'),
      AwingWord('pə', '_'),
      AwingWord('zaɲkə', '_'),
      AwingWord('ɲdzɛ\'ə', '_'),
      AwingWord('anu', '_'),
      AwingWord('lə', '_'),
      AwingWord('ɲtə', '_'),
      AwingWord('ɲgə', '_'),
      AwingWord('ɲwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('tə', '_'),
      AwingWord('fə\'ə', '_'),
      AwingWord('anuə', '_'),
      AwingWord('atsəɡ', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Pi pətsə pə sɔɲə ɲgə ɲwunə a finə məta nə afʊə, ki pə sɔɲ nə tso'ə anu.",
    english: 'Some people say that business people do business with supernatural power, no one knows whether that is true.',
    difficulty: 3,
    words: [
      AwingWord('Pi', '_'),
      AwingWord('pətsə', '_'),
      AwingWord('pə', '_'),
      AwingWord('sɔɲə', '_'),
      AwingWord('ɲgə', '_'),
      AwingWord('ɲwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('finə', '_'),
      AwingWord('məta', '_'),
      AwingWord('nə', '_'),
      AwingWord('afʊə', '_'),
      AwingWord('ki', '_'),
      AwingWord('pə', '_'),
      AwingWord('sɔɲ', '_'),
      AwingWord('nə', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Pó pó'ə mó nkə lā a kə soŋ lā tso'ə ngə a yĩ kwə fi'tə mǎ əyĩə.",
    english: 'When a child is beaten, he will feel comforted to say that he will tell his mother when she comes back.',
    difficulty: 3,
    words: [
      AwingWord('Pó', '_'),
      AwingWord('pó\'ə', '_'),
      AwingWord('mó', '_'),
      AwingWord('nkə', '_'),
      AwingWord('lā', '_'),
      AwingWord('a', '_'),
      AwingWord('kə', '_'),
      AwingWord('soŋ', '_'),
      AwingWord('lā', '_'),
      AwingWord('tso\'ə', '_'),
      AwingWord('ngə', '_'),
      AwingWord('a', '_'),
      AwingWord('yĩ', '_'),
      AwingWord('kwə', '_'),
      AwingWord('fi\'tə', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Nɔŋkɔ Mbúwíŋɔ a nid ńgɔ mbɔ' ɲwunɔ ghâ' ńtseelɔ yitsɔ, azɔŋɔ a fɔŋɔ ntseembí nɔ ndɛ**.",
    english: 'The Awing culture demands that junior people should add an affix to the names of their elders.',
    difficulty: 3,
    words: [
      AwingWord('Nɔŋkɔ', '_'),
      AwingWord('Mbúwíŋɔ', '_'),
      AwingWord('a', '_'),
      AwingWord('nid', '_'),
      AwingWord('ńgɔ', '_'),
      AwingWord('mbɔ\'', '_'),
      AwingWord('ɲwunɔ', '_'),
      AwingWord('ghâ\'', '_'),
      AwingWord('ńtseelɔ', '_'),
      AwingWord('yitsɔ', '_'),
      AwingWord('azɔŋɔ', '_'),
      AwingWord('a', '_'),
      AwingWord('fɔŋɔ', '_'),
      AwingWord('ntseembí', '_'),
      AwingWord('nɔ', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Mbɔ' ɣwunə a zɔ'ə məngyɛ̀ pá' á ghɔntə nə tɔ̀shú ajúmə yɔ̀ mə nɔŋnə á apa yɔ̀.",
    english: 'If a man marries a woman who is sickly, he will hardly have a franc in his pocket.',
    difficulty: 3,
    words: [
      AwingWord('Mbɔ\'', '_'),
      AwingWord('ɣwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('zɔ\'ə', '_'),
      AwingWord('məngyɛ', '_'),
      AwingWord('pá\'', '_'),
      AwingWord('á', '_'),
      AwingWord('ghɔntə', '_'),
      AwingWord('nə', '_'),
      AwingWord('tɔ', '_'),
      AwingWord('shú', '_'),
      AwingWord('ajúmə', '_'),
      AwingWord('yɔ', '_'),
      AwingWord('mə', '_'),
      AwingWord('nɔŋnə', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Mə Əsə a nə jwǎa 76 ká'ə fē nchĩmbĩ əjĩə á mǎ lǝg nǝ júnə atũə ɲwu mǝsǝŋ əwǝ.",
    english: 'God\'s son died so that he could redeem the lives of human beings.',
    difficulty: 3,
    words: [
      AwingWord('Mə', '_'),
      AwingWord('Əsə', '_'),
      AwingWord('a', '_'),
      AwingWord('nə', '_'),
      AwingWord('jwǎa', '_'),
      AwingWord('76', '_'),
      AwingWord('ká\'ə', '_'),
      AwingWord('fē', '_'),
      AwingWord('nchĩmbĩ', '_'),
      AwingWord('əjĩə', '_'),
      AwingWord('á', '_'),
      AwingWord('mǎ', '_'),
      AwingWord('lǝg', '_'),
      AwingWord('nǝ', '_'),
      AwingWord('júnə', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Ajɪə anu kɪlelənkayə á løg nə mbə' nka əyɪ əwɪ, ɲwu mbɪə a kɛ túg pɔ.",
    english: 'Human beings do not have the kind of knowledge that a spider uses to build its nest.',
    difficulty: 3,
    words: [
      AwingWord('Ajɪə', '_'),
      AwingWord('anu', '_'),
      AwingWord('kɪlelənkayə', '_'),
      AwingWord('á', '_'),
      AwingWord('løg', '_'),
      AwingWord('nə', '_'),
      AwingWord('mbə\'', '_'),
      AwingWord('nka', '_'),
      AwingWord('əyɪ', '_'),
      AwingWord('əwɪ', '_'),
      AwingWord('ɲwu', '_'),
      AwingWord('mbɪə', '_'),
      AwingWord('a', '_'),
      AwingWord('kɛ', '_'),
      AwingWord('túg', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Pə sɔŋ ɲgə kɔ ɲwunə a kɔ əshʊə á əfooghɪ, pɪ pə kə ɲkɔɔlə tsɔ'ə kɔ nə.",
    english: 'Word is that people should not fish in Awing lake, yet people continue doing so.',
    difficulty: 3,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('sɔŋ', '_'),
      AwingWord('ɲgə', '_'),
      AwingWord('kɔ', '_'),
      AwingWord('ɲwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('kɔ', '_'),
      AwingWord('əshʊə', '_'),
      AwingWord('á', '_'),
      AwingWord('əfooghɪ', '_'),
      AwingWord('pɪ', '_'),
      AwingWord('pə', '_'),
      AwingWord('kə', '_'),
      AwingWord('ɲkɔɔlə', '_'),
      AwingWord('tsɔ\'ə', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Alɛ pə' ɲwu mbɪə a lə' ko'ə 82 kóolə ná sóg ngá nkáb əji á ko' lá zəənə.",
    english: 'When will a human being ever be satisfied with money?',
    difficulty: 3,
    words: [
      AwingWord('Alɛ', '_'),
      AwingWord('pə\'', '_'),
      AwingWord('ɲwu', '_'),
      AwingWord('mbɪə', '_'),
      AwingWord('a', '_'),
      AwingWord('lə\'', '_'),
      AwingWord('ko\'ə', '_'),
      AwingWord('82', '_'),
      AwingWord('kóolə', '_'),
      AwingWord('ná', '_'),
      AwingWord('sóg', '_'),
      AwingWord('ngá', '_'),
      AwingWord('nkáb', '_'),
      AwingWord('əji', '_'),
      AwingWord('á', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Afa'ə Afésə lá afa'ə akóoməpúmə, a tá nkó əpú lá a kê kɔŋ ngá ŋwu tsə a jwa'ə yí pô.",
    english: 'Afese\'s job is wood work.',
    difficulty: 3,
    words: [
      AwingWord('Afa\'ə', '_'),
      AwingWord('Afésə', '_'),
      AwingWord('lá', '_'),
      AwingWord('afa\'ə', '_'),
      AwingWord('akóoməpúmə', '_'),
      AwingWord('a', '_'),
      AwingWord('tá', '_'),
      AwingWord('nkó', '_'),
      AwingWord('əpú', '_'),
      AwingWord('lá', '_'),
      AwingWord('a', '_'),
      AwingWord('kê', '_'),
      AwingWord('kɔŋ', '_'),
      AwingWord('ngá', '_'),
      AwingWord('ŋwu', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Ajúmə atsəm pá' á chígé ná nden ŋwu Mbiwiŋə sôŋ lá ngá á len tə nkɔdkə.",
    english: 'When something is very old, an Awing man says it is so old that it is peeling off.',
    difficulty: 3,
    words: [
      AwingWord('Ajúmə', '_'),
      AwingWord('atsəm', '_'),
      AwingWord('pá\'', '_'),
      AwingWord('á', '_'),
      AwingWord('chígé', '_'),
      AwingWord('ná', '_'),
      AwingWord('nden', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('Mbiwiŋə', '_'),
      AwingWord('sôŋ', '_'),
      AwingWord('lá', '_'),
      AwingWord('ngá', '_'),
      AwingWord('á', '_'),
      AwingWord('len', '_'),
      AwingWord('tə', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Mbəəmə apəəmə a jɪ kwê 86 kwúd nká'ə na ló a kweekə ngwú á ndzəm əwə.",
    english: 'When a hunter sees game, he sets the dog behind it.',
    difficulty: 3,
    words: [
      AwingWord('Mbəəmə', '_'),
      AwingWord('apəəmə', '_'),
      AwingWord('a', '_'),
      AwingWord('jɪ', '_'),
      AwingWord('kwê', '_'),
      AwingWord('86', '_'),
      AwingWord('kwúd', '_'),
      AwingWord('nká\'ə', '_'),
      AwingWord('na', '_'),
      AwingWord('ló', '_'),
      AwingWord('a', '_'),
      AwingWord('kweekə', '_'),
      AwingWord('ngwú', '_'),
      AwingWord('á', '_'),
      AwingWord('ndzəm', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Ngəb ə chî pi pə tɔŋə akwê əwí nə mbô mbɔ' ɲwunə a zəənə shishɪə ajú əsoŋ ɲgə ló paɲpaɲə.",
    english: 'People lie in politics to such extent that one can see a black object an call it red.',
    difficulty: 3,
    words: [
      AwingWord('Ngəb', '_'),
      AwingWord('ə', '_'),
      AwingWord('chî', '_'),
      AwingWord('pi', '_'),
      AwingWord('pə', '_'),
      AwingWord('tɔŋə', '_'),
      AwingWord('akwê', '_'),
      AwingWord('əwí', '_'),
      AwingWord('nə', '_'),
      AwingWord('mbô', '_'),
      AwingWord('mbɔ\'', '_'),
      AwingWord('ɲwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('zəənə', '_'),
      AwingWord('shishɪə', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Á pɔŋə mə túg nə akɔŋnə á məmə anuə atsəm ŋwunə a tə nə fa'ə zɔ́ələ.",
    english: 'It is good to exercise love in all of one\'s activities.',
    difficulty: 3,
    words: [
      AwingWord('Á', '_'),
      AwingWord('pɔŋə', '_'),
      AwingWord('mə', '_'),
      AwingWord('túg', '_'),
      AwingWord('nə', '_'),
      AwingWord('akɔŋnə', '_'),
      AwingWord('á', '_'),
      AwingWord('məmə', '_'),
      AwingWord('anuə', '_'),
      AwingWord('atsəm', '_'),
      AwingWord('ŋwunə', '_'),
      AwingWord('a', '_'),
      AwingWord('tə', '_'),
      AwingWord('nə', '_'),
      AwingWord('fa\'ə', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Ngaŋməŋgéemə a **tsid ntsə**əla.",
    english: 'A fortune-teller lies.',
    difficulty: 1,
    words: [
      AwingWord('Ngaŋməŋgéemə', '_'),
      AwingWord('a', '_'),
      AwingWord('tsid', '_'),
      AwingWord('ntsə', '_'),
      AwingWord('əla', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Pi pətsə pə kwaŋ ŋgə** **ngwüdlóŋ ə tɔŋ lə anuə təpəŋə** ngwùdlóŋə 113 nká’ə á laŋə.",
    english: 'Some people believe that when a heron cries it is an evil omen.',
    difficulty: 3,
    words: [
      AwingWord('Pi', '_'),
      AwingWord('pətsə', '_'),
      AwingWord('pə', '_'),
      AwingWord('kwaŋ', '_'),
      AwingWord('ŋgə', '_'),
      AwingWord('ngwüdlóŋ', '_'),
      AwingWord('ə', '_'),
      AwingWord('tɔŋ', '_'),
      AwingWord('lə', '_'),
      AwingWord('anuə', '_'),
      AwingWord('təpəŋə', '_'),
      AwingWord('ngwùdlóŋə', '_'),
      AwingWord('113', '_'),
      AwingWord('nká', '_'),
      AwingWord('ə', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Pə mŋŋkwa pō kə ndzō'ə lə nəkyɛŋ pō pə pwōd əghā ətsəmə, pō chūə ngə nyanyā.",
    english: 'Midwives keep hearing the cries of babies, as they cry nyanya.',
    difficulty: 3,
    words: [
      AwingWord('Pə', '_'),
      AwingWord('mŋŋkwa', '_'),
      AwingWord('pō', '_'),
      AwingWord('kə', '_'),
      AwingWord('ndzō\'ə', '_'),
      AwingWord('lə', '_'),
      AwingWord('nəkyɛŋ', '_'),
      AwingWord('pō', '_'),
      AwingWord('pə', '_'),
      AwingWord('pwōd', '_'),
      AwingWord('əghā', '_'),
      AwingWord('ətsəmə', '_'),
      AwingWord('pō', '_'),
      AwingWord('chūə', '_'),
      AwingWord('ngə', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Mbɔ' nənta ná atí ná pyádnə ńtí ŋwu Mbĩwĩŋə a sɔŋ ló ńgá ná tí tə ńkakə.",
    english: 'When a fruit is well ready for harvest, an Awing man says it is so ripe that it has become rough.',
    difficulty: 3,
    words: [
      AwingWord('Mbɔ\'', '_'),
      AwingWord('nənta', '_'),
      AwingWord('ná', '_'),
      AwingWord('atí', '_'),
      AwingWord('ná', '_'),
      AwingWord('pyádnə', '_'),
      AwingWord('ńtí', '_'),
      AwingWord('ŋwu', '_'),
      AwingWord('Mbĩwĩŋə', '_'),
      AwingWord('a', '_'),
      AwingWord('sɔŋ', '_'),
      AwingWord('ló', '_'),
      AwingWord('ńgá', '_'),
      AwingWord('ná', '_'),
      AwingWord('tí', '_'),
    ],
  ),

  // DICT batch 5 — added Session 63 Part H (expert-mode proverbs)
  AwingSentence(
    awing: "Pó pətsí pó chí áwí ńgə'ə; o fē ajú ná mó mbí ńtə ńkwáalə a tyantə ná apó yə.",
    english: 'Some children are very greedy such that you give something to a child and ask for it the same moment and he hardens the hand.',
    difficulty: 3,
    words: [
      AwingWord('Pó', '_'),
      AwingWord('pətsí', '_'),
      AwingWord('pó', '_'),
      AwingWord('chí', '_'),
      AwingWord('áwí', '_'),
      AwingWord('ńgə\'ə', '_'),
      AwingWord('o', '_'),
      AwingWord('fē', '_'),
      AwingWord('ajú', '_'),
      AwingWord('ná', '_'),
      AwingWord('mó', '_'),
      AwingWord('mbí', '_'),
      AwingWord('ńtə', '_'),
      AwingWord('ńkwáalə', '_'),
      AwingWord('a', '_'),
    ],
  ),

];

class SentencesScreen extends StatefulWidget {
  const SentencesScreen({Key? key}) : super(key: key);

  @override
  State<SentencesScreen> createState() => _SentencesScreenState();
}

class _SentencesScreenState extends State<SentencesScreen> {
  int _selectedMode = 0; // 0 = Reading, 1 = Building

  @override
  void initState() {
    super.initState();
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
                ? const _ReadingMode()
                : const _BuildingMode(),
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
  const _ReadingMode();

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
              mediumSentences.length,
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
            itemCount: mediumSentences.length,
            itemBuilder: (context, index) => _SentenceCard(
              sentence: mediumSentences[index],
            ),
          ),
        ),
      ],
    );
  }
}

class _SentenceCard extends StatelessWidget {
  final AwingSentence sentence;

  const _SentenceCard({
    required this.sentence,
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
                AwingAudioActionButton(
                  awing: sentence.awing,
                  playColor: Colors.orange,
                  // A sentence, not a word: the recorder is word-oriented,
                  // so show "No recording" rather than send the user
                  // somewhere that cannot accept this.
                  offerToRecord: false,
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
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: AwingAudioButton(
                        awing: word.word,
                        color: Colors.white,
                      ),
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
  const _BuildingMode();

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
    _buildingExercises = List.from(mediumSentences)..shuffle(_random);
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
                _buildingExercises = List.from(mediumSentences)..shuffle(_random);
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
