#!/usr/bin/env python3
"""
Extract inflected forms (V.s, Sg.s, Pl.s, V.p.s) from the dictionary's
existing english fields. These are clean Awing surface forms already
embedded in the entries we extracted via Claude vision — no PDF
re-mining needed.

Example:
  Headword: wúnə   English: "invite, ask. V.s: ńgwú"
  → Adds: ńgwú → "invite (subject form)"

  Headword: wiŋə   English: "1) big. Sg.s: wiŋ"
  → Adds: wiŋ → "big (singular short form)"

  Headword: nəkəə  English: "house. Pl.: təkəə"
  → Adds: təkəə → "houses"

Safety: state-machine balance check + auto-restore on failure.
"""
from __future__ import annotations
import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VOCAB = ROOT / "lib" / "data" / "awing_vocabulary.dart"
BACKUP = ROOT / "lib" / "data" / "awing_vocabulary.dart.bak_inflected"
DICT_DIR = ROOT / "contributions" / "dictionary_extract"
REPORT = ROOT / "contributions" / "inflected_forms_report.json"


# Inflected-form markers in dictionary glosses, with label suffix
INFLECTION_PATTERNS = [
    # (regex, label suffix on the gloss, category-hint)
    (re.compile(r"V\.s\s*:\s*([^\s,;.\n]+)"),    "(verb subject form)", "actions"),
    (re.compile(r"V\.p\.s\s*:\s*([^\s,;.\n]+)"), "(plural verb form)",  "actions"),
    (re.compile(r"Sg\.s\s*:\s*([^\s,;.\n]+)"),   "(short singular form)", None),
    (re.compile(r"\bSg\.\s*:\s*([^\s,;.\n]+)"),  "(singular)",          None),
    (re.compile(r"\bPl\.s\s*:\s*([^\s,;.\n]+)"), "(short plural form)",  None),
    (re.compile(r"\bPl\.\s*:\s*([^\s,;.\n]+)"),  "(plural)",             None),
]


# ===== State-machine balance check (reused) =====
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


def parse_existing_pair(line):
    """Extract (awing, english) from an AwingWord literal."""
    if "AwingWord(" not in line: return None
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
    if awing and english:
        return (awing, english)
    return None


def dart_escape(s):
    return s.replace("\\", "\\\\").replace("'", "\\'")


