#!/usr/bin/env python3
"""test_schwa_rule.py — A/B listen-test the word-final ə → a rule.

Picks ~50 UNRECORDED Awing vocab words ending in ə (the ones the new
rule would actually change) and produces two clips per word:
  BEFORE_<key>.mp3  — old rule (ə → e everywhere)
  AFTER_<key>.mp3   — new rule (word-final ə → a, mid-word ə → e)

Output: scripts/_schwa_test/
You listen, judge if AFTER consistently sounds more natural than
BEFORE, and decide to keep or revert the rule change in
generate_audio_edge.py.

Usage:
  python scripts/test_schwa_rule.py
  python scripts/test_schwa_rule.py --count 30        # fewer clips
  python scripts/test_schwa_rule.py --voice young_man # different voice
"""
from __future__ import annotations

import argparse
import asyncio
import random
import re
import sys
import unicodedata
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
VOCAB_FILE = REPO / "lib" / "data" / "awing_vocabulary.dart"
OUT_DIR = REPO / "scripts" / "_schwa_test"

# Audio key (must match generate_audio_edge.py / pronunciation_service)
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


# Native recording locations
NATIVE_ROOTS = [
    REPO / "android" / "install_time_assets" / "src" / "main" / "assets" / "audio" / "native",
    REPO / "assets" / "audio" / "native",
]


def find_recorded_keys() -> set[str]:
    keys = set()
    for root in NATIVE_ROOTS:
        if not root.exists():
            continue
        for ext in ("*.opus", "*.mp3", "*.m4a", "*.wav"):
            for path in root.rglob(ext):
                keys.add(path.stem)
    return keys


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


# OLD rule: ə → e everywhere
def speakable_OLD(text: str) -> str:
    text = unicodedata.normalize("NFC", text)
    cleaned = []
    for ch in text:
        decomp = unicodedata.normalize("NFD", ch)
        kept = "".join(c for c in decomp if not unicodedata.category(c).startswith("M"))
        cleaned.append(unicodedata.normalize("NFC", kept))
    text = "".join(cleaned)
    text = text.replace("ŋg", "ngg").replace("Ŋg", "Ngg")
    text = text.replace("ŋk", "nk").replace("Ŋk", "Nk")
    for old, new in [
        ("Ɛ", "E"), ("ɛ", "e"), ("Ɔ", "O"), ("ɔ", "o"),
        ("Ə", "E"), ("ə", "e"), ("Ɨ", "I"), ("ɨ", "i"),
        ("Ŋ", "Ng"), ("ŋ", "ng"), ("ɣ", "gh"),
        ("ʼ", ""), ("’", ""), ("‘", ""), ("'", ""),
    ]:
        text = text.replace(old, new)
    return re.sub(r"\s+", " ", text).strip()


# NEW rule: word-final ə → a, else ə → e
def speakable_NEW(text: str) -> str:
    text = unicodedata.normalize("NFC", text)
    cleaned = []
    for ch in text:
        decomp = unicodedata.normalize("NFD", ch)
        kept = "".join(c for c in decomp if not unicodedata.category(c).startswith("M"))
        cleaned.append(unicodedata.normalize("NFC", kept))
    text = "".join(cleaned)
    text = text.replace("ŋg", "ngg").replace("Ŋg", "Ngg")
    text = text.replace("ŋk", "nk").replace("Ŋk", "Nk")
    # NEW: word-final ə → a
    text = re.sub(r"ə(?=$|[\s.,!?;:\"\-])", "a", text)
    text = re.sub(r"Ə(?=$|[\s.,!?;:\"\-])", "A", text)
    for old, new in [
        ("Ɛ", "E"), ("ɛ", "e"), ("Ɔ", "O"), ("ɔ", "o"),
        ("Ə", "E"), ("ə", "e"), ("Ɨ", "I"), ("ɨ", "i"),
        ("Ŋ", "Ng"), ("ŋ", "ng"), ("ɣ", "gh"),
        ("ʼ", ""), ("’", ""), ("‘", ""), ("'", ""),
    ]:
        text = text.replace(old, new)
    return re.sub(r"\s+", " ", text).strip()


async def synthesize_one(text: str, voice: str, out_path: Path) -> bool:
    """Single Edge TTS call, returns success."""
    try:
        import edge_tts
    except ImportError:
        print("✗ edge-tts not installed: pip install edge-tts")
        return False
    voice_map = {
        "boy":          "sw-KE-RafikiNeural",
        "girl":         "sw-KE-ZuriNeural",
        "young_man":    "sw-TZ-DaudiNeural",
        "young_woman":  "sw-TZ-RehemaNeural",
        "man":          "sw-TZ-DaudiNeural",
        "woman":        "sw-TZ-RehemaNeural",
    }
    edge_voice = voice_map.get(voice, voice_map["young_man"])
    try:
        comm = edge_tts.Communicate(text, edge_voice, rate="-15%")
        await comm.save(str(out_path))
        return out_path.exists() and out_path.stat().st_size > 1000
    except Exception as e:
        print(f"  ✗ {text!r}: {e}")
        return False


async def main_async(words: list[str], voice: str) -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    # Clear old test files
    for f in OUT_DIR.glob("*.mp3"):
        f.unlink()

    ok = 0
    print(f"\nSynthesizing {len(words)} word pairs with voice={voice!r}...\n")
    print(f"  {'Awing':<20} {'BEFORE (ə→e)':<20} {'AFTER (ə-final→a)'}")
    print(f"  {'-'*20} {'-'*20} {'-'*20}")
    for i, awing in enumerate(words, 1):
        old_text = speakable_OLD(awing)
        new_text = speakable_NEW(awing)
        if old_text == new_text:
            # Rule didn't actually trigger for this word — skip
            continue
        key = audio_key(awing)
        before_path = OUT_DIR / f"BEFORE_{key}.mp3"
        after_path = OUT_DIR / f"AFTER_{key}.mp3"

        success_before = await synthesize_one(old_text, voice, before_path)
        success_after = await synthesize_one(new_text, voice, after_path)
        if success_before and success_after:
            ok += 1
            print(f"  {awing:<20} {old_text:<20} {new_text}")
    print(f"\n  ✓ Created {ok} A/B pairs in {OUT_DIR}")
    return 0 if ok > 0 else 1


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--count", type=int, default=50)
    ap.add_argument("--voice", default="young_man",
                    choices=["boy", "girl", "young_man", "young_woman", "man", "woman"])
    ap.add_argument("--seed", type=int, default=42)
    args = ap.parse_args()

    print("Loading vocabulary...")
    vocab = load_vocab()
    print(f"  {len(vocab):,} entries")

    print("Finding recorded words to exclude...")
    recorded = find_recorded_keys()
    print(f"  {len(recorded):,} recorded keys")

    # Filter: word ends in ə (or Ə), and NOT in recorded set
    candidates = [
        w for w in vocab
        if (w.endswith("ə") or w.endswith("Ə"))
        and audio_key(w) not in recorded
    ]
    print(f"  {len(candidates):,} unrecorded words ending in ə")

    if not candidates:
        print("✗ No candidates — every ə-ending word is already recorded.")
        return 1

    random.seed(args.seed)
    random.shuffle(candidates)
    chosen = candidates[: args.count]
    print(f"\n  Will A/B test {len(chosen)} of them.")

    return asyncio.run(main_async(chosen, args.voice))


if __name__ == "__main__":
    sys.exit(main())
