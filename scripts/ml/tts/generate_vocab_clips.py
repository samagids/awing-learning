#!/usr/bin/env python3
"""generate_vocab_clips.py — Synthesize all 8k vocab words with trained Coqui VITS

Runs LOCALLY (on your Windows GPU machine, NOT on RunPod). After fine-tuning
on RunPod completes, you download:
  - awing_vits_voice.pth   (the trained model, ~100-150 MB)
  - awing_vits_voice.json  (model config)

Place both in models/awing_bible_voice/, then run this script. It:
  1. Loads the trained Coqui VITS model via TTS.utils.synthesizer.Synthesizer
  2. Reads every word from awing_vocabulary.dart
  3. Normalizes each word via normalize_for_inference()
  4. Synthesizes a WAV → encodes as MP3 → writes to PAD pack
  5. Skips words with BAD phonemes (Edge TTS fallback handles those)

Output goes to:
    android/install_time_assets/src/main/assets/audio/bible_trained/{category}/{key}.mp3

Then pronunciation_service.dart picks it up as a new tier between native
(Dr. Sama / family) and character voices (Edge TTS).

Hardware: works on CPU but slow (~2 sec/word, ~5 hours total for 8k words).
On NVIDIA GPU: ~0.3 sec/word, ~45 minutes total.

Usage:
  python scripts\\ml\\tts\\generate_vocab_clips.py [--force] [--limit N]
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
import time
import unicodedata
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))
from normalize_text import normalize_for_inference

REPO = SCRIPT_DIR.parent.parent.parent
VOCAB_FILE = REPO / "lib" / "data" / "awing_vocabulary.dart"
# Coqui VITS model files (downloaded from RunPod after training).
# Place these in models/awing_bible_voice/ before running this script.
MODEL_DIR = REPO / "models" / "awing_bible_voice"
MODEL_PTH = MODEL_DIR / "awing_vits_voice.pth"
MODEL_JSON = MODEL_DIR / "awing_vits_voice.json"
OUT_ROOT = REPO / "android" / "install_time_assets" / "src" / "main" / "assets" / "audio" / "bible_trained"

# Same audio_key() logic as generate_audio_edge.py and apply_recordings_as_audio.py
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


def load_vocab() -> list[tuple[str, str, str]]:
    """Return [(awing, english, category), ...] from awing_vocabulary.dart."""
    sq = r"'((?:\\.|[^'\\])*)'"
    dq = r'"((?:\\.|[^"\\])*)"'
    s = rf"(?:{sq}|{dq})"
    pat = re.compile(
        rf"AwingWord\(\s*awing:\s*{s}\s*,\s*english:\s*{s}.*?category:\s*{s}",
        re.DOTALL,
    )
    content = VOCAB_FILE.read_text(encoding="utf-8")
    out = []
    for m in pat.finditer(content):
        line_start = content.rfind("\n", 0, m.start()) + 1
        if "//" in content[line_start : m.start()]:
            continue
        awing = (m.group(1) if m.group(1) is not None else m.group(2) or "").replace("\\'", "'")
        # group(3..4) = english, group(5..6) = category
        groups = [g for g in m.groups() if g is not None]
        if len(groups) >= 3:
            english = groups[1].replace("\\'", "'")
            category = groups[2].replace("\\'", "'")
            if awing:
                out.append((awing, english, category))
    return out


# Map vocab category → output subdirectory
CATEGORY_DIRS = {
    "bodyParts": "vocabulary",
    "animalsNature": "vocabulary",
    "foodDrink": "vocabulary",
    "actions": "vocabulary",
    "thingsObjects": "vocabulary",
    "familyPeople": "vocabulary",
    "numbers": "vocabulary",
    "descriptiveWords": "vocabulary",
    "pronouns": "vocabulary",
    "timeWords": "vocabulary",
    "moreActions": "vocabulary",
    "moreThings": "vocabulary",
    "dictionaryEntries": "vocabulary",
}


def init_synthesizer():
    """Lazy-import Coqui TTS. Returns a Synthesizer wrapping the trained
    VITS model. CUDA is used automatically if available, else CPU."""
    try:
        from TTS.utils.synthesizer import Synthesizer
        import torch
    except ImportError:
        print("ERROR: coqui-tts not installed.")
        print("  pip install coqui-tts>=0.27")
        sys.exit(1)
    use_cuda = torch.cuda.is_available()
    print(f"  Using {'CUDA' if use_cuda else 'CPU'} for inference")
    synth = Synthesizer(
        tts_checkpoint=str(MODEL_PTH),
        tts_config_path=str(MODEL_JSON),
        use_cuda=use_cuda,
    )
    return synth


def synthesize_one(synth, awing: str, out_path: Path, force: bool) -> str:
    """Synthesize one word to MP3. Returns 'ok' / 'skip' / 'err:<reason>'."""
    if out_path.exists() and not force:
        return "skip"
    text = normalize_for_inference(awing)
    if not text:
        return "err:empty-after-norm"

    # Coqui Synthesizer.tts() returns a numpy waveform; save_wav writes it.
    tmp_wav = out_path.with_suffix(".wav")
    try:
        wav = synth.tts(text)
        synth.save_wav(wav, str(tmp_wav))
    except Exception as e:
        return f"err:synth:{e}"

    if not tmp_wav.exists() or tmp_wav.stat().st_size < 500:
        return "err:empty-wav"

    # Encode to MP3
    try:
        subprocess.run(
            ["ffmpeg", "-y", "-loglevel", "error",
             "-i", str(tmp_wav),
             "-codec:a", "libmp3lame", "-b:a", "64k", "-ar", "22050", "-ac", "1",
             str(out_path)],
            check=True, capture_output=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        return f"err:ffmpeg:{e}"
    finally:
        try:
            tmp_wav.unlink()
        except FileNotFoundError:
            pass

    return "ok" if out_path.exists() and out_path.stat().st_size > 500 else "err:no-output"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--force", action="store_true",
                    help="Overwrite existing MP3s (default: skip existing)")
    ap.add_argument("--limit", type=int, default=0,
                    help="Stop after N words (for testing; 0 = no limit)")
    args = ap.parse_args()

    # Verify model exists
    if not MODEL_PTH.exists():
        print(f"ERROR: {MODEL_PTH} not found.")
        print("  Download awing_vits_voice.pth + .json from RunPod first.")
        return 1
    if not MODEL_JSON.exists():
        print(f"ERROR: {MODEL_JSON} not found.")
        print("  Download awing_vits_voice.json from RunPod first.")
        return 1

    print("=" * 70)
    print(" Awing TTS — synthesizing vocab clips from trained Bible model")
    print("=" * 70)
    print(f"  Model:  {MODEL_PTH}")
    print(f"  Config: {MODEL_JSON}")
    print(f"  Output: {OUT_ROOT}")
    print()

    print("Loading Coqui VITS voice...")
    voice = init_synthesizer()
    print("  ✓ loaded")

    print("Loading vocabulary...")
    vocab = load_vocab()
    if args.limit:
        vocab = vocab[: args.limit]
    print(f"  → {len(vocab):,} words to synthesize")
    print()

    stats = {"ok": 0, "skip": 0, "err": 0}
    err_samples = []
    t0 = time.time()

    for i, (awing, english, category) in enumerate(vocab, 1):
        subdir = CATEGORY_DIRS.get(category, "vocabulary")
        out_dir = OUT_ROOT / subdir
        out_dir.mkdir(parents=True, exist_ok=True)
        out_path = out_dir / f"{audio_key(awing)}.mp3"

        result = synthesize_one(voice, awing, out_path, args.force)
        if result == "ok":
            stats["ok"] += 1
        elif result == "skip":
            stats["skip"] += 1
        else:
            stats["err"] += 1
            if len(err_samples) < 10:
                err_samples.append((awing, result))

        if i % 100 == 0:
            elapsed = time.time() - t0
            rate = i / elapsed
            eta_min = (len(vocab) - i) / rate / 60
            print(f"  [{i:>6,}/{len(vocab):,}] "
                  f"ok={stats['ok']:,} skip={stats['skip']:,} err={stats['err']:,} "
                  f"({rate:.1f}/s, ETA {eta_min:.0f}min)")

    elapsed = time.time() - t0
    print()
    print("=" * 70)
    print(f"  Synthesized: {stats['ok']:,}")
    print(f"  Skipped:     {stats['skip']:,} (already existed)")
    print(f"  Errors:      {stats['err']:,}")
    print(f"  Wall time:   {elapsed / 60:.1f} min")
    if err_samples:
        print()
        print("  First 10 errors:")
        for w, r in err_samples:
            print(f"    {w!r}: {r}")
    print()
    print(f"  Output: {OUT_ROOT}")
    print(f"  Next: run pack_and_upload_assets.sh to push the new PAD")
    return 0


if __name__ == "__main__":
    sys.exit(main())