def main():
    src = VOCAB.read_text(encoding="utf-8")
    p, b, c = check_balance(src)
    if p or b or c:
        print(f"ERROR: vocab file unbalanced (p={p} b={b} c={c})")
        return 1

    shutil.copy(VOCAB, BACKUP)
    print(f"Backup: {BACKUP.name}")

    # ---------- 1. Build existing (awing, english) set ----------
    existing = set()
    existing_awing_only = set()
    for line in src.split("\n"):
        pair = parse_existing_pair(line)
        if pair:
            existing.add(pair)
            existing_awing_only.add(pair[0])
    print(f"Existing entries: {len(existing):,}")

    # ---------- 2. Load Format B dictionary JSONs (which have V.s etc.) ----------
    json_files = sorted(DICT_DIR.glob("pages_*.json"))
    candidates = []  # (lemma_awing, lemma_english, inflected_form, label, category_hint, page)
    for jf in json_files:
        try:
            data = json.loads(jf.read_text(encoding="utf-8"))
        except Exception:
            continue
        if isinstance(data, list):
            entries = data
            page_label = jf.stem.replace("pages_", "")
        elif isinstance(data, dict):
            entries = data.get("entries", [])
            page_label = data.get("dict_pages", data.get("pages", "?"))
        else:
            continue
        for e in entries:
            if not isinstance(e, dict): continue
            lemma = e.get("awing", "").strip()
            eng_field = e.get("english", "").strip()
            if not lemma or not eng_field: continue
            for pat, label, cat_hint in INFLECTION_PATTERNS:
                for m in pat.finditer(eng_field):
                    form = m.group(1).strip().rstrip(".,;")
                    if not form: continue
                    # Strip leading garbage chars
                    form = form.lstrip("'\"-_")
                    if not form or len(form) < 2: continue
                    # Skip if same as the lemma (no inflection)
                    if form == lemma: continue
                    # Get primary english gloss (before first . or ;)
                    primary = re.split(r"[.;]", eng_field, maxsplit=1)[0].strip()
                    # If primary starts with a number, strip "1) " prefix
                    primary = re.sub(r"^\d+\)\s*", "", primary).strip()
                    # Keep it short — for inflected forms, the gloss is the
                    # primary meaning + the form label
                    if len(primary) > 60:
                        primary = primary[:60].rsplit(",", 1)[0]
                    inflected_english = f"{primary} {label}"
                    candidates.append((
                        lemma, primary, form, label, cat_hint, page_label, e
                    ))

    print(f"Inflection candidates found in dictionary: {len(candidates):,}")

    # ---------- 3. Dedup & filter ----------
    to_add = []
    skipped_dup = 0
    skipped_garbage = 0
    seen_local = set()
    for lemma, primary, form, label, cat_hint, page, lemma_entry in candidates:
        gloss = f"{primary} {label}"
        key = (form, gloss)
        if key in existing or key in seen_local:
            skipped_dup += 1
            continue
        # Skip if the form looks like OCR garbage (no vowel)
        if not re.search(r"[aeiouɛəɔɨ]", form, re.IGNORECASE):
            skipped_garbage += 1
            continue
        # Skip if the form contains digits (mangled diacritics)
        if re.search(r"\d", form):
            skipped_garbage += 1
            continue
        seen_local.add(key)

        # Categorize: use cat_hint if given, else inherit from primary gloss
        if cat_hint:
            category = cat_hint
        else:
            # Quick categorization based on lemma's existing context
            # Default to 'things' since most inflected forms are nouns/adjectives
            category = "things"
            primary_low = primary.lower()
            if any(w in primary_low for w in [" of ", "person", "father", "mother",
                                                "child", "uncle", "aunt", "wife", "husband"]):
                category = "family"
            elif any(w in primary_low for w in ["tree", "water", "stone", "ground",
                                                  "sky", "fire", "wind", "rain"]):
                category = "nature"
            elif any(w in primary_low for w in ["food", "drink", "eat", "soup", "milk"]):
                category = "food"
            elif any(w in primary_low for w in ["big", "small", "tall", "good", "bad",
                                                  "long", "short", "many", "few"]):
                category = "descriptive"
            elif any(w in primary_low for w in ["hand", "head", "foot", "eye", "ear",
                                                  "blood", "bone", "heart"]):
                category = "body"

        to_add.append({
            "awing": form,
            "english": gloss,
            "category": category,
            "lemma": lemma,
            "page": page,
        })

    print(f"To add: {len(to_add):,}")
    print(f"  Skipped duplicates: {skipped_dup:,}")
    print(f"  Skipped OCR garbage: {skipped_garbage:,}")

    if not to_add:
        print("\nNothing new to add.")
        return 0

    # ---------- 4. Build new Dart literals ----------
    new_lines = []
    cat_counts = {}
    for e in to_add:
        category = e["category"]
        cat_counts[category] = cat_counts.get(category, 0) + 1
        fields = [
            f"awing: '{dart_escape(e['awing'])}'",
            f"english: '{dart_escape(e['english'])}'",
            f"category: '{category}'",
            "difficulty: 2",
        ]
        new_lines.append(f"  // dict-inflection from {dart_escape(e['lemma'])} (p.{e['page']})")
        new_lines.append(f"  AwingWord({', '.join(fields)}),")

    # ---------- 5. Splice into dictionaryEntries ----------
    lines = src.split("\n")
    start_idx = None
    for i, ln in enumerate(lines):
        if "const List<AwingWord> dictionaryEntries" in ln:
            start_idx = i; break
    if start_idx is None:
        print("ERROR: dictionaryEntries not found")
        shutil.copy(BACKUP, VOCAB)
        return 1

    end_idx = None
    depth = 0; saw_open = False
    in_str = None; esc = False
    for i in range(start_idx, len(lines)):
        ln = lines[i]
        j = 0
        while j < len(ln):
            ch = ln[j]
            if in_str:
                if esc: esc = False; j += 1; continue
                if ch == "\\": esc = True; j += 1; continue
                if ch == in_str: in_str = None; j += 1; continue
                j += 1; continue
            if ch == "'" or ch == '"': in_str = ch; j += 1; continue
            if ch == "/" and j+1 < len(ln) and ln[j+1] == "/": break
            if ch == "[":
                depth += 1; saw_open = True
            elif ch == "]":
                depth -= 1
                if saw_open and depth == 0:
                    end_idx = i; break
            j += 1
        if end_idx is not None: break

    if end_idx is None:
        print("ERROR: end of dictionaryEntries not found")
        shutil.copy(BACKUP, VOCAB)
        return 1

    insertion = [
        "",
        "  // ============================================================",
        f"  // Inflected forms (run {len(to_add):,})",
        "  // V.s/Sg.s/Pl.s/Pl. metadata extracted from existing dictionary",
        "  // glosses — these are clean Awing surface forms already",
        "  // documented in the source data.",
        f"  // Categories: {sorted(cat_counts.items(), key=lambda x: -x[1])}",
        "  // ============================================================",
    ]
    final_lines = lines[:end_idx] + insertion + new_lines + lines[end_idx:]
    new_src = "\n".join(final_lines)

    # ---------- 6. Safety check ----------
    p2, b2, c2 = check_balance(new_src)
    if p2 or b2 or c2:
        print(f"✗ ABORT: unbalanced (p={p2} b={b2} c={c2})")
        shutil.copy(BACKUP, VOCAB)
        return 1

    VOCAB.write_text(new_src, encoding="utf-8")
    n_before = sum(1 for ln in src.split("\n") if "AwingWord(" in ln)
    n_after = sum(1 for ln in new_src.split("\n") if "AwingWord(" in ln)
    print()
    print(f"✓ SUCCESS")
    print(f"  Before: {n_before:,}")
    print(f"  After:  {n_after:,} (+{n_after - n_before})")
    print(f"  Category breakdown:")
    for cat, n in sorted(cat_counts.items(), key=lambda x: -x[1]):
        print(f"    {cat}: {n:,}")

    REPORT.parent.mkdir(exist_ok=True)
    REPORT.write_text(json.dumps({
        "before": n_before, "after": n_after,
        "added": n_after - n_before,
        "skipped_dup": skipped_dup,
        "skipped_garbage": skipped_garbage,
        "categories": cat_counts,
    }, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"  Report: {REPORT.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
