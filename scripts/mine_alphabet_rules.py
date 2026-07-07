#!/usr/bin/env python3
"""mine_alphabet_rules.py — Session 62.

Mines pronunciation rule candidates for Awing letters by comparing:
  - What Whisper-Swahili transcribes from the native alphabet clip
    (assets/audio/alphabet/{letter_key}.mp3, extracted from YouTube
    videos back in Sessions 7–21)
  - What awing_to_speakable() from generate_audio_edge.py would produce
    for that same letter today

Divergences are printed as a Markdown table + HTML report with embedded
audio players so Dr. Sama can listen to each candidate and decide.

The alphabet is a much cleaner mining substrate than mid-word:
each clip is one isolated phoneme, so Whisper's transcription has no
coarticulation noise and any mismatch with Edge TTS's default output is
a real, targeted rule candidate.

Usage:
    python scripts/mine_alphabet_rules.py            # default: mine + report
    python scripts/mine_alphabet_rules.py --html     # also open report in browser
    python scripts/mine_alphabet_rules.py --model tiny   # faster/lower quality
    python scripts/mine_alphabet_rules.py --skip-transcribe  # just re-render report from cache

Output:
    training_data/pattern_mine_alphabet/whisper_transcriptions.json
    training_data/pattern_mine_alphabet/alphabet_report.md
    training_data/pattern_mine_alphabet/alphabet_report.html
"""
from __future__ import annotations
import argparse
import json
import os
import subprocess
import sys
import unicodedata
from pathlib import Path
from typing import Optional

REPO = Path(__file__).resolve().parent.parent
ALPHABET_DIR = REPO / "assets" / "audio" / "alphabet"
OUT_DIR = REPO / "training_data" / "pattern_mine_alphabet"
CACHE_FILE = OUT_DIR / "whisper_transcriptions.json"
REPORT_MD = OUT_DIR / "alphabet_report.md"
REPORT_HTML = OUT_DIR / "alphabet_report.html"


# ==================================================================
# Alphabet catalog — (letter, clip_filename, kind, kid-friendly hint)
# ==================================================================
# The clip filenames were established in Session 21 audio extraction
# and match pronunciation_service.dart's _audioKey() mapping.
ALPHABET: list[tuple[str, str, str, str]] = [
    # (letter, clip_key, kind, hint)
    # ---- 9 vowels ----
    ("a",  "a",         "vowel", "like 'a' in father"),
    ("e",  "e",         "vowel", "like 'e' in bed"),
    ("ɛ",  "epsilon",   "vowel", "open 'eh', more open than plain e"),
    ("ə",  "schwa",     "vowel", "like 'uh' in about"),
    ("i",  "i",         "vowel", "like 'ee' in see"),
    ("ɨ",  "barred_i",  "vowel", "centralized 'i' — between 'i' and 'u'"),
    ("o",  "o",         "vowel", "like 'o' in bore"),
    ("ɔ",  "open_o",    "vowel", "open 'aw' — more open than plain o"),
    ("u",  "u",         "vowel", "like 'oo' in boot"),
    # ---- 22 consonants (incl. glottal stop) ----
    ("b",  "b",         "consonant", "like 'b' in boy"),
    ("ch", "ch",        "consonant", "like 'ch' in church"),
    ("d",  "d",         "consonant", "like 'd' in dog"),
    ("f",  "f",         "consonant", "like 'f' in fish"),
    ("g",  "g",         "consonant", "like 'g' in go"),
    ("gh", "gh",        "consonant", "IPA /ɣ/ — soft 'g'; no English equiv."),
    ("j",  "j",         "consonant", "like 'j' in jump"),
    ("k",  "k",         "consonant", "like 'k' in kite"),
    ("l",  "l",         "consonant", "like 'l' in lamp"),
    ("m",  "m",         "consonant", "like 'm' in mom"),
    ("n",  "n",         "consonant", "like 'n' in no"),
    ("ny", "ny",        "consonant", "like 'ny' in canyon"),
    ("ŋ",  "eng",       "consonant", "like 'ng' in sing"),
    ("p",  "p",         "consonant", "like 'p' in pen"),
    ("s",  "s",         "consonant", "like 's' in sun"),
    ("sh", "sh",        "consonant", "like 'sh' in shoe"),
    ("t",  "t",         "consonant", "like 't' in top"),
    ("ts", "ts",        "consonant", "like 'ts' in cats"),
    ("w",  "w",         "consonant", "like 'w' in wet"),
    ("y",  "y",         "consonant", "like 'y' in yes"),
    ("z",  "z",         "consonant", "like 'z' in zoo"),
    ("'",  "glottal",   "consonant", "glottal stop — like the middle of 'uh-oh'"),
]


