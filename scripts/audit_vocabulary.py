#!/usr/bin/env python3
"""
Read-only audit of the vocabulary file. Checks for:
  1. File integrity (bracket balance, no truncation)
  2. Religious-leak glosses that slipped past filters
  3. Proper-noun glosses (transliterated names)
  4. Empty / placeholder / malformed glosses
  5. Suspicious patterns (very long glosses, single-character awing,
     glosses with multiple unrelated meanings collapsed)
  6. Same awing repeated 3+ times (potential remaining noise)
  7. Glosses that look like they need review

DOES NOT modify the file. Reports findings for manual decision.

Run from PowerShell:
    python scripts\\audit_vocabulary.py
"""
from __future__ import annotations
import re
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VOCAB = ROOT / "lib" / "data" / "awing_vocabulary.dart"


def parse_awing_word(line):
    """Extract awing + english from single-line AwingWord literal."""
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
        quote = line[p]; p += 1
        out = []
        while p < len(line):
            c = line[p]
            if c == "\\" and p + 1 < len(line):
                out.append(line[p + 1]); p += 2; continue
            if c == quote:
                return "".join(out), p + 1
            out.append(c); p += 1
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
        if key == "awing": awing = value
        elif key == "english": english = value
        while pos < len(line) and line[pos] in " \t,":
            pos += 1
    return awing, english


def check_balance(src):
    paren = bracket = brace = 0
    in_string = None; escape_next = False; in_comment = False; in_block = False
    i = 0
    while i < len(src):
        c = src[i]
        if c == "\n":
            if in_comment and not in_block: in_comment = False
            i += 1; continue
        if in_block:
            if c == "*" and i+1 < len(src) and src[i+1] == "/":
                in_block = False; i += 2; continue
            i += 1; continue
        if in_comment: i += 1; continue
        if in_string:
            if escape_next: escape_next = False; i += 1; continue
            if c == "\\": escape_next = True; i += 1; continue
            if c == in_string: in_string = None; i += 1; continue
            i += 1; continue
        if c == "/" and i+1 < len(src):
            if src[i+1] == "/": in_comment = True; i += 2; continue
            if src[i+1] == "*": in_block = True; i += 2; continue
        if c == "'" or c == '"': in_string = c; i += 1; continue
        if c == "(": paren += 1
        elif c == ")": paren -= 1
        elif c == "[": bracket += 1
        elif c == "]": bracket -= 1
        elif c == "{": brace += 1
        elif c == "}": brace -= 1
        i += 1
    return paren, bracket, brace


# Religious-leak terms that should NOT be glosses for kids' vocab
RELIGIOUS_LEAK = {
    "god","gods","lord","lords","christ","jesus","messiah","spirit","holy",
    "heaven","heavens","hell","kingdom","sin","sinner","saved","savior",
    "saviour","salvation","demon","demons","satan","devil","beelzebub",
    "disciple","disciples","apostle","apostles","prophet","prophets",
    "angel","angels","archangel","cherub","scripture","gospel","covenant",
    "amen","hallelujah","parable","pharisee","pharisees","sadducee","sadducees",
    "priest","priests","levite","levites","gentile","gentiles","heathen",
    "synagogue","tabernacle","passover","pentecost","sabbath","altar",
    "sacrifice","righteous","righteousness","unrighteous","wicked","godly",
    "blasphemy","preach","worship","worshiped","praying","prayed","prayer",
    "blessed","crucify","crucified","resurrection","baptize","baptized",
    "anoint","anointed","forgive","forgiven","centurion","woe","tribulation",
    "scourge","redeemer","redeemed","atone","atonement","blameless",
}

# Proper noun glosses — biblical/historical names
PROPER_NOUNS = {
    "abraham","isaac","jacob","moses","aaron","david","solomon","elijah",
    "isaiah","daniel","jeremiah","ezekiel","jonah","mary","joseph","peter",
    "paul","john","james","matthew","mark","luke","timothy","titus","silas",
    "barnabas","stephen","ananias","cornelius","caiaphas","herod","caesar",
    "pilate","felix","festus","agrippa","jerusalem","judea","samaria",
    "galilee","nazareth","bethlehem","egypt","rome","corinth","ephesus",
    "athens","babylon","sodom","gomorrah","damascus","antioch","philippi",
    "thessalonica","tyre","sidon","tarsus","macedonia","achaia","cilicia",
    "galatia","cappadocia","pontus","bithynia","mysia","troas","miletus",
    "rhodes","cyprus","crete","malta","syracuse","perga","derbe","lystra",
    "iconium","colosse","laodicea","sardis","pergamum","smyrna","thyatira",
    "philadelphia","israel","jacinth","jasper","amethyst","topaz","beryl",
    "onyx","chalcedony","sardonyx","carnelian","chrysolite","chrysoprase",
    "abba","selah","alleluia","maranatha","gehenna","hades","sheol","ruby",
    "sardius","sapphire","emerald","kanəlya","silvanus","apollos","priscilla",
    "aquila",
}


