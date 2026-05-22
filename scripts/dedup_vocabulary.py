#!/usr/bin/env python3
"""
Safe vocabulary dedup script for awing_vocabulary.dart.

Strategy:
  1. Parse each line of the file independently.
  2. Only consider lines that match the pattern:
     `  AwingWord(awing: '<aw>', english: '<en>', category: '<cat>'...),`
     on a SINGLE LINE. Multi-line entries (where the AwingWord(...) spans
     multiple lines) are left UNTOUCHED — they're harder to parse safely.
  3. Extract awing + english via a STATE MACHINE that properly handles
     escaped quotes (`'foo\\'s bar'`), unlike the regex approach that
     broke things last time.
  4. For each English gloss group with N>1 entries:
       - Keep the FIRST occurrence (curated entries come first in file)
       - Mark subsequent ones for removal
  5. Also remove any entry whose gloss is a known religious-leak term.
  6. Write a backup of the original file before any change.
  7. After deletion, verify bracket balance via state-machine parse —
     if balance is off, automatically restore from backup.

Run from PowerShell:
    python scripts\\dedup_vocabulary.py

Output:
    - lib/data/awing_vocabulary.dart           — modified
    - lib/data/awing_vocabulary.dart.bak_dedup — backup
    - contributions/dedup_report.json          — diff log
"""
from __future__ import annotations
import json
import re
import shutil
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VOCAB = ROOT / "lib" / "data" / "awing_vocabulary.dart"
BACKUP = ROOT / "lib" / "data" / "awing_vocabulary.dart.bak_dedup"
REPORT = ROOT / "contributions" / "dedup_report.json"

# Religious / NT-context glosses to always remove
RELIGIOUS_GLOSSES = {
    "god","gods","lord","lords","christ","jesus","messiah",
    "spirit","spirits","holy","heaven","heavens","hell","kingdom",
    "sin","sins","sinful","sinner","sinners","saved","savior",
    "saviour","salvation","redeemer","redeemed","redemption",
    "atone","atonement","atoned",
    "demon","demons","demoniac","satan","devil","beelzebub",
    "disciple","disciples","apostle","apostles","prophet","prophets",
    "prophesy","prophesies","prophecy",
    "angel","angels","archangel","cherub","seraphim",
    "scripture","scriptures","gospel","covenant","amen","hallelujah",
    "hosanna","parable","parables",
    "pharisee","pharisees","sadducee","sadducees","priest","priests",
    "levite","levites","gentile","gentiles","jew","jews","heathen","heathens",
    "synagogue","synagogues","temple","temples","tabernacle","tabernacles",
    "passover","pentecost","sabbath","sabbaths","altar","altars",
    "sacrifice","sacrifices",
    "righteous","righteousness","unrighteous","wicked","godly",
    "godliness","godhead","ungodly","blameless","blasphemy",
    "preach","preached","worship","worshiped","praying","prayed",
    "prayer","prayers","pray",
    "blessed","blessings","blesseth",
    "crucify","crucified","crucifixion","resurrection","resurrect",
    "baptize","baptized","baptism","anoint","anointed",
    "forgive","forgiven","forgiveness",
    "centurion","centurions",
    "woe","woes","lamentation","wailing","wail",
    "tribulation","tribulations","scourge","scourged",
    "betray","betrayed","betrayer",
    "uncircumcised","circumcise","circumcised","circumcision",
}


