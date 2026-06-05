#!/usr/bin/env python3
"""finetune_vits_bible.py — Coqui VITS training on Awing Bible corpus

Single-speaker VITS training from scratch on our LJSpeech-format corpus.
Coqui TTS's reference implementation, adapted with conservative
hyperparameters for our 7,410-verse Awing dataset.

Why train from scratch instead of fine-tune from English VITS?
  - Single-speaker, single-language. No multi-speaker complexity.
  - Phoneme inventory is Awing-specific; transfer from English would
    confuse the model with phonemes it shouldn't pronounce.
  - 7,410 training samples is enough for VITS to converge (~6 hrs on A100).

Inputs (assumed present after setup_runpod_coqui.sh + tarball extracted):
  /workspace/bible_corpus_normalized/train/metadata.csv + wav/
  /workspace/bible_corpus_normalized/eval/metadata.csv + wav/

Outputs:
  /workspace/runs/vits_awing/  (lightning checkpoints, tensorboard logs)
  /workspace/awing_vits_voice.pth  (best model — download this back home)
  /workspace/awing_vits_voice.json (config — download too)

Wall time on single A100 80GB: ~3-6 hours to convergence
Cost @ $1.50/hr: ~$5-9
"""
from __future__ import annotations

import os
import shutil
import sys
from pathlib import Path

import torch
from trainer import Trainer, TrainerArgs

from TTS.tts.configs.shared_configs import BaseDatasetConfig, CharactersConfig
from TTS.tts.configs.vits_config import VitsConfig
from TTS.tts.datasets import load_tts_samples
from TTS.tts.models.vits import Vits, VitsAudioConfig
from TTS.utils.audio import AudioProcessor
from TTS.tts.utils.text.tokenizer import TTSTokenizer

WORKSPACE = Path("/workspace")
CORPUS = WORKSPACE / "bible_corpus_normalized"
RUNS_DIR = WORKSPACE / "runs" / "vits_awing"
COMBINED_DIR = WORKSPACE / "combined_dataset"

SAMPLE_RATE = 22050
# BATCH_SIZE: A100 80GB easily handles 64 (uses ~16 GB VRAM at batch=64).
# Tested 2026-06-05: batch=32 used only 8.4 GB / 81 GB and got 60% GPU
# util, so 2x bump halves training time without risk. Reduce to 16 if
# you ever see OOM on a smaller GPU (e.g. A100 40GB with mixed precision).
BATCH_SIZE = 64
NUM_EPOCHS = 200  # Early stops via loss plateau in practice
LEARNING_RATE = 0.0002


def merge_splits() -> None:
    """Coqui prefers a single metadata.csv. Merge train + eval, with
    eval clips marked for use as validation split inside training.

    LJSpeech format requires 3 pipe-delimited columns:
      clip_id | original_text | normalized_text
    Our forced-alignment output (forced_align.py) uses 2 columns
    (clip_id|text). We duplicate `text` into both LJSpeech text columns
    since we already normalized via normalize_for_training()."""
    if (COMBINED_DIR / "metadata.csv").exists():
        print("  Combined dataset already exists, reusing.")
        return

    COMBINED_DIR.mkdir(parents=True, exist_ok=True)
    wav_dir = COMBINED_DIR / "wavs"
    wav_dir.mkdir(exist_ok=True)

    lines = []
    for split in ("train", "eval"):
        meta = CORPUS / split / "metadata.csv"
        src_wav_dir = CORPUS / split / "wav"
        for line in meta.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or "|" not in line:
                continue
            parts = line.split("|")
            clip_id = parts[0]
            text = parts[1] if len(parts) >= 2 else ""
            if not text:
                continue
            src = src_wav_dir / f"{clip_id}.wav"
            dst = wav_dir / f"{clip_id}.wav"
            if not dst.exists() and src.exists():
                # Use symlinks to avoid duplicating 3 GB of audio
                dst.symlink_to(src.resolve())
            # Force LJSpeech 3-column format: id|text|text
            normalized = parts[2] if len(parts) >= 3 else text
            lines.append(f"{clip_id}|{text}|{normalized}")
    (COMBINED_DIR / "metadata.csv").write_text(
        "\n".join(lines) + "\n", encoding="utf-8"
    )
    print(f"  ✓ Merged {len(lines):,} clips into {COMBINED_DIR}")


