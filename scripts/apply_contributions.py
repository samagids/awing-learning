#!/usr/bin/env python3
"""
apply_contributions.py — Apply approved contributions to Dart data files.

Reads approved_contributions.json from the contributions/ folder and applies
spelling corrections, pronunciation fixes, and new words/sentences to the
Dart source files in lib/data/.

Usage:
    python scripts/apply_contributions.py                  # Apply all approved
    python scripts/apply_contributions.py --list           # List pending changes
    python scripts/apply_contributions.py --dry-run        # Preview without modifying
    python scripts/apply_contributions.py --clean          # Remove processed file
    python scripts/apply_contributions.py --reset-version  # Re-pull every approved
                                                           # contribution from the
                                                           # webhook (useful after a
                                                           # server-side schema change)
    python scripts/apply_contributions.py --replace-audio  # Let a re-recording
                                                           # OVERWRITE the native clip
                                                           # it replaces. Off by
                                                           # default. The displaced
                                                           # clip is copied to
                                                           # contributions/replaced_
                                                           # native_audio/ first.
    python scripts/apply_contributions.py --download       # Download only, don't apply
    python scripts/apply_contributions.py --refetch-audio  # Re-download m4a + re-run
                                                           # Whisper for pronunciation
                                                           # fixes already archived in
                                                           # contributions/applied/.
                                                           # Use after redeploying the
                                                           # webhook so you don't have
                                                           # to re-record the word.

The build_and_run.bat script calls this automatically before generating audio.

Pronunciation fix design (v2 — reference-only):
  The developer's raw recording is NEVER played in the app. Instead:
    1. The m4a is downloaded from Drive and saved as a REFERENCE file at
       contributions/voice_references/{key}.m4a (overwrites on re-record —
       latest wins). This is a training corpus for future model fine-tuning.
    2. If a pronunciationGuide was typed by the developer, it becomes the
       speakable_override for Edge TTS.
    3. Otherwise, if OpenAI Whisper is installed, the recording is
       transcribed (Swahili-biased) and the transcription becomes the
       speakable_override.
    4. Otherwise the fix still queues for Edge TTS regeneration using the
       default awing_to_speakable() pronunciation mapping.
  Edge TTS then regenerates the word in all 6 character voices using the
  override — the learner always hears the mode-appropriate character voice
  (boy/girl for beginner, young_man/young_woman for medium, man/woman for
  expert), not the developer's voice.

Latest-wins dedup:
  When the same target word is approved multiple times, only the
  highest-version contribution per (type, target) is applied. Older
  duplicates are discarded so we never apply an outdated correction.
"""

import json
import os
import re
import sys
import shutil
import unicodedata
import subprocess
import tempfile
import urllib.request
import urllib.error
from datetime import datetime

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)

# Newline literal — used by helpers that build multi-line strings
# without relying on f-strings (heredoc-safe).
NL = chr(10)
CONTRIBUTIONS_DIR = os.path.join(PROJECT_DIR, 'contributions')
APPROVED_FILE = os.path.join(CONTRIBUTIONS_DIR, 'approved_contributions.json')
APPLIED_DIR = os.path.join(CONTRIBUTIONS_DIR, 'applied')
WEBHOOKS_FILE = os.path.join(PROJECT_DIR, 'config', 'webhooks.json')
VERSION_FILE = os.path.join(CONTRIBUTIONS_DIR, 'last_version.txt')

REGENERATE_FILE = os.path.join(CONTRIBUTIONS_DIR, 'regenerate_words.json')
# Developer voice recordings are archived here as a future training corpus.
# They are NEVER played directly in the app — the 6 Edge TTS character voices
# are always what the learner hears.
VOICE_REFERENCES_DIR = os.path.join(CONTRIBUTIONS_DIR, 'voice_references')

# v1.22.0 (Session 66): user-contributed vocabulary images land in the
# PAD (Play Asset Delivery) images folder alongside the SDXL-generated
# images. Filename matches the audio_key so PackImage / word cards find
# it via the same key derivation as the app uses. Contributed images
# override AI-generated ones (they're written last).
VOCAB_IMAGES_DIR = os.path.join(
    PROJECT_DIR, 'android', 'install_time_assets', 'src', 'main', 'assets',
    'images', 'vocabulary')


# ============================================================
# SECURITY: input sanitization
# ============================================================
# Every user-submitted string that lands in a Dart source file MUST go
# through these helpers. Without them, a malicious contribution payload
# could inject arbitrary Dart code into the project (e.g. an `english`
# field of "x'); print(open('/etc/passwd').read()); ('", which would
# get embedded verbatim into a vocabulary AwingWord literal and execute
# at next build).
#
# The contributions webhook is a public endpoint — assume hostile input.

# Length limits — generous but bounded.
MAX_AWING_LEN = 80          # A single Awing word or short phrase.
MAX_ENGLISH_LEN = 200       # English gloss or short sentence translation.
MAX_CATEGORY_LEN = 32       # Category name (allowlisted further below).
MAX_SENTENCE_LEN = 300      # A whole Awing sentence + punctuation.

# Awing alphabet: a-z A-Z + special vowels + tone diacritics (combining
# acute, grave, circumflex, caron) + apostrophe + space + a few common
# punctuation marks. Anything else means probably an injection attempt.
_AWING_OK_RE = re.compile(
    r"^[A-Za-zɛɔəɨŋɣÆ"
    r"̀́̂̌̃"  # combining diacritics
    r"'’‘"                    # apostrophes (straight + curly)
    r" \-.,;:!\?\(\)\[\] ]+$",
    re.UNICODE,
)
# Allowed English chars: letters, digits, spaces, basic punctuation.
# Notably DISALLOWED: backslash, quote, paren-bracket-bracket combos
# that could close+reopen a Dart string literal.
_ENGLISH_OK_RE = re.compile(
    r"^[A-Za-z0-9 \-.,;:!\?\(\)/'’]+$",
)
_CATEGORY_OK_RE = re.compile(r"^[a-z_]{1,32}$")


def _dart_string_literal(s):
    """Return a safe Dart-quoted string literal for s. Always uses
    single quotes; escapes any character that would terminate the
    literal or inject code. Output is guaranteed parsable by Dart."""
    if not isinstance(s, str):
        s = str(s)
    # Strip null bytes outright (no legitimate use, breaks tooling).
    s = s.replace('\x00', '')
    # Backslash MUST be escaped first, before we add new backslashes.
    s = s.replace('\\', '\\\\')
    s = s.replace("'", "\\'")
    s = s.replace('\n', '\\n').replace('\r', '\\r').replace('\t', '\\t')
    # $ and ${} are interpolation in Dart strings — escape both.
    s = s.replace('$', '\\$')
    return "'" + s + "'"


class ContributionRejected(ValueError):
    """Raised when a contribution fails sanity validation. The caller
    should log + skip without modifying any source file."""


def _validate_awing(s, max_len=MAX_AWING_LEN, field_name='awing'):
    """Reject Awing strings that look like injection attempts. Length
    cap + character allowlist + must-not-contain Dart syntax.

    We NFD-decompose before checking the allowlist so pre-composed
    Latin-with-diacritic codepoints (e.g. 'ô' U+00F4, 'ě' U+011B,
    'á' U+00E1) split into base ASCII letter + combining mark, both
    of which appear in the allowlist. Without this step, every word
    containing a tone-marked Latin vowel would get rejected.
    """
    if not isinstance(s, str) or not s.strip():
        raise ContributionRejected(f"{field_name}: empty or non-string")
    s = s.strip()
    if len(s) > max_len:
        raise ContributionRejected(
            f"{field_name}: too long ({len(s)} > {max_len})"
        )
    s_nfd = unicodedata.normalize('NFD', s)
    if not _AWING_OK_RE.match(s_nfd):
        # Find offending chars for the log (in the original NFC form for
        # readability — the user submitted NFC text; report NFC chars).
        bad = ''.join(sorted(set(
            c for c in unicodedata.normalize('NFD', s)
            if not _AWING_OK_RE.match(c)
        )))
        raise ContributionRejected(
            f"{field_name}: contains disallowed chars: {bad!r}"
        )
    # Defense in depth: explicitly forbid Dart syntax tokens.
    for token in ('//', '/*', '*/', "'''", '"""', '${', '\\u', '\\x'):
        if token in s:
            raise ContributionRejected(
                f"{field_name}: contains forbidden token {token!r}"
            )
    return s


def _validate_english(s, max_len=MAX_ENGLISH_LEN, field_name='english'):
    """Reject English glosses that look like injection."""
    if not isinstance(s, str) or not s.strip():
        raise ContributionRejected(f"{field_name}: empty or non-string")
    s = s.strip()
    if len(s) > max_len:
        raise ContributionRejected(
            f"{field_name}: too long ({len(s)} > {max_len})"
        )
    if not _ENGLISH_OK_RE.match(s):
        bad = ''.join(sorted(set(c for c in s if not _ENGLISH_OK_RE.match(c))))
        raise ContributionRejected(
            f"{field_name}: contains disallowed chars: {bad!r}"
        )
    for token in ('//', '/*', '*/', "'''", '"""', '${', '\\u', '\\x',
                  'AwingWord', 'AwingSentence', 'AwingPhrase', 'import '):
        if token in s:
            raise ContributionRejected(
                f"{field_name}: contains forbidden token {token!r}"
            )
    return s


def _validate_category(s):
    """Category MUST be in our explicit allowlist — never pass user-
    supplied categories through unsanitized."""
    allowed = {
        'body', 'animals', 'nature', 'actions', 'things', 'family',
        'daily', 'greeting', 'question', 'farewell', 'food',
        'descriptive', 'numbers', 'pronouns', 'time', 'general',
        'classroom',
    }
    if not isinstance(s, str):
        raise ContributionRejected('category: non-string')
    s = s.strip().lower()
    if s not in allowed:
        raise ContributionRejected(
            f'category: {s!r} not in allowlist {sorted(allowed)}'
        )
    return s


def _validate_audio_url(url):
    """Audio URLs must be on Drive (or Apps Script proxy). Reject
    anything else to prevent SSRF — a malicious audioUrl pointing at
    an internal IP, file://, or attacker-controlled host could be
    used to scan the dev's network or fetch malware."""
    if not isinstance(url, str) or not url.startswith(('https://')):
        raise ContributionRejected('audioUrl: must be https://')
    allowed_hosts = (
        'drive.google.com',
        'docs.google.com',
        'script.google.com',
        'script.googleusercontent.com',
    )
    # Crude but reliable host check.
    after_scheme = url[len('https://'):]
    host = after_scheme.split('/', 1)[0].split('?', 1)[0].lower()
    if host not in allowed_hosts and not any(host.endswith('.' + h) for h in allowed_hosts):
        raise ContributionRejected(
            f'audioUrl: host {host!r} not in allowlist {allowed_hosts}'
        )
    return url


def _validate_image_url(url):
    """v1.22.0 (Session 66): mirror of _validate_audio_url for image
    contributions. Same allowlist — the webhook stores images in the
    same Drive account audio lives in, so the trust boundary is
    identical."""
    if not isinstance(url, str) or not url.startswith(('https://')):
        raise ContributionRejected('imageUrl: must be https://')
    allowed_hosts = (
        'drive.google.com',
        'docs.google.com',
        'script.google.com',
        'script.googleusercontent.com',
    )
    after_scheme = url[len('https://'):]
    host = after_scheme.split('/', 1)[0].split('?', 1)[0].lower()
    if host not in allowed_hosts and not any(host.endswith('.' + h) for h in allowed_hosts):
        raise ContributionRejected(
            f'imageUrl: host {host!r} not in allowlist {allowed_hosts}'
        )
    return url

# Legacy file from the v1 pronunciationFix design (Session 48) that installed
# the raw recording into every voice directory. If found, we delete it on
# first run so the refactored pipeline starts clean.
LEGACY_NATIVE_RECORDINGS_FILE = os.path.join(CONTRIBUTIONS_DIR, 'native_recordings.json')

# Dart data files
VOCAB_FILE = os.path.join(PROJECT_DIR, 'lib', 'data', 'awing_vocabulary.dart')
ALPHABET_FILE = os.path.join(PROJECT_DIR, 'lib', 'data', 'awing_alphabet.dart')
TONES_FILE = os.path.join(PROJECT_DIR, 'lib', 'data', 'awing_tones.dart')

