/// Awing vocabulary data extracted from:
///   - AwingOrthography2005.pdf (Alomofor Christian & Stephen C. Anderson)
///   - AwingphonologyMar2009Final_U_arc.pdf (Bianca van den Berg, SIL)
///   - Awing English Dictionary (Alomofor Christian, CABTAL, 2007) — 3098 entries
/// Organized by category for lesson content.
/// Priority: simple, common words that kids and beginners can learn easily.
/// When multiple Awing words exist for the same meaning, we use the simplest one.

class AwingWord {
  final String awing;
  final String english;
  final String category;
  final String? tonePattern; // e.g. 'high', 'low', 'rising', 'falling'
  final String? pluralForm;
  final String? shortForm;
  final int difficulty; // 1=beginner, 2=medium, 3=expert

  const AwingWord({
    required this.awing,
    required this.english,
    required this.category,
    this.tonePattern,
    this.pluralForm,
    this.shortForm,
    this.difficulty = 1,
  });
}

// ============================================================
// NEW CATEGORIES (Session 37 - PDF-verified entries)
// ============================================================

/// Pronouns — personal and demonstrative pronouns
const List<AwingWord> pronouns = [
  // Source: Awing English Dictionary English-Awing Index +
  // AwingOrthography2005.pdf example sentences (pages 9, 11, 12).
  AwingWord(awing: 'ghǒ', english: 'you (singular)', category: 'pronouns', difficulty: 1),
  // From orthography PDF p.12: "Ghǒ ghɛnɔ́ lə əfó?" (Where are you going?)
];

/// Time words — temporal expressions and temporal nouns
const List<AwingWord> timeWords = [
  // Source: Awing English Dictionary
  AwingWord(awing: "nətú'ə", english: 'night', category: 'things', difficulty: 1),  // Session 56 audit: was "ntúa'ɔ" — dict says "nətú'ə"
  AwingWord(awing: 'agha ghena', english: 'now', category: 'things', difficulty: 1),
  AwingWord(awing: 'agha yia', english: 'later', category: 'things', difficulty: 1),
  AwingWord(awing: 'təká', english: 'never', category: 'things', difficulty: 2),  // Session 56 audit: was "taká" — dict says "təká"
  AwingWord(awing: 'sáŋə', english: 'month', category: 'things', difficulty: 2),  // Session 56 audit: was "saŋ" — dict says "sáŋə"
  AwingWord(awing: 'agha', english: 'season', category: 'things', difficulty: 1)];

/// PDF-verified extras — words and forms that appear in
/// AwingOrthography2005.pdf example sentences but were missing from
/// the dictionary-derived vocabulary. Added to support PDF-verified
/// stories and sentences without flagging them as "fabricated".
/// Pages cited from AwingOrthography2005.pdf.
const List<AwingWord> pdfVerifiedExtras = [
  // From p.9: "A kə ghɛnɔ́ məteenɔ́." (He went to the market.)
  AwingWord(awing: 'ghɛnɔ́', english: 'go, went', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məteenɔ́', english: 'market', category: 'things', tonePattern: 'high', difficulty: 2),
  // From p.11: "Móonə a tə nonnɔ́ a əkwunɔ́." (The baby is lying on the bed.)
  // Dr. Sama (native speaker) corrected the natural spoken form to
  // "Móonə nonnɔ́ əkwunɔ́" — Awing drops the "a tə" progressive auxiliary
  // and the locative "a" particle. The PDF version is more formal/written.
  AwingWord(awing: 'nonnɔ́', english: 'lying, lying down', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əkwunɔ́', english: 'bed', category: 'things', tonePattern: 'high', difficulty: 2),
  // From p.11: "A ghɛlɔ́ lə aké?" (What is he doing?)
  AwingWord(awing: 'ghɛlɔ́', english: 'doing, do', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aké', english: 'what', category: 'pronouns', difficulty: 1),
  // From p.11: "Po ma ngyǐə lə əfê" (They are not coming here)
  AwingWord(awing: 'ngyǐə', english: 'coming', category: 'actions', tonePattern: 'rising', difficulty: 2),
  // əfê here = "here" (locative); dict has separate homonym əfê = "giver"
  // From p.12: "Po zí nóolə." (They have seen a snake.)
  AwingWord(awing: 'zí', english: 'have seen, saw', category: 'actions', tonePattern: 'high', difficulty: 2),
  // From p.12: "Mbá'chi, Apɛnə nə Mbyáb tə nkɔ́'ə atǐə." (Mbachia, Apena and Mbyaabo are climbing a tree.)
  AwingWord(awing: "nkɔ́'ə", english: 'climbing, climb', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atǐə', english: 'tree', category: 'nature', tonePattern: 'rising', difficulty: 2),
  // Proper names from p.12 — Awing names that appear in orthography examples
  AwingWord(awing: "Mbá'chi", english: 'Mbachia (name)', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'Apɛnə', english: 'Apena (name)', category: 'family', difficulty: 1),

  // From p.10: "Lɛ̌ nəpɔ́'ə." (This is a pumpkin.)
  AwingWord(awing: 'Lɛ̌', english: 'this is', category: 'pronouns', tonePattern: 'rising', difficulty: 2),
  // Homonyms: orthography uses these meanings that differ from
  // dictionary's primary listing. Both are valid in actual Awing.
  AwingWord(awing: 'móonə', english: 'baby, child', category: 'family', difficulty: 1),
  AwingWord(awing: 'əfó', english: 'where (interrogative)', category: 'pronouns', difficulty: 1),
  AwingWord(awing: 'ma', english: 'not (negative particle)', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'əfê', english: 'here, this place', category: 'descriptive', tonePattern: 'falling', difficulty: 2)];

// ============================================================
// BEGINNER VOCABULARY (difficulty: 1) — simple, everyday words
// ============================================================

/// Body parts — simple words kids learn first
const List<AwingWord> bodyParts = [
  // Beginner (difficulty 1) — simple body parts kids know
  AwingWord(awing: 'apô', english: 'hand', category: 'body'),
  AwingWord(awing: 'atûə', english: 'head', category: 'body'),
  AwingWord(awing: 'nəlwîə', english: 'nose', category: 'body'),
  AwingWord(awing: 'ndě', english: 'neck (body part)', category: 'body', pluralForm: 'məndě'),
  AwingWord(awing: 'nkadtə', english: 'back', category: 'body'),
  AwingWord(awing: "mbe'ta", english: 'shoulder', category: 'body'),  // Session 56 audit: was "mbe'tə" — dict says "mbe'ta"
  AwingWord(awing: 'achîə', english: 'blood', category: 'body'),
  AwingWord(awing: 'akoolə', english: 'leg', category: 'body'),
  AwingWord(awing: 'aləəmə', english: 'tongue', category: 'body'),  // Session 56 audit: was "alɔ́əmə" — dict says "aləəmə"
  AwingWord(awing: 'ŋgɔ́ɔmə', english: 'body', category: 'body'),
  AwingWord(awing: 'ŋgɔ̀ɔnə', english: 'eye', category: 'body'),
  AwingWord(awing: 'ntɔ̀ə', english: 'ear', category: 'body'),
  // Medium (difficulty 2)
  AwingWord(awing: 'nəpe', english: 'liver', category: 'body', difficulty: 1),
  AwingWord(awing: 'nətô', english: 'intestines', category: 'body', difficulty: 1),
  AwingWord(awing: 'felə', english: 'breastbone', category: 'body', difficulty: 2),  // Session 56 audit: was "fɛlə" — dict says "felə"
  AwingWord(awing: 'ghaŋə', english: 'chest', category: 'body', difficulty: 2),  // Session 56 audit: was "aghâŋə" — dict says "ghaŋə"
  AwingWord(awing: 'nəlágə', english: 'eye', category: 'body', pluralForm: 'mələ́g'),  // Session 56 audit: was "nəlɔ́gə" — dict says "nəlágə"
  AwingWord(awing: 'nətôglə', english: 'ear', category: 'body'),  // Session 56 audit: was "ntɔ̂glə" — dict says "nətôglə"
  AwingWord(awing: 'ntsoolə', english: 'mouth (body)', category: 'body', pluralForm: 'məntsoolə'),
  AwingWord(awing: 'nəsoŋə', english: 'tooth', category: 'body', pluralForm: 'məsoŋ'),  // Session 56 audit: was "nəsoŋɔ́" — dict says "nəsoŋə"
  AwingWord(awing: 'nənoŋə', english: 'hair', category: 'body', pluralForm: 'mənɔŋə'),  // Session 56 audit: was "nənɔŋə" — dict says "nənoŋə"
  AwingWord(awing: 'akwəŋó', english: 'bone', category: 'body'),  // Session 56 audit: was "akwəŋɔ́" — dict says "akwəŋó"
  AwingWord(awing: 'nəpəmə', english: 'stomach', category: 'body', pluralForm: 'məpəmə'),
  AwingWord(awing: "alu'ə", english: 'hip', category: 'body'),  // Session 56 audit: was "alu'ɔ̀" — dict says "alu'ə"
  AwingWord(awing: 'atéelə', english: 'foot', category: 'body'),
  AwingWord(awing: 'nəpéenə', english: 'crown of head', category: 'body'),
  // Medium (difficulty 2)
  AwingWord(awing: 'əleló', english: 'beard', category: 'body', difficulty: 2),  // Session 56 audit: was "ələlə" — dict says "əleló"
  AwingWord(awing: 'atúəkeenə', english: 'shoulder blade', category: 'body', difficulty: 1),
  AwingWord(awing: "kwɔ'tə", english: 'knee', category: 'body', difficulty: 2),
  AwingWord(awing: 'nəbâŋə', english: 'wing (of bird)', category: 'body', difficulty: 2),
  AwingWord(awing: 'nəlwɛ̂ɨ', english: 'hump', category: 'body', difficulty: 3),
  AwingWord(awing: 'nətoŋə́', english: 'navel', category: 'body', difficulty: 2),  // Session 56 audit: was "nətɔŋɔ́" — dict says "nətoŋə́"
  AwingWord(awing: "nətə'ə", english: 'thigh', category: 'body', difficulty: 2),  // Session 56 audit: was "nətɔ'ə" — dict says "nətə'ə"
  AwingWord(awing: 'ntîə', english: 'height', category: 'body', difficulty: 1),
  AwingWord(awing: 'ajwíə', english: 'soul/spirit', category: 'body', difficulty: 2),
  AwingWord(awing: 'ntéəmə', english: 'heart', category: 'body', difficulty: 2),  // Session 56 audit: was "ntɔ̂əmə" — dict says "ntéəmə"
  // New body parts from phonology/orthography PDFs
  AwingWord(awing: 'ŋgwɛ̂ŋə', english: 'cheek', category: 'body'),
  AwingWord(awing: 'ndzwîə', english: 'chin', category: 'body'),
  AwingWord(awing: 'nkwə̂ŋə', english: 'elbow', category: 'body'),
  AwingWord(awing: 'ntsə̂ŋə', english: 'finger', category: 'body'),
  AwingWord(awing: 'mbwɔ̂ŋə', english: 'neck (back of)', category: 'body', difficulty: 2),
  AwingWord(awing: 'ndɛ̂ŋə', english: 'jaw', category: 'body', difficulty: 1),
  AwingWord(awing: 'ŋgwɔ̂ŋə', english: 'forehead', category: 'body'),
  AwingWord(awing: 'ntsɔ̂ŋə', english: 'rib', category: 'body', difficulty: 1),
  AwingWord(awing: 'mbə̂ŋɔ́', english: 'palm (of hand)', category: 'body'),
  // Session 60: Removed `nkɔ̂ŋə = throat` — unverified, conflicts with the
  // PDF-verified `tôgndě = throat` entry below. User-reported wrong gloss
  // in quiz (tester saw it offered "throat" as answer for nkɔ̂ŋə, which is
  // wrong; tôgndě is the correct word).
  AwingWord(awing: 'ŋgwɛ̀nə', english: 'skin', category: 'body'),
  AwingWord(awing: 'ŋkwâŋə', english: 'waist', category: 'body'),
  // === NEW: PDF-verified entries (Session 37) ===
  AwingWord(awing: 'nalanɔ́', english: 'joint', category: 'body', difficulty: 1),
  AwingWord(awing: "mbi'ə", english: 'kidney', category: 'body', difficulty: 3),  // Session 56 audit: was "mbî'ɔ́" — dict says "mbi'ə"
  AwingWord(awing: 'afɔ́bla', english: 'lung', category: 'body', difficulty: 3)];

/// Animals and nature — fun for kids
const List<AwingWord> animalsNature = [
  // Beginner animals
  AwingWord(awing: 'əshûə', english: 'fish', category: 'animals'),
  // Session 52 gloss audit: was "owl" — dict says "1) crawl. 2) slither, eg of snakes"
  AwingWord(awing: 'koŋə', english: 'crawl, slither', category: 'actions'),
  AwingWord(awing: 'nóolə', english: 'snake', category: 'animals'),
  AwingWord(awing: 'aŋkoomə', english: 'ram', category: 'animals'),  // Session 56 audit: was "ankoomə" — dict says "aŋkoomə"
  AwingWord(awing: 'mbéŋə', english: 'goat', category: 'animals'),  // Session 56 audit: was "ndzô" (OCR fabrication — dict says ndzɔ=beans, mbéŋə=goat)
  // REMOVED 2026-05-20: mbyâə → "guard dog" — fabrication reported by
  // tester. Not in 2007 Awing English Dictionary, not in Bible NT corpus.
  // Actual Awing for "dog" is ngwûə / ajǎʼkə / ńkadlə̂ / nətwáabə;
  // "guard" alone is mbyáabə. The compound "guard dog" was invented.
  AwingWord(awing: 'ndoŋə', english: 'duck', category: 'animals'),  // Session 56 audit: was "əndəŋə" — dict says "ndoŋə"
  AwingWord(awing: 'kshǐa', english: 'cricket', category: 'animals'),
  AwingWord(awing: 'mbeŋə', english: 'cockroach', category: 'animals'),  // Session 56 audit: was "mbeŋó" — dict says "mbeŋə"
  AwingWord(awing: 'kánáŋə́', english: 'chameleon', category: 'animals'),  // Session 56 audit: was "kónáŋó" — dict says "kánáŋə́"
  AwingWord(awing: 'apəabə', english: 'he-goat', category: 'animals'),  // Session 56 audit: was "apóbə" — dict says "apəabə"
  AwingWord(awing: 'ngwûə', english: 'dog', category: 'animals', pluralForm: 'məngwûə'),
  AwingWord(awing: 'ngábə', english: 'chicken', category: 'animals', pluralForm: 'məngɔ́bə'),  // Session 56 audit: was "ngɔ́bə" — dict says "ngábə"
  AwingWord(awing: 'pûshíə', english: 'cat', category: 'animals'),
  AwingWord(awing: 'sáŋə', english: 'bird', category: 'animals', pluralForm: 'pəsáŋɔ́'),  // Session 56 audit: was "sáŋɔ́" — dict says "sáŋə"
  AwingWord(awing: "təŋka'ə", english: 'elephant', category: 'animals'),  // Session 56 audit: was "tâŋka'ə" — dict says "təŋka'ə"
  AwingWord(awing: 'sáambaŋə', english: 'lion', category: 'animals'),
  AwingWord(awing: 'ambónə', english: 'hippopotamus', category: 'animals'),
  AwingWord(awing: 'chwíə', english: 'antelope', category: 'animals'),
  AwingWord(awing: 'lúmtə', english: 'mosquito', category: 'animals'),  // Session 56 audit: was "lúmtɔ́" — dict says "lúmtə"
  // REMOVED kwíŋə "tortoise" — per dict EXACT match kwíŋə = "grow up / prosper" (verb), not an animal (Session 51 audit)
  AwingWord(awing: 'kwúneemə', english: 'pig', category: 'animals'),
  AwingWord(awing: 'tətseemə', english: 'frog', category: 'animals'),  // Session 56 audit: was "tatseemə" — dict says "tətseemə"
  AwingWord(awing: 'lóolá', english: 'toad', category: 'animals'),  // Session 56 audit: was "lóolə" — dict says "lóolá"
  AwingWord(awing: 'anjwa', english: 'giraffe', category: 'animals'),
  AwingWord(awing: 'njakásə', english: 'donkey', category: 'animals'),  // Session 56 audit: was "ŋjakásə" — dict says "njakásə"
  // REMOVED nka'ə "leopard" — per dict EXACT match nka'ə = "leprosy" (not a kid-friendly word AND not a leopard) (Session 51 audit)
  AwingWord(awing: 'kígháləgháló', english: 'butterfly', category: 'animals'),
  AwingWord(awing: 'fóolá', english: 'rat', category: 'animals'),  // Session 56 audit: was "fóolɔ́" — dict says "fóolá"
  AwingWord(awing: 'anəmá', english: 'louse', category: 'animals'),  // Session 56 audit: was "anɔ́mɔ́" — dict says "anəmá"
  AwingWord(awing: 'njá', english: 'shrimp', category: 'animals'),
  AwingWord(awing: 'ngwumnə́', english: 'locust', category: 'animals'),  // Session 56 audit: was "ngwúmnɔ́" — dict says "ngwumnə́"
  AwingWord(awing: "to'lə", english: 'squirrel', category: 'animals'),  // Session 56 audit: was "tɔ'lɔ́" — dict says "to'lə"
  AwingWord(awing: "aŋkə'á", english: 'rooster', category: 'animals'),  // Session 56 audit: was "əŋka'ɔ́" — dict says "aŋkə'á"
  // Beginner nature
  AwingWord(awing: 'atɨə', english: 'tree', category: 'nature'),  // Session 56 audit: was "atîə" — dict says "atɨə"
  AwingWord(awing: 'akoobá', english: 'forest', category: 'nature'),  // Session 56 audit: was "akoobɔ́" — dict says "akoobá"
  AwingWord(awing: "ngɔ́'ə", english: 'stone', category: 'nature'),  // Session 56 audit: was "ngə'ə" — dict says "ngɔ́'ə"
  AwingWord(awing: 'wáako', english: 'sand', category: 'nature'),  // Session 56 audit: was "wâakɔ́" — dict says "wáako"
  AwingWord(awing: 'afûə', english: 'leaf', category: 'nature'),
  // REMOVED sánə "moon" — per dict EXACT match sánə = "break" (verb). The Awing word for moon is sáŋə (now corrected below) (Session 51 audit)
  // REMOVED ndě "water (drink)" — per Awing English Dictionary ndě has 3 homonyms: 1) elder/voc 2) neck (n 1/6) 3) house, inheritance (n 9/6). NONE mean water. The correct word for water/river is nkǐə (rising tone). Compounds like ndě móga "kitchen" use the "house" sense. (User-flagged Session 52)
  AwingWord(awing: 'pôb', english: 'fire', category: 'nature'),  // Session 56 audit: was "íŋə" — dict says "pôb"
  AwingWord(awing: 'àlě', english: 'day', category: 'nature'),
  AwingWord(awing: 'alóma', english: 'cloud', category: 'nature'),  // Session 56 audit: was "aləmə" — dict says "alóma"
  AwingWord(awing: 'alemó', english: 'pool', category: 'nature'),  // Session 56 audit: was "aləmó" — dict says "alemó"
  // CORRECTED nkîə "river/stream" → nkǐə "water; river" — per Awing English Dictionary EXACT match: nkǐə (rising tone, n 1/6, homonym 1) = "1) water 2) river". Same word for both per user. (User-flagged Session 52)
  AwingWord(awing: 'nkǐə', english: 'water; river', category: 'nature'),
  AwingWord(awing: 'nəpóolə', english: 'sky', category: 'nature'),
  AwingWord(awing: 'mánuma', english: 'sun', category: 'nature'),  // Session 56 audit: was "mɔ́numə" — dict says "mánuma"
  AwingWord(awing: 'mbaŋə', english: 'rain', category: 'nature'),  // Session 56 audit: was "mbəŋə" — dict says "mbaŋə"
  AwingWord(awing: 'sáma', english: 'wind', category: 'nature'),  // Session 56 audit: was "sɔ́mə" — dict says "sáma"
  AwingWord(awing: 'nəyeŋə́', english: 'grass', category: 'nature'),  // Session 56 audit: was "nəyeŋɔ́" — dict says "nəyeŋə́"
  AwingWord(awing: 'nəfaŋə', english: 'thunder', category: 'nature'),  // Session 56 audit: was "nəfáŋɔ́" — dict says "nəfaŋə"
  AwingWord(awing: "nətú'ə", english: 'night', category: 'nature'),
  // REMOVED alě "morning" — per dict EXACT match alě = "day" (which is already in line 161 as àlě). The Awing word for "morning" is not yet PDF-confirmed. (Session 51 audit)
  AwingWord(awing: 'nkwaná', english: 'evening', category: 'nature'),  // Session 56 audit: was "nkwanɔ́" — dict says "nkwaná"
  AwingWord(awing: 'alanə', english: 'road/path', category: 'nature'),
  AwingWord(awing: 'nəfógə', english: 'waterfall', category: 'nature'),
  AwingWord(awing: 'ndəsê', english: 'ground/earth', category: 'nature'),
  AwingWord(awing: 'móláglə', english: 'shadow', category: 'nature'),  // Session 56 audit: was "mɔ́lɔ̂glə" — dict says "móláglə"
  AwingWord(awing: 'ndo', english: 'valley', category: 'nature'),
  AwingWord(awing: 'nkwəənə', english: 'mountain', category: 'nature'),
  AwingWord(awing: "nkya' sáŋə", english: 'moonlight', category: 'nature'),
  // Medium/Expert
  AwingWord(awing: 'anyiŋə', english: 'claw', category: 'animals', difficulty: 2),  // Session 56 audit: was "anyeŋə" — dict says "anyiŋə"
  AwingWord(awing: 'nənjwínə', english: 'fly', category: 'animals', difficulty: 2),  // Session 56 audit: was "nənjwínnə" — dict says "nənjwínə"
  AwingWord(awing: "ngó'ə́", english: 'termite', category: 'animals', difficulty: 2),  // Session 56 audit: was "ngə'ɔ́" — dict says "ngó'ə́"
  AwingWord(awing: "njɔ́ə", english: 'groundnuts', category: 'nature', difficulty: 2),
  AwingWord(awing: "nkəŋə", english: 'peace plant', category: 'nature', difficulty: 2),
  AwingWord(awing: 'ɔ̀fɨ̂ə', english: 'medicine', category: 'nature', difficulty: 1),
  AwingWord(awing: 'afoonə', english: 'hunting', category: 'nature', difficulty: 2),  // Session 56 audit: was "əfóonə" — dict says "afoonə"
  AwingWord(awing: 'akəghaŋə', english: 'okra', category: 'nature', difficulty: 2),  // Session 56 audit: was "əkəghanə" — dict says "akəghaŋə"
  // New from phonology PDF — more nature words
  AwingWord(awing: 'əkûə', english: 'hole/pit', category: 'nature'),
  AwingWord(awing: 'aɣə\'ɔ́', english: 'cave', category: 'nature', difficulty: 1),
  AwingWord(awing: 'nəkwuunə́', english: 'entrance', category: 'nature', difficulty: 2),  // Session 56 audit: was "nəkwùːnɔ́" — dict says "nəkwuunə́"
  AwingWord(awing: 'asháŋə', english: 'hill', category: 'nature'),
  AwingWord(awing: 'ndùə', english: 'dust', category: 'nature'),
  AwingWord(awing: 'ŋgóŋə', english: 'swamp', category: 'nature', difficulty: 1),
  AwingWord(awing: 'əfɔ̂glə', english: 'marsh', category: 'nature', difficulty: 1),
  AwingWord(awing: 'ndzəmə', english: 'back (place)', category: 'nature', difficulty: 1),
  AwingWord(awing: 'atsə̂ŋə', english: 'outside area', category: 'nature', difficulty: 1),
  AwingWord(awing: 'ŋkə́ə', english: 'clearing', category: 'nature', difficulty: 1),
  // New animals from orthography/phonology PDFs
  AwingWord(awing: 'ŋgàbə', english: 'crab', category: 'animals'),
  AwingWord(awing: 'nətwéenə', english: 'spider', category: 'animals'),
  AwingWord(awing: 'ŋgwíŋə', english: 'bee', category: 'animals'),
  AwingWord(awing: 'ndzomə', english: 'worm', category: 'animals'),
  AwingWord(awing: 'əghâlə', english: 'lizard', category: 'animals'),
  // Session 52 gloss audit: was "pangolin" — dict has no "pangolin" sense; primary = "cane, walking stick, club, cudgel"
  AwingWord(awing: 'mbâŋə', english: 'cane, walking stick', category: 'things', difficulty: 2),
  AwingWord(awing: 'ŋgwâŋə', english: 'porcupine', category: 'animals', difficulty: 1),
  AwingWord(awing: 'nkwúbə', english: 'dove', category: 'animals'),
  AwingWord(awing: 'ŋkwɔ́ŋə', english: 'parrot', category: 'animals', difficulty: 1),
  // === NEW: PDF-verified entries (Session 37) ===
  AwingWord(awing: 'máwúmə́', english: 'hawk', category: 'animals', difficulty: 2),  // Session 56 audit: was "máwúmɔ́" — dict says "máwúmə́"
  AwingWord(awing: 'pɨ̌\'ɔ', english: 'hen', category: 'animals', difficulty: 1),
  AwingWord(awing: 'njakásə', english: 'jackal', category: 'animals', difficulty: 3),  // Session 56 audit: was "njakaŋɔ" — dict says "njakásə"
  AwingWord(awing: "nkámázɔ́'ə́", english: 'monkey', category: 'animals', difficulty: 2),  // Session 56 audit: was "nkámɔ́zɔ'ɔ́" — dict says "nkámázɔ́'ə́"
  AwingWord(awing: 'nɔ́sanɔ́', english: 'ocean/sea', category: 'nature', difficulty: 1),
  AwingWord(awing: 'nkɔŋ nó ngɔ́sma', english: 'rainbow', category: 'nature', difficulty: 1),
  AwingWord(awing: 'nkya\' sáŋa', english: 'moonlight', category: 'nature', difficulty: 1),
  AwingWord(awing: 'mɔ̀m napooɔ́la', english: 'heaven', category: 'nature', difficulty: 3),
  AwingWord(awing: 'sfoŋhasɔ́mɔ́', english: 'lake', category: 'nature', difficulty: 1)];

/// Food and drink — things kids eat and drink
const List<AwingWord> foodDrink = [
  // Beginner — common foods
  AwingWord(awing: 'majîə', english: 'food/meal', category: 'food'),
  AwingWord(awing: "amú'á", english: 'banana', category: 'food'),  // Session 56 audit: was "amú'ɔ́" — dict says "amú'á"
  AwingWord(awing: "azó'ə", english: 'yam', category: 'food'),
  AwingWord(awing: "akwu'ó", english: 'cocoyam', category: 'food'),  // Session 56 audit: was "akwú'ɔ́" — dict says "akwu'ó"
  AwingWord(awing: 'ngəsáŋɔ́', english: 'corn/maize', category: 'food'),
  AwingWord(awing: 'nûə', english: 'honey', category: 'food'),
  AwingWord(awing: 'ndzě', english: 'vegetable', category: 'food'),
  AwingWord(awing: 'mâfɛ', english: 'sweet potato', category: 'food'),  // Session 56 audit: was "mâfe" — dict says "mâfɛ"
  AwingWord(awing: 'apopó', english: 'pawpaw', category: 'food'),
  AwingWord(awing: 'nəpumə́', english: 'egg', category: 'food', pluralForm: 'mbumɔ́'),  // Session 56 audit: was "nəpumɔ́" — dict says "nəpumə́"
  AwingWord(awing: 'neemə', english: 'meat', category: 'food'),
  AwingWord(awing: 'nəkwúnə', english: 'rice', category: 'food'),
  AwingWord(awing: 'máliga', english: 'milk', category: 'food'),  // Session 56 audit: was "mɔ́lígə" — dict says "máliga"
  AwingWord(awing: 'lámósə', english: 'orange', category: 'food'),  // Session 56 audit: was "lámɔ́sə" — dict says "lámósə"
  AwingWord(awing: 'tâmto', english: 'tomato', category: 'food'),
  AwingWord(awing: "ná'ə", english: 'soup/sauce', category: 'food'),
  AwingWord(awing: 'ngwápə', english: 'guava', category: 'food'),  // Session 56 audit: was "ngwápa" — dict says "ngwápə"
  AwingWord(awing: 'panápəələ', english: 'pineapple', category: 'food'),  // Session 56 audit: was "panɔ́paələ" — dict says "panápəələ"
  AwingWord(awing: 'akəfə', english: 'coffee', category: 'food'),  // Session 56 audit: was "akəfé" — dict says "akəfə"
  AwingWord(awing: 'pyâ', english: 'avocado', category: 'food'),
  AwingWord(awing: 'ngéemə', english: 'bunch of banana', category: 'food'),
  AwingWord(awing: "achú'ə", english: 'pounded cocoyam', category: 'food'),
  AwingWord(awing: "nələ'ə́", english: 'sweet yam', category: 'food'),  // Session 56 audit: was "nəlɔ'ɔ́" — dict says "nələ'ə́"
  AwingWord(awing: 'nkwûə', english: 'sort of okra', category: 'food'),
  AwingWord(awing: 'ónyúsə', english: 'onion', category: 'food'),  // Session 56 audit: was "ɔ́nyúsə" — dict says "ónyúsə"
  // Medium
  AwingWord(awing: 'aŋkəsálə', english: 'cassava', category: 'food', difficulty: 1),
  AwingWord(awing: 'ngəəbə', english: 'goblet', category: 'food', difficulty: 2),  // Session 56 audit: was "nəgɔ̌əbə" — dict says "ngəəbə"
  AwingWord(awing: 'apéenə', english: 'fufu corn', category: 'food', difficulty: 1),
  AwingWord(awing: 'gəlébə', english: 'grape', category: 'food', difficulty: 2),  // Session 56 audit: was "galéba" — dict says "gəlébə"
  AwingWord(awing: "shí sɔ̂ntê", english: 'green pepper', category: 'food', difficulty: 2),
  AwingWord(awing: "paŋ sɔ̂ntê", english: 'red pepper', category: 'food', difficulty: 2),
  AwingWord(awing: "nkɔ̂ŋ ɔ̂'lə", english: 'sugar cane', category: 'food', difficulty: 2),
  // New food from phonology/orthography PDFs
  // REMOVED ndzě ndě "water leaf" — used ndě as water (wrong; ndě = neck/elder/house). ndzě alone = "vegetable" per dict. Compound unverified. (User-flagged Session 52)
  AwingWord(awing: 'ŋgə̂ŋə', english: 'palm wine', category: 'food', difficulty: 1),
  AwingWord(awing: 'nkúnə', english: 'oil', category: 'food'),
  // REMOVED asháŋə ndě "cooked rice" — both wrong: rice = nəkwúnə (not asháŋə) per dict, and ndě is not water. Replaced with verified dict entry. (User-flagged Session 52)
  AwingWord(awing: 'nkwə̂ə', english: 'kola nut', category: 'food', difficulty: 1),
  AwingWord(awing: 'ŋgə́ŋə', english: 'palm fruit', category: 'food', difficulty: 1),
  // REMOVED mbənə "flour" — per Awing English Dictionary mbənə is a grammatical exclamation marker, not "flour" (Session 51 audit, EXACT match)
  AwingWord(awing: 'ntsɔ́ŋə', english: 'salt (local)', category: 'food', difficulty: 1),
  AwingWord(awing: 'ŋgwénə', english: 'mushroom', category: 'food'),
  // Session 52 gloss audit: was "pepper (spice)" — dict says "1) prison. 2) penalty, punishment"
  AwingWord(awing: 'atsǎŋə', english: 'prison; penalty', category: 'things'),
  AwingWord(awing: 'ndzɔ̂ŋə', english: 'sugar', category: 'food'),
  AwingWord(awing: 'mbwáŋə', english: 'fresh corn', category: 'food')];

/// Simple actions (verbs) — everyday actions kids can act out
const List<AwingWord> actions = [
  // Beginner — simple everyday actions
  AwingWord(awing: 'nô', english: 'drink', category: 'actions'),
  AwingWord(awing: 'yǐə', english: 'come', category: 'actions'),
  AwingWord(awing: 'fê', english: 'give', category: 'actions'),
  AwingWord(awing: 'mîəə', english: 'swallow', category: 'actions'),  // Session 56 audit: was "mîə" — dict says "mîəə"
  AwingWord(awing: 'lúmə', english: 'bite', category: 'actions'),
  AwingWord(awing: "zó'ə", english: 'hear', category: 'actions'),
  // CORRECTED pímə "see" → "believe; accept" — per Awing English Dictionary EXACT match: "1) believe 2) accept 3) admit a truth 4) confess" (Session 51 audit, user-flagged)
  AwingWord(awing: 'pímə', english: 'believe; accept', category: 'actions'),
  AwingWord(awing: 'pɛ́nə', english: 'dance', category: 'actions'),
  AwingWord(awing: "cha'tə̂", english: 'greet', category: 'actions'),  // Session 56 audit: was "cha'tɔ́" — dict says "cha'tə̂"
  AwingWord(awing: 'túmə', english: 'send', category: 'actions'),
  AwingWord(awing: 'léŋə', english: 'lick', category: 'actions'),
  AwingWord(awing: "lyáŋə", english: 'hide', category: 'actions'),
  AwingWord(awing: 'fínə', english: 'sell', category: 'actions', shortForm: 'fi'),
  AwingWord(awing: 'ghenə̂', english: 'go', category: 'actions'),  // Session 56 audit: was "ghɛnɔ́" — dict says "ghenə̂"
  AwingWord(awing: 'pìə', english: 'give birth', category: 'actions'),
  // Session 52 gloss audit: was "smell" — dict says "continuously" / "1) also. 2) too (additive marker)"
  AwingWord(awing: 'kâ', english: 'also; too', category: 'descriptive'),
  AwingWord(awing: 'tɨ̂ə', english: 'stand', category: 'actions', shortForm: 'tî'),
  AwingWord(awing: 'kwúnə', english: 'enter', category: 'actions'),
  AwingWord(awing: 'kəənə̂', english: 'run', category: 'actions'),  // Session 56 audit: was "kə́ərə" — dict says "kəənə̂"
  // Session 52: was kíə "pay (money)" — kíə (high tone) does not exist in the
  // Awing English Dictionary. Per dict, "pay (for goods, services, etc.)" = tûə.
  AwingWord(awing: 'tûə', english: 'pay (for goods)', category: 'actions', tonePattern: 'falling', shortForm: 'ńtú'),
  AwingWord(awing: 'fɔ̂nə', english: 'read', category: 'actions'),
  AwingWord(awing: 'jwiəə', english: 'breathe', category: 'actions'),  // Session 56 audit: was "jwîə" — dict says "jwiəə"
  AwingWord(awing: 'pyáabə', english: 'watch/wait', category: 'actions'),
  AwingWord(awing: 'kyagó', english: 'untie', category: 'actions'),
  AwingWord(awing: 'náŋə', english: 'look at', category: 'actions'),  // Session 56 audit: was "ńnáŋ" — dict says "náŋə"
  AwingWord(awing: 'jíə', english: 'eat', category: 'actions'),
  AwingWord(awing: 'lê', english: 'sleep', category: 'actions'),
  // REMOVED jwítə "rest" — per Awing English Dictionary jwítə means "kill, murder" (unsafe in kids' app, dict EXACT match Session 51 audit)
  AwingWord(awing: "júnə", english: 'buy', category: 'actions'),
  AwingWord(awing: 'kóolə', english: 'catch/harvest', category: 'actions'),
  AwingWord(awing: 'ghɛdtɔ́', english: 'do a little', category: 'actions'),
  AwingWord(awing: 'nyinɔ́', english: 'walk/travel', category: 'actions'),
  AwingWord(awing: 'nyintô', english: 'take a walk', category: 'actions'),  // Session 56 audit: was "nyintɔ́" — dict says "nyintô"
  AwingWord(awing: 'tómə', english: 'kick/shoot', category: 'actions'),
  AwingWord(awing: 'sóŋə', english: 'say/speak', category: 'actions'),
  AwingWord(awing: 'wiŋə', english: 'laugh', category: 'actions'),  // Session 56 audit: was "wiŋɔ́" — dict says "wiŋə"
  AwingWord(awing: 'weŋô', english: 'smile', category: 'actions'),  // Session 56 audit: was "weŋɔ́" — dict says "weŋô"
  AwingWord(awing: 'kyéŋə', english: 'cry/weep', category: 'actions'),
  AwingWord(awing: 'zoobə̂', english: 'sing', category: 'actions'),  // Session 56 audit: was "zoobɔ́" — dict says "zoobə̂"
  AwingWord(awing: "ŋwa'lô", english: 'write', category: 'actions'),  // Session 56 audit: was "ŋwa'lɔ́" — dict says "ŋwa'lô"
  AwingWord(awing: "zé'ka", english: 'teach', category: 'actions'),  // Session 56 audit: was "zé'kə" — dict says "zé'ka"
  AwingWord(awing: "zé'ə", english: 'learn', category: 'actions'),
  AwingWord(awing: 'pookô', english: 'say goodbye', category: 'actions'),  // Session 56 audit: was "pookɔ́" — dict says "pookô"
  AwingWord(awing: 'sogə', english: 'wash', category: 'actions'),  // Session 56 audit: was "sogɔ́" — dict says "sogə"
  AwingWord(awing: 'léelə', english: 'prepare', category: 'actions'),
  AwingWord(awing: 'kamtə̂', english: 'eat hastily', category: 'actions'),  // Session 56 audit: was "kamtɔ́" — dict says "kamtə̂"
  AwingWord(awing: 'loonɔ́', english: 'desire/want', category: 'actions'),
  AwingWord(awing: "wó'tə", english: 'remember', category: 'actions'),  // Session 56 audit: was "wɔ́'tə" — dict says "wó'tə"
  AwingWord(awing: 'piímə', english: 'believe/accept', category: 'actions'),
  AwingWord(awing: 'ləgnə̂', english: 'forget', category: 'actions'),  // Session 56 audit: was "logŋə" — dict says "ləgnə̂"
  // Medium
  AwingWord(awing: "tsó'ə", english: 'heal', category: 'actions', difficulty: 2),
  AwingWord(awing: 'kwágə', english: 'cough', category: 'actions', difficulty: 1),
  AwingWord(awing: 'fyáalə', english: 'chase', category: 'actions', difficulty: 1),
  AwingWord(awing: "ŋá'ə", english: 'open', category: 'actions', difficulty: 2),
  AwingWord(awing: 'jágə', english: 'yawn', category: 'actions', difficulty: 1),
  AwingWord(awing: 'séenə', english: 'cut open', category: 'actions', difficulty: 2),  // Session 56 audit: was "sɛ́nə" — dict says "séenə"
  AwingWord(awing: 'tséebə', english: 'talk', category: 'actions', difficulty: 2, shortForm: 'tsáb'),  // Session 56 audit: was "tsɛ́bə" — dict says "tséebə"
  // Session 52 gloss audit: was "find" — dict says 'demonstrative adjective "this" (noun classes 5, 7, 9)'
  AwingWord(awing: 'zə́ənə', english: 'this (demonstrative)', category: 'descriptive', difficulty: 1),
  // Session 52 gloss audit: was "sell" (that is fínə, already at L293) — dict says "new" / "resemble"
  AwingWord(awing: 'fìə', english: 'new; resemble', category: 'descriptive', difficulty: 2, shortForm: 'fî'),
  AwingWord(awing: 'mwé', english: 'salty', category: 'actions', difficulty: 1),
  AwingWord(awing: "myá'á", english: 'throw away', category: 'actions', difficulty: 2),
  // New actions from phonology PDF
  // Session 52 gloss audit: was "snore" — dict says "1) take. 2) listen"
  AwingWord(awing: 'kǒ', english: 'take; listen', category: 'actions', difficulty: 1),
  AwingWord(awing: 'pá\'ə', english: 'braid/plait', category: 'actions', difficulty: 1),
  AwingWord(awing: 'kyê', english: 'pluck', category: 'actions', difficulty: 2),  // Session 56 audit: was "kjê" — dict says "kyê"
  AwingWord(awing: 'kəŋtə̂', english: 'be pleased', category: 'actions', difficulty: 2),  // Session 56 audit: was "kòŋtə́" — dict says "kəŋtə̂"
  AwingWord(awing: 'shǎmtə', english: 'widen', category: 'actions', difficulty: 1),
  AwingWord(awing: 'tʰímə', english: 'string beads', category: 'actions', difficulty: 3),
  AwingWord(awing: 'nɛ́rə', english: 'groan with pain', category: 'actions', difficulty: 2),
  AwingWord(awing: 'fwɔ̀ːtə', english: 'mumble', category: 'actions', difficulty: 3),
  // Session 52: was sáŋə "sweep (with broom)" — WRONG. Per dictionary, sáŋə = "moon, month"
  // (or homonym "bird"). The Awing word for "sweep" is zəgə (already at L2321).
  // The word for "broom" is nəsáŋə (already at L3310). Replaced with the verb that
  // ACTUALLY means sweep, but kept as a duplicate-removed comment to avoid clash with L2321.
  // sáŋə itself is preserved as a nature word elsewhere if needed.
  AwingWord(awing: 'chínə', english: 'build', category: 'actions'),  // Session 56 audit: was "tsíə" — dict says "chínə"
  AwingWord(awing: 'sɛ̀glə', english: 'weave', category: 'actions', difficulty: 1),
  AwingWord(awing: 'kpɔ́ŋə', english: 'break', category: 'actions'),
  AwingWord(awing: 'dɛ̀ŋə', english: 'carry on head', category: 'actions'),
  AwingWord(awing: 'nyâŋə', english: 'mix/stir', category: 'actions'),
  AwingWord(awing: 'tɔ̀ŋə', english: 'pound (with mortar)', category: 'actions'),
  AwingWord(awing: 'kwelô', english: 'pour', category: 'actions'),  // Session 56 audit: was "kwɛ́nə" — dict says "kwelô"
  AwingWord(awing: 'tsɔ́mə', english: 'squeeze', category: 'actions', difficulty: 1),
  AwingWord(awing: 'shɔ́ŋə', english: 'climb', category: 'actions'),
  AwingWord(awing: 'bwɔ́nə', english: 'mould/shape', category: 'actions', difficulty: 1),
  AwingWord(awing: 'fɔ̀ŋə', english: 'blow (fire)', category: 'actions'),
  AwingWord(awing: 'tsɛ́rə', english: 'stop up/block', category: 'actions', difficulty: 2),
  AwingWord(awing: 'dzə̀mə', english: 'think/reflect', category: 'actions'),
  AwingWord(awing: 'lwɔ̀ŋə', english: 'count/calculate', category: 'actions'),
  AwingWord(awing: 'náŋnə', english: 'cook', category: 'actions'),  // Session 56 audit: was "nə̂ŋə" — dict says "náŋnə"
  AwingWord(awing: 'tɔ̀ə', english: 'plant (seed)', category: 'actions'),
  AwingWord(awing: 'kəmtɔ́', english: 'harvest', category: 'actions'),
  AwingWord(awing: 'njwíŋə', english: 'whistle', category: 'actions'),
  AwingWord(awing: 'ŋwàŋə', english: 'return', category: 'actions'),
  AwingWord(awing: 'wúnə', english: 'ask', category: 'actions'),  // Session 56 audit: was "kwɨ̌nə" — dict says "wúnə"
  AwingWord(awing: 'pá\'tə', english: 'share/divide', category: 'actions'),
  // Session 52 gloss audit: CRITICAL FIX — was "praise", dict says "1) curse. 2) destroy. 3) spoil" (OPPOSITE meaning)
  AwingWord(awing: 'tsə́ŋə', english: 'curse; destroy; spoil', category: 'actions', difficulty: 3),
  AwingWord(awing: 'shwɔ́ŋə', english: 'pray', category: 'actions', difficulty: 2),
  // === NEW: PDF-verified entries (Session 37) ===
  AwingWord(awing: 'kwûə', english: 'die', category: 'actions', difficulty: 1),  // Session 56 audit: was "kwúɔ" — dict says "kwûə"
  AwingWord(awing: 'tóŋə', english: 'dig', category: 'actions', difficulty: 1),  // Session 56 audit: was "fóŋɔ" — dict says "tóŋə"
  AwingWord(awing: 'tsóolə', english: 'descend', category: 'actions', difficulty: 2),  // Session 56 audit: was "tsóolɔ" — dict says "tsóolə"
  AwingWord(awing: 'tsanɔ́', english: 'destroy', category: 'actions', difficulty: 1),
  AwingWord(awing: 'looóɔ', english: 'want/desire', category: 'actions', difficulty: 1),
  AwingWord(awing: 'túga', english: 'have', category: 'actions', difficulty: 1),
  AwingWord(awing: "zó'ə", english: 'hear', category: 'actions', difficulty: 1),  // Session 56 audit: was "zo'ɔ" — dict says "zó'ə"
  AwingWord(awing: 'kwáatə', english: 'help', category: 'actions', difficulty: 1),  // Session 56 audit: was "kwaalɔ" — dict says "kwáatə"
  AwingWord(awing: "fi'nə̂", english: 'imitate', category: 'actions', difficulty: 2),  // Session 56 audit: was "fî'nɔ́" — dict says "fi'nə̂"
  AwingWord(awing: 'téekə', english: 'join', category: 'actions', difficulty: 1),  // Session 56 audit: was "téeka" — dict says "téekə"
  AwingWord(awing: "tá'ə", english: 'judge', category: 'actions', difficulty: 2),  // Session 56 audit: was "sá'ɔ" — dict says "tá'ə"
  AwingWord(awing: 'lîə', english: 'jump', category: 'actions', difficulty: 1),  // Session 56 audit: was "llia" — dict says "lîə"
  AwingWord(awing: "lo'kâ", english: 'keep', category: 'actions', difficulty: 2),  // Session 56 audit: was "bə'kɔ́" — dict says "lo'kâ"
  AwingWord(awing: 'chwígə', english: 'kiss', category: 'actions', difficulty: 2),  // Session 56 audit: was "chwiɔ́ɔ" — dict says "chwígə"
  AwingWord(awing: 'póŋə', english: 'lack', category: 'actions', difficulty: 2),  // Session 56 audit: was "póŋa" — dict says "póŋə"
  AwingWord(awing: "zé'ə", english: 'learn', category: 'actions', difficulty: 1),  // Session 56 audit: was "ze'ɔ́" — dict says "zé'ə"
  AwingWord(awing: 'noŋnɔ́', english: 'lie down', category: 'actions', difficulty: 1),
  AwingWord(awing: "jwó'tə", english: 'listen', category: 'actions', difficulty: 1),  // Session 56 audit: was "jwî'ɔ́ta" — dict says "jwó'tə"
  AwingWord(awing: 'fwonə̂', english: 'lock', category: 'actions', difficulty: 2),  // Session 56 audit: was "íwna" — dict says "fwonə̂"
  AwingWord(awing: 'ta\'a', english: 'search', category: 'actions', difficulty: 1),
  AwingWord(awing: 'tsóŋtə', english: 'make', category: 'actions', difficulty: 1),  // Session 56 audit: was "tsoŋkɔ́" — dict says "tsóŋtə"
  AwingWord(awing: "zó'ə", english: 'marry', category: 'actions', difficulty: 2),  // Session 56 audit: was "zɔ́'ɔ" — dict says "zó'ə"
  AwingWord(awing: 'ləŋə', english: 'melt', category: 'actions', difficulty: 2),  // Session 56 audit: was "loŋa" — dict says "ləŋə"
  AwingWord(awing: 'nóŋkə', english: 'nurse', category: 'actions', difficulty: 2),  // Session 56 audit: was "nɔŋka" — dict says "nóŋkə"
  AwingWord(awing: 'zo\'na', english: 'obey', category: 'actions', difficulty: 2),
  AwingWord(awing: 'kwáalə', english: 'obtain', category: 'actions', difficulty: 2),  // Session 56 audit: was "kwáala" — dict says "kwáalə"
  AwingWord(awing: 'nna\'', english: 'open', category: 'actions', difficulty: 1),
  AwingWord(awing: 'tûə', english: 'pay', category: 'actions', difficulty: 1),  // Session 56 audit: was "tía" — dict says "tûə"
  AwingWord(awing: "kwa'ə", english: 'play', category: 'actions', difficulty: 1),  // Session 56 audit: was "kwa'ɔ́" — dict says "kwa'ə"
  AwingWord(awing: 'píta', english: 'plant', category: 'actions', difficulty: 1),
  AwingWord(awing: "nə'â", english: 'press', category: 'actions', difficulty: 2),  // Session 56 audit: was "no'a" — dict says "nə'â"
  AwingWord(awing: "fya'â", english: 'quarrel', category: 'actions', difficulty: 2),  // Session 56 audit: was "fya'ɔ́" — dict says "fya'â"
  AwingWord(awing: 'kwúmtə', english: 'remember', category: 'actions', difficulty: 1),  // Session 56 audit: was "kwúmtɔ́" — dict says "kwúmtə"
  // Session 52 gloss audit: was "remove" — dict says "fellow-wife (co-wife in polygamous marriage)"
  AwingWord(awing: 'fóga', english: 'fellow-wife', category: 'family', difficulty: 1),
  AwingWord(awing: 'kwúblə', english: 'repent', category: 'actions', difficulty: 3),  // Session 56 audit: was "kwúbla" — dict says "kwúblə"
  AwingWord(awing: 'kyikâ', english: 'refuse', category: 'actions', difficulty: 2),  // Session 56 audit: was "kila" — dict says "kyikâ"
  AwingWord(awing: 'chwádkə', english: 'save', category: 'actions', difficulty: 2),  // Session 56 audit: was "chwaadka" — dict says "chwádkə"
  AwingWord(awing: 'sóŋə', english: 'say', category: 'actions', difficulty: 1),  // Session 56 audit: was "sóŋa" — dict says "sóŋə"
  AwingWord(awing: 'ghabnə̂', english: 'separate', category: 'actions', difficulty: 2),  // Session 56 audit: was "ghabnɔ" — dict says "ghabnə̂"
  AwingWord(awing: "fa'ô", english: 'serve', category: 'actions', difficulty: 2),  // Session 56 audit: was "fa'a" — dict says "fa'ô"
  AwingWord(awing: 'tímə', english: 'sew', category: 'actions', difficulty: 2),  // Session 56 audit: was "tíma" — dict says "tímə"
  AwingWord(awing: 'ghabnə̂', english: 'share', category: 'actions', difficulty: 2),  // Session 56 audit: was "ghabnɔ́" — dict says "ghabnə̂"
  AwingWord(awing: "ŋwa'ô", english: 'shine', category: 'actions', difficulty: 1),  // Session 56 audit: was "gwa'a" — dict says "ŋwa'ô"
  AwingWord(awing: 'támə', english: 'shoot', category: 'actions', difficulty: 2),  // Session 56 audit: was "tóma" — dict says "támə"
  AwingWord(awing: 'naasla', english: 'show', category: 'actions', difficulty: 1),
  AwingWord(awing: 'kəŋə̂', english: 'shut', category: 'actions', difficulty: 1),  // Session 56 audit: was "kaŋɔ́" — dict says "kəŋə̂"
  AwingWord(awing: "gho'ə̂", english: 'grind', category: 'actions', difficulty: 1),  // Session 56 audit: was "ghə̀ŋə" — dict says "gho'ə̂"
  AwingWord(awing: 'lyǎŋə', english: 'hide', category: 'actions', difficulty: 1),
  AwingWord(awing: "tyá'la", english: 'straddle', category: 'actions', difficulty: 3),  // Session 56 audit: was "tyə́'lə" — dict says "tyá'la"
  AwingWord(awing: 'piə̀', english: 'sow', category: 'actions', difficulty: 1),
  AwingWord(awing: 'zòŋə́', english: 'follow', category: 'actions', difficulty: 1),
  AwingWord(awing: "lá'kə", english: 'thank', category: 'actions', difficulty: 1),  // Session 56 audit: was "lə́kə́" — dict says "lá'kə"
  AwingWord(awing: 'pjə́bə́', english: 'protect', category: 'actions', difficulty: 1)];

/// Things, objects, and food — words kids encounter daily
const List<AwingWord> thingsObjects = [
  // Beginner — everyday objects and food
  AwingWord(awing: 'ajúmə', english: 'thing', category: 'things'),
  // ndě homonym 3: house, inheritance. Used in compounds like
  // ndě móga (kitchen = house of cooking), ndě melo'ə (bar = house of
  // drinking), ndě móona (naming ceremony). The word for "water/river"
  // is nkǐə (rising tone), NOT ndě.
  AwingWord(awing: 'ndě', english: 'house, inheritance', category: 'things', difficulty: 1),
  AwingWord(awing: 'nəngoomá', english: 'plantain', category: 'things'),  // Session 56 audit: was "nəgoomɔ́" — dict says "nəngoomá"
  AwingWord(awing: 'ngwáŋə', english: 'salt', category: 'things'),
  AwingWord(awing: 'ndzɔ', english: 'beans', category: 'food'),  // Session 56 audit: was "ndzǒ" — dict says "ndzɔ"; Session 57: category 'things'→'food' (beans is food)
  AwingWord(awing: 'mândzǒ', english: 'groundnuts', category: 'things'),
  AwingWord(awing: "nəpɔ́'ə", english: 'pumpkin', category: 'things'),  // Session 56 audit: was "nəpɔ'ɔ́" — dict says "nəpɔ́'ə"
  AwingWord(awing: 'ndua', english: 'hammer', category: 'things'),  // Session 56 audit: was "nduə" — dict says "ndua"
  AwingWord(awing: 'əkwuná', english: 'bed', category: 'things'),  // Session 56 audit: was "əkwunɔ́" — dict says "əkwuná"
  AwingWord(awing: 'nəkəŋ', english: 'pot', category: 'things', pluralForm: 'məkəŋɔ́'),  // Session 56 audit: was "nəkəŋɔ́" — dict says "nəkəŋ"
  AwingWord(awing: 'apeemə', english: 'bag', category: 'things', shortForm: 'apa'),
  AwingWord(awing: 'əpúmə', english: 'basket (large)', category: 'things'),
  AwingWord(awing: 'ajwika', english: 'window', category: 'things'),  // Session 56 audit: was "ajwikə" — dict says "ajwika"
  AwingWord(awing: 'mbê', english: 'knife', category: 'things'),
  AwingWord(awing: "akó'ə", english: 'chair', category: 'things'),  // Session 56 audit: was "kəíə" — dict says "akó'ə"
  AwingWord(awing: 'lɛ̀ərə', english: 'hat', category: 'things'),
  AwingWord(awing: "shwa'ə", english: 'razor', category: 'things'),  // Session 56 audit: was "shwa'a" — dict says "shwa'ə"
  AwingWord(awing: 'alóŋə', english: 'dance group', category: 'things'),  // Session 56 audit: was "əlɔ́ŋə" — dict says "alóŋə"
  AwingWord(awing: 'ŋgɛ̀ərə', english: 'gun', category: 'things'),
  AwingWord(awing: 'akwâalə', english: 'support', category: 'things'),
  AwingWord(awing: 'əpéenə', english: 'bread', category: 'things'),
  AwingWord(awing: "nətó'ə", english: 'potato', category: 'things'),
  AwingWord(awing: 'apúə', english: 'ashes', category: 'things'),
  AwingWord(awing: 'kóŋ', english: 'ditch', category: 'things'),  // Session 56 audit: was "kóŋó" — dict says "kóŋ"
  AwingWord(awing: "əsá'ə", english: 'needle', category: 'things'),
  AwingWord(awing: 'ndê', english: 'house', category: 'things'),
  AwingWord(awing: 'ntaŋə', english: 'hut', category: 'things'),  // Session 56 audit: was "ntɔ̂ŋɔ̂" — dict says "ntaŋə"
  AwingWord(awing: 'atógə', english: 'room', category: 'things'),  // Session 56 audit: was "atɔ́gə" — dict says "atógə"
  AwingWord(awing: 'asogə', english: 'soap', category: 'things'),
  AwingWord(awing: "atsa'á", english: 'clothes', category: 'things'),  // Session 56 audit: was "atsa'ɔ́" — dict says "atsa'á"
  AwingWord(awing: 'múto', english: 'car', category: 'things'),
  AwingWord(awing: "aŋwa'lə", english: 'book/school', category: 'things'),
  // Session 52: was kíə "key (lock)" — kíə (high tone) does not exist in the
  // Awing English Dictionary. Per dict, "key (from English)" = kîə (falling tone).
  AwingWord(awing: 'kîə', english: 'key', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'mógɔ́', english: 'fire/burn', category: 'things'),
  AwingWord(awing: 'chénə', english: 'chain', category: 'things'),
  AwingWord(awing: 'nkelá', english: 'rope', category: 'things', pluralForm: 'mənkelɔ́'),  // Session 56 audit: was "nkelɔ́" — dict says "nkelá"
  AwingWord(awing: 'nkwumə', english: 'box', category: 'things'),
  AwingWord(awing: 'bólə', english: 'ball', category: 'things'),  // Session 56 audit: was "bɔ̂lə" — dict says "bólə"
  AwingWord(awing: "ntso ndê", english: 'door', category: 'things'),
  AwingWord(awing: 'nkeemə́', english: 'basket', category: 'things'),  // Session 56 audit: was "nkéemɔ́" — dict says "nkeemə́"
  // Session 60: Removed `kwa'ɔ́ = plate` — Session 56 audit confirmed
  // `kwa'ɔ́` is a typo of `kwa'ə` (which means "play" not "plate") and
  // the correct entry is at line 458. This row was a fabrication that
  // a quiz tester reported as not matching the meaning.
  AwingWord(awing: 'nto', english: 'trousers', category: 'things'),
  AwingWord(awing: "ntó'ə", english: 'calabash', category: 'things'),
  AwingWord(awing: 'atso', english: 'musical instrument', category: 'things'),
  AwingWord(awing: 'ntaŋə', english: 'horn', category: 'things'),  // Session 56 audit: was "ntâŋɔ̂" — dict says "ntaŋə"
  AwingWord(awing: 'máta', english: 'mat', category: 'things'),
  // CORRECTED tone nkîə → nkǐə "song" — per dict, both homonyms (water/river AND song) use rising-tone nkǐə, not falling-tone nkîə (User-flagged Session 52)
  AwingWord(awing: 'nkǐə', english: 'song', category: 'things'),
  // REMOVED nda'ə "string" — per Awing English Dictionary nda'ə = "only, lone" (per CLAUDE.md, the only Awing word that does not end in a vowel; grammatical, not a kid-facing object). (Session 51 audit, EXACT match)
  AwingWord(awing: 'bɔ́bə', english: 'bulb/ball', category: 'things'),
  AwingWord(awing: 'ŋwíŋɔ́', english: 'machete/cutlass', category: 'things'),
  AwingWord(awing: 'apáŋə', english: 'bamboo', category: 'things'),  // Session 56 audit: was "ndaŋɔ́" — dict says "apáŋə"
  AwingWord(awing: 'táksə', english: 'tax', category: 'things'),  // Session 56 audit: was "táksa" — dict says "táksə"
  // Medium/Expert — less common objects
  AwingWord(awing: 'mbéenə', english: 'nail', category: 'things', difficulty: 1),
  AwingWord(awing: "fwə'ə", english: 'chisel', category: 'things', difficulty: 2),  // Session 56 audit: was "fwɔ'ə" — dict says "fwə'ə"
  AwingWord(awing: 'ndzəəmə', english: 'dream', category: 'things', difficulty: 2),  // Session 56 audit: was "ndzoəmə" — dict says "ndzəəmə"
  AwingWord(awing: 'ndwîgtə', english: 'end', category: 'things', difficulty: 1),
  AwingWord(awing: "əghâa", english: 'season', category: 'things', difficulty: 3),
  // New things from phonology/orthography PDFs
  // CORRECTED sáŋə "broom" → "moon/month" — per dict EXACT match sáŋə = "1) moon 2) month" or "bird" (Session 51 audit, recategorized to nature below)
  AwingWord(awing: 'sáŋə', english: 'moon/month', category: 'nature'),
  AwingWord(awing: 'atê', english: 'rust', category: 'things', difficulty: 1),
  AwingWord(awing: 'akɔ̀\'ə', english: 'stool/chair (traditional)', category: 'things'),
  AwingWord(awing: 'ŋgwánə', english: 'pot (clay)', category: 'things'),
  AwingWord(awing: 'nkwɔ̂ŋə', english: 'stick/staff', category: 'things'),
  AwingWord(awing: 'ətsê', english: 'mortar', category: 'things'),
  AwingWord(awing: 'mbə̂ŋə', english: 'drum', category: 'things'),
  AwingWord(awing: 'ŋgwɔ̂bə', english: 'bowl', category: 'things'),
  AwingWord(awing: 'atsúŋə', english: 'fence', category: 'things'),
  AwingWord(awing: "lí'ə", english: 'hoe', category: 'things'),  // Session 56 audit: was "mbé'ə" — dict says "lí'ə"
  AwingWord(awing: 'nəkwɔ́ŋə', english: 'pestle', category: 'things'),
  AwingWord(awing: 'ŋgwə̂ə', english: 'paddle/oar', category: 'things', difficulty: 1),
  AwingWord(awing: 'ntsɔ̂ŋə', english: 'market stall', category: 'things', difficulty: 1),
  AwingWord(awing: 'àtɔ̂glə', english: 'pillow', category: 'things'),
  AwingWord(awing: 'nkwə̂mə', english: 'container', category: 'things'),
  AwingWord(awing: 'əkə̂ŋə', english: 'cooking pot', category: 'things'),
  AwingWord(awing: 'ndwîglə', english: 'edge/end', category: 'things', difficulty: 1),
  AwingWord(awing: 'ndzɛ̀ŋə', english: 'trap', category: 'things', difficulty: 1),
  AwingWord(awing: 'atə̂ŋə', english: 'story/tale', category: 'things'),
  AwingWord(awing: 'ŋwà\'lə', english: 'letter/writing', category: 'things'),
  AwingWord(awing: 'ntɔ́gə', english: 'name', category: 'things'),
  AwingWord(awing: 'ŋkə̂ŋə', english: 'word/language', category: 'things'),
  // === NEW: PDF-verified entries (Session 37) ===
  AwingWord(awing: 'akwelə', english: 'herd', category: 'things', difficulty: 2),  // Session 56 audit: was "akwɛlɔ" — dict says "akwelə"
  AwingWord(awing: 'ndzaŋa', english: 'kind', category: 'things', difficulty: 1),
  AwingWord(awing: 'ndé moŋa', english: 'kitchen', category: 'things', difficulty: 1),
  AwingWord(awing: "kó'ó", english: 'ladder', category: 'things', difficulty: 2),  // Session 56 audit: was "kɔ́'ɔ" — dict says "kó'ó"
  AwingWord(awing: 'atséebə', english: 'language', category: 'things', difficulty: 2),  // Session 56 audit: was "ɔ́tsĕba" — dict says "atséebə"
  AwingWord(awing: 'noŋkə', english: 'law', category: 'things', difficulty: 3),  // Session 56 audit: was "noŋka" — dict says "noŋkə"
  AwingWord(awing: 'nchîmbîə', english: 'life', category: 'things', difficulty: 2),  // Session 56 audit: was "nchímbîɔ" — dict says "nchîmbîə"
  AwingWord(awing: "nkya'ə", english: 'light', category: 'things', difficulty: 1),  // Session 56 audit: was "nkya'ɔ" — dict says "nkya'ə"
  AwingWord(awing: 'ŋwíŋə', english: 'machete', category: 'things', difficulty: 1),  // Session 56 audit: was "nwîŋa" — dict says "ŋwíŋə"
  AwingWord(awing: 'ngəsáŋə́', english: 'corn', category: 'things', difficulty: 1),  // Session 56 audit: was "ngɔ́sáŋɔ́" — dict says "ngəsáŋə́"
  AwingWord(awing: 'nkəənə', english: 'message', category: 'things', difficulty: 1),  // Session 56 audit: was "nkáɔna" — dict says "nkəənə"
  AwingWord(awing: 'ntúmə', english: 'messenger', category: 'things', difficulty: 2),  // Session 56 audit: was "ntúma" — dict says "ntúmə"
  AwingWord(awing: 'anyi ntúmɔ', english: 'metal', category: 'things', difficulty: 1),
  AwingWord(awing: 'awɛ', english: 'mirror', category: 'things', difficulty: 1),
  AwingWord(awing: 'nkéebə', english: 'money', category: 'things', difficulty: 1),  // Session 56 audit: was "nkɛɛbɔ" — dict says "nkéebə"
  AwingWord(awing: 'akɔ́ɔma', english: 'happiness', category: 'things', difficulty: 1),
  AwingWord(awing: "ngá'ə", english: 'hardship', category: 'things', difficulty: 2),  // Session 56 audit: was "ngo'ɔ" — dict says "ngá'ə"
  AwingWord(awing: 'akwaŋə', english: 'idea', category: 'things', difficulty: 2),  // Session 56 audit: was "akwɔŋa" — dict says "akwaŋə"
  AwingWord(awing: 'aghoonó', english: 'illness', category: 'things', difficulty: 2),  // Session 56 audit: was "aghoɔnɔ́" — dict says "aghoonó"
  AwingWord(awing: 'nənyinə', english: 'journey', category: 'things', difficulty: 2),  // Session 56 audit: was "nanŷina" — dict says "nənyinə"
  AwingWord(awing: "əshí'nə", english: 'kindness', category: 'things', difficulty: 2),  // Session 56 audit: was "ashî'na" — dict says "əshí'nə"
  AwingWord(awing: "ndé'ə", english: 'necklace', category: 'things', difficulty: 2),  // Session 56 audit: was "ndé'ɔ́" — dict says "ndé'ə"
  AwingWord(awing: "əsá'ə", english: 'needle', category: 'things', difficulty: 1),  // Session 56 audit: was "sɔ́'a" — dict says "əsá'ə"
  AwingWord(awing: 'nka sáŋɔ́', english: 'nest', category: 'things', difficulty: 1),
  AwingWord(awing: "ajwa'áli'ó", english: 'noise', category: 'things', difficulty: 2),  // Session 56 audit: was "ajwa'ali'ɔ́" — dict says "ajwa'áli'ó"
  AwingWord(awing: 'ndenə', english: 'number', category: 'things', difficulty: 2),  // Session 56 audit: was "ndema" — dict says "ndenə"
  AwingWord(awing: 'atía nɔ́taɔna', english: 'palm tree', category: 'things', difficulty: 1),
  AwingWord(awing: 'alaŋó', english: 'path', category: 'things', difficulty: 1),  // Session 56 audit: was "alanɔ́" — dict says "alaŋó"
  AwingWord(awing: 'awaamɔ́mbɔama', english: 'patience', category: 'things', difficulty: 2),
  AwingWord(awing: 'ntûə', english: 'payment', category: 'things', difficulty: 2),  // Session 56 audit: was "ntía" — dict says "ntûə"
  AwingWord(awing: 'nkəŋə', english: 'peace', category: 'things', difficulty: 1),  // Session 56 audit: was "nkɔŋa" — dict says "nkəŋə"
  AwingWord(awing: "ndí'ə", english: 'poison', category: 'things', difficulty: 2),  // Session 56 audit: was "ndá'ɔ́" — dict says "ndí'ə"
  AwingWord(awing: 'naíɔ́\'ɔ', english: 'potato', category: 'things', difficulty: 1),
  AwingWord(awing: "shwa'ə", english: 'razor', category: 'things', difficulty: 2),  // Session 56 audit: was "shwa'ɔ" — dict says "shwa'ə"
  AwingWord(awing: 'ngwubə', english: 'shoe', category: 'things', difficulty: 1),  // Session 56 audit: was "ngwúba" — dict says "ngwubə"
  AwingWord(awing: 'msóm', english: 'sin', category: 'things', difficulty: 2),
  AwingWord(awing: 'asɔ́ɔma', english: 'shame', category: 'things', difficulty: 1),
  AwingWord(awing: "aŋwa'lə", english: 'school', category: 'things', difficulty: 1),  // Session 56 audit: was "agwa'la" — dict says "aŋwa'lə"
  AwingWord(awing: 'náanə', english: 'sea', category: 'things', difficulty: 1),  // Session 56 audit: was "nɔ́sana" — dict says "náanə"
  AwingWord(awing: 'sə̀bə̀ə̀bə́', english: 'thorn', category: 'things', difficulty: 1),
  AwingWord(awing: 'alědnə', english: 'wealth', category: 'things', difficulty: 2),  // Session 56 audit: was "alɛ́dnə̀" — dict says "alědnə"
  AwingWord(awing: 'ge:nə́', english: 'week', category: 'things', difficulty: 1),
  // Session 52 gloss audit: was "village" (that is alá'ə at L584) — dict says "hook" / "far future tense marker"
  AwingWord(awing: 'lá\'ə̀', english: 'hook', category: 'things', difficulty: 1),
  AwingWord(awing: 'mətuə́\'ə', english: 'caterpillar', category: 'things', difficulty: 1),
  AwingWord(awing: 'àkəỳə́', english: 'cave', category: 'things', difficulty: 1)];

/// Family, people, and places — essential for conversations
const List<AwingWord> familyPeople = [
  // Beginner — family and common places
  AwingWord(awing: 'mǎ', english: 'mother', category: 'family', pluralForm: 'pəmǎ'),
  AwingWord(awing: 'tátə', english: 'grandfather', category: 'family'),
  AwingWord(awing: 'mábna', english: 'baby', category: 'family'),
  // ndě has 3 homonyms per dict + native speaker (Dr. Sama):
  // (1) neck (body part) — entry 60 in bodyParts
  // (2) elder, person of higher rank — vocative form of address
  // (3) house, inheritance — entry below in thingsObjects
  // Water/river is NOT one of the meanings — that's nkǐə (rising tone).
  AwingWord(awing: 'ndě', english: 'elder, respected person', category: 'family', difficulty: 2),
  // REMOVED yə "he/she" — per Awing English Dictionary yə is an associative/possessive grammatical marker, not the pronoun for "he/she" (Session 51 audit, EXACT match)
  AwingWord(awing: "alá'ə", english: 'village', category: 'family', pluralForm: "əlá'ə"),
  AwingWord(awing: 'adě', english: 'house', category: 'family'),
  AwingWord(awing: 'ngye', english: 'voice', category: 'family'),
  AwingWord(awing: 'məteenə̂', english: 'market', category: 'family'),  // Session 56 audit: was "mətéenɔ́" — dict says "məteenə̂"
  AwingWord(awing: 'əfóŋə', english: 'reader', category: 'family', pluralForm: 'pəfɔ́nə'),  // Session 56 audit: was "əfɔ́nə" — dict says "əfóŋə"
  AwingWord(awing: 'ndáəshə', english: 'thief', category: 'family'),
  AwingWord(awing: 'ndimá', english: 'nephew', category: 'family'),  // Session 56 audit: was "əndìmə" — dict says "ndimá"
  AwingWord(awing: 'ngəmə́', english: 'mother-in-law', category: 'family'),  // Session 56 audit: was "ŋgàmə" — dict says "ngəmə́"
  AwingWord(awing: 'əgùərə', english: 'descendant', category: 'family'),
  AwingWord(awing: 'tǎ', english: 'father/parent', category: 'family', pluralForm: 'pətǎ'),
  AwingWord(awing: 'ngəənə', english: 'friend', category: 'family', pluralForm: 'pəghəənə'),
  AwingWord(awing: 'ndúmə', english: 'husband', category: 'family'),
  AwingWord(awing: 'mangyè', english: 'wife', category: 'family'),  // Session 56 audit: was "maŋgyè" — dict says "mangyè"
  AwingWord(awing: 'ndè', english: 'elder', category: 'family'),
  AwingWord(awing: 'əfo', english: 'chief/ruler', category: 'family'),
  AwingWord(awing: "ŋwunə", english: 'person', category: 'family', pluralForm: 'paənə'),
  AwingWord(awing: "mɔ́ mbyâŋnə", english: 'boy/son', category: 'family'),
  AwingWord(awing: "mɔ́ maŋgyè", english: 'girl/daughter', category: 'family'),
  AwingWord(awing: 'mɔ́ŋkə', english: 'child', category: 'family'),
  AwingWord(awing: 'ngaŋə', english: 'owner', category: 'family'),
  AwingWord(awing: "ngaŋəfa'ə", english: 'servant', category: 'family'),
  // Session 52 gloss audit: was "butcher" (the butcher is adzə̌ə at L637) — dict says "bucket"
  AwingWord(awing: "nkɔ́'ə", english: 'bucket', category: 'things'),
  AwingWord(awing: 'atúmə', english: 'country/land', category: 'family'),
  AwingWord(awing: 'afoonə', english: 'farm', category: 'family'),
  AwingWord(awing: 'nchîndê', english: 'compound', category: 'family'),
  // Session 52 gloss audit: was "place" — dict says "cultivated ground"
  AwingWord(awing: "ali'ə", english: 'cultivated ground', category: 'nature'),
  AwingWord(awing: 'awátə', english: 'hospital', category: 'family'),
  AwingWord(awing: 'chɔ́sə', english: 'church', category: 'family'),
  // Medium/Expert
  AwingWord(awing: 'ayáŋə', english: 'wisdom', category: 'family', difficulty: 2),
  AwingWord(awing: 'ndo', english: 'stream', category: 'family', difficulty: 2),  // Session 56 audit: was "nkɨ́ə" — dict says "ndo"
  // New family/people from phonology/orthography PDFs
  AwingWord(awing: 'mǎ wíŋɔ́', english: 'grandmother', category: 'family'),
  AwingWord(awing: 'nda', english: 'sister/sibling', category: 'family'),
  AwingWord(awing: 'nə̂ŋgə', english: 'brother', category: 'family'),
  AwingWord(awing: 'mɔ́\'ŋkə', english: 'young person', category: 'family'),
  AwingWord(awing: 'əfɔ̀nə', english: 'teacher', category: 'family'),
  AwingWord(awing: 'ətsɛ́bə', english: 'speaker/orator', category: 'family', difficulty: 1),
  AwingWord(awing: 'əzó\'ə', english: 'listener/judge', category: 'family', difficulty: 1),
  // Session 52 gloss audit: was "traditional doctor" — dict says "owner" (like ngaŋə at L603)
  AwingWord(awing: 'ngàŋə', english: 'owner', category: 'family', difficulty: 1),
  AwingWord(awing: 'əfo wíŋɔ́', english: 'paramount chief', category: 'family', difficulty: 1),
  AwingWord(awing: 'əkwáŋə', english: 'stranger/visitor', category: 'family'),
  AwingWord(awing: 'ndzɔ̂ŋə', english: 'age group', category: 'family', difficulty: 1),
  AwingWord(awing: 'əlúmə', english: 'hunter', category: 'family', difficulty: 1),
  AwingWord(awing: 'ŋgwîə', english: 'twins', category: 'family'),
  AwingWord(awing: 'əpɔ̀ŋə', english: 'co-wife', category: 'family', difficulty: 3),
  AwingWord(awing: 'nkwə̂ŋə', english: 'council/meeting', category: 'family', difficulty: 1),
  // === NEW: PDF-verified entries (Session 37) ===
  AwingWord(awing: 'mbɛ', english: 'chief', category: 'family', difficulty: 2),  // Session 56 audit: was "mɔ̂nə" — dict says "mbɛ"
  AwingWord(awing: 'mən\'ɔ', english: 'person', category: 'family', difficulty: 1),
  AwingWord(awing: 'məbîə', english: 'boy', category: 'family', difficulty: 1),
  AwingWord(awing: 'əbîə', english: 'girl', category: 'family', difficulty: 1),
  AwingWord(awing: 'məkwɛ́', english: 'servant', category: 'family', difficulty: 1),
  AwingWord(awing: 'adzə̌ə', english: 'butcher', category: 'family', difficulty: 1),
  AwingWord(awing: 'ndzɔ̂ŋɔ', english: 'country', category: 'family', difficulty: 1),
  // Session 52 gloss audit: was "place" — dict says 'where? (interrogative)'
  AwingWord(awing: 'àfó', english: 'where?', category: 'descriptive', difficulty: 1)];

/// Numbers and counting
const List<AwingWord> numbers = [
  AwingWord(awing: 'wûu', english: 'one', category: 'numbers'),  // Session 56 audit: was "əmɔ́" — dict says "wûu"
  AwingWord(awing: 'pě', english: 'two', category: 'numbers'),  // Session 56 audit: was "əpá" — dict says "pě"
  AwingWord(awing: 'wô', english: 'three', category: 'numbers'),  // Session 56 audit: was "əlɛ́" — dict says "wô"
  AwingWord(awing: 'kwa', english: 'four', category: 'numbers'),  // Session 56 audit: was "əkwá" — dict says "kwa"
  AwingWord(awing: 'tênə', english: 'five', category: 'numbers'),  // Session 56 audit: was "ətáanə" — dict says "tênə"
  AwingWord(awing: 'ntogə́', english: 'six', category: 'numbers'),
  AwingWord(awing: 'asaambê', english: 'seven', category: 'numbers'),
  AwingWord(awing: 'nəfeemə́', english: 'eight', category: 'numbers'),
  AwingWord(awing: 'nəpu\'ə́', english: 'nine', category: 'numbers'),
  AwingWord(awing: 'nəghámə', english: 'ten', category: 'numbers'),  // Session 56 audit: was "əghám" — dict says "nəghámə"
  // Teens (11-19) — dictionary: ntsəb + base number
  AwingWord(awing: 'əghám nə əmɔ́', english: 'eleven', category: 'numbers', difficulty: 1),
  AwingWord(awing: 'əghám nə əpá', english: 'twelve', category: 'numbers', difficulty: 1),
  AwingWord(awing: 'ntsəb teelə́', english: 'thirteen', category: 'numbers', difficulty: 1),
  AwingWord(awing: 'ntsəb nəkwa', english: 'fourteen', category: 'numbers', difficulty: 1),
  AwingWord(awing: 'ntsəb tênə', english: 'fifteen', category: 'numbers', difficulty: 1),
  AwingWord(awing: 'ntsəb ntogə́', english: 'sixteen', category: 'numbers', difficulty: 1),
  AwingWord(awing: 'ntsəb asaambê', english: 'seventeen', category: 'numbers', difficulty: 1),
  AwingWord(awing: 'ntsəb nəfeemə́', english: 'eighteen', category: 'numbers', difficulty: 1),
  AwingWord(awing: 'ntsəb nəpu\'ə́', english: 'nineteen', category: 'numbers', difficulty: 1),
  // Tens (20-90) — dictionary: məghə́m mén + base number
  AwingWord(awing: 'mbá', english: 'twenty', category: 'numbers', difficulty: 1),
  AwingWord(awing: 'mbá nə əghám', english: 'thirty', category: 'numbers', difficulty: 1),
  AwingWord(awing: 'mbá əpá', english: 'forty', category: 'numbers', difficulty: 1),
  AwingWord(awing: 'məghə́m mén tênə', english: 'fifty', category: 'numbers', difficulty: 1),
  AwingWord(awing: 'məghə́m mén ntogə́', english: 'sixty', category: 'numbers', difficulty: 1),
  AwingWord(awing: 'məghə́m mén asaambê', english: 'seventy', category: 'numbers', difficulty: 1),
  AwingWord(awing: 'məghə́m mén nəfeemə́', english: 'eighty', category: 'numbers', difficulty: 1),
  AwingWord(awing: 'məghə́m mén nəpu\'ə́', english: 'ninety', category: 'numbers', difficulty: 1),
  // Hundred (medium)
  AwingWord(awing: 'ŋgwú', english: 'hundred', category: 'numbers', difficulty: 1),
  // Compound twenties (21-25) — dictionary p.192
  AwingWord(awing: "məghə́m mém mbê nə́ tá'ə", english: 'twenty-one', category: 'numbers', difficulty: 3),
  AwingWord(awing: 'məghə́m mém mbê nə́ pém pê', english: 'twenty-two', category: 'numbers', difficulty: 3),
  AwingWord(awing: 'məghə́m mém mbê nə́ pén teelə́', english: 'twenty-three', category: 'numbers', difficulty: 3),
  AwingWord(awing: 'məghə́m mém mbê nə́ nəkwa', english: 'twenty-four', category: 'numbers', difficulty: 3),
  AwingWord(awing: 'məghə́m mém mbê nə́ pén tênə', english: 'twenty-five', category: 'numbers', difficulty: 3),
  // Hundreds (200-500) — dictionary: nked + base number
  AwingWord(awing: 'nked pê', english: 'two hundred', category: 'numbers', difficulty: 3),
  AwingWord(awing: 'nked teelə́', english: 'three hundred', category: 'numbers', difficulty: 3),
  AwingWord(awing: 'nked zén nəkwa', english: 'four hundred', category: 'numbers', difficulty: 3),
  AwingWord(awing: 'nked tênə', english: 'five hundred', category: 'numbers', difficulty: 3),
  // Thousand
  AwingWord(awing: 'tóosə', english: 'thousand', category: 'numbers', difficulty: 3),  // Session 56 audit: was "tə́sə" — dict says "tóosə"
];

// ============================================================
// MEDIUM/EXPERT VOCABULARY (difficulty: 2-3) — more complex words
// ============================================================

/// More actions/verbs from the orthography & phonology PDFs
const List<AwingWord> moreActions = [
  // Medium
  AwingWord(awing: 'shîəə', english: 'stretch', category: 'actions', difficulty: 2),  // Session 56 audit: was "shîə" — dict says "shîəə"
  AwingWord(awing: 'yîkə', english: 'harden', category: 'actions', difficulty: 1),
  AwingWord(awing: 'fágə', english: 'blow', category: 'actions', difficulty: 2),  // Session 56 audit: was "tɔ́gə" — dict says "fágə"
  AwingWord(awing: 'kaŋtə', english: 'stumble', category: 'actions', difficulty: 2),  // Session 56 audit: was "kaŋtɔ́" — dict says "kaŋtə"
  AwingWord(awing: 'sednô', english: 'turn round', category: 'actions', difficulty: 2),  // Session 56 audit: was "sɛdnɔ́" — dict says "sednô"
  AwingWord(awing: 'nyaglə', english: 'tickle', category: 'actions', difficulty: 2),  // Session 56 audit: was "nyaglɔ́" — dict says "nyaglə"
  AwingWord(awing: 'nɔ́ŋə', english: 'suck', category: 'actions', difficulty: 1),
  AwingWord(awing: 'lednə̂', english: 'sweat', category: 'actions', difficulty: 2),  // Session 56 audit: was "lɛdnɔ́" — dict says "lednə̂"
  // Session 52 gloss audit: was "twist" — dict says "give birth (by many women or many children by one)"
  AwingWord(awing: 'pìkə', english: 'give birth', category: 'actions', difficulty: 1),
  AwingWord(awing: 'kwúbtə', english: 'close', category: 'actions', difficulty: 1),
  AwingWord(awing: 'akwúblə', english: 'exchange', category: 'actions', difficulty: 2),  // Session 56 audit: was "kwùɔbə" — dict says "akwúblə"
  AwingWord(awing: 'lóŋkə', english: 'fill', category: 'actions', difficulty: 2),  // Session 56 audit: was "lɛ̀ŋkə" — dict says "lóŋkə"
  AwingWord(awing: 'ídkə', english: 'frighten', category: 'actions', difficulty: 1),
  AwingWord(awing: 'nwâŋə', english: 'disappear', category: 'actions', difficulty: 1),
  AwingWord(awing: 'ɔ̂ŋwâə', english: 'be clean', category: 'actions', difficulty: 1),
  AwingWord(awing: 'təənô', english: 'be mature', category: 'actions', difficulty: 2, shortForm: 'tə̂nə'),  // Session 56 audit: was "tɔ̂ənə" — dict says "təənô"
  AwingWord(awing: 'fìnə', english: 'resemble each other', category: 'actions', difficulty: 2),
  AwingWord(awing: "tyá'la", english: 'straddle', category: 'actions', difficulty: 2),  // Session 56 audit: was "tyá'lə" — dict says "tyá'la"
  AwingWord(awing: 'puónə', english: 'dip in water', category: 'actions', difficulty: 2),
  AwingWord(awing: 'chwígə', english: 'spy', category: 'actions', difficulty: 2),  // Session 56 audit: was "chwigó" — dict says "chwígə"
  // Expert
  AwingWord(awing: 'təəmə', english: 'choke', category: 'actions', difficulty: 3),  // Session 56 audit: was "tɔ́əmə" — dict says "təəmə"
  AwingWord(awing: "ne'â", english: 'limp', category: 'actions', difficulty: 3),  // Session 56 audit: was "ne'ɔ́" — dict says "ne'â"
  AwingWord(awing: 'pwódkə', english: 'appease', category: 'actions', difficulty: 3),  // Session 56 audit: was "pwɔ́nə" — dict says "pwódkə"
  AwingWord(awing: "ɔ̀pwə̂nənə", english: 'be kind', category: 'actions', difficulty: 3),
  AwingWord(awing: 'ntɨ́mmaə', english: 'stagger', category: 'actions', difficulty: 3)];

/// More things/objects — medium and expert level
const List<AwingWord> moreThings = [
  AwingWord(awing: 'nəchwélə', english: 'hearth', category: 'things', difficulty: 1),
  AwingWord(awing: "ntúmkə", english: 'entrance hut', category: 'things', difficulty: 2),
  AwingWord(awing: 'əleglə', english: 'bridge', category: 'things', difficulty: 2),  // Session 56 audit: was "əlɛɛlə" — dict says "əleglə"
  AwingWord(awing: 'ŋgwɔ́ɔlə', english: 'snail', category: 'things', difficulty: 1),
  AwingWord(awing: 'nəghǒ', english: 'grinding stone', category: 'things', difficulty: 1),
  AwingWord(awing: 'akwé', english: 'response', category: 'things', difficulty: 1),
  AwingWord(awing: 'akoolá', english: 'latrine', category: 'things', difficulty: 1),
  AwingWord(awing: "ashwí'ə", english: 'swelling', category: 'things', difficulty: 2),
  AwingWord(awing: 'njwîŋə', english: 'whistle', category: 'things', difficulty: 1),
  AwingWord(awing: 'mbwódnə', english: 'blessing', category: 'things', difficulty: 2),
  // Session 52 gloss audit: was "hardship" — dict says "year" / "red-feathered bird" / "termite"
  AwingWord(awing: "ngó'ə", english: 'year', category: 'things', difficulty: 2),
  AwingWord(awing: 'atsáŋə', english: 'punishment', category: 'things', difficulty: 3),
  AwingWord(awing: 'ŋwáglə', english: 'bell', category: 'things', difficulty: 3),  // Session 56 audit: was "ŋwáglɔ́" — dict says "ŋwáglə"
  AwingWord(awing: 'azagá', english: 'odour', category: 'things', difficulty: 3),  // Session 56 audit: was "azagɔ́" — dict says "azagá"
];

/// Descriptive words (adjectives/adverbs) — colors, sizes, qualities
const List<AwingWord> descriptiveWords = [
  // Colors and appearance
  AwingWord(awing: 'shíshíə', english: 'black', category: 'descriptive'),
  AwingWord(awing: 'fúfûə', english: 'white', category: 'descriptive'),
  AwingWord(awing: 'paŋə', english: 'red', category: 'descriptive'),  // Session 56 audit: was "paŋpaŋə" — dict says "paŋə"
  AwingWord(awing: 'sénə', english: 'blue/green/dark', category: 'descriptive'),
  // Size and shape
  AwingWord(awing: 'wíŋɔ́', english: 'big', category: 'descriptive'),
  AwingWord(awing: 'mɔ́', english: 'small', category: 'descriptive'),
  AwingWord(awing: 'sagɔ́', english: 'long/far', category: 'descriptive'),
  AwingWord(awing: 'kəmkə̂', english: 'short', category: 'descriptive'),  // Session 56 audit: was "kamkɔ̂" — dict says "kəmkə̂"
  AwingWord(awing: 'fáŋə', english: 'fat/thick', category: 'descriptive'),
  AwingWord(awing: 'ashwánə', english: 'thin', category: 'descriptive'),
  // Qualities
  // Session 52 gloss audit: was "good/kind" — dict says "trade"
  AwingWord(awing: "ashî'nə", english: 'trade', category: 'things'),
  AwingWord(awing: 'poŋô', english: 'beautiful', category: 'descriptive'),  // Session 56 audit: was "pɔ̀ŋɔ́" — dict says "poŋô"
  AwingWord(awing: 'tonô', english: 'hot', category: 'descriptive'),  // Session 56 audit: was "tɔnɔ́" — dict says "tonô"
  AwingWord(awing: 'nwâ', english: 'cold', category: 'descriptive'),
  AwingWord(awing: 'tyantɔ̌', english: 'hard/strong', category: 'descriptive'),
  AwingWord(awing: "fía", english: 'new/fresh', category: 'descriptive'),
  AwingWord(awing: 'ndenə', english: 'old', category: 'descriptive'),
  AwingWord(awing: 'mboŋɔ́', english: 'many/much', category: 'descriptive'),
  AwingWord(awing: "nta'lə", english: 'few/little', category: 'descriptive'),
  AwingWord(awing: 'senô', english: 'today', category: 'descriptive'),  // Session 56 audit: was "senɔ́" — dict says "senô"
  AwingWord(awing: "ngwe'ə́", english: 'tomorrow', category: 'descriptive'),  // Session 56 audit: was "ngwe'ɔ́" — dict says "ngwe'ə́"
  AwingWord(awing: 'zá', english: 'often/usually', category: 'descriptive'),
  // Medium difficulty
  AwingWord(awing: 'dotê', english: 'ugly', category: 'descriptive', difficulty: 2),  // Session 56 audit: was "dɔtɔ́" — dict says "dotê"
  AwingWord(awing: "təji'ə", english: 'alone', category: 'descriptive', difficulty: 2),  // Session 56 audit: was "tɔ̀jí'ə" — dict says "təji'ə"
  AwingWord(awing: 'páta', english: 'even though', category: 'descriptive', difficulty: 2),  // Session 56 audit: was "pátə" — dict says "páta"
  AwingWord(awing: 'chígɔ́', english: 'truly/really', category: 'descriptive', difficulty: 1),
  AwingWord(awing: 'ghâsə', english: 'clever/smart', category: 'descriptive', difficulty: 1),
  AwingWord(awing: 'zaŋkə', english: 'light (not heavy)', category: 'descriptive', difficulty: 2),  // Session 56 audit: was "zaŋkɔ̂" — dict says "zaŋkə"
  AwingWord(awing: 'kóŋɔ́', english: 'empty', category: 'descriptive', difficulty: 1),
  // New descriptive words from phonology/orthography PDFs
  AwingWord(awing: 'kwɨ̂ŋɔ́', english: 'sweet', category: 'descriptive'),
  AwingWord(awing: 'shwàŋə', english: 'sharp', category: 'descriptive'),
  AwingWord(awing: 'kwakə̂', english: 'broken', category: 'descriptive'),  // Session 56 audit: was "kpɔ̂ŋə" — dict says "kwakə̂"
  AwingWord(awing: 'tsɛ̀ŋə', english: 'dry', category: 'descriptive'),
  // CORRECTED fúfúə "bright/clean" → "white" per Awing English Dictionary EXACT match (Session 51 audit)
  AwingWord(awing: 'fúfúə', english: 'white', category: 'descriptive'),
  AwingWord(awing: 'dzə̀mə', english: 'deep', category: 'descriptive', difficulty: 1),
  // Session 52 gloss audit: was "wide" — dict says "think" (and also "clean furrows of farm bed")
  AwingWord(awing: 'kwàŋə', english: 'think', category: 'actions'),
  AwingWord(awing: 'ntsə̂ŋə', english: 'narrow', category: 'descriptive', difficulty: 1),
  AwingWord(awing: 'tə̂ŋə', english: 'straight', category: 'descriptive'),
  // Session 52 gloss audit: was "round/circular" — dict says "ringworm"
  AwingWord(awing: 'kwə̂glə', english: 'ringworm', category: 'body'),
  AwingWord(awing: 'ataŋə', english: 'full', category: 'descriptive'),  // Session 56 audit: was "yíŋə" — dict says "ataŋə"
  AwingWord(awing: 'tsɔ̂ŋə', english: 'heavy', category: 'descriptive'),
  AwingWord(awing: 'sɛ̂ŋə', english: 'raw/uncooked', category: 'descriptive', difficulty: 1),
  AwingWord(awing: 'shɔ̂ŋə', english: 'ripe/ready', category: 'descriptive'),
  // Session 52 gloss audit: was "early" — dict says "steep place, hilly place" (primary gloss)
  AwingWord(awing: 'kə̂ŋə', english: 'steep place, hilly place', category: 'nature'),
  // Session 52 gloss audit: was "late" — dict says "cane, walking stick" (tone variant of L 208 mbâŋə)
  AwingWord(awing: 'mbàŋə', english: 'cane, walking stick', category: 'things'),
  AwingWord(awing: 'ntsɔ́ŋɔ́', english: 'fast/quick', category: 'descriptive'),
  AwingWord(awing: 'nyàŋə', english: 'slow/careful', category: 'descriptive'),
  AwingWord(awing: 'wɔ̂ŋə', english: 'quiet/silent', category: 'descriptive'),
  AwingWord(awing: 'kpɔ̀ŋɔ́', english: 'loud/noisy', category: 'descriptive', difficulty: 1),
  // Session 52: was nûə "sweet (like honey)" — WRONG. Per dictionary, nûə = "honey"
  // (the noun, already correctly at L232 in food category). Replaced with ləmkə̂
  // ("be tasty/sweet"), the actual word for the "sweet" descriptor.
  AwingWord(awing: 'ləmkə̂', english: 'sweet/tasty', category: 'descriptive', tonePattern: 'falling'),
  AwingWord(awing: 'shɨ̂ŋə', english: 'sour/bitter', category: 'descriptive'),
  // === NEW: PDF-verified entries (Session 37) ===
  AwingWord(awing: 'dotê', english: 'dirty', category: 'descriptive', difficulty: 1),  // Session 56 audit: was "dɔ́tɔ̀" — dict says "dotê"
  AwingWord(awing: 'tyanɔ́', english: 'hard', category: 'descriptive', difficulty: 1),
  AwingWord(awing: 'yɨ̌la', english: 'difficult', category: 'descriptive', difficulty: 1),
  AwingWord(awing: 'achínə', english: 'important', category: 'descriptive', difficulty: 2),  // Session 56 audit: was "achîna" — dict says "achínə"
  AwingWord(awing: 'lóŋnə', english: 'lazy', category: 'descriptive', difficulty: 2),  // Session 56 audit: was "bɨ̀ŋna" — dict says "lóŋnə"
  AwingWord(awing: 'sagə', english: 'long', category: 'descriptive', difficulty: 1),  // Session 56 audit: was "sga" — dict says "sagə"
  AwingWord(awing: 'préta', english: 'crazy', category: 'descriptive', difficulty: 1),
  AwingWord(awing: 'yéelə', english: 'mad', category: 'descriptive', difficulty: 2),  // Session 56 audit: was "yéeta" — dict says "yéelə"
  AwingWord(awing: 'mbɔŋɔ́', english: 'many', category: 'descriptive', difficulty: 1),
  AwingWord(awing: 'tsaanɔ́', english: 'mature', category: 'descriptive', difficulty: 1),
  AwingWord(awing: 'fîə', english: 'new', category: 'descriptive', difficulty: 1),  // Session 56 audit: was "fía" — dict says "fîə"
  AwingWord(awing: 'póŋə', english: 'poor', category: 'descriptive', difficulty: 1),  // Session 56 audit: was "fóŋa" — dict says "póŋə"
  AwingWord(awing: 'léelə', english: 'ready', category: 'descriptive', difficulty: 1),  // Session 56 audit: was "léeta" — dict says "léelə"
  AwingWord(awing: 'ndaŋə', english: 'same', category: 'descriptive', difficulty: 2),  // Session 56 audit: was "ndɔŋɔ́" — dict says "ndaŋə"
  AwingWord(awing: 'ghoonə̂', english: 'sick', category: 'descriptive', difficulty: 1),  // Session 56 audit: was "ghooɔ́nɔ́" — dict says "ghoonə̂"
  AwingWord(awing: 'zaŋkə', english: 'light', category: 'descriptive', difficulty: 1),  // Session 56 audit: was "zaŋkɔ́" — dict says "zaŋkə"
  AwingWord(awing: 'achîna', english: 'strong', category: 'descriptive', difficulty: 1),
  AwingWord(awing: 'neebɔ', english: 'clean', category: 'descriptive', difficulty: 1),
  AwingWord(awing: 'azoŋkə', english: 'second', category: 'descriptive', difficulty: 2),  // Session 56 audit: was "azɔŋɔ́" — dict says "azoŋkə"
  AwingWord(awing: 'ntúa\'ɔ', english: 'nice', category: 'descriptive', difficulty: 1)];

// ============================================================
// PHRASES & GREETINGS — simple, practical phrases for daily use
// ============================================================

class AwingPhrase {
  final String awing;
  final String english;
  final String? context; // when to use it
  final String category; // greeting, daily, question, farewell, classroom
  final String? clipKey; // audio clip filename in sentences/ folder

  const AwingPhrase({
    required this.awing,
    required this.english,
    this.context,
    this.category = 'greeting',
    this.clipKey,
  });
}

/// Phrases and sentences verified from the Awing Orthography Guide (2005)
/// by Alomofor Christian and Stephen C. Anderson, and the Awing English
/// Dictionary (2007) by Alomofor Christian, CABTAL.
///
/// IMPORTANT: Only add phrases that are directly sourced from these PDFs
/// or confirmed by a native Awing speaker. Do NOT fabricate phrases.
const List<AwingPhrase> awingPhrases = [
  // === VERIFIED SENTENCES — from AwingOrthography2005.pdf ===

  // Page 9: Past tense example
  AwingPhrase(
    awing: "A kə ghɛnɔ́ məteenɔ́.",
    english: "He went to the market",
    context: "Past tense — talking about where someone went",
    category: 'daily',
    clipKey: 'daily_market',
  ),

  // Page 10: Elision / demonstrative example
  AwingPhrase(
    awing: "Lɛ̌ nəpɔ'ɔ́.",
    english: "This is a pumpkin",
    context: "Pointing at something and naming it",
    category: 'daily',
    clipKey: 'daily_this_pumpkin',
  ),

  // Page 11: Full stop / declarative sentence.
  // Dr. Sama corrected the natural spoken form: Awing drops "a tə"
  // (progressive aux) and the locative "a". PDF form was more formal.
  AwingPhrase(
    awing: "Móonə nonnɔ́ əkwunɔ́.",
    english: "The baby is lying on the bed",
    context: "Describing what someone is doing — present progressive",
    category: 'daily',
    clipKey: 'daily_baby_bed',
  ),

  // Page 11: Question mark / interrogative
  AwingPhrase(
    awing: "A ghɛlɔ́ lə aké?",
    english: "What is he doing?",
    context: "Asking about someone's activity — complement question",
    category: 'question',
    clipKey: 'question_what_doing',
  ),

  // Page 11: Exclamation / command
  AwingPhrase(
    awing: "Lǒ!",
    english: "Get out!",
    context: "Command — telling someone to leave",
    category: 'classroom',
    clipKey: 'classroom_get_out',
  ),

  // Page 11: Negative imperative
  AwingPhrase(
    awing: "Kə pinkɔ́ sóŋə!",
    english: "Don't mention it again!",
    context: "Telling someone not to repeat something",
    category: 'classroom',
    clipKey: 'classroom_dont_mention',
  ),

  // Page 11: Comma / two clauses
  AwingPhrase(
    awing: "Po ma ngyǐə lə əfê, po ghɛnɔ́ lə nkǐə.",
    english: "They are not coming here, they are going to the stream",
    context: "Describing movement — two clauses with comma",
    category: 'daily',
    clipKey: 'daily_going_stream',
  ),

  // Page 11-12: Comma / listing possessions
  AwingPhrase(
    awing: "Ŋwu yə a túgə pəŋgyɛ̌ pɛn pəpɛ̌, məŋgɔ́b mɛn mənteelɔ́ nə tá'ə ngwûə.",
    english: "That man has two wives, three chickens and one dog",
    context: "Listing things someone has — numbers and nouns",
    category: 'daily',
    clipKey: 'daily_man_possessions',
  ),

  // Page 12: Quotation marks / direct speech
  AwingPhrase(
    awing: "Ghǒ ghɛnɔ́ lə əfó?",
    english: "Where are you going?",
    context: "Asking someone where they are headed",
    category: 'question',
    clipKey: 'question_where_going',
  ),

  // Page 12: Full quotation with speaker
  AwingPhrase(
    awing: "Máma a tə mbítə ngə, \"Ghǒ ghɛnɔ́ lə əfó?\"",
    english: "Grandmother is asking, \"Where are you going?\"",
    context: "Direct speech — quoting what grandmother said",
    category: 'daily',
    clipKey: 'daily_grandma_asking',
  ),

  // Page 12: Capitalisation / first word
  AwingPhrase(
    awing: "Po zí nóolə.",
    english: "They have seen a snake",
    context: "Reporting what happened — perfect tense",
    category: 'daily',
    clipKey: 'daily_seen_snake',
  ),

  // Page 12: Capitalisation / proper nouns
  AwingPhrase(
    awing: "Mbá'chi, Apɛnə nə Mbyáb tə nkɔ́'ə atǐə.",
    english: "Mbachia, Apena and Mbyaabo are climbing a tree",
    context: "Proper nouns are capitalized — naming people",
    category: 'daily',
    clipKey: 'daily_climbing_tree',
  ),

  // Page 12: Capitalisation / after colon
  AwingPhrase(
    awing: "Lɔ́ anuə: Táta akɛ̌ ndé chíə pó.",
    english: "It is true: Tata (grandfather) is not in the house",
    context: "Colon usage — confirming a fact",
    category: 'daily',
    clipKey: 'daily_tata_house',
  ),

  // === VERIFIED WORDS USED AS EXCLAMATIONS — from Awing English Dictionary ===
  // Page vi of dictionary: tone examples confirm these words exist

  // yə = he (p.8 orthography), yǐə = come (p.8 orthography)
  // ko = take (p.8 orthography), kǒ = snore (p.8 orthography)
  // mǎ = mother (p.9 orthography noun class table)


  // Auto-extracted from Bible NT (non-biblical-feeling)
  // JHN.10.30
  AwingPhrase(awing: 'Pəg Tǎ lə́ táʼə.”', english: 'I and the Father are one.”'),
  // 1TH.5.16
  AwingPhrase(awing: 'Tə́ nə́ ńkɔŋtə̂ əghâ ətsəmə,', english: 'Rejoice always.'),
  // JHN.6.48
  AwingPhrase(awing: 'Maŋ lə́ apéenə məkálə́ nchîmbîə.', english: 'I am the bread of life.'),
  // 1CO.1.19
  AwingPhrase(awing: 'ə́sɛdkə̂ ajíənuə ngaŋə́ŋwaʼlə a pə́ ənukə́taŋə.”', english: 'For it is written,\n“I will destroy the wisdom of the wise,\nI will bring the discernment of the discerning to nothing.”'),
  // 1CO.16.14
  AwingPhrase(awing: 'Faʼ nə́ afaʼə atsəm nə́ akɔŋnə.', english: 'Let all that you do be done in love.'),
  // MAT.5.4
  AwingPhrase(awing: 'Mbɔŋə́ yə pɨ pö kyéŋ nə́,', english: 'Blessed are those who mourn,\nfor they shall be comforted.'),
  // MRK.15.13
  AwingPhrase(awing: 'Pó tɔ́ŋnə ə́sóŋ ńgə́, “Kwumtə̂ yə́!”', english: 'They cried out again, “Crucify him!”'),
  // 1CO.4.16
  AwingPhrase(awing: 'Ńdaŋ ə́lɨ́d, zoŋ nə́ ntag məkoolə mə.', english: 'I beg you therefore, be imitators of me.'),
  // ACT.14.7
  AwingPhrase(awing: 'ńtíʼə ńnáŋkə nkɨ yi əshîʼnə wə́ ə́wə́.', english: 'There they preached the Good News.'),
  // EPH.5.30
  AwingPhrase(awing: 'ńté ńgə́ pɛn lə́ əlam mbɨ píə.', english: 'because we are members of his body, of his flesh and bones.'),
  // JHN.6.4
  AwingPhrase(awing: 'Akɔŋtə ndzáʼkə Pəjusə a kə tə́ ḿbáatə.', english: 'Now the Passover, the feast of the Jews, was at hand.'),
  // JHN.12.15
  AwingPhrase(awing: 'Jɨ́ nə́, əfo əwəənə́ a tə́ ńgyǐəə,', english: '“Don’t be afraid, daughter of Zion. Behold, your King comes, sitting on a donkey’s colt.”'),
  // LUK.1.40
  AwingPhrase(awing: 'ńtíʼ ńkwúnə á ndɛ̂ Zakalya ńchaʼtə̂ Elisabɛlə.', english: 'and entered into the house of Zacharias and greeted Elizabeth.'),
  // LUK.23.24
  AwingPhrase(awing: 'Payilɛlə a kwéʼnə ḿbí ńdzoŋ ndzəm əzoobə́.', english: 'Pilate decreed that what they asked for should be done.'),
  // LUK.24.43
  AwingPhrase(awing: 'a kwá ńkɔ́d tsɔʼə á mbi pó.', english: 'He took them, and ate in front of them.'),
  // MAT.2.18
  AwingPhrase(awing: 'Pə́ tə́ ńdzóʼ ngye yitsə̌ á Lama,', english: '“A voice was heard in Ramah,\nlamentation, weeping and great mourning,\nRachel weeping for her children;\nshe wouldn’t be comforted,\nbecause they are no more.”'),
  // MAT.4.20
  AwingPhrase(awing: 'Pó tɔ́g ḿmɛdtə̂ məŋkɛd mɔ́b ńdzoŋə̂ yə́.', english: 'They immediately left their nets and followed him.'),
  // MAT.22.38
  AwingPhrase(awing: 'Lɛ̌ ntsɛɛmbi ntəgə́ ńkə́ ḿbə́ yi ngweŋə́.', english: 'This is the first and great commandment.'),
  // MRK.4.14
  AwingPhrase(awing: 'Mbipú wə̂ a pǐ lə́ atséebə Əsê.', english: 'The farmer sows the word.'),
  // MRK.6.42
  AwingPhrase(awing: 'Ŋwu ntsəmə a nə ńjî tə ńdzɛ́lə.', english: 'They all ate, and were filled.'),
  // 1JN.5.21
  AwingPhrase(awing: 'Póonə mə, lə́ʼ nə́ wɨ́ məsê mə́ məfɨgə.', english: 'Little children, keep yourselves from idols.'),
  // ACT.19.7
  AwingPhrase(awing: 'Pó pətsəm kə pə́ lə́ ándó ntsɔb pɛ̌.', english: 'They were about twelve men in all.'),
  // ACT.19.41
  AwingPhrase(awing: 'A sóŋ ə́lɨ́d lə́, ńtíʼ ə́shamkə̂ nkyeetə zə̂.', english: 'When he had thus spoken, he dismissed the assembly.'),
  // HEB.1.12
  AwingPhrase(awing: 'Pɨ yǒ píʼtə pə́ələ́ ándó tə́sɛ atsəʼə́ əfə́gə,', english: 'You will roll them up like a mantle,\nand they will be changed;\nbut you are the same.\nYour years will not fail.”'),
  // HEB.2.12
  AwingPhrase(awing: 'maŋ yǐ ŋáŋkə gho á mə́m nkyeetə əzoobə́.”', english: 'saying,\n“I will declare your name to my brothers.\nAmong of the congregation I will sing your praise.”'),
  // HEB.10.37
  AwingPhrase(awing: '“Lə́ tsɔʼə mɔ́ akəmtə ndɛlə́ á pɛ́d nə́,', english: '“In a very little while,\nhe who comes will come, and will not wait.'),
  // JHN.12.40
  AwingPhrase(awing: 'ńtíʼ ńgyǐəə á mbô maŋ, maŋ tsóʼə ághóobə́.”', english: '“He has blinded their eyes and he hardened their heart,\nlest they should see with their eyes,\nand perceive with their heart,\nand would turn,\nand I would heal them.”'),

  // ====================================================================
  // DICTIONARY-MINED PHRASES — multi-word entries from the 2007
  // Awing English Dictionary (Alomofor Christian, CABTAL). These are
  // dictionary-curated compound expressions, NOT extracted from Bible
  // narrative — kid-safe content only (religious/mature/death-euphemism
  // entries were filtered out during extraction). Added Session 60.
  // ====================================================================
  // dict:p.15
  AwingPhrase(
    awing: "afa'ə apímnə",
    english: "partnership work",
    category: "daily",
    clipKey: "daily_afae_apimne",
  ),
  // dict:p.17
  AwingPhrase(
    awing: "afúə ndí'ə",
    english: "antidote, anti-poison",
    category: "daily",
    clipKey: "daily_afue_ndie",
  ),
  // dict:p.21
  AwingPhrase(
    awing: "ajwigó ngwe'ó",
    english: "day after tomorrow",
    category: "daily",
    clipKey: "daily_ajwigo_ngweo",
  ),
  // dict:p.20
  AwingPhrase(
    awing: "ajúmə nəkwa'ə",
    english: "play instrument, toy",
    category: "daily",
    clipKey: "daily_ajume_nekwae",
  ),
  // dict:p.24
  AwingPhrase(
    awing: "ako'nə ndəŋə",
    english: "bamboo chair",
    category: "daily",
    clipKey: "daily_akone_ndenge",
  ),
  // dict:p.27
  AwingPhrase(
    awing: "akwu'ló atìə",
    english: "base of tree trunk; stump",
    category: "daily",
    clipKey: "daily_akwulo_atie",
  ),
  // dict:p.24
  AwingPhrase(
    awing: "akó'ə ndəŋə",
    english: "bamboo chair",
    category: "daily",
    clipKey: "daily_akoe_ndenge",
  ),
  // dict:p.24
  AwingPhrase(
    awing: "akǒ'nə ləəmó",
    english: "colt (young horse)",
    category: "daily",
    clipKey: "daily_akone_leemo",
  ),
  // dict:p.24
  AwingPhrase(
    awing: "akǒ'nə mbyâŋnə",
    english: "young man",
    category: "daily",
    clipKey: "daily_akone_mbyangne",
  ),
  // dict:p.24
  AwingPhrase(
    awing: "akǒ'nə məŋgyě",
    english: "young woman",
    category: "daily",
    clipKey: "daily_akone_menggye",
  ),
  // dict:p.24
  AwingPhrase(
    awing: "akǒ'nə nkeelə",
    english: "medium sized drum",
    category: "daily",
    clipKey: "daily_akone_nkeele",
  ),
  // dict:p.28
  AwingPhrase(
    awing: "alaŋó maŋgo'ə",
    english: "bumpy road",
    category: "daily",
    clipKey: "daily_alango_manggoe",
  ),
  // dict:p.28
  AwingPhrase(
    awing: "alaŋó nətsa'ó",
    english: "muddy road",
    category: "daily",
    clipKey: "daily_alango_netsao",
  ),
  // dict:p.30
  AwingPhrase(
    awing: "ali' ghenó",
    english: "here",
    category: "daily",
    clipKey: "daily_ali_gheno",
  ),
  // dict:p.30
  AwingPhrase(
    awing: "ali' yîə",
    english: "there (that place)",
    category: "daily",
    clipKey: "daily_ali_yie",
  ),
  // dict:p.31
  AwingPhrase(
    awing: "ali'ó kətaŋə",
    english: "emptiness, nothing, void",
    category: "daily",
    clipKey: "daily_alio_ketange",
  ),
  // dict:p.28
  AwingPhrase(
    awing: "alá'ə akoobá",
    english: "bush country, rural area",
    category: "daily",
    clipKey: "daily_alae_akooba",
  ),
  // dict:p.28
  AwingPhrase(
    awing: "alá'ə pakwûə",
    english: "world of the dead",
    category: "daily",
    clipKey: "daily_alae_pakwue",
  ),
  // dict:p.35
  AwingPhrase(
    awing: "apagó atsə'ó",
    english: "a piece of cloth",
    category: "daily",
    clipKey: "daily_apago_atseo",
  ),
  // dict:p.36
  AwingPhrase(
    awing: "apu'ə məjiə",
    english: "food leftovers. In Awing, food leftovers of an elder is eaten by a child",
    category: "family",
    clipKey: "family_apue_mejie",
  ),
  // dict:p.43
  AwingPhrase(
    awing: "atsa'á mako'ná",
    english: "shirt. Shirts are usually worn by men",
    category: "daily",
    clipKey: "daily_atsaa_makona",
  ),
  // dict:p.42
  AwingPhrase(
    awing: "atsa'ə ndəsê",
    english: "mud block. We use mud blocks to build houses in Awing",
    category: "daily",
    clipKey: "daily_atsae_ndese",
  ),
  // dict:p.44
  AwingPhrase(
    awing: "atso'ə ngəsáŋə",
    english: "corn cob. One can plant a cob of corn and it produces a bag full",
    category: "daily",
    clipKey: "daily_atsoe_ngesange",
  ),
  // dict:p.52
  AwingPhrase(
    awing: "chi'ə́ asaŋɔ́",
    english: "wag tail",
    category: "daily",
    clipKey: "daily_chie_asango",
  ),
  // dict:p.53
  AwingPhrase(
    awing: "chigə tákɔ'ə",
    english: "biggest",
    category: "daily",
    clipKey: "daily_chige_takoe",
  ),
  // dict:p.55
  AwingPhrase(
    awing: "chwaalâ afa'ə",
    english: "look for a job",
    category: "daily",
    clipKey: "daily_chwaala_afae",
  ),
  // dict:p.55
  AwingPhrase(
    awing: "chwaalâ ape'ə",
    english: "accumulate wealth",
    category: "daily",
    clipKey: "daily_chwaala_apee",
  ),
  // dict:p.53
  AwingPhrase(
    awing: "chú' mógə",
    english: "light (fire)",
    category: "daily",
    clipKey: "daily_chu_moge",
  ),
  // dict:p.53
  AwingPhrase(
    awing: "chú' əshunə́",
    english: "start a relationship",
    category: "daily",
    clipKey: "daily_chu_eshune",
  ),
  // dict:p.50
  AwingPhrase(
    awing: "chǐ myā'â",
    english: "knock down, tip over",
    category: "daily",
    clipKey: "daily_chi_myaa",
  ),
  // dict:p.67
  AwingPhrase(
    awing: "felə ali'ó",
    english: "move away, migrate",
    category: "daily",
    clipKey: "daily_fele_alio",
  ),
  // dict:p.67
  AwingPhrase(
    awing: "felə ndzɔ'á",
    english: "divorce. When a woman divorces she loses her charm",
    category: "question",
    clipKey: "question_fele_ndzoa",
  ),
  // dict:p.70
  AwingPhrase(
    awing: "fu' mbélə",
    english: "dung beetle. Dung beetles are usually found in cow dung",
    category: "daily",
    clipKey: "daily_fu_mbele",
  ),
  // dict:p.71
  AwingPhrase(
    awing: "fya'ə̂ anuə",
    english: "pour libation. People pour libation on the fourth day of the Awing week",
    category: "daily",
    clipKey: "daily_fyae_anue",
  ),
  // dict:p.
  AwingPhrase(
    awing: "kwud nká'ə",
    english: "build a fence",
    category: "daily",
    clipKey: "daily_kwud_nkae",
  ),
  // dict:p.
  AwingPhrase(
    awing: "kwíŋ nkîə",
    english: "turtle (water turtle)",
    category: "daily",
    clipKey: "daily_kwing_nkie",
  ),
  // dict:p.
  AwingPhrase(
    awing: "ká' nəsoŋá",
    english: "laugh in a wild manner",
    category: "daily",
    clipKey: "daily_ka_nesonga",
  ),
  // dict:p.
  AwingPhrase(
    awing: "káyé məŋgo'ə",
    english: "gravel",
    category: "daily",
    clipKey: "daily_kaye_menggoe",
  ),
  // dict:p.
  AwingPhrase(
    awing: "kəŋ məŋkwâ'lə",
    english: "desert (nothing grows in a desert)",
    category: "daily",
    clipKey: "daily_keng_mengkwale",
  ),
  // dict:p.
  AwingPhrase(
    awing: "ma' məlóŋə",
    english: "be sad, look pitiful",
    category: "daily",
    clipKey: "daily_ma_melonge",
  ),
  // dict:p.
  AwingPhrase(
    awing: "ma' nkó'ə",
    english: "decorate, make something flowerish or beautiful",
    category: "daily",
    clipKey: "daily_ma_nkoe",
  ),
  // dict:p.
  AwingPhrase(
    awing: "ma'ô atsə'ə",
    english: "wear clothes, dress up",
    category: "daily",
    clipKey: "daily_mao_atsee",
  ),
  // dict:p.
  AwingPhrase(
    awing: "ma'ô kəghoghə",
    english: "give much importance to something, especially more than it is due",
    category: "daily",
    clipKey: "daily_mao_keghoghe",
  ),
  // dict:p.
  AwingPhrase(
    awing: "maŋ cha'tô",
    english: "greetings",
    category: "greeting",
    clipKey: "greeting_mang_chato",
  ),
  // dict:p.
  AwingPhrase(
    awing: "mbaŋ mbenə",
    english: "testicle",
    category: "daily",
    clipKey: "daily_mbang_mbene",
  ),
  // dict:p.
  AwingPhrase(
    awing: "mbi təŋkə̂'ə",
    english: "elephant's trunk",
    category: "daily",
    clipKey: "daily_mbi_tengkee",
  ),
  // dict:p.
  AwingPhrase(
    awing: "mbá' əpúmə",
    english: "weaver, somebody who weaves",
    category: "question",
    clipKey: "question_mba_epume",
  ),
  // dict:p.
  AwingPhrase(
    awing: "megtə acha'tə",
    english: "wave a greeting",
    category: "greeting",
    clipKey: "greeting_megte_achate",
  ),
  // dict:p.
  AwingPhrase(
    awing: "məchína nəka'á",
    english: "being together",
    category: "daily",
    clipKey: "daily_mechina_nekaa",
  ),
  // dict:p.
  AwingPhrase(
    awing: "məchína təzá'ə",
    english: "celibacy",
    category: "daily",
    clipKey: "daily_mechina_tezae",
  ),
  // dict:p.
  AwingPhrase(
    awing: "ncha'tə əsê",
    english: "spiritual healer, somebody who heals through prayers",
    category: "question",
    clipKey: "question_nchate_ese",
  ),
  // dict:p.
  AwingPhrase(
    awing: "ndzâblə məsá'ə",
    english: "porcupine",
    category: "daily",
    clipKey: "daily_ndzable_mesae",
  ),
  // dict:p.
  AwingPhrase(
    awing: "ndzɔ́'ə alá'ə",
    english: "in public",
    category: "daily",
    clipKey: "daily_ndzoe_alae",
  ),
  // dict:p.
  AwingPhrase(
    awing: "ndí' məjíə",
    english: "farmer",
    category: "daily",
    clipKey: "daily_ndi_mejie",
  ),
  // dict:p.
  AwingPhrase(
    awing: "ndě melo'ə",
    english: "bar, drinking spot",
    category: "daily",
    clipKey: "daily_nde_meloe",
  ),
  // dict:p.
  AwingPhrase(
    awing: "ngá mə'ə́",
    english: "once, one time",
    category: "daily",
    clipKey: "daily_nga_mee",
  ),
  // dict:p.
  AwingPhrase(
    awing: "nji' nəságə",
    english: "clitoris",
    category: "daily",
    clipKey: "daily_nji_nesage",
  ),
  // dict:p.
  AwingPhrase(
    awing: "nji' nətôglə",
    english: "earwax",
    category: "daily",
    clipKey: "daily_nji_netogle",
  ),
  // dict:p.
  AwingPhrase(
    awing: "nkaŋ nkíə",
    english: "1) river bank. 2) sea shore. 3) beach",
    category: "daily",
    clipKey: "daily_nkang_nkie",
  ),
  // dict:p.
  AwingPhrase(
    awing: "nked teelə̂",
    english: "three hundred (300)",
    category: "daily",
    clipKey: "daily_nked_teele",
  ),
  // dict:p.
  AwingPhrase(
    awing: "nkya' nəfaŋə́",
    english: "lightning",
    category: "daily",
    clipKey: "daily_nkya_nefange",
  ),
  // dict:p.
  AwingPhrase(
    awing: "nkya' sáŋə́",
    english: "moonlight",
    category: "daily",
    clipKey: "daily_nkya_sange",
  ),
  // dict:p.
  AwingPhrase(
    awing: "nká' məneemə",
    english: "cattle pen",
    category: "daily",
    clipKey: "daily_nka_meneeme",
  ),
  // dict:p.
  AwingPhrase(
    awing: "nká' nəpumə́",
    english: "eggshell",
    category: "daily",
    clipKey: "daily_nka_nepume",
  ),
  // dict:p.
  AwingPhrase(
    awing: "nkəŋ ndəpa'ə",
    english: "pipe stem",
    category: "daily",
    clipKey: "daily_nkeng_ndepae",
  ),
  // dict:p.
  AwingPhrase(
    awing: "nkəŋk ô'lə",
    english: "sugar cane",
    category: "daily",
    clipKey: "daily_nkengk_ole",
  ),
  // dict:p.
  AwingPhrase(
    awing: "nkəŋə aŋwa'lə",
    english: "pen",
    category: "daily",
    clipKey: "daily_nkenge_angwale",
  ),
  // dict:p.
  AwingPhrase(
    awing: "ntaŋ ngɔ'ə́",
    english: "hut built for collecting termite",
    category: "daily",
    clipKey: "daily_ntang_ngoe",
  ),
  // dict:p.
  AwingPhrase(
    awing: "ntsɔ́'ə afa'ə",
    english: "reward, remuneration",
    category: "daily",
    clipKey: "daily_ntsoe_afae",
  ),
  // dict:p.
  AwingPhrase(
    awing: "ntsəb mə'á",
    english: "eleven (11)",
    category: "daily",
    clipKey: "daily_ntseb_mea",
  ),
  // dict:p.
  AwingPhrase(
    awing: "ntsəb teelə̂",
    english: "thirteen (13)",
    category: "daily",
    clipKey: "daily_ntseb_teele",
  ),
  // dict:p.
  AwingPhrase(
    awing: "ntəənə acha'tésê",
    english: "fasting",
    category: "daily",
    clipKey: "daily_nteene_achatese",
  ),
  // dict:p.
  AwingPhrase(
    awing: "nətú' ənumnə",
    english: "eclipse (sun)",
    category: "daily",
    clipKey: "daily_netu_enumne",
  ),
  // dict:p.
  AwingPhrase(
    awing: "pe'ə atûə",
    english: "carry on head",
    category: "daily",
    clipKey: "daily_pee_atue",
  ),
  // dict:p.
  AwingPhrase(
    awing: "pá əshí'á",
    english: "how many?",
    category: "question",
    clipKey: "question_pa_eshia",
  ),
  // dict:p.
  AwingPhrase(
    awing: "pánkó akɔ'ə",
    english: "stool, a sort of seat",
    category: "daily",
    clipKey: "daily_panko_akoe",
  ),
  // dict:p.
  AwingPhrase(
    awing: "pó' mbeebə",
    english: "flap wings",
    category: "daily",
    clipKey: "daily_po_mbeebe",
  ),
  // dict:p.
  AwingPhrase(
    awing: "pó' mbô",
    english: "clap (hands), beg",
    category: "daily",
    clipKey: "daily_po_mbo",
  ),
  // dict:p.
  AwingPhrase(
    awing: "sog ətsə'á",
    english: "launder",
    category: "daily",
    clipKey: "daily_sog_etsea",
  ),
  // dict:p.
  AwingPhrase(
    awing: "sə'â ali'á",
    english: "clear (land or a grown place for planting)",
    category: "daily",
    clipKey: "daily_sea_alia",
  ),
  // dict:p.
  AwingPhrase(
    awing: "tasa' móga",
    english: "spark of fire",
    category: "daily",
    clipKey: "daily_tasa_moga",
  ),
  // dict:p.
  AwingPhrase(
    awing: "tsó' mbîəə",
    english: "transplant",
    category: "daily",
    clipKey: "daily_tso_mbiee",
  ),
  // dict:p.
  AwingPhrase(
    awing: "tsó' mbô",
    english: "drop (tr), let go",
    category: "daily",
    clipKey: "daily_tso_mbo",
  ),
  // dict:p.
  AwingPhrase(
    awing: "tsó' ətsə'á",
    english: "undress",
    category: "daily",
    clipKey: "daily_tso_etsea",
  ),
  // dict:p.
  AwingPhrase(
    awing: "tá' ngǎ",
    english: "once, one time",
    category: "daily",
    clipKey: "daily_ta_nga",
  ),
  // dict:p.
  AwingPhrase(
    awing: "tá' əpúmə",
    english: "bead. Pl.: pətá' əpúmə",
    category: "daily",
    clipKey: "daily_ta_epume",
  ),
  // dict:p.
  AwingPhrase(
    awing: "táko' sáŋə́",
    english: "turkey. Pl.: pətáko' pə́ pəsáŋə́",
    category: "daily",
    clipKey: "daily_tako_sange",
  ),
  // dict:p.
  AwingPhrase(
    awing: "táko' ŋwunə",
    english: "adult. Pl.: pətáko' pə́ pəənə",
    category: "daily",
    clipKey: "daily_tako_ngwune",
  ),
  // dict:p.
  AwingPhrase(
    awing: "tä afa'ə",
    english: "master",
    category: "daily",
    clipKey: "daily_t_afae",
  ),
  // dict:p.
  AwingPhrase(
    awing: "tó' nkîə",
    english: "draw water",
    category: "daily",
    clipKey: "daily_to_nkie",
  ),
  // dict:p.
  AwingPhrase(
    awing: "tó'kə nkadtə",
    english: "be proud",
    category: "daily",
    clipKey: "daily_toke_nkadte",
  ),
  // dict:p.
  AwingPhrase(
    awing: "tó'kə nkonə",
    english: "be proud",
    category: "daily",
    clipKey: "daily_toke_nkone",
  ),
  // dict:p.
  AwingPhrase(
    awing: "tú nkîə",
    english: "cross river",
    category: "daily",
    clipKey: "daily_tu_nkie",
  ),
  // dict:p.
  AwingPhrase(
    awing: "wu'nə nkwumə",
    english: "1) close a box. 2) close a coffin",
    category: "daily",
    clipKey: "daily_wune_nkwume",
  ),
  // dict:p.
  AwingPhrase(
    awing: "wê atsə'á",
    english: "wear clothes",
    category: "daily",
    clipKey: "daily_we_atsea",
  ),
  // dict:p.
  AwingPhrase(
    awing: "yéeka əli'á",
    english: "disturb or annoy. V.s: ńgyéeka əli'",
    category: "daily",
    clipKey: "daily_yeeka_elia",
  ),
  // dict:p.
  AwingPhrase(
    awing: "zó' nkîə",
    english: "swim",
    category: "daily",
    clipKey: "daily_zo_nkie",
  ),
  // dict:p.
  AwingPhrase(
    awing: "ŋwu mbyâŋnə",
    english: "1) man 2) male (sex)",
    category: "daily",
    clipKey: "daily_ngwu_mbyangne",
  ),
  // dict:p.
  AwingPhrase(
    awing: "ŋá' nkwumə",
    english: "open (box)",
    category: "daily",
    clipKey: "daily_nga_nkwume",
  ),
  // dict:p.59
  AwingPhrase(
    awing: "Əfo Nká'fo",
    english: "the seventh fon of Awing",
    category: "daily",
    clipKey: "daily_efo_nkafo",
  ),
  // dict:p.59
  AwingPhrase(
    awing: "Əfo Nká'ŋngwé",
    english: "the fifth fon of Awing",
    category: "daily",
    clipKey: "daily_efo_nkangngwe",
  ),
  // dict:p.58
  AwingPhrase(
    awing: "əfeŋ məlá'ə",
    english: "roofer of thatched houses",
    category: "daily",
    clipKey: "daily_efeng_melae",
  ),
  // dict:p.59
  AwingPhrase(
    awing: "əfó' nkîə",
    english: "dry river bed",
    category: "daily",
    clipKey: "daily_efo_nkie",
  ),
  // dict:p.60
  AwingPhrase(
    awing: "əghâ nda'ə",
    english: "another time",
    category: "daily",
    clipKey: "daily_egha_ndae",
  ),
  // dict:p.60
  AwingPhrase(
    awing: "əghâ wá'ó",
    english: "time of famine",
    category: "daily",
    clipKey: "daily_egha_wao",
  ),
  // dict:p.62
  AwingPhrase(
    awing: "əlimə́ afa'ə",
    english: "working relationship",
    category: "daily",
    clipKey: "daily_elime_afae",
  ),
  // dict:p.62
  AwingPhrase(
    awing: "əma' pó'ə",
    english: "story teller",
    category: "daily",
    clipKey: "daily_ema_poe",
  ),
  // dict:p.63
  AwingPhrase(
    awing: "ənumnə natú'ə",
    english: "eclipse of the moon",
    category: "daily",
    clipKey: "daily_enumne_natue",
  ),
  // dict:p.63
  AwingPhrase(
    awing: "əŋwa'lə nkeebə",
    english: "1) treasurer 2) accountant",
    category: "daily",
    clipKey: "daily_engwale_nkeebe",
  ),
  // dict:p.63
  AwingPhrase(
    awing: "əŋwa'lə əŋwa'lə",
    english: "secretary, typist",
    category: "daily",
    clipKey: "daily_engwale_engwale",
  ),
  // dict:p.25
  AwingPhrase(
    awing: "akwaŋ yə əshi'nə",
    english: "confidence, good thoughts",
    category: "daily",
    clipKey: "daily_akwang_ye_eshine",
  ),
  // dict:p.24
  AwingPhrase(
    awing: "akó' yə fíə",
    english: "youngster",
    category: "daily",
    clipKey: "daily_ako_ye_fie",
  ),
  // dict:p.30
  AwingPhrase(
    awing: "ali' yə áwó",
    english: "there (place that is the subject of conversation)",
    category: "daily",
    clipKey: "daily_ali_ye_awo",
  ),
  // dict:p.30
  AwingPhrase(
    awing: "ali'ó ghók'ə Əsê",
    english: "sanctuary; place of worship",
    category: "daily",
    clipKey: "daily_alio_ghoke_ese",
  ),
  // dict:p.31
  AwingPhrase(
    awing: "ali'ó nəfoonə Əsê",
    english: "paradise",
    category: "daily",
    clipKey: "daily_alio_nefoone_ese",
  ),
  // dict:p.42
  AwingPhrase(
    awing: "atsa'ə mbó nakaŋá",
    english: "potter's clay. The potters clay is usually found near the stream",
    category: "daily",
    clipKey: "daily_atsae_mbo_nakanga",
  ),
  // dict:p.50
  AwingPhrase(
    awing: "chî nó ŋgə́'ə",
    english: "be in difficulty, live in hardship",
    category: "daily",
    clipKey: "daily_chi_no_nggee",
  ),
  // dict:p.51
  AwingPhrase(
    awing: "chî tə zə́'ə",
    english: "be unmarried, stay unmarried",
    category: "daily",
    clipKey: "daily_chi_te_zee",
  ),
  // dict:p.50
  AwingPhrase(
    awing: "chî ŋgǎ mə́'á",
    english: "be forever, be everlasting",
    category: "daily",
    clipKey: "daily_chi_ngga_mea",
  ),
  // dict:p.52
  AwingPhrase(
    awing: "chîə ándó ngɔ'ə",
    english: "be numb, unemotional and inhuman (idiom)",
    category: "daily",
    clipKey: "daily_chie_ando_ngoe",
  ),
  // dict:p.
  AwingPhrase(
    awing: "mámé yi ndzá'ka",
    english: "grandmother (maternal)",
    category: "family",
    clipKey: "family_mame_yi_ndzaka",
  ),
  // dict:p.
  AwingPhrase(
    awing: "mé ngo' naghǒ",
    english: "lower grinding stone",
    category: "daily",
    clipKey: "daily_me_ngo_nagho",
  ),
  // dict:p.
  AwingPhrase(
    awing: "mó na mbeláló'ə",
    english: "calf",
    category: "daily",
    clipKey: "daily_mo_na_mbelaloe",
  ),
  // dict:p.
  AwingPhrase(
    awing: "mó ngo' naghǒ",
    english: "upper grinding stone",
    category: "daily",
    clipKey: "daily_mo_ngo_nagho",
  ),
  // dict:p.
  AwingPhrase(
    awing: "məlo' má məkálə̂",
    english: "beer, wine, whiskies",
    category: "daily",
    clipKey: "daily_melo_ma_mekale",
  ),
  // dict:p.
  AwingPhrase(
    awing: "ndzɔ́'ə tá' məngyè",
    english: "polygamy",
    category: "daily",
    clipKey: "daily_ndzoe_ta_mengye",
  ),
  // dict:p.
  AwingPhrase(
    awing: "ndəsê yi əshí'nə",
    english: "fertile soil",
    category: "daily",
    clipKey: "daily_ndese_yi_eshine",
  ),
  // dict:p.
  AwingPhrase(
    awing: "nkǐ yi əshî'nə",
    english: "gospel, good news",
    category: "daily",
    clipKey: "daily_nki_yi_eshine",
  ),
  // dict:p.
  AwingPhrase(
    awing: "nəgha' nó mógə",
    english: "1) embers. 2) charcoal",
    category: "daily",
    clipKey: "daily_negha_no_moge",
  ),
  // dict:p.
  AwingPhrase(
    awing: "nəkəŋ nó atsa'ə́",
    english: "cooking pot (earthenware)",
    category: "daily",
    clipKey: "daily_nekeng_no_atsae",
  ),
// dict:p.
  AwingPhrase(
    awing: "nəkəŋ nó nkíə",
    english: "pot (for water)",
    category: "daily",
    clipKey: "daily_nekeng_no_nkie",
  ),
  // dict:p.
  AwingPhrase(
    awing: "nəla' nó akoolə",
    english: "ankle",
    category: "daily",
    clipKey: "daily_nela_no_akoole",
  ),
  // dict:p.
  AwingPhrase(
    awing: "nəló' nə́ nəlwíə",
    english: "1) lip plug. 2) lip disk",
    category: "daily",
    clipKey: "daily_nelo_ne_nelwie",
  ),
  // dict:p.
  AwingPhrase(
    awing: "nəpo' nó kéenə",
    english: "melon",
    category: "daily",
    clipKey: "daily_nepo_no_keene",
  ),
  // dict:p.
  AwingPhrase(
    awing: "nəpo' nó məkálə",
    english: "pawpaw",
    category: "daily",
    clipKey: "daily_nepo_no_mekale",
  ),
  // dict:p.
  AwingPhrase(
    awing: "nəpó' nó əpúmə",
    english: "threshing-floor",
    category: "daily",
    clipKey: "daily_nepo_no_epume",
  ),
  // dict:p.
  AwingPhrase(
    awing: "nəsoŋ nó tə̂ŋka'ə",
    english: "elephant's tusk",
    category: "daily",
    clipKey: "daily_nesong_no_tengkae",
  ),
  // dict:p.
  AwingPhrase(
    awing: "pó' nó nduə",
    english: "hit with a hammer",
    category: "daily",
    clipKey: "daily_po_no_ndue",
  ),
  // dict:p.
  AwingPhrase(
    awing: "tădmé yi ndza'kə",
    english: "great grandfather (maternal). Pl.: pətădmé pipá ndza'kə",
    category: "family",
    clipKey: "family_tdme_yi_ndzake",
  ),
  // dict:p.
  AwingPhrase(
    awing: "zó' nə məghôlə",
    english: "annoint, rub with oil",
    category: "daily",
    clipKey: "daily_zo_ne_meghole",
  ),
  // dict:p.59
  AwingPhrase(
    awing: "Əfo Ngôngá' I",
    english: "third fon of Awing",
    category: "daily",
    clipKey: "daily_efo_ngonga_i",
  ),
  // dict:p.59
  AwingPhrase(
    awing: "Əfo Ngôngá' II",
    english: "the sixth fon of Awing",
    category: "daily",
    clipKey: "daily_efo_ngonga_ii",
  ),
  // dict:p.59
  AwingPhrase(
    awing: "Əfo Ngôngá' III",
    english: "the twelfth fon of Awing (1950 to 1998)",
    category: "daily",
    clipKey: "daily_efo_ngonga_iii",
  ),
  // dict:p.62
  AwingPhrase(
    awing: "əlén yi əshí'nə",
    english: "good reputation",
    category: "daily",
    clipKey: "daily_elen_yi_eshine",
  ),
  // dict:p.20
  AwingPhrase(
    awing: "ajú yə pá' nə",
    english: "wickerwork",
    category: "daily",
    clipKey: "daily_aju_ye_pa_ne",
  ),
  // dict:p.30
  AwingPhrase(
    awing: "ali' yə noŋnə nə",
    english: "open place, clearing",
    category: "daily",
    clipKey: "daily_ali_ye_nongne_ne",
  ),
  // dict:p.41
  AwingPhrase(
    awing: "atú yə pó' ná",
    english: "headache. Headache is frequent in the dry season",
    category: "daily",
    clipKey: "daily_atu_ye_po_na",
  ),
  // dict:p.41
  AwingPhrase(
    awing: "atú yə tsə́'nə ná",
    english: "intelligence, high learning ability",
    category: "classroom",
    clipKey: "classroom_atu_ye_tsene_na",
  ),
  // dict:p.41
  AwingPhrase(
    awing: "atú yə ŋa'nə ná",
    english: "intelligence, high learning ability",
    category: "classroom",
    clipKey: "classroom_atu_ye_ngane_na",
  ),
  // dict:p.
  AwingPhrase(
    awing: "jwí'kə á ndî' mógə",
    english: "smoke, dry in smoke, dry over fire",
    category: "daily",
    clipKey: "daily_jwike_a_ndi_moge",
  ),
  // dict:p.
  AwingPhrase(
    awing: "manoŋ má əli' mbáata",
    english: "pubic hair",
    category: "daily",
    clipKey: "daily_manong_ma_eli_mbaata",
  ),
  // dict:p.
  AwingPhrase(
    awing: "mǎ pətǎ yi ndzá'kə",
    english: "grandmother of someone",
    category: "family",
    clipKey: "family_ma_peta_yi_ndzake",
  ),
  // dict:p.
  AwingPhrase(
    awing: "məlo' má tyantə̂ nə̂",
    english: "alcohol (general)",
    category: "daily",
    clipKey: "daily_melo_ma_tyante_ne",
  ),
  // dict:p.
  AwingPhrase(
    awing: "nkǐ yi sá' nó",
    english: "spring",
    category: "daily",
    clipKey: "daily_nki_yi_sa_no",
  ),
  // dict:p.
  AwingPhrase(
    awing: "nəló' nó aghələ məjíə",
    english: "ladle",
    category: "daily",
    clipKey: "daily_nelo_no_aghele_mejie",
  ),
  // dict:p.
  AwingPhrase(
    awing: "nələŋ nó kɔ́'ə aŋkándə",
    english: "strap for climbing",
    category: "daily",
    clipKey: "daily_neleng_no_koe_angkande",
  ),
  // dict:p.
  AwingPhrase(
    awing: "tä pətä yi ndza'kə",
    english: "great great grandfather (paternal). Pl.: pətä pətä pipá pətä ndza'kə",
    category: "family",
    clipKey: "family_t_pet_yi_ndzake",
  ),
  // dict:p.62
  AwingPhrase(
    awing: "əli' pipá jum nó",
    english: "drought, famine",
    category: "daily",
    clipKey: "daily_eli_pipa_jum_no",
  ),
  // dict:p.62
  AwingPhrase(
    awing: "əli' pipá lum nó",
    english: "hot weather",
    category: "daily",
    clipKey: "daily_eli_pipa_lum_no",
  ),
  // dict:p.62
  AwingPhrase(
    awing: "əli' pipá nwa' nó",
    english: "daylight",
    category: "daily",
    clipKey: "daily_eli_pipa_nwa_no",
  ),
  // dict:p.
  AwingPhrase(
    awing: "məghám mém mbê nə tá'ə",
    english: "twenty-one (21)",
    category: "daily",
    clipKey: "daily_megham_mem_mbe_ne_tae",
  ),
  // dict:p.
  AwingPhrase(
    awing: "məghám mém mbê nə pém pê",
    english: "twenty-two (22)",
    category: "daily",
    clipKey: "daily_megham_mem_mbe_ne_pem_pe",
  ),
  // dict:p.
  AwingPhrase(
    awing: "məghám mém mbê nə pén teelə̂",
    english: "twenty-three (23)",
    category: "daily",
    clipKey: "daily_megham_mem_mbe_ne_pen_teele",
  ),
  // dict:p.
  AwingPhrase(
    awing: "məghám mém mbê nə pén tênə",
    english: "twenty-five (25)",
    category: "daily",
    clipKey: "daily_megham_mem_mbe_ne_pen_tene",
  )];

// ============================================================
// TONE MINIMAL PAIRS — words that differ only by tone
// ============================================================

class ToneMinimalPair {
  final String word1;
  final String english1;
  final String tone1;
  final String word2;
  final String english2;
  final String tone2;
  final String? word3;
  final String? english3;
  final String? tone3;

  const ToneMinimalPair({
    required this.word1,
    required this.english1,
    required this.tone1,
    required this.word2,
    required this.english2,
    required this.tone2,
    this.word3,
    this.english3,
    this.tone3,
  });
}

const List<ToneMinimalPair> toneMinimalPairs = [
  // From AwingOrthography2005.pdf page 8
  ToneMinimalPair(
    word1: 'kóŋɔ́', english1: 'ditch', tone1: 'high',
    word2: 'kɔ́ŋə', english2: 'flow', tone2: 'mid',
    word3: 'kɔ̀ŋə', english3: 'owl', tone3: 'low',
  ),
  ToneMinimalPair(
    word1: 'kô', english1: 'take', tone1: 'falling',
    word2: 'kó', english2: 'snore', tone2: 'high',
  ),
  ToneMinimalPair(
    word1: 'àfɔ́gə̂', english1: 'blind person', tone1: 'high',
    word2: 'àfɔ́gə', english2: 'malaria', tone2: 'mid',
  ),
  ToneMinimalPair(
    word1: 'àlɔ́mə̂', english1: 'pool', tone1: 'high-final',
    word2: 'àlɔ́mə', english2: 'cloud', tone2: 'mid-final',
  ),
  ToneMinimalPair(
    word1: 'àkōolə̂', english1: 'latrine', tone1: 'high-final',
    word2: 'akōolə', english2: 'leg', tone2: 'mid-final',
  ),
  // From phonology PDF page 23
  ToneMinimalPair(
    word1: 'pìə', english1: 'give birth', tone1: 'low',
    word2: 'pìə̂', english2: 'sow (plant)', tone2: 'falling',
  ),
  // New minimal pairs from phonology PDF
  ToneMinimalPair(
    word1: 'ndě', english1: 'neck', tone1: 'mid',
    word2: 'ndè', english2: 'water', tone2: 'low',
  ),
  ToneMinimalPair(
    word1: 'lê', english1: 'sleep', tone1: 'falling',
    word2: 'lé', english2: 'eat (alternate)', tone2: 'high',
  ),
  ToneMinimalPair(
    word1: 'nô', english1: 'drink', tone1: 'falling',
    word2: 'nó', english2: 'give', tone2: 'high',
  ),
  ToneMinimalPair(
    word1: 'fê', english1: 'give', tone1: 'falling',
    word2: 'fé', english2: 'blow', tone2: 'high',
  ),
  // REMOVED tone minimal pair kíə/kìə (pay/key) — per dictionary, kíə (high) and
  // kìə (low) do not exist. "Pay (for goods)" = tûə (falling). "Key (from English)"
  // = kîə (falling). Same tone, different segments — not a tone minimal pair. (Session 52)
  // REMOVED tone minimal pair nkîə/nkíə (river/song) — per dictionary, both meanings (water/river AND song) are HOMONYMS using the SAME rising-tone word nkǐə. They are not a tone minimal pair. (User-flagged Session 52)
];

// ============================================================
// NOUN CLASSES — singular/plural patterns
// ============================================================

class NounClass {
  final int classNumber;
  final String singularExample;
  final String pluralExample;
  final String english;
  final String? prefix;

  const NounClass({
    required this.classNumber,
    required this.singularExample,
    required this.pluralExample,
    required this.english,
    this.prefix,
  });
}

const List<NounClass> nounClasses = [
  NounClass(classNumber: 1, singularExample: 'mǎ', pluralExample: 'pəmǎ', english: 'mother/mothers', prefix: 'Ø/pə-'),
  NounClass(classNumber: 3, singularExample: 'əkwunɔ́', pluralExample: 'məkwunɔ́', english: 'bed/beds', prefix: 'ə-/mə-'),
  NounClass(classNumber: 5, singularExample: 'nəkəŋɔ́', pluralExample: 'məkəŋɔ́', english: 'pot/pots', prefix: 'nə-/mə-'),
  NounClass(classNumber: 7, singularExample: "alá'ə", pluralExample: "əlá'ə", english: 'village/villages', prefix: 'a-/ə-'),
  NounClass(classNumber: 9, singularExample: 'nduə', pluralExample: 'mənduə', english: 'hammer/hammers', prefix: 'N-/mə-'),
  NounClass(classNumber: 1, singularExample: 'apeemə', pluralExample: 'əpeemə', english: 'bag/bags', prefix: 'a-/ə-'),
  NounClass(classNumber: 5, singularExample: 'ndě', pluralExample: 'məndě', english: 'neck/necks', prefix: 'N-/mə-'),
  NounClass(classNumber: 5, singularExample: 'ntsoolə', pluralExample: 'məntsoolə', english: 'war/wars', prefix: 'N-/mə-'),
  // New noun classes from phonology PDF (van den Berg 2009)
  NounClass(classNumber: 3, singularExample: 'əfɔ̀nə', pluralExample: 'pəfɔ̀nə', english: 'teacher/teachers', prefix: 'ə-/pə-'),
  NounClass(classNumber: 7, singularExample: 'atîə', pluralExample: 'ətîə', english: 'tree/trees', prefix: 'a-/ə-'),
  NounClass(classNumber: 9, singularExample: 'ngwûə', pluralExample: 'məngwûə', english: 'dog/dogs', prefix: 'N-/mə-'),
  NounClass(classNumber: 1, singularExample: 'tǎ', pluralExample: 'pətǎ', english: 'father/fathers', prefix: 'Ø/pə-'),
  NounClass(classNumber: 5, singularExample: 'nkelɔ́', pluralExample: 'mənkelɔ́', english: 'rope/ropes', prefix: 'N-/mə-'),
  NounClass(classNumber: 7, singularExample: 'akoolə', pluralExample: 'əkoolə', english: 'leg/legs', prefix: 'a-/ə-'),
  NounClass(classNumber: 3, singularExample: 'əkwunɔ́', pluralExample: 'məkwunɔ́', english: 'bed/beds (alt)', prefix: 'ə-/mə-')];


// ============================================================
// DICTIONARY ENTRIES — extracted from Awing English Dictionary
// (Alomofor Christian, CABTAL, 2007) via Claude vision PDF read
// Total: 2494 additional entries
// ============================================================
const List<AwingWord> dictionaryEntries = [
  // body (121)
  AwingWord(awing: 'achí yə əshi\'nə', english: 'good sign when blood twitches near the eye', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'achiə təpəŋə', english: 'bad sign when blood twitches', category: 'body', difficulty: 2),
  AwingWord(awing: 'achwinə', english: 'act of provocation by twitching fingers at each other', category: 'body', difficulty: 2),
  AwingWord(awing: 'afeelókwú\'ó', english: 'small of the back', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afúə azánə', english: 'leaf of palm, palm needle', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aghəŋə', english: 'lip; edge of a hollow vessel', category: 'body', difficulty: 2),
  AwingWord(awing: 'aghəŋə ntsoolə', english: 'fat lip', category: 'body', difficulty: 1),
  AwingWord(awing: 'akəghoolámiə', english: 'nape of neck', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akə\'lə', english: 'triangular hedge on pig\'s neck to constrain it', category: 'body', difficulty: 2),
  AwingWord(awing: 'akwəŋó əshûə', english: 'fish bone', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akwə\'tó', english: 'knee', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aləəbó', english: 'growth on the neck', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aləəbənófâŋə', english: 'growth in the armpit as sign of wound', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'alógántəəmə', english: 'heart break', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alə\'tó', english: 'chin', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alu\'ə', english: 'hip', category: 'body', difficulty: 1),
  AwingWord(awing: 'ambêmálo\'ə', english: 'palm rat', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'amiə', english: 'neck', category: 'body', difficulty: 1),
  AwingWord(awing: 'aŋkəələngwúə', english: 'finger-like potatoe used as medicine (genson)', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apô yə kwaabə', english: 'left hand; left direction', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'apô yə təənə', english: 'right hand; right direction', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'aselə', english: 'sore throat. Sore throat attacks the throat', category: 'body', difficulty: 2),
  AwingWord(awing: 'atéelə akoolə', english: 'foot. The foot is the part that we put on the ground', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atéelə apô', english: 'palm of hand', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'atɨə kokonólə', english: 'coconut palm. There is no coconut tree in Awing', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atɨə maghólə', english: 'oil palm. Oil palms are palms that produce palm nuts', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atɨə nətəənə', english: 'palm tree. A palm tree produces red oil', category: 'body', difficulty: 2),
  AwingWord(awing: 'atóŋnəntsoolə', english: 'long mouth (used as insult)', category: 'body', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'atoŋə', english: 'pointed mouth of a bottle or calabash', category: 'body', difficulty: 2),
  AwingWord(awing: 'atúəmbe\'tə', english: 'shoulder blade. An Awing man usually carries his load on his shoulders', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atsa\'ámbəəmə', english: 'muscle. He whose flesh is resistant lives longer', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atsêeblá\'ə', english: 'mother tongue, local language', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'atséebántsoolə', english: 'communication by mouth', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atsê', english: 'one palm leave', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'atso\'ámásəŋə', english: 'tooth stick, toothbrush', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azáŋə', english: 'palm branch', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azelándé', english: 'fold skin of neck, especially in fleshy people', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'cha\'âz', english: 'of the eyes, bear a white substance especially early in the morning from bed', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'châ\'lə', english: 'A sort of white substance from the eye that comes out usually after sleep', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî nó əlimá', english: 'Have many blood relations who are caring', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chwá\'tə', english: 'shave one\'s hair improperly', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwí mbó', english: 'twitch fingers as a sign of agreement to contest a fight', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfeŋ fiə apô', english: 'ring of finger', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əfeŋ nəlwîə', english: 'nose ring', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əfeŋə akoolə', english: 'ankle ring, bangle', category: 'body', difficulty: 2),
  AwingWord(awing: 'ələələ', english: 'bamboo-skin (often fresh) used as rope', category: 'body', difficulty: 2),
  AwingWord(awing: 'əŋaŋ nələŋə', english: 'tendon', category: 'body', difficulty: 1),
  AwingWord(awing: 'əŋaŋə́', english: 'vein; root', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əsâŋngyénə', english: 'rib', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əshwignə́', english: 'a sort of thread produced from raffia palm stumps', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fá', english: 'cross through thick grass or fast running water on foot', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'féekə', english: 'expose teeth especially in laughter (colloquial)', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fəmá', english: 'deep one\'s hands, head, feet etc into sth eg water', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fîə akoolə', english: 'toe', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fîə apô', english: 'finger', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fid nəlwîə', english: 'blow nose', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fú məlo\'ə', english: 'palm wine. There is much palm wine in Awing village', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fú nənoŋə', english: 'grey hair. Grey hair is an indication that one is aging', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ghəəbə̂', english: 'crunch soft bone (as a dog)', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'jubô', english: 'skin (animal), strip off (bark), peel', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kwumə', english: 'nail; roof', category: 'body', difficulty: 1),
  AwingWord(awing: 'kwumtô', english: 'nail', category: 'body', tonePattern: 'falling'),
  AwingWord(awing: 'mbe\'ta', english: 'shoulder', category: 'body'),
  AwingWord(awing: 'mbi\'ə', english: 'kidney', category: 'body'),
  AwingWord(awing: 'məghód má paŋ nə̂', english: 'palm oil', category: 'body', tonePattern: 'falling'),
  AwingWord(awing: 'məm nəpəmə', english: 'stomach (internal)', category: 'body', difficulty: 1),
  AwingWord(awing: 'máma apô', english: 'palm (of hand)', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'manoŋ má əli\' mbáata', english: 'pubic hair', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'manoŋ má mbǎəmə', english: 'hair (of body)', category: 'body', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'manwáŋa', english: 'bone marrow', category: 'body', tonePattern: 'high'),
  AwingWord(awing: 'mimá', english: 'associative marker used for head nouns which are of class sixm meaning \'of\'', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mó na mbeláló\'ə', english: 'calf', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəghabta', english: 'armpit', category: 'body'),
  AwingWord(awing: 'nəghagə', english: 'cheek, jaw', category: 'body'),
  AwingWord(awing: 'nəla\' nó akoolə', english: 'ankle', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nələŋə nó apô', english: 'hand limb', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nəló\' nə́ nəlwíə', english: 'lip plug; lip disk', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nənoŋ nó atûə', english: 'hair of head', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nətén nó akoolə', english: 'sole of foot', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nətəənə', english: 'palm nut', category: 'body'),
  AwingWord(awing: 'nətə\'ə', english: 'thigh', category: 'body'),
  AwingWord(awing: 'nətsóŋ nó akoolə', english: 'heel', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nətsóŋ nó atûə', english: 'lock of hair', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nəzeŋnə́', english: 'forehead', category: 'body', tonePattern: 'high'),
  AwingWord(awing: 'ngəd nəlágə́', english: 'eyebrow', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngwub mbəəmə', english: 'skin (of man)', category: 'body', difficulty: 2),
  AwingWord(awing: 'ngwub nəlágə', english: 'eyelid', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkənə apô', english: 'elbow', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nkyeelá', english: 'raffia palm', category: 'body', tonePattern: 'high'),
  AwingWord(awing: 'nkyǐmégə', english: 'tears', category: 'body', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ntəmə akoolə', english: 'calf of leg', category: 'body', difficulty: 2),
  AwingWord(awing: 'ntso', english: 'date palm', category: 'body'),
  AwingWord(awing: 'ntso nkyílə', english: 'head of arrow', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nyíŋkə', english: 'express excitement by laughing and exposing one\'s teeth; be excited', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ŋwaŋkô móga', english: 'blink eyes', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'pe\'ə atûə', english: 'carry on head', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'péŋə achíə', english: 'bleed or lose blood. Heavy work makes people lose blood', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pipá', english: 'associative marker used for head nouns of class 2, meaning \'of\'', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pwə\'ə', english: 'spit in an unpleasant manner', category: 'body', difficulty: 3),
  AwingWord(awing: 'seelô', english: 'tear (tr)', category: 'body', tonePattern: 'falling'),
  AwingWord(awing: 'səbnô', english: 'be worry; be depressed', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'shágə', english: 'steal palm wine from another person\'s palm bush', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tôgndě', english: 'throat', category: 'body', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'twîəə', english: 'spit', category: 'body', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tsó\'óto\'ə', english: 'very sweet palm wine', category: 'body', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'waglə', english: 'hold loosely of a tied rope round something eg round a cow\'s neck', category: 'body', difficulty: 2),
  AwingWord(awing: 'yinə̌', english: 'associative marker used for head nouns which are of class 5', category: 'body', tonePattern: 'rising', difficulty: 2),

  // family (100)
  AwingWord(awing: 'achíkə ŋwunə', english: 'old person irresponsive to bodily emotions', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'adochenə', english: 'school children\'s game played with a small ball', category: 'family', difficulty: 2),
  AwingWord(awing: 'afəmólá\'ə', english: 'land where forefathers settled within the Awing clan; quarter name', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ajiəmógó', english: 'all-knowing person, proud and boastful person', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akəmóntsoolə', english: 'greedy person, powerful person', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akəghə', english: 'stupid person, imbecile; stupidity', category: 'family', difficulty: 2),
  AwingWord(awing: 'akəmótógiə', english: 'deaf person', category: 'family', tonePattern: 'high'),
  AwingWord(awing: 'akǒ\'nə məŋgyě', english: 'young woman', category: 'family', tonePattern: 'rising'),
  AwingWord(awing: 'akwu\'ó', english: 'travelling people (mystical, cause floods in enemy villages)', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aloonətəjiə', english: 'person, discontented though rich', category: 'family', difficulty: 2),
  AwingWord(awing: 'anəələmóonə', english: 'child dedication, usually takes place in church a few months (two to three months) after birth', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apo\'ə', english: 'slave', category: 'family', difficulty: 2),
  AwingWord(awing: 'asoŋə', english: 'mystical power used by one to enrich himself by dragging away another person\'s wealth', category: 'family', difficulty: 2),
  AwingWord(awing: 'atágətatsə\'ə', english: 'stiff and unrelenting person', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atássəəmə', english: 'A person who is wild and animal in nature. If you see a wild man, you should hide', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atúmnə', english: 'the habit of giving too many assignments or laying too much burden on other people', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atsa\'ə mbó nakaŋá', english: 'potter\'s clay. The potters clay is usually found near the stream', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atséebánkwûə', english: 'will of a dead person', category: 'family', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'azoŋ yə mbyâŋnə', english: 'younger brother', category: 'family', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'azoŋ yə məŋgyě', english: 'younger sister', category: 'family', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'azəbtə', english: 'a special signal that is understood only by an in-house or a specific person', category: 'family', difficulty: 2),
  AwingWord(awing: 'chigə ngəənə', english: 'good or true friend', category: 'family', difficulty: 2),
  AwingWord(awing: 'chigəngaŋnkéebə', english: 'billionaire; very rich man', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'dógto', english: 'doctor', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfeŋ ngɔŋə', english: 'ruler\'s bangle, especially that worn by fons', category: 'family', difficulty: 2),
  AwingWord(awing: 'əfəgə', english: 'blind person', category: 'family', difficulty: 1),
  AwingWord(awing: 'əfəgmógə', english: 'blind person', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfəmə', english: 'poor person', category: 'family', difficulty: 1),
  AwingWord(awing: 'əfi əpúmə', english: 'seller or somebody who sells', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfi neemə', english: 'butcher', category: 'family', difficulty: 1),
  AwingWord(awing: 'əfinə', english: 'seller or somebody who sells', category: 'family', difficulty: 2),
  AwingWord(awing: 'əfo nəfeŋə', english: 'a very inhygenic person (in exaggerated proportions)', category: 'family', difficulty: 2),
  AwingWord(awing: 'əkə̂mátôglə', english: 'deaf person', category: 'family', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əlimə́', english: 'relationship by family', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əma\'ngwulə', english: 'ancestor', category: 'family'),
  AwingWord(awing: 'ənyi ntúmə', english: 'messenger', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fálisîə', english: 'High Priest', category: 'family', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kaghog ŋwunə', english: 'man of integrity, important man', category: 'family', difficulty: 2),
  AwingWord(awing: 'mbá\' əpúmə', english: 'weaver, somebody who weaves', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mbô', english: 'people of', category: 'family', tonePattern: 'falling'),
  AwingWord(awing: 'mbǎəmə apóəmə', english: 'hunter', category: 'family', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'mbógə atúə', english: 'unlucky person', category: 'family', tonePattern: 'high'),
  AwingWord(awing: 'mbâkâ', english: 'which people, people of where, people of what (a sort of phrasal expression)', category: 'family', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mbóŋə', english: 'poor man, needy', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mbó məkəŋə', english: 'potter', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mé nəlóga', english: 'pupil (of eye)', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məko mó əfo', english: 'fon\'s messenger', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mámé', english: 'grandmother (maternal)', category: 'family', tonePattern: 'high'),
  AwingWord(awing: 'mangyè natûa', english: 'principal wife, first wife', category: 'family', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mápéenə', english: 'mother-in-law to the bride', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'móona', english: 'child', category: 'family', tonePattern: 'high'),
  AwingWord(awing: 'mó mbyâŋnə', english: 'son, little boy; boy', category: 'family', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mó má yi mbyâŋnə', english: 'grandson', category: 'family', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mó má yi mangyè', english: 'granddaughter', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mó nkə', english: 'child', category: 'family', tonePattern: 'high', difficulty: 2),

  AwingWord(awing: 'mó yi mbóolə', english: 'baby', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mó yi mangyè', english: 'daughter, girl child', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nden mangyè', english: 'old woman', category: 'family', tonePattern: 'low', difficulty: 2),
  AwingWord(awing: 'nden ŋwunə', english: 'old man', category: 'family', difficulty: 1),
  AwingWord(awing: 'ndí\' məjíə', english: 'farmer', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ndim mǎ yi mbyâŋnə', english: 'mother\'s brother (uncle)', category: 'family', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ndim mǎ yi məngyè', english: 'mother\'s sister (aunt)', category: 'family', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ndim tǎ yi mbyâŋnə', english: 'father\'s brother (uncle)', category: 'family', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ndim tǎ yi məngyè', english: 'father\'s sister (aunt)', category: 'family', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ndimá', english: 'nephew; niece', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ndɔ́ŋə', english: 'lazy person', category: 'family', tonePattern: 'high'),
  AwingWord(awing: 'ndzɔ̂lə', english: 'thief', category: 'family', tonePattern: 'falling'),
  AwingWord(awing: 'ndzoŋndzəm Yésə', english: 'disciple of Jesus', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ndzoŋndzəmə', english: 'disciple, follower', category: 'family'),
  AwingWord(awing: 'nətə nó məkəŋə', english: 'potter\'s kiln', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngaŋndzəmə', english: 'disciple, follower', category: 'family'),
  AwingWord(awing: 'ngaŋnaghéenə', english: 'guest, visitor; stranger', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngaŋtsábpê', english: 'deceitful person', category: 'family', tonePattern: 'falling'),
  AwingWord(awing: 'ngəmə́', english: 'mother-in-law to the husband or groom; mother-in-law, daughter-in-law', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngwad neemə', english: 'butcher', category: 'family', difficulty: 1),
  AwingWord(awing: 'ngwam əshúə', english: 'fisherman', category: 'family', tonePattern: 'high'),
  AwingWord(awing: 'ngwulə', english: 'clan, family; descendant', category: 'family', difficulty: 2),
  AwingWord(awing: 'nkwiŋə', english: 'unmarried person', category: 'family'),
  AwingWord(awing: 'nkwû əsê', english: 'spirit of a dead person (invisible)', category: 'family', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ntáŋ məteenə́', english: 'trader', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ntwîə aleemə', english: 'blacksmith', category: 'family', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ntse mbi yi mbyâŋnə', english: 'elder brother', category: 'family', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ntse mbi yi məngyè', english: 'elder sister', category: 'family', tonePattern: 'low', difficulty: 2),
  AwingWord(awing: 'ntse mbiə', english: 'elder', category: 'family'),
  AwingWord(awing: 'ŋwu Əsê', english: 'priest; pastor', category: 'family', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ŋwu Əsê yi ngwiŋə́', english: 'Chief Priest; High Priest', category: 'family', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ŋwu yi ńdéeləŋ nó', english: 'senile person', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ŋwunə achánə', english: 'person who turns away from others in disgust', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tă', english: 'father; parent', category: 'family', difficulty: 1),
  AwingWord(awing: 'tădmé', english: 'grandfather (maternal)', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tădmé yi ndza\'kə', english: 'great grandfather (maternal)', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'táko\' ŋwunə', english: 'adult', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'təlénja', english: 'stranger. From: English', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'təwélakámə', english: 'A sharp flute used for rallying people for emergenncies (example war, serious development projects etc)', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tóondzəmə', english: 'somebody who plays a limited role in another person\'s struggles; supporter, ally', category: 'family', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'twá nəpəmə', english: 'conceive a child, become pregnant', category: 'family', tonePattern: 'high', difficulty: 2),

  // animals (57)
  AwingWord(awing: 'atəənə akóolə əshûə', english: 'fish trap. Afish trap is found where there is water', category: 'animals', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'jwî\'lə', english: 'a sort of fly that frequents rotting things', category: 'animals', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kaŋə', english: 'wild cat that preys on fowls', category: 'animals', difficulty: 2),
  AwingWord(awing: 'kéenó', english: 'crab', category: 'animals', tonePattern: 'high'),
  AwingWord(awing: 'kíchíə', english: 'cricket (insect that thrives in dry season)', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kífəmə', english: 'a kind of big bee that lives in dry wood', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kíza\'', english: 'grasshopper (delicious food for some tribes)', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kó əshûə', english: 'fish in Awing lake (word that people should not fish in Awing lake)', category: 'animals', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'konə', english: 'owl, a bird with deep eyes that cries in the night (associated with bad omens)', category: 'animals', difficulty: 2),
  AwingWord(awing: 'kwíŋ nkǐə', english: 'turtle (water turtle)', category: 'animals', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'kwúneemə afoonə', english: 'warthog', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ləəmó', english: 'horse. Only fulanis have horses in Awing', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mbéŋ ndzelə', english: 'sheep', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mbi təŋkə̂\'ə', english: 'elephant\'s trunk', category: 'animals', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mé sáŋə́', english: 'ostrich', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məlámchú\'ə́', english: 'sort of bee that produces a stench or smell; something that smells excessively', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məŋwédnúə', english: 'bee', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mó fóolə́', english: 'mouse', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mó mbéŋ ndzelə', english: 'lamb', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mó mbéŋə', english: 'little goat', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mó ngwûə', english: 'puppy', category: 'animals', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mó púshîa', english: 'kitten', category: 'animals', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'na nkîa', english: 'rhinoceros', category: 'animals', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ndi sáŋə́', english: 'vulture', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ndú kwúneemə', english: 'boar', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ndú ləəmə́', english: 'stallion', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ndú neemə', english: 'bull', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ndzâblə', english: 'cane rat, cutting grass, grass cutter', category: 'animals', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ndzâblə məsá\'ə', english: 'porcupine', category: 'animals', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'néelə', english: 'buffalo', category: 'animals', tonePattern: 'high'),
  AwingWord(awing: 'nəlélə', english: 'army ant, soldier ant', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəmaŋnə', english: 'wild cat', category: 'animals'),
  AwingWord(awing: 'nənyaglə', english: 'earthworm', category: 'animals'),
  AwingWord(awing: 'nəsoŋ nó tə̂ŋka\'ə', english: 'elephant\'s tusk', category: 'animals', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nəwelá', english: 'a sort of small bird, known to be very unstable and as jumpy as a flee', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngábə', english: 'chicken, fowl', category: 'animals', tonePattern: 'high'),
  AwingWord(awing: 'ngwě kwúneemə', english: 'sow', category: 'animals', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ngwě ləəmə́', english: 'mare (horse)', category: 'animals', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ngwě mbéŋ ndzelə', english: 'ewe', category: 'animals', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ngwě mbéŋə', english: 'she-goat; nanny goat', category: 'animals', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ngwě neemə', english: 'cow', category: 'animals', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'nka kíleləŋkaŋə́', english: 'spider\'s web', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkǐ əshúə', english: 'fish dam', category: 'animals', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ntaŋ ngɔ\'ə́', english: 'hut built for collecting termite', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'samba', english: 'men dance group led by an elephant-like masked person. It is animated with xylophones', category: 'animals', difficulty: 2),
  AwingWord(awing: 'téembogla', english: 'a very big snake. From: English', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'təŋka\'ə', english: 'elephant', category: 'animals', difficulty: 1),
  AwingWord(awing: 'tásélaséla', english: 'ant', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tásélaséla yi ndzag nə', english: 'flying ant', category: 'animals', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'to\'lə', english: 'squirrel', category: 'animals', difficulty: 1),

  // nature (160)
  AwingWord(awing: 'achi\'lə', english: 'turf of grass', category: 'nature', difficulty: 2),
  AwingWord(awing: 'afédngónə', english: 'third day of the week and minor market day', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afúə əghəmə', english: 'fig leaf used for communication; message from the fon', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afúə nəkənə', english: 'wild grass that grows in the farm', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ajwigó', english: 'a day', category: 'nature', tonePattern: 'high'),
  AwingWord(awing: 'ajwigó ngwe\'ó', english: 'day after tomorrow', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akəblá ndəsê', english: 'clod of earth', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akəpógló', english: 'dust', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akoobá', english: 'forest, bush', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akoobá afəgó', english: 'indian bamboo bush', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akô\'ka', english: 'hill', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akwu\'ló atìə', english: 'base of tree trunk; stump', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alá\'ə akoobá', english: 'bush country, rural area', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alaŋó', english: 'path; road; destiny', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alaŋó akəpógló', english: 'dusty road', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alaŋó maŋgo\'ə', english: 'bumpy road', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alaŋó nətsa\'ó', english: 'muddy road', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alaŋómakálá', english: 'motorable road; paved road', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alě mbîə senô', english: 'this day, today', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'alě məteenə', english: 'market day', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'alélá\'ə', english: 'resting day, mostly used for ceremonies', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alěmbîə', english: 'day', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'aləəmómógó', english: 'flame of fire', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aleme', english: 'first day of the week', category: 'nature', difficulty: 2),
  AwingWord(awing: 'alemó', english: 'deep pool of water', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alóma', english: 'cloud, fog', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alí\'ə', english: 'cultivated ground', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alimkə', english: 'horizontal or level road', category: 'nature', difficulty: 2),
  AwingWord(awing: 'alúmə', english: 'a red medicinal plant', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ambuə', english: 'medicinal plant that produces a sticky substance used as gum', category: 'nature', difficulty: 2),
  AwingWord(awing: 'antwə̌\'lə', english: 'little irish-like nuts from the ground, eaten as food', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'aŋa\'ə', english: 'sort of tree like a fig, having large leaves', category: 'nature', difficulty: 2),
  AwingWord(awing: 'aŋkálə', english: 'large ridges that are formed by burning soil and vegetation', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apômbə\'ə', english: 'the fifth day of the week', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'atəsoŋə', english: 'elephant grass', category: 'nature', difficulty: 1),
  AwingWord(awing: 'atatsá\'ó', english: 'mud', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atɨə akwamnə', english: 'plum tree. A plum tree produces plum', category: 'nature', difficulty: 2),
  AwingWord(awing: 'atɨə apoŋwiŋə', english: 'A kind of soft tree used for making xylophones', category: 'nature', difficulty: 2),
  AwingWord(awing: 'atɨə awaglápanêmə', english: 'a boundary stick which its leaves are used for making a public announcement', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'atɨə azoomə', english: 'a plum tree', category: 'nature', difficulty: 2),
  AwingWord(awing: 'atɨə chaŋnə', english: 'ink tree. The ink tree grows on the hill (pasture land)', category: 'nature', difficulty: 2),
  AwingWord(awing: 'atɨə əghəmə', english: 'a fig tree. A fig tree is a tree god in some places', category: 'nature', difficulty: 2),
  AwingWord(awing: 'atɨə əleelə', english: 'A huge and hard tree used for making bridges', category: 'nature', difficulty: 2),
  AwingWord(awing: 'atɨə fóŋáfóŋá', english: 'A sort of smooth tree used for sawing plank. A plank tree is used for sawing plank', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atɨə məsəbtə', english: 'tree that develops thorns. Nobody likes climbing a thorn tree', category: 'nature', difficulty: 2),
  AwingWord(awing: 'atɨə nəpíə', english: 'cola nut tree. A cola nut tree bears colanuts', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atɨə nəpiəmbéŋə', english: 'quiny tree. A quiny tree is a peaceful tree', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ato\'ə', english: 'raffia bush', category: 'nature', difficulty: 1),
  AwingWord(awing: 'atúmə məyeŋá', english: 'bush dweller, fulanis (used derogatorily). Some Awing people call a bororo man, bush dweller', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atsa\'ə ndəsê', english: 'mud block. We use mud blocks to build houses in Awing', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'azéenə', english: 'playground; palace assembly ground', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chîə mbi ndě', english: 'stay awake late into the night', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'chigə məsanə', english: 'early morning', category: 'nature', difficulty: 1),
  AwingWord(awing: 'chigə náŋə', english: 'scrutinise; examine well', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chúbə', english: 'remove something in a very fast way, usually from danger or by means of forceful seizure', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwáanə', english: 'cut in a crude or inhuman way', category: 'nature', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'chwaglə', english: 'bath oneself or wash something in an improper way', category: 'nature', difficulty: 2),
  AwingWord(awing: 'chwí\'ə', english: 'plant (cocoyams)', category: 'nature', tonePattern: 'high'),
  AwingWord(awing: 'chwí\'tô', english: 'plant (cocoyams) a little', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əfagə atíə', english: 'branch (of tree)', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfab nɔ́lə\'ə́', english: 'plant disease that attacks sweet yams, boring holes in them', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfabâ', english: 'plant disease that attacks cocoyams', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əfabátíə', english: 'plant disease that attacks trees, boring holes in it', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfo atíə', english: 'baobab tree', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfó\' nkǐə', english: 'dry river bed', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'əfooghaəmá', english: 'lake Awing (only lake Awing is called by this name)', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əghâ', english: 'season; time', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əghâ alumə', english: 'dry season', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əghâ magheemá', english: 'rainy season', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əlě', english: 'a rough-stemmed tree that grows in grassland areas', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'əleemá', english: 'bird droplets that grow into tree branches on any tree', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'óláəló', english: 'yes; any thing kept by a tree god remains the same until the owner comes for it', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ənumnə natú\'ə', english: 'eclipse of the moon', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əshwáŋ neemə', english: 'path of a wild animal', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əwaglápanə̂mə', english: 'a boundary stick which its leaves are used for making a public announcement (a special kind that grows only in Baminyam)', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əzooná yîə', english: 'day before yesterday', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'féŋtə', english: 'get well, recover from illness', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fəláwa', english: 'flower (Whites like planting flowers in their compounds)', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fəmtəfəmtə', english: 'word that describes the movement of somebody who is not seeing his path, also of somebody who moves as if he is not seeing', category: 'nature', difficulty: 3),
  AwingWord(awing: 'fláwa', english: 'flower', category: 'nature', tonePattern: 'high'),
  AwingWord(awing: 'foŋə̂', english: 'to flourish with fresh leaves and flower (of plants). When it rains, crops flourish in the farm', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fugə', english: 'a kind of bag used to carry products from the farm', category: 'nature', difficulty: 2),
  AwingWord(awing: 'ghóŋə', english: 'farm bed', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ghóŋə aneemə', english: 'farm bed (animal-related)', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'jwígə', english: 'pass or a day; spend a day, make a day', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'jwí\'kə á ndî\' mógə', english: 'smoke, dry in smoke, dry over fire', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kǎa', english: 'clean of farm beds roughly', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'kəfəələ', english: 'storm or wind; vent', category: 'nature', difficulty: 2),
  AwingWord(awing: 'kwáŋta', english: 'clean the furrows of a farm bed a little (using a hoe)', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwedtâ', english: 'pour out a little of something on the ground or in a container', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kwelô', english: 'pour something on ground or container (solid or liquid)', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mba\' mbaŋə', english: 'rain maker or somebody who makes rain not to fall with the use of magical powers', category: 'nature', difficulty: 2),
  AwingWord(awing: 'mba\'ə', english: 'rain maker or somebody who makes rain not to fall with the use of magical powers', category: 'nature', difficulty: 2),
  AwingWord(awing: 'mbeelə', english: 'furrow between farm beds', category: 'nature', difficulty: 2),
  AwingWord(awing: 'mbe\'nó', english: 'the eighth day of the week', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mbɛ', english: 'name used only for the fon or village chief', category: 'nature', difficulty: 2),
  AwingWord(awing: 'mbǎəmə atîə', english: 'bark of tree', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'mbiə', english: 'seed', category: 'nature'),
  AwingWord(awing: 'mé ngo\' naghǒ', english: 'lower grinding stone', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'məgha\'tə má nkwəənə', english: 'vast and dry valley', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mánu yi ńté nó', english: 'sunshine', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məsâna', english: 'morning', category: 'nature', tonePattern: 'falling'),
  AwingWord(awing: 'məsobsoobə̂', english: 'thorn', category: 'nature', tonePattern: 'falling'),
  AwingWord(awing: 'móga', english: 'fire, burn', category: 'nature', tonePattern: 'high'),
  AwingWord(awing: 'mó ngo\' naghǒ', english: 'upper grinding stone', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'mó sáŋ ndúumbîa', english: 'morning-star (Venus)', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mó sáŋə', english: 'star', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nchwelə', english: 'the sixth day of the week', category: 'nature', difficulty: 2),
  AwingWord(awing: 'nchwîa', english: 'the fourth day of the week; day of rest and also for carrying out traditional ceremonies', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ndəsê yi əshí\'nə', english: 'fertile soil', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ndúumbîə', english: 'the period early in the morning between 4 Am and 5 Am', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ndzəmá', english: 'darkness', category: 'nature', tonePattern: 'high'),
  AwingWord(awing: 'ndzəŋ mənumə', english: 'afternoon, moment or period at sun down. Come in the afternoon', category: 'nature', difficulty: 2),
  AwingWord(awing: 'nəgho\'ə', english: 'manner of grinding something or style with which something is ground', category: 'nature', difficulty: 2),
  AwingWord(awing: 'nəkwumə́', english: 'a long kind of basket used for carrying farm products and firewood', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəŋkwâ\'lə', english: 'sand; little stones', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nəpeelə', english: 'boundary of field', category: 'nature', difficulty: 2),
  AwingWord(awing: 'nətú\'ə', english: 'night', category: 'nature', tonePattern: 'high'),
  AwingWord(awing: 'nətsóŋə', english: 'knot tied of any fibre product or plant, even of hair; lock e.g of hair', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngo\'ə', english: 'year', category: 'nature'),
  AwingWord(awing: 'ngɔ́\'ə', english: 'stone', category: 'nature', tonePattern: 'high'),
  // Session 52: was 'nkaŋ nkíə' — nkíə (high tone) does not exist. Per dict, water/river = nkǐə (rising).
  AwingWord(awing: 'nkaŋ nkǐə', english: 'river bank; sea shore', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'nkéebə', english: 'main market day in Awing; the seventh day of the week in Awing', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkəŋə', english: 'Traditional peace plant, planted in places of worship and used in ceremonies of peace', category: 'nature', difficulty: 2),
  AwingWord(awing: 'nkǐ yi sá\' nó', english: 'spring', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'nkəlá', english: 'large bed of farm formed by putting soil on compost and burnt', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkəŋ nelwîə', english: 'bridge (of nose)', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nkəŋ nó ngámə', english: 'rainbow', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkweelə', english: 'the second day of the week and minor market day', category: 'nature', difficulty: 2),
  AwingWord(awing: 'nkya\' nəfaŋə́', english: 'lightning', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkya\' sáŋə́', english: 'moonlight', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkyakəpeŋə', english: 'dawn', category: 'nature', difficulty: 1),
  AwingWord(awing: 'nô ndəpa\'ə', english: 'smoke tobacco', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ntîtú\'ə', english: 'mid-night', category: 'nature', tonePattern: 'falling'),
  AwingWord(awing: 'ntínumnə', english: 'noon, mid-day', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nwí\'ə', english: 'plant (of seeds) too close to each other', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ŋwiŋə', english: 'tree god', category: 'nature'),
  AwingWord(awing: 'péŋə', english: 'be lost; someone missing in the forest', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pôb', english: 'sound that describes something snuffing out eg fire or breath', category: 'nature', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'póga', english: 'bark (as dog)', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'póokə', english: 'wither eg a plant', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pwəlô', english: 'put soil on ridges', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'sáŋ yi fîə', english: 'new moon', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'sáŋ yi ńdwénkə nó', english: 'full moon', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'shí\'nə', english: 'use one\'s labour in exchange for farm products', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'shǔəə', english: 'break wind, fart', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'tasa\' móga', english: 'spark of fire', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tú nkǐə', english: 'cross river', category: 'nature', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'túmkə', english: 'make or help someone or something cross through a difficult place eg river', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'wəg ŋgênə', english: 'carry away by the force of wind', category: 'nature', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'wəg ńkwelə', english: 'pour down something using the force of wind', category: 'nature', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'yagə', english: 'scare away by shouting eg of animals or birds in a farm; yell out curses eg to a thief', category: 'nature', difficulty: 3),

  // food (89)
  AwingWord(awing: 'achiba', english: 'food or drinks given to console somebody (death)', category: 'food', difficulty: 3),
  AwingWord(awing: 'achibənáwûə', english: 'food or drinks given to a house of mourning', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'achú\'ə', english: 'cocoyams pounded and eaten with red soup, meat and vegetables', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afúə ŋgəsáŋə', english: 'corn husk', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akəká', english: 'ground corn fufu, softened with water and steamed', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akoŋə ŋgəsáŋə', english: 'corn stalk, corn husk', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akwâ', english: 'pounded Irish potato and banana', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'alífəámó', english: 'bat; fruit bat', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'amú\'á', english: 'banana', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'amú\'áchú\'ə', english: 'banana used for preparing achu', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'amú\'áfəŋə', english: 'banana not used as food but as medicinal plant', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'amú\'ámakálə', english: 'A kind of banana that is kept to ripe and is then eaten as food', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aŋgênə', english: 'A kind of elephant stalk that looks very much like sugar cane', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'aŋkəələ', english: 'carrot-like food', category: 'food', difficulty: 2),
  AwingWord(awing: 'aŋkwúbə', english: 'a raffia fruit with a hard smooth surface', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apéenəməkálə', english: 'bread. Makala like bread, hot water and sugar in the morning', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apu\'ə məjiə', english: 'food leftovers. In Awing, food leftovers of an elder is eaten by a child', category: 'food', difficulty: 2),
  AwingWord(awing: 'aso\'ə', english: 'a carved piece of wood used for lifting achu from the motar', category: 'food', difficulty: 2),
  AwingWord(awing: 'atɨə apopó', english: 'a pawpaw tree', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ato\'lóndé', english: 'adam\'s apple', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atsá\'ə', english: 'the different divisions of a banana bunch', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atso\'ə', english: 'cob of corn. One can plant a cob of corn and it produces a bag full', category: 'food', difficulty: 2),
  AwingWord(awing: 'atso\'ə ngəsáŋə', english: 'corn cob. One can plant a cob of corn and it produces a bag full', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'awa\'ə', english: 'a container for achu soup', category: 'food', difficulty: 2),
  AwingWord(awing: 'azó\'ə', english: 'yam', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azó\'áŋwúná', english: 'A sort of yam attributed to men and usually harvested and kept in men\'s houses', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azó\'íbo', english: 'A sort of yam that originated from Ibo land in Nigeria', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'básko', english: 'sort of short stemmed banana bearing a large stem', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'bóyó', english: 'a sort of short stemmed banana bearing a large stem', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chî tə məjiə', english: 'be without food', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chib nəwûə', english: 'give food or drinks to a house of mourning', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ənɔ̌ púmə', english: 'food offered by relatives of the diseased during a dead celebration', category: 'food', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'gəlumáŋ', english: 'a sort of coffee branch usually cut and thrown for soaking all the water that the coffee stem needs', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ghed məjîə', english: 'prepare food (mid-day meal)', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'jinə', english: 'exchange food, share in different aspects', category: 'food', difficulty: 2),
  AwingWord(awing: 'kagə̂', english: 'of a raffia fruit (clear its hard surface), peel raffia fruit', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ká\'lə̂', english: 'wine container made from a kind of pumpkin', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ká\'ó', english: 'a piece of plank for cutting meat, also hard surface used by butchers', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'káyé məsaŋə̂', english: 'guinea corn', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'koshamə', english: 'curdled milk; cottage cheese', category: 'food', difficulty: 2),
  AwingWord(awing: 'kyaŋə', english: 'cut a big slice eg flesh or meat', category: 'food', difficulty: 2),
  AwingWord(awing: 'kyaŋtə̂', english: 'cut big slices eg flesh or meat', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kyéŋtə', english: 'Cut off undesirable ends of vegetable', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'lámósə yi ńtságnə', english: 'lemon', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'lúmnə', english: 'eat food with little or no soup', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'lwichwí\'á', english: 'something very bitter eg fruit', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mbəm ŋgəsánə', english: 'grain of corn, maize', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məghóla', english: 'oil', category: 'food', tonePattern: 'high'),
  AwingWord(awing: 'məji má nkwanə̂', english: 'evening meal, supper', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məjîə', english: 'food', category: 'food', tonePattern: 'falling'),
  AwingWord(awing: 'məkwúnə', english: 'rice', category: 'food', tonePattern: 'high'),
  AwingWord(awing: 'məlo\' má məkálə̂', english: 'beer, wine, whiskies', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məsaŋ má aluma', english: 'sorghum; millett of the dry season', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məsaŋ má məgheemə̂', english: 'millet (of the rainy season)', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məsaŋ má ngəsáŋə̂', english: 'the flower on the stalk of corn (at the tip of)', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məsaŋə', english: 'the flower on the stalk of maize (any sort of maize)', category: 'food', difficulty: 2),
  AwingWord(awing: 'məsəngágá', english: 'corn cob that has born scanty number of grains, usually this kind bears last reason being that it was planted late', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nələ\'ə́', english: 'sweet yam', category: 'food', tonePattern: 'high'),
  AwingWord(awing: 'nənta nó atíə', english: 'fruit', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nənteemə́', english: 'fruit', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəpo\' nó məkálə', english: 'pawpaw', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nətə', english: 'the leave of a cocoyam', category: 'food', difficulty: 2),
  AwingWord(awing: 'nətó\'ə', english: 'potato', category: 'food', tonePattern: 'high'),
  AwingWord(awing: 'ngəsáŋə́', english: 'corn, maize', category: 'food', tonePattern: 'high'),
  AwingWord(awing: 'ngwápə', english: 'guava. From: English', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nju ngəsáŋə', english: 'corn silk', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkagə', english: 'a 20 litres container for measuring eg coffee measurement', category: 'food', difficulty: 2),
  AwingWord(awing: 'nkəŋk ô\'lə', english: 'sugar cane', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'paŋ sêntê', english: 'pepper (red)', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'pi nənteemə́', english: 'bear fruit', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'shí sêntê', english: 'green pepper', category: 'food', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tămto', english: 'tomato. From: English', category: 'food', difficulty: 2),
  AwingWord(awing: 'tímo', english: 'a kind of insecticide used to spray on arabica coffee', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tyáala', english: 'to strain food or anything using water', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsógchwéŋə', english: 'something very sour fruit', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zeebə', english: 'A bamboo ceiling in kitchens used for drying maize, beans, potatoes etc', category: 'food', difficulty: 2),
  AwingWord(awing: 'zédkə', english: 'make one sated up with food', category: 'food', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zó\'tə', english: 'apply oil a little', category: 'food', tonePattern: 'high', difficulty: 2),

  // actions (695)
  AwingWord(awing: 'achínə', english: 'be hefty, huge in build; important; powerful; great', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ajía mə ghóg ná', english: 'be myopic, shortsighted', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'anuə mó wam ná', english: 'be guilty, being guilty', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'blemâ', english: 'blame', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'cháabə', english: 'tightly clustered. Lice are tightly clustered on the dog\'s body', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chaakâ', english: 'accompany, lead away; send through or pass something across', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chaakâ məŋgyě', english: 'escort a bride to her groom', category: 'actions', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'chaanâ', english: 'be abundant, be much. People who steal public property have abundant wealth', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'cháb-tə', english: 'tightly clustered ', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'cha\'âı', english: 'last very long. The ancient people lived very long lives', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chagâ', english: '(colloquial) smash or step on something (tr). The tyres of a car smashes all sorts of things', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chágə', english: 'Of cocoyams, not get ready after it has been prepared (is usually watery)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chagtə̂', english: 'smash many times, crush many times', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chakâ', english: 'get smashed (intr)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chámtə', english: 'whisper, speak quietly. If one does not want another person to here what he is saying, he whispers', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chánə', english: 'turn away from someone in disgust; talk impolitely', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chántə', english: 'be much, be abundant; be sated, satisfied', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'cha\'tə̂', english: 'greet. A polite man greets everybody he/she meets along the way', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chi\' əli\'ə', english: 'raise false alarm, give false value to something. It is not good to raise false alarm in peace time', category: 'actions', difficulty: 2),
  AwingWord(awing: 'chî kətaŋə', english: 'be empty. A traditional doctor is not without supernatural powers (secret power)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chi\' mbe\'tə', english: 'refuse something by shrugging one\'s shoulders', category: 'actions', difficulty: 2),
  AwingWord(awing: 'chi\' mbəəmə', english: 'puff up or demonstrate pride', category: 'actions', difficulty: 2),
  AwingWord(awing: 'chî mbó kətaŋə', english: 'be powerless, be weak, be defenceless. The leaders of some countries are really powerless', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chǐ mə́\'á', english: 'be alone; be single, be without companion', category: 'actions', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'chǐ myā\'â', english: 'knock down, tip over', category: 'actions', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'chî ndzaŋ yi nda\'ə', english: 'be different, be contrary to expectations', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî nó aghoonə', english: 'be ill or sick. When somebody is ill he cannot do any kind of thing', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî nó ajúmə', english: 'be rich, be wealthy, have money', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî nó apógə', english: 'be in fear. He who lives in fear cannot do any great thing', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî nó əpo\'ə', english: 'be innocent. It is a grievous evil for a man to be imprisoned innocently', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî nó móonə', english: 'be pregnant, be with child. In the olden days it was terrible for an unmarried girl to be pregnant', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî nó nəpəmə', english: 'be pregnant, be with child', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî nó ŋgə́\'ə', english: 'be in difficulty, live in hardship', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî nó njiə', english: 'be hungry. A slave is he who has enough, yet remains hungry', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî ŋgǎ mə́\'á', english: 'be forever, be everlasting', category: 'actions', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'chî tə nə', english: 'be thirsty', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî tə zə́\'ə', english: 'be unmarried, stay unmarried', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî yə fɨə', english: 'be new. modern products get spoilt when they are still new', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chî yə págə', english: 'be unripe, be raw. When mangoes are still unripe children still harvest it', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chibâ', english: 'be less expensive, cheap. During the rainy season raffia palm is less expensive in Awing', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chibkə̂', english: 'make to appear less expensive or less valuable; make something appear ugly', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chídtə', english: 'cut into pieces', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chi\'â', english: 'shake (tr). When a solution is put in water, it is shaken so that it dissolves', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chi\'ə', english: 'rub. Medicine for frontal headache is rubbed on the forehead', category: 'actions', difficulty: 2),
  AwingWord(awing: 'chîz', english: 'stay, inhabit, dwell; meet', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chɨə', english: 'push; support', category: 'actions', difficulty: 1),
  AwingWord(awing: 'chɨə á məm əwə́', english: '(continued on next page)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chîə á mém təpəŋə', english: 'be part of', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə á mám təpəŋə', english: 'live in sin', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə achíə', english: 'be inborn, be a habit', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə ándó neemə', english: 'be cruel (idiom)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə ándó ngɔ\'ə', english: 'be numb, unemotional and inhuman (idiom)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chi\'ə́ asaŋɔ́', english: 'wag tail', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'chîə ashamnə ashamnə', english: 'be scattered or disorganised; live apart, not together (of people)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə atíə atíə', english: 'be unstable, be unsettled', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə awata', english: 'be hospitalised, be in hospital bed', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə aweləweelə', english: 'be mixed', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə apábpéebá', english: 'be multicoloured or having many different marks', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə əsê', english: 'be low, be humble', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə mbiə', english: 'be infront; be ahead', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə mbia', english: 'be alive', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə mbó', english: 'of a baby about to be born, said to be in hand', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə mátê', english: 'be in extreme difficulties such that one cannot have a sound sleep', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə ndəzeemə', english: 'be dreaming; be wandering', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə nəlyaŋnə', english: 'in a hidden place', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə ntso nəwûə', english: 'be dieing or about to die', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chigə əshunə́', english: 'good friendship', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chigə ndəlá', english: 'the right time', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chigə ndúmə', english: 'reliable source', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chigə neemə', english: 'cruel; poorly behaved', category: 'actions', difficulty: 2),
  AwingWord(awing: 'chigə tákɔ\'ə', english: 'biggest', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chíkə', english: 'push (many things)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chíka', english: 'stay of many people or many places, inhabit many places', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chílə', english: 'cut into many little pieces', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chi\'nâ', english: 'shake by itself (intransitive), be shaken', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chínə', english: 'be hefty, huge in build; important', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chíta', english: 'cheat', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'chí\'ta', english: 'rub many places', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chítázɔ́\'ə', english: 'be celibate', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'chid ntsəənə', english: 'lie, tell a lie', category: 'actions', difficulty: 2),
  AwingWord(awing: 'chú\' əshunə́', english: 'start a relationship', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chú\' mógə', english: 'light (fire)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chúbnə', english: 'fault finding', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'chú\'ə', english: 'pound', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'chûə', english: 'say, used in a rather snobbish and derogatory manner', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chú\'tə', english: 'pound many times, smash many times', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chútóŋonə', english: 'wail; scream', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwâ', english: 'to clear (a field)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chwa ndəlá', english: 'create, allocate or find time', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwáakə', english: 'begin; generate a machine', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwáakə nkyeetə', english: 'start an association', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwaalâ', english: 'find, look for something; investigate', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chwáalə', english: 'survive narrowly; recover from an illness', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwaalâ afa\'ə', english: 'look for a job', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chwaalâ ape\'ə', english: 'accumulate wealth', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chwaalâ ndúmə', english: 'of a pig, present signs that it is ready for crossing/mating', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chwáalə nəwûə', english: 'survive death', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'chwádkə', english: 'save, deliver from danger', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwántə', english: 'cut many spots or many things', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwaŋkə̂', english: 'grow lankily, of plants and people (tall, lacking in freshness and flesh)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chwéŋtə', english: 'pour liquids', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'chwə\'â', english: 'soften a piece of land for planting', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chwí ələnə', english: 'name something or somebody', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwíəə', english: 'give a name', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwigtə', english: 'kiss a little', category: 'actions', difficulty: 2),
  AwingWord(awing: 'chwí\'kə', english: 'make two or more things closer together', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwinɔ̂', english: 'act provocatively or threaten', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chwí\'nə', english: 'get tight together; unite', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwíŋə', english: 'be thin', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'chwíŋtə', english: 'a little thin or less in weight', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwí\'tə', english: 'accumulate, pack', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'chwitə ngonə', english: 'wail sharply', category: 'actions', difficulty: 3),
  AwingWord(awing: 'dotê', english: 'be dirty; be ugly', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fablô', english: 'be fastidious', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'fádtə', english: 'stuff or force in many things', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fa\'ô', english: 'work; serve', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fagô', english: 'break, dislodge', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fagkô', english: 'break in little pieces or many pieces (intransitive)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fagtô', english: 'break in little pieces or many pieces (transitive)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fanô', english: 'do something terrible; become terrible', category: 'actions', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'fankə', english: 'be wrong', category: 'actions'),
  AwingWord(awing: 'fáŋkə', english: '1) be fat (of many things)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'faŋnô', english: 'embrace, hug', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'fa\'tô', english: 'work a little', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'féelə', english: 'force or stuff in something, fasten eg a fence', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'feŋə̂', english: 'unwrap, expose, open food that has been wrapped', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'féŋkə', english: 'disgrace, ridicule; defile', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fê ntəgɔ́', english: 'advice; counsel', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'felə ndzɔ\'á', english: 'divorce. When a woman divorces she loses her charm', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fəələ̂', english: 'blow (of fire or nose); eat heavily (derogative use)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fáənə', english: 'bend down, stoop', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fáətə', english: 'large and pointed (used insultively for buttocks)', category: 'actions', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'fəgə̂', english: 'be blind', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'fágə', english: 'blow (with fan or breath)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fágtə', english: 'blow (many times), blow a little', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fəmə', english: 'be poor', category: 'actions'),
  AwingWord(awing: 'fəmkə', english: 'drown (transitive). In war people drown their enemies in water as a way of punishing them', category: 'actions', difficulty: 3),
  AwingWord(awing: 'fəmnə', english: 'drown (intransitive). Why is it that humans drown under water, while fish do not', category: 'actions', difficulty: 2),
  AwingWord(awing: 'fəmtô', english: 'walk as if one is not seeing or blind. When a blind man is walking, he walks unsteadily', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fi\'â', english: 'measure (of distance or height). One never measures his height with that of his father', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fi\'kâ', english: 'imitate. Children learn faster because they imitate everything they see one doing', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'filə', english: 'blame', category: 'actions'),
  AwingWord(awing: 'fi\'nə̂', english: 'imitate. People who work out of envy can be dangerous', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fi\'tə̂', english: 'tell. When a child is beaten, he will feel comforted to say that he will tell his mother when she comes back', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fídkə', english: 'exile, expel', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'figə̂', english: 'decieve. Some bad students decieve their peasant parents to get money', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'figtə̂', english: 'decieve (many people); decieve many times', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fo\'â', english: 'be rich', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'fógə', english: 'pick; choose', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fónə', english: 'call. A pastor responds to a call to God\'s service, not enlisting into a job', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fónnə', english: 'call', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'fóomə', english: 'be oily', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'fu\'ô', english: 'bubble up, boil . A pot is boiling on fire', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fwo\'â', english: 'hollow out . There is a machine for hollowing out trees', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fwonə̂', english: 'imprison; lock or key eg a door', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fwontə̂', english: 'lock (many doors); imprison, of many people', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fwoŋə̂', english: 'lift or remove sth sticky. When it rains people lift a lot of mud with their feet', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fwoolâ', english: 'shave, as with a blade; peel off', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fwootâ', english: 'mumble. A dumb mumbles instead', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fyaamə̂', english: 'remove sth hanging or suspended. Remove a dress from the line (rope)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fyádtə', english: 'chase (many things); insist many things', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fya\'â', english: 'rebuke; quarrel', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fya\'ə̂', english: 'water. Water tomatoe', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fyagə̂', english: 'dislodge something from another. It is difficult to dislodge two friends from each other', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fyagtə̂', english: 'separate two things from each other. It is normal to separate two people fighting', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fyamtə̂', english: 'of things hanging or suspended, remove them. Remove those dresses hanging on the line', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fya\'sê', english: 'sacrifice to the dead', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'gómə', english: 'clue', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'ghabkə̂', english: 'half done or gone. He has not gone half', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghabnə̂', english: 'divide, separate, share (intr). They have shared their property', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghabtə̂', english: 'divide, separate (tr). He has shared his belongings', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghá\'ə', english: 'be big', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'gháglə', english: 'be smart. A smart woman is more pleasing to people', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ghagtə̂', english: 'make poorly, of furniture. He has made that bamboo chair poorly', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghánkə', english: 'stagger, make somebody to stagger (tr). He has made somebody to stagger and fall', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ghántə', english: 'visit a little, visit many people; wonder about', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'gheebə̂', english: 'divide or share, give (tr). It is good to give alms (be generous)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghéenə', english: 'visit', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'ghedtô', english: 'act, do, make a little', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghelə̂', english: 'act, do', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'ghenkə̂', english: 'make go', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'ghə\'ə̂', english: 'frugal, be greedy', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghəəkə̂', english: 'disturb, stupify', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'ghəənə̂', english: 'be stupid', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'ghəətə̂', english: 'fumble, do something wrongly', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghághlə', english: 'hasten up, hurry, be fast', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ghó\'kə', english: 'respect, honour, praise; worship', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ghoolə̂', english: 'pay dowry; marry', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghoonə̂', english: 'be sick, be ill', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghó\'tónô', english: 'be fastidious, be difficult to deal with, feel high of one\'s self', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghədkə̂', english: 'frighten', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'gho\'ə̂', english: 'crush (transitively), grind', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghəntə̂', english: 'often sick, frequently ill', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'gho\'tə̂', english: 'grind a little, grind many things', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'jáabə', english: 'reduce', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'jábtə', english: 'replant', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'já\'ə', english: 'skip through, leap over', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'jî əkomó', english: 'be crowned, take title of a noble through a ceremony in the palace', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'jî ənuə', english: 'be intelligent, be bright', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'jî mbəglə', english: 'be corrupt', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'jîəə', english: 'begin, start', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'jimkə', english: 'wake somebody up (transitive)', category: 'actions', difficulty: 2),
  AwingWord(awing: 'jimnə̂', english: 'wake up (intransitive)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ji\'tə̂', english: 'be frugal, be stingy', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'júblə', english: 'be foolishly excited', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'jubtə̂', english: 'peel many things', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'júmə', english: 'dry up; lose weight', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'júmnánáwûə', english: 'resurrect, come back to life', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'júnə', english: 'buy; corrupt', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'jwǎa', english: 'trap an object flying in the air', category: 'actions', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'jwáabə', english: 'provoke, taunt', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'jwábtə', english: 'provoke many times, taunt continously', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'jwa\'ə', english: 'annoy, disturb', category: 'actions'),
  AwingWord(awing: 'jwánə', english: 'befit; suit', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'jwó\'ə', english: 'test', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'jwó\'tə', english: 'listen', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'jwiəə', english: 'breathe; open the window to let air in', category: 'actions', difficulty: 2),
  AwingWord(awing: 'jwikə', english: 'pant; ventilate', category: 'actions', difficulty: 1),
  AwingWord(awing: 'jwí\'kə', english: 'boil a little in hot water so as to preserve by drying', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'jwitô', english: 'rest, take a rest', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'káatə', english: 'threaten', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kádtə', english: 'coil rope, rap many things', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ká\'ə', english: 'clot (as blood)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'káglə', english: 'sweep imperfectly', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'kagnə̂', english: 'threaten each other', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kagtə̂', english: 'threaten many times', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kakə̂', english: 'be rough', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'kamə̂', english: 'lift in big lumps', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kanə̂', english: 'jump from a high place', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kéelə', english: 'wrap up, coil (rope)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kéenə', english: 'be tired', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'kédkə', english: 'burn in many places', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kélə', english: 'burn', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'kábkə', english: 'cover', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'kǎə', english: 'be deaf', category: 'actions', tonePattern: 'rising'),
  AwingWord(awing: 'káəbə', english: 'shell, of groundnuts and egussi', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kəəkô', english: 'run (referring to many things or people running)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kəələ̂', english: 'run away, flee, escape', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kəətə̂', english: 'run a little or make an effort to run', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kəmə̂', english: 'drive away', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'kəmtə̂', english: 'sprinkle a little (powder, ground etc) on something', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kəŋkə̂', english: 'avoid, alienate', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'kəŋtə̂', english: 'shut a little; shut many', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kápkə nkwumə', english: 'close a box', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ká\'tə', english: 'cut many times; cut many things', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kîəə', english: 'refuse, reject', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'kíbnə', english: 'high, of forehead', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kíbtə', english: 'shell a little', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kí\'tə', english: 'Obstruct many people, things or places; defend (many people, things or places)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kó əsóənə', english: 'be shy (it is not good for somebody to be too timid and do wrong)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ko\'â', english: 'arrive; be enough', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kogə', english: 'be blunt', category: 'actions', difficulty: 1),
  AwingWord(awing: 'kóga', english: 'bring up (child or young of any animal)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kógnə', english: 'behave stupidly', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'ko\'nâ', english: 'right, (be) correct', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kóŋkə', english: 'cause to be carried away by water current', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kóo', english: 'snore', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'kookâ', english: 'peel off in bits; fall off by itself', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kóokə', english: 'shift blame (when a thief is caught he shifts the blame to hunger)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'koolâ', english: 'harvest fruits with impunity', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kóoma', english: 'shave (as if one is mourning)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kóomə', english: 'scratch eg an itching part of the body, scratch the surface of a wall to remove paint or dirt', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kóomálənə', english: 'pity, show sympathy', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'koonâ', english: 'fall or peel off in large quantities (usually by itself)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kóotə', english: 'take hold of many things (as a fishtrap traps fish)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kədkô', english: 'peel off, usually as a sign of delapidation', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kódta', english: 'eat many things, eat a little thing (before going to work)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kó\'ə', english: 'grow, of plants; mount, for example a horse', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kó\'kə', english: 'raise, of a child; lift', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kólə', english: 'ruminate, chew cud', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kómtə', english: 'Clean a little, usually with a hoe; clean roasted food', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kó\'nə', english: 'Climbing, scramble of many things; Scramble around something or somebody', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kontə̂', english: 'bump, trip', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'kəŋnə̂', english: 'be happy with each other; be joyful with each other', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kóŋnə', english: 'Crawl; slither, of many things (snakes are slithering in the farm)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kó\'tə', english: 'brag', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'kwáakə', english: 'cackle (as of fowls), especially when a fowl lays an egg or when it senses danger', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwáalə', english: 'help', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'kwáankǐə', english: 'be baptised', category: 'actions', tonePattern: 'rising'),
  AwingWord(awing: 'kwáatə', english: 'help a little', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwa\'ə', english: 'play, make jokes', category: 'actions', difficulty: 2),
  AwingWord(awing: 'kwagtə̂', english: 'clean a little, using a hoe (usually in the coffee farm)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kwakə̂', english: 'get broken', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'kwa\'lə̂', english: 'tempt', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'kwaŋtə̂', english: 'think a bit, decide', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kwêe', english: 'answer; reply', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kweekô', english: 'Influence a person or an animal against another', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kwê', english: '(colloquial) tell a lie (people lie in politics to such extent that one can see a black object an call it red)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kwénkə', english: 'Help somebody or something go in', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwəələ̂', english: 'Ask many annoying questions', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kwá\'tə', english: 'kneel', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'kwígə', english: 'revenge', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'kwíŋkə', english: 'bring up , raise', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwubə̂', english: 'be frugal', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'kwúblə', english: 'alter, change (transitive)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwúblə mbimá', english: 'convert; change one\'s believes', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwúdtə', english: 'tie many things', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwûə', english: 'be dead; die', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kwúka', english: 'die, of many things', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwú\'kə', english: 'make sb or sth stoop, bend or bow', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwúlə', english: 'fasten; bind', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwúmtə', english: 'remember, remind', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'kwú\'nə', english: 'stoop; bend', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwú\'tə', english: 'stoop, of many people; bend, of many people', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kyaalô', english: 'Lift sth soft or rotten with a hoe or spade. Clean off mess', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kyáamə', english: 'wring out, squeeze', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kyaatə', english: 'Do a little cleaning of mess', category: 'actions', difficulty: 2),
  AwingWord(awing: 'kyáglə', english: 'Dirty, with marks caused by sweat, water or cosmetics', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kyagtə', english: 'untie many things eg bags', category: 'actions', difficulty: 2),
  AwingWord(awing: 'kyámtə', english: 'wring out water (just a little) from sth', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kyê', english: 'abandon sth because it has been desecrated or misused', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kyêe', english: 'smash grain into little pieces, using a grinding machine', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kyeetə̂', english: 'Bring together, gather', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kye\'â', english: 'Make a small opening on a thing. This refers to things that can be peeled, esp. food items', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kye\'kə̂', english: 'develop openings or cracks (intr)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kyéŋə mbi əsê', english: 'confess', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'kyé\'tə', english: 'hatch', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'kyéɛlə', english: 'claim reimbursement', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'kyímə', english: 'Cut off sth attached to another, esp. using a sharp point', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kyímtə', english: 'Cut off things attached to the main part, especially using a sharp point', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ladkô', english: 'continuously, non-stop; connect, link', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ladtô', english: 'tangle', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'lá\'ə', english: 'hook', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'la\'â', english: 'announce (especially of a birth); say (colloquial)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'lagə', english: 'fetch, of firewood; gather or assemble, of objects', category: 'actions', difficulty: 2),
  AwingWord(awing: 'lá\'kə', english: 'thank or give thanks', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'la\'nə̂', english: 'promise, say that one will do something', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'langa', english: 'palate, sense of taste', category: 'actions', difficulty: 2),
  AwingWord(awing: 'laŋə̂', english: 'succeed, make it', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'lá\'tə', english: 'hook many times', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'leŋkə', english: 'notice or put a mark on something so as to give it identity', category: 'actions', difficulty: 3),
  AwingWord(awing: 'lednə̂', english: 'perspire, sweat', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'leelô', english: 'float', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'lelə', english: 'be heavy', category: 'actions'),
  AwingWord(awing: 'lenə', english: 'be old (not young, not new)', category: 'actions', difficulty: 2),
  AwingWord(awing: 'ləbə', english: 'slap', category: 'actions'),
  AwingWord(awing: 'lə\'ə', english: 'avoid, evade', category: 'actions'),
  AwingWord(awing: 'lógə', english: 'cut (tr); decide, put an end', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ləgnə̂', english: 'forgive; forget', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'lágnə', english: 'cut (tr), decide', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ləmə', english: 'stink (bad or offensive); smell (intransitive verb)', category: 'actions', difficulty: 2),
  AwingWord(awing: 'ləmkə̂', english: 'smell (transitive verb), sense through the nose', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ləmnô', english: 'startle, surprise', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'ləmtô', english: 'grumble, complain', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'ləŋə̂', english: 'stir', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'líbkə', english: 'make or cause something to go round', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'líblə', english: 'go round, surround', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'lí\'ə', english: 'cultivate, hoe (v)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'lîə', english: 'jump, leap', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'lóŋkə', english: 'fill, of solids', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'loonâ', english: 'want; desire', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'lóbtə', english: 'plan', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'lo\'â', english: 'put a spell on', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'lóg ŋgenə', english: 'carry away', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'lóg ngiə', english: 'bring, bring along', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'lo\'kâ', english: 'keep; bury (euphemism)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'lóŋnə', english: 'be lazy', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'lúmtə', english: 'gnaw', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'lúnkə', english: 'fill, of solids and liquids', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'lwénkə', english: 'fill; be full', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'lwénkə nəŋkə', english: 'fulfill the law, obey law', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'lwîəə', english: 'be bitter', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'lwigtâ', english: 'be last', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'lwikô', english: 'a little bitter', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'lyamkô', english: 'contaminate, spread eg a disease', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'lyamnô', english: 'spread, of disease', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ma\' məlóŋə', english: 'be sad, look pitiful', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ma\'â', english: 'give, of a free gift. This done or demanded only after buying something. eg eating oil', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'máma', english: 'name used for old women; prefix used before the names of old women', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mêe', english: 'be used up', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'megtə acha\'tə', english: 'wave a greeting', category: 'actions', difficulty: 2),
  AwingWord(awing: 'medkâ', english: 'make something to become habitual', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'médkə', english: 'immerse somebody or something in water (tr)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'medtô', english: 'allow, permit; cease, stop, leave', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'melô', english: 'become a habit', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'méla', english: 'immerse or dive in water', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məchína atîə', english: 'be high', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mág mimá sén nə', english: 'be dizzy', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məgtə̂', english: 'finish', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'məghábnə apô', english: 'be generous', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məjûmnánə nəwûə', english: 'ressurrection', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'məlêlənə̂', english: 'be dim', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'məmtə̂', english: 'feel something through a physical touch (active voice)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məpêŋnə ajwíə', english: 'be unconscious', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mí\'tə', english: 'stutter', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'moomâ', english: 'try', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'mootô', english: 'chat, discuss', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'mya\'â', english: 'throw away; abandon', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nâ', english: 'insist, press', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'náanə', english: 'be seated; sit', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'na\'ə̂', english: 'be silent, be still', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'náŋə', english: 'look at; look for', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'náŋkə', english: 'announce, inform', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'náŋnə', english: 'cook, boil food', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nèe', english: 'insist, press on', category: 'actions', tonePattern: 'low', difficulty: 2),
  AwingWord(awing: 'neebô', english: 'be neat, be polished', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ne\'â', english: 'limp', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'néŋ əsóomə atûə', english: 'accuse falsely', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'néŋə', english: 'put; place', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nédkə', english: 'grunt', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'nélə', english: 'groan', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'nəələ', english: 'show, explain; demonstrate', category: 'actions', difficulty: 2),
  AwingWord(awing: 'naŋê', english: 'step on, stamp (with feet)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nəntə̂', english: 'trample', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'nid ńgə́', english: 'imply that, mean that', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkogə́', english: 'widow (used neutrally for both man and woman)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nô ngoolə', english: 'swear, oath, make a statement that is considered as the truth', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'noŋnô', english: 'lie down; be level', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nə\'â', english: 'press', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'nóŋə', english: 'suckle (intr)', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'nyaanô', english: 'sluggish, slow', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'nyá\'ə', english: 'a little', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nyamnô', english: 'mix', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'nyée', english: 'growl', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'nyinô', english: 'move; travel', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nyintô', english: 'take a walk, stroll', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nyíŋnə', english: 'be restless, be unsettled', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ŋá\'ə', english: 'open (tr)', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'ŋá\'kə', english: 'open (tr)', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'ŋá\'nə', english: 'open (intr), of something opening by itself', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ŋáŋkə', english: 'lift', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'ŋédtə', english: 'be crooked', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ŋwa\'ô', english: 'clean, clear; holy', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ŋwa\'lô', english: 'write', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'ŋwaŋkô', english: 'flash, of something bright eg of lightening; shine', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ŋwéetə', english: 'be jealous, be envious', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ŋwédlə', english: 'be too excited', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ŋwú\'kə', english: 'make something stoop', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ŋwú\'nə', english: 'bow, as in greeting; stoop', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'páatə', english: 'approach; make narrow', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pábtə', english: 'make something a little warm; roast a bit', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pa\'ə', english: 'plait, braid , weave', category: 'actions', difficulty: 2),
  AwingWord(awing: 'págə', english: 'ferment', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'panô', english: 'hang up', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'paŋə', english: 'be red', category: 'actions'),
  AwingWord(awing: 'paŋnə', english: 'ripen, become ripe, of many things', category: 'actions', difficulty: 2),
  AwingWord(awing: 'pèe', english: 'sharpen', category: 'actions', tonePattern: 'low'),
  AwingWord(awing: 'péebə', english: 'bake (in ashes)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'peelô', english: 'carry on the bavk (sic: back)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'peenə', english: 'hate', category: 'actions'),
  AwingWord(awing: 'pegə', english: 'enlarge; widen', category: 'actions', difficulty: 1),
  AwingWord(awing: 'péŋkə', english: 'misplace', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'péelə', english: 'be mad. Rather than stay alive and be mad, one be dead rather', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'péntə', english: 'paint, daub with paint', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pə', english: 'then. = You told him, what then did he say?', category: 'actions', difficulty: 2),
  AwingWord(awing: 'pá ndəŋdəŋə', english: 'be equal, be same', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pá nkaŋ nwunə', english: 'be young', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pó\'ə', english: 'break (tr)', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'páəmə', english: '1) hunt', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'pəglə', english: 'put in disorder, scatter', category: 'actions', difficulty: 2),
  AwingWord(awing: 'péŋnə ńgwûə', english: 'capsize, tip over and fall', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'pəŋtô', english: 'contradict', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'pí\'ə', english: 'hem', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'pí\'kə', english: 'twist, treat cunningly, handle cunningly', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pímnə', english: 'agree', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'pítə', english: 'ask, request', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'pí\'tə', english: 'fold, wrap up', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pi fê', english: 'return, give back (tr)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'pó\' mbeebə', english: 'flap wings', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pó\'nə', english: 'fight, fight each other', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'póŋə', english: 'be poor; lack', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'póŋə awaamə mbəəmə', english: 'be impatient, lack patience', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pookô', english: 'say goodbye, take leave of', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'póomə', english: 'build, mold (pottery)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pəbnô', english: 'squat, sit (on bear ground)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'poŋô', english: 'be good; beautiful', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'pwódkə', english: 'be impotent', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'pwódnə', english: 'be kind or gentle, of people; be soft, of objects', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pwónə', english: 'dip', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'pyáanə', english: 'pick up', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'pyáatə', english: 'examine closely (with care, love and diligence), explain diligently', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pyábtə', english: 'guide many things or people; guide a little', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sa\'ə', english: 'snatch', category: 'actions'),
  AwingWord(awing: 'tá\'ə', english: 'order, of someone to do something; judge', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sa\'ə məngyè', english: 'marry by taking the fiancee by trickery or by physical force', category: 'actions', tonePattern: 'low', difficulty: 2),
  AwingWord(awing: 'sakə', english: 'lengthen', category: 'actions'),
  AwingWord(awing: 'sá\'kə', english: 'burst out, of many things', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sá\'nə', english: 'quarrel with each other', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sánkə', english: 'get broken', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'sántə', english: 'cut or break into many pieces', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'séenə', english: 'saw , cut open', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'seŋtə', english: 'flatten', category: 'actions'),
  AwingWord(awing: 'sedkô', english: 'curve, bend (tr), make it go round; make something go round', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'sednô', english: 'turn round (intr)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'seekô', english: 'torn in many pieces, torn in many spots eg of a dress', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'séekə', english: 'blaze, of light; shine intensely, of light (tr)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'seenô', english: 'be torn, torn eg of dress', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'sábkə', english: 'swing', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'səəkə', english: 'be slippery', category: 'actions'),
  AwingWord(awing: 'səələ', english: 'slice', category: 'actions'),
  AwingWord(awing: 'səənô', english: 'slip', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'sôətə', english: 'slice in many things, castrate many things', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'səŋə', english: 'sifter', category: 'actions'),
  AwingWord(awing: 'sô', english: 'weed', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'sogə', english: 'wash (tr)', category: 'actions'),
  AwingWord(awing: 'sóŋgo\'á', english: 'crown', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sǒo', english: 'cover completely. Masqueraders wear masks', category: 'actions', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'sóokə', english: 'pass something through, especially into a narrow place or into a place difficult to be accessed', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'soolô', english: 'domesticate, tame', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'sóola', english: 'go through a hole or a narrow place', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sha\'\'tə', english: 'sprout', category: 'actions'),
  AwingWord(awing: 'shaabô', english: 'comb', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'shaalô', english: 'husk (corn)', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'shamkô', english: 'scatter, spread out (maize) (tr)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'shamnô', english: 'be wide', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'sháŋə', english: 'count, number', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'shígə', english: 'wipe', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'shikô', english: 'deepen', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'shitô', english: 'straighten', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'shúmə', english: 'whip, beat up', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'shwaalô', english: 'be odd; be ugly', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'shwánta', english: 'persuade. If you persuade somebody with good words he listens to you', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'shwee', english: 'miss, fail to get. If one misses something it is good to try again', category: 'actions', difficulty: 2),
  AwingWord(awing: 'shweekô', english: 'fail, not work as planned', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'shwə\'á', english: 'reduce in intensity . That illness is reducing in intensity', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'shwəənô', english: 'slither (of snake), roll', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'shwəətô', english: 'caress', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'shwəgtô', english: 'fade', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'shwíŋə', english: 'suck', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'taalô', english: 'stagger', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'táaatə', english: 'set many traps', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ta\'â', english: 'search, especially through piles of things', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tágə', english: 'harvest, collect (honey from hive)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'taŋô', english: 'be sticky', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'taŋnə', english: 'suffer', category: 'actions', difficulty: 1),
  AwingWord(awing: 'táta', english: 'address, to an old man', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'téekə', english: 'meet, catch up with; join', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'téemə', english: 'set a trap; net, of fish', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tégə', english: 'meet, catch up with; join', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tegnə', english: 'already left (gone), just left (gone)', category: 'actions', difficulty: 2),
  AwingWord(awing: 'tê', english: 'hot, of pepper', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tê ndê', english: 'leave the house very early in the mourning hours, especially at mourning twilight (colloquial usage)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'teŋkə', english: 'push', category: 'actions', difficulty: 1),
  AwingWord(awing: 'tó', english: 'functions as one of the two forms of the verb \'to be\'. He is going to the farm', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tə shîəə', english: 'be shallow', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'təələ', english: 'boast', category: 'actions', difficulty: 1),
  AwingWord(awing: 'tóga', english: 'discipline, put on the right path', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tógə atûə', english: 'be eager, (be) zealous', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tágtə', english: 'put many things', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tám əsóomə atûə', english: 'accuse falsely', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'támə', english: 'kick, shoot', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'taŋnô', english: 'tether (sheep, goats)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tímə', english: 'sew using a needle', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tí ndəŋdəŋə́', english: 'be level, be straight', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tí ngəələ', english: 'be hollow', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tímnə', english: 'wander', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'to\'ə', english: 'become dwarf, of people; all grow, of plants', category: 'actions', difficulty: 2),
  AwingWord(awing: 'tó\'kə nkadtə', english: 'be proud', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'tó\'kə nkonə', english: 'be proud', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'tômbáŋə', english: 'flip over', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'tóoka', english: 'overtake', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'toonô', english: 'singe; roast', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tógə', english: 'pierce (of ears) for earings', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tómtə', english: 'justify; support', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tonô', english: 'be hot', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'to\'nô', english: 'inquire curiously', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tóŋnə', english: 'shout', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tûə', english: 'pay (for goods, services, etc.)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'túəŋə', english: 'bury', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tûg əsəənə', english: 'ashamed', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'túgə', english: 'have, hold; look after, care for', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'túgə akoŋnə', english: 'be happy with each other; be joyful with each other', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'túgə apógə', english: 'be afraid', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'twáamə', english: 'lift up; carry', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'twéetə atwêŋə', english: 'gird up, of one\'s loins; get ready for action', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'twîə', english: 'melt iron', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'twi\'ə', english: 'delay, stay for long', category: 'actions', difficulty: 2),
  AwingWord(awing: 'tyâ', english: 'reject', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tyáatə', english: 'explain carefully with every necessary detail', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tyagə', english: 'lift, of sth sticky', category: 'actions', difficulty: 2),
  AwingWord(awing: 'tyá\'la', english: 'straddle', category: 'actions', tonePattern: 'high'),
  AwingWord(awing: 'tyantô', english: 'be hard; strong', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tyantə', english: 'harden', category: 'actions', difficulty: 1),
  AwingWord(awing: 'tyantô má jí nə́', english: 'be scarce, hard to find', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tsáblə', english: 'talk nonsense, talk foolishly, talk alot', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsámtə', english: 'chew many things; chew a little', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tséebə', english: 'speak, talk', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tséemə', english: 'chew', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsé\'ə', english: 'admire', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tségnə', english: 'sneeze', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tseŋnə', english: 'herd of cattle, sheep etc', category: 'actions', difficulty: 2),
  AwingWord(awing: 'tsédndzəmə', english: 'last, finalise, end', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsəələ', english: 'defeat, beat in a contest', category: 'actions', difficulty: 2),
  AwingWord(awing: 'tséla', english: 'stop up, patch', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsentə', english: 'assemble, meet, heap up, join, put together, gather', category: 'actions', difficulty: 2),
  AwingWord(awing: 'tsəəmə', english: 'drip', category: 'actions', difficulty: 1),
  AwingWord(awing: 'tsóga', english: 'be expensive', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsoŋ aléna', english: 'slander', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsəŋkô', english: 'condemn, spoil, damage', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tsəŋkô apímnə', english: 'break a promise', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tsid ntsəələ', english: 'lie, tell a lie', category: 'actions', difficulty: 2),
  AwingWord(awing: 'tsímkə', english: 'trickle', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsó\'ə', english: 'heal (tr), cure', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsonkə', english: 'create, make; manufacture', category: 'actions', difficulty: 2),
  AwingWord(awing: 'tsóŋə', english: 'make a knot, tie a knot', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsóŋtə', english: 'make many knots, tie knots', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsoobô', english: 'imperfectly done, do imperfectly eg preparing food', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tsóoka', english: 'lower (tr), decrease (intr)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsóoka mbəəmə', english: 'be humble', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsóolə', english: 'descend, go down', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsó\' mbîəə', english: 'transplant', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tsó\' mbô', english: 'drop (tr), let go', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tsó\'kə', english: 'lend', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsɔɔ', english: 'taste poorly, not flavoured; of food', category: 'actions', difficulty: 2),
  AwingWord(awing: 'waamô', english: 'accuse', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'waamə', english: 'hold, catch (fish), seize', category: 'actions', difficulty: 2),
  AwingWord(awing: 'wadnô', english: 'cross, traverse, pass through', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'wágə', english: 'despise', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'wam mbəəmə', english: 'be patient; calm one\'s self', category: 'actions', difficulty: 2),
  AwingWord(awing: 'wamtô', english: 'tie loosely, of a rope round something eg round a cow\'s neck', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'wê atsə\'á', english: 'wear clothes', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'we\'â', english: 'open', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'weŋkô', english: 'smile a lot, smile frequently especially without descriminating with whom this is done', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'wê', english: 'weigh. From: English', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'wednô', english: 'mix', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'wedtô', english: 'mix (many things)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'wé\'ə', english: 'curse away, purge something', category: 'actions', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'welô', english: 'weight', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'wénə', english: 'draw pictures; make incisions', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'wénnə', english: 'be worried, be impatient', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'wáələ', english: 'worry, feel disturbed', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'wəg əfógə', english: 'fan', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'wəgô', english: 'blow of air', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'wó\'tə', english: 'remember, remind', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'wǔəə', english: 'fall; fail', category: 'actions', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'wukə̂', english: 'fall many times; fall, of many people', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'wúnə', english: 'invite, ask or demand that somebody should help one, often to do jobs that cannot be done by the individual', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'wu\'nə nkwumə', english: 'close a box; close a coffin', category: 'actions', difficulty: 2),
  AwingWord(awing: 'wúnta', english: 'invite, of many people', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'yaalô', english: 'carry, of heavy load (colloquial usage)', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'yáŋə', english: 'be wise', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'yantə', english: 'protrude, of stomach', category: 'actions', difficulty: 3),
  AwingWord(awing: 'yénta', english: 'half-eat something (leaving teeth marks) eg as is usually done by a cat or rat', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'yéeka', english: 'disturb or annoy somebody or something', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'yéeka əli\'á', english: 'disturb or annoy', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'yéelə', english: 'loose the mind; be mad (used colloquially)', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'yîəə', english: 'come, approach', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'yigə', english: 'escape capture easily, skilled in evading capture', category: 'actions', difficulty: 2),
  AwingWord(awing: 'yílə', english: 'difficult, hard', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zadtô', english: 'sprinkle', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'zagə', english: 'fly', category: 'actions', difficulty: 1),
  AwingWord(awing: 'zag náanə', english: 'alight', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zá\'kə', english: 'lend, give on credit', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zámkə', english: 'put (of something) on another', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zámnə', english: 'sit on something high or uplifted eg on a powerful throne', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'záŋ ndê', english: 'be angry', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'záŋə', english: 'give pain, hurt', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zaŋkə', english: 'be light (not heavy)', category: 'actions', difficulty: 2),
  AwingWord(awing: 'zé\'ə', english: 'learn', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zegô', english: 'smear a surface with something sticky', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'zegə̂', english: 'wipe off something sticky eg of excreta after excreting', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'zé\'ka', english: 'teach', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zélə', english: 'be sated', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zəələ', english: 'steal', category: 'actions', difficulty: 1),
  AwingWord(awing: 'zəəmə̂', english: 'wake somebody from sleep', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'záənə', english: 'find; see', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zəgə', english: 'sweep', category: 'actions', difficulty: 1),
  AwingWord(awing: 'zəgtə̂', english: 'sweep a little', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'zá\'nə', english: 'lean against', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zó\'ə', english: 'hear; feel', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zo\'kə', english: 'make less tight', category: 'actions', difficulty: 2),
  AwingWord(awing: 'zó\'nə', english: 'be obedient', category: 'actions', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zoŋ pə́ pê', english: 'be third', category: 'actions', tonePattern: 'falling'),
  AwingWord(awing: 'zoŋkə̂', english: 'be second', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'zoolə̂', english: 'roar', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'zó\' nə məghôlə', english: 'annoint, rub with oil', category: 'actions', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'zəbtə', english: 'babble, of baby', category: 'actions', difficulty: 2),
  AwingWord(awing: 'zəmnə̂', english: 'insult each other', category: 'actions', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'zəmtə̂', english: 'insult', category: 'actions', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'zoŋnə̂', english: 'fight over something', category: 'actions', tonePattern: 'falling', difficulty: 2),

  // descriptive (131)
  AwingWord(awing: 'achaakə', english: 'escort accompanying a bride to her new home', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'afélə', english: 'uninfluential; physically powerless', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afya\'ó anuə', english: 'sacrifice for the dead, libation', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aghaglə móchìsə', english: 'empty match box', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aghəəló', english: 'open gourd for washing twins', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ajúblə', english: 'foolish excitement, uncontrolled and misguided excitement', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ajwigó tapəŋə', english: 'bad company', category: 'descriptive', tonePattern: 'high'),
  AwingWord(awing: 'akəféŋəntsoolə', english: 'obscene/immoral behaviour', category: 'descriptive', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'akəghə atséebə', english: 'foolish talk', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akəká\'ó', english: 'kind of basket weaved using soft interior of raffia bamboo', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akəkógó atséebə', english: 'foolish talk', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akíbnə', english: 'high (of forehead)', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akǒ\'nə mbyâŋnə', english: 'young man', category: 'descriptive', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'akó\' yə fíə', english: 'new generation', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akweŋómbéŋə', english: 'young goat', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akyâglə', english: 'dirty marks on body or clothes caused by dirty water, sweat or cosmetics', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akye\'ə', english: 'small sign or indication (usually of something bigger to come)', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'alá\'ə', english: 'much, a lot', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alá\'ə pakwûə', english: 'world of the dead', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'alě nəwûə Yésó', english: 'good Friday', category: 'descriptive', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'alêtələ', english: 'sharp and alert person (colloquial)', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'alaŋə', english: 'stick used to hold together two ends of a rope', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'ali\' yə noŋnə nə', english: 'open place, clearing', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'anüənda\'ə', english: 'false thing', category: 'descriptive'),
  AwingWord(awing: 'anuyələnə', english: 'old fashioned practice', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'anyádlə', english: 'digusting, dirty', category: 'descriptive', tonePattern: 'high'),
  AwingWord(awing: 'apa\'ə', english: 'a flat covering (of door, window, hut etc.)', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'apáŋə', english: 'an open bamboo cupboard attached to the wall of the house used for putting kitchen utensils', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apuməŋkwúnə', english: 'small pox', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'asəələ', english: 'castrated', category: 'descriptive'),
  AwingWord(awing: 'asagá', english: 'A place that is open and exposed', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'asəglə', english: 'important, great, powerful, influential', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'asəŋə', english: 'a kind of weaved basin', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'asóŋətəzéənə', english: 'false witness; lier', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'asha\'kə', english: 'ruined, disintegrated, broken', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'ashwə̌lə', english: 'unusual, strange', category: 'descriptive', tonePattern: 'rising'),
  AwingWord(awing: 'ateekáŋá', english: 'something very strong', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atɨəndê', english: 'first floor of a roof', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'atóomə', english: 'A long drum', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atúəsê', english: 'bag containing a dead close relation\'s (father, mother, grand mother, grand father etc) hair, worshipped periodically for appeasement', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'atsa\'áfágə', english: 'warm clothing', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atságə', english: 'bitterness, quarrelsomeness', category: 'descriptive', tonePattern: 'high'),
  AwingWord(awing: 'atságántəəmə', english: 'ill temper', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chî əshi\'nə', english: 'be healthy, be well; be save', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chigə', english: 'real, true; important', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'chigə anuə', english: 'truth; real thing', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'chigə anuə təpəŋə', english: 'terrible evil; scandal', category: 'descriptive', difficulty: 3),
  AwingWord(awing: 'chɔ́sə məfigə', english: 'false religion', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfeemá', english: 'a small stick used to facilitate wood splitting', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'Əfo Nəfəmátûə', english: 'the first fon of Awing', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əghó\'ə', english: 'a sort of large, delicious and expensive mushroom', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əka yi fîə', english: 'new testament', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əka yi lenə', english: 'old testament', category: 'descriptive', difficulty: 1),
  AwingWord(awing: 'əkwə̌nkwáŋə̂', english: 'bony', category: 'descriptive', tonePattern: 'rising'),
  AwingWord(awing: 'əlén təpəŋə', english: 'bad reputation', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əlén yi əshí\'nə', english: 'good reputation', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əli\' pipá lum nó', english: 'hot weather', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əli\' pipá nwá nó', english: 'cold weather', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əloonə', english: 'a sort of blessing invoked from the dead', category: 'descriptive', difficulty: 3),
  AwingWord(awing: 'əpábpéebá', english: 'multicoloured; spotted', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əpəgkáŋə', english: 'broken dishes; cymbals', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əpagpagə', english: 'fragmented, be in pieces; fragments, pieces', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'əpêdpələ', english: 'corrugated; furrowed', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əshí\'ó', english: 'how many', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fya\'átûə', english: 'sacrifice to the dead. People worship the dead in Awing and this against the word of God', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghelə̂ á fóomə', english: 'make smooth', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghelə̂ á kakô', english: 'make rough', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'jî ntú majîə', english: 'eat first of new crops, eat first of new fruit', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kə', english: 'marker of past tense for an event that took place a few days ago', category: 'descriptive', difficulty: 3),
  AwingWord(awing: 'káféŋə', english: 'little sorts of mushroom-like plants', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kákwumə̌kókwumə', english: 'word that describes how a foolish man moves, especially into trouble', category: 'descriptive', tonePattern: 'rising', difficulty: 3),
  AwingWord(awing: 'kəlá\'ə', english: 'marker of far past tense, used for events that take place many years back', category: 'descriptive', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'kəmkə̂', english: 'be short; short', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kápyagəkápyaga', english: 'word that describes how a foolish man moves, especially into trouble', category: 'descriptive', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'káyé', english: 'little, small', category: 'descriptive', tonePattern: 'high'),
  AwingWord(awing: 'kibu\'ləkibu\'lə', english: 'sound of movement by a fat person; word describing the way of movement by a person who is very fat', category: 'descriptive', difficulty: 3),
  AwingWord(awing: 'kóghá', english: 'a piece of rough iron used for sharpening metals eg matchetes and knifes', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwed ndotîa', english: 'empty garbage, throw away dirt', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kyíbó', english: 'a kind of basket weaved using the hard covering of raffia bamboo', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kyikâ', english: '(of babies) have the habit of refusing strangers; refuse, of many people', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'lóŋ', english: 'intensifies the idea that something is very black', category: 'descriptive', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'mǎ pətǎ pətǎ', english: 'great grandmother (paternal)', category: 'descriptive', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ma\'ô kəghoghə', english: 'give much importance to something, especially more than it is due', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mbi pəkwûə', english: 'abode of the dead', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mboŋô', english: 'many, much, a lot', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mé', english: 'big, great, important', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mé asóolə', english: 'big hoe', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mé nkeelə', english: 'big drum', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məchína nəka\'á', english: 'being together', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məfóomə', english: 'fat', category: 'descriptive', tonePattern: 'high'),
  AwingWord(awing: 'mətsəŋkeela', english: 'be globe shaped, be spherical; be round', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'mó kányaŋə', english: 'little; small', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mó nkeelə', english: 'small drum', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'môkamə', english: 'A dance group in Njom. Only young men participate', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ndɔ́', english: 'real, true', category: 'descriptive', tonePattern: 'high'),
  AwingWord(awing: 'ndǎndɔ́', english: 'real, true', category: 'descriptive', tonePattern: 'rising'),
  AwingWord(awing: 'nə', english: 'marker of past tense for an event that took place a few days ago', category: 'descriptive', difficulty: 3),
  AwingWord(awing: 'nəfoonə', english: 'fat', category: 'descriptive'),
  AwingWord(awing: 'nəkólə', english: 'quarter or small unit of administration', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəsog nó akwubə', english: 'bath room or any shade for bathing', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəténə', english: 'bottom; below', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngaŋkéebə', english: 'rich person', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngoŋə', english: 'sharp wail, ululation at funeral(n)', category: 'descriptive', difficulty: 3),
  AwingWord(awing: 'ngwəshíə', english: 'loincloth of some sort worn in the olden days, especially old women', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'njúbtə', english: 'dry. Dry corn is good for popping', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkya\'ə', english: 'light; electricity', category: 'descriptive', difficulty: 1),
  AwingWord(awing: 'nóolə akəfə́', english: 'green mamba', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nta\'lə', english: 'few, small number', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'ntsêdndzəmə', english: 'last, final', category: 'descriptive', tonePattern: 'falling'),
  AwingWord(awing: 'ntsəmə', english: 'whole, total', category: 'descriptive'),
  AwingWord(awing: 'ŋá\' nkwumə', english: 'open (box)', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'panpaŋə', english: 'red', category: 'descriptive'),
  AwingWord(awing: 'pá əshí\'á', english: 'how many?', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pətsá', english: 'attribute \'some\', modifying classes 2 and 8 nouns', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sagə', english: 'far; be long', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'shí ŋwunə', english: 'black man', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'shíshí ŋwunə', english: 'black man', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tä pətä pətä', english: 'great grandfather (paternal)', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'tä pətä yi ndza\'kə', english: 'great great grandfather (paternal)', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'tä\'lətä\'lə', english: 'word that describes how a sickly lean person moves', category: 'descriptive', difficulty: 3),
  AwingWord(awing: 'təji\'ə', english: 'alone', category: 'descriptive'),
  AwingWord(awing: 'təpəŋə', english: 'evil', category: 'descriptive', difficulty: 3),
  AwingWord(awing: 'táshúnə', english: 'so much, too much', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tû\'mândzəŋə', english: 'a secret group for men of same age group', category: 'descriptive', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tséebə ndəŋndəŋə́', english: 'be honest; speak the truth', category: 'descriptive', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsənkeelə', english: 'round; globe shaped, spherical', category: 'descriptive', difficulty: 2),
  AwingWord(awing: 'wiŋə', english: 'big; great', category: 'descriptive', difficulty: 1),

  // things (1117)
  AwingWord(awing: 'a', english: 'he, she (personal pronoun)', category: 'things'),
  AwingWord(awing: 'achábtə', english: 'dirt built up in layers on a surface, animal or body', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'achánə', english: 'act of turning away from somebody in disgust', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'acha\'tə', english: 'greetings', category: 'things', difficulty: 1),
  AwingWord(awing: 'acha\'tésê', english: 'prayers', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'acha\'tésênjiə', english: 'fasting; intensive and serious prayer', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'achəkelə', english: 'sieve', category: 'things', difficulty: 1),
  AwingWord(awing: 'achibamátéenə', english: 'cheap and undesirable products or goods', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'achíalúmə', english: 'name of a quarter in Awing', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'achiətazó\'ə', english: 'celibate, unmarried for religious reasons', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'achílə ajúmə', english: 'stopper; plug', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'achwí\'nə', english: 'unity, togetherness', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afablə', english: 'fastidiousness', category: 'things', difficulty: 1),
  AwingWord(awing: 'afa\'ə', english: 'work', category: 'things', difficulty: 1),
  AwingWord(awing: 'afa\'ə apímnə', english: 'partnership work', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afa\'ə Əsê', english: 'religious ministry, work for God', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'afanə', english: 'terrible thing; taboo', category: 'things', difficulty: 3),
  AwingWord(awing: 'afankónuə', english: 'mistake', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'afaŋŋə', english: 'embrace', category: 'things', difficulty: 1),
  AwingWord(awing: 'afeŋə', english: 'wasp', category: 'things', difficulty: 1),
  AwingWord(awing: 'afəələ', english: 'water tube used for letting water into the bowels', category: 'things', difficulty: 2),
  AwingWord(awing: 'afəələ neemə', english: 'female pig that has passed the stage of crossing', category: 'things', difficulty: 2),
  AwingWord(awing: 'afəmó', english: 'land where forefathers settled and lived', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afìə', english: 'resemblance, look very much alike', category: 'things', tonePattern: 'low', difficulty: 2),
  AwingWord(awing: 'afi\'nónkaŋə', english: 'imitation', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afo\'ə', english: 'material gain or riches', category: 'things', difficulty: 2),
  AwingWord(awing: 'afoonə ndzo\'ó', english: 'ceremony in which the bride and groom are shaved of private parts', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afúə atìə', english: 'one thousand francs CFA note (colloquial)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afúə fóolə', english: 'rat poison', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afúə məmbəmə', english: 'tablets, drugs', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afúə ndí\'ə', english: 'antidote, anti-poison', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'afunə', english: 'restlessness', category: 'things', difficulty: 1),
  AwingWord(awing: 'afunó', english: 'leopard', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aghabnə', english: 'average', category: 'things', difficulty: 1),
  AwingWord(awing: 'aghaglə', english: 'skeleton', category: 'things', difficulty: 1),
  AwingWord(awing: 'aghaglótûə', english: 'skull', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'aghántə', english: 'physical exercise', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aghə\'ə', english: 'frugality', category: 'things', difficulty: 1),
  AwingWord(awing: 'agha\'ó', english: 'cave', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aghəŋə nəságə', english: 'pudenda', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aghognə', english: 'shock, trembling; fear', category: 'things', difficulty: 2),
  AwingWord(awing: 'aghóoba', english: 'fear, trembling on hearing of death', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aghoolá atûa', english: 'dowry', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'aghoonó', english: 'illness, disease, malady', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aghoonó móghaba', english: 'sexually transmissible disease', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'agho\'tánó', english: 'pride, considering one\'s self special or more important', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aghógta', english: 'rattle (musical instrument)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ajía', english: 'his/hers, used for class 7 nouns (possessive)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ajiəmbágló', english: 'corruption', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ajíənuə', english: 'knowledge; know how; meaning', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ajíəŋwa\'lə', english: 'literacy; the knowledge to read and write', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aji\'tə', english: 'frugality, selfishness', category: 'things', difficulty: 1),
  AwingWord(awing: 'ajú yə pá\' nə', english: 'wickerwork', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ajú yə sá nə', english: 'garri (food made from cassava)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ajú yitsə', english: 'something (pronoun)', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ajuba', english: 'replica, carbon copy', category: 'things', difficulty: 2),
  AwingWord(awing: 'ajúmə əzələ', english: 'stolen goods', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ajúmə nəkwa\'ə', english: 'play instrument, toy', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ajúməsoolə', english: 'domestic animal', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ajúmətsə\'ə', english: 'handkerchief, piece of cloth', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ajwa\'áli\'ó', english: 'disappointment', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ajwelə', english: 'vapour', category: 'things', difficulty: 1),
  AwingWord(awing: 'ajwiə Əsê', english: 'the spirit of God', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ajwiŋə', english: 'link; something that links two things', category: 'things', difficulty: 2),
  AwingWord(awing: 'aka\'nə', english: 'competition', category: 'things', difficulty: 1),
  AwingWord(awing: 'akán yə shí nə', english: 'bowl', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'akáŋəsê', english: 'church offering (money or material)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akáŋətûə', english: 'helmet', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'akeelə', english: 'fence, usually of wood', category: 'things', difficulty: 2),
  AwingWord(awing: 'akeelə kwúneemə', english: 'pig sty', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akéenə', english: 'tiredness, fatigue', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akô', english: 'what (interrogative pronoun)', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'akóbka', english: 'covering (of door, cupboard, car, hut, blanket etc.)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akəghoolə', english: 'intestinal worm', category: 'things', difficulty: 1),
  AwingWord(awing: 'akəghoolámagə', english: 'conjunctivitis', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akəkógó', english: 'fool', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akəmə', english: 'piece, half (of liquids, objects etc.)', category: 'things', difficulty: 2),
  AwingWord(awing: 'akəmə ajúmə', english: 'splinter, sliver', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akəmə aŋwa\'lə', english: 'note(n), piece of writing', category: 'things', difficulty: 2),
  AwingWord(awing: 'akəmə tsáb ntê', english: 'introduction, preamble', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akəmə mbaŋə', english: 'throwing stick', category: 'things', difficulty: 1),
  AwingWord(awing: 'akəmtə', english: 'stage, phase; round; chapter (of a book)', category: 'things', difficulty: 2),
  AwingWord(awing: 'akəŋə', english: 'covering of door, cupboard, car; something that screens', category: 'things', difficulty: 2),
  AwingWord(awing: 'akəpu\'ə', english: 'fit; fainting fit', category: 'things', difficulty: 1),
  AwingWord(awing: 'akətûə', english: 'deaf person', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akǒ\'nə ləəmó', english: 'colt (young horse)', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'akǒ\'nə nkeelə', english: 'medium sized drum', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ako\'nə ndəŋə', english: 'bamboo chair', category: 'things', difficulty: 1),
  AwingWord(awing: 'akóolámáləŋə', english: 'grace, pity', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akoolənányinə', english: 'companionship', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akó\'ə', english: 'chair; throne; high office; position', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akó\'ə ndəŋə', english: 'bamboo chair', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akó\'ndê', english: 'threshold, doorstep', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akô\'kámbəəmə', english: 'fastidiousness, pride; considering one\'s self special', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akoŋə', english: 'stem, stalk (of maize, millet etc.)', category: 'things', difficulty: 2),
  AwingWord(awing: 'akoŋŋə', english: 'love, happiness, bliss of wedded couples', category: 'things', difficulty: 2),
  AwingWord(awing: 'akoŋŋəshîə', english: 'romantic love', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akoŋtə', english: 'rejoicing; festival; feast', category: 'things', difficulty: 2),
  AwingWord(awing: 'akwáakə', english: 'inflammables; something that keeps fire burning', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akwáalónkǐə', english: 'baptism', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'akwagə', english: 'phlegm', category: 'things', difficulty: 1),
  AwingWord(awing: 'akwagəntəəmə', english: 'asthmatic cough', category: 'things', difficulty: 1),
  AwingWord(awing: 'akwagətəəmə', english: 'whooping cough', category: 'things', difficulty: 1),
  AwingWord(awing: 'akwagətəfélə', english: 'whooping cough', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akwa\'lə', english: 'question; temptation; criticism; interview', category: 'things', difficulty: 2),
  AwingWord(awing: 'akwaŋ yə əshi\'nə', english: 'confidence, good thoughts', category: 'things', difficulty: 2),
  AwingWord(awing: 'akwaŋə', english: 'idea; thought; pensiveness (especially negative)', category: 'things', difficulty: 2),
  AwingWord(awing: 'akwaŋónuə', english: 'reasoning; idea; thought', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akwaŋəsê', english: 'God\'s will', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akwaŋətûə', english: 'thought; idea', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akwelə mbéŋə', english: 'flock (of sheep, goats etc.)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akwelə məneemə', english: 'herd of cattle', category: 'things', difficulty: 2),
  AwingWord(awing: 'akwelə sóŋó', english: 'crop of bird', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akwenə', english: 'collaboration', category: 'things', difficulty: 1),
  AwingWord(awing: 'akwəŋótûə', english: 'skull', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akwubə', english: 'crust, skin (of fruit)', category: 'things', difficulty: 2),
  AwingWord(awing: 'akwubə əshûə', english: 'fish-scale', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akwubə môndzó', english: 'shell (of groundnut)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akwubánô', english: 'flesh, of a living person', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akwúblə', english: 'equivalence; something to exchange or replace with; replacement', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akwu\'ló', english: 'log', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akwúláshîə', english: 'frown (noun)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akwúmtə', english: 'ceremony in memory of somebody who died; remembrance; reminder', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akyâamə', english: 'bile, gall', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akya\'óshîə', english: 'mirror (noun)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'akye\'ónuə', english: 'omen', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'akyé', english: 'jungle dweller (wicked); men living in forest attacking passers-by for money', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alabó', english: 'cloth, tied by women', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alá\'ə pəŋwiŋə', english: 'spirit world, world of the gods', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alá\'əkálá', english: 'Europe or America', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alá\'əmákálá', english: 'Europe or America', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alá\'əmátíə', english: 'name of a quarter in Awing', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alagó', english: 'scar', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alamó', english: 'body part', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alaŋnəkyîə', english: 'channel', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'alaŋəpópó\'ə', english: 'public toilet', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alě atsəmə', english: 'everyday', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'alě tsə', english: 'someday', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'alě Yésojúmnə nə nəwûə', english: 'Easter Sunday', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'aleelá', english: 'trouble', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aleemə', english: 'smithing', category: 'things', difficulty: 1),
  AwingWord(awing: 'aleeməmósóŋó', english: 'birdlime (adhesive to catch birds)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alegtə', english: 'flattery', category: 'things', difficulty: 1),
  AwingWord(awing: 'alegtəntəəmə', english: 'comfort, petting', category: 'things', difficulty: 1),
  AwingWord(awing: 'alenápíná', english: 'birthday', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aleŋ', english: 'incense', category: 'things'),
  AwingWord(awing: 'aleŋkə', english: 'mark of identification; ritual scar', category: 'things', difficulty: 3),
  AwingWord(awing: 'alědnə', english: 'wealth, property', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'alógámáfûə', english: 'sickle', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'aləgnə', english: 'forgetfulness', category: 'things', difficulty: 1),
  AwingWord(awing: 'alámbeŋə', english: 'talking drum', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aləmtə', english: 'whisper', category: 'things', difficulty: 1),
  AwingWord(awing: 'alóŋə', english: 'disease of the scalp (sticky in nature)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aləŋəlóŋənófoonə', english: 'praying mantis', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aləŋənófoonáse', english: 'God\'s throne, God\'s presence', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ali\' ghenó', english: 'here', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ali\' yə áwó', english: 'there (place that is the subject of conversation)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ali\' yîə', english: 'there (that place)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ali\'ó', english: 'place; point', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ali\'ó ghók\'ə Əsê', english: 'sanctuary; place of worship', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ali\'ó kətaŋə', english: 'emptiness, nothing, void', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ali\'ó nəfoonə Əsê', english: 'paradise', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'ali\'ófûə', english: 'traditional hospital, mostly to consult mediums', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ali\'ófya\'ónuə', english: 'ritual place', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ali\'óká', english: 'where (inter.)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ali\'əmáfênə', english: 'alter', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ali\'əmápa\'ó', english: 'toilet, WC', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ali\'əmáteenó', english: 'shop', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ali\'əmátsəŋnə', english: 'latrine', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ali\'ándəsê', english: 'land', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ali\'ənəfoonásê', english: 'throne of God, God\'s presence', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ali\'əsê', english: 'a place thought to host a god tree or cave', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ali\'ətəŋwunə', english: 'desolate or vocant place', category: 'things', difficulty: 2),
  AwingWord(awing: 'ali\'ətəpímnə', english: 'disunited place or neighbourhood', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ali\'ətûə', english: 'very close friend', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ali\'ətwíəleemə', english: 'forge', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ali\'átsêebə', english: 'statement, comment', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ali\'átsəmə', english: 'Everywhere; anywhere', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alóobə', english: 'cunning; deceit', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alóbtə', english: 'plan; estimation', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alo\'ə', english: 'deformity; curse', category: 'things', difficulty: 3),
  AwingWord(awing: 'alónə', english: 'begging', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alubə', english: 'drasina', category: 'things', difficulty: 1),
  AwingWord(awing: 'alúə', english: 'goose', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alu\'á', english: 'lumbago (muscular pain of the lumbar regions, of an illness)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'alwaalə', english: 'palate', category: 'things', difficulty: 1),
  AwingWord(awing: 'alwe', english: 'filaria', category: 'things', difficulty: 1),
  AwingWord(awing: 'alya\'ə', english: 'description', category: 'things', difficulty: 1),
  AwingWord(awing: 'ama\'ə', english: 'gift, especially to a customer to encourage him', category: 'things', difficulty: 2),
  AwingWord(awing: 'ambáŋá', english: 'a flip over', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ambo\'ə', english: 'elephantiasis', category: 'things', difficulty: 1),
  AwingWord(awing: 'amɨ\'ə', english: 'dew', category: 'things', difficulty: 1),
  AwingWord(awing: 'ándó', english: 'approximately; like, as', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ándó móonə', english: 'childishly', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'anəələ', english: 'dedication, presentation', category: 'things'),
  AwingWord(awing: 'anəəlághoonə', english: 'symptom of disease', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'anəəlámbəəmə', english: 'pride', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'anəné', english: 'Money of the smallest value', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ánónə', english: 'exactly', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'antsĕ', english: 'whistle for refereeing a football match', category: 'things', difficulty: 2),
  AwingWord(awing: 'anuə', english: 'something; concern', category: 'things', difficulty: 1),
  AwingWord(awing: 'anuə əshunə', english: 'partnership', category: 'things', difficulty: 1),
  AwingWord(awing: 'anuə nəfoonə', english: 'kingdom of', category: 'things'),
  AwingWord(awing: 'anuə ŋwu ntsəmə', english: 'event that involves everybody', category: 'things', difficulty: 2),
  AwingWord(awing: 'anüəngi\'tə', english: 'something urgent', category: 'things'),
  AwingWord(awing: 'anuəsê', english: 'christianity; religion', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'anuətájiə', english: 'mystery', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'anuətámə', english: 'habit', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'anuyəfíə', english: 'fashion', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'anyaŋgá', english: 'decoration, embellishment', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'anyiŋə apô', english: 'fingernail. A finger nail beautifies somebody', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'anyíŋnə', english: 'emotional instability', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'anatə', english: 'pride', category: 'things', difficulty: 1),
  AwingWord(awing: 'aŋkəndó\'á', english: 'galore, medal', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aŋkənu\'á', english: 'canoe', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aŋkəŋâ', english: 'dove', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'aŋo\'tə', english: 'frugality', category: 'things', difficulty: 1),
  AwingWord(awing: 'aŋwa\'lə', english: 'book; knowledge', category: 'things', difficulty: 2),
  AwingWord(awing: 'aŋwa\'lósê', english: 'scripture; bible', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'apádnə', english: 'acquaintance', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apadtəmóonə', english: 'baby sling', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apa\'ándê', english: 'door', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'apagó atsə\'ó', english: 'a piece of cloth', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apanə', english: 'hook', category: 'things', difficulty: 1),
  AwingWord(awing: 'ape', english: 'profit', category: 'things', difficulty: 1),
  AwingWord(awing: 'ape\'ə', english: 'load, burden, belongings', category: 'things', difficulty: 2),
  AwingWord(awing: 'apeŋə', english: 'outside', category: 'things', difficulty: 1),
  AwingWord(awing: 'apélə', english: 'pit', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apélə nkɨə', english: 'waterhole, fountain or any hole that gushes out water; well', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apenə', english: 'scar', category: 'things', difficulty: 1),
  AwingWord(awing: 'apəabə', english: 'he-goat, billy goat', category: 'things', difficulty: 2),
  AwingWord(awing: 'apəəmə', english: 'hunt', category: 'things', difficulty: 1),
  AwingWord(awing: 'apimnə', english: 'agreement', category: 'things', difficulty: 1),
  AwingWord(awing: 'apinə', english: 'curse', category: 'things', difficulty: 3),
  AwingWord(awing: 'apitə', english: 'request, question', category: 'things', difficulty: 1),
  AwingWord(awing: 'apitə atsêebə', english: 'question', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'apó\'ámbó', english: 'supplication, plea', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'apó\'ámóonə', english: 'circumcision (male). Circumcision is no longer an acceptable thing in the world today', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apoomə', english: 'covering (especially of leaves or clothing) against the sun, rain or destruction', category: 'things', difficulty: 2),
  AwingWord(awing: 'apógə', english: 'fear', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apəŋəntəəmə', english: 'Grace; pity', category: 'things', difficulty: 2),
  AwingWord(awing: 'apəŋətûə', english: 'luck, fortune', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'apu\'ə', english: 'left over', category: 'things', difficulty: 1),
  AwingWord(awing: 'apúmnə', english: 'worry, restlessness', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'apútə', english: 'complaint, especially in court', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'asá\'ə', english: 'command', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'asá\'ónuə', english: 'announcement, public announcement (usually in the market)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'asagó', english: 'wall, of a house', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'asagándê', english: 'wall, of a house', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'asaŋó', english: 'tail', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aseelósêela', english: 'sideward', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'aseemə', english: 'a site where mushrooms grow', category: 'things', difficulty: 2),
  AwingWord(awing: 'asədkátsêebə', english: 'translation. It is good to know how to translate', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'asêkátsə\'ó', english: 'rag. A rag is used to clean a cemented floor', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'asəələkwúneemə', english: 'a castrated pig', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'asəkə', english: 'exageration, giving of false value', category: 'things', difficulty: 2),
  AwingWord(awing: 'asəmə', english: 'swarm', category: 'things', difficulty: 1),
  AwingWord(awing: 'asogəmáyéŋ', english: 'wild beast (used as an insult)', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'asóŋətəfa\'ə', english: 'hypocrite, pretentious person', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'asobnə', english: 'worry, sadness', category: 'things', difficulty: 1),
  AwingWord(awing: 'ashaabə', english: 'comb', category: 'things', difficulty: 1),
  AwingWord(awing: 'ashǎdnə akáŋə', english: 'plate. A plate is not good for dishing soup', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ashi\'nə', english: 'trade. People trade food when they do not have money to buy it', category: 'things', difficulty: 2),
  AwingWord(awing: 'ashwadkə', english: 'exageration, giving of false value', category: 'things', difficulty: 2),
  AwingWord(awing: 'ashwěnuə', english: 'a failure, a missed opportunity. This act is really a failure', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ashwí\'ə', english: 'swelling', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atálə', english: 'a courtyard in the palace where the fon sits with his subjects to debate issues', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atáŋə', english: 'mathematical problem, mathematical sum', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ataŋmóonə', english: 'a disease that makes babies to grow pale', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atáŋkə mbəəmə', english: 'wrinkle (on skin); wrinkled skin', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atéemə', english: 'dangerous pit or hole', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'aténkə', english: 'support', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atəələ', english: 'pride', category: 'things', difficulty: 1),
  AwingWord(awing: 'atəəmə', english: 'calabash', category: 'things', difficulty: 1),
  AwingWord(awing: 'atəənə', english: 'iron; trap (usually made of iron or metal)', category: 'things', difficulty: 2),
  AwingWord(awing: 'atandó\'ə', english: 'ball. Apise plays football', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atashiə', english: 'thread', category: 'things', difficulty: 1),
  AwingWord(awing: 'atátá', english: 'courtyard', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atata\'ə', english: 'snail', category: 'things', difficulty: 1),
  AwingWord(awing: 'atatsələ', english: 'insect', category: 'things', difficulty: 1),
  AwingWord(awing: 'atɨə', english: 'above, up', category: 'things', difficulty: 3),
  AwingWord(awing: 'atɨə awaglə', english: 'a boundary stick', category: 'things', difficulty: 2),
  AwingWord(awing: 'atɨəpéŋá', english: 'second floor of a roof. Awing people dry corn on the second floor of the roof', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ató\'nónkonə', english: 'hump (of hunchback). The hunchback of cattle is very tasty', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atoŋátóŋə', english: 'upside down', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atóonə', english: 'impatience', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atógə əkwunə', english: 'bedroom. The bedroom is private', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atómtə', english: 'reason; justification', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ato\'nə', english: 'prophecy', category: 'things', difficulty: 1),
  AwingWord(awing: 'atú yə júm ná', english: 'wakefulness, alertness', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atú yə ŋa\'nə ná', english: 'intelligence, high learning ability', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atú yə pó\' ná', english: 'headache. Headache is frequent in the dry season', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atú yə tsə́\'nə ná', english: 'intelligence, high learning ability', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atúəfa\'ə', english: 'occupation, job', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atúəndê', english: 'roof of a house. The most important thing for the roof of a house is the zinc', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'atúənápe', english: 'side pain. Side pain is an illness of elderly people', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atúənósénə', english: 'frontal headache. frontal headache causes blood to flow from one\'s nose', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atsa\'ə amú\'á', english: 'regime (of banana). A regime of banana is much cheaper in Awing than in all other places', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atsa\'ənákəŋə', english: 'clay. Clay is sticky', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atsámnə', english: 'sigh', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'atsá\'nə', english: 'greed', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atsaŋá', english: 'stem, of banana', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atséebə', english: 'language; word', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atséebámakálə', english: 'English language', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atséebámənŋeemə', english: 'joke, play talk', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atséebándzəmándzəmə', english: 'gossip', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atséebánákwa\'ə', english: 'joke, humour', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atséebánámú\'á', english: 'parable; proverb', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atséebápəfipámbô', english: 'sign language', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'atséebásê', english: 'gospel; word of God', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'atseŋə', english: 'bladder', category: 'things', difficulty: 1),
  AwingWord(awing: 'atselə', english: 'peg', category: 'things', difficulty: 1),
  AwingWord(awing: 'atsa\'á', english: 'clothes', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atsa\'á mako\'ná', english: 'shirt. Shirts are usually worn by men', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atsə\'kə', english: 'criticism, the act of deminishing the value of something, the act of making something appear less important', category: 'things', difficulty: 2),
  AwingWord(awing: 'atsəmə', english: 'whichever. Bring whichever you like', category: 'things', difficulty: 2),
  AwingWord(awing: 'atsəmətsəmə', english: 'total. The total is what', category: 'things', difficulty: 2),
  AwingWord(awing: 'atsóobə', english: 'fine or levy for commiting a crime', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'atsóokámbəəmə', english: 'humility', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'awaamə', english: 'handle', category: 'things', difficulty: 1),
  AwingWord(awing: 'awaamámbəəmə', english: 'self control; patience', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'awaamətəmedtə', english: 'faithful person; patient person', category: 'things', difficulty: 2),
  AwingWord(awing: 'awágə', english: 'a belittling; mockery', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'awágnə', english: 'carelessness, neglect', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'awakántəəmə', english: 'loose and shameless behaviour', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'awé\'ə', english: 'curse', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'awelə', english: 'mixture', category: 'things', difficulty: 1),
  AwingWord(awing: 'awelówelə', english: 'assorted, variety', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'awěnkɨə', english: 'A women dance group in Akuhle quarter, based in Tata Mofolo\'s compound', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'awəgə', english: 'bellow', category: 'things', difficulty: 1),
  AwingWord(awing: 'awəgáfágə', english: 'fan. A fan is necessary when there is heat', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'awə́\'tə', english: 'reminder', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'awuəmátéenə', english: 'something in less demand or cheap', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'awüənuə', english: 'mistake, fault', category: 'things', difficulty: 1),
  AwingWord(awing: 'awǔ\'nə', english: 'covering for anything', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ayè\'tə', english: 'frugality', category: 'things', tonePattern: 'low', difficulty: 2),
  AwingWord(awing: 'ayéékálí\'ó', english: 'disturbance, disorder', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ayéelə', english: 'confusion, disorder', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ayélə', english: 'exclamation, surprise', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azagá', english: 'odour, smell', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azáŋándé', english: 'anger', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azáŋkómbəəmə', english: 'physical exercise', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azéemə', english: 'possessive pronoun \'mine\', used for class 7 nouns. Where is my own plum?', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azénə', english: 'possessive pronoun \'ours\' used for nouns of class 7', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azə́ənə', english: 'possessive plural pronoun \'yours\' used for class 7 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azú\'kə', english: 'surty, guarantee', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azəŋtə', english: 'imbecile, fool, stupid person', category: 'things', difficulty: 2),
  AwingWord(awing: 'azó', english: 'possessive singular pronoun \'yours\' used for class 7 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azó\'ámakálá', english: 'mbecile, fool, stupid person. A sort of yam that originated from Ibo land in Nigeria', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'azoŋə', english: 'junior', category: 'things', difficulty: 1),
  AwingWord(awing: 'azoobə', english: 'song, singing', category: 'things', difficulty: 1),
  AwingWord(awing: 'azoomə', english: 'plum', category: 'things', difficulty: 1),
  AwingWord(awing: 'azəgə', english: 'Lie that is told with a lot of passion and without remorse', category: 'things', difficulty: 2),
  AwingWord(awing: 'azəŋə', english: 'argument, disunity', category: 'things', difficulty: 1),
  AwingWord(awing: 'bâ', english: 'bar. Some people stay in the bar for the whole day', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'báabəələ', english: 'Bible or the word of God. The word of God is called a Bible', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'bǎbtísə', english: 'baptist, refering to a christian denomination and also to those who belong to it', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'bándéchə', english: 'bandage', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'báŋə', english: 'bank. A bank is a place where we keep money', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'bəláibə', english: 'bribe', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'bəlégə', english: 'break. All school children take break period', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'bôm', english: 'sound that describes a start or sudden wake up', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'bîm', english: 'sound that describes something that is fall. When a fat person falls on the ground, he falls thump', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'bíshobə', english: 'bishop. A bishop is a high ranking person in the church', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'bílɨ', english: 'sound of movement by a group or herd of cattle', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'blêmə', english: 'blame', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'bóbə', english: 'bulb', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'bûm', english: 'word that intensifies the sound of a traditionally made gun, or of something falling', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'búsbágə', english: 'hump (of cow). The hump (of cow) is a choiced morsel', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'châgchagchag', english: 'sound (word) that describes the dropping of water', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'cha\'tə̂ nəwûə', english: 'condole, comfort', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'cha\'tásê', english: 'pray. Pray, if you want to succeed in all your endeavours', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chê\'', english: 'sound (word) that intensifies the smooth or oily nature of something', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'chî kókánə́', english: 'be unhealthy, be sick; be uncomfortable', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîı', english: 'marker of negation. If a man does not marry, he is called a bachelor', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chîə natûə', english: 'rule over, dominate', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chígchəgchígchəg', english: 'sound (word) that tells how a bird cries', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'chigə nó ndəlá', english: 'exactly on time', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chipó\'ə́', english: 'mute, less excited person, too calm a person', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chí\'tôglə', english: 'fungi, eaten as food', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'chɔ́gə', english: 'chalk', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chɔ́sə mbəláló\'ə́', english: 'islam; mosque', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chuchuə', english: 'gossip', category: 'things'),
  AwingWord(awing: 'chúu', english: 'intensifies the smelling nature of something', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'chwántə́ nkiə', english: 'brook, stream', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'chwî\'', english: 'sound (word) that intensifies the bitterness of something', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'chwíŋ', english: 'sound (word) that intensifies the sourness of something', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'chwí\'túə', english: 'cooperate; share ideas', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ě', english: 'utterance that indicates that one has been making a mistake', category: 'things', tonePattern: 'rising', difficulty: 3),
  AwingWord(awing: 'élə', english: 'aids', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ə́', english: 'they, it, thing in question or talked about', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ə̂\'ə', english: 'no', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əfag ndúmə', english: 'fork (in path)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfeŋ', english: 'in this compound, this place, here (nominal)', category: 'things', difficulty: 2),
  AwingWord(awing: 'əfeŋ məlá\'ə', english: 'roofer of thatched houses', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfeŋə', english: 'roofer of thatched houses', category: 'things', difficulty: 2),
  AwingWord(awing: 'əfê', english: 'giver', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əfédndê', english: 'the secret meaning behind something', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əfédndê atseebə', english: 'speech with lots of terminology', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əfédndzɔ\'ə', english: 'divorcee', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfelə', english: 'appearance', category: 'things'),
  AwingWord(awing: 'əfəblə', english: 'lungs, especially of animals', category: 'things', difficulty: 2),
  AwingWord(awing: 'əfəənə́', english: 'shin', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfəmá', english: 'mold', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfəŋə́', english: 'a hole on the body caused by accident or illness', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfi məjîə', english: 'restaurant dealer', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əfi ndasê', english: 'real estate agent; somebody who sells land', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əfi ngɔŋə', english: 'traitor', category: 'things', difficulty: 1),
  AwingWord(awing: 'Əfo Akófo', english: 'the ninth fon of Awing', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'Əfo Alôndzá I', english: 'fourth fon of Awing', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'Əfo Alôndzá II', english: 'the eighth fon of Awing', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'Əfo Ayáfo', english: 'the eleventh fon of Awing (disappeared 1950)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'Əfo Əfoozó I', english: 'the tenth fon of Awing', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'Əfo Əfoozó II', english: 'the thirteenth fon of Awing (enthroned 4th may 1998)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'Əfo Məfumánəngoomá', english: 'the second fon of Awing', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfo najîa', english: 'glutton, heavy eater', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'Əfo Ngôngá\' I', english: 'third fon of Awing', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'Əfo Ngôngá\' II', english: 'the sixth fon of Awing', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'Əfo Ngôngá\' III', english: 'the twelfth fon of Awing (1950 to 1998)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'Əfo Nká\'ŋngwé', english: 'the fifth fon of Awing', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'Əfo Nká\'fo', english: 'the seventh fon of Awing', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfó\'ə', english: 'gutter, deep place or thing', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfóŋə', english: 'reader or somebody who reads', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfoonpalê', english: 'somebody with a sleep addiction', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'Əfoontó\'ə', english: 'name of the fon, used only by the young and unmarried', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əfoopəfo', english: 'sovereign; almighty', category: 'things', difficulty: 1),
  AwingWord(awing: 'əfwoŋə', english: 'ox', category: 'things', difficulty: 1),
  AwingWord(awing: 'əghâ akə', english: 'when?, what time', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əghâ atsəmə', english: 'always', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əghâ aghâ', english: 'irregularly; from time to time', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əghâ ghená', english: 'now', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əghâ nda\'ə', english: 'another time', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əghâ njia', english: 'time of famine', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əghâ pipó ní nó', english: 'often, most of the time', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əghâ wá\'ó', english: 'time of famine', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əghâ yi wá', english: 'then, that moment', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əghâ yîə', english: 'later, in the near future (limited to a day)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əghâ yitsə̌', english: 'sometimes', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'əghəənə', english: 'friendship', category: 'things', difficulty: 1),
  AwingWord(awing: 'əghəmə', english: 'fig (tree)', category: 'things', difficulty: 1),
  AwingWord(awing: 'əgho', english: 'possessive pronoun yours (used for nouns of class 3)', category: 'things', difficulty: 2),
  AwingWord(awing: 'əghoobá', english: 'possessive pronoun \'theirs\' used for class 1 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əghə̂', english: 'reflexive pronoun ours (exclusive). Used specifically for class 3 nouns', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əjîə', english: 'possessive pronoun his/hers (used for nouns of class 9)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əkeelə', english: 'frugality, stinginess, a desire not to share', category: 'things', difficulty: 2),
  AwingWord(awing: 'əkeenə', english: 'oath; covenant', category: 'things', difficulty: 2),
  AwingWord(awing: 'əkəəbə', english: 'indian bamboo ropes', category: 'things', difficulty: 3),
  AwingWord(awing: 'əkəkə́\'lápúmə', english: 'trash; scrap', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əkəmə́', english: 'nobleship', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əkogə́', english: 'widowhood', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əkwubə', english: 'frugality', category: 'things', difficulty: 1),
  AwingWord(awing: 'ə́lá ndê', english: 'wall of a house', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ólé', english: 'how? (interrogative)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əlénə', english: 'name; reputation', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əléna ajúmə', english: 'noun', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əli\' pipá jum nó', english: 'drought, famine', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əli\' pipá nwa\' nó', english: 'daylight', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əlimə́ afa\'ə', english: 'working relationship', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ələŋə', english: 'laziness', category: 'things', difficulty: 1),
  AwingWord(awing: 'əma\' pó\'ə', english: 'story teller', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ənáŋnə majîə', english: 'cook', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ənoonə', english: 'crowd', category: 'things', difficulty: 1),
  AwingWord(awing: 'ənɔ̌ fúto', english: 'photographer', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ənu kətaŋə', english: 'meaningless thing; useless idea', category: 'things', difficulty: 2),
  AwingWord(awing: 'əŋǎ\'pilô', english: 'giant; boaster', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'əŋwa\'lə əŋwa\'lə', english: 'secretary, typist', category: 'things', difficulty: 1),
  AwingWord(awing: 'əŋwa\'lə nkeebə', english: 'treasurer; accountant', category: 'things', difficulty: 1),
  AwingWord(awing: 'əpəgpúmə', english: 'scrap; metal waste', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əpénə', english: 'possessive adjective ours (inclusive). Used for nouns of class 5', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əpééná', english: 'possessive plural adjective \'yours\', used for nouns of class 8', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əpiə', english: 'possessive adjective his/hers, used for nouns of class 8', category: 'things', difficulty: 2),
  AwingWord(awing: 'əpô', english: 'possessive singular pronoun yours, used for nouns of class 8', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əpóobá', english: 'possessive adjective theirs, used for nouns of class 8', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əpoŋə', english: 'goodness', category: 'things', difficulty: 1),
  AwingWord(awing: 'əpûmbîə', english: 'wealth, worldly things', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əpúmáfa\'ə', english: 'scaffolding', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əpúmógə', english: 'looking glasses', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'əpûngɔŋə', english: 'common property; public property', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əpûntéelə', english: 'Lord\'s Supper article', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əpûtsəmə', english: 'everything', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əsa\'ə', english: 'shoot', category: 'things', difficulty: 1),
  AwingWord(awing: 'əsá\'mánumə', english: 'east; sunrise', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əsəpó\'á', english: 'something that is cheap or free of charge', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əsê', english: 'god; fetish (spirit)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'Əsê nəpóolə', english: 'God (the one who has created everything on earth); supreme being', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əséenə', english: 'crevice', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əsenə́', english: 'venom (of snake), stinger', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əsəənə', english: 'shame', category: 'things', difficulty: 1),
  AwingWord(awing: 'əsóomə', english: 'destruction that springs from jealousy, envy, or simply an evil heart, ill-will', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əsoŋ nkadtə', english: 'spine, backbone', category: 'things', difficulty: 1),
  AwingWord(awing: 'əshîə', english: 'appearance', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'əshí\'nə', english: '1) goodness, kindness', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əshúmə̌fágə', english: 'mudfish', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'əshwáŋə', english: 'track (of animal)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ətéelə', english: 'a sort of mushroom', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əwə', english: 'who?', category: 'things', difficulty: 1),
  AwingWord(awing: 'əwəənə́', english: 'possessive pronoun \'yours\', used to modify nouns of class 1', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əwəgə́', english: 'possessive pronoun \'ours\' used for class 1 nouns; possessive adj \'our\' used for class 1 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əwágó', english: 'possessive pronoun \'ours\' used for class 3 nouns; possessive adj \'our\' used for class 3 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əyîə', english: 'possessive pronoun \'hers\' used for class 1 nouns', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'əzeemə', english: 'possessive pronoun \'mine\' used for class 9 nouns', category: 'things', difficulty: 2),
  AwingWord(awing: 'əzəəná', english: 'yours (pl)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əzəgá', english: 'possessive pronoun \'ours\' used for nouns of class 9; possessive adj \'our\' used for nouns of class 9', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əzələ', english: 'theft', category: 'things', difficulty: 1),
  AwingWord(awing: 'əzo', english: 'possessive singular pronoun \'yours\' used for class 9 nouns', category: 'things', difficulty: 2),
  AwingWord(awing: 'əzoobá', english: 'possessive pronoun \'theirs\' used for class 9 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'əzooná', english: 'yesterday', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'fê atsámə', english: 'punish. A person is only punished when he does something wrong', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fê mbwódnə', english: 'bless. If God is pleased with somebody, he gives him peace', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'fê ndǎ', english: 'congratulate. People should learn to say \'thank you\'', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'féenkǐə', english: 'baptise', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'felə ali\'ó', english: 'move away, migrate', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fágəndi\'ə', english: 'antidote, anti-poison', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'Fəlénchə', english: 'French. People who live in Douala speak French', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fəŋ', english: 'sound (word) reinforcing an act of acceptance that is done without any thought or interest', category: 'things', difficulty: 3),
  AwingWord(awing: 'fig mbəəmə', english: 'pretend. A person decieves himself thinking that he has decieved somebody else', category: 'things', difficulty: 2),
  AwingWord(awing: 'fógə təpəŋə', english: 'exorcise. Evil cannot be used to ward off evil', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fôo', english: 'sound (word) that describes a deep breath', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'fu\' mbélə', english: 'dung beetle. Dung beetles are usually found in cow dung', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'fwə\'ə', english: 'chisel', category: 'things', difficulty: 1),
  AwingWord(awing: 'fyaabə', english: 'a piece of stick or iron used for controling embers, also a piece of stick used for disposing of th harmful or unwanted', category: 'things', difficulty: 2),
  AwingWord(awing: 'fya\'ə̂ anuə', english: 'pour libation. People pour libation on the fourth day of the Awing week', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'gélə', english: 'gate', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'gôlə', english: 'gold', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghâ', english: 'word used at the end of an expression to mark exclamation', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghen ná mbia', english: 'continue, go ahead', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ghenə̂', english: 'demonstrative adjective \'this\' for nouns of classes one and three', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghenkə̂ ndəlá', english: 'waste time', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghídntəŋə̂', english: 'hiccough', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ghôo', english: 'sound (word) that describes something spilling on the ground', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'Íslələ', english: 'Israel (from English)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'jéntailə', english: 'gentile (from English)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ká ajúmə', english: 'nothing', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ká ŋwunə', english: 'nobody', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kánáda', english: 'women dance group (originally based in Tata Alota\'s compound, no longer active)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kě', english: 'marker of negation', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ká\' nəsoŋá', english: 'laugh in a wild manner', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kəənə', english: 'whether, if', category: 'things', difficulty: 3),
  AwingWord(awing: 'kaghoghə', english: 'integrity, importance', category: 'things'),
  AwingWord(awing: 'kákáŋə́', english: 'poorly', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kəlo\'', english: 'sound that describes or intensifies the manner in which something falls', category: 'things', difficulty: 3),
  AwingWord(awing: 'kəlo\'ko\'', english: 'sound that describes or intensifies the manner in which something falls', category: 'things', difficulty: 3),
  AwingWord(awing: 'kəlɔ\'kɔ\'', english: 'sound that describes or intensifies the manner in which something is falling', category: 'things', difficulty: 3),
  AwingWord(awing: 'kəmú\'ntəŋə', english: '(entry continues to next page)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ká\'tátíə', english: 'kingfisher (bird that makes a cutting sound on a tree)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'káyé məŋgo\'ə', english: 'gravel', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ki', english: 'or, either', category: 'things', difficulty: 3),
  AwingWord(awing: 'kí mbi', english: 'again, once more', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kí\'ə', english: 'obstruction; obstruction', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kíghálágháalə', english: 'butterfly', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kíghidghaabə', english: 'cartilage', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kíkəm ŋwunə', english: 'dwarf', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kíkəmə ajîə', english: 'shortsightedness (a shortsighted person is not different from a fool)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kílelónkaŋə̂', english: 'spider', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kíláglakəmósaŋə', english: 'gecko', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kimbó\'nkonə', english: 'zebra', category: 'things', tonePattern: 'high', difficulty: 2),

  AwingWord(awing: 'klóbə', english: 'women dance group based in Tata Ngonyo\'s compound (from English)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kə\'', english: 'word that intensifies the hardness of something', category: 'things', difficulty: 3),
  AwingWord(awing: 'kó əpúmə', english: 'work wood (Afese\'s job is wood work)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kó\'ó', english: 'ladder', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'kəŋ', english: 'intensifies the strongness of something (something is usually strong \'kong\')', category: 'things', difficulty: 3),
  AwingWord(awing: 'kəŋ məŋkwâ\'lə', english: 'desert (nothing grows in a desert)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kəŋ nəyeŋə', english: 'grassland (feeding ground for cattle)', category: 'things', difficulty: 2),
  AwingWord(awing: 'kəŋ yi njùbtə', english: 'desert', category: 'things', tonePattern: 'low', difficulty: 2),
  AwingWord(awing: 'kótinə', english: 'cotton (from English)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwá mbiə', english: 'lead; be first', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwákwá', english: 'a dance group in Tame Fonka\'s compound', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwâŋ', english: 'intensifies the cleanliness of something', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'kwaŋ kákáŋə̂', english: 'hesitate (when an evil doer hesitates in his plans, it demonstrates the voice of God)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'kwêd', english: 'sound (word) that describes the immediacy with which a stop is made', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'kwə\'ə̂', english: 'namesake', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'kwíŋə mə́ ŋwíŋə', english: 'sharpen a knife', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwud nká\'ə', english: 'build a fence', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'kwúlə akálé', english: 'dress smartly, dress in nice fitting attires', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'láalé', english: 'jigger', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'laŋkô ndelô', english: 'entertain, amuse', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'légə á ndu mbumá', english: 'incubate, set on eggs', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'lə', english: 'but', category: 'things', difficulty: 3),
  AwingWord(awing: 'ləba', english: 'rubber', category: 'things'),
  AwingWord(awing: 'ləəmó koŋ yi njùbtə', english: 'camel', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ləg əkeenə', english: 'take an oath', category: 'things', difficulty: 2),
  AwingWord(awing: 'lóg nələgə', english: 'wink (of eye)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'láglələglə', english: 'word that describes how a snake moves or how something else moves like a snake', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'ləzámə', english: 'exam', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'lá əsê', english: 'rise up (intr)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ló nkéebə', english: 'beg for money', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'lókə', english: 'lock', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'lókiə', english: 'luck', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ma\' nkó\'ə', english: 'decorate, make something flowerish or beautiful', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mǎ pəmá', english: 'grandmother (maternal)', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'mǎ pətǎ', english: 'grandmother (paternal)', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'mǎ pətǎ yi ndzá\'kə', english: 'grandmother of someone', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ma\'ô atsə\'ə', english: 'wear clothes, dress up', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mângasá', english: 'Women dance group based in Sam Sunyewe\'s compound', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'maŋ cha\'tô', english: 'greetings', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'maŋə', english: 'he/him pronoun', category: 'things'),
  AwingWord(awing: 'mbagə aləmə', english: 'A dance group in Tame Efoomba\'s compound', category: 'things', difficulty: 2),
  AwingWord(awing: 'mbě ndumó', english: 'mole', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'mbáʔə', english: 'lump (of clay or mud)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mbǎəmə', english: 'body; self', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'mbôláʔə', english: 'proverb, wise saying, idiomatic expression', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mbi ndê', english: 'floor', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mbi yi ntsɛɛmbia', english: 'olden times', category: 'things', difficulty: 1),
  AwingWord(awing: 'mbimâ', english: 'believe', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'mbi yi ńdzáŋnə', english: 'pain', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'mbifúə', english: 'cowrie shell', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'Mbîwiŋə', english: 'Awing', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mbo\'â', english: 'circumcision (male)', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'mbô\'máwúmó', english: 'eagle', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mbô\'móonə', english: 'the manner of circumcising, the way in which circumcision is done', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mbô\'nəntsoolə', english: 'soldier, army officer', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mbəba akoolə', english: 'footprint (of man or animal)', category: 'things', difficulty: 2),
  AwingWord(awing: 'mbo\'ə', english: 'if', category: 'things', difficulty: 3),
  AwingWord(awing: 'mbyáabə', english: 'guard', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'mé fia apô', english: '(continues on next page)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mé ghagə́', english: '(continuation) thumb', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'méd mánumə', english: 'west; sunset', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'méná', english: 'a word that is used before numbers that modify class six nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mə', english: 'my', category: 'things', difficulty: 1),
  AwingWord(awing: 'mó', english: 'the infinitive \'to\'', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'məchína təzá\'ə', english: 'celibacy', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'máəló', english: 'demonstrative pronoun \'it\' used for nouns of class six', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məəná', english: 'demontrative adj \'this\', used for nouns of class six', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məfênə', english: 'giving; offering', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məfu\'ə', english: 'foam', category: 'things'),
  AwingWord(awing: 'mág mó əfo', english: 'somebody who investigates issues and report to the fon', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məgtə azonə̂', english: 'settle dispute', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mâghaba', english: 'adultry', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məghám mém mbê nə nəkwa', english: 'twenty-four (24)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məghám mém mbê nə tá\'ə', english: 'twenty-one (21)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məghó\'kənə', english: 'worship; worshipping', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məkálé', english: 'English language', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'məkeemə̂', english: 'gun powder', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'məko\'nə̂', english: 'north', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'məkwú má akokíə', english: 'cowpies', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'mókwúbla', english: 'shelter', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'məkwúblənə', english: 'repentance; repenting', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məkwumə́', english: 'masquerader, dance group uniquely made up of men and totally veiled', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məleemə', english: 'deception, deceit', category: 'things'),
  AwingWord(awing: 'məláŋə', english: 'sorrow, pity', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'məlo\' má tyantə̂ nə̂', english: 'alcohol (general)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məlóŋ má atîa', english: 'sap', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məm nəpóola', english: 'heaven', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məméema', english: 'possessive pronoun \'mine\' used for class 6 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mámé yi ndzá\'ka', english: 'grandmother (maternal)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məméənə', english: 'possessive pronoun plural \'yours\' used for class 6 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məmía', english: 'possessive pronoun \'his\' used for class 6 nouns; possessive pronoun hers, used for class 6 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məmô', english: 'possessive pronoun singular \'yours\' used for class 6 nouns', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'məmóoba', english: 'possessive pronoun \'theirs\' used for class 6 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'manganə', english: 'charm (fetish)', category: 'things'),
  AwingWord(awing: 'mángâsé', english: 'scorpion', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'manoŋ má mbéŋa', english: 'wool', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'manoŋ má ndě má neemə', english: 'mane', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'manoŋ má neemə', english: 'fur', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məntalása', english: 'matress', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'mankálə', english: 'pap; mushy food', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'manwâ\'na', english: 'cleanliness; holiness', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mápə́ŋə́ fláwa', english: 'bud', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mápə́ŋə́ móona', english: 'foetus', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məso\'ə', english: 'robe of honour and respect for men', category: 'things', difficulty: 2),
  AwingWord(awing: 'mətəənə', english: 'strength', category: 'things'),
  AwingWord(awing: 'mətágna mangyè', english: 'being engaged, being betrothed', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'məti má nkîa', english: 'current, of water; wave of water', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mətoŋə̂', english: 'down, south', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'mətoŋŋə̂', english: 'down, South', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'mótwe\'á', english: 'caterpillar', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'mətwâŋnə', english: 'burial, burying', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'mətsá', english: 'attribute \'certain\', modifying nouns of class 6; attribute \'some\', modifying nouns of class 6', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mîa', english: 'demonstrative adj \'those\', modifies nouns of class six', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mó kwúneemə', english: 'piglet', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mó mangyè', english: 'bride; girl, little girl', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mó natûə', english: 'firstborn', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mó ngába', english: 'chick', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mó ntîə', english: 'orphan', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'mó ŋwíŋə', english: 'knife', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'mo\'ə̂', english: '(not given)', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'na mbǎəmə', english: 'human flesh, \'meat of body\'', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'na məyeŋə', english: 'wild animal', category: 'things'),
  AwingWord(awing: 'na nəyeŋə̂', english: 'wild animal', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'náŋ mbiə', english: 'hope, be optimistic', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nátíbə', english: 'native', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ncha\'tə əsê', english: 'spiritual healer, somebody who heals through prayers', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nchîə', english: 'soot', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'nchílə', english: 'Women dance group in Njom, no longer active, but still have their drums and other things', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nchîmbîə', english: 'life, living', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nchwadkə̂', english: 'salvation', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'nchwá\'ə', english: 'subscription, tontine', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nchwiga', english: 'spy', category: 'things'),
  AwingWord(awing: 'ndadkándadka', english: 'continously, non-stop', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nda\'ə', english: 'only, lone', category: 'things', difficulty: 1),
  AwingWord(awing: 'nda\'nə', english: 'promise', category: 'things'),
  AwingWord(awing: 'ndě yi mbwódta nə̂', english: 'nausea', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ndé\'ə', english: 'necklace', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ndé\'nə', english: 'spare, something that has not got a partner', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ndě melo\'ə', english: 'bar, drinking spot', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ndě móga', english: 'kitchen', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ndě móona', english: 'birth ceremony, naming ceremony', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ndedta', english: 'frontier (of ethnic area); boundary', category: 'things', difficulty: 2),
  AwingWord(awing: 'ndeela', english: 'A sort of feast celebrated by Bororos', category: 'things', difficulty: 2),
  AwingWord(awing: 'ndelə̂', english: 'time', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'ndámə', english: 'wire', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ndaŋə', english: 'bamboo', category: 'things'),
  AwingWord(awing: 'ndəŋndəŋə', english: 'truth. Speak the truth', category: 'things', difficulty: 2),
  AwingWord(awing: 'ndəpa\'ə', english: 'tobacco; cigarette', category: 'things', difficulty: 1),
  AwingWord(awing: 'ndəsê təpəŋə', english: 'barren land', category: 'things', tonePattern: 'falling', difficulty: 2),

  AwingWord(awing: 'ndəzəəmə', english: 'moth', category: 'things'),
  AwingWord(awing: 'ndí\'ə', english: 'poison', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ndoonə', english: 'curse', category: 'things', difficulty: 3),
  AwingWord(awing: 'ndotíə', english: 'dirt, rubbish', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ndú atsəmə', english: 'everywhere', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ndzaŋə', english: 'color, kind, pattern', category: 'things', difficulty: 2),
  AwingWord(awing: 'ndzaŋə á laŋ ná', english: 'account (report)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ndzeemó', english: 'axe', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ndzelá', english: 'satisfaction (of sth especially food), satedness', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ndzəəmə', english: 'dream; vision (supernatural)', category: 'things', difficulty: 2),
  AwingWord(awing: 'ndzogə', english: 'itch (n)', category: 'things'),
  AwingWord(awing: 'ndzɔ́\'ə alá\'ə', english: 'in public', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'ndzɔ́\'ə tá\' məngyè', english: 'polygamy', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ndzəmnə', english: 'insult', category: 'things', difficulty: 3),
  AwingWord(awing: 'neemə akoobá', english: 'wild animal', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'néŋ əfɔ́gə', english: 'blow up, inflate', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'néŋ mbwódnə', english: 'bless', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'néŋ nəfaŋə́', english: 'wound (sth or sb)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəchwáakə', english: 'style of beginning', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəchwaakinə́', english: 'the beginning, the start', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəchwéd nə́ atoonə akáŋəsê', english: 'alter', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'nəchwi\'ə́', english: 'turf, of grass', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəfágə', english: 'twin', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəfed nó ngo\'ə́', english: 'titled feather. Titled feathers are given to people who do great things', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəfelə', english: 'feather', category: 'things'),
  AwingWord(awing: 'nəfemə̂', english: 'a secret place, especially in the fon\'s palace', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nəfaŋ nó móənə', english: 'ulcer', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəfo nə́ Əsê', english: 'kingdom of', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nəfyânə', english: 'spanking', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'nəgheebə', english: 'the manner of sharing or distributing', category: 'things', difficulty: 2),
  AwingWord(awing: 'nəghéenə', english: 'visit', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəgha\' nó mógə', english: 'embers; charcoal', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəgholə', english: 'a challenging task', category: 'things', difficulty: 2),
  AwingWord(awing: 'nəjíə', english: 'possessive pronoun "his" used for class 5 nouns; possessive pronoun "her" used for class 5 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəká\'ə', english: 'bundle (especially of firewood)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəkaŋə', english: 'magic', category: 'things'),
  AwingWord(awing: 'nəkéelə', english: 'headpad', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəkəŋ nó atsa\'ə́', english: 'cooking pot (earthenware)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəkəŋ nó ndəpa\'ə́', english: 'tobacco pipe', category: 'things', tonePattern: 'high', difficulty: 2),
  // Session 52: was 'nəkəŋ nó nkíə' — nkíə (high tone) does not exist. Per dict, water = nkǐə (rising).
  AwingWord(awing: 'nəkəŋ nó nkǐə', english: 'pot (for water)', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'nəkəŋ nó séləbə', english: 'metal pot', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəkəŋə́', english: 'tobacco pipe', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəkó\'ə', english: 'growth (of plants)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəkoŋ nó nkyílə', english: 'arrow', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəkoŋə́', english: 'lance, spear', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəkwedná əpúmə', english: 'garbage dump', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəkwinə', english: 'beam; rafter', category: 'things', difficulty: 1),
  AwingWord(awing: 'nəkwíŋə', english: 'manner of prospering, manner of growing (of plants), manner of climbing', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəkwu nó ndê', english: 'doorway', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nəkwu\'ə́', english: 'mortar', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəkyéŋə', english: 'mourning, crying', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəkyéŋə mbi Əsê', english: 'confession', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'nəkye nó nûə', english: 'beewax; bee-bread', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nəkyéelə', english: 'debt', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəkyelá', english: 'hearth', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəkyelá nó mógə́', english: 'fireplace, hearth', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəla\'ə', english: 'string', category: 'things'),
  AwingWord(awing: 'nələŋ nó kɔ́\'ə aŋkándə', english: 'strap for climbing', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nələŋə́', english: 'knuckle, joint', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəló\' nó aghələ məjíə', english: 'ladle', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəló\'ə', english: 'spoon', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəloŋə', english: 'harp', category: 'things'),
  AwingWord(awing: 'nəlwelá', english: 'bump, knot (in wood)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəlwí nə́ əshúə', english: 'gill', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nənchwínə', english: 'waxbill', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəntəələ', english: 'maggot (found in rotten meat)', category: 'things', difficulty: 2),
  AwingWord(awing: 'nənyinə', english: 'journey; movement, travel', category: 'things', difficulty: 2),
  AwingWord(awing: 'nəpá nó ngɔŋə', english: 'public alter. Used by any person for his family or personal sacrifices', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəpab nó əshúə', english: 'fin', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəpaŋə', english: 'redness', category: 'things'),
  AwingWord(awing: 'nəpeebə', english: 'wing', category: 'things'),
  AwingWord(awing: 'nəped nó nûə', english: 'beehive', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nəpenə́', english: 'edge, side, beside', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəpəgə', english: 'foolishness', category: 'things'),
  AwingWord(awing: 'nəpəm nó atîə', english: 'trunk, of tree', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nəpəm nó lúm nə́', english: 'stomachache, upset stomach', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəpíə', english: 'cola nut', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəpíəmbéŋə', english: 'quiny; The fruit of a quiny tree is used as medicine', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəpí nó neemə', english: 'udder', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəpó\' nó əpúmə', english: 'threshing-floor', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəpo\'ə́', english: 'bundle', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəpo\' nó kéenə', english: 'melon', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəpɔ́\'ə', english: 'pumpkin', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəpɔŋə', english: 'beauty', category: 'things'),
  AwingWord(awing: 'nəsáŋə', english: 'broom', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nəse', english: 'grave', category: 'things'),
  AwingWord(awing: 'nəsednə', english: 'bend, curve, corner', category: 'things', difficulty: 2),
  AwingWord(awing: 'nəsô', english: 'the manner of weeding', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nəsóŋə', english: 'the manner of saying', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəsɔ\'ə', english: 'the manner of clearing (of a field)', category: 'things', difficulty: 2),
  AwingWord(awing: 'nəsoŋ nó kwúneemə afoonə', english: 'tusk (of warthog)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəsoŋ nə́ záŋ ná', english: 'toothache', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəshugnə', english: 'camp, encampment', category: 'things'),
  AwingWord(awing: 'nətáŋə', english: 'hardship, stress', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nətú\' ənumnə', english: 'eclipse (sun)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nətu nó ndúmə', english: 'crossroads, intersection', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nətu nó nəkoŋə́', english: 'shaft of arrow', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nətûə', english: 'summit, highest point, tip, chief, headman', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nətwéŋ nó pəkwûə', english: 'cemetery', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nətsa\'ə́', english: 'marsh', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nətsê nó neemə', english: 'heifer', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nətsə́', english: 'attribute "certain", modifying nouns of class 5; attribute "some", modifying nouns of class 5', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəwaŋə́', english: 'sales point, place for business transaction', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəwû nó nkǐ mógə', english: 'funeral', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'nəwuə', english: 'the manner of falling', category: 'things', difficulty: 2),
  AwingWord(awing: 'nəyeŋə yi səbtə nó', english: 'weeds', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəzéemə', english: 'possessive pronoun "mine" used for class 5 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəzágə́', english: 'possessive pronoun "ours" used for class 5 nouns; possessive adj "our" used for class 5 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nəzô', english: 'possessive singular pronoun "yours" used for class 5 nouns. Where is your potatoe', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nəzóobá', english: 'possessive pronoun "theirs" used for nouns of class 5', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngá', english: 'no', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngá mə\'ə́', english: 'once, one time', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngá yitsə̂', english: 'again, once more', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ngagə', english: 'fist', category: 'things'),
  AwingWord(awing: 'ngaŋəfa\'ə', english: 'servant. Am not your servant', category: 'things', difficulty: 2),
  AwingWord(awing: 'ngaŋəfúə', english: 'medicine man, traditional healer', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngaŋkwaalətáksə', english: 'tax collector. From: English', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngaŋtsáŋə', english: 'prisoner; captive', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngaŋkəpeenə', english: 'enemy. Peter is my enemy', category: 'things', difficulty: 3),
  AwingWord(awing: 'ngaŋmáŋéemə', english: 'diviner, fortune-teller. A fortune-teller lies', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngaŋnchindê', english: 'host, owner of the compound', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ngaŋnənyinə', english: 'traveller, very mobile person', category: 'things', difficulty: 2),
  AwingWord(awing: 'ngaŋtsoolə', english: 'army officer, soldier', category: 'things', difficulty: 2),
  AwingWord(awing: 'ngéelə', english: 'gun', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ngedtəpəŋə', english: 'sinner, evil doer', category: 'things', difficulty: 3),
  AwingWord(awing: 'ńgə́', english: 'verb complement, occurs only after verbs', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngá\'ə', english: 'hardship, distress', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ngi yi mbyâŋnə', english: 'boyfriend', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ngi yi məngyè', english: 'girlfriend', category: 'things', tonePattern: 'low', difficulty: 2),
  AwingWord(awing: 'ngo\'kə́', english: 'splendor; glory', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngóobə', english: 'cunning; deceit', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngoolə', english: 'swear, a statement that is considered as the truth, oath', category: 'things', difficulty: 2),
  AwingWord(awing: 'ngólə', english: 'hole', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ngonə', english: 'dance group in Njom, no longer active', category: 'things', difficulty: 2),
  AwingWord(awing: 'ngwâ', english: 'sheath', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'ngwâ nəkoŋ nó nkyílə', english: 'quiver', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ngwaamə', english: 'accuser', category: 'things'),
  AwingWord(awing: 'ngwágə', english: 'someone who despises', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngwě əsê', english: 'fetish priestess', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ngwe\'ə́', english: 'tomorrow', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngwəpá\'ə', english: 'biggest dance group in Awing based in Njom', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngwub neemə', english: 'hide of cattle', category: 'things', difficulty: 2),
  AwingWord(awing: 'ngwubə', english: 'shoe; hide of any animal', category: 'things', difficulty: 2),
  AwingWord(awing: 'ngwubə akoolə', english: 'shoe', category: 'things', difficulty: 1),
  AwingWord(awing: 'ngwüdlóŋə́', english: 'heron. Some people believe that when a heron cries it is an evil omen', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngwumnə́ akwunə́', english: 'bedbug', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngyéŋə', english: 'side (of body)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ngyeenakə\'ə', english: 'shepherd, cow boy', category: 'things', difficulty: 2),
  AwingWord(awing: 'ngyêtûə', english: 'earache', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ni\'ə́', english: 'a sort of pointed weed, usually pierces into the feet of farmers when they are weeding', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'njakásə', english: 'jackal. From: English', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nji\' nətôglə', english: 'earwax', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'njiə', english: 'hunger', category: 'things'),
  AwingWord(awing: 'nji\'ə́', english: 'egussi', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'njîməneemə', english: 'pastureland', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'njubkə', english: 'sth peeling off', category: 'things', difficulty: 2),
  AwingWord(awing: 'nju\'ə', english: 'silk', category: 'things'),
  AwingWord(awing: 'nka kwíŋə́', english: 'shell (of turtle)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nká\' məneemə', english: 'cattle pen', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nká\' nəpumə́', english: 'eggshell', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nka sáŋə́', english: 'nest', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nka\'ə', english: 'leprosy', category: 'things'),
  AwingWord(awing: 'nkámázɔ́\'ə́', english: 'monkey', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkaŋə', english: 'age-group', category: 'things'),
  AwingWord(awing: 'nkeenə́ akyamə', english: 'gall bladder', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkeenə́ atətsələ', english: 'cocoon', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nked nətəŋə́', english: 'umbilical cord', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nked nkyílə', english: 'bowstring', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkelá akóolə əshúə', english: 'fishing net', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkelá apɔ́əmə', english: 'hunting net', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkəənə', english: 'news, message', category: 'things'),
  AwingWord(awing: 'nkəm əsê', english: 'fetish priestess', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nkəmə́', english: 'title of sub-chief; sub-chief', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkǐ nəko\'nó', english: 'national anthem', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'nkǐ yi əshî\'nə', english: 'gospel, good news', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'nkog məngyè', english: 'widow', category: 'things', tonePattern: 'low', difficulty: 2),
  AwingWord(awing: 'nkog ngábə', english: 'hen', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkog ŋwu mbyâŋnə', english: 'widower', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nkoolə', english: 'bruise', category: 'things'),
  AwingWord(awing: 'nkóomə atûə', english: 'barber', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'nkɔ\'ə', english: 'bucket', category: 'things'),
  AwingWord(awing: 'nkənə', english: 'hunchback', category: 'things'),
  AwingWord(awing: 'nkəŋ ndəpa\'ə', english: 'pipe stem', category: 'things', difficulty: 1),
  AwingWord(awing: 'nkəŋə aŋwa\'lə', english: 'pen', category: 'things', difficulty: 1),
  AwingWord(awing: 'nkwa', english: 'mask', category: 'things'),
  AwingWord(awing: 'nkwáalə', english: 'midwife', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nkwâtáksə', english: 'tax collector', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'nkwe', english: 'masqueraders based in Tame Mbah Ako\'s compound. No longer active', category: 'things', difficulty: 2),
  AwingWord(awing: 'nkwáŋə', english: 'firewood', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'nkwiŋ məngyè', english: 'spinster', category: 'things', tonePattern: 'low', difficulty: 2),
  AwingWord(awing: 'nkwiŋ ŋwu mbyâŋnə', english: 'bachelor', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nkwúblə mbimá', english: 'convert, somebody who changes his or her believes', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkwu\'ə', english: 'chaffs of grain', category: 'things', difficulty: 2),
  AwingWord(awing: 'nkye', english: 'granary', category: 'things'),
  AwingWord(awing: 'nkye məngyè', english: 'barren woman', category: 'things', tonePattern: 'low', difficulty: 2),
  AwingWord(awing: 'nkyeetə', english: 'meeting, assembly', category: 'things'),
  AwingWord(awing: 'nkyílə', english: 'hunting bow; sword', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nó mətû mətûə', english: 'spitting cobra', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'nó ngámə', english: 'python', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'noŋkə', english: 'law, practice', category: 'things'),
  AwingWord(awing: 'nóŋ ntsoolə', english: 'kiss, of lovers only', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ntagə akoolə', english: 'footstep', category: 'things', difficulty: 1),
  AwingWord(awing: 'ntaŋə', english: 'horn (musical instrument)', category: 'things', difficulty: 2),
  AwingWord(awing: 'ńte akə̌', english: 'why?', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'ńte ngə́', english: 'because', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'ntəələ', english: 'capital for starting a business', category: 'things', difficulty: 2),
  AwingWord(awing: 'ntəənə acha\'tésê', english: 'fasting', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'ntəmə', english: 'a skirt-like dress worn by men', category: 'things', difficulty: 2),
  AwingWord(awing: 'ntó\'ə', english: 'calabash', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ntóoma', english: 'pillar, wedge, esp. for a house', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ntú əsê', english: 'prophet', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ntyâ əpúmə', english: 'somebody who finds it difficult to make a choice', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'ntsa\'ə', english: 'hoof', category: 'things'),
  AwingWord(awing: 'ntseŋ ndê Əsê', english: 'angel', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'ntseŋnə', english: 'somebody who looks after something eg cattle', category: 'things', difficulty: 2),
  AwingWord(awing: 'ntseŋnə məneemə', english: 'shepherd', category: 'things'),
  AwingWord(awing: 'ntsentə', english: 'meeting, grouping', category: 'things'),
  AwingWord(awing: 'ntsəələ', english: 'lie (falsehood)', category: 'things'),
  AwingWord(awing: 'ntsəmá', english: 'confidential or private conversation', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ntsóŋə', english: 'bottle', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ntsəŋkə', english: 'condemnation; destruction, destroyer', category: 'things', difficulty: 2),
  AwingWord(awing: 'ntso sáŋə́', english: 'beak, bill', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'ntsɔ́\'ə afa\'ə', english: 'reward, remuneration', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'ntsə\'lə', english: 'comb (of rooster), crest', category: 'things', difficulty: 2),
  AwingWord(awing: 'nyâ\'', english: 'opening sound that is gradual and secretive eg of a door', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'nyânyâ', english: 'sound that describes a crying baby', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'nya\'nya\'ə', english: 'drizzle', category: 'things'),
  AwingWord(awing: 'nyâ\'nya\'nya\'', english: 'intensifies the continuous and muddy nature of a drizzle', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'nyá\'tənyá\'tə', english: 'sound (word) that describes how secretive somebody moves', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nyênənyenə', english: 'sound (word) that describes the slowness of someting or somebody', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'ŋwu ntsəmə', english: 'everybody', category: 'things', difficulty: 1),
  AwingWord(awing: 'ŋwunə', english: 'inhabitant, resident', category: 'things'),
  AwingWord(awing: 'ŋwunə alə\'á', english: 'cripple', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'óflenə', english: 'offering given in church', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pábánduuŋgɔ́\'ə', english: 'lizard; agama lizard', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pá\'mághéemə́', english: 'flea', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pâmtə', english: 'sound that describes a start or sudden wake', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'pánkó', english: 'something that accompanies a bigger one eg a stool', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pánkó akɔ\'ə', english: 'stool, a sort of seat', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'paŋ sɔŋə́', english: 'weaverbird', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pe\'ə', english: 'marker, of simple past tense. Used for events that take place the same day', category: 'things', difficulty: 3),
  AwingWord(awing: 'péŋkə ajwiə', english: 'faint. Some people who lose their breath on hearing any bad news', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pénkə aghoonə́', english: 'throb with pain', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pô', english: 'demonstrative adj \'those\', used to modify nouns of classes one and three', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'pəənə́', english: 'demonstrative pronoun \'you\' (pl.). Occurs after nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'páanə', english: 'class two and eight interrogative \'which\'', category: 'things', tonePattern: 'high', difficulty: 2),
  // Session 60: Simplified gloss for kids' quiz. Original from
  // dictionary was the technical linguistic term "we exclusive, that
  // is, excluding others" — a real meaning but unreadable for a
  // child. User reported the quiz showed this as nonsense.
  AwingWord(awing: 'pəgə', english: 'we (not including you)', category: 'pronouns'),
  AwingWord(awing: 'págtə', english: 'quench, extinguish', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pəlô', english: 'ancestors; les ancetre', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'pôm', english: 'sound that describes a start or sudden wake', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'pəpíə', english: 'possessive pronoun \'his\' used for class 2 nouns; possessive pronoun \'hers\' used for class 2 nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pəpóobá', english: 'possessive pronoun \'theirs\' used for nouns of class 5', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pi ndəŋ', english: 'boil over', category: 'things', difficulty: 1),
  AwingWord(awing: 'píi', english: 'intensifies the blackness of something', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'pímə məmə', english: 'accept reluctantly', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pó\' mbô', english: 'clap (hands), beg', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'pó\' nó nduə', english: 'hit with a hammer', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pó\' ngoŋə', english: 'cry out; scream', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pó\'əpa\'ə', english: 'abstain, avoid, stay away from', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pó\'mâmbéŋə', english: 'hyena', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'pôŋ', english: 'intensifies the redness of something', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'po\'á', english: 'mushroom', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'púu', english: 'intensifies the whiteness of something', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'pyáb nó nəkaŋə', english: 'protect by charm', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'pyádnə', english: 'really, truly; very well', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sá ndedtə', english: 'peg out (of boundary)', category: 'things', tonePattern: 'high', difficulty: 2),

  AwingWord(awing: 'sáŋ pábá', english: 'harmattan', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'séenásê', english: 'puff adder', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'sedkə ndzəmə', english: 'turn over (tr)', category: 'things', difficulty: 2),
  AwingWord(awing: 'sélóbə', english: 'silver', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'səmtwá\'', english: 'sound (word) that describes how two things bump on each other or two people meet unexpectedly', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'sáŋ məkálə', english: 'pigeon', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sáŋ neemə', english: 'cattle egret', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sáŋ ngábə', english: 'partridge', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sáŋ ngábə akoobá', english: 'guinea fowl', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sílenə', english: 'ceiling', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'sínágoga', english: 'sinagogue', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'sog əpúmə', english: 'wash utensils', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sog ətsə\'á', english: 'launder', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'sogə akwubə', english: 'bathe (wash body) (intr)', category: 'things', difficulty: 2),
  AwingWord(awing: 'soŋ nkəlá', english: 'pull; resist', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'soŋə múto', english: 'steer, drive a car', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'soŋə ndəsê', english: 'drag on the grown', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'sóoŋ', english: 'sound (word) produced to describe the intensity with which somebody is listening, hearing or looking', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'sə\'â ali\'á', english: 'clear (land or a grown place for planting)', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'shwa\'ə', english: 'razor blade. If you give a razor blade to a child he will wound himself with', category: 'things', difficulty: 3),
  AwingWord(awing: 'shwěmôndóŋə', english: 'shrew, name of animal', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'tä afa\'ə', english: 'master', category: 'things', difficulty: 1),
  AwingWord(awing: 'tá\' əpúmə', english: 'bead', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tá\' ngǎ', english: 'once, one time', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'tä pətä', english: 'grandfather (paternal)', category: 'things', difficulty: 1),
  AwingWord(awing: 'táksə', english: 'tax. From: English', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'téemə atəənə́', english: 'set a trap', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'témpəələ', english: 'temple. From: English', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tə', english: '"us", excluding other people; "we" excluding other people', category: 'things', difficulty: 2),
  AwingWord(awing: 'tâb', english: 'intensifies the softness of something. Mattress is so soft', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'təə', english: 'non-stop', category: 'things', difficulty: 1),
  AwingWord(awing: 'táfu\'əmántséntsé', english: 'dragonfly', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'təjî ndzɔ\'á', english: 'virgin', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'táko\' sáŋə́', english: 'turkey', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tám nó afûə', english: 'bewitch', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'támásê', english: 'destruction, wastage', category: 'things', tonePattern: 'falling'),
  AwingWord(awing: 'táŋká\'andíkwumá', english: 'millipede', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'təpí əsê', english: 'unbeliever, somebody who does not believe in God or the popular religion', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'təpíma', english: 'unbeliever, polite expression for pagan or somebody who does not identify himself with one\'s religion or the popular religion', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tasa\'ə', english: 'spark', category: 'things', difficulty: 1),
  AwingWord(awing: 'tatəənə', english: 'between; middle', category: 'things', difficulty: 1),
  AwingWord(awing: 'təti nəpu nə́ ngəbə', english: 'yolk (of egg)', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tí\'ə', english: 'let; allow', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tó\'', english: 'sound (word) that adds meaning to the quietness of somebody or something', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'tó\' nkǐə', english: 'draw water', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'tôd', english: 'sound (word) that intensifies the messy state of a thing or situation', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'tóŋ njwîŋə', english: 'whistle', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tósə', english: 'touch lamp. From: English', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'túg ntáəmə', english: 'be courageous; be brave', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'twáamə aléemə', english: 'hurt oneself', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'twám nó mbô', english: 'carry in arms', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tyáŋə mənaŋə', english: 'gossip', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsópó', english: 'plague; epidemic', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsô', english: 'sound (word) that describes the fastness in which one or many things disappear into the unknown', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'tsonkô ndena', english: 'haggle; negotiate', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tsó\' ətsə\'á', english: 'undress', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'tsóg', english: 'sound (word) that intensifies the coldness of something', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'vâd', english: 'sound (word) that describes the fastness of something or somebody', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'vâinə', english: 'vain. From: English', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'vîp', english: 'sound (word) that describes the fastness of sometning or somebody', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'wâg', english: 'sound (word) that describes the sound of something being opened or torn with brute force', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'wág Əsê', english: 'blaspheme; belittle God', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'welə', english: 'weight. It is not good to carry a lot of weight. From: English', category: 'things', difficulty: 2),
  AwingWord(awing: 'wô', english: 'demonstrtive adj \'that\' used to modify nouns of classes one and three. That pig is whose own', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'wáənə', english: 'which?', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'wískiə', english: 'whisky', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'wûu', english: 'sound (word) that describes the rumbling of something', category: 'things', tonePattern: 'falling', difficulty: 3),


  AwingWord(awing: 'yêe', english: 'sound (word) that describes how a group (herd, swarm, people etc) run into different directions, usually in such of safty', category: 'things', tonePattern: 'falling', difficulty: 3),
  AwingWord(awing: 'yó', english: 'his; her', category: 'things', tonePattern: 'high'),
  AwingWord(awing: 'yǐpəchíə', english: 'concubinage; cohabitation', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'yitsə̌', english: 'attribute "certain", modifying nouns of classes 1, 3, 7 and 9', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'yôyo', english: 'Women dance group based in Tame Tangwing\'s compound. No longer active', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'zǎa', english: 'winnow, of grain', category: 'things', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'zá\'ə', english: 'before (contrasted with afterwards). You were suppose to tell me before he comes', category: 'things', tonePattern: 'high', difficulty: 3),
  AwingWord(awing: 'zagə atîə', english: 'soar', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'zén', english: 'a word that is used before numbers that modify class five nouns', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zə̂', english: 'demonstrative adjective \'that\' (talked about); demonstrative adjective "that", pointing', category: 'things', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'zoŋ əshwáŋə', english: 'track, of an animal', category: 'things', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'zoomə', english: 'confession', category: 'things', difficulty: 1),
  AwingWord(awing: 'zó\' nkǐə', english: 'swim', category: 'things', tonePattern: 'rising', difficulty: 2),

  // numbers (12 — duplicates of the curated numbers list have been removed.
  // The curated `numbers` list above is authoritative for the kid-facing
  // Numbers screen; these are extended/alternate forms only.)
  AwingWord(awing: 'azoŋkə', english: 'second, second place', category: 'numbers', difficulty: 1),
  AwingWord(awing: 'kwa', english: 'four (see nəkwa)', category: 'numbers', difficulty: 2),
  AwingWord(awing: 'məghám mém mbê', english: 'twenty (20)', category: 'numbers', tonePattern: 'falling'),
  AwingWord(awing: 'məghám mén nəfeemə̂', english: 'eighty (80)', category: 'numbers', tonePattern: 'falling'),
  AwingWord(awing: 'məghám mén nəkwa', english: 'forty (40)', category: 'numbers', tonePattern: 'high'),
  AwingWord(awing: 'məghám mén nəpu\'ə̂', english: 'ninety (90)', category: 'numbers', tonePattern: 'falling'),
  AwingWord(awing: 'məghám mén ntogə̂', english: 'sixty (60)', category: 'numbers', tonePattern: 'falling'),
  AwingWord(awing: 'məghám mén teelə̂', english: 'thirty (30)', category: 'numbers', tonePattern: 'falling'),
  AwingWord(awing: 'məghám mén tênə', english: 'fifty (50)', category: 'numbers', tonePattern: 'falling'),
  AwingWord(awing: 'məghám méná asaambê', english: 'seventy (70)', category: 'numbers', tonePattern: 'falling'),
  AwingWord(awing: 'nəghámə', english: 'ten (alternate form)', category: 'numbers', tonePattern: 'high', difficulty: 2),
  AwingWord(awing: 'nkelá', english: 'hundred (100)', category: 'numbers', tonePattern: 'high'),
  AwingWord(awing: 'ntsoobə asaambê', english: 'seventeen (17)', category: 'numbers', tonePattern: 'falling'),
  AwingWord(awing: 'ntsəb mə\'á', english: 'eleven (11)', category: 'numbers', tonePattern: 'high'),
  AwingWord(awing: 'ntsəb napu\'á', english: 'nineteen (19)', category: 'numbers', tonePattern: 'high'),
  AwingWord(awing: 'ntsəb pê', english: 'twelve (12)', category: 'numbers', tonePattern: 'falling'),
  AwingWord(awing: 'pě', english: 'two (alternate form)', category: 'numbers', tonePattern: 'rising', difficulty: 2),
  AwingWord(awing: 'teelə', english: 'three (alternate form)', category: 'numbers', difficulty: 2),
  AwingWord(awing: 'tênə', english: 'five (alternate form)', category: 'numbers', tonePattern: 'falling', difficulty: 2),
  AwingWord(awing: 'tóosə', english: 'thousand (1000). From: English', category: 'numbers', tonePattern: 'high', difficulty: 2),

  // === Auto-extracted from Bible NT corpus (auto_extract_app_content.py) ===
  AwingWord(awing: 'ə́sóŋ', english: 'said', category: 'actions', difficulty: 1),
    // bible:MAT.1.20, conf=0.45, freq=525
  AwingWord(awing: 'əshîʼnə', english: 'good', category: 'descriptive', difficulty: 1),
    // bible:MAT.3.10, conf=0.50, freq=501
  AwingWord(awing: 'ə́sóŋə', english: 'said', category: 'actions', difficulty: 1),
    // bible:MAT.3.1, conf=0.40, freq=446
  AwingWord(awing: 'táʼ', english: 'one', category: 'numbers', difficulty: 1),
    // bible:MAT.5.36, conf=0.61, freq=382
  AwingWord(awing: 'ngaŋə́zoŋə́ndzəm', english: 'disciples', category: 'things', difficulty: 3),
    // bible:MAT.5.1, conf=0.65, freq=338
  AwingWord(awing: 'ḿbímə', english: 'faith', category: 'things', difficulty: 1),
    // bible:MAT.3.15, conf=0.70, freq=323
  AwingWord(awing: 'fiʼtə̂', english: 'tell', category: 'actions', difficulty: 1),
    // bible:MAT.2.8, conf=0.45, freq=317
  AwingWord(awing: 'nɨ́', english: 'many', category: 'numbers', difficulty: 1),
    // bible:MAT.7.22, conf=0.61, freq=301
  AwingWord(awing: 'ndɛ̂', english: 'house', category: 'things', difficulty: 1),

    // bible:MAT.4.7, conf=0.95, freq=277
  AwingWord(awing: 'pɛ̌', english: 'two', category: 'numbers', difficulty: 1),
    // bible:MAT.2.16, conf=0.46, freq=264
  AwingWord(awing: 'nkɨ', english: 'good', category: 'descriptive', difficulty: 1),
    // bible:MAT.9.35, conf=0.42, freq=260
  AwingWord(awing: 'məngyě', english: 'woman', category: 'things', difficulty: 1),
    // bible:MAT.1.23, conf=0.43, freq=253
  AwingWord(awing: 'Mmaʼmbîə', english: 'lord', category: 'things', difficulty: 3),
    // bible:MAT.1.20, conf=0.91, freq=220
  AwingWord(awing: 'táʼə', english: 'one', category: 'numbers', difficulty: 1),
    // bible:MAT.5.29, conf=0.57, freq=214
  AwingWord(awing: 'mäŋ', english: 'tell', category: 'actions', difficulty: 1),
    // bible:MAT.3.9, conf=0.41, freq=210
  AwingWord(awing: 'fóŋ', english: 'called', category: 'things', difficulty: 1),
    // bible:MAT.1.16, conf=0.46, freq=205
  AwingWord(awing: 'nchîmbî', english: 'life', category: 'things', difficulty: 1),
    // bible:MAT.6.25, conf=0.53, freq=205
  AwingWord(awing: 'əlɛ́n', english: 'name', category: 'things', difficulty: 1),
    // bible:MAT.1.21, conf=0.55, freq=194
  AwingWord(awing: 'ḿbítə', english: 'said', category: 'actions', difficulty: 1),
    // bible:MAT.2.2, conf=0.41, freq=189
  AwingWord(awing: 'fɛ́lə', english: 'out', category: 'things', difficulty: 1),
    // bible:MAT.2.1, conf=0.44, freq=188
  AwingWord(awing: 'ŋwaʼlə̂', english: 'written', category: 'things', difficulty: 1),
    // bible:MAT.4.4, conf=0.41, freq=188
  AwingWord(awing: 'nəpó', english: 'heaven', category: 'things', difficulty: 2),
    // bible:MAT.3.16, conf=0.52, freq=178
  AwingWord(awing: 'ńdzóʼ', english: 'heard', category: 'things', difficulty: 1),
    // bible:MAT.2.3, conf=0.70, freq=168
  AwingWord(awing: 'ńkwúnə', english: 'into', category: 'things', difficulty: 1),


    // bible:MAT.2.15, conf=0.50, freq=155
  AwingWord(awing: 'Ajwǐəsê', english: 'spirit', category: 'things', difficulty: 2),
    // bible:MAT.1.18, conf=0.92, freq=148
  AwingWord(awing: 'ndɛn', english: 'things', category: 'things', difficulty: 1),
    // bible:MAT.6.32, conf=0.44, freq=147
  AwingWord(awing: 'tú', english: 'sent', category: 'actions', difficulty: 1),
    // bible:MAT.2.8, conf=0.51, freq=142
  AwingWord(awing: 'ngaŋəfaʼ', english: 'servant', category: 'family', difficulty: 1),



    // bible:MAT.2.2, conf=0.47, freq=136
  AwingWord(awing: 'ńjɨ́', english: 'saw', category: 'things', difficulty: 1),
    // bible:MAT.2.9, conf=0.41, freq=136
  AwingWord(awing: 'pətǎ', english: 'fathers', category: 'family', difficulty: 1),
    // bible:MAT.1.1, conf=0.61, freq=129
  AwingWord(awing: 'akɔŋnə', english: 'love', category: 'actions', difficulty: 1),

    // bible:MAT.2.1, conf=0.89, freq=123
  AwingWord(awing: 'Tə́kɔʼndɛ̂sê', english: 'temple', category: 'things', difficulty: 1),

    // bible:MAT.6.7, conf=0.57, freq=122
  AwingWord(awing: 'mbwɔ́dnə', english: 'peace', category: 'things', difficulty: 2),
    // bible:MAT.5.9, conf=0.64, freq=121
  AwingWord(awing: 'ngoʼ', english: 'years', category: 'things', difficulty: 1),
    // bible:MAT.2.16, conf=0.44, freq=116
  AwingWord(awing: 'Lə́', english: 'said', category: 'actions', difficulty: 1),
    // bible:MAT.3.14, conf=0.44, freq=115
  AwingWord(awing: 'tɔŋ', english: 'city', category: 'things', difficulty: 1),
    // bible:MAT.5.38, conf=0.60, freq=114
  AwingWord(awing: 'aŋkənúʼə́', english: 'boat', category: 'things', difficulty: 1),

    // bible:MAT.5.17, conf=0.69, freq=113
  AwingWord(awing: 'pəlim', english: 'brothers', category: 'things', difficulty: 1),
    // bible:MAT.1.2, conf=0.71, freq=112
  AwingWord(awing: 'pətə́kɔʼ', english: 'chief', category: 'things', difficulty: 1),
    // bible:MAT.2.4, conf=0.56, freq=111
  AwingWord(awing: 'ńdzɨ́', english: 'saw', category: 'things', difficulty: 1),

    // bible:ACT.11.30, conf=0.53, freq=106
  AwingWord(awing: 'Lə́ələ́', english: 'therefore', category: 'things', difficulty: 1),
    // bible:MAT.1.17, conf=0.50, freq=105
  AwingWord(awing: 'nəgháʼ', english: 'glory', category: 'things', difficulty: 2),
    // bible:MAT.4.8, conf=0.82, freq=104
  AwingWord(awing: 'mɛdnə̂', english: 'eternal', category: 'things', difficulty: 2),
    // bible:MAT.18.8, conf=0.49, freq=104
  AwingWord(awing: 'ngwě', english: 'wife', category: 'family', difficulty: 1),
    // bible:MAT.1.6, conf=0.51, freq=103
  AwingWord(awing: 'pəngyě', english: 'women', category: 'things', difficulty: 1),
    // bible:MAT.13.56, conf=0.40, freq=102
  AwingWord(awing: 'asaambɛ̂', english: 'seven', category: 'numbers', difficulty: 1),
    // bible:MAT.12.45, conf=0.91, freq=101
  AwingWord(awing: 'əmə́g', english: 'eyes', category: 'body', difficulty: 1),
    // bible:MAT.9.29, conf=0.53, freq=99
  AwingWord(awing: 'nəkwa', english: 'four', category: 'numbers', difficulty: 1),
    // bible:MAT.1.17, conf=0.56, freq=97
  AwingWord(awing: 'pətəpɔŋ', english: 'sins', category: 'things', difficulty: 2),
    // bible:MAT.3.6, conf=0.60, freq=95
  AwingWord(awing: 'ńtsɛɛlə̂', english: 'than', category: 'things', difficulty: 1),
    // bible:MAT.6.26, conf=0.44, freq=95
  AwingWord(awing: 'məntú', english: 'apostles', category: 'things', difficulty: 3),
    // bible:MAT.1.22, conf=0.56, freq=94
  AwingWord(awing: 'pəlimə́', english: 'brothers', category: 'things', difficulty: 1),


    // bible:MAT.3.1, conf=0.70, freq=92
  AwingWord(awing: 'mɔʼə́', english: 'eternal', category: 'things', difficulty: 2),
    // bible:MAT.18.8, conf=0.53, freq=92
  AwingWord(awing: 'ntsɔb', english: 'twelve', category: 'numbers', difficulty: 1),
    // bible:MAT.1.17, conf=0.77, freq=91
  AwingWord(awing: 'məko', english: 'feet', category: 'body', difficulty: 1),
    // bible:MAT.4.9, conf=0.67, freq=88
  AwingWord(awing: 'ntseŋndɛ̂sê', english: 'angel', category: 'things', difficulty: 1),
    // bible:LUK.1.13, conf=0.73, freq=88
  AwingWord(awing: 'apɔŋə́ntə́əmə', english: 'grace', category: 'things', difficulty: 2),

    // bible:MAT.22.43, conf=0.66, freq=85
  AwingWord(awing: 'mbêsê', english: 'priest', category: 'things', difficulty: 1),
    // bible:MAT.8.4, conf=0.87, freq=84
  AwingWord(awing: 'mə́ənə́', english: 'things', category: 'things', difficulty: 1),


    // bible:MAT.3.7, conf=0.96, freq=80
  AwingWord(awing: 'məloʼ', english: 'wine', category: 'food', difficulty: 1),
    // bible:MAT.9.17, conf=0.57, freq=76
  AwingWord(awing: 'ntsɛɛmbi', english: 'first', category: 'descriptive', difficulty: 1),
    // bible:MAT.10.2, conf=0.57, freq=76
    // bible:MAT.4.24, conf=0.64, freq=75
  AwingWord(awing: 'júmnə', english: 'dead', category: 'things', difficulty: 3),
    // bible:MAT.12.42, conf=0.53, freq=75
  AwingWord(awing: 'móonə', english: 'son', category: 'family', difficulty: 1),
    // bible:MAT.1.18, conf=0.50, freq=74
  AwingWord(awing: 'ngaŋə́pêsê', english: 'priests', category: 'things', difficulty: 3),
    // bible:MAT.2.4, conf=0.92, freq=72
  AwingWord(awing: 'akwaŋ', english: 'hope', category: 'things', difficulty: 2),
    // bible:MAT.1.20, conf=0.66, freq=71
  AwingWord(awing: 'məntúmə́sê', english: 'prophets', category: 'things', difficulty: 3),
    // bible:MAT.2.23, conf=0.85, freq=71
  AwingWord(awing: 'ńnáanə', english: 'sat', category: 'actions', difficulty: 1),
    // bible:MAT.5.1, conf=0.59, freq=71
  AwingWord(awing: 'ndɛ̂sê', english: 'synagogue', category: 'things', difficulty: 2),
    // bible:MAT.12.4, conf=0.55, freq=71
  AwingWord(awing: 'ntûsê', english: 'prophet', category: 'things', difficulty: 2),
    // bible:MAT.2.5, conf=0.82, freq=68
  AwingWord(awing: 'ńkɔŋtə̂', english: 'rejoice', category: 'things', difficulty: 1),
    // bible:MAT.2.10, conf=0.43, freq=68
  AwingWord(awing: 'ndim', english: 'brother', category: 'things', difficulty: 1),

    // bible:MAT.8.10, conf=0.54, freq=67
  AwingWord(awing: 'Nə́', english: 'said', category: 'actions', difficulty: 1),

    // bible:MAT.2.4, conf=0.86, freq=66
  AwingWord(awing: 'apá', english: 'bread', category: 'food', difficulty: 1),
    // bible:MAT.4.4, conf=0.52, freq=66
  AwingWord(awing: 'ńtsɛ', english: 'than', category: 'things', difficulty: 1),



    // bible:MAT.4.18, conf=0.89, freq=63
  AwingWord(awing: 'mɔ́mɛ́', english: 'brother', category: 'things', difficulty: 1),
    // bible:MAT.7.3, conf=0.62, freq=63
  AwingWord(awing: 'móg', english: 'fire', category: 'nature', difficulty: 1),

    // bible:MAT.2.5, conf=0.52, freq=60
  AwingWord(awing: 'pətseŋpə́ndɛ́pə́sê', english: 'angels', category: 'things', difficulty: 1),
    // bible:MAT.4.11, conf=0.92, freq=59
  AwingWord(awing: 'fóg', english: 'day', category: 'things', difficulty: 1),
    // bible:MAT.5.32, conf=0.61, freq=59
  AwingWord(awing: 'mbóŋ', english: 'multitude', category: 'things', difficulty: 1),
    // bible:MAT.6.2, conf=0.44, freq=59
  AwingWord(awing: 'apeŋ', english: 'out', category: 'things', difficulty: 1),
    // bible:MAT.9.25, conf=0.54, freq=59
  AwingWord(awing: 'Lɛ̌', english: 'said', category: 'actions', difficulty: 1),
    // bible:MAT.3.17, conf=0.52, freq=58
  AwingWord(awing: 'záʼ', english: 'before', category: 'things', difficulty: 1),
    // bible:MAT.5.24, conf=0.45, freq=58
  AwingWord(awing: 'ndzɛd', english: 'lamb', category: 'animals', difficulty: 1),

    // bible:MAT.5.21, conf=0.61, freq=56
  AwingWord(awing: 'mbéŋ', english: 'lamb', category: 'animals', difficulty: 1),
    // bible:MAT.12.11, conf=0.59, freq=56
  AwingWord(awing: 'mənta', english: 'fruit', category: 'nature', difficulty: 1),


    // bible:MAT.1.2, conf=0.83, freq=52
  AwingWord(awing: 'əlěmbî', english: 'days', category: 'things', difficulty: 1),
    // bible:MAT.4.2, conf=0.79, freq=52
  AwingWord(awing: 'tɔsə', english: 'thousand', category: 'numbers', difficulty: 1),
    // bible:MAT.14.21, conf=0.92, freq=52
  AwingWord(awing: 'Apoŋə', english: 'multitude', category: 'things', difficulty: 1),

    // bible:MAT.7.21, conf=0.96, freq=51
  AwingWord(awing: 'ngweŋ', english: 'priest', category: 'things', difficulty: 1),
    // bible:MAT.11.21, conf=0.69, freq=51
  AwingWord(awing: 'tǎpə', english: 'father', category: 'family', difficulty: 1),
    // bible:MAT.1.2, conf=0.94, freq=50
  AwingWord(awing: 'məkálə́', english: 'bread', category: 'food', difficulty: 1),
    // bible:MAT.4.3, conf=0.66, freq=50
  AwingWord(awing: 'nə́ənə', english: 'sea', category: 'nature', difficulty: 1),
    // bible:MAT.4.15, conf=0.46, freq=50
  AwingWord(awing: 'tsɔ́ʼtə', english: 'judge', category: 'things', difficulty: 1),

    // bible:MAT.27.11, conf=0.78, freq=50
  AwingWord(awing: 'pɔ́pə́mɛ́', english: 'brothers', category: 'things', difficulty: 1),
    // bible:MAT.12.46, conf=0.69, freq=49
  AwingWord(awing: 'nəgháʼə', english: 'glory', category: 'things', difficulty: 2),
    // bible:MAT.19.28, conf=0.71, freq=49
  AwingWord(awing: 'ngɔʼ', english: 'stone', category: 'nature', difficulty: 1),
    // bible:MAT.7.9, conf=0.70, freq=47
  AwingWord(awing: 'Təmbɔʼ', english: 'said', category: 'actions', difficulty: 1),
    // bible:MAT.9.16, conf=0.43, freq=47
  AwingWord(awing: 'pəfo', english: 'kings', category: 'family', difficulty: 1),
    // bible:MAT.2.6, conf=0.57, freq=46
  AwingWord(awing: 'ḿmaʼə̂', english: 'into', category: 'things', difficulty: 1),
    // bible:MAT.5.29, conf=0.48, freq=46
  AwingWord(awing: 'nəlyaŋnə́', english: 'mystery', category: 'things', difficulty: 1),
    // bible:MAT.6.4, conf=0.41, freq=46
  AwingWord(awing: 'ngaŋə́ghɛlə', english: 'sinners', category: 'things', difficulty: 1),
    // bible:MAT.7.11, conf=0.59, freq=46
  AwingWord(awing: 'ńjúmnə', english: 'dead', category: 'things', difficulty: 3),
    // bible:MAT.9.18, conf=0.46, freq=46
  AwingWord(awing: 'ngwǔəə', english: 'fell', category: 'actions', difficulty: 1),
    // bible:MAT.4.6, conf=0.44, freq=45
  AwingWord(awing: 'ngaŋkəpa', english: 'enemies', category: 'things', difficulty: 1),
    // bible:MAT.5.43, conf=0.42, freq=45
  AwingWord(awing: 'nkáʼə', english: 'prison', category: 'things', difficulty: 1),
    // bible:MAT.11.2, conf=0.53, freq=45
  AwingWord(awing: 'alěláʼə́sê', english: 'sabbath', category: 'things', difficulty: 2),

    // bible:MAT.2.22, conf=0.84, freq=44
  AwingWord(awing: 'mógə́', english: 'fire', category: 'nature', difficulty: 1),
    // bible:MAT.3.10, conf=0.66, freq=44
  AwingWord(awing: 'məmbéŋ', english: 'sheep', category: 'animals', difficulty: 1),
    // bible:MAT.7.15, conf=0.84, freq=44
  AwingWord(awing: 'ḿbóʼmbô', english: 'begged', category: 'things', difficulty: 1),

    // bible:MAT.4.21, conf=0.98, freq=42
  AwingWord(awing: 'chaʼtə́sê', english: 'pray', category: 'things', difficulty: 2),
    // bible:MAT.6.5, conf=0.45, freq=42
  AwingWord(awing: 'ńdwɛ́nkə', english: 'full', category: 'descriptive', difficulty: 1),
    // bible:MAT.6.23, conf=0.43, freq=42
  AwingWord(awing: 'Ndzéʼkə', english: 'teacher', category: 'things', difficulty: 1),
    // bible:MAT.8.19, conf=0.71, freq=42
  AwingWord(awing: 'pəkwû', english: 'dead', category: 'things', difficulty: 3),
    // bible:MAT.8.22, conf=0.78, freq=41
  AwingWord(awing: 'ńgweŋə̂', english: 'high', category: 'descriptive', difficulty: 1),
    // bible:MAT.9.24, conf=0.59, freq=41
  AwingWord(awing: 'pɔ́gə', english: 'don', category: 'things', difficulty: 1),
    // bible:MAT.1.20, conf=0.57, freq=40
  AwingWord(awing: 'əjwi', english: 'spirits', category: 'things', difficulty: 1),
    // bible:MAT.8.16, conf=0.70, freq=40
  AwingWord(awing: 'nchîntɨ', english: 'life', category: 'things', difficulty: 1),
    // bible:MAT.18.8, conf=0.93, freq=40
  AwingWord(awing: 'məfaʼ', english: 'works', category: 'actions', difficulty: 1),
    // bible:MAT.5.16, conf=0.85, freq=39
  AwingWord(awing: 'ə́sɛ́n', english: 'today', category: 'things', difficulty: 1),
    // bible:MAT.5.36, conf=0.44, freq=39
  AwingWord(awing: 'nətúʼ', english: 'night', category: 'things', difficulty: 1),
    // bible:MAT.24.43, conf=0.87, freq=39
  AwingWord(awing: 'Zə́m', english: 'fruit', category: 'nature', difficulty: 1),
    // bible:MAT.3.8, conf=0.82, freq=38
  AwingWord(awing: 'ńnô', english: 'drink', category: 'actions', difficulty: 1),
    // bible:MAT.11.18, conf=0.42, freq=38
  AwingWord(awing: 'Ndzáʼkə', english: 'passover', category: 'things', difficulty: 2),
    // bible:MAT.26.2, conf=0.76, freq=38
  AwingWord(awing: 'Mənkyeetə', english: 'assemblies', category: 'things', difficulty: 1),
    // bible:ACT.9.31, conf=0.84, freq=38
  AwingWord(awing: 'ə́fóŋ', english: 'called', category: 'things', difficulty: 1),
    // bible:MAT.2.4, conf=0.41, freq=37
  AwingWord(awing: 'achaʼtə́sê', english: 'prayer', category: 'things', difficulty: 2),
    // bible:MAT.6.7, conf=0.46, freq=37
  AwingWord(awing: 'əka', english: 'covenant', category: 'things', difficulty: 2),
    // bible:MAT.14.7, conf=0.78, freq=37
  AwingWord(awing: 'əshû', english: 'fish', category: 'animals', difficulty: 1),
    // bible:MAT.7.10, conf=0.67, freq=36
  AwingWord(awing: 'apagləpaglə', english: 'cross', category: 'things', difficulty: 1),
    // bible:MAT.10.38, conf=0.58, freq=36
  AwingWord(awing: 'nkɛd', english: 'hundred', category: 'numbers', difficulty: 1),
    // bible:MAT.13.47, conf=0.69, freq=36
  AwingWord(awing: 'apɔ́gə', english: 'fear', category: 'things', difficulty: 2),

    // bible:MAT.4.5, conf=0.89, freq=35
  AwingWord(awing: 'təənə', english: 'right', category: 'things', difficulty: 1),
    // bible:MAT.6.3, conf=0.89, freq=35
  AwingWord(awing: 'nəfɔ', english: 'kingdom', category: 'things', difficulty: 2),
    // bible:MAT.8.12, conf=0.43, freq=35
  AwingWord(awing: 'əfə́g', english: 'blind', category: 'things', difficulty: 1),
    // bible:MAT.8.15, conf=0.51, freq=35
  AwingWord(awing: 'yɛ́d', english: 'signs', category: 'things', difficulty: 1),

    // bible:MAT.27.17, conf=0.89, freq=35
  AwingWord(awing: 'məfɛ̂nə', english: 'gift', category: 'things', difficulty: 1),
    // bible:JHN.4.10, conf=0.57, freq=35
  AwingWord(awing: 'aləŋənə́fɔ', english: 'throne', category: 'things', difficulty: 1),

    // bible:MAT.4.12, conf=0.82, freq=34
  AwingWord(awing: 'ngaŋə́sáʼə́məsáʼ', english: 'council', category: 'things', difficulty: 1),
    // bible:MAT.5.25, conf=0.44, freq=34
  AwingWord(awing: 'ntsǒndɛ̂', english: 'door', category: 'things', difficulty: 1),
    // bible:MAT.6.6, conf=0.53, freq=34
  AwingWord(awing: 'əshî', english: 'face', category: 'body', difficulty: 1),



    // bible:MAT.2.1, conf=0.85, freq=33
  AwingWord(awing: 'azáŋə́ndé', english: 'wrath', category: 'things', difficulty: 3),
    // bible:MAT.3.7, conf=0.76, freq=33
  AwingWord(awing: 'ndzoŋdzəm', english: 'disciple', category: 'things', difficulty: 2),
    // bible:MAT.8.21, conf=0.61, freq=33
  AwingWord(awing: 'atséebə́nə́múʼ', english: 'parable', category: 'things', difficulty: 1),
    // bible:MAT.13.3, conf=0.85, freq=33
  AwingWord(awing: 'tə́kɔʼə', english: 'great', category: 'things', difficulty: 1),
    // bible:MAT.13.32, conf=0.48, freq=33
  AwingWord(awing: 'ntsɛɛmbiə', english: 'first', category: 'descriptive', difficulty: 1),
    // bible:MAT.21.36, conf=0.64, freq=33
  AwingWord(awing: 'laʼnə̂', english: 'promise', category: 'things', difficulty: 1),
    // bible:LUK.1.54, conf=0.45, freq=33
    // bible:MAT.5.27, conf=0.68, freq=31
  AwingWord(awing: 'zɛ́n', english: 'two', category: 'numbers', difficulty: 1),
    // bible:MAT.8.28, conf=0.45, freq=31
  AwingWord(awing: 'akóolə́mə́lə́ŋə', english: 'mercy', category: 'things', difficulty: 2),
    // bible:MAT.9.13, conf=0.74, freq=31
  AwingWord(awing: 'ńdíblə', english: 'around', category: 'things', difficulty: 1),

    // bible:MAT.2.6, conf=0.70, freq=30
  AwingWord(awing: 'məngɔʼ', english: 'stones', category: 'nature', difficulty: 1),
    // bible:MAT.3.9, conf=0.40, freq=30
  AwingWord(awing: 'ŋ́ŋáŋkə', english: 'god', category: 'things', difficulty: 1),
    // bible:MAT.5.16, conf=0.53, freq=30
  AwingWord(awing: 'ntaŋ', english: 'tabernacle', category: 'things', difficulty: 1),


    // bible:MAT.11.25, conf=0.57, freq=30
  AwingWord(awing: 'mə́numə', english: 'sun', category: 'nature', difficulty: 1),
    // bible:MAT.13.6, conf=0.60, freq=30
  AwingWord(awing: 'Ntseŋndɛ̂', english: 'angel', category: 'things', difficulty: 1),
    // bible:MAT.1.20, conf=0.93, freq=29
  AwingWord(awing: 'ńkwěe', english: 'answered', category: 'actions', difficulty: 1),
    // bible:MAT.9.12, conf=0.45, freq=29
  AwingWord(awing: 'ndɔ́ŋ', english: 'cup', category: 'things', difficulty: 1),
    // bible:MAT.10.42, conf=0.90, freq=29
  AwingWord(awing: 'júmkə', english: 'raised', category: 'things', difficulty: 1),

    // bible:MAT.11.14, conf=0.97, freq=29
  AwingWord(awing: 'apoʼ', english: 'free', category: 'things', difficulty: 1),

    // bible:MAT.1.18, conf=0.75, freq=28
  AwingWord(awing: 'məŋkwâʼlə̌', english: 'wilderness', category: 'nature', difficulty: 1),
    // bible:MAT.3.1, conf=0.82, freq=28
    // bible:MAT.4.10, conf=0.57, freq=28
  AwingWord(awing: 'ndzɛnə́', english: 'side', category: 'things', difficulty: 1),
    // bible:MAT.4.15, conf=0.43, freq=28
  AwingWord(awing: 'nəghə́m', english: 'ten', category: 'numbers', difficulty: 1),

    // bible:ACT.9.27, conf=0.71, freq=28
  AwingWord(awing: 'əpa', english: 'another', category: 'things', difficulty: 1),
    // bible:MAT.2.11, conf=0.48, freq=27
  AwingWord(awing: 'nkyaʼə', english: 'light', category: 'nature', difficulty: 1),
    // bible:MAT.5.15, conf=0.70, freq=27
  AwingWord(awing: 'nələ́g', english: 'eye', category: 'body', difficulty: 1),
    // bible:MAT.5.29, conf=0.85, freq=27
  AwingWord(awing: 'məghɔ́d', english: 'ointment', category: 'things', difficulty: 1),
    // bible:MAT.6.17, conf=0.59, freq=27
  AwingWord(awing: 'məsânə', english: 'morning', category: 'things', difficulty: 1),
    // bible:MAT.16.3, conf=0.44, freq=27
  AwingWord(awing: 'əlɛ́nə', english: 'name', category: 'things', difficulty: 1),

    // bible:MAT.22.17, conf=0.74, freq=27
  AwingWord(awing: 'nəchwaakənə́', english: 'beginning', category: 'things', difficulty: 1),
    // bible:MAT.24.21, conf=0.63, freq=27
  AwingWord(awing: 'Əfooghɨ', english: 'sea', category: 'nature', difficulty: 1),
    // bible:MAT.4.13, conf=0.58, freq=26
  AwingWord(awing: 'ngaŋəfaʼə', english: 'servant', category: 'family', difficulty: 1),
    // bible:MAT.8.6, conf=0.46, freq=26
  AwingWord(awing: 'ńkyéŋ', english: 'out', category: 'things', difficulty: 1),
    // bible:MAT.8.29, conf=0.58, freq=26
  AwingWord(awing: 'ńnoŋkə̂', english: 'laid', category: 'things', difficulty: 1),
    // bible:MAT.9.18, conf=0.50, freq=26
  AwingWord(awing: 'ntáʼ', english: 'loaves', category: 'food', difficulty: 1),
    // bible:MAT.14.17, conf=0.73, freq=26
  AwingWord(awing: 'ḿmɛdnə̂', english: 'forever', category: 'things', difficulty: 1),

    // bible:MAT.2.22, conf=0.80, freq=25
  AwingWord(awing: 'ŋáʼ', english: 'opened', category: 'actions', difficulty: 1),
    // bible:MAT.7.7, conf=0.40, freq=25
  AwingWord(awing: 'ndzɛlə', english: 'sheep', category: 'animals', difficulty: 1),
    // bible:MAT.7.15, conf=0.40, freq=25
  AwingWord(awing: 'əkɨʼnəmə́nu', english: 'signs', category: 'things', difficulty: 1),
    // bible:MAT.7.22, conf=0.40, freq=25
  AwingWord(awing: 'kɔ́d', english: 'eat', category: 'actions', difficulty: 1),

    // bible:MAT.8.16, conf=0.40, freq=25
  AwingWord(awing: 'afyaʼə́nu', english: 'sacrifice', category: 'things', difficulty: 2),
    // bible:MAT.9.13, conf=0.44, freq=25
  AwingWord(awing: 'pɔ̂nkə̂', english: 'children', category: 'family', difficulty: 1),
    // bible:MAT.11.25, conf=0.64, freq=25
  AwingWord(awing: 'əkyeʼmə́nu', english: 'signs', category: 'things', difficulty: 1),
    // bible:MAT.16.3, conf=0.92, freq=25
  AwingWord(awing: 'póʼə', english: 'circumcision', category: 'things', difficulty: 3),

    // bible:ACT.16.12, conf=0.92, freq=25
  AwingWord(awing: 'apɔŋə́ntɨ́', english: 'grace', category: 'things', difficulty: 2),
    // bible:ROM.6.15, conf=0.80, freq=25
  AwingWord(awing: 'Mɔ̂', english: 'son', category: 'family', difficulty: 1),
    // bible:MAT.1.23, conf=0.50, freq=24
  AwingWord(awing: 'maʼə̂', english: 'into', category: 'things', difficulty: 1),
    // bible:MAT.3.10, conf=0.50, freq=24
    // bible:MAT.4.1, conf=0.88, freq=24
  AwingWord(awing: 'mələ́ŋ', english: 'mercy', category: 'things', difficulty: 2),
    // bible:MAT.5.7, conf=0.54, freq=24
  AwingWord(awing: 'nchubə', english: 'tax', category: 'things', difficulty: 1),
    // bible:MAT.5.46, conf=0.71, freq=24
  AwingWord(awing: 'mənkǐ', english: 'one', category: 'numbers', difficulty: 1),
    // bible:MAT.7.25, conf=0.42, freq=24
  AwingWord(awing: 'nkwanə́', english: 'evening', category: 'things', difficulty: 1),
    // bible:MAT.8.16, conf=0.79, freq=24
  AwingWord(awing: 'ńjúmkə', english: 'raised', category: 'things', difficulty: 1),
    // bible:MAT.10.8, conf=0.75, freq=24
  AwingWord(awing: 'ŋwíŋ', english: 'sword', category: 'things', difficulty: 3),
    // bible:MAT.10.21, conf=0.88, freq=24
  AwingWord(awing: 'mətôglə', english: 'hear', category: 'things', difficulty: 1),
    // bible:MAT.11.15, conf=0.71, freq=24
  AwingWord(awing: 'ŋáʼnə', english: 'opened', category: 'actions', difficulty: 1),
    // bible:MAT.3.16, conf=0.57, freq=23
  AwingWord(awing: 'jwaʼ', english: 'anxious', category: 'things', difficulty: 2),
    // bible:MAT.6.25, conf=0.43, freq=23
  AwingWord(awing: 'akwaʼlə', english: 'temptation', category: 'things', difficulty: 2),

    // bible:MAT.14.3, conf=0.91, freq=22
  AwingWord(awing: 'pwɔ́d', english: 'weak', category: 'descriptive', difficulty: 1),
    // bible:MAT.24.32, conf=0.41, freq=22
  AwingWord(awing: 'məsáʼ', english: 'one', category: 'numbers', difficulty: 1),
    // bible:MRK.10.42, conf=0.45, freq=22
  AwingWord(awing: 'pəpépə́sê', english: 'priest', category: 'things', difficulty: 1),
    // bible:LUK.6.4, conf=0.45, freq=22
  AwingWord(awing: 'əlam', english: 'body', category: 'things', difficulty: 1),
    // bible:ROM.12.4, conf=0.73, freq=22
  AwingWord(awing: 'pətseŋpə́ndɛ̂', english: 'angels', category: 'things', difficulty: 1),
    // bible:MAT.4.6, conf=0.95, freq=21
  AwingWord(awing: 'kɛ́d', english: 'fire', category: 'nature', difficulty: 1),
    // bible:MAT.4.16, conf=0.48, freq=21
  AwingWord(awing: 'nəpá', english: 'altar', category: 'things', difficulty: 1),
    // bible:MAT.5.24, conf=0.86, freq=21
  AwingWord(awing: 'ńtsɔ́ʼtə', english: 'judgment', category: 'things', difficulty: 2),
    // bible:MAT.7.1, conf=0.48, freq=21
  AwingWord(awing: 'ńgoonə̂', english: 'sick', category: 'descriptive', difficulty: 1),
    // bible:MAT.8.14, conf=0.76, freq=21
  AwingWord(awing: 'ghɛn', english: 'said', category: 'actions', difficulty: 1),
    // bible:MAT.11.4, conf=0.62, freq=21
  AwingWord(awing: 'akóolə́mə́lə́ŋ', english: 'mercy', category: 'things', difficulty: 2),
    // bible:MAT.12.7, conf=0.57, freq=21
  AwingWord(awing: 'mbipú', english: 'seed', category: 'nature', difficulty: 1),


    // bible:ACT.6.5, conf=0.71, freq=21
  AwingWord(awing: 'əsɨ́', english: 'ashamed', category: 'things', difficulty: 1),
    // bible:ROM.1.26, conf=0.43, freq=21
  AwingWord(awing: 'mǎpə', english: 'mother', category: 'family', difficulty: 1),
    // bible:MAT.1.16, conf=0.90, freq=20
  AwingWord(awing: 'ńtsóokə', english: 'down', category: 'things', difficulty: 1),

    // bible:MAT.3.3, conf=0.90, freq=20
  AwingWord(awing: 'tɔ́g', english: 'immediately', category: 'things', difficulty: 1),

    // bible:MAT.4.23, conf=0.45, freq=20
  AwingWord(awing: 'ləəmə̂', english: 'sat', category: 'actions', difficulty: 1),

    // bible:MAT.6.1, conf=0.60, freq=20
  AwingWord(awing: 'ə́sɛ̂nə̌', english: 'today', category: 'things', difficulty: 1),
    // bible:MAT.6.11, conf=0.50, freq=20
  AwingWord(awing: 'ngaŋə́pyáabə', english: 'officers', category: 'things', difficulty: 2),
    // bible:MAT.18.34, conf=0.40, freq=20
  AwingWord(awing: 'nkog', english: 'widow', category: 'things', difficulty: 1),
    // bible:MAT.22.24, conf=0.60, freq=20
  AwingWord(awing: 'achaʼtə', english: 'greet', category: 'actions', difficulty: 1),
    // bible:LUK.1.29, conf=0.45, freq=20
  AwingWord(awing: 'əzɛnə̂', english: 'god', category: 'things', difficulty: 1),
    // bible:LUK.1.75, conf=0.50, freq=20
  AwingWord(awing: 'tɨd', english: 'boast', category: 'things', difficulty: 1),

    // bible:MAT.2.13, conf=0.68, freq=19
  AwingWord(awing: 'lyáŋ', english: 'hidden', category: 'things', difficulty: 1),
    // bible:MAT.5.14, conf=0.58, freq=19
  AwingWord(awing: 'pəpóŋə', english: 'poor', category: 'descriptive', difficulty: 1),
    // bible:MAT.11.5, conf=0.68, freq=19
  AwingWord(awing: 'akyeʼə́nuə', english: 'sign', category: 'things', difficulty: 1),

    // bible:MAT.13.51, conf=0.42, freq=19
  AwingWord(awing: 'akyeʼə́nu', english: 'sign', category: 'things', difficulty: 1),
    // bible:MAT.16.4, conf=0.74, freq=19
  AwingWord(awing: 'chwád', english: 'saved', category: 'actions', difficulty: 1),

    // bible:MRK.16.20, conf=0.95, freq=19
  AwingWord(awing: 'awaamə́ntə́əmə', english: 'perseverance', category: 'things', difficulty: 1),
    // bible:ROM.5.3, conf=0.53, freq=19
  AwingWord(awing: 'ngyaʼə́', english: 'house', category: 'things', difficulty: 1),
    // bible:MAT.1.20, conf=0.44, freq=18
  AwingWord(awing: 'məkoolə', english: 'feet', category: 'body', difficulty: 1),
    // bible:MAT.5.13, conf=0.72, freq=18
  AwingWord(awing: 'pəsə́ŋ', english: 'birds', category: 'animals', difficulty: 1),
    // bible:MAT.6.26, conf=0.78, freq=18
  AwingWord(awing: 'akəkógə́', english: 'foolish', category: 'things', difficulty: 1),
    // bible:MAT.7.26, conf=0.44, freq=18
  AwingWord(awing: 'tǎdndzɔʼə́', english: 'bridegroom', category: 'things', difficulty: 1),
    // bible:MAT.9.15, conf=1.00, freq=18
  AwingWord(awing: 'pəfəg', english: 'blind', category: 'things', difficulty: 1),
    // bible:MAT.9.27, conf=1.00, freq=18
  AwingWord(awing: 'məlɛ́n', english: 'names', category: 'things', difficulty: 1),
    // bible:MAT.10.2, conf=0.44, freq=18
  AwingWord(awing: 'ngəsáŋ', english: 'wheat', category: 'things', difficulty: 1),

    // bible:MAT.15.33, conf=0.61, freq=18
  AwingWord(awing: 'póonə', english: 'children', category: 'family', difficulty: 1),


    // bible:MAT.1.19, conf=0.53, freq=17
  AwingWord(awing: 'ńkwə́ʼtə', english: 'down', category: 'things', difficulty: 1),
    // bible:MAT.2.11, conf=0.53, freq=17
  AwingWord(awing: 'shaʼtə̂', english: 'down', category: 'things', difficulty: 1),
    // bible:MAT.5.17, conf=0.41, freq=17
  AwingWord(awing: 'kəm', english: 'out', category: 'things', difficulty: 1),
    // bible:MAT.8.16, conf=0.76, freq=17
  AwingWord(awing: 'pəmə́nu', english: 'hour', category: 'things', difficulty: 1),


    // bible:MAT.16.13, conf=0.71, freq=17
  AwingWord(awing: 'nəfɛdnə́', english: 'beginning', category: 'things', difficulty: 1),
    // bible:MAT.19.4, conf=0.47, freq=17
  AwingWord(awing: 'Əghâ', english: 'said', category: 'actions', difficulty: 1),

    // bible:MAT.26.47, conf=0.71, freq=17
  AwingWord(awing: 'láʼkə', english: 'god', category: 'things', difficulty: 1),




    // bible:MAT.2.20, conf=0.62, freq=16
  AwingWord(awing: 'ngɔʼə', english: 'stone', category: 'nature', difficulty: 1),

    // bible:MAT.4.13, conf=0.88, freq=16
  AwingWord(awing: 'ńtɔ́g', english: 'immediately', category: 'things', difficulty: 1),
    // bible:MAT.4.22, conf=0.75, freq=16
  AwingWord(awing: 'məndɛ̂', english: 'synagogues', category: 'things', difficulty: 1),
    // bible:MAT.4.23, conf=0.50, freq=16
  AwingWord(awing: 'məghɔ', english: 'out', category: 'things', difficulty: 1),
    // bible:MAT.4.23, conf=0.44, freq=16
  AwingWord(awing: 'alamə́', english: 'members', category: 'things', difficulty: 1),
    // bible:MAT.5.29, conf=0.56, freq=16
  AwingWord(awing: 'ntsǒnkáʼ', english: 'gate', category: 'things', difficulty: 1),
    // bible:MAT.7.13, conf=0.44, freq=16
  AwingWord(awing: 'kəfɨd', english: 'wind', category: 'nature', difficulty: 1),
    // bible:MAT.8.26, conf=0.81, freq=16
  AwingWord(awing: 'pəkwúna', english: 'pigs', category: 'animals', difficulty: 1),
    // bible:MAT.8.30, conf=0.81, freq=16
  AwingWord(awing: 'ńkwum', english: 'touched', category: 'things', difficulty: 1),
    // bible:MAT.9.20, conf=0.50, freq=16
  AwingWord(awing: 'məfag', english: 'branches', category: 'nature', difficulty: 1),
    // bible:MAT.13.32, conf=0.62, freq=16
  AwingWord(awing: 'ayáŋ', english: 'wisdom', category: 'things', difficulty: 2),
    // bible:MAT.13.54, conf=0.81, freq=16
  AwingWord(awing: 'kwɛlə̂', english: 'poured', category: 'actions', difficulty: 1),



    // bible:MAT.27.32, conf=0.88, freq=16
  AwingWord(awing: 'kwíŋ', english: 'god', category: 'things', difficulty: 1),
    // bible:LUK.2.52, conf=0.50, freq=16
  AwingWord(awing: 'pəlú', english: 'husbands', category: 'family', difficulty: 1),

    // bible:MAT.1.2, conf=1.00, freq=15
  AwingWord(awing: 'ŋ́ŋáʼ', english: 'opened', category: 'actions', difficulty: 1),

    // bible:MAT.3.2, conf=0.53, freq=15
  AwingWord(awing: 'mənoŋ', english: 'hair', category: 'body', difficulty: 1),
    // bible:MAT.3.4, conf=0.80, freq=15
  AwingWord(awing: 'kwaʼlə̂', english: 'tempted', category: 'actions', difficulty: 2),
    // bible:MAT.4.1, conf=0.47, freq=15
  AwingWord(awing: 'ńtwə́ŋə', english: 'buried', category: 'things', difficulty: 1),

    // bible:MAT.10.3, conf=0.93, freq=15
  AwingWord(awing: 'yáŋ', english: 'wise', category: 'things', difficulty: 1),
    // bible:MAT.11.25, conf=0.60, freq=15
  AwingWord(awing: 'Alěláʼsê', english: 'sabbath', category: 'things', difficulty: 2),
    // bible:MAT.12.1, conf=1.00, freq=15
  AwingWord(awing: 'ńkɔ́lə', english: 'eat', category: 'actions', difficulty: 1),

    // bible:MAT.13.56, conf=0.67, freq=15
  AwingWord(awing: 'wad', english: 'covenant', category: 'things', difficulty: 2),
    // bible:MAT.14.7, conf=0.47, freq=15
  AwingWord(awing: 'jú', english: 'buy', category: 'actions', difficulty: 1),
    // bible:MAT.14.15, conf=0.40, freq=15
  AwingWord(awing: 'alə́m', english: 'cloud', category: 'nature', difficulty: 1),

    // bible:MAT.16.17, conf=0.40, freq=15
  AwingWord(awing: 'pəkog', english: 'widows', category: 'things', difficulty: 1),
    // bible:MAT.23.13, conf=0.93, freq=15
  AwingWord(awing: 'Əkəkóg', english: 'foolish', category: 'things', difficulty: 1),

    // bible:MAT.24.3, conf=0.53, freq=15
  AwingWord(awing: 'ńtsɛntə̂', english: 'together', category: 'things', difficulty: 1),
    // bible:MAT.26.3, conf=0.60, freq=15
  AwingWord(awing: 'nkaŋŋwu', english: 'young', category: 'descriptive', difficulty: 1),
    // bible:MRK.14.51, conf=0.60, freq=15
  AwingWord(awing: 'ndíʼ', english: 'smoke', category: 'things', difficulty: 1),
    // bible:MRK.16.18, conf=0.73, freq=15
  AwingWord(awing: 'ńchaʼtə̂', english: 'greet', category: 'actions', difficulty: 1),

    // bible:LUK.16.20, conf=0.73, freq=15
  AwingWord(awing: 'pəshunə́', english: 'beloved', category: 'things', difficulty: 1),
    // bible:LUK.23.12, conf=0.67, freq=15
  AwingWord(awing: 'əpoʼə', english: 'righteousness', category: 'things', difficulty: 2),



    // bible:ACT.24.27, conf=0.80, freq=15
  AwingWord(awing: 'kɔntə̂', english: 'without', category: 'things', difficulty: 1),

    // bible:MAT.1.2, conf=0.93, freq=14
  AwingWord(awing: 'Əsê', english: 'god', category: 'things', difficulty: 1),

    // bible:MAT.4.13, conf=0.93, freq=14
  AwingWord(awing: 'ngaŋə́kwáalə́', english: 'tax', category: 'things', difficulty: 1),
    // bible:MAT.5.46, conf=1.00, freq=14
  AwingWord(awing: 'pəzə̌', english: 'robbers', category: 'things', difficulty: 1),
    // bible:MAT.6.19, conf=0.57, freq=14
  AwingWord(awing: 'nchîndɛ̂', english: 'house', category: 'things', difficulty: 1),
    // bible:MAT.9.6, conf=0.71, freq=14
  AwingWord(awing: 'koʼlə̂', english: 'faith', category: 'things', difficulty: 1),
    // bible:MAT.11.6, conf=0.43, freq=14
  AwingWord(awing: 'lá', english: 'understand', category: 'things', difficulty: 1),
    // bible:MAT.13.19, conf=0.57, freq=14
  AwingWord(awing: 'Jwə́ʼtə', english: 'said', category: 'actions', difficulty: 1),
    // bible:MAT.15.10, conf=0.64, freq=14
  AwingWord(awing: 'Akwaŋə́nuə', english: 'god', category: 'things', difficulty: 1),
    // bible:MAT.16.23, conf=0.43, freq=14
  AwingWord(awing: 'nəpuʼə́', english: 'nine', category: 'numbers', difficulty: 1),

    // bible:MAT.21.17, conf=0.86, freq=14
  AwingWord(awing: 'ndzə̌lə', english: 'thief', category: 'things', difficulty: 3),
    // bible:MAT.24.43, conf=0.71, freq=14
  AwingWord(awing: 'məndú', english: 'god', category: 'things', difficulty: 1),

    // bible:ACT.8.3, conf=0.57, freq=14
  AwingWord(awing: 'pələəmə́', english: 'horses', category: 'animals', difficulty: 1),
    // bible:ACT.8.28, conf=0.57, freq=14
  AwingWord(awing: 'lɔ́btə', english: 'god', category: 'things', difficulty: 1),
    // bible:ACT.9.24, conf=0.57, freq=14
  AwingWord(awing: 'afyaʼə́', english: 'strife', category: 'things', difficulty: 1),
    // bible:ACT.23.7, conf=0.50, freq=14
  AwingWord(awing: 'ə́fyagə̂', english: 'perfect', category: 'descriptive', difficulty: 1),

    // bible:MAT.3.1, conf=1.00, freq=13
  AwingWord(awing: 'kə́ʼ', english: 'measure', category: 'things', difficulty: 1),
    // bible:MAT.3.10, conf=0.54, freq=13
  AwingWord(awing: 'əpí', english: 'clothing', category: 'things', difficulty: 1),


    // bible:MAT.4.19, conf=0.62, freq=13
  AwingWord(awing: 'kwɛd', english: 'out', category: 'things', difficulty: 1),
    // bible:MAT.5.13, conf=0.54, freq=13
  AwingWord(awing: 'zô', english: 'eye', category: 'body', difficulty: 1),
    // bible:MAT.5.29, conf=0.54, freq=13
  AwingWord(awing: 'əsêndú', english: 'god', category: 'things', difficulty: 1),
    // bible:MAT.7.2, conf=0.46, freq=13
  AwingWord(awing: 'Mbəŋ', english: 'rain', category: 'nature', difficulty: 1),
    // bible:MAT.7.25, conf=0.69, freq=13
  AwingWord(awing: 'mənka', english: 'baskets', category: 'things', difficulty: 1),
    // bible:MAT.8.20, conf=0.62, freq=13
  AwingWord(awing: 'ḿbyáanə', english: 'take', category: 'things', difficulty: 1),
    // bible:MAT.9.6, conf=0.46, freq=13
  AwingWord(awing: 'əfoʼ', english: 'rich', category: 'descriptive', difficulty: 1),
    // bible:MAT.9.38, conf=0.62, freq=13
  AwingWord(awing: 'zɔ', english: 'blasphemy', category: 'things', difficulty: 1),
    // bible:MAT.12.31, conf=0.46, freq=13
  AwingWord(awing: 'yǐ', english: 'said', category: 'actions', difficulty: 1),
    // bible:MAT.14.18, conf=0.54, freq=13
  AwingWord(awing: 'pəghɔ', english: 'sick', category: 'descriptive', difficulty: 1),
    // bible:MAT.14.35, conf=0.85, freq=13
  AwingWord(awing: 'mbóomə', english: 'god', category: 'things', difficulty: 1),
    // bible:MAT.15.3, conf=0.46, freq=13
  AwingWord(awing: 'sháŋ', english: 'man', category: 'things', difficulty: 1),
    // bible:MAT.15.38, conf=0.46, freq=13
  AwingWord(awing: 'nəghə́mə', english: 'ten', category: 'numbers', difficulty: 1),
    // bible:MAT.18.28, conf=0.77, freq=13
  AwingWord(awing: 'sɔb', english: 'against', category: 'things', difficulty: 1),
    // bible:MAT.24.7, conf=0.85, freq=13
  AwingWord(awing: 'alěmbî', english: 'day', category: 'things', difficulty: 1),
    // bible:MAT.24.36, conf=0.85, freq=13
  AwingWord(awing: 'fúfú', english: 'white', category: 'descriptive', difficulty: 1),
    // bible:MAT.27.59, conf=0.46, freq=13
  AwingWord(awing: 'əshɨ́', english: 'ashamed', category: 'things', difficulty: 1),

    // bible:ACT.25.13, conf=0.85, freq=13
  AwingWord(awing: 'achǐ', english: 'blood', category: 'things', difficulty: 1),

    // bible:MAT.1.2, conf=0.92, freq=12
  AwingWord(awing: 'nɔd', english: 'god', category: 'things', difficulty: 1),

    // bible:MAT.10.3, conf=0.92, freq=12
  AwingWord(awing: 'mbaŋ', english: 'mustard', category: 'things', difficulty: 1),
    // bible:MAT.10.10, conf=0.42, freq=12
  AwingWord(awing: 'Mbwɔ́dnə', english: 'said', category: 'actions', difficulty: 1),

    // bible:MAT.11.21, conf=1.00, freq=12
  AwingWord(awing: 'ńkwɛlə̂', english: 'into', category: 'things', difficulty: 1),
    // bible:MAT.13.48, conf=0.50, freq=12
  AwingWord(awing: 'akáŋ', english: 'poured', category: 'actions', difficulty: 1),
    // bible:MAT.14.11, conf=0.42, freq=12
  AwingWord(awing: 'ḿbagtə̂', english: 'broke', category: 'actions', difficulty: 1),
    // bible:MAT.14.19, conf=0.83, freq=12
  AwingWord(awing: 'fig', english: 'tree', category: 'nature', difficulty: 1),
    // bible:MAT.21.19, conf=0.92, freq=12
  AwingWord(awing: 'məngɔʼə', english: 'stones', category: 'nature', difficulty: 1),
    // bible:MAT.21.35, conf=0.42, freq=12
  AwingWord(awing: 'lə́ʼ', english: 'escape', category: 'actions', difficulty: 1),

    // bible:MAT.27.16, conf=0.92, freq=12
  AwingWord(awing: 'lɛn', english: 'old', category: 'descriptive', difficulty: 1),

    // bible:LUK.17.11, conf=0.83, freq=12
  AwingWord(awing: 'zɔ́b', english: 'officer', category: 'things', difficulty: 2),


    // bible:ACT.4.36, conf=0.75, freq=12
  AwingWord(awing: 'nəkaʼ', english: 'remains', category: 'things', difficulty: 1),
    // bible:ROM.6.3, conf=0.50, freq=12
  AwingWord(awing: 'ə́fyag', english: 'perfect', category: 'descriptive', difficulty: 1),
    // bible:1CO.13.9, conf=0.50, freq=12
  AwingWord(awing: 'nətúʼə', english: 'night', category: 'things', difficulty: 1),
    // bible:MAT.2.14, conf=1.00, freq=11
  AwingWord(awing: 'kə́yé', english: 'children', category: 'family', difficulty: 1),

    // bible:MAT.2.23, conf=0.91, freq=11
  AwingWord(awing: 'mənteemə́', english: 'fruit', category: 'nature', difficulty: 1),
    // bible:MAT.3.8, conf=0.82, freq=11
  AwingWord(awing: 'ngwɛʼə́', english: 'tomorrow', category: 'things', difficulty: 1),
    // bible:MAT.6.30, conf=1.00, freq=11
  AwingWord(awing: 'ńtoonə̂', english: 'burned', category: 'things', difficulty: 1),

    // bible:MAT.10.4, conf=1.00, freq=11
  AwingWord(awing: 'ngɔ́n', english: 'darnel', category: 'things', difficulty: 1),
    // bible:MAT.13.26, conf=0.55, freq=11
  AwingWord(awing: 'atǐəpagləpaglə', english: 'cross', category: 'things', difficulty: 1),

    // bible:MAT.23.35, conf=0.73, freq=11
  AwingWord(awing: 'məŋnkwəənə', english: 'mountains', category: 'nature', difficulty: 1),
    // bible:MAT.24.16, conf=0.82, freq=11
  AwingWord(awing: 'nəfaŋ', english: 'thunders', category: 'things', difficulty: 1),
    // bible:MAT.24.27, conf=0.45, freq=11
    // bible:MAT.25.38, conf=0.82, freq=11
  AwingWord(awing: 'məloʼə', english: 'wine', category: 'food', difficulty: 1),
    // bible:MRK.15.23, conf=0.45, freq=11
  AwingWord(awing: 'Mmaʼmbîə', english: 'lord', category: 'things', difficulty: 3),
    // bible:LUK.1.25, conf=1.00, freq=11
  AwingWord(awing: 'achîəndɛ̂', english: 'foundation', category: 'things', difficulty: 1),
    // bible:LUK.6.48, conf=0.73, freq=11
  AwingWord(awing: 'ńdzoŋkə̂', english: 'second', category: 'numbers', difficulty: 1),
    // bible:ACT.7.13, conf=0.82, freq=11
  AwingWord(awing: 'mətûə', english: 'elders', category: 'family', difficulty: 2),



    // bible:MAT.4.21, conf=1.00, freq=10
  AwingWord(awing: 'ntsɔ́ʼəfaʼə', english: 'reward', category: 'things', difficulty: 2),
    // bible:MAT.5.12, conf=0.70, freq=10
  AwingWord(awing: 'ngaŋmə́fɨg', english: 'hypocrites', category: 'things', difficulty: 1),
    // bible:MAT.6.2, conf=0.70, freq=10
  AwingWord(awing: 'ngaŋmə́fɨgə', english: 'hypocrites', category: 'things', difficulty: 1),
    // bible:MAT.6.5, conf=1.00, freq=10
  AwingWord(awing: 'məshî', english: 'faces', category: 'body', difficulty: 1),
    // bible:MAT.6.16, conf=0.70, freq=10
  AwingWord(awing: 'ajɨ́', english: 'said', category: 'actions', difficulty: 1),
    // bible:MAT.6.17, conf=0.40, freq=10
  AwingWord(awing: 'ńtɛ̂', english: 'sun', category: 'nature', difficulty: 1),
    // bible:MAT.6.28, conf=0.50, freq=10
  AwingWord(awing: 'məmí', english: 'own', category: 'things', difficulty: 1),
    // bible:MAT.6.34, conf=0.40, freq=10
  AwingWord(awing: 'ńtə́m', english: 'lots', category: 'things', difficulty: 1),
    // bible:MAT.7.25, conf=0.40, freq=10
  AwingWord(awing: 'ńkwéʼnə', english: 'even', category: 'things', difficulty: 1),
    // bible:MAT.8.26, conf=0.40, freq=10
  AwingWord(awing: 'nəlwî', english: 'touched', category: 'things', difficulty: 1),

    // bible:MAT.10.7, conf=0.90, freq=10
  AwingWord(awing: 'pəmǎ', english: 'parents', category: 'things', difficulty: 1),
    // bible:MAT.10.21, conf=0.60, freq=10
  AwingWord(awing: 'mə́lə́glə', english: 'shadow', category: 'nature', difficulty: 1),

    // bible:MAT.12.39, conf=1.00, freq=10
  AwingWord(awing: 'məŋaŋ', english: 'root', category: 'nature', difficulty: 1),
    // bible:MAT.13.6, conf=0.70, freq=10
  AwingWord(awing: 'ətsábnə́múʼ', english: 'parables', category: 'things', difficulty: 2),

    // bible:MAT.14.16, conf=0.50, freq=10
  AwingWord(awing: 'əpuʼ', english: 'baskets', category: 'things', difficulty: 1),
    // bible:MAT.14.20, conf=0.70, freq=10
  AwingWord(awing: 'mələ́ŋə', english: 'mercy', category: 'things', difficulty: 2),
    // bible:MAT.15.22, conf=0.70, freq=10
  AwingWord(awing: 'ŋwuntə̂', english: 'murmured', category: 'things', difficulty: 1),
    // bible:MAT.20.11, conf=0.40, freq=10
  AwingWord(awing: 'ə́sog', english: 'said', category: 'actions', difficulty: 1),
    // bible:MAT.23.26, conf=0.40, freq=10
  AwingWord(awing: 'pəlê', english: 'sleep', category: 'actions', difficulty: 1),
    // bible:MAT.25.5, conf=0.50, freq=10
  AwingWord(awing: 'ńjúnə', english: 'bought', category: 'actions', difficulty: 1),
    // bible:MAT.27.7, conf=0.50, freq=10
  AwingWord(awing: 'ńgɔ', english: 'sick', category: 'descriptive', difficulty: 1),
    // bible:MRK.5.25, conf=0.60, freq=10
  AwingWord(awing: 'məndɔ́ŋ', english: 'horns', category: 'things', difficulty: 1),

    // bible:LUK.1.5, conf=0.80, freq=10
  AwingWord(awing: 'ngɛdtəpɔŋə', english: 'sinner', category: 'things', difficulty: 2),
    // bible:LUK.5.8, conf=0.60, freq=10
  AwingWord(awing: 'Ghə́glə', english: 'quickly', category: 'things', difficulty: 1),
    // bible:LUK.14.21, conf=0.40, freq=10
  AwingWord(awing: 'tə́mtə', english: 'stone', category: 'nature', difficulty: 1),
    // bible:LUK.20.6, conf=0.60, freq=10
  AwingWord(awing: 'ńdjɨ́', english: 'said', category: 'actions', difficulty: 1),
    // bible:JHN.7.48, conf=0.40, freq=10
  AwingWord(awing: 'ngaŋntsəələ', english: 'liar', category: 'things', difficulty: 1),



    // bible:ACT.18.12, conf=1.00, freq=10
  AwingWord(awing: 'kətɨd', english: 'boasting', category: 'things', difficulty: 1),
    // bible:ROM.15.17, conf=0.60, freq=10
  AwingWord(awing: 'asəgə́ndzɔʼə', english: 'lord', category: 'things', difficulty: 3),


    // bible:MAT.3.6, conf=1.00, freq=9
  AwingWord(awing: 'mənó', english: 'serpents', category: 'animals', difficulty: 1),
    // bible:MAT.3.7, conf=0.56, freq=9
  AwingWord(awing: 'sɛlə̂', english: 'become', category: 'things', difficulty: 1),
    // bible:MAT.4.3, conf=0.56, freq=9
  AwingWord(awing: 'pəghoonə́', english: 'sick', category: 'descriptive', difficulty: 1),
    // bible:MAT.4.24, conf=0.67, freq=9
  AwingWord(awing: 'tɛ̂', english: 'sun', category: 'nature', difficulty: 1),
    // bible:MAT.5.45, conf=0.44, freq=9
  AwingWord(awing: 'fyag', english: 'perfect', category: 'descriptive', difficulty: 1),
    // bible:MAT.5.48, conf=0.67, freq=9
  AwingWord(awing: 'kwaabə', english: 'right', category: 'things', difficulty: 1),
    // bible:MAT.6.3, conf=0.89, freq=9
  AwingWord(awing: 'achaʼtə́sênji', english: 'fast', category: 'descriptive', difficulty: 2),
    // bible:MAT.6.16, conf=0.67, freq=9
  AwingWord(awing: 'póʼtə', english: 'opened', category: 'actions', difficulty: 1),

    // bible:MAT.8.2, conf=0.44, freq=9
  AwingWord(awing: 'nkweglə', english: 'paralytic', category: 'things', difficulty: 1),
    // bible:MAT.9.2, conf=0.78, freq=9
  AwingWord(awing: 'pəkwûə', english: 'dead', category: 'things', difficulty: 3),
    // bible:MAT.10.8, conf=0.78, freq=9
  AwingWord(awing: 'asáʼə́məsáʼ', english: 'judgment', category: 'things', difficulty: 2),
    // bible:MAT.10.15, conf=0.67, freq=9
  AwingWord(awing: 'ńdzɔb', english: 'one', category: 'numbers', difficulty: 1),

    // bible:MAT.12.14, conf=0.44, freq=9
  AwingWord(awing: 'ńjú', english: 'bought', category: 'actions', difficulty: 1),
    // bible:MAT.13.44, conf=0.44, freq=9
  AwingWord(awing: 'Fɛ̂', english: 'give', category: 'actions', difficulty: 1),
    // bible:MAT.14.8, conf=0.56, freq=9
  AwingWord(awing: 'ńtsəŋ', english: 'ointment', category: 'things', difficulty: 1),
    // bible:MAT.15.19, conf=0.67, freq=9
  AwingWord(awing: 'təpɛlə', english: 'table', category: 'things', difficulty: 1),
    // bible:MAT.15.27, conf=0.78, freq=9
  AwingWord(awing: 'chúʼ', english: 'one', category: 'numbers', difficulty: 1),

    // bible:MAT.21.9, conf=0.67, freq=9
  AwingWord(awing: 'Ə́sɛdkə̂', english: 'into', category: 'things', difficulty: 1),
    // bible:MAT.21.12, conf=0.44, freq=9
  AwingWord(awing: 'ətəənə́', english: 'anchors', category: 'things', difficulty: 1),

    // bible:MAT.23.15, conf=0.67, freq=9
  AwingWord(awing: 'lə́g', english: 'unless', category: 'things', difficulty: 1),
    // bible:MAT.24.22, conf=0.44, freq=9
  AwingWord(awing: 'məfǔ', english: 'tree', category: 'nature', difficulty: 1),
    // bible:MAT.24.32, conf=0.56, freq=9
  AwingWord(awing: 'məŋwíŋ', english: 'swords', category: 'things', difficulty: 1),

    // bible:MRK.2.14, conf=0.67, freq=9
  AwingWord(awing: 'ənumnə', english: 'day', category: 'things', difficulty: 1),
    // bible:MRK.4.27, conf=0.67, freq=9
  AwingWord(awing: 'əŋkənúʼə́', english: 'boats', category: 'things', difficulty: 1),
    // bible:MRK.4.36, conf=0.67, freq=9
  AwingWord(awing: 'gleb', english: 'vineyard', category: 'things', difficulty: 1),
    // bible:MRK.12.2, conf=0.56, freq=9
  AwingWord(awing: 'ḿbɛ́nkə', english: 'trembling', category: 'things', difficulty: 1),
    // bible:MRK.16.8, conf=0.78, freq=9
  AwingWord(awing: 'əmə́gə', english: 'eyes', category: 'body', difficulty: 1),
    // bible:LUK.2.30, conf=0.44, freq=9
  AwingWord(awing: 'nənumnə', english: 'day', category: 'things', difficulty: 1),
    // bible:LUK.2.37, conf=1.00, freq=9
  AwingWord(awing: 'gɔbnɔ', english: 'proconsul', category: 'things', difficulty: 1),
    // bible:LUK.3.1, conf=0.56, freq=9
  AwingWord(awing: 'ə́fɨgə̂', english: 'deceived', category: 'things', difficulty: 1),
    // bible:LUK.19.8, conf=0.44, freq=9
  AwingWord(awing: 'atəəmə́tɨ́', english: 'vision', category: 'things', difficulty: 1),
    // bible:LUK.24.23, conf=0.78, freq=9
  AwingWord(awing: 'pəfúfú', english: 'white', category: 'descriptive', difficulty: 1),





    // bible:ACT.23.24, conf=0.78, freq=9
  AwingWord(awing: 'ndɔtí', english: 'god', category: 'things', difficulty: 1),
    // bible:ROM.1.24, conf=0.44, freq=9
  AwingWord(awing: 'pəzéʼkə', english: 'teachers', category: 'things', difficulty: 1),

    // bible:2CO.2.13, conf=1.00, freq=9
  AwingWord(awing: 'əpúmə́tsəŋkə', english: 'plagues', category: 'things', difficulty: 1),

    // bible:MAT.1.3, conf=0.75, freq=8
  AwingWord(awing: 'aləŋənə́foonə', english: 'throne', category: 'things', difficulty: 1),
    // bible:MAT.5.34, conf=1.00, freq=8
  AwingWord(awing: 'mbǒʼḿbóʼ', english: 'immorality', category: 'things', difficulty: 3),
    // bible:MAT.6.7, conf=0.50, freq=8
  AwingWord(awing: 'ńkə́g', english: 'faith', category: 'things', difficulty: 1),
    // bible:MAT.6.30, conf=0.62, freq=8
  AwingWord(awing: 'záʼə', english: 'first', category: 'descriptive', difficulty: 1),
    // bible:MAT.8.21, conf=0.75, freq=8
  AwingWord(awing: 'sə́mə', english: 'wind', category: 'nature', difficulty: 1),
    // bible:MAT.8.24, conf=0.50, freq=8
  AwingWord(awing: 'akəpóglə́', english: 'dust', category: 'nature', difficulty: 1),
    // bible:MAT.10.14, conf=0.88, freq=8
  AwingWord(awing: 'Ndzoŋdzəmə', english: 'disciple', category: 'things', difficulty: 2),
    // bible:MAT.10.24, conf=0.62, freq=8
  AwingWord(awing: 'Fiʼtə̂', english: 'tell', category: 'actions', difficulty: 1),
    // bible:MAT.13.36, conf=0.62, freq=8
  AwingWord(awing: 'ḿbɛ́nə', english: 'came', category: 'actions', difficulty: 1),


    // bible:MAT.15.31, conf=0.62, freq=8
  AwingWord(awing: 'nəkyɛ́', english: 'lord', category: 'things', difficulty: 3),
    // bible:MAT.18.25, conf=0.62, freq=8
  AwingWord(awing: 'ngaŋnəpad', english: 'neighbor', category: 'family', difficulty: 1),

    // bible:MAT.19.26, conf=0.50, freq=8
  AwingWord(awing: 'aləŋə', english: 'throne', category: 'things', difficulty: 1),

    // bible:MAT.21.1, conf=1.00, freq=8
  AwingWord(awing: 'ńchiʼnə̂', english: 'earthquake', category: 'things', difficulty: 1),
    // bible:MAT.21.10, conf=0.88, freq=8
  AwingWord(awing: 'yɛ́ɛlə', english: 'out', category: 'things', difficulty: 1),
    // bible:MAT.26.5, conf=0.50, freq=8
  AwingWord(awing: 'aŋkəʼə́', english: 'rooster', category: 'animals', difficulty: 1),
    // bible:MAT.26.34, conf=1.00, freq=8
  AwingWord(awing: 'ńchwegə̂', english: 'kiss', category: 'things', difficulty: 1),
    // bible:MAT.26.48, conf=0.50, freq=8
  AwingWord(awing: 'ńgyɛ́ɛlə', english: 'out', category: 'things', difficulty: 1),
    // bible:MAT.27.24, conf=0.62, freq=8
  AwingWord(awing: 'paŋpaŋə', english: 'purple', category: 'things', difficulty: 1),
    // bible:MAT.27.28, conf=0.62, freq=8
  AwingWord(awing: 'ńtóŋ', english: 'tomb', category: 'things', difficulty: 3),

    // bible:MAT.27.56, conf=1.00, freq=8
  AwingWord(awing: 'nkǎŋkǐ', english: 'sea', category: 'nature', difficulty: 1),

    // bible:MRK.3.18, conf=0.50, freq=8
  AwingWord(awing: 'atɔ́gə', english: 'room', category: 'things', difficulty: 1),
    // bible:MRK.14.14, conf=0.88, freq=8
  AwingWord(awing: 'atéemə́təndwegtə', english: 'abyss', category: 'things', difficulty: 1),
    // bible:LUK.8.31, conf=1.00, freq=8
  AwingWord(awing: 'mənchwa', english: 'divided', category: 'things', difficulty: 1),
    // bible:LUK.11.17, conf=0.50, freq=8
  AwingWord(awing: 'məngoʼ', english: 'years', category: 'things', difficulty: 1),
    // bible:LUK.12.19, conf=0.75, freq=8
  AwingWord(awing: 'límkə', english: 'harm', category: 'things', difficulty: 1),
    // bible:LUK.12.46, conf=0.62, freq=8
  AwingWord(awing: 'pəfoʼ', english: 'rich', category: 'descriptive', difficulty: 1),
    // bible:LUK.21.1, conf=0.75, freq=8
  AwingWord(awing: 'kɛ́lə', english: 'light', category: 'nature', difficulty: 1),
    // bible:JHN.1.5, conf=0.50, freq=8
  AwingWord(awing: 'ŋáʼkə', english: 'open', category: 'actions', difficulty: 1),
    // bible:JHN.9.17, conf=0.50, freq=8
  AwingWord(awing: 'fwɔn', english: 'one', category: 'numbers', difficulty: 1),

    // bible:ACT.9.19, conf=1.00, freq=8
  AwingWord(awing: 'kwéŋə', english: 'things', category: 'things', difficulty: 1),


    // bible:ACT.18.21, conf=0.75, freq=8
  AwingWord(awing: 'Sɛləba', english: 'silver', category: 'things', difficulty: 1),

    // bible:ROM.5.14, conf=0.75, freq=8
  AwingWord(awing: 'məshú', english: 'god', category: 'things', difficulty: 1),
    // bible:1CO.15.39, conf=0.50, freq=8
  AwingWord(awing: 'asəgə́ndzɔʼ', english: 'perseverance', category: 'things', difficulty: 1),
    // bible:COL.1.11, conf=0.50, freq=8
  AwingWord(awing: 'fɨdnû', english: 'opened', category: 'actions', difficulty: 1),


    // bible:MAT.1.17, conf=0.71, freq=7
  AwingWord(awing: 'əsáʼmə́nu', english: 'east', category: 'things', difficulty: 1),
    // bible:MAT.2.1, conf=0.71, freq=7
  AwingWord(awing: 'məŋkɛlə́', english: 'boat', category: 'things', difficulty: 1),
    // bible:MAT.4.21, conf=0.43, freq=7
  AwingWord(awing: 'pəkɔ́ŋə́sê', english: 'lame', category: 'things', difficulty: 1),
    // bible:MAT.4.24, conf=0.86, freq=7
  AwingWord(awing: 'nkwə́ŋ', english: 'own', category: 'things', difficulty: 1),
    // bible:MAT.7.3, conf=0.43, freq=7
  AwingWord(awing: 'ńkə́gə', english: 'few', category: 'numbers', difficulty: 1),

    // bible:MAT.8.13, conf=0.43, freq=7
  AwingWord(awing: 'mɛ́nə', english: 'god', category: 'things', difficulty: 1),
    // bible:MAT.8.17, conf=0.57, freq=7
  AwingWord(awing: 'Zoŋə̂', english: 'follow', category: 'actions', difficulty: 1),
    // bible:MAT.8.22, conf=1.00, freq=7
  AwingWord(awing: 'ńtsə́g', english: 'out', category: 'things', difficulty: 1),
    // bible:MAT.8.28, conf=0.71, freq=7
  AwingWord(awing: 'fɨ́dkə', english: 'out', category: 'things', difficulty: 1),

    // bible:MAT.9.2, conf=0.86, freq=7
  AwingWord(awing: 'nkwânchubə', english: 'tax', category: 'things', difficulty: 1),
    // bible:MAT.9.9, conf=1.00, freq=7
  AwingWord(awing: 'ńnɨ́', english: 'sat', category: 'actions', difficulty: 1),
    // bible:MAT.9.10, conf=0.43, freq=7
  AwingWord(awing: 'ngɔ́d', english: 'through', category: 'things', difficulty: 1),
    // bible:MAT.9.16, conf=0.86, freq=7
  AwingWord(awing: 'ńkəm', english: 'out', category: 'things', difficulty: 1),
    // bible:MAT.9.33, conf=0.86, freq=7
  AwingWord(awing: 'pətɔ̂ŋ', english: 'city', category: 'things', difficulty: 1),
    // bible:MAT.11.1, conf=0.57, freq=7
  AwingWord(awing: 'chiʼ', english: 'shaken', category: 'things', difficulty: 1),


    // bible:MAT.11.22, conf=1.00, freq=7
  AwingWord(awing: 'Noŋkə', english: 'lawful', category: 'things', difficulty: 1),
    // bible:MAT.12.10, conf=1.00, freq=7
  AwingWord(awing: 'ńtég', english: 'came', category: 'actions', difficulty: 1),

    // bible:MAT.12.47, conf=1.00, freq=7
  AwingWord(awing: 'məsɔbsɔb', english: 'thorns', category: 'things', difficulty: 1),
    // bible:MAT.13.7, conf=1.00, freq=7
  AwingWord(awing: 'mbəm', english: 'fruit', category: 'nature', difficulty: 1),
    // bible:MAT.13.8, conf=1.00, freq=7
  AwingWord(awing: 'nətáŋ', english: 'riches', category: 'things', difficulty: 1),
    // bible:MAT.13.22, conf=0.43, freq=7
  AwingWord(awing: 'əkáŋ', english: 'angels', category: 'things', difficulty: 1),
    // bible:MAT.13.33, conf=0.57, freq=7
  AwingWord(awing: 'asəgə́', english: 'land', category: 'things', difficulty: 1),

    // bible:MAT.14.35, conf=0.43, freq=7
  AwingWord(awing: 'ə́shíʼə́', english: 'loaves', category: 'food', difficulty: 1),
    // bible:MAT.15.34, conf=0.57, freq=7
  AwingWord(awing: 'jáʼ', english: 'appeared', category: 'things', difficulty: 1),
    // bible:MAT.17.3, conf=0.43, freq=7
  AwingWord(awing: 'leŋ', english: 'didn', category: 'things', difficulty: 1),
    // bible:MAT.17.12, conf=0.57, freq=7
  AwingWord(awing: 'kə́g', english: 'nothing', category: 'things', difficulty: 1),

    // bible:MAT.17.25, conf=1.00, freq=7
  AwingWord(awing: 'nyegnə̂', english: 'mocked', category: 'actions', difficulty: 2),
    // bible:MAT.20.19, conf=0.71, freq=7
  AwingWord(awing: 'fóŋnə', english: 'son', category: 'family', difficulty: 1),
    // bible:MAT.20.30, conf=0.43, freq=7
  AwingWord(awing: 'kɔ́ŋə́sê', english: 'man', category: 'things', difficulty: 1),
    // bible:MAT.21.14, conf=0.71, freq=7
  AwingWord(awing: 'ngaŋə́fanə', english: 'other', category: 'things', difficulty: 1),
    // bible:MAT.21.41, conf=0.43, freq=7
  AwingWord(awing: 'ntaʼlə', english: 'few', category: 'numbers', difficulty: 1),

    // bible:MAT.22.32, conf=1.00, freq=7
  AwingWord(awing: 'mbab', english: 'wings', category: 'things', difficulty: 1),
    // bible:MAT.23.37, conf=0.71, freq=7
  AwingWord(awing: 'ntsǒnkáʼə', english: 'out', category: 'things', difficulty: 1),
    // bible:MAT.24.33, conf=0.71, freq=7
  AwingWord(awing: 'pəlám', english: 'lamps', category: 'things', difficulty: 1),
    // bible:MAT.25.1, conf=0.71, freq=7
  AwingWord(awing: 'ntɨ̌túʼ', english: 'midnight', category: 'things', difficulty: 1),
    // bible:MAT.25.6, conf=0.86, freq=7
  AwingWord(awing: 'foʼə̂', english: 'reap', category: 'actions', difficulty: 1),
    // bible:MAT.25.26, conf=0.57, freq=7
  AwingWord(awing: 'ngab', english: 'day', category: 'things', difficulty: 1),
    // bible:MAT.25.32, conf=0.71, freq=7
  AwingWord(awing: 'pəpóŋ', english: 'poor', category: 'descriptive', difficulty: 1),

    // bible:MAT.26.58, conf=0.86, freq=7
  AwingWord(awing: 'ə́fyáalə', english: 'cyrene', category: 'things', difficulty: 1),
    // bible:MAT.27.32, conf=0.43, freq=7
  AwingWord(awing: 'ŋ́ŋáʼə', english: 'come', category: 'things', difficulty: 1),
    // bible:MRK.4.22, conf=0.43, freq=7
  AwingWord(awing: 'ńdə́gə', english: 'opened', category: 'actions', difficulty: 1),
    // bible:MRK.6.27, conf=0.57, freq=7
  AwingWord(awing: 'ə́sogə̂', english: 'washed', category: 'actions', difficulty: 1),

    // bible:MRK.7.26, conf=0.86, freq=7
  AwingWord(awing: 'weŋ', english: 'son', category: 'family', difficulty: 1),

    // bible:MRK.13.32, conf=0.43, freq=7
  AwingWord(awing: 'twə́ŋə', english: 'buried', category: 'things', difficulty: 1),
    // bible:MRK.14.8, conf=0.43, freq=7
  AwingWord(awing: 'ńnáakə', english: 'into', category: 'things', difficulty: 1),
    // bible:MRK.16.19, conf=0.43, freq=7
  AwingWord(awing: 'Pətseŋnə', english: 'shepherds', category: 'things', difficulty: 1),
    // bible:LUK.2.8, conf=0.86, freq=7
  AwingWord(awing: 'ngɛdtəpɔŋ', english: 'one', category: 'numbers', difficulty: 1),
    // bible:LUK.6.22, conf=0.86, freq=7
  AwingWord(awing: 'ngwan', english: 'stripes', category: 'things', difficulty: 1),
    // bible:LUK.12.47, conf=0.57, freq=7
  AwingWord(awing: 'akwáalə́nkǐ', english: 'baptism', category: 'things', difficulty: 2),
    // bible:LUK.12.50, conf=0.71, freq=7
  AwingWord(awing: 'ə́lɔgə̂', english: 'words', category: 'things', difficulty: 1),
    // bible:LUK.21.24, conf=0.57, freq=7
  AwingWord(awing: 'ńjwáglə', english: 'cried', category: 'actions', difficulty: 1),

    // bible:JHN.1.41, conf=0.43, freq=7
  AwingWord(awing: 'pətəkaŋ', english: 'elders', category: 'family', difficulty: 2),
    // bible:JHN.8.9, conf=0.43, freq=7
  AwingWord(awing: 'ŋ́ŋáʼnə', english: 'opened', category: 'actions', difficulty: 1),
    // bible:JHN.9.10, conf=0.43, freq=7
  AwingWord(awing: 'təghə́', english: 'without', category: 'things', difficulty: 1),
    // bible:JHN.14.6, conf=0.43, freq=7
  AwingWord(awing: 'Pəlimə́', english: 'brothers', category: 'things', difficulty: 1),
    // bible:ACT.1.16, conf=0.86, freq=7
  AwingWord(awing: 'jwaʼlə̂', english: 'another', category: 'things', difficulty: 1),

    // bible:ACT.4.36, conf=1.00, freq=7
  AwingWord(awing: 'pəghəənə', english: 'strangers', category: 'things', difficulty: 1),

    // bible:ACT.10.1, conf=0.86, freq=7
  AwingWord(awing: 'kyádkənkǐ', english: 'island', category: 'things', difficulty: 1),
    // bible:ACT.13.6, conf=0.86, freq=7
  AwingWord(awing: 'Yǐəə', english: 'saying', category: 'actions', difficulty: 1),



    // bible:ACT.18.2, conf=0.86, freq=7
  AwingWord(awing: 'wáakə́', english: 'sea', category: 'nature', difficulty: 1),
    // bible:ACT.27.17, conf=0.57, freq=7
  AwingWord(awing: 'pə́pə̌', english: 'god', category: 'things', difficulty: 1),
    // bible:2CO.1.17, conf=0.57, freq=7
  AwingWord(awing: 'nəpaŋ', english: 'voice', category: 'things', difficulty: 1),
    // bible:1TH.4.16, conf=0.57, freq=7
  AwingWord(awing: 'nəjí', english: 'sounded', category: 'things', difficulty: 1),


    // bible:MAT.3.5, conf=1.00, freq=6
  AwingWord(awing: 'nəloŋ', english: 'down', category: 'things', difficulty: 1),


    // bible:MAT.4.10, conf=0.50, freq=6
  AwingWord(awing: 'azɔŋ', english: 'against', category: 'things', difficulty: 1),
    // bible:MAT.5.23, conf=0.50, freq=6
  AwingWord(awing: 'aliʼə́sáʼə́məsáʼ', english: 'judge', category: 'things', difficulty: 1),
    // bible:MAT.5.25, conf=0.50, freq=6
  AwingWord(awing: 'ndɔ́la', english: 'two', category: 'numbers', difficulty: 1),
    // bible:MAT.5.26, conf=0.67, freq=6
  AwingWord(awing: 'achaʼtə́sênjiə', english: 'fast', category: 'descriptive', difficulty: 2),
    // bible:MAT.6.16, conf=0.83, freq=6
  AwingWord(awing: 'ńdzə', english: 'swords', category: 'things', difficulty: 1),
    // bible:MAT.6.20, conf=0.50, freq=6
  AwingWord(awing: 'tsɛɛkə̂', english: 'out', category: 'things', difficulty: 1),


    // bible:MAT.9.9, conf=0.83, freq=6
  AwingWord(awing: 'Móonə', english: 'said', category: 'actions', difficulty: 1),
    // bible:MAT.9.18, conf=0.67, freq=6
  AwingWord(awing: 'fɛ́dkə', english: 'out', category: 'things', difficulty: 1),


    // bible:MAT.11.21, conf=0.83, freq=6
  AwingWord(awing: 'ḿbə́g', english: 'than', category: 'things', difficulty: 1),
    // bible:MAT.12.45, conf=0.50, freq=6
  AwingWord(awing: 'ńdagtə̂', english: 'baskets', category: 'things', difficulty: 1),
    // bible:MAT.13.4, conf=0.83, freq=6
  AwingWord(awing: 'ńtáŋnə', english: 'night', category: 'things', difficulty: 1),

    // bible:MAT.15.22, conf=0.67, freq=6
  AwingWord(awing: 'məngwû', english: 'dogs', category: 'animals', difficulty: 1),
    // bible:MAT.15.26, conf=1.00, freq=6
  AwingWord(awing: 'ntáʼə', english: 'loaves', category: 'food', difficulty: 1),

    // bible:MAT.16.13, conf=0.83, freq=6
  AwingWord(awing: 'kyag', english: 'into', category: 'things', difficulty: 1),
    // bible:MAT.16.19, conf=0.50, freq=6
  AwingWord(awing: 'sə́', english: 'themselves', category: 'pronouns', difficulty: 1),
    // bible:MAT.19.12, conf=0.67, freq=6
  AwingWord(awing: 'ńkɨ́ʼə', english: 'god', category: 'things', difficulty: 1),
    // bible:MAT.19.14, conf=0.50, freq=6
  AwingWord(awing: 'ngaŋnkéebə', english: 'into', category: 'things', difficulty: 1),
    // bible:MAT.19.23, conf=1.00, freq=6
  AwingWord(awing: 'Zə́ənə', english: 'behold', category: 'things', difficulty: 2),
    // bible:MAT.19.27, conf=0.83, freq=6
  AwingWord(awing: 'ələŋəmə́fɔ', english: 'thrones', category: 'things', difficulty: 2),
    // bible:MAT.19.28, conf=1.00, freq=6
  AwingWord(awing: 'ntɨ̌numnə', english: 'about', category: 'things', difficulty: 1),
    // bible:MAT.20.5, conf=0.67, freq=6
  AwingWord(awing: 'lə́', english: 'god', category: 'things', difficulty: 1),

    // bible:MAT.20.29, conf=1.00, freq=6
  AwingWord(awing: 'ńnaʼə̂', english: 'rebuked', category: 'things', difficulty: 1),
    // bible:MAT.20.31, conf=0.50, freq=6
  AwingWord(awing: 'ńtɔ́ŋnə', english: 'out', category: 'things', difficulty: 1),
    // bible:MAT.20.31, conf=0.50, freq=6
  AwingWord(awing: 'təŋnə̂', english: 'tied', category: 'things', difficulty: 1),
    // bible:MAT.21.2, conf=0.67, freq=6
  AwingWord(awing: 'əkɔʼ', english: 'seats', category: 'things', difficulty: 1),
    // bible:MAT.21.12, conf=1.00, freq=6
  AwingWord(awing: 'ńtóŋə', english: 'went', category: 'things', difficulty: 1),
    // bible:MAT.21.33, conf=0.83, freq=6
  AwingWord(awing: 'ńgwúnə', english: 'invited', category: 'things', difficulty: 1),
    // bible:MAT.22.9, conf=0.67, freq=6
  AwingWord(awing: 'tɔ́mtə', english: 'came', category: 'actions', difficulty: 1),
    // bible:MAT.22.16, conf=0.50, freq=6
  AwingWord(awing: 'fîəpô', english: 'finger', category: 'body', difficulty: 1),
    // bible:MAT.23.4, conf=0.83, freq=6
  AwingWord(awing: 'məntsoolə', english: 'end', category: 'things', difficulty: 1),
    // bible:MAT.24.6, conf=0.50, freq=6
  AwingWord(awing: 'sɛ́nə', english: 'light', category: 'nature', difficulty: 1),

    // bible:MAT.26.3, conf=1.00, freq=6
  AwingWord(awing: 'ḿbóolə', english: 'weak', category: 'descriptive', difficulty: 1),
    // bible:MAT.26.41, conf=0.67, freq=6
  AwingWord(awing: 'ńtwǐ', english: 'spat', category: 'things', difficulty: 3),
    // bible:MAT.26.67, conf=0.50, freq=6
  AwingWord(awing: 'məngwúb', english: 'rocks', category: 'nature', difficulty: 1),
    // bible:MAT.27.51, conf=0.50, freq=6
  AwingWord(awing: 'ŋ́ŋáʼkə', english: 'opened', category: 'actions', difficulty: 1),
    // bible:MAT.27.52, conf=0.67, freq=6
  AwingWord(awing: 'ngaŋntsɨd', english: 'liar', category: 'things', difficulty: 1),
    // bible:MAT.27.63, conf=0.50, freq=6
  AwingWord(awing: 'ńkwɛdnə̂', english: 'one', category: 'numbers', difficulty: 1),
    // bible:MRK.2.22, conf=0.50, freq=6
  AwingWord(awing: 'pəfî', english: 'languages', category: 'things', difficulty: 1),
    // bible:MRK.7.33, conf=0.67, freq=6
  AwingWord(awing: 'ńgwad', english: 'covenant', category: 'things', difficulty: 2),
    // bible:MRK.14.12, conf=0.67, freq=6
  AwingWord(awing: 'ambáŋə́', english: 'water', category: 'nature', difficulty: 1),

    // bible:MRK.14.54, conf=1.00, freq=6
  AwingWord(awing: 'toonə̂', english: 'into', category: 'things', difficulty: 1),
    // bible:LUK.1.9, conf=0.50, freq=6
  AwingWord(awing: 'təmbɔʼə', english: 'god', category: 'things', difficulty: 1),

    // bible:LUK.3.32, conf=0.67, freq=6
  AwingWord(awing: 'ŋáʼə', english: 'veil', category: 'things', difficulty: 1),
    // bible:LUK.4.17, conf=0.50, freq=6
  AwingWord(awing: 'aghɔ', english: 'healed', category: 'actions', difficulty: 1),
    // bible:LUK.4.40, conf=0.50, freq=6
  AwingWord(awing: 'nəpɔŋ', english: 'glory', category: 'things', difficulty: 2),
    // bible:LUK.9.26, conf=0.67, freq=6
  AwingWord(awing: 'ə́sagə̂', english: 'its', category: 'pronouns', difficulty: 1),
    // bible:LUK.12.15, conf=0.50, freq=6
  AwingWord(awing: 'məmbéŋə', english: 'good', category: 'descriptive', difficulty: 1),
    // bible:LUK.12.32, conf=0.50, freq=6
  AwingWord(awing: 'pəfə́m', english: 'poor', category: 'descriptive', difficulty: 1),
    // bible:LUK.14.13, conf=0.83, freq=6
  AwingWord(awing: 'jwə́ʼə', english: 'fire', category: 'nature', difficulty: 1),
    // bible:LUK.14.24, conf=0.50, freq=6
  AwingWord(awing: 'tətəənə', english: 'middle', category: 'things', difficulty: 1),

    // bible:JHN.1.19, conf=0.50, freq=6
  AwingWord(awing: 'shwəgtə̂', english: 'away', category: 'things', difficulty: 1),
    // bible:JHN.2.10, conf=0.83, freq=6
  AwingWord(awing: 'ńgabnə̂', english: 'division', category: 'things', difficulty: 1),
    // bible:JHN.7.43, conf=0.50, freq=6
  AwingWord(awing: 'sɛ́n', english: 'night', category: 'things', difficulty: 1),

    // bible:JHN.11.2, conf=0.67, freq=6
  AwingWord(awing: 'tǎpətǎ', english: 'father', category: 'family', difficulty: 1),


    // bible:ACT.6.9, conf=1.00, freq=6
  AwingWord(awing: 'atəəmə́tə́əmə', english: 'into', category: 'things', difficulty: 1),
    // bible:ACT.10.10, conf=0.50, freq=6
  AwingWord(awing: 'ə́fyaʼ', english: 'idols', category: 'things', difficulty: 1),

    // bible:ACT.16.8, conf=0.83, freq=6
  AwingWord(awing: 'əsáʼməsáʼə', english: 'another', category: 'things', difficulty: 1),
    // bible:ACT.17.34, conf=0.50, freq=6
  AwingWord(awing: 'nəweŋ', english: 'officer', category: 'things', difficulty: 2),
    // bible:ACT.22.26, conf=0.67, freq=6
  AwingWord(awing: 'əshunə́', english: 'greet', category: 'actions', difficulty: 1),
    // bible:ROM.2.3, conf=0.67, freq=6
  AwingWord(awing: 'zéʼə', english: 'know', category: 'things', difficulty: 1),
    // bible:1CO.14.31, conf=0.50, freq=6
  AwingWord(awing: 'nənta', english: 'god', category: 'things', difficulty: 1),

    // bible:COL.2.1, conf=1.00, freq=6
  AwingWord(awing: 'ńdzoolə̂', english: 'thunders', category: 'things', difficulty: 1),
    // bible:REV.4.5, conf=0.83, freq=6
  AwingWord(awing: 'akɔ́', english: 'beast', category: 'animals', difficulty: 1),
    // bible:REV.14.9, conf=0.83, freq=6
  AwingWord(awing: 'afoʼəmə́jî', english: 'sickle', category: 'things', difficulty: 1),


    // bible:MAT.1.11, conf=1.00, freq=5
  AwingWord(awing: 'məpad', english: 'neighbors', category: 'family', difficulty: 1),
    // bible:MAT.2.16, conf=0.60, freq=5
  AwingWord(awing: 'alúʼə', english: 'dove', category: 'animals', difficulty: 1),
    // bible:MAT.3.16, conf=0.80, freq=5
  AwingWord(awing: 'əláʼə', english: 'said', category: 'actions', difficulty: 1),
    // bible:MAT.4.8, conf=0.60, freq=5
  AwingWord(awing: 'kwə́ʼtə', english: 'down', category: 'things', difficulty: 1),

    // bible:MAT.4.24, conf=0.60, freq=5
  AwingWord(awing: 'ghɔ', english: 'sick', category: 'descriptive', difficulty: 1),
    // bible:MAT.4.24, conf=0.80, freq=5
  AwingWord(awing: 'ntɛ́n', english: 'stand', category: 'actions', difficulty: 1),
    // bible:MAT.5.15, conf=0.60, freq=5
  AwingWord(awing: 'akəkóg', english: 'foolish', category: 'things', difficulty: 1),
    // bible:MAT.5.22, conf=0.60, freq=5
  AwingWord(awing: 'ə́shamkə̂', english: 'away', category: 'things', difficulty: 1),
    // bible:MAT.5.31, conf=0.40, freq=5
  AwingWord(awing: 'kwab', english: 'left', category: 'actions', difficulty: 1),
    // bible:MAT.5.39, conf=0.80, freq=5
  AwingWord(awing: 'tsɔ́ʼkə', english: 'lend', category: 'things', difficulty: 1),
    // bible:MAT.5.42, conf=0.60, freq=5
  AwingWord(awing: 'təjǐsê', english: 'tax', category: 'things', difficulty: 1),

    // bible:MAT.6.6, conf=0.40, freq=5
  AwingWord(awing: 'tə́mə́sɛ́', english: 'don', category: 'things', difficulty: 1),
    // bible:MAT.6.19, conf=0.80, freq=5
  AwingWord(awing: 'ńdzə́gə', english: 'sow', category: 'actions', difficulty: 1),

    // bible:MAT.6.29, conf=1.00, freq=5
  AwingWord(awing: 'nəyeŋ', english: 'into', category: 'things', difficulty: 1),
    // bible:MAT.6.30, conf=0.60, freq=5
  AwingWord(awing: 'lǎa', english: 'said', category: 'actions', difficulty: 1),
    // bible:MAT.7.4, conf=0.40, freq=5
  AwingWord(awing: 'kə́gə', english: 'few', category: 'numbers', difficulty: 1),
    // bible:MAT.7.14, conf=0.40, freq=5
  AwingWord(awing: 'zə́mə', english: 'fruit', category: 'nature', difficulty: 1),
    // bible:MAT.7.17, conf=0.80, freq=5
  AwingWord(awing: 'ənu', english: 'wise', category: 'things', difficulty: 1),
    // bible:MAT.7.24, conf=0.40, freq=5
  AwingWord(awing: 'əléemə', english: 'one', category: 'numbers', difficulty: 1),
    // bible:MAT.8.6, conf=0.60, freq=5
  AwingWord(awing: 'ńchiʼ', english: 'heads', category: 'things', difficulty: 1),
    // bible:MAT.8.24, conf=0.40, freq=5
  AwingWord(awing: 'mə́sɔ́', english: 'blood', category: 'things', difficulty: 1),
    // bible:MAT.9.20, conf=1.00, freq=5
  AwingWord(awing: 'jwáglə', english: 'shouted', category: 'actions', difficulty: 1),
    // bible:MAT.9.23, conf=0.60, freq=5
  AwingWord(awing: 'Alfɔsə', english: 'son', category: 'family', difficulty: 1),

    // bible:MAT.10.5, conf=0.80, freq=5
  AwingWord(awing: 'kɔdtə̂', english: 'city', category: 'things', difficulty: 1),
    // bible:MAT.10.14, conf=0.80, freq=5
  AwingWord(awing: 'ngaŋə́sáʼə́məsáʼə', english: 'deliver', category: 'things', difficulty: 1),
    // bible:MAT.10.17, conf=0.40, freq=5
  AwingWord(awing: 'kɔnə̂', english: 'day', category: 'things', difficulty: 1),

    // bible:MAT.11.7, conf=0.60, freq=5
  AwingWord(awing: 'fiʼkə̂', english: 'compare', category: 'things', difficulty: 1),
    // bible:MAT.11.16, conf=0.40, freq=5
  AwingWord(awing: 'lwaʼə', english: 'immorality', category: 'things', difficulty: 3),
    // bible:MAT.11.19, conf=0.40, freq=5
  AwingWord(awing: 'ənuə', english: 'wise', category: 'things', difficulty: 1),
    // bible:MAT.11.25, conf=0.80, freq=5
  AwingWord(awing: 'əfɔ', english: 'into', category: 'things', difficulty: 1),
    // bible:MAT.12.1, conf=0.80, freq=5
  AwingWord(awing: 'ńtwám', english: 'cup', category: 'things', difficulty: 1),
    // bible:MAT.12.29, conf=0.60, freq=5
  AwingWord(awing: 'ndimə́', english: 'brother', category: 'things', difficulty: 1),
    // bible:MAT.12.50, conf=1.00, freq=5
  AwingWord(awing: 'əfooghəəmə́', english: 'sea', category: 'nature', difficulty: 1),
    // bible:MAT.13.1, conf=0.60, freq=5
  AwingWord(awing: 'atséebə́nə́múʼə́', english: 'parable', category: 'things', difficulty: 1),
    // bible:MAT.13.10, conf=0.80, freq=5
  AwingWord(awing: 'fɔ́lə́sə', english: 'mustard', category: 'things', difficulty: 1),
    // bible:MAT.13.31, conf=1.00, freq=5
  AwingWord(awing: 'təjiʼ', english: 'own', category: 'things', difficulty: 1),
    // bible:MAT.14.13, conf=0.60, freq=5
  AwingWord(awing: 'pəfəgə́', english: 'blind', category: 'things', difficulty: 1),
    // bible:MAT.15.14, conf=1.00, freq=5
  AwingWord(awing: 'pəkî', english: 'key', category: 'things', difficulty: 1),
    // bible:MAT.16.19, conf=0.80, freq=5
  AwingWord(awing: 'kɨ́ʼə́', english: 'stumbling', category: 'things', difficulty: 1),
    // bible:MAT.16.23, conf=0.40, freq=5
  AwingWord(awing: 'ḿbéŋkə', english: 'man', category: 'things', difficulty: 1),

    // bible:MAT.17.4, conf=0.60, freq=5
  AwingWord(awing: 'nchub', english: 'said', category: 'actions', difficulty: 1),
    // bible:MAT.17.24, conf=0.60, freq=5
  AwingWord(awing: 'məghə́mə', english: 'seventy', category: 'numbers', difficulty: 1),
    // bible:MAT.18.22, conf=1.00, freq=5
  AwingWord(awing: 'ńnyáʼ', english: 'saw', category: 'things', difficulty: 1),
    // bible:MAT.20.3, conf=0.40, freq=5
  AwingWord(awing: 'ḿmegnə̂', english: 'out', category: 'things', difficulty: 1),
    // bible:MAT.20.31, conf=0.60, freq=5
  AwingWord(awing: 'jáʼə', english: 'revealed', category: 'actions', difficulty: 1),
    // bible:MAT.23.15, conf=0.60, freq=5
  AwingWord(awing: 'pánə', english: 'out', category: 'things', difficulty: 1),
    // bible:MAT.24.26, conf=0.40, freq=5
  AwingWord(awing: 'shúm', english: 'prophesy', category: 'things', difficulty: 2),
    // bible:MAT.24.49, conf=0.40, freq=5
  AwingWord(awing: 'kɛləshín', english: 'lamps', category: 'things', difficulty: 1),
    // bible:MAT.25.23, conf=1.00, freq=5
  AwingWord(awing: 'akwub', english: 'alabaster', category: 'things', difficulty: 1),
    // bible:MAT.26.7, conf=0.40, freq=5
  AwingWord(awing: 'Aliʼə́', english: 'called', category: 'things', difficulty: 1),
    // bible:MAT.27.8, conf=0.80, freq=5
  AwingWord(awing: 'ńjwə́ʼ', english: 'tasted', category: 'things', difficulty: 1),
    // bible:MAT.27.34, conf=0.60, freq=5
  AwingWord(awing: 'ńdə́mə', english: 'wrapped', category: 'things', difficulty: 1),
    // bible:MAT.27.59, conf=0.80, freq=5
  AwingWord(awing: 'ńkwaʼlə̂', english: 'tempted', category: 'actions', difficulty: 2),
    // bible:MRK.1.13, conf=0.60, freq=5
  AwingWord(awing: 'chiʼə̂', english: 'lord', category: 'things', difficulty: 3),
    // bible:MRK.1.26, conf=0.60, freq=5
  AwingWord(awing: 'Pə́', english: 'sins', category: 'things', difficulty: 2),
    // bible:MRK.2.9, conf=0.40, freq=5
  AwingWord(awing: 'ngǎŋndzəm', english: 'against', category: 'things', difficulty: 1),
    // bible:MRK.3.6, conf=0.60, freq=5
  AwingWord(awing: 'aghoonə́', english: 'many', category: 'numbers', difficulty: 1),
    // bible:MRK.3.10, conf=0.40, freq=5
  AwingWord(awing: 'ńchiʼə̂', english: 'said', category: 'actions', difficulty: 1),
    // bible:MRK.4.39, conf=0.40, freq=5
  AwingWord(awing: 'ńdə́gtə', english: 'often', category: 'things', difficulty: 1),
    // bible:MRK.5.4, conf=0.40, freq=5
  AwingWord(awing: 'akwantə', english: 'things', category: 'things', difficulty: 1),
    // bible:MRK.6.11, conf=0.60, freq=5
  AwingWord(awing: 'túʼə', english: 'day', category: 'things', difficulty: 1),
    // bible:MRK.6.35, conf=0.60, freq=5
  AwingWord(awing: 'ḿbookə̂', english: 'leave', category: 'actions', difficulty: 1),
    // bible:MRK.6.46, conf=0.60, freq=5
  AwingWord(awing: 'məkəŋ', english: 'clay', category: 'things', difficulty: 1),
    // bible:MRK.7.4, conf=0.80, freq=5
  AwingWord(awing: 'akɔ́ʼkə', english: 'evil', category: 'things', difficulty: 3),
    // bible:MRK.7.22, conf=0.40, freq=5
  AwingWord(awing: 'ńdzɔŋnə̂', english: 'disciples', category: 'things', difficulty: 3),

    // bible:MRK.9.39, conf=0.40, freq=5
  AwingWord(awing: 'Jɨ́', english: 'said', category: 'actions', difficulty: 1),

    // bible:MRK.10.37, conf=0.80, freq=5
  AwingWord(awing: 'tɔ́ŋnə', english: 'voice', category: 'things', difficulty: 1),
    // bible:MRK.10.47, conf=0.60, freq=5
  AwingWord(awing: 'glebə', english: 'another', category: 'things', difficulty: 1),
    // bible:MRK.12.1, conf=0.60, freq=5
  AwingWord(awing: 'ngaŋə́shíʼnə', english: 'farmers', category: 'things', difficulty: 1),

    // bible:MRK.12.37, conf=1.00, freq=5
  AwingWord(awing: 'ńtóotə', english: 'stirred', category: 'things', difficulty: 1),
    // bible:MRK.15.11, conf=0.60, freq=5
  AwingWord(awing: 'ńdzéʼ', english: 'learn', category: 'things', difficulty: 1),
    // bible:LUK.1.3, conf=0.60, freq=5
  AwingWord(awing: 'ə́sɛd', english: 'god', category: 'things', difficulty: 1),


    // bible:LUK.4.27, conf=0.80, freq=5
  AwingWord(awing: 'ə́fɛ́dkə', english: 'out', category: 'things', difficulty: 1),
    // bible:LUK.4.41, conf=0.80, freq=5
  AwingWord(awing: 'nkǐmə́g', english: 'weeping', category: 'actions', difficulty: 1),
    // bible:LUK.7.38, conf=0.40, freq=5
  AwingWord(awing: 'ńjwaʼlə̂', english: 'because', category: 'things', difficulty: 1),

    // bible:LUK.10.33, conf=0.60, freq=5
  AwingWord(awing: 'mə́ŋgâsê', english: 'power', category: 'things', difficulty: 1),

    // bible:LUK.12.45, conf=0.60, freq=5
  AwingWord(awing: 'Kɛ́', english: 'never', category: 'things', difficulty: 1),
    // bible:LUK.15.29, conf=0.60, freq=5
  AwingWord(awing: 'ndɛdtə', english: 'don', category: 'things', difficulty: 1),

    // bible:LUK.17.37, conf=0.40, freq=5
  AwingWord(awing: 'ngaŋə́táŋə́mə́tá', english: 'merchants', category: 'things', difficulty: 1),
    // bible:LUK.19.45, conf=0.60, freq=5
  AwingWord(awing: 'məmá', english: 'said', category: 'actions', difficulty: 1),
    // bible:LUK.20.8, conf=0.60, freq=5
  AwingWord(awing: 'ətyǎntə', english: 'great', category: 'things', difficulty: 1),
    // bible:LUK.21.11, conf=0.40, freq=5
  AwingWord(awing: 'asáʼə́məsáʼə', english: 'day', category: 'things', difficulty: 1),
    // bible:LUK.22.66, conf=1.00, freq=5
  AwingWord(awing: 'əfankəmə́nu', english: 'sins', category: 'things', difficulty: 2),
    // bible:LUK.24.47, conf=0.80, freq=5
  AwingWord(awing: 'Ŋáŋkə', english: 'god', category: 'things', difficulty: 1),
    // bible:JHN.9.24, conf=0.80, freq=5
  AwingWord(awing: 'sáʼkə', english: 'thunders', category: 'things', difficulty: 1),
    // bible:JHN.12.29, conf=0.80, freq=5
  AwingWord(awing: 'paŋpaŋ', english: 'purple', category: 'things', difficulty: 1),
    // bible:JHN.19.5, conf=0.80, freq=5
  AwingWord(awing: 'ngyéŋ', english: 'side', category: 'things', difficulty: 1),
    // bible:JHN.19.34, conf=0.80, freq=5
  AwingWord(awing: 'mətsɨ́', english: 'things', category: 'things', difficulty: 1),

    // bible:ACT.2.10, conf=1.00, freq=5
  AwingWord(awing: 'ńchwád', english: 'saved', category: 'actions', difficulty: 1),

    // bible:ACT.7.30, conf=0.80, freq=5
  AwingWord(awing: 'nəkyéŋ', english: 'tears', category: 'things', difficulty: 1),
    // bible:ACT.7.34, conf=0.60, freq=5
  AwingWord(awing: 'pəkɔ́', english: 'made', category: 'things', difficulty: 1),





    // bible:ACT.14.19, conf=1.00, freq=5
  AwingWord(awing: 'kəʼlə̂', english: 'reasoned', category: 'things', difficulty: 1),

  // ====================================================================
  // BIBLE NT AUTO-EXTRACTED VOCABULARY — 2,712 entries from CABTAL Awing
  // NT corpus (azocab). Added Session 60 (2026-05-20) per Dr. Sama
  // directive. All entries default to difficulty: 3 (Expert-only) so they
  // never surface in beginner/medium quizzes per Session 47 level filter.
  //
  // Glosses are best-effort auto-extracted via English co-occurrence
  // analysis with religious-context blocking. Many will need native-
  // speaker correction over time — use the contribution workflow.
  // Entries marked '// needs review' have low confidence (<0.15) or
  // weak gloss candidates and should be checked first.
  //
  // Provenance trail per entry: bible:<verse-ref>, freq=<verse-count>,
  // conf=<top-gloss-confidence>, alts: <runner-up glosses>.
  // ====================================================================
  // bible:MAT.1.3, freq=3380, conf=0.04, alts: things, man, don // needs review
  AwingWord(awing: 'páʼ', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:MAT.1.18, freq=1175, conf=0.04, alts: things, man, don // needs review
  AwingWord(awing: 'chî', english: 'even', category: 'things', difficulty: 1),
  // bible:MAT.1.11, freq=1145, conf=0.07, alts: things, man, great // needs review
  AwingWord(awing: 'tíʼ', english: 'disciples', category: 'things', difficulty: 3),
  // bible:MAT.1.22, freq=1104, conf=0.06, alts: things, don, man // needs review
  AwingWord(awing: 'anu', english: 'about', category: 'things', difficulty: 1),
  // bible:MAT.1.19, freq=793, conf=0.18, alts: don, man, things
  AwingWord(awing: 'ńkě', english: 'didn', category: 'things', difficulty: 1),
  // bible:MAT.1.22, freq=751, conf=0.06, alts: things, man, don // needs review
  AwingWord(awing: 'ghɛd', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:MAT.3.7, freq=746, conf=0.05, alts: don, man, things // needs review
  AwingWord(awing: 'təmbɔʼ', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:MAT.2.13, freq=733, conf=0.05, alts: things, man, don // needs review
  AwingWord(awing: 'ə́wɨ́', english: 'having', category: 'things', difficulty: 1),
  // bible:MAT.1.2, freq=695, conf=0.07, alts: priests, chief, things // needs review
  AwingWord(awing: 'pópə', english: 'disciples', category: 'family', difficulty: 3),
  // bible:MAT.4.3, freq=694, conf=0.06, alts: things, man, don // needs review
  AwingWord(awing: 'mbɔʼ', english: 'say', category: 'things', difficulty: 1),
  // bible:MAT.1.25, freq=668, conf=0.04, alts: things, life, don // needs review
  AwingWord(awing: 'fɛ̂', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:MAT.3.2, freq=602, conf=0.05, alts: things, man, don // needs review
  AwingWord(awing: 'mənu', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:MAT.2.22, freq=591, conf=0.07, alts: don, things, man // needs review
  AwingWord(awing: 'jî', english: 'eat', category: 'actions', difficulty: 1),
  // bible:MAT.1.16, freq=580, conf=0.05, alts: earth, things, man // needs review
  AwingWord(awing: 'ndu', english: 'even', category: 'nature', difficulty: 1),
  // bible:MAT.2.8, freq=578, conf=0.06, alts: things, man, don // needs review
  AwingWord(awing: 'ghɛn', english: 'sent', category: 'actions', difficulty: 1),
  // bible:MAT.3.11, freq=555, conf=0.07, alts: things, don, life // needs review
  AwingWord(awing: 'túg', english: 'having', category: 'things', difficulty: 1),
  // bible:MAT.1.11, freq=542, conf=0.10, alts: things, don, man // needs review
  AwingWord(awing: 'ághɔ́b', english: 'answered', category: 'actions', difficulty: 1),
  // bible:MAT.1.18, freq=537, conf=0.08, alts: man, disciples, behold // needs review
  AwingWord(awing: 'ńtə́', english: 'hope', category: 'things', difficulty: 2),
  // bible:MAT.1.19, freq=530, conf=0.07, alts: heart, believed, things // needs review
  AwingWord(awing: 'ntɨ́', english: 'believe', category: 'actions', difficulty: 1),
  // bible:MAT.1.20, freq=516, conf=0.04, alts: don, things, man // needs review
  AwingWord(awing: 'kɔ', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:MAT.2.15, freq=500, conf=0.22, alts: himself, man, things
  AwingWord(awing: 'əjí', english: 'disciples', category: 'pronouns', difficulty: 3),
  // bible:MAT.4.23, freq=451, conf=0.09, alts: everyone, man, things // needs review
  AwingWord(awing: 'ntsəm', english: 'whoever', category: 'pronouns', difficulty: 1),
  // bible:MAT.2.6, freq=446, conf=0.05, alts: man, things, city // needs review
  AwingWord(awing: 'mə́mə', english: 'enter', category: 'things', difficulty: 1),
  // bible:MAT.1.18, freq=429, conf=0.06, alts: man, things, days // needs review
  AwingWord(awing: 'ńchî', english: 'many', category: 'numbers', difficulty: 1),
  // bible:MAT.1.17, freq=417, conf=0.07, alts: time, things, days // needs review
  AwingWord(awing: 'ndɛd', english: 'until', category: 'things', difficulty: 1),
  // bible:MAT.2.3, freq=413, conf=0.05, alts: things, man, world // needs review
  AwingWord(awing: 'zɨ', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:MAT.1.11, freq=402, conf=0.09, alts: man, disciples, departed // needs review
  AwingWord(awing: 'ńgɛnə̂', english: 'away', category: 'actions', difficulty: 1),
  // bible:MAT.3.11, freq=394, conf=0.07, alts: man, things, behold // needs review
  AwingWord(awing: 'tsə̌', english: 'anyone', category: 'pronouns', difficulty: 1),
  // bible:MAT.3.7, freq=393, conf=0.09, alts: certainly, don, things // needs review
  AwingWord(awing: 'áwɨ́', english: 'most', category: 'things', difficulty: 1),
  // bible:MAT.2.1, freq=377, conf=0.10, alts: children, assemblies, things // needs review
  AwingWord(awing: 'pɔ́', english: 'assembly', category: 'family', difficulty: 1),
  // bible:MAT.2.9, freq=349, conf=0.07, alts: place, things, man // needs review
  AwingWord(awing: 'aliʼ', english: 'away', category: 'things', difficulty: 1),
  // bible:MAT.1.12, freq=335, conf=0.10, alts: man, things, after // needs review
  AwingWord(awing: 'ńgɛn', english: 'away', category: 'things', difficulty: 1),
  // bible:MAT.1.22, freq=327, conf=0.09, alts: things, place, day // needs review
  AwingWord(awing: 'aliʼə́', english: 'together', category: 'things', difficulty: 1),
  // bible:MAT.4.25, freq=323, conf=0.08, alts: things, men, pharisees // needs review
  AwingWord(awing: 'pətsə́', english: 'many', category: 'numbers', difficulty: 1),
  // bible:MAT.5.18, freq=310, conf=0.11, alts: don, neither, man // needs review
  AwingWord(awing: 'kɨ', english: 'nor', category: 'things', difficulty: 1),
  // bible:MAT.2.11, freq=305, conf=0.06, alts: things, delivered, bread // needs review
  AwingWord(awing: 'ə́fɛ̂', english: 'thanks', category: 'food', difficulty: 1),
  // bible:MAT.5.18, freq=301, conf=0.13, alts: most, truth, righteousness // needs review
  AwingWord(awing: 'ndə̌ŋdəŋ', english: 'certainly', category: 'descriptive', difficulty: 1),
  // bible:MAT.2.15, freq=296, conf=0.06, alts: things, man, sent // needs review
  AwingWord(awing: 'ńgɛd', english: 'having', category: 'actions', difficulty: 1),
  // bible:MAT.1.19, freq=294, conf=0.10, alts: believed, things, don // needs review
  AwingWord(awing: 'néŋ', english: 'believe', category: 'actions', difficulty: 1),
  // bible:MAT.1.23, freq=288, conf=0.06, alts: man, things, whoever // needs review
  AwingWord(awing: 'páʼə', english: 'even', category: 'pronouns', difficulty: 1),
  // bible:MAT.1.20, freq=287, conf=0.05, alts: things, don, man // needs review
  AwingWord(awing: 'lɔg', english: 'away', category: 'things', difficulty: 1),
  // bible:MAT.1.25, freq=275, conf=0.12, alts: man, things, don // needs review
  AwingWord(awing: 'yətsə́', english: 'nothing', category: 'things', difficulty: 1),
  // bible:MAT.1.20, freq=273, conf=0.04, alts: man, things, don // needs review
  AwingWord(awing: 'lǒo', english: 'angel', category: 'things', difficulty: 1),
  // bible:MAT.5.10, freq=270, conf=0.15, alts: righteous, right, hand
  AwingWord(awing: 'tɨ́', english: 'righteousness', category: 'body', difficulty: 2),
  // bible:MAT.2.20, freq=263, conf=0.07, alts: things, many, man // needs review
  AwingWord(awing: 'nə̈', english: 'about', category: 'numbers', difficulty: 1),
  // bible:MAT.4.4, freq=246, conf=0.18, alts: book, things, scripture
  AwingWord(awing: 'aŋwaʼlə', english: 'written', category: 'things', difficulty: 1),
  // bible:MAT.5.10, freq=239, conf=0.07, alts: things, works, don // needs review
  AwingWord(awing: 'faʼə̂', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:MAT.5.25, freq=238, conf=0.08, alts: man, day, don // needs review
  AwingWord(awing: 'ghɛnə̂', english: 'away', category: 'things', difficulty: 1),
  // bible:MAT.3.1, freq=236, conf=0.09, alts: love, wilderness, don // needs review
  AwingWord(awing: 'kɔŋ', english: 'beloved', category: 'actions', difficulty: 1),
  // bible:MAT.5.46, freq=233, conf=0.11, alts: don, man, disciples // needs review
  AwingWord(awing: 'akə̂', english: 'say', category: 'things', difficulty: 1),
  // bible:MAT.1.24, freq=230, conf=0.07, alts: man, things, don // needs review
  AwingWord(awing: 'pěʼ', english: 'answered', category: 'actions', difficulty: 1),
  // bible:MAT.2.15, freq=227, conf=0.06, alts: things, word, away // needs review
  AwingWord(awing: 'zɨ́d', english: 'body', category: 'things', difficulty: 1),
  // bible:MAT.3.10, freq=223, conf=0.13, alts: good, things, works // needs review
  AwingWord(awing: 'mimə', english: 'many', category: 'descriptive', difficulty: 1),
  // bible:MAT.1.19, freq=222, conf=0.11, alts: truth, things, true // needs review
  AwingWord(awing: 'ndə̌ŋdəŋə́', english: 'righteousness', category: 'things', difficulty: 2),
  // bible:MAT.1.17, freq=221, conf=0.11, alts: man, things, don // needs review
  AwingWord(awing: 'atû', english: 'woe', category: 'things', difficulty: 1),
  // bible:MAT.9.34, freq=213, conf=0.08, alts: power, things, man // needs review
  AwingWord(awing: 'mətɨ', english: 'authority', category: 'things', difficulty: 1),
  // bible:MAT.2.4, freq=208, conf=0.07, alts: things, day, many // needs review
  AwingWord(awing: 'ətsəm', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:MAT.5.34, freq=208, conf=0.05, alts: things, don, man // needs review
  AwingWord(awing: 'ghɛlə̂', english: 'say', category: 'things', difficulty: 1),
  // bible:MAT.3.5, freq=206, conf=0.08, alts: beginning, day, man // needs review
  AwingWord(awing: 'ə́fɛ́lə', english: 'great', category: 'things', difficulty: 1),
  // bible:MAT.1.17, freq=205, conf=0.06, alts: man, things, away // needs review
  AwingWord(awing: 'fɛ́d', english: 'many', category: 'numbers', difficulty: 1),
  // bible:MAT.3.6, freq=205, conf=0.09, alts: don, among, behold // needs review
  AwingWord(awing: 'tíʼə', english: 'great', category: 'things', difficulty: 1),
  // bible:MAT.2.9, freq=204, conf=0.11, alts: man, behold, people // needs review
  AwingWord(awing: 'ńgyǐ', english: 'brought', category: 'actions', difficulty: 1),
  // bible:MAT.4.25, freq=204, conf=0.15, alts: great, voice, loud
  AwingWord(awing: 'tə́kɔʼ', english: 'city', category: 'descriptive', difficulty: 1),
  // bible:MAT.1.1, freq=203, conf=0.09, alts: man, things, himself // needs review
  AwingWord(awing: 'ají', english: 'hand', category: 'body', difficulty: 1),
  // bible:MAT.5.20, freq=203, conf=0.10, alts: man, death, died // needs review
  AwingWord(awing: 'kwû', english: 'enter', category: 'things', difficulty: 1),
  // bible:MAT.3.5, freq=199, conf=0.17, alts: sea, after, jordan
  AwingWord(awing: 'nkǐ', english: 'water', category: 'nature', difficulty: 1),
  // bible:MAT.5.11, freq=198, conf=0.07, alts: don, brothers, things // needs review
  AwingWord(awing: 'áwə́ənə́', english: 'even', category: 'things', difficulty: 1),
  // bible:MAT.2.1, freq=196, conf=0.08, alts: man, things, word // needs review
  AwingWord(awing: 'wɨ́d', english: 'even', category: 'things', difficulty: 1),
  // bible:MAT.4.23, freq=189, conf=0.15, alts: teacher, things, taught
  AwingWord(awing: 'ńdzéʼkə', english: 'teaching', category: 'actions', difficulty: 1),
  // bible:MAT.7.20, freq=189, conf=0.11, alts: things, days, happened // needs review
  AwingWord(awing: 'laŋ', english: 'after', category: 'things', difficulty: 1),
  // bible:MAT.5.18, freq=185, conf=0.06, alts: man, things, own // needs review
  AwingWord(awing: 'ajíə', english: 'away', category: 'things', difficulty: 1),
  // bible:MAT.8.11, freq=185, conf=0.26, alts: things, man, brothers
  AwingWord(awing: 'pipə', english: 'many', category: 'numbers', difficulty: 1),
  // bible:MAT.2.12, freq=183, conf=0.14, alts: country, tax, chief // needs review
  AwingWord(awing: 'aláʼ', english: 'city', category: 'family', difficulty: 1),
  // bible:MAT.2.23, freq=182, conf=0.07, alts: things, according, law // needs review
  AwingWord(awing: 'nɨd', english: 'show', category: 'actions', difficulty: 1),
  // bible:MAT.5.21, freq=178, conf=0.17, alts: things, word, hears
  AwingWord(awing: 'zóʼ', english: 'hear', category: 'things', difficulty: 1),
  // bible:MAT.3.15, freq=177, conf=0.09, alts: things, good, perfect // needs review
  AwingWord(awing: 'koʼnə̂', english: 'worthy', category: 'descriptive', difficulty: 1),
  // bible:MAT.2.15, freq=176, conf=0.06, alts: don, things, men // needs review
  AwingWord(awing: 'ńgɛlə̂', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:MAT.2.13, freq=173, conf=0.15, alts: death, killed, priests
  AwingWord(awing: 'jwítə', english: 'kill', category: 'actions', difficulty: 3),
  // bible:MAT.3.9, freq=170, conf=0.05, alts: things, don, heart // needs review
  AwingWord(awing: 'mɨ', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:MAT.1.24, freq=165, conf=0.14, alts: led, away, man // needs review
  AwingWord(awing: 'ńdɔgə̂', english: 'brought', category: 'actions', difficulty: 1),
  // bible:MAT.2.2, freq=163, conf=0.08, alts: things, man, behold // needs review
  AwingWord(awing: 'ńdzə́ənə', english: 'having', category: 'things', difficulty: 1),
  // bible:MAT.3.11, freq=159, conf=0.13, alts: heart, things, good // needs review
  AwingWord(awing: 'məntɨ́', english: 'hearts', category: 'descriptive', difficulty: 1),
  // bible:MAT.8.9, freq=157, conf=0.09, alts: man, power, life // needs review
  AwingWord(awing: 'ńtúg', english: 'having', category: 'things', difficulty: 1),
  // bible:MAT.9.33, freq=156, conf=0.08, alts: things, languages, voice // needs review
  AwingWord(awing: 'tsáb', english: 'speaks', category: 'things', difficulty: 1),
  // bible:MAT.2.1, freq=155, conf=0.15, alts: man, great, people
  AwingWord(awing: 'aláʼə', english: 'city', category: 'things', difficulty: 1),
  // bible:MAT.5.39, freq=154, conf=0.13, alts: man, good, law // needs review
  AwingWord(awing: 'təpɔŋə', english: 'evil', category: 'descriptive', difficulty: 3),
  // bible:MAT.6.25, freq=153, conf=0.08, alts: don, things, man // needs review
  AwingWord(awing: 'ajú', english: 'eat', category: 'actions', difficulty: 1),
  // bible:MAT.3.4, freq=148, conf=0.17, alts: disciples, food, bread
  AwingWord(awing: 'məjî', english: 'eat', category: 'actions', difficulty: 1),
  // bible:MAT.3.12, freq=146, conf=0.05, alts: things, man, world // needs review
  AwingWord(awing: 'əpú', english: 'even', category: 'things', difficulty: 1),
  // bible:MAT.3.14, freq=146, conf=0.08, alts: man, don, things // needs review
  AwingWord(awing: 'ə́lɛ́', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:MAT.3.2, freq=141, conf=0.10, alts: leave, away, man // needs review
  AwingWord(awing: 'mɛdtə̂', english: 'left', category: 'actions', difficulty: 1),
  // bible:MAT.9.26, freq=140, conf=0.18, alts: things, words, away
  AwingWord(awing: 'atsáb', english: 'word', category: 'things', difficulty: 1),
  // bible:MAT.1.22, freq=139, conf=0.08, alts: things, eyes, himself // needs review
  AwingWord(awing: 'mí', english: 'feet', category: 'pronouns', difficulty: 1),
  // bible:MAT.3.7, freq=139, conf=0.06, alts: things, believed, men // needs review
  AwingWord(awing: 'əghɔ́b', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:MAT.2.6, freq=137, conf=0.15, alts: judgment, judged, man
  AwingWord(awing: 'əsáʼ', english: 'judge', category: 'things', difficulty: 1),
  // bible:MAT.4.5, freq=135, conf=0.05, alts: things, before, place // needs review
  AwingWord(awing: 'ŋwaʼ', english: 'pure', category: 'things', difficulty: 1),
  // bible:MAT.1.21, freq=129, conf=0.10, alts: men, man, brothers // needs review
  AwingWord(awing: 'mbyâŋnə', english: 'mother', category: 'family', difficulty: 1),
  // bible:MAT.2.9, freq=128, conf=0.11, alts: things, behold, before // needs review
  AwingWord(awing: 'ntə́əmə', english: 'stood', category: 'actions', difficulty: 1),
  // bible:MAT.1.17, freq=124, conf=0.21, alts: day, time, many
  AwingWord(awing: 'ńkoʼ', english: 'until', category: 'numbers', difficulty: 1),
  // bible:MAT.1.25, freq=124, conf=0.06, alts: man, behold, things // needs review
  AwingWord(awing: 'ndaʼ', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:MAT.2.16, freq=122, conf=0.06, alts: things, about, good // needs review
  AwingWord(awing: 'mətsəm', english: 'assemblies', category: 'descriptive', difficulty: 1),
  // bible:MAT.4.10, freq=122, conf=0.08, alts: man, things, wife // needs review
  AwingWord(awing: 'shib', english: 'good', category: 'family', difficulty: 1),
  // bible:MAT.5.12, freq=122, conf=0.14, alts: good, things, until // needs review
  AwingWord(awing: 'pɔŋə̂', english: 'before', category: 'descriptive', difficulty: 1),
  // bible:MAT.14.14, freq=121, conf=0.07, alts: things, man, good // needs review
  AwingWord(awing: 'ńtúgə', english: 'having', category: 'descriptive', difficulty: 1),
  // bible:MAT.1.11, freq=120, conf=0.07, alts: man, things, day // needs review
  AwingWord(awing: 'ńdɔg', english: 'brought', category: 'actions', difficulty: 1),
  // bible:MAT.4.8, freq=120, conf=0.09, alts: world, judged, man // needs review
  AwingWord(awing: 'sáʼ', english: 'judge', category: 'things', difficulty: 1),
  // bible:MAT.6.34, freq=120, conf=0.12, alts: oppression, things, many // needs review
  AwingWord(awing: 'ngə́ʼ', english: 'suffer', category: 'numbers', difficulty: 1),
  // bible:MAT.11.20, freq=120, conf=0.07, alts: man, things, before // needs review
  AwingWord(awing: 'ḿbɛ́d', english: 'left', category: 'actions', difficulty: 1),
  // bible:MAT.2.6, freq=117, conf=0.11, alts: ruler, man, officer // needs review
  AwingWord(awing: 'nətû', english: 'centurion', category: 'family', difficulty: 2),
  // bible:MAT.7.24, freq=115, conf=0.12, alts: good, work, man // needs review
  AwingWord(awing: 'afaʼ', english: 'servant', category: 'actions', difficulty: 1),
  // bible:MAT.2.8, freq=114, conf=0.11, alts: worshiped, worship, things // needs review
  AwingWord(awing: 'ńgóʼkə', english: 'honor', category: 'things', difficulty: 2),
  // bible:MAT.2.15, freq=114, conf=0.23, alts: things, way, good
  AwingWord(awing: 'ńtú', english: 'sent', category: 'actions', difficulty: 1),
  // bible:MAT.16.21, freq=114, conf=0.18, alts: chief, priests, rulers
  AwingWord(awing: 'mətû', english: 'elders', category: 'family', difficulty: 2),
  // bible:MAT.5.10, freq=112, conf=0.06, alts: man, things, say // needs review
  AwingWord(awing: 'pə̈', english: 'disciples', category: 'things', difficulty: 3),
  // bible:MAT.1.17, freq=108, conf=0.07, alts: man, time, things // needs review
  AwingWord(awing: 'ə́fɛ́d', english: 'behold', category: 'things', difficulty: 2),
  // bible:MAT.1.25, freq=108, conf=0.10, alts: man, great, day // needs review
  AwingWord(awing: 'láʼ', english: 'until', category: 'things', difficulty: 1),
  // bible:MAT.5.43, freq=107, conf=0.05, alts: love, don, loved // needs review
  AwingWord(awing: 'kɔŋə̂', english: 'desire', category: 'actions', difficulty: 1),
  // bible:MAT.2.13, freq=106, conf=0.06, alts: things, way, happened // needs review
  AwingWord(awing: 'ə́fiʼtə̂', english: 'about', category: 'things', difficulty: 1),
  // bible:MAT.21.25, freq=106, conf=0.05, alts: things, love, having // needs review
  AwingWord(awing: 'áwɛ̂n', english: 'before', category: 'actions', difficulty: 1),
  // bible:MAT.9.18, freq=105, conf=0.10, alts: things, behold, parable // needs review
  AwingWord(awing: 'ńtséebə', english: 'speaking', category: 'things', difficulty: 1),
  // bible:MAT.7.5, freq=104, conf=0.08, alts: blind, don, eyes // needs review
  AwingWord(awing: 'əliʼ', english: 'sight', category: 'things', difficulty: 1),
  // bible:MAT.9.3, freq=102, conf=0.22, alts: themselves, man, between
  AwingWord(awing: 'tətɨ', english: 'among', category: 'pronouns', difficulty: 1),
  // bible:MAT.1.17, freq=101, conf=0.14, alts: right, tribe, man // needs review
  AwingWord(awing: 'əlá', english: 'hand', category: 'body', difficulty: 1),
  // bible:MAT.5.42, freq=101, conf=0.12, alts: brothers, things, don // needs review
  AwingWord(awing: 'loonə̂', english: 'want', category: 'actions', difficulty: 1),
  // bible:MAT.10.22, freq=100, conf=0.08, alts: brothers, good, hold // needs review
  AwingWord(awing: 'ńtyantə̂', english: 'stand', category: 'actions', difficulty: 1),
  // bible:MAT.2.12, freq=98, conf=0.12, alts: returned, good, back // needs review
  AwingWord(awing: 'ḿbəənə̂', english: 'again', category: 'body', difficulty: 1),
  // bible:MAT.6.24, freq=96, conf=0.15, alts: silver, sold, received
  AwingWord(awing: 'nkáb', english: 'money', category: 'actions', difficulty: 1),
  // bible:MAT.1.23, freq=95, conf=0.07, alts: things, many, days // needs review
  AwingWord(awing: 'kə̈', english: 'even', category: 'numbers', difficulty: 1),
  // bible:MAT.3.9, freq=95, conf=0.08, alts: things, earth, man // needs review
  AwingWord(awing: 'tsoŋkə̂', english: 'golden', category: 'nature', difficulty: 1),
  // bible:MAT.8.27, freq=94, conf=0.07, alts: things, man, day // needs review
  AwingWord(awing: 'yəwə́', english: 'marveled', category: 'things', difficulty: 2),
  // bible:MAT.6.2, freq=92, conf=0.08, alts: things, men, themselves // needs review
  AwingWord(awing: 'əzɔb', english: 'own', category: 'pronouns', difficulty: 1),
  // bible:MAT.5.19, freq=91, conf=0.12, alts: things, don, commandments // needs review
  AwingWord(awing: 'zóʼnə', english: 'obey', category: 'things', difficulty: 2),
  // bible:MAT.11.29, freq=91, conf=0.16, alts: flesh, myself, don
  AwingWord(awing: 'mbəəmə', english: 'body', category: 'pronouns', difficulty: 1),
  // bible:MAT.2.19, freq=88, conf=0.10, alts: entered, died, man // needs review
  AwingWord(awing: 'ńkwú', english: 'dead', category: 'actions', difficulty: 3),
  // bible:MAT.5.22, freq=88, conf=0.22, alts: man, better, things
  AwingWord(awing: 'pɔŋ', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:MAT.2.8, freq=87, conf=0.08, alts: things, seek, man // needs review
  AwingWord(awing: 'ńnáŋə', english: 'looking', category: 'things', difficulty: 1),
  // bible:MAT.5.2, freq=86, conf=0.11, alts: things, teaching, teach // needs review
  AwingWord(awing: 'zéʼkə', english: 'taught', category: 'actions', difficulty: 1),
  // bible:MAT.5.13, freq=86, conf=0.18, alts: except, man, don
  AwingWord(awing: 'ńdéʼtə', english: 'unless', category: 'things', difficulty: 1),
  // bible:MAT.6.7, freq=86, conf=0.08, alts: don, man, seize // needs review
  AwingWord(awing: 'wam', english: 'cheer', category: 'things', difficulty: 1),
  // bible:MAT.6.7, freq=86, conf=0.21, alts: ears, don, word
  AwingWord(awing: 'zóʼə', english: 'hear', category: 'things', difficulty: 1),
  // bible:MAT.5.17, freq=85, conf=0.07, alts: things, before, days // needs review
  AwingWord(awing: 'pɨ́d', english: 'body', category: 'things', difficulty: 1),
  // bible:MAT.20.1, freq=84, conf=0.07, alts: things, whatever, servant // needs review
  AwingWord(awing: 'ə́faʼə̂', english: 'good', category: 'family', difficulty: 1),
  // bible:MAT.5.28, freq=83, conf=0.09, alts: man, don, things // needs review
  AwingWord(awing: 'náŋ', english: 'behold', category: 'things', difficulty: 2),
  // bible:MAT.17.15, freq=83, conf=0.08, alts: even, things, exceedingly // needs review
  AwingWord(awing: 'ḿbyádnə', english: 'much', category: 'things', difficulty: 1),
  // bible:MAT.1.19, freq=82, conf=0.13, alts: immorality, marriage, wife // needs review
  AwingWord(awing: 'ndzɔʼə́', english: 'sexual', category: 'family', difficulty: 3),
  // bible:MAT.4.2, freq=82, conf=0.12, alts: men, don, disciples // needs review
  AwingWord(awing: 'ńchaʼtə́sê', english: 'praying', category: 'things', difficulty: 1),
  // bible:MAT.5.16, freq=82, conf=0.09, alts: things, clean, man // needs review
  AwingWord(awing: 'ŋwaʼə̂', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:MAT.5.33, freq=82, conf=0.18, alts: promised, law, oath
  AwingWord(awing: 'ndaʼnə', english: 'promise', category: 'things', difficulty: 1),
  // bible:MAT.9.16, freq=82, conf=0.18, alts: betrayed, man, old
  AwingWord(awing: 'fî', english: 'new', category: 'descriptive', difficulty: 1),
  // bible:MAT.10.14, freq=82, conf=0.15, alts: listen, behold, man
  AwingWord(awing: 'jwə́ʼtə', english: 'hear', category: 'actions', difficulty: 1),
  // bible:MAT.20.3, freq=82, conf=0.15, alts: don, nor, anything
  AwingWord(awing: 'ajûtsə́', english: 'nothing', category: 'things', difficulty: 1),
  // bible:MAT.5.25, freq=79, conf=0.09, alts: man, laid, both // needs review
  AwingWord(awing: 'ńnéŋə', english: 'prison', category: 'things', difficulty: 1),
  // bible:MAT.5.38, freq=78, conf=0.10, alts: men, ones, send // needs review
  AwingWord(awing: 'tsɔ́ʼ', english: 'chosen', category: 'actions', difficulty: 1),
  // bible:MRK.6.17, freq=78, conf=0.18, alts: man, things, even
  AwingWord(awing: 'nkɔ̌ʼmbɨ', english: 'himself', category: 'pronouns', difficulty: 1),
  // bible:MAT.8.6, freq=77, conf=0.08, alts: things, great, sufferings // needs review
  AwingWord(awing: 'ngə́ʼə', english: 'suffer', category: 'things', difficulty: 1),
  // bible:MAT.2.16, freq=76, conf=0.07, alts: brothers, great, children // needs review
  AwingWord(awing: 'pətsəmə', english: 'saints', category: 'family', difficulty: 1),
  // bible:MAT.3.4, freq=76, conf=0.09, alts: things, man, earth // needs review
  AwingWord(awing: 'ńtsoŋkə̂', english: 'prepared', category: 'nature', difficulty: 1),
  // bible:MAT.3.11, freq=76, conf=0.11, alts: most, great, high // needs review
  AwingWord(awing: 'tsɛ', english: 'greater', category: 'things', difficulty: 1),
  // bible:MAT.5.21, freq=76, conf=0.19, alts: kill, rest, men
  AwingWord(awing: 'ńjwítə', english: 'killed', category: 'actions', difficulty: 3),
  // bible:MAT.1.18, freq=75, conf=0.11, alts: day, disciples, end // needs review
  AwingWord(awing: 'ńkoʼə̂', english: 'until', category: 'things', difficulty: 1),
  // bible:MAT.12.40, freq=75, conf=0.21, alts: city, early, first
  AwingWord(awing: 'mɛ́', english: 'great', category: 'numbers', difficulty: 1),
  // bible:MAT.4.18, freq=74, conf=0.10, alts: walk, sea, about // needs review
  AwingWord(awing: 'ńnyinə̂', english: 'walking', category: 'actions', difficulty: 1),
  // bible:MAT.13.17, freq=74, conf=0.07, alts: things, way, about // needs review
  AwingWord(awing: 'mɨ́d', english: 'many', category: 'numbers', difficulty: 1),
  // bible:MAT.1.17, freq=73, conf=0.21, alts: about, man, against
  AwingWord(awing: 'ńchúʼə', english: 'began', category: 'things', difficulty: 1),
  // bible:MAT.1.17, freq=73, conf=0.08, alts: day, until, away // needs review
  AwingWord(awing: 'koʼ', english: 'long', category: 'things', difficulty: 1),
  // bible:MAT.5.25, freq=73, conf=0.15, alts: centurion, officer, commanding
  AwingWord(awing: 'ngaŋə́maʼə́ntso', english: 'soldiers', category: 'things', difficulty: 2),
  // bible:MAT.4.6, freq=72, conf=0.13, alts: tree, branches, man // needs review
  AwingWord(awing: 'atǐ', english: 'fruit', category: 'nature', difficulty: 1),
  // bible:MAT.12.19, freq=72, conf=0.17, alts: words, things, language
  AwingWord(awing: 'ətsáb', english: 'languages', category: 'things', difficulty: 1),
  // bible:MAT.2.2, freq=71, conf=0.16, alts: honor, jews, serve
  AwingWord(awing: 'ghóʼkə', english: 'worship', category: 'actions', difficulty: 2),
  // bible:MAT.3.4, freq=71, conf=0.15, alts: garments, white, man
  AwingWord(awing: 'ətsəʼ', english: 'clothing', category: 'descriptive', difficulty: 1),
  // bible:MAT.5.12, freq=71, conf=0.05, alts: life, body, children // needs review
  AwingWord(awing: 'əzɨ', english: 'good', category: 'family', difficulty: 1),
  // bible:MAT.27.12, freq=71, conf=0.12, alts: many, away, sent // needs review
  AwingWord(awing: 'ńnéŋ', english: 'believed', category: 'actions', difficulty: 1),
  // bible:MAT.3.3, freq=70, conf=0.09, alts: things, about, languages // needs review
  AwingWord(awing: 'ńtsáb', english: 'before', category: 'things', difficulty: 1),
  // bible:MAT.6.33, freq=70, conf=0.28, alts: things, man, own
  AwingWord(awing: 'peg', english: 'first', category: 'numbers', difficulty: 1),
  // bible:MAT.4.25, freq=68, conf=0.09, alts: own, children, parents // needs review
  AwingWord(awing: 'pɔ́b', english: 'sins', category: 'family', difficulty: 2),
  // bible:MAT.4.24, freq=67, conf=0.10, alts: possessed, man, healed // needs review
  AwingWord(awing: 'pɛ̌sê', english: 'cast', category: 'actions', difficulty: 1),
  // bible:MAT.5.47, freq=67, conf=0.22, alts: fellow, beloved, don
  AwingWord(awing: 'chaʼtə̂', english: 'greet', category: 'actions', difficulty: 1),
  // bible:MAT.4.2, freq=66, conf=0.13, alts: hundred, years, thirty // needs review
  AwingWord(awing: 'məghə́m', english: 'forty', category: 'numbers', difficulty: 1),
  // bible:MAT.6.17, freq=66, conf=0.13, alts: wife, man, sexual // needs review
  AwingWord(awing: 'ndzɔʼ', english: 'among', category: 'family', difficulty: 1),
  // bible:MAT.3.7, freq=65, conf=0.16, alts: house, household, many
  AwingWord(awing: 'ngwud', english: 'offspring', category: 'numbers', difficulty: 1),
  // bible:MAT.8.31, freq=65, conf=0.06, alts: things, men, good // needs review
  AwingWord(awing: 'áwə́g', english: 'even', category: 'descriptive', difficulty: 1),
  // bible:MAT.7.20, freq=64, conf=0.10, alts: themselves, men, people // needs review
  AwingWord(awing: 'móobə́', english: 'hands', category: 'pronouns', difficulty: 1),
  // bible:MAT.10.23, freq=64, conf=0.08, alts: don, man, way // needs review
  AwingWord(awing: 'ndaʼə', english: 'himself', category: 'pronouns', difficulty: 1),
  // bible:MAT.12.10, freq=64, conf=0.12, alts: sought, behold, hand // needs review
  AwingWord(awing: 'ńnáŋ', english: 'looking', category: 'body', difficulty: 1),
  // bible:MAT.3.12, freq=63, conf=0.17, alts: uncircumcision, begged, beg
  AwingWord(awing: 'póʼ', english: 'circumcision', category: 'things', difficulty: 3),
  // bible:MAT.3.11, freq=62, conf=0.08, alts: time, day, behold // needs review
  AwingWord(awing: 'koʼə̂', english: 'until', category: 'things', difficulty: 1),
  // bible:MAT.23.25, freq=61, conf=0.09, alts: love, among, don // needs review
  AwingWord(awing: 'məmbɨ', english: 'yourselves', category: 'actions', difficulty: 1),
  // bible:MAT.1.19, freq=60, conf=0.11, alts: love, beloved, things // needs review
  AwingWord(awing: 'ńkɔŋə̂', english: 'loved', category: 'actions', difficulty: 1),
  // bible:MAT.4.17, freq=60, conf=0.16, alts: man, disciples, time
  AwingWord(awing: 'chúʼə', english: 'began', category: 'things', difficulty: 1),
  // bible:MAT.3.5, freq=59, conf=0.10, alts: region, sea, borders // needs review
  AwingWord(awing: 'mboʼ', english: 'asia', category: 'nature', difficulty: 3),
  // bible:MAT.5.17, freq=59, conf=0.17, alts: full, things, joy
  AwingWord(awing: 'lwɛ́nkə', english: 'filled', category: 'actions', difficulty: 1),
  // bible:MAT.5.19, freq=59, conf=0.08, alts: things, good, against // needs review
  AwingWord(awing: 'azɔ́b', english: 'live', category: 'descriptive', difficulty: 1),
  // bible:MAT.6.21, freq=58, conf=0.09, alts: treasure, things, good // needs review
  AwingWord(awing: 'afoʼə', english: 'riches', category: 'descriptive', difficulty: 1),
  // bible:MAT.8.29, freq=58, conf=0.08, alts: man, things, didn // needs review
  AwingWord(awing: 'ghə́', english: 'without', category: 'things', difficulty: 1),
  // bible:MAT.11.13, freq=58, conf=0.06, alts: things, heart, great // needs review
  AwingWord(awing: 'mətsəmə', english: 'law', category: 'things', difficulty: 1),
  // bible:MAT.1.3, freq=57, conf=0.07, alts: things, don, men // needs review
  AwingWord(awing: 'əghoobə́', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:MAT.4.12, freq=57, conf=0.23, alts: bonds, sent, before
  AwingWord(awing: 'atsáŋ', english: 'prison', category: 'actions', difficulty: 1),
  // bible:MAT.7.25, freq=57, conf=0.09, alts: men, don, man // needs review
  AwingWord(awing: 'wǔ', english: 'condemn', category: 'things', difficulty: 1),
  // bible:MAT.11.23, freq=57, conf=0.09, alts: against, way, woman // needs review
  AwingWord(awing: 'wə́ələ́', english: 'away', category: 'things', difficulty: 1),
  // bible:MAT.5.48, freq=56, conf=0.11, alts: justified, law, works // needs review
  AwingWord(awing: 'ńkoʼnə̂', english: 'righteousness', category: 'things', difficulty: 2),
  // bible:MAT.6.28, freq=56, conf=0.11, alts: after, don, about // needs review
  AwingWord(awing: 'kɔ́ʼ', english: 'wind', category: 'nature', difficulty: 1),
  // bible:MAT.5.1, freq=55, conf=0.09, alts: great, until, together // needs review
  AwingWord(awing: 'ńkɔ́ʼ', english: 'mountain', category: 'nature', difficulty: 1),
  // bible:MAT.5.23, freq=55, conf=0.17, alts: remember, don, remembered
  AwingWord(awing: 'ńkwumtə̂', english: 'crucified', category: 'actions', difficulty: 3),
  // bible:MAT.12.12, freq=55, conf=0.08, alts: man, things, having // needs review
  AwingWord(awing: 'lánə', english: 'answered', category: 'actions', difficulty: 1),
  // bible:MAT.12.33, freq=55, conf=0.17, alts: man, laid, sent
  AwingWord(awing: 'míə', english: 'hands', category: 'actions', difficulty: 1),
  // bible:MAT.6.2, freq=54, conf=0.12, alts: things, received, men // needs review
  AwingWord(awing: 'pɛ́dtə', english: 'already', category: 'things', difficulty: 1),
  // bible:MAT.8.3, freq=54, conf=0.17, alts: man, farmers, wall
  AwingWord(awing: 'nkáʼ', english: 'vineyard', category: 'things', difficulty: 1),
  // bible:MAT.9.35, freq=53, conf=0.17, alts: heads, nation, earth
  AwingWord(awing: 'ətú', english: 'nations', category: 'nature', difficulty: 1),
  // bible:MAT.2.21, freq=52, conf=0.09, alts: rose, stood, returned // needs review
  AwingWord(awing: 'ńdǒo', english: 'great', category: 'things', difficulty: 1),
  // bible:MAT.5.33, freq=52, conf=0.11, alts: oath, earth, swear // needs review
  AwingWord(awing: 'atyǎntə', english: 'great', category: 'nature', difficulty: 1),
  // bible:MAT.6.25, freq=52, conf=0.09, alts: don, things, flesh // needs review
  AwingWord(awing: 'əzəənə́', english: 'yourselves', category: 'things', difficulty: 1),
  // bible:MAT.15.3, freq=52, conf=0.16, alts: commandment, law, good
  AwingWord(awing: 'məntəgə́', english: 'commandments', category: 'descriptive', difficulty: 2),
  // bible:MAT.2.11, freq=51, conf=0.09, alts: man, city, own // needs review
  AwingWord(awing: 'ə́fógə', english: 'white', category: 'descriptive', difficulty: 1),
  // bible:MAT.8.12, freq=50, conf=0.12, alts: great, people, teeth // needs review
  AwingWord(awing: 'məsɔŋ', english: 'multitude', category: 'things', difficulty: 1),
  // bible:MAT.25.21, freq=50, conf=0.21, alts: joy, things, well
  AwingWord(awing: 'kɔŋtə̂', english: 'rejoice', category: 'descriptive', difficulty: 1),
  // bible:MAT.2.5, freq=49, conf=0.16, alts: things, wrote, prophets
  AwingWord(awing: 'ŋ́ŋwaʼlə̂', english: 'written', category: 'things', difficulty: 1),
  // bible:MAT.5.11, freq=49, conf=0.06, alts: things, don, knowledge // needs review
  AwingWord(awing: 'azɨ́', english: 'answered', category: 'actions', difficulty: 1),
  // bible:MAT.5.41, freq=49, conf=0.08, alts: man, goods, possessions // needs review
  AwingWord(awing: 'apeʼə', english: 'yourselves', category: 'things', difficulty: 1),
  // bible:MAT.12.19, freq=49, conf=0.09, alts: man, cried, going // needs review
  AwingWord(awing: 'kɔ́ʼə', english: 'voice', category: 'things', difficulty: 1),
  // bible:MAT.14.5, freq=49, conf=0.15, alts: fear, things, feared
  AwingWord(awing: 'ḿbɔ́gə', english: 'afraid', category: 'descriptive', difficulty: 1),
  // bible:MAT.2.1, freq=48, conf=0.13, alts: stars, star, sun // needs review
  AwingWord(awing: 'sáŋ', english: 'months', category: 'nature', difficulty: 1),
  // bible:MAT.5.22, freq=48, conf=0.11, alts: rebuked, judged, judge // needs review
  AwingWord(awing: 'əsáʼə', english: 'judgment', category: 'things', difficulty: 2),
  // bible:MAT.6.19, freq=48, conf=0.07, alts: things, don, man // needs review
  AwingWord(awing: 'lɔʼkə̂', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:MAT.12.44, freq=48, conf=0.09, alts: stumble, man, cut // needs review
  AwingWord(awing: 'ájɨ́d', english: 'cast', category: 'actions', difficulty: 1),
  // bible:MAT.3.6, freq=47, conf=0.10, alts: children, own, parents // needs review
  AwingWord(awing: 'póobə́', english: 'sins', category: 'family', difficulty: 2),
  // bible:MAT.6.2, freq=47, conf=0.13, alts: against, houses, receive // needs review
  AwingWord(awing: 'məláʼ', english: 'synagogues', category: 'things', difficulty: 1),
  // bible:MAT.1.18, freq=46, conf=0.12, alts: sexual, immorality, married // needs review
  AwingWord(awing: 'zɔ́ʼ', english: 'wife', category: 'family', difficulty: 1),
  // bible:MAT.5.17, freq=45, conf=0.09, alts: destruction, don, old // needs review
  AwingWord(awing: 'tsəŋkə̂', english: 'destroy', category: 'descriptive', difficulty: 1),
  // bible:MAT.5.24, freq=45, conf=0.21, alts: before, good, away
  AwingWord(awing: 'ḿbeg', english: 'first', category: 'descriptive', difficulty: 1),
  // bible:MAT.5.45, freq=45, conf=0.06, alts: things, man, say // needs review
  AwingWord(awing: 'ńkə̈', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:MAT.8.10, freq=45, conf=0.13, alts: amazed, astonished, things // needs review
  AwingWord(awing: 'ńkɨʼnə̂', english: 'marveled', category: 'things', difficulty: 2),
  // bible:MAT.23.3, freq=45, conf=0.09, alts: even, love, law // needs review
  AwingWord(awing: 'ńdzóʼnə', english: 'subjection', category: 'actions', difficulty: 1),
  // bible:MRK.12.29, freq=45, conf=0.10, alts: hand, man, power // needs review
  AwingWord(awing: 'əzɛ̂n', english: 'flesh', category: 'body', difficulty: 1),
  // bible:MAT.13.13, freq=44, conf=0.14, alts: things, man, understand // needs review
  AwingWord(awing: 'ńdzóʼə', english: 'hear', category: 'things', difficulty: 1),
  // bible:MAT.10.28, freq=43, conf=0.21, alts: afraid, don, men
  AwingWord(awing: 'pɔ́g', english: 'fear', category: 'descriptive', difficulty: 2),
  // bible:MAT.11.11, freq=43, conf=0.10, alts: things, men, most // needs review
  AwingWord(awing: 'tsɛɛlə̂', english: 'greater', category: 'things', difficulty: 1),
  // bible:MAT.14.24, freq=43, conf=0.17, alts: long, time, off
  AwingWord(awing: 'ndi', english: 'far', category: 'things', difficulty: 1),
  // bible:MAT.14.29, freq=43, conf=0.11, alts: light, day, walks // needs review
  AwingWord(awing: 'nyi', english: 'walk', category: 'actions', difficulty: 1),
  // bible:MAT.5.42, freq=42, conf=0.07, alts: world, man, things // needs review
  AwingWord(awing: 'ńtsɔ́ʼə', english: 'chose', category: 'things', difficulty: 1),
  // bible:MRK.1.13, freq=42, conf=0.14, alts: living, four, animals // needs review
  AwingWord(awing: 'məna', english: 'creatures', category: 'numbers', difficulty: 1),
  // bible:MAT.4.10, freq=41, conf=0.10, alts: about, man, men // needs review
  AwingWord(awing: 'nəpɛnə́', english: 'stood', category: 'actions', difficulty: 1),
  // bible:MAT.6.34, freq=41, conf=0.07, alts: things, good, servant // needs review
  AwingWord(awing: 'mənuə', english: 'faithful', category: 'family', difficulty: 2),
  // bible:MAT.2.16, freq=40, conf=0.10, alts: things, children, angry // needs review
  AwingWord(awing: 'záŋ', english: 'wrath', category: 'family', difficulty: 3),
  // bible:MAT.3.5, freq=40, conf=0.13, alts: people, villages, place // needs review
  AwingWord(awing: 'əláʼ', english: 'cities', category: 'things', difficulty: 1),
  // bible:MAT.6.17, freq=40, conf=0.11, alts: feet, wash, things // needs review
  AwingWord(awing: 'sog', english: 'washed', category: 'actions', difficulty: 1),
  // bible:MAT.9.16, freq=40, conf=0.11, alts: cloth, away, garment // needs review
  AwingWord(awing: 'atsəʼ', english: 'linen', category: 'things', difficulty: 1),
  // bible:MAT.9.17, freq=40, conf=0.08, alts: things, revealed, prepared // needs review
  AwingWord(awing: 'mə́ələ́', english: 'wine', category: 'food', difficulty: 1),
  // bible:MAT.12.12, freq=40, conf=0.08, alts: things, man, much // needs review
  AwingWord(awing: 'ńchígə́', english: 'having', category: 'things', difficulty: 1),
  // bible:MAT.14.24, freq=40, conf=0.13, alts: sea, going, way // needs review
  AwingWord(awing: 'ńkɔ́ʼə', english: 'wind', category: 'nature', difficulty: 1),
  // bible:MAT.5.13, freq=39, conf=0.08, alts: don, man, behold // needs review
  AwingWord(awing: 'pɛ́lə', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:MAT.7.6, freq=39, conf=0.12, alts: turning, around, men // needs review
  AwingWord(awing: 'sɛdnə̂', english: 'turned', category: 'things', difficulty: 1),
  // bible:MAT.5.6, freq=38, conf=0.06, alts: men, place, hands // needs review
  AwingWord(awing: 'ə̈', english: 'hunger', category: 'things', difficulty: 1),
  // bible:MAT.13.22, freq=38, conf=0.09, alts: jews, even, rest // needs review
  AwingWord(awing: 'mətsə́', english: 'against', category: 'things', difficulty: 1),
  // bible:MAT.14.21, freq=38, conf=0.15, alts: hates, hate, even
  AwingWord(awing: 'pǎ', english: 'though', category: 'actions', difficulty: 1),
  // bible:MAT.18.10, freq=38, conf=0.08, alts: things, don, many // needs review
  AwingWord(awing: 'əŋwaʼlə', english: 'about', category: 'numbers', difficulty: 1),
  // bible:MAT.2.3, freq=37, conf=0.11, alts: love, neighbors, master // needs review
  AwingWord(awing: 'ngaŋ', english: 'neighbor', category: 'actions', difficulty: 1),
  // bible:MAT.9.16, freq=37, conf=0.12, alts: linen, veil, head // needs review
  AwingWord(awing: 'apagə', english: 'cloth', category: 'body', difficulty: 1),
  // bible:MAT.23.7, freq=37, conf=0.10, alts: love, loved, marketplaces // needs review
  AwingWord(awing: 'ńkɔŋ', english: 'wish', category: 'actions', difficulty: 1),
  // bible:LUK.1.2, freq=37, conf=0.06, alts: things, ourselves, love // needs review
  AwingWord(awing: 'áwɛ̂nə', english: 'delivered', category: 'actions', difficulty: 1),
  // bible:MAT.20.1, freq=36, conf=0.11, alts: vineyard, word, man // needs review
  AwingWord(awing: 'əyə́', english: 'himself', category: 'pronouns', difficulty: 1),
  // bible:MAT.1.19, freq=35, conf=0.08, alts: jews, man, men // needs review
  AwingWord(awing: 'əshîsaŋ', english: 'openly', category: 'descriptive', difficulty: 1),
  // bible:MAT.5.7, freq=35, conf=0.13, alts: men, against, light // needs review
  AwingWord(awing: 'məsɔŋə́', english: 'multitude', category: 'descriptive', difficulty: 1),
  // bible:MAT.6.26, freq=35, conf=0.14, alts: behold, things, people // needs review
  AwingWord(awing: 'ḿbɛ́lə', english: 'speaking', category: 'things', difficulty: 1),
  // bible:MAT.7.6, freq=35, conf=0.11, alts: throw, way, things // needs review
  AwingWord(awing: 'maʼ', english: 'overcomes', category: 'actions', difficulty: 1),
  // bible:MAT.7.28, freq=35, conf=0.13, alts: astonished, amazed, things // needs review
  AwingWord(awing: 'kɨʼnə̂', english: 'marveled', category: 'things', difficulty: 2),
  // bible:MAT.2.3, freq=34, conf=0.10, alts: time, things, began // needs review
  AwingWord(awing: 'jɨ́d', english: 'disciples', category: 'things', difficulty: 3),
  // bible:MAT.4.13, freq=34, conf=0.15, alts: seaside, again, simon
  AwingWord(awing: 'nkaŋ', english: 'sea', category: 'nature', difficulty: 1),
  // bible:MAT.9.30, freq=34, conf=0.12, alts: blind, man, eyes // needs review
  AwingWord(awing: 'əliʼə́', english: 'sight', category: 'things', difficulty: 1),
  // bible:MAT.11.7, freq=34, conf=0.09, alts: things, first, good // needs review
  AwingWord(awing: 'ńkwaŋ', english: 'supposed', category: 'descriptive', difficulty: 1),
  // bible:MAT.12.35, freq=34, conf=0.06, alts: earth, men, man // needs review
  AwingWord(awing: 'ńdɔʼkə̂', english: 'treasure', category: 'nature', difficulty: 1),
  // bible:MAT.13.13, freq=34, conf=0.13, alts: many, things, body // needs review
  AwingWord(awing: 'pǎtə', english: 'though', category: 'numbers', difficulty: 1),
  // bible:MAT.14.9, freq=34, conf=0.07, alts: sat, after, good // needs review
  AwingWord(awing: 'áwɨ́d', english: 'commanded', category: 'descriptive', difficulty: 1),
  // bible:MAT.1.24, freq=33, conf=0.09, alts: don, brothers, works // needs review
  AwingWord(awing: 'ə́faʼ', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:MAT.4.23, freq=33, conf=0.08, alts: walk, good, among // needs review
  AwingWord(awing: 'nyinə̂', english: 'news', category: 'actions', difficulty: 1),
  // bible:MAT.5.38, freq=33, conf=0.12, alts: didn, people, threw // needs review
  AwingWord(awing: 'ńtsɔ́ʼ', english: 'chosen', category: 'things', difficulty: 1),
  // bible:MAT.15.32, freq=33, conf=0.07, alts: days, brothers, after // needs review
  AwingWord(awing: 'pə̌gpo', english: 'stayed', category: 'things', difficulty: 1),
  // bible:MAT.19.26, freq=33, conf=0.12, alts: looking, things, before // needs review
  AwingWord(awing: 'tə́g', english: 'set', category: 'things', difficulty: 1),
  // bible:MAT.8.16, freq=32, conf=0.09, alts: day, among, first // needs review
  AwingWord(awing: 'ḿbɛn', english: 'evening', category: 'numbers', difficulty: 1),
  // bible:MAT.15.11, freq=32, conf=0.09, alts: things, man, doesn // needs review
  AwingWord(awing: 'mə̈', english: 'defile', category: 'things', difficulty: 1),
  // bible:MAT.22.6, freq=32, conf=0.08, alts: away, good, perseverance // needs review
  AwingWord(awing: 'ńgwam', english: 'before', category: 'descriptive', difficulty: 1),
  // bible:MAT.26.11, freq=32, conf=0.05, alts: don, things, even // needs review
  AwingWord(awing: 'pɨ̌pə', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:MAT.1.24, freq=31, conf=0.14, alts: coming, own, country // needs review
  AwingWord(awing: 'ńkwə̂', english: 'house', category: 'things', difficulty: 1),
  // bible:MAT.10.22, freq=31, conf=0.17, alts: end, first, man
  AwingWord(awing: 'ndwegtə', english: 'last', category: 'numbers', difficulty: 1),
  // bible:MAT.14.12, freq=31, conf=0.20, alts: dead, man, laid
  AwingWord(awing: 'akwûə', english: 'body', category: 'things', difficulty: 1),

  // bible:MAT.5.10, freq=30, conf=0.12, alts: persecuted, persecution, sake // needs review
  AwingWord(awing: 'tsaŋkə̂', english: 'persecute', category: 'things', difficulty: 2),
  // bible:MAT.7.24, freq=30, conf=0.08, alts: man, built, city // needs review
  AwingWord(awing: 'mbɔ́', english: 'house', category: 'things', difficulty: 1),
  // bible:MAT.8.4, freq=30, conf=0.12, alts: appeared, testimony, offer // needs review
  AwingWord(awing: 'ńnɨd', english: 'show', category: 'actions', difficulty: 1),
  // bible:MAT.10.4, freq=30, conf=0.15, alts: against, good, earth
  AwingWord(awing: 'póʼnə', english: 'war', category: 'nature', difficulty: 3),
  // bible:MAT.12.12, freq=30, conf=0.06, alts: man, according, good // needs review
  AwingWord(awing: 'əwɛ̂nə', english: 'lawful', category: 'descriptive', difficulty: 1),
  // bible:MAT.4.8, freq=29, conf=0.12, alts: show, sins, mountain // needs review
  AwingWord(awing: 'ńnəələ̂', english: 'showed', category: 'actions', difficulty: 1),
  // bible:MAT.5.11, freq=29, conf=0.16, alts: truth, don, false
  AwingWord(awing: 'ntsɨd', english: 'lie', category: 'things', difficulty: 1),
  // bible:MAT.5.22, freq=29, conf=0.15, alts: quiet, don, says
  AwingWord(awing: 'sáʼə', english: 'rebuked', category: 'descriptive', difficulty: 1),
  // bible:MAT.7.2, freq=29, conf=0.07, alts: things, yourself, same // needs review
  AwingWord(awing: 'ghö', english: 'before', category: 'pronouns', difficulty: 1),
  // bible:MAT.13.44, freq=29, conf=0.08, alts: gentiles, blessing, hope // needs review
  AwingWord(awing: 'afoʼ', english: 'riches', category: 'things', difficulty: 1),
  // bible:MAT.19.22, freq=29, conf=0.14, alts: joy, sorrowful, rejoice // needs review
  AwingWord(awing: 'afɨnə', english: 'sorrow', category: 'things', difficulty: 2),
  // bible:MAT.3.11, freq=28, conf=0.10, alts: sandals, worthy, comes // needs review
  AwingWord(awing: 'ngwub', english: 'whose', category: 'things', difficulty: 1),

  // bible:MAT.6.30, freq=28, conf=0.11, alts: don, little, say // needs review
  AwingWord(awing: 'əjɨ', english: 'anxious', category: 'things', difficulty: 2),
  // bible:MAT.8.6, freq=28, conf=0.10, alts: sick, laid, house // needs review
  AwingWord(awing: 'noŋnə̂', english: 'lying', category: 'descriptive', difficulty: 1),
  // bible:MAT.12.36, freq=28, conf=0.10, alts: word, rather, gift // needs review
  AwingWord(awing: 'kətaŋ', english: 'vain', category: 'things', difficulty: 1),
  // bible:MAT.12.39, freq=28, conf=0.13, alts: tradition, many, evil // needs review
  AwingWord(awing: 'myaʼ', english: 'away', category: 'descriptive', difficulty: 1),
  // bible:MAT.13.13, freq=28, conf=0.12, alts: don, seeing, hearing // needs review
  AwingWord(awing: 'ńjwə́ʼtə', english: 'hear', category: 'things', difficulty: 1),
  // bible:MAT.13.44, freq=28, conf=0.09, alts: tomb, stone, faces // needs review
  AwingWord(awing: 'ńkə́bkə', english: 'away', category: 'nature', difficulty: 1),
  // bible:MAT.20.27, freq=28, conf=0.12, alts: bondservant, servant, woman // needs review
  AwingWord(awing: 'apoʼə', english: 'free', category: 'family', difficulty: 1),
  // bible:LUK.14.18, freq=28, conf=0.11, alts: brothers, exhort, please // needs review
  AwingWord(awing: 'póʼmbô', english: 'beg', category: 'things', difficulty: 1),
  // bible:MAT.2.16, freq=27, conf=0.11, alts: man, don, deceive // needs review
  AwingWord(awing: 'fɨgə̂', english: 'astray', category: 'things', difficulty: 1),
  // bible:MAT.5.5, freq=27, conf=0.10, alts: exalted, humble, humbles // needs review
  AwingWord(awing: 'tsóokə', english: 'himself', category: 'descriptive', difficulty: 1),
  // bible:MAT.5.21, freq=27, conf=0.13, alts: old, before, things // needs review
  AwingWord(awing: 'pəchə́', english: 'prophets', category: 'descriptive', difficulty: 3),
  // bible:MAT.5.27, freq=27, conf=0.20, alts: sexual, commit, commits
  AwingWord(awing: 'mə̂ghabə', english: 'adultery', category: 'things', difficulty: 3),
  // bible:MAT.8.24, freq=27, conf=0.13, alts: woman, head, behold // needs review
  AwingWord(awing: 'kə́bkə', english: 'covered', category: 'body', difficulty: 1),
  // bible:MAT.8.30, freq=27, conf=0.12, alts: pigs, prostitute, sexual // needs review
  AwingWord(awing: 'akwɛlə', english: 'herd', category: 'things', difficulty: 1),
  // bible:MAT.9.2, freq=27, conf=0.14, alts: man, sins, house // needs review
  AwingWord(awing: 'məta', english: 'mat', category: 'things', difficulty: 1),
  // bible:MAT.9.36, freq=27, conf=0.17, alts: don, daughter, trouble
  AwingWord(awing: 'ńjwaʼə̂', english: 'troubled', category: 'family', difficulty: 1),
  // bible:MAT.10.17, freq=27, conf=0.15, alts: scourge, third, stripes
  AwingWord(awing: 'ə́shúmə', english: 'beat', category: 'numbers', difficulty: 1),
  // bible:MAT.11.21, freq=27, conf=0.09, alts: changed, long, man // needs review
  AwingWord(awing: 'ńkwúblə', english: 'repented', category: 'things', difficulty: 1),
  // bible:MAT.13.41, freq=27, conf=0.19, alts: things, killed, disciples
  AwingWord(awing: 'apuʼə', english: 'rest', category: 'actions', difficulty: 1),
  // bible:MAT.19.5, freq=27, conf=0.18, alts: joined, man, body
  AwingWord(awing: 'tsɛntə̂', english: 'together', category: 'things', difficulty: 1),
  // bible:MRK.10.37, freq=27, conf=0.08, alts: things, servant, brothers // needs review
  AwingWord(awing: 'əwəg', english: 'many', category: 'family', difficulty: 1),
  // bible:MAT.2.11, freq=26, conf=0.11, alts: heads, brought, city // needs review
  AwingWord(awing: 'əpɔ́b', english: 'many', category: 'actions', difficulty: 1),
  // bible:MAT.2.16, freq=26, conf=0.12, alts: astray, deceived, false // needs review
  AwingWord(awing: 'fɨg', english: 'lead', category: 'things', difficulty: 1),
  // bible:MAT.5.14, freq=26, conf=0.09, alts: good, bind, tents // needs review
  AwingWord(awing: 'kwúd', english: 'bound', category: 'descriptive', difficulty: 1),
  // bible:MAT.5.22, freq=26, conf=0.10, alts: away, empty, nothing // needs review
  AwingWord(awing: 'kətaŋə', english: 'sent', category: 'actions', difficulty: 1),
  // bible:MAT.6.27, freq=26, conf=0.09, alts: together, added, anxious // needs review
  AwingWord(awing: 'ḿbegə̂', english: 'add', category: 'things', difficulty: 1),
  // bible:MAT.13.8, freq=26, conf=0.12, alts: fire, burning, angel // needs review
  AwingWord(awing: 'ńkɛ́lə', english: 'hundred', category: 'nature', difficulty: 1),
  // bible:MAT.14.5, freq=26, conf=0.20, alts: even, many, death
  AwingWord(awing: 'ḿbǎtə', english: 'though', category: 'numbers', difficulty: 1),
  // bible:MAT.2.10, freq=25, conf=0.18, alts: things, afraid, sorry
  AwingWord(awing: 'tətətə', english: 'exceedingly', category: 'descriptive', difficulty: 1),
  // bible:MAT.4.24, freq=25, conf=0.14, alts: fell, man, servants // needs review
  AwingWord(awing: 'ńgwǔ', english: 'invited', category: 'things', difficulty: 1),
  // bible:MAT.6.12, freq=25, conf=0.18, alts: forgive, love, atoning
  AwingWord(awing: 'ńdəgnə̂', english: 'sins', category: 'actions', difficulty: 2),
  // bible:MAT.9.15, freq=25, conf=0.14, alts: mourn, weep, mourning // needs review
  AwingWord(awing: 'fɨnə̂', english: 'sorry', category: 'actions', difficulty: 1),
  // bible:MAT.10.1, freq=25, conf=0.12, alts: himself, cast, lepers // needs review
  AwingWord(awing: 'tsóʼ', english: 'heal', category: 'actions', difficulty: 1),
  // bible:MAT.10.16, freq=25, conf=0.13, alts: masters, bondage, free // needs review
  AwingWord(awing: 'əpoʼ', english: 'servants', category: 'things', difficulty: 2),
  // bible:MAT.12.29, freq=25, conf=0.09, alts: man, first, fell // needs review
  AwingWord(awing: 'ńkwúlə', english: 'house', category: 'numbers', difficulty: 1),
  // bible:MAT.13.2, freq=25, conf=0.11, alts: nothing, much, gathered // needs review
  AwingWord(awing: 'tə́shú', english: 'many', category: 'numbers', difficulty: 1),
  // bible:MAT.24.31, freq=25, conf=0.11, alts: great, twelve, tribes // needs review
  AwingWord(awing: 'məlá', english: 'four', category: 'numbers', difficulty: 1),
  // bible:MRK.3.25, freq=25, conf=0.12, alts: against, divided, end // needs review
  AwingWord(awing: 'məntso', english: 'gates', category: 'things', difficulty: 1),
  // bible:MRK.5.33, freq=25, conf=0.14, alts: trembling, boldness, great // needs review
  AwingWord(awing: 'apɔ́g', english: 'fear', category: 'things', difficulty: 2),
  // bible:MRK.9.22, freq=25, conf=0.11, alts: eyes, holiness, life // needs review
  AwingWord(awing: 'mə́g', english: 'though', category: 'things', difficulty: 1),

  // bible:MAT.1.1, freq=24, conf=0.08, alts: time, things, multitude // needs review
  AwingWord(awing: 'ńchwáakə', english: 'first', category: 'numbers', difficulty: 1),
  // bible:MAT.3.6, freq=24, conf=0.15, alts: cried, before, crying
  AwingWord(awing: 'ńkyéŋə', english: 'weeping', category: 'things', difficulty: 1),
  // bible:MAT.3.10, freq=24, conf=0.11, alts: feet, tree, enemies // needs review
  AwingWord(awing: 'nətɛ́n', english: 'until', category: 'nature', difficulty: 1),
  // bible:MAT.5.11, freq=24, conf=0.16, alts: persecute, before, against
  AwingWord(awing: 'ńtsaŋkə̂', english: 'persecuted', category: 'things', difficulty: 2),
  // bible:MAT.5.18, freq=24, conf=0.14, alts: perish, sheep, man // needs review
  AwingWord(awing: 'péŋ', english: 'lost', category: 'animals', difficulty: 1),
  // bible:MAT.5.25, freq=24, conf=0.13, alts: way, enter, say // needs review
  AwingWord(awing: 'pwɔ́dnə', english: 'easier', category: 'things', difficulty: 1),
  // bible:MAT.6.2, freq=24, conf=0.11, alts: don, most, receive // needs review
  AwingWord(awing: 'ntsɔ́ʼəfaʼ', english: 'reward', category: 'things', difficulty: 2),
  // bible:MAT.8.18, freq=24, conf=0.15, alts: multitudes, great, people
  AwingWord(awing: 'ənɔ', english: 'multitude', category: 'things', difficulty: 1),
  // bible:MAT.9.14, freq=24, conf=0.09, alts: house, says, behold // needs review
  AwingWord(awing: 'pə̂gpə', english: 'disciples', category: 'things', difficulty: 3),
  // bible:MAT.10.31, freq=24, conf=0.16, alts: gold, stones, pearls
  AwingWord(awing: 'səglə̂', english: 'precious', category: 'things', difficulty: 1),
  // bible:MAT.17.5, freq=24, conf=0.08, alts: behold, gold, man // needs review
  AwingWord(awing: 'ŋwaŋkə̂', english: 'bright', category: 'descriptive', difficulty: 1),
  // bible:MAT.19.12, freq=24, conf=0.13, alts: multitude, together, brothers // needs review
  AwingWord(awing: 'pətsɨ́', english: 'didn', category: 'things', difficulty: 1),
  // bible:MRK.5.38, freq=24, conf=0.13, alts: men, uproar, murder // needs review
  AwingWord(awing: 'ajwaʼlə', english: 'city', category: 'things', difficulty: 1),
  // bible:LUK.22.28, freq=24, conf=0.11, alts: sufferings, comfort, afflictions // needs review
  AwingWord(awing: 'məngə́ʼ', english: 'affliction', category: 'things', difficulty: 1),
  // bible:JHN.11.48, freq=24, conf=0.07, alts: love, things, both // needs review
  AwingWord(awing: 'azɛ̂n', english: 'become', category: 'actions', difficulty: 1),
  // bible:MAT.2.12, freq=23, conf=0.13, alts: warned, strictly, way // needs review
  AwingWord(awing: 'ńkwantə̂', english: 'commanded', category: 'things', difficulty: 1),
  // bible:MAT.2.13, freq=23, conf=0.17, alts: things, seek, men
  AwingWord(awing: 'ńchwáalə', english: 'saved', category: 'actions', difficulty: 1),
  // bible:MAT.4.1, freq=23, conf=0.36, alts: angels, time, led
  AwingWord(awing: 'Dɛbəələ', english: 'devil', category: 'things', difficulty: 3),
  // bible:MAT.5.15, freq=23, conf=0.07, alts: things, light, stand // needs review
  AwingWord(awing: 'tə́gə', english: 'lamp', category: 'actions', difficulty: 1),
  // bible:MAT.18.34, freq=23, conf=0.18, alts: release, prisoners, until
  AwingWord(awing: 'ngaŋə́tsáŋ', english: 'prisoner', category: 'things', difficulty: 1),
  // bible:MAT.24.16, freq=23, conf=0.13, alts: flee, mountains, good // needs review
  AwingWord(awing: 'ndə̌', english: 'ran', category: 'actions', difficulty: 1),
  // bible:MAT.1.20, freq=22, conf=0.12, alts: things, servant, don // needs review
  AwingWord(awing: 'kwə̂', english: 'house', category: 'family', difficulty: 1),
  // bible:MAT.5.19, freq=22, conf=0.11, alts: little, enter, great // needs review
  AwingWord(awing: 'kə́nyaŋ', english: 'least', category: 'things', difficulty: 1),
  // bible:MAT.5.25, freq=22, conf=0.11, alts: disciples, man, lest // needs review
  AwingWord(awing: 'ńtégə', english: 'met', category: 'things', difficulty: 1),
  // bible:MAT.8.12, freq=22, conf=0.13, alts: thrown, against, woe // needs review
  AwingWord(awing: 'myaʼə̂', english: 'left', category: 'actions', difficulty: 1),
  // bible:MAT.11.23, freq=22, conf=0.16, alts: humbles, himself, humbled
  AwingWord(awing: 'kɔ́ʼkə', english: 'exalted', category: 'pronouns', difficulty: 1),
  // bible:MAT.13.32, freq=22, conf=0.19, alts: man, its, mount
  AwingWord(awing: 'mətǐ', english: 'vineyard', category: 'things', difficulty: 1),
  // bible:MAT.13.50, freq=22, conf=0.13, alts: sea, fire, off // needs review
  AwingWord(awing: 'ḿmaʼ', english: 'cast', category: 'actions', difficulty: 1),
  // bible:MAT.15.13, freq=22, conf=0.06, alts: things, didn, good // needs review
  AwingWord(awing: 'ázə́ələ́', english: 'answered', category: 'actions', difficulty: 1),
  // bible:MAT.2.16, freq=21, conf=0.10, alts: first, earth, prophets // needs review
  AwingWord(awing: 'ńchúʼ', english: 'beginning', category: 'nature', difficulty: 1),
  // bible:MAT.3.10, freq=21, conf=0.11, alts: even, people, cut // needs review
  AwingWord(awing: 'ńdzá', english: 'often', category: 'things', difficulty: 1),
  // bible:MAT.12.4, freq=21, conf=0.10, alts: entered, sea, after // needs review
  AwingWord(awing: 'ńtwáamə', english: 'house', category: 'actions', difficulty: 1),
  // bible:MAT.17.11, freq=21, conf=0.11, alts: things, first, covenant // needs review
  AwingWord(awing: 'tyáŋtə', english: 'prepared', category: 'numbers', difficulty: 1),
  // bible:MAT.20.16, freq=21, conf=0.12, alts: brothers, death, things // needs review
  AwingWord(awing: 'lwigtə̂', english: 'finally', category: 'descriptive', difficulty: 1),
  // bible:MAT.27.48, freq=21, conf=0.08, alts: vinegar, full, set // needs review
  AwingWord(awing: 'ńkɔ́ʼkə', english: 'sponge', category: 'descriptive', difficulty: 1),
  // bible:ROM.5.8, freq=21, conf=0.08, alts: love, children, hope // needs review
  AwingWord(awing: 'azɛ̂nə', english: 'redemption', category: 'actions', difficulty: 2),
  // bible:MAT.3.12, freq=20, conf=0.14, alts: whole, sacrifices, hand // needs review
  AwingWord(awing: 'tɔ', english: 'fire', category: 'body', difficulty: 1),
  // bible:MAT.6.2, freq=20, conf=0.09, alts: straight, don, men // needs review
  AwingWord(awing: 'əlaŋə́', english: 'streets', category: 'things', difficulty: 1),
  // bible:MAT.8.32, freq=20, conf=0.17, alts: fallen, asleep, fathers
  AwingWord(awing: 'ńkwúkə', english: 'died', category: 'things', difficulty: 3),
  // bible:MAT.9.3, freq=20, conf=0.14, alts: treated, evil, didn // needs review
  AwingWord(awing: 'ńdzɔmtə̂', english: 'blasphemed', category: 'descriptive', difficulty: 1),
  // bible:MAT.9.8, freq=20, conf=0.10, alts: things, great, disciples // needs review
  AwingWord(awing: 'tətə', english: 'even', category: 'things', difficulty: 1),
  // bible:MAT.11.1, freq=20, conf=0.09, alts: good, left, man // needs review
  AwingWord(awing: 'tə́gtə', english: 'set', category: 'descriptive', difficulty: 1),
  // bible:MAT.14.3, freq=20, conf=0.15, alts: man, chains, herodias
  AwingWord(awing: 'ńkwúd', english: 'bound', category: 'things', difficulty: 1),
  // bible:MAT.17.27, freq=20, conf=0.08, alts: day, earth, next // needs review
  AwingWord(awing: 'ə́fóg', english: 'first', category: 'nature', difficulty: 1),
  // bible:MRK.4.11, freq=20, conf=0.18, alts: things, wisdom, good
  AwingWord(awing: 'ajíənu', english: 'knowledge', category: 'descriptive', difficulty: 2),
  // bible:MAT.1.18, freq=19, conf=0.09, alts: watched, eyes, after // needs review
  AwingWord(awing: 'ńtə́g', english: 'before', category: 'things', difficulty: 1),
  // bible:MAT.5.30, freq=19, conf=0.10, alts: stumble, having, off // needs review
  AwingWord(awing: 'ḿmyaʼə̂', english: 'cast', category: 'actions', difficulty: 1),
  // bible:MAT.9.8, freq=19, conf=0.11, alts: men, afraid, feared // needs review
  AwingWord(awing: 'ḿbɔ́g', english: 'devout', category: 'descriptive', difficulty: 1),
  // bible:MAT.9.15, freq=19, conf=0.12, alts: man, fellow, say // needs review
  AwingWord(awing: 'ngaŋəko', english: 'friend', category: 'family', difficulty: 1),
  // bible:MAT.10.34, freq=19, conf=0.14, alts: don, against, fight // needs review
  AwingWord(awing: 'ḿbóʼnə', english: 'war', category: 'actions', difficulty: 3),
  // bible:MAT.18.1, freq=19, conf=0.15, alts: city, greatest, among
  AwingWord(awing: 'gháʼ', english: 'great', category: 'things', difficulty: 1),
  // bible:MAT.24.30, freq=19, conf=0.13, alts: cloud, man, clouds // needs review
  AwingWord(awing: 'alə́mə', english: 'coming', category: 'nature', difficulty: 1),
  // bible:MAT.26.7, freq=19, conf=0.17, alts: sweet, anointed, aroma
  AwingWord(awing: 'azagə́', english: 'ointment', category: 'descriptive', difficulty: 1),
  // bible:MRK.6.18, freq=19, conf=0.11, alts: man, wife, children // needs review
  AwingWord(awing: 'zɔ́ʼə', english: 'marry', category: 'family', difficulty: 1),
  // bible:MRK.12.1, freq=19, conf=0.09, alts: man, wait, country // needs review
  AwingWord(awing: 'pyáb', english: 'own', category: 'actions', difficulty: 1),
  // bible:LUK.17.14, freq=19, conf=0.08, alts: man, before, without // needs review
  AwingWord(awing: 'ŋ́ŋwaʼə̂', english: 'himself', category: 'pronouns', difficulty: 1),
  // bible:MAT.3.7, freq=18, conf=0.10, alts: don, things, warned // needs review
  AwingWord(awing: 'kwantə̂', english: 'commanded', category: 'things', difficulty: 1),
  // bible:MAT.10.32, freq=18, conf=0.12, alts: men, things, bring // needs review
  AwingWord(awing: 'əshîsaŋə', english: 'before', category: 'things', difficulty: 1),
  // bible:MAT.13.30, freq=18, conf=0.14, alts: circumcised, uncircumcision, both // needs review
  AwingWord(awing: 'ḿbóʼə', english: 'circumcision', category: 'things', difficulty: 3),
  // bible:MAT.15.8, freq=18, conf=0.17, alts: long, away, near
  AwingWord(awing: 'sag', english: 'far', category: 'things', difficulty: 1),
  // bible:MAT.23.20, freq=18, conf=0.08, alts: time, thanks, bread // needs review
  AwingWord(awing: 'ázɨ́d', english: 'cup', category: 'food', difficulty: 1),
  // bible:MRK.1.28, freq=18, conf=0.10, alts: abroad, jews, among // needs review
  AwingWord(awing: 'shamnə̂', english: 'scattered', category: 'actions', difficulty: 1),
  // bible:MRK.11.3, freq=18, conf=0.10, alts: say, even, away // needs review
  AwingWord(awing: 'áwə́ələ́', english: 'law', category: 'things', difficulty: 1),
  // bible:MAT.2.20, freq=17, conf=0.12, alts: die, fruit, its // needs review
  AwingWord(awing: 'kwúkə', english: 'dead', category: 'nature', difficulty: 3),
  // bible:MAT.10.38, freq=17, conf=0.06, alts: worthy, looking, away // needs review
  AwingWord(awing: 'twá', english: 'after', category: 'things', difficulty: 1),
  // bible:MAT.11.26, freq=17, conf=0.10, alts: believe, ones, around // needs review
  AwingWord(awing: 'ḿbɔŋ', english: 'better', category: 'actions', difficulty: 1),
  // bible:MAT.11.28, freq=17, conf=0.08, alts: labor, again, woe // needs review
  AwingWord(awing: 'pɨ̈', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:MAT.18.17, freq=17, conf=0.17, alts: don, man, wine
  AwingWord(awing: 'ńkǐəə', english: 'denied', category: 'food', difficulty: 1),
  // bible:MRK.4.36, freq=17, conf=0.12, alts: even, want, earth // needs review
  AwingWord(awing: 'ḿbɛ́dtə', english: 'already', category: 'actions', difficulty: 1),
  // bible:MRK.9.39, freq=17, conf=0.10, alts: don, forbid, own // needs review
  AwingWord(awing: 'zɔŋ', english: 'against', category: 'things', difficulty: 1),
  // bible:LUK.24.39, freq=17, conf=0.16, alts: flesh, blood, death
  AwingWord(awing: 'nkɔ̌ʼmbəəmə', english: 'myself', category: 'pronouns', difficulty: 1),
  // bible:MAT.1.20, freq=16, conf=0.10, alts: days, body, man // needs review
  AwingWord(awing: 'nəpəm', english: 'belly', category: 'descriptive', difficulty: 1),
  // bible:MAT.5.22, freq=16, conf=0.07, alts: man, brother, far // needs review
  AwingWord(awing: 'mbɔʼə', english: 'says', category: 'family', difficulty: 1),
  // bible:MAT.5.25, freq=16, conf=0.12, alts: things, finished, led // needs review
  AwingWord(awing: 'ḿməgtə̂', english: 'after', category: 'things', difficulty: 1),
  // bible:MAT.9.21, freq=16, conf=0.15, alts: touched, garment, many
  AwingWord(awing: 'kwum', english: 'touch', category: 'actions', difficulty: 1),
  // bible:MAT.9.31, freq=16, conf=0.12, alts: spread, day, week // needs review
  AwingWord(awing: 'ńgeebə̂', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:MAT.11.28, freq=16, conf=0.12, alts: man, day, dear // needs review
  AwingWord(awing: 'tə́shúnə́', english: 'own', category: 'things', difficulty: 1),
  // bible:MAT.25.27, freq=16, conf=0.09, alts: back, own, even // needs review
  AwingWord(awing: 'ḿběʼ', english: 'knowing', category: 'body', difficulty: 1),
  // bible:LUK.2.45, freq=16, conf=0.15, alts: man, looking, didn
  AwingWord(awing: 'ə́sɛdnə̂', english: 'turned', category: 'things', difficulty: 1),
  // bible:MAT.3.7, freq=15, conf=0.14, alts: great, place, wrath // needs review
  AwingWord(awing: 'ńnə́ənə', english: 'many', category: 'numbers', difficulty: 1),
  // bible:MAT.5.15, freq=15, conf=0.10, alts: house, lamp, stand // needs review
  AwingWord(awing: 'əkwu', english: 'dead', category: 'actions', difficulty: 3),
  // bible:MAT.9.16, freq=15, conf=0.13, alts: things, about, say // needs review
  AwingWord(awing: 'tsɔ́ʼnə', english: 'understand', category: 'things', difficulty: 1),
  // bible:MAT.9.33, freq=15, conf=0.07, alts: man, time, nor // needs review
  AwingWord(awing: 'láʼə', english: 'nothing', category: 'things', difficulty: 1),
  // bible:MAT.9.37, freq=15, conf=0.09, alts: harvest, ought, sows // needs review
  AwingWord(awing: 'foʼ', english: 'laborers', category: 'things', difficulty: 1),
  // bible:MAT.11.16, freq=15, conf=0.11, alts: children, long, house // needs review
  AwingWord(awing: 'ngaŋmə́ko', english: 'friends', category: 'family', difficulty: 1),
  // bible:MAT.12.11, freq=15, conf=0.12, alts: man, pit, dug // needs review
  AwingWord(awing: 'apɛ́lə', english: 'wine', category: 'food', difficulty: 1),
  // bible:MAT.15.27, freq=15, conf=0.08, alts: filled, pieces, broken // needs review
  AwingWord(awing: 'əpag', english: 'left', category: 'actions', difficulty: 1),
  // bible:MAT.21.10, freq=15, conf=0.11, alts: great, things, earthquake // needs review
  AwingWord(awing: 'chiʼnə̂', english: 'shaken', category: 'things', difficulty: 1),
  // bible:MAT.23.23, freq=15, conf=0.12, alts: things, near, parable // needs review
  AwingWord(awing: 'zéʼ', english: 'learn', category: 'things', difficulty: 1),
  // bible:MAT.25.6, freq=15, conf=0.10, alts: behold, multitude, prison // needs review
  AwingWord(awing: 'ńtéekə', english: 'coming', category: 'things', difficulty: 1),
  // bible:MAT.26.3, freq=15, conf=0.14, alts: praetorium, court, caiaphas // needs review
  AwingWord(awing: 'ntɔ́ʼ', english: 'king', category: 'family', difficulty: 1),
  // bible:MRK.9.2, freq=15, conf=0.12, alts: light, damascus, sky // needs review
  AwingWord(awing: 'ŋ́ŋwaŋkə̂', english: 'around', category: 'nature', difficulty: 1),
  // bible:MRK.14.3, freq=15, conf=0.10, alts: opportunity, woman, commandment // needs review
  AwingWord(awing: 'əsa', english: 'occasion', category: 'things', difficulty: 1),
  // bible:LUK.2.48, freq=15, conf=0.06, alts: things, mother, men // needs review
  AwingWord(awing: 'ńdánə', english: 'behold', category: 'family', difficulty: 2),

  // bible:ACT.15.20, freq=15, conf=0.12, alts: don, good, sexual // needs review
  AwingWord(awing: 'ńkɔ', english: 'away', category: 'descriptive', difficulty: 1),
  // bible:MAT.1.23, freq=14, conf=0.07, alts: brother, death, part // needs review
  AwingWord(awing: 'pɛ̌npo', english: 'fellow', category: 'family', difficulty: 1),
  // bible:MAT.6.20, freq=14, conf=0.09, alts: agrippa, men, way // needs review
  AwingWord(awing: 'tə́m', english: 'king', category: 'family', difficulty: 1),
  // bible:MAT.8.11, freq=14, conf=0.10, alts: light, before, nothing // needs review
  AwingWord(awing: 'kyaʼə̂', english: 'revealed', category: 'descriptive', difficulty: 1),
  // bible:MAT.8.24, freq=14, conf=0.14, alts: much, place, fell // needs review
  AwingWord(awing: 'ńnoŋnə̂', english: 'lying', category: 'things', difficulty: 1),
  // bible:MAT.9.27, freq=14, conf=0.06, alts: mercy, men, cried // needs review
  AwingWord(awing: 'mə́gə́', english: 'blind', category: 'things', difficulty: 1),
  // bible:MAT.13.19, freq=14, conf=0.12, alts: hears, sown, word // needs review
  AwingWord(awing: 'ńgwukə̂', english: 'fell', category: 'actions', difficulty: 1),
  // bible:MAT.13.45, freq=14, conf=0.18, alts: sponge, drink, reed
  AwingWord(awing: 'tsə́g', english: 'vinegar', category: 'actions', difficulty: 1),
  // bible:MAT.15.19, freq=14, conf=0.11, alts: evil, hearts, mind // needs review
  AwingWord(awing: 'əkwaŋ', english: 'thoughts', category: 'descriptive', difficulty: 1),
  // bible:MAT.24.11, freq=14, conf=0.10, alts: false, arise, astray // needs review
  AwingWord(awing: 'məfɨg', english: 'prophets', category: 'things', difficulty: 3),
  // bible:MRK.6.41, freq=14, conf=0.09, alts: each, distributed, loaves // needs review
  AwingWord(awing: 'ńgabtə̂', english: 'broke', category: 'actions', difficulty: 1),
  // bible:LUK.2.44, freq=14, conf=0.13, alts: relatives, day, brothers // needs review
  AwingWord(awing: 'pəshu', english: 'friends', category: 'family', difficulty: 1),
  // bible:LUK.15.8, freq=14, conf=0.07, alts: bold, desire, power // needs review
  AwingWord(awing: 'əzəg', english: 'ourselves', category: 'pronouns', difficulty: 1),
  // bible:MAT.2.9, freq=13, conf=0.14, alts: nothing, set, brothers // needs review
  AwingWord(awing: 'nənyi', english: 'journey', category: 'things', difficulty: 1),
  // bible:MAT.5.44, freq=13, conf=0.14, alts: love, don, enemies // needs review
  AwingWord(awing: 'wə́ənə́', english: 'behold', category: 'actions', difficulty: 2),
  // bible:MAT.6.20, freq=13, conf=0.13, alts: off, followed, distance // needs review
  AwingWord(awing: 'sɛ', english: 'afar', category: 'things', difficulty: 1),
  // bible:MAT.6.26, freq=13, conf=0.13, alts: man, sow, reap // needs review
  AwingWord(awing: 'ə́foʼə̂', english: 'rich', category: 'descriptive', difficulty: 1),
  // bible:MAT.6.31, freq=13, conf=0.14, alts: don, things, eat // needs review
  AwingWord(awing: 'ńjwaʼ', english: 'anxious', category: 'actions', difficulty: 2),
  // bible:MAT.9.13, freq=13, conf=0.14, alts: things, learned, scriptures // needs review
  AwingWord(awing: 'ńdzéʼə', english: 'learn', category: 'things', difficulty: 1),
  // bible:MAT.11.17, freq=13, conf=0.10, alts: high, priest, ear // needs review
  AwingWord(awing: 'ńdə́g', english: 'off', category: 'body', difficulty: 1),
  // bible:MAT.22.46, freq=13, conf=0.10, alts: questions, man, neither // needs review
  AwingWord(awing: 'fiʼə̂', english: 'dared', category: 'things', difficulty: 1),
  // bible:MAT.24.12, freq=13, conf=0.13, alts: don, grow, brothers // needs review
  AwingWord(awing: 'póolə', english: 'weaknesses', category: 'things', difficulty: 1),
  // bible:MRK.10.19, freq=13, conf=0.11, alts: don, man, lie // needs review
  AwingWord(awing: 'tsɨd', english: 'false', category: 'things', difficulty: 1),
  // bible:LUK.1.6, freq=13, conf=0.09, alts: world, among, before // needs review
  AwingWord(awing: 'ngɛdmə́nu', english: 'deeds', category: 'things', difficulty: 1),
  // bible:LUK.2.35, freq=13, conf=0.08, alts: after, gentiles, first // needs review
  AwingWord(awing: 'ə́laŋ', english: 'own', category: 'numbers', difficulty: 1),
  // bible:LUK.7.34, freq=13, conf=0.19, alts: eating, insane, crazy
  AwingWord(awing: 'ḿbɛ́ɛlə', english: 'drunken', category: 'things', difficulty: 1),
  // bible:LUK.9.46, freq=13, conf=0.12, alts: arose, brothers, jews // needs review
  AwingWord(awing: 'azɔŋə', english: 'among', category: 'things', difficulty: 1),
  // bible:LUK.22.16, freq=13, conf=0.09, alts: body, clothed, groan // needs review
  AwingWord(awing: 'pɛ̈n', english: 'toward', category: 'things', difficulty: 1),
  // bible:ACT.1.7, freq=13, conf=0.12, alts: things, right, don // needs review
  AwingWord(awing: 'aliʼə́nuə', english: 'good', category: 'descriptive', difficulty: 1),

  // bible:MAT.5.18, freq=12, conf=0.09, alts: earth, day, pass // needs review
  AwingWord(awing: 'ḿměe', english: 'away', category: 'nature', difficulty: 1),
  // bible:MAT.5.36, freq=12, conf=0.14, alts: answered, word, healed // needs review
  AwingWord(awing: 'kwíʼnə', english: 'disciples', category: 'things', difficulty: 3),
  // bible:MAT.6.28, freq=12, conf=0.09, alts: purple, clothing, field // needs review
  AwingWord(awing: 'ətsəʼə́', english: 'naked', category: 'nature', difficulty: 3),
  // bible:MAT.10.5, freq=12, conf=0.10, alts: good, heart, gentiles // needs review
  AwingWord(awing: 'ńtə́gtə', english: 'among', category: 'descriptive', difficulty: 1),
  // bible:MAT.12.44, freq=12, conf=0.11, alts: return, many, macedonia // needs review
  AwingWord(awing: 'ńtyáŋtə', english: 'prepared', category: 'actions', difficulty: 1),
  // bible:MAT.13.52, freq=12, conf=0.08, alts: man, things, many // needs review
  AwingWord(awing: 'apeʼ', english: 'inheritance', category: 'numbers', difficulty: 1),
  // bible:MAT.19.9, freq=12, conf=0.11, alts: against, adultery, immorality // needs review
  AwingWord(awing: 'ńkéelə', english: 'places', category: 'things', difficulty: 1),
  // bible:MAT.23.23, freq=12, conf=0.09, alts: silence, mercy, law // needs review
  AwingWord(awing: 'naʼ', english: 'answered', category: 'actions', difficulty: 1),
  // bible:MAT.26.23, freq=12, conf=0.08, alts: things, men, good // needs review
  AwingWord(awing: 'azə́g', english: 'hand', category: 'body', difficulty: 1),
  // bible:MAT.26.67, freq=12, conf=0.17, alts: struck, spit, fists
  AwingWord(awing: 'mətwê', english: 'spat', category: 'things', difficulty: 3),
  // bible:MRK.2.7, freq=12, conf=0.12, alts: against, man, insulted // needs review
  AwingWord(awing: 'zɔmtə̂', english: 'blaspheme', category: 'things', difficulty: 1),
  // bible:LUK.2.44, freq=12, conf=0.08, alts: power, about, near // needs review
  AwingWord(awing: 'ńnyi', english: 'journey', category: 'things', difficulty: 1),
  // bible:LUK.12.46, freq=12, conf=0.07, alts: day, days, house // needs review
  AwingWord(awing: 'ńgabkə̂', english: 'hour', category: 'things', difficulty: 1),
  // bible:LUK.14.19, freq=12, conf=0.15, alts: tested, yoke, man
  AwingWord(awing: 'jwə́ʼ', english: 'test', category: 'things', difficulty: 1),
  // bible:JHN.10.1, freq=12, conf=0.12, alts: sheep, didn, house // needs review
  AwingWord(awing: 'məlaʼə́', english: 'war', category: 'animals', difficulty: 3),
  // bible:JHN.10.33, freq=12, conf=0.09, alts: man, good, things // needs review
  AwingWord(awing: 'pə̈g', english: 'work', category: 'actions', difficulty: 1),

  // bible:MAT.1.19, freq=11, conf=0.09, alts: man, scatters, against // needs review
  AwingWord(awing: 'shamkə̂', english: 'gather', category: 'actions', difficulty: 1),
  // bible:MAT.2.3, freq=11, conf=0.12, alts: don, brothers, good // needs review
  AwingWord(awing: 'jwaʼə̂', english: 'troubled', category: 'descriptive', difficulty: 1),
  // bible:MAT.2.6, freq=11, conf=0.11, alts: little, book, boat // needs review
  AwingWord(awing: 'kə́nyaŋə́', english: 'small', category: 'descriptive', difficulty: 1),
  // bible:MAT.5.30, freq=11, conf=0.09, alts: off, causes, stumble // needs review
  AwingWord(awing: 'lə́gə', english: 'cut', category: 'things', difficulty: 1),
  // bible:MAT.9.36, freq=11, conf=0.17, alts: moved, fish, sea
  AwingWord(awing: 'ńkó', english: 'compassion', category: 'animals', difficulty: 2),
  // bible:MAT.20.2, freq=11, conf=0.09, alts: agreed, man, even // needs review
  AwingWord(awing: 'ḿbímnə', english: 'sent', category: 'actions', difficulty: 1),
  // bible:MAT.22.13, freq=11, conf=0.12, alts: weeping, bread, darkness // needs review
  AwingWord(awing: 'kɔ́lə', english: 'teeth', category: 'food', difficulty: 1),
  // bible:MAT.23.13, freq=11, conf=0.08, alts: things, many, right // needs review
  AwingWord(awing: 'kɨ́ʼ', english: 'even', category: 'descriptive', difficulty: 1),
  // bible:MAT.23.23, freq=11, conf=0.10, alts: multitude, hand, pharisees // needs review
  AwingWord(awing: 'naʼə̂', english: 'silent', category: 'body', difficulty: 1),
  // bible:MAT.25.38, freq=11, conf=0.25, alts: clothe, stranger, sick
  AwingWord(awing: 'ntə̌blə', english: 'naked', category: 'descriptive', difficulty: 3),
  // bible:MRK.6.55, freq=11, conf=0.10, alts: began, away, stone // needs review
  AwingWord(awing: 'ńtwá', english: 'around', category: 'nature', difficulty: 1),
  // bible:MRK.12.33, freq=11, conf=0.11, alts: himself, things, offered // needs review
  AwingWord(awing: 'ə́fyaʼə́nu', english: 'once', category: 'pronouns', difficulty: 1),
  // bible:MRK.14.50, freq=11, conf=0.12, alts: hand, doesn, hired // needs review
  AwingWord(awing: 'ńkəələ̂', english: 'fled', category: 'body', difficulty: 1),

  // bible:ROM.2.4, freq=11, conf=0.10, alts: perseverance, repentance, endured // needs review
  AwingWord(awing: 'awaamə́ntɨ́', english: 'patience', category: 'things', difficulty: 2),
  // bible:MAT.3.4, freq=10, conf=0.09, alts: bush, own, waist // needs review
  AwingWord(awing: 'akoobə́', english: 'wild', category: 'things', difficulty: 1),
  // bible:MAT.5.23, freq=10, conf=0.10, alts: bowl, gift, brother // needs review
  AwingWord(awing: 'akáŋə', english: 'poured', category: 'actions', difficulty: 1),
  // bible:MAT.5.39, freq=10, conf=0.06, alts: right, don, turn // needs review
  AwingWord(awing: 'sɛdkə̂', english: 'cheek', category: 'body', difficulty: 1),
  // bible:MAT.8.13, freq=10, conf=0.09, alts: many, hour, well // needs review
  AwingWord(awing: 'ńgyáŋə', english: 'healed', category: 'actions', difficulty: 1),
  // bible:MAT.8.28, freq=10, conf=0.13, alts: coming, people, country // needs review
  AwingWord(awing: 'ńjwánə', english: 'met', category: 'things', difficulty: 1),
  // bible:MAT.9.38, freq=10, conf=0.10, alts: laborers, harvest, field // needs review
  AwingWord(awing: 'afɔ', english: 'send', category: 'actions', difficulty: 1),
  // bible:MAT.12.19, freq=10, conf=0.12, alts: neither, doesn, answered // needs review
  AwingWord(awing: 'kë', english: 'nor', category: 'things', difficulty: 1),
  // bible:MAT.13.12, freq=10, conf=0.09, alts: widows, great, doesn // needs review
  AwingWord(awing: 'chaanə̂', english: 'even', category: 'things', difficulty: 1),
  // bible:MAT.21.31, freq=10, conf=0.15, alts: tax, collectors, even
  AwingWord(awing: 'əkwɛlə', english: 'prostitutes', category: 'things', difficulty: 1),
  // bible:MRK.5.38, freq=10, conf=0.13, alts: weeping, mourned, don // needs review
  AwingWord(awing: 'ə́fɨnə̂', english: 'great', category: 'things', difficulty: 1),
  // bible:MRK.6.31, freq=10, conf=0.15, alts: rest, longer, even
  AwingWord(awing: 'nyáʼ', english: 'little', category: 'things', difficulty: 1),
  // bible:LUK.1.1, freq=10, conf=0.11, alts: send, diligent, concerning // needs review
  AwingWord(awing: 'fǔəlóʼə', english: 'since', category: 'actions', difficulty: 1),
  // bible:LUK.1.67, freq=10, conf=0.09, alts: earth, opened, didn // needs review
  AwingWord(awing: 'tíʼə̈', english: 'great', category: 'nature', difficulty: 1),
  // bible:LUK.1.80, freq=10, conf=0.09, alts: becoming, day, child // needs review
  AwingWord(awing: 'kwéŋ', english: 'growing', category: 'family', difficulty: 1),
  // bible:LUK.2.46, freq=10, conf=0.15, alts: questions, middle, things
  AwingWord(awing: 'əpítə', english: 'about', category: 'things', difficulty: 1),
  // bible:LUK.10.34, freq=10, conf=0.16, alts: stripes, body, wine
  AwingWord(awing: 'məfəŋ', english: 'sores', category: 'food', difficulty: 1),
  // bible:LUK.17.5, freq=10, conf=0.10, alts: days, own, increase // needs review
  AwingWord(awing: 'əzəgə́', english: 'hope', category: 'things', difficulty: 2),

  // bible:MAT.6.19, freq=9, conf=0.09, alts: evil, adulteries, thoughts // needs review
  AwingWord(awing: 'ńdzəələ̂', english: 'steal', category: 'descriptive', difficulty: 1),
  // bible:MAT.10.35, freq=9, conf=0.14, alts: law, struck, something // needs review
  AwingWord(awing: 'kɔn', english: 'boast', category: 'pronouns', difficulty: 1),
  // bible:MAT.12.48, freq=9, conf=0.16, alts: brothers, mother, receive
  AwingWord(awing: 'mbə̂kə̂', english: 'answered', category: 'actions', difficulty: 1),
  // bible:MAT.13.2, freq=9, conf=0.08, alts: great, beach, stood // needs review
  AwingWord(awing: 'nkǎŋkǐə', english: 'multitude', category: 'things', difficulty: 1),
  // bible:MAT.13.5, freq=9, conf=0.11, alts: fell, soil, rocky // needs review
  AwingWord(awing: 'shǐ', english: 'depth', category: 'things', difficulty: 1),
  // bible:MAT.22.7, freq=9, conf=0.08, alts: against, guards, prison // needs review
  AwingWord(awing: 'pəsoye', english: 'king', category: 'family', difficulty: 1),
  // bible:MAT.23.15, freq=9, conf=0.13, alts: sea, brothers, earth // needs review
  AwingWord(awing: 'pəmɛ́', english: 'great', category: 'nature', difficulty: 1),
  // bible:MAT.27.29, freq=9, conf=0.10, alts: mocking, save, priests // needs review
  AwingWord(awing: 'ńnyegnə̂', english: 'mocked', category: 'actions', difficulty: 2),
  // bible:MRK.3.28, freq=9, conf=0.12, alts: speaking, evil, wrath // needs review
  AwingWord(awing: 'ndzɔmnə', english: 'away', category: 'descriptive', difficulty: 1),
  // bible:MRK.9.38, freq=9, conf=0.14, alts: someone, themselves, without // needs review
  AwingWord(awing: 'fiʼ', english: 'measure', category: 'pronouns', difficulty: 1),
  // bible:MRK.10.20, freq=9, conf=0.12, alts: man, child, way // needs review
  AwingWord(awing: 'Mɔ̂nkə̂', english: 'youth', category: 'family', difficulty: 3),
  // bible:MRK.14.69, freq=9, conf=0.14, alts: often, man, time // needs review
  AwingWord(awing: 'ḿbégnə', english: 'again', category: 'things', difficulty: 1),
  // bible:LUK.12.37, freq=9, conf=0.09, alts: didn, day, servants // needs review
  AwingWord(awing: 'lɛ́ɛlə', english: 'servant', category: 'family', difficulty: 1),
  // bible:MAT.5.29, freq=8, conf=0.08, alts: causes, gehenna, cast // needs review
  AwingWord(awing: 'ḿmyaʼ', english: 'away', category: 'things', difficulty: 1),
  // bible:MAT.9.17, freq=8, conf=0.12, alts: unclean, mouth, unholy // needs review
  AwingWord(awing: 'féŋ', english: 'neither', category: 'body', difficulty: 1),
  // bible:MAT.9.27, freq=8, conf=0.11, alts: mercy, followed, passed // needs review
  AwingWord(awing: 'ə́fóŋnə', english: 'cried', category: 'actions', difficulty: 1),
  // bible:MAT.13.32, freq=8, conf=0.11, alts: babies, toward, becomes // needs review
  AwingWord(awing: 'ńkwíŋ', english: 'grown', category: 'actions', difficulty: 1),

  // bible:MAT.21.8, freq=8, conf=0.13, alts: road, branches, trees // needs review
  AwingWord(awing: 'əpóobə́', english: 'spread', category: 'actions', difficulty: 1),
  // bible:MAT.21.9, freq=8, conf=0.08, alts: creatures, honor, sits // needs review
  AwingWord(awing: 'ńdzoobə̂', english: 'living', category: 'things', difficulty: 1),
  // bible:MAT.23.6, freq=8, conf=0.10, alts: best, synagogues, seats // needs review
  AwingWord(awing: 'weŋə́', english: 'feasts', category: 'things', difficulty: 1),
  // bible:MAT.26.8, freq=8, conf=0.14, alts: advanced, well, years // needs review
  AwingWord(awing: 'ndɛnə', english: 'old', category: 'descriptive', difficulty: 1),
  // bible:MAT.26.53, freq=8, conf=0.12, alts: commanding, men, kill // needs review
  AwingWord(awing: 'ngaŋə́maʼə́ntsoolə', english: 'officer', category: 'actions', difficulty: 2),

  // bible:MAT.27.20, freq=8, conf=0.12, alts: persuaded, destroy, priests // needs review
  AwingWord(awing: 'legtə̂', english: 'consolation', category: 'things', difficulty: 1),
  // bible:MAT.27.39, freq=8, conf=0.10, alts: passed, blasphemed, heads // needs review
  AwingWord(awing: 'məndzɔmnə', english: 'wagging', category: 'things', difficulty: 1),
  // bible:MAT.28.7, freq=8, conf=0.14, alts: haste, arose, goes // needs review
  AwingWord(awing: 'ńgə́glə', english: 'quickly', category: 'descriptive', difficulty: 1),
  // bible:MRK.11.3, freq=8, conf=0.14, alts: after, brothers, earth // needs review
  AwingWord(awing: 'ḿbɨnkə̂', english: 'back', category: 'body', difficulty: 1),
  // bible:MRK.11.10, freq=8, conf=0.08, alts: name, man, wall // needs review
  AwingWord(awing: 'ŋáŋnə', english: 'great', category: 'things', difficulty: 1),
  // bible:LUK.1.6, freq=8, conf=0.11, alts: blamelessly, before, body // needs review
  AwingWord(awing: 'fid', english: 'blameless', category: 'things', difficulty: 2),
  // bible:LUK.6.4, freq=8, conf=0.06, alts: brothers, house, lawful // needs review
  AwingWord(awing: 'lə̈', english: 'alone', category: 'things', difficulty: 1),
  // bible:LUK.7.8, freq=8, conf=0.11, alts: man, own, boast // needs review
  AwingWord(awing: 'azá', english: 'servant', category: 'family', difficulty: 1),
  // bible:LUK.20.37, freq=8, conf=0.09, alts: wild, creeping, animals // needs review
  AwingWord(awing: 'akɔb', english: 'bush', category: 'things', difficulty: 1),
  // bible:ACT.15.20, freq=8, conf=0.17, alts: immorality, blood, idols
  AwingWord(awing: 'mbǒʼḿbóʼə́', english: 'sexual', category: 'things', difficulty: 3),
  // bible:ACT.20.19, freq=8, conf=0.12, alts: things, humble, gentleness // needs review
  AwingWord(awing: 'atsóokə́mbəəmə', english: 'humility', category: 'descriptive', difficulty: 2),
  // bible:MAT.4.21, freq=7, conf=0.11, alts: light, own, works // needs review
  AwingWord(awing: 'məmɔ́b', english: 'going', category: 'descriptive', difficulty: 1),
  // bible:MAT.6.26, freq=7, conf=0.10, alts: stone, precious, nor // needs review
  AwingWord(awing: 'ə́səglə̂', english: 'most', category: 'nature', difficulty: 1),
  // bible:MAT.10.10, freq=7, conf=0.10, alts: away, good, things // needs review
  AwingWord(awing: 'zə́g', english: 'sent', category: 'actions', difficulty: 1),
  // bible:MAT.14.2, freq=7, conf=0.08, alts: signs, false, works // needs review
  AwingWord(awing: 'əkɨʼnəmə́nuə', english: 'prophets', category: 'things', difficulty: 3),
  // bible:MAT.18.15, freq=7, conf=0.10, alts: brother, sins, forgive // needs review
  AwingWord(awing: 'afankə́nuə', english: 'against', category: 'family', difficulty: 1),
  // bible:MAT.18.16, freq=7, conf=0.09, alts: men, finger, help // needs review
  AwingWord(awing: 'ńtɔ́mtə', english: 'themselves', category: 'actions', difficulty: 1),
  // bible:MAT.28.17, freq=7, conf=0.06, alts: things, doubted, don // needs review
  AwingWord(awing: 'ńkoʼlə̂', english: 'bowed', category: 'things', difficulty: 1),
  // bible:MRK.14.3, freq=7, conf=0.09, alts: ointment, anointed, blood // needs review
  AwingWord(awing: 'ńkwɛd', english: 'poured', category: 'actions', difficulty: 1),
  // bible:LUK.2.7, freq=7, conf=0.09, alts: inn, calls, lost // needs review
  AwingWord(awing: 'pəghɨ', english: 'room', category: 'things', difficulty: 1),
  // bible:LUK.6.49, freq=7, conf=0.12, alts: boasting, ruin, fell // needs review
  AwingWord(awing: 'ńkɔn', english: 'law', category: 'things', difficulty: 1),
  // bible:LUK.18.34, freq=7, conf=0.05, alts: things, understand, didn // needs review
  AwingWord(awing: 'ŋ́ŋwaʼ', english: 'none', category: 'things', difficulty: 1),
  // bible:ACT.19.13, freq=7, conf=0.10, alts: man, even, temptation // needs review
  AwingWord(awing: 'moomə̂', english: 'die', category: 'things', difficulty: 1),
  // bible:MAT.4.8, freq=6, conf=0.26, alts: mountain, world, high
  AwingWord(awing: 'Dɛbəəl', english: 'devil', category: 'nature', difficulty: 3),
  // bible:MAT.5.15, freq=6, conf=0.12, alts: servant, measuring, shines // needs review
  AwingWord(awing: 'akɔʼə', english: 'house', category: 'family', difficulty: 1),
  // bible:MAT.6.2, freq=6, conf=0.11, alts: don, opportunity, received // needs review
  AwingWord(awing: 'əsêndúmə', english: 'deliver', category: 'things', difficulty: 1),
  // bible:MAT.9.2, freq=6, conf=0.09, alts: man, behold, paralytic // needs review
  AwingWord(awing: 'peʼə̂', english: 'paralyzed', category: 'things', difficulty: 1),
  // bible:MAT.12.14, freq=6, conf=0.09, alts: conspired, counsel, together // needs review
  AwingWord(awing: 'ńtyáŋə', english: 'against', category: 'things', difficulty: 1),
  // bible:MAT.22.7, freq=6, conf=0.07, alts: king, destroyed, city // needs review
  AwingWord(awing: 'pəwɨ́', english: 'sent', category: 'actions', difficulty: 1),
  // bible:MAT.25.32, freq=6, conf=0.10, alts: generosity, news, good // needs review
  AwingWord(awing: 'ghab', english: 'service', category: 'descriptive', difficulty: 1),

  // bible:MAT.27.51, freq=6, conf=0.07, alts: veil, earth, bottom // needs review
  AwingWord(awing: 'nətɛ́nə', english: 'top', category: 'nature', difficulty: 1),
  // bible:MRK.2.21, freq=6, conf=0.12, alts: wisdom, piece, shrinks // needs review
  AwingWord(awing: 'ńtsɔ́ʼnə', english: 'mountains', category: 'things', difficulty: 1),
  // bible:MRK.7.22, freq=6, conf=0.06, alts: covetings, evil, desires // needs review
  AwingWord(awing: 'tsəŋ', english: 'pride', category: 'descriptive', difficulty: 1),
  // bible:MRK.9.30, freq=6, conf=0.12, alts: things, anyone, didn // needs review
  AwingWord(awing: 'ńtóokə', english: 'passed', category: 'pronouns', difficulty: 1),
  // bible:MRK.14.72, freq=6, conf=0.09, alts: before, remember, deny // needs review
  AwingWord(awing: 'wə́ʼtə', english: 'remembered', category: 'actions', difficulty: 1),
  // bible:LUK.6.28, freq=6, conf=0.07, alts: bless, mistreat, none // needs review
  AwingWord(awing: 'tsəm', english: 'curse', category: 'things', difficulty: 3),

  // bible:JHN.10.37, freq=6, conf=0.07, alts: believe, don, teacher // needs review
  AwingWord(awing: 'tə̈', english: 'works', category: 'actions', difficulty: 1),
  // bible:ACT.8.23, freq=6, conf=0.07, alts: poison, bitterness, iniquity // needs review
  AwingWord(awing: 'ə́sɛlə̂', english: 'bondage', category: 'things', difficulty: 3),
  // bible:ACT.15.36, freq=6, conf=0.12, alts: barnabas, doing, after // needs review
  AwingWord(awing: 'ə́léenə́', english: 'much', category: 'things', difficulty: 1),
  // bible:ACT.20.38, freq=6, conf=0.11, alts: sailed, ships, accompanied // needs review
  AwingWord(awing: 'apáŋə́nkǐə', english: 'ship', category: 'things', difficulty: 1),
  // bible:1CO.1.25, freq=6, conf=0.11, alts: strong, stronger, wiser // needs review
  AwingWord(awing: 'pwɔ́dkə', english: 'weakness', category: 'descriptive', difficulty: 1),
  // bible:1CO.5.10, freq=6, conf=0.10, alts: world, empty, chatter // needs review
  AwingWord(awing: 'lə́ʼə', english: 'sexual', category: 'descriptive', difficulty: 3),
  // bible:MAT.5.25, freq=5, conf=0.11, alts: judgment, seat, quickly // needs review
  AwingWord(awing: 'aliʼə́sáʼə́məsáʼə', english: 'anyone', category: 'pronouns', difficulty: 1),
  // bible:MAT.9.6, freq=5, conf=0.12, alts: sins, authority, man // needs review
  AwingWord(awing: 'pətəpɔŋə', english: 'forgive', category: 'things', difficulty: 2),
  // bible:MAT.13.3, freq=5, conf=0.12, alts: sow, behold, parables // needs review
  AwingWord(awing: 'Ndíʼə', english: 'farmer', category: 'things', difficulty: 3),
  // bible:MAT.13.32, freq=5, conf=0.07, alts: herbs, birds, air // needs review
  AwingWord(awing: 'sɛd', english: 'becomes', category: 'things', difficulty: 1),
  // bible:MAT.26.3, freq=5, conf=0.11, alts: together, elders, chief // needs review
  AwingWord(awing: 'pəkəm', english: 'high', category: 'family', difficulty: 1),

  // bible:LUK.6.40, freq=5, conf=0.07, alts: above, fully, trained // needs review
  AwingWord(awing: 'ḿməg', english: 'teacher', category: 'things', difficulty: 1),




  // bible:ACT.17.17, freq=5, conf=0.14, alts: jews, reasoned, entered // needs review
  AwingWord(awing: 'ńkəʼlə̂', english: 'synagogue', category: 'actions', difficulty: 2),


  // bible:ACT.20.16, freq=5, conf=0.11, alts: time, lusts, possible // needs review
  AwingWord(awing: 'laŋkə̂', english: 'past', category: 'things', difficulty: 1),
  // bible:ACT.24.10, freq=5, conf=0.11, alts: judgment, judge, defense // needs review
  AwingWord(awing: 'məsáʼə', english: 'years', category: 'things', difficulty: 1),
  // bible:ACT.25.11, freq=5, conf=0.11, alts: accuse, appeal, death // needs review
  AwingWord(awing: 'chaakə̂', english: 'appealed', category: 'things', difficulty: 1),
  // bible:ACT.25.27, freq=5, conf=0.11, alts: against, delivered, specify // needs review
  AwingWord(awing: 'ngaŋətsáŋə', english: 'prisoner', category: 'things', difficulty: 1),
  // bible:ROM.9.18, freq=5, conf=0.11, alts: mercy, alive, hardens // needs review
  AwingWord(awing: 'atyǎntətûə', english: 'dead', category: 'things', difficulty: 3),
  // bible:ROM.16.19, freq=5, conf=0.15, alts: away, turn, truth
  AwingWord(awing: 'pəpóʼ', english: 'fables', category: 'things', difficulty: 1),
  // bible:1CO.3.12, freq=5, conf=0.18, alts: silver, wood, hay
  AwingWord(awing: 'gôl', english: 'gold', category: 'things', difficulty: 1),
  // bible:1CO.8.1, freq=5, conf=0.10, alts: love, together, fitted // needs review
  AwingWord(awing: 'kwíŋə', english: 'building', category: 'actions', difficulty: 1),
  // bible:1CO.15.19, freq=5, conf=0.07, alts: life, hoped, pitiable // needs review
  AwingWord(awing: 'sɔbnə̂', english: 'most', category: 'things', difficulty: 1),
  // bible:2CO.1.9, freq=5, conf=0.06, alts: sentence, trust, ourselves // needs review
  AwingWord(awing: 'zə́ʼnə', english: 'within', category: 'pronouns', difficulty: 1),
  // bible:GAL.5.23, freq=5, conf=0.15, alts: control, minded, sober
  AwingWord(awing: 'awaamə́mbəəmə', english: 'self', category: 'things', difficulty: 1),
  // bible:EPH.2.14, freq=5, conf=0.07, alts: partition, broke, wall // needs review
  AwingWord(awing: 'kəpa', english: 'both', category: 'things', difficulty: 1),
  // bible:EPH.4.19, freq=5, conf=0.16, alts: control, sober, callous
  AwingWord(awing: 'awaamə́mbɨ', english: 'self', category: 'things', difficulty: 1),
  // bible:PHP.2.3, freq=5, conf=0.11, alts: having, good, conceit // needs review
  AwingWord(awing: 'atsóokə́mbɨ', english: 'humility', category: 'descriptive', difficulty: 2),
  // bible:1TH.1.7, freq=5, conf=0.21, alts: believe, became, macedonia
  AwingWord(awing: 'fiʼnəghɔlə', english: 'example', category: 'actions', difficulty: 1),
  // bible:1TH.2.19, freq=5, conf=0.11, alts: isn, himself, joy // needs review
  AwingWord(awing: 'aŋkəndɔ́ʼə́', english: 'crown', category: 'pronouns', difficulty: 1),
  // bible:MAT.3.12, freq=4, conf=0.10, alts: fire, unquenchable, cleanse // needs review
  AwingWord(awing: 'pə́gnə', english: 'hand', category: 'body', difficulty: 1),
  // bible:MAT.5.11, freq=4, conf=0.18, alts: reproach, evil, sake
  AwingWord(awing: 'ngaŋə́zoŋə́ndzəmə', english: 'disciples', category: 'descriptive', difficulty: 3),
  // bible:MAT.5.13, freq=4, conf=0.17, alts: good, lost, salted
  AwingWord(awing: 'ngwáŋ', english: 'salt', category: 'food', difficulty: 1),
  // bible:MAT.5.37, freq=4, conf=0.06, alts: whatever, rebuked, harm // needs review
  AwingWord(awing: 'yətsɨ́', english: 'evil', category: 'descriptive', difficulty: 3),
  // bible:MAT.5.43, freq=4, conf=0.19, alts: love, yourself, enemy
  AwingWord(awing: 'nəpad', english: 'neighbor', category: 'actions', difficulty: 1),
  // bible:MAT.6.16, freq=4, conf=0.12, alts: fasting, don, hypocrites // needs review
  AwingWord(awing: 'asɔbnə', english: 'sorrowful', category: 'descriptive', difficulty: 1),
  // bible:MAT.6.19, freq=4, conf=0.13, alts: don, yourselves, break // needs review
  AwingWord(awing: 'əsəʼ', english: 'moth', category: 'actions', difficulty: 1),
  // bible:MAT.6.23, freq=4, conf=0.18, alts: evil, darkness, whole
  AwingWord(awing: 'ńgáʼə', english: 'great', category: 'descriptive', difficulty: 1),
  // bible:MAT.6.30, freq=4, conf=0.06, alts: won, grass, field // needs review
  AwingWord(awing: 'Wə̌ə', english: 'tomorrow', category: 'nature', difficulty: 3),
  // bible:MAT.7.3, freq=4, conf=0.12, alts: brother, speck, own // needs review
  AwingWord(awing: 'atítíə', english: 'beam', category: 'family', difficulty: 1),
  // bible:MAT.7.15, freq=4, conf=0.17, alts: among, sheep, behold
  AwingWord(awing: 'əfunə́', english: 'wolves', category: 'animals', difficulty: 1),
  // bible:MAT.8.10, freq=4, conf=0.12, alts: great, followed, even // needs review
  AwingWord(awing: 'apə́ŋə', english: 'haven', category: 'things', difficulty: 1),
  // bible:MAT.8.11, freq=4, conf=0.16, alts: west, sit, many
  AwingWord(awing: 'mɛ́dmə́nu', english: 'east', category: 'actions', difficulty: 1),
  // bible:MAT.8.34, freq=4, conf=0.07, alts: behold, city, begged // needs review
  AwingWord(awing: 'tég', english: 'depart', category: 'things', difficulty: 2),
  // bible:MAT.9.16, freq=4, conf=0.16, alts: away, new, piece
  AwingWord(awing: 'lɛnə̂', english: 'old', category: 'descriptive', difficulty: 1),
  // bible:MAT.9.17, freq=4, conf=0.07, alts: both, new, old // needs review
  AwingWord(awing: 'ḿbə́gə', english: 'wine', category: 'food', difficulty: 1),


  // bible:MAT.10.12, freq=4, conf=0.14, alts: house, household, teacher // needs review
  AwingWord(awing: 'ngǎŋndɛ̂', english: 'master', category: 'family', difficulty: 1),
  // bible:MAT.10.29, freq=4, conf=0.17, alts: sold, aren, afraid
  AwingWord(awing: 'mənchwînə', english: 'sparrows', category: 'actions', difficulty: 1),
  // bible:MAT.12.1, freq=4, conf=0.09, alts: grain, fields, day // needs review
  AwingWord(awing: 'lagtə̂', english: 'pluck', category: 'things', difficulty: 1),
  // bible:MAT.12.30, freq=4, conf=0.07, alts: scatters, against, doesn // needs review
  AwingWord(awing: 'ńnɔd', english: 'gather', category: 'actions', difficulty: 1),
  // bible:MAT.12.46, freq=4, conf=0.11, alts: multitude, great, speaking // needs review
  AwingWord(awing: 'ŋwuməsɔŋ', english: 'multitudes', category: 'things', difficulty: 1),
  // bible:MAT.13.7, freq=4, conf=0.19, alts: fell, grew, choked
  AwingWord(awing: 'məsɔbsoobə', english: 'thorns', category: 'things', difficulty: 1),
  // bible:MAT.13.32, freq=4, conf=0.12, alts: becomes, herbs, birds // needs review
  AwingWord(awing: 'fáŋ', english: 'big', category: 'descriptive', difficulty: 1),
  // bible:MAT.13.34, freq=4, conf=0.15, alts: things, parable, without
  AwingWord(awing: 'ətsábnə́múʼə́', english: 'parables', category: 'things', difficulty: 2),
  // bible:MAT.13.39, freq=4, conf=0.13, alts: allowed, thief, watched // needs review
  AwingWord(awing: 'pə́ʼ', english: 'broken', category: 'actions', difficulty: 1),
  // bible:MAT.14.3, freq=4, conf=0.14, alts: herod, brother, wife // needs review
  AwingWord(awing: 'Ɛlɔdyas', english: 'herodias', category: 'family', difficulty: 3),
  // bible:MAT.14.6, freq=4, conf=0.07, alts: herodias, among, danced // needs review
  AwingWord(awing: 'dína', english: 'birthday', category: 'things', difficulty: 1),
  // bible:MAT.14.9, freq=4, conf=0.12, alts: grieved, sake, oaths // needs review
  AwingWord(awing: 'ńgwaalə̂', english: 'calf', category: 'animals', difficulty: 1),
  // bible:MAT.14.9, freq=4, conf=0.07, alts: sake, oaths, king // needs review
  AwingWord(awing: 'ngaŋnə́ghá', english: 'grieved', category: 'family', difficulty: 3),
  // bible:MAT.14.22, freq=4, conf=0.14, alts: away, boat, side // needs review
  AwingWord(awing: 'kwə́əkə', english: 'sent', category: 'actions', difficulty: 1),
  // bible:MAT.14.30, freq=4, conf=0.12, alts: wind, afraid, save // needs review
  AwingWord(awing: 'mɛ́d', english: 'sink', category: 'actions', difficulty: 1),
  // bible:MAT.14.35, freq=4, conf=0.07, alts: recognized, place, region // needs review
  AwingWord(awing: 'ńdeŋ', english: 'sent', category: 'actions', difficulty: 1),
  // bible:MAT.15.16, freq=4, conf=0.07, alts: burning, dressed, waist // needs review
  AwingWord(awing: 'əpɨ́', english: 'understand', category: 'things', difficulty: 1),
  // bible:MAT.17.25, freq=4, conf=0.19, alts: children, time, receive
  AwingWord(awing: 'pəyǐyinə́', english: 'strangers', category: 'family', difficulty: 1),
  // bible:MAT.18.12, freq=4, conf=0.12, alts: ninety, hundred, gone // needs review
  AwingWord(awing: 'apuʼ', english: 'nine', category: 'numbers', difficulty: 1),
  // bible:MAT.18.34, freq=4, conf=0.06, alts: due, delivered, tormentors // needs review
  AwingWord(awing: 'nkáʼə́tsáŋ', english: 'until', category: 'things', difficulty: 1),
  // bible:MAT.19.18, freq=4, conf=0.11, alts: gentiles, offer, murder // needs review
  AwingWord(awing: 'mənaŋə́', english: 'both', category: 'things', difficulty: 1),
  // bible:MAT.20.3, freq=4, conf=0.10, alts: something, around, throne // needs review
  AwingWord(awing: 'tɨ́mtə', english: 'living', category: 'pronouns', difficulty: 1),
  // bible:MAT.20.13, freq=4, conf=0.12, alts: denarius, agree, doing // needs review
  AwingWord(awing: 'təkoʼ', english: 'present', category: 'things', difficulty: 1),
  // bible:MAT.21.12, freq=4, conf=0.14, alts: doves, money, changers // needs review
  AwingWord(awing: 'əlúʼə', english: 'sold', category: 'actions', difficulty: 1),
  // bible:MAT.21.33, freq=4, conf=0.18, alts: vineyard, fruit, season
  AwingWord(awing: 'ńdzə́ʼkə', english: 'farmers', category: 'nature', difficulty: 1),
  // bible:MAT.21.38, freq=4, conf=0.14, alts: inheritance, themselves, kill // needs review
  AwingWord(awing: 'njîndɛ̂', english: 'heir', category: 'actions', difficulty: 1),
  // bible:MAT.23.5, freq=4, conf=0.06, alts: days, works, enlarge // needs review
  AwingWord(awing: 'pəpɔ́b', english: 'broad', category: 'things', difficulty: 1),
  // bible:MAT.23.13, freq=4, conf=0.12, alts: houses, widows, receive // needs review
  AwingWord(awing: 'məngyaʼə́', english: 'long', category: 'things', difficulty: 1),
  // bible:MAT.23.15, freq=4, conf=0.12, alts: woe, becomes, around // needs review
  AwingWord(awing: 'pəkɔŋ', english: 'sea', category: 'nature', difficulty: 1),
  // bible:MAT.23.23, freq=4, conf=0.07, alts: mercy, justice, left // needs review
  AwingWord(awing: 'ngoʼə́', english: 'woe', category: 'things', difficulty: 1),
  // bible:MAT.24.7, freq=4, conf=0.09, alts: famines, places, against // needs review
  AwingWord(awing: 'ə́sɔb', english: 'rise', category: 'actions', difficulty: 1),
  // bible:MAT.24.10, freq=4, conf=0.12, alts: hate, deliver, stumble // needs review
  AwingWord(awing: 'ə́fi', english: 'many', category: 'actions', difficulty: 1),
  // bible:MAT.24.45, freq=4, conf=0.07, alts: household, servant, due // needs review
  AwingWord(awing: 'náakə', english: 'faithful', category: 'family', difficulty: 2),
  // bible:MAT.25.38, freq=4, conf=0.21, alts: naked, clothe, thirsty
  AwingWord(awing: 'ngɨ', english: 'stranger', category: 'things', difficulty: 1),
  // bible:MAT.26.39, freq=4, conf=0.16, alts: fell, away, possible
  AwingWord(awing: 'ńkwádtə', english: 'little', category: 'things', difficulty: 1),

  // bible:MAT.26.74, freq=4, conf=0.06, alts: man, don, crowed // needs review
  AwingWord(awing: 'ńdzoomə̂', english: 'curse', category: 'things', difficulty: 3),
  // bible:MAT.27.7, freq=4, conf=0.12, alts: potter, strangers, counsel // needs review
  AwingWord(awing: 'atsaʼ', english: 'field', category: 'nature', difficulty: 1),
  // bible:MAT.27.24, freq=4, conf=0.12, alts: nothing, rather, multitude // needs review
  AwingWord(awing: 'ńtíʼə̈', english: 'before', category: 'things', difficulty: 1),
  // bible:MAT.27.34, freq=4, conf=0.11, alts: drink, mixed, myrrh // needs review
  AwingWord(awing: 'ńgwɛd', english: 'wine', category: 'actions', difficulty: 1),

  // bible:MAT.27.60, freq=4, conf=0.14, alts: stone, door, cut // needs review
  AwingWord(awing: 'ńkabkə̂', english: 'rolled', category: 'nature', difficulty: 1),
  // bible:MRK.1.31, freq=4, conf=0.11, alts: fever, left, raised // needs review
  AwingWord(awing: 'ḿbɨgə̂', english: 'hand', category: 'body', difficulty: 1),
  // bible:MRK.3.5, freq=4, conf=0.12, alts: grieved, stretched, restored // needs review
  AwingWord(awing: 'ŋ́ŋwéetə', english: 'jealousy', category: 'things', difficulty: 1),
  // bible:MRK.3.14, freq=4, conf=0.16, alts: twelve, send, appointed
  AwingWord(awing: 'məntúmə', english: 'apostles', category: 'actions', difficulty: 3),
  // bible:MRK.6.17, freq=4, conf=0.15, alts: herod, herself, bound
  AwingWord(awing: 'Ɛlɔdyasə', english: 'herodias', category: 'pronouns', difficulty: 3),
  // bible:MRK.6.22, freq=4, conf=0.11, alts: sound, harpists, lady // needs review
  AwingWord(awing: 'apɛ́n', english: 'whatever', category: 'pronouns', difficulty: 1),
  // bible:MRK.6.33, freq=4, conf=0.18, alts: arrived, together, ran
  AwingWord(awing: 'ńdeŋə̂', english: 'recognized', category: 'actions', difficulty: 1),
  // bible:MRK.6.48, freq=4, conf=0.12, alts: wind, distressed, contrary // needs review
  AwingWord(awing: 'tóokə', english: 'passed', category: 'nature', difficulty: 1),

  // bible:MRK.7.35, freq=4, conf=0.15, alts: immediately, tongue, impediment
  AwingWord(awing: 'kyakə̂', english: 'opened', category: 'actions', difficulty: 1),
  // bible:MRK.7.36, freq=4, conf=0.07, alts: widely, commanded, proclaimed // needs review
  AwingWord(awing: 'lyaʼtə̂', english: 'much', category: 'things', difficulty: 1),
  // bible:MRK.9.27, freq=4, conf=0.12, alts: set, arose, hand // needs review
  AwingWord(awing: 'ńdookə̂', english: 'raised', category: 'body', difficulty: 1),
  // bible:MRK.11.20, freq=4, conf=0.12, alts: fig, away, passed // needs review
  AwingWord(awing: 'júm', english: 'tree', category: 'nature', difficulty: 1),
  // bible:MRK.11.30, freq=4, conf=0.21, alts: answer, men, believe
  AwingWord(awing: 'Akwáalə́nkǐə', english: 'baptism', category: 'actions', difficulty: 3),
  // bible:MRK.12.41, freq=4, conf=0.17, alts: man, money, multitude
  AwingWord(awing: 'Ngǎŋnkáb', english: 'rich', category: 'descriptive', difficulty: 3),
  // bible:MRK.13.10, freq=4, conf=0.06, alts: things, news, first // needs review
  AwingWord(awing: 'ə́shib', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:MRK.14.31, freq=4, conf=0.07, alts: same, thing, die // needs review
  AwingWord(awing: 'ńněe', english: 'deny', category: 'things', difficulty: 1),
  // bible:MRK.14.72, freq=4, conf=0.11, alts: third, sounded, angel // needs review
  AwingWord(awing: 'ńtɔ́ŋ', english: 'second', category: 'numbers', difficulty: 1),
  // bible:MRK.15.24, freq=4, conf=0.17, alts: among, garments, parted
  AwingWord(awing: 'pilə́', english: 'lots', category: 'things', difficulty: 1),

  // bible:LUK.1.24, freq=4, conf=0.06, alts: things, after, months // needs review
  AwingWord(awing: 'ńdyáŋə', english: 'hid', category: 'actions', difficulty: 1),
  // bible:LUK.1.37, freq=4, conf=0.06, alts: nothing, jews, macedonia // needs review
  AwingWord(awing: 'Əsë', english: 'impossible', category: 'things', difficulty: 1),
  // bible:LUK.2.46, freq=4, conf=0.12, alts: both, questions, after // needs review
  AwingWord(awing: 'ətséebə', english: 'words', category: 'things', difficulty: 1),
  // bible:LUK.3.1, freq=4, conf=0.12, alts: man, brother, reign // needs review
  AwingWord(awing: 'aləŋ', english: 'sit', category: 'actions', difficulty: 1),

  // bible:LUK.3.9, freq=4, conf=0.11, alts: even, fruit, tree // needs review
  AwingWord(awing: 'kə́ʼə', english: 'cut', category: 'nature', difficulty: 1),

  // bible:LUK.5.30, freq=4, conf=0.12, alts: drink, tax, sinners // needs review
  AwingWord(awing: 'ŋ́ŋwuntə̂', english: 'murmured', category: 'actions', difficulty: 1),
  // bible:LUK.6.10, freq=4, conf=0.07, alts: man, around, sound // needs review
  AwingWord(awing: 'ə́shǐəə', english: 'restored', category: 'things', difficulty: 1),
  // bible:LUK.7.28, freq=4, conf=0.11, alts: poor, baptizer, least // needs review
  AwingWord(awing: 'mengyě', english: 'widow', category: 'descriptive', difficulty: 1),
  // bible:LUK.7.38, freq=4, conf=0.12, alts: feet, hair, ointment // needs review
  AwingWord(awing: 'ə́shíg', english: 'wiped', category: 'body', difficulty: 1),
  // bible:LUK.9.1, freq=4, conf=0.06, alts: diseases, twelve, power // needs review
  AwingWord(awing: 'pəpɛ̌sê', english: 'authority', category: 'things', difficulty: 1),
  // bible:LUK.9.1, freq=4, conf=0.11, alts: healings, gifts, diseases // needs review
  AwingWord(awing: 'məghoonə́', english: 'authority', category: 'things', difficulty: 1),
  // bible:LUK.11.39, freq=4, conf=0.16, alts: agrippa, cleanse, cup
  AwingWord(awing: 'əsɔ́', english: 'defense', category: 'things', difficulty: 1),
  // bible:LUK.12.55, freq=4, conf=0.11, alts: nor, neither, wind // needs review
  AwingWord(awing: 'tɔnə̂', english: 'heat', category: 'nature', difficulty: 1),
  // bible:LUK.13.29, freq=4, conf=0.11, alts: west, north, south // needs review
  AwingWord(awing: 'məkɔʼnə́', english: 'east', category: 'things', difficulty: 1),
  // bible:LUK.13.34, freq=4, conf=0.12, alts: gathers, children, often // needs review
  AwingWord(awing: 'ńtə́mtə', english: 'stoned', category: 'family', difficulty: 3),
  // bible:LUK.16.16, freq=4, conf=0.11, alts: news, law, prophets // needs review
  AwingWord(awing: 'ə́fyád', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:LUK.16.19, freq=4, conf=0.06, alts: luxury, fine, purple // needs review
  AwingWord(awing: 'ə́wɨ̈', english: 'living', category: 'things', difficulty: 1),
  // bible:LUK.16.25, freq=4, conf=0.12, alts: things, bad, remember // needs review
  AwingWord(awing: 'əpɔŋ', english: 'good', category: 'actions', difficulty: 1),
  // bible:LUK.17.16, freq=4, conf=0.16, alts: giving, bless, fell
  AwingWord(awing: 'ńdáʼkə', english: 'thanks', category: 'things', difficulty: 1),
  // bible:LUK.17.28, freq=4, conf=0.22, alts: drank, planted, even
  AwingWord(awing: 'lɔlə', english: 'lot', category: 'food', difficulty: 1),
  // bible:LUK.17.35, freq=4, conf=0.12, alts: crush, together, grain // needs review
  AwingWord(awing: 'ghɔʼə̂', english: 'stone', category: 'nature', difficulty: 1),
  // bible:LUK.18.2, freq=4, conf=0.11, alts: city, fear, judge // needs review
  AwingWord(awing: 'əsáʼməsáʼ', english: 'certain', category: 'things', difficulty: 1),
  // bible:LUK.19.2, freq=4, conf=0.18, alts: named, tax, man
  AwingWord(awing: 'zakyɔsə', english: 'zacchaeus', category: 'things', difficulty: 1),
  // bible:LUK.20.26, freq=4, conf=0.12, alts: basket, trap, weren // needs review
  AwingWord(awing: 'ńká', english: 'wall', category: 'things', difficulty: 1),
  // bible:LUK.20.26, freq=4, conf=0.12, alts: trap, weren, answer // needs review
  AwingWord(awing: 'awǔənu', english: 'blameless', category: 'actions', difficulty: 2),
  // bible:LUK.21.12, freq=4, conf=0.11, alts: name, priests, chief // needs review
  AwingWord(awing: 'wamtə̂', english: 'authority', category: 'family', difficulty: 1),



  // bible:JHN.2.5, freq=4, conf=0.11, alts: eat, together, mother // needs review
  AwingWord(awing: 'ńtád', english: 'servants', category: 'actions', difficulty: 2),
  // bible:JHN.2.12, freq=4, conf=0.06, alts: days, brothers, capernaum // needs review
  AwingWord(awing: 'əlěmbîə', english: 'few', category: 'numbers', difficulty: 1),
  // bible:JHN.9.6, freq=4, conf=0.15, alts: eyes, man, anointed
  AwingWord(awing: 'ńtwábtə', english: 'mud', category: 'nature', difficulty: 1),
  // bible:JHN.9.6, freq=4, conf=0.15, alts: eyes, man, anointed
  AwingWord(awing: 'atətsáʼ', english: 'mud', category: 'nature', difficulty: 1),
  // bible:JHN.15.4, freq=4, conf=0.10, alts: branch, back, price // needs review
  AwingWord(awing: 'əfagə', english: 'remain', category: 'body', difficulty: 1),
  // bible:JHN.19.34, freq=4, conf=0.12, alts: water, blood, side // needs review
  AwingWord(awing: 'mmaʼntso', english: 'soldier', category: 'nature', difficulty: 1),

  // bible:ACT.2.8, freq=4, conf=0.07, alts: native, own, hear // needs review
  AwingWord(awing: 'əpɛ́nə', english: 'language', category: 'things', difficulty: 1),
  // bible:ACT.2.29, freq=4, conf=0.07, alts: buried, day, died // needs review
  AwingWord(awing: 'ə́fênə̌', english: 'both', category: 'things', difficulty: 1),
  // bible:ACT.2.42, freq=4, conf=0.09, alts: steadfastly, breaking, testimony // needs review
  AwingWord(awing: 'ńnoolə̂', english: 'bread', category: 'food', difficulty: 1),
  // bible:ACT.2.43, freq=4, conf=0.20, alts: wonders, great, fear
  AwingWord(awing: 'əkyeʼmə́nuə', english: 'signs', category: 'things', difficulty: 1),
  // bible:ACT.3.25, freq=4, conf=0.10, alts: promises, fathers, children // needs review
  AwingWord(awing: 'məndaʼnə', english: 'having', category: 'family', difficulty: 1),

  // bible:ACT.7.32, freq=4, conf=0.07, alts: dared, trembled, away // needs review
  AwingWord(awing: 'pɛ́nkə', english: 'fathers', category: 'things', difficulty: 1),



  // bible:ACT.10.36, freq=4, conf=0.10, alts: news, life, water // needs review
  AwingWord(awing: 'wɨ̈d', english: 'good', category: 'nature', difficulty: 1),

  // bible:ACT.12.15, freq=4, conf=0.07, alts: crazy, angel, joy // needs review
  AwingWord(awing: 'fyád', english: 'insisted', category: 'things', difficulty: 1),
  // bible:ACT.13.6, freq=4, conf=0.12, alts: name, paphos, certain // needs review
  AwingWord(awing: 'ngaŋnəkaŋ', english: 'sorcerer', category: 'things', difficulty: 3),
  // bible:ACT.13.19, freq=4, conf=0.15, alts: eyes, wipe, tear
  AwingWord(awing: 'shíg', english: 'away', category: 'things', difficulty: 1),

  // bible:ACT.15.20, freq=4, conf=0.12, alts: sins, write, blood // needs review
  AwingWord(awing: 'fyaʼə́nu', english: 'offered', category: 'actions', difficulty: 1),


  // bible:ACT.20.10, freq=4, conf=0.12, alts: breastplates, fell, life // needs review
  AwingWord(awing: 'ghaŋ', english: 'horses', category: 'things', difficulty: 1),
  // bible:ACT.21.8, freq=4, conf=0.07, alts: next, house, day // needs review
  AwingWord(awing: 'ńkwáatə', english: 'evangelist', category: 'things', difficulty: 1),
  // bible:ACT.22.24, freq=4, conf=0.18, alts: officer, commanding, commanded
  AwingWord(awing: 'pə́lə́gə́', english: 'barracks', category: 'things', difficulty: 1),
  // bible:ACT.27.10, freq=4, conf=0.15, alts: sirs, injury, ship
  AwingWord(awing: 'shaʼkə̂', english: 'loss', category: 'things', difficulty: 1),
  // bible:ROM.1.11, freq=4, conf=0.12, alts: gift, long, end // needs review
  AwingWord(awing: 'titi', english: 'having', category: 'things', difficulty: 1),
  // bible:ROM.1.29, freq=4, conf=0.12, alts: full, envy, habits // needs review
  AwingWord(awing: 'əfóʼńdé', english: 'covetousness', category: 'descriptive', difficulty: 1),
  // bible:ROM.1.31, freq=4, conf=0.11, alts: beast, dragon, breakers // needs review
  AwingWord(awing: 'məyeŋə́', english: 'without', category: 'animals', difficulty: 1),

  // bible:ROM.9.21, freq=4, conf=0.15, alts: honor, dishonor, vessels
  AwingWord(awing: 'atsaʼə́', english: 'clay', category: 'things', difficulty: 1),
  // bible:ROM.9.23, freq=4, conf=0.07, alts: mercy, vessels, prepared // needs review
  AwingWord(awing: 'chwíʼtə', english: 'beforehand', category: 'things', difficulty: 1),
  // bible:ROM.9.31, freq=4, conf=0.12, alts: law, following, righteousness // needs review
  AwingWord(awing: 'fǔ', english: 'after', category: 'things', difficulty: 1),

  // bible:ROM.15.3, freq=4, conf=0.07, alts: even, reproached, please // needs review
  AwingWord(awing: 'ńkë', english: 'fell', category: 'actions', difficulty: 1),
  // bible:1CO.3.7, freq=4, conf=0.11, alts: plants, nor, gives // needs review
  AwingWord(awing: 'fyaʼ', english: 'waters', category: 'things', difficulty: 1),
  // bible:1CO.9.19, freq=4, conf=0.12, alts: myself, bondage, though // needs review
  AwingWord(awing: 'soŋtə̂', english: 'gain', category: 'pronouns', difficulty: 1),
  // bible:1CO.11.1, freq=4, conf=0.18, alts: even, comparing, measuring
  AwingWord(awing: 'fiʼnə̂', english: 'imitators', category: 'things', difficulty: 1),
  // bible:1CO.15.43, freq=4, conf=0.09, alts: power, earthquake, raised // needs review
  AwingWord(awing: 'apɛ̂', english: 'great', category: 'things', difficulty: 1),
  // bible:2CO.1.6, freq=4, conf=0.16, alts: salvation, same, afflicted
  AwingWord(awing: 'səg', english: 'endure', category: 'things', difficulty: 1),
  // bible:2CO.4.8, freq=4, conf=0.07, alts: perplexed, despair, pressed // needs review
  AwingWord(awing: 'məngə́ʼə', english: 'side', category: 'things', difficulty: 1),
  // bible:2CO.8.14, freq=4, conf=0.07, alts: become, equality, time // needs review
  AwingWord(awing: 'məmɨ́', english: 'supplies', category: 'things', difficulty: 1),
  // bible:EPH.2.7, freq=4, conf=0.07, alts: ages, exceeding, show // needs review
  AwingWord(awing: 'ńgáʼ', english: 'toward', category: 'actions', difficulty: 1),
  // bible:EPH.4.10, freq=4, conf=0.17, alts: fervent, day, heat
  AwingWord(awing: 'məpó', english: 'heavens', category: 'things', difficulty: 1),
  // bible:COL.3.5, freq=4, conf=0.11, alts: sexual, earth, desire // needs review
  AwingWord(awing: 'ndɔtíə', english: 'immorality', category: 'nature', difficulty: 3),
  // bible:1TI.2.9, freq=4, conf=0.11, alts: gold, women, expensive // needs review
  AwingWord(awing: 'məshumə́', english: 'pearls', category: 'things', difficulty: 1),
  // bible:1TI.4.7, freq=4, conf=0.17, alts: exercise, toward, old
  AwingWord(awing: 'apɔ́gə́sê', english: 'godliness', category: 'descriptive', difficulty: 1),
  // bible:1TI.4.11, freq=4, conf=0.10, alts: first, again, principles // needs review
  AwingWord(awing: 'məndzeʼkə́', english: 'teach', category: 'actions', difficulty: 1),
  // bible:2TI.2.17, freq=4, conf=0.12, alts: earth, beast, fatal // needs review
  AwingWord(awing: 'nəfəŋ', english: 'wound', category: 'animals', difficulty: 3),
  // bible:HEB.4.5, freq=4, conf=0.15, alts: enter, disobedience, place
  AwingWord(awing: 'nəjwitənə́', english: 'rest', category: 'things', difficulty: 1),
  // bible:HEB.10.3, freq=4, conf=0.21, alts: sins, yearly, reminder
  AwingWord(awing: 'əfyaʼmə́nu', english: 'sacrifices', category: 'things', difficulty: 2),
  // bible:REV.1.8, freq=4, conf=0.12, alts: omega, says, life // needs review
  AwingWord(awing: 'nəlwigtənə́', english: 'alpha', category: 'things', difficulty: 1),
  // bible:REV.1.13, freq=4, conf=0.14, alts: lamp, golden, among // needs review
  AwingWord(awing: 'atə́gə́lam', english: 'stands', category: 'things', difficulty: 1),
  // bible:REV.2.26, freq=4, conf=0.14, alts: languages, peoples, tribes // needs review
  AwingWord(awing: 'ətúmə', english: 'nations', category: 'things', difficulty: 1),
  // bible:REV.4.4, freq=4, conf=0.17, alts: twenty, four, throne
  AwingWord(awing: 'pəlɛ', english: 'crowns', category: 'numbers', difficulty: 2),
  // bible:REV.4.7, freq=4, conf=0.12, alts: eagle, loud, dwell // needs review
  AwingWord(awing: 'ńdzagə̂', english: 'flying', category: 'animals', difficulty: 1),


  // bible:MAT.1.4, freq=3, conf=0.12, alts: salmon, amminadab, became // needs review
  AwingWord(awing: 'lamə', english: 'lamp', category: 'things', difficulty: 1),




  // bible:MAT.1.24, freq=3, conf=0.18, alts: wife, himself, commanded
  AwingWord(awing: 'ńjimnə̂', english: 'sleep', category: 'actions', difficulty: 1),
  // bible:MAT.2.1, freq=3, conf=0.12, alts: men, herod, bethlehem // needs review
  AwingWord(awing: 'ngaŋə́zéʼə', english: 'wise', category: 'descriptive', difficulty: 1),

  // bible:MAT.3.17, freq=3, conf=0.10, alts: beloved, behold, voice // needs review
  AwingWord(awing: 'pyádnə̈', english: 'well', category: 'descriptive', difficulty: 1),
  // bible:MAT.4.19, freq=3, conf=0.07, alts: men, after, nothing // needs review
  AwingWord(awing: 'ngaŋə́kóolə', english: 'fishers', category: 'things', difficulty: 1),
  // bible:MAT.4.24, freq=3, conf=0.07, alts: report, diseases, epileptics // needs review
  AwingWord(awing: 'ńdzáŋnə', english: 'possessed', category: 'things', difficulty: 3),
  // bible:MAT.5.13, freq=3, conf=0.12, alts: nothing, flavor, lost // needs review
  AwingWord(awing: 'nəŋtə̂', english: 'feet', category: 'things', difficulty: 1),
  // bible:MAT.5.29, freq=3, conf=0.09, alts: gehenna, cast, stumble // needs review
  AwingWord(awing: 'fwɔŋə̂', english: 'causes', category: 'things', difficulty: 1),
  // bible:MAT.5.39, freq=3, conf=0.11, alts: don, strikes, right // needs review
  AwingWord(awing: 'nəghág', english: 'cheek', category: 'body', difficulty: 1),
  // bible:MAT.5.39, freq=3, conf=0.07, alts: right, evil, don // needs review
  AwingWord(awing: 'pəŋə̂', english: 'cheek', category: 'body', difficulty: 1),
  // bible:MAT.6.6, freq=3, conf=0.11, alts: door, inner, room // needs review
  AwingWord(awing: 'ńgwuʼnə̂', english: 'shut', category: 'things', difficulty: 1),
  // bible:MAT.6.19, freq=3, conf=0.07, alts: don, rust, steal // needs review
  AwingWord(awing: 'mbə́ʼ', english: 'break', category: 'actions', difficulty: 1),
  // bible:MAT.7.5, freq=3, conf=0.08, alts: brother, beam, first // needs review
  AwingWord(awing: 'atítí', english: 'hypocrite', category: 'family', difficulty: 1),
  // bible:MAT.7.16, freq=3, conf=0.15, alts: figs, gather, grapes
  AwingWord(awing: 'kɨ́kɔb', english: 'thorns', category: 'actions', difficulty: 1),
  // bible:MAT.7.27, freq=3, conf=0.12, alts: fell, great, house // needs review
  AwingWord(awing: 'ə́shaʼkə̂', english: 'fall', category: 'actions', difficulty: 1),

  // bible:MAT.8.17, freq=3, conf=0.12, alts: disease, diseases, bore // needs review
  AwingWord(awing: 'əlɔʼ', english: 'sickness', category: 'things', difficulty: 1),
  // bible:MAT.8.17, freq=3, conf=0.07, alts: bore, fulfilled, isaiah // needs review
  AwingWord(awing: 'əpɛ́n', english: 'diseases', category: 'things', difficulty: 1),
  // bible:MAT.8.20, freq=3, conf=0.08, alts: man, nests, birds // needs review
  AwingWord(awing: 'məngɔ́d', english: 'foxes', category: 'things', difficulty: 1),
  // bible:MAT.8.32, freq=3, conf=0.12, alts: rushed, pigs, sea // needs review
  AwingWord(awing: 'ə́fə́mnə', english: 'herd', category: 'nature', difficulty: 1),
  // bible:MAT.8.33, freq=3, conf=0.07, alts: fed, away, everything // needs review
  AwingWord(awing: 'ńdzə́g', english: 'possessed', category: 'things', difficulty: 3),
  // bible:MAT.9.17, freq=3, conf=0.12, alts: wine, new, old // needs review
  AwingWord(awing: 'məwɨ́', english: 'both', category: 'food', difficulty: 1),
  // bible:MAT.9.17, freq=3, conf=0.06, alts: days, both, new // needs review
  AwingWord(awing: 'kwɛdnə̂', english: 'wine', category: 'food', difficulty: 1),
  // bible:MAT.9.33, freq=3, conf=0.16, alts: man, rebuked, nothing
  AwingWord(awing: 'chípóʼ', english: 'mute', category: 'things', difficulty: 1),

  // bible:MAT.10.16, freq=3, conf=0.12, alts: wolves, behold, send // needs review
  AwingWord(awing: 'mənóolə', english: 'serpents', category: 'actions', difficulty: 1),
  // bible:MAT.11.5, freq=3, conf=0.09, alts: deaf, receive, sight // needs review
  AwingWord(awing: 'əkə̌tû', english: 'hear', category: 'things', difficulty: 1),
  // bible:MAT.11.21, freq=3, conf=0.12, alts: woe, works, ashes // needs review
  AwingWord(awing: 'ńkɔ́g', english: 'long', category: 'nature', difficulty: 1),
  // bible:MAT.11.29, freq=3, conf=0.12, alts: rest, souls, upon // needs review
  AwingWord(awing: 'akəʼlə́', english: 'yoke', category: 'things', difficulty: 1),
  // bible:MAT.11.30, freq=3, conf=0.07, alts: yoke, easy, light // needs review
  AwingWord(awing: 'ńdzaŋkə̂', english: 'burden', category: 'descriptive', difficulty: 1),
  // bible:MAT.12.7, freq=3, conf=0.06, alts: mercy, wouldn, means // needs review
  AwingWord(awing: 'afyaʼə́nuə', english: 'desire', category: 'things', difficulty: 1),
  // bible:MAT.12.7, freq=3, conf=0.12, alts: mercy, desire, wouldn // needs review
  AwingWord(awing: 'mbóʼngaŋ', english: 'righteous', category: 'things', difficulty: 2),
  // bible:MAT.12.19, freq=3, conf=0.12, alts: nor, strive, neither // needs review
  AwingWord(awing: 'fyaʼnə̂', english: 'anyone', category: 'pronouns', difficulty: 1),
  // bible:MAT.12.30, freq=3, conf=0.07, alts: scatters, against, doesn // needs review
  AwingWord(awing: 'kəpeenə́', english: 'gather', category: 'actions', difficulty: 1),
  // bible:MAT.12.40, freq=3, conf=0.07, alts: man, jonah, days // needs review
  AwingWord(awing: 'mətúʼ', english: 'whale', category: 'things', difficulty: 1),

  // bible:MAT.12.42, freq=3, conf=0.14, alts: behold, generation, greater // needs review
  AwingWord(awing: 'alěsáʼə́məsáʼ', english: 'judgment', category: 'things', difficulty: 2),
  // bible:MAT.13.6, freq=3, conf=0.07, alts: away, scorched, sun // needs review
  AwingWord(awing: 'ńtɔ', english: 'risen', category: 'actions', difficulty: 1),
  // bible:MAT.13.6, freq=3, conf=0.12, alts: withered, risen, scorched // needs review
  AwingWord(awing: 'ńjúmə', english: 'away', category: 'things', difficulty: 1),
  // bible:MAT.13.30, freq=3, conf=0.12, alts: reapers, both, darnel // needs review
  AwingWord(awing: 'ngaŋə́pə́ʼə́', english: 'harvest', category: 'things', difficulty: 1),
  // bible:MAT.13.30, freq=3, conf=0.07, alts: darnel, bundles, harvest // needs review
  AwingWord(awing: 'mbə́ʼə', english: 'both', category: 'things', difficulty: 1),
  // bible:MAT.13.50, freq=3, conf=0.07, alts: teeth, furnace, cast // needs review
  AwingWord(awing: 'ə́tíʼ', english: 'gnashing', category: 'things', difficulty: 1),
  // bible:MAT.13.52, freq=3, conf=0.06, alts: don, scribe, treasure // needs review
  AwingWord(awing: 'ngaŋnchîndɛ̂', english: 'new', category: 'descriptive', difficulty: 1),
  // bible:MAT.14.24, freq=3, conf=0.15, alts: boat, waves, sea
  AwingWord(awing: 'ńtóʼnə', english: 'wind', category: 'nature', difficulty: 1),
  // bible:MAT.14.34, freq=3, conf=0.20, alts: land, crossed, shore
  AwingWord(awing: 'Jɛnɛsɛlɛlə', english: 'gennesaret', category: 'actions', difficulty: 3),
  // bible:MAT.15.30, freq=3, conf=0.13, alts: blind, great, healed // needs review
  AwingWord(awing: 'pəkə́neʼə́ntá', english: 'lame', category: 'things', difficulty: 1),
  // bible:MAT.15.30, freq=3, conf=0.15, alts: lame, healed, blind
  AwingWord(awing: 'pəchípóʼ', english: 'mute', category: 'things', difficulty: 1),
  // bible:MAT.16.1, freq=3, conf=0.16, alts: pharisees, man, lawful
  AwingWord(awing: 'ḿmoomə̂', english: 'testing', category: 'things', difficulty: 1),
  // bible:MAT.16.9, freq=3, conf=0.11, alts: thousand, baskets, many // needs review
  AwingWord(awing: 'ńdag', english: 'loaves', category: 'numbers', difficulty: 1),
  // bible:MAT.16.19, freq=3, conf=0.12, alts: bound, keys, released // needs review
  AwingWord(awing: 'kyagə̂', english: 'untying', category: 'things', difficulty: 1),
  // bible:MAT.16.27, freq=3, conf=0.17, alts: everyone, angels, man
  AwingWord(awing: 'ə́zoŋ', english: 'according', category: 'pronouns', difficulty: 1),
  // bible:MAT.17.8, freq=3, conf=0.11, alts: standing, alone, except // needs review
  AwingWord(awing: 'pɨg', english: 'eyes', category: 'actions', difficulty: 1),
  // bible:MAT.19.20, freq=3, conf=0.16, alts: man, youth, things
  AwingWord(awing: 'ngwəshu', english: 'young', category: 'descriptive', difficulty: 1),
  // bible:MAT.20.5, freq=3, conf=0.16, alts: ninth, about, likewise
  AwingWord(awing: 'ndzəŋ', english: 'hour', category: 'things', difficulty: 1),
  // bible:MAT.20.31, freq=3, conf=0.14, alts: mercy, quiet, cried // needs review
  AwingWord(awing: 'pɔ́ʼnə', english: 'rebuked', category: 'descriptive', difficulty: 1),
  // bible:MAT.21.12, freq=3, conf=0.10, alts: tables, changers, overthrew // needs review
  AwingWord(awing: 'pətəpɛlə', english: 'money', category: 'things', difficulty: 1),
  // bible:MAT.21.13, freq=3, conf=0.12, alts: house, written, den // needs review
  AwingWord(awing: 'pəzə̌lə', english: 'robbers', category: 'things', difficulty: 3),
  // bible:MAT.21.16, freq=3, conf=0.11, alts: nursing, woe, child // needs review
  AwingWord(awing: 'ńnɔ́ŋkə', english: 'babies', category: 'family', difficulty: 1),
  // bible:MAT.21.34, freq=3, conf=0.12, alts: fruit, farmers, season // needs review
  AwingWord(awing: 'akyɛ̂mənta', english: 'sent', category: 'actions', difficulty: 1),
  // bible:MAT.22.26, freq=3, conf=0.12, alts: children, left, died // needs review
  AwingWord(awing: 'ḿməgə̂', english: 'third', category: 'family', difficulty: 1),
  // bible:MAT.23.4, freq=3, conf=0.12, alts: shoulders, themselves, borne // needs review
  AwingWord(awing: 'əpeʼ', english: 'burdens', category: 'pronouns', difficulty: 1),
  // bible:MAT.23.4, freq=3, conf=0.12, alts: shoulders, themselves, borne // needs review
  AwingWord(awing: 'lɛd', english: 'help', category: 'actions', difficulty: 1),
  // bible:MAT.23.8, freq=3, conf=0.08, alts: don, rabbi, brothers // needs review
  AwingWord(awing: 'Mə́sa', english: 'teacher', category: 'things', difficulty: 3),
  // bible:MAT.23.13, freq=3, conf=0.08, alts: receive, long, prayers // needs review
  AwingWord(awing: 'ḿbóŋkə', english: 'widows', category: 'things', difficulty: 1),
  // bible:MAT.24.7, freq=3, conf=0.08, alts: famines, places, against // needs review
  AwingWord(awing: 'gháʼə', english: 'rise', category: 'actions', difficulty: 1),
  // bible:MAT.24.18, freq=3, conf=0.12, alts: field, back, cloak // needs review
  AwingWord(awing: 'kód', english: 'return', category: 'actions', difficulty: 1),
  // bible:MAT.24.45, freq=3, conf=0.14, alts: faithful, household, set // needs review
  AwingWord(awing: 'ńgyáŋ', english: 'wise', category: 'descriptive', difficulty: 1),
  // bible:MAT.25.24, freq=3, conf=0.11, alts: scatter, gathering, talent // needs review
  AwingWord(awing: 'ńkyɛ̂', english: 'sow', category: 'things', difficulty: 1),
  // bible:MAT.26.31, freq=3, conf=0.12, alts: scattered, flock, shepherd // needs review
  AwingWord(awing: 'kəəkə̂', english: 'stumble', category: 'things', difficulty: 1),
  // bible:MAT.26.31, freq=3, conf=0.06, alts: flock, shepherd, written // needs review
  AwingWord(awing: 'ə́shamnə̂', english: 'scattered', category: 'actions', difficulty: 1),
  // bible:MAT.26.38, freq=3, conf=0.12, alts: soul, even, sorrowful // needs review
  AwingWord(awing: 'ghɔ́ŋ', english: 'stay', category: 'things', difficulty: 1),
  // bible:MAT.26.47, freq=3, conf=0.12, alts: clubs, priests, chief // needs review
  AwingWord(awing: 'əpə̌ʼtə', english: 'swords', category: 'family', difficulty: 1),
  // bible:MAT.26.51, freq=3, conf=0.12, alts: off, drew, struck // needs review
  AwingWord(awing: 'sɔŋ', english: 'sword', category: 'things', difficulty: 3),
  // bible:MAT.26.60, freq=3, conf=0.12, alts: none, even, last // needs review
  AwingWord(awing: 'məntsɨd', english: 'many', category: 'numbers', difficulty: 1),
  // bible:MAT.26.65, freq=3, conf=0.16, alts: multitude, clothes, need
  AwingWord(awing: 'ə́sɛɛtə̂', english: 'tore', category: 'actions', difficulty: 1),
  // bible:MAT.27.7, freq=3, conf=0.12, alts: strangers, field, counsel // needs review
  AwingWord(awing: 'wɨ̈', english: 'bury', category: 'nature', difficulty: 1),

  // bible:MAT.27.30, freq=3, conf=0.12, alts: spit, spat, head // needs review
  AwingWord(awing: 'twǐ', english: 'struck', category: 'body', difficulty: 1),



  // bible:MAT.27.35, freq=3, conf=0.12, alts: casting, crucified, clothing // needs review
  AwingWord(awing: 'pid', english: 'lots', category: 'things', difficulty: 1),
  // bible:MAT.27.48, freq=3, conf=0.13, alts: vinegar, drink, reed // needs review
  AwingWord(awing: 'kwunchá', english: 'sponge', category: 'actions', difficulty: 1),
  // bible:MAT.27.48, freq=3, conf=0.13, alts: vinegar, drink, reed // needs review
  AwingWord(awing: 'ńchibə̂', english: 'sponge', category: 'actions', difficulty: 1),

  // bible:MAT.28.4, freq=3, conf=0.11, alts: trembling, before, fear // needs review
  AwingWord(awing: 'ḿbénkə', english: 'fell', category: 'actions', difficulty: 1),
  // bible:MRK.1.44, freq=3, conf=0.06, alts: things, offer, say // needs review
  AwingWord(awing: 'afyaʼə́sê', english: 'nothing', category: 'things', difficulty: 1),
  // bible:MRK.2.4, freq=3, conf=0.07, alts: mat, lying, paralytic // needs review
  AwingWord(awing: 'apaʼ', english: 'near', category: 'things', difficulty: 1),
  // bible:MRK.3.18, freq=3, conf=0.09, alts: alphaeus, zealot, bartholomew // needs review
  AwingWord(awing: 'Zilɔlə', english: 'simon', category: 'things', difficulty: 3),

  // bible:MRK.4.4, freq=3, conf=0.07, alts: sowed, devoured, seed // needs review
  AwingWord(awing: 'ḿbyá', english: 'fell', category: 'actions', difficulty: 1),
  // bible:MRK.4.15, freq=3, conf=0.12, alts: comes, takes, sown // needs review
  AwingWord(awing: 'mbǐpúmə', english: 'seed', category: 'nature', difficulty: 1),
  // bible:MRK.4.24, freq=3, conf=0.07, alts: measured, hear, whatever // needs review
  AwingWord(awing: 'pegtə̂', english: 'heed', category: 'pronouns', difficulty: 1),
  // bible:MRK.4.39, freq=3, conf=0.12, alts: waves, wind, great // needs review
  AwingWord(awing: 'tóʼnə', english: 'sea', category: 'nature', difficulty: 1),
  // bible:MRK.6.47, freq=3, conf=0.07, alts: alone, evening, land // needs review
  AwingWord(awing: 'asəg', english: 'boat', category: 'things', difficulty: 1),
  // bible:MRK.6.52, freq=3, conf=0.12, alts: custody, loaves, hadn // needs review
  AwingWord(awing: 'fwɔnə̂', english: 'about', category: 'things', difficulty: 1),
  // bible:MRK.7.32, freq=3, conf=0.07, alts: hand, lay, begged // needs review
  AwingWord(awing: 'kə́káŋ', english: 'impediment', category: 'actions', difficulty: 1),
  // bible:MRK.9.16, freq=3, conf=0.12, alts: asking, scribes, following // needs review
  AwingWord(awing: 'zɔŋə̂', english: 'urged', category: 'things', difficulty: 1),
  // bible:MRK.9.26, freq=3, conf=0.07, alts: crying, became, convulsing // needs review
  AwingWord(awing: 'ngoŋ', english: 'boy', category: 'things', difficulty: 1),
  // bible:MRK.10.50, freq=3, conf=0.12, alts: casting, away, sprang // needs review
  AwingWord(awing: 'wáatə', english: 'cloak', category: 'things', difficulty: 1),
  // bible:MRK.11.4, freq=3, conf=0.16, alts: away, young, untied
  AwingWord(awing: 'ńkyagə̂', english: 'donkey', category: 'animals', difficulty: 1),

  // bible:MRK.11.25, freq=3, conf=0.07, alts: stand, forgive, against // needs review
  AwingWord(awing: 'pəfankə', english: 'whenever', category: 'actions', difficulty: 1),
  // bible:MRK.11.31, freq=3, conf=0.18, alts: believe, say, reasoned
  AwingWord(awing: 'ńtsəmnə̂', english: 'themselves', category: 'actions', difficulty: 1),
  // bible:MRK.12.2, freq=3, conf=0.14, alts: vineyard, share, sent // needs review
  AwingWord(awing: 'kyɛ̂', english: 'fruit', category: 'actions', difficulty: 1),
  // bible:MRK.12.38, freq=3, conf=0.09, alts: long, walk, marketplaces // needs review
  AwingWord(awing: 'pətə́sɛ', english: 'robes', category: 'actions', difficulty: 1),
  // bible:MRK.12.44, freq=3, conf=0.12, alts: live, abundance, gifts // needs review
  AwingWord(awing: 'ŋɔʼtə̂', english: 'poverty', category: 'things', difficulty: 1),
  // bible:MRK.12.44, freq=3, conf=0.14, alts: live, abundance, gifts // needs review
  AwingWord(awing: 'ńkɔdtə̂', english: 'poverty', category: 'things', difficulty: 1),
  // bible:MRK.13.28, freq=3, conf=0.12, alts: summer, parable, its // needs review
  AwingWord(awing: 'məgheemə́', english: 'near', category: 'things', difficulty: 1),
  // bible:MRK.13.29, freq=3, conf=0.07, alts: doors, even, coming // needs review
  AwingWord(awing: 'ntsoolə́poʼə', english: 'near', category: 'things', difficulty: 1),
  // bible:MRK.14.4, freq=3, conf=0.11, alts: living, themselves, ointment // needs review
  AwingWord(awing: 'ńtə́mə́sɛ́', english: 'wasted', category: 'pronouns', difficulty: 1),

  // bible:MRK.14.54, freq=3, conf=0.07, alts: followed, until, distance // needs review
  AwingWord(awing: 'ńdîə', english: 'court', category: 'things', difficulty: 1),
  // bible:MRK.14.65, freq=3, conf=0.12, alts: began, palms, fists // needs review
  AwingWord(awing: 'ńkɔnə̂', english: 'struck', category: 'things', difficulty: 1),

  // bible:MRK.16.17, freq=3, conf=0.17, alts: kinds, new, believe
  AwingWord(awing: 'pəfîə', english: 'languages', category: 'actions', difficulty: 1),

  // bible:LUK.1.2, freq=3, conf=0.07, alts: even, eyewitnesses, word // needs review
  AwingWord(awing: 'ńkád', english: 'servants', category: 'things', difficulty: 2),

  // bible:LUK.1.51, freq=3, conf=0.07, alts: scattered, strength, imagination // needs review
  AwingWord(awing: 'ə́shaʼtə̂', english: 'arm', category: 'body', difficulty: 1),
  // bible:LUK.1.69, freq=3, conf=0.07, alts: raised, horn, house // needs review
  AwingWord(awing: 'lookə̂', english: 'salvation', category: 'things', difficulty: 2),
  // bible:LUK.2.7, freq=3, conf=0.13, alts: trough, cloth, wrapped // needs review
  AwingWord(awing: 'nəkwuʼ', english: 'feeding', category: 'things', difficulty: 1),

  // bible:LUK.4.25, freq=3, conf=0.11, alts: days, half, widows // needs review
  AwingWord(awing: 'akəm', english: 'great', category: 'numbers', difficulty: 1),
  // bible:LUK.4.40, freq=3, conf=0.07, alts: sick, setting, brought // needs review
  AwingWord(awing: 'ḿmɛ́lə', english: 'diseases', category: 'actions', difficulty: 1),
  // bible:LUK.6.1, freq=3, conf=0.12, alts: written, rubbing, fields // needs review
  AwingWord(awing: 'kəblə̂', english: 'grain', category: 'things', difficulty: 1),
  // bible:LUK.6.38, freq=3, conf=0.07, alts: same, running, good // needs review
  AwingWord(awing: 'ńjáʼ', english: 'back', category: 'actions', difficulty: 1),
  // bible:LUK.6.48, freq=3, conf=0.14, alts: broke, man, house // needs review
  AwingWord(awing: 'Awɛ̌nkǐə', english: 'stream', category: 'things', difficulty: 3),

  // bible:LUK.7.45, freq=3, conf=0.16, alts: since, time, ceased
  AwingWord(awing: 'chweg', english: 'kiss', category: 'things', difficulty: 1),
  // bible:LUK.9.30, freq=3, conf=0.07, alts: elijah, talking, men // needs review
  AwingWord(awing: 'ńjáʼə', english: 'behold', category: 'things', difficulty: 2),
  // bible:LUK.10.31, freq=3, conf=0.11, alts: passed, way, chance // needs review
  AwingWord(awing: 'ńdə́ʼ', english: 'side', category: 'things', difficulty: 1),
  // bible:LUK.10.42, freq=3, conf=0.07, alts: away, part, good // needs review
  AwingWord(awing: 'ntəənə', english: 'chosen', category: 'descriptive', difficulty: 1),
  // bible:LUK.11.27, freq=3, conf=0.07, alts: certain, breasts, bore // needs review
  AwingWord(awing: 'ńkwíŋkə', english: 'multitude', category: 'things', difficulty: 1),
  // bible:LUK.12.1, freq=3, conf=0.16, alts: many, multitude, trampled
  AwingWord(awing: 'pətɔsə', english: 'thousands', category: 'numbers', difficulty: 1),

  // bible:LUK.13.21, freq=3, conf=0.17, alts: lump, hid, until
  AwingWord(awing: 'atsɛ̂káŋə', english: 'yeast', category: 'things', difficulty: 1),
  // bible:LUK.15.27, freq=3, conf=0.11, alts: calf, fattened, safe // needs review
  AwingWord(awing: 'waalə̂', english: 'killed', category: 'actions', difficulty: 3),
  // bible:LUK.16.3, freq=3, conf=0.12, alts: cloths, taking, dig // needs review
  AwingWord(awing: 'ńdə́mtə', english: 'linen', category: 'things', difficulty: 1),
  // bible:LUK.16.24, freq=3, conf=0.12, alts: mercy, flame, dip // needs review
  AwingWord(awing: 'alɨ́', english: 'tongue', category: 'body', difficulty: 1),
  // bible:LUK.17.4, freq=3, conf=0.12, alts: day, seven, repent // needs review
  AwingWord(awing: 'awǔənuə', english: 'against', category: 'numbers', difficulty: 1),

  // bible:LUK.21.1, freq=3, conf=0.07, alts: people, rich, gifts // needs review
  AwingWord(awing: 'ḿbɨg', english: 'treasury', category: 'descriptive', difficulty: 1),
  // bible:LUK.21.21, freq=3, conf=0.07, alts: mountains, depart, enter // needs review
  AwingWord(awing: 'ghɔ́ŋə', english: 'therein', category: 'things', difficulty: 1),
  // bible:LUK.23.30, freq=3, conf=0.12, alts: begin, cover, hills // needs review
  AwingWord(awing: 'məmbá', english: 'mountains', category: 'things', difficulty: 1),
  // bible:LUK.23.53, freq=3, conf=0.16, alts: laid, stone, cut
  AwingWord(awing: 'aghəʼ', english: 'tomb', category: 'nature', difficulty: 3),
  // bible:LUK.24.12, freq=3, conf=0.11, alts: finger, wrote, ground // needs review
  AwingWord(awing: 'ńkwúʼnə', english: 'stooped', category: 'body', difficulty: 1),
  // bible:LUK.24.12, freq=3, conf=0.12, alts: wrapped, looking, themselves // needs review
  AwingWord(awing: 'ńdə́m', english: 'around', category: 'pronouns', difficulty: 1),
  // bible:LUK.24.13, freq=3, conf=0.17, alts: named, day, behold
  AwingWord(awing: 'pəmad', english: 'stadia', category: 'things', difficulty: 1),
  // bible:LUK.24.35, freq=3, conf=0.18, alts: recognized, happened, things
  AwingWord(awing: 'ḿbagə̂', english: 'bread', category: 'food', difficulty: 1),
  // bible:JHN.1.5, freq=3, conf=0.12, alts: overcome, darkness, hasn // needs review
  AwingWord(awing: 'pə́gtə', english: 'quench', category: 'things', difficulty: 1),

  // bible:JHN.2.8, freq=3, conf=0.07, alts: ruler, feast, multitude // needs review
  AwingWord(awing: 'ńtóʼ', english: 'draw', category: 'family', difficulty: 1),

  // bible:JHN.4.14, freq=3, conf=0.16, alts: life, become, well
  AwingWord(awing: 'sáʼə́sê', english: 'water', category: 'nature', difficulty: 1),
  // bible:JHN.4.52, freq=3, conf=0.18, alts: fever, left, hour
  AwingWord(awing: 'əzoonə́', english: 'yesterday', category: 'things', difficulty: 1),

  // bible:JHN.5.39, freq=3, conf=0.11, alts: life, sealed, search // needs review
  AwingWord(awing: 'nchîntəənə', english: 'eternal', category: 'things', difficulty: 2),
  // bible:JHN.6.31, freq=3, conf=0.14, alts: fathers, wilderness, written // needs review
  AwingWord(awing: 'mana', english: 'manna', category: 'nature', difficulty: 1),


  // bible:JHN.11.31, freq=3, conf=0.07, alts: jews, followed, house // needs review
  AwingWord(awing: 'ńdegtə̂', english: 'quickly', category: 'things', difficulty: 1),

  // bible:JHN.12.13, freq=3, conf=0.11, alts: seals, its, king // needs review
  AwingWord(awing: 'lə́gtə', english: 'book', category: 'family', difficulty: 1),
  // bible:JHN.13.4, freq=3, conf=0.12, alts: supper, waist, around // needs review
  AwingWord(awing: 'sooko', english: 'outer', category: 'things', difficulty: 1),

  // bible:JHN.18.23, freq=3, conf=0.07, alts: evil, testify, answered // needs review
  AwingWord(awing: 'ńdəbə̂', english: 'well', category: 'descriptive', difficulty: 1),
  // bible:JHN.18.31, freq=3, conf=0.11, alts: forgiving, each, judge // needs review
  AwingWord(awing: 'pəpɨ́', english: 'forgave', category: 'pronouns', difficulty: 1),
  // bible:JHN.18.40, freq=3, conf=0.06, alts: man, again, robber // needs review
  AwingWord(awing: 'túʼ', english: 'shouted', category: 'things', difficulty: 1),
  // bible:JHN.19.31, freq=3, conf=0.12, alts: wouldn, jews, cross // needs review
  AwingWord(awing: 'ḿbə́ʼtə', english: 'legs', category: 'things', difficulty: 1),
  // bible:JHN.19.34, freq=3, conf=0.12, alts: blood, water, spear // needs review
  AwingWord(awing: 'ńkóŋ', english: 'side', category: 'nature', difficulty: 1),


  // bible:ACT.4.3, freq=3, conf=0.12, alts: next, custody, evening // needs review
  AwingWord(awing: 'ə́fwɔnə̂', english: 'until', category: 'things', difficulty: 1),


  // bible:ACT.8.9, freq=3, conf=0.07, alts: certain, man, simon // needs review
  AwingWord(awing: 'məndɛd', english: 'great', category: 'things', difficulty: 1),
  // bible:ACT.8.32, freq=3, conf=0.07, alts: doesn, slaughter, mouth // needs review
  AwingWord(awing: 'ńkóomə', english: 'led', category: 'body', difficulty: 1),
  // bible:ACT.9.22, freq=3, conf=0.07, alts: jews, damascus, strength // needs review
  AwingWord(awing: 'megnə̂', english: 'increased', category: 'things', difficulty: 1),

  // bible:ACT.10.45, freq=3, conf=0.12, alts: gift, gentiles, poured // needs review
  AwingWord(awing: 'ti', english: 'many', category: 'numbers', difficulty: 1),
  // bible:ACT.10.47, freq=3, conf=0.07, alts: people, received, forbid // needs review
  AwingWord(awing: 'ńdzɔŋ', english: 'water', category: 'nature', difficulty: 1),




  // bible:ACT.13.27, freq=3, conf=0.17, alts: reasoned, voices, nor
  AwingWord(awing: 'əlěláʼsê', english: 'sabbath', category: 'things', difficulty: 2),
  // bible:ACT.14.15, freq=3, conf=0.11, alts: things, living, vain // needs review
  AwingWord(awing: 'ənukə́taŋ', english: 'bring', category: 'things', difficulty: 1),
  // bible:ACT.15.14, freq=3, conf=0.12, alts: people, reported, simeon // needs review
  AwingWord(awing: 'pəpí', english: 'first', category: 'numbers', difficulty: 1),



  // bible:ACT.16.22, freq=3, conf=0.12, alts: rods, multitude, magistrates // needs review
  AwingWord(awing: 'ngwanə', english: 'beaten', category: 'things', difficulty: 1),





  // bible:ACT.19.28, freq=3, conf=0.07, alts: ephesians, filled, anger // needs review
  AwingWord(awing: 'lum', english: 'great', category: 'things', difficulty: 1),


  // bible:ACT.20.8, freq=3, conf=0.07, alts: lights, together, many // needs review
  AwingWord(awing: 'ajábtə', english: 'room', category: 'numbers', difficulty: 1),
  // bible:ACT.20.34, freq=3, conf=0.07, alts: light, hands, yourselves // needs review
  AwingWord(awing: 'Ngaŋmə́koolə', english: 'served', category: 'actions', difficulty: 3),
  // bible:ACT.23.14, freq=3, conf=0.12, alts: bound, nothing, curse // needs review
  AwingWord(awing: 'chwíʼnə', english: 'ourselves', category: 'pronouns', difficulty: 1),


  // bible:ACT.26.17, freq=3, conf=0.07, alts: people, gentiles, delivering // needs review
  AwingWord(awing: 'kɨ́ʼtə', english: 'send', category: 'actions', difficulty: 1),
  // bible:ACT.27.31, freq=3, conf=0.12, alts: saved, unless, stay // needs review
  AwingWord(awing: 'ngaŋə́soŋə́', english: 'ship', category: 'actions', difficulty: 1),
  // bible:ACT.27.40, freq=3, conf=0.12, alts: wind, casting, left // needs review
  AwingWord(awing: 'əkəm', english: 'same', category: 'nature', difficulty: 1),

  // bible:ROM.1.14, freq=3, conf=0.13, alts: wise, both, debtor // needs review
  AwingWord(awing: 'əkəkógə́', english: 'foolish', category: 'descriptive', difficulty: 1),
  // bible:ROM.1.24, freq=3, conf=0.12, alts: world, themselves, bodies // needs review
  AwingWord(awing: 'lwaʼ', english: 'lust', category: 'pronouns', difficulty: 3),
  // bible:ROM.2.4, freq=3, conf=0.12, alts: repentance, patience, forbearance // needs review
  AwingWord(awing: 'wágnə', english: 'knowing', category: 'things', difficulty: 1),

  // bible:ROM.5.6, freq=3, conf=0.07, alts: right, time, weak // needs review
  AwingWord(awing: 'ḿbwɔ́dkə', english: 'died', category: 'descriptive', difficulty: 3),

  // bible:ROM.9.31, freq=3, conf=0.12, alts: law, following, righteousness // needs review
  AwingWord(awing: 'alóʼə', english: 'after', category: 'things', difficulty: 1),
  // bible:ROM.9.32, freq=3, conf=0.12, alts: seek, law, didn // needs review
  AwingWord(awing: 'fǔəlóʼ', english: 'works', category: 'things', difficulty: 1),
  // bible:ROM.9.32, freq=3, conf=0.17, alts: seek, law, didn
  AwingWord(awing: 'məfaʼə', english: 'works', category: 'things', difficulty: 1),
  // bible:ROM.11.17, freq=3, conf=0.14, alts: off, root, broken // needs review
  AwingWord(awing: 'fag', english: 'branches', category: 'things', difficulty: 1),

  // bible:1CO.3.6, freq=3, conf=0.07, alts: apollos, planted, increase // needs review
  AwingWord(awing: 'fyaʼə̂', english: 'watered', category: 'things', difficulty: 1),
  // bible:1CO.5.9, freq=3, conf=0.11, alts: sexual, idolaters, letter // needs review
  AwingWord(awing: 'ngaŋə́jîə', english: 'sinners', category: 'things', difficulty: 1),
  // bible:1CO.8.5, freq=3, conf=0.12, alts: genealogies, gods, though // needs review
  AwingWord(awing: 'pəmaʼ', english: 'disputes', category: 'things', difficulty: 1),

  // bible:1CO.13.12, freq=3, conf=0.12, alts: dimly, mirror, even // needs review
  AwingWord(awing: 'akyaʼə́shîə', english: 'glass', category: 'things', difficulty: 1),
  // bible:1CO.14.20, freq=3, conf=0.07, alts: children, don, thoughts // needs review
  AwingWord(awing: 'pətəkaŋə́', english: 'babies', category: 'family', difficulty: 1),
  // bible:2CO.6.7, freq=3, conf=0.07, alts: right, righteousness, hand // needs review
  AwingWord(awing: 'məkɔŋ', english: 'left', category: 'actions', difficulty: 1),
  // bible:2CO.7.1, freq=3, conf=0.07, alts: holiness, defilement, cleanse // needs review
  AwingWord(awing: 'dɔtə̂', english: 'fear', category: 'things', difficulty: 2),

  // bible:2CO.10.10, freq=3, conf=0.07, alts: weighty, presence, say // needs review
  AwingWord(awing: 'ńtsə́gə', english: 'despised', category: 'things', difficulty: 1),
  // bible:2CO.11.33, freq=3, conf=0.07, alts: basket, escaped, hands // needs review
  AwingWord(awing: 'ńdə́ʼə', english: 'wall', category: 'things', difficulty: 1),
  // bible:GAL.2.9, freq=3, conf=0.12, alts: reputed, right, gentiles // needs review
  AwingWord(awing: 'məntɔ́', english: 'pillars', category: 'descriptive', difficulty: 1),
  // bible:GAL.4.5, freq=3, conf=0.12, alts: receive, children, law // needs review
  AwingWord(awing: 'ətûə', english: 'heads', category: 'family', difficulty: 1),
  // bible:GAL.5.15, freq=3, conf=0.07, alts: don, careful, devour // needs review
  AwingWord(awing: 'ńdímkə', english: 'consume', category: 'things', difficulty: 1),
  // bible:EPH.1.22, freq=3, conf=0.12, alts: feet, subjection, things // needs review
  AwingWord(awing: 'mətɛ́n', english: 'head', category: 'body', difficulty: 1),
  // bible:EPH.2.19, freq=3, conf=0.12, alts: citizens, strangers, longer // needs review
  AwingWord(awing: 'pəŋwúd', english: 'masters', category: 'things', difficulty: 2),
  // bible:EPH.4.24, freq=3, conf=0.12, alts: man, holiness, new // needs review
  AwingWord(awing: 'afiʼkə', english: 'example', category: 'descriptive', difficulty: 1),
  // bible:EPH.6.16, freq=3, conf=0.11, alts: earth, thrust, taking // needs review
  AwingWord(awing: 'meg', english: 'sickle', category: 'nature', difficulty: 1),

  // bible:COL.1.26, freq=3, conf=0.12, alts: generations, ages, revealed // needs review
  AwingWord(awing: 'ńdyáŋ', english: 'hidden', category: 'actions', difficulty: 1),
  // bible:COL.3.12, freq=3, conf=0.12, alts: garments, ones, chosen // needs review
  AwingWord(awing: 'ə́wê', english: 'white', category: 'descriptive', difficulty: 1),

  // bible:2TH.1.4, freq=3, conf=0.12, alts: boast, afflictions, endure // needs review
  AwingWord(awing: 'atsaŋkə', english: 'persecutions', category: 'things', difficulty: 2),
  // bible:2TH.3.6, freq=3, conf=0.07, alts: withdraw, brother, command // needs review
  AwingWord(awing: 'pəlɔŋ', english: 'walks', category: 'family', difficulty: 1),
  // bible:1TI.5.4, freq=3, conf=0.07, alts: children, grandchildren, widow // needs review
  AwingWord(awing: 'məngwud', english: 'sight', category: 'family', difficulty: 1),
  // bible:2TI.2.22, freq=3, conf=0.12, alts: pursue, righteousness, youthful // needs review
  AwingWord(awing: 'alublə', english: 'lusts', category: 'things', difficulty: 1),
  // bible:HEB.11.4, freq=3, conf=0.11, alts: cain, abel, righteous // needs review
  AwingWord(awing: 'Abɛɛlə', english: 'speaks', category: 'things', difficulty: 3),

  // bible:HEB.12.15, freq=3, conf=0.12, alts: bitter, looking, bitterness // needs review
  AwingWord(awing: 'lwǐ', english: 'many', category: 'descriptive', difficulty: 1),
  // bible:HEB.12.18, freq=3, conf=0.11, alts: opened, seal, mountain // needs review
  AwingWord(awing: 'shíshí', english: 'black', category: 'nature', difficulty: 1),
  // bible:2PE.2.14, freq=3, conf=0.07, alts: greed, cursing, children // needs review
  AwingWord(awing: 'anǔəndzɔ́ʼə́', english: 'cease', category: 'family', difficulty: 1),
  // bible:2PE.3.12, freq=3, conf=0.11, alts: seven, looking, cause // needs review
  AwingWord(awing: 'pəsáŋ', english: 'stars', category: 'numbers', difficulty: 1),

  // bible:REV.4.5, freq=3, conf=0.12, alts: thunders, lightnings, fire // needs review
  AwingWord(awing: 'ə́sáʼkə', english: 'sounds', category: 'nature', difficulty: 1),
  // bible:REV.6.5, freq=3, conf=0.12, alts: black, balance, third // needs review
  AwingWord(awing: 'kilo', english: 'living', category: 'descriptive', difficulty: 1),
  // bible:REV.8.2, freq=3, conf=0.11, alts: seven, trumpets, sound // needs review
  AwingWord(awing: 'məpaŋ', english: 'angels', category: 'numbers', difficulty: 1),
  // bible:REV.8.7, freq=3, conf=0.15, alts: followed, great, green
  AwingWord(awing: 'məwəŋ', english: 'hail', category: 'descriptive', difficulty: 1),
  // bible:REV.9.17, freq=3, conf=0.14, alts: fire, mouths, smoke // needs review
  AwingWord(awing: 'amúʼ', english: 'sulfur', category: 'nature', difficulty: 1),
  // bible:REV.12.3, freq=3, conf=0.12, alts: great, old, devil // needs review
  AwingWord(awing: 'dəlagɔn', english: 'dragon', category: 'descriptive', difficulty: 1),
  // bible:REV.13.14, freq=3, conf=0.15, alts: beast, worship, granted
  AwingWord(awing: 'mɔ́pəkɔ́', english: 'image', category: 'animals', difficulty: 1),
  // bible:REV.14.2, freq=3, conf=0.11, alts: harps, harpists, waters // needs review
  AwingWord(awing: 'məloŋ', english: 'sound', category: 'things', difficulty: 1),
  // bible:REV.21.11, freq=3, conf=0.15, alts: precious, wall, city
  AwingWord(awing: 'jaspa', english: 'jasper', category: 'things', difficulty: 1),












  // bible:MAT.2.8, freq=2, conf=0.12, alts: bethlehem, search, child // needs review
  AwingWord(awing: 'Bɛtəlɛɛm', english: 'sent', category: 'actions', difficulty: 3),
  // bible:MAT.2.11, freq=2, conf=0.12, alts: fell, gifts, worshiped // needs review
  AwingWord(awing: 'flaŋkisɛnə', english: 'frankincense', category: 'things', difficulty: 1),
  // bible:MAT.2.11, freq=2, conf=0.12, alts: fell, gifts, frankincense // needs review
  AwingWord(awing: 'mɛ̂lə', english: 'myrrh', category: 'things', difficulty: 1),
  // bible:MAT.2.15, freq=2, conf=0.20, alts: until, death, herod
  AwingWord(awing: 'chɨ́mkə', english: 'fulfilled', category: 'things', difficulty: 1),
  // bible:MAT.3.4, freq=2, conf=0.08, alts: belt, around, locusts // needs review
  AwingWord(awing: 'atwéŋ', english: 'waist', category: 'things', difficulty: 1),
  // bible:MAT.3.12, freq=2, conf=0.07, alts: burn, floor, chaff // needs review
  AwingWord(awing: 'məkwú', english: 'cleanse', category: 'things', difficulty: 1),
  // bible:MAT.3.12, freq=2, conf=0.07, alts: burn, floor, chaff // needs review
  AwingWord(awing: 'ə́tsɛntə̂', english: 'cleanse', category: 'things', difficulty: 1),
  // bible:MAT.4.2, freq=2, conf=0.07, alts: afterward, hungry, days // needs review
  AwingWord(awing: 'pənətúʼ', english: 'forty', category: 'numbers', difficulty: 1),
  // bible:MAT.4.8, freq=2, conf=0.07, alts: devil, world, high // needs review
  AwingWord(awing: 'ŋ́ŋáŋnə', english: 'mountain', category: 'nature', difficulty: 1),
  // bible:MAT.4.18, freq=2, conf=0.07, alts: brother, net, walking // needs review
  AwingWord(awing: 'ńtéemə', english: 'casting', category: 'family', difficulty: 1),
  // bible:MAT.5.26, freq=2, conf=0.07, alts: last, until, certainly // needs review
  AwingWord(awing: 'ndzǒ', english: 'means', category: 'things', difficulty: 1),
  // bible:MAT.5.26, freq=2, conf=0.17, alts: last, until, penny
  AwingWord(awing: 'puʼkə̂', english: 'means', category: 'things', difficulty: 1),
  // bible:MAT.5.28, freq=2, conf=0.07, alts: lust, already, after // needs review
  AwingWord(awing: 'ńděe', english: 'gazes', category: 'things', difficulty: 1),
  // bible:MAT.5.31, freq=2, conf=0.20, alts: away, writing, whoever
  AwingWord(awing: 'ashamkə́ndzɔ́ʼə́', english: 'divorce', category: 'pronouns', difficulty: 1),
  // bible:MAT.5.39, freq=2, conf=0.12, alts: don, strikes, right // needs review
  AwingWord(awing: 'ləb', english: 'cheek', category: 'body', difficulty: 1),
  // bible:MAT.5.41, freq=2, conf=0.10, alts: whoever, mile, fathoms // needs review
  AwingWord(awing: 'məntag', english: 'compels', category: 'pronouns', difficulty: 1),
  // bible:MAT.6.14, freq=2, conf=0.18, alts: trespasses, men, heavenly
  AwingWord(awing: 'pəpə́ənə́', english: 'forgive', category: 'things', difficulty: 2),
  // bible:MAT.6.26, freq=2, conf=0.10, alts: don, sow, much // needs review
  AwingWord(awing: 'əpü', english: 'feeds', category: 'things', difficulty: 1),
  // bible:MAT.6.26, freq=2, conf=0.12, alts: nor, feeds, don // needs review
  AwingWord(awing: 'mənkye', english: 'barns', category: 'things', difficulty: 1),
  // bible:MAT.7.6, freq=2, conf=0.12, alts: dogs, trample, pearls // needs review
  AwingWord(awing: 'pəkwúneemə', english: 'pigs', category: 'things', difficulty: 1),
  // bible:MAT.7.16, freq=2, conf=0.11, alts: thorns, gather, grapes // needs review
  AwingWord(awing: 'ńdagə̂', english: 'figs', category: 'actions', difficulty: 1),
  // bible:MAT.7.16, freq=2, conf=0.11, alts: thorns, gather, grapes // needs review
  AwingWord(awing: 'lámə́sə', english: 'figs', category: 'actions', difficulty: 1),
  // bible:MAT.7.19, freq=2, conf=0.12, alts: cut, doesn, good // needs review
  AwingWord(awing: 'nəkyɛlə́', english: 'fire', category: 'nature', difficulty: 1),
  // bible:MAT.8.11, freq=2, conf=0.07, alts: east, many, west // needs review
  AwingWord(awing: 'ə́lɔg', english: 'sit', category: 'actions', difficulty: 1),
  // bible:MAT.8.20, freq=2, conf=0.12, alts: sky, foxes, man // needs review
  AwingWord(awing: 'zag', english: 'birds', category: 'nature', difficulty: 1),
  // bible:MAT.8.25, freq=2, conf=0.15, alts: save, woke, wind
  AwingWord(awing: 'ńjimkə̂', english: 'dying', category: 'actions', difficulty: 3),
  // bible:MAT.9.16, freq=2, conf=0.07, alts: old, unshrunk, hole // needs review
  AwingWord(awing: 'sɛɛnə̂', english: 'piece', category: 'descriptive', difficulty: 1),
  // bible:MAT.9.17, freq=2, conf=0.11, alts: both, new, preserved // needs review
  AwingWord(awing: 'kâʼlə̌', english: 'wine', category: 'food', difficulty: 1),
  // bible:MAT.9.17, freq=2, conf=0.11, alts: both, new, preserved // needs review
  AwingWord(awing: 'sánə', english: 'wine', category: 'food', difficulty: 1),
  // bible:MAT.10.23, freq=2, conf=0.12, alts: next, man, persecute // needs review
  AwingWord(awing: 'jitə̂', english: 'until', category: 'things', difficulty: 1),
  // bible:MAT.11.19, freq=2, conf=0.12, alts: gluttonous, children, say // needs review
  AwingWord(awing: 'apɛ̌ləmə́loʼə', english: 'drunkard', category: 'family', difficulty: 3),

  // bible:MAT.11.21, freq=2, conf=0.08, alts: works, ashes, repented // needs review
  AwingWord(awing: 'ə́fuʼə̂', english: 'woe', category: 'nature', difficulty: 1),

  // bible:MAT.12.1, freq=2, conf=0.12, alts: pluck, fields, day // needs review
  AwingWord(awing: 'məmbəm', english: 'grain', category: 'things', difficulty: 1),
  // bible:MAT.12.11, freq=2, conf=0.07, alts: man, sabbath, day // needs review
  AwingWord(awing: 'apɛ́d', english: 'won', category: 'things', difficulty: 1),
  // bible:MAT.12.24, freq=2, conf=0.17, alts: beelzebul, prince, man
  AwingWord(awing: 'Bɛlzebɔb', english: 'cast', category: 'actions', difficulty: 3),
  // bible:MAT.12.41, freq=2, conf=0.12, alts: repented, behold, someone // needs review
  AwingWord(awing: 'alěsáʼə́məsáʼə', english: 'judgment', category: 'pronouns', difficulty: 2),
  // bible:MAT.12.42, freq=2, conf=0.07, alts: behold, earth, judgment // needs review
  AwingWord(awing: 'Mɛ̂fo', english: 'rise', category: 'actions', difficulty: 3),

  // bible:MAT.13.4, freq=2, conf=0.10, alts: sowed, devoured, birds // needs review
  AwingWord(awing: 'pitsə́', english: 'fell', category: 'actions', difficulty: 1),
  // bible:MAT.13.22, freq=2, conf=0.12, alts: becomes, sown, deceitfulness // needs review
  AwingWord(awing: 'fumkə̂', english: 'among', category: 'things', difficulty: 1),
  // bible:MAT.13.25, freq=2, conf=0.11, alts: away, weeds, slept // needs review
  AwingWord(awing: 'ngɔ́nə', english: 'darnel', category: 'actions', difficulty: 1),
  // bible:MAT.13.30, freq=2, conf=0.12, alts: both, darnel, bundles // needs review
  AwingWord(awing: 'pə́ʼə', english: 'harvest', category: 'things', difficulty: 1),
  // bible:MAT.13.48, freq=2, conf=0.07, alts: away, good, filled // needs review
  AwingWord(awing: 'ngaŋə́kóolə́shû', english: 'bad', category: 'descriptive', difficulty: 1),
  // bible:MAT.13.55, freq=2, conf=0.09, alts: carpenter, simon, isn // needs review
  AwingWord(awing: 'nkɔ̂pú', english: 'joses', category: 'things', difficulty: 1),
  // bible:MAT.13.57, freq=2, conf=0.07, alts: house, except, offended // needs review
  AwingWord(awing: 'záŋnə', english: 'honor', category: 'things', difficulty: 2),
  // bible:MAT.14.12, freq=2, conf=0.20, alts: body, disciples, devout
  AwingWord(awing: 'ńtwə́ŋ', english: 'buried', category: 'things', difficulty: 1),
  // bible:MAT.14.26, freq=2, conf=0.17, alts: walking, sea, cried
  AwingWord(awing: 'nkwûsê', english: 'ghost', category: 'nature', difficulty: 1),
  // bible:MAT.14.31, freq=2, conf=0.13, alts: hand, hold, little // needs review
  AwingWord(awing: 'ńnɛdkə̂', english: 'stretched', category: 'actions', difficulty: 1),


  // bible:MAT.18.6, freq=2, conf=0.08, alts: ones, around, neck // needs review
  AwingWord(awing: 'aghɔʼə́péenə', english: 'believe', category: 'actions', difficulty: 1),
  // bible:MAT.18.23, freq=2, conf=0.07, alts: certain, king, wanted // needs review
  AwingWord(awing: 'shitə̂', english: 'servants', category: 'family', difficulty: 2),
  // bible:MAT.18.32, freq=2, conf=0.07, alts: forgave, begged, debt // needs review
  AwingWord(awing: 'nətsəm', english: 'servant', category: 'family', difficulty: 1),
  // bible:MAT.20.8, freq=2, conf=0.11, alts: laborers, evening, last // needs review
  AwingWord(awing: 'mənkáb', english: 'wages', category: 'things', difficulty: 2),
  // bible:MAT.20.12, freq=2, conf=0.07, alts: spent, last, borne // needs review
  AwingWord(awing: 'ḿbeʼə̂', english: 'equal', category: 'things', difficulty: 1),
  // bible:MAT.20.27, freq=2, conf=0.18, alts: among, first, whoever
  AwingWord(awing: 'nkwâmbi', english: 'bondservant', category: 'numbers', difficulty: 1),
  // bible:MAT.21.19, freq=2, conf=0.10, alts: seeing, leaves, tree // needs review
  AwingWord(awing: 'məfǔə', english: 'nothing', category: 'nature', difficulty: 1),
  // bible:MAT.21.31, freq=2, conf=0.11, alts: collectors, prostitutes, certainly // needs review
  AwingWord(awing: 'ngaŋə́kwáalə́nchubə', english: 'tax', category: 'things', difficulty: 1),
  // bible:MAT.21.36, freq=2, conf=0.07, alts: same, sent, treated // needs review
  AwingWord(awing: 'ngaŋə́kyɛ̂mənta', english: 'servants', category: 'actions', difficulty: 2),
  // bible:MAT.22.11, freq=2, conf=0.07, alts: man, king, wedding // needs review
  AwingWord(awing: 'ngǎŋndzɔ́ʼə́', english: 'clothing', category: 'family', difficulty: 1),
  // bible:MAT.22.26, freq=2, conf=0.17, alts: second, same, seventh
  AwingWord(awing: 'azoŋə́zoŋə', english: 'third', category: 'numbers', difficulty: 1),
  // bible:MAT.22.34, freq=2, conf=0.07, alts: themselves, together, pharisees // needs review
  AwingWord(awing: 'ńnaʼkə̂', english: 'silenced', category: 'pronouns', difficulty: 1),
  // bible:MAT.23.2, freq=2, conf=0.07, alts: pharisees, scribes, sat // needs review
  AwingWord(awing: 'akɔʼ', english: 'seat', category: 'things', difficulty: 1),
  // bible:MAT.23.4, freq=2, conf=0.13, alts: themselves, borne, finger // needs review
  AwingWord(awing: 'mbeʼtə', english: 'shoulders', category: 'body', difficulty: 1),
  // bible:MAT.23.25, freq=2, conf=0.10, alts: platter, outside, extortion // needs review
  AwingWord(awing: 'əkáŋə', english: 'cup', category: 'things', difficulty: 1),
  // bible:MAT.23.27, freq=2, conf=0.12, alts: woe, whitened, tombs // needs review
  AwingWord(awing: 'əkwəŋə́', english: 'bones', category: 'things', difficulty: 1),

  // bible:MAT.23.37, freq=2, conf=0.08, alts: children, often, sent // needs review
  AwingWord(awing: 'ngə́bə', english: 'gathers', category: 'actions', difficulty: 1),
  // bible:MAT.23.38, freq=2, conf=0.07, alts: behold, left, desolate // needs review
  AwingWord(awing: 'afəmə́', english: 'house', category: 'things', difficulty: 1),
  // bible:MAT.24.17, freq=2, conf=0.25, alts: housetop, things, nor
  AwingWord(awing: 'atûndɛ̂', english: 'house', category: 'things', difficulty: 1),
  // bible:MAT.24.45, freq=2, conf=0.07, alts: household, servant, due // needs review
  AwingWord(awing: 'ə́fɛ̈', english: 'faithful', category: 'family', difficulty: 2),
  // bible:MAT.25.8, freq=2, conf=0.10, alts: oil, foolish, going // needs review
  AwingWord(awing: 'ḿbə́gnə', english: 'lamps', category: 'food', difficulty: 1),
  // bible:MAT.25.36, freq=2, conf=0.07, alts: clothed, prison, naked // needs review
  AwingWord(awing: 'ńtsaʼə̂', english: 'sick', category: 'descriptive', difficulty: 1),
  // bible:MAT.25.46, freq=2, conf=0.07, alts: life, away, punishment // needs review
  AwingWord(awing: 'ńtsɛɛkə̂', english: 'eternal', category: 'things', difficulty: 2),
  // bible:MAT.26.7, freq=2, conf=0.07, alts: head, poured, woman // needs review
  AwingWord(awing: 'azɔ́ʼə', english: 'alabaster', category: 'body', difficulty: 1),
  // bible:MAT.26.17, freq=2, conf=0.10, alts: day, first, eat // needs review
  AwingWord(awing: 'akɔ́lə́péenə', english: 'passover', category: 'actions', difficulty: 2),
  // bible:MAT.27.5, freq=2, conf=0.07, alts: silver, away, himself // needs review
  AwingWord(awing: 'ńdə́ŋə', english: 'sanctuary', category: 'pronouns', difficulty: 1),
  // bible:MAT.27.7, freq=2, conf=0.20, alts: potter, strangers, counsel
  AwingWord(awing: 'mbɔ̂məkəŋ', english: 'field', category: 'nature', difficulty: 1),
  // bible:MAT.27.7, freq=2, conf=0.07, alts: field, counsel, bury // needs review
  AwingWord(awing: 'yǐyinə́', english: 'strangers', category: 'nature', difficulty: 1),
  // bible:MAT.27.24, freq=2, conf=0.07, alts: rather, multitude, water // needs review
  AwingWord(awing: 'yə̈', english: 'nothing', category: 'nature', difficulty: 1),
  // bible:MAT.27.27, freq=2, conf=0.07, alts: together, whole, governor // needs review
  AwingWord(awing: 'ntɔ́ʼə', english: 'garrison', category: 'numbers', difficulty: 1),
  // bible:MAT.27.45, freq=2, conf=0.13, alts: sixth, darkness, until // needs review
  AwingWord(awing: 'ntɨ̌mə́numə', english: 'hour', category: 'things', difficulty: 1),

  // bible:MAT.27.46, freq=2, conf=0.08, alts: hour, forsaken, ninth // needs review
  AwingWord(awing: 'sabachtani', english: 'loud', category: 'descriptive', difficulty: 1),
  // bible:MAT.27.51, freq=2, conf=0.13, alts: veil, bottom, torn // needs review
  AwingWord(awing: 'ə́sɛɛnə̂', english: 'top', category: 'things', difficulty: 1),
  // bible:MRK.1.3, freq=2, conf=0.06, alts: wilderness, paths, straight // needs review
  AwingWord(awing: 'məshwáŋ', english: 'crying', category: 'actions', difficulty: 1),
  // bible:MRK.1.7, freq=2, conf=0.07, alts: stoop, after, mightier // needs review
  AwingWord(awing: 'ńkyag', english: 'sandals', category: 'things', difficulty: 1),
  // bible:MRK.1.35, freq=2, conf=0.12, alts: place, early, dark // needs review
  AwingWord(awing: 'ndúumbî', english: 'morning', category: 'descriptive', difficulty: 1),
  // bible:MRK.2.4, freq=2, conf=0.07, alts: mat, lying, paralytic // needs review
  AwingWord(awing: 'ngɔ́lə', english: 'near', category: 'things', difficulty: 1),
  // bible:MRK.2.22, freq=2, conf=0.11, alts: new, old, else // needs review
  AwingWord(awing: 'sá', english: 'wine', category: 'food', difficulty: 1),
  // bible:MRK.2.23, freq=2, conf=0.10, alts: fields, sabbath, going // needs review
  AwingWord(awing: 'ətsoʼ', english: 'grain', category: 'things', difficulty: 1),
  // bible:MRK.3.21, freq=2, conf=0.14, alts: friends, seize, loud // needs review
  AwingWord(awing: 'pɛ́ɛlə', english: 'insane', category: 'descriptive', difficulty: 1),

  // bible:MRK.4.21, freq=2, conf=0.14, alts: lamp, stand, basket // needs review
  AwingWord(awing: 'nəchwɛ́d', english: 'bed', category: 'actions', difficulty: 1),
  // bible:MRK.4.30, freq=2, conf=0.07, alts: liken, illustrate, world // needs review
  AwingWord(awing: 'ńdyaʼtə̂', english: 'parable', category: 'things', difficulty: 1),
  // bible:MRK.5.22, freq=2, conf=0.12, alts: fell, behold, name // needs review
  AwingWord(awing: 'Jailɔsə', english: 'synagogue', category: 'things', difficulty: 3),
  // bible:MRK.5.31, freq=2, conf=0.13, alts: multitude, say, touched // needs review
  AwingWord(awing: 'jwíʼnə', english: 'against', category: 'things', difficulty: 1),
  // bible:MRK.6.48, freq=2, conf=0.07, alts: distressed, contrary, walking // needs review
  AwingWord(awing: 'tɛ́n', english: 'wind', category: 'nature', difficulty: 1),
  // bible:MRK.6.53, freq=2, conf=0.07, alts: moored, gennesaret, land // needs review
  AwingWord(awing: 'ńtəŋnə̂', english: 'shore', category: 'things', difficulty: 1),
  // bible:MRK.7.22, freq=2, conf=0.07, alts: covetings, evil, desires // needs review
  AwingWord(awing: 'tɔ́gndě', english: 'pride', category: 'descriptive', difficulty: 1),
  // bible:MRK.7.34, freq=2, conf=0.15, alts: looking, opened, ephphatha
  AwingWord(awing: 'ńtsámnə', english: 'sighed', category: 'things', difficulty: 3),
  // bible:MRK.8.11, freq=2, conf=0.08, alts: sign, question, pharisees // needs review
  AwingWord(awing: 'zɔŋnə̂', english: 'testing', category: 'things', difficulty: 1),
  // bible:MRK.9.18, freq=2, conf=0.12, alts: foams, teeth, seizes // needs review
  AwingWord(awing: 'ə́fwɔʼkə̂', english: 'mouth', category: 'body', difficulty: 1),
  // bible:MRK.9.20, freq=2, conf=0.07, alts: mouth, wallowing, foaming // needs review
  AwingWord(awing: 'ńkablə̂', english: 'fell', category: 'actions', difficulty: 1),
  // bible:MRK.9.25, freq=2, conf=0.07, alts: command, enter, rebuked // needs review
  AwingWord(awing: 'ńkwəŋnə̂', english: 'multitude', category: 'things', difficulty: 1),
  // bible:MRK.9.43, freq=2, conf=0.08, alts: rather, life, off // needs review
  AwingWord(awing: 'ngǎmɔʼə́', english: 'cut', category: 'things', difficulty: 1),
  // bible:MRK.9.45, freq=2, conf=0.07, alts: rather, life, lame // needs review
  AwingWord(awing: 'ntá', english: 'cut', category: 'things', difficulty: 1),
  // bible:MRK.9.48, freq=2, conf=0.07, alts: die, worm, fire // needs review
  AwingWord(awing: 'əkəgho', english: 'doesn', category: 'animals', difficulty: 1),
  // bible:MRK.10.46, freq=2, conf=0.11, alts: jericho, blind, multitude // needs review
  AwingWord(awing: 'əfə̌gmə́g', english: 'road', category: 'nature', difficulty: 1),
  // bible:MRK.10.46, freq=2, conf=0.12, alts: multitude, great, road // needs review
  AwingWord(awing: 'ńdɔ́nə', english: 'blind', category: 'nature', difficulty: 1),
  // bible:MRK.10.50, freq=2, conf=0.08, alts: away, cloak, sprang // needs review
  AwingWord(awing: 'ə́sad', english: 'casting', category: 'things', difficulty: 1),
  // bible:MRK.11.20, freq=2, conf=0.12, alts: fig, passed, tree // needs review
  AwingWord(awing: 'məŋaŋə́', english: 'away', category: 'nature', difficulty: 1),
  // bible:MRK.11.25, freq=2, conf=0.07, alts: stand, forgive, against // needs review
  AwingWord(awing: 'pəpô', english: 'whenever', category: 'actions', difficulty: 1),
  // bible:MRK.12.1, freq=2, conf=0.12, alts: press, country, dug // needs review
  AwingWord(awing: 'atsoŋkəmə́loʼə', english: 'wine', category: 'actions', difficulty: 1),
  // bible:MRK.12.9, freq=2, conf=0.06, alts: farmers, vineyard, fell // needs review
  AwingWord(awing: 'ngaŋnkáʼə', english: 'destroy', category: 'things', difficulty: 1),
  // bible:MRK.12.15, freq=2, conf=0.07, alts: bring, hypocrisy, test // needs review
  AwingWord(awing: 'ngɔ́b', english: 'denarius', category: 'things', difficulty: 1),
  // bible:MRK.13.9, freq=2, conf=0.07, alts: deliver, sake, synagogues // needs review
  AwingWord(awing: 'pəgɔ́bnɔ', english: 'testimony', category: 'things', difficulty: 2),
  // bible:MRK.14.11, freq=2, conf=0.07, alts: deliver, glad, sought // needs review
  AwingWord(awing: 'alaŋə́sêndú', english: 'money', category: 'things', difficulty: 1),
  // bible:MRK.14.43, freq=2, conf=0.12, alts: clubs, speaking, multitude // needs review
  AwingWord(awing: 'məmbaŋə', english: 'swords', category: 'things', difficulty: 1),
  // bible:MRK.14.44, freq=2, conf=0.07, alts: kiss, away, sign // needs review
  AwingWord(awing: 'ńchweg', english: 'safely', category: 'descriptive', difficulty: 1),
  // bible:MRK.14.63, freq=2, conf=0.07, alts: high, tore, clothes // needs review
  AwingWord(awing: 'sɛɛtə̂', english: 'need', category: 'actions', difficulty: 1),
  // bible:MRK.14.65, freq=2, conf=0.12, alts: face, prophesy, palms // needs review
  AwingWord(awing: 'Sɛ̌ɛ', english: 'struck', category: 'body', difficulty: 3),
  // bible:MRK.15.17, freq=2, conf=0.15, alts: crown, thorns, weaving
  AwingWord(awing: 'kɨ́koobə́', english: 'purple', category: 'things', difficulty: 1),
  // bible:MRK.15.21, freq=2, conf=0.12, alts: cross, simon, coming // needs review
  AwingWord(awing: 'Silɛnə', english: 'cyrene', category: 'things', difficulty: 3),
  // bible:MRK.15.33, freq=2, conf=0.07, alts: hour, until, ninth // needs review
  AwingWord(awing: 'ntɨ̌mə́nu', english: 'darkness', category: 'things', difficulty: 1),

  // bible:MRK.15.42, freq=2, conf=0.14, alts: day, evening, sabbath // needs review
  AwingWord(awing: 'atyáŋtə́púmə', english: 'preparation', category: 'things', difficulty: 1),
  // bible:MRK.16.1, freq=2, conf=0.07, alts: anoint, sabbath, mother // needs review
  AwingWord(awing: 'ə́zɔ́ʼə', english: 'past', category: 'family', difficulty: 1),

  // bible:LUK.1.20, freq=2, conf=0.07, alts: proper, day, behold // needs review
  AwingWord(awing: 'chípóʼə́', english: 'believe', category: 'actions', difficulty: 1),
  // bible:LUK.2.24, freq=2, conf=0.07, alts: law, pigeons, turtledoves // needs review
  AwingWord(awing: 'fyaʼə́nuə', english: 'offer', category: 'things', difficulty: 1),
  // bible:LUK.2.36, freq=2, conf=0.07, alts: tribe, great, husband // needs review
  AwingWord(awing: 'Ntəŋkaŋ', english: 'prophetess', category: 'family', difficulty: 3),


  // bible:LUK.3.17, freq=2, conf=0.07, alts: burn, floor, chaff // needs review
  AwingWord(awing: 'əkwub', english: 'cleanse', category: 'things', difficulty: 1),









  // bible:LUK.4.5, freq=2, conf=0.07, alts: devil, world, moment // needs review
  AwingWord(awing: 'məfɔ', english: 'mountain', category: 'nature', difficulty: 1),
  // bible:LUK.4.35, freq=2, conf=0.07, alts: harm, silent, middle // needs review
  AwingWord(awing: 'alɔʼ', english: 'rebuked', category: 'things', difficulty: 1),
  // bible:LUK.5.1, freq=2, conf=0.07, alts: lake, gennesaret, pressed // needs review
  AwingWord(awing: 'ńjíʼnə', english: 'multitude', category: 'nature', difficulty: 1),
  // bible:LUK.5.3, freq=2, conf=0.13, alts: boat, boats, land // needs review
  AwingWord(awing: 'kwádtə', english: 'simon', category: 'things', difficulty: 1),
  // bible:LUK.5.19, freq=2, conf=0.07, alts: multitude, tiles, bring // needs review
  AwingWord(awing: 'nəgha', english: 'housetop', category: 'things', difficulty: 1),
  // bible:LUK.6.21, freq=2, conf=0.07, alts: laugh, weep, hunger // needs review
  AwingWord(awing: 'zɛ́lə', english: 'filled', category: 'actions', difficulty: 1),
  // bible:LUK.6.34, freq=2, conf=0.07, alts: back, sinners, even // needs review
  AwingWord(awing: 'ńtsɔ́ʼkə', english: 'receive', category: 'body', difficulty: 1),

  // bible:LUK.8.17, freq=2, conf=0.17, alts: nor, revealed, hidden
  AwingWord(awing: 'kyaʼnə̂', english: 'nothing', category: 'things', difficulty: 1),
  // bible:LUK.8.19, freq=2, conf=0.07, alts: mother, brothers, crowd // needs review
  AwingWord(awing: 'ŋwuməsɔŋə́', english: 'near', category: 'family', difficulty: 1),
  // bible:LUK.8.25, freq=2, conf=0.08, alts: water, even, marveled // needs review
  AwingWord(awing: 'nkɨʼnənuə', english: 'afraid', category: 'nature', difficulty: 1),
  // bible:LUK.8.32, freq=2, conf=0.07, alts: allowed, mountain, enter // needs review
  AwingWord(awing: 'kwúna', english: 'feeding', category: 'nature', difficulty: 1),

  // bible:LUK.8.50, freq=2, conf=0.07, alts: don, believe, answered // needs review
  AwingWord(awing: 'Jaliɔsə', english: 'afraid', category: 'actions', difficulty: 3),
  // bible:LUK.9.17, freq=2, conf=0.07, alts: baskets, twelve, filled // needs review
  AwingWord(awing: 'pakə̂', english: 'left', category: 'actions', difficulty: 1),
  // bible:LUK.9.58, freq=2, conf=0.07, alts: man, place, nests // needs review
  AwingWord(awing: 'məŋka', english: 'foxes', category: 'things', difficulty: 1),
  // bible:LUK.10.13, freq=2, conf=0.07, alts: works, ashes, repented // needs review
  AwingWord(awing: 'apû', english: 'woe', category: 'nature', difficulty: 1),
  // bible:LUK.11.7, freq=2, conf=0.07, alts: children, don, within // needs review
  AwingWord(awing: 'noŋtə̂', english: 'bother', category: 'family', difficulty: 1),
  // bible:LUK.11.26, freq=2, conf=0.07, alts: goes, becomes, evil // needs review
  AwingWord(awing: 'ńchwa', english: 'takes', category: 'descriptive', difficulty: 1),
  // bible:LUK.11.33, freq=2, conf=0.12, alts: light, lit, basket // needs review
  AwingWord(awing: 'mbindɛ̂', english: 'lamp', category: 'descriptive', difficulty: 1),
  // bible:LUK.12.24, freq=2, conf=0.07, alts: feeds, don, valuable // needs review
  AwingWord(awing: 'Əŋkəŋâ', english: 'warehouse', category: 'things', difficulty: 1),
  // bible:LUK.12.24, freq=2, conf=0.12, alts: warehouse, feeds, don // needs review
  AwingWord(awing: 'pəsə́ŋə́', english: 'birds', category: 'things', difficulty: 1),
  // bible:LUK.12.27, freq=2, conf=0.07, alts: don, spin, arrayed // needs review
  AwingWord(awing: 'atəshǐ', english: 'toil', category: 'things', difficulty: 1),
  // bible:LUK.12.36, freq=2, conf=0.12, alts: marriage, immediately, feast // needs review
  AwingWord(awing: 'ḿbóʼtə', english: 'open', category: 'actions', difficulty: 1),
  // bible:LUK.12.37, freq=2, conf=0.07, alts: certainly, recline, most // needs review
  AwingWord(awing: 'ətwéŋ', english: 'servants', category: 'things', difficulty: 2),
  // bible:LUK.12.40, freq=2, conf=0.08, alts: don, man, coming // needs review
  AwingWord(awing: 'ńdɛ́ɛlə', english: 'hour', category: 'things', difficulty: 1),
  // bible:LUK.13.4, freq=2, conf=0.07, alts: eighteen, killed, offenders // needs review
  AwingWord(awing: 'asagə́', english: 'fell', category: 'actions', difficulty: 1),
  // bible:LUK.13.4, freq=2, conf=0.07, alts: eighteen, killed, offenders // needs review
  AwingWord(awing: 'kəmnə̂', english: 'fell', category: 'actions', difficulty: 1),
  // bible:LUK.13.7, freq=2, conf=0.07, alts: fig, cut, none // needs review
  AwingWord(awing: 'ata', english: 'looking', category: 'things', difficulty: 1),
  // bible:LUK.13.15, freq=2, conf=0.07, alts: doesn, stall, away // needs review
  AwingWord(awing: 'akad', english: 'water', category: 'nature', difficulty: 1),
  // bible:LUK.14.16, freq=2, conf=0.14, alts: invited, great, certain // needs review
  AwingWord(awing: 'ajíəpú', english: 'supper', category: 'things', difficulty: 1),
  // bible:LUK.14.29, freq=2, conf=0.07, alts: mock, finish, perhaps // needs review
  AwingWord(awing: 'ńdeŋnə̂', english: 'begins', category: 'things', difficulty: 1),
  // bible:LUK.15.25, freq=2, conf=0.07, alts: elder, music, house // needs review
  AwingWord(awing: 'ntəŋkaŋə́', english: 'near', category: 'family', difficulty: 1),
  // bible:LUK.16.3, freq=2, conf=0.07, alts: dig, within, don // needs review
  AwingWord(awing: 'líʼə', english: 'taking', category: 'things', difficulty: 1),
  // bible:LUK.16.7, freq=2, conf=0.07, alts: write, much, wheat // needs review
  AwingWord(awing: 'ghɔʼ', english: 'hundred', category: 'actions', difficulty: 1),
  // bible:LUK.16.8, freq=2, conf=0.07, alts: children, dishonest, world // needs review
  AwingWord(awing: 'pímtə', english: 'commended', category: 'family', difficulty: 1),
  // bible:LUK.16.15, freq=2, conf=0.07, alts: justify, exalted, hearts // needs review
  AwingWord(awing: 'nəsəgə', english: 'sight', category: 'things', difficulty: 1),
  // bible:LUK.16.20, freq=2, conf=0.12, alts: gate, certain, lazarus // needs review
  AwingWord(awing: 'Njɨ̂ngə́ʼ', english: 'beggar', category: 'things', difficulty: 3),

  // bible:LUK.17.34, freq=2, conf=0.14, alts: night, people, left // needs review
  AwingWord(awing: 'əkwunə́', english: 'bed', category: 'things', difficulty: 1),
  // bible:LUK.18.25, freq=2, conf=0.07, alts: man, enter, camel // needs review
  AwingWord(awing: 'tə̂ŋkaʼə', english: 'easier', category: 'animals', difficulty: 1),
  // bible:LUK.18.31, freq=2, conf=0.07, alts: man, twelve, behold // needs review
  AwingWord(awing: 'chwaŋ', english: 'concerning', category: 'things', difficulty: 1),
  // bible:LUK.18.38, freq=2, conf=0.15, alts: mercy, led, quiet
  AwingWord(awing: 'tsá', english: 'cried', category: 'actions', difficulty: 1),
  // bible:LUK.19.3, freq=2, conf=0.12, alts: couldn, trying, crowd // needs review
  AwingWord(awing: 'ńkəmkə̂', english: 'short', category: 'descriptive', difficulty: 1),
  // bible:LUK.20.18, freq=2, conf=0.08, alts: crush, falls, pieces // needs review
  AwingWord(awing: 'pə́ʼkə', english: 'whomever', category: 'things', difficulty: 1),
  // bible:LUK.20.20, freq=2, conf=0.07, alts: something, deliver, sent // needs review
  AwingWord(awing: 'məŋkɔ́ʼ', english: 'trap', category: 'actions', difficulty: 1),
  // bible:LUK.20.20, freq=2, conf=0.07, alts: something, deliver, sent // needs review
  AwingWord(awing: 'ḿbɨ́ʼkə', english: 'trap', category: 'actions', difficulty: 1),
  // bible:LUK.21.9, freq=2, conf=0.07, alts: don, end, first // needs review
  AwingWord(awing: 'əjwaʼlə', english: 'won', category: 'numbers', difficulty: 1),
  // bible:LUK.21.9, freq=2, conf=0.07, alts: don, end, first // needs review
  AwingWord(awing: 'ghɔdlə̂', english: 'won', category: 'numbers', difficulty: 1),
  // bible:LUK.21.12, freq=2, conf=0.07, alts: synagogues, persecute, name // needs review
  AwingWord(awing: 'ngaŋə́sáʼə́láʼə', english: 'sake', category: 'things', difficulty: 1),
  // bible:LUK.21.34, freq=2, conf=0.07, alts: life, day, carousing // needs review
  AwingWord(awing: 'ghognə̂', english: 'suddenly', category: 'descriptive', difficulty: 1),
  // bible:LUK.22.1, freq=2, conf=0.20, alts: bread, unleavened, feast
  AwingWord(awing: 'akɔ́lə', english: 'passover', category: 'food', difficulty: 2),
  // bible:LUK.22.19, freq=2, conf=0.14, alts: memory, thanks, body // needs review
  AwingWord(awing: 'ńgwə́ʼtə', english: 'broke', category: 'actions', difficulty: 1),
  // bible:LUK.22.35, freq=2, conf=0.12, alts: purse, nothing, sent // needs review
  AwingWord(awing: 'pɔ́sa', english: 'wallet', category: 'actions', difficulty: 1),
  // bible:LUK.22.44, freq=2, conf=0.07, alts: blood, became, drops // needs review
  AwingWord(awing: 'alɛ̌dnə', english: 'great', category: 'things', difficulty: 1),
  // bible:LUK.22.44, freq=2, conf=0.12, alts: blood, became, drops // needs review
  AwingWord(awing: 'əkəmtə', english: 'great', category: 'things', difficulty: 1),
  // bible:LUK.22.55, freq=2, conf=0.12, alts: kindled, among, middle // needs review
  AwingWord(awing: 'nyagtə̂', english: 'fire', category: 'nature', difficulty: 1),
  // bible:LUK.23.29, freq=2, conf=0.07, alts: breasts, say, bore // needs review
  AwingWord(awing: 'nɔ́ŋkə', english: 'barren', category: 'things', difficulty: 1),
  // bible:LUK.23.41, freq=2, conf=0.07, alts: nothing, man, justly // needs review
  AwingWord(awing: 'pɔ̈', english: 'receive', category: 'things', difficulty: 1),
  // bible:LUK.23.43, freq=2, conf=0.18, alts: today, assuredly, unspeakable
  AwingWord(awing: 'paladayisə', english: 'paradise', category: 'things', difficulty: 1),
  // bible:LUK.24.11, freq=2, conf=0.09, alts: didn, nonsense, words // needs review
  AwingWord(awing: 'ə́fîə', english: 'believe', category: 'actions', difficulty: 1),
  // bible:LUK.24.29, freq=2, conf=0.06, alts: day, urged, almost // needs review
  AwingWord(awing: 'ńgɔ́ŋ', english: 'evening', category: 'things', difficulty: 1),

  // bible:JHN.2.8, freq=2, conf=0.22, alts: ruler, feast, drink
  AwingWord(awing: 'tóʼ', english: 'draw', category: 'actions', difficulty: 1),
  // bible:JHN.2.14, freq=2, conf=0.10, alts: oxen, sheep, changers // needs review
  AwingWord(awing: 'ngaŋə́kwúblə́nkáb', english: 'money', category: 'animals', difficulty: 1),

  // bible:JHN.5.2, freq=2, conf=0.07, alts: bethesda, five, hebrew // needs review
  AwingWord(awing: 'əlaakə', english: 'gate', category: 'numbers', difficulty: 1),



  // bible:JHN.8.21, freq=2, conf=0.07, alts: away, die, again // needs review
  AwingWord(awing: 'kə́káŋə́', english: 'seek', category: 'things', difficulty: 1),
  // bible:JHN.9.3, freq=2, conf=0.08, alts: nor, man, parents // needs review
  AwingWord(awing: 'fəg', english: 'works', category: 'things', difficulty: 1),
  // bible:JHN.9.18, freq=2, conf=0.08, alts: concerning, jews, believe // needs review
  AwingWord(awing: 'ńgyǒ', english: 'sight', category: 'actions', difficulty: 1),
  // bible:JHN.9.34, freq=2, conf=0.07, alts: answered, teach, threw // needs review
  AwingWord(awing: 'ńchaanə̂', english: 'born', category: 'actions', difficulty: 1),
  // bible:JHN.10.1, freq=2, conf=0.07, alts: doesn, same, thief // needs review
  AwingWord(awing: 'ḿbáʼnə', english: 'fold', category: 'things', difficulty: 1),
  // bible:JHN.10.12, freq=2, conf=0.07, alts: doesn, hand, shepherd // needs review
  AwingWord(awing: 'ńgwamtə̂', english: 'wolf', category: 'body', difficulty: 1),
  // bible:JHN.10.32, freq=2, conf=0.11, alts: answered, stone, works // needs review
  AwingWord(awing: 'tə́mə', english: 'good', category: 'nature', difficulty: 1),
  // bible:JHN.12.3, freq=2, conf=0.07, alts: pound, filled, precious // needs review
  AwingWord(awing: 'ńdəmkə̂', english: 'house', category: 'things', difficulty: 1),
  // bible:JHN.12.43, freq=2, conf=0.18, alts: loved, men, don
  AwingWord(awing: 'nəkwíŋ', english: 'praise', category: 'things', difficulty: 1),
  // bible:JHN.13.4, freq=2, conf=0.11, alts: towel, wrapped, supper // needs review
  AwingWord(awing: 'táawúlə', english: 'around', category: 'things', difficulty: 1),
  // bible:JHN.13.5, freq=2, conf=0.07, alts: around, poured, wipe // needs review
  AwingWord(awing: 'əjï', english: 'water', category: 'nature', difficulty: 1),
  // bible:JHN.15.4, freq=2, conf=0.07, alts: remains, unless, fruit // needs review
  AwingWord(awing: 'pádnə', english: 'itself', category: 'nature', difficulty: 1),
  // bible:JHN.16.20, freq=2, conf=0.11, alts: lament, weep, turned // needs review
  AwingWord(awing: 'ḿmɨ́ʼə', english: 'joy', category: 'actions', difficulty: 1),
  // bible:JHN.19.2, freq=2, conf=0.12, alts: garment, crown, thorns // needs review
  AwingWord(awing: 'ḿbáʼ', english: 'purple', category: 'things', difficulty: 1),
  // bible:JHN.19.23, freq=2, conf=0.12, alts: soldiers, crucified, soldier // needs review
  AwingWord(awing: 'sɛɛlə̂', english: 'garments', category: 'things', difficulty: 1),
  // bible:JHN.20.24, freq=2, conf=0.12, alts: wasn, twelve, cana // needs review
  AwingWord(awing: 'Nəfág', english: 'didymus', category: 'things', difficulty: 3),
  // bible:JHN.21.7, freq=2, conf=0.07, alts: around, simon, coat // needs review
  AwingWord(awing: 'ńkanə̂', english: 'loved', category: 'actions', difficulty: 1),
  // bible:JHN.21.18, freq=2, conf=0.12, alts: carry, old, don // needs review
  AwingWord(awing: 'atwíŋə', english: 'hands', category: 'actions', difficulty: 1),
  // bible:JHN.21.20, freq=2, conf=0.07, alts: leaned, supper, betray // needs review
  AwingWord(awing: 'ńdzə́ʼnə', english: 'loved', category: 'actions', difficulty: 1),
  // bible:ACT.1.6, freq=2, conf=0.08, alts: together, shepherd, souls // needs review
  AwingWord(awing: 'pɨnkə̂', english: 'restoring', category: 'things', difficulty: 1),
  // bible:ACT.1.12, freq=2, conf=0.07, alts: mountain, away, sabbath // needs review
  AwingWord(awing: 'kilóméta', english: 'near', category: 'nature', difficulty: 1),
  // bible:ACT.1.20, freq=2, conf=0.12, alts: dwell, therein, book // needs review
  AwingWord(awing: 'Pəsamsə', english: 'psalms', category: 'things', difficulty: 3),


  // bible:ACT.2.1, freq=2, conf=0.25, alts: place, day, accord
  AwingWord(awing: 'Pɛntekɔsə', english: 'pentecost', category: 'things', difficulty: 3),
  // bible:ACT.2.3, freq=2, conf=0.12, alts: distributed, appeared, fire // needs review
  AwingWord(awing: 'əlɨ́', english: 'tongues', category: 'nature', difficulty: 1),
  // bible:ACT.2.6, freq=2, conf=0.07, alts: multitude, sound, language // needs review
  AwingWord(awing: 'zɔd', english: 'speaking', category: 'things', difficulty: 1),


  // bible:ACT.2.24, freq=2, conf=0.07, alts: possible, held, death // needs review
  AwingWord(awing: 'ghɔ́ŋkə', english: 'raised', category: 'things', difficulty: 1),
  // bible:ACT.2.44, freq=2, conf=0.09, alts: common, things, believed // needs review
  AwingWord(awing: 'nəkaʼə́', english: 'together', category: 'things', difficulty: 1),


  // bible:ACT.3.6, freq=2, conf=0.12, alts: gold, walk, name // needs review
  AwingWord(awing: 'seleba', english: 'silver', category: 'actions', difficulty: 1),
  // bible:ACT.3.8, freq=2, conf=0.07, alts: walk, began, stood // needs review
  AwingWord(awing: 'lî', english: 'walking', category: 'actions', difficulty: 1),

  // bible:ACT.4.13, freq=2, conf=0.07, alts: ignorant, recognized, unlearned // needs review
  AwingWord(awing: 'asáŋəsáŋə́', english: 'boldness', category: 'things', difficulty: 1),
  // bible:ACT.4.14, freq=2, conf=0.09, alts: say, man, seeing // needs review
  AwingWord(awing: 'ńnaʼnə̂', english: 'nothing', category: 'things', difficulty: 1),
  // bible:ACT.5.17, freq=2, conf=0.12, alts: priest, sect, filled // needs review
  AwingWord(awing: 'pətɔ́mtə', english: 'high', category: 'things', difficulty: 1),
  // bible:ACT.7.10, freq=2, conf=0.12, alts: afflictions, house, king // needs review
  AwingWord(awing: 'Fɛlɔ', english: 'pharaoh', category: 'family', difficulty: 3),
  // bible:ACT.7.41, freq=2, conf=0.07, alts: calf, brought, days // needs review
  AwingWord(awing: 'pəkóomə́', english: 'works', category: 'actions', difficulty: 1),
  // bible:ACT.8.11, freq=2, conf=0.07, alts: amazed, time, listened // needs review
  AwingWord(awing: 'nəkaŋ', english: 'long', category: 'things', difficulty: 1),

  // bible:ACT.9.25, freq=2, conf=0.07, alts: lowering, night, basket // needs review
  AwingWord(awing: 'ńdaŋkə̂', english: 'wall', category: 'things', difficulty: 1),

  // bible:ACT.10.16, freq=2, conf=0.08, alts: received, immediately, times // needs review
  AwingWord(awing: 'yəwɨ́', english: 'vessel', category: 'things', difficulty: 1),
  // bible:ACT.10.32, freq=2, conf=0.07, alts: named, house, simon // needs review
  AwingWord(awing: 'ngaŋnə́ghéenə', english: 'summon', category: 'things', difficulty: 1),
  // bible:ACT.12.19, freq=2, conf=0.07, alts: death, stayed, examined // needs review
  AwingWord(awing: 'ńtɔʼnə̂', english: 'guards', category: 'things', difficulty: 1),
  // bible:ACT.13.1, freq=2, conf=0.12, alts: teachers, niger, cyrene // needs review
  AwingWord(awing: 'ngaŋə́náŋkə́nkɨ', english: 'prophets', category: 'things', difficulty: 3),



  // bible:ACT.13.12, freq=2, conf=0.07, alts: proconsul, believed, teaching // needs review
  AwingWord(awing: 'tǐə', english: 'astonished', category: 'things', difficulty: 1),
  // bible:ACT.13.19, freq=2, conf=0.07, alts: four, canaan, seven // needs review
  AwingWord(awing: 'ŋwúd', english: 'hundred', category: 'numbers', difficulty: 1),
  // bible:ACT.13.21, freq=2, conf=0.12, alts: benjamin, man, king // needs review
  AwingWord(awing: 'Bɛnjamɛn', english: 'tribe', category: 'family', difficulty: 3),
  // bible:ACT.13.41, freq=2, conf=0.07, alts: wonder, believe, declares // needs review
  AwingWord(awing: 'ḿbyáatə', english: 'perish', category: 'actions', difficulty: 3),



  // bible:ACT.15.29, freq=2, conf=0.10, alts: blood, immorality, sexual // needs review
  AwingWord(awing: 'ńdzɔ́ʼnə', english: 'idols', category: 'things', difficulty: 1),




  // bible:ACT.16.24, freq=2, conf=0.08, alts: prison, threw, secured // needs review
  AwingWord(awing: 'atɔ́g', english: 'command', category: 'things', difficulty: 1),
  // bible:ACT.16.27, freq=2, conf=0.12, alts: sword, jailer, supposing // needs review
  AwingWord(awing: 'ŋwéŋ', english: 'kill', category: 'actions', difficulty: 3),

  // bible:ACT.17.14, freq=2, conf=0.07, alts: timothy, stayed, sea // needs review
  AwingWord(awing: 'ńchaakə̂', english: 'sent', category: 'actions', difficulty: 1),
  // bible:ACT.18.25, freq=2, conf=0.12, alts: way, fervent, concerning // needs review
  AwingWord(awing: 'alaŋə́ndúmə', english: 'accurately', category: 'descriptive', difficulty: 1),
  // bible:ACT.18.25, freq=2, conf=0.07, alts: concerning, although, man // needs review
  AwingWord(awing: 'ḿbə̈', english: 'fervent', category: 'things', difficulty: 1),
  // bible:ACT.19.9, freq=2, conf=0.07, alts: multitude, evil, daily // needs review
  AwingWord(awing: 'əlětsəmə', english: 'speaking', category: 'descriptive', difficulty: 1),
  // bible:ACT.19.22, freq=2, conf=0.12, alts: sent, macedonia, timothy // needs review
  AwingWord(awing: 'Ɛlastusə', english: 'erastus', category: 'actions', difficulty: 1),
  // bible:ACT.19.24, freq=2, conf=0.12, alts: demetrius, silver, named // needs review
  AwingWord(awing: 'Demetəlosə', english: 'business', category: 'things', difficulty: 3),
  // bible:ACT.19.24, freq=2, conf=0.12, alts: demetrius, silver, named // needs review
  AwingWord(awing: 'əsêməngyě', english: 'artemis', category: 'things', difficulty: 1),



  // bible:ACT.20.7, freq=2, conf=0.10, alts: day, talked, until // needs review
  AwingWord(awing: 'ntéelə', english: 'break', category: 'actions', difficulty: 1),

  // bible:ACT.20.19, freq=2, conf=0.12, alts: tears, jews, plots // needs review
  AwingWord(awing: 'əkwaʼlə', english: 'trials', category: 'things', difficulty: 2),

  // bible:ACT.21.11, freq=2, conf=0.12, alts: bound, man, thus // needs review
  AwingWord(awing: 'atwíŋ', english: 'belt', category: 'things', difficulty: 1),


  // bible:ACT.24.17, freq=2, conf=0.07, alts: needy, after, bring // needs review
  AwingWord(awing: 'ə́fyaʼə́nuə', english: 'gifts', category: 'things', difficulty: 1),
  // bible:ACT.25.3, freq=2, conf=0.07, alts: kill, asking, against // needs review
  AwingWord(awing: 'ḿbántə', english: 'summon', category: 'actions', difficulty: 1),


  // bible:ACT.27.6, freq=2, conf=0.12, alts: alexandria, sailing, italy // needs review
  AwingWord(awing: 'apáŋə́nkǐ', english: 'ship', category: 'things', difficulty: 1),

  // bible:ACT.28.3, freq=2, conf=0.12, alts: fastened, viper, bundle // needs review
  AwingWord(awing: 'sénəsê', english: 'hand', category: 'body', difficulty: 1),
  // bible:ACT.28.4, freq=2, conf=0.07, alts: justice, allowed, doubt // needs review
  AwingWord(awing: 'ngaŋə́láʼə', english: 'murderer', category: 'things', difficulty: 3),

  // bible:ROM.1.23, freq=2, conf=0.12, alts: footed, man, four // needs review
  AwingWord(awing: 'məneemə', english: 'creeping', category: 'numbers', difficulty: 1),
  // bible:ROM.3.15, freq=2, conf=0.12, alts: feet, swift, blood // needs review
  AwingWord(awing: 'twáb', english: 'shed', category: 'things', difficulty: 1),
  // bible:ROM.5.15, freq=2, conf=0.06, alts: man, abound, died // needs review
  AwingWord(awing: 'pələŋ', english: 'gift', category: 'things', difficulty: 1),
  // bible:ROM.7.14, freq=2, conf=0.07, alts: sold, fleshly, spiritual // needs review
  AwingWord(awing: 'päʼ', english: 'law', category: 'actions', difficulty: 1),




  // bible:ROM.11.1, freq=2, conf=0.12, alts: benjamin, reject, people // needs review
  AwingWord(awing: 'Bɛnjamɛnə', english: 'tribe', category: 'things', difficulty: 3),

  // bible:ROM.11.17, freq=2, conf=0.10, alts: branches, tree, olive // needs review
  AwingWord(awing: 'ḿbádkə', english: 'wild', category: 'nature', difficulty: 1),
  // bible:ROM.11.30, freq=2, conf=0.17, alts: mercy, past, obtained
  AwingWord(awing: 'ńtyantə́tûə', english: 'disobedient', category: 'things', difficulty: 1),

  // bible:ROM.13.1, freq=2, conf=0.08, alts: soul, authority, authorities // needs review
  AwingWord(awing: 'pəsáʼ', english: 'higher', category: 'things', difficulty: 1),
  // bible:ROM.14.2, freq=2, conf=0.13, alts: eat, man, vegetables // needs review
  AwingWord(awing: 'ndzɛ̌', english: 'eats', category: 'actions', difficulty: 1),
  // bible:ROM.15.33, freq=2, conf=0.06, alts: write, faithful, angel // needs review
  AwingWord(awing: 'Amɛnə', english: 'peace', category: 'actions', difficulty: 3),
  // bible:1CO.1.10, freq=2, conf=0.12, alts: same, divisions, perfected // needs review
  AwingWord(awing: 'aghabtə', english: 'among', category: 'things', difficulty: 1),

  // bible:1CO.3.2, freq=2, conf=0.12, alts: fed, weren, even // needs review
  AwingWord(awing: 'nəpə́ənə', english: 'milk', category: 'food', difficulty: 1),
  // bible:1CO.4.8, freq=2, conf=0.12, alts: reign, wish, already // needs review
  AwingWord(awing: 'pəfoʼə', english: 'rich', category: 'descriptive', difficulty: 1),
  // bible:1CO.4.10, freq=2, conf=0.07, alts: sake, strong, fools // needs review
  AwingWord(awing: 'əkəghə', english: 'honor', category: 'descriptive', difficulty: 2),
  // bible:1CO.4.12, freq=2, conf=0.07, alts: curse, working, persecuted // needs review
  AwingWord(awing: 'wɛ́ʼə', english: 'toil', category: 'things', difficulty: 1),
  // bible:1CO.5.11, freq=2, conf=0.12, alts: don, brother, idolater // needs review
  AwingWord(awing: 'ngǎŋfóʼndé', english: 'covetous', category: 'family', difficulty: 1),
  // bible:1CO.5.11, freq=2, conf=0.07, alts: don, brother, extortionist // needs review
  AwingWord(awing: 'ngaŋmənaŋə́', english: 'idolater', category: 'family', difficulty: 1),
  // bible:1CO.6.4, freq=2, conf=0.06, alts: things, life, account // needs review
  AwingWord(awing: 'nətɨnə́', english: 'judge', category: 'things', difficulty: 1),
  // bible:1CO.6.9, freq=2, conf=0.11, alts: sexually, idolaters, adulterers // needs review
  AwingWord(awing: 'ngaŋə́ghóʼkə', english: 'immoral', category: 'things', difficulty: 3),
  // bible:1CO.9.10, freq=2, conf=0.12, alts: plow, plows, threshes // needs review
  AwingWord(awing: 'líʼ', english: 'sake', category: 'things', difficulty: 1),
  // bible:1CO.9.10, freq=2, conf=0.07, alts: plows, threshes, sake // needs review
  AwingWord(awing: 'ńkəblə̂', english: 'plow', category: 'things', difficulty: 1),
  // bible:1CO.10.21, freq=2, conf=0.08, alts: drink, cup, partake // needs review
  AwingWord(awing: 'atə́gtə', english: 'both', category: 'actions', difficulty: 1),
  // bible:1CO.11.15, freq=2, conf=0.07, alts: woman, covering, hair // needs review
  AwingWord(awing: 'mənoŋə', english: 'long', category: 'body', difficulty: 1),
  // bible:1CO.11.28, freq=2, conf=0.09, alts: cup, man, examine // needs review
  AwingWord(awing: 'ńchaʼ', english: 'drink', category: 'actions', difficulty: 1),
  // bible:1CO.12.14, freq=2, conf=0.40, alts: member, many
  AwingWord(awing: 'alam', english: 'body', category: 'numbers', difficulty: 1),
  // bible:1CO.13.4, freq=2, conf=0.07, alts: doesn, patient, love // needs review
  AwingWord(awing: 'aŋáŋkə', english: 'envy', category: 'actions', difficulty: 1),
  // bible:1CO.13.12, freq=2, conf=0.22, alts: dimly, mirror, even
  AwingWord(awing: 'zɨ́nə', english: 'face', category: 'body', difficulty: 1),
  // bible:1CO.14.25, freq=2, conf=0.07, alts: among, face, secrets // needs review
  AwingWord(awing: 'məkwəʼtə́', english: 'declaring', category: 'body', difficulty: 1),

  // bible:2CO.1.17, freq=2, conf=0.06, alts: things, show, determined // needs review
  AwingWord(awing: 'ńdɔ́btə', english: 'purpose', category: 'actions', difficulty: 1),

  // bible:2CO.3.1, freq=2, conf=0.12, alts: again, need, commendation // needs review
  AwingWord(awing: 'fítə', english: 'ourselves', category: 'actions', difficulty: 1),
  // bible:2CO.5.2, freq=2, conf=0.12, alts: groan, longing, habitation // needs review
  AwingWord(awing: 'tsámnə', english: 'clothed', category: 'things', difficulty: 1),
  // bible:2CO.6.12, freq=2, conf=0.15, alts: restricted, affections, life
  AwingWord(awing: 'məmə́ənə́', english: 'own', category: 'things', difficulty: 1),
  // bible:2CO.8.13, freq=2, conf=0.12, alts: distressed, flock, examples // needs review
  AwingWord(awing: 'ńjíʼə', english: 'eased', category: 'things', difficulty: 1),
  // bible:2CO.9.10, freq=2, conf=0.07, alts: sowing, multiply, seed // needs review
  AwingWord(awing: 'afoʼəmə́jíə', english: 'supply', category: 'nature', difficulty: 1),
  // bible:2CO.10.12, freq=2, conf=0.07, alts: measuring, themselves, ourselves // needs review
  AwingWord(awing: 'nəghɔd', english: 'comparing', category: 'pronouns', difficulty: 1),



  // bible:GAL.3.17, freq=2, conf=0.07, alts: effect, confirmed, say // needs review
  AwingWord(awing: 'shígtə', english: 'hundred', category: 'numbers', difficulty: 1),
  // bible:GAL.3.29, freq=2, conf=0.08, alts: according, heirs, promise // needs review
  AwingWord(awing: 'pəjî', english: 'offspring', category: 'things', difficulty: 1),

  // bible:GAL.6.2, freq=2, conf=0.07, alts: fulfill, bear, burdens // needs review
  AwingWord(awing: 'əpə́ənə́', english: 'law', category: 'things', difficulty: 1),
  // bible:EPH.5.5, freq=2, conf=0.12, alts: nor, immoral, man // needs review
  AwingWord(awing: 'nənaanənə́', english: 'inheritance', category: 'things', difficulty: 1),
  // bible:EPH.5.27, freq=2, conf=0.12, alts: without, gloriously, defect // needs review
  AwingWord(awing: 'alɔʼə́', english: 'spot', category: 'things', difficulty: 1),
  // bible:PHP.2.5, freq=2, conf=0.08, alts: ignorant, concerning, don // needs review
  AwingWord(awing: 'akwaŋə́nu', english: 'mind', category: 'things', difficulty: 1),
  // bible:PHP.2.26, freq=2, conf=0.10, alts: troubled, longed, sick // needs review
  AwingWord(awing: 'ńdublə̂', english: 'since', category: 'descriptive', difficulty: 1),
  // bible:PHP.3.1, freq=2, conf=0.07, alts: same, write, finally // needs review
  AwingWord(awing: 'pégnə', english: 'safe', category: 'actions', difficulty: 1),
  // bible:COL.1.26, freq=2, conf=0.07, alts: ages, revealed, hidden // needs review
  AwingWord(awing: 'məngoʼə́', english: 'generations', category: 'things', difficulty: 1),
  // bible:COL.2.2, freq=2, conf=0.12, alts: both, assurance, full // needs review
  AwingWord(awing: 'anuənə́lyáŋnə́', english: 'mystery', category: 'descriptive', difficulty: 1),

  // bible:1TH.2.3, freq=2, conf=0.07, alts: error, deception, uncleanness // needs review
  AwingWord(awing: 'afankə', english: 'nor', category: 'things', difficulty: 1),
  // bible:1TH.4.10, freq=2, conf=0.09, alts: abound, macedonia, exhort // needs review
  AwingWord(awing: 'ḿbegtə̂', english: 'toward', category: 'things', difficulty: 1),
  // bible:1TI.1.4, freq=2, conf=0.12, alts: genealogies, cause, myths // needs review
  AwingWord(awing: 'tɨ́ntə', english: 'disputes', category: 'things', difficulty: 1),
  // bible:1TI.4.12, freq=2, conf=0.06, alts: man, life, believe // needs review
  AwingWord(awing: 'ńgwág', english: 'example', category: 'actions', difficulty: 1),
  // bible:2TI.3.8, freq=2, conf=0.06, alts: men, opposed, oppose // needs review
  AwingWord(awing: 'Janɛsə', english: 'concerning', category: 'things', difficulty: 3),
  // bible:2TI.3.8, freq=2, conf=0.06, alts: men, opposed, oppose // needs review
  AwingWord(awing: 'Jambəlɛsə', english: 'concerning', category: 'things', difficulty: 3),
  // bible:TIT.1.9, freq=2, conf=0.07, alts: convict, doctrine, faithful // needs review
  AwingWord(awing: 'təkoʼə', english: 'holding', category: 'things', difficulty: 1),
  // bible:TIT.3.3, freq=2, conf=0.12, alts: living, envy, hateful // needs review
  AwingWord(awing: 'lublə̂', english: 'pleasures', category: 'things', difficulty: 1),
  // bible:HEB.5.13, freq=2, conf=0.14, alts: word, righteousness, everyone // needs review
  AwingWord(awing: 'nəpɨ́', english: 'milk', category: 'food', difficulty: 1),
  // bible:HEB.6.6, freq=2, conf=0.07, alts: themselves, impossible, away // needs review
  AwingWord(awing: 'yitsə̈', english: 'fell', category: 'actions', difficulty: 1),
  // bible:HEB.7.3, freq=2, conf=0.07, alts: nor, life, continually // needs review
  AwingWord(awing: 'Mɛkisidɛg', english: 'remains', category: 'things', difficulty: 3),
  // bible:HEB.9.2, freq=2, conf=0.11, alts: place, lamp, stand // needs review
  AwingWord(awing: 'atə́gə́lámə', english: 'first', category: 'actions', difficulty: 1),
  // bible:HEB.9.9, freq=2, conf=0.12, alts: sacrifices, gifts, concerning // needs review
  AwingWord(awing: 'əkáŋsê', english: 'offered', category: 'things', difficulty: 1),
  // bible:HEB.9.13, freq=2, conf=0.12, alts: blood, ashes, bulls // needs review
  AwingWord(awing: 'ə́fyáamə', english: 'goats', category: 'nature', difficulty: 1),
  // bible:HEB.9.16, freq=2, conf=0.14, alts: death, testament, necessity // needs review
  AwingWord(awing: 'ntəgə́nəwû', english: 'last', category: 'things', difficulty: 1),

  // bible:HEB.11.7, freq=2, conf=0.12, alts: noah, fear, saving // needs review
  AwingWord(awing: 'apáŋ', english: 'ship', category: 'things', difficulty: 1),

  // bible:HEB.11.33, freq=2, conf=0.12, alts: lions, worked, subdued // needs review
  AwingWord(awing: 'pəsáambaŋə', english: 'mouths', category: 'things', difficulty: 1),
  // bible:HEB.11.37, freq=2, conf=0.07, alts: sawn, around, slain // needs review
  AwingWord(awing: 'ə́sə́ələ', english: 'tempted', category: 'things', difficulty: 2),
  // bible:HEB.11.38, freq=2, conf=0.11, alts: caves, earth, wandering // needs review
  AwingWord(awing: 'əghəʼ', english: 'mountains', category: 'nature', difficulty: 1),

  // bible:HEB.12.28, freq=2, conf=0.06, alts: reverence, awe, serve // needs review
  AwingWord(awing: 'aliʼənə́fɔ', english: 'acceptably', category: 'actions', difficulty: 1),
  // bible:HEB.13.11, freq=2, conf=0.12, alts: outside, blood, place // needs review
  AwingWord(awing: 'pə́lə́glə́', english: 'camp', category: 'things', difficulty: 1),
  // bible:JAS.1.23, freq=2, conf=0.07, alts: mirror, man, natural // needs review
  AwingWord(awing: 'akyaʼə́shî', english: 'looking', category: 'things', difficulty: 1),
  // bible:JAS.5.1, freq=2, conf=0.07, alts: weep, rich, miseries // needs review
  AwingWord(awing: 'jwéʼtə', english: 'coming', category: 'actions', difficulty: 1),
  // bible:1PE.1.5, freq=2, conf=0.06, alts: last, power, ready // needs review
  AwingWord(awing: 'ńkɨ́ʼtə', english: 'salvation', category: 'things', difficulty: 2),
  // bible:1PE.1.24, freq=2, conf=0.07, alts: man, withers, falls // needs review
  AwingWord(awing: 'wə̈', english: 'grass', category: 'nature', difficulty: 1),
  // bible:1PE.4.3, freq=2, conf=0.07, alts: desire, gentiles, carousings // needs review
  AwingWord(awing: 'akóomə́', english: 'past', category: 'things', difficulty: 1),
  // bible:1PE.5.8, freq=2, conf=0.12, alts: walks, adversary, seeking // needs review
  AwingWord(awing: 'sáambaŋ', english: 'lion', category: 'animals', difficulty: 1),


  // bible:REV.4.3, freq=2, conf=0.12, alts: jasper, around, throne // needs review
  AwingWord(awing: 'nôngə́m', english: 'rainbow', category: 'things', difficulty: 1),
  // bible:REV.4.6, freq=2, conf=0.12, alts: living, something, similar // needs review
  AwingWord(awing: 'gəlasə', english: 'glass', category: 'pronouns', difficulty: 1),
  // bible:REV.4.7, freq=2, conf=0.12, alts: face, man, third // needs review
  AwingWord(awing: 'mbôʼmə́wúmə́', english: 'eagle', category: 'body', difficulty: 1),
  // bible:REV.5.8, freq=2, conf=0.12, alts: having, fell, book // needs review
  AwingWord(awing: 'ashǎdnə', english: 'living', category: 'things', difficulty: 1),
  // bible:REV.5.8, freq=2, conf=0.12, alts: living, having, fell // needs review
  AwingWord(awing: 'aleŋə', english: 'incense', category: 'things', difficulty: 1),
  // bible:REV.6.14, freq=2, conf=0.17, alts: mountain, rolled, scroll
  AwingWord(awing: 'pəkyádkənkǐ', english: 'island', category: 'nature', difficulty: 1),
  // bible:REV.8.3, freq=2, conf=0.11, alts: angel, prayers, add // needs review
  AwingWord(awing: 'atoonə́leŋ', english: 'censer', category: 'things', difficulty: 1),
  // bible:REV.8.9, freq=2, conf=0.12, alts: sea, third, died // needs review
  AwingWord(awing: 'Əpáŋnkǐ', english: 'living', category: 'nature', difficulty: 1),
  // bible:REV.8.10, freq=2, conf=0.07, alts: waters, great, third // needs review
  AwingWord(awing: 'nəpö', english: 'fell', category: 'actions', difficulty: 1),
  // bible:REV.8.10, freq=2, conf=0.11, alts: rivers, springs, fell // needs review
  AwingWord(awing: 'pəsáʼə́sê', english: 'third', category: 'numbers', difficulty: 1),
  // bible:REV.9.9, freq=2, conf=0.12, alts: chariots, iron, rushing // needs review
  AwingWord(awing: 'pəmuto', english: 'horses', category: 'things', difficulty: 1),
  // bible:REV.9.10, freq=2, conf=0.13, alts: tails, power, months // needs review
  AwingWord(awing: 'əsaŋə́', english: 'harm', category: 'things', difficulty: 1),
  // bible:REV.9.10, freq=2, conf=0.07, alts: harm, tails, stings // needs review
  AwingWord(awing: 'asaŋə́', english: 'months', category: 'things', difficulty: 1),
  // bible:REV.9.17, freq=2, conf=0.07, alts: proceed, fiery, hyacinth // needs review
  AwingWord(awing: 'safaya', english: 'horses', category: 'things', difficulty: 1),
  // bible:REV.9.21, freq=2, conf=0.07, alts: repent, murders, sexual // needs review
  AwingWord(awing: 'məkaŋ', english: 'immorality', category: 'things', difficulty: 3),
  // bible:REV.10.3, freq=2, conf=0.11, alts: thunders, voice, voices // needs review
  AwingWord(awing: 'məfaŋ', english: 'seven', category: 'numbers', difficulty: 1),


  // bible:REV.21.11, freq=2, conf=0.12, alts: jasper, precious, most // needs review
  AwingWord(awing: 'yiwə́', english: 'having', category: 'things', difficulty: 1),

  // bible:REV.21.15, freq=2, conf=0.11, alts: its, city, walls // needs review
  AwingWord(awing: 'ə́fiʼə̂', english: 'reed', category: 'things', difficulty: 1),
  // bible:REV.21.16, freq=2, conf=0.12, alts: its, great, equal // needs review
  AwingWord(awing: 'yiwɨ́', english: 'city', category: 'things', difficulty: 1),







































  // bible:MAT.2.23, freq=1, conf=0.17, alts: city, nazarene, fulfilled
  AwingWord(awing: 'yö', english: 'prophets', category: 'things', difficulty: 3),
  // bible:MAT.3.4, freq=1, conf=0.07, alts: belt, around, clothing // needs review
  AwingWord(awing: 'kəmbôʼnkɔnə́', english: 'waist', category: 'things', difficulty: 1),
  // bible:MAT.3.12, freq=1, conf=0.07, alts: burn, floor, chaff // needs review
  AwingWord(awing: 'əkaglə́', english: 'cleanse', category: 'things', difficulty: 1),
  // bible:MAT.4.13, freq=1, conf=0.12, alts: zebulun, capernaum, region // needs review
  AwingWord(awing: 'Zɛbulɔn', english: 'leaving', category: 'things', difficulty: 3),

  // bible:MAT.4.18, freq=1, conf=0.09, alts: brother, net, walking // needs review
  AwingWord(awing: 'ngaŋə́kóolə́shûə', english: 'casting', category: 'family', difficulty: 1),
  // bible:MAT.4.24, freq=1, conf=0.07, alts: report, diseases, epileptics // needs review
  AwingWord(awing: 'akəpuʼ', english: 'possessed', category: 'things', difficulty: 3),
  // bible:MAT.5.3, freq=1, conf=0.17, alts: theirs
  AwingWord(awing: 'fə́m', english: 'poor', category: 'descriptive', difficulty: 1),
  // bible:MAT.5.22, freq=1, conf=0.07, alts: brother, whoever, gehenna // needs review
  AwingWord(awing: 'sɔ́mə́sə', english: 'cause', category: 'family', difficulty: 1),
  // bible:MAT.5.28, freq=1, conf=0.11, alts: lust, already, after // needs review
  AwingWord(awing: 'lěe', english: 'gazes', category: 'things', difficulty: 1),
  // bible:MAT.5.35, freq=1, conf=0.12, alts: footstool, great, king // needs review
  AwingWord(awing: 'atə́gə', english: 'nor', category: 'family', difficulty: 1),
  // bible:MAT.5.38, freq=1, conf=0.50, alts: eye
  AwingWord(awing: 'nəsɔŋ', english: 'tooth', category: 'body', difficulty: 1),
  // bible:MAT.5.39, freq=1, conf=0.12, alts: right, evil, don // needs review
  AwingWord(awing: 'kwégə', english: 'cheek', category: 'body', difficulty: 1),
  // bible:MAT.5.41, freq=1, conf=0.33, alts: whoever, mile
  AwingWord(awing: 'ntagə', english: 'compels', category: 'pronouns', difficulty: 1),
  // bible:MAT.5.47, freq=1, conf=0.14, alts: same, don, tax // needs review
  AwingWord(awing: 'ndzéʼnə', english: 'greet', category: 'actions', difficulty: 1),
  // bible:MAT.6.17, freq=1, conf=0.20, alts: head, fast, wash
  AwingWord(awing: 'ə́shaabə̂', english: 'anoint', category: 'actions', difficulty: 1),
  // bible:MAT.6.26, freq=1, conf=0.07, alts: feeds, don, sow // needs review
  AwingWord(awing: 'zagnə̂', english: 'nor', category: 'things', difficulty: 1),
  // bible:MAT.7.4, freq=1, conf=0.14, alts: brother, behold, remove // needs review
  AwingWord(awing: 'nələ́gə', english: 'beam', category: 'family', difficulty: 1),
  // bible:MAT.7.6, freq=1, conf=0.07, alts: trample, pearls, don // needs review
  AwingWord(awing: 'məngwûə', english: 'dogs', category: 'things', difficulty: 1),
  // bible:MAT.7.16, freq=1, conf=0.17, alts: thistles, fruits, thorns
  AwingWord(awing: 'məŋkɨ́nkɨ́ə', english: 'figs', category: 'things', difficulty: 1),
  // bible:MAT.8.1, freq=1, conf=0.25, alts: multitudes, great, mountain
  AwingWord(awing: 'mənoonə', english: 'followed', category: 'actions', difficulty: 1),
  // bible:MAT.8.20, freq=1, conf=0.09, alts: man, nests, birds // needs review
  AwingWord(awing: 'Əntsɔb', english: 'foxes', category: 'things', difficulty: 1),

  // bible:MAT.8.32, freq=1, conf=0.11, alts: behold, cliff, herd // needs review
  AwingWord(awing: 'shwəənə̂', english: 'water', category: 'nature', difficulty: 1),
  // bible:MAT.9.9, freq=1, conf=0.10, alts: man, follow, followed // needs review
  AwingWord(awing: 'akwáalə́nchubə', english: 'tax', category: 'actions', difficulty: 1),
  // bible:MAT.9.23, freq=1, conf=0.12, alts: ruler, disorder, house // needs review
  AwingWord(awing: 'ngaŋə́zoobə', english: 'players', category: 'family', difficulty: 1),

  // bible:MAT.10.9, freq=1, conf=0.17, alts: money, silver, don
  AwingWord(awing: 'pəpɔ́ŋə́', english: 'belts', category: 'things', difficulty: 1),
  // bible:MAT.10.9, freq=1, conf=0.17, alts: money, silver, don
  AwingWord(awing: 'pəshílə', english: 'belts', category: 'things', difficulty: 1),
  // bible:MAT.10.9, freq=1, conf=0.17, alts: money, silver, don
  AwingWord(awing: 'pəkə̂pa', english: 'belts', category: 'things', difficulty: 1),
  // bible:MAT.10.18, freq=1, conf=0.14, alts: governors, kings, brought // needs review
  AwingWord(awing: 'ngaŋə́sáʼə́láʼ', english: 'sake', category: 'actions', difficulty: 1),
  // bible:MAT.10.27, freq=1, conf=0.14, alts: housetops, light, hear // needs review
  AwingWord(awing: 'ńchámtə', english: 'darkness', category: 'descriptive', difficulty: 1),
  // bible:MAT.10.30, freq=1, conf=0.33, alts: head, numbered
  AwingWord(awing: 'ə́sháŋə', english: 'hairs', category: 'body', difficulty: 1),
  // bible:MAT.10.35, freq=1, conf=0.12, alts: man, mother, against // needs review
  AwingWord(awing: 'mə́pɨ́', english: 'law', category: 'family', difficulty: 1),
  // bible:MAT.11.8, freq=1, conf=0.14, alts: man, clothing, houses // needs review
  AwingWord(awing: 'məntɔ́ʼ', english: 'behold', category: 'things', difficulty: 2),
  // bible:MAT.11.12, freq=1, conf=0.10, alts: force, until, days // needs review
  AwingWord(awing: 'ngaŋə́fɛ̂ngə́ʼ', english: 'baptizer', category: 'things', difficulty: 1),
  // bible:MAT.11.21, freq=1, conf=0.08, alts: works, ashes, repented // needs review
  AwingWord(awing: 'Əkɨʼnə', english: 'woe', category: 'nature', difficulty: 1),
  // bible:MAT.12.19, freq=1, conf=0.12, alts: strive, neither, streets // needs review
  AwingWord(awing: 'kɨ̈', english: 'nor', category: 'things', difficulty: 1),
  // bible:MAT.12.43, freq=1, conf=0.10, alts: man, gone, rest // needs review
  AwingWord(awing: 'njǔbtə̈', english: 'doesn', category: 'things', difficulty: 1),
  // bible:MAT.12.49, freq=1, conf=0.14, alts: behold, hand, mother // needs review
  AwingWord(awing: 'ə́shiʼ', english: 'stretched', category: 'body', difficulty: 1),
  // bible:MAT.13.14, freq=1, conf=0.10, alts: understand, prophecy, says // needs review
  AwingWord(awing: 'ńdéenə', english: 'perceive', category: 'things', difficulty: 1),
  // bible:MAT.13.26, freq=1, conf=0.14, alts: weeds, fruit, sprang // needs review
  AwingWord(awing: 'ḿbadtə̂', english: 'darnel', category: 'nature', difficulty: 1),
  // bible:MAT.13.46, freq=1, conf=0.17, alts: price, sold, pearl
  AwingWord(awing: 'ńdyâ', english: 'great', category: 'actions', difficulty: 1),
  // bible:MAT.13.47, freq=1, conf=0.11, alts: fish, cast, again // needs review
  AwingWord(awing: 'nkï', english: 'dragnet', category: 'animals', difficulty: 1),
  // bible:MAT.13.48, freq=1, conf=0.10, alts: away, good, filled // needs review
  AwingWord(awing: 'ə́wú', english: 'bad', category: 'descriptive', difficulty: 1),
  // bible:MAT.13.48, freq=1, conf=0.10, alts: away, good, filled // needs review
  AwingWord(awing: 'ńtídtə', english: 'bad', category: 'descriptive', difficulty: 1),
  // bible:MAT.13.49, freq=1, conf=0.14, alts: world, end, among // needs review
  AwingWord(awing: 'tídtə', english: 'angels', category: 'things', difficulty: 1),
  // bible:MAT.14.8, freq=1, conf=0.17, alts: platter, head, mother
  AwingWord(awing: 'toʼkə̂', english: 'baptizer', category: 'body', difficulty: 1),
  // bible:MAT.15.22, freq=1, conf=0.08, alts: mercy, cried, behold // needs review
  AwingWord(awing: 'ḿbyádnə̈', english: 'possessed', category: 'things', difficulty: 3),
  // bible:MAT.15.34, freq=1, conf=0.14, alts: few, loaves, fish // needs review
  AwingWord(awing: 'zɛ́nə', english: 'small', category: 'animals', difficulty: 1),

  // bible:MAT.16.6, freq=1, conf=0.17, alts: pharisees, sadducees, beware
  AwingWord(awing: 'ńtsě', english: 'heed', category: 'things', difficulty: 1),
  // bible:MAT.17.15, freq=1, conf=0.10, alts: mercy, water, epileptic // needs review
  AwingWord(awing: 'ngwuəkəpuʼə', english: 'often', category: 'nature', difficulty: 1),
  // bible:MAT.17.17, freq=1, conf=0.12, alts: perverse, answered, generation // needs review
  AwingWord(awing: 'awaʼə', english: 'long', category: 'things', difficulty: 1),
  // bible:MAT.17.27, freq=1, conf=0.07, alts: stater, stumble, mouth // needs review
  AwingWord(awing: 'əzɔ̌', english: 'cause', category: 'body', difficulty: 1),
  // bible:MAT.18.28, freq=1, conf=0.10, alts: servants, owed, throat // needs review
  AwingWord(awing: 'ə́faŋə̂', english: 'hundred', category: 'body', difficulty: 1),
  // bible:MAT.18.34, freq=1, conf=0.14, alts: due, delivered, tormentors // needs review
  AwingWord(awing: 'nətsəmə', english: 'until', category: 'things', difficulty: 1),
  // bible:MAT.19.7, freq=1, conf=0.25, alts: divorce, bill
  AwingWord(awing: 'ashamkə̂', english: 'command', category: 'things', difficulty: 1),
  // bible:MAT.19.8, freq=1, conf=0.14, alts: allowed, hearts, divorce // needs review
  AwingWord(awing: 'nəfɛd', english: 'hardness', category: 'things', difficulty: 1),
  // bible:MAT.19.9, freq=1, conf=0.10, alts: immorality, except, sexual // needs review
  AwingWord(awing: 'ńjínə', english: 'adultery', category: 'things', difficulty: 3),
  // bible:MAT.20.3, freq=1, conf=0.17, alts: third, idle, hour
  AwingWord(awing: 'ńkɔ́ʼtə', english: 'marketplace', category: 'numbers', difficulty: 1),
  // bible:MAT.20.4, freq=1, conf=0.25, alts: right, way, vineyard
  AwingWord(awing: 'atɔʼ', english: 'whatever', category: 'descriptive', difficulty: 1),
  // bible:MAT.20.6, freq=1, conf=0.14, alts: hour, day, stand // needs review
  AwingWord(awing: 'ńtɨ́mtə', english: 'idle', category: 'actions', difficulty: 1),
  // bible:MAT.21.1, freq=1, conf=0.12, alts: sent, mount, bethsphage // needs review
  AwingWord(awing: 'Bɛtfashə', english: 'near', category: 'actions', difficulty: 3),
  // bible:MAT.21.20, freq=1, conf=0.14, alts: wither, marveled, tree // needs review
  AwingWord(awing: 'ńjúm', english: 'away', category: 'nature', difficulty: 1),
  // bible:MAT.21.25, freq=1, conf=0.12, alts: say, believe, baptism // needs review
  AwingWord(awing: 'tsəmnə̂', english: 'themselves', category: 'actions', difficulty: 1),
  // bible:MAT.21.44, freq=1, conf=0.12, alts: fall, falls, pieces // needs review
  AwingWord(awing: 'lə́kə', english: 'scatter', category: 'actions', difficulty: 1),
  // bible:MAT.21.44, freq=1, conf=0.12, alts: fall, falls, pieces // needs review
  AwingWord(awing: 'nwadtə̂', english: 'scatter', category: 'actions', difficulty: 1),
  // bible:MAT.22.7, freq=1, conf=0.12, alts: king, destroyed, city // needs review
  AwingWord(awing: 'pəjwítə', english: 'sent', category: 'actions', difficulty: 1),
  // bible:MAT.22.13, freq=1, conf=0.08, alts: teeth, away, darkness // needs review
  AwingWord(awing: 'ngaŋə́téelə', english: 'servants', category: 'things', difficulty: 2),
  // bible:MAT.23.5, freq=1, conf=0.14, alts: works, enlarge, fringes // needs review
  AwingWord(awing: 'fáŋkə̈', english: 'broad', category: 'things', difficulty: 1),
  // bible:MAT.23.5, freq=1, conf=0.14, alts: works, enlarge, fringes // needs review
  AwingWord(awing: 'məndzíglə́', english: 'broad', category: 'things', difficulty: 1),
  // bible:MAT.23.15, freq=1, conf=0.07, alts: becomes, around, gehenna // needs review
  AwingWord(awing: 'mənkǐə', english: 'woe', category: 'things', difficulty: 1),
  // bible:MAT.23.17, freq=1, conf=0.17, alts: fools, sanctifies, blind
  AwingWord(awing: 'nəsəg', english: 'greater', category: 'things', difficulty: 1),
  // bible:MAT.23.34, freq=1, conf=0.08, alts: scourge, synagogues, prophets // needs review
  AwingWord(awing: 'ə́shúm', english: 'kill', category: 'actions', difficulty: 3),
  // bible:MAT.23.34, freq=1, conf=0.08, alts: scourge, synagogues, prophets // needs review
  AwingWord(awing: 'məláʼmə́sê', english: 'kill', category: 'actions', difficulty: 3),
  // bible:MAT.23.34, freq=1, conf=0.08, alts: scourge, synagogues, prophets // needs review
  AwingWord(awing: 'mbɔb', english: 'kill', category: 'actions', difficulty: 3),


  // bible:MAT.24.26, freq=1, conf=0.17, alts: don, wilderness, behold
  AwingWord(awing: 'mənkwâʼlə̌', english: 'believe', category: 'actions', difficulty: 1),
  // bible:MAT.24.28, freq=1, conf=0.20, alts: gather, wherever, carcass
  AwingWord(awing: 'əntsônə́ngwúmnə́', english: 'vultures', category: 'actions', difficulty: 1),
  // bible:MAT.24.31, freq=1, conf=0.08, alts: great, ones, chosen // needs review
  AwingWord(awing: 'ńchûə', english: 'angels', category: 'things', difficulty: 1),
  // bible:MAT.24.36, freq=1, conf=0.14, alts: even, day, hour // needs review
  AwingWord(awing: 'ńdə́ʼtə', english: 'angels', category: 'things', difficulty: 1),
  // bible:MAT.24.48, freq=1, conf=0.14, alts: say, servant, delaying // needs review
  AwingWord(awing: 'twiʼə̂', english: 'evil', category: 'family', difficulty: 3),
  // bible:MAT.24.49, freq=1, conf=0.14, alts: servants, drink, drunkards // needs review
  AwingWord(awing: 'əpɛ̌mə́loʼə', english: 'begins', category: 'actions', difficulty: 1),
  // bible:MAT.25.4, freq=1, conf=0.25, alts: oil, wise, lamps
  AwingWord(awing: 'əboolə́', english: 'vessels', category: 'food', difficulty: 1),
  // bible:MAT.25.5, freq=1, conf=0.25, alts: slept, bridegroom, delayed
  AwingWord(awing: 'ńtwiʼ', english: 'slumbered', category: 'actions', difficulty: 1),
  // bible:MAT.25.9, freq=1, conf=0.12, alts: buy, wise, answered // needs review
  AwingWord(awing: 'ngaŋə́finə', english: 'rather', category: 'actions', difficulty: 1),
  // bible:MAT.25.10, freq=1, conf=0.12, alts: away, buy, shut // needs review
  AwingWord(awing: 'tûʼnkaŋ', english: 'marriage', category: 'actions', difficulty: 1),
  // bible:MAT.25.16, freq=1, conf=0.20, alts: five, received, immediately
  AwingWord(awing: 'táŋ', english: 'talents', category: 'numbers', difficulty: 1),
  // bible:MAT.26.7, freq=1, conf=0.10, alts: head, poured, woman // needs review
  AwingWord(awing: 'alabasəta', english: 'alabaster', category: 'body', difficulty: 1),
  // bible:MAT.26.11, freq=1, conf=0.50, alts: don
  AwingWord(awing: 'ətsə̈m', english: 'poor', category: 'descriptive', difficulty: 1),

  // bible:MAT.26.71, freq=1, conf=0.12, alts: man, else, someone // needs review
  AwingWord(awing: 'ntsoolə́poʼ', english: 'onto', category: 'pronouns', difficulty: 1),
  // bible:MAT.26.74, freq=1, conf=0.12, alts: don, man, crowed // needs review
  AwingWord(awing: 'məndoonə', english: 'curse', category: 'things', difficulty: 3),
  // bible:MAT.26.75, freq=1, conf=0.09, alts: deny, wept, remembered // needs review
  AwingWord(awing: 'mɨ́ʼə', english: 'bitterly', category: 'descriptive', difficulty: 1),
  // bible:MAT.27.3, freq=1, conf=0.07, alts: silver, felt, condemned // needs review
  AwingWord(awing: 'ńkwígə', english: 'back', category: 'body', difficulty: 1),
  // bible:MAT.27.19, freq=1, conf=0.08, alts: suffered, sent, seat // needs review
  AwingWord(awing: 'aləŋə́sáʼə́məsáʼ', english: 'nothing', category: 'actions', difficulty: 1),

  // bible:MAT.27.34, freq=1, conf=0.17, alts: drink, sour, tasted
  AwingWord(awing: 'ńdwǐ', english: 'wine', category: 'actions', difficulty: 1),
  // bible:MAT.27.52, freq=1, conf=0.12, alts: raised, bodies, fallen // needs review
  AwingWord(awing: 'kə́ʼkə', english: 'tombs', category: 'things', difficulty: 1),

  // bible:MAT.27.59, freq=1, conf=0.17, alts: body, cloth, wrapped
  AwingWord(awing: 'akwû', english: 'linen', category: 'things', difficulty: 1),
  // bible:MAT.28.2, freq=1, conf=0.08, alts: great, away, behold // needs review
  AwingWord(awing: 'ḿbáŋkə', english: 'descended', category: 'things', difficulty: 1),
  // bible:MAT.28.8, freq=1, conf=0.10, alts: quickly, great, joy // needs review
  AwingWord(awing: 'aghə́glə', english: 'fear', category: 'things', difficulty: 2),

  // bible:MRK.1.6, freq=1, conf=0.08, alts: belt, around, clothed // needs review
  AwingWord(awing: 'kəmbôʼnkɔn', english: 'waist', category: 'things', difficulty: 1),
  // bible:MRK.1.7, freq=1, conf=0.10, alts: stoop, after, mightier // needs review
  AwingWord(awing: 'kwúʼnə', english: 'sandals', category: 'things', difficulty: 1),
  // bible:MRK.1.24, freq=1, conf=0.20, alts: nazarene
  AwingWord(awing: 'tseŋkə̂', english: 'destroy', category: 'things', difficulty: 1),
  // bible:MRK.1.32, freq=1, conf=0.14, alts: evening, sick, brought // needs review
  AwingWord(awing: 'ḿmɛ́d', english: 'possessed', category: 'actions', difficulty: 3),
  // bible:MRK.2.21, freq=1, conf=0.07, alts: shrinks, new, tears // needs review
  AwingWord(awing: 'fï', english: 'piece', category: 'descriptive', difficulty: 1),

  // bible:MRK.3.6, freq=1, conf=0.17, alts: herodians, pharisees, against
  AwingWord(awing: 'ńkwaŋtə̂', english: 'destroy', category: 'things', difficulty: 1),

  // bible:MRK.3.9, freq=1, conf=0.12, alts: near, wouldn, press // needs review
  AwingWord(awing: 'ńnwaalə̂', english: 'boat', category: 'actions', difficulty: 1),
  // bible:MRK.3.10, freq=1, conf=0.20, alts: pressed, healed, touch
  AwingWord(awing: 'ńchinə̂', english: 'diseases', category: 'actions', difficulty: 1),
  // bible:MRK.3.14, freq=1, conf=0.25, alts: send, appointed, preach
  AwingWord(awing: 'pəənə̈', english: 'twelve', category: 'actions', difficulty: 1),

  // bible:MRK.4.21, freq=1, conf=0.17, alts: lamp, basket, stand
  AwingWord(awing: 'atsɛ̂káŋ', english: 'bed', category: 'actions', difficulty: 1),
  // bible:MRK.4.28, freq=1, conf=0.12, alts: grain, fruit, first // needs review
  AwingWord(awing: 'akɔŋ', english: 'bears', category: 'nature', difficulty: 1),
  // bible:MRK.4.28, freq=1, conf=0.12, alts: grain, fruit, first // needs review
  AwingWord(awing: 'atsoʼə', english: 'bears', category: 'nature', difficulty: 1),
  // bible:MRK.4.38, freq=1, conf=0.11, alts: don, teacher, asleep // needs review
  AwingWord(awing: 'pilo', english: 'care', category: 'things', difficulty: 1),
  // bible:MRK.4.38, freq=1, conf=0.11, alts: don, teacher, asleep // needs review
  AwingWord(awing: 'kwág', english: 'care', category: 'things', difficulty: 1),
  // bible:MRK.5.1, freq=1, conf=0.25, alts: gadarenes, sea, country
  AwingWord(awing: 'Gɛlɛsen', english: 'side', category: 'nature', difficulty: 3),
  // bible:MRK.5.5, freq=1, conf=0.12, alts: mountains, crying, day // needs review
  AwingWord(awing: 'məngoŋ', english: 'tombs', category: 'things', difficulty: 1),
  // bible:MRK.5.5, freq=1, conf=0.12, alts: mountains, crying, day // needs review
  AwingWord(awing: 'ńkə́ʼtə', english: 'tombs', category: 'things', difficulty: 1),
  // bible:MRK.5.13, freq=1, conf=0.07, alts: drowned, thousand, spirits // needs review
  AwingWord(awing: 'ə́shwəənə̂', english: 'steep', category: 'numbers', difficulty: 1),

  // bible:MRK.5.23, freq=1, conf=0.09, alts: much, please, death // needs review
  AwingWord(awing: 'ngə́ŋ', english: 'healthy', category: 'things', difficulty: 1),
  // bible:MRK.5.24, freq=1, conf=0.17, alts: great, followed, sides
  AwingWord(awing: 'ńjwíʼnə', english: 'multitude', category: 'things', difficulty: 1),
  // bible:MRK.5.26, freq=1, conf=0.11, alts: rather, grew, spent // needs review
  AwingWord(awing: 'Ńtsaŋnə̂', english: 'suffered', category: 'things', difficulty: 3),
  // bible:MRK.5.26, freq=1, conf=0.11, alts: rather, grew, spent // needs review
  AwingWord(awing: 'pəlɔ́gta', english: 'suffered', category: 'things', difficulty: 1),

  // bible:MRK.5.41, freq=1, conf=0.12, alts: taking, cumi, means // needs review
  AwingWord(awing: 'kum', english: 'girl', category: 'things', difficulty: 1),

  // bible:MRK.6.26, freq=1, conf=0.10, alts: wish, oaths, king // needs review
  AwingWord(awing: 'Əfɛ̂nkǐ', english: 'sake', category: 'family', difficulty: 1),
  // bible:MRK.6.49, freq=1, conf=0.20, alts: supposed, walking, sea
  AwingWord(awing: 'məngoŋə', english: 'ghost', category: 'nature', difficulty: 1),
  // bible:MRK.7.4, freq=1, conf=0.07, alts: couches, unless, don // needs review
  AwingWord(awing: 'kɔ́pa', english: 'bronze', category: 'things', difficulty: 1),
  // bible:MRK.7.11, freq=1, conf=0.10, alts: profit, received, say // needs review
  AwingWord(awing: 'Kɔbanə', english: 'corban', category: 'things', difficulty: 3),
  // bible:MRK.7.22, freq=1, conf=0.10, alts: covetings, evil, desires // needs review
  AwingWord(awing: 'nəféŋə', english: 'pride', category: 'descriptive', difficulty: 1),
  // bible:MRK.7.30, freq=1, conf=0.12, alts: house, child, gone // needs review
  AwingWord(awing: 'ngyaʼ', english: 'away', category: 'family', difficulty: 1),

  // bible:MRK.7.33, freq=1, conf=0.12, alts: multitude, privately, ears // needs review
  AwingWord(awing: 'ńtwitə̂', english: 'spat', category: 'things', difficulty: 3),

  // bible:MRK.8.3, freq=1, conf=0.14, alts: away, long, home // needs review
  AwingWord(awing: 'məndi', english: 'fasting', category: 'things', difficulty: 2),

  // bible:MRK.8.25, freq=1, conf=0.12, alts: eyes, everyone, hands // needs review
  AwingWord(awing: 'ə́fóokə', english: 'restored', category: 'pronouns', difficulty: 1),

  // bible:MRK.9.18, freq=1, conf=0.08, alts: teeth, mouth, seizes // needs review
  AwingWord(awing: 'záʼkə', english: 'foams', category: 'body', difficulty: 1),
  // bible:MRK.9.25, freq=1, conf=0.08, alts: command, enter, rebuked // needs review
  AwingWord(awing: 'akə̌tû', english: 'multitude', category: 'things', difficulty: 1),
  // bible:MRK.10.20, freq=1, conf=0.25, alts: things, youth, observed
  AwingWord(awing: 'nkaŋŋwunə', english: 'teacher', category: 'things', difficulty: 1),
  // bible:MRK.10.33, freq=1, conf=0.08, alts: gentiles, man, behold // needs review
  AwingWord(awing: 'ə́lə́g', english: 'deliver', category: 'things', difficulty: 1),


  // bible:MRK.11.1, freq=1, conf=0.12, alts: sent, bethany, mount // needs review
  AwingWord(awing: 'Bɛlfasə', english: 'near', category: 'actions', difficulty: 3),
  // bible:MRK.11.8, freq=1, conf=0.11, alts: road, branches, trees // needs review
  AwingWord(awing: 'ə́fagtə̂', english: 'spreading', category: 'nature', difficulty: 1),
  // bible:MRK.11.8, freq=1, conf=0.11, alts: road, branches, trees // needs review
  AwingWord(awing: 'məŋnkáʼə', english: 'spreading', category: 'nature', difficulty: 1),
  // bible:MRK.11.11, freq=1, conf=0.11, alts: around, evening, twelve // needs review
  AwingWord(awing: 'Bɛtaniə', english: 'bethany', category: 'things', difficulty: 3),
  // bible:MRK.11.13, freq=1, conf=0.08, alts: figs, off, afar // needs review
  AwingWord(awing: 'pəfig', english: 'nothing', category: 'things', difficulty: 1),
  // bible:MRK.11.15, freq=1, conf=0.07, alts: tables, throw, sold // needs review
  AwingWord(awing: 'ngaŋə́kwúblə́nkéebə', english: 'money', category: 'actions', difficulty: 1),
  // bible:MRK.11.15, freq=1, conf=0.07, alts: tables, throw, sold // needs review
  AwingWord(awing: 'ngaŋə́finə́lúʼə', english: 'money', category: 'actions', difficulty: 1),
  // bible:MRK.11.21, freq=1, conf=0.12, alts: away, tree, remembering // needs review
  AwingWord(awing: 'ńdɔʼ', english: 'fig', category: 'nature', difficulty: 1),
  // bible:MRK.12.7, freq=1, conf=0.14, alts: kill, heir, among // needs review
  AwingWord(awing: 'ngaŋə́ləŋə́tɔʼ', english: 'themselves', category: 'actions', difficulty: 1),
  // bible:MRK.12.14, freq=1, conf=0.07, alts: taxes, don, defer // needs review
  AwingWord(awing: 'ngaŋəlɔʼ', english: 'honest', category: 'descriptive', difficulty: 2),
  // bible:MRK.13.1, freq=1, conf=0.17, alts: teacher, stones, disciples
  AwingWord(awing: 'əshwi', english: 'buildings', category: 'things', difficulty: 1),
  // bible:MRK.13.22, freq=1, conf=0.08, alts: chosen, even, possible // needs review
  AwingWord(awing: 'pənchwádkə', english: 'ones', category: 'things', difficulty: 1),
  // bible:MRK.14.3, freq=1, conf=0.07, alts: bethany, house, head // needs review
  AwingWord(awing: 'nad', english: 'broke', category: 'actions', difficulty: 1),
  // bible:MRK.14.20, freq=1, conf=0.25, alts: dips, dish, answered
  AwingWord(awing: 'ńtsɛnə̂', english: 'twelve', category: 'things', difficulty: 1),
  // bible:MRK.14.25, freq=1, conf=0.10, alts: anew, day, certainly // needs review
  AwingWord(awing: 'əfîfîə', english: 'drink', category: 'actions', difficulty: 1),
  // bible:MRK.14.32, freq=1, conf=0.17, alts: place, gethsemane, sit
  AwingWord(awing: 'Gɛtsɛmani', english: 'named', category: 'actions', difficulty: 3),
  // bible:MRK.14.47, freq=1, conf=0.09, alts: certain, off, servant // needs review
  AwingWord(awing: 'ńkə́ʼə', english: 'cut', category: 'family', difficulty: 1),
  // bible:MRK.14.51, freq=1, conf=0.07, alts: grabbed, man, followed // needs review
  AwingWord(awing: 'ńgwáatə', english: 'certain', category: 'things', difficulty: 1),
  // bible:MRK.14.68, freq=1, conf=0.14, alts: understand, crowed, neither // needs review
  AwingWord(awing: 'ńtɔ́ŋə', english: 'nor', category: 'things', difficulty: 1),

  // bible:MRK.15.17, freq=1, conf=0.20, alts: weaving, crown, clothed
  AwingWord(awing: 'ńtwíŋə', english: 'purple', category: 'things', difficulty: 1),
  // bible:MRK.15.19, freq=1, conf=0.14, alts: bowing, reed, head // needs review
  AwingWord(awing: 'ńtwǐəə', english: 'spat', category: 'body', difficulty: 3),

  // bible:MRK.15.23, freq=1, conf=0.17, alts: drink, myrrh, mixed
  AwingWord(awing: 'myl', english: 'wine', category: 'actions', difficulty: 1),
  // bible:MRK.16.20, freq=1, conf=0.11, alts: confirming, working, followed // needs review
  AwingWord(awing: 'ńgɛ̈n', english: 'everywhere', category: 'things', difficulty: 1),
  // bible:LUK.1.22, freq=1, conf=0.14, alts: remained, signs, vision // needs review
  AwingWord(awing: 'alə́ŋkə', english: 'continued', category: 'things', difficulty: 1),
  // bible:LUK.1.48, freq=1, conf=0.17, alts: behold, servant, state
  AwingWord(awing: 'mɔsɔŋə́', english: 'generations', category: 'family', difficulty: 1),
  // bible:LUK.1.63, freq=1, conf=0.17, alts: name, marveled, wrote
  AwingWord(awing: 'táafɛlə', english: 'tablet', category: 'things', difficulty: 1),
  // bible:LUK.1.64, freq=1, conf=0.14, alts: blessing, tongue, opened // needs review
  AwingWord(awing: 'ə́ghóʼkə', english: 'mouth', category: 'body', difficulty: 1),
  // bible:LUK.2.1, freq=1, conf=0.17, alts: world, augustus, enrolled
  AwingWord(awing: 'Ɔgɔstusə', english: 'decree', category: 'things', difficulty: 1),

  // bible:LUK.2.12, freq=1, conf=0.12, alts: trough, lying, sign // needs review
  AwingWord(awing: 'lə́m', english: 'feeding', category: 'things', difficulty: 1),
  // bible:LUK.2.36, freq=1, conf=0.07, alts: tribe, great, husband // needs review
  AwingWord(awing: 'fanuɛlə', english: 'prophetess', category: 'family', difficulty: 1),
  // bible:LUK.2.42, freq=1, conf=0.14, alts: twelve, feast, according // needs review
  AwingWord(awing: 'pěʼə̈', english: 'old', category: 'descriptive', difficulty: 1),





  // bible:LUK.3.5, freq=1, conf=0.08, alts: mountain, valley, rough // needs review
  AwingWord(awing: 'məghaʼtə', english: 'crooked', category: 'nature', difficulty: 1),
  // bible:LUK.3.5, freq=1, conf=0.08, alts: mountain, valley, rough // needs review
  AwingWord(awing: 'ŋɔ́dtə', english: 'crooked', category: 'nature', difficulty: 1),
  // bible:LUK.3.5, freq=1, conf=0.08, alts: mountain, valley, rough // needs review
  AwingWord(awing: 'əpɛ́d', english: 'crooked', category: 'nature', difficulty: 1),

































































  // bible:LUK.4.1, freq=1, conf=0.12, alts: jordan, wilderness, full // needs review
  AwingWord(awing: 'ntsǒnkǐ', english: 'led', category: 'nature', difficulty: 1),



  // bible:LUK.4.39, freq=1, conf=0.14, alts: left, rebuked, stood // needs review
  AwingWord(awing: 'tád', english: 'fever', category: 'things', difficulty: 1),
  // bible:LUK.4.42, freq=1, conf=0.12, alts: away, place, day // needs review
  AwingWord(awing: 'nkyakə̂', english: 'wouldn', category: 'things', difficulty: 1),
  // bible:LUK.5.2, freq=1, conf=0.14, alts: boats, fishermen, gone // needs review
  AwingWord(awing: 'akóolə́shû', english: 'lake', category: 'nature', difficulty: 1),
  // bible:LUK.5.6, freq=1, conf=0.17, alts: great, net, caught
  AwingWord(awing: 'ńdə́kə', english: 'multitude', category: 'things', difficulty: 1),
  // bible:LUK.5.7, freq=1, conf=0.11, alts: both, boats, filled // needs review
  AwingWord(awing: 'ńkɔ́mtə', english: 'boat', category: 'things', difficulty: 1),
  // bible:LUK.5.19, freq=1, conf=0.11, alts: multitude, tiles, bring // needs review
  AwingWord(awing: 'ḿbub', english: 'housetop', category: 'things', difficulty: 1),
  // bible:LUK.5.19, freq=1, conf=0.11, alts: multitude, tiles, bring // needs review
  AwingWord(awing: 'ndǎndǎ', english: 'housetop', category: 'things', difficulty: 1),
  // bible:LUK.5.19, freq=1, conf=0.11, alts: multitude, tiles, bring // needs review
  AwingWord(awing: 'apaʼə', english: 'housetop', category: 'things', difficulty: 1),
  // bible:LUK.5.27, freq=1, conf=0.11, alts: tax, follow, after // needs review
  AwingWord(awing: 'aliʼə́kwáalə́', english: 'named', category: 'actions', difficulty: 1),
  // bible:LUK.5.38, freq=1, conf=0.17, alts: both, new, preserved
  AwingWord(awing: 'pəkâʼlə̌', english: 'wine', category: 'food', difficulty: 1),
  // bible:LUK.5.38, freq=1, conf=0.17, alts: both, new, preserved
  AwingWord(awing: 'tog', english: 'wine', category: 'food', difficulty: 1),
  // bible:LUK.6.1, freq=1, conf=0.08, alts: grain, fields, sabbath // needs review
  AwingWord(awing: 'pyántə', english: 'rubbing', category: 'things', difficulty: 1),
  // bible:LUK.6.35, freq=1, conf=0.07, alts: enemies, nothing, back // needs review
  AwingWord(awing: 'ngǎŋsóomə', english: 'toward', category: 'body', difficulty: 1),
  // bible:LUK.6.44, freq=1, conf=0.07, alts: nor, don, fruit // needs review
  AwingWord(awing: 'mənkɨ́ŋkɨ́', english: 'figs', category: 'nature', difficulty: 1),
  // bible:LUK.7.4, freq=1, conf=0.25, alts: earnestly, begged
  AwingWord(awing: 'ńchíg', english: 'worthy', category: 'things', difficulty: 1),
  // bible:LUK.7.5, freq=1, conf=0.25, alts: loves, built, nation
  AwingWord(awing: 'aghóʼkə', english: 'synagogue', category: 'things', difficulty: 2),
  // bible:LUK.7.11, freq=1, conf=0.11, alts: great, nain, city // needs review
  AwingWord(awing: 'Nɛnə', english: 'multitude', category: 'things', difficulty: 3),
  // bible:LUK.7.17, freq=1, conf=0.17, alts: report, region, surrounding
  AwingWord(awing: 'ngaŋmə́peelə', english: 'concerning', category: 'things', difficulty: 1),
  // bible:LUK.7.25, freq=1, conf=0.09, alts: man, clothed, clothing // needs review
  AwingWord(awing: 'məntɔ́ʼə', english: 'behold', category: 'things', difficulty: 2),
  // bible:LUK.7.31, freq=1, conf=0.33, alts: people, liken
  AwingWord(awing: 'ə́fiʼkə̂', english: 'generation', category: 'things', difficulty: 1),
  // bible:LUK.7.32, freq=1, conf=0.12, alts: children, marketplace, weep // needs review
  AwingWord(awing: 'apɛ́nə́ndzɔ́ʼə́', english: 'dance', category: 'actions', difficulty: 1),

  // bible:LUK.7.38, freq=1, conf=0.08, alts: behind, head, kissed // needs review
  AwingWord(awing: 'ńnwáakə', english: 'tears', category: 'body', difficulty: 1),
  // bible:LUK.7.43, freq=1, conf=0.14, alts: forgave, most, answered // needs review
  AwingWord(awing: 'nəkyɛ́ɛlə', english: 'simon', category: 'things', difficulty: 1),


  // bible:LUK.8.5, freq=1, conf=0.08, alts: sowed, trampled, devoured // needs review
  AwingWord(awing: 'apǐəpúmə', english: 'fell', category: 'actions', difficulty: 1),
  // bible:LUK.8.5, freq=1, conf=0.08, alts: sowed, trampled, devoured // needs review
  AwingWord(awing: 'ḿbyántə', english: 'fell', category: 'actions', difficulty: 1),

  // bible:LUK.8.33, freq=1, conf=0.10, alts: lake, drowned, man // needs review
  AwingWord(awing: 'məndə̌', english: 'steep', category: 'nature', difficulty: 1),
  // bible:LUK.8.36, freq=1, conf=0.33, alts: healed
  AwingWord(awing: 'ńdǎa', english: 'possessed', category: 'things', difficulty: 3),

  // bible:LUK.8.47, freq=1, conf=0.08, alts: presence, declared, woman // needs review
  AwingWord(awing: 'ə́fɛ̈d', english: 'trembling', category: 'things', difficulty: 1),
  // bible:LUK.9.17, freq=1, conf=0.12, alts: baskets, twelve, filled // needs review
  AwingWord(awing: 'lag', english: 'left', category: 'actions', difficulty: 1),
  // bible:LUK.9.17, freq=1, conf=0.12, alts: baskets, twelve, filled // needs review
  AwingWord(awing: 'pəkyíbə́', english: 'left', category: 'actions', difficulty: 1),
  // bible:LUK.9.39, freq=1, conf=0.09, alts: takes, suddenly, behold // needs review
  AwingWord(awing: 'fwɔʼkə̂', english: 'foams', category: 'things', difficulty: 1),
  // bible:LUK.9.39, freq=1, conf=0.09, alts: takes, suddenly, behold // needs review
  AwingWord(awing: 'nuʼə̂', english: 'foams', category: 'things', difficulty: 1),
  // bible:LUK.9.41, freq=1, conf=0.11, alts: perverse, answered, generation // needs review
  AwingWord(awing: 'ə́fə́ŋkə', english: 'long', category: 'things', difficulty: 1),
  // bible:LUK.9.41, freq=1, conf=0.11, alts: perverse, answered, generation // needs review
  AwingWord(awing: 'ə́wam', english: 'long', category: 'things', difficulty: 1),
  // bible:LUK.9.62, freq=1, conf=0.11, alts: plow, back, fit // needs review
  AwingWord(awing: 'asóolə', english: 'looking', category: 'body', difficulty: 1),
  // bible:LUK.10.13, freq=1, conf=0.08, alts: works, ashes, repented // needs review
  AwingWord(awing: 'kɔ́g', english: 'woe', category: 'nature', difficulty: 1),
  // bible:LUK.10.13, freq=1, conf=0.08, alts: works, ashes, repented // needs review
  AwingWord(awing: 'pəshíshí', english: 'woe', category: 'nature', difficulty: 1),
  // bible:LUK.10.19, freq=1, conf=0.10, alts: hurt, authority, behold // needs review
  AwingWord(awing: 'pəmə́ŋgâsê', english: 'nothing', category: 'actions', difficulty: 1),
  // bible:LUK.10.34, freq=1, conf=0.09, alts: bound, oil, inn // needs review
  AwingWord(awing: 'afǔ', english: 'wine', category: 'food', difficulty: 1),
  // bible:LUK.11.7, freq=1, conf=0.11, alts: children, don, within // needs review
  AwingWord(awing: 'ə́fwɔn', english: 'bother', category: 'family', difficulty: 1),
  // bible:LUK.11.12, freq=1, conf=0.25, alts: won, asks, scorpion
  AwingWord(awing: 'nəpu', english: 'egg', category: 'animals', difficulty: 1),
  // bible:LUK.11.12, freq=1, conf=0.25, alts: won, asks, scorpion
  AwingWord(awing: 'ngə́b', english: 'egg', category: 'animals', difficulty: 1),
  // bible:LUK.11.24, freq=1, conf=0.07, alts: none, dry, man // needs review
  AwingWord(awing: 'pəjǔbtə', english: 'back', category: 'body', difficulty: 1),
  // bible:LUK.11.31, freq=1, conf=0.07, alts: behold, earth, judgment // needs review
  AwingWord(awing: 'ə́zóʼ', english: 'rise', category: 'actions', difficulty: 1),
  // bible:LUK.11.33, freq=1, conf=0.17, alts: lamp, basket, stand
  AwingWord(awing: 'məkwuʼ', english: 'lit', category: 'actions', difficulty: 1),
  // bible:LUK.11.33, freq=1, conf=0.17, alts: lamp, basket, stand
  AwingWord(awing: 'atiʼə', english: 'lit', category: 'actions', difficulty: 1),
  // bible:LUK.11.39, freq=1, conf=0.09, alts: cup, platter, inward // needs review
  AwingWord(awing: 'məndzəm', english: 'cleanse', category: 'things', difficulty: 1),
  // bible:LUK.11.39, freq=1, conf=0.09, alts: cup, platter, inward // needs review
  AwingWord(awing: 'awaaməńkwáalə́', english: 'cleanse', category: 'things', difficulty: 1),

  // bible:LUK.12.24, freq=1, conf=0.08, alts: feeds, don, valuable // needs review
  AwingWord(awing: 'alɔʼkə', english: 'warehouse', category: 'things', difficulty: 1),
  // bible:LUK.12.27, freq=1, conf=0.09, alts: don, spin, arrayed // needs review
  AwingWord(awing: 'pəflǎwa', english: 'toil', category: 'things', difficulty: 1),
  // bible:LUK.12.27, freq=1, conf=0.09, alts: don, spin, arrayed // needs review
  AwingWord(awing: 'ḿbáʼə', english: 'toil', category: 'things', difficulty: 1),
  // bible:LUK.12.35, freq=1, conf=0.25, alts: dressed, waist, lamps
  AwingWord(awing: 'ətwíŋ', english: 'burning', category: 'things', difficulty: 1),
  // bible:LUK.12.37, freq=1, conf=0.09, alts: certainly, recline, most // needs review
  AwingWord(awing: 'twéetə', english: 'servants', category: 'things', difficulty: 2),
  // bible:LUK.12.53, freq=1, conf=0.14, alts: mother, divided, against // needs review
  AwingWord(awing: 'pəmə́pɨ́', english: 'law', category: 'family', difficulty: 1),
  // bible:LUK.12.55, freq=1, conf=0.14, alts: say, blows, heat // needs review
  AwingWord(awing: 'ńgwəg', english: 'wind', category: 'nature', difficulty: 1),
  // bible:LUK.12.58, freq=1, conf=0.07, alts: adversary, deliver, magistrate // needs review
  AwingWord(awing: 'alaŋə́sêndúmə', english: 'judge', category: 'things', difficulty: 1),
  // bible:LUK.13.8, freq=1, conf=0.11, alts: alone, around, until // needs review
  AwingWord(awing: 'ə́líblə', english: 'dig', category: 'things', difficulty: 1),
  // bible:LUK.13.8, freq=1, conf=0.11, alts: alone, around, until // needs review
  AwingWord(awing: 'sɔləfâ', english: 'dig', category: 'things', difficulty: 1),
  // bible:LUK.13.11, freq=1, conf=0.10, alts: infirmity, herself, behold // needs review
  AwingWord(awing: 'ŋ́ŋɔ́dnə', english: 'eighteen', category: 'pronouns', difficulty: 1),
  // bible:LUK.13.15, freq=1, conf=0.08, alts: doesn, stall, away // needs review
  AwingWord(awing: 'məfwɔŋ', english: 'water', category: 'nature', difficulty: 1),
  // bible:LUK.13.15, freq=1, conf=0.08, alts: doesn, stall, away // needs review
  AwingWord(awing: 'mənjakásə', english: 'water', category: 'nature', difficulty: 1),
  // bible:LUK.13.21, freq=1, conf=0.14, alts: until, leavened, woman // needs review
  AwingWord(awing: 'flǎa', english: 'hid', category: 'actions', difficulty: 1),
  // bible:LUK.13.25, freq=1, conf=0.07, alts: don, master, house // needs review
  AwingWord(awing: 'ntsǒndɛ̈', english: 'begin', category: 'family', difficulty: 1),
  // bible:LUK.13.26, freq=1, conf=0.14, alts: drank, presence, say // needs review
  AwingWord(awing: 'ńnônə', english: 'begin', category: 'food', difficulty: 1),
  // bible:LUK.13.30, freq=1, conf=0.33, alts: behold, first
  AwingWord(awing: 'nkwâmbiə', english: 'last', category: 'numbers', difficulty: 1),
  // bible:LUK.13.32, freq=1, conf=0.08, alts: complete, tomorrow, third // needs review
  AwingWord(awing: 'antsɔb', english: 'mission', category: 'numbers', difficulty: 1),
  // bible:LUK.14.9, freq=1, conf=0.12, alts: begin, room, place // needs review
  AwingWord(awing: 'mɔ́kə́nyaŋə́', english: 'both', category: 'things', difficulty: 1),
  // bible:LUK.14.13, freq=1, conf=0.20, alts: maimed, poor, feast
  AwingWord(awing: 'pəkə́neʼə́ntéemə', english: 'lame', category: 'descriptive', difficulty: 1),
  // bible:LUK.14.19, freq=1, conf=0.14, alts: try, yoke, please // needs review
  AwingWord(awing: 'alíʼə́líʼə', english: 'oxen', category: 'things', difficulty: 1),
  // bible:LUK.14.21, freq=1, conf=0.07, alts: lame, master, house // needs review
  AwingWord(awing: 'kə́neʼə́ntá', english: 'quickly', category: 'family', difficulty: 1),
  // bible:LUK.14.23, freq=1, conf=0.14, alts: compel, house, servant // needs review
  AwingWord(awing: 'alaŋə́ndú', english: 'highways', category: 'family', difficulty: 1),
  // bible:LUK.14.23, freq=1, conf=0.14, alts: compel, house, servant // needs review
  AwingWord(awing: 'pəfyaalə́', english: 'highways', category: 'family', difficulty: 1),
  // bible:LUK.14.24, freq=1, conf=0.20, alts: supper, taste, invited
  AwingWord(awing: 'aliʼə́jíəpú', english: 'none', category: 'things', difficulty: 1),
  // bible:LUK.14.35, freq=1, conf=0.11, alts: soil, fit, pile // needs review
  AwingWord(awing: 'manyɔ̂', english: 'nor', category: 'things', difficulty: 1),
  // bible:LUK.16.3, freq=1, conf=0.07, alts: dig, within, don // needs review
  AwingWord(awing: 'lɔ́nə', english: 'taking', category: 'things', difficulty: 1),
  // bible:LUK.16.5, freq=1, conf=0.17, alts: first, owe, each
  AwingWord(awing: 'məkyɛ́', english: 'much', category: 'numbers', difficulty: 1),
  // bible:LUK.16.6, freq=1, conf=0.12, alts: quickly, write, oil // needs review
  AwingWord(awing: 'Məŋkag', english: 'hundred', category: 'actions', difficulty: 3),
  // bible:LUK.16.6, freq=1, conf=0.12, alts: quickly, write, oil // needs review
  AwingWord(awing: 'məzaŋ', english: 'hundred', category: 'actions', difficulty: 1),
  // bible:LUK.16.19, freq=1, conf=0.10, alts: luxury, fine, purple // needs review
  AwingWord(awing: 'nkéebə̈', english: 'living', category: 'things', difficulty: 1),
  // bible:LUK.16.24, freq=1, conf=0.07, alts: mercy, dip, water // needs review
  AwingWord(awing: 'tsɛn', english: 'flame', category: 'nature', difficulty: 1),
  // bible:LUK.17.2, freq=1, conf=0.08, alts: rather, ones, around // needs review
  AwingWord(awing: 'aghɔʼə́púmə', english: 'cause', category: 'things', difficulty: 1),
  // bible:LUK.17.15, freq=1, conf=0.14, alts: loud, glorifying, healed // needs review
  AwingWord(awing: 'apəənənəndzə̈m', english: 'back', category: 'body', difficulty: 1),
  // bible:LUK.17.23, freq=1, conf=0.20, alts: don, away, follow
  AwingWord(awing: 'ḿbúmə', english: 'nor', category: 'actions', difficulty: 1),
  // bible:LUK.17.27, freq=1, conf=0.09, alts: marriage, day, until // needs review
  AwingWord(awing: 'məndzɔʼə́', english: 'drank', category: 'actions', difficulty: 1),
  // bible:LUK.18.2, freq=1, conf=0.12, alts: judge, certain, respect // needs review
  AwingWord(awing: 'anü', english: 'fear', category: 'things', difficulty: 2),
  // bible:LUK.18.3, freq=1, conf=0.20, alts: often, widow, city
  AwingWord(awing: 'ńdzä', english: 'adversary', category: 'things', difficulty: 1),
  // bible:LUK.18.11, freq=1, conf=0.07, alts: extortionists, tax, even // needs review
  AwingWord(awing: 'pəwaaməńkwáalə́', english: 'adulterers', category: 'things', difficulty: 1),
  // bible:LUK.18.25, freq=1, conf=0.11, alts: man, enter, camel // needs review
  AwingWord(awing: 'atɛ̂tsəʼ', english: 'easier', category: 'animals', difficulty: 1),
  // bible:LUK.18.36, freq=1, conf=0.25, alts: multitude, hearing, going
  AwingWord(awing: 'kwəŋnə̂', english: 'meant', category: 'things', difficulty: 1),

  // bible:LUK.19.8, freq=1, conf=0.07, alts: goods, behold, zacchaeus // needs review
  AwingWord(awing: 'ə́jábtə', english: 'exacted', category: 'things', difficulty: 1),
  // bible:LUK.19.23, freq=1, conf=0.14, alts: interest, deposit, coming // needs review
  AwingWord(awing: 'nəlɔʼkə', english: 'money', category: 'things', difficulty: 1),

  // bible:LUK.19.33, freq=1, conf=0.25, alts: colt, its, untying
  AwingWord(awing: 'ŋwúlə́', english: 'owners', category: 'things', difficulty: 1),
  // bible:LUK.19.43, freq=1, conf=0.12, alts: surround, barricade, side // needs review
  AwingWord(awing: 'tsélə', english: 'enemies', category: 'things', difficulty: 1),
  // bible:LUK.20.17, freq=1, conf=0.14, alts: same, chief, rejected // needs review
  AwingWord(awing: 'ngaŋə́póomə', english: 'cornerstone', category: 'family', difficulty: 1),
  // bible:LUK.20.31, freq=1, conf=0.17, alts: children, third, died
  AwingWord(awing: 'azoŋ', english: 'left', category: 'actions', difficulty: 1),
  // bible:LUK.20.43, freq=1, conf=0.25, alts: feet, footstool, until
  AwingWord(awing: 'nətəgnə́', english: 'enemies', category: 'things', difficulty: 1),
  // bible:LUK.20.46, freq=1, conf=0.08, alts: long, feasts, synagogues // needs review
  AwingWord(awing: 'ələŋ', english: 'robes', category: 'things', difficulty: 1),
  // bible:LUK.21.6, freq=1, conf=0.20, alts: things, days, thrown
  AwingWord(awing: 'ńdzámnə', english: 'left', category: 'actions', difficulty: 1),
  // bible:LUK.21.20, freq=1, conf=0.17, alts: hand, desolation, armies
  AwingWord(awing: 'ngaŋə́maʼə̂', english: 'surrounded', category: 'body', difficulty: 1),
  // bible:LUK.21.23, freq=1, conf=0.10, alts: pregnant, great, nurse // needs review
  AwingWord(awing: 'pəmə́puə', english: 'woe', category: 'things', difficulty: 1),
  // bible:LUK.21.25, freq=1, conf=0.09, alts: sea, stars, waves // needs review
  AwingWord(awing: 'Əkyeʼ', english: 'moon', category: 'nature', difficulty: 1),
  // bible:LUK.21.25, freq=1, conf=0.09, alts: sea, stars, waves // needs review
  AwingWord(awing: 'ə́zoolə̂', english: 'moon', category: 'nature', difficulty: 1),
  // bible:LUK.22.12, freq=1, conf=0.17, alts: preparations, large, show
  AwingWord(awing: 'ajábtə́ndɛ̂', english: 'room', category: 'actions', difficulty: 1),
  // bible:LUK.22.25, freq=1, conf=0.20, alts: kings, nations, benefactors
  AwingWord(awing: 'pəkwá', english: 'authority', category: 'things', difficulty: 1),
  // bible:LUK.22.44, freq=1, conf=0.10, alts: blood, became, drops // needs review
  AwingWord(awing: 'ńchɨ́mkə', english: 'great', category: 'things', difficulty: 1),
  // bible:LUK.22.54, freq=1, conf=0.10, alts: seized, away, followed // needs review
  AwingWord(awing: 'chwaŋə', english: 'led', category: 'things', difficulty: 1),
  // bible:LUK.23.10, freq=1, conf=0.17, alts: chief, vehemently, accusing
  AwingWord(awing: 'ńtɛ́nə', english: 'priests', category: 'family', difficulty: 3),
  // bible:LUK.23.33, freq=1, conf=0.17, alts: right, left, criminals
  AwingWord(awing: 'Aghaglə́tûə', english: 'crucified', category: 'descriptive', difficulty: 3),
  // bible:LUK.23.41, freq=1, conf=0.12, alts: nothing, man, justly // needs review
  AwingWord(awing: 'əghɔ̂', english: 'receive', category: 'things', difficulty: 1),
  // bible:LUK.23.54, freq=1, conf=0.20, alts: day, sabbath, preparation
  AwingWord(awing: 'achwíʼtə', english: 'near', category: 'things', difficulty: 1),
  // bible:LUK.24.5, freq=1, conf=0.11, alts: seek, bowed, becoming // needs review
  AwingWord(awing: 'ńkwúʼtə', english: 'living', category: 'things', difficulty: 1),
  // bible:LUK.24.13, freq=1, conf=0.11, alts: day, behold, village // needs review
  AwingWord(awing: 'Emɔsə', english: 'named', category: 'things', difficulty: 3),


  // bible:LUK.24.25, freq=1, conf=0.17, alts: prophets, foolish, heart
  AwingWord(awing: 'ńdyə́ənə', english: 'believe', category: 'actions', difficulty: 1),
  // bible:LUK.24.38, freq=1, conf=0.25, alts: troubled, hearts, arise
  AwingWord(awing: 'Áwɨ̈', english: 'doubts', category: 'things', difficulty: 3),
  // bible:JHN.1.39, freq=1, conf=0.17, alts: day, tenth, stayed
  AwingWord(awing: 'ńjwég', english: 'hour', category: 'things', difficulty: 1),




  // bible:JHN.4.6, freq=1, conf=0.11, alts: hour, sixth, sat // needs review
  AwingWord(awing: 'ńkéenə', english: 'well', category: 'descriptive', difficulty: 1),
  // bible:JHN.4.15, freq=1, conf=0.12, alts: don, thirsty, sir // needs review
  AwingWord(awing: 'atóʼə́nkǐə', english: 'water', category: 'nature', difficulty: 1),

  // bible:JHN.5.2, freq=1, conf=0.11, alts: bethesda, five, hebrew // needs review
  AwingWord(awing: 'məkwuunə́', english: 'gate', category: 'numbers', difficulty: 1),
  // bible:JHN.5.3, freq=1, conf=0.10, alts: lame, great, water // needs review
  AwingWord(awing: 'pəkweglə', english: 'multitude', category: 'nature', difficulty: 1),
  // bible:JHN.5.13, freq=1, conf=0.17, alts: place, healed, didn
  AwingWord(awing: 'ə́sóotə', english: 'withdrawn', category: 'things', difficulty: 1),
  // bible:JHN.5.18, freq=1, conf=0.09, alts: jews, broke, equal // needs review
  AwingWord(awing: 'pələŋə́', english: 'cause', category: 'things', difficulty: 1),
  // bible:JHN.6.12, freq=1, conf=0.12, alts: left, lost, filled // needs review
  AwingWord(awing: 'apag', english: 'nothing', category: 'things', difficulty: 1),
  // bible:JHN.6.19, freq=1, conf=0.08, alts: near, afraid, sea // needs review
  AwingWord(awing: 'Máyilə', english: 'boat', category: 'nature', difficulty: 3),

  // bible:JHN.7.12, freq=1, conf=0.10, alts: concerning, murmuring, man // needs review
  AwingWord(awing: 'Məntsəmə́', english: 'multitude', category: 'things', difficulty: 3),
  // bible:JHN.8.15, freq=1, conf=0.33, alts: judge, flesh
  AwingWord(awing: 'ŋwü', english: 'according', category: 'things', difficulty: 1),
  // bible:JHN.8.16, freq=1, conf=0.14, alts: alone, sent, even // needs review
  AwingWord(awing: 'ndə́gsáʼə', english: 'judge', category: 'actions', difficulty: 1),
  // bible:JHN.8.20, freq=1, conf=0.14, alts: hour, arrested, words // needs review
  AwingWord(awing: 'mənkwum', english: 'treasury', category: 'things', difficulty: 1),
  // bible:JHN.9.7, freq=1, conf=0.11, alts: sent, away, means // needs review
  AwingWord(awing: 'Silɔmə', english: 'back', category: 'actions', difficulty: 3),
  // bible:JHN.9.8, freq=1, conf=0.17, alts: before, blind, isn
  AwingWord(awing: 'Ngaŋmə́pad', english: 'begged', category: 'things', difficulty: 3),
  // bible:JHN.9.41, freq=1, conf=0.20, alts: say, blind
  AwingWord(awing: 'afankə́nu', english: 'remains', category: 'things', difficulty: 1),

  // bible:JHN.11.44, freq=1, conf=0.09, alts: wrappings, around, hand // needs review
  AwingWord(awing: 'lə́mtə', english: 'bound', category: 'body', difficulty: 1),
  // bible:JHN.11.54, freq=1, conf=0.08, alts: jews, wilderness, among // needs review
  AwingWord(awing: 'Ɛflɛm', english: 'near', category: 'nature', difficulty: 1),
  // bible:JHN.12.3, freq=1, conf=0.07, alts: pound, filled, precious // needs review
  AwingWord(awing: 'nalə', english: 'house', category: 'things', difficulty: 1),
  // bible:JHN.12.6, freq=1, conf=0.12, alts: cared, thief, steal // needs review
  AwingWord(awing: 'ńnyáʼtə', english: 'money', category: 'things', difficulty: 1),
  // bible:JHN.12.13, freq=1, conf=0.08, alts: branches, trees, palm // needs review
  AwingWord(awing: 'əzáŋ', english: 'king', category: 'family', difficulty: 1),
  // bible:JHN.13.5, freq=1, conf=0.09, alts: around, poured, wipe // needs review
  AwingWord(awing: 'ə́shígə', english: 'water', category: 'nature', difficulty: 1),
  // bible:JHN.13.26, freq=1, conf=0.11, alts: simon, answered, bread // needs review
  AwingWord(awing: 'tsɛnə̂', english: 'piece', category: 'food', difficulty: 1),
  // bible:JHN.13.26, freq=1, conf=0.11, alts: simon, answered, bread // needs review
  AwingWord(awing: 'ńtsɛn', english: 'piece', category: 'food', difficulty: 1),
  // bible:JHN.14.2, freq=1, conf=0.12, alts: house, place, homes // needs review
  AwingWord(awing: 'ətɔ́g', english: 'weren', category: 'things', difficulty: 1),
  // bible:JHN.15.15, freq=1, conf=0.12, alts: doesn, longer, servant // needs review
  AwingWord(awing: 'pɛ́lə̈', english: 'servants', category: 'family', difficulty: 2),
  // bible:JHN.16.1, freq=1, conf=0.25, alts: caused, wouldn, things
  AwingWord(awing: 'nəndzəmə', english: 'stumble', category: 'things', difficulty: 1),
  // bible:JHN.18.1, freq=1, conf=0.14, alts: words, garden, entered // needs review
  AwingWord(awing: 'tə́chwáŋ', english: 'brook', category: 'actions', difficulty: 1),
  // bible:JHN.18.1, freq=1, conf=0.14, alts: words, garden, entered // needs review
  AwingWord(awing: 'Kidlɔnə', english: 'brook', category: 'actions', difficulty: 3),
  // bible:JHN.18.3, freq=1, conf=0.09, alts: priests, chief, weapons // needs review
  AwingWord(awing: 'pətɔsəlamə', english: 'detachment', category: 'family', difficulty: 1),
  // bible:JHN.18.10, freq=1, conf=0.07, alts: right, off, malchus // needs review
  AwingWord(awing: 'ə́sɔŋə̂', english: 'cut', category: 'descriptive', difficulty: 1),

  // bible:JHN.18.28, freq=1, conf=0.09, alts: passover, caiaphas, themselves // needs review
  AwingWord(awing: 'tadkə̂', english: 'led', category: 'pronouns', difficulty: 1),


  // bible:JHN.19.23, freq=1, conf=0.07, alts: soldier, woven, parts // needs review
  AwingWord(awing: 'nətsɛ̂', english: 'crucified', category: 'things', difficulty: 3),

  // bible:JHN.19.31, freq=1, conf=0.08, alts: jews, cross, away // needs review
  AwingWord(awing: 'Atyáŋtə́pú', english: 'wouldn', category: 'things', difficulty: 3),
  // bible:JHN.19.33, freq=1, conf=0.17, alts: already, legs, didn
  AwingWord(awing: 'pə́ʼtə', english: 'break', category: 'actions', difficulty: 1),
  // bible:JHN.19.34, freq=1, conf=0.12, alts: blood, side, spear // needs review
  AwingWord(awing: 'nəkɔŋ', english: 'water', category: 'nature', difficulty: 1),
  // bible:JHN.19.36, freq=1, conf=0.17, alts: bone, happened, things
  AwingWord(awing: 'akwəŋə́', english: 'scripture', category: 'body', difficulty: 2),
  // bible:JHN.19.39, freq=1, conf=0.08, alts: hundred, roman, first // needs review
  AwingWord(awing: 'aloyis', english: 'pounds', category: 'numbers', difficulty: 1),
  // bible:JHN.19.39, freq=1, conf=0.08, alts: hundred, roman, first // needs review
  AwingWord(awing: 'pəkilo', english: 'pounds', category: 'numbers', difficulty: 1),
  // bible:JHN.20.11, freq=1, conf=0.14, alts: wept, tomb, standing // needs review
  AwingWord(awing: 'ńdzəŋkə̂', english: 'stooped', category: 'actions', difficulty: 1),
  // bible:JHN.20.15, freq=1, conf=0.10, alts: carried, supposing, away // needs review
  AwingWord(awing: 'ndîʼpúmə', english: 'looking', category: 'things', difficulty: 1),

  // bible:JHN.20.22, freq=1, conf=0.25, alts: breathed
  AwingWord(awing: 'ńjwǐəə', english: 'receive', category: 'things', difficulty: 1),
  // bible:JHN.21.8, freq=1, conf=0.08, alts: hundred, cubits, dragging // needs review
  AwingWord(awing: 'pəmɛta', english: 'boat', category: 'numbers', difficulty: 1),
  // bible:JHN.21.9, freq=1, conf=0.17, alts: land, bread, fire
  AwingWord(awing: 'əsəg', english: 'fish', category: 'animals', difficulty: 1),
  // bible:JHN.21.11, freq=1, conf=0.07, alts: wasn, great, net // needs review
  AwingWord(awing: 'aŋkənúʼ', english: 'hundred', category: 'numbers', difficulty: 1),
  // bible:ACT.1.8, freq=1, conf=0.08, alts: parts, power, upon // needs review
  AwingWord(awing: 'məndwigtə', english: 'receive', category: 'things', difficulty: 1),
  // bible:ACT.1.10, freq=1, conf=0.12, alts: behold, white, clothing // needs review
  AwingWord(awing: 'pəfú', english: 'looking', category: 'descriptive', difficulty: 1),
  // bible:ACT.1.18, freq=1, conf=0.08, alts: obtained, man, open // needs review
  AwingWord(awing: 'atoŋə́tóŋə', english: 'headlong', category: 'actions', difficulty: 1),
  // bible:ACT.1.18, freq=1, conf=0.08, alts: obtained, man, open // needs review
  AwingWord(awing: 'shwegnə̂', english: 'headlong', category: 'actions', difficulty: 1),
  // bible:ACT.1.18, freq=1, conf=0.08, alts: obtained, man, open // needs review
  AwingWord(awing: 'mətô', english: 'headlong', category: 'actions', difficulty: 1),
  // bible:ACT.1.18, freq=1, conf=0.08, alts: obtained, man, open // needs review
  AwingWord(awing: 'túmnə', english: 'headlong', category: 'actions', difficulty: 1),







  // bible:ACT.2.10, freq=1, conf=0.08, alts: cyrene, both, jews // needs review
  AwingWord(awing: 'məmboʼ', english: 'phrygia', category: 'things', difficulty: 3),


  // bible:ACT.2.28, freq=1, conf=0.20, alts: life, ways, gladness
  AwingWord(awing: 'məsémə́ndú', english: 'presence', category: 'things', difficulty: 1),
  // bible:ACT.3.7, freq=1, conf=0.11, alts: right, raised, strength // needs review
  AwingWord(awing: 'mələʼtə́', english: 'received', category: 'descriptive', difficulty: 1),
  // bible:ACT.3.11, freq=1, conf=0.08, alts: wondering, man, held // needs review
  AwingWord(awing: 'ńtsə́ŋnə', english: 'lame', category: 'actions', difficulty: 1),
  // bible:ACT.3.17, freq=1, conf=0.33, alts: ignorance, brothers
  AwingWord(awing: 'təjîə', english: 'rulers', category: 'things', difficulty: 1),
  // bible:ACT.3.20, freq=1, conf=0.20, alts: before, ordained
  AwingWord(awing: 'ńtsəʼə̂', english: 'send', category: 'actions', difficulty: 1),
  // bible:ACT.3.24, freq=1, conf=0.17, alts: prophets, after, days
  AwingWord(awing: 'məŋkɨ', english: 'followed', category: 'actions', difficulty: 1),
  // bible:ACT.4.29, freq=1, conf=0.17, alts: servants, threats, grant
  AwingWord(awing: 'kag', english: 'boldness', category: 'things', difficulty: 1),
  // bible:ACT.4.34, freq=1, conf=0.09, alts: lands, among, neither // needs review
  AwingWord(awing: 'fintə̂', english: 'houses', category: 'things', difficulty: 1),

  // bible:ACT.5.15, freq=1, conf=0.09, alts: cots, mattresses, even // needs review
  AwingWord(awing: 'pəmə́ta', english: 'carried', category: 'actions', difficulty: 1),

  // bible:ACT.6.3, freq=1, conf=0.08, alts: appoint, good, seven // needs review
  AwingWord(awing: 'agheebə', english: 'report', category: 'descriptive', difficulty: 1),
  // bible:ACT.6.5, freq=1, conf=0.07, alts: multitude, man, words // needs review
  AwingWord(awing: 'Plokɔlɔs', english: 'prochorus', category: 'things', difficulty: 3),




  // bible:ACT.6.11, freq=1, conf=0.11, alts: blasphemous, words, secretly // needs review
  AwingWord(awing: 'atság', english: 'say', category: 'things', difficulty: 1),
  // bible:ACT.7.2, freq=1, conf=0.08, alts: fathers, mesopotamia, haran // needs review
  AwingWord(awing: 'məsopotemya', english: 'listen', category: 'actions', difficulty: 1),




  // bible:ACT.7.20, freq=1, conf=0.11, alts: nourished, house, months // needs review
  AwingWord(awing: 'ashwiə', english: 'handsome', category: 'things', difficulty: 1),
  // bible:ACT.7.20, freq=1, conf=0.11, alts: nourished, house, months // needs review
  AwingWord(awing: 'kóg', english: 'handsome', category: 'things', difficulty: 1),


  // bible:ACT.7.35, freq=1, conf=0.08, alts: both, judge, ruler // needs review
  AwingWord(awing: 'nəchuʼnə́', english: 'deliverer', category: 'family', difficulty: 1),
  // bible:ACT.7.41, freq=1, conf=0.12, alts: calf, brought, days // needs review
  AwingWord(awing: 'mbɛlə́lóʼə́', english: 'works', category: 'actions', difficulty: 1),






  // bible:ACT.9.1, freq=1, conf=0.11, alts: threats, against, high // needs review
  AwingWord(awing: 'ńkag', english: 'slaughter', category: 'things', difficulty: 3),
  // bible:ACT.9.7, freq=1, conf=0.14, alts: seeing, hearing, stood // needs review
  AwingWord(awing: 'naʼnə̂', english: 'sound', category: 'things', difficulty: 1),

  // bible:ACT.9.24, freq=1, conf=0.11, alts: kill, watched, became // needs review
  AwingWord(awing: 'ə́jwítə', english: 'both', category: 'actions', difficulty: 1),
  // bible:ACT.9.34, freq=1, conf=0.12, alts: bed, immediately, arose // needs review
  AwingWord(awing: 'sad', english: 'aeneas', category: 'things', difficulty: 1),




  // bible:ACT.10.7, freq=1, conf=0.11, alts: servants, continually, cornelius // needs review
  AwingWord(awing: 'soye', english: 'devout', category: 'things', difficulty: 1),
  // bible:ACT.10.10, freq=1, conf=0.14, alts: trance, became, desired // needs review
  AwingWord(awing: 'ńnáŋnə', english: 'fell', category: 'actions', difficulty: 1),
  // bible:ACT.10.11, freq=1, conf=0.10, alts: certain, great, container // needs review
  AwingWord(awing: 'aləpá', english: 'descending', category: 'things', difficulty: 1),
  // bible:ACT.10.11, freq=1, conf=0.10, alts: certain, great, container // needs review
  AwingWord(awing: 'məlwî', english: 'descending', category: 'things', difficulty: 1),
  // bible:ACT.10.14, freq=1, conf=0.17, alts: unclean, anything, eaten
  AwingWord(awing: 'Aléʼnə', english: 'common', category: 'food', difficulty: 3),
  // bible:ACT.11.19, freq=1, conf=0.07, alts: phoenicia, speaking, jews // needs review
  AwingWord(awing: 'ghɛnkə̂', english: 'scattered', category: 'actions', difficulty: 1),
  // bible:ACT.12.7, freq=1, conf=0.07, alts: chains, fell, shone // needs review
  AwingWord(awing: 'atûəmbeʼtə', english: 'quickly', category: 'descriptive', difficulty: 1),

  // bible:ACT.12.17, freq=1, conf=0.08, alts: place, hand, prison // needs review
  AwingWord(awing: 'jíʼtə', english: 'declared', category: 'body', difficulty: 1),
  // bible:ACT.12.20, freq=1, conf=0.07, alts: country, tyre, personal // needs review
  AwingWord(awing: 'Bəlastusə', english: 'having', category: 'things', difficulty: 3),








  // bible:ACT.13.9, freq=1, conf=0.14, alts: eyes, filled, saul // needs review
  AwingWord(awing: 'ngɔ̌dmə́g', english: 'fastened', category: 'things', difficulty: 1),
  // bible:ACT.13.20, freq=1, conf=0.17, alts: after, until, things
  AwingWord(awing: 'Samuɛlə', english: 'judges', category: 'things', difficulty: 3),


  // bible:ACT.13.50, freq=1, conf=0.07, alts: prominent, jews, stirred // needs review
  AwingWord(awing: 'tóotə', english: 'devout', category: 'things', difficulty: 1),
  // bible:ACT.14.10, freq=1, conf=0.14, alts: leaped, upright, stand // needs review
  AwingWord(awing: 'nyintə̂', english: 'loud', category: 'actions', difficulty: 1),

  // bible:ACT.14.13, freq=1, conf=0.08, alts: jupiter, whose, gates // needs review
  AwingWord(awing: 'pəfəlawa', english: 'oxen', category: 'things', difficulty: 1),
  // bible:ACT.14.22, freq=1, conf=0.09, alts: afflictions, enter, continue // needs review
  AwingWord(awing: 'ḿbóʼtə́mbô', english: 'confirming', category: 'things', difficulty: 1),

  // bible:ACT.15.7, freq=1, conf=0.07, alts: mouth, good, much // needs review
  AwingWord(awing: 'twiʼ', english: 'believe', category: 'actions', difficulty: 1),

  // bible:ACT.15.20, freq=1, conf=0.12, alts: blood, idols, immorality // needs review
  AwingWord(awing: 'zɔ́ʼnə', english: 'write', category: 'actions', difficulty: 1),


  // bible:ACT.15.24, freq=1, conf=0.14, alts: unsettling, commandment, souls // needs review
  AwingWord(awing: 'ndzeʼkə̈', english: 'law', category: 'things', difficulty: 1),









  // bible:ACT.16.14, freq=1, conf=0.07, alts: seller, purple, named // needs review
  AwingWord(awing: 'ntâŋməteenə́', english: 'listen', category: 'actions', difficulty: 1),
  // bible:ACT.16.14, freq=1, conf=0.07, alts: seller, purple, named // needs review
  AwingWord(awing: 'dya', english: 'listen', category: 'actions', difficulty: 1),
  // bible:ACT.16.15, freq=1, conf=0.11, alts: faithful, household, house // needs review
  AwingWord(awing: 'pəteenə́', english: 'persuaded', category: 'things', difficulty: 2),
  // bible:ACT.16.17, freq=1, conf=0.09, alts: salvation, following, most // needs review
  AwingWord(awing: 'ńtïʼ', english: 'servants', category: 'things', difficulty: 2),
  // bible:ACT.16.21, freq=1, conf=0.17, alts: romans, customs, advocate
  AwingWord(awing: 'Pəlomanə', english: 'lawful', category: 'descriptive', difficulty: 3),
  // bible:ACT.16.24, freq=1, conf=0.11, alts: prison, threw, secured // needs review
  AwingWord(awing: 'kəpoʼə', english: 'command', category: 'things', difficulty: 1),
  // bible:ACT.16.27, freq=1, conf=0.07, alts: supposing, doors, kill // needs review
  AwingWord(awing: 'ńkəəkə̂', english: 'jailer', category: 'actions', difficulty: 2),




  // bible:ACT.17.7, freq=1, conf=0.12, alts: king, decrees, act // needs review
  AwingWord(awing: 'Jasɛnə', english: 'contrary', category: 'family', difficulty: 3),
  // bible:ACT.17.15, freq=1, conf=0.09, alts: escorted, timothy, commandment // needs review
  AwingWord(awing: 'ḿbinkə̂', english: 'quickly', category: 'descriptive', difficulty: 1),
  // bible:ACT.17.17, freq=1, conf=0.12, alts: jews, marketplace, synagogue // needs review
  AwingWord(awing: 'əlětsəm', english: 'devout', category: 'things', difficulty: 1),

  // bible:ACT.17.18, freq=1, conf=0.07, alts: say, resurrection, babbler // needs review
  AwingWord(awing: 'Pəsətɔyik', english: 'deities', category: 'things', difficulty: 3),
  // bible:ACT.17.26, freq=1, conf=0.08, alts: appointed, blood, seasons // needs review
  AwingWord(awing: 'məndɛlə́', english: 'boundaries', category: 'things', difficulty: 1),
  // bible:ACT.17.26, freq=1, conf=0.08, alts: appointed, blood, seasons // needs review
  AwingWord(awing: 'məndɛdtə', english: 'boundaries', category: 'things', difficulty: 1),
  // bible:ACT.17.28, freq=1, conf=0.20, alts: own, move, live
  AwingWord(awing: 'nchîmbîəʼ', english: 'offspring', category: 'things', difficulty: 1),



  // bible:ACT.18.3, freq=1, conf=0.14, alts: same, practiced, tent // needs review
  AwingWord(awing: 'əpǎgtsəʼ', english: 'worked', category: 'things', difficulty: 1),




  // bible:ACT.18.11, freq=1, conf=0.12, alts: months, among, year // needs review
  AwingWord(awing: 'akəmə̈', english: 'six', category: 'numbers', difficulty: 1),




  // bible:ACT.19.4, freq=1, conf=0.11, alts: repentance, after, people // needs review
  AwingWord(awing: 'póobə̈', english: 'believe', category: 'actions', difficulty: 1),
  // bible:ACT.19.6, freq=1, conf=0.14, alts: prophesied, hands, laid // needs review
  AwingWord(awing: 'pəfîə̈', english: 'languages', category: 'things', difficulty: 1),
  // bible:ACT.19.8, freq=1, conf=0.08, alts: persuading, synagogue, months // needs review
  AwingWord(awing: 'teelə̈', english: 'concerning', category: 'things', difficulty: 1),


  // bible:ACT.19.16, freq=1, conf=0.09, alts: man, house, overpowered // needs review
  AwingWord(awing: 'məfəŋə́', english: 'evil', category: 'descriptive', difficulty: 3),
  // bible:ACT.19.24, freq=1, conf=0.08, alts: silver, named, certain // needs review
  AwingWord(awing: 'ntwîəleemə', english: 'demetrius', category: 'things', difficulty: 1),
  // bible:ACT.19.28, freq=1, conf=0.17, alts: ephesians, filled, anger
  AwingWord(awing: 'atǐə̈', english: 'great', category: 'things', difficulty: 1),

  // bible:ACT.19.33, freq=1, conf=0.11, alts: jews, defense, hand // needs review
  AwingWord(awing: 'ńjíʼtə', english: 'multitude', category: 'body', difficulty: 1),
  // bible:ACT.19.33, freq=1, conf=0.11, alts: jews, defense, hand // needs review
  AwingWord(awing: 'twágtə', english: 'multitude', category: 'body', difficulty: 1),
  // bible:ACT.19.34, freq=1, conf=0.10, alts: ephesians, time, voice // needs review
  AwingWord(awing: 'Atɛmisə', english: 'great', category: 'things', difficulty: 3),
  // bible:ACT.19.38, freq=1, conf=0.10, alts: craftsmen, open, press // needs review
  AwingWord(awing: 'Dɛmətiosə', english: 'demetrius', category: 'actions', difficulty: 3),





  // bible:ACT.20.9, freq=1, conf=0.07, alts: fell, named, certain // needs review
  AwingWord(awing: 'Utikɔsə', english: 'weighed', category: 'actions', difficulty: 3),
  // bible:ACT.20.9, freq=1, conf=0.07, alts: fell, named, certain // needs review
  AwingWord(awing: 'ajweekə', english: 'weighed', category: 'actions', difficulty: 1),
  // bible:ACT.20.10, freq=1, conf=0.14, alts: life, don, embracing // needs review
  AwingWord(awing: 'ŋ́ŋwúʼnə', english: 'fell', category: 'actions', difficulty: 1),






  // bible:ACT.20.16, freq=1, conf=0.08, alts: possible, day, pentecost // needs review
  AwingWord(awing: 'Pɛntekɔs', english: 'past', category: 'things', difficulty: 3),

  // bible:ACT.20.35, freq=1, conf=0.08, alts: example, remember, help // needs review
  AwingWord(awing: 'fɛ̈', english: 'receive', category: 'actions', difficulty: 1),




  // bible:ACT.21.5, freq=1, conf=0.08, alts: children, city, beach // needs review
  AwingWord(awing: 'ntsǒnkǐə', english: 'until', category: 'family', difficulty: 1),

  // bible:ACT.21.13, freq=1, conf=0.08, alts: doing, die, name // needs review
  AwingWord(awing: 'akə̈', english: 'bound', category: 'things', difficulty: 1),
  // bible:ACT.21.15, freq=1, conf=0.25, alts: baggage, days
  AwingWord(awing: 'əpə́g', english: 'after', category: 'things', difficulty: 1),
  // bible:ACT.21.15, freq=1, conf=0.25, alts: baggage, days
  AwingWord(awing: 'əpə́gə́', english: 'after', category: 'things', difficulty: 1),


  // bible:ACT.21.23, freq=1, conf=0.33, alts: men, four
  AwingWord(awing: 'lɔ̈', english: 'vow', category: 'numbers', difficulty: 1),
  // bible:ACT.21.26, freq=1, conf=0.07, alts: declaring, purification, day // needs review
  AwingWord(awing: 'məsog', english: 'next', category: 'things', difficulty: 1),
  // bible:ACT.21.27, freq=1, conf=0.09, alts: jews, stirred, completed // needs review
  AwingWord(awing: 'asogə́mbɨ', english: 'multitude', category: 'things', difficulty: 1),
  // bible:ACT.21.28, freq=1, conf=0.07, alts: crying, teaches, man // needs review
  AwingWord(awing: 'ńtadkə̂', english: 'everywhere', category: 'things', difficulty: 1),

  // bible:ACT.21.30, freq=1, conf=0.08, alts: dragged, doors, ran // needs review
  AwingWord(awing: 'wuʼtə̂', english: 'seized', category: 'actions', difficulty: 1),
  // bible:ACT.21.37, freq=1, conf=0.14, alts: commanding, greek, brought // needs review
  AwingWord(awing: 'kwúnkə', english: 'officer', category: 'actions', difficulty: 2),
  // bible:ACT.21.38, freq=1, conf=0.08, alts: stirred, thousand, wilderness // needs review
  AwingWord(awing: 'pəməkizâ', english: 'led', category: 'nature', difficulty: 1),


  // bible:ACT.22.11, freq=1, conf=0.17, alts: damascus, hand, couldn
  AwingWord(awing: 'ə́fəkə̂', english: 'led', category: 'body', difficulty: 1),
  // bible:ACT.22.23, freq=1, conf=0.17, alts: air, threw, dust
  AwingWord(awing: 'ḿmegtə̂', english: 'off', category: 'nature', difficulty: 1),
  // bible:ACT.22.23, freq=1, conf=0.17, alts: air, threw, dust
  AwingWord(awing: 'nchwáʼə', english: 'off', category: 'nature', difficulty: 1),
  // bible:ACT.22.29, freq=1, conf=0.10, alts: afraid, officer, realized // needs review
  AwingWord(awing: 'shwiʼtə̂', english: 'bound', category: 'descriptive', difficulty: 1),

  // bible:ACT.23.23, freq=1, conf=0.07, alts: seventy, armed, third // needs review
  AwingWord(awing: 'ngaŋə́kəələlə́əmə́', english: 'hundred', category: 'numbers', difficulty: 1),
  // bible:ACT.23.23, freq=1, conf=0.07, alts: seventy, armed, third // needs review
  AwingWord(awing: 'ngaŋə́maʼənə́kɔŋ', english: 'hundred', category: 'numbers', difficulty: 1),


  // bible:ACT.23.30, freq=1, conf=0.08, alts: jews, sent, wait // needs review
  AwingWord(awing: 'ńtyáŋ', english: 'accusers', category: 'actions', difficulty: 1),

  // bible:ACT.24.2, freq=1, conf=0.09, alts: enjoy, prosperity, much // needs review
  AwingWord(awing: 'ə́sag', english: 'accuse', category: 'things', difficulty: 1),


  // bible:ACT.24.26, freq=1, conf=0.12, alts: often, sent, talked // needs review
  AwingWord(awing: 'jíʼ', english: 'money', category: 'actions', difficulty: 1),

  // bible:ACT.24.27, freq=1, conf=0.08, alts: jews, bonds, left // needs review
  AwingWord(awing: 'ńgɔ́ŋkə', english: 'gain', category: 'things', difficulty: 1),
  // bible:ACT.26.14, freq=1, conf=0.09, alts: kick, language, hebrew // needs review
  AwingWord(awing: 'aliʼə́líʼ', english: 'persecuting', category: 'things', difficulty: 2),










  // bible:ACT.27.12, freq=1, conf=0.07, alts: southeast, majority, haven // needs review
  AwingWord(awing: 'Fɔniksə', english: 'looking', category: 'things', difficulty: 3),

  // bible:ACT.27.13, freq=1, conf=0.07, alts: weighed, shore, supposing // needs review
  AwingWord(awing: 'ḿbɔ́ʼnə', english: 'wind', category: 'nature', difficulty: 1),
  // bible:ACT.27.14, freq=1, conf=0.14, alts: shore, long, euroclydon // needs review
  AwingWord(awing: 'Ɛsta', english: 'wind', category: 'nature', difficulty: 1),


  // bible:ACT.27.30, freq=1, conf=0.09, alts: anchors, bow, sailors // needs review
  AwingWord(awing: 'póŋkə', english: 'boat', category: 'things', difficulty: 1),
  // bible:ACT.27.44, freq=1, conf=0.12, alts: safely, follow, rest // needs review
  AwingWord(awing: 'plaŋ', english: 'planks', category: 'actions', difficulty: 1),
  // bible:ACT.28.2, freq=1, conf=0.10, alts: rain, kindness, cold // needs review
  AwingWord(awing: 'ńnyagtə̂', english: 'kindled', category: 'nature', difficulty: 1),
  // bible:ACT.28.2, freq=1, conf=0.10, alts: rain, kindness, cold // needs review
  AwingWord(awing: 'zɔ́gə', english: 'kindled', category: 'nature', difficulty: 1),
  // bible:ACT.28.4, freq=1, conf=0.08, alts: justice, allowed, doubt // needs review
  AwingWord(awing: 'tsə́ŋnə', english: 'murderer', category: 'things', difficulty: 3),
  // bible:ACT.28.5, freq=1, conf=0.14, alts: wasn, off, creature // needs review
  AwingWord(awing: 'megə̂', english: 'harmed', category: 'things', difficulty: 1),





  // bible:ACT.28.20, freq=1, conf=0.20, alts: bound, chain, hope
  AwingWord(awing: 'feenə́', english: 'cause', category: 'things', difficulty: 1),
  // bible:ROM.1.12, freq=1, conf=0.17, alts: mine, encouraged, yours
  AwingWord(awing: 'əghéemə', english: 'both', category: 'things', difficulty: 1),
  // bible:ROM.1.31, freq=1, conf=0.12, alts: unforgiving, unmerciful, natural // needs review
  AwingWord(awing: 'zəŋtə̂', english: 'breakers', category: 'things', difficulty: 1),
  // bible:ROM.2.22, freq=1, conf=0.11, alts: say, man, temples // needs review
  AwingWord(awing: 'pəŋweŋ', english: 'rob', category: 'things', difficulty: 1),

  // bible:ROM.3.13, freq=1, conf=0.11, alts: tongues, open, lips // needs review
  AwingWord(awing: 'ngəələ́', english: 'throat', category: 'actions', difficulty: 1),
  // bible:ROM.3.24, freq=1, conf=0.17, alts: freely, redemption
  AwingWord(awing: 'páʼə̈', english: 'justified', category: 'things', difficulty: 1),
  // bible:ROM.3.25, freq=1, conf=0.08, alts: blood, demonstration, righteousness // needs review
  AwingWord(awing: 'ńgwágnə', english: 'sent', category: 'actions', difficulty: 1),
  // bible:ROM.4.17, freq=1, conf=0.08, alts: life, gives, presence // needs review
  AwingWord(awing: 'ətúumbî', english: 'calls', category: 'things', difficulty: 1),
  // bible:ROM.5.2, freq=1, conf=0.12, alts: stand, rejoice, hope // needs review
  AwingWord(awing: 'ńjwə́ʼə', english: 'access', category: 'actions', difficulty: 1),
  // bible:ROM.6.13, freq=1, conf=0.10, alts: righteousness, alive, unrighteousness // needs review
  AwingWord(awing: 'əfanə', english: 'members', category: 'things', difficulty: 1),
  // bible:ROM.7.5, freq=1, conf=0.11, alts: sinful, law, passions // needs review
  AwingWord(awing: 'noŋkə̈', english: 'worked', category: 'things', difficulty: 1),
  // bible:ROM.7.15, freq=1, conf=0.20, alts: don, doing, practice
  AwingWord(awing: 'mɨ̈d', english: 'desire', category: 'things', difficulty: 1),
  // bible:ROM.8.26, freq=1, conf=0.08, alts: don, intercession, weaknesses // needs review
  AwingWord(awing: 'nɛ́dkə', english: 'same', category: 'things', difficulty: 1),
  // bible:ROM.8.36, freq=1, conf=0.11, alts: sake, long, even // needs review
  AwingWord(awing: 'wadtə̂', english: 'killed', category: 'actions', difficulty: 3),

  // bible:ROM.9.21, freq=1, conf=0.10, alts: right, same, honor // needs review
  AwingWord(awing: 'əlɔʼkə̂', english: 'lump', category: 'descriptive', difficulty: 1),
  // bible:ROM.9.28, freq=1, conf=0.12, alts: short, righteousness, finish // needs review
  AwingWord(awing: 'kwaʼ', english: 'cut', category: 'descriptive', difficulty: 1),
  // bible:ROM.10.12, freq=1, conf=0.14, alts: same, greek, rich // needs review
  AwingWord(awing: 'chwɛ́d', english: 'distinction', category: 'descriptive', difficulty: 1),
  // bible:ROM.10.17, freq=1, conf=0.20, alts: word, comes
  AwingWord(awing: 'mbimə̈', english: 'hearing', category: 'things', difficulty: 1),
  // bible:ROM.10.21, freq=1, conf=0.11, alts: long, contrary, day // needs review
  AwingWord(awing: 'ngaŋə́tyǎntə́tû', english: 'stretched', category: 'things', difficulty: 1),
  // bible:ROM.11.3, freq=1, conf=0.11, alts: life, left, alone // needs review
  AwingWord(awing: 'məpá', english: 'killed', category: 'actions', difficulty: 3),
  // bible:ROM.11.4, freq=1, conf=0.10, alts: thousand, knee, answer // needs review
  AwingWord(awing: 'pəpá', english: 'myself', category: 'actions', difficulty: 1),

  // bible:ROM.11.10, freq=1, conf=0.25, alts: eyes, darkened, bow
  AwingWord(awing: 'mənkadtə', english: 'back', category: 'body', difficulty: 1),


  // bible:ROM.11.22, freq=1, conf=0.11, alts: cut, fell, severity // needs review
  AwingWord(awing: 'tsə́gə', english: 'toward', category: 'things', difficulty: 1),
  // bible:ROM.11.24, freq=1, conf=0.08, alts: contrary, nature, good // needs review
  AwingWord(awing: 'pádkə', english: 'cut', category: 'descriptive', difficulty: 1),
  // bible:ROM.11.25, freq=1, conf=0.07, alts: desire, gentiles, don // needs review
  AwingWord(awing: 'jínuə', english: 'ignorant', category: 'things', difficulty: 1),
  // bible:ROM.11.30, freq=1, conf=0.14, alts: mercy, obtained, disobedient // needs review
  AwingWord(awing: 'tyantə́tûə', english: 'past', category: 'things', difficulty: 1),
  // bible:ROM.12.8, freq=1, conf=0.11, alts: mercy, exhorts, gives // needs review
  AwingWord(awing: 'ghɔnkə̂', english: 'generosity', category: 'things', difficulty: 1),
  // bible:ROM.12.11, freq=1, conf=0.17, alts: lagging, diligence, serving
  AwingWord(awing: 'ńdɔ́ŋnə', english: 'fervent', category: 'things', difficulty: 1),
  // bible:ROM.12.19, freq=1, conf=0.07, alts: don, beloved, place // needs review
  AwingWord(awing: 'ḿbəələ̂', english: 'seek', category: 'things', difficulty: 1),
  // bible:ROM.12.20, freq=1, conf=0.10, alts: thirsty, feed, doing // needs review
  AwingWord(awing: 'wummogə́', english: 'drink', category: 'actions', difficulty: 1),
  // bible:ROM.13.7, freq=1, conf=0.14, alts: respect, honor, customs // needs review
  AwingWord(awing: 'nkɔʼə́tû', english: 'taxes', category: 'things', difficulty: 1),
  // bible:ROM.14.7, freq=1, conf=0.25, alts: none, lives, dies
  AwingWord(awing: 'chïə', english: 'himself', category: 'pronouns', difficulty: 1),





  // bible:ROM.16.5, freq=1, conf=0.11, alts: beloved, house, fruits // needs review
  AwingWord(awing: 'Əpanetusə', english: 'greet', category: 'actions', difficulty: 1),







  // bible:ROM.16.11, freq=1, conf=0.17, alts: household, kinsman, narcissus
  AwingWord(awing: 'Ɛlɔdyon', english: 'greet', category: 'actions', difficulty: 1),














  // bible:ROM.16.16, freq=1, conf=0.20, alts: kiss, assemblies
  AwingWord(awing: 'ńchwigə̂', english: 'greet', category: 'actions', difficulty: 1),
  // bible:ROM.16.18, freq=1, conf=0.08, alts: don, smooth, serve // needs review
  AwingWord(awing: 'məpəm', english: 'flattering', category: 'actions', difficulty: 1),






  // bible:1CO.1.1, freq=1, conf=0.14, alts: brother // needs review
  AwingWord(awing: 'Sɔstenesə', english: 'sosthenes', category: 'family', difficulty: 3),
  // bible:1CO.1.11, freq=1, conf=0.14, alts: reported, household, among // needs review
  AwingWord(awing: 'kloe', english: 'concerning', category: 'things', difficulty: 1),


  // bible:1CO.1.27, freq=1, conf=0.11, alts: world, strong, foolish // needs review
  AwingWord(awing: 'ngaŋmə́təənə', english: 'shame', category: 'descriptive', difficulty: 1),
  // bible:1CO.1.28, freq=1, conf=0.12, alts: nothing, world, bring // needs review
  AwingWord(awing: 'ńkəŋkə̂', english: 'despised', category: 'things', difficulty: 1),
  // bible:1CO.2.4, freq=1, conf=0.11, alts: demonstration, words, power // needs review
  AwingWord(awing: 'ə̈fɛ̂', english: 'persuasive', category: 'things', difficulty: 1),

  // bible:1CO.3.10, freq=1, conf=0.08, alts: man, builds, builder // needs review
  AwingWord(awing: 'mbɔ̂ndɛ̂', english: 'master', category: 'family', difficulty: 1),
  // bible:1CO.3.15, freq=1, conf=0.12, alts: loss, man, himself // needs review
  AwingWord(awing: 'chúb', english: 'saved', category: 'actions', difficulty: 1),
  // bible:1CO.4.9, freq=1, conf=0.08, alts: angels, apostles, sentenced // needs review
  AwingWord(awing: 'aleŋnə', english: 'both', category: 'things', difficulty: 1),
  // bible:1CO.4.9, freq=1, conf=0.08, alts: angels, apostles, sentenced // needs review
  AwingWord(awing: 'nəkwaʼə', english: 'both', category: 'things', difficulty: 1),
  // bible:1CO.4.11, freq=1, conf=0.10, alts: certain, even, place // needs review
  AwingWord(awing: 'əsɛ̌kə', english: 'thirst', category: 'things', difficulty: 1),
  // bible:1CO.4.13, freq=1, conf=0.11, alts: even, world, until // needs review
  AwingWord(awing: 'nəkwɛdnə́', english: 'off', category: 'things', difficulty: 1),
  // bible:1CO.4.19, freq=1, conf=0.17, alts: shortly, power, puffed
  AwingWord(awing: 'ngaŋə́chánə', english: 'willing', category: 'things', difficulty: 1),
  // bible:1CO.5.10, freq=1, conf=0.12, alts: extortionists, sinners, world // needs review
  AwingWord(awing: 'pəkad', english: 'meaning', category: 'things', difficulty: 1),
  // bible:1CO.6.10, freq=1, conf=0.11, alts: inherit, slanderers, extortionists // needs review
  AwingWord(awing: 'əpɛ̌mə́loʼ', english: 'nor', category: 'things', difficulty: 1),
  // bible:1CO.6.10, freq=1, conf=0.11, alts: inherit, slanderers, extortionists // needs review
  AwingWord(awing: 'ngaŋmə́naŋ', english: 'nor', category: 'things', difficulty: 1),
  // bible:1CO.6.16, freq=1, conf=0.14, alts: don, says, become // needs review
  AwingWord(awing: 'njîəkwɛlə', english: 'joined', category: 'things', difficulty: 1),
  // bible:1CO.7.7, freq=1, conf=0.11, alts: wish, man, own // needs review
  AwingWord(awing: 'məmíə', english: 'gift', category: 'things', difficulty: 1),
  // bible:1CO.7.18, freq=1, conf=0.17, alts: uncircumcision, become, circumcised
  AwingWord(awing: 'alagə́', english: 'uncircumcised', category: 'things', difficulty: 1),
  // bible:1CO.7.21, freq=1, conf=0.14, alts: don, use, bondservant // needs review
  AwingWord(awing: 'shǎa', english: 'bother', category: 'things', difficulty: 1),
  // bible:1CO.8.4, freq=1, conf=0.11, alts: idols, world, sacrificed // needs review
  AwingWord(awing: 'ajíəmə́jî', english: 'concerning', category: 'things', difficulty: 1),
  // bible:1CO.9.7, freq=1, conf=0.07, alts: feeds, drink, soldier // needs review
  AwingWord(awing: 'nəta', english: 'plants', category: 'actions', difficulty: 1),
  // bible:1CO.9.7, freq=1, conf=0.07, alts: feeds, drink, soldier // needs review
  AwingWord(awing: 'mə́lég', english: 'plants', category: 'actions', difficulty: 1),
  // bible:1CO.9.15, freq=1, conf=0.09, alts: rather, none, write // needs review
  AwingWord(awing: 'aliʼə́nu', english: 'boasting', category: 'actions', difficulty: 1),
  // bible:1CO.9.24, freq=1, conf=0.17, alts: don, prize, run
  AwingWord(awing: 'mɨtə̂', english: 'race', category: 'things', difficulty: 1),
  // bible:1CO.9.25, freq=1, conf=0.09, alts: exercises, strives, control // needs review
  AwingWord(awing: 'mɛdkə̂', english: 'receive', category: 'things', difficulty: 1),
  // bible:1CO.9.26, freq=1, conf=0.20, alts: beating, fight, run
  AwingWord(awing: 'ngag', english: 'air', category: 'actions', difficulty: 1),
  // bible:1CO.9.27, freq=1, conf=0.10, alts: myself, means, after // needs review
  AwingWord(awing: 'nuʼ', english: 'submission', category: 'pronouns', difficulty: 1),

  // bible:1CO.11.1, freq=1, conf=0.33, alts: imitators
  AwingWord(awing: 'ńtə̈', english: 'even', category: 'things', difficulty: 1),
  // bible:1CO.12.28, freq=1, conf=0.07, alts: healings, gifts, apostles // needs review
  AwingWord(awing: 'ngaŋə́tsóʼə', english: 'languages', category: 'things', difficulty: 1),
  // bible:1CO.13.1, freq=1, conf=0.10, alts: angels, don, become // needs review
  AwingWord(awing: 'kwə́ŋ', english: 'languages', category: 'things', difficulty: 1),
  // bible:1CO.13.1, freq=1, conf=0.10, alts: angels, don, become // needs review
  AwingWord(awing: 'əpǒʼpóʼə́', english: 'languages', category: 'things', difficulty: 1),
  // bible:1CO.13.4, freq=1, conf=0.14, alts: doesn, patient, love // needs review
  AwingWord(awing: 'akɔnə́ndzɔʼ', english: 'envy', category: 'actions', difficulty: 1),
  // bible:1CO.13.5, freq=1, conf=0.08, alts: provoked, takes, doesn // needs review
  AwingWord(awing: 'aŋwɛ', english: 'itself', category: 'things', difficulty: 1),
  // bible:1CO.13.12, freq=1, conf=0.17, alts: mirror, even, part
  AwingWord(awing: 'məshîə', english: 'dimly', category: 'descriptive', difficulty: 1),
  // bible:1CO.14.7, freq=1, conf=0.07, alts: life, harp, even // needs review
  AwingWord(awing: 'jwǐə', english: 'distinction', category: 'things', difficulty: 1),
  // bible:1CO.14.7, freq=1, conf=0.07, alts: life, harp, even // needs review
  AwingWord(awing: 'fluto', english: 'distinction', category: 'things', difficulty: 1),
  // bible:1CO.14.7, freq=1, conf=0.07, alts: life, harp, even // needs review
  AwingWord(awing: 'ngyɛ', english: 'distinction', category: 'things', difficulty: 1),
  // bible:1CO.14.23, freq=1, conf=0.09, alts: assembled, say, won // needs review
  AwingWord(awing: 'əpɛ̌lə', english: 'languages', category: 'things', difficulty: 1),
  // bible:1CO.14.26, freq=1, conf=0.10, alts: psalm, language, interpretation // needs review
  AwingWord(awing: 'azoobə́nkǐə', english: 'revelation', category: 'things', difficulty: 1),
  // bible:1CO.14.28, freq=1, conf=0.20, alts: silent, interpreter, assembly
  AwingWord(awing: 'tyáaatə', english: 'himself', category: 'pronouns', difficulty: 1),
  // bible:1CO.15.31, freq=1, conf=0.14, alts: affirm, die, daily // needs review
  AwingWord(awing: 'kwɛnə̂', english: 'boasting', category: 'things', difficulty: 1),
  // bible:1CO.15.32, freq=1, conf=0.08, alts: profit, raised, tomorrow // needs review
  AwingWord(awing: 'məyeŋ', english: 'drink', category: 'actions', difficulty: 1),
  // bible:1CO.15.33, freq=1, conf=0.14, alts: evil, don, corrupt // needs review
  AwingWord(awing: 'əghɨ', english: 'morals', category: 'descriptive', difficulty: 1),
  // bible:1CO.15.43, freq=1, conf=0.17, alts: sown, power, weakness
  AwingWord(awing: 'shwad', english: 'raised', category: 'things', difficulty: 1),
  // bible:1CO.15.51, freq=1, conf=0.25, alts: behold, mystery, sleep
  AwingWord(awing: 'ə́kwúblə', english: 'changed', category: 'actions', difficulty: 1),
  // bible:1CO.15.52, freq=1, conf=0.10, alts: last, sound, trumpet // needs review
  AwingWord(awing: 'pə́btə', english: 'raised', category: 'things', difficulty: 1),
  // bible:1CO.15.54, freq=1, conf=0.09, alts: immortality, imperishable, become // needs review
  AwingWord(awing: 'ḿmǐəə', english: 'victory', category: 'things', difficulty: 1),
  // bible:1CO.16.1, freq=1, conf=0.14, alts: galatia, likewise, commanded // needs review
  AwingWord(awing: 'amaʼə́nkáb', english: 'concerning', category: 'things', difficulty: 1),

  // bible:1CO.16.12, freq=1, conf=0.12, alts: concerning, apollos, brother // needs review
  AwingWord(awing: 'ńtɛ́nkə', english: 'desire', category: 'family', difficulty: 1),
  // bible:1CO.16.12, freq=1, conf=0.12, alts: concerning, apollos, brother // needs review
  AwingWord(awing: 'ńgéenə', english: 'desire', category: 'family', difficulty: 1),
  // bible:1CO.16.13, freq=1, conf=0.17, alts: stand, strong, firm
  AwingWord(awing: 'atyǎŋtəntə́əmə', english: 'courageous', category: 'actions', difficulty: 1),


  // bible:1CO.16.18, freq=1, conf=0.25, alts: refreshed, acknowledge
  AwingWord(awing: 'ə́féŋtə', english: 'yours', category: 'things', difficulty: 1),


  // bible:2CO.3.18, freq=1, conf=0.09, alts: mirror, transformed, same // needs review
  AwingWord(awing: 'Wə́ələ̈', english: 'unveiled', category: 'things', difficulty: 3),
  // bible:2CO.4.2, freq=1, conf=0.07, alts: craftiness, nor, manifestation // needs review
  AwingWord(awing: 'píʼkə', english: 'sight', category: 'things', difficulty: 1),
  // bible:2CO.4.4, freq=1, conf=0.08, alts: good, world, minds // needs review
  AwingWord(awing: 'ajubə', english: 'blinded', category: 'descriptive', difficulty: 1),
  // bible:2CO.4.8, freq=1, conf=0.20, alts: perplexed, despair, pressed
  AwingWord(awing: 'ńjíʼ', english: 'side', category: 'things', difficulty: 1),
  // bible:2CO.4.15, freq=1, conf=0.10, alts: multiplied, abound, thanksgiving // needs review
  AwingWord(awing: 'əchaʼtə́sê', english: 'cause', category: 'things', difficulty: 1),
  // bible:2CO.4.15, freq=1, conf=0.10, alts: multiplied, abound, thanksgiving // needs review
  AwingWord(awing: 'ndǎmbôsê', english: 'cause', category: 'things', difficulty: 1),
  // bible:2CO.5.6, freq=1, conf=0.20, alts: home, body, absent
  AwingWord(awing: 'məndiə', english: 'confident', category: 'things', difficulty: 1),
  // bible:2CO.5.14, freq=1, conf=0.17, alts: died, constrains, love
  AwingWord(awing: 'tɛ́nkə', english: 'judge', category: 'actions', difficulty: 1),
  // bible:2CO.6.5, freq=1, conf=0.17, alts: riots, watchings, fastings
  AwingWord(awing: 'ə́sámkə', english: 'labors', category: 'things', difficulty: 1),
  // bible:2CO.6.14, freq=1, conf=0.11, alts: don, darkness, yoked // needs review
  AwingWord(awing: 'Pətəpǐsê', english: 'unequally', category: 'descriptive', difficulty: 3),
  // bible:2CO.6.14, freq=1, conf=0.11, alts: don, darkness, yoked // needs review
  AwingWord(awing: 'təbə̂', english: 'unequally', category: 'descriptive', difficulty: 1),
  // bible:2CO.7.5, freq=1, conf=0.10, alts: relief, even, macedonia // needs review
  AwingWord(awing: 'məndúmə', english: 'fear', category: 'things', difficulty: 2),
  // bible:2CO.7.5, freq=1, conf=0.10, alts: relief, even, macedonia // needs review
  AwingWord(awing: 'sáʼnə', english: 'fear', category: 'things', difficulty: 2),
  // bible:2CO.10.9, freq=1, conf=0.33, alts: letters, terrify
  AwingWord(awing: 'ghɔdkə̂', english: 'desire', category: 'things', difficulty: 1),
  // bible:2CO.10.15, freq=1, conf=0.07, alts: labors, sphere, proper // needs review
  AwingWord(awing: 'əzɨ̈', english: 'boasting', category: 'things', difficulty: 1),
  // bible:2CO.11.12, freq=1, conf=0.17, alts: desire, boast, off
  AwingWord(awing: 'ńtɨd', english: 'cut', category: 'things', difficulty: 1),
  // bible:2CO.11.20, freq=1, conf=0.09, alts: takes, bondage, man // needs review
  AwingWord(awing: 'ńdəb', english: 'captive', category: 'things', difficulty: 2),
  // bible:2CO.11.23, freq=1, conf=0.08, alts: servants, measure, often // needs review
  AwingWord(awing: 'ághóobə̈', english: 'labors', category: 'things', difficulty: 1),

  // bible:2CO.11.33, freq=1, conf=0.20, alts: basket, escaped, hands
  AwingWord(awing: 'ə́sóokə', english: 'wall', category: 'things', difficulty: 1),
  // bible:2CO.12.5, freq=1, conf=0.20, alts: behalf, weaknesses, except
  AwingWord(awing: 'əza', english: 'boast', category: 'things', difficulty: 1),
  // bible:2CO.12.7, freq=1, conf=0.09, alts: thorn, exceeding, greatness // needs review
  AwingWord(awing: 'ənyintú', english: 'exalted', category: 'things', difficulty: 1),
  // bible:2CO.12.8, freq=1, conf=0.17, alts: depart, begged, thing
  AwingWord(awing: 'zəənə̈', english: 'concerning', category: 'things', difficulty: 1),
  // bible:2CO.12.10, freq=1, conf=0.10, alts: persecutions, weaknesses, necessities // needs review
  AwingWord(awing: 'atsaŋnə', english: 'sake', category: 'things', difficulty: 1),
  // bible:2CO.12.11, freq=1, conf=0.09, alts: nothing, inferior, apostles // needs review
  AwingWord(awing: 'əliʼkə́taŋ', english: 'boasting', category: 'things', difficulty: 1),
  // bible:2CO.13.8, freq=1, conf=0.33, alts: against, truth
  AwingWord(awing: 'mənü', english: 'nothing', category: 'things', difficulty: 1),
  // bible:2CO.13.12, freq=1, conf=0.33, alts: kiss
  AwingWord(awing: 'mɨ̈', english: 'greet', category: 'actions', difficulty: 1),
  // bible:GAL.1.13, freq=1, conf=0.08, alts: past, jews, religion // needs review
  AwingWord(awing: 'ə́fǔəlóʼə', english: 'living', category: 'things', difficulty: 1),
  // bible:GAL.1.17, freq=1, conf=0.12, alts: damascus, apostles, away // needs review
  AwingWord(awing: 'Damakɔsə', english: 'nor', category: 'things', difficulty: 3),
  // bible:GAL.2.7, freq=1, conf=0.12, alts: even, contrary, good // needs review
  AwingWord(awing: 'afiʼtə́nkɨ', english: 'uncircumcised', category: 'descriptive', difficulty: 1),
  // bible:GAL.3.13, freq=1, conf=0.09, alts: law, become, hangs // needs review
  AwingWord(awing: 'lə́ŋ', english: 'curse', category: 'things', difficulty: 3),
  // bible:GAL.4.14, freq=1, conf=0.08, alts: nor, temptation, even // needs review
  AwingWord(awing: 'nyáŋkə', english: 'reject', category: 'things', difficulty: 1),
  // bible:GAL.5.15, freq=1, conf=0.20, alts: don, careful, devour
  AwingWord(awing: 'ḿbóg', english: 'consume', category: 'things', difficulty: 1),
  // bible:GAL.5.20, freq=1, conf=0.10, alts: idolatry, outbursts, divisions // needs review
  AwingWord(awing: 'ələəmə', english: 'rivalries', category: 'things', difficulty: 1),
  // bible:GAL.5.22, freq=1, conf=0.11, alts: patience, fruit, kindness // needs review
  AwingWord(awing: 'asəgə́ntə́əmə', english: 'joy', category: 'nature', difficulty: 1),
  // bible:GAL.6.4, freq=1, conf=0.10, alts: man, else, someone // needs review
  AwingWord(awing: 'ngɛdmə́nuə', english: 'boast', category: 'pronouns', difficulty: 1),
  // bible:GAL.6.5, freq=1, conf=0.20, alts: man, bear, each
  AwingWord(awing: 'twám', english: 'own', category: 'pronouns', difficulty: 1),
  // bible:GAL.6.17, freq=1, conf=0.12, alts: branded, body, bear // needs review
  AwingWord(awing: 'əlagə́', english: 'cause', category: 'things', difficulty: 1),
  // bible:EPH.3.8, freq=1, conf=0.12, alts: gentiles, least, unsearchable // needs review
  AwingWord(awing: 'afiʼə', english: 'preach', category: 'things', difficulty: 2),
  // bible:EPH.4.14, freq=1, conf=0.07, alts: back, carried, children // needs review
  AwingWord(awing: 'məŋɔ́dtə́', english: 'wind', category: 'body', difficulty: 1),
  // bible:EPH.4.16, freq=1, conf=0.07, alts: joint, working, individual // needs review
  AwingWord(awing: 'ńgwamnə̂', english: 'itself', category: 'things', difficulty: 1),
  // bible:EPH.4.16, freq=1, conf=0.07, alts: joint, working, individual // needs review
  AwingWord(awing: 'ńkɔŋnə̂', english: 'itself', category: 'things', difficulty: 1),
  // bible:EPH.4.30, freq=1, conf=0.12, alts: don, day, grieve // needs review
  AwingWord(awing: 'ńdeŋkə̂', english: 'sealed', category: 'things', difficulty: 1),
  // bible:EPH.4.31, freq=1, conf=0.14, alts: away, outcry, wrath // needs review
  AwingWord(awing: 'nəsɛnə́', english: 'bitterness', category: 'things', difficulty: 1),
  // bible:EPH.4.31, freq=1, conf=0.14, alts: away, outcry, wrath // needs review
  AwingWord(awing: 'ə́sáʼnə', english: 'bitterness', category: 'things', difficulty: 1),
  // bible:EPH.5.10, freq=1, conf=0.25, alts: well, proving
  AwingWord(awing: 'alóʼ', english: 'pleasing', category: 'descriptive', difficulty: 1),
  // bible:EPH.5.19, freq=1, conf=0.11, alts: songs, singing, hymns // needs review
  AwingWord(awing: 'pəsalms', english: 'speaking', category: 'things', difficulty: 1),
  // bible:EPH.5.27, freq=1, conf=0.09, alts: defect, wrinkle, himself // needs review
  AwingWord(awing: 'twíŋkə', english: 'gloriously', category: 'pronouns', difficulty: 1),
  // bible:EPH.5.33, freq=1, conf=0.11, alts: husband, even, respects // needs review
  AwingWord(awing: 'ńdə́əkə', english: 'nevertheless', category: 'family', difficulty: 1),
  // bible:EPH.6.2, freq=1, conf=0.17, alts: commandment, mother, first
  AwingWord(awing: 'Lə́əkə', english: 'honor', category: 'family', difficulty: 3),
  // bible:EPH.6.15, freq=1, conf=0.14, alts: news, preparation, peace // needs review
  AwingWord(awing: 'kád', english: 'good', category: 'descriptive', difficulty: 1),
  // bible:EPH.6.20, freq=1, conf=0.25, alts: ought, ambassador, boldly
  AwingWord(awing: 'ənyintúmə', english: 'chains', category: 'things', difficulty: 1),
  // bible:PHP.1.23, freq=1, conf=0.12, alts: dilemma, depart, better // needs review
  AwingWord(awing: 'soŋnə̂', english: 'desire', category: 'things', difficulty: 1),
  // bible:PHP.2.3, freq=1, conf=0.11, alts: nothing, rivalry, counting // needs review
  AwingWord(awing: 'əkad', english: 'conceit', category: 'things', difficulty: 1),
  // bible:PHP.2.15, freq=1, conf=0.07, alts: children, defect, lights // needs review
  AwingWord(awing: 'ajîəmbə̂glə́', english: 'crooked', category: 'family', difficulty: 1),
  // bible:PHP.2.19, freq=1, conf=0.12, alts: doing, timothy, send // needs review
  AwingWord(awing: 'apəələ', english: 'cheered', category: 'actions', difficulty: 1),

  // bible:PHP.2.27, freq=1, conf=0.17, alts: mercy, sick, nearly
  AwingWord(awing: 'məméemə', english: 'sorrow', category: 'descriptive', difficulty: 2),
  // bible:PHP.3.2, freq=1, conf=0.17, alts: evil, circumcision, false
  AwingWord(awing: 'kə́ʼtə', english: 'dogs', category: 'descriptive', difficulty: 1),
  // bible:PHP.3.8, freq=1, conf=0.07, alts: nothing, loss, gain // needs review
  AwingWord(awing: 'məkɔ́lə', english: 'suffered', category: 'things', difficulty: 1),
  // bible:PHP.3.21, freq=1, conf=0.08, alts: subject, even, working // needs review
  AwingWord(awing: 'apwɔ̌dkə', english: 'change', category: 'things', difficulty: 1),
  // bible:PHP.3.21, freq=1, conf=0.08, alts: subject, even, working // needs review
  AwingWord(awing: 'zɨ̈d', english: 'change', category: 'things', difficulty: 1),
  // bible:PHP.4.2, freq=1, conf=0.14, alts: euodia, exhort, way // needs review
  AwingWord(awing: 'Sɛnchə', english: 'same', category: 'things', difficulty: 3),
  // bible:PHP.4.3, freq=1, conf=0.07, alts: life, book, good // needs review
  AwingWord(awing: 'təb', english: 'labored', category: 'descriptive', difficulty: 1),
  // bible:PHP.4.3, freq=1, conf=0.07, alts: life, book, good // needs review
  AwingWord(awing: 'Klɛmɛn', english: 'labored', category: 'descriptive', difficulty: 3),
  // bible:PHP.4.3, freq=1, conf=0.07, alts: life, book, good // needs review
  AwingWord(awing: 'ńtəb', english: 'labored', category: 'descriptive', difficulty: 1),
  // bible:PHP.4.8, freq=1, conf=0.07, alts: lovely, virtue, report // needs review
  AwingWord(awing: 'ńtséʼə', english: 'honorable', category: 'things', difficulty: 1),

  // bible:PHP.4.18, freq=1, conf=0.07, alts: smelling, abound, filled // needs review
  AwingWord(awing: 'Ɛpafloditusə', english: 'well', category: 'descriptive', difficulty: 1),
  // bible:PHP.4.18, freq=1, conf=0.07, alts: smelling, abound, filled // needs review
  AwingWord(awing: 'lɨ', english: 'well', category: 'descriptive', difficulty: 1),

  // bible:COL.1.7, freq=1, conf=0.11, alts: behalf, even, beloved // needs review
  AwingWord(awing: 'Ɛpaflasə', english: 'faithful', category: 'descriptive', difficulty: 2),
  // bible:COL.1.22, freq=1, conf=0.10, alts: defect, body, death // needs review
  AwingWord(awing: 'təkɔntə', english: 'reconciled', category: 'things', difficulty: 1),
  // bible:COL.2.6, freq=1, conf=0.20, alts: received
  AwingWord(awing: 'əjɨ̌po', english: 'walk', category: 'actions', difficulty: 1),
  // bible:COL.2.11, freq=1, conf=0.12, alts: circumcised, body, hands // needs review
  AwingWord(awing: 'aghɛlətə́pɔŋ', english: 'off', category: 'things', difficulty: 1),
  // bible:COL.2.18, freq=1, conf=0.08, alts: angels, worshiping, vainly // needs review
  AwingWord(awing: 'jɨ̈', english: 'rob', category: 'things', difficulty: 1),
  // bible:COL.2.18, freq=1, conf=0.08, alts: angels, worshiping, vainly // needs review
  AwingWord(awing: 'lɨ́d', english: 'rob', category: 'things', difficulty: 1),
  // bible:COL.3.4, freq=1, conf=0.25, alts: life
  AwingWord(awing: 'ə́nɔd', english: 'revealed', category: 'things', difficulty: 1),
  // bible:COL.3.11, freq=1, conf=0.11, alts: bondservant, barbarian, uncircumcision // needs review
  AwingWord(awing: 'Əfɛ́ləné', english: 'scythian', category: 'things', difficulty: 1),
  // bible:COL.3.11, freq=1, conf=0.11, alts: bondservant, barbarian, uncircumcision // needs review
  AwingWord(awing: 'ətúmə́yéŋə́', english: 'scythian', category: 'things', difficulty: 1),
  // bible:COL.3.13, freq=1, conf=0.11, alts: man, even, forgave // needs review
  AwingWord(awing: 'əfankə', english: 'bearing', category: 'things', difficulty: 1),
  // bible:COL.3.16, freq=1, conf=0.07, alts: songs, singing, hymns // needs review
  AwingWord(awing: 'Zə́ʼkə', english: 'richly', category: 'descriptive', difficulty: 3),


  // bible:COL.4.12, freq=1, conf=0.10, alts: prayers, perfect, servant // needs review
  AwingWord(awing: 'Ɛpaflusə', english: 'complete', category: 'family', difficulty: 1),



  // bible:1TH.1.6, freq=1, conf=0.09, alts: affliction, became, imitators // needs review
  AwingWord(awing: 'ə́fiʼnə̂', english: 'joy', category: 'things', difficulty: 1),
  // bible:1TH.3.3, freq=1, conf=0.25, alts: appointed, moved, task
  AwingWord(awing: 'tsaŋnə̂', english: 'afflictions', category: 'things', difficulty: 2),
  // bible:1TH.5.3, freq=1, conf=0.10, alts: escape, woman, destruction // needs review
  AwingWord(awing: 'kaʼə', english: 'pregnant', category: 'things', difficulty: 1),
  // bible:1TH.5.14, freq=1, conf=0.09, alts: disorderly, encourage, patient // needs review
  AwingWord(awing: 'lɔ́ŋnə', english: 'toward', category: 'things', difficulty: 1),
  // bible:2TH.3.2, freq=1, conf=0.20, alts: delivered, unreasonable, men
  AwingWord(awing: 'ngǎŋntɨ́', english: 'evil', category: 'descriptive', difficulty: 3),
  // bible:2TH.3.5, freq=1, conf=0.14, alts: direct, love, perseverance // needs review
  AwingWord(awing: 'awaamə́ndzɔʼ', english: 'hearts', category: 'actions', difficulty: 1),
  // bible:2TH.3.14, freq=1, conf=0.11, alts: doesn, man, letter // needs review
  AwingWord(awing: 'zɨ̈', english: 'note', category: 'things', difficulty: 1),
  // bible:1TI.1.9, freq=1, conf=0.07, alts: lawless, murderers, mothers // needs review
  AwingWord(awing: 'ngaŋə́wuə', english: 'fathers', category: 'things', difficulty: 1),
  // bible:1TI.1.9, freq=1, conf=0.07, alts: lawless, murderers, mothers // needs review
  AwingWord(awing: 'pətəzóʼntə́gə́', english: 'fathers', category: 'things', difficulty: 1),
  // bible:1TI.1.9, freq=1, conf=0.07, alts: lawless, murderers, mothers // needs review
  AwingWord(awing: 'pətəpɔ́gsê', english: 'fathers', category: 'things', difficulty: 1),
  // bible:1TI.1.18, freq=1, conf=0.10, alts: timothy, child, wage // needs review
  AwingWord(awing: 'atéelə́pô', english: 'good', category: 'family', difficulty: 1),

  // bible:1TI.2.9, freq=1, conf=0.07, alts: themselves, propriety, pearls // needs review
  AwingWord(awing: 'ajíənü', english: 'same', category: 'pronouns', difficulty: 1),
  // bible:1TI.2.12, freq=1, conf=0.11, alts: don, authority, man // needs review
  AwingWord(awing: 'ńnaʼ', english: 'nor', category: 'things', difficulty: 1),
  // bible:1TI.3.2, freq=1, conf=0.09, alts: reproach, husband, good // needs review
  AwingWord(awing: 'atsóokə́ntə́əmə', english: 'modest', category: 'family', difficulty: 1),
  // bible:1TI.3.15, freq=1, conf=0.08, alts: themselves, wait, long // needs review
  AwingWord(awing: 'ntɔ̂ndɛ̂', english: 'living', category: 'actions', difficulty: 1),
  // bible:1TI.4.1, freq=1, conf=0.07, alts: paying, later, expressly // needs review
  AwingWord(awing: 'ńdzöŋ', english: 'doctrines', category: 'things', difficulty: 1),
  // bible:1TI.4.3, freq=1, conf=0.09, alts: believe, foods, commanding // needs review
  AwingWord(awing: 'piwɨ́', english: 'marriage', category: 'actions', difficulty: 1),
  // bible:1TI.4.10, freq=1, conf=0.08, alts: both, reproach, believe // needs review
  AwingWord(awing: 'təjwitə', english: 'living', category: 'actions', difficulty: 1),
  // bible:1TI.5.3, freq=1, conf=0.50, alts: honor
  AwingWord(awing: 'Pəkogə́', english: 'widows', category: 'things', difficulty: 3),
  // bible:1TI.5.11, freq=1, conf=0.11, alts: desire, younger, refuse // needs review
  AwingWord(awing: 'zogə', english: 'widows', category: 'things', difficulty: 1),
  // bible:1TI.6.4, freq=1, conf=0.08, alts: nothing, evil, obsessed // needs review
  AwingWord(awing: 'ə́fyaʼnə̂', english: 'envy', category: 'descriptive', difficulty: 1),
  // bible:1TI.6.9, freq=1, conf=0.08, alts: temptation, drown, lusts // needs review
  AwingWord(awing: 'ətéemə', english: 'ruin', category: 'things', difficulty: 1),
  // bible:1TI.6.9, freq=1, conf=0.08, alts: temptation, drown, lusts // needs review
  AwingWord(awing: 'pɨ̈d', english: 'ruin', category: 'things', difficulty: 1),
  // bible:1TI.6.15, freq=1, conf=0.10, alts: king, show, kings // needs review
  AwingWord(awing: 'pəmaʼpə́mbîə', english: 'ruler', category: 'actions', difficulty: 1),
  // bible:2TI.1.5, freq=1, conf=0.09, alts: persuaded, reminded, sincere // needs review
  AwingWord(awing: 'mǎpəmǎ', english: 'grandmother', category: 'family', difficulty: 1),


  // bible:2TI.1.12, freq=1, conf=0.09, alts: persuaded, committed, day // needs review
  AwingWord(awing: 'lánə̈', english: 'cause', category: 'things', difficulty: 1),
  // bible:2TI.1.15, freq=1, conf=0.20, alts: hermogenes, asia, turned
  AwingWord(awing: 'Figɛlusə', english: 'away', category: 'things', difficulty: 3),
  // bible:2TI.1.15, freq=1, conf=0.20, alts: hermogenes, asia, turned
  AwingWord(awing: 'Emogɛnɛsə', english: 'away', category: 'things', difficulty: 3),

  // bible:2TI.2.5, freq=1, conf=0.12, alts: competed, unless, anyone // needs review
  AwingWord(awing: 'nkəndə̌', english: 'competes', category: 'pronouns', difficulty: 1),



  // bible:2TI.2.19, freq=1, conf=0.08, alts: name, stands, names // needs review
  AwingWord(awing: 'achîəndɛ̂sê', english: 'depart', category: 'things', difficulty: 2),

  // bible:2TI.2.23, freq=1, conf=0.14, alts: generate, refuse, foolish // needs review
  AwingWord(awing: 'əzɔŋ', english: 'ignorant', category: 'descriptive', difficulty: 1),

  // bible:2TI.3.13, freq=1, conf=0.14, alts: evil, deceived, worse // needs review
  AwingWord(awing: 'ńchîə̈', english: 'deceiving', category: 'descriptive', difficulty: 1),
  // bible:2TI.3.16, freq=1, conf=0.11, alts: reproof, righteousness, profitable // needs review
  AwingWord(awing: 'ə́shitə̂', english: 'scripture', category: 'things', difficulty: 2),
  // bible:2TI.3.16, freq=1, conf=0.11, alts: reproof, righteousness, profitable // needs review
  AwingWord(awing: 'tə́ŋkə', english: 'scripture', category: 'things', difficulty: 2),
  // bible:2TI.4.10, freq=1, conf=0.09, alts: crescens, left, world // needs review
  AwingWord(awing: 'Kələsɛnə', english: 'loved', category: 'actions', difficulty: 3),



  // bible:2TI.4.15, freq=1, conf=0.25, alts: greatly, opposed, words
  AwingWord(awing: 'pəteenə̈', english: 'beware', category: 'things', difficulty: 1),






  // bible:TIT.1.5, freq=1, conf=0.09, alts: appoint, crete, order // needs review
  AwingWord(awing: 'Kəletə', english: 'left', category: 'actions', difficulty: 3),
  // bible:TIT.1.7, freq=1, conf=0.08, alts: angered, gain, steward // needs review
  AwingWord(awing: 'atsə́gə́ntə́əmə', english: 'wine', category: 'food', difficulty: 1),
  // bible:TIT.1.11, freq=1, conf=0.08, alts: sake, dishonest, mouths // needs review
  AwingWord(awing: 'naʼkə̂', english: 'gain', category: 'things', difficulty: 1),
  // bible:TIT.1.12, freq=1, conf=0.12, alts: evil, beasts, idle // needs review
  AwingWord(awing: 'Kəletansə', english: 'gluttons', category: 'descriptive', difficulty: 3),
  // bible:TIT.1.12, freq=1, conf=0.12, alts: evil, beasts, idle // needs review
  AwingWord(awing: 'pəlɔŋə̈', english: 'gluttons', category: 'descriptive', difficulty: 1),
  // bible:TIT.2.4, freq=1, conf=0.17, alts: children, young, love
  AwingWord(awing: 'ə́zéʼkə', english: 'train', category: 'actions', difficulty: 1),
  // bible:TIT.3.10, freq=1, conf=0.14, alts: man, after, first // needs review
  AwingWord(awing: 'əkwantə', english: 'factious', category: 'numbers', difficulty: 1),
  // bible:TIT.3.11, freq=1, conf=0.20, alts: condemned, self, knowing
  AwingWord(awing: 'ḿbəglə̂', english: 'perverted', category: 'things', difficulty: 3),





  // bible:TIT.3.14, freq=1, conf=0.12, alts: maintain, good, people // needs review
  AwingWord(awing: 'Pəpɛ́n', english: 'works', category: 'descriptive', difficulty: 3),

  // bible:HEB.2.10, freq=1, conf=0.10, alts: children, author, salvation // needs review
  AwingWord(awing: 'pɔ̂ŋkə̂', english: 'sufferings', category: 'family', difficulty: 2),
  // bible:HEB.2.15, freq=1, conf=0.17, alts: lifetime, deliver, subject
  AwingWord(awing: 'ntsə̈m', english: 'fear', category: 'things', difficulty: 2),
  // bible:HEB.4.12, freq=1, conf=0.07, alts: word, able, piercing // needs review
  AwingWord(awing: 'mənyɔ́ŋ', english: 'both', category: 'things', difficulty: 1),
  // bible:HEB.5.1, freq=1, conf=0.08, alts: offer, gifts, appointed // needs review
  AwingWord(awing: 'əghóobə̈', english: 'both', category: 'things', difficulty: 1),
  // bible:HEB.5.13, freq=1, conf=0.14, alts: righteousness, everyone, word // needs review
  AwingWord(awing: 'nɔ́ŋ', english: 'milk', category: 'food', difficulty: 1),
  // bible:HEB.6.1, freq=1, conf=0.07, alts: works, toward, laying // needs review
  AwingWord(awing: 'ńdáʼə̈', english: 'leaving', category: 'things', difficulty: 1),
  // bible:HEB.6.2, freq=1, conf=0.12, alts: eternal, resurrection, baptisms // needs review
  AwingWord(awing: 'mələ́g', english: 'laying', category: 'things', difficulty: 1),
  // bible:HEB.6.18, freq=1, conf=0.08, alts: impossible, hold, immutable // needs review
  AwingWord(awing: 'nəpab', english: 'lie', category: 'actions', difficulty: 1),
  // bible:HEB.6.19, freq=1, conf=0.11, alts: soul, within, steadfast // needs review
  AwingWord(awing: 'tə́əmə̈', english: 'both', category: 'things', difficulty: 1),
  // bible:HEB.7.1, freq=1, conf=0.08, alts: slaughter, king, most // needs review
  AwingWord(awing: 'salɛmə', english: 'returning', category: 'family', difficulty: 1),
  // bible:HEB.7.2, freq=1, conf=0.09, alts: part, righteousness, king // needs review
  AwingWord(awing: 'Mɛkisidɛ̈g', english: 'means', category: 'family', difficulty: 3),

  // bible:HEB.7.12, freq=1, conf=0.20, alts: changed, law, priesthood
  AwingWord(awing: 'lǎŋtə', english: 'change', category: 'things', difficulty: 1),
  // bible:HEB.7.26, freq=1, conf=0.10, alts: sinners, high, heavens // needs review
  AwingWord(awing: 'məpóolə', english: 'higher', category: 'things', difficulty: 1),
  // bible:HEB.8.3, freq=1, conf=0.11, alts: something, offer, gifts // needs review
  AwingWord(awing: 'pêsê', english: 'both', category: 'pronouns', difficulty: 1),
  // bible:HEB.9.4, freq=1, conf=0.07, alts: rod, manna, ark // needs review
  AwingWord(awing: 'ńdɔgə̈', english: 'holding', category: 'things', difficulty: 1),
  // bible:HEB.9.5, freq=1, conf=0.12, alts: mercy, seat, above // needs review
  AwingWord(awing: 'akə́pkə', english: 'detail', category: 'things', difficulty: 1),
  // bible:HEB.9.19, freq=1, conf=0.07, alts: both, water, wool // needs review
  AwingWord(awing: 'Nzdaŋə', english: 'itself', category: 'nature', difficulty: 3),
  // bible:HEB.9.19, freq=1, conf=0.07, alts: both, water, wool // needs review
  AwingWord(awing: 'yisɔb', english: 'itself', category: 'nature', difficulty: 1),
  // bible:HEB.10.2, freq=1, conf=0.10, alts: wouldn, worshipers, else // needs review
  AwingWord(awing: 'akóolə́sɨ́', english: 'having', category: 'things', difficulty: 1),
  // bible:HEB.10.11, freq=1, conf=0.10, alts: same, away, day // needs review
  AwingWord(awing: 'ə́fyaʼə̂', english: 'often', category: 'things', difficulty: 1),
  // bible:HEB.10.12, freq=1, conf=0.12, alts: right, forever, sat // needs review
  AwingWord(awing: 'nkóŋə', english: 'hand', category: 'body', difficulty: 1),
  // bible:HEB.10.26, freq=1, conf=0.11, alts: willfully, after, truth // needs review
  AwingWord(awing: 'məjînə̌', english: 'remains', category: 'things', difficulty: 1),
  // bible:HEB.11.9, freq=1, conf=0.08, alts: same, promise, land // needs review
  AwingWord(awing: 'məntaŋə́', english: 'tents', category: 'things', difficulty: 1),
  // bible:HEB.11.10, freq=1, conf=0.17, alts: whose, maker, builder
  AwingWord(awing: 'əchîndɛ̂', english: 'foundations', category: 'things', difficulty: 1),
  // bible:HEB.11.29, freq=1, conf=0.11, alts: passed, swallowed, land // needs review
  AwingWord(awing: 'ḿmɛ́dkə', english: 'dry', category: 'descriptive', difficulty: 1),



  // bible:HEB.11.33, freq=1, conf=0.10, alts: subdued, obtained, righteousness // needs review
  AwingWord(awing: 'tsɛ́d', english: 'worked', category: 'things', difficulty: 1),
  // bible:HEB.11.34, freq=1, conf=0.07, alts: sword, war, power // needs review
  AwingWord(awing: 'ḿbə́gtə', english: 'grew', category: 'actions', difficulty: 1),
  // bible:HEB.11.34, freq=1, conf=0.07, alts: sword, war, power // needs review
  AwingWord(awing: 'məmóg', english: 'grew', category: 'actions', difficulty: 1),
  // bible:HEB.11.34, freq=1, conf=0.07, alts: sword, war, power // needs review
  AwingWord(awing: 'apóʼnə', english: 'grew', category: 'actions', difficulty: 1),
  // bible:HEB.11.38, freq=1, conf=0.12, alts: mountains, world, holes // needs review
  AwingWord(awing: 'məsəgə́', english: 'wandering', category: 'things', difficulty: 1),
  // bible:HEB.11.38, freq=1, conf=0.12, alts: mountains, world, holes // needs review
  AwingWord(awing: 'ngaŋə́kəələ́', english: 'wandering', category: 'things', difficulty: 1),
  // bible:HEB.11.38, freq=1, conf=0.12, alts: mountains, world, holes // needs review
  AwingWord(awing: 'məngɔ́lə', english: 'wandering', category: 'things', difficulty: 1),
  // bible:HEB.11.39, freq=1, conf=0.17, alts: didn, testimony, having
  AwingWord(awing: 'ńtséʼ', english: 'receive', category: 'things', difficulty: 1),
  // bible:HEB.12.13, freq=1, conf=0.14, alts: lame, dislocated, paths // needs review
  AwingWord(awing: 'neʼ', english: 'rather', category: 'things', difficulty: 1),
  // bible:HEB.12.13, freq=1, conf=0.14, alts: lame, dislocated, paths // needs review
  AwingWord(awing: 'pə́ʼnə', english: 'rather', category: 'things', difficulty: 1),
  // bible:HEB.12.13, freq=1, conf=0.14, alts: lame, dislocated, paths // needs review
  AwingWord(awing: 'septuagen', english: 'rather', category: 'things', difficulty: 1),
  // bible:HEB.12.16, freq=1, conf=0.11, alts: sold, sexually, esau // needs review
  AwingWord(awing: 'akáŋə́mə́jîə', english: 'immoral', category: 'actions', difficulty: 3),

  // bible:HEB.12.27, freq=1, conf=0.14, alts: signifies, once, remain // needs review
  AwingWord(awing: 'ə́fógtə', english: 'phrase', category: 'things', difficulty: 1),
  // bible:HEB.13.3, freq=1, conf=0.14, alts: remember, bonds, since // needs review
  AwingWord(awing: 'nkáʼə́tsáŋə', english: 'bound', category: 'actions', difficulty: 1),
  // bible:HEB.13.5, freq=1, conf=0.11, alts: neither, love, things // needs review
  AwingWord(awing: 'akɔŋə́nkéebə', english: 'money', category: 'actions', difficulty: 1),
  // bible:HEB.13.10, freq=1, conf=0.17, alts: right, serve, eat
  AwingWord(awing: 'aliʼə́ghóʼkə́sê', english: 'tabernacle', category: 'actions', difficulty: 1),
  // bible:JAS.1.2, freq=1, conf=0.17, alts: temptations, count, various
  AwingWord(awing: 'pəpɔŋ', english: 'joy', category: 'things', difficulty: 1),
  // bible:JAS.1.11, freq=1, conf=0.07, alts: perishes, away, arises // needs review
  AwingWord(awing: 'ńkoonə̂', english: 'wind', category: 'nature', difficulty: 1),
  // bible:JAS.1.14, freq=1, conf=0.14, alts: away, lust, own // needs review
  AwingWord(awing: 'ə́soŋtə̂', english: 'tempted', category: 'things', difficulty: 2),
  // bible:JAS.1.27, freq=1, conf=0.08, alts: religion, affliction, world // needs review
  AwingWord(awing: 'pətǐ', english: 'widows', category: 'things', difficulty: 1),
  // bible:JAS.2.2, freq=1, conf=0.11, alts: ring, man, synagogue // needs review
  AwingWord(awing: 'əfə́m', english: 'fine', category: 'things', difficulty: 1),
  // bible:JAS.2.12, freq=1, conf=0.25, alts: freedom, men, law
  AwingWord(awing: 'ə́zoŋə̂', english: 'judged', category: 'things', difficulty: 1),
  // bible:JAS.2.16, freq=1, conf=0.11, alts: filled, good, warmed // needs review
  AwingWord(awing: 'ńdumtə̂', english: 'needs', category: 'descriptive', difficulty: 1),
  // bible:JAS.2.19, freq=1, conf=0.20, alts: believe, shudder
  AwingWord(awing: 'ńdzoŋə̈', english: 'well', category: 'actions', difficulty: 1),
  // bible:JAS.3.5, freq=1, conf=0.09, alts: great, boasts, spread // needs review
  AwingWord(awing: 'lyǎ', english: 'small', category: 'descriptive', difficulty: 1),
  // bible:JAS.3.7, freq=1, conf=0.11, alts: mankind, creeping, creature // needs review
  AwingWord(awing: 'məshûə', english: 'tamed', category: 'things', difficulty: 1),
  // bible:JAS.3.8, freq=1, conf=0.12, alts: full, deadly, nobody // needs review
  AwingWord(awing: 'ńdúnə', english: 'evil', category: 'descriptive', difficulty: 3),
  // bible:JAS.3.9, freq=1, conf=0.17, alts: bless, image, men
  AwingWord(awing: 'alɨ̈', english: 'curse', category: 'things', difficulty: 3),
  // bible:JAS.3.17, freq=1, conf=0.07, alts: mercy, good, peaceful // needs review
  AwingWord(awing: 'atóŋə́mbî', english: 'partiality', category: 'descriptive', difficulty: 1),
  // bible:JAS.3.18, freq=1, conf=0.25, alts: peace, sown, fruit
  AwingWord(awing: 'ngaŋə́kwɛlə̂', english: 'righteousness', category: 'nature', difficulty: 2),
  // bible:JAS.4.4, freq=1, conf=0.08, alts: adulterers, wants, don // needs review
  AwingWord(awing: 'Ngaŋə́jîəmə̂ghabə', english: 'toward', category: 'things', difficulty: 3),
  // bible:JAS.4.13, freq=1, conf=0.12, alts: tomorrow, say, today // needs review
  AwingWord(awing: 'táŋə', english: 'profit', category: 'things', difficulty: 1),
  // bible:JAS.5.7, freq=1, conf=0.07, alts: waits, behold, until // needs review
  AwingWord(awing: 'ngaŋə́líʼə́líʼ', english: 'farmer', category: 'things', difficulty: 1),
  // bible:JAS.5.7, freq=1, conf=0.07, alts: waits, behold, until // needs review
  AwingWord(awing: 'asəgə́ndzɔ̈ʼ', english: 'farmer', category: 'things', difficulty: 1),
  // bible:JAS.5.7, freq=1, conf=0.07, alts: waits, behold, until // needs review
  AwingWord(awing: 'alu', english: 'farmer', category: 'things', difficulty: 1),

  // bible:JAS.5.17, freq=1, conf=0.08, alts: man, nature, months // needs review
  AwingWord(awing: 'asánə', english: 'six', category: 'numbers', difficulty: 1),

  // bible:1PE.3.3, freq=1, conf=0.10, alts: fine, jewels, wearing // needs review
  AwingWord(awing: 'məféŋ', english: 'adorning', category: 'things', difficulty: 1),
  // bible:1PE.3.3, freq=1, conf=0.10, alts: fine, jewels, wearing // needs review
  AwingWord(awing: 'məndeʼ', english: 'adorning', category: 'things', difficulty: 1),
  // bible:1PE.5.8, freq=1, conf=0.08, alts: adversary, seeking, watchful // needs review
  AwingWord(awing: 'ə́fuʼ', english: 'walks', category: 'things', difficulty: 1),
  // bible:2PE.2.4, freq=1, conf=0.08, alts: darkness, spare, tartarus // needs review
  AwingWord(awing: 'təŋtə̂', english: 'angels', category: 'things', difficulty: 1),
  // bible:2PE.2.4, freq=1, conf=0.08, alts: darkness, spare, tartarus // needs review
  AwingWord(awing: 'atsɔ́ʼtə́sáʼə', english: 'angels', category: 'things', difficulty: 1),
  // bible:2PE.2.9, freq=1, conf=0.11, alts: temptation, day, judgment // needs review
  AwingWord(awing: 'pəmɔ', english: 'deliver', category: 'things', difficulty: 1),
  // bible:2PE.2.10, freq=1, conf=0.07, alts: afraid, evil, authority // needs review
  AwingWord(awing: 'tsə̈', english: 'defilement', category: 'descriptive', difficulty: 1),
  // bible:2PE.2.13, freq=1, conf=0.08, alts: spots, revel, daytime // needs review
  AwingWord(awing: 'nëŋ', english: 'pleasure', category: 'things', difficulty: 1),


  // bible:2PE.2.17, freq=1, conf=0.10, alts: water, darkness, blackness // needs review
  AwingWord(awing: 'ŋ́ŋɔ́ŋə', english: 'wells', category: 'nature', difficulty: 1),
  // bible:2PE.2.18, freq=1, conf=0.08, alts: great, emptiness, words // needs review
  AwingWord(awing: 'zog', english: 'swelling', category: 'things', difficulty: 1),
  // bible:2PE.2.19, freq=1, conf=0.10, alts: man, bondage, promising // needs review
  AwingWord(awing: 'jîmbəglə́', english: 'themselves', category: 'pronouns', difficulty: 1),
  // bible:2PE.2.22, freq=1, conf=0.08, alts: vomit, proverb, washed // needs review
  AwingWord(awing: 'ajǎʼkə', english: 'dog', category: 'animals', difficulty: 1),
  // bible:2PE.2.22, freq=1, conf=0.08, alts: vomit, proverb, washed // needs review
  AwingWord(awing: 'ńkadlə̂', english: 'dog', category: 'animals', difficulty: 1),
  // bible:2PE.2.22, freq=1, conf=0.08, alts: vomit, proverb, washed // needs review
  AwingWord(awing: 'nətwáabə', english: 'dog', category: 'animals', difficulty: 1),
  // bible:2PE.3.3, freq=1, conf=0.11, alts: walking, after, lusts // needs review
  AwingWord(awing: 'ńnyignə̂', english: 'last', category: 'things', difficulty: 1),
  // bible:2PE.3.6, freq=1, conf=0.20, alts: water, means, world
  AwingWord(awing: 'awɛ̌nkǐ', english: 'overflowed', category: 'nature', difficulty: 1),
  // bible:2PE.3.14, freq=1, conf=0.11, alts: defect, beloved, seeing // needs review
  AwingWord(awing: 'ə́túg', english: 'sight', category: 'things', difficulty: 1),
  // bible:1JN.3.12, freq=1, conf=0.12, alts: brother, killed, kill // needs review
  AwingWord(awing: 'Jɛnɛsis', english: 'evil', category: 'actions', difficulty: 3),
  // bible:REV.1.9, freq=1, conf=0.08, alts: brother, patmos, isle // needs review
  AwingWord(awing: 'Anuənə́foonə', english: 'testimony', category: 'family', difficulty: 3),

  // bible:REV.1.11, freq=1, conf=0.08, alts: book, thyatira, sardis // needs review
  AwingWord(awing: 'Səmiləna', english: 'write', category: 'actions', difficulty: 3),


  // bible:REV.1.13, freq=1, conf=0.08, alts: man, around, chest // needs review
  AwingWord(awing: 'ətád', english: 'reaching', category: 'body', difficulty: 1),
  // bible:REV.1.13, freq=1, conf=0.08, alts: man, around, chest // needs review
  AwingWord(awing: 'aŋkəndá', english: 'reaching', category: 'body', difficulty: 1),
  // bible:REV.1.14, freq=1, conf=0.12, alts: wool, head, white // needs review
  AwingWord(awing: 'məwəŋə́', english: 'flame', category: 'body', difficulty: 1),
  // bible:REV.1.20, freq=1, conf=0.10, alts: right, stars, hand // needs review
  AwingWord(awing: 'ətə́gtə́lam', english: 'angels', category: 'body', difficulty: 1),
  // bible:REV.2.10, freq=1, conf=0.07, alts: life, don, faithful // needs review
  AwingWord(awing: 'ə́jwə́ʼə', english: 'afraid', category: 'descriptive', difficulty: 1),


  // bible:REV.2.18, freq=1, conf=0.07, alts: write, eyes, angel // needs review
  AwingWord(awing: 'Bəlasə', english: 'flame', category: 'actions', difficulty: 3),
  // bible:REV.2.20, freq=1, conf=0.07, alts: prophetess, servants, teaches // needs review
  AwingWord(awing: 'Jɛsəbɛl', english: 'calls', category: 'things', difficulty: 3),
  // bible:REV.2.27, freq=1, conf=0.12, alts: pots, rule, clay // needs review
  AwingWord(awing: 'ńnwadtə̂', english: 'iron', category: 'things', difficulty: 1),
  // bible:REV.2.27, freq=1, conf=0.12, alts: pots, rule, clay // needs review
  AwingWord(awing: 'apagə́pag', english: 'iron', category: 'things', difficulty: 1),
  // bible:REV.2.28, freq=1, conf=0.50, alts: star
  AwingWord(awing: 'ndûmbîə', english: 'morning', category: 'nature', difficulty: 1),
  // bible:REV.3.15, freq=1, conf=0.17, alts: nor, hot, wish
  AwingWord(awing: 'ńtɔnə̂', english: 'works', category: 'descriptive', difficulty: 1),




  // bible:REV.4.3, freq=1, conf=0.14, alts: jasper, around, throne // needs review
  AwingWord(awing: 'ńkyádkə', english: 'rainbow', category: 'things', difficulty: 1),
  // bible:REV.4.3, freq=1, conf=0.14, alts: jasper, around, throne // needs review
  AwingWord(awing: 'emeladə', english: 'rainbow', category: 'things', difficulty: 1),
  // bible:REV.4.4, freq=1, conf=0.08, alts: twenty, four, thrones // needs review
  AwingWord(awing: 'kyádkə', english: 'around', category: 'numbers', difficulty: 1),
  // bible:REV.4.5, freq=1, conf=0.08, alts: sounds, spirits, seven // needs review
  AwingWord(awing: 'mənkyaʼ', english: 'proceed', category: 'numbers', difficulty: 1),
  // bible:REV.4.5, freq=1, conf=0.08, alts: sounds, spirits, seven // needs review
  AwingWord(awing: 'tɔsəlam', english: 'proceed', category: 'numbers', difficulty: 1),

  // bible:REV.4.7, freq=1, conf=0.09, alts: man, eagle, calf // needs review
  AwingWord(awing: 'asə̌lə', english: 'third', category: 'animals', difficulty: 1),
  // bible:REV.5.13, freq=1, conf=0.07, alts: lamb, created, sits // needs review
  AwingWord(awing: 'jwǐ', english: 'honor', category: 'animals', difficulty: 2),
  // bible:REV.5.13, freq=1, conf=0.07, alts: lamb, created, sits // needs review
  AwingWord(awing: 'məmbî', english: 'honor', category: 'animals', difficulty: 2),
  // bible:REV.6.1, freq=1, conf=0.11, alts: lamb, four, thunder // needs review
  AwingWord(awing: 'pəfɨdnû', english: 'living', category: 'animals', difficulty: 1),
  // bible:REV.6.1, freq=1, conf=0.11, alts: lamb, four, thunder // needs review
  AwingWord(awing: 'chû', english: 'living', category: 'animals', difficulty: 1),
  // bible:REV.6.5, freq=1, conf=0.09, alts: black, balance, third // needs review
  AwingWord(awing: 'awɛ̂púmə', english: 'living', category: 'descriptive', difficulty: 1),
  // bible:REV.6.6, freq=1, conf=0.08, alts: denarius, wine, don // needs review
  AwingWord(awing: 'wit', english: 'living', category: 'food', difficulty: 1),
  // bible:REV.6.6, freq=1, conf=0.08, alts: denarius, wine, don // needs review
  AwingWord(awing: 'bale', english: 'living', category: 'food', difficulty: 1),
  // bible:REV.6.9, freq=1, conf=0.09, alts: killed, lamb, souls // needs review
  AwingWord(awing: 'fɨdnûə', english: 'fifth', category: 'actions', difficulty: 1),
  // bible:REV.6.15, freq=1, conf=0.07, alts: themselves, mountains, commanding // needs review
  AwingWord(awing: 'ngaŋə́póʼnə́tso', english: 'hid', category: 'actions', difficulty: 1),
  // bible:REV.6.17, freq=1, conf=0.20, alts: day, stand, wrath
  AwingWord(awing: 'alězáŋə́ndé', english: 'great', category: 'actions', difficulty: 1),

  // bible:REV.7.1, freq=1, conf=0.08, alts: wind, angels, blow // needs review
  AwingWord(awing: 'pəkəfɨd', english: 'holding', category: 'nature', difficulty: 1),





  // bible:REV.7.14, freq=1, conf=0.12, alts: great, blood, washed // needs review
  AwingWord(awing: 'pəsooko', english: 'robes', category: 'things', difficulty: 1),
  // bible:REV.8.6, freq=1, conf=0.17, alts: themselves, sound, seven
  AwingWord(awing: 'ńchwíʼtə', english: 'angels', category: 'numbers', difficulty: 1),
  // bible:REV.8.7, freq=1, conf=0.07, alts: blood, followed, third // needs review
  AwingWord(awing: 'ńgwɛlə̂', english: 'green', category: 'descriptive', difficulty: 1),
  // bible:REV.8.10, freq=1, conf=0.08, alts: waters, great, third // needs review
  AwingWord(awing: 'tɔsəlamə', english: 'fell', category: 'actions', difficulty: 1),
  // bible:REV.8.11, freq=1, conf=0.10, alts: became, third, died // needs review
  AwingWord(awing: 'ńdwǐə', english: 'waters', category: 'numbers', difficulty: 1),
  // bible:REV.8.13, freq=1, conf=0.08, alts: voices, loud, angels // needs review
  AwingWord(awing: 'mbôʼmə́wú', english: 'woe', category: 'descriptive', difficulty: 1),
  // bible:REV.8.13, freq=1, conf=0.08, alts: voices, loud, angels // needs review
  AwingWord(awing: 'məpaŋə', english: 'woe', category: 'descriptive', difficulty: 1),
  // bible:REV.9.4, freq=1, conf=0.08, alts: hurt, don, green // needs review
  AwingWord(awing: 'mətǐə', english: 'foreheads', category: 'actions', difficulty: 1),
  // bible:REV.9.11, freq=1, conf=0.12, alts: greek, abyss, hebrew // needs review
  AwingWord(awing: 'Abadɔnə', english: 'king', category: 'family', difficulty: 3),
  // bible:REV.9.11, freq=1, conf=0.12, alts: greek, abyss, hebrew // needs review
  AwingWord(awing: 'Apolyɔnə', english: 'king', category: 'family', difficulty: 3),
  // bible:REV.9.12, freq=1, conf=0.14, alts: woe, woes, behold // needs review
  AwingWord(awing: 'məndɔ', english: 'past', category: 'things', difficulty: 1),

  // bible:REV.9.16, freq=1, conf=0.20, alts: million, number, horsemen
  AwingWord(awing: 'pəmiliyɔnə', english: 'hundred', category: 'numbers', difficulty: 1),
  // bible:REV.9.17, freq=1, conf=0.07, alts: proceed, fiery, hyacinth // needs review
  AwingWord(awing: 'pəkɨ́ʼ', english: 'horses', category: 'things', difficulty: 1),
  // bible:REV.9.20, freq=1, conf=0.07, alts: mankind, idols, wood // needs review
  AwingWord(awing: 'ə́sə́əkə', english: 'plagues', category: 'things', difficulty: 3),
  // bible:REV.9.20, freq=1, conf=0.07, alts: mankind, idols, wood // needs review
  AwingWord(awing: 'bəlonə', english: 'plagues', category: 'things', difficulty: 3),
  // bible:REV.9.21, freq=1, conf=0.14, alts: repent, murders, sexual // needs review
  AwingWord(awing: 'əzə̌', english: 'immorality', category: 'things', difficulty: 3),
  // bible:REV.10.6, freq=1, conf=0.10, alts: longer, created, delay // needs review
  AwingWord(awing: 'ə́lɛ́ɛlə', english: 'swore', category: 'things', difficulty: 1),
  // bible:REV.10.9, freq=1, conf=0.10, alts: telling, mouth, stomach // needs review
  AwingWord(awing: 'ə́lwǐəə', english: 'book', category: 'body', difficulty: 1),
  // bible:REV.11.1, freq=1, conf=0.11, alts: reed, someone, worship // needs review
  AwingWord(awing: 'afiʼə́púmə', english: 'rise', category: 'actions', difficulty: 1),
  // bible:REV.11.2, freq=1, conf=0.08, alts: don, months, forty // needs review
  AwingWord(awing: 'ńchúʼtə', english: 'court', category: 'numbers', difficulty: 1),
  // bible:REV.11.4, freq=1, conf=0.12, alts: trees, lamp, standing // needs review
  AwingWord(awing: 'ətǐ', english: 'stands', category: 'actions', difficulty: 1),
  // bible:REV.11.6, freq=1, conf=0.07, alts: waters, often, blood // needs review
  AwingWord(awing: 'pəsáʼə', english: 'desire', category: 'things', difficulty: 1),

  // bible:REV.11.16, freq=1, conf=0.09, alts: worshiped, twenty, four // needs review
  AwingWord(awing: 'mɔ̈b', english: 'fell', category: 'actions', difficulty: 1),
  // bible:REV.11.19, freq=1, conf=0.07, alts: ark, sounds, followed // needs review
  AwingWord(awing: 'ńtsǒo', english: 'great', category: 'things', difficulty: 1),

  // bible:REV.12.12, freq=1, conf=0.07, alts: great, rejoice, devil // needs review
  AwingWord(awing: 'fuʼə̂', english: 'woe', category: 'things', difficulty: 1),
  // bible:REV.12.14, freq=1, conf=0.08, alts: great, wings, serpent // needs review
  AwingWord(awing: 'ńdzag', english: 'fly', category: 'actions', difficulty: 1),
  // bible:REV.12.16, freq=1, conf=0.10, alts: helped, mouth, spewed // needs review
  AwingWord(awing: 'ḿmǐ', english: 'river', category: 'body', difficulty: 1),
  // bible:REV.13.10, freq=1, conf=0.14, alts: captivity, sword, anyone // needs review
  AwingWord(awing: 'asəgə́ntɨ́', english: 'killed', category: 'actions', difficulty: 3),
  // bible:REV.14.2, freq=1, conf=0.11, alts: great, playing, sound // needs review
  AwingWord(awing: 'ngaŋə́póʼə́pɛ́n', english: 'waters', category: 'things', difficulty: 1),

  // bible:REV.14.18, freq=1, conf=0.07, alts: send, earth, power // needs review
  AwingWord(awing: 'ńkə́ʼ', english: 'great', category: 'actions', difficulty: 1),
  // bible:REV.14.20, freq=1, conf=0.07, alts: horses, hundred, thousand // needs review
  AwingWord(awing: 'ńkyám', english: 'wine', category: 'food', difficulty: 1),
  // bible:REV.14.20, freq=1, conf=0.07, alts: horses, hundred, thousand // needs review
  AwingWord(awing: 'meta', english: 'wine', category: 'food', difficulty: 1),
  // bible:REV.15.2, freq=1, conf=0.07, alts: something, harps, image // needs review
  AwingWord(awing: 'ńgwɛdnə̂', english: 'having', category: 'pronouns', difficulty: 1),
  // bible:REV.15.2, freq=1, conf=0.07, alts: something, harps, image // needs review
  AwingWord(awing: 'nɔmba', english: 'having', category: 'pronouns', difficulty: 1),
  // bible:REV.16.9, freq=1, conf=0.08, alts: great, name, power // needs review
  AwingWord(awing: 'ajúʼə', english: 'plagues', category: 'things', difficulty: 3),
  // bible:REV.16.11, freq=1, conf=0.12, alts: sores, repent, didn // needs review
  AwingWord(awing: 'əliʼnə́záŋ', english: 'works', category: 'things', difficulty: 1),

  // bible:REV.16.13, freq=1, conf=0.10, alts: mouth, spirits, coming // needs review
  AwingWord(awing: 'pəmə́túʼə́', english: 'something', category: 'body', difficulty: 1),

  // bible:REV.16.21, freq=1, conf=0.08, alts: great, talent, severe // needs review
  AwingWord(awing: 'lɛlə̂', english: 'hailstones', category: 'things', difficulty: 1),
  // bible:REV.17.1, freq=1, conf=0.10, alts: angels, great, sits // needs review
  AwingWord(awing: 'əshǎdnə', english: 'waters', category: 'things', difficulty: 1),

  // bible:REV.17.14, freq=1, conf=0.10, alts: faithful, chosen, lamb // needs review
  AwingWord(awing: 'pəmaʼmbî', english: 'overcome', category: 'animals', difficulty: 1),
  // bible:REV.18.12, freq=1, conf=0.07, alts: merchandise, most, wood // needs review
  AwingWord(awing: 'blonz', english: 'fine', category: 'things', difficulty: 1),
  // bible:REV.18.12, freq=1, conf=0.07, alts: merchandise, most, wood // needs review
  AwingWord(awing: 'mábel', english: 'fine', category: 'things', difficulty: 1),
  // bible:REV.18.13, freq=1, conf=0.07, alts: horses, fine, frankincense // needs review
  AwingWord(awing: 'senamon', english: 'wine', category: 'food', difficulty: 1),
  // bible:REV.18.13, freq=1, conf=0.07, alts: horses, fine, frankincense // needs review
  AwingWord(awing: 'male', english: 'wine', category: 'food', difficulty: 1),
  // bible:REV.18.13, freq=1, conf=0.07, alts: horses, fine, frankincense // needs review
  AwingWord(awing: 'məghɔ́lə', english: 'wine', category: 'food', difficulty: 1),
  // bible:REV.18.16, freq=1, conf=0.08, alts: fine, purple, great // needs review
  AwingWord(awing: 'pəpaŋpaŋ', english: 'woe', category: 'things', difficulty: 1),

  // bible:REV.18.22, freq=1, conf=0.09, alts: craftsman, craft, sound // needs review
  AwingWord(awing: 'ətso', english: 'players', category: 'things', difficulty: 1),
  // bible:REV.19.2, freq=1, conf=0.07, alts: servants, great, avenged // needs review
  AwingWord(awing: 'əsáʼsáʼ', english: 'judgments', category: 'things', difficulty: 2),
  // bible:REV.19.13, freq=1, conf=0.14, alts: blood, sprinkled, word // needs review
  AwingWord(awing: 'pwɔ́nə', english: 'clothed', category: 'things', difficulty: 1),
  // bible:REV.19.15, freq=1, conf=0.07, alts: iron, fierceness, mouth // needs review
  AwingWord(awing: 'chúʼtə', english: 'wine', category: 'body', difficulty: 1),
  // bible:REV.19.16, freq=1, conf=0.12, alts: thigh, kings, lords // needs review
  AwingWord(awing: 'nətoʼ', english: 'king', category: 'family', difficulty: 1),
  // bible:REV.19.16, freq=1, conf=0.12, alts: thigh, kings, lords // needs review
  AwingWord(awing: 'pəmaʼmbîə', english: 'king', category: 'family', difficulty: 1),
  // bible:REV.20.4, freq=1, conf=0.07, alts: hand, didn, word // needs review
  AwingWord(awing: 'ələŋəmə́foonə', english: 'thousand', category: 'body', difficulty: 1),
  // bible:REV.20.8, freq=1, conf=0.08, alts: together, four, number // needs review
  AwingWord(awing: 'ə́fɨg', english: 'magog', category: 'numbers', difficulty: 1),


  // bible:REV.21.1, freq=1, conf=0.14, alts: away, passed, first // needs review
  AwingWord(awing: 'nəfî', english: 'new', category: 'descriptive', difficulty: 1),
  // bible:REV.21.4, freq=1, conf=0.08, alts: crying, away, mourning // needs review
  AwingWord(awing: 'Pəlɛn', english: 'nor', category: 'things', difficulty: 3),
  // bible:REV.21.8, freq=1, conf=0.07, alts: lake, sinners, immoral // needs review
  AwingWord(awing: 'támkə', english: 'sorcerers', category: 'nature', difficulty: 1),
  // bible:REV.21.16, freq=1, conf=0.08, alts: equal, reed, length // needs review
  AwingWord(awing: 'afiʼə́pú', english: 'great', category: 'things', difficulty: 1),
  // bible:REV.21.17, freq=1, conf=0.11, alts: measure, cubits, wall // needs review
  AwingWord(awing: 'pəmeta', english: 'hundred', category: 'numbers', difficulty: 1),
  // bible:REV.21.19, freq=1, conf=0.07, alts: wall, sapphire, jasper // needs review
  AwingWord(awing: 'agatə', english: 'second', category: 'numbers', difficulty: 1),
  // bible:REV.21.19, freq=1, conf=0.07, alts: wall, sapphire, jasper // needs review
  AwingWord(awing: 'ɛmɛlɛdə', english: 'second', category: 'numbers', difficulty: 1),
  // bible:REV.21.20, freq=1, conf=0.07, alts: fifth, twelfth, eighth // needs review
  AwingWord(awing: 'onizə', english: 'jacinth', category: 'numbers', difficulty: 1),
  // bible:REV.21.20, freq=1, conf=0.07, alts: fifth, twelfth, eighth // needs review
  AwingWord(awing: 'kanəlya', english: 'jacinth', category: 'numbers', difficulty: 1),

  // bible:REV.21.20, freq=1, conf=0.07, alts: fifth, twelfth, eighth // needs review
  AwingWord(awing: 'kwatzə', english: 'jacinth', category: 'numbers', difficulty: 1),

  // bible:REV.21.20, freq=1, conf=0.07, alts: fifth, twelfth, eighth // needs review
  AwingWord(awing: 'topakzə', english: 'jacinth', category: 'numbers', difficulty: 1),
  // bible:REV.21.20, freq=1, conf=0.07, alts: fifth, twelfth, eighth // needs review
  AwingWord(awing: 'chasidoni', english: 'jacinth', category: 'numbers', difficulty: 1),
  // bible:REV.21.20, freq=1, conf=0.07, alts: fifth, twelfth, eighth // needs review
  AwingWord(awing: 'tukwasə', english: 'jacinth', category: 'numbers', difficulty: 1),
  // bible:REV.21.20, freq=1, conf=0.07, alts: fifth, twelfth, eighth // needs review
  AwingWord(awing: 'ametist', english: 'jacinth', category: 'numbers', difficulty: 1),
  // bible:REV.21.25, freq=1, conf=0.17, alts: day, shut, night
  AwingWord(awing: 'wuʼnə̂', english: 'gates', category: 'things', difficulty: 1),
  // bible:REV.22.14, freq=1, conf=0.12, alts: right, life, enter // needs review
  AwingWord(awing: 'Apɔŋə́', english: 'commandments', category: 'descriptive', difficulty: 3),
  // bible:REV.22.15, freq=1, conf=0.09, alts: sorcerers, loves, falsehood // needs review
  AwingWord(awing: 'ngaŋnə́kaŋə', english: 'dogs', category: 'things', difficulty: 1),
  // bible:REV.22.15, freq=1, conf=0.09, alts: sorcerers, loves, falsehood // needs review
  AwingWord(awing: 'ngaŋə́zɔ́ʼə', english: 'dogs', category: 'things', difficulty: 1),
  // bible:REV.22.15, freq=1, conf=0.09, alts: sorcerers, loves, falsehood // needs review
  AwingWord(awing: 'ngaŋə́jwítə', english: 'dogs', category: 'things', difficulty: 1)];

// ============================================================
// HELPER FUNCTIONS
// ============================================================

/// All vocabulary combined for easy access across the app.
/// Order matters for quiz/exam logic — keeps curated entries first.
List<AwingWord> get allVocabulary => [
  ...pronouns,
  ...timeWords,
  ...pdfVerifiedExtras,
  ...bodyParts,
  ...animalsNature,
  ...foodDrink,
  ...actions,
  ...thingsObjects,
  ...familyPeople,
  ...numbers,
  ...moreActions,
  ...moreThings,
  ...descriptiveWords,
  ...dictionaryEntries,
];

/// Get vocabulary by category name (matches AwingWord.category strings).
List<AwingWord> getVocabularyByCategory(String category) {
  return allVocabulary.where((w) => w.category == category).toList();
}

/// Get vocabulary by difficulty level (returns all entries at <= level).
List<AwingWord> getVocabularyByDifficulty(int level) {
  return allVocabulary.where((w) => w.difficulty <= level).toList();
}
