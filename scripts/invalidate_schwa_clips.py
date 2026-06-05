#!/usr/bin/env python3
"""invalidate_schwa_clips.py — Delete OPUS clips for all unrecorded vocab
words that CONTAIN ə (the words affected by the Session 60+ word-final
ə → a rule change in awing_to_speakable()).

Why: generate_audio_edge.py uses an incremental cache — it skips files
that already exist. To pick up the new schwa rule, we have to invalidate
the cache for words the rule would change.

Why surgical (not nuke everything): regenerating only the ~4,800 affected
words across 4 voices ≈ 19,000 clips × 0.5 sec each ≈ 2.6 hrs on Edge TTS.
Regenerating everything (~9,000 words × 4 voices ≈ 36,000 clips) would be
~5 hrs and burns Edge TTS quota for no quality gain.

Safety:
- Only touches files under audio/{boy,girl,young_man,young_woman,man,woman}/
- Skips audio/native/ and audio/community/ (recorded clips — untouched)
- Skips audio/alphabet,sentences,stories sub-paths (only vocab clips affected)
- Reports what it would do; --apply to actually delete

Usage:
  python scripts/invalidate_schwa_clips.py            # dry-run, lists count
  python scripts/invalidate_schwa_clips.py --apply    # actually deletes
"""
from __future__ import annotations

import argparse
import re
import sys
import unicodedata
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
VOCAB_FILE = REPO / "lib" / "data" / "awing_vocabulary.dart"

# PAD pack audio root + legacy root
AUDIO_ROOTS = [
    REPO / "android" / "install_time_assets" / "src" / "main" / "assets" / "audio",
    REPO / "assets" / "audio",
]

# These voice subdirs hold Edge TTS clips that may need invalidating.
# Native + community + alphabet/sentences/stories are NEVER touched.
EDGE_VOICES = ("boy", "girl", "young_man", "young_woman", "man", "woman")
EDGE_CATEGORIES = ("vocabulary",)  # only vocab is affected by the schwa rule


_KEY_REPL = {"ɛ": "e", "Ɛ": "E", "ɔ": "o", "Ɔ": "O", "ə": "e", "Ə": "E",
             "ɨ": "i", "Ɨ": "I", "ŋ": "ng", "Ŋ": "Ng", "ɣ": "g", "Ɣ": "G"}


def audio_key(awing: str) -> str:
    s = awing.replace("'", "").replace("ʼ", "").replace("’", "").replace("‘", "")
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if not unicodedata.combining(c))
    for k, v in _KEY_REPL.items():
        s = s.replace(k, v)
    s = re.sub(r"[^A-Za-z0-9]+", "_", s).strip("_").lower()
    return s


def load_vocab() -> list[str]:
    sq = r"'((?:\\.|[^'\\])*)'"
    dq = r'"((?:\\.|[^"\\])*)"'
    s = rf"(?:{sq}|{dq})"
    pat = re.compile(rf"AwingWord\(\s*awing:\s*{s}", re.DOTALL)
    content = VOCAB_FILE.read_text(encoding="utf-8")
    out = []
    for m in pat.finditer(content):
        line_start = content.rfind("\n", 0, m.start()) + 1
        if "//" in content[line_start : m.start()]:
            continue
        awing = (m.group(1) or m.group(2) or "").replace("\\'", "'")
        if awing:
            out.append(awing)
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true",
                    help="Actually delete files. Without this flag, only counts.")
    args = ap.parse_args()

    # 1. Find affected words
    print("Loading vocabulary...")
    vocab = load_vocab()
    affected_words = [w for w in vocab if "ə" in w or "Ə" in w]
    affected_keys = {audio_key(w) for w in affected_words}
    print(f"  {len(vocab):,} total vocab words")
    print(f"  {len(affected_words):,} contain ə (will be regenerated)")
    print(f"  {len(affected_keys):,} unique audio keys")

    # 2. Walk Edge TTS voice directories and find clips matching affected keys
    print("\nScanning Edge TTS voice clips...")
    to_delete = []
    for root in AUDIO_ROOTS:
        if not root.exists():
            continue
        for voice in EDGE_VOICES:
            for category in EDGE_CATEGORIES:
                voice_dir = root / voice / category
                if not voice_dir.exists():
                    continue
                for ext in (".opus", ".mp3"):
                    for path in voice_dir.glob(f"*{ext}"):
                        if path.stem in affected_keys:
                            to_delete.append(path)

    print(f"  Found {len(to_delete):,} clip files to invalidate")

    if not to_delete:
        print("\nNothing to do.")
        return 0

    # 3. Show a sample and total size
    total_bytes = sum(p.stat().st_size for p in to_delete)
    print(f"  Total size: {total_bytes / 1024 / 1024:.1f} MB")
    print("\nSample of files (first 10):")
    for p in to_delete[:10]:
        rel = p.relative_to(REPO)
        print(f"  {rel}")

    # 4. Per-voice summary
    print("\nPer-voice counts:")
    from collections import Counter
    voice_counts = Counter()
    for p in to_delete:
        # Find voice name in path
        for v in EDGE_VOICES:
            if f"/{v}/" in str(p).replace("\\", "/"):
                voice_counts[v] += 1
                break
    for voice in EDGE_VOICES:
        if voice_counts[voice]:
            print(f"  {voice:<15} {voice_counts[voice]:,} clips")

    # 5. Delete (if --apply) or stop
    if not args.apply:
        print("\nDry run — no files deleted.")
        print("Run again with --apply to actually delete.")
        return 0

    print(f"\nDeleting {len(to_delete):,} files...")
    deleted = 0
    for p in to_delete:
        try:
            p.unlink()
            deleted += 1
        except OSError as e:
            print(f"  ✗ {p.name}: {e}")
    print(f"  ✓ Deleted {deleted:,} clips")
    print("\nNext: python scripts/generate_audio_edge.py generate")
    print("  (will regenerate only the deleted clips with the new schwa rule)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
