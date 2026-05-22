#!/usr/bin/env python3
"""
Redistribute the 7,517 vocabulary entries across Beginner / Medium / Expert
based on the actual structure of each entry. Goal: most common words land
in Beginner, compounds/uncommon stuff land in Medium, ideophones/markers/
specialized terms land in Expert.

Rules (applied per AwingWord literal):

  EXPERT (difficulty: 3) — if ANY of these:
    - POS class is ideo./part./tns./excl./poss./prep./conj./neg./class./am./voc./focused
    - English contains "(particle)", "(marker)", "(ideo)", "(archaic)", "ritual"
    - Awing token starts with uppercase Latin (proper-noun residue)
    - English describes a sacrificial/traditional-ritual concept

  BEGINNER (difficulty: 1) — if ALL of these:
    - Awing word is a SINGLE token (no spaces — no compound phrases)
    - Awing word length ≤ 9 characters (short, learnable)
    - English gloss ≤ 25 chars (concise meaning)
    - English starts with a common everyday word (body part, food, animal,
      family, basic action, color, simple descriptive)
    - No homonym number OR homonym number == 1 (primary sense only)
    - POS is n. v. adj. (concrete content words)

  MEDIUM (difficulty: 2) — everything else (the default catch-all)

Safety: state-machine balance check before AND after, auto-restore on
failure. Backup at lib/data/awing_vocabulary.dart.bak_redistribute.
"""
from __future__ import annotations
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VOCAB = ROOT / "lib" / "data" / "awing_vocabulary.dart"
BACKUP = ROOT / "lib" / "data" / "awing_vocabulary.dart.bak_redistribute"
REPORT = ROOT / "contributions" / "redistribute_report.json"


# Common everyday-vocabulary English words — if the gloss starts with one
# of these (or IS one), the entry is a good Beginner candidate.
BEGINNER_WORDS = {
    # body
    "hand","arm","leg","foot","head","hair","eye","ear","mouth","tooth",
    "nose","tongue","lip","chin","neck","face","skin","blood","bone",
    "heart","stomach","belly","chest","back","knee","elbow","finger",
    "toe","navel","hip","waist","shoulder","beard","thumb","nail","throat",
    # family
    "father","mother","child","son","daughter","brother","sister",
    "uncle","aunt","cousin","baby","boy","girl","man","woman","person",
    "people","friend","family","husband","wife","ancestor","ancestors",
    "elder","chief","king","queen","grandfather","grandmother","groom",
    "bride","twin","relative","stranger","guest","host","worker",
    # food + drink
    "food","drink","water","milk","oil","salt","sugar","pepper","rice",
    "corn","yam","cassava","banana","plantain","potato","tomato","onion",
    "beans","meat","fish","egg","honey","wine","beer","tea","coffee",
    "bread","fruit","mushroom","mango","papaya","orange","lemon",
    "avocado","pineapple","coconut","cocoyam","sauce","soup",
    # animals + nature
    "dog","cat","cow","goat","sheep","pig","chicken","bird","snake",
    "lion","elephant","monkey","rat","frog","ant","bee","fly","worm",
    "fish","cock","hen","horse","spider","leopard","duck","eagle",
    "owl","crab","insect","mosquito","scorpion","python","baboon",
    "buffalo","fowl","chick","baby","puppy","kitten","calf","piglet",
    "wasp","cockroach","cricket","camel","donkey","wolf","mouse",
    "tortoise","turtle","grasshopper","worm","toad","cattle","tail",
    "wing","horn","feather","claw","beak","fur","hide",
    # nature
    "tree","leaf","flower","grass","root","sun","moon","star","sky",
    "cloud","rain","wind","fire","earth","ground","soil","sand","stone",
    "mountain","hill","river","stream","lake","sea","road","path","day",
    "night","morning","evening","year","week","month","forest","village",
    "town","cave","sunlight","moonlight","branch","seed","plant","ash",
    # common actions
    "eat","drink","sleep","walk","run","jump","sit","stand","fall","come",
    "go","see","hear","speak","say","know","take","give","make","do",
    "buy","sell","work","play","cry","laugh","sing","dance","write",
    "read","wash","cook","cut","catch","carry","drop","throw","hold",
    "open","close","lift","push","pull","kick","greet","help","love",
    "fear","want","ask","answer","look","listen","find","steal","bite",
    "smile","kill","die","live","plant","bring","fly","swim","climb",
    "build","cook","bury","bow","blow","beat","blame","bleed","bless",
    "boast","boil","born","bury","sell","buy","sit","wait","jump",
    "stand","start","stop","return",
    # colors + simple descriptive
    "red","blue","green","yellow","white","black","brown","big","small",
    "tall","short","long","good","bad","new","old","hot","cold","wet",
    "dry","clean","dirty","sweet","bitter","strong","weak","light",
    "dark","quick","slow","near","far","tasty","beautiful","ugly",
    "kind","wise","poor","rich","happy","sad","easy","hard","empty",
    "full","cheap","loud","quiet","sharp","blunt","smooth","rough",
    "alive","dead","true","false","heavy","fat","thin","round","flat",
    # numbers
    "one","two","three","four","five","six","seven","eight","nine","ten",
    "twenty","hundred","thousand","first","second","many","few","much",
    "all","none","some",
    # common things
    "house","door","window","road","bed","chair","table","cup","plate",
    "knife","spoon","pot","pan","basket","bag","box","money","stone",
    "fire","light","drum","horn","cloth","clothes","shoe","ring","cup",
    "book","letter","car","bicycle","gun","arrow","spear","axe","sword",
    "ladder","mat","needle","comb","key","lock","cup","game","song",
    "story","language","name","word","sound","picture","photo","gift",
    "rope","stick","wood","glass","color","number","letter","sign",
    "smoke","shadow","mirror","fence","gate","floor","wall","window",
    "bell","whistle","trap","arrow","mask","mat","oil",
    # time
    "today","yesterday","tomorrow","now","later","always","never",
    "often","sometimes","early","late","once","again",
    # pronouns + relations
    "i","me","my","you","your","he","she","him","her","his","hers",
    "we","us","our","they","them","this","that","here","there","who",
    "where","why","when","how","what","which",
}

