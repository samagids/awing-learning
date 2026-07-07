"""Extract vocab + phrases from Dart source into JSON for the Worker.

Parses lib/data/awing_vocabulary.dart, pulls every AwingWord(...) and
AwingPhrase(...) constructor call, and writes:
  cf-worker/src/vocab_data.json

Run this once after editing the Dart vocab file, before redeploying
the Worker:
    python cf-worker/scripts/extract_vocab.py
"""
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
DART_SRC = REPO / "lib" / "data" / "awing_vocabulary.dart"
OUT_JSON = REPO / "cf-worker" / "src" / "vocab_data.json"

def _find_calls(src: str, ctor: str):
    i = 0
    while True:
        i = src.find(ctor + "(", i)
        if i < 0:
            return
        start = i + len(ctor) + 1
        depth = 1
        j = start
        in_string = None
        while j < len(src) and depth > 0:
            c = src[j]
            if in_string:
                if c == "\\":
                    j += 2
                    continue
                if c == in_string:
                    in_string = None
                j += 1
                continue
            if c == "'" or c == '"':
                in_string = c
                j += 1
                continue
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0:
                    yield src[start:j]
                    break
            j += 1
        i = j + 1

STR_RE = re.compile(r"""
    (?P<key>\w+)
    \s*:\s*
    (?:
      '(?P<sq>(?:\\'|[^'])*)'
      |
      "(?P<dq>(?:\\"|[^"])*)"
      |
      (?P<num>\d+)
    )
""", re.VERBOSE)

def _parse_named(chunk: str) -> dict:
    out = {}
    for m in STR_RE.finditer(chunk):
        val = m.group("sq") or m.group("dq") or m.group("num")
        if val is None:
            continue
        if m.group("sq") is not None or m.group("dq") is not None:
            val = val.replace("\\'", "'").replace('\\"', '"').replace("\\\\", "\\").replace("\\n", "\n")
        elif m.group("num") is not None:
            val = int(val)
        out[m.group("key")] = val
    return out

def main():
    src = DART_SRC.read_text(encoding="utf-8")

    words = []
    for chunk in _find_calls(src, "AwingWord"):
        d = _parse_named(chunk)
        if "awing" not in d or "english" not in d:
            continue
        words.append({
            "awing": d["awing"],
            "english": d["english"],
            "category": d.get("category", "other"),
            "difficulty": int(d.get("difficulty", 1)) if str(d.get("difficulty", "1")).isdigit() else 1,
        })

    phrases = []
    for chunk in _find_calls(src, "AwingPhrase"):
        d = _parse_named(chunk)
        if "awing" not in d or "english" not in d:
            continue
        phrases.append({
            "awing": d["awing"],
            "english": d["english"],
            "category": d.get("category", "daily"),
        })

    # Dedup: same (awing, english) → keep first occurrence.
    seen = set()
    dedup_words = []
    for w in words:
        key = (w["awing"].lower(), w["english"].lower())
        if key in seen:
            continue
        seen.add(key)
        dedup_words.append(w)
    print(f"  deduped words: {len(words)} -> {len(dedup_words)}")

    seen_p = set()
    dedup_phrases = []
    for ph in phrases:
        key = (ph["awing"].lower(), ph["english"].lower())
        if key in seen_p:
            continue
        seen_p.add(key)
        dedup_phrases.append(ph)
    print(f"  deduped phrases: {len(phrases)} -> {len(dedup_phrases)}")

    out = {"words": dedup_words, "phrases": dedup_phrases}
    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(out, ensure_ascii=False), encoding="utf-8")

    print(f"Wrote {len(words)} words + {len(phrases)} phrases to {OUT_JSON.relative_to(REPO)}")
    print(f"  file size: {OUT_JSON.stat().st_size / 1024:.1f} KB")

if __name__ == "__main__":
    main()
