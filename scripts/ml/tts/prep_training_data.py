#!/usr/bin/env python3
"""prep_training_data.py — Package Bible corpus for cloud GPU upload

Reads the existing Session 56 corpus at:
    corpus/aligned/piper/{train,eval}/
        metadata.csv  (LJSpeech format: clip_id|text)
        wav/         (one WAV per clip, 22050 Hz mono)

Applies training-time text normalization (normalize_text.py) to every
verse so the model sees consistent orthography. Writes a normalized copy
to:
    corpus/aligned/normalized/{train,eval}/
        metadata.csv  (normalized texts)
        wav/         (symlinks to the original WAVs — no duplication)

Then packs everything into a single tar.gz for upload to RunPod:
    corpus/aligned/bible_corpus_normalized.tar.gz

Outputs a summary so we know how much data we're shipping.

Run:
    python scripts/ml/tts/prep_training_data.py
"""
from __future__ import annotations

import shutil
import subprocess
import sys
import tarfile
from pathlib import Path

# Import the shared normalizer
SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))
from normalize_text import normalize_for_training

REPO = SCRIPT_DIR.parent.parent.parent
CORPUS_ROOT = REPO / "corpus" / "aligned"
SOURCE_ROOT = CORPUS_ROOT / "piper"
NORM_ROOT = CORPUS_ROOT / "normalized"
TARBALL = CORPUS_ROOT / "bible_corpus_normalized.tar.gz"


def normalize_split(split: str) -> tuple[int, int]:
    """Normalize one split (train/eval). Returns (lines_in, lines_out)."""
    src_meta = SOURCE_ROOT / split / "metadata.csv"
    src_wav_dir = SOURCE_ROOT / split / "wav"
    dst_dir = NORM_ROOT / split
    dst_wav_dir = dst_dir / "wav"
    dst_meta = dst_dir / "metadata.csv"

    if not src_meta.exists():
        print(f"  ! {src_meta} missing — skip")
        return 0, 0
    if not src_wav_dir.exists():
        print(f"  ! {src_wav_dir} missing — skip")
        return 0, 0

    dst_dir.mkdir(parents=True, exist_ok=True)
    dst_wav_dir.mkdir(parents=True, exist_ok=True)

    lines_in = 0
    lines_out = 0
    out_lines = []
    for raw in src_meta.read_text(encoding="utf-8").splitlines():
        lines_in += 1
        raw = raw.strip()
        if not raw or "|" not in raw:
            continue
        clip_id, text = raw.split("|", 1)
        normalized = normalize_for_training(text)
        if not normalized:
            continue
        # Verify the WAV exists; skip orphans
        wav_src = src_wav_dir / f"{clip_id}.wav"
        if not wav_src.exists():
            continue
        # Copy (not symlink — tarballs hate symlinks across hosts)
        wav_dst = dst_wav_dir / f"{clip_id}.wav"
        if not wav_dst.exists():
            shutil.copy2(wav_src, wav_dst)
        out_lines.append(f"{clip_id}|{normalized}")
        lines_out += 1

    dst_meta.write_text("\n".join(out_lines) + "\n", encoding="utf-8")
    return lines_in, lines_out


def pack_tarball() -> int:
    """Pack the normalized corpus into a single tar.gz. Returns size in MB."""
    if TARBALL.exists():
        print(f"  ⚠ existing tarball will be overwritten ({TARBALL.stat().st_size / 1024 / 1024:.0f} MB)")
        TARBALL.unlink()

    print(f"  Packing → {TARBALL.name}...")
    with tarfile.open(TARBALL, "w:gz", compresslevel=6) as tf:
        # Add only the normalized/ tree, with a clean top-level directory name
        tf.add(NORM_ROOT, arcname="bible_corpus_normalized")
    size_mb = TARBALL.stat().st_size / 1024 / 1024
    return int(size_mb)


def main() -> int:
    print("=" * 70)
    print(" Bible corpus → cloud GPU upload package")
    print("=" * 70)
    print()

    if not SOURCE_ROOT.exists():
        print(f"  ✗ {SOURCE_ROOT} missing — run scripts/ml/forced_align.py first")
        return 1

    print(f"Source:      {SOURCE_ROOT}")
    print(f"Normalized:  {NORM_ROOT}")
    print(f"Tarball:     {TARBALL}")
    print()

    # Normalize both splits
    for split in ("train", "eval"):
        print(f"Normalizing {split}/ ...")
        lines_in, lines_out = normalize_split(split)
        print(f"  → {lines_out:,}/{lines_in:,} verses kept")

    # Pack
    print()
    print("Creating tarball...")
    size_mb = pack_tarball()
    print(f"  ✓ {TARBALL.name}: {size_mb} MB")

    # Summary
    print()
    print("=" * 70)
    print(" Ready to upload")
    print("=" * 70)
    print(f"  File:  {TARBALL}")
    print(f"  Size:  {size_mb} MB")
    print()
    print("  Next step (on Windows):")
    print(f"    1. Spin up a RunPod A100: see scripts/ml/tts/RUNPOD_GUIDE.md")
    print(f"    2. Upload {TARBALL.name} to /workspace/ on the pod (via")
    print(f"       runpodctl, scp, or the web UI's file uploader)")
    print(f"    3. Inside the pod, run: bash setup_runpod.sh && python finetune_bible.py")
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
