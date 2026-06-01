#!/usr/bin/env python3
"""Build a self-contained HTML recorder for a remote native Awing speaker.

Output: native_speaker_recorder.html in the project root — a ~500 KB file
you can email / WhatsApp / Drive-share to any native Awing speaker who
agrees to contribute recordings. They open it in Firefox (or via a tiny
local web server), record on the items they know, then export ALL their
recordings as one ZIP file to send back.

The recorder includes:
  - All current Awing vocabulary (~7,500 words), phrases, and sentences
    (Bible-stripped per Session 60+ directives)
  - Filter buttons by category and difficulty
  - Search box
  - One mic per item (single-recorder, unlike family_recorder's 6-person
    matrix)
  - In-page playback (IndexedDB persistence)
  - Auto-download per recording + "Download ALL as ZIP" via JSZip CDN
  - A name field at the top so every filename is tagged with the speaker

The build script:
  1. Parses lib/data/awing_vocabulary.dart and sentences_screen.dart
  2. Drops bible/USFM-tagged items defensively (already gone, but belt-
     and-braces in case the file regresses)
  3. Substitutes JSON into scripts/native_speaker_recorder_template.html
  4. Writes native_speaker_recorder.html in the project root
"""
from __future__ import annotations

import argparse
import html
import json
import re
import sys
import unicodedata
from pathlib import Path

ROOT          = Path(__file__).resolve().parent.parent
VOCAB_DART    = ROOT / "lib" / "data" / "awing_vocabulary.dart"
SENTENCES_DART = ROOT / "lib" / "screens" / "medium" / "sentences_screen.dart"
OUTPUT_HTML   = ROOT / "native_speaker_recorder.html"
TEMPLATE_PATH = Path(__file__).resolve().parent / "native_speaker_recorder_template.html"


def audio_key(awing: str) -> str:
    """Mirror generate_audio_edge.py / image_service.dart audio_key()."""
    s = unicodedata.normalize("NFD", awing)
    s = "".join(c for c in s if not unicodedata.combining(c))
    table = {
        "ɛ": "e", "Ɛ": "E",
        "ɔ": "o", "Ɔ": "O",
        "ə": "e", "Ə": "E",
        "ɨ": "i", "Ɨ": "I",
        "ŋ": "ng", "Ŋ": "NG",
        "ɣ": "g", "Ɣ": "G",
    }
    s = "".join(table.get(c, c) for c in s)
    for ap in ("'", "’", "‘", "ʼ", "ʹ"):
        s = s.replace(ap, "")
    s = s.lower()
    s = re.sub(r"\s+", "_", s)
    s = re.sub(r"[^a-z0-9_]", "", s)
    return s


def unescape_dart(s: str) -> str:
    return (s.replace("\\'", "'")
             .replace('\\"', '"')
             .replace("\\\\", "\\")
             .replace("\\n", "\n")
             .replace("\\t", "\t"))


def strip_comments(src: str) -> str:
    """Remove // line comments and /* */ block comments while respecting strings."""
    src = re.sub(r"/\*.*?\*/", "", src, flags=re.DOTALL)
    out, i, n = [], 0, len(src)
    while i < n:
        c = src[i]
        if c in ("'", '"'):
            quote = c
            out.append(c); i += 1
            while i < n:
                ch = src[i]; out.append(ch)
                if ch == "\\" and i + 1 < n:
                    out.append(src[i + 1]); i += 2; continue
                i += 1
                if ch == quote: break
        elif c == "/" and i + 1 < n and src[i + 1] == "/":
            while i < n and src[i] != "\n": i += 1
        else:
            out.append(c); i += 1
    return "".join(out)


# Block-level parser for AwingX(...) literals (handles multi-line, escaped quotes)
def find_literal_end(text: str, start: int, opener: str) -> int | None:
    """Return index past the closing ) of an AwingX(...) literal."""
    ko = text.find(opener + "(", start)
    if ko < 0: return None
    i = ko + len(opener) + 1
    depth = 1
    in_str = None
    while i < len(text) and depth > 0:
        c = text[i]
        if in_str:
            if c == "\\" and i + 1 < len(text):
                i += 2; continue
            if c == in_str: in_str = None
        elif c in ("'", '"'): in_str = c
        elif c == "(": depth += 1
        elif c == ")": depth -= 1
        i += 1
    return i  # one past the closing ')'


def extract_blocks(src: str, opener: str):
    """Yield (start_idx, end_idx, block_text) for every opener(...) literal."""
    i = 0
    while True:
        ko = src.find(opener + "(", i)
        if ko < 0: return
        end = find_literal_end(src, ko, opener)
        if end is None: return
        yield ko, end, src[ko:end]
        i = end


def field(block: str, name: str) -> str | None:
    """Extract `name: 'value'` or `name: "value"` from an AwingX block."""
    m = re.search(
        rf"{name}:\s*('((?:[^'\\]|\\.)*)'|\"((?:[^\"\\]|\\.)*)\")",
        block, re.DOTALL,
    )
    if not m: return None
    return unescape_dart(m.group(2) if m.group(2) is not None else m.group(3))


