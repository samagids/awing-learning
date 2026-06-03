#!/usr/bin/env python3
"""Place Dr. Sama's recorded Awing WAVs into the PAD asset pack as the
'native' voice tier — the app's highest-priority audio source.

Reads:  training_data/recordings/manifest.json
Writes: android/install_time_assets/src/main/assets/audio/native/<category>/<key>.mp3

The Flutter app's PronunciationService searches `assets/audio/native/...`
first, then falls back to the per-character Edge TTS Swahili voices for
words without a recording. So every character (boy, girl, young_man,
young_woman, man, woman) plays the authentic recording for the 197
words covered, and the synthesised approximation only for the rest.

Usage:
    python3 scripts/apply_recordings_as_audio.py
        # Convert all WAVs to MP3 and write under audio/native/

    python3 scripts/apply_recordings_as_audio.py --dry-run
        # List what would be written without touching disk

    python3 scripts/apply_recordings_as_audio.py --force
        # Overwrite existing native MP3s even if newer than source WAV
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
import unicodedata
from pathlib import Path

# Force UTF-8 stdout/stderr so log lines with ✓ / ✗ / arrows don't
# crash on Windows when piped (cp1252 fallback). See identical block
# in sync_recordings.py for rationale.
for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, 'reconfigure'):
        try:
            _stream.reconfigure(encoding='utf-8', errors='replace')
        except Exception:
            pass

REPO_ROOT = Path(__file__).resolve().parents[1]
RECORDINGS_DIR = REPO_ROOT / "training_data" / "recordings"
MANIFEST = RECORDINGS_DIR / "manifest.json"
PAD_AUDIO_ROOT = REPO_ROOT / "android" / "install_time_assets" / "src" / "main" / "assets" / "audio"
NATIVE_OUT    = PAD_AUDIO_ROOT / "native"
KIDS_OUT      = PAD_AUDIO_ROOT / "native_kids"
COMMUNITY_OUT = PAD_AUDIO_ROOT / "community"  # v1.17.x — contributor recordings

# Algorithm-version sentinel for the silence-trim pipeline. Bump this
# integer whenever the trim algorithm changes in a way that warrants a
# full re-encode of the PAD pack (different windowing, different
# threshold, fixed bug, etc.). The script auto-forces a full re-encode
# whenever the sentinel on disk differs from this constant, so future
# build_and_run.bat runs Just Work — no one has to remember to pass
# --force after pulling a trim improvement.
#
#   v1: initial silence trim (10ms windows, 5% relative threshold,
#       0.005 absolute floor, 20ms padding) — matches lib/utils/
#       silence_trim.dart defaults.
#   v2: emit permanent 16 kHz mono PCM-16 WAV alongside the MP3 as
#       the grader reference (Phase 1C). Existing PAD packs have
#       only MP3, so v2 triggers a full re-encode pass to generate
#       the missing .wav files.
_AUDIO_PIPELINE_VERSION = 2
_PIPELINE_VERSION_FILE = PAD_AUDIO_ROOT / ".pipeline_version"


def _read_pipeline_version() -> int:
    """Return the algorithm version recorded in the PAD pack, or 0 if
    the sentinel is missing/unreadable (treats first-run as "below v1"
    so the next encode pass refreshes everything)."""
    try:
        return int(_PIPELINE_VERSION_FILE.read_text(encoding="utf-8").strip())
    except (FileNotFoundError, ValueError, OSError):
        return 0


def _write_pipeline_version() -> None:
    try:
        _PIPELINE_VERSION_FILE.parent.mkdir(parents=True, exist_ok=True)
        _PIPELINE_VERSION_FILE.write_text(
            str(_AUDIO_PIPELINE_VERSION) + "\n", encoding="utf-8"
        )
    except OSError as exc:
        print(f"  WARNING: could not write pipeline version sentinel: {exc}")

# Known kid recorders → folder slug. Matches the FAMILY list in
# scripts/build_family_recorder.py and the kidVoicesByCharacter map in
# lib/services/pronunciation_service.dart. Adding a name here AND
# updating the Dart picker is what enables a new "Whose voice?" option
# on the Beginner home screen.
KID_SLUGS = {
    "joel":    "joel",
    "janelle": "janelle",
    "joyce":   "joyce",
    "jadyne":  "jadyne",
}

# Adult-name normalizations. These all map to None (not a kid slug) so
# they route to canonical native/, but the SET is recognized so the
# recorder name in the manifest is canonicalized for display + dedup
# consistency. Mirrors sync_recordings.py::_RECORDER_ALIASES.
_ADULT_ALIASES = {
    "sama", "samagids", "samagids@gmail.com", "samagidshop@gmail.com",
    "guidion", "guidion sama", "dr guidion sama", "dr. guidion sama",
    "dr. sama", "dr sama",
    "berlin", "berlin sama",
}


def _is_community_contributor(name) -> bool:
    """Mirrors sync_recordings.py::_is_community_contributor. Returns
    True when the manifest's recorder field signals a Contribute-screen
    submission. Audio routes to audio/community/, NEVER overwrites
    Dr. Sama's audio/native/ recording for the same word."""
    if not name:
        return False
    return name.strip().lower().startswith('default')


