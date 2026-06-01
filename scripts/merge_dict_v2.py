#!/usr/bin/env python3
"""scripts/merge_dict_v2.py — Merge contributions/dictionary_extract_v2/*.json
entries into lib/data/awing_vocabulary.dart.

For each entry in the v2 JSON files:
  1. Compute audio_key (normalized, for dedup)
  2. Check if (audio_key, english_short) already exists in vocab.dart
     - If yes, skip
     - If no, append to dictionaryEntries list as new AwingWord

Run: python3 scripts/merge_dict_v2.py [--dry-run]
"""
import json
import re
import sys
import unicodedata
from pathlib import Path
from collections import defaultdict

VOCAB = Path("lib/data/awing_vocabulary.dart")
V2_DIR = Path("contributions/dictionary_extract_v2")

def audio_key(s):
    nfd = unicodedata.normalize("NFD", s)
    no_tone = "".join(c for c in nfd if unicodedata.category(c) != "Mn")
    s2 = unicodedata.normalize("NFC", no_tone).lower()
    s2 = s2.replace("ɛ", "e").replace("ɔ", "o").replace("ə", "a").replace("ɨ", "i").replace("ŋ", "ng")
    s2 = re.sub(r"[^a-z0-9_]+", "_", s2)
    return s2.strip("_") or "_"

def english_short(eng):
    return re.sub(r"\s*\([^)]*\)", "", eng.lower()).strip()

# Categorize based on English content
def categorize(english):
    e = english.lower()
    if any(x in e for x in ["body", "skin", "bone", "blood", "eye", "ear", "nose", "hand", "foot", "head", "tooth", "mouth", "tongue", "heart", "leg", "arm", "finger", "neck", "lip", "knee"]):
        return "body"
    if any(x in e for x in ["dog", "cat", "bird", "fish", "snake", "cow", "goat", "sheep", "animal", "elephant", "lion", "monkey", "cockroach", "insect", "louse"]):
        return "animals"
    if any(x in e for x in ["food", "rice", "milk", "egg", "fruit", "vegetable", "drink", "meat", "soup", "honey"]):
        return "food"
    if any(x in e for x in ["father", "mother", "child", "baby", "friend", "uncle", "aunt", "brother", "sister", "person", "people", "chief", "elder"]):
        return "family"
    if any(x in e for x in ["river", "tree", "sky", "rain", "sun", "moon", "grass", "mountain", "stone", "fire"]):
        return "nature"
    if e.startswith(("see ", "look ", "go ", "come ", "eat ", "drink ", "say ", "speak", "do ", "make", "give", "take", "kill", "catch")):
        return "actions"
    return "things"

def difficulty_guess(eng, pos):
    # Simple verbs and common nouns = 1; longer compounds = 2; rare = 3
    if pos in ("v", "n.p", "c.n") and " " in (eng or ""):
        return 2
    return 1

def dart_escape(s):
    return s.replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ")

def main(dry_run=False):
    content = VOCAB.read_text(encoding="utf-8")
    # Find existing (audio_key, english_short) pairs to skip
    pat = re.compile(r"AwingWord\(\s*awing:\s*'([^']+)',\s*english:\s*'((?:[^'\\]|\\.)+)'")
    existing = set()
    for ln in content.split("\n"):
        if ln.lstrip().startswith("//"):
            continue
        m = pat.search(ln)
        if m:
            existing.add((audio_key(m.group(1)), english_short(m.group(2))))

    # Load all v2 JSON files
    new_entries = []
    skipped = 0
    for jf in sorted(V2_DIR.glob("page_*.json")):
        try:
            data = json.loads(jf.read_text(encoding="utf-8"))
        except Exception:
            continue
        for e in data:
            aw = (e.get("awing") or "").strip()
            en = (e.get("english") or "").strip()
            if not aw or not en:
                continue
            key = (audio_key(aw), english_short(en))
            if key in existing:
                skipped += 1
                continue
            existing.add(key)
            pos = e.get("pos", "")
            cat = categorize(en)
            diff = difficulty_guess(en, pos)
            new_entries.append({
                "awing": aw,
                "english": en,
                "category": cat,
                "difficulty": diff,
                "source": jf.stem,
            })

    print(f"Loaded v2 entries: {len(new_entries) + skipped}")
    print(f"Already in vocab: {skipped}")
    print(f"NEW to add:        {len(new_entries)}")

    if dry_run or not new_entries:
        return

    # Insert before the closing `]` of `dictionaryEntries`. Find that anchor.
    anchor = re.search(r"(const\s+List<AwingWord>\s+dictionaryEntries\s*=\s*\[.*?)(\n\];)", content, re.DOTALL)
    if not anchor:
        print("Could not find dictionaryEntries list anchor")
        return

    additions = []
    for e in new_entries:
        line = f"  AwingWord(awing: '{dart_escape(e['awing'])}', english: '{dart_escape(e['english'])}', category: '{e['category']}', difficulty: {e['difficulty']}),  // v2:{e['source']}"
        additions.append(line)
    add_block = "\n  // === Session 61 v2 dictionary extraction ===\n" + "\n".join(additions) + "\n"
    new_content = content[:anchor.end(1)] + add_block + content[anchor.end(1):]
    VOCAB.write_text(new_content, encoding="utf-8")
    print(f"\nAppended {len(new_entries)} entries to {VOCAB}")

if __name__ == "__main__":
    main(dry_run="--dry-run" in sys.argv)
