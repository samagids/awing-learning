#!/usr/bin/env python3
"""
Redistribute vocabulary v2 — INVERTED polarity from v1.

V1 was Beginner-strict: only ~10% landed in Beginner.
V2 is Beginner-DEFAULT: only bump UP to Medium or Expert for specific
reasons. Most entries default to Beginner.

Target distribution (rough): Beginner ~60-70%, Medium ~25-35%, Expert ~3-5%

Rules:
  EXPERT (3) — any of:
    - POS class is ideo./part./tns./excl./poss./prep./conj./neg./class./
      am./voc./focused./tns mk./asp mk./inter./attr./demos./qual.
    - English contains markers like "(particle)", "(marker)", "(archaic)",
      "associative", "imperfective", "tense marker", "demonstrative adj"
    - Awing token starts with uppercase Latin (proper noun residue)
    - English mentions ritual / libation / sacrifice / fetish

  MEDIUM (2) — any of (only if not Expert):
    - Awing is multi-word phrase (compound nouns/verb phrases)
    - English contains "(2)", "(3)", "(4)", "(5)" (homonym senses 2+)
    - English contains semicolon AND multiple senses (e.g.
      "be patient; calm one's self")
    - English starts with explicit POS marker "n.p./v.p./c.n./adj.p."
    - English describes a specialized concept (over 60 chars and
      contains "of [body part]" / "of [animal type]" / "specifically")
    - Awing has 3+ syllables AND English gloss has 3+ words

  BEGINNER (1) — default catch-all (everything else)

Safety: state-machine balance check before AND after, auto-restore on
failure. Backup at lib/data/awing_vocabulary.dart.bak_redistribute_v2.
"""
from __future__ import annotations
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VOCAB = ROOT / "lib" / "data" / "awing_vocabulary.dart"
BACKUP = ROOT / "lib" / "data" / "awing_vocabulary.dart.bak_redistribute_v2"
REPORT = ROOT / "contributions" / "redistribute_v2_report.json"


# POS markers that scream Expert
EXPERT_POS_PATTERN = re.compile(
    r"\b(ideo\.|part\.|tns\.|excl\.|poss\.|prep\.|conj\.|neg\.|class\.|"
    r"am\.|voc\.|focused\.|tns mk\.|asp mk\.|inter\.|attr\.|dem\.|qual\.|"
    r"p\.n\.)\b"
)

# Expert content markers in English gloss
EXPERT_GLOSS_PATTERN = re.compile(
    r"\b(ideo|particle|marker|archaic|associative|imperfective|perfective|"
    r"tense marker|demonstrative|honorific|voc\.|prn\.|excl\.|"
    r"ritual|libation|sacrifice|fetish|sacred|ceremonial|"
    r"sound \(word\)|intensifies)\b",
    re.IGNORECASE,
)

# Proper-noun residue (Awing token starting with uppercase Latin)
PROPER_NOUN_PATTERN = re.compile(r"^[A-Z][a-zA-Zəɛɔɨŋɣ]+")


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


def parse_awingword_fields(line):
    if "AwingWord(" not in line: return None
    aw = re.search(r"awing:\s*'((?:[^'\\]|\\.)*)'", line)
    en = re.search(r"english:\s*'((?:[^'\\]|\\.)*)'", line)
    if not aw or not en: return None
    return aw.group(1).replace("\\'", "'"), en.group(1).replace("\\'", "'")