def _is_community_wav(wav_path) -> bool:
    """Recognize WAV files that sync_recordings.py prefixed with
    'community__'. Used as a secondary signal in case the manifest
    entry's recorder field is missing."""
    try:
        from pathlib import Path as _P
        return _P(wav_path).name.startswith('community__')
    except Exception:
        return False


def _recorder_to_kid_slug(name: str | None) -> str | None:
    """Return the per-kid output slug if `name` is a known family kid,
    else None. Case-insensitive, tolerates extra whitespace. Recognized
    adult aliases (sama / Dr. Guidion Sama / berlin) also return None
    but are intentionally distinguished from truly unknown recorders
    in the routing logic above (both route to canonical, but adults
    are expected canonical-tier contributors, unknowns are not)."""
    if not name:
        return None
    norm = name.strip().lower()
    # Plain match
    if norm in KID_SLUGS:
        return KID_SLUGS[norm]
    # Tolerate "Joel Sama" / "Joel S." etc. by taking the first token.
    first = norm.split()[0] if norm else ""
    return KID_SLUGS.get(first)

# Map manifest "source" field -> the audio/native/<category>/ subdir
# the app's PronunciationService searches under. The app currently
# tries categories ['vocabulary', 'alphabet', 'dictionary', 'sentences']
# in order, so any unknown source falls through to vocabulary.
_SOURCE_TO_CATEGORY = {
    "alphabet": "alphabet",
    "vocabulary": "vocabulary",
    "dictionary": "dictionary",
    "sentences": "sentences",
    "phrases": "vocabulary",  # phrases live under vocabulary in the lookup
    "stories": "stories",
}

# Tone diacritics + Awing-special chars stripped to build ASCII filenames.
# MUST match the Dart-side _audioKey function in pronunciation_service.dart
# so file lookup succeeds. (Verified: the Dart side does the same NFD
# strip + replacement table.)
_TONE_DIACRITICS = {"́", "̀", "̂", "̌", "̃", "̄"}
_REPLACEMENTS = {
    "ɛ": "e", "Ɛ": "E",
    "ɔ": "o", "Ɔ": "O",
    "ə": "e", "Ə": "E",
    "ɨ": "i", "Ɨ": "I",
    "ŋ": "ng", "Ŋ": "Ng",
    "ɣ": "g", "Ɣ": "G",
    "ʼ": "", "’": "", "‘": "", "'": "",
}


def audio_key(awing: str) -> str:
    """ASCII-safe filename derived from Awing text. Mirrors
    pronunciation_service.dart's _audioKey."""
    decomp = unicodedata.normalize("NFD", awing)
    decomp = "".join(c for c in decomp if c not in _TONE_DIACRITICS)
    s = unicodedata.normalize("NFC", decomp)
    for src, dst in _REPLACEMENTS.items():
        s = s.replace(src, dst)
    s = re.sub(r"[^a-zA-Z0-9_-]+", "_", s)
    s = re.sub(r"_+", "_", s).strip("_")
    return s.lower() or "_"