# POS classes that mark function-words / specialized markers → Expert
EXPERT_POS = {
    "ideo.", "part.", "tns.", "excl.", "poss.", "prep.", "conj.", "neg.",
    "class.", "am.", "voc.", "tns mk.", "asp mk.", "comp.", "qual.",
    "dem.", "inter.", "attr.", "focused", "focused.", "foc.",
    "p.n.", "ints.", "intj.",
}

# Awing words starting with uppercase Latin = likely transliterated proper
# noun (Sînəgəgə = Synagogue, Yésə = Jesus). These slipped past prior
# filters because we kept them at diff=2 by default.
PROPER_NOUN_PATTERN = re.compile(r"^[A-Z][a-zA-Zəɛɔɨŋɣ]+$")

# Phrases in English that mark ritual / specialized / archaic content
EXPERT_GLOSS_MARKERS = re.compile(
    r"\b(ideo|particle|marker|archaic|ritual|libation|sacrifice|"
    r"associative|imperfective|perfective|tense|focused|honorific|"
    r"voc\.|prn\.|excl\.|conj\.|prep\.)",
    re.IGNORECASE,
)


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


def classify_entry(awing: str, english: str, pos: str | None, homonym: int | None) -> int:
    """Return target difficulty (1=Beg, 2=Med, 3=Exp) for this entry."""
    # ===== EXPERT checks =====
    if pos and pos.lower().strip() in EXPERT_POS:
        return 3
    if awing and PROPER_NOUN_PATTERN.match(awing):
        return 3
    if EXPERT_GLOSS_MARKERS.search(english):
        return 3
    # Awing homonym tag (multi-sense secondary meanings) → Expert
    # We DON'T have homonym in Dart literal directly — we filter via gloss
    # markers like "(2)" or "(3)" already.
    if re.search(r"\([2-9]\)", english):
        return 3
    # Glosses that are pure POS-tag explanations
    if re.search(r"^(am\.|prn\.|prep\.|conj\.|tns mk\.|tns\.|part\.)", english, re.IGNORECASE):
        return 3

    # ===== BEGINNER checks (must satisfy ALL) =====
    is_single_token = " " not in awing
    is_short_awing = len(awing) <= 9
    is_short_gloss = len(english) <= 25
    has_no_paren = "(" not in english  # no clarifying parens
    has_no_semicolon = ";" not in english  # not a multi-sense gloss
    not_compound_pos = pos in (None, "n.", "v.", "adj.", "")

    # First English word check
    first_word = re.split(r"[\s,;]", english.lower(), maxsplit=1)[0].strip(".,;:")
    is_common_word = first_word in BEGINNER_WORDS

    if (is_single_token and is_short_awing and is_short_gloss
        and has_no_paren and has_no_semicolon and not_compound_pos
        and is_common_word):
        return 1

    # ===== Otherwise MEDIUM =====
    return 2