# ==================================================================
# Bring in the current awing_to_speakable() to diff against
# ==================================================================

def _load_awing_to_speakable():
    """Import awing_to_speakable() from generate_audio_edge.py without
    triggering its top-level venv-activation dance.

    Uses ast to locate the FunctionDef by name and extract just that
    function's source, then execs it in a fresh namespace with the
    imports it needs. Safer than string-slicing on section headers."""
    import ast as _ast
    edge = REPO / "scripts" / "generate_audio_edge.py"
    src = edge.read_text(encoding="utf-8")
    tree = _ast.parse(src)
    fn_node = None
    for node in tree.body:
        if isinstance(node, _ast.FunctionDef) and node.name == "awing_to_speakable":
            fn_node = node
            break
    if fn_node is None:
        raise SystemExit(
            "ERROR: awing_to_speakable() not found in scripts/generate_audio_edge.py. "
            "Was it renamed?"
        )
    fn_src = _ast.get_source_segment(src, fn_node)
    if not fn_src:
        raise SystemExit("ERROR: could not extract source segment for awing_to_speakable.")
    # Prepend the imports the function body references.
    body = "import re\nimport unicodedata\n\n" + fn_src
    ns: dict = {}
    exec(compile(body, "awing_to_speakable_extract", "exec"), ns)
    fn = ns.get("awing_to_speakable")
    if fn is None:
        raise SystemExit("ERROR: extracted body did not define awing_to_speakable().")
    return fn


# ==================================================================
# Whisper transcription (Swahili, since our TTS voice is Swahili)
# ==================================================================

def _ensure_venv():
    """Re-exec inside the Awing venv if not already there.

    Same idiom as scripts/mine_phonetic_rules.py — needed because
    Whisper's torch dependency is only installed in the venv."""
    venv_py = REPO / "venv" / "Scripts" / "python.exe"
    if not venv_py.exists():
        venv_py = REPO / "venv" / "bin" / "python"
    if not venv_py.exists():
        return  # Not in a repo with venv setup; assume host has whisper.
    current = Path(sys.executable).resolve()
    if current == venv_py.resolve():
        return
    print(f"Re-executing inside venv: {venv_py}")
    r = subprocess.run([str(venv_py), *sys.argv])
    sys.exit(r.returncode)


def _transcribe_all(model_size: str, limit: int, verbose: bool) -> dict[str, str]:
    try:
        import whisper  # type: ignore
    except ImportError:
        raise SystemExit(
            "openai-whisper not installed in this venv. Install with:\n"
            "  venv\\Scripts\\pip install openai-whisper"
        )
    print(f"Loading Whisper model '{model_size}' (first time takes a bit)...")
    model = whisper.load_model(model_size)
    results: dict[str, str] = {}
    skipped: list[str] = []
    processed = 0
    for letter, clip_key, kind, hint in ALPHABET:
        if limit and processed >= limit:
            break
        clip = ALPHABET_DIR / f"{clip_key}.mp3"
        if not clip.exists():
            skipped.append(clip_key)
            continue
        # language='sw' matches Edge TTS Swahili voice — we want to know
        # what Whisper-Swahili "hears" so we can match its orthography.
        try:
            out = model.transcribe(str(clip), language="sw", fp16=False)
        except Exception as e:
            results[clip_key] = f"__ERROR__:{e}"
            continue
        text = (out.get("text") or "").strip()
        results[clip_key] = text
        if verbose:
            print(f"  {letter:>3}  ({clip_key:>9})  -> {text!r}")
        processed += 1
    if skipped:
        print(f"WARNING: {len(skipped)} clip(s) missing on disk: {skipped}")
    return results


# ==================================================================
# Diff analysis
# ==================================================================

def _normalize_for_compare(s: str) -> str:
    """Lowercase + strip punctuation + collapse whitespace."""
    s = unicodedata.normalize("NFKC", s or "")
    out = []
    for c in s.lower():
        cat = unicodedata.category(c)
        if cat.startswith(("L", "N")) or c == " ":
            out.append(c)
    return " ".join("".join(out).split())


def _classify(letter: str, whisper: str, awing_to_speakable) -> tuple[str, str, str]:
    """Return (edge_default, comparison_class, one_line_note)."""
    default = awing_to_speakable(letter)
    default_norm = _normalize_for_compare(default)
    whisper_norm = _normalize_for_compare(whisper)
    if not whisper:
        return default, "empty", "Whisper produced nothing — clip may be too quiet or non-verbal"
    if whisper_norm == default_norm:
        return default, "match", "Exact match — no rule change needed"
    # Substring is a partial match
    if whisper_norm in default_norm or default_norm in whisper_norm:
        return default, "partial", f"Partial: Whisper heard {whisper!r}, Edge default {default!r}"
    return default, "diff", f"Divergence: Whisper heard {whisper!r}, Edge default {default!r}"


