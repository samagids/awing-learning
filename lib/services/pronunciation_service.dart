import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:awing_ai_learning/services/asset_pack_service.dart';

/// Pronunciation service for the Awing language.
///
/// Uses 6 character voices organized by difficulty level:
///   - Beginner: boy + girl (child voices, slower, higher pitch)
///   - Medium:   young_man + young_woman (young adult voices, moderate pace)
///   - Expert:   man + woman (adult voices, natural pace, deeper)
///
/// Audio directory structure:
///   assets/audio/{boy,girl,young_man,young_woman,man,woman}/{alphabet,vocabulary,sentences,stories}/
///
/// Audio pipeline:
///   1. Edge TTS character voice clips (6 voices) — PRIMARY
///   2. English phonetic TTS approximation — FALLBACK
class PronunciationService {
  static final PronunciationService _instance = PronunciationService._();
  factory PronunciationService() => _instance;
  PronunciationService._();

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _initialized = false;
  bool _audioPlayerConfigured = false;

  /// Active flutter_tts locale code. Set by init() based on what the OS
  /// has installed. Drives the choice between awingToSpeakable() (Swahili
  /// path -- matches the build-time Edge TTS pipeline) and the older
  /// awingToPhonetic() English-approximation path.
  String _ttsLocale = 'en-US';

  /// True when flutter_tts is currently configured to speak Swahili.
  /// Most Awing words contain ɛ/ɔ/ə/ɨ/ŋ/ɣ and prenasalized clusters that
  /// English TTS cannot pronounce, so when a Swahili voice IS installed
  /// the speakable rules from the build-time pipeline produce far closer
  /// output. When no Swahili voice exists, awingToPhonetic() (English
  /// approximation) is used instead.
  bool _swahiliAvailable = false;

  /// Current voice character. Screens set this based on difficulty level.
  String _currentVoice = 'boy';

  /// Optional override: when set to a kid slug, audio lookup tries
  /// assets/audio/native_kids/<slug>/<category>/<key>.mp3 BEFORE the
  /// default native voice. Falls back to native (Dr. Sama) when the
  /// specific kid hasn't recorded that word yet. Persisted by the
  /// screen that set it (BeginnerHome).
  String? _kidOverride;

  /// Known kid recorders, keyed by character voice. Only these slugs
  /// produce hits in audio/native_kids/. Mirrors the FAMILY list in
  /// scripts/build_family_recorder.py.
  static const Map<String, List<String>> kidVoicesByCharacter = {
    'boy': ['joel', 'janelle'],
    'girl': ['joyce', 'jadyne'],
  };

  /// Human-readable name for each kid slug. Mirrors the dev Record-tab
  /// picker so attribution stays consistent across the app.
  static const Map<String, String> kidDisplayNames = {
    'joel': 'Joel',
    'janelle': 'Janelle',
    'joyce': 'Joyce',
    'jadyne': 'Jadyne',
  };

  /// Valid voice characters
  static const voices = ['boy', 'girl', 'young_man', 'young_woman', 'man', 'woman'];

  /// Voices for each difficulty level
  static const beginnerVoices = ['boy', 'girl'];
  static const mediumVoices = ['young_man', 'young_woman'];
  static const expertVoices = ['man', 'woman'];

  /// Get the current voice character name
  String get currentVoice => _currentVoice;

  /// Currently-active kid override slug (or null = use the default
  /// native voice).
  String? get kidOverride => _kidOverride;

  /// Set the kid override. Pass null to clear and fall back to the
  /// canonical native voice (Dr. Sama) for every word.
  void setKidOverride(String? slug) {
    if (slug == null || slug.isEmpty) {
      _kidOverride = null;
      return;
    }
    final knownKids = kidVoicesByCharacter.values
        .expand((v) => v)
        .toSet();
    if (knownKids.contains(slug)) {
      _kidOverride = slug;
    }
  }

  /// Set voice by character name
  void setVoice(String voice) {
    if (voices.contains(voice)) {
      _currentVoice = voice;
    }
  }

  /// Set voice based on difficulty level.
  /// Beginner → boy, Medium → young_man, Expert → man.
  /// Alternates to female voice if [alternate] is true.
  void setVoiceForLevel(String level, {bool alternate = false}) {
    switch (level.toLowerCase()) {
      case 'beginner':
        _currentVoice = alternate ? 'girl' : 'boy';
        break;
      case 'medium':
        _currentVoice = alternate ? 'young_woman' : 'young_man';
        break;
      case 'expert':
        _currentVoice = alternate ? 'woman' : 'man';
        break;
    }
  }

