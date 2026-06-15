#!/usr/bin/env python3
"""dedupe_and_recategorize.py -- final sanity pass on awing_vocabulary.dart.

Catches three remaining issue classes the Session 60 audit rounds
didn't address:

  1. EXACT DUPLICATE AwingWord entries (same awing + english + category).
     Session 50's per-letter PDF chunks shared overlap rows and never
     got deduped. Result: the picker shows "chipo'a -> billionaire"
     7+ times in a row.

  2. CATEGORY MISMATCHES. Heuristic: scan the english gloss for
     category-conflicting keywords. Examples:
         - "billionaire" in animals -> family/things
         - "money" / "dollar" / "cent" in body -> things
         - "snake/dog/cat/bird" in things -> animals
     Move misfits to a more sensible category.

  3. TRAILING ENGLISH FRAGMENTS like "a very", "of which", "by means".
     Common OCR/dictionary-edit artifacts when a translation got cut.

Run:
  python scripts/dedupe_and_recategorize.py --dry-run
  python scripts/dedupe_and_recategorize.py --apply
"""
from __future__ import annotations
import argparse
import re
import shutil
import sys
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
VOCAB = REPO / "lib" / "data" / "awing_vocabulary.dart"
BAK = REPO / "lib" / "data" / "awing_vocabulary.dart.bak_session60_dedupe"

# Full-block AwingWord regex with all common fields. The (?P<head>) +
# (?P<body>) split lets us swap category without re-parsing.
ENTRY_RE = re.compile(
    r"AwingWord\(\s*"
    r"awing:\s*(['\"])(?P<awing>(?:\\.|(?!\1).)*?)\1\s*,\s*"
    r"english:\s*(['\"])(?P<english>(?:\\.|(?!\3).)*?)\3\s*,\s*"
    r"category:\s*(['\"])(?P<category>[^'\"]+)\5"
    r"(?P<tail>.*?)\)",
    re.DOTALL,
)


# ---- Category mismatch rules ----
# Each rule: (set of categories the entry IS currently in,
# regex on english, new category to move to).
CATEGORY_FIXES = [
    # Money / wealth never belongs in 'animals'
    (["animals"],
     re.compile(r"\b(?:billionaire|millionaire|wealth|money|"
                r"dollar|cent|cash|bank|tax)\b", re.IGNORECASE),
     "family"),
    # Money in body parts -> things
    (["body"],
     re.compile(r"\b(?:money|dollar|cent|cash|bank)\b", re.IGNORECASE),
     "things"),
    # Animal names in things -> animals. Require the animal noun to
    # be the WHOLE gloss head, terminated by end / comma / semicolon /
    # paren -- not a modifier inside a compound noun ("rat poison"
    # should stay in things; "rat" or "rat, big one" should move).
    (["things"],
     re.compile(r"^(?:snake|dog|cat|bird|goat|sheep|cow|fish|"
                r"chicken|pig|rat|mouse|monkey|elephant|lion|"
                r"tiger|frog|turtle|spider|ant|bee|bat)"
                r"(?:[,;.()\s]*$|[,;.()])",
                re.IGNORECASE),
     "animals"),
    # Person/relative roles in animals -> family
    (["animals"],
     re.compile(r"\b(?:father|mother|brother|sister|aunt|uncle|"
                r"grandfather|grandmother|husband|wife|cousin|"
                r"nephew|niece|son|daughter|child)\b",
                re.IGNORECASE),
     "family"),
    # Foods in animals (when not the animal itself) -> food
    (["animals"],
     re.compile(r"^(?:bee-bread|honey|milk|cheese|butter|"
                r"oil|sugar|salt|flour|bread)\b", re.IGNORECASE),
     "food"),
]

# ---- English fragment trimmers ----
# Trailing fragments that mean nothing in isolation.
TRAILING_FRAGS = [
    re.compile(r",\s*a\s+very\s*$", re.IGNORECASE),
    re.compile(r",\s*of\s+which\s*$", re.IGNORECASE),
    re.compile(r",\s*by\s+means\s+of\s*$", re.IGNORECASE),
    re.compile(r",\s*as\s+in\s*$", re.IGNORECASE),
    re.compile(r",\s*for\s+example\s*$", re.IGNORECASE),
    re.compile(r",\s*such\s+as\s*$", re.IGNORECASE),
    re.compile(r",\s*especially\s*$", re.IGNORECASE),
    re.compile(r",\s*in\s+general\s*$", re.IGNORECASE),
    re.compile(r"\s+a\s+very\s*$", re.IGNORECASE),
    re.compile(r",\s*\d+\s*$"),       # ", 5" / ", 12"
    re.compile(r"\s+\d+\s*$"),         # trailing bare number
    re.compile(r",?\s*etc\.?\s*$", re.IGNORECASE),
]


def dart_un(eng: str) -> str:
    """Un-escape Dart string literal contents for comparison."""
    return eng.replace("\\'", "'").replace('\\"', '"').replace("\\\\", "\\")