# ==================================================================
# Report generation
# ==================================================================

MD_HEADER = """# Alphabet Rule-Mining Report — Session 62

Sources:
- Native audio: `assets/audio/alphabet/{{clip_key}}.mp3` (extracted from
  YouTube alphabet lesson videos in Sessions 7–21)
- Whisper model: {model} (`language='sw'` — matches Edge TTS Swahili voice)
- Edge TTS default: `awing_to_speakable(letter)` from
  `scripts/generate_audio_edge.py`

Classification:
- **match** — Whisper transcription matches current Edge default exactly.
- **partial** — one is a substring of the other. Look at the specific
  words to decide.
- **diff** — full divergence. Strong rule candidate.
- **empty** — Whisper heard nothing (silent clip or non-verbal).

To add a rule for a `diff` letter, append to the `replacements` list in
`scripts/generate_audio_edge.py::awing_to_speakable()`.

---

## Summary

| Class    | Count |
|----------|------:|
{summary}

## Full table

| Letter | Kind      | Clip           | Whisper heard | Edge default | Class    | Suggested rule                    |
|:-------|:----------|:---------------|:--------------|:-------------|:---------|:----------------------------------|
{rows}
"""

HTML_TEMPLATE = """<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Alphabet Rule-Mining Report</title>
<style>
  body {{ font-family: -apple-system, sans-serif; max-width: 1100px; margin: 2em auto; padding: 0 1em; }}
  h1 {{ color: #006432; }}
  table {{ width: 100%; border-collapse: collapse; margin-top: 1em; }}
  th, td {{ padding: 8px 10px; border-bottom: 1px solid #ddd; text-align: left; vertical-align: middle; }}
  th {{ background: #f5f5f5; }}
  .letter {{ font-size: 1.3em; font-weight: bold; }}
  .class-match   {{ background: #e8f5e9; }}
  .class-partial {{ background: #fff8e1; }}
  .class-diff    {{ background: #ffebee; }}
  .class-empty   {{ background: #f5f5f5; color: #999; }}
  audio {{ height: 32px; }}
  .whisper {{ font-family: monospace; }}
  .edge    {{ font-family: monospace; color: #555; }}
  .hint    {{ color: #777; font-size: 0.85em; }}
</style>
</head>
<body>
<h1>Alphabet Rule-Mining Report</h1>
<p><b>Model:</b> Whisper <code>{model}</code> (language=<code>sw</code>) —
 what Whisper-Swahili hears from the native audio clip.<br>
<b>Edge default:</b> current <code>awing_to_speakable(letter)</code> output
 from <code>scripts/generate_audio_edge.py</code>.</p>
<h2>Legend</h2>
<ul>
 <li><span class="class-match">match</span> — Edge default already matches native.</li>
 <li><span class="class-partial">partial</span> — one is a substring of the other. Judgement call.</li>
 <li><span class="class-diff">diff</span> — real divergence. Rule candidate.</li>
 <li><span class="class-empty">empty</span> — Whisper heard nothing (clip may be silent).</li>
</ul>
<table>
<tr>
  <th>Letter</th>
  <th>Kind</th>
  <th>Native clip</th>
  <th>Whisper heard</th>
  <th>Edge default</th>
  <th>Class</th>
  <th>Hint</th>
</tr>
{rows}
</table>
</body>
</html>
"""


