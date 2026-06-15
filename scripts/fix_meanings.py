#!/usr/bin/env python3
"""fix_meanings.py — rewrite dictionary-artifact glosses to clean ones.

For every AwingWord whose english field matches a known boilerplate
pattern (noun-class concord markers, long ideophone definitions), it:
  1. Generates a cleaner gloss (extracts core meaning, drops jargon).
  2. Bumps the entry's difficulty to 3 (Expert) so it never surfaces
     in Beginner-mode quizzes/exams/contribute lists.

Run:
  python scripts/fix_meanings.py --dry-run
  python scripts/fix_meanings.py --apply

Outputs:
  contributions/meanings_fix_preview.csv
"""
from __future__ import annotations
import argparse
import csv
import re
import sys
import shutil
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
VOCAB = REPO / "lib" / "data" / "awing_vocabulary.dart"
BAK = REPO / "lib" / "data" / "awing_vocabulary.dart.bak_session60_fix_meanings"
OUT = REPO / "contributions" / "meanings_fix_preview.csv"

CLASS_NOISE = [
    # Parenthetical: "(used for nouns of class N)" etc.
    r"\(\s*(?:used\s+for|for|used\s+to\s+modify|modifying|modifies)?\s*(?:nouns?\s+of\s+)?class(?:es)?(?!\w)\s+[\w\d\s\-,]+?\)",
    r"\(\s*possessive\s*\)",
    # "used for [head] nouns [<connector>] class N[a-z]" or "class N, M and P"
    # connector ∈ {of, which are of, of which are, which are, that are of, ""}
    r",?\s*used\s+for\s+(?:head\s+)?nouns?\s+(?:that\s+are\s+of\s+|which\s+are\s+of\s+|of\s+which\s+are\s+|of\s+|which\s+are\s+)?class(?:es)?(?!\w)\s+[\w\d\s,]+(?:\s+and\s+\d+[a-z]?)?",
    # Plain "used for head nouns that are of class N, M and P" (no
    # leading "used for" — for entries that ALREADY had "used for"
    # consumed by an earlier strip).
    r",?\s*(?:for\s+)?(?:head\s+)?nouns?\s+(?:that|which)\s+are\s+of\s+class(?:es)?(?!\w)\s+[\w\d\s,]+(?:\s+and\s+\d+[a-z]?)?",
    # "used for class N nouns" / "used for classes N and M nouns"
    r",?\s*used\s+for\s+class(?:es)?(?!\w)\s+[\w\d\s,]+(?:\s+and\s+\d+[a-z]?)?\s*nouns?",
    # "(used to modify|modifying|modifies|for) [head] [nouns of] class N[a-z]"
    # also "to modify class" with no digit (truncated dictionary entry)
    r",?\s*(?:for|used\s+to\s+modify|to\s+modify|modifying|modifies)\s+(?:head\s+)?(?:nouns?\s+of\s+|nouns?\s+|of\s+nouns?\s+of\s+)?class(?:es)?(?!\w)(?:\s+[\w\d\s,]+(?:\s+and\s+\d+[a-z]?)?)?",
    # "meaning 'of'" lead-in
    r",?\s*meaning\s+(?=[\'\"‘’“”])",
    # Trailing "(class N)"
    r"\(\s*class(?:es)?(?!\w)\s+[\w\d\s\-,]+?\)",
    # Bare "class N nouns" / "classes 5, 7 and 9 nouns"
    r",?\s*\bclass(?:es)?(?!\w)\s+[\d\w\s,]+(?:\s+and\s+\d+[a-z]?)?\s*nouns?\b",
    # "for class N"
    r",?\s*for\s+class(?:es)?(?!\w)\s+[\d\w\s\-,]+(?:\s+and\s+\d+[a-z]?)?",
    # Trailing "S.: zi" / "Sg.: foo" / "Pl.: bar" singular/plural reference
    r"\.?\s*\b(?:S|Sg|Pl)\.\s*:\s*\S+",
    # OCR-typo tolerant: "classe six" / "clase 5" — strip the whole
    # 'used for/of nouns of class<typo> <num>' fragment.
    r",?\s*(?:used\s+for|for|of)\s+nouns?\s+of\s+class\w*\s+"
    r"(?:\d+[a-z]?|one|two|three|four|five|six|seven|eight|nine)"
    r"(?:\s+and\s+\d+[a-z]?)?",
    # Last-resort: bare "class<typo> <written-or-digit>" with no
    # surrounding "used for" / "nouns of" — strip the fragment.
    r",?\s*\bclass\w*\s+"
    r"(?:\d+[a-z]?|one|two|three|four|five|six|seven|eight|nine)"
    r"(?:\s+nouns?)?",
]

