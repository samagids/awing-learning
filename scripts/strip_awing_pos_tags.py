#!/usr/bin/env python3
"""strip_awing_pos_tags.py — strip dictionary POS prefixes from the
AWING WORD FIELD (not just english).

Dictionary OCR left tags like `n.p.`, `adj.`, `c.n.`, `v.t.`, `v.i.`,
`adv.`, `num.` glued to the front of the Awing word itself. The
picker, audio generator, and image generator all use the awing field
verbatim — so the user sees "n.p. nkoŋ nelwíə" and audio tries to
literally say "n-dot-p-dot". Strip them.

Run:
  python scripts/strip_awing_pos_tags.py --dry-run
  python scripts/strip_awing_pos_tags.py --apply
"""
import argparse
import re
import shutil
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
VOCAB = REPO / "lib" / "data" / "awing_vocabulary.dart"
BAK = REPO / "lib" / "data" / "awing_vocabulary.dart.bak_session60_strip_pos"

# Leading POS prefix patterns. Each matches at start of the awing string.
POS_PREFIX = re.compile(
    r"^(?:n\.p\.|c\.n\.|v\.t\.|v\.i\.|adv\.|adj\.|num\.|interj\.|"
    r"prep\.|conj\.|n\.\s|v\.\s)\s*",
    re.IGNORECASE,
)

# Match an AwingWord entry's awing field with backref-aware quotes.
AWING_FIELD = re.compile(
    r"(AwingWord\(\s*awing:\s*)(['\"])"
    r"((?:\\.|(?!\2).)*?)\2",
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

    for m in AWING_FIELD.finditer(src):
        prefix = m.group(1)       # "AwingWord(awing: "
        quote = m.group(2)        # ' or "
        awing = m.group(3)        # the actual Awing string

        # Skip if commented out
        line_start = src.rfind("\n", 0, m.start()) + 1
        if "//" in src[line_start:m.start()]:
            out_chunks.append(src[last_end:m.end()])
            last_end = m.end()
            continue

        new_awing = POS_PREFIX.sub("", awing).strip()
        if new_awing != awing:
            n_fixed += 1
            if len(examples) < 10:
                line_no = src[:m.start()].count("\n") + 1
                examples.append((line_no, awing, new_awing))
            out_chunks.append(src[last_end:m.start()])
            out_chunks.append(f"{prefix}{quote}{new_awing}{quote}")
            last_end = m.end()

    out_chunks.append(src[last_end:])
    new_src = "".join(out_chunks)

    print(f"Found {n_fixed} AwingWord entries with POS-tag prefix in awing field.")
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