def _write_reports(rows: list[dict], model_size: str) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    # Summary counts
    counts: dict[str, int] = {}
    for r in rows:
        counts[r["class"]] = counts.get(r["class"], 0) + 1
    summary_lines = [f"| {k:<8} | {v:>5} |" for k, v in sorted(counts.items())]

    # Markdown table
    md_row_lines = []
    for r in rows:
        note = ""
        if r["class"] == "diff":
            note = f"add `{r['letter']}` → `{r['whisper']}` mapping"
        elif r["class"] == "partial":
            note = "listen + judge"
        md_row_lines.append(
            f"| `{r['letter']}` | {r['kind']} | `{r['clip_key']}.mp3` | "
            f"`{r['whisper']}` | `{r['edge_default']}` | {r['class']} | {note} |"
        )
    REPORT_MD.write_text(
        MD_HEADER.format(
            model=model_size,
            summary="\n".join(summary_lines) or "| (none)   |     0 |",
            rows="\n".join(md_row_lines),
        ),
        encoding="utf-8",
    )
    print(f"Wrote {REPORT_MD.relative_to(REPO)}")

    # HTML with embedded audio
    html_rows = []
    for r in rows:
        cls = f"class-{r['class']}"
        # HTML lives in training_data/pattern_mine_alphabet/, audio in
        # assets/audio/alphabet/ — compute a relative path from the HTML.
        audio_rel = os.path.relpath(
            ALPHABET_DIR / f"{r['clip_key']}.mp3",
            OUT_DIR,
        ).replace("\\", "/")
        html_rows.append(
            f'  <tr class="{cls}">'
            f'<td class="letter">{r["letter"]}</td>'
            f'<td>{r["kind"]}</td>'
            f'<td><audio controls src="{audio_rel}"></audio></td>'
            f'<td class="whisper">{r["whisper"] or "&mdash;"}</td>'
            f'<td class="edge">{r["edge_default"]}</td>'
            f'<td>{r["class"]}</td>'
            f'<td class="hint">{r["hint"]}</td>'
            f'</tr>'
        )
    REPORT_HTML.write_text(
        HTML_TEMPLATE.format(model=model_size, rows="\n".join(html_rows)),
        encoding="utf-8",
    )
    print(f"Wrote {REPORT_HTML.relative_to(REPO)}")


# ==================================================================
# Main
# ==================================================================

def main() -> int:
    ap = argparse.ArgumentParser(description="Mine pronunciation rule candidates from native alphabet clips.")
    ap.add_argument("--model", default="medium",
                    help="Whisper model size: tiny | base | small | medium | large "
                         "(default medium — best quality/speed tradeoff for isolated phonemes)")
    ap.add_argument("--limit", type=int, default=0,
                    help="Process only the first N letters (for quick smoke tests)")
    ap.add_argument("--html", action="store_true",
                    help="Open the HTML report in the default browser at the end")
    ap.add_argument("--skip-transcribe", action="store_true",
                    help="Skip Whisper and reuse whisper_transcriptions.json from a prior run")
    ap.add_argument("-v", "--verbose", action="store_true",
                    help="Print each transcription as it comes in")
    args = ap.parse_args()

    _ensure_venv()

    # Load transcriptions (from cache or fresh Whisper run)
    if args.skip_transcribe and CACHE_FILE.exists():
        print(f"Loading cached transcriptions from {CACHE_FILE.relative_to(REPO)}")
        transcriptions = json.loads(CACHE_FILE.read_text(encoding="utf-8"))
    else:
        transcriptions = _transcribe_all(args.model, args.limit, args.verbose)
        OUT_DIR.mkdir(parents=True, exist_ok=True)
        CACHE_FILE.write_text(json.dumps(transcriptions, indent=2, ensure_ascii=False),
                              encoding="utf-8")
        print(f"Cached transcriptions to {CACHE_FILE.relative_to(REPO)}")

    # Load current awing_to_speakable() and classify each letter
    awing_to_speakable = _load_awing_to_speakable()

    rows = []
    for letter, clip_key, kind, hint in ALPHABET:
        whisper = transcriptions.get(clip_key, "")
        if whisper.startswith("__ERROR__:"):
            rows.append({
                "letter": letter, "clip_key": clip_key, "kind": kind,
                "hint": hint, "whisper": whisper.split(":", 1)[1],
                "edge_default": "", "class": "empty",
            })
            continue
        edge_default, cls, _note = _classify(letter, whisper, awing_to_speakable)
        rows.append({
            "letter": letter, "clip_key": clip_key, "kind": kind,
            "hint": hint, "whisper": whisper,
            "edge_default": edge_default, "class": cls,
        })

    _write_reports(rows, args.model)

    # Print terminal summary
    print()
    print("Summary:")
    for cls in ("match", "partial", "diff", "empty"):
        n = sum(1 for r in rows if r["class"] == cls)
        marker = {"match": "✓", "partial": "~", "diff": "✗", "empty": "·"}[cls]
        print(f"  {marker} {cls:<8}: {n:>3}")
    print()
    diffs = [r for r in rows if r["class"] == "diff"]
    if diffs:
        print("Rule candidates (diff class):")
        for r in diffs:
            print(f"  {r['letter']:>3}  ({r['clip_key']:>9})  "
                  f"Whisper={r['whisper']!r}  Edge={r['edge_default']!r}")
    print()
    print(f"Open {REPORT_HTML.relative_to(REPO)} in a browser to listen "
          f"to each clip and judge candidates.")

    if args.html:
        import webbrowser
        webbrowser.open(REPORT_HTML.as_uri())

    return 0


if __name__ == "__main__":
    sys.exit(main())