# PAD asset pack audio directory — where Edge TTS writes, and where
# native speaker recordings are copied so the app can use them.
AUDIO_DIR = os.path.join(
    PROJECT_DIR, 'android', 'install_time_assets', 'src', 'main', 'assets', 'audio'
)
VOICE_DIRS = ['boy', 'girl', 'young_man', 'young_woman', 'man', 'woman']


def ensure_directories():
    """Create contributions/, contributions/applied/, and the voice
    references archive dir if they don't exist."""
    os.makedirs(CONTRIBUTIONS_DIR, exist_ok=True)
    os.makedirs(APPLIED_DIR, exist_ok=True)
    os.makedirs(VOICE_REFERENCES_DIR, exist_ok=True)
    # One-time cleanup of the legacy v1 state file, if present.
    if os.path.exists(LEGACY_NATIVE_RECORDINGS_FILE):
        try:
            os.remove(LEGACY_NATIVE_RECORDINGS_FILE)
        except OSError:
            pass


# ------------------------------------------------------------------
# Audio helpers (native speaker recording pipeline)
# ------------------------------------------------------------------

def _audio_key(awing_text):
    """Delegates to scripts/awing_key.py — the single derivation shared
    with Dart's PronunciationService._audioKey(). See that file for why
    three derivations existed and what each got wrong."""
    import os as _os, sys as _sys
    _d = _os.path.dirname(_os.path.abspath(__file__))
    if _d not in _sys.path:
        _sys.path.insert(0, _d)
    from awing_key import audio_key as _ak
    return _ak(awing_text)


def _is_alphabet_letter(awing_word):
    """Heuristic: check if a target word is an alphabet letter.

    Alphabet keys in the app correspond to single letters / digraphs /
    trigraphs from awing_alphabet.dart — they're short (typically 1-4
    chars) and the key appears in the alphabet Dart file.
    """
    if not awing_word or len(awing_word) > 4:
        return False
    try:
        with open(ALPHABET_FILE, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception:
        return False
    # Look for `letter: 'X'` or `letter: "X"` exactly matching the target
    pat_s = re.compile(r"letter:\s*'" + re.escape(awing_word) + r"'", re.UNICODE)
    pat_d = re.compile(r'letter:\s*"' + re.escape(awing_word) + r'"', re.UNICODE)
    return bool(pat_s.search(content) or pat_d.search(content))


def _guess_category(awing_word):
    """Pick the audio subdirectory (alphabet/vocabulary/sentences/stories)
    based on the contribution's target word.

    Heuristic:
      - Contains spaces → 'sentences' (multi-word phrase or sentence)
      - Matches an alphabet letter → 'alphabet'
      - Otherwise → 'vocabulary'
    """
    if not awing_word:
        return 'vocabulary'
    if ' ' in awing_word.strip():
        return 'sentences'
    if _is_alphabet_letter(awing_word):
        return 'alphabet'
    return 'vocabulary'


def _extract_drive_file_id(url):
    """Parse a Google Drive share URL to extract the file ID.

    Handles:
      https://drive.google.com/file/d/FILEID/view?usp=...
      https://drive.google.com/uc?id=FILEID&export=download
      https://drive.google.com/open?id=FILEID
    Returns the file id string or None.
    """
    if not url:
        return None
    m = re.search(r'/file/d/([a-zA-Z0-9_-]+)', url)
    if m:
        return m.group(1)
    m = re.search(r'[?&]id=([a-zA-Z0-9_-]+)', url)
    if m:
        return m.group(1)
    return None


def _download_drive_file(audio_url, dest_path):
    """Download a Google Drive audio file to dest_path.

    Converts share-link URLs to direct-download URLs. Returns True on
    success, False on any failure (non-fatal — caller falls back to
    Edge TTS regeneration).
    """
    file_id = _extract_drive_file_id(audio_url)
    if not file_id:
        print(f"  ✗ Could not parse Drive URL: {audio_url}")
        return False

    direct_url = f"https://drive.google.com/uc?export=download&id={file_id}"
    try:
        req = urllib.request.Request(direct_url, headers={
            'User-Agent': 'Mozilla/5.0 (apply_contributions)',
        })
        with urllib.request.urlopen(req, timeout=60) as resp:
            data = resp.read()
        if len(data) < 1024:
            # Probably an HTML error page, not the audio — Drive sometimes
            # shows a virus-scan page for files > 100 MB, but m4a clips are
            # tiny so we should always get the binary.
            print(f"  ✗ Drive response too small ({len(data)} bytes) — probably an error page")
            return False
        with open(dest_path, 'wb') as f:
            f.write(data)
        return True
    except Exception as e:
        print(f"  ✗ Drive download failed: {e}")
        return False


def _find_ffmpeg():
    """Locate the ffmpeg binary. Returns path or None."""
    for candidate in ['ffmpeg', 'ffmpeg.exe']:
        resolved = shutil.which(candidate)
        if resolved:
            return resolved
    return None


def _convert_m4a_to_mp3(m4a_path, mp3_path):
    """Convert m4a → mp3 via ffmpeg. Returns True on success."""
    ffmpeg = _find_ffmpeg()
    if not ffmpeg:
        print(f"  ✗ ffmpeg not found on PATH — cannot convert {m4a_path}")
        return False
    try:
        result = subprocess.run(
            [ffmpeg, '-y', '-loglevel', 'error',
             '-i', m4a_path,
             '-codec:a', 'libmp3lame', '-q:a', '4',
             mp3_path],
            capture_output=True,
            text=True,
            timeout=60,
        )
        if result.returncode != 0:
            print(f"  ✗ ffmpeg failed: {result.stderr.strip()}")
            return False
        return os.path.exists(mp3_path) and os.path.getsize(mp3_path) > 0
    except Exception as e:
        print(f"  ✗ ffmpeg error: {e}")
        return False


# Set by --replace-audio. Off by default, and it must stay off by
# default: a contributor's recording must never silently overwrite a clip
# that is already shipping. It is turned on only for a developer run that
# exists specifically to fix a clip that sounds wrong.
REPLACE_EXISTING_AUDIO = False


def _promote_references_to_native(keys):
    """Convert freshly archived voice references into native audio clips.

    Delegates to scripts/apply_voice_references_as_native.py so there is
    one implementation of the conversion: silence-trimmed via
    scripts/trim_silence.py, written as .opus (48 kHz mono, playback) plus
    .wav (16 kHz mono, the pronunciation grader reference), and skipped
    entirely when the word already has a clip.

    Trimming is the reason this delegates rather than shelling out to
    ffmpeg here. Raw submissions carry the pause either side of the word;
    untrimmed, the median clip measured 1.68s against 0.56s for audio
    already shipping, worst case 9.34s.

    Returns the number of clips written. Never raises -- a contribution
    run must not fail because audio tooling is missing on this machine.
    """
    if not keys:
        return 0
    try:
        import importlib.util
        mod_path = os.path.join(SCRIPT_DIR, 'apply_voice_references_as_native.py')
        if not os.path.exists(mod_path):
            print('  (apply_voice_references_as_native.py not found -- '
                  'recordings archived but not promoted)')
            return 0
        spec = importlib.util.spec_from_file_location('_promote', mod_path)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)

        if not mod.have_ffmpeg():
            print('  (ffmpeg not on PATH -- recordings archived but not '
                  'promoted; re-run after installing ffmpeg)')
            return 0

        out_dir = os.path.join(mod.NATIVE_DIR, mod.DEFAULT_CATEGORY)
        written = 0
        for key in keys:
            src = os.path.join(mod.REFS_DIR, key + '.m4a')
            if not os.path.exists(src):
                continue
            prior = mod.existing_native(key)
            if prior and not REPLACE_EXISTING_AUDIO:
                continue          # never overwrite a clip that exists
            if prior:
                # Keep the displaced clip. A replacement can be worse than
                # what it replaced, and without this there is nothing to
                # go back to - the original only existed inside the AAB.
                bak_dir = os.path.join(PROJECT_DIR, 'contributions',
                                       'replaced_native_audio')
                os.makedirs(bak_dir, exist_ok=True)
                stamp = datetime.now().strftime('%Y%m%d_%H%M%S')
                for ext in ('.opus', '.wav', '.mp3'):
                    old_p = os.path.splitext(prior)[0] + ext
                    if os.path.exists(old_p):
                        shutil.copy2(
                            old_p,
                            os.path.join(bak_dir, f'{key}_{stamp}{ext}'))
                print(f'  ↻ {key}: replacing the existing clip '
                      f'(old one kept in contributions/replaced_native_audio/)')
            os.makedirs(out_dir, exist_ok=True)
            status, detail = mod.convert(
                src,
                os.path.join(out_dir, key + '.opus'),
                os.path.join(out_dir, key + '.wav'))
            if status == 'ok':
                written += 1
            elif status == 'silent':
                print(f'  ⚠ {key}: recording is entirely silent — not shipped')
            else:
                print(f'  ⚠ {key}: could not promote ({detail})')
        return written
    except Exception as e:
        print(f'  (promotion to native tier failed: {e!s:.120})')
        return 0


def _archive_voice_reference(audio_url, awing_word, dry_run=False):
    """Download the developer's recording and save it as a REFERENCE file
    at contributions/voice_references/{key}.m4a.

    The recording is NEVER played in the app — it is a future training
    corpus for fine-tuning the character voices. Re-recording the same
    word simply overwrites the previous reference, implementing
    latest-wins for the archive.

    Returns (archived: bool, key: str, m4a_path: Optional[str]).
    `m4a_path` is only set on success and is passed to the optional
    Whisper transcription step.
    """
    key = _audio_key(awing_word)
    if not key:
        print(f"  ✗ Could not derive audio key from '{awing_word}'")
        return False, '', None

    dest_path = os.path.join(VOICE_REFERENCES_DIR, f'{key}.m4a')

    if dry_run:
        print(f"  [DRY RUN] Would download {audio_url}")
        print(f"  [DRY RUN] Would archive to {dest_path} (overwrites if exists)")
        return True, key, None

    os.makedirs(VOICE_REFERENCES_DIR, exist_ok=True)
    print(f"  → Downloading voice reference from Drive...")
    if not _download_drive_file(audio_url, dest_path):
        return False, key, None

    size_kb = os.path.getsize(dest_path) / 1024.0
    print(f"  ✓ Archived reference: voice_references/{key}.m4a ({size_kb:.1f} KB)")
    return True, key, dest_path


# v1.24.5: approved contributor images are recorded here so
# generate_images.py knows never to overwrite or delete one. Without it the
# next build regenerates the SDXL picture over the top and the contribution
# vanishes with no error anywhere.
CONTRIBUTED_IMAGES_FILE = os.path.join(
    CONTRIBUTIONS_DIR, 'contributed_images.json')


def _record_contributed_image(key, awing_word, english, profile):
    """Append one image key to the protected list. Idempotent."""
    try:
        existing = []
        if os.path.exists(CONTRIBUTED_IMAGES_FILE):
            with open(CONTRIBUTED_IMAGES_FILE, 'r', encoding='utf-8') as f:
                existing = json.load(f)
        if any(e.get('key') == key for e in existing):
            return
        existing.append({
            'key': key,
            'awing': awing_word,
            'english': english,
            'contributor': profile,
            'installed_at': datetime.now().isoformat(),
        })
        os.makedirs(CONTRIBUTIONS_DIR, exist_ok=True)
        with open(CONTRIBUTED_IMAGES_FILE, 'w', encoding='utf-8') as f:
            json.dump(existing, f, indent=2, ensure_ascii=False)
    except Exception as exc:
        print(f"  ⚠ Could not record contributed image {key}: {exc}")


def _glosses_for(awing_word, vocab_content):
    """Every English gloss the vocabulary carries for this exact Awing word.

    A contributor photographs a WORD, but the app looks images up by
    (awing, english) so homonyms get their own picture. One photo of a
    cheek should therefore be installed for every gloss of that spelling,
    or the card the contributor was actually looking at may be the one
    that stays blank.
    """
    out = []
    pattern = re.compile(
        r"AwingWord\(\s*awing:\s*'((?:[^'\\]|\\.)*)'\s*,\s*"
        r"english:\s*'((?:[^'\\]|\\.)*)'")
    for m in pattern.finditer(vocab_content):
        if m.group(1) == awing_word:
            out.append(m.group(2))
    return out


