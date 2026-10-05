#!/usr/bin/env python3
"""Promote developer voice references into the native audio tier.

Why this exists
---------------
Before v1.24.0 a `pronunciationFix` contribution worked like this: the
recording was archived to contributions/voice_references/{key}.m4a as a
REFERENCE, the word was queued in regenerate_words.json, and
generate_audio_edge.py re-synthesised it in all six character voices. The
learner heard a mode-appropriate character voice, never the developer's.

v1.24.0 deleted the six synthetic voices. Nothing replaced that last step,
so the chain now ends at the queue: generate_audio_edge.py is not called by
build_and_run.bat at all. PronunciationService says it plainly --

    // No recording exists. Deliberately silent -- see _buildSearchPaths.
    debugPrint('... staying silent (v1.24.0)')

-- so every word whose only audio was going to be synthesised is now
simply silent, while a real recording of it sits unused in
voice_references/.

This script closes that gap: it converts those references into the native
tier the app actually plays. The "reference-only" rule was never about the
recording being unsuitable; it was about preferring a character voice that
no longer exists. native/vocabulary/ already ships hundreds of Dr. Sama's
recordings that the app plays today.

Safety
------
NEVER overwrites an existing native clip. A word that already has audio is
left exactly as it is; only silence is filled. Use --force to override,
which you should not normally do.

Keys
----
The .m4a basename is already the key PronunciationService._audioKey()
produces -- apply_contributions.py uses the same derivation. Note that
build_native_audio_manifest.py does NOT agree for multi-word entries (it
emits akeme_angwale where Dart emits akemeangwale); the filename is
authoritative because it is what the app looks up.

Encoding matches what is already on disk:
    .opus  48 kHz mono  (playback)
    .wav   16 kHz mono  (pronunciation grader reference)
"""
import argparse
import os
import shutil
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
REFS_DIR = os.path.join(PROJECT_DIR, 'contributions', 'voice_references')
NATIVE_DIR = os.path.join(
    PROJECT_DIR, 'android', 'install_time_assets', 'src', 'main',
    'assets', 'audio', 'native')
DEFAULT_CATEGORY = 'vocabulary'   # speakAwing() searches this first


def have_ffmpeg():
    return shutil.which('ffmpeg') is not None


def existing_native(key):
    """Return the path of any existing clip for `key`, in any category."""
    if not os.path.isdir(NATIVE_DIR):
        return None
    for cat in sorted(os.listdir(NATIVE_DIR)):
        cat_dir = os.path.join(NATIVE_DIR, cat)
        if not os.path.isdir(cat_dir):
            continue
        for ext in ('.opus', '.wav', '.mp3'):
            p = os.path.join(cat_dir, key + ext)
            if os.path.exists(p):
                return p
    return None


def convert(src, dest_opus, dest_wav):
    """m4a -> trimmed wav (16k mono) + opus (48k mono).

    Returns (status, detail) where status is 'ok', 'silent' or 'error'.

    Silence trimming is NOT optional. A raw submission carries the pause
    before and after the word; measured over the first 358 promoted
    without it, the median clip ran 1.68s against 0.56s for the clips
    already shipping, and the worst was 9.34s. A child taps a word and
    waits. apply_recordings_as_audio.py has always trimmed via
    scripts/trim_silence.py, so this uses the same helper and inherits the
    same thresholds -- including its all-silent detection, which drops a
    recording that is nothing but room noise rather than shipping it.
    """
    from pathlib import Path
    try:
        from trim_silence import trim_audio_file
    except ImportError:
        try:
            from scripts.trim_silence import trim_audio_file
        except ImportError:
            return 'error', ('trim_silence/pydub unavailable -- refusing to '
                             'write untrimmed audio')

    # 1) m4a -> trimmed 16 kHz mono PCM wav (the grader reference).
    try:
        info = trim_audio_file(Path(src), Path(dest_wav),
                               target_sample_rate=16000)
    except Exception as e:
        return 'error', f'trim failed: {e!s:.160}'

    if getattr(info, 'all_silent', False):
        try:
            os.remove(dest_wav)
        except OSError:
            pass
        return 'silent', 'entirely silent'

    if not os.path.exists(dest_wav) or os.path.getsize(dest_wav) == 0:
        return 'error', 'trimmed wav is empty'

    # 2) trimmed wav -> 48 kHz mono opus (playback), matching what is
    #    already on disk. Encoding from the TRIMMED wav, not the raw m4a,
    #    so both outputs are the same audio.
    r = subprocess.run(
        ['ffmpeg', '-y', '-loglevel', 'error', '-i', dest_wav,
         '-ac', '1', '-ar', '48000', '-c:a', 'libopus', '-b:a', '32k',
         dest_opus], capture_output=True)
    if r.returncode != 0:
        return 'error', r.stderr.decode('utf-8', 'replace')[:200]
    if not os.path.exists(dest_opus) or os.path.getsize(dest_opus) == 0:
        return 'error', 'opus output is empty'

    removed = getattr(info, 'removed_sec', 0.0) or 0.0
    return 'ok', (f'trimmed {removed:.2f}s' if removed >= 0.1 else '')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dry-run', action='store_true',
                    help='report what would be written, change nothing')
    ap.add_argument('--category', default=DEFAULT_CATEGORY)
    ap.add_argument('--force', action='store_true',
                    help='overwrite native clips that already exist')
    ap.add_argument('keys', nargs='*',
                    help='specific keys to promote (default: all references)')
    args = ap.parse_args()

    if not os.path.isdir(REFS_DIR):
        print(f'No voice_references directory at {REFS_DIR}')
        return 1
    if not args.dry_run and not have_ffmpeg():
        print('ERROR: ffmpeg not on PATH -- required to convert m4a.')
        return 1

    wanted = set(args.keys) if args.keys else None
    refs = sorted(f for f in os.listdir(REFS_DIR) if f.endswith('.m4a'))

    out_dir = os.path.join(NATIVE_DIR, args.category)
    written = skipped_existing = failed = 0
    to_write = []

    for fname in refs:
        key = os.path.splitext(fname)[0]
        if wanted is not None and key not in wanted:
            continue
        have = existing_native(key)
        if have and not args.force:
            skipped_existing += 1
            continue
        to_write.append((key, os.path.join(REFS_DIR, fname)))

    print(f'  references:        {len(refs)}')
    print(f'  already have audio:{skipped_existing:>5}  (left untouched)')
    print(f'  would promote:     {len(to_write):>5}  -> native/{args.category}/')

    if args.dry_run:
        for key, _ in to_write[:20]:
            print(f'    + {key}')
        if len(to_write) > 20:
            print(f'    ... and {len(to_write) - 20} more')
        return 0

    if to_write:
        os.makedirs(out_dir, exist_ok=True)
    silent = 0
    for key, src in to_write:
        status, detail = convert(src,
                                 os.path.join(out_dir, key + '.opus'),
                                 os.path.join(out_dir, key + '.wav'))
        if status == 'ok':
            written += 1
            print(f'    ✓ {key}' + (f'  ({detail})' if detail else ''))
        elif status == 'silent':
            silent += 1
            print(f'    ⚠ {key}: {detail} — not shipped')
        else:
            failed += 1
            print(f'    ✗ {key}: {detail}')

    print()
    print(f'  Written: {written}  Skipped (already had audio): '
          f'{skipped_existing}  Silent (dropped): {silent}  '
          f'Failed: {failed}')
    if written:
        print('  Now re-run scripts/build_native_audio_manifest.py, then let')
        print('  build_and_run.bat [4c/7] re-upload the PAD bundle.')
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
