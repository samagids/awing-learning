#!/usr/bin/env python3
"""strip_phrase_plural_refs.py — strip trailing `. Pl.: <awing plural>`
from AwingPhrase english fields.

Dictionary OCR captured plural references inside the english gloss:
  english: 'bead. Pl.: pətá\\' əpúmə'
                ^^^^^^^^^^^^^^^^^^^^ — should become just 'bead'

These show up to users as raw dictionary syntax in the picker.

Run:
  python scripts/strip_phrase_plural_refs.py --dry-run
  python scripts/strip_phrase_plural_refs.py --apply
"""
import argparse
import re
import shutil
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
VOCAB = REPO / "lib" / "data" / "awing_vocabulary.dart"
BAK = REPO / "lib" / "data" / "awing_vocabulary.dart.bak_session60_strip_phrase_pl"

# Strip ". Pl.: foo" / ". Sg.: foo" / ". S.: foo" tail.
# Greedily consume to end-of-string — Awing plurals contain `'` glottal
# stops so a non-quote-stop pattern would chop them mid-word.
PLURAL_TAIL = re.compile(
    r"\s*\.\s*(?:S|Sg|Pl)\.\s*:\s*.*$",
    re.IGNORECASE,
)

PHRASE_ENTRY = re.compile(
    r"(AwingPhrase\(\s*awing:\s*(['\"])(?:\\.|(?!\2).)*?\2\s*,\s*"
    r"english:\s*)(['\"])((?:\\.|(?!\3).)*?)\3",
    re.DOTALL,
)


def main():
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
    n_fixed = 0
    examples = []

    for m in PHRASE_ENTRY.finditer(src):
        prefix = m.group(1)
        quote = m.group(3)
        english = m.group(4)

        # Skip if commented out
        line_start = src.rfind("\n", 0, m.start()) + 1
        if "//" in src[line_start:m.start()]:
            out_chunks.append(src[last_end:m.end()])
            last_end = m.end()
            continue

        new_eng = PLURAL_TAIL.sub("", english).strip()
        if new_eng != english:
            n_fixed += 1
            if len(examples) < 10:
                line_no = src[:m.start()].count("\n") + 1
                examples.append((line_no, english, new_eng))
            out_chunks.append(src[last_end:m.start()])
            out_chunks.append(f"{prefix}{quote}{new_eng}{quote}")
            last_end = m.end()

    out_chunks.append(src[last_end:])
    new_src = "".join(out_chunks)

    print(f"Found {n_fixed} AwingPhrase entries with plural ref in english.")
    if examples:
        print("\nExamples:")
        for line, before, after in examples:
            print(f"  L{line}:")
            print(f"    OLD: {before!r}")
            print(f"    NEW: {after!r}")

    if args.dry_run:
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