def _install_vocabulary_image(image_url, awing_word, profile,
                              vocab_content=None, english_hint='',
                              dry_run=False):
    """Download an approved contributor photo and install it as the
    vocabulary card image for `awing_word`.

    v1.24.5 — THIS WAS BROKEN FROM THE DAY IT SHIPPED (v1.22.0).

    It saved `{audio_key(awing)}.png`. The app asks for
    `{audio_key(awing)}__{english_slug(english)}` — see
    ImageService.packPath. No contributed image has ever appeared on a
    card: the file landed in the pack under a name nothing requests, and
    because a missing image is a silent fallback, nobody saw an error.
    Evidence at the time of the fix: zero .png files in the vocabulary
    image folder, and every one of the 9,025 pack images carrying the
    `__` that this function never wrote.

    Now installs under the real key, once per gloss of that spelling, and
    records each key so the generator leaves it alone.
    """
    if not awing_word:
        print("  ✗ No target word for image install")
        return False

    glosses = []
    if vocab_content:
        glosses = _glosses_for(awing_word, vocab_content)
    if not glosses and english_hint:
        # A brand-new word is not in the vocabulary yet when its image
        # arrives alongside it; the submission's own English is right.
        glosses = [english_hint]
    if not glosses:
        print(f"  ✗ No English gloss known for '{awing_word}' — cannot "
              f"build the image key the app looks up. Image not installed.")
        return False

    keys = []
    for gloss in glosses:
        try:
            from awing_key import image_key as _ik
            keys.append((_ik(awing_word, gloss), gloss))
        except Exception as exc:
            print(f"  ✗ Could not derive image key for "
                  f"'{awing_word}' / '{gloss}': {exc}")
    if not keys:
        return False

    if dry_run:
        print(f"  [DRY RUN] Would download {image_url}")
        for key, gloss in keys:
            print(f"  [DRY RUN] Would install images/vocabulary/{key}.png "
                  f"({gloss}, from {profile})")
        return True

    os.makedirs(VOCAB_IMAGES_DIR, exist_ok=True)
    print("  → Downloading vocabulary image from Drive...")

    first_key = keys[0][0]
    first_path = os.path.join(VOCAB_IMAGES_DIR, f'{first_key}.png')
    if not _download_drive_file(image_url, first_path):
        return False

    size_kb = os.path.getsize(first_path) / 1024.0
    for i, (key, gloss) in enumerate(keys):
        dest = os.path.join(VOCAB_IMAGES_DIR, f'{key}.png')
        if i > 0:
            shutil.copyfile(first_path, dest)
        # The generator writes .webp. A contributed .png at the same stem
        # would lose the lookup to it (the app resolves webp first), so the
        # generated one goes. The key is recorded below, so it will not
        # come back on the next run.
        stale_webp = os.path.join(VOCAB_IMAGES_DIR, f'{key}.webp')
        if os.path.exists(stale_webp):
            try:
                os.remove(stale_webp)
                print(f"    removed generated {key}.webp — "
                      f"the contributed photo wins")
            except OSError as exc:
                print(f"    ! could not remove {key}.webp: {exc}")
        _record_contributed_image(key, awing_word, gloss, profile)
        print(f"  ✓ Installed image: images/vocabulary/{key}.png "
              f"({size_kb:.1f} KB, {gloss}, from {profile})")
    return True


# Module-level flag so we only print the "Whisper missing" banner once
# per run even when dozens of pronunciation fixes are processed in a loop.
_WHISPER_WARNED = False


# Words whose Whisper transcription was rejected as implausible, written
# here for Dr. Sama to review. Never consumed by the build.
WHISPER_REJECTED_FILE = os.path.join(
    CONTRIBUTIONS_DIR, 'whisper_rejected.json')

# Minimum character-level similarity between the submitted Awing and
# Whisper's transcription before the transcription is trusted as a
# speakable override. Calibrated on the 13 pronunciation fixes applied on
# 2026-10-05: it keeps every plausible phonetic rendering and rejects
# every hallucination. See _whisper_plausible().
WHISPER_MIN_SIMILARITY = 0.60

# Higher bar when Whisper returns pure ASCII for a word written with
# non-ASCII Awing characters -- the signature of it resolving the audio
# into English rather than transcribing it.
WHISPER_ASCII_MIN_SIMILARITY = 0.75


def _whisper_plausible(target, text):
    """Is `text` a plausible ASR rendering of the Awing word `target`?

    Whisper is an English/Swahili-trained model being asked to transcribe
    Awing. When it has nothing to latch onto it does not fail — it
    hallucinates confidently, and the result used to be written straight
    into regenerate_words.json as the authoritative pronunciation. On
    2026-10-05, 'ambáŋá' came back as "I'm Buna", 'alá'ə' as
    'alá'əəəəringe', and 'aləmə̌' as 'aləmə̌ aləmə̌ kiye'.

    That is fabricated Awing, which this project does not ship.

    This is deliberately NOT an orthography judgement — it does not decide
    what is correct, it only decides whether the ASR output corresponds to
    the word that was submitted. On rejection the submitted spelling (Dr.
    Sama's own input) stands and the word is flagged for review.

    Returns (ok, reason).
    """
    import difflib
    import unicodedata

    t = unicodedata.normalize('NFC', (target or '').strip())
    x = unicodedata.normalize('NFC', (text or '').strip())

    if not x:
        return False, 'empty transcription'
    if x == t:
        return True, 'exact match'

    # A different number of words means Whisper heard extra speech, or
    # dropped half the word. Both produce nonsense overrides.
    tw, xw = len(t.split()), len(x.split())
    if tw != xw:
        return False, f'word count {tw} -> {xw}'

    ratio = difflib.SequenceMatcher(None, t.casefold(), x.casefold()).ratio()

    # Awing uses characters English does not. A transcription that comes
    # back pure ASCII when the target is not has often been resolved into
    # English, so hold it to a higher bar -- but do NOT veto it outright:
    # 'nkagə' -> 'nkaga' is a schwa rendered as 'a', which is exactly the
    # phonetic approximation this pipeline wants.
    floor = WHISPER_MIN_SIMILARITY
    note = ''
    if any(ord(c) > 127 for c in t) and all(ord(c) < 128 for c in x):
        floor = WHISPER_ASCII_MIN_SIMILARITY
        note = ', ASCII-only transcription of a non-ASCII word'

    if ratio < floor:
        return False, f'similarity {ratio:.2f} < {floor}{note}'

    return True, f'similarity {ratio:.2f}{note}'


def _record_whisper_rejection(target, text, reason, english=''):
    """Append a rejected transcription to the review file."""
    rows = []
    if os.path.exists(WHISPER_REJECTED_FILE):
        try:
            with open(WHISPER_REJECTED_FILE, 'r', encoding='utf-8') as f:
                rows = json.load(f)
            if not isinstance(rows, list):
                rows = []
        except Exception:
            rows = []
    rows = [r for r in rows if r.get('awing') != target]
    rows.append({
        'awing': target,
        'english': english,
        'whisper_said': text,
        'rejected_because': reason,
    })
    try:
        ensure_directories()
        with open(WHISPER_REJECTED_FILE, 'w', encoding='utf-8') as f:
            json.dump(rows, f, ensure_ascii=False, indent=2)
            f.write('\n')
    except Exception as e:
        print(f"    (could not write {WHISPER_REJECTED_FILE}: {e})")


def _whisper_transcribe(m4a_path, awing_hint=''):
    """Attempt to transcribe a recording with OpenAI Whisper.

    Whisper's multilingual model produces a Swahili-biased phonetic
    approximation of Awing words — that transcription becomes the
    speakable_override for Edge TTS, which is how the 6 character voices
    learn to pronounce the word correctly. Without Whisper the character
    voices fall back to the naive awing_to_speakable() mapping.

    If Whisper is not installed we print a LOUD warning (once per run) and
    return None. The caller will emit its own per-word warning and the
    word will end up in regenerate_words.json without an override.

    `awing_hint` is passed as the initial_prompt so Whisper is nudged
    toward the intended word.
    """
    global _WHISPER_WARNED

    if not m4a_path or not os.path.exists(m4a_path):
        return None
    try:
        import whisper  # type: ignore
    except ImportError:
        if not _WHISPER_WARNED:
            _WHISPER_WARNED = True
            print()
            print("  " + "=" * 64)
            print("  !! OpenAI Whisper is NOT installed.")
            print("  !! The character voices can only be trained to pronounce")
            print("  !! recorded words correctly when Whisper transcribes them.")
            print("  !! Without it, Edge TTS falls back to its default mapping")
            print("  !! (which is why ghǒ currently sounds spelled out).")
            print("  !!")
            print("  !! Fix with ONE command:")
            print("  !!     venv\\Scripts\\pip install openai-whisper")
            print("  !! Then rerun: python scripts\\apply_contributions.py")
            print("  " + "=" * 64)
            print()
        return None

    try:
        # Default to the small multilingual model — a balance of quality
        # and download size. Callers can override WHISPER_MODEL in env.
        model_name = os.environ.get('WHISPER_MODEL', 'small')
        print(f"  → Transcribing with Whisper ({model_name})...")
        model = whisper.load_model(model_name)
        result = model.transcribe(
            m4a_path,
            language='sw',           # Swahili bias — closest Bantu language
            task='transcribe',
            initial_prompt=awing_hint or None,
            fp16=False,
        )
        text = (result.get('text') or '').strip()
        if not text:
            return None
        print(f"    Whisper says: '{text}'")
        return text
    except Exception as e:
        print(f"    ⚠ Whisper transcription failed: {e}")
        return None


# ============================================================
# Audio-contributors auto-update
# ============================================================
# When a pronunciationFix or newWord-with-audio is applied, the
# submitter's profileName goes into this set. After all contributions
# are processed, _flush_audio_contributors() appends any new names to
# lib/data/audio_contributors.dart's approvedContributors list. The
# About screen reads that list, so testers see new contributors
# credited on the next build without anyone touching the Dart file.
_audio_contributors_collected = set()

# Profile-name aliases. Lowercased lookup. Used when the submitter's
# typed profileName isn't the form we want displayed in the About
# screen credit list. Add entries here as needed.
_AUDIO_CONTRIBUTOR_ALIASES = {
    'bb': 'Berlin Sama',
    # Session 66p — 'Monto’oh' is the name of a device profile, not a
    # person. It reached the About screen because this contributor
    # signs in with Apple, which surrenders a display name only on the
    # very first authorization, so googleDisplayName was null on all 13
    # recordings and the client fell back to profileName.
    #
    # Confirmed by Dr. Sama as Dr. Richard Alombah — the same person as
    # the 'fozo' / 'frichardfozo' aliases below, reaching us from a
    # different device. Both apostrophes are listed because the device
    # submits U+2019 and a keyboard may produce ASCII.
    'monto’oh': 'Dr. Richard Alombah',
    "monto'oh": 'Dr. Richard Alombah',
    'montooh': 'Dr. Richard Alombah',
    # Session 63 — resolve every variant of Dr. Richard's profileName
    # (his app auth might surface any of these depending on how his
    # Google profile is set) to the polished display name.
    'richard': 'Dr. Richard Alombah',
    'richard alombah': 'Dr. Richard Alombah',
    'dr richard': 'Dr. Richard Alombah',
    'dr. richard': 'Dr. Richard Alombah',
    'fozo': 'Dr. Richard Alombah',
    'frichardfozo': 'Dr. Richard Alombah',
    # Session 63 — Juliette Mandah (profileName resolved to "Nyla" from
    # her device's local profile; her Google account's real name is
    # Juliette Mandah). Session 63 Part B (googleDisplayName in payload)
    # makes this unnecessary for FUTURE contributors, but future
    # contributions from Juliette's device still land under the profile
    # name so keep the alias too.
    'nyla': 'Juliette Mandah',
    'juliette': 'Juliette Mandah',
    'juliette mandah': 'Juliette Mandah',
    'mandah': 'Juliette Mandah',
}

# Profile names to NEVER credit (core voices already hard-coded, fake
# placeholders, server-side sentinels). Lowercased.
_AUDIO_CONTRIBUTOR_SKIPLIST = {
    '', 'anonymous', 'unknown', 'developer', 'default',
    'dr. guidion sama', 'dr guidion sama', 'guidion sama',
    'dr. sama', 'dr sama', 'guidion', 'sama',
    'joel sama', 'joel',
    'joyce sama', 'joyce',
    'jadyne sama', 'jadyne',
    'janelle sama', 'janelle',
}


# Honorifics and particles ignored when deciding whether two spellings
# name the same person.
_NAME_TITLES = {'dr', 'dr.', 'mr', 'mr.', 'mrs', 'mrs.', 'ms', 'ms.',
                'prof', 'prof.', 'rev', 'rev.', 'sir', 'madam'}


