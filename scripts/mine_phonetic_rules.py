#!/usr/bin/env python3
"""mine_phonetic_rules.py -- learn TTS-correction rules from native recordings.

The Edge TTS pipeline maps each Awing word through `awing_to_speakable()`
to a Swahili-phonetic spelling, then sends that to Microsoft's Swahili
neural voice. Some words come out wrong because the default mapping
rules (ɛ → e, ŋ → ng, etc.) miss subtler patterns the Swahili TTS needs.

This script:
  1. Walks every native recording in training_data/recordings/
  2. Runs Whisper-Swahili ASR on it to get what Swahili-speaking ears
     hear (the GROUND TRUTH for what Edge TTS should produce).
  3. Computes what `awing_to_speakable()` produces for the same Awing
     word (the CURRENT default).
  4. Diffs the two strings character-by-character.
  5. Aggregates consistent character-level substitutions.
  6. Writes a candidates report grouped by confidence so Dr. Sama can
     decide which rules to ship into awing_to_speakable().

Idempotent. Re-runs any time you add new recordings. Safe -- does NOT
modify generate_audio_edge.py.

Outputs:
  contributions/phonetic_rules_candidates.csv -- full per-recording diff
  contributions/phonetic_rules_report.md      -- human-readable summary
                                                  + suggested code

Run:
  python scripts/mine_phonetic_rules.py
  python scripts/mine_phonetic_rules.py --min-occurrences 5
"""
from __future__ import annotations
import argparse
import csv
import json
import os
import sys
from collections import Counter, defaultdict
from difflib import SequenceMatcher
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
RECORDINGS_DIR = REPO / "training_data" / "recordings"
MANIFEST = RECORDINGS_DIR / "manifest.json"
# Bible NT forced-aligned corpus (Session 56 -- 7,410 train + 364 eval
# verse-level clips). metadata.csv has "USFM|awing_text" rows, audio
# lives in {split}/wav/{usfm}.wav. License: CABTAL upstream, audio is
# TRAINING SIGNAL ONLY; we mine the speakable-rule deltas from these
# pairs but the audio itself is never bundled in the APK or
# regenerated for the app.
BIBLE_CORPUS_DIR = REPO / "corpus" / "aligned" / "piper"
BIBLE_TRAIN_META = BIBLE_CORPUS_DIR / "train" / "metadata.csv"
BIBLE_EVAL_META  = BIBLE_CORPUS_DIR / "eval"  / "metadata.csv"
OUT_DIR = REPO / "contributions"
OUT_CSV = OUT_DIR / "phonetic_rules_candidates.csv"
OUT_MD = OUT_DIR / "phonetic_rules_report.md"

# Confidence-band thresholds for the report
HIGH_CONFIDENCE = 0.70   # rule fires on 70%+ of words with that grapheme
MED_CONFIDENCE = 0.40


def _ensure_venv():
    """Re-exec inside ~/awing_venv (Linux) or venv (Windows) if not in one."""
    if sys.prefix != sys.base_prefix:
        return  # already in a venv
    # Try both common venv paths
    candidates = [
        REPO / "venv" / "Scripts" / "python.exe",
        REPO / "venv" / "bin" / "python",
        Path.home() / "awing_venv" / "bin" / "python",
    ]
    for py in candidates:
        if py.exists():
            os.execv(str(py), [str(py)] + sys.argv)
    print("WARNING: not running inside a venv. Whisper may not be available.")