def parse_awing_word_line(line: str) -> tuple[str | None, str | None]:
    """
    State-machine parser. Returns (awing, english) if `line` is a
    single-line AwingWord literal, else (None, None).

    Handles escaped quotes inside string literals correctly.
    """
    if "AwingWord(" not in line:
        return None, None

    # Find start of the AwingWord call
    start = line.find("AwingWord(")
    if start < 0:
        return None, None
    pos = start + len("AwingWord(")

    # Parse field-by-field. We want `awing` and `english`.
    # Strategy: skip whitespace, expect `<key>:` then `<value>`,
    # where value is a string literal that may contain escaped chars.
    awing = None
    english = None

    def skip_ws(p):
        while p < len(line) and line[p] in " \t":
            p += 1
        return p

    def parse_string(p):
        """Read a string literal starting at p. Return (value, end_pos)."""
        if p >= len(line) or line[p] not in ("'", '"'):
            return None, p
        quote = line[p]
        p += 1
        out = []
        while p < len(line):
            c = line[p]
            if c == "\\" and p + 1 < len(line):
                # escape sequence — preserve next char as literal
                out.append(line[p + 1])
                p += 2
                continue
            if c == quote:
                return "".join(out), p + 1
            out.append(c)
            p += 1
        return None, p  # unterminated string — bail

    # Read up to 6 fields (awing, english, category, tonePattern, pluralForm, difficulty)
    for _ in range(8):
        pos = skip_ws(pos)
        if pos >= len(line) or line[pos] == ")":
            break
        # field name
        kstart = pos
        while pos < len(line) and line[pos] not in " \t:":
            pos += 1
        key = line[kstart:pos]
        # skip colon and ws
        while pos < len(line) and line[pos] in " \t:":
            pos += 1
        # parse value (string or int)
        if pos < len(line) and line[pos] in ("'", '"'):
            value, pos = parse_string(pos)
        else:
            # integer or identifier
            vstart = pos
            while pos < len(line) and line[pos] not in " \t,)":
                pos += 1
            value = line[vstart:pos]
        if key == "awing":
            awing = value
        elif key == "english":
            english = value
        # skip comma
        while pos < len(line) and line[pos] in " \t,":
            pos += 1

    return awing, english


def normalize_gloss(en: str) -> str:
    """Normalize English gloss for grouping. Strip parentheticals + lowercase."""
    en = re.sub(r"\s*\([^)]*\)\s*", " ", en).strip().lower()
    en = re.sub(r"\s+", " ", en)
    return en


def check_balance(src: str) -> tuple[int, int, int]:
    """State-machine bracket balance. Returns (paren, bracket, brace) final depths."""
    paren = bracket = brace = 0
    in_string = None
    escape_next = False
    in_comment = False
    in_block_comment = False
    i = 0
    while i < len(src):
        c = src[i]
        if c == "\n":
            if in_comment and not in_block_comment:
                in_comment = False
            i += 1; continue
        if in_block_comment:
            if c == "*" and i + 1 < len(src) and src[i + 1] == "/":
                in_block_comment = False; i += 2; continue
            i += 1; continue
        if in_comment:
            i += 1; continue
        if in_string:
            if escape_next:
                escape_next = False; i += 1; continue
            if c == "\\":
                escape_next = True; i += 1; continue
            if c == in_string:
                in_string = None; i += 1; continue
            i += 1; continue
        if c == "/" and i + 1 < len(src):
            if src[i + 1] == "/":
                in_comment = True; i += 2; continue
            if src[i + 1] == "*":
                in_block_comment = True; i += 2; continue
        if c == "'" or c == '"':
            in_string = c; i += 1; continue
        if c == "(": paren += 1
        elif c == ")": paren -= 1
        elif c == "[": bracket += 1
        elif c == "]": bracket -= 1
        elif c == "{": brace += 1
        elif c == "}": brace -= 1
        i += 1
    return paren, bracket, brace