def _name_fingerprint(name):
    """Order- and title-insensitive identity for a person's name.

    v1.24.2 (Session 66p): the skiplist and the duplicate check both
    compared lowercased strings. The skiplist held 'dr. guidion sama',
    'guidion sama', 'guidion' and 'sama' -- but not 'sama guidion'. A
    contributor whose profile was saved family-name-first therefore
    sailed past every entry and was auto-added to the PUBLIC About
    screen, which is how 'Sama Guidion' came to be credited alongside
    'Dr. Guidion Sama' as if they were two people.

    Comparing the SET of name tokens fixes the whole class rather than
    adding one more string to the list. 'Berlin Sama' and 'Joel Sama'
    stay distinct because only the shared surname overlaps, never the
    full set.
    """
    if not name:
        return frozenset()
    cleaned = ''.join(c if (c.isalpha() or c.isspace()) else ' '
                      for c in str(name).lower())
    return frozenset(t for t in cleaned.split()
                     if t and t not in _NAME_TITLES)


def _canonicalize_contributor_name(profile):
    """Return the display name for a profileName, or None to skip.
    Handles 'default <name>' (Session 49 recorderSlugOf bug pattern),
    aliases, core-voice dedup, and basic title-case fallback."""
    if not profile or not isinstance(profile, str):
        return None
    name = profile.strip()
    if name.lower().startswith('default '):
        name = name[8:].strip()
    if not name:
        return None
    lname = name.lower()
    fp = _name_fingerprint(name)
    if lname in _AUDIO_CONTRIBUTOR_SKIPLIST or any(
            fp and fp == _name_fingerprint(s) for s in
            _AUDIO_CONTRIBUTOR_SKIPLIST):
        return None
    if lname in _AUDIO_CONTRIBUTOR_ALIASES:
        return _AUDIO_CONTRIBUTOR_ALIASES[lname]
    if not any(c.isalpha() for c in name):
        return None
    if name == name.lower() or name == name.upper():
        name = ' '.join(p.capitalize() for p in name.split())
    return name


# Names that reached the publish step but were not full names. Written
# here for Dr. Sama rather than onto the About screen.
CONTRIBUTORS_PENDING_FILE = os.path.join(
    CONTRIBUTIONS_DIR, 'contributors_pending_review.json')


def _looks_like_a_full_name(name):
    """Two or more name tokens, i.e. something a person is actually called.

    v1.24.2 (Session 66p): the About screen of a children's app credited
    'Monto’oh', which is not a person -- it is a device profile, submitted
    as profileName 'default Monto’oh'.

    The client already tries to do better: contribution_service.dart asks
    Google silent sign-in for a display name, then falls back to the
    Firebase display name. Both can legitimately return null -- an Apple
    contributor who never had a display name populated, or someone not
    signed in at all -- and the code then falls back to the local profile
    name, which is whatever was typed on the device.

    A credit is a person's name, so require at least two tokens. One-word
    profile names go to CONTRIBUTORS_PENDING_FILE for review instead of
    straight onto a public screen.
    """
    # Split on WHITESPACE, not on punctuation. _name_fingerprint() turns
    # every non-letter into a space, which is right for identity matching
    # but wrong here: it made "Monto’oh" look like the two-word name
    # "monto oh" and published it. A person's name is separated by spaces.
    tokens = []
    for raw in str(name).split():
        letters = ''.join(c for c in raw if c.isalpha())
        if len(letters) > 1 and letters.lower() not in _NAME_TITLES:
            tokens.append(letters)
    return len(tokens) >= 2


def _record_pending_contributor(display_name, profile, had_google_name):
    """Queue a name that is not publishable as-is for human review."""
    rows = []
    if os.path.exists(CONTRIBUTORS_PENDING_FILE):
        try:
            with open(CONTRIBUTORS_PENDING_FILE, 'r', encoding='utf-8') as f:
                rows = json.load(f)
            if not isinstance(rows, list):
                rows = []
        except Exception:
            rows = []
    if any(r.get('name') == display_name for r in rows):
        return
    rows.append({
        'name': display_name,
        'from_profile_name': profile,
        'had_google_display_name': bool(had_google_name),
        'why': 'not a full name (fewer than two name tokens)',
        'action': ("Add the contributor's real name to "
                   "lib/data/audio_contributors.dart by hand, or ignore."),
    })
    try:
        ensure_directories()
        with open(CONTRIBUTORS_PENDING_FILE, 'w', encoding='utf-8') as f:
            json.dump(rows, f, ensure_ascii=False, indent=2)
            f.write('\n')
    except Exception as e:
        print(f"    (could not write {CONTRIBUTORS_PENDING_FILE}: {e})")


def _collect_audio_contributor(profile, ctype, has_audio,
                                google_display_name=None):
    """Add a contributor to the pending list if their submission was
    audio-bearing. Called from the apply loop after a successful
    print of the contribution header.

    Session 63 Part B — when the contribution carries a
    google_display_name (full name from the contributor's Google Sign-In
    account), that's PREFERRED over the local profileName. Google
    display names are already polished (real names, correct case), so
    we skip the alias/canonicalize logic entirely for them and just
    dedup against the skiplist. Falls back to profileName + full
    canonicalize logic when google_display_name is empty/missing
    (older clients that predate this field).
    """
    if ctype not in ('pronunciationFix', 'newWord'):
        return
    if not has_audio:
        return
    # Prefer Google display name if present.
    if google_display_name:
        gname = str(google_display_name).strip()
        if gname and gname.lower() not in _AUDIO_CONTRIBUTOR_SKIPLIST:
            if _looks_like_a_full_name(gname):
                _audio_contributors_collected.add(gname)
            else:
                _record_pending_contributor(gname, profile, True)
            return
    # Fallback: canonicalize the local profileName.
    canon = _canonicalize_contributor_name(profile)
    if canon:
        if _looks_like_a_full_name(canon):
            _audio_contributors_collected.add(canon)
        else:
            # A one-word profile name is not a credit. Do not publish it.
            _record_pending_contributor(canon, profile, False)


def _flush_audio_contributors():
    """If any new contributors were collected during this run, append
    them to lib/data/audio_contributors.dart's approvedContributors
    list. Idempotent -- skips names already in the list. Preserves
    insertion order (new names appear AFTER existing ones)."""
    if not _audio_contributors_collected:
        return 0
    dart_path = os.path.join(
        PROJECT_DIR, 'lib', 'data', 'audio_contributors.dart')
    if not os.path.exists(dart_path):
        print(NL + '  [contributors] ' + dart_path
              + ' not found, skipping auto-update')
        return 0
    text = open(dart_path, encoding='utf-8').read()

    import re as _re
    pat = _re.compile(
        r'(const\s+List<String>\s+approvedContributors\s*=\s*\[)'
        r'(.*?)'
        r'(\];)',
        _re.S,
    )
    m = pat.search(text)
    if not m:
        print(NL + "  [contributors] couldn't find approvedContributors "
              "list, skipping")
        return 0

    body = m.group(2)
    existing = [n for n in _re.findall(r"['" + '"' + r"]([^'" + '"' + r"]+)['" + '"' + r"]", body)]
    existing_lower = {n.lower() for n in existing}
    existing_fps = {_name_fingerprint(n) for n in existing if n}

    new_names = []
    for name in sorted(_audio_contributors_collected):
        fp = _name_fingerprint(name)
        if name.lower() in existing_lower or (fp and fp in existing_fps):
            continue
        new_names.append(name)
        existing_lower.add(name.lower())
        existing_fps.add(fp)

    if not new_names:
        return 0

    indent = '  '
    additions = ''.join(
        NL + indent + "'" + n + "',  // auto-added by apply_contributions.py"
        for n in new_names
    )
    # The last entry ends with a trailing '// auto-added ...' comment, so
    # endswith(',') was false and a comma got appended INSIDE the comment
    # ("...apply_contributions.py,"). Harmless to Dart, but it corrupted
    # the file a little more on every run. Only add a comma when the last
    # CODE line actually lacks one.
    new_body = body.rstrip()
    last_code = new_body.split(NL)[-1].split('//')[0].rstrip()
    if last_code and not last_code.endswith(','):
        new_body += ','
    new_body += additions + NL

    text = text[:m.start(2)] + new_body + text[m.end(2):]
    open(dart_path, 'w', encoding='utf-8', newline='\n').write(text)

    print(NL + '  [contributors] Added ' + str(len(new_names))
          + ' new contributor(s) to audio_contributors.dart:')
    for n in new_names:
        print('    + ' + n)
    return len(new_names)


def _flush_and_exit(rc):
    """Run _flush_audio_contributors() at the very end of apply, just
    before the process exits. Non-fatal if flush fails."""
    try:
        _flush_audio_contributors()
    except Exception as _e:
        print('  [contributors] auto-update failed (non-fatal): '
              + str(_e))
    return rc


def reset_version():
    """Delete last_version.txt so the next run re-pulls every approved
    contribution from the webhook. Useful after a server-side schema
    change (e.g. we now send audioUrl in the response)."""
    if os.path.exists(VERSION_FILE):
        os.remove(VERSION_FILE)
        print(f"✓ Reset {VERSION_FILE} — next run will re-download every approved contribution.")
    else:
        print(f"  {VERSION_FILE} does not exist — nothing to reset.")


def get_webhook_url():
    """Load the contributions webhook URL from config/webhooks.json."""
    if not os.path.exists(WEBHOOKS_FILE):
        return None
    try:
        with open(WEBHOOKS_FILE, 'r', encoding='utf-8') as f:
            config = json.load(f)
        url = config.get('contributions_url', '')
        if url and url.startswith('https://'):
            return url
    except Exception as e:
        print(f"  Warning: Could not read webhooks.json: {e}")
    return None


def get_script_secret():
    """Read the SCRIPT_SECRET shared secret used to authenticate
    privileged webhook calls (fetch_audio, fetch_all, approve, reject).

    Source order:
      1. AWING_SCRIPT_SECRET environment variable.
      2. config/webhooks.json's `script_secret` key.
      3. ~/.awing_script_secret file (single line, contents = secret).

    Returns None if no secret is configured. Privileged calls without a
    secret will be rejected by the webhook with status=unauthorized;
    the caller surfaces that as a clear error.
    """
    secret = os.environ.get('AWING_SCRIPT_SECRET', '').strip()
    if secret:
        return secret
    if os.path.exists(WEBHOOKS_FILE):
        try:
            with open(WEBHOOKS_FILE, 'r', encoding='utf-8') as f:
                config = json.load(f)
            secret = (config.get('script_secret') or '').strip()
            if secret:
                return secret
        except Exception:
            pass
    home_secret = os.path.expanduser('~/.awing_script_secret')
    if os.path.exists(home_secret):
        try:
            with open(home_secret, 'r', encoding='utf-8') as f:
                secret = f.read().strip()
            if secret:
                return secret
        except Exception:
            pass
    return None


def get_last_version():
    """Get the last content version we applied (stored locally)."""
    if not os.path.exists(VERSION_FILE):
        return 0
    try:
        with open(VERSION_FILE, 'r') as f:
            return int(f.read().strip())
    except (ValueError, OSError):
        return 0


def save_last_version(version):
    """Save the last content version we applied. MONOTONIC.

    v1.23.4 (Session 64c) — this used to write whatever it was handed.
    One caller passed `result.get('version', 0)` from a response parsed
    off a bare urlopen; when Apps Script's 302 decayed that POST into a
    GET on doGet(), the health payload has no 'version', so it wrote
    **0** and rewound the counter to the beginning of time. The next run
    then re-downloaded all 404 approved contributions and re-applied
    them — re-fetching voice references from Drive, re-running Whisper
    and re-queueing regeneration across all 6 character voices, for work
    that was already done.

    A counter that only ever moves forward cannot cause that, whatever
    a caller hands it. Going backwards is now an explicit operation:
    `--reset-version`, which deletes the file outright.
    """
    ensure_directories()
    try:
        new = int(version)
    except (TypeError, ValueError):
        print(f"  Refusing to write non-numeric version {version!r} "
              f"(keeping {get_last_version()}).")
        return
    current = get_last_version()
    if new < current:
        print(f"  Refusing to rewind version {current} -> {new}. "
              f"Use --reset-version if that is really what you want.")
        return
    with open(VERSION_FILE, 'w') as f:
        f.write(str(new))