def _load_awing_to_speakable():
    """Pull the live awing_to_speakable() from generate_audio_edge.py so
    rules we mine apply against the SAME default behavior the production
    TTS path uses. Avoids drift."""
    import importlib.util
    edge_path = REPO / "scripts" / "generate_audio_edge.py"
    if not edge_path.exists():
        raise SystemExit(f"Missing {edge_path}")
    spec = importlib.util.spec_from_file_location("generate_audio_edge", edge_path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    if not hasattr(mod, "awing_to_speakable"):
        raise SystemExit("generate_audio_edge.py has no awing_to_speakable()")
    return mod.awing_to_speakable


def _load_manifest():
    """training_data/recordings/manifest.json maps filename -> Awing text."""
    if not MANIFEST.exists():
        raise SystemExit(f"Missing manifest: {MANIFEST}")
    data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    # Manifest format varies across sessions; normalize.
    entries = []
    if isinstance(data, dict) and "recordings" in data:
        data = data["recordings"]
    if isinstance(data, list):
        for r in data:
            fn = (r.get("wav_path") or r.get("filename")
                  or r.get("path") or r.get("file"))
            awing = r.get("awing") or r.get("text") or r.get("word")
            if fn and awing:
                entries.append((fn, awing))
    elif isinstance(data, dict):
        for fn, awing in data.items():
            if isinstance(awing, dict):
                awing = awing.get("awing") or awing.get("text")
            if fn and awing:
                entries.append((fn, awing))
    return entries


def _load_bible_entries(splits=("train", "eval"), max_chars_per_verse: int = 200):
    """Load (wav_path, awing_text) pairs from the forced-aligned Bible NT
    corpus produced by scripts/ml/forced_align.py (Session 56).

    Each metadata.csv row is `USFM|awing_text`; audio lives in
    {split}/wav/{usfm}.wav. Verses longer than `max_chars_per_verse`
    are dropped -- Whisper-Swahili's transcription quality degrades on
    long clips and the diff routine generates more noise than signal.
    """
    entries = []
    for split in splits:
        meta = BIBLE_CORPUS_DIR / split / "metadata.csv"
        if not meta.exists():
            print(f"  [bible] {split} metadata.csv not found at {meta.relative_to(REPO)} -- skipping")
            continue
        wav_root = BIBLE_CORPUS_DIR / split / "wav"
        with open(meta, "r", encoding="utf-8") as f:
            for line in f:
                line = line.rstrip("\n")
                if not line or "|" not in line:
                    continue
                usfm, text = line.split("|", 1)
                text = text.strip()
                if not text or len(text) > max_chars_per_verse:
                    continue
                wav = wav_root / f"{usfm}.wav"
                if not wav.exists():
                    continue
                # Return RELATIVE path string so the main loop's
                # "audio = path-from-record OR REPO/path" branch works.
                entries.append((str(wav.relative_to(REPO)), text))
        print(f"  [bible] loaded {len(entries)} pairs so far (after {split})")
    return entries


def _whisper_transcribe(model, audio_path: Path) -> str:
    """Run Whisper-Swahili ASR on an audio file. Returns lowercase
    transcription stripped of punctuation."""
    try:
        result = model.transcribe(str(audio_path), language="sw", fp16=False)
        text = result.get("text", "").strip().lower()
        # Strip basic punctuation
        for ch in ',.!?;:"-':
            text = text.replace(ch, "")
        return text.strip()
    except Exception as e:
        print(f"  whisper error on {audio_path.name}: {e}")
        return ""


def _diff_pairs(default: str, native: str):
    """Compute CONTEXTUALIZED substitution pairs from default -> native.

    Returns (default_substr, native_substr) pairs that are SAFE to use
    as global string-replace rules:

      - Both sides MUST be non-empty (avoids `''.replace("", "x")` which
        would insert "x" between every character).
      - For each `replace` opcode, we extend ONE character of left
        context on both sides so the rule fires in the right place.
        Example: default "yi" vs native "yi+h" -> opcode insert at
        position 2 -> we widen to ("yi", "yih") so the rule is
        `"yi" -> "yih"`, not the meaningless `"" -> "h"`.
      - Drop pairs where >40% of either side differs from the other
        (likely Whisper hallucinations, not real phonetic substitutions).
    """
    pairs = []
    sm = SequenceMatcher(None, default, native, autojunk=False)
    for op, i1, i2, j1, j2 in sm.get_opcodes():
        if op == "equal":
            continue
        d_chunk = default[i1:i2]
        n_chunk = native[j1:j2]

        # Skip very long mismatches (likely Whisper hallucinations)
        if len(d_chunk) > 6 or len(n_chunk) > 6:
            continue

        # Widen with left-context for pure insertions/deletions so the
        # rule is anchored. Refuse to emit empty-side pairs.
        if not d_chunk or not n_chunk:
            # Extend left context by 1 char if available on BOTH sides
            if i1 > 0 and j1 > 0 and default[i1 - 1] == native[j1 - 1]:
                ctx = default[i1 - 1]
                d_chunk = ctx + d_chunk
                n_chunk = ctx + n_chunk
            else:
                continue  # skip un-anchorable empty-side pair
        if not d_chunk or not n_chunk:
            continue
        if d_chunk == n_chunk:
            continue

        pairs.append((d_chunk, n_chunk))
    return pairs


def _patch_awing_to_speakable(high_rules):
    """Append high-confidence rules to awing_to_speakable() inside
    scripts/generate_audio_edge.py. Wrapped in a marker block so we
    can locate and remove them later without hand-editing."""
    import shutil
    import datetime
    edge_path = REPO / "scripts" / "generate_audio_edge.py"
    src = edge_path.read_text(encoding="utf-8")

    MARK_START = "    # ---- BEGIN auto-mined phonetic rules ----"
    MARK_END = "    # ---- END auto-mined phonetic rules ----"

    # Remove any prior auto-mined block (re-runs are idempotent)
    import re
    src = re.sub(
        rf"{re.escape(MARK_START)}.*?{re.escape(MARK_END)}\n",
        "",
        src,
        flags=re.DOTALL,
    )

    # Build the new block
    lines = [MARK_START,
             "    # Auto-generated by mine_phonetic_rules.py from native",
             "    # recordings. Each rule fired on >=70% of words "
             "containing the source",
             "    # grapheme. Remove a rule by deleting its .replace() "
             "line; restore",
             "    # original behavior by deleting this whole block.",
             ]
    for c in high_rules:
        d, n = c["default"], c["native"]
        # Skip empty/whitespace rules
        if not d.strip() and not n.strip():
            continue
        if d == n:
            continue
        lines.append(
            f"    s = s.replace({d!r}, {n!r})"
            f"  # mined: {c['occurrences']} words, "
            f"{c['confidence']:.0%} confidence"
        )
    lines.append(MARK_END)
    new_block = "\n".join(lines) + "\n"

    # Insert before the function's final `return s`. We assume the
    # function ends with `return s` (current code does).
    if "def awing_to_speakable" not in src:
        raise SystemExit("Cannot find awing_to_speakable in generate_audio_edge.py")
    func_start = src.index("def awing_to_speakable")
    func_end = src.index("\ndef ", func_start + 1) if "\ndef " in src[func_start + 1:] else len(src)
    func_body = src[func_start:func_end]
    if "return s" not in func_body:
        raise SystemExit("awing_to_speakable() doesn't end with `return s`")
    last_return = func_body.rfind("return s")
    insert_at = func_start + last_return
    # Find the start of that line
    line_start = src.rfind("\n", 0, insert_at) + 1
    new_src = src[:line_start] + new_block + src[line_start:]

    # Back up before writing
    stamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    bak = edge_path.with_suffix(f".py.bak_mine_{stamp}")
    shutil.copy2(edge_path, bak)
    edge_path.write_text(new_src, encoding="utf-8")
    raw = edge_path.read_bytes().rstrip(b"\x00 \t\r\n") + b"\n"
    edge_path.write_bytes(raw)
    return bak


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--source", choices=("recordings", "bible", "all"),
                    default="recordings",
                    help="Which audio pool to mine. "
                         "'recordings' = Dr. Sama's WAVs (default, ~369 entries). "
                         "'bible' = Bible NT forced-aligned verses (~7,400 entries, ~14 hrs audio). "
                         "'all' = both pools combined.")
    ap.add_argument("--min-occurrences", type=int, default=3,
                    help="Minimum word count a rule must apply to before "
                         "it's reported (default 3 for recordings, "
                         "auto-bumped to 10 if source includes Bible).")
    ap.add_argument("--limit", type=int, default=0,
                    help="Process only the first N entries (for testing). "
                         "Useful with --source bible to estimate runtime "
                         "before a full pass.")
    ap.add_argument("--max-rule-length", type=int, default=6,
                    help="Drop rule candidates whose default or native "
                         "substring is longer than this many chars. "
                         "Longer rules tend to span word boundaries and "
                         "produce noise on multi-word Bible verses "
                         "(default 6).")
    ap.add_argument("--auto-apply", action="store_true",
                    help="Auto-patch generate_audio_edge.py with the "
                         "high-confidence (>=70%) rules.")
    args = ap.parse_args()

    # If source includes Bible, bump min-occurrences default to filter
    # the much-noisier verse-level rule candidates.
    if args.source in ("bible", "all") and args.min_occurrences == 3:
        args.min_occurrences = 10
        print("Source includes Bible NT -- bumping --min-occurrences to 10 "
              "(reduce verse-level rule noise).")

    _ensure_venv()

    # Lazy whisper import after venv re-exec
    try:
        import whisper  # type: ignore
    except ImportError:
        raise SystemExit(
            "openai-whisper not installed in this venv. Install with:\n"
            "  venv\\Scripts\\pip install openai-whisper")

    awing_to_speakable = _load_awing_to_speakable()

    entries = []
    if args.source in ("recordings", "all"):
        rec_entries = _load_manifest()
        print(f"Found {len(rec_entries)} recordings in manifest.")
        entries.extend(rec_entries)
    if args.source in ("bible", "all"):
        bible_entries = _load_bible_entries()
        print(f"Found {len(bible_entries)} Bible verse pairs.")
        entries.extend(bible_entries)

    if args.limit:
        entries = entries[:args.limit]
    print(f"Total entries to process: {len(entries)}")
    if not entries:
        return 1

    print("Loading Whisper 'medium' model (first run downloads ~1.5 GB)...")
    model = whisper.load_model("medium")

    # Per-recording rows: (awing, default, native, pairs)
    rows = []
    # Aggregated rules: (default_chunk, native_chunk) -> list of awing words
    rule_examples: dict = defaultdict(list)

    for i, (fn, awing) in enumerate(entries, 1):
        audio = RECORDINGS_DIR / fn
        if not audio.exists():
            # Manifest paths might be relative to repo or absolute
            audio = REPO / fn
        if not audio.exists():
            print(f"  [{i}/{len(entries)}] {awing}: SKIP (missing audio)")
            continue
        default = awing_to_speakable(awing).lower()
        native = _whisper_transcribe(model, audio)
        if not native:
            continue
        pairs = _diff_pairs(default, native)
        rows.append((awing, default, native, ";".join(
            f"{d}->{n}" for d, n in pairs)))
        for pair in pairs:
            rule_examples[pair].append(awing)
        if i <= 5 or i % 25 == 0:
            print(f"  [{i}/{len(entries)}] {awing:<20} default={default!r:<20} native={native!r}")

    print(f"\nProcessed {len(rows)} recordings.")

    # Write per-recording CSV
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    with OUT_CSV.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["awing", "default", "native_whisper", "pairs"])
        for row in rows:
            w.writerow(row)
    print(f"Wrote per-recording diff -> {OUT_CSV.relative_to(REPO)}")

    # Aggregate to rule candidates
    # Confidence per rule: count of words it fires on / count of words
    # where the `default` substring appears at all. Compute denominator
    # via a separate scan that counts substring occurrences of EXACTLY
    # the chunk lengths we see in rule_examples (not just 1-3 char) so
    # rules like 'gh ', 'a\'ə', or longer don't get a 0 denominator.
    chunk_lengths = sorted({len(d) for (d, _) in rule_examples.keys()})
    default_chunk_count = Counter()
    for _, default, _, _ in rows:
        for size in chunk_lengths:
            for k in range(len(default) - size + 1):
                default_chunk_count[default[k:k+size]] += 1

    candidates = []
    for (d_chunk, n_chunk), words in rule_examples.items():
        if len(words) < args.min_occurrences:
            continue
        # Drop wide rules -- they typically span word boundaries on
        # multi-word verses and produce phantom rules like
        # ("ə nə" -> "uh nuh"). Single-word rules are the real targets.
        if (len(d_chunk) > args.max_rule_length or
                len(n_chunk) > args.max_rule_length):
            continue
        # Skip rules whose default chunk has a space in it -- those are
        # cross-word artifacts from continuous-speech Whisper output,
        # not real phonetic substitutions. Same for native-side spaces.
        if " " in d_chunk or " " in n_chunk:
            continue
        denom = default_chunk_count.get(d_chunk, 0)
        # Floor denom at occurrences count -- if a chunk fires on N
        # words it must appear at least N times in the corpus
        denom = max(denom, len(words))
        conf = len(words) / denom
        candidates.append({
            "default": d_chunk,
            "native": n_chunk,
            "occurrences": len(words),
            "graphemes_seen": denom,
            "confidence": conf,
            "examples": words[:8],
        })

    candidates.sort(key=lambda r: (-r["confidence"], -r["occurrences"]))

    # Write Markdown report
    lines = [
        "# Phonetic rule candidates",
        "",
        f"Mined from **{len(rows)} native recordings** by comparing what",
        "Whisper-Swahili hears in your voice vs what",
        "`awing_to_speakable()` currently outputs.",
        "",
        f"Min occurrences threshold: **{args.min_occurrences}**",
        "",
        "## High-confidence rules (≥ 70% of cases)",
        "",
        "These fire consistently and are good candidates to ship into",
        "`awing_to_speakable()` immediately:",
        "",
    ]
    high = [c for c in candidates if c["confidence"] >= HIGH_CONFIDENCE]
    med = [c for c in candidates if MED_CONFIDENCE <= c["confidence"] < HIGH_CONFIDENCE]
    low = [c for c in candidates if c["confidence"] < MED_CONFIDENCE]

    def fmt_row(c):
        return (f"- `{c['default']!r}` → `{c['native']!r}` ({c['occurrences']} "
                f"of {c['graphemes_seen']} = {c['confidence']:.0%}). "
                f"Examples: {', '.join(c['examples'][:5])}")

    if high:
        lines.extend(fmt_row(c) for c in high)
    else:
        lines.append("_(none -- mining produced no high-confidence rules)_")
    lines.extend([
        "",
        "## Medium-confidence (40-70%)",
        "",
        "Worth inspecting individually -- some may be context-dependent",
        "(only fires after certain consonants, etc.) and need a more",
        "targeted regex than a global replace.",
        "",
    ])
    if med:
        lines.extend(fmt_row(c) for c in med)
    else:
        lines.append("_(none)_")
    lines.extend([
        "",
        "## Low-confidence (< 40%) -- review only",
        "",
    ])
    if low:
        lines.extend(fmt_row(c) for c in low[:30])
    else:
        lines.append("_(none)_")

    # Suggested code snippet
    lines.extend([
        "",
        "## Suggested patches for `awing_to_speakable()`",
        "",
        "Add these `.replace()` lines INSIDE the existing function, ",
        "AFTER the current rules but BEFORE the final `.strip()`. ",
        "Hand-edit `scripts/generate_audio_edge.py`:",
        "",
        "```python",
    ])
    for c in high[:10]:
        d = c["default"].replace('"', '\\"')
        n = c["native"].replace('"', '\\"')
        lines.append(f'    s = s.replace({d!r}, {n!r})  # {c["occurrences"]} words, '
                     f'{c["confidence"]:.0%} confidence')
    lines.append("```")
    lines.append("")
    lines.append("After each change, regenerate audio for the affected ")
    lines.append("words via `python scripts/generate_audio_edge.py generate`.")
    lines.append("")

    OUT_MD.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote report -> {OUT_MD.relative_to(REPO)}")
    print(f"\nFound {len(high)} HIGH-confidence rules, "
          f"{len(med)} medium, {len(low)} low.")

    if args.auto_apply and high:
        print("\n=== --auto-apply: patching generate_audio_edge.py ===")
        bak = _patch_awing_to_speakable(high)
        print(f"Backup: {bak.relative_to(REPO)}")
        print(f"Applied {len(high)} high-confidence rules.")
        print("\nNext step: regenerate audio for affected words:")
        print("  python scripts\\generate_audio_edge.py generate")
    elif args.auto_apply:
        print("\nNo high-confidence rules to apply.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
