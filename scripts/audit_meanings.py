#!/usr/bin/env python3
"""audit_meanings.py — find Awing entries with dictionary-artifact glosses.

Surfaces entries whose `english` field reads like a dictionary annotation
rather than a kid-friendly meaning. Common patterns:

  - "modifying nouns of class 5"
  - "possessive pronoun 'his' used for class 6 nouns"
  - "attribute 'certain', modifying ..."
  - "Sg.s:", "Pl.s:", "Cl. 6"
  - "noun class N", "of class N"
  - "intransitive verb, ..."
  - "ideophone for ..."
  - Definitions running longer than 12 English words

Outputs:
  contributions/meanings_audit.csv  — full list with reason flag(s)
  contributions/meanings_audit.txt  — top 50 worst offenders, formatted
  stdout summary

Run:
  python scripts/audit_meanings.py                # report only
  python scripts/audit_meanings.py --bump-class   # also bump grammar-class
                                                    entries to difficulty:3
                                                    in-place in the .dart file
"""
from __future__ import annotations
import argparse
import csv
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
VOCAB = REPO / "lib" / "data" / "awing_vocabulary.dart"
OUT_DIR = REPO / "contributions"
OUT_CSV = OUT_DIR / "meanings_audit.csv"
OUT_TXT = OUT_DIR / "meanings_audit.txt"

# Patterns that flag a gloss as a dictionary-artifact / grammar-marker
PATTERNS = [
    ("class_marker",
     # "class 5", "class 9a", "class six", "class N and M"
     re.compile(r"\b(?:of\s+)?class(?:es)?\s+(?:\d+[a-z]?|"
                r"one|two|three|four|five|six|seven|eight|nine)\b",
                re.IGNORECASE)),
    ("noun_class",
     re.compile(r"\bnouns?\s+of\s+class(?:es)?\b|\bnoun\s+class(?:es)?\b",
                re.IGNORECASE)),
    ("possessive_marker",
     re.compile(r"possessive\s+(?:plural\s+|singular\s+)?"
                r"(?:adj(?:ective)?|pronoun)\b",
                re.IGNORECASE)),
    ("attribute_marker",
     re.compile(r"^\s*attribute\b.*modify", re.IGNORECASE)),
    ("demonstrative_marker",
     re.compile(r"demonstrative\s+(?:adjective|adj|pronoun)\b",
                re.IGNORECASE)),
    ("modify_class_no_digit",
     # "used to modify class" (truncated, no digit) — still useless gloss
     re.compile(r"\b(?:modify|modifies|modifying)\s+class(?:es)?\b",
                re.IGNORECASE)),
    ("sg_pl_ref",
     # Trailing "S.: xxx" or "Pl.: xxx" or "Sg.: xxx" reference
     re.compile(r"\.\s*(?:S|Sg|Pl)\.\s*:\s*\S", re.IGNORECASE)),
    ("dict_sgpl_artifact",
     re.compile(r"\b(?:Sg|Pl)\.s:|^\s*Cl\.\s*\d", re.IGNORECASE | re.M)),
    ("ideophone_jargon",
     re.compile(r"^ideophone\b|^ideo\.\s", re.IGNORECASE)),
    ("subscript_artifact",
     re.compile(r"\b\w+[₀-₉]\b")),
    ("multiple_senses_unsorted",
     re.compile(r"(?:^|\s)1\)[^|]+2\)[^|]+3\)")),
    ("dictionary_pos_inline",
     re.compile(r"\b(?:v\.t\.|v\.i\.|n\.p\.|c\.n\.|adv\.|adj\.|num\.)",
                re.IGNORECASE)),
    ("associative_marker",
     re.compile(r"\bassociative\s+marker\b", re.IGNORECASE)),
    ("page_continuation",
     # OCR cruft: "(continues on next page)" / "(continuation)" /
     # "(entry continues to next page)" / "(continued on next page)"
     re.compile(r"\(\s*(?:continuation|continues?|entry\s+continues?|"
                r"continued)\b.*?\)", re.IGNORECASE)),
    ("leading_dict_tag",
     # Leading "(colloquial)" / "(formal)" / "(archaic)" / "(of babies)"
     # — dictionary tags that leak into the gloss
     re.compile(r"^\s*\((?:colloquial|formal|archaic|slang|informal|"
                r"figurative|dialect|euphemism|pejorative|polite|rude|"
                r"vulgar|technical|literary|of\s+\w+)\)",
                re.IGNORECASE)),
    ("malformed_paren",
     # "(be)pour" / "(bepoor)" / "(adj)smart" — POS marker merged
     re.compile(r"^\s*\([a-zA-Z]{1,4}\)[a-zA-Z]")),
    ("wrapped_paren_only",
     # Entire gloss is just "(bepoor)" — wraparound artifact
     re.compile(r"^\s*\([^)]+\)\s*$")),
]