# v1.24.2 (Session 66p): every webhook call in this file used to be a
# single attempt. setup_and_deploy._verify() has retried 3x with
# exponential backoff since v1.23.3 and survived two consecutive 404s in
# a real run on 2026-10-05 — while download_approved(), one step later in
# the same build, died on the first read timeout and aborted everything.
#
# The asymmetry was worse than it looks. The deploy's verification calls
# check_version with currentVersion=999999, so the server returns no
# updates and answers instantly. download_approved() calls it with the
# REAL local version, so Apps Script has to gather and serialise every
# update since then. At 507 vs a server on 518 that is 11 versions of
# contributions in one response body. The heavier call had the shorter
# timeout and no retry.
def _post_webhook(url, payload_dict, timeout=120, attempts=3, label=''):
    """POST to an Apps Script webhook with retry and exponential backoff.

    Returns the decoded JSON dict. Raises the last exception if every
    attempt fails, so callers keep their existing except: handling and
    the tri-state "we learned nothing" contract is preserved.

    Always goes through _post_follow: Apps Script answers every POST with
    a 302, and letting urllib follow it converts POST -> GET, landing on
    doGet() and returning the health payload. See the long note in
    download_approved() for the history of that trap.
    """
    import time as _time
    from setup_and_deploy import _post_follow as _pf

    data = json.dumps(payload_dict).encode('utf-8')
    last_err = None
    for attempt in range(attempts):
        try:
            req = urllib.request.Request(
                url,
                data=data,
                headers={'Content-Type': 'application/json; charset=utf-8'},
                method='POST',
            )
            return json.loads(_pf(req, timeout=timeout).decode('utf-8'))
        except Exception as e:
            last_err = e
            if attempt < attempts - 1:
                wait = 3 * (attempt + 1)
                what = f' {label}' if label else ''
                print(f"    [retry]{what} {type(e).__name__}: {e} — "
                      f"waiting {wait}s and retrying "
                      f"({attempt + 2}/{attempts})")
                _time.sleep(wait)
    raise last_err


def download_approved():
    """Download approved contributions from the Google Apps Script webhook.

    Checks the current content version against the server, downloads any
    new approved contributions, and saves them to approved_contributions.json.

    Returns the number of new contributions downloaded.
    """
    webhook_url = get_webhook_url()
    if not webhook_url:
        return 0

    current_version = get_last_version()
    print(f"  Checking for new approved contributions (local version: {current_version})...")

    # Ask the webhook for updates since our version
    payload = json.dumps({
        'action': 'check_version',
        'currentVersion': current_version,
    }).encode('utf-8')

    # v1.23.4 (Session 64c): this used a bare urllib.request.urlopen,
    # which auto-follows Apps Script's 302 and converts POST -> GET,
    # landing on doGet() and returning its health payload. That payload
    # has status == 'ok' and no 'updates', so the old code read it as
    # "no new contributions" AND then called save_last_version(0),
    # silently rewinding the local version counter. Reuse the one helper
    # in this repo that POSTs without following and then GETs the
    # Location target.
    try:
        from setup_and_deploy import _post_follow as _pf
    except Exception as _imp_err:
        # Falling back to a bare urlopen would silently reintroduce the
        # 302 trap this whole function exists to avoid. Say so.
        print(f"  WARNING: could not import _post_follow ({_imp_err}); "
              f"falling back to a redirect-following POST, which may "
              f"misread the response.")
        _pf = None

    try:
        if _pf is not None:
            # 120s, not 30s: this response carries every update since
            # our local version, so it grows with how far behind we are.
            result = _post_webhook(
                webhook_url,
                {'action': 'check_version',
                 'currentVersion': current_version},
                timeout=120, label='check_version')
        else:
            req = urllib.request.Request(
                webhook_url,
                data=payload,
                headers={'Content-Type': 'application/json'},
                method='POST',
            )
            with urllib.request.urlopen(req, timeout=120) as resp:
                result = json.loads(resp.read().decode('utf-8'))
    except urllib.error.URLError as e:
        print(f"  UNREACHABLE: could not reach webhook: {e}")
        return None
    except Exception as e:
        print(f"  UNREACHABLE: download failed: {e}")
        return None

    # doGet's health payload leaked through: status ok, a 'service' key,
    # and no 'version'. We learned NOTHING about pending contributions.
    if result.get('status') == 'ok' and result.get('service') \
            and 'version' not in result:
        print("  UNREACHABLE: got doGet's health payload instead of the "
              "doPost result.")
        return None

    if result.get('status') != 'ok':
        print(f"  UNREACHABLE: webhook error: "
              f"{result.get('message', 'unknown')}")
        return None

    if 'version' not in result:
        print("  UNREACHABLE: response has no 'version' field.")
        return None

    server_version = result.get('version', 0)
    updates = result.get('updates', [])

    if not updates:
        print(f"  No new contributions (server version: {server_version}).")
        save_last_version(server_version)
        return 0

    print(f"  Found {len(updates)} new approved contributions (server v{server_version}).")

    # Merge with any existing local approved file
    ensure_directories()
    existing = []
    if os.path.exists(APPROVED_FILE):
        try:
            with open(APPROVED_FILE, 'r', encoding='utf-8') as f:
                existing = json.load(f)
                if isinstance(existing, dict):
                    existing = [existing]
        except Exception:
            existing = []

    # Deduplicate by ID. The server's Approved sheet was NOT idempotent in
    # earlier versions — if `handleApproval` was called twice for the same
    # contribution id (which happens when the offline-queue retry resends an
    # approval the server already processed), it appended a SECOND row with
    # a higher version. `handleVersionCheck` returns BOTH rows. We collapse
    # them here, keeping only the highest-version row per id. The server's
    # JSON uses key `version` (not `itemVersion`); we accept both for safety.
    def _ver(c):
        return c.get('version', c.get('itemVersion', 0)) or 0

    by_id = {}
    for c in existing:
        cid = c.get('id')
        if not cid:
            by_id[f"__noid_existing_{len(by_id)}"] = c
            continue
        prev = by_id.get(cid)
        if prev is None or _ver(c) >= _ver(prev):
            by_id[cid] = c
    for update in updates:
        cid = update.get('id')
        if not cid:
            by_id[f"__noid_update_{len(by_id)}"] = update
            continue
        prev = by_id.get(cid)
        if prev is None or _ver(update) >= _ver(prev):
            by_id[cid] = update
    existing = list(by_id.values())

    # Save merged file
    with open(APPROVED_FILE, 'w', encoding='utf-8') as f:
        json.dump(existing, f, indent=2, ensure_ascii=False)

    print(f"  Saved {len(existing)} total contributions to approved_contributions.json")

    # Save the new version number (after successful apply, not here)
    # We'll save it after apply_contributions() succeeds
    return len(updates)


def load_contributions():
    """Load approved contributions from JSON file."""
    if not os.path.exists(APPROVED_FILE):
        return []

    with open(APPROVED_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)

    if isinstance(data, dict):
        return [data]
    return data


def apply_spelling_correction(content, target_word, correction):
    """Replace a word's Awing spelling in a Dart file.

    Both `target_word` and `correction` are validated as Awing strings
    before any regex substitution. The correction is inserted via a
    callable replacement function, NOT as a sub() pattern string —
    this prevents the correction text from being interpreted as regex
    backreferences (e.g. a malicious correction containing `\\1` would
    otherwise expand to the previously matched group, allowing a
    crafted contribution to inject content from elsewhere in the file
    or trigger sub() errors).

    Handles both regular strings and strings with apostrophes.
    Returns (modified_content, was_changed).
    Raises ContributionRejected if either input fails validation.
    """
    target_word = _validate_awing(target_word, field_name='spellingCorrection.target')
    correction = _validate_awing(correction, field_name='spellingCorrection.correction')

    changed = False

    # Replacement is a CALLABLE so `correction` is treated as literal
    # text — \1, \g<>, etc. inside `correction` are not interpreted.
    def _make_repl(correction_value):
        def _repl(m):
            return m.group(1) + correction_value + m.group(3)
        return _repl
    repl = _make_repl(correction)

    # Pattern 1: awing: 'target_word' (single-quoted)
    pattern1 = re.compile(
        r"(awing:\s*')(" + re.escape(target_word) + r")(')",
        re.UNICODE
    )
    if pattern1.search(content):
        content = pattern1.sub(repl, content)
        changed = True

    # Pattern 2: awing: "target_word" (double-quoted)
    pattern2 = re.compile(
        r'(awing:\s*")(' + re.escape(target_word) + r')(")',
        re.UNICODE
    )
    if pattern2.search(content):
        content = pattern2.sub(repl, content)
        changed = True

    # Pattern 3: letter: 'target_word' (for alphabet data)
    pattern3 = re.compile(
        r"(letter:\s*')(" + re.escape(target_word) + r")(')",
        re.UNICODE
    )
    if pattern3.search(content):
        content = pattern3.sub(repl, content)
        changed = True

    return content, changed


def apply_new_word(content, word, english, category):
    """Add a new word to the appropriate category list in awing_vocabulary.dart.

    All three fields are validated and re-escaped via _dart_string_literal()
    before being concatenated into Dart source. This is the primary
    defense against the contribution → arbitrary code execution attack:
    without these escapes, a malicious `english` like:

        x'); print(open('/etc/passwd').read()); ('

    would be embedded into the AwingWord literal verbatim and execute at
    next build (the file is just Dart source we're string-concatenating
    into). _dart_string_literal() escapes \\, ', $, newlines, and null
    bytes so the output is a guaranteed-safe Dart string literal.

    Raises ContributionRejected if any field fails validation.
    Returns (modified_content, was_added).
    """
    # Hard validation FIRST — bail out before touching the file if any
    # input looks hostile.
    word = _validate_awing(word, field_name='newWord.word')
    english = _validate_english(english, field_name='newWord.english')
    category = _validate_category(category)

    # Map categories to list variable names. Category itself is already
    # in the allowlist (_validate_category) so this is a closed mapping
    # with a safe default.
    category_map = {
        'body': 'bodyParts',
        'animals': 'animalsNature',
        'nature': 'animalsNature',
        'actions': 'actions',
        'things': 'thingsPlaces',
        'family': 'familyPeople',
        'daily': 'dailyLife',
        'greeting': 'dailyLife',
        'question': 'dailyLife',
        'farewell': 'dailyLife',
        'food': 'foodDrink',
        'descriptive': 'descriptiveWords',
        'numbers': 'numbers',
        'pronouns': 'pronouns',
        'time': 'timeWords',
        'classroom': 'dailyLife',
        'general': 'dailyLife',
        'other': 'dailyLife',
    }

    list_name = category_map.get(category, 'dailyLife')

    # Check if word already exists
    if re.search(re.escape(word), content, re.UNICODE):
        print(f"  Word '{word}' already exists in vocabulary, skipping")
        return content, False

    # Find the closing bracket of the target list: ];
    # We look for the pattern: const List<AwingWord> listName = [\n...\n];
    pattern = re.compile(
        r"(const List<AwingWord> " + list_name + r" = \[)(.*?)(^\];)",
        re.MULTILINE | re.DOTALL
    )
    match = pattern.search(content)
    if not match:
        print(f"  Could not find list '{list_name}' for category '{category}'")
        return content, False

    # Build the new entry using _dart_string_literal() — all three fields
    # are guaranteed-safe Dart literals after this. No interpolation.
    awing_lit = _dart_string_literal(word)
    english_lit = _dart_string_literal(english)
    category_lit = _dart_string_literal(category)
    new_entry = (
        f"  AwingWord(awing: {awing_lit}, english: {english_lit}, "
        f"category: {category_lit}),\n"
    )

    # Insert before the closing ];
    insert_pos = match.end(2)
    content = content[:insert_pos] + new_entry + content[insert_pos:]

    return content, True


def apply_new_sentence(tones_content, awing_text, english_text):
    """Add a new sentence to the sentences list in awing_tones.dart.

    Both fields are validated as Awing-and-English strings respectively
    (with the longer MAX_SENTENCE_LEN cap), then concatenated as
    _dart_string_literal()-escaped tokens. See apply_new_word for the
    rationale — same defense against Dart injection.

    Raises ContributionRejected if either field fails validation.
    Returns (modified_content, was_added).
    """
    awing_text = _validate_awing(awing_text, max_len=MAX_SENTENCE_LEN,
                                 field_name='newSentence.awing')
    english_text = _validate_english(english_text, max_len=MAX_SENTENCE_LEN,
                                     field_name='newSentence.english')

    # Check if already exists
    if re.search(re.escape(awing_text), tones_content, re.UNICODE):
        print(f"  Sentence '{awing_text[:30]}...' already exists, skipping")
        return tones_content, False

    # Find the awingSentences list
    pattern = re.compile(
        r"(const List<AwingSentence> awingSentences = \[)(.*?)(^\];)",
        re.MULTILINE | re.DOTALL
    )
    match = pattern.search(tones_content)
    if not match:
        print("  Could not find awingSentences list in awing_tones.dart")
        return tones_content, False

    awing_lit = _dart_string_literal(awing_text)
    english_lit = _dart_string_literal(english_text)

    new_entry = (
        f"  AwingSentence(\n"
        f"    awing: {awing_lit},\n"
        f"    english: {english_lit},\n"
        f"    wordByWord: [],\n"
        f"  ),\n"
    )

    insert_pos = match.end(2)
    tones_content = tones_content[:insert_pos] + new_entry + tones_content[insert_pos:]

    return tones_content, True


