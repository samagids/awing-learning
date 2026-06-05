#!/usr/bin/env python3
"""finetune_bible.py — Piper fine-tune on Bible corpus (runs ON the RunPod pod)

Runs piper-train to fine-tune the Akoose (sw_CD) Piper checkpoint on our
normalized Awing Bible corpus. Akoose is the closest Cameroon Bantu voice
in Piper's library — its phoneme inventory overlaps with Awing's, giving
the fine-tune a head start.

Inputs (assumed present after running setup_runpod.sh + extracting tarball):
  /workspace/bible_corpus_normalized/train/metadata.csv + wav/
  /workspace/bible_corpus_normalized/eval/metadata.csv + wav/
  /workspace/piper_base/sw_CD-lanfrica-medium.onnx

Outputs:
  /workspace/runs/bible_awing/  (lightning checkpoints, tensorboard logs)
  /workspace/runs/bible_awing/best_checkpoint.ckpt (highest-val-score)

Wall time estimates (single A100 80GB):
  - Preprocessing: ~5 min
  - Per epoch: ~3-5 min (~7,400 verses, batch 32)
  - Convergence: 50-100 epochs → 3-6 hours total
  - Cost @ $0.79/hr: ~$3-5

Stops training when val_loss plateaus for 10 epochs (early stopping).
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

WORKSPACE = Path("/workspace")
CORPUS = WORKSPACE / "bible_corpus_normalized"
BASE_CKPT = WORKSPACE / "piper_base" / "sw_CD-lanfrica-medium.onnx"
RUNS_DIR = WORKSPACE / "runs" / "bible_awing"
CACHE_DIR = WORKSPACE / "training_cache"

# Hyperparameters — tuned for 7,400-verse Awing dataset on A100
SAMPLE_RATE = 22050
BATCH_SIZE = 32         # A100 80GB handles this; reduce to 16 for 40GB
MAX_EPOCHS = 200
EARLY_STOP_PATIENCE = 10
VAL_CHECK_INTERVAL = 1.0  # Validate every epoch
LEARNING_RATE = 2e-4


def preflight() -> bool:
    """Verify everything we need exists before consuming GPU time."""
    print("=" * 70)
    print(" Pre-flight checks")
    print("=" * 70)
    ok = True
    checks = [
        (CORPUS / "train" / "metadata.csv", "Training metadata"),
        (CORPUS / "train" / "wav", "Training WAV directory"),
        (CORPUS / "eval" / "metadata.csv", "Eval metadata"),
        (CORPUS / "eval" / "wav", "Eval WAV directory"),
        (BASE_CKPT, "Base Piper checkpoint"),
    ]
    for path, label in checks:
        if path.exists():
            if path.is_dir():
                n = len(list(path.glob("*.wav"))) if "wav" in str(path) else "(dir)"
                print(f"  ✓ {label}: {path} ({n} files)" if isinstance(n, int)
                      else f"  ✓ {label}: {path}")
            else:
                sz = path.stat().st_size / 1024 / 1024
                print(f"  ✓ {label}: {path} ({sz:.0f} MB)")
        else:
            print(f"  ✗ {label}: MISSING at {path}")
            ok = False

    # GPU check
    try:
        result = subprocess.run(
            ["nvidia-smi", "--query-gpu=name,memory.total", "--format=csv,noheader"],
            capture_output=True, text=True, check=True,
        )
        print(f"  ✓ GPU: {result.stdout.strip()}")
    except Exception as e:
        print(f"  ✗ GPU check failed: {e}")
        ok = False

    print()
    return ok


def preprocess() -> None:
    """Run piper-train preprocessing on both splits."""
    print("=" * 70)
    print(" Preprocessing corpus (computes mel-spectrograms, ~5 min)")
    print("=" * 70)
    CACHE_DIR.mkdir(parents=True, exist_ok=True)

    # piper-train expects a single combined dataset directory
    combined = CACHE_DIR / "dataset"
    combined.mkdir(parents=True, exist_ok=True)

    # Merge train + eval (piper-train does its own split internally)
    merged_csv = combined / "metadata.csv"
    merged_wav = combined / "wav"
    merged_wav.mkdir(exist_ok=True)

    if not merged_csv.exists():
        print("  Building merged dataset directory...")
        lines = []
        for split in ("train", "eval"):
            meta = CORPUS / split / "metadata.csv"
            wav_dir = CORPUS / split / "wav"
            for line in meta.read_text(encoding="utf-8").splitlines():
                line = line.strip()
                if not line:
                    continue
                lines.append(line)
                clip_id = line.split("|", 1)[0]
                src = wav_dir / f"{clip_id}.wav"
                dst = merged_wav / f"{clip_id}.wav"
                if not dst.exists() and src.exists():
                    dst.symlink_to(src.resolve())
        merged_csv.write_text("\n".join(lines), encoding="utf-8")
        print(f"  ✓ {len(lines):,} clips merged")
    else:
        print("  Merged dataset already exists — reusing")

    # Run piper-train preprocess
    out_dir = CACHE_DIR / "preprocessed"
    if not (out_dir / "config.json").exists():
        cmd = [
            sys.executable, "-m", "piper_train.preprocess",
            "--language", "awing",
            "--input-dir", str(combined),
            "--output-dir", str(out_dir),
            "--dataset-format", "ljspeech",
            "--single-speaker",
            "--sample-rate", str(SAMPLE_RATE),
        ]
        print(f"  Running: {' '.join(cmd)}")
        subprocess.run(cmd, check=True)
    print(f"  ✓ Preprocessed: {out_dir}")
    print()


def train() -> None:
    """Run piper-train training loop."""
    print("=" * 70)
    print(f" Training — max {MAX_EPOCHS} epochs, early-stop after {EARLY_STOP_PATIENCE} stagnant")
    print("=" * 70)
    RUNS_DIR.mkdir(parents=True, exist_ok=True)
    preprocessed = CACHE_DIR / "preprocessed"

    cmd = [
        sys.executable, "-m", "piper_train",
        "--dataset-dir", str(preprocessed),
        "--accelerator", "gpu",
        "--devices", "1",
        "--batch-size", str(BATCH_SIZE),
        "--validation-split", "0.05",
        "--num-test-examples", "5",
        "--max_epochs", str(MAX_EPOCHS),
        "--resume_from_checkpoint", str(BASE_CKPT.with_suffix("")) + ".ckpt"
            if BASE_CKPT.with_suffix("").with_suffix(".ckpt").exists()
            else "",
        "--checkpoint-epochs", "5",
        "--precision", "16",
        "--quality", "medium",
        "--default_root_dir", str(RUNS_DIR),
    ]
    cmd = [c for c in cmd if c]
    print(f"  Running: {' '.join(cmd[:6])}...")
    print()
    subprocess.run(cmd, check=True)
    print()
    print(f"  ✓ Training complete. Checkpoints in {RUNS_DIR}")


def export_onnx() -> None:
    """Export the best Lightning checkpoint to ONNX (the runtime format)."""
    print("=" * 70)
    print(" Exporting best checkpoint to ONNX")
    print("=" * 70)
    # Find best checkpoint (highest version number's best.ckpt)
    candidates = sorted(RUNS_DIR.rglob("*.ckpt"),
                        key=lambda p: p.stat().st_mtime, reverse=True)
    if not candidates:
        print("  ✗ no checkpoint found")
        return
    best = candidates[0]
    print(f"  Best checkpoint: {best}")

    out_onnx = WORKSPACE / "awing_bible_voice.onnx"
    cmd = [
        sys.executable, "-m", "piper_train.export_onnx",
        str(best),
        str(out_onnx),
    ]
    print(f"  Running: {' '.join(cmd)}")
    subprocess.run(cmd, check=True)
    print(f"  ✓ Exported: {out_onnx}")

    # Also copy the config JSON next to it
    cfg_src = CACHE_DIR / "preprocessed" / "config.json"
    cfg_dst = WORKSPACE / "awing_bible_voice.onnx.json"
    if cfg_src.exists():
        cfg_dst.write_bytes(cfg_src.read_bytes())
        print(f"  ✓ Config: {cfg_dst}")
    print()


def main() -> int:
    if not preflight():
        print("Pre-flight failed — fix the missing items above and retry.")
        return 1
    preprocess()
    train()
    export_onnx()
    print("=" * 70)
    print(" DONE. Download these two files back to your local machine:")
    print(f"   /workspace/awing_bible_voice.onnx       (~25-30 MB)")
    print(f"   /workspace/awing_bible_voice.onnx.json  (~10 KB)")
    print(" Then run generate_vocab_clips.py locally to synthesize all 8k words.")
    print("=" * 70)
    return 0


if __name__ == "__main__":
    sys.exit(main())
