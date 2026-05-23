#!/usr/bin/env python3
"""Convert family_recordings/*.webm into MP3 files in the PAD native-voice tier.

Reads the structured filenames the recorder produces -- {voice}_{name}__{key}.webm
-- and:

  1. Converts each .webm to .mp3 via ffmpeg (libmp3lame, 22050 Hz mono).
  2. Picks the LATEST recording per (voice, name, key) so re-records win.
  3. Copies the MP3 into:
        android/install_time_assets/src/main/assets/audio/native/{voice}/{key}.mp3
     The PronunciationService loads the 'native' tier as priority 0.

  When two family members share the same voice tier (Joel + Janelle both on
  'boy', Joyce + Jadyne both on 'girl'), this script uses whichever recording
  is NEWEST on disk. Override per-word selection by passing --prefer joel,joyce.

Usage:
    python scripts/process_family_recordings.py
    python scripts/process_family_recordings.py --dry-run
    python scripts/process_family_recordings.py --prefer guidion,berlin,joel,joyce
"""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

ROOT          = Path(__file__).resolve().parent.parent
RECORDINGS    = ROOT / "family_recordings"
NATIVE_AUDIO  = (ROOT / "android" / "install_time_assets" / "src" /
                 "main" / "assets" / "audio" / "native")

FILENAME_RE = re.compile(
    r"^(?P<voice>man|woman|boy|girl)_(?P<name>[a-z]+)__(?P<key>[a-z0-9_]+(?:__\d+)?)\.webm$"
)


def parse_args():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dry-run", action="store_true",
                    help="Print what would happen without converting/copying")
    ap.add_argument("--prefer", default="",
                    help="Comma-separated list of preferred names within each voice "
                         "tier when there is a tie. Earlier = higher priority.")
    return ap.parse_args()


def ensure_ffmpeg():
    if shutil.which("ffmpeg") is None:
        sys.exit("ffmpeg not found in PATH. Install with: winget install Gyan.FFmpeg")


def scan_recordings():
    """Return {(voice, key): [Path...]} sorted newest-first per bucket."""
    if not RECORDINGS.exists():
        sys.exit("Missing folder: " + str(RECORDINGS))
    by_slot = defaultdict(list)
    rejected = []
    for p in sorted(RECORDINGS.glob("*.webm")):
        m = FILENAME_RE.match(p.name)
        if not m:
            rejected.append(p.name)
            continue
        voice = m.group("voice")
        name  = m.group("name")
        key   = m.group("key")
        by_slot[(voice, key)].append((p, name))
    # Sort each bucket newest-first by mtime
    for slot, lst in by_slot.items():
        lst.sort(key=lambda pn: pn[0].stat().st_mtime, reverse=True)
    return by_slot, rejected


def pick_winner(bucket, prefer):
    """Pick which recording wins for a (voice, key) slot."""
    if prefer:
        for name in prefer:
            for path, owner in bucket:
                if owner == name:
                    return path, owner
    # Default: newest mtime
    return bucket[0]


def convert(src: Path, dst: Path, dry_run: bool) -> bool:
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dry_run:
        print("[dry-run] {}  ->  {}".format(src.name, dst.relative_to(ROOT)))
        return True
    cmd = [
        "ffmpeg", "-y", "-loglevel", "error",
        "-i", str(src),
        "-ar", "22050", "-ac", "1",
        "-codec:a", "libmp3lame", "-q:a", "4",
        str(dst),
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        print("ffmpeg FAILED for {}: {}".format(src.name, proc.stderr.strip()))
        return False
    return True


def main():
    args = parse_args()
    ensure_ffmpeg()
    prefer = [s.strip().lower() for s in args.prefer.split(",") if s.strip()]

    by_slot, rejected = scan_recordings()
    print("Found {} (voice, word) slots in {}".format(len(by_slot), RECORDINGS))
    if rejected:
        print("Rejected (bad filename): " + ", ".join(rejected[:5]) +
              (" ... +{} more".format(len(rejected) - 5) if len(rejected) > 5 else ""))

    converted, skipped = 0, 0
    for (voice, key), bucket in sorted(by_slot.items()):
        winner_path, winner_name = pick_winner(bucket, prefer)
        dst = NATIVE_AUDIO / voice / (key + ".mp3")
        if convert(winner_path, dst, args.dry_run):
            converted += 1
            if len(bucket) > 1:
                others = ", ".join(n for _, n in bucket[1:])
                print("  {} [{}] {}  (winner: {}; also recorded: {})".format(
                    voice, key, " " if args.dry_run else "OK", winner_name, others))
            else:
                print("  {} [{}] {}  (from {})".format(
                    voice, key, " " if args.dry_run else "OK", winner_name))
        else:
            skipped += 1

    print()
    print("Done. Converted {} files, skipped {}.".format(converted, skipped))
    if not args.dry_run and converted:
        print("MP3s landed under: " + str(NATIVE_AUDIO.relative_to(ROOT)))
        print("Next step: rebuild the APK so PAD picks up the new audio.")


if __name__ == "__main__":
    main()