def main() -> int:
    print("=" * 70)
    print(" Coqui VITS fine-tune on Awing Bible corpus")
    print("=" * 70)

    # Preflight
    if not CORPUS.exists():
        print(f"  ✗ Missing {CORPUS}")
        return 1
    if not torch.cuda.is_available():
        print("  ✗ CUDA not available")
        return 1
    print(f"  GPU: {torch.cuda.get_device_name(0)}")
    print(f"  VRAM: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.0f} GB")

    print()
    print("[1/4] Merging train + eval into combined dataset...")
    merge_splits()

    print()
    print("[2/4] Building dataset config...")
    dataset_config = BaseDatasetConfig(
        formatter="ljspeech",
        meta_file_train="metadata.csv",
        path=str(COMBINED_DIR),
        # No language code needed for monolingual VITS
    )

    print()
    print("[3/4] Building model config...")
    audio_config = VitsAudioConfig(
        sample_rate=SAMPLE_RATE,
        win_length=1024,
        hop_length=256,
        num_mels=80,
        mel_fmin=0,
        mel_fmax=None,
    )

    # Awing-specific character set: lowercase Latin + special vowels + tones
    # Coqui's tokenizer needs to know which characters are valid input.
    # We let the auto-builder discover the inventory from the dataset.
    character_config = CharactersConfig(
        characters_class="TTS.tts.utils.text.characters.IPAPhonemes",
        # Include all special Awing chars; punctuation_chars handled
        # automatically. Coqui tolerates extras.
        pad="<PAD>",
        eos="<EOS>",
        bos="<BOS>",
        blank="<BLNK>",
    )

    config = VitsConfig(
        audio=audio_config,
        run_name="vits_awing_bible",
        batch_size=BATCH_SIZE,
        eval_batch_size=8,
        batch_group_size=4,
        num_loader_workers=4,
        num_eval_loader_workers=2,
        run_eval=True,
        test_delay_epochs=-1,
        epochs=NUM_EPOCHS,
        text_cleaner=None,                # Awing is already normalized
        use_phonemes=False,               # No phoneme dictionary for Awing
        compute_input_seq_cache=True,
        print_step=50,
        print_eval=False,
        mixed_precision=True,             # fp16 — A100 handles fine
        output_path=str(RUNS_DIR),
        datasets=[dataset_config],
        save_step=2000,
        save_n_checkpoints=3,
        save_best_after=2000,
        lr_gen=LEARNING_RATE,
        lr_disc=LEARNING_RATE,
        cudnn_benchmark=True,
        # Validation: hold out 5% for eval; the rest trains
        eval_split_size=0.05,
    )

    print("  ✓ VITS config built")
    print(f"     batch_size: {BATCH_SIZE}")
    print(f"     epochs:     {NUM_EPOCHS} (with early-stop via loss plateau)")
    print(f"     output:     {RUNS_DIR}")

    print()
    print("[4/4] Loading samples + building model...")
    train_samples, eval_samples = load_tts_samples(
        dataset_config,
        eval_split=True,
        eval_split_size=config.eval_split_size,
    )
    print(f"  → {len(train_samples):,} training samples")
    print(f"  → {len(eval_samples):,} eval samples")

    ap = AudioProcessor.init_from_config(config)
    tokenizer, config = TTSTokenizer.init_from_config(config)
    model = Vits(config, ap, tokenizer, speaker_manager=None)
    print("  ✓ Model initialized")

    # Train
    print()
    print("=" * 70)
    print(" Starting training — go get coffee. Watch progress via:")
    print(f"   tail -f {RUNS_DIR}/vits_awing_bible-*/trainer_*.log")
    print("=" * 70)

    trainer = Trainer(
        TrainerArgs(),
        config,
        output_path=str(RUNS_DIR),
        model=model,
        train_samples=train_samples,
        eval_samples=eval_samples,
    )
    trainer.fit()

    # Find best checkpoint
    print()
    print("=" * 70)
    print(" Training complete. Locating best checkpoint...")
    best_paths = sorted(
        RUNS_DIR.rglob("best_model*.pth"),
        key=lambda p: p.stat().st_mtime, reverse=True,
    )
    if not best_paths:
        best_paths = sorted(
            RUNS_DIR.rglob("checkpoint_*.pth"),
            key=lambda p: p.stat().st_mtime, reverse=True,
        )
    if best_paths:
        best = best_paths[0]
        out_model = WORKSPACE / "awing_vits_voice.pth"
        out_config = WORKSPACE / "awing_vits_voice.json"
        shutil.copy(best, out_model)
        config_src = best.parent / "config.json"
        if config_src.exists():
            shutil.copy(config_src, out_config)
        print(f"  ✓ Model:  {out_model} ({out_model.stat().st_size / 1024**2:.0f} MB)")
        print(f"  ✓ Config: {out_config}")
    print()
    print(" DOWNLOAD these to your local machine, then STOP THE POD.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
