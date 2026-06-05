#!/usr/bin/env python3
"""learn_speakable_from_natives.py — Mine Awing→Swahili phonetic patterns
from your existing native recordings using Whisper-Swahili.

Runs LOCALLY on Windows/Linux. Uses your existing CUDA GPU.

DESIGN PRINCIPLE (per user directive):
  The 423 recorded words ALREADY play their native audio at runtime
  (priority 0 in pronunciation_service.dart). We do NOT write per-word
  overrides for them. Instead, the 423 (awing_word, whisper_swahili)
  pairs are TRAINING DATA used to mine generalized rules that improve
  `awing_to_speakable()` for the ~7,000 OTHER words that don't have
  native recordings.

What it does:
  1. Finds every native recording (Dr. Sama + family + remote contributors)
     in android/install_time_assets/.../audio/native/
  2. Reverse-maps each filename back to its Awing word
  3. Whisper-transcribes each clip in Swahili
  4. For each (awing_word, whisper_swahili) pair, compares to what
     `awing_to_speakable()` would produce TODAY
  5. Frequency-analyzes which grapheme substitutions disagree most often
     → these are candidates for upgrading `awing_to_speakable()`
  6. For each candidate rule, COUNTS how many of the ~7,000 unrecorded
     words it would actually affect (so you can prioritize high-impact
     rule changes)

Outputs (ALL diagnostic — none get applied automatically):
  contributions/native_whisper_transcriptions.json — full transcript data
  contributions/speakable_rule_proposals.txt       — human-readable report
                                                     with impact counts on
                                                     unrecorded words

You manually decide which rule changes to promote into
`scripts/generate_audio_edge.py awing_to_speakable()`. Then regenerate
ONLY the words that lack native audio.

Usage:
  python scripts/learn_speakable_from_natives.py
  python scripts/learn_speakable_from_natives.py --limit 50  # test first
  python scripts/learn_speakable_from_natives.py --model small  # faster
  python scripts/learn_speakable_from_natives.py --analyze-only
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from collections import Counter
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
VOCAB_FILE = REPO / "lib" / "data" / "awing_vocabulary.dart"

# Native recording locations (PAD pack + legacy)
NATIVE_ROOTS = [
    REPO / "android" / "install_time_assets" / "src" / "main" / "assets" / "audio" / "native",
    REPO / "assets" / "audio" / "native",
]

OUT_DIR = REPO / "contributions"
TRANSCRIPTIONS_JSON = OUT_DIR / "native_whisper_transcriptions.json"
PROPOSALS_FILE = OUT_DIR / "speakable_rule_proposals.txt"
# Per user directive: we do NOT write to regenerate_words.json.
# Recorded words play their native audio. The Whisper data is used as
# training material to improve rules for unrecorded words only.


# ===== filename ↔ Awing helpers (must match generate_audio_edge.py) =====

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


def awing_to_speakable(text: str) -> str:
    """Current production rules (mirrors generate_audio_edge.py)."""
    s = unicodedata.normalize("NFD", text)
    s = "".join(c for c in s if not unicodedata.combining(c))
    s = s.replace("ŋg", "ngg").replace("ŋk", "nk")
    s = s.replace("ŋ", "ng").replace("Ŋ", "Ng")
    s = s.replace("ɛ", "e").replace("Ɛ", "E")
    s = s.replace("ɔ", "o").replace("Ɔ", "O")
    s = s.replace("ə", "e").replace("Ə", "E")
    s = s.replace("ɨ", "i").replace("Ɨ", "I")
    s = s.replace("ɣ", "g").replace("Ɣ", "G")
    s = s.replace("gh", "g").replace("Gh", "G")
    s = s.replace("'", "").replace("ʼ", "").replace("’", "").replace("‘", "")
    return s.lower()


def load_vocab() -> list[tuple[str, str]]:
    """Returns [(awing, audio_key)] for every uncommented AwingWord literal."""
    sq = r"'((?:\\.|[^'\\])*)'"
    dq = r'"((?:\\.|[^"\\])*)"'
    s = rf"(?:{sq}|{dq})"
    pat = re.compile(rf"AwingWord\(\s*awing:\s*{s}", re.DOTALL)
    content = VOCAB_FILE.read_text(encoding="utf-8")
    out = []
    seen_keys = set()
    for m in pat.finditer(content):
        line_start = content.rfind("\n", 0, m.start()) + 1
        if "//" in content[line_start : m.start()]:
            continue
        awing = (m.group(1) or m.group(2) or "").replace("\\'", "'")
        if not awing:
            continue
        key = audio_key(awing)
        # First occurrence wins for homonym handling
        if key in seen_keys:
            continue
        seen_keys.add(key)
        out.append((awing, key))
    return out


def find_native_recordings() -> list[Path]:
    """Discover every native audio file under known PAD/legacy roots."""
    found = []
    for root in NATIVE_ROOTS:
        if not root.exists():
            continue
        for ext in ("*.opus", "*.mp3", "*.m4a", "*.wav"):
            found.extend(root.rglob(ext))
    return found


# ===== Whisper transcription =====


def transcribe_clips(clips_to_process, model_name: str) -> dict:
    """Returns {audio_key: {'whisper_sw': ..., 'file': ...}}. Loads model lazily."""
    try:
        import whisper
        import torch
    except ImportError:
        print("\n✗ openai-whisper not installed. Install with:")
        print("    pip install openai-whisper")
        sys.exit(1)

    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"  Loading Whisper {model_name!r} on {device}...")
    model = whisper.load_model(model_name, device=device)
    print("  ✓ loaded")

    results = {}
    for i, (path, key, awing) in enumerate(clips_to_process, 1):
        try:
            r = model.transcribe(
                str(path),
                language="sw",
                fp16=(device == "cuda"),
                verbose=False,
                no_speech_threshold=0.4,
            )
            text = (r.get("text") or "").strip().lower()
            results[key] = {
                "awing": awing,
                "whisper_sw": text,
                "current_speakable": awing_to_speakable(awing),
                "file": str(path.relative_to(REPO)).replace("\\", "/"),
            }
        except Exception as e:
            print(f"    ✗ {key}: {e}")
            continue
        if i % 20 == 0 or i == len(clips_to_process):
            print(f"  [{i:>4}/{len(clips_to_process)}] {key:25s} → {text!r}")
    return results


# ===== Pattern analysis =====


def analyze_disagreements(transcriptions: dict) -> tuple[list, Counter, Counter]:
    """Returns (per_word_overrides, char_substitution_counter, full_subst_counter)."""
    overrides = []
    char_subs = Counter()
    full_subs = Counter()

    for key, data in transcriptions.items():
        awing = data["awing"]
        whisper_sw = data["whisper_sw"]
        current = data["current_speakable"]
        if not whisper_sw:
            continue
        if whisper_sw == current:
            continue
        overrides.append({
            "awing": awing,
            "current": current,
            "whisper": whisper_sw,
        })
        # Track full-string substitutions
        full_subs[(current, whisper_sw)] += 1
        # Track per-character substitution at a very rough level — align by
        # zipping (lossy but informative for high-frequency single-char swaps)
        for a, b in zip(current, whisper_sw):
            if a != b:
                char_subs[(a, b)] += 1
    return overrides, char_subs, full_subs


# ===== Main =====


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--limit", type=int, default=0,
                    help="Stop after N clips (for testing)")
    ap.add_argument("--force", action="store_true",
                    help="Re-transcribe even if already in cache")
    ap.add_argument("--model", default="medium",
                    choices=["tiny", "base", "small", "medium", "large"],
                    help="Whisper model (medium is a good balance; small is 2x faster)")
    ap.add_argument("--analyze-only", action="store_true",
                    help="Skip transcription, just re-run analysis on cached data")
    args = ap.parse_args()

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    # 1. Survey vocab + native files
    print("Loading vocabulary...")
    vocab = load_vocab()
    key_to_awing = {key: awing for awing, key in vocab}
    print(f"  {len(key_to_awing):,} unique vocabulary entries")

    print("Discovering native recordings...")
    files = find_native_recordings()
    print(f"  Found {len(files):,} audio files in:")
    for r in NATIVE_ROOTS:
        if r.exists():
            print(f"    {r.relative_to(REPO)}")

    # 2. Filter to clips that match vocab
    mapped = []
    unmatched = 0
    for path in files:
        key = path.stem
        if key in key_to_awing:
            mapped.append((path, key, key_to_awing[key]))
        else:
            unmatched += 1
    print(f"  {len(mapped):,} clips map to vocab entries ({unmatched} unmatched)")

    if not mapped and not args.analyze_only:
        print("\n✗ Nothing to transcribe — check that native recordings exist.")
        return 1

    # 3. Load existing transcriptions (resume support)
    existing = {}
    if TRANSCRIPTIONS_JSON.exists() and not args.force:
        try:
            existing = json.loads(TRANSCRIPTIONS_JSON.read_text(encoding="utf-8"))
            print(f"  Cached: {len(existing):,} clips already transcribed")
        except Exception:
            existing = {}

    if not args.analyze_only:
        # 4. Transcribe new clips
        to_process = [t for t in mapped if t[1] not in existing or args.force]
        print(f"  → {len(to_process):,} new clips to transcribe")
        if args.limit:
            to_process = to_process[: args.limit]
            print(f"  → limited to {args.limit}")

        if to_process:
            new_results = transcribe_clips(to_process, args.model)
            existing.update(new_results)
            TRANSCRIPTIONS_JSON.write_text(
                json.dumps(existing, ensure_ascii=False, indent=2),
                encoding="utf-8",
            )
            print(f"  ✓ Saved {len(existing):,} transcriptions to {TRANSCRIPTIONS_JSON.relative_to(REPO)}")

    if not existing:
        print("\nNo transcriptions to analyze.")
        return 0

    # 5. Analyze disagreements (training-data analysis only — no app override)
    print("\n" + "=" * 70)
    print(" ANALYSIS: current awing_to_speakable() vs Whisper-Swahili")
    print("=" * 70)
    disagreements, char_subs, full_subs = analyze_disagreements(existing)
    print(f"  {len(disagreements):,} of {len(existing):,} clips disagree with current rules "
          f"({100*len(disagreements)/len(existing):.1f}%)")

    # 6. Identify the set of UNRECORDED words (~7,000) where rule changes
    # would actually be applied at synthesis time. This lets us count how
    # impactful each proposed rule change would be.
    recorded_keys = set(existing.keys())
    unrecorded = [(awing, key) for awing, key in vocab if key not in recorded_keys]
    print(f"  Unrecorded vocab (would benefit from rule changes): {len(unrecorded):,}")

    # 7. For each candidate character substitution rule, count how many
    # unrecorded words contain the LHS character — that's the upper bound
    # of how many words the rule would change.
    rule_impact = {}
    for (a, b), count_in_natives in char_subs.most_common():
        if count_in_natives < 2:
            continue
        # Search the unrecorded set for occurrences of `a` in the current
        # awing_to_speakable() output (which is what the rule operates on)
        affected = sum(1 for awing, _ in unrecorded if a in awing_to_speakable(awing))
        rule_impact[(a, b)] = {
            "natives_supporting": count_in_natives,
            "unrecorded_affected": affected,
        }

    # 8. Write human-readable proposals report
    lines = []
    lines.append("Awing → Swahili phonetic learning report")
    lines.append("=" * 70)
    lines.append(f"Source:  {len(existing):,} native recordings via Whisper-{args.model}")
    lines.append(f"Recorded vocab (already play native audio):  {len(recorded_keys):,}")
    lines.append(f"Unrecorded vocab (would benefit from rules): {len(unrecorded):,}")
    lines.append(f"Native clips disagreeing with current rules: {len(disagreements):,}")
    lines.append("")
    lines.append("PROPOSED RULE CHANGES TO awing_to_speakable()")
    lines.append("Ranked by impact: how many unrecorded words each would affect")
    lines.append("-" * 70)
    lines.append(f"  {'Current':>10} → {'Whisper':>10}  {'NativeEvidence':>15} {'UnrecordedAffected':>20}")
    sorted_rules = sorted(
        rule_impact.items(),
        key=lambda kv: kv[1]["unrecorded_affected"],
        reverse=True,
    )
    for (a, b), stats in sorted_rules[:40]:
        lines.append(
            f"  {a!r:>10} → {b!r:>10}  {stats['natives_supporting']:>15} {stats['unrecorded_affected']:>20}"
        )
    lines.append("")
    lines.append("DIAGNOSTIC: per-word disagreements (informational only)")
    lines.append("These words ARE played from native audio at runtime; this list")
    lines.append("shows where Whisper's transcription differs from current rules.")
    lines.append("-" * 70)
    lines.append(f"  {'Awing':<25} {'Current':<20} → {'Whisper'}")
    for o in disagreements[:50]:
        lines.append(f"  {o['awing']:<25} {o['current']:<20} → {o['whisper']}")
    lines.append("")
    lines.append("HOW TO APPLY (manual)")
    lines.append("-" * 70)
    lines.append("1. Review the PROPOSED RULE CHANGES table above. A high-impact")
    lines.append("   row (e.g. 'ə' → 'a' with 2000 unrecorded_affected) means")
    lines.append("   updating one line of scripts/generate_audio_edge.py would")
    lines.append("   change ~2000 unrecorded words' Edge TTS output.")
    lines.append("")
    lines.append("2. Edit scripts/generate_audio_edge.py awing_to_speakable() to")
    lines.append("   incorporate the high-impact rules.")
    lines.append("")
    lines.append("3. Regenerate ONLY unrecorded words:")
    lines.append("   python scripts/generate_audio_edge.py generate")
    lines.append("   (the regenerate command's existing behaviour: native-recorded")
    lines.append("   words are skipped because the runtime fallback already plays")
    lines.append("   the native clip — Edge TTS output for those words is unused)")
    lines.append("")
    lines.append("4. No file in the app code is modified by this script. Recorded")
    lines.append("   words remain untouched.")
    PROPOSALS_FILE.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"  ✓ Wrote rule proposals to {PROPOSALS_FILE.relative_to(REPO)}")

    # 9. Show top 15 on stdout for instant review
    print("\n  Top 15 rule-change candidates (by unrecorded words affected):")
    print(f"    {'Current':>10} → {'Whisper':>10}  {'Evidence':>9} {'Affects':>9}")
    for (a, b), stats in sorted_rules[:15]:
        print(
            f"    {a!r:>10} → {b!r:>10}  {stats['natives_supporting']:>9} {stats['unrecorded_affected']:>9}"
        )

    print("\nDone. Review", PROPOSALS_FILE.relative_to(REPO), "and decide which")
    print("rules to promote into awing_to_speakable() in generate_audio_edge.py.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