  /// Initialize TTS engine and audio player
  Future<void> init() async {
    if (_initialized) return;

    // Prefer Swahili (matches build-time Edge TTS sw-KE / sw-TZ neural
    // voices). Fall back to English if no Swahili voice is installed on
    // the device. The selected locale drives awingToSpeakable vs
    // awingToPhonetic in speakAwing() and speakSentence().
    _swahiliAvailable = false;
    _ttsLocale = 'en-US';
    for (final locale in const ['sw-KE', 'sw-TZ', 'sw']) {
      try {
        final ok = await _tts.isLanguageAvailable(locale);
        if (ok == true) {
          await _tts.setLanguage(locale);
          _ttsLocale = locale;
          _swahiliAvailable = true;
          break;
        }
      } catch (_) {
        // isLanguageAvailable can throw on some devices; try next.
      }
    }
    if (!_swahiliAvailable) {
      await _tts.setLanguage('en-US');
    }
    await _tts.setSpeechRate(0.35);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    // Configure AudioPlayer to use the MUSIC audio stream so that
    // the device volume buttons control playback volume correctly.
    if (!_audioPlayerConfigured) {
      await _audioPlayer.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          audioMode: AndroidAudioMode.normal,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      ));
      await _audioPlayer.setVolume(1.0);
      _audioPlayerConfigured = true;
    }

    _initialized = true;
  }

  /// Special alphabet file names for letters that would collide in ASCII.
  static const _alphabetFileNames = {
    'ɛ': 'epsilon',
    'ə': 'schwa',
    'ɨ': 'barred_i',
    'ɔ': 'open_o',
    'ŋ': 'eng',
    "'": 'glottal',
  };

  final AssetPackService _assetPack = AssetPackService();

  /// Play an audio asset file from the install-time asset pack.
  /// Returns true if successful.
  Future<bool> _playAudioAsset(String assetPath) async {
    try {
      // Assets are in the PAD install-time pack, accessed via platform channel.
      // The asset pack path is relative to the pack root (no "assets/" prefix).
      final packPath = assetPath.replaceFirst('assets/', '');
      final filePath = await _assetPack.getAssetPath(packPath);
      if (filePath == null) return false;

      await _audioPlayer.stop();
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _audioPlayer.play(DeviceFileSource(filePath));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Resolve a file path to the WAV reference for the on-device
  /// pronunciation grader (lib/services/pronunciation_grader.dart).
  ///
  /// The PAD pack ships a .wav alongside every native-tier .mp3
  /// (see scripts/apply_recordings_as_audio.py v2+). Search order
  /// mirrors playback's [_buildSearchPaths] BUT only across the
  /// native + native_kids tiers — the grader never compares against
  /// TTS-synthesized character voices, those aren't real speech.
  ///
  /// Returns:
  ///   - The cached file path of the first matching .wav, OR
  ///   - null when no native reference exists for this word
  ///     (caller should hide / disable the grader UI for that word).
  ///
  /// Walks tiers:
  ///   1. native_kids/<picked kid>/<category>/<key>.wav  (when kid override active)
  ///   2. native/<category>/<key>.wav                    (canonical Dr. Sama reference)
  ///
  /// Caches the resolved path inside the same PAD-asset extraction
  /// cache the audio player uses, so subsequent grader calls for the
  /// same word are free.
  Future<String?> referenceWavPathForGrading({
    required String awingWord,
    required String category,
  }) async {
    final key = _audioKey(awingWord);

    final candidates = <String>[];
    if (_kidOverride != null) {
      candidates
          .add('assets/audio/native_kids/$_kidOverride/$category/$key.wav');
    }
    candidates.add('assets/audio/native/$category/$key.wav');

    for (final asset in candidates) {
      try {
        final packPath = asset.replaceFirst('assets/', '');
        final exists = await _assetPack.assetExists(packPath);
        if (!exists) continue;
        final filePath = await _assetPack.getAssetPath(packPath);
        if (filePath != null) return filePath;
      } catch (_) {
        // Try next candidate.
      }
    }
    return null;
  }

  /// Get the voice list for the same level as the current voice.
  List<String> _sameLevelVoices() {
    if (beginnerVoices.contains(_currentVoice)) return beginnerVoices;
    if (mediumVoices.contains(_currentVoice)) return mediumVoices;
    return expertVoices;
  }

  /// Build search paths for a given audio key across voice directories.
  ///
  /// ONLY searches within the current level's voice directories.
  /// Each level has its own voices with level-appropriate content:
  ///   - Beginner (boy/girl): alphabet + beginner vocabulary + sentences
  ///   - Medium (young_man/young_woman): alphabet + beginner+medium vocabulary + sentences
  ///   - Expert (man/woman): alphabet + all vocabulary + sentences + stories
  ///
  /// Does NOT fall back to other levels because voices only contain
  /// audio for words at their difficulty level.
  List<String> _buildSearchPaths(String key, String category) {
    final paths = <String>[];

    // -1. Kid-voice override — only when the user has explicitly picked
    //     a specific kid (Joel, Janelle, Joyce, Jadyne) in the Beginner
    //     home picker. Populated by scripts/apply_recordings_as_audio.py
    //     from training_data/recordings/ when the manifest's `recorder`
    //     field matches a known kid name. Falls through silently when
    //     that specific kid hasn't recorded this word yet — the user
    //     still hears the canonical native voice below.
    if (_kidOverride != null) {
      paths.add(
          'assets/audio/native_kids/$_kidOverride/$category/$key.opus');
    }

    // 0. Native speaker recording — highest priority across all voices.
    //    Populated by scripts/apply_recordings_as_audio.py from
    //    training_data/recordings/ (Dr. Sama's recordings). When present,
    //    every character voice plays the authentic recording instead of
    //    the Edge TTS Swahili approximation.
    paths.add('assets/audio/native/$category/$key.opus');

    // 0.5. Community contributor recording (v1.17.x — new tier).
    //      Anyone who submits audio via the Contribute screen (not
    //      Dr. Sama, not a registered family kid) lands here. The
    //      tier sits BELOW Dr. Sama's native recording, so any word
    //      he's recorded plays HIS voice first — community audio is
    //      only used as a fallback for words he hasn't covered yet.
    paths.add('assets/audio/community/$category/$key.opus');

    // NOTE (Session 60+): bible_trained tier removed. The one-time
    // RunPod A100 Coqui VITS fine-tune on 22.83 hrs of Bible audio
    // technically converged (mel loss 47→25 over ~5 hrs of training),
    // but inference output did not produce intelligible Awing vocab
    // pronunciation. Root causes documented in CLAUDE.md Session 60+:
    // (1) VITS doesn't model tones — Awing tone diacritics were
    // treated as unconditioned vocabulary characters, (2) 22 hrs is
    // marginal for single-speaker VITS, (3) Bible→vocab domain shift
    // (full sentences to single words). ~$15 negative result. Do not
    // retry without addressing tones explicitly (e.g. pitch-
    // conditioned model or tone-aware text encoder).

    // 1. Current character voice (Edge TTS Swahili — approximation,
    //    used when none of the above tiers have a recording)
    paths.add('assets/audio/$_currentVoice/$category/$key.opus');

    // 2. Same-level alternate voice (e.g. girl if boy is selected)
    for (final v in _sameLevelVoices()) {
      if (v != _currentVoice) {
        paths.add('assets/audio/$v/$category/$key.opus');
      }
    }

    // No cross-level fallback — voices only contain their level's content

    return paths;
  }

  /// Speak an Awing word — tries real audio first, falls back to TTS.
  Future<void> speakAwing(String awingWord) async {
    await init();

    final key = _audioKey(awingWord);

    // Try all voice+category combinations
    for (final category in ['vocabulary', 'alphabet', 'dictionary', 'sentences']) {
      for (final path in _buildSearchPaths(key, category)) {
        if (await _playAudioAsset(path)) return;
      }
    }

    // Fallback to TTS. On Swahili-capable devices, use the same
    // awing_to_speakable() rules the build-time Edge TTS pipeline uses
    // (so runtime-synthesized Awing matches pre-baked clips). On English-
    // only devices, use the older awingToPhonetic English approximation.
    final phonetic = _swahiliAvailable
        ? awingToSpeakable(awingWord)
        : awingToPhonetic(awingWord);
    await _tts.setSpeechRate(0.4);
    await _tts.speak(phonetic);
    await _tts.setSpeechRate(0.35);
  }

  /// Speak an Awing sentence — tries pre-generated clip first,
  /// then word-by-word, then full phonetic fallback.
  Future<void> speakSentence(String sentence, {String? clipKey}) async {
    await init();

    // Try sentence clip by key
    if (clipKey != null) {
      for (final path in _buildSearchPaths(clipKey, 'sentences')) {
        if (await _playAudioAsset(path)) return;
      }
    }

    // Try sentence clip by auto-generated key
    final autoKey = _audioKey(sentence);
    for (final path in _buildSearchPaths(autoKey, 'sentences')) {
      if (await _playAudioAsset(path)) return;
    }

    // Fallback: speak word by word with pauses
    final words = sentence.split(RegExp(r'\s+'));
    for (final word in words) {
      if (word.isEmpty) continue;
      final cleanWord = word.replaceAll(RegExp(r'[.?!,]'), '');
      if (cleanWord.isEmpty) continue;

      final wordKey = _audioKey(cleanWord);
      bool played = false;
      for (final category in ['vocabulary', 'dictionary']) {
        for (final path in _buildSearchPaths(wordKey, category)) {
          if (await _playAudioAsset(path)) {
            played = true;
            break;
          }
        }
        if (played) break;
      }

      if (!played) {
        // Same Swahili-vs-English choice as speakAwing.
        final phonetic = _swahiliAvailable
            ? awingToSpeakable(cleanWord)
            : awingToPhonetic(cleanWord);
        await _tts.speak(phonetic);
        await Future.delayed(const Duration(milliseconds: 300));
      } else {
        await Future.delayed(const Duration(milliseconds: 600));
      }
    }
  }

  /// Speak a story line — tries story clip first, then sentence fallback
  Future<void> speakStoryLine(String text, {String? clipKey}) async {
    await init();

    if (clipKey != null) {
      for (final path in _buildSearchPaths(clipKey, 'stories')) {
        if (await _playAudioAsset(path)) return;
      }
    }

    await speakSentence(text);
  }

  /// Speak the English translation normally
  Future<void> speakEnglish(String englishWord) async {
    await init();
    await _tts.setSpeechRate(0.45);
    await _tts.speak(englishWord);
    await _tts.setSpeechRate(0.35);
  }

  /// Speak an isolated phoneme/sound for alphabet learning.
  /// Uses phonemic pronunciation (the SOUND the letter makes),
  /// not the English letter name.
  Future<void> speakSound(String phoneme) async {
    await init();

    // Try special alphabet file name first (for ɛ, ə, ɔ, ɨ, ŋ, ')
    final specialName = _alphabetFileNames[phoneme];
    if (specialName != null) {
      for (final path in _buildSearchPaths(specialName, 'alphabet')) {
        if (await _playAudioAsset(path)) return;
      }
    }

    // Try default alphabet audio file
    final key = _audioKey(phoneme);
    for (final path in _buildSearchPaths(key, 'alphabet')) {
      if (await _playAudioAsset(path)) return;
    }

    // Fallback to TTS — use phonemic sound, NOT the letter name
    await _tts.setSpeechRate(0.3);
    final soundGuide = _letterToSound(phoneme);
    await _tts.speak(soundGuide);
    await _tts.setSpeechRate(0.35);
  }

  /// Convert a letter/phoneme to its spoken SOUND for TTS.
  /// For example, 'b' → 'buh', 'k' → 'kuh', not 'bee'/'kay'.
  static String _letterToSound(String letter) {
    final l = letter.toLowerCase().trim();
    const soundMap = {
      // Vowels — say the actual vowel sound
      'a': 'ah',
      'e': 'ay',
      'i': 'ee',
      'o': 'oh',
      'u': 'oo',
      'ɛ': 'eh',
      'ə': 'uh',
      'ɔ': 'aw',
      'ɨ': 'ih',
      // Consonants — say the sound, not the letter name
      'b': 'buh',
      'ch': 'chuh',
      'd': 'duh',
      'f': 'fuh',
      'g': 'guh',
      'gh': 'ghuh',
      'j': 'juh',
      'k': 'kuh',
      'l': 'luh',
      'm': 'muh',
      'mm': 'mmuh',
      'n': 'nuh',
      'ny': 'nyuh',
      'ŋ': 'nguh',
      'p': 'puh',
      's': 'sss',
      'sh': 'shh',
      't': 'tuh',
      'ts': 'tsuh',
      'w': 'wuh',
      'y': 'yuh',
      'z': 'zuh',
      "'": 'uh',
    };
    // If not in the map, add 'uh' to make it sound like a phoneme, not a letter name
    if (soundMap.containsKey(l)) return soundMap[l]!;
    // For unknown short inputs, just return as-is (awingToPhonetic handles longer words)
    return l.length <= 2 ? '${l}uh' : awingToPhonetic(l);
  }

  /// Stop any current audio or speech
  Future<void> stop() async {
    await _audioPlayer.stop();
    await _tts.stop();
  }

  /// Check if a real audio recording exists for this word.
  Future<bool> hasRealAudio(String awingWord) async {
    final key = _audioKey(awingWord);
    for (final category in ['vocabulary', 'alphabet', 'dictionary', 'sentences']) {
      for (final path in _buildSearchPaths(key, category)) {
        try {
          await _playAudioAsset(path);
          await _audioPlayer.stop();
          return true;
        } catch (_) {
          // Not found, try next path
        }
      }
    }
    return false;
  }

  /// Public alias of [_audioKey] — used by RecordingsService and the
  /// Dev Mode Record tab to compute the canonical audio filename
  /// stem for each Awing item.
  static String audioKey(String awingWord) => _audioKey(awingWord);

  /// Convert an Awing word to a safe filename key.
  static String _audioKey(String awingWord) {
    String key = awingWord.toLowerCase();

    // Strip tone diacritics
    key = key
        .replaceAll('á', 'a').replaceAll('à', 'a')
        .replaceAll('â', 'a').replaceAll('ǎ', 'a')
        .replaceAll('é', 'e').replaceAll('è', 'e')
        .replaceAll('ê', 'e').replaceAll('ě', 'e')
        .replaceAll('í', 'i').replaceAll('ì', 'i')
        .replaceAll('î', 'i').replaceAll('ǐ', 'i')
        .replaceAll('ó', 'o').replaceAll('ò', 'o')
        .replaceAll('ô', 'o').replaceAll('ǒ', 'o')
        .replaceAll('ú', 'u').replaceAll('ù', 'u')
        .replaceAll('û', 'u').replaceAll('ǔ', 'u');

    // Replace special vowels with ASCII
    key = key
        .replaceAll('ɛ́', 'e').replaceAll('ɛ̂', 'e').replaceAll('ɛ̌', 'e').replaceAll('ɛ', 'e')
        .replaceAll('ə́', 'e').replaceAll('ə̂', 'e').replaceAll('ə̌', 'e').replaceAll('ə', 'e')
        .replaceAll('ɔ́', 'o').replaceAll('ɔ̂', 'o').replaceAll('ɔ̌', 'o').replaceAll('ɔ', 'o')
        .replaceAll('ɨ́', 'i').replaceAll('ɨ̂', 'i').replaceAll('ɨ̌', 'i').replaceAll('ɨ', 'i')
        .replaceAll('ŋ', 'ng');

    // Remove glottal stops and special characters
    key = key.replaceAll("'", '').replaceAll("\u2019", '').replaceAll("\u2018", '');

    // Remove any remaining non-ASCII characters
    key = key.replaceAll(RegExp(r'[^a-z0-9]'), '');

    return key;
  }

  /// Convert Awing text to a Swahili-pronounceable spelling for
  /// flutter_tts. Direct Dart port of awing_to_speakable() in
  /// scripts/generate_audio_edge.py -- same rules the build-time Edge
  /// TTS pipeline uses, so runtime fallback TTS sounds consistent with
  /// pre-baked clips when the device has a Swahili voice installed.
  ///
  /// Note on Unicode: the Python source NFD-decomposes pre-composed
  /// characters then drops 5 specific tone marks. Our app content uses
  /// combining-mark sequences (not pre-composed Latin diacritics), so
  /// iterating runes and skipping the U+0300-U+036F combining-mark
  /// block is equivalent for every Awing string in vocab/phrases/
  /// sentences/stories.
  static String awingToSpeakable(String text) {
    if (text.isEmpty) return text;

    // 1. Strip tone-bearing combining marks (acute, grave, circumflex,
    //    caron, tilde, etc.) -- TTS handles its own prosody.
    final stripped = StringBuffer();
    for (final rune in text.runes) {
      if (rune >= 0x0300 && rune <= 0x036F) continue;
      stripped.writeCharCode(rune);
    }
    String result = stripped.toString();

    // 2. ŋg / ŋk cluster handling BEFORE isolated ŋ becomes "ng".
    result = result
        .replaceAll('ŋg', 'ngg')
        .replaceAll('Ŋg', 'Ngg')
        .replaceAll('ŋk', 'nk')
        .replaceAll('Ŋk', 'Nk');

    // 3. Word-final "a + glottal-stop + ə" -> "a" (Whisper-mined rule).
    //    Source: 4 native recordings ending in /a'ə/ all produced "-a"
    //    via Whisper-Swahili, not "-a'a" or "-aa". Fires BEFORE the
    //    generic word-final schwa rule so the apostrophe context is
    //    still available to distinguish from long vowels like "naa".
    final aGlottalSchwa = RegExp("a['’‘ʼ]ə"
        r'(?=$|[\s.,!?;:"\-])');
    result = result.replaceAll(aGlottalSchwa, 'a');
    final upperAGlottalSchwa = RegExp("A['’‘ʼ]Ə"
        r'(?=$|[\s.,!?;:"\-])');
    result = result.replaceAll(upperAGlottalSchwa, 'A');

    // 4. Word-final ə -> 'a'. Swahili almost never ends words in 'e',
    //    so our default ə->e for mid-word doesn't apply word-finally.
    result = result.replaceAll(
        RegExp(r'ə(?=$|[\s.,!?;:"\-])'), 'a');
    result = result.replaceAll(
        RegExp(r'Ə(?=$|[\s.,!?;:"\-])'), 'A');

    // 5. Bulk Awing-only graphemes -> Latin equivalents.
    const replacements = <List<String>>[
      ['Ɛ', 'E'], ['ɛ', 'e'],
      ['Ɔ', 'O'], ['ɔ', 'o'],
      ['Ə', 'E'], ['ə', 'e'],
      ['Ɨ', 'I'], ['ɨ', 'i'],
      ['Ŋ', 'Ng'], ['ŋ', 'ng'],
      ['ɣ', 'gh'],
      ['ʼ', ''], ['’', ''], ['‘', ''], ["'", ''],
    ];
    for (final pair in replacements) {
      result = result.replaceAll(pair[0], pair[1]);
    }

    // 6. Collapse runs of whitespace.
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
    return result;
  }

  /// Convert Awing orthography to English phonetic approximation for TTS fallback.
  /// Designed so English TTS will SOUND OUT the word as a single unit, not spell it.
  ///
  /// Strategy: build a pronounceable English-like word by converting each Awing
  /// grapheme to an English syllable. The result should look like a real English
  /// word so TTS reads it fluently (e.g., "nkɔ́'ə" → "nkaw-uh", "ŋgóonɛ́" → "nggoh-neh").
  static String awingToPhonetic(String awingWord) {
    String text = awingWord.toLowerCase().trim();
    if (text.isEmpty) return text;

    // Strip all tone diacritics (combining marks) via Unicode NFD decomposition
    // This handles á→a, ɛ́→ɛ, ə̌→ə, etc. without needing every combination
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      // Skip combining diacritical marks (U+0300–U+036F)
      if (rune >= 0x0300 && rune <= 0x036F) continue;
      buffer.write(char);
    }
    text = buffer.toString();

    // Process character by character, consuming multi-char sequences first
    final out = StringBuffer();
    int i = 0;
    while (i < text.length) {
      String? match;

      // Try 3-character sequences
      if (i + 2 < text.length) {
        final tri = text.substring(i, i + 3);
        match = _phonemeMap3[tri];
        if (match != null) { out.write(match); i += 3; continue; }
      }

      // Try 2-character sequences
      if (i + 1 < text.length) {
        final di = text.substring(i, i + 2);
        match = _phonemeMap2[di];
        if (match != null) { out.write(match); i += 2; continue; }
      }

      // Single character
      final ch = text[i];
      match = _phonemeMap1[ch];
      if (match != null) {
        out.write(match);
      } else if (RegExp(r'[a-z]').hasMatch(ch)) {
        // Unknown letter — keep as-is with a vowel so TTS doesn't spell it
        out.write('${ch}uh');
      } else if (ch == ' ') {
        out.write(' ');
      }
      // Skip other characters (punctuation, remaining diacritics, etc.)
      i++;
    }

    return out.toString().trim();
  }

  /// 3-character phoneme mappings (checked first)
  static const _phonemeMap3 = {
    // Prenasalized + labialized
    'mbw': 'mbwah',
    'ndw': 'ndwah',
    'ngw': 'ngwah',
    'nkw': 'nkwah',
    // Prenasalized + palatalized
    'nty': 'ntchah',
    'nky': 'nkyah',
  };

  /// 2-character phoneme mappings (checked second)
  static const _phonemeMap2 = {
    // Long vowels — pronounce as extended single sound
    'aa': 'ahh',
    'ee': 'ayy',
    'oo': 'ohh',
    'uu': 'ooh',
    // Prenasalized stops (common in Bantu)
    'mb': 'mb',
    'nd': 'nd',
    'nj': 'nj',
    'nk': 'nk',
    'nt': 'nt',
    'nz': 'nz',
    // Consonant digraphs
    'gh': 'g',
    'sh': 'sh',
    'ch': 'ch',
    'ts': 'ts',
    'ny': 'nyuh',
    'ng': 'ng',
    // Palatalized
    'ty': 'tchah',
    'ky': 'kyah',
    'fy': 'fyah',
    'py': 'pyah',
    'ly': 'lyah',
    // Labialized
    'tw': 'twah',
    'kw': 'kwah',
    'fw': 'fwah',
    'bw': 'bwah',
    'pw': 'pwah',
    'gw': 'gwah',
    // Double consonants
    'mm': 'mm',
    'nn': 'nn',
  };

  /// 1-character phoneme mappings (checked last)
  static const _phonemeMap1 = {
    // Plain vowels
    'a': 'ah',
    'e': 'eh',
    'i': 'ee',
    'o': 'oh',
    'u': 'oo',
    // Special Awing vowels
    'ɛ': 'eh',
    'ə': 'uh',
    'ɔ': 'aw',
    'ɨ': 'ih',
    // Precomposed vowels with tone diacritics (single Unicode codepoints).
    // These are NOT decomposed by Dart, so the combining-mark stripper misses them.
    // Acute (high tone)
    'á': 'ah', 'é': 'eh', 'í': 'ee', 'ó': 'oh', 'ú': 'oo',
    // Grave (low tone)
    'à': 'ah', 'è': 'eh', 'ì': 'ee', 'ò': 'oh', 'ù': 'oo',
    // Circumflex (falling tone)
    'â': 'ah', 'ê': 'eh', 'î': 'ee', 'ô': 'oh', 'û': 'oo',
    // Caron/háček (rising tone)
    'ǎ': 'ah', 'ě': 'eh', 'ǐ': 'ee', 'ǒ': 'oh', 'ǔ': 'oo',
    // Consonants — most are fine as-is for English TTS
    'b': 'b',
    'd': 'd',
    'f': 'f',
    'g': 'g',
    'j': 'j',
    'k': 'k',
    'l': 'l',
    'm': 'm',
    'n': 'n',
    'p': 'p',
    'r': 'r',
    's': 's',
    't': 't',
    'w': 'w',
    'y': 'y',
    'z': 'z',
    'ŋ': 'ng',
    "'": '',     // glottal stop — brief pause handled by TTS naturally
    "\u2019": '', // curly apostrophe
    "\u2018": '', // left curly apostrophe
  };

  /// Get a human-readable pronunciation guide string for display
  static String getPronunciationGuide(String awingWord) {
    String result = awingWord;

    result = result
        .replaceAll('á', 'a').replaceAll('à', 'a')
        .replaceAll('â', 'a').replaceAll('ǎ', 'a')
        .replaceAll('é', 'e').replaceAll('è', 'e')
        .replaceAll('ê', 'e').replaceAll('ě', 'e')
        .replaceAll('í', 'i').replaceAll('ì', 'i')
        .replaceAll('î', 'i').replaceAll('ǐ', 'i')
        .replaceAll('ó', 'o').replaceAll('ò', 'o')
        .replaceAll('ô', 'o').replaceAll('ǒ', 'o')
        .replaceAll('ú', 'u').replaceAll('ù', 'u')
        .replaceAll('û', 'u').replaceAll('ǔ', 'u')
        .replaceAll('ɛ́', 'EH').replaceAll('ɛ', 'EH')
        .replaceAll('ə́', 'UH').replaceAll('ə', 'UH')
        .replaceAll('ɔ́', 'AW').replaceAll('ɔ', 'AW')
        .replaceAll('ɨ́', 'IH').replaceAll('ɨ', 'IH')
        .replaceAll('ŋ', 'NG')
        .replaceAll("'", '-');

    return result;
  }

  void dispose() {
    _audioPlayer.dispose();
    _tts.stop();
  }
}