def trim_trailing_fragment(eng: str) -> str:
    """Strip dangling sentence-fragment patterns at the end."""
    prev = None
    cur = eng
    while prev != cur:
        prev = cur
        for pat in TRAILING_FRAGS:
            cur = pat.sub("", cur).rstrip(",;: ").strip()
    return cur


def categorize_fix(category: str, english_un: str) -> str | None:
    """Return a new category if the entry obviously misfits, else None."""
    for cats, pat, new_cat in CATEGORY_FIXES:
        if category in cats and pat.search(english_un):
            return new_cat
    return None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    if not args.dry_run and not args.apply:
        print("Pass --dry-run or --apply.")
        return 1

    src = VOCAB.read_text(encoding="utf-8")
    out_chunks = []
    last_end = 0

    seen_keys: set[tuple[str, str, str]] = set()
    n_dupes = 0
    n_recats = 0
    n_trims = 0
    recat_examples = []
    trim_examples = []
    dupe_examples = []

    for m in ENTRY_RE.finditer(src):
        full = m.group(0)
        # Un-escape captured fields so the _quote helper sees the raw
        # string value (apostrophes etc.) instead of source bytes. The
        # ENTRY_RE captures the LITERAL source slice including escape
        # sequences like \' -- we need the actual content.
        awing = dart_un(m.group("awing"))
        english = m.group("english")
        category = m.group("category")
        tail = m.group("tail")

        # Skip commented-out entries unchanged
        line_start = src.rfind("\n", 0, m.start()) + 1
        prefix = src[line_start:m.start()]
        if "//" in prefix:
            out_chunks.append(src[last_end:m.end()])
            last_end = m.end()
            continue

        en_un = dart_un(english)

        # ---- 1. Dedup ----
        key = (awing, en_un, category)
        if key in seen_keys:
            n_dupes += 1
            if len(dupe_examples) < 5:
                dupe_examples.append(f"{awing} ({category}): {en_un[:50]}")
            # Skip emitting this entry. Also skip any trailing comma
            # on the same line so we don't leave dangling commas.
            out_chunks.append(src[last_end:m.start()])
            after = src[m.end():m.end() + 50]
            # If there's a "," immediately after, consume it.
            m2 = re.match(r",\s*", after)
            if m2:
                last_end = m.end() + m2.end()
            else:
                last_end = m.end()
            continue
        seen_keys.add(key)

        # ---- 2. Trim trailing fragments ----
        new_en_un = trim_trailing_fragment(en_un)
        if new_en_un != en_un:
            n_trims += 1
            if len(trim_examples) < 5:
                trim_examples.append(f"{awing}: {en_un!r} -> {new_en_un!r}")
            en_un = new_en_un

        # ---- 3. Recategorize ----
        new_cat = categorize_fix(category, en_un)
        if new_cat:
            n_recats += 1
            if len(recat_examples) < 5:
                recat_examples.append(
                    f"{awing} ({category}->{new_cat}): {en_un[:50]}")
            category = new_cat

        # Re-emit with updated english + category. Pick quote style
        # per field so apostrophes (glottal stops) in Awing words
        # don't terminate the string. If the value contains a single
        # quote, wrap in double quotes; if both, fall back to single
        # with escaping.
        def _quote(value: str) -> str:
            # `value` is the un-escaped content. Pick safest wrapper.
            if "'" not in value:
                return "'" + value.replace("\\", "\\\\") + "'"
            if '"' not in value:
                return '"' + value.replace("\\", "\\\\") + '"'
            # Has both -- escape single quotes.
            escaped = value.replace("\\", "\\\\").replace("'", "\\'")
            return "'" + escaped + "'"

        awing_lit = _quote(awing)
        english_lit = _quote(en_un)
        category_lit = _quote(category)
        rebuilt = (
            f"AwingWord(awing: {awing_lit}, english: {english_lit}, "
            f"category: {category_lit}" + tail + ")"
        )
        out_chunks.append(src[last_end:m.start()])
        out_chunks.append(rebuilt)
        last_end = m.end()

    out_chunks.append(src[last_end:])
    new_src = "".join(out_chunks)

    print(f"Exact duplicates removed: {n_dupes}")
    for ex in dupe_examples:
        print(f"   . {ex}")
    print(f"Category mismatches fixed: {n_recats}")
    for ex in recat_examples:
        print(f"   . {ex}")
    print(f"Trailing fragments trimmed: {n_trims}")
    for ex in trim_examples:
        print(f"   . {ex}")

    if args.dry_run:
        print("\n(dry-run -- no file written)")
        return 0

    if not BAK.exists():
        shutil.copy2(VOCAB, BAK)
        print(f"\nBackup -> {BAK.relative_to(REPO)}")
    VOCAB.write_text(new_src, encoding="utf-8")
    raw = VOCAB.read_bytes().rstrip(b"\x00 \t\r\n") + b"\n"
    VOCAB.write_bytes(raw)
    print(f"Wrote {VOCAB.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