GRAM_NOISE = [
    r"\bpossessive\s+(?:plural\s+|singular\s+)?(?:adjective|pronoun|adj)\b",
    r"\bpossessive\s+singular\b",
    r"\bpossessive\s+plural\b",
    r"\bassociative\s+marker\b",
    r"\bdemonstrative\s+(?:adjective|pronoun|adj)\b",
    r"\bdemonstrative\b",
    r"\bdem\.\s+adj\b",
    r"\battribute\b",
    r"\binterrogative\b",
    r"\binter\.\s+inter\b",
    r"\binter\b",
    r"\(\s*possessive\s*\)",
]

# Only fire if the string actually STARTS with "1)" — avoids
# spurious splits on "(class 3)" etc.
SENSE_RE = re.compile(r"(?:^|\s)(\d+\))\s+")
QUOTED_RE = re.compile(r"[\'\"‘’“”]([^\'\"‘’“”]+)[\'\"‘’“”]")


def clean_gloss(eng: str) -> str:
    if not eng:
        return eng

    # OCR cruft: entire gloss is a page-continuation artifact. No real
    # meaning is recoverable — these are dictionary pagination text
    # that leaked into the gloss field. Mark as missing.
    if re.match(
            r"^\s*\(\s*(?:continuation|continues?|entry\s+continues?|"
            r"continued)\b.*?\)\s*$",
            eng, re.IGNORECASE):
        return "(meaning missing)"
    # Leading page-continuation prefix with a word after: keep the word.
    # "(continuation) thumb" → "thumb"
    eng = re.sub(
        r"^\s*\(\s*(?:continuation|continues?|entry\s+continues?|"
        r"continued)\b[^)]*\)\s*",
        "", eng, flags=re.IGNORECASE)
    # Trailing page-continuation: "foo (continues on next page)" → "foo"
    eng = re.sub(
        r"\s*\(\s*(?:continues?|continued)\s+(?:on|to)\s+next\s+page\s*\)\s*$",
        "", eng, flags=re.IGNORECASE).strip()
    # Leading dictionary register tags: (colloquial) / (formal) / etc.
    # "(colloquial) smash" → "smash"
    eng = re.sub(
        r"^\s*\((?:colloquial|formal|archaic|slang|informal|"
        r"figurative|dialect|euphemism|pejorative|polite|rude|"
        r"vulgar|technical|literary|of\s+[\w\s]+)\)\s*",
        "", eng, flags=re.IGNORECASE).strip()
    # Malformed POS marker glued to gloss: "(be)pour" → "pour"
    eng = re.sub(r"^\s*\([a-zA-Z]{1,4}\)(?=[a-zA-Z])",
                 "", eng).strip()
    # Wrapped-paren only "(bepoor)" → strip parens → "bepoor"
    m_wrap = re.match(r"^\s*\(([^)]+)\)\s*$", eng)
    if m_wrap and not re.search(r"(?:continuation|continues|next\s+page)",
                                m_wrap.group(1), re.IGNORECASE):
        eng = m_wrap.group(1).strip()
    if not eng:
        return "(meaning missing)"

    senses = []
    if re.match(r"^\s*1\)\s+", eng):
        parts = SENSE_RE.split(eng)
        for i in range(1, len(parts), 2):
            if i + 1 < len(parts):
                senses.append(parts[i + 1].strip())
    if not senses:
        senses = [eng.strip()]

    has_class_jargon = bool(re.search(
        r"\b(?:class(?:es)?\s+(?:\d+[a-z]?|one|two|three|four|five|"
        r"six|seven|eight|nine)|possessive\s+(?:pronoun|adj)|"
        r"demonstrative|attribute|associative\s+marker|"
        r"(?:modify|modifies|modifying)\s+class(?:es)?(?!\w))\b",
        eng, re.IGNORECASE))

    cleaned_senses = []
    for sense in senses:
        s = sense
        # If a quoted core meaning exists, use it directly.
        if has_class_jargon:
            qm = QUOTED_RE.search(s)
            if qm:
                core = qm.group(1).strip()
                if core and core.lower() not in {"of"}:
                    if core not in cleaned_senses:
                        cleaned_senses.append(core)
                    continue
        # Otherwise strip class noise + gram noise until stable.
        prev = None
        while prev != s:
            prev = s
            for pat in CLASS_NOISE:
                s = re.sub(pat, "", s, flags=re.IGNORECASE)
            for pat in GRAM_NOISE:
                s = re.sub(pat, "", s, flags=re.IGNORECASE)
        s = re.sub(r"\s+", " ", s).strip(" ,;:.")
        # If a quoted core meaning survived, prefer it
        m = QUOTED_RE.search(s)
        if m:
            core = m.group(1).strip()
            if len(core) >= 2 and core.lower() not in {
                    "of", "the", "a", "an"}:
                s = core
        s = re.sub(r"^(?:the|a|an|of)\s+", "", s, flags=re.IGNORECASE)
        # Long-form: cut at first ';' (def from examples)
        if ";" in s:
            s = s.split(";", 1)[0].strip()
        # If post-clean result starts with a dictionary-description
        # template like "word that is used", treat it as a pure noun
        # class marker — there's no learnable English meaning.
        if has_class_jargon and re.match(
                r"^(?:word|sound|particle)\s+(?:that|used|which)\b",
                s, re.IGNORECASE):
            s = "noun class marker"
        if s and s not in cleaned_senses:
            cleaned_senses.append(s)

    if not cleaned_senses:
        # If the input was pure "associative marker" boilerplate that
        # cleaning emptied, fall back to the Bantu grammar default:
        # an associative marker IS the linker meaning "of".
        if re.search(r"\bassociative\s+marker\b", eng, re.IGNORECASE):
            return "of (linker)"
        # Pure noun-class concord prefix with no learnable meaning:
        # "used for head nouns that are of class X" etc. Give it a
        # short label instead of leaving the verbose original.
        if re.search(
                r"\bused\s+for\s+(?:head\s+)?nouns?\b",
                eng, re.IGNORECASE):
            return "noun class marker"
        # Anything else: extract the class number(s) and give a short
        # "modifier (class N)" hint instead of dumping the original.
        m = re.search(
            r"\bclass(?:es)?\w*\s+([\d\w\s,]+(?:\s+and\s+\d+[a-z]?)?)",
            eng, re.IGNORECASE)
        if m and has_class_jargon:
            cls = m.group(1).strip().rstrip(" nounsouns.")
            return f"modifier (class {cls})"
        return eng[:60].strip()

    result = "; ".join(cleaned_senses)
    if len(result) > 60:
        cut = result[:60]
        if cut.count("(") > cut.count(")"):
            cut = cut.rsplit("(", 1)[0].rstrip(",;: ")
        else:
            cut = cut.rsplit(" ", 1)[0].rstrip(",;: ")
        result = cut
    return result