def main():
    src = VOCAB.read_text(encoding="utf-8")

    # Pre-check: file must currently be balanced
    p, b, c = check_balance(src)
    if p or b or c:
        print(f"ERROR: starting file is unbalanced (paren={p} bracket={b} brace={c})")
        print("Run `git checkout HEAD -- lib/data/awing_vocabulary.dart` first")
        return 1

    print(f"Starting file: {len(src):,} bytes")

    # Backup
    shutil.copy(VOCAB, BACKUP)
    print(f"Backup written: {BACKUP.name}")

    # Parse line by line, extracting single-line AwingWord entries
    lines = src.split("\n")
    entries = []  # list of (line_idx, awing, english_norm, english_raw)
    for i, line in enumerate(lines):
        aw, en = parse_awing_word_line(line)
        if aw is None or en is None:
            continue
        entries.append((i, aw, normalize_gloss(en), en))

    print(f"Single-line AwingWord entries detected: {len(entries):,}")

    # Group by normalized English
    by_gloss: dict[str, list] = defaultdict(list)
    for idx, aw, en_norm, en_raw in entries:
        by_gloss[en_norm].append((idx, aw, en_raw))

    # Plan removals
    removals: dict[int, str] = {}  # line_idx → reason
    for en_norm, group in by_gloss.items():
        # Religious-gloss check
        if en_norm in RELIGIOUS_GLOSSES:
            for idx, aw, en_raw in group:
                removals[idx] = f"religious-gloss '{en_norm}'"
            continue
        # Duplicates: keep first (smallest line index), mark others
        if len(group) > 1:
            group_sorted = sorted(group, key=lambda x: x[0])
            for idx, aw, en_raw in group_sorted[1:]:
                removals[idx] = f"duplicate-of-L{group_sorted[0][0] + 1} ('{en_norm}')"

    print(f"\nWill remove: {len(removals)} entries")
    reasons = Counter(r.split(" ", 1)[0] for r in removals.values())
    for r, n in reasons.most_common():
        print(f"  {r}: {n}")

    # Also include preceding `// bible:...` provenance comment lines
    # for cleanup. Walk backwards from each removed line.
    extended_removals = set(removals.keys())
    for idx in list(removals.keys()):
        # Look backward for // bible: provenance comment lines
        prev = idx - 1
        while prev >= 0:
            line = lines[prev].strip()
            if line.startswith("// bible:"):
                extended_removals.add(prev)
                prev -= 1
            else:
                break

    # Build new file by skipping marked lines.
    # CRITICAL: when a removed entry's line ends with a list-closing
    # token (`];` or `)];`), preserve that close on its own line so the
    # surrounding `List<AwingWord>` literal still terminates correctly.
    list_close_re = re.compile(r"\)\s*\];?\s*$|\)\s*\]\s*,?\s*$")
    new_lines = []
    for i, line in enumerate(lines):
        if i in extended_removals:
            # If this removed line ends a list, keep the `];` close
            stripped = line.rstrip()
            if stripped.endswith(")];"):
                # Preserve the list close on its own line
                new_lines.append("];")
            elif stripped.endswith("),];"):
                new_lines.append("];")
            elif stripped.endswith(")]"):
                new_lines.append("]")
            elif stripped.endswith("])"):
                # Unlikely but defensive
                new_lines.append("]")
            # Otherwise: just drop the line (entry was mid-list)
            continue
        new_lines.append(line)
    new_src = "\n".join(new_lines)

    # Verify balance
    p2, b2, c2 = check_balance(new_src)
    if p2 or b2 or c2:
        print(f"\n✗ ABORT: new file unbalanced (paren={p2} bracket={b2} brace={c2})")
        print("Restoring from backup...")
        shutil.copy(BACKUP, VOCAB)
        print("Restored.")
        return 1

    # Verify still has both list closures
    if "...dictionaryEntries,\n];" not in new_src and "...dictionaryEntries\n];" not in new_src:
        print("\n✗ ABORT: dictionaryEntries list closure missing")
        shutil.copy(BACKUP, VOCAB)
        return 1

    # Write
    VOCAB.write_text(new_src, encoding="utf-8")

    # Final counts
    n_aw_before = sum(1 for line in src.split("\n") if "AwingWord(" in line)
    n_aw_after = sum(1 for line in new_src.split("\n") if "AwingWord(" in line)
    print(f"\n✓ Success.")
    print(f"  Before: {n_aw_before:,} AwingWord references")
    print(f"  After:  {n_aw_after:,} AwingWord references")
    print(f"  Removed: {n_aw_before - n_aw_after} entries (+ comment lines)")
    print(f"  File size: {len(new_src):,} bytes")

    # Report
    report = {
        "summary": {
            "before_awing_word": n_aw_before,
            "after_awing_word": n_aw_after,
            "removed_entries": n_aw_before - n_aw_after,
            "removed_lines_total": len(extended_removals),
        },
        "reasons": dict(reasons),
        "removed_lines": sorted([
            {"line": idx + 1, "reason": removals.get(idx, "comment")}
            for idx in extended_removals
        ], key=lambda x: x["line"]),
    }
    REPORT.parent.mkdir(exist_ok=True)
    REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"  Report: {REPORT.name}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