# Word-by-word AwingWord parser. Regex matches an AwingWord literal block
# (single line OR multi-line) and captures awing + english + difficulty.
WORD_RE = re.compile(
    r"AwingWord\(\s*"
    r"awing:\s*(['\"])((?:\\.|(?!\1).)*?)\1\s*,\s*"
    r"english:\s*(['\"])((?:\\.|(?!\3).)*?)\3"
    r"(.*?)\)",
    re.DOTALL,
)
DIFFICULTY_RE = re.compile(r"difficulty:\s*(\d)")


def find_offenders(content: str) -> list[dict]:
    offenders = []
    for m in WORD_RE.finditer(content):
        # Skip if commented out
        line_start = content.rfind("\n", 0, m.start()) + 1
        if "//" in content[line_start:m.start()]:
            continue
        awing = m.group(2)
        english = m.group(4)
        rest = m.group(5)
        diff_m = DIFFICULTY_RE.search(rest)
        difficulty = int(diff_m.group(1)) if diff_m else 1

        # Run all patterns
        hits = []
        for label, pat in PATTERNS:
            if pat.search(english):
                hits.append(label)

        # Length-based flag
        word_count = len(english.split())
        if word_count > 12:
            hits.append(f"long_{word_count}w")

        if hits:
            line_no = content[:m.start()].count("\n") + 1
            offenders.append({
                "line": line_no,
                "awing": awing,
                "english": english,
                "difficulty": difficulty,
                "flags": ",".join(hits),
                "char_len": len(english),
            })
    return offenders


def bump_class_markers(content: str) -> tuple[str, int]:
    """In-place: any AwingWord whose english matches the class_marker
    pattern AND has no difficulty set (or difficulty < 3) gets bumped
    to difficulty: 3. This hides them from Beginner contributors.

    Returns (new_content, num_bumped).
    """
    bumped = 0
    out = []
    last_end = 0
    for m in WORD_RE.finditer(content):
        out.append(content[last_end:m.start()])
        block = m.group(0)
        # Same skip-if-commented check
        line_start = content.rfind("\n", 0, m.start()) + 1
        if "//" in content[line_start:m.start()]:
            out.append(block)
            last_end = m.end()
            continue
        english = m.group(4)
        # Only bump grammar-marker entries
        is_class_marker = (
            PATTERNS[0][1].search(english) or  # class_marker
            PATTERNS[1][1].search(english) or  # noun_class
            PATTERNS[2][1].search(english) or  # possessive_marker
            PATTERNS[3][1].search(english)     # attribute_marker
        )
        if is_class_marker:
            diff_m = DIFFICULTY_RE.search(block)
            current = int(diff_m.group(1)) if diff_m else 1
            if current < 3:
                if diff_m:
                    new_block = block[:diff_m.start()] + \
                                f"difficulty: 3" + \
                                block[diff_m.end():]
                else:
                    # Insert difficulty: 3 just before closing paren
                    new_block = block[:-1].rstrip() + ", difficulty: 3)"
                out.append(new_block)
                bumped += 1
                last_end = m.end()
                continue
        out.append(block)
        last_end = m.end()
    out.append(content[last_end:])
    return "".join(out), bumped


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--bump-class", action="store_true",
                    help="Also bump grammar-class entries to difficulty:3 "
                         "in awing_vocabulary.dart (writes the file).")
    args = ap.parse_args()

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    content = VOCAB.read_text(encoding="utf-8")
    print(f"Scanning {VOCAB} ({len(content):,} bytes)...")

    offenders = find_offenders(content)
    print(f"Flagged {len(offenders):,} entries with one or more issues.")

    # Group by flag for the summary
    from collections import Counter
    flag_counts = Counter()
    for o in offenders:
        for f in o["flags"].split(","):
            base = f.split("_")[0] if f.startswith("long_") else f
            flag_counts[base] += 1
    print("\nFlag distribution:")
    for label, count in flag_counts.most_common():
        print(f"  {label:<24} {count:>6}")

    # Write CSV
    with OUT_CSV.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=[
            "line", "awing", "english", "difficulty",
            "char_len", "flags"])
        w.writeheader()
        for o in sorted(offenders, key=lambda x: -x["char_len"]):
            w.writerow(o)
    print(f"\nWrote full audit -> {OUT_CSV.relative_to(REPO)}")

    # Worst 50, formatted
    worst = sorted(offenders, key=lambda x: -x["char_len"])[:50]
    lines = ["TOP 50 OFFENDERS BY GLOSS LENGTH", "=" * 70, ""]
    for o in worst:
        lines.append(f"  L{o['line']:<6} [diff={o['difficulty']}] "
                     f"{o['awing']}")
        lines.append(f"    flags: {o['flags']}")
        lines.append(f"    en: {o['english']}")
        lines.append("")
    OUT_TXT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote top-50 report -> {OUT_TXT.relative_to(REPO)}")

    if args.bump_class:
        new_content, bumped = bump_class_markers(content)
        if bumped > 0:
            VOCAB.write_text(new_content, encoding="utf-8")
            print(f"\nBumped {bumped} grammar-class entries to "
                  f"difficulty:3 in {VOCAB.relative_to(REPO)}")
        else:
            print("\nNo entries needed bumping (all class-markers already "
                  "at difficulty 3+).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