def load_applied_ids():
    """Every contribution id we have already applied, from the archives
    in contributions/applied/.

    v1.23.4 (Session 64c) — this ledger was written after every run and
    never once read back. The ONLY thing standing between us and
    re-applying the entire history was last_version.txt: a single
    integer, written by a caller that defaulted to 0, inside a
    swallow-everything try/except labelled "Non-critical". When that
    integer got clobbered, 404 contributions were re-applied -- each one
    re-downloading a voice reference from Drive, re-running Whisper and
    re-queueing regeneration across 6 character voices.

    An id that has been applied stays applied. A re-approval of the same
    contribution carries the SAME id with a higher version (see the
    Session 48 note on handleApproval idempotency), so matching on id is
    exactly the duplicate case we want to drop. A genuinely new
    correction to the same word gets a new id and still comes through.
    """
    seen = set()
    if not os.path.isdir(APPLIED_DIR):
        return seen
    for fname in sorted(os.listdir(APPLIED_DIR)):
        if not fname.endswith('.json'):
            continue
        try:
            with open(os.path.join(APPLIED_DIR, fname), 'r',
                      encoding='utf-8') as f:
                rows = json.load(f)
        except Exception:
            continue          # a corrupt archive must not block a build
        if isinstance(rows, dict):
            rows = [rows]
        for r in rows:
            if isinstance(r, dict) and r.get('id'):
                seen.add(r['id'])
    return seen


def apply_contributions(contributions, dry_run=False, skip_applied=True):
    """Apply all contributions to the Dart data files."""
    if not contributions:
        print("No contributions to apply.")
        return 0

    if skip_applied:
        already = load_applied_ids()
        if already:
            before = len(contributions)
            contributions = [c for c in contributions
                             if c.get('id') not in already]
            dropped = before - len(contributions)
            if dropped:
                print(f"  Skipping {dropped} contribution(s) already "
                      f"applied in an earlier run "
                      f"({len(contributions)} remain).")
        if not contributions:
            print("  Nothing new to apply.")
            return 0

    # Two-stage dedup:
    #   1. By id — collapses server-side duplicates where `handleApproval`
    #      was called twice for the same contribution id (the Session 48
    #      idempotency fix prevents new duplicates, but legacy data may
    #      still have them).
    #   2. By (type, normalized target) — latest-wins. When the developer
    #      re-records or re-corrects the SAME word (different ids, same
    #      target), only the highest-version row is applied so we never
    #      apply an outdated correction.
    # Server JSON uses key `version`; older data may use `itemVersion`.
    def _ver(c):
        return c.get('version', c.get('itemVersion', 0)) or 0

    def _norm_target(c):
        ctype = (c.get('type') or '').strip()
        target = (c.get('targetWord') or '').strip()
        # Normalize to the audio key for pronunciationFix so differently
        # diacritized spellings of the same recording collapse. For every
        # other type we key off the raw target since spelling matters.
        if ctype == 'pronunciationFix':
            return (ctype, _audio_key(target))
        return (ctype, target.lower())

    # Stage 1 — by id
    by_id = {}
    kept = []
    for c in contributions:
        cid = c.get('id')
        if not cid:
            kept.append(c)
            continue
        prev = by_id.get(cid)
        if prev is None:
            by_id[cid] = c
            kept.append(c)
        elif _ver(c) > _ver(prev):
            kept[kept.index(prev)] = c
            by_id[cid] = c
    before_id = len(contributions)
    contributions = kept
    if len(contributions) < before_id:
        print(f"  Dedup by id: {before_id} → {len(contributions)} "
              f"(removed {before_id - len(contributions)} duplicate id(s))")

    # Stage 2 — latest-wins by (type, normalized target)
    by_target = {}
    kept2 = []
    for c in contributions:
        key = _norm_target(c)
        # No target or unknown type → can't dedupe, keep it
        if not key[1]:
            kept2.append(c)
            continue
        prev = by_target.get(key)
        if prev is None:
            by_target[key] = c
            kept2.append(c)
        elif _ver(c) >= _ver(prev):
            kept2[kept2.index(prev)] = c
            by_target[key] = c
    before_target = len(contributions)
    contributions = kept2
    if len(contributions) < before_target:
        print(f"  Dedup latest-wins by target: {before_target} → "
              f"{len(contributions)} (kept only the latest version of each "
              f"(type, target))")

    # Read current Dart files
    with open(VOCAB_FILE, 'r', encoding='utf-8') as f:
        vocab_content = f.read()
    with open(ALPHABET_FILE, 'r', encoding='utf-8') as f:
        alphabet_content = f.read()

    tones_content = None
    if os.path.exists(TONES_FILE):
        with open(TONES_FILE, 'r', encoding='utf-8') as f:
            tones_content = f.read()

    applied_count = 0
    rejected_count = 0
    vocab_modified = False
    alphabet_modified = False
    tones_modified = False
    regenerate_words = []  # Words needing audio regeneration (all pronunciationFix + spelling changes)
    archived_references = []  # Developer recordings archived to voice_references/

    for c in contributions:
        ctype = c.get('type', '')
        target = c.get('targetWord', '')
        correction = c.get('correction', '')
        english = c.get('englishMeaning', '')
        category = c.get('category', 'other')
        pronunciation = c.get('pronunciationGuide', '')
        profile = c.get('profileName', 'Unknown')
        # Session 63 Part B — full name from contributor's Google account,
        # if the app version sending the submission was new enough to
        # include it. Preferred by _collect_audio_contributor over the
        # local profileName when present.
        google_display_name = c.get('googleDisplayName') or ''
        audio_url = c.get('audioUrl') or ''

        # SECURITY: validate audio_url BEFORE we ever fetch it. SSRF
        # risk: a malicious contribution could point audioUrl at an
        # internal IP, file://, or attacker-controlled server.
        if audio_url:
            try:
                audio_url = _validate_audio_url(audio_url)
            except ContributionRejected as e:
                print(f"\n  ⚠ Rejecting audio for [{ctype}] '{target}': {e}")
                audio_url = ''  # don't fetch, but allow non-audio fields to proceed

        # v1.22.0 (Session 66): image contributions. Same SSRF allowlist
        # as audio. Approved images override the SDXL-generated vocab
        # image at android/install_time_assets/.../vocabulary/{key}.png.
        image_url = c.get('imageUrl') or ''
        if image_url:
            try:
                image_url = _validate_image_url(image_url)
            except ContributionRejected as e:
                print(f"\n  ⚠ Rejecting image for [{ctype}] '{target}': {e}")
                image_url = ''

        print(f"\nApplying: [{ctype}] '{target}' → '{correction}' (from {profile})")
        _collect_audio_contributor(
            profile, ctype, bool(audio_url),
            google_display_name=google_display_name)

        # v1.22.0 (Session 66): fetch + install any attached image
        # BEFORE the type-specific branches below run. The image is
        # orthogonal to the correction type — spelling corrections, new
        # words, translation corrections, and pronunciation fixes can
        # all carry an image.
        if image_url and target:
            try:
                _install_vocabulary_image(image_url, target, profile,
                                          vocab_content=vocab_content,
                                          english_hint=english,
                                          dry_run=dry_run)
            except Exception as e:
                print(f"  ⚠ Image install failed for '{target}': {e}")

        # SECURITY: every branch below that mutates a Dart file delegates
        # input validation to its helper (apply_*). If a helper raises
        # ContributionRejected we log the rejection, count it, and
        # continue to the next contribution — never let one malicious
        # payload break the whole batch.
        # The try/except is intentionally wide: any helper-raised
        # ContributionRejected is a data-quality failure, not a bug.

        if ctype == 'spellingCorrection':
            try:
                # Try vocabulary file first
                vocab_content, changed = apply_spelling_correction(
                    vocab_content, target, correction)
                if changed:
                    vocab_modified = True
                    applied_count += 1
                    # Spelling changed → audio key changed → regenerate audio for new word
                    regenerate_words.append({
                        'awing': correction,
                        'english': english or '',
                        'category': category if category in ('body', 'animals',
                            'nature', 'actions', 'things', 'family', 'daily',
                            'greeting', 'question', 'farewell', 'food',
                            'descriptive', 'numbers', 'pronouns', 'time',
                            'classroom', 'general') else 'general',
                    })
                    print(f"  ✓ Updated spelling in awing_vocabulary.dart")
                    print(f"    Audio will be regenerated for corrected word '{correction}'")
                    continue

                # Try alphabet file
                alphabet_content, changed = apply_spelling_correction(
                    alphabet_content, target, correction)
                if changed:
                    alphabet_modified = True
                    applied_count += 1
                    regenerate_words.append({
                        'awing': correction,
                        'english': english or '',
                        'category': 'general',
                    })
                    print(f"  ✓ Updated spelling in awing_alphabet.dart")
                    print(f"    Audio will be regenerated for corrected word '{correction}'")
                    continue

                # Try tones file
                if tones_content:
                    tones_content, changed = apply_spelling_correction(
                        tones_content, target, correction)
                    if changed:
                        tones_modified = True
                        applied_count += 1
                        regenerate_words.append({
                            'awing': correction,
                            'english': english or '',
                            'category': 'general',
                        })
                        print(f"  ✓ Updated spelling in awing_tones.dart")
                        print(f"    Audio will be regenerated for corrected word '{correction}'")
                        continue

                print(f"  ✗ Word '{target}' not found in any data file")
            except ContributionRejected as e:
                print(f"  ⛔ REJECTED: {e}")
                rejected_count += 1
                continue

        elif ctype == 'newWord':
            try:
                vocab_content, added = apply_new_word(
                    vocab_content, correction or target, english, category)
                if added:
                    vocab_modified = True
                    applied_count += 1
                    print(f"  ✓ Added new word to awing_vocabulary.dart")
            except ContributionRejected as e:
                print(f"  ⛔ REJECTED: {e}")
                rejected_count += 1
                continue

        elif ctype == 'newSentence' or ctype == 'newPhrase':
            if tones_content:
                try:
                    tones_content, added = apply_new_sentence(
                        tones_content, correction or target, english or correction)
                    if added:
                        tones_modified = True
                        applied_count += 1
                        print(f"  ✓ Added new sentence to awing_tones.dart")
                except ContributionRejected as e:
                    print(f"  ⛔ REJECTED: {e}")
                    rejected_count += 1
                    continue

        elif ctype == 'translationCorrection':
            # User reported a wrong translation via the flag button in the
            # Translate screens. Payload:
            #   - target       = the wrong Awing the app showed
            #   - correction   = the correct Awing per the reporter
            #   - english      = the English source (via englishMeaning)
            #   - notes (JSON) = { wrong, context, wordByWord: {en:aw,...}, freeText }
            # We add the correction as a new dictionary entry AND every
            # word-by-word pair as additional entries (each pair also
            # improves LLM retrieval context on next Worker deploy).
            try:
                import json as _json
                notes_json = c.get('notes', '') or ''
                structured = {}
                try:
                    structured = _json.loads(notes_json)
                except Exception:
                    structured = {}
                pairs = []
                # Main correction pair
                if correction and english:
                    pairs.append((correction, english))
                # Word-by-word pairs
                wbw = structured.get('wordByWord', {}) if isinstance(structured, dict) else {}
                if isinstance(wbw, dict):
                    for en, aw in wbw.items():
                        en = str(en).strip()
                        aw = str(aw).strip()
                        if en and aw:
                            pairs.append((aw, en))
                # Apply each pair via apply_new_word
                added_here = 0
                for aw, en in pairs:
                    try:
                        vocab_content, added = apply_new_word(
                            vocab_content, aw, en,
                            category or 'general')
                        if added:
                            vocab_modified = True
                            added_here += 1
                            # Queue new word for audio generation.
                            regenerate_words.append({
                                'awing': aw,
                                'english': en,
                                'category': category if category in ('body',
                                    'animals', 'nature', 'actions', 'things',
                                    'family', 'daily', 'greeting', 'question',
                                    'farewell', 'food', 'descriptive',
                                    'numbers', 'pronouns', 'time',
                                    'classroom', 'general') else 'general',
                            })
                    except ContributionRejected as e:
                        print(f"  ⛔ REJECTED (pair {aw}/{en}): {e}")
                        # keep going with other pairs
                if added_here:
                    applied_count += 1
                    print(f"  ✓ Added {added_here} corrected pair(s) to awing_vocabulary.dart")
                    if structured.get('freeText'):
                        print(f"    Reporter notes: {structured.get('freeText')[:120]}")
                else:
                    print(f"  ⚠ Translation correction produced no dictionary additions "
                          f"(all pairs may already exist)")
            except Exception as e:
                print(f"  ⛔ REJECTED: {e}")
                rejected_count += 1
                continue

        elif ctype == 'pronunciationFix':
            # Reference-only pronunciation fixes (v2 design):
            # The developer's recording is NEVER played in the app. Instead:
            #   1. Archive the m4a to voice_references/{key}.m4a as a future
            #      training corpus. Re-records overwrite, so latest wins.
            #   2. Derive a speakable_override for Edge TTS from (in order):
            #        a. the developer's typed pronunciationGuide
            #        b. an optional Whisper ASR transcription (Swahili-biased)
            #        c. no override — Edge TTS uses its default
            #           awing_to_speakable() mapping
            #   3. Queue the word for Edge TTS regeneration. The learner
            #      always hears the mode-appropriate character voice
            #      (boy/girl for beginner, young_man/young_woman for medium,
            #      man/woman for expert) — not the developer's voice.
            m4a_path = None
            if audio_url:
                archived, key, m4a_path = _archive_voice_reference(
                    audio_url, target, dry_run=dry_run)
                if archived:
                    archived_references.append({
                        'key': key,
                        'awing': target,
                        'english': english or '',
                        'archived_at': datetime.now().isoformat(),
                    })
                else:
                    print(f"  ⚠ Voice reference archive failed — continuing with TTS regen")
            else:
                # The webhook's response did NOT include an audioUrl for this
                # pronunciationFix. Without the recording we can't run Whisper
                # to learn how the word should be pronounced, so the character
                # voices will fall back to Edge TTS's default spelling-based
                # mapping — exactly the bug the developer recorded the fix to
                # solve. Almost always caused by an older deployment of
                # scripts/contributions_webapp.gs that predates the change
                # which puts audioUrl into handleVersionCheck responses.
                print()
                print("  " + "!" * 64)
                print(f"  !! NO AUDIO URL for '{target}' — the character voices will")
                print("  !! NOT learn from the recording!")
                print("  !!")
                print("  !! Root cause: the deployed Apps Script webhook is outdated")
                print("  !! and is not returning audioUrl in check_version responses.")
                print("  !!")
                print("  !! Fix (2 steps):")
                print("  !!   1. Redeploy the webhook:")
                print("  !!      cd scripts\\clasp_contributions")
                print("  !!      clasp push --force && clasp deploy")
                print("  !!   2. Rerun with --refetch-audio to recover the recording")
                print("  !!      for already-applied contributions:")
                print("  !!      python scripts\\apply_contributions.py --refetch-audio")
                print("  " + "!" * 64)
                print()

            speakable_override = ''
            override_source = ''
            if pronunciation:
                speakable_override = pronunciation
                override_source = 'pronunciationGuide'
            elif m4a_path and not dry_run:
                whisper_text = _whisper_transcribe(m4a_path, awing_hint=target)
                if whisper_text:
                    ok, why = _whisper_plausible(target, whisper_text)
                    if ok:
                        speakable_override = whisper_text
                        override_source = 'whisper'
                    else:
                        # Whisper hallucinated rather than failed. Keep the
                        # submitted spelling; never ship invented Awing.
                        print(f"  ⚠ REJECTED Whisper transcription for "
                              f"'{target}': '{whisper_text}' ({why})")
                        print(f"    → No override set. Logged to "
                              f"contributions/whisper_rejected.json for review.")
                        _record_whisper_rejection(
                            target, whisper_text, why, english or '')
                elif True:
                    # Whisper either isn't installed (banner already printed
                    # by _whisper_transcribe) or produced nothing for this
                    # recording — warn so the user understands this specific
                    # word won't get a trained-from-recording override.
                    print(f"  ⚠ Whisper produced no transcription for '{target}'")
                    print(f"    → Edge TTS will fall back to default mapping for this word")

            word_entry = {
                'awing': target,
                'english': english or '',
                'category': category,
                # Propagate recorder so downstream pipeline (apply_recordings_
                # as_audio.py, future per-kid Edge TTS overrides) can attribute
                # the voice. Falls back to None when the webhook still hasn't
                # joined profileName from Submissions (pre-Session 60 deploys).
                'recorder': profile if profile and profile != 'Unknown' else None,
            }
            if speakable_override:
                word_entry['speakable_override'] = speakable_override
                print(f"  → Speakable override ({override_source}): '{speakable_override}'")
            else:
                print(f"  → No override — Edge TTS will use default pronunciation mapping")
            print(f"    Queued for regeneration in all 6 character voices")
            regenerate_words.append(word_entry)
            applied_count += 1

        elif ctype == 'generalFeedback':
            print(f"  → Feedback noted: {c.get('notes', correction)}")

    # Write modified files
    if not dry_run:
        if vocab_modified:
            with open(VOCAB_FILE, 'w', encoding='utf-8') as f:
                f.write(vocab_content)
            print(f"\n✓ Saved {VOCAB_FILE}")

        if alphabet_modified:
            with open(ALPHABET_FILE, 'w', encoding='utf-8') as f:
                f.write(alphabet_content)
            print(f"✓ Saved {ALPHABET_FILE}")

        if tones_modified and tones_content:
            with open(TONES_FILE, 'w', encoding='utf-8') as f:
                f.write(tones_content)
            print(f"✓ Saved {TONES_FILE}")

        # Write regeneration list for Edge TTS (any spelling/pronunciation
        # change queues its word here so all 6 character voices get a fresh
        # clip, with an optional speakable_override to shape pronunciation).
        if regenerate_words:
            # De-duplicate by awing — a contribution pass may queue the
            # same word twice if both the spelling and the pronunciation
            # changed. Keep the LAST entry (which has any override set).
            seen = {}
            for w in regenerate_words:
                seen[w.get('awing', '')] = w
            regenerate_words = list(seen.values())
            with open(REGENERATE_FILE, 'w', encoding='utf-8') as f:
                json.dump(regenerate_words, f, ensure_ascii=False, indent=2)
            print(f"\n✓ Wrote {len(regenerate_words)} word(s) to {REGENERATE_FILE}")
            print(f"  Edge TTS will force-regenerate these words for all 6 voices")

        # v1.24.2 (Session 66p) — PROMOTE the recordings into the native
        # tier the app actually plays.
        #
        # Until now this step only printed a summary. The design was
        # "reference only": the recording trained Edge TTS, which
        # re-synthesised the word in six character voices so the learner
        # heard a mode-appropriate voice rather than the contributor's.
        #
        # v1.24.0 deleted those six voices. Nothing replaced the last
        # step, so the chain ended at regenerate_words.json — a queue only
        # generate_audio_edge.py reads, and build_and_run.bat never calls
        # it. Every recording approved since then went nowhere: 358 of
        # them had piled up unused while 452 words sat silent in the app.
        #
        # The choice now is this recording or silence, so promote it.
        # Never overwrites an existing clip; only fills silence.
        if archived_references:
            print(f"\n✓ Archived {len(archived_references)} developer recording(s) "
                  f"to {VOICE_REFERENCES_DIR}")
            promoted = _promote_references_to_native(
                [r['key'] for r in archived_references])
            if promoted:
                print(f"  ✓ Promoted {promoted} into audio/native/vocabulary/ "
                      f"— these words will now speak in the app.")
                print(f"  Re-run build_and_run.bat so [4c/7] re-uploads the "
                      f"PAD bundle, or CI will build without them.")
            else:
                print(f"  No new native clips (every word already had audio, "
                      f"or ffmpeg/pydub is unavailable).")

        # Archive the processed file
        os.makedirs(APPLIED_DIR, exist_ok=True)
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        archive_path = os.path.join(APPLIED_DIR, f'applied_{timestamp}.json')
        shutil.move(APPROVED_FILE, archive_path)
        print(f"✓ Archived contributions to {archive_path}")
    else:
        print("\n[DRY RUN] No files were modified.")

    if rejected_count:
        print()
        print("  " + "!" * 64)
        print(f"  !! REJECTED {rejected_count} contribution(s) for failing security validation.")
        print(f"  !! These payloads contained disallowed characters, suspicious")
        print(f"  !! tokens, or were too long. They were SKIPPED — no Dart")
        print(f"  !! source file was modified by the rejected entries.")
        print(f"  !!")
        print(f"  !! If a legitimate contribution was rejected, check the")
        print(f"  !! reason printed inline above (e.g. character allowlist,")
        print(f"  !! length cap) and either fix the payload or relax the")
        print(f"  !! validator. NEVER bypass validation to apply a payload.")
        print("  " + "!" * 64)

    return applied_count