def parse_awingword_fields(line: str):
    """Extract awing, english, pos from a one-line AwingWord literal."""
    if "AwingWord(" not in line: return None
    aw = re.search(r"awing:\s*'((?:[^'\\]|\\.)*)'", line)
    en = re.search(r"english:\s*'((?:[^'\\]|\\.)*)'", line)
    if not aw or not en: return None
    awing = aw.group(1).replace("\\'", "'")
    english = en.group(1).replace("\\'", "'")
    return awing, english


def update_difficulty_in_line(line: str, new_diff: int) -> str:
    """Set difficulty to new_diff. Add the field if missing, replace if present."""
    if "difficulty:" in line:
        return re.sub(r"difficulty:\s*\d", f"difficulty: {new_diff}", line)
    # No difficulty field — add it before the closing `),`
    # Find the last `)` of the AwingWord literal
    end = line.rfind("),")
    if end == -1:
        # Maybe just `)` no comma (last entry of list)
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

        # Extract POS hint from preceding `// dict:p.X` or other comment, or
        # from the entry itself (none — we don't store POS in Dart).
        # We'll infer from gloss patterns and english parens like "(prn.)"
        pos = None
        pos_m = re.search(r"\b(n\.|v\.|adj\.|adv\.|prn\.|prep\.|conj\.|am\.|"
                           r"voc\.|ideo\.|part\.|tns\.|excl\.|poss\.|tns mk\.|"
                           r"asp mk\.|attr\.|qual\.|class\.|dem\.|inter\.|"
                           r"c\.n\.|n\.p\.|v\.p\.|adj\.p\.)\b", english)
        if pos_m: pos = pos_m.group(1)

        # Read current difficulty
        cur_m = re.search(r"difficulty:\s*(\d)", line)
        cur = int(cur_m.group(1)) if cur_m else 1  # default in AwingWord ctor

        new_diff = classify_entry(awing, english, pos, None)

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
    after_dist = Counter()
    for line in new_src.split("\n"):
        if "AwingWord(" not in line: continue
        m = re.search(r"difficulty:\s*(\d)", line)
        if m:
            after_dist[int(m.group(1))] += 1

    print(f"\n✓ Redistribution complete")
    print(f"  Total entries: {total:,}")
    print(f"  Changed to Beginner: {changes[1]:,}")
    print(f"  Changed to Medium: {changes[2]:,}")
    print(f"  Changed to Expert: {changes[3]:,}")
    print(f"  Unchanged: {no_change:,}")
    print()
    print(f"FINAL DISTRIBUTION:")
    for d in (1, 2, 3):
        label = {1: "Beginner", 2: "Medium  ", 3: "Expert  "}[d]
        n = after_dist[d]
        pct = 100 * n / total if total else 0
        print(f"  {label}: {n:>5,} ({pct:.1f}%)")

    import json
    REPORT.parent.mkdir(exist_ok=True)
    REPORT.write_text(json.dumps({
        "total": total,
        "changes": changes,
        "no_change": no_change,
        "after_distribution": dict(after_dist),
    }, indent=2), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
