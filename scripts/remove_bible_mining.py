#!/usr/bin/env python3
"""
Remove ALL Bible-mined entries from awing_vocabulary.dart.

A Bible-mined entry is identified by having a `// bible:REF...` provenance
comment IMMEDIATELY above the AwingWord literal. The auto-glosser quality
was confirmed too low to trust:
  - 17+ different Awing words all collapsed to "all"
  - Proper nouns like Pɔlə (Paul), Pəjus (Jews), Jɛlusalɛm (Jerusalem)
    got auto-glossed as English content words
  - Curly-quote contamination, etc.

Keeps:
  - All curated entries (no provenance comment)
  - All dictionary-sourced entries (// dict:p.X provenance)
  - Multi-line entries
"""
from __future__ import annotations
import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VOCAB = ROOT / "lib" / "data" / "awing_vocabulary.dart"
BACKUP = ROOT / "lib" / "data" / "awing_vocabulary.dart.bak_remove_bible"
REPORT = ROOT / "contributions" / "remove_bible_report.json"


def check_balance(src):
    p = b = c = 0
    s = None; esc = False; cm = False; bc = False
    i = 0
    while i < len(src):
        ch = src[i]
        if ch == "\n":
            if cm and not bc: cm = False
            i += 1; continue
        if bc:
            if ch == "*" and i+1 < len(src) and src[i+1] == "/":
                bc = False; i += 2; continue
            i += 1; continue
        if cm: i += 1; continue
        if s:
            if esc: esc = False; i += 1; continue
            if ch == "\\": esc = True; i += 1; continue
            if ch == s: s = None; i += 1; continue
            i += 1; continue
        if ch == "/" and i+1 < len(src):
            if src[i+1] == "/": cm = True; i += 2; continue
            if src[i+1] == "*": bc = True; i += 2; continue
        if ch == "'" or ch == '"': s = ch; i += 1; continue
        if ch == "(": p += 1
        elif ch == ")": p -= 1
        elif ch == "[": b += 1
        elif ch == "]": b -= 1
        elif ch == "{": c += 1
        elif ch == "}": c -= 1
        i += 1
    return p, b, c


def main():
    src = VOCAB.read_text(encoding="utf-8")
    p, b, c = check_balance(src)
    if p or b or c:
        print(f"ERROR: unbalanced (p={p} b={b} c={c})")
        return 1

    shutil.copy(VOCAB, BACKUP)
    print(f"Backup: {BACKUP.name}")

    lines = src.split("\n")
    # Find all AwingWord lines preceded by // bible: comment
    bible_lines = set()  # indices to remove

    for i, line in enumerate(lines):
        if "AwingWord(" not in line: continue
        # Check immediate previous lines for // bible: comment
        prev = i - 1
        has_bible_comment = False
        while prev >= 0 and lines[prev].strip().startswith("// bible:"):
            bible_lines.add(prev)
            has_bible_comment = True
            prev -= 1
        if has_bible_comment:
            bible_lines.add(i)

    print(f"Bible-mined lines to remove: {len(bible_lines):,}")
    entry_count = sum(1 for i in bible_lines if "AwingWord(" in lines[i])
    print(f"AwingWord entries to remove: {entry_count:,}")

    # Build new file with list-close preservation
    new_lines = []
    for i, line in enumerate(lines):
        if i in bible_lines:
            stripped = line.rstrip()
            if stripped.endswith(")];"):
                new_lines.append("];")
            elif stripped.endswith("),];"):
                new_lines.append("];")
            continue
        new_lines.append(line)
    new_src = "\n".join(new_lines)

    # Clean up extraneous blank lines
    new_src = re.sub(r"\n{3,}", "\n\n", new_src)

    p2, b2, c2 = check_balance(new_src)
    if p2 or b2 or c2:
        print(f"✗ ABORT: unbalanced (p={p2} b={b2} c={c2})")
        shutil.copy(BACKUP, VOCAB)
        return 1

    VOCAB.write_text(new_src, encoding="utf-8")
    n_before = sum(1 for ln in src.split("\n") if "AwingWord(" in ln)
    n_after = sum(1 for ln in new_src.split("\n") if "AwingWord(" in ln)
    print(f"✓ SUCCESS")
    print(f"  Before: {n_before:,}")
    print(f"  After:  {n_after:,} (-{n_before - n_after})")
    print(f"  File size: {len(new_src):,} bytes")

    REPORT.parent.mkdir(exist_ok=True)
    REPORT.write_text(json.dumps({
        "summary": {"before": n_before, "after": n_after, "removed": n_before - n_after},
    }, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"  Report: {REPORT.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