def list_contributions():
    """List all pending approved contributions."""
    contributions = load_contributions()
    if not contributions:
        print("No approved contributions found.")
        print(f"Place approved_contributions.json in: {CONTRIBUTIONS_DIR}")
        return

    print(f"\n{'='*60}")
    print(f"  {len(contributions)} Approved Contributions")
    print(f"{'='*60}")

    for i, c in enumerate(contributions, 1):
        ctype = c.get('type', 'unknown')
        target = c.get('targetWord', '')
        correction = c.get('correction', '')
        profile = c.get('profileName', 'Unknown')
        date = c.get('submittedAt', '')[:10]

        icon = {
            'spellingCorrection': '📝',
            'pronunciationFix': '🎤',
            'newWord': '➕',
            'newSentence': '📖',
            'newPhrase': '💬',
            'generalFeedback': '💡',
        }.get(ctype, '❓')

        print(f"\n  {i}. {icon} [{ctype}]")
        print(f"     Word: {target}")
        if correction:
            print(f"     → {correction}")
        if c.get('englishMeaning'):
            print(f"     English: {c['englishMeaning']}")
        if c.get('category'):
            print(f"     Category: {c['category']}")
        if c.get('pronunciationGuide'):
            print(f"     Pronunciation: {c['pronunciationGuide']}")
        print(f"     From: {profile} ({date})")


def clean_applied():
    """Remove all applied contribution archives."""
    if os.path.exists(APPLIED_DIR):
        shutil.rmtree(APPLIED_DIR)
        print(f"Cleaned: {APPLIED_DIR}")
    if os.path.exists(APPROVED_FILE):
        os.remove(APPROVED_FILE)
        print(f"Removed: {APPROVED_FILE}")
    print("Done.")


