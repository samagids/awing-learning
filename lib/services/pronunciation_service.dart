import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:awing_ai_learning/services/asset_pack_service.dart';
import 'package:awing_ai_learning/services/image_service.dart'
    show ImageService;
import 'package:awing_ai_learning/data/audio_clip_claims.dart';

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
    // the device. _swahiliAvailable is what drives awingToSpeakable
    // vs awingToPhonetic in speakAwing() and speakSentence().
    _swahiliAvailable = false;
    for (final locale in const ['sw-KE', 'sw-TZ', 'sw']) {
      try {
        final ok = await _tts.isLanguageAvailable(locale);
        if (ok == true) {
          await _tts.setLanguage(locale);
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

    // v1.24.0 (NACDA DMV feedback): the Edge TTS character-voice tiers
    // were REMOVED from here. They used Swahili neural voices to
    // approximate Awing, which cannot model Awing tone — the same reason
    // the Bible-trained VITS attempt failed above. A confident wrong
    // pronunciation of a tonal language teaches children the wrong word,
    // so this project now treats synthesized Awing as fabrication and
    // ships silence instead.
    //
    // Every tier left in this list is a RECORDING OF A HUMAN:
    //   native_kids/ — a family member
    //   native/      — Dr. Sama
    //   community/   — a contributor
    //
    // Do not re-add a synthetic tier here. If a word has no recording the
    // UI shows a Record button (see hasNativeAudio) and asks the
    // community for one.
    return paths;
  }

  /// Play a human recording of an Awing word, or do nothing.
  ///
  /// v1.24.0: there is no synthetic fallback any more. Silence is the
  /// correct answer for a word nobody has recorded — ask
  /// [hasNativeAudio] first and offer the Record button instead of a
  /// speaker.
  /// [english] disambiguates words that share an Awing spelling.
  ///
  /// Session 66w. A clip was keyed on the AWING SPELLING ALONE and
  /// _audioKey() strips tone, so `mbaŋə` (rain) and `mbáŋə` (the maggot-like
  /// insect in raffia palm) both resolved to `mbange.opus` - and so did
  /// `mbaŋə` cane, walking stick, stomach disease and three more that are
  /// spelled identically. 176 clips were answering for 604 cards, so 428
  /// cards played a recording made for a different word. Dr. Sama, hearing
  /// it: "seems you name both audios the same."
  ///
  /// The IMAGE key never had this problem - it is audioKey + '__' +
  /// englishSlug, which is why `mbange__rain` and `mbange__tumor` are
  /// different pictures. Audio now asks for that same key FIRST and falls
  /// back to the bare key, so a clip that has not been renamed yet still
  /// plays. That fallback is what makes the migration safe to do in
  /// stages: at no point does a word go silent.
  Future<void> speakAwing(String awingWord, {String? english}) async {
    await init();

    for (final key in _clipKeys(awingWord, english)) {
      for (final category in [
        'vocabulary',
        'alphabet',
        'dictionary',
        'sentences'
      ]) {
        for (final path in _buildSearchPaths(key, category)) {
          if (await _playAudioAsset(path)) return;
        }
      }
    }

    // No recording exists. Deliberately silent — see _buildSearchPaths.
    if (kDebugMode) {
      debugPrint('Pronunciation: no human recording for "$awingWord"; '
          'staying silent (v1.24.0).');
    }
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
        // v1.24.0: no synthetic Awing. A word with no recording is simply
        // skipped, so the parts of the sentence that ARE recorded still
        // read aloud correctly instead of being interrupted by a wrong
        // machine pronunciation.
        await Future.delayed(const Duration(milliseconds: 150));
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

    // v1.24.0: no synthetic fallback. A letter sound is Awing phonology,
    // and an English or Swahili voice guessing it is exactly the wrong
    // thing to teach. 27 of the 31 letters have native recordings; the
    // remainder stay silent until someone records them.
    if (kDebugMode) {
      debugPrint('Pronunciation: no human recording for sound "$phoneme"; '
          'staying silent (v1.24.0).');
    }
  }

  /// Stop any current audio or speech
  Future<void> stop() async {
    await _audioPlayer.stop();
    await _tts.stop();
  }

  /// Check if a real audio recording exists for this word.
  /// Whether a HUMAN recording exists for this word.
  ///
  /// v1.24.0 — this used to be broken in two ways, and it mattered once
  /// the UI started depending on it:
  ///   1. it ignored `_playAudioAsset`'s return value and returned `true`
  ///      for the first path it tried, so it answered "yes" for every
  ///      word in the dictionary;
  ///   2. it answered by PLAYING the clip and then stopping it, so a
  ///      silent existence check made noise.
  /// It also had no callers, so neither fault was ever visible.
  ///
  /// Now it asks the asset pack whether the file is there and plays
  /// nothing. Used by the UI to choose between a speaker button and a
  /// Record button.
  /// [clipKey] is for callers that store a sentence clip under a name of
  /// their own (the phrase book). Without it a phrase would be reported as
  /// unrecorded even when its clip is in the pack, because the auto key is
  /// derived from the text rather than the clip name.
  /// The clip names to try, most specific first. See [speakAwing].
  ///
  /// The bare key is DROPPED when kAudioClipClaims says that clip was
  /// recorded for a different meaning. mbange.opus is one native
  /// recording of ONE of rain / tumor / cane / walking stick / the raffia
  /// palm insect; letting the other eight fall back to it is how 428
  /// cards came to play the wrong word.
  ///
  /// The result is silence on those cards until each gets its own
  /// recording. That is the right answer here. The app already treats
  /// silence as valid - "there is no synthetic fallback any more" - and
  /// on a vocabulary card for a child, hearing nothing is better than
  /// hearing a different word and learning it.
  ///
  /// With no [english] there is nothing to compare, so the bare key is
  /// kept and behaviour is exactly as before.
  List<String> _clipKeys(String awingWord, String? english) {
    final out = <String>[];
    final gloss = english?.trim() ?? '';
    if (gloss.isNotEmpty) {
      out.add(ImageService.imageKey(awingWord, gloss));
    }
    final bare = _audioKey(awingWord);
    final claimedBy = kAudioClipClaims[bare];
    final takenByAnother = gloss.isNotEmpty &&
        claimedBy != null &&
        claimedBy.toLowerCase() != gloss.toLowerCase();
    if (!takenByAnother && !out.contains(bare)) out.add(bare);
    return out;
  }

  Future<bool> hasNativeAudio(String awingWord,
      {String? clipKey, String? english}) async {
    await init();
    if (clipKey != null) {
      for (final asset in _buildSearchPaths(clipKey, 'sentences')) {
        try {
          if (await _assetPack.assetExists(asset.replaceFirst('assets/', ''))) {
            return true;
          }
        } catch (_) {
          // Unreadable pack entry — treat as absent and keep looking.
        }
      }
    }
    for (final key in _clipKeys(awingWord, english)) {
      for (final category in [
        'vocabulary',
        'alphabet',
        'dictionary',
        'sentences'
      ]) {
        for (final asset in _buildSearchPaths(key, category)) {
          try {
            if (await _assetPack
                .assetExists(asset.replaceFirst('assets/', ''))) {
              return true;
            }
          } catch (_) {
            // Unreadable pack entry — treat as absent and keep looking.
          }
        }
      }
    }
    return false;
  }

  /// Former name, kept so existing call sites keep compiling.
  @Deprecated('Use hasNativeAudio — this name predates the v1.24.0 '
      'removal of synthetic audio, when "real" still needed saying.')
  Future<bool> hasRealAudio(String awingWord) => hasNativeAudio(awingWord);

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

    // v1.24.2 (Session 66p) — map the remaining pre-composed letters
    // BEFORE the strip below deletes them outright.
    //
    // The strip is a catch-all for leftover combining marks, which is
    // correct: 'kə̌' -> 'ke' loses only the caron. But a pre-composed
    // letter that never reached the maps above is a whole letter, and the
    // strip removed it silently. 'apʉə' keyed to 'ape' and therefore
    // played a DIFFERENT word's recording; 'tśəmə' ("stand") keyed to
    // 'teme'; 'tă' keyed to 't', colliding with the alphabet letter clip.
    //
    // These are the exact characters present in lib/data, counted from
    // the content rather than guessed: ń×37 ü×35 ʉ×27 ś×11 ä×7 ō×6 and a
    // tail of singletons. Several are plainly OCR damage (Greek ε for ɛ,
    // ł, ø, ğ) but mapping them to a sensible base letter still beats
    // deleting them.
    key = key
        .replaceAll('ʃ', 'sh').replaceAll('ɣ', 'gh')
        .replaceAll('ń', 'n')
        .replaceAll('ü', 'u').replaceAll('ʉ', 'u').replaceAll('ū', 'u')
        .replaceAll('ŭ', 'u')
        .replaceAll('ś', 's').replaceAll('š', 's')
        .replaceAll('ä', 'a').replaceAll('ā', 'a').replaceAll('ă', 'a')
        .replaceAll('ạ', 'a')
        .replaceAll('ō', 'o').replaceAll('õ', 'o').replaceAll('ø', 'o')
        .replaceAll('ī', 'i')
        .replaceAll('ē', 'e').replaceAll('ĕ', 'e')
        .replaceAll('ε', 'e').replaceAll('έ', 'e')
        .replaceAll('ł', 'l').replaceAll('ğ', 'g');

    // Glottal stop and the modifier apostrophe join the plain apostrophe
    // handled above; the aspiration modifier carries no segment.
    key = key
        .replaceAll('\u02bc', '').replaceAll('\u0294', '')
        .replaceAll('\u02b0', '');

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