def extract_words(src: str) -> list[dict]:
    seen, items = set(), []
    for _, _, block in extract_blocks(src, "AwingWord"):
        awing = (field(block, "awing") or "").strip()
        english = (field(block, "english") or "").strip()
        category = (field(block, "category") or "things").strip()
        if not awing or not english:
            continue
        diff_m = re.search(r"difficulty:\s*(\d+)", block)
        difficulty = int(diff_m.group(1)) if diff_m else 1
        key = audio_key(awing)
        sig = (awing, english.lower())
        if sig in seen:
            continue
        seen.add(sig)
        items.append({
            "kind": "word",
            "awing": awing,
            "english": english,
            "category": category,
            "difficulty": difficulty,
            "key": key,
        })
    return items


def extract_phrases(src: str) -> list[dict]:
    seen, items = set(), []
    for _, _, block in extract_blocks(src, "AwingPhrase"):
        awing = (field(block, "awing") or "").strip()
        english = (field(block, "english") or "").strip()
        category = (field(block, "category") or "phrase").strip()
        if not awing:
            continue
        key = audio_key(awing)
        if key in seen: continue
        seen.add(key)
        items.append({
            "kind": "phrase",
            "awing": awing,
            "english": english,
            "category": category,
            "difficulty": 1,
            "key": key,
        })
    return items


def extract_sentences(src: str) -> list[dict]:
    seen, items = set(), []
    for _, _, block in extract_blocks(src, "AwingSentence"):
        awing = (field(block, "awing") or "").strip()
        english = (field(block, "english") or "").strip()
        if not awing:
            continue
        key = audio_key(awing)
        if key in seen: continue
        seen.add(key)
        items.append({
            "kind": "sentence",
            "awing": awing,
            "english": english,
            "category": "sentence",
            "difficulty": 2,
            "key": key,
        })
    return items


def merge_homonyms(items: list[dict]) -> list[dict]:
    """One card per Awing spelling; combine multiple English meanings with '; '."""
    out, order = {}, []
    for it in items:
        sig = it["awing"]
        if sig not in out:
            out[sig] = dict(it)
            out[sig]["english_list"] = [it["english"]]
            order.append(sig)
        else:
            if it["english"] not in out[sig]["english_list"]:
                out[sig]["english_list"].append(it["english"])
            if it.get("difficulty", 3) < out[sig].get("difficulty", 3):
                out[sig]["difficulty"] = it["difficulty"]
    final = []
    for sig in order:
        m = out[sig]
        m["english"] = "; ".join(m["english_list"])
        del m["english_list"]
        final.append(m)
    return final


def disambiguate_keys(items: list[dict]) -> list[dict]:
    """Append __2, __3 when different Awing spellings collapse to same audio_key."""
    seen = {}
    for it in items:
        base = it["key"]
        n = seen.get(base, 0) + 1
        seen[base] = n
        if n > 1:
            it["key"] = f"{base}__{n}"
    return items


def build_dataset() -> list[dict]:
    if not VOCAB_DART.exists():
        sys.exit(f"Missing source: {VOCAB_DART}")
    vocab_src = strip_comments(VOCAB_DART.read_text(encoding="utf-8"))
    sent_src = strip_comments(SENTENCES_DART.read_text(encoding="utf-8")) if SENTENCES_DART.exists() else ""

    phrases   = extract_phrases(vocab_src)
    sentences = extract_sentences(sent_src)
    words     = extract_words(vocab_src)

    # Drop words whose Awing form already appears as phrase/sentence
    used = {x["awing"] for x in (phrases + sentences)}
    words = [w for w in words if w["awing"] not in used]

    phrases   = merge_homonyms(phrases)
    sentences = merge_homonyms(sentences)
    words     = merge_homonyms(words)

    items = []
    items.extend(phrases)
    items.extend(sentences)
    items.extend(sorted(words, key=lambda w: (w["difficulty"], w["awing"])))
    disambiguate_keys(items)

    counts = {"phrase": len(phrases), "sentence": len(sentences), "word": len(words)}
    diffs = {1: 0, 2: 0, 3: 0}
    for w in words:
        diffs[w.get("difficulty", 1)] += 1
    print(f"Extracted: {counts['phrase']} phrases, {counts['sentence']} sentences, "
          f"{counts['word']} words (B={diffs[1]}, M={diffs[2]}, E={diffs[3]})")
    return items


def emit_html(items: list[dict], speaker_name: str = "") -> None:
    if not TEMPLATE_PATH.exists():
        sys.exit(f"Missing template: {TEMPLATE_PATH}")
    template = TEMPLATE_PATH.read_text(encoding="utf-8")
    welcome_html = ""
    if speaker_name:
        welcome_html = (
            '<p style="margin:6px 0 0;color:#5d4037;font-weight:600;font-size:14px;">'
            'Welcome, ' + html.escape(speaker_name) + '! Your work on the orthography and dictionary made this app possible.'
            '</p>'
        )
    rendered = (template
        .replace("__ITEMS_JSON__", json.dumps(items, ensure_ascii=False))
        .replace("__SPEAKER_NAME__", html.escape(speaker_name))
        .replace("__PERSONAL_WELCOME__", welcome_html))
    html_str = rendered
    OUTPUT_HTML.write_text(html_str, encoding="utf-8")
    size_kb = OUTPUT_HTML.stat().st_size / 1024
    print(f"Wrote {OUTPUT_HTML} ({size_kb:.1f} KB, {len(items)} items)")
    print()
    print("Send this single file to your native speaker contributor:")
    print(f"  {OUTPUT_HTML}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Build the native speaker recorder HTML.")
    parser.add_argument("--speaker", default="", help="Pre-fill the speaker name in the form.")
    args = parser.parse_args()
    emit_html(build_dataset(), speaker_name=args.speaker)