def refetch_audio():
    """Re-download m4a recordings + re-run Whisper for every pronunciationFix
    contribution that was already applied earlier.

    Why this exists:
      Earlier versions of scripts/contributions_webapp.gs didn't include
      audioUrl in handleVersionCheck's response. Contributions approved
      during that window were applied without the recording, so the
      character voices never learned the correct pronunciation — they
      fell back to Edge TTS's default awing_to_speakable() mapping, which
      is exactly the bug the developer recorded the fix to solve.

      After redeploying the updated webhook, this command walks every
      applied_*.json archive, asks the server for the audioUrl for each
      pronunciationFix id (via the 'fetch_audio' webhook endpoint), and
      then runs the SAME archive + Whisper pipeline apply_contributions()
      would have run if the audio had been present the first time. The
      resulting speakable_override values are merged into
      regenerate_words.json so the next Edge TTS run produces the right
      audio for every character voice, in every mode.

    This function does NOT re-apply Dart edits — those already ran the
    first time. It only recovers the missing audio → override pipeline.
    """
    webhook_url = get_webhook_url()
    if not webhook_url:
        print("  ✗ No webhook URL configured in config/webhooks.json — cannot refetch.")
        return

    if not os.path.exists(APPLIED_DIR):
        print(f"  {APPLIED_DIR} does not exist — no applied contributions to recover.")
        return

    # Gather every pronunciationFix that was ever applied
    applied_files = sorted(
        f for f in os.listdir(APPLIED_DIR)
        if f.startswith('applied_') and f.endswith('.json')
    )
    if not applied_files:
        print("  No applied_*.json archives found — nothing to refetch.")
        return

    print(f"\nScanning {len(applied_files)} applied archive(s) for pronunciation fixes...")

    pron_fixes = []
    for fname in applied_files:
        path = os.path.join(APPLIED_DIR, fname)
        try:
            with open(path, 'r', encoding='utf-8') as f:
                data = json.load(f)
        except Exception as e:
            print(f"  ⚠ Could not read {fname}: {e}")
            continue
        if isinstance(data, dict):
            data = [data]
        for c in data:
            if (c.get('type') or '') != 'pronunciationFix':
                continue
            cid = c.get('id')
            target = c.get('targetWord', '')
            if not cid or not target:
                continue
            pron_fixes.append(c)

    if not pron_fixes:
        print("  No pronunciationFix contributions found in applied archives.")
        return

    # Latest-wins per (type, normalized target). We only need to fetch and
    # re-transcribe the newest recording for each word; older ones would be
    # shadowed by the latest-wins dedup in apply_contributions anyway.
    def _ver(c):
        return c.get('version', c.get('itemVersion', 0)) or 0

    by_target = {}
    for c in pron_fixes:
        key = _audio_key(c.get('targetWord', ''))
        if not key:
            continue
        prev = by_target.get(key)
        if prev is None or _ver(c) >= _ver(prev):
            by_target[key] = c

    kept = list(by_target.values())
    print(f"  Found {len(pron_fixes)} pronunciation fixes, {len(kept)} "
          f"unique target(s) after latest-wins dedup.")

    ids = [c.get('id') for c in kept if c.get('id')]
    if not ids:
        print("  ⚠ None of the pronunciation fixes have an id — cannot fetch audio.")
        return

    # Ask the webhook for the audioUrl of each contribution id.
    # Requires the deployed webhook to implement the 'fetch_audio' action
    # (added in contributions_webapp.gs this session). If the endpoint
    # doesn't exist we'll get back an empty `audio` map and exit cleanly.
    print(f"  → Asking webhook for audioUrls of {len(ids)} contribution(s)...")
    secret = get_script_secret()
    if not secret:
        print("  ⚠ No SCRIPT_SECRET configured — fetch_audio is a privileged endpoint")
        print("    and requires authentication. Set one of:")
        print("      • environment variable AWING_SCRIPT_SECRET=<your_secret>")
        print("      • add 'script_secret' key to config/webhooks.json")
        print("      • write the secret to ~/.awing_script_secret")
        print("    The same value must be set in the Apps Script editor:")
        print("      Project Settings → Script Properties → SCRIPT_SECRET")
        return
    payload_dict = {
        'action': 'fetch_audio',
        'ids': ids,
        'scriptSecret': secret,
    }
    try:
        # v1.23.4 (Session 64c): was a bare urlopen. On the 302 leak
        # doGet's health payload arrives, whose status IS 'ok', so the
        # check below passed, `audio` came back empty, and the user was
        # told "the deployed version doesn't implement fetch_audio yet,
        # or none of these have a recording" -- blaming the deployment
        # or the data for a request that never reached doPost.
        # _post_webhook keeps that no-follow behaviour and adds retry.
        #
        # Downloads audio URLs for every id in one call, so this grows
        # with the batch size the same way check_version does.
        result = _post_webhook(webhook_url, payload_dict,
                               timeout=120, label='fetch_audio')
    except Exception as e:
        print(f"  ✗ Webhook call failed: {e}")
        print(f"     Make sure you've redeployed the webhook:")
        print(f"       cd scripts\\clasp_contributions && clasp push --force && clasp deploy")
        return

    if result.get('status') == 'ok' and result.get('service') \
            and 'audio' not in result:
        print(f"  ✗ Could not read the doPost response (got doGet's "
              f"health payload). The request never reached fetch_audio,")
        print(f"    so this says NOTHING about whether recordings exist.")
        print(f"    Retry; if it persists the deployment may be warming up.")
        return

    if result.get('status') != 'ok':
        print(f"  ✗ Webhook error: {result.get('message', 'unknown')}")
        return

    audio_by_id = result.get('audio') or {}
    if not audio_by_id:
        print(f"  ⚠ Webhook returned no audioUrls. Either the deployed version")
        print(f"    doesn't implement the 'fetch_audio' action yet, or none of")
        print(f"    these submissions have a recording on file.")
        print(f"    Redeploy and re-run:")
        print(f"      cd scripts\\clasp_contributions && clasp push --force && clasp deploy")
        return

    print(f"  ✓ Got audioUrls for {len(audio_by_id)} / {len(ids)} contribution(s).")

    # Load any existing regenerate_words.json so we merge rather than overwrite
    existing_regen = []
    if os.path.exists(REGENERATE_FILE):
        try:
            with open(REGENERATE_FILE, 'r', encoding='utf-8') as f:
                existing_regen = json.load(f)
            if isinstance(existing_regen, dict):
                existing_regen = [existing_regen]
        except Exception:
            existing_regen = []

    regen_by_key = {}
    for w in existing_regen:
        regen_by_key[_audio_key(w.get('awing', ''))] = w

    fetched = 0
    transcribed = 0
    for c in kept:
        cid = c.get('id')
        target = c.get('targetWord', '')
        english = c.get('englishMeaning', '')
        category = c.get('category', 'other')
        pronunciation = c.get('pronunciationGuide', '')

        audio_url = audio_by_id.get(cid)
        if not audio_url:
            print(f"\n  ✗ No audio on server for '{target}' (id={cid}) — skipping")
            continue

        print(f"\n  Recovering: '{target}' (from {c.get('profileName', 'Unknown')})")
        archived, key, m4a_path = _archive_voice_reference(audio_url, target)
        if not archived or not m4a_path:
            continue
        fetched += 1

        # Prefer a typed pronunciationGuide if the developer provided one;
        # otherwise fall back to Whisper transcription of the recording.
        speakable_override = ''
        override_source = ''
        if pronunciation:
            speakable_override = pronunciation
            override_source = 'pronunciationGuide'
        else:
            whisper_text = _whisper_transcribe(m4a_path, awing_hint=target)
            if whisper_text:
                ok, why = _whisper_plausible(target, whisper_text)
                if ok:
                    speakable_override = whisper_text
                    override_source = 'whisper'
                    transcribed += 1
                else:
                    print(f"    ⚠ REJECTED Whisper transcription for "
                          f"'{target}': '{whisper_text}' ({why})")
                    print(f"      → No override set. Logged to "
                          f"contributions/whisper_rejected.json for review.")
                    _record_whisper_rejection(
                        target, whisper_text, why, english or '')
            elif True:
                print(f"    ⚠ Whisper produced no transcription — no override set for '{target}'")

        entry = {
            'awing': target,
            'english': english or '',
            'category': category,
        }
        if speakable_override:
            entry['speakable_override'] = speakable_override
            print(f"    → Speakable override ({override_source}): '{speakable_override}'")

        regen_by_key[key] = entry

    if regen_by_key:
        merged = list(regen_by_key.values())
        with open(REGENERATE_FILE, 'w', encoding='utf-8') as f:
            json.dump(merged, f, ensure_ascii=False, indent=2)
        print(f"\n✓ Wrote {len(merged)} word(s) to {REGENERATE_FILE}")
        print(f"  Fetched audio for {fetched}, transcribed {transcribed} with Whisper.")
        print(f"\nNext step:")
        print(f"  .\\scripts\\build_and_run.bat")
        print(f"  (or just: python scripts\\generate_audio_edge.py regenerate)")
    else:
        print(f"\n  Nothing written to {REGENERATE_FILE}.")


def main():
    args = sys.argv[1:]

    if '--help' in args or '-h' in args:
        print(__doc__)
        return

    # --replace-audio: let a re-recording overwrite the clip it is meant
    # to replace. Without it, a developer can re-record a wrong-sounding
    # word in the app, the submission is approved, and the promotion step
    # silently drops it because a clip already exists - the app looks like
    # it worked and nothing changed.
    global REPLACE_EXISTING_AUDIO
    if '--replace-audio' in args:
        REPLACE_EXISTING_AUDIO = True
        args = [a for a in args if a != '--replace-audio']
        print('⚠ --replace-audio: existing native clips WILL be overwritten '
              'by matching re-recordings.')
        print('  Displaced clips are copied to '
              'contributions/replaced_native_audio/ first.')

    # Always ensure directories exist
    ensure_directories()

    if '--list' in args:
        list_contributions()
        return

    if '--clean' in args:
        clean_applied()
        return

    if '--refetch-audio' in args:
        # Recovery path: for pronunciationFix contributions that were
        # applied BEFORE the webhook started returning audioUrl, pull the
        # recording from the server, re-run Whisper, and merge the override
        # into regenerate_words.json. Does NOT re-apply Dart edits.
        refetch_audio()
        return

    if '--reset-version' in args:
        reset_version()
        # Allow --reset-version + normal run to re-pull and apply in one go
        args = [a for a in args if a != '--reset-version']

    if '--download' in args:
        # Download only, don't apply
        count = download_approved()
        if count is None:
            print("\n  Could not check the webhook. Nothing downloaded.")
            return 1
        if count > 0:
            print(f"\nDownloaded {count} new contributions.")
            print(f"Run without --download to apply them.")
        return

    dry_run = '--dry-run' in args

    # Step 1: Try to download new approved contributions from the webhook (if configured)
    webhook_url = get_webhook_url()
    if webhook_url and '--offline' in args:
        # Explicit opt-out: the operator accepts that this build may not
        # include contributions approved since the last successful check.
        print()
        print("  --offline: SKIPPING the approved-contributions check.")
        print("  This build may be missing content approved since the")
        print("  last successful sync. Do not ship it to the stores")
        print("  without re-running online first.")
        print()
        webhook_url = None
    if webhook_url:
        # v1.23.4 (Session 64c): the return value used to be discarded
        # entirely, so a timeout and a genuine "nothing pending" were
        # indistinguishable and the build carried on either way, ready
        # to ship an APK missing approved content with one Warning line
        # as the only trace.
        if download_approved() is None:
            print()
            print("=" * 60)
            print("  ERROR: could not check for approved contributions.")
            print("=" * 60)
            print("  The webhook did not return a readable answer, so we")
            print("  do NOT know whether approved contributions are")
            print("  pending. Building now could ship an APK missing")
            print("  content Dr. Sama has already approved.")
            print()
            print("  Retry, or to build anyway (you accept that risk):")
            print("     python scripts\\apply_contributions.py --offline")
            print("=" * 60)
            return 1

    # Step 2: Load and apply local contributions
    contributions = load_contributions()
    if not contributions:
        print("No approved contributions to apply.")
        print("Skipping contribution application.")
        return

    print(f"\nFound {len(contributions)} approved contributions.")
    applied = apply_contributions(contributions, dry_run=dry_run)
    print(f"\n{'='*60}")
    print(f"  Applied: {applied}/{len(contributions)} contributions")
    print(f"{'='*60}")

    if applied > 0 and not dry_run:
        # Save the server version so we don't re-download these next time
        if webhook_url:
            try:
                # Re-check to get the latest version number.
                # v1.23.4 (Session 64c): was a bare urlopen, which let
                # Apps Script's 302 turn this POST into a GET on
                # doGet(). Its health payload carries no 'version', so
                # the `, 0)` default fired and reset the counter.
                # Cheap call (999999 means no updates come back), but
                # losing it silently re-applies every contribution on
                # the next build, so retry it as well.
                result = _post_webhook(
                    webhook_url,
                    {'action': 'check_version', 'currentVersion': 999999},
                    timeout=30, label='save_version')
                if 'version' in result:
                    save_last_version(result['version'])
                else:
                    print("  Could not read the server version "
                          "(keeping local version "
                          f"{get_last_version()}).")
            except Exception as _e:
                # Still non-fatal, but no longer silent: losing this
                # bookkeeping step is how contributions get re-applied.
                print(f"  Could not refresh the server version ({_e}); "
                      f"keeping local version {get_last_version()}.")

        print("\nNext steps:")
        print("  1. Audio will be regenerated by build_and_run.bat")
        print("  2. APK will be built with the updated content")
        print("  3. Verify on device before pushing to app stores")


if __name__ == '__main__':
    # v1.23.4 (Session 64c): was `_flush_and_exit(main())` -- the return
    # code was computed and then THROWN AWAY, so this script always
    # exited 0. build_and_run.bat's "if !ERRORLEVEL! neq 0 -> abort"
    # check on step [1/7] was dead code for its entire life.
    sys.exit(_flush_and_exit(main()) or 0)
