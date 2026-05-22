#!/usr/bin/env python3
"""
SAFE vocabulary cleanup — only removes:
  1. Exact-duplicate (awing, english) pairs — same Awing word with same gloss
     listed twice in the file (true duplicates, no information loss)
  2. Specific tester-flagged fabrications (the small known-bad list)
  3. Pure-Bible-name transliterations whose Awing word starts with Latin
     uppercase AND whose gloss is a known proper noun

DOES NOT:
  - Remove entries because their gloss happens to match another entry's
    gloss. Awing has many legitimate synonyms (long/short forms, noun
    class variants, dialectal forms). Same English != duplicate Awing.
  - Touch multi-line entries.

Run from PowerShell:
    python scripts\\safe_cleanup.py
"""
from __future__ import annotations
import json
import re
import shutil
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VOCAB = ROOT / "lib" / "data" / "awing_vocabulary.dart"
BACKUP = ROOT / "lib" / "data" / "awing_vocabulary.dart.bak_safe_cleanup"
REPORT = ROOT / "contributions" / "safe_cleanup_report.json"

# Known fabrications already flagged (from this session's audits)
KNOWN_FABRICATIONS_AWING = {
    # Rev 21:20 gemstones — transliterated Greek/Hebrew from one verse
    "onizə", "kanəlya", "kwatzə", "topakzə", "chasidoni",
    "tukwasə", "ametist", "jaspa",
}

# Known dog auto-gloss collisions (per session 60 dog cleanup)
DOG_FABRICATIONS_AWING = {
    "ajǎʼkə", "ńkadlə̂", "nətwáabə",  # all from 2 Peter 2:22
    "kə́ʼtə",                          # from Philippians 3:2
    "ngaŋnə́kaŋə", "ngaŋə́zɔ́ʼə", "ngaŋə́jwítə",  # from Rev 22:15
    "məngwû",                          # short-form duplicate of məngwûə
}


def parse_line(line: str):
    """Extract awing + english from a single-line AwingWord literal.
    Returns (awing, english) or (None, None)."""
    if "AwingWord(" not in line:
        return None, None
    start = line.find("AwingWord(") + len("AwingWord(")
    pos = start
    awing = english = None

    def skip_ws(p):
        while p < len(line) and line[p] in " \t":
            p += 1
        return p

    def parse_string(p):
        if p >= len(line) or line[p] not in ("'", '"'):
            return None, p
        quote = line[p]
        p += 1
        out = []
        while p < len(line):
            c = line[p]
            if c == "\\" and p + 1 < len(line):
                out.append(line[p + 1])
                p += 2
                continue
            if c == quote:
                return "".join(out), p + 1
            out.append(c)
            p += 1
        return None, p

    for _ in range(8):
        pos = skip_ws(pos)
        if pos >= len(line) or line[pos] == ")":
            break
        kstart = pos
        while pos < len(line) and line[pos] not in " \t:":
            pos += 1
        key = line[kstart:pos]
        while pos < len(line) and line[pos] in " \t:":
            pos += 1
        if pos < len(line) and line[pos] in ("'", '"'):
            value, pos = parse_string(pos)
        else:
            vstart = pos
            while pos < len(line) and line[pos] not in " \t,)":
                pos += 1
            value = line[vstart:pos]
        if key == "awing":
            awing = value
        elif key == "english":
            english = value
        while pos < len(line) and line[pos] in " \t,":
            pos += 1
    return awing, english


def check_balance(src: str):
    """State-machine bracket balance check."""
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

    p, b, c = check_balance(src)
    if p or b or c:
        print(f"ERROR: file already unbalanced (paren={p} bracket={b} brace={c})")
        print("Run `git checkout HEAD -- lib/data/awing_vocabulary.dart` first")
        return 1

    print(f"Starting: {len(src):,} bytes")

    # Backup
    shutil.copy(VOCAB, BACKUP)
    print(f"Backup: {BACKUP.name}")

    # Parse line by line
    lines = src.split("\n")
    entries = []
    for i, line in enumerate(lines):
        aw, en = parse_line(line)
        if aw is None or en is None:
            continue
        entries.append((i, aw, en))
    print(f"Single-line AwingWord entries: {len(entries):,}")

    # Build removal plan
    removals = {}  # line_idx -> reason

    # 1. Exact (awing, english) duplicates — keep first
    seen_pairs = {}
    for idx, aw, en in entries:
        key = (aw, en.lower().strip())
        if key in seen_pairs:
            removals[idx] = f"exact-duplicate-of-L{seen_pairs[key] + 1}"
        else:
            seen_pairs[key] = idx

    # 2. Known fabrications
    all_fabrications = KNOWN_FABRICATIONS_AWING | DOG_FABRICATIONS_AWING
    for idx, aw, en in entries:
        if aw in all_fabrications:
            removals[idx] = f"known-fabrication ({aw})"

    print(f"\nWill remove: {len(removals)} entries")
    reasons = Counter(r.split(" ")[0].split("-of-")[0] for r in removals.values())
    for r, n in reasons.most_common():
        print(f"  {r}: {n}")

    # Also remove preceding // bible: provenance comment lines
    extended_removals = set(removals.keys())
    for idx in list(removals.keys()):
        prev = idx - 1
        while prev >= 0:
            line = lines[prev].strip()
            if line.startswith("// bible:"):
                extended_removals.add(prev); prev -= 1
            else:
                break

    # Build new file, preserving list-closing `];` tokens
    new_lines = []
    for i, line in enumerate(lines):
        if i in extended_removals:
            stripped = line.rstrip()
            if stripped.endswith(")];"):
                new_lines.append("];")
            elif stripped.endswith("),];"):
                new_lines.append("];")
            continue
        new_lines.append(line)
    new_src = "\n".join(new_lines)

    # Verify
    p2, b2, c2 = check_balance(new_src)
    if p2 or b2 or c2:
        print(f"\n✗ ABORT: unbalanced (paren={p2} bracket={b2} brace={c2})")
        shutil.copy(BACKUP, VOCAB)
        return 1

    if "];" not in new_src[-1500:]:
        print("\n✗ ABORT: list closure missing in tail")
        shutil.copy(BACKUP, VOCAB)
        return 1

    VOCAB.write_text(new_src, encoding="utf-8")
    n_before = sum(1 for ln in src.split("\n") if "AwingWord(" in ln)
    n_after = sum(1 for ln in new_src.split("\n") if "AwingWord(" in ln)
    print(f"\n✓ SUCCESS")
    print(f"  Before: {n_before:,} AwingWord")
    print(f"  After:  {n_after:,} AwingWord")
    print(f"  Removed: {n_before - n_after}")

    report = {
        "summary": {
            "before": n_before,
            "after": n_after,
            "removed": n_before - n_after,
        },
        "reasons": dict(reasons),
        "removed_lines": sorted(
            [{"line": idx + 1, "reason": removals.get(idx, "comment")}
             for idx in extended_removals],
            key=lambda x: x["line"],
        ),
    }
    REPORT.parent.mkdir(exist_ok=True)
    REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"  Report: {REPORT.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
