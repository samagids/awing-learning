#!/usr/bin/env python3
"""
Surgical cleanup — only removes UNAMBIGUOUS errors:
  1. Awing words that ARE proper-noun transliterations (start with
     uppercase Latin AND gloss is exactly a single proper noun)
  2. Glosses that are EXCLUSIVELY NT-specific religious phrases
     (Chief Priest, High Priest, priest;pastor compound, disciple of Jesus,
     spirit of a dead person, etc.)
  3. Polyseme duplicates: same Awing word, gloss is shorter/subset of
     another entry's gloss for same Awing word → keep the more complete one

Does NOT touch:
  - 'soul', 'spirit', 'sin', 'evil' — universal concepts, real Awing words
  - Long dictionary definitions (verbose but accurate)
  - Single-char Awing words like 'a', 'á', 'ě' (real particles/pronouns)
  - Multi-line entries
"""
from __future__ import annotations
import json
import re
import shutil
import unicodedata
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VOCAB = ROOT / "lib" / "data" / "awing_vocabulary.dart"
BACKUP = ROOT / "lib" / "data" / "awing_vocabulary.dart.bak_surgical"
REPORT = ROOT / "contributions" / "surgical_cleanup_report.json"


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


# Exact gloss strings that are NT-specific phrases (kept as-is in vocab)
NT_EXCLUSIVE_GLOSSES = {
    "disciple of jesus",
    "disciple, follower",
    "follower of jesus",
    "high priest",
    "chief priest",
    "priest; pastor",
    "pastor; priest",
    "the high priest",
    "the chief priest",
    "spirit of a dead person",
    "spirit of a dead person (invisible)",
    "ghost; spirit of dead",
    "pharisee",
    "pharisees",
    "sadducee",
    "sadducees",
    "scribes",
    "the scribes",
}

# Lowercase proper-noun glosses where if BOTH awing and english match,
# it's a clear transliteration
CLEAR_PROPER_NOUNS = {
    "aquila", "apollos", "priscilla", "barnabas", "silas", "silvanus",
    "timothy", "titus", "philemon", "onesimus", "tychicus", "trophimus",
    "demas", "epaphras", "stephanas", "gaius", "linus", "claudia",
    "narcissus", "rufus", "lucius", "manaen", "sergius", "tertius",
    "quartus", "olympas", "phlegon", "hermas", "patrobas", "hermes",
    "philologus", "julia", "nereus", "ampliatus", "urbanus", "stachys",
    "apelles", "aristobulus", "narcissus", "tryphena", "tryphosa",
    "persis", "asyncritus", "agabus", "festus", "felix", "drusilla",
    "bernice", "agrippa", "claudius", "cornelius", "gallio", "mnason",
    "mark", "matthew", "luke", "john", "james", "peter", "paul", "jude",
}


def main():
    src = VOCAB.read_text(encoding="utf-8")
    p, b, c = check_balance(src)
    if p or b or c:
        print(f"ERROR: unbalanced (p={p} b={b} c={c})")
        return 1

    shutil.copy(VOCAB, BACKUP)
    print(f"Backup: {BACKUP.name}")

    lines = src.split("\n")
    entries = []  # (line_idx, awing, english)
    for i, line in enumerate(lines):
        aw, en = parse_line(line)
        if aw is not None and en is not None:
            entries.append((i, aw, en))

    n_total = len(entries)
    print(f"Single-line AwingWord entries: {n_total:,}")

    removals = {}  # line_idx -> reason

    # 1. Proper-noun transliterations: capitalized Awing + gloss is a name
    for ln, aw, en in entries:
        if not aw or not aw[0].isascii() or not aw[0].isupper(): continue
        # Mostly-ASCII Awing (likely a transliteration of foreign name)
        ascii_chars = sum(1 for ch in aw if ch.isascii() and ch.isalpha())
        special_awing_chars = sum(1 for ch in aw if ch in "ɛəɔɨŋɣ" or unicodedata.category(ch) == "Mn")
        is_transliteration = ascii_chars >= len(aw) - 1 and special_awing_chars == 0
        en_clean = re.sub(r"\s*\(.*?\)\s*", " ", en).strip().lower()
        en_words = set(re.sub(r"[^a-zA-Z\s]", " ", en_clean).split())
        if is_transliteration and en_words & CLEAR_PROPER_NOUNS:
            removals[ln] = f"proper-noun transliteration: {aw}→{en}"

    # 2. NT-exclusive gloss phrases (exact-match, not keyword)
    for ln, aw, en in entries:
        en_clean = re.sub(r"\s*\(.*?\)\s*", " ", en).strip().lower()
        en_clean = re.sub(r"\s+", " ", en_clean).strip()
        if en_clean in NT_EXCLUSIVE_GLOSSES:
            if ln not in removals:
                removals[ln] = f"NT-exclusive gloss: {en}"

    # 3. Polyseme duplicates — for same Awing, find entries where one gloss
    #    is a strict subset of another gloss. Keep the more verbose one.
    by_awing = defaultdict(list)
    for ln, aw, en in entries:
        by_awing[aw.lower()].append((ln, aw, en))

    polyseme_redundant = 0
    for aw_key, group in by_awing.items():
        if len(group) < 2: continue
        # Sort by english length DESC (longer is more informative)
        group_sorted = sorted(group, key=lambda x: -len(x[2]))
        # Check: is shorter entry's gloss a substring of longer entry's gloss?
        kept_glosses = []
        for ln, aw, en in group_sorted:
            en_lower = re.sub(r"[^a-zA-Z\s]", "", en.lower()).strip()
            # Tokenize
            tokens = set(en_lower.split())
            redundant = False
            for kept_en, kept_ln in kept_glosses:
                kept_tokens = set(re.sub(r"[^a-zA-Z\s]", "", kept_en.lower()).split())
                # If this entry's content words are a strict subset of a kept entry's
                if tokens and tokens.issubset(kept_tokens):
                    if ln not in removals:
                        removals[ln] = f"polyseme-dup: '{en}' subset of '{kept_en}' (L{kept_ln+1})"
                    redundant = True
                    polyseme_redundant += 1
                    break
            if not redundant:
                kept_glosses.append((en, ln))

    print(f"\nRemovals:")
    print(f"  Proper-noun transliterations: {sum(1 for r in removals.values() if 'proper-noun' in r)}")
    print(f"  NT-exclusive glosses: {sum(1 for r in removals.values() if 'NT-exclusive' in r)}")
    print(f"  Polyseme duplicates: {sum(1 for r in removals.values() if 'polyseme' in r)}")
    print(f"  Total: {len(removals)}")
    print()

    # Show samples
    print("Sample removals:")
    for ln in list(removals.keys())[:15]:
        print(f"  L{ln+1}: {removals[ln][:120]}")
    print()

    # Extend to include preceding // bible: comment lines
    extended = set(removals.keys())
    for idx in list(removals.keys()):
        prev = idx - 1
        while prev >= 0 and lines[prev].strip().startswith("// bible:"):
            extended.add(prev); prev -= 1

    # Build new file with list-close preservation
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
        print(f"✗ ABORT: unbalanced after edit (p={p2} b={b2} c={c2})")
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
        "removed": [{"line": ln+1, "reason": removals[ln]} for ln in sorted(removals.keys())],
    }, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"  Report: {REPORT.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