DART_ENTRY_RE = re.compile(
    r"(AwingWord\(\s*awing:\s*(['\"])((?:\\.|(?!\2).)*?)\2\s*,\s*"
    r"english:\s*(['\"])((?:\\.|(?!\4).)*?)\4)"
    r"(?P<rest>.*?\))",
    re.DOTALL,
)
DIFF_RE = re.compile(r"difficulty:\s*\d")


def dart_escape(s: str, quote: str) -> str:
    s = s.replace("\\", "\\\\")
    s = s.replace(quote, "\\" + quote)
    s = s.replace("\n", " ").replace("\r", " ")
    return s


def needs_fix(eng: str, flags) -> bool:
    if any(f in flags for f in [
        "class_marker", "noun_class", "possessive_marker",
        "attribute_marker", "demonstrative_marker",
        "modify_class_no_digit", "sg_pl_ref",
        "multiple_senses_unsorted", "associative_marker",
        "page_continuation", "leading_dict_tag",
        "malformed_paren", "wrapped_paren_only",
    ]):
        return True
    if any(f.startswith("long_") for f in flags):
        word_counts = []
        for f in flags:
            if f.startswith("long_") and f[5:-1].isdigit():
                word_counts.append(int(f[5:-1]))
        if word_counts and max(word_counts) > 18:
            return True
    return False


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    if not args.dry_run and not args.apply:
        print("Pass --dry-run or --apply.")
        return 1

    audit_path = REPO / "contributions" / "meanings_audit.csv"
    if not audit_path.exists():
        print(f"Missing {audit_path} - run audit_meanings.py first.")
        return 1
    audit = {}
    with audit_path.open(encoding="utf-8") as f:
        for row in csv.DictReader(f):
            key = (row["awing"], row["english"])
            audit[key] = set(row["flags"].split(","))
    print(f"Loaded {len(audit)} audit rows.")

    src = VOCAB.read_text(encoding="utf-8")
    out_chunks = []
    last_end = 0
    n_fixed = 0
    n_bumped = 0
    preview_rows = []
    n_unchanged = 0

    for m in DART_ENTRY_RE.finditer(src):
        out_chunks.append(src[last_end:m.start()])
        awing = m.group(3)
        q = m.group(4)
        eng = m.group(5)
        rest = m.group("rest")

        line_start = src.rfind("\n", 0, m.start()) + 1
        if "//" in src[line_start:m.start()]:
            out_chunks.append(m.group(0))
            last_end = m.end()
            continue

        key = (awing, eng)
        flags = audit.get(key)
        if not flags or not needs_fix(eng, flags):
            out_chunks.append(m.group(0))
            last_end = m.end()
            continue

        un = eng.replace("\\'", "'").replace('\\"', '"').replace("\\\\", "\\")
        new_eng_un = clean_gloss(un)

        if new_eng_un == un:
            n_unchanged += 1

        new_eng = dart_escape(new_eng_un, q)

        new_rest = rest
        if DIFF_RE.search(new_rest):
            new_rest = DIFF_RE.sub("difficulty: 3", new_rest)
            n_bumped += 1
        else:
            new_rest = new_rest.rstrip()
            if new_rest.endswith(")"):
                new_rest = new_rest[:-1].rstrip(", \t") + ", difficulty: 3)"
                n_bumped += 1

        new_block = (
            f"AwingWord(awing: {q}{awing}{q}, english: {q}{new_eng}{q}"
            + new_rest
        )
        out_chunks.append(new_block)
        last_end = m.end()
        n_fixed += 1
        preview_rows.append({
            "awing": awing,
            "old_english": un,
            "new_english": new_eng_un,
            "flags": ",".join(sorted(flags)),
        })

    out_chunks.append(src[last_end:])
    new_src = "".join(out_chunks)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=[
            "awing", "old_english", "new_english", "flags"])
        w.writeheader()
        for row in preview_rows:
            w.writerow(row)

    print(f"\nRewritten: {n_fixed} entries (incl. {n_unchanged} where")
    print(f"  gloss couldn't be improved further but difficulty bumped)")
    print(f"Difficulty bumped to 3: {n_bumped} entries")
    print(f"Preview CSV: {OUT.relative_to(REPO)}")

    if args.dry_run:
        print("\nFirst 30 proposed rewrites:")
        for row in preview_rows[:30]:
            print(f"  {row['awing']}")
            print(f"    OLD: {row['old_english'][:100]}")
            print(f"    NEW: {row['new_english']}")
        return 0

    if not BAK.exists():
        shutil.copy2(VOCAB, BAK)
        print(f"Backup -> {BAK.relative_to(REPO)}")
    VOCAB.write_text(new_src, encoding="utf-8")
    raw = VOCAB.read_bytes().rstrip(b"\x00 \t\r\n") + b"\n"
    VOCAB.write_bytes(raw)
    print(f"Wrote {VOCAB.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
