#!/usr/bin/env python3
"""
Final targeted cleanup of Bible-sourced entries with:
  1. Awing field starts with a curly/straight quote (")(')("') — capture
     error where punctuation got included in the Awing token.
  2. Awing field starts with uppercase Latin letter (A-Z) AND has NO
     Awing-specific characters (ɛ, ə, ɔ, ɨ, ŋ, ɣ, tone diacritics) →
     this is almost certainly a transliterated proper noun (NT place
     name or person name from Acts/Romans/etc.). Legitimate Awing words
     either use Awing-specific characters or start lowercase.

Only touches entries with `// bible:` provenance comment immediately above.
Does NOT touch curated entries or the original dictionary additions.

Safety: state-machine balance check + auto-restore on failure.
"""
from __future__ import annotations
import json
import re
import shutil
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VOCAB = ROOT / "lib" / "data" / "awing_vocabulary.dart"
BACKUP = ROOT / "lib" / "data" / "awing_vocabulary.dart.bak_bible_pn"
REPORT = ROOT / "contributions" / "bible_pn_cleanup_report.json"

AWING_CHARS = set("ɛəɔɨŋɣÆ")  # Awing-specific Latin extensions

def has_awing_chars(s: str) -> bool:
    if any(c in AWING_CHARS for c in s):
        return True
    # Check for combining tone diacritics
    for c in s:
        if unicodedata.category(c) == "Mn":  # combining mark
            return True
    return False


def parse_line(line):
    if "AwingWord(" not in line: return None, None
    start = line.find("AwingWord(") + len("AwingWord(")
    pos = start
    awing = english = None
    def skip(p):
        while p < len(line) and line[p] in " \t": p += 1
        return p
    def parse_str(p):
        if p >= len(line) or line[p] not in ("'", '"'): return None, p
        q = line[p]; p += 1
        out = []
        while p < len(line):
            c = line[p]
            if c == "\\" and p+1 < len(line):
                out.append(line[p+1]); p += 2; continue
            if c == q: return "".join(out), p+1
            out.append(c); p += 1
        return None, p
    for _ in range(8):
        pos = skip(pos)
        if pos >= len(line) or line[pos] == ")": break
        ks = pos
        while pos < len(line) and line[pos] not in " \t:": pos += 1
        key = line[ks:pos]
        while pos < len(line) and line[pos] in " \t:": pos += 1
        if pos < len(line) and line[pos] in ("'", '"'):
            value, pos = parse_str(pos)
        else:
            vs = pos
            while pos < len(line) and line[pos] not in " \t,)": pos += 1
            value = line[vs:pos]
        if key == "awing": awing = value
        elif key == "english": english = value
        while pos < len(line) and line[pos] in " \t,": pos += 1
    return awing, english


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
        print(f"ERROR: file unbalanced (p={p} b={b} c={c})")
        return 1

    shutil.copy(VOCAB, BACKUP)
    print(f"Backup: {BACKUP.name}")

    lines = src.split("\n")
    removals = {}  # line_idx -> reason

    # Walk through lines. For each AwingWord line, check the IMMEDIATELY
    # PRECEDING line for `// bible:` comment. If yes, apply the strict
    # filters.
    quote_chars = {"\"", "'", "“", "”", "‘", "’", "«", "»"}

    for i, line in enumerate(lines):
        aw, en = parse_line(line)
        if not aw or not en: continue

        # Is this entry Bible-sourced? Look at preceding line(s) for // bible:
        is_bible = False
        for j in range(max(0, i-2), i):
            if lines[j].strip().startswith("// bible:"):
                is_bible = True; break
        if not is_bible: continue

        # Check 1: starts with a quote character
        if aw and aw[0] in quote_chars:
            removals[i] = f"quote-contamination: '{aw[:30]}'"
            continue

        # Check 2: starts with uppercase Latin AND has no Awing-specific chars
        if aw and aw[0].isascii() and aw[0].isupper():
            if not has_awing_chars(aw):
                removals[i] = f"proper-noun transliteration: '{aw}' → '{en}'"
                continue
            # Even WITH Awing chars, if mostly Latin AND gloss is a known
            # place/person, still likely a name
            ascii_count = sum(1 for ch in aw if ch.isascii() and ch.isalpha())
            if ascii_count >= len(aw) * 0.7:
                # Check if gloss is a known Bible name/place
                # (heuristic: single capitalized word in gloss)
                en_clean = en.strip()
                if en_clean and en_clean[0].isupper() and " " not in en_clean:
                    removals[i] = f"likely-proper-noun: '{aw}' → '{en}'"

    print(f"\nWill remove: {len(removals)} entries")
    by_reason = {}
    for r in removals.values():
        key = r.split(":")[0]
        by_reason[key] = by_reason.get(key, 0) + 1
    for k, n in sorted(by_reason.items(), key=lambda x: -x[1]):
        print(f"  {k}: {n}")
    print()
    print("Samples:")
    for ln in list(removals.keys())[:20]:
        print(f"  L{ln+1}: {removals[ln][:120]}")
    print()

    # Extend to preceding // bible: comments
    extended = set(removals.keys())
    for idx in list(removals.keys()):
        prev = idx - 1
        while prev >= 0 and lines[prev].strip().startswith("// bible:"):
            extended.add(prev); prev -= 1

    # Build new
    new_lines = []
    for i, line in enumerate(lines):
        if i in extended:
            stripped = line.rstrip()
            if stripped.endswith(")];"):
                new_lines.append("];")
            elif stripped.endswith("),];"):
                new_lines.append("];")
            continue
        new_lines.append(line)
    new_src = "\n".join(new_lines)

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

    REPORT.parent.mkdir(exist_ok=True)
    REPORT.write_text(json.dumps({
        "summary": {"before": n_before, "after": n_after, "removed": n_before - n_after},
        "by_reason": by_reason,
        "removed": [{"line": ln+1, "reason": removals[ln]} for ln in sorted(removals.keys())],
    }, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"  Report: {REPORT.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