def convert_wav_to_mp3(wav_path: Path, mp3_path: Path) -> bool:
    """Trim silence and emit BOTH a permanent 16 kHz mono PCM-16 WAV
    (grader reference) AND a 22050 Hz mono MP3 (in-app playback).

    Two outputs per recording:
      - {mp3_path}                       — MP3 for the audio player
      - {mp3_path.with_suffix('.wav')}   — WAV for the on-device
                                            pronunciation grader

    Why two formats:
      - The Flutter audio player wants MP3 (existing behavior — small,
        fast, codec built into every Android/iOS audio stack).
      - The pronunciation grader (lib/services/pronunciation_grader.dart)
        wants raw PCM so we DON'T have to bundle an MP3 decoder native
        library — which would reintroduce the cross-platform / x86_64
        Android problem that killed the ONNX approach. WAV decoder is
        pure Dart, runs everywhere.

    Pipeline:
      1. Trim leading/trailing silence (shared algorithm with the
         on-device grader — scripts/trim_silence.py mirrors
         lib/utils/silence_trim.dart byte-for-byte).
      2. Write trimmed audio as 16 kHz mono PCM-16 WAV (canonical
         speech rate, ~32 KB/sec).
      3. ffmpeg the WAV -> MP3 at 22050 Hz mono 64 kbps for playback.

    Size impact: ~15 MB added to the PAD pack across all native +
    native_kids clips. Acceptable for the offline, on-device grader.
    """
    mp3_path.parent.mkdir(parents=True, exist_ok=True)
    wav_out = mp3_path.with_suffix(".wav")

    # 1) Trim silence directly to the permanent 16 kHz WAV.
    try:
        from scripts.trim_silence import trim_audio_file  # type: ignore
    except ImportError:
        try:
            import sys as _sys

            _sys.path.insert(0, str(REPO_ROOT))
            from scripts.trim_silence import trim_audio_file  # type: ignore
        except Exception:
            trim_audio_file = None  # type: ignore

    trimmed_ok = False
    if trim_audio_file is not None:
        try:
            info = trim_audio_file(wav_path, wav_out, target_sample_rate=16000)
            if info.all_silent:
                # Recording was entirely silent — skip both outputs so
                # we don't ship a useless reference / MP3 over the wire.
                print(f"    ⚠ entirely silent — skipped")
                wav_out.unlink(missing_ok=True)
                return False
            if info.removed_sec >= 0.1:
                print(
                    f"    ✂ trimmed {info.removed_sec:.2f}s silence "
                    f"({info.original_sec:.2f}s → {info.trimmed_sec:.2f}s)"
                )
            trimmed_ok = True
        except Exception as exc:  # noqa: BLE001
            print(f"    trim failed ({exc!s:.80}) — falling back to ffmpeg copy")
            wav_out.unlink(missing_ok=True)

    # 2) Fallback if trim wasn't available or failed: ffmpeg the source
    # WAV to 16 kHz mono PCM-16 so the grader at least has a valid
    # reference, even if it includes silence padding.
    if not trimmed_ok:
        try:
            result = subprocess.run(
                ["ffmpeg", "-y", "-loglevel", "error",
                 "-i", str(wav_path),
                 "-ar", "16000",
                 "-ac", "1",
                 "-sample_fmt", "s16",
                 str(wav_out)],
                capture_output=True,
                check=False,
            )
            if result.returncode != 0:
                print(
                    f"    ffmpeg WAV-copy error: "
                    f"{result.stderr.decode('utf-8', errors='replace')[:200]}"
                )
                return False
        except FileNotFoundError:
            print("ERROR: ffmpeg not on PATH. Install ffmpeg or run from the venv with ffmpeg available.")
            return False

    # 3) ffmpeg the trimmed WAV -> MP3 at the standard playback settings.
    try:
        result = subprocess.run(
            ["ffmpeg", "-y", "-loglevel", "error",
             "-i", str(wav_out),
             "-codec:a", "libmp3lame",
             "-b:a", "64k",
             "-ar", "22050",
             "-ac", "1",  # mono
             str(mp3_path)],
            capture_output=True,
            check=False,
        )
        if result.returncode != 0:
            print(f"    ffmpeg error: {result.stderr.decode('utf-8', errors='replace')[:200]}")
            # Don't delete wav_out — the grader can still use it even if
            # the MP3 step failed.
            return False
        ok = mp3_path.exists() and mp3_path.stat().st_size > 500
        if ok and not (wav_out.exists() and wav_out.stat().st_size > 500):
            # Sanity: should never happen since trim/ffmpeg wrote it above
            print(f"    WARN: WAV reference missing or empty at {wav_out.name}")
        return ok
    except FileNotFoundError:
        print("ERROR: ffmpeg not on PATH. Install ffmpeg or run from the venv with ffmpeg available.")
        return False


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--dry-run", action="store_true",
                    help="List what would be written without touching disk.")
    ap.add_argument("--force", action="store_true",
                    help="Overwrite existing MP3s even if newer than the WAV.")
    ap.add_argument("--source-filter", default=None,
                    help="Only process recordings with manifest.source == this "
                         "value (e.g. 'alphabet').")
    args = ap.parse_args()

    if not MANIFEST.exists():
        print(f"ERROR: {MANIFEST} not found.")
        return 1

    # Pipeline version is now informational only. The per-file check
    # below considers BOTH the MP3 and the WAV side-car and skips when
    # both exist and are newer than the source WAV. So if v2 added the
    # WAV side-car, the first run will re-encode files that are missing
    # their .wav, but files that already have BOTH outputs and were
    # encoded by the current algorithm just get skipped — no wholesale
    # re-encoding.
    #
    # If you DO want to force a full re-encode (e.g. after tweaking the
    # silence-trim thresholds and wanting every clip refreshed), pass
    # --force on the command line.
    on_disk_version = _read_pipeline_version()
    if on_disk_version != _AUDIO_PIPELINE_VERSION and not args.dry_run:
        print(
            f"  Pipeline version: disk=v{on_disk_version} "
            f"→ script=v{_AUDIO_PIPELINE_VERSION} "
            f"(per-file check handles upgrades incrementally; "
            f"pass --force for full re-encode)\n"
        )

    entries = json.loads(MANIFEST.read_text(encoding="utf-8"))
    print(f"Manifest: {len(entries)} recordings\n")

    by_category: dict[str, int] = {}
    written, skipped, failed = 0, 0, 0

    by_kid: dict[str, int] = {}

    for entry in entries:
        awing = (entry.get("awing") or "").strip()
        wav_rel = entry.get("wav_path", "")
        source = entry.get("source", "vocabulary")
        if not awing or not wav_rel:
            continue

        wav_path = REPO_ROOT / wav_rel
        if not wav_path.exists():
            print(f"  MISSING WAV: {wav_rel} (skipping)")
            failed += 1
            continue

        if args.source_filter and source != args.source_filter:
            continue

        category = _SOURCE_TO_CATEGORY.get(source, "vocabulary")
        key = audio_key(awing)
        mp3_path = NATIVE_OUT / category / f"{key}.mp3"

        # Optional per-kid copy. Only when the manifest names a known
        # kid (Joel, Janelle, Joyce, Jadyne) does this path get
        # written. PronunciationService searches the per-kid path
        # FIRST when the user picks that kid in the Beginner home;
        # missing words fall through to the canonical native path
        # below silently. Recordings by Dr. Sama / Berlin Sama /
        # unknown contributors only write the canonical path.
        recorder_name = entry.get("recorder")
        is_community = (
            _is_community_contributor(recorder_name)
            or _is_community_wav(entry.get("wav_path", ""))
        )
        kid_slug = (None if is_community
                    else _recorder_to_kid_slug(recorder_name))
        kid_mp3_path = (KIDS_OUT / kid_slug / category / f"{key}.mp3"
                        if kid_slug else None)
        community_mp3_path = (
            COMMUNITY_OUT / category / f"{key}.mp3" if is_community else None
        )

        # Routing rule (final architecture):
        #   kid_slug present (Joel/Janelle/Joyce/Jadyne):
        #     → write ONLY to audio/native_kids/<slug>/...
        #     → NEVER touch canonical (preserves "My voice" as Dr. Sama
        #       only — picking Joyce never falls back to Joel's voice)
        #
        #   kid_slug absent (Dr. Sama / Berlin Sama / blank / unknown):
        #     → write ONLY to canonical audio/native/...
        #     → curated reference voice; kids never overwrite this
        #
        # Result: PronunciationService search order
        #   1. native_kids/<picked_kid>/   (that kid only)
        #   2. native/                     (Dr. Sama reference fallback)
        #   3. <character>/                (Edge TTS Swahili fallback)
        # cleanly delivers "Joyce's voice only, else Dr. Sama, else TTS".
        # Routing tiers (highest → lowest priority):
        #   1. kid_slug present  → audio/native_kids/<slug>/  (kid-only)
        #   2. is_community      → audio/community/   (contributor — does
        #                          NOT overwrite Dr. Sama's audio/native/)
        #   3. neither           → audio/native/      (Dr. Sama canonical)
        if kid_slug:
            target_path = kid_mp3_path
        elif is_community:
            target_path = community_mp3_path
        else:
            target_path = mp3_path
        wav_companion = target_path.with_suffix(".wav")

        wav_mtime = wav_path.stat().st_mtime

        # Skip when ALL of these are true:
        #   - The MP3 already exists AND is newer than the source WAV
        #   - The WAV side-car already exists AND is newer than the source WAV
        #     (added in pipeline v2 for the on-device grader)
        # If either output is missing or older than the source, we re-encode.
        mp3_fresh = (
            target_path.exists()
            and target_path.stat().st_mtime >= wav_mtime
        )
        wav_fresh = (
            wav_companion.exists()
            and wav_companion.stat().st_mtime >= wav_mtime
        )
        need_write = not (mp3_fresh and wav_fresh)

        if not args.force and not need_write:
            skipped += 1
            continue

        rel_out = target_path.relative_to(REPO_ROOT)
        if kid_slug:
            kid_note = f"  [kid: {kid_slug}]"
        elif is_community:
            kid_note = "  [community]"
        else:
            kid_note = "  [canonical]"
        print(f"  {awing!r:24s} ({source:11s}) -> {rel_out}{kid_note}")
        by_category[category] = by_category.get(category, 0) + 1
        if kid_slug:
            by_kid[kid_slug] = by_kid.get(kid_slug, 0) + 1

        if args.dry_run:
            written += 1
            continue

        # Single conversion to the ONE target path (canonical OR kid,
        # never both). Storage savings + correctness: every byte written
        # belongs to exactly one voice tier with no overwrite conflicts.
        try:
            target_path.parent.mkdir(parents=True, exist_ok=True)
        except OSError as e:
            print(f"    WARN: target mkdir failed: {e}")
            failed += 1
            continue

        ok = convert_wav_to_mp3(wav_path, target_path)
        if ok:
            written += 1
        else:
            failed += 1

    print()
    print(f"{'(DRY RUN) ' if args.dry_run else ''}"
          f"Written: {written}  Skipped (cached): {skipped}  Failed: {failed}")
    print(f"By category: {by_category}")
    if by_kid:
        print(f"By kid:      {by_kid}")
    print()
    print(f"Output root: {NATIVE_OUT.relative_to(REPO_ROOT)}")
    if by_kid:
        print(f"Kid root:    {KIDS_OUT.relative_to(REPO_ROOT)}")
    print()

    # Record the algorithm version we just encoded with so future runs
    # know not to re-trim everything. We only update the sentinel if at
    # least one clip was processed without a hard failure — partial runs
    # (e.g. ffmpeg crashed midway) should NOT advance the version, so the
    # next invocation retries the remaining files.
    if not args.dry_run and failed == 0:
        _write_pipeline_version()

    if not args.dry_run and written > 0:
        print("Next:")
        print("  flutter build appbundle --release")
        print("  # then bundletool install-apks (PAD pack includes new native/ tree)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