def classify(awing: str, english: str) -> int:
    """Returns target difficulty (1, 2, or 3)."""
    en_low = english.lower()

    # ===== EXPERT checks =====
    # POS marker in English (e.g. "associative marker", "demonstrative adj")
    if EXPERT_POS_PATTERN.search(english):
        return 3
    if EXPERT_GLOSS_PATTERN.search(english):
        return 3
    # Proper noun (transliterated foreign name)
    if awing and PROPER_NOUN_PATTERN.match(awing):
        return 3

    # ===== MEDIUM checks =====
    # Multi-word Awing phrase
    if " " in awing:
        return 2
    # Homonym sense 2+
    if re.search(r"\([2-9]\)", english):
        return 2
    # Multiple senses separated by semicolon AND not just suffix metadata
    if ";" in english:
        # Don't penalize entries like "thing; matter" (genuinely simple homonyms)
        # but DO penalize complex multi-sense glosses with 3+ clauses
        clauses = [c.strip() for c in english.split(";") if c.strip()]
        if len(clauses) >= 3:
            return 2
        # Or any single clause >35 chars (specialized)
        if any(len(c) > 35 for c in clauses):
            return 2
    # Very long english (>50 chars) typically specialized
    if len(english) > 50:
        return 2
    # Awing with 4+ syllables (rough heuristic: 4+ vowel groups)
    syllable_count = len(re.findall(r"[aeiouəɛɔɨ]+", awing.lower()))
    if syllable_count >= 4 and len(english) > 20:
        return 2

    # ===== BEGINNER (default catch-all) =====
    return 1


def update_difficulty_in_line(line, new_diff):
    if "difficulty:" in line:
        return re.sub(r"difficulty:\s*\d", f"difficulty: {new_diff}", line)
    # Add difficulty before closing `),`
    end = line.rfind("),")
    if end == -1:
        end = line.rfind(")")
        if end == -1: return line
    return line[:end] + f", difficulty: {new_diff}" + line[end:]


def main():
    src = VOCAB.read_text(encoding="utf-8")
    p, b, c = check_balance(src)
    if p or b or c:
        print(f"ERROR: vocab file unbalanced (p={p} b={b} c={c})")
        return 1

    shutil.copy(VOCAB, BACKUP)
    print(f"Backup: {BACKUP.name}")

    lines = src.split("\n")
    changes = {1: 0, 2: 0, 3: 0}
    no_change = 0
    total = 0

    for i, line in enumerate(lines):
        if "AwingWord(" not in line:
            continue
        total += 1
        parsed = parse_awingword_fields(line)
        if not parsed:
            continue
        awing, english = parsed

        new_diff = classify(awing, english)

        cur_m = re.search(r"difficulty:\s*(\d)", line)
        cur = int(cur_m.group(1)) if cur_m else 1

        if new_diff != cur:
            changes[new_diff] += 1
            lines[i] = update_difficulty_in_line(line, new_diff)
        else:
            no_change += 1

    new_src = "\n".join(lines)

    # Safety check
    p2, b2, c2 = check_balance(new_src)
    if p2 or b2 or c2:
        print(f"✗ ABORT: unbalanced (p={p2} b={b2} c={c2})")
        shutil.copy(BACKUP, VOCAB)
        return 1

    VOCAB.write_text(new_src, encoding="utf-8")

    # Re-count post-merge distribution
    from collections import Counter
    after = Counter()
    for line in new_src.split("\n"):
        if "AwingWord(" not in line: continue
        m = re.search(r"difficulty:\s*(\d)", line)
        if m: after[int(m.group(1))] += 1

    print(f"\n✓ V2 redistribution complete")
    print(f"  Total entries: {total:,}")
    print(f"  Changed to Beginner: {changes[1]:,}")
    print(f"  Changed to Medium: {changes[2]:,}")
    print(f"  Changed to Expert: {changes[3]:,}")
    print(f"  Unchanged: {no_change:,}")
    print()
    print(f"FINAL DISTRIBUTION:")
    for d in (1, 2, 3):
        label = {1: "Beginner", 2: "Medium  ", 3: "Expert  "}[d]
        n = after[d]
        pct = 100 * n / total if total else 0
        print(f"  {label}: {n:>5,} ({pct:.1f}%)")

    import json
    REPORT.parent.mkdir(exist_ok=True)
    REPORT.write_text(json.dumps({
        "total": total,
        "changes": changes,
        "no_change": no_change,
        "after_distribution": dict(after),
    }, indent=2), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