def main():
    src = VOCAB.read_text(encoding="utf-8")
    print(f"=== File: {len(src):,} bytes ===\n")

    # 1. Bracket balance
    p, b, c = check_balance(src)
    print(f"1. File integrity:")
    print(f"   Brackets: paren={p}, bracket={b}, brace={c}")
    if p == 0 and b == 0 and c == 0:
        print(f"   ✓ Balanced\n")
    else:
        print(f"   ✗ UNBALANCED — file is broken!\n")
        return 1

    # Tail check
    tail = src[-500:]
    if "...dictionaryEntries,\n];" in src or "...dictionaryEntries\n];" in src:
        print(f"   ✓ allVocabulary getter closes properly")
    else:
        print(f"   ✗ allVocabulary missing closure!")
    if "getVocabularyByDifficulty" in src:
        print(f"   ✓ Helper functions present\n")
    else:
        print(f"   ✗ Helper functions missing!\n")

    # 2. Parse all entries
    entries = []
    for i, line in enumerate(src.split("\n"), 1):
        aw, en = parse_awing_word(line)
        if aw is not None and en is not None:
            entries.append((i, aw, en))
    print(f"2. Total single-line AwingWord entries: {len(entries):,}\n")

    # 3. Religious-leak gloss check
    religious_leaks = []
    for ln, aw, en in entries:
        en_words = set(re.sub(r"[^a-zA-Z\s]", " ", en.lower()).split())
        if en_words & RELIGIOUS_LEAK:
            religious_leaks.append((ln, aw, en))
    print(f"3. Religious-leak glosses (god/disciples/scribes/etc.): {len(religious_leaks)}")
    for ln, aw, en in religious_leaks[:10]:
        print(f"   L{ln}: {aw} → {en}")
    if len(religious_leaks) > 10:
        print(f"   ... and {len(religious_leaks) - 10} more\n")
    else:
        print()

    # 4. Proper-noun glosses
    proper_noun_glosses = []
    for ln, aw, en in entries:
        en_words = set(re.sub(r"[^a-zA-Z\s]", " ", en.lower()).split())
        if en_words & PROPER_NOUNS:
            proper_noun_glosses.append((ln, aw, en))
    print(f"4. Proper-noun glosses (names/places): {len(proper_noun_glosses)}")
    for ln, aw, en in proper_noun_glosses[:10]:
        print(f"   L{ln}: {aw} → {en}")
    if len(proper_noun_glosses) > 10:
        print(f"   ... and {len(proper_noun_glosses) - 10} more\n")
    else:
        print()

    # 5. Empty / placeholder glosses
    bad_glosses = []
    for ln, aw, en in entries:
        en_clean = en.strip()
        if not en_clean or en_clean in {"(uncertain)", "(needs review)", "(see Bible context)"}:
            bad_glosses.append((ln, aw, en))
    print(f"5. Empty/placeholder glosses: {len(bad_glosses)}")
    for ln, aw, en in bad_glosses[:10]:
        print(f"   L{ln}: {aw} → '{en}'")
    print()

    # 6. Awing word appearing 3+ times (potential remaining noise)
    awing_counts = Counter(aw.lower() for _, aw, _ in entries)
    repeats = [(aw, n) for aw, n in awing_counts.items() if n >= 3]
    repeats.sort(key=lambda x: -x[1])
    print(f"6. Awing words appearing 3+ times: {len(repeats)}")
    for aw, n in repeats[:15]:
        # Show their glosses
        glosses = [en for _, a, en in entries if a.lower() == aw][:5]
        print(f"   {aw} ({n}×): {glosses}")
    if len(repeats) > 15:
        print(f"   ... and {len(repeats) - 15} more\n")
    else:
        print()

    # 7. Suspicious patterns
    print(f"7. Suspicious patterns:")
    very_long = [(ln, aw, en) for ln, aw, en in entries if len(en) > 80]
    print(f"   Glosses > 80 chars: {len(very_long)}")
    for ln, aw, en in very_long[:5]:
        print(f"     L{ln}: {aw} → {en[:90]}...")
    single_char_awing = [(ln, aw, en) for ln, aw, en in entries if len(aw) == 1]
    print(f"   Single-character Awing: {len(single_char_awing)}")
    for ln, aw, en in single_char_awing[:5]:
        print(f"     L{ln}: '{aw}' → {en}")
    print()

    # 8. Bible-references-only entries (very high count means many Bible adds)
    bible_refs = src.count("// bible:")
    print(f"8. Bible-sourced provenance markers: {bible_refs:,}")
    needs_review = src.count("// needs review")
    print(f"   Marked 'needs review': {needs_review:,}\n")

    # Final tally
    print(f"=== AUDIT SUMMARY ===")
    issues = len(religious_leaks) + len(proper_noun_glosses) + len(bad_glosses)
    print(f"   Total potential issues to address: {issues}")
    if issues == 0:
        print(f"   ✓ Vocabulary is clean!")
    else:
        print(f"   ⚠  Recommend addressing the issues above before commit.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
