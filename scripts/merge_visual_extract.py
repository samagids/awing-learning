#!/usr/bin/env python3
"""
Merge visual-extracted English-Awing index entries into the main vocab.

Reads contributions/visual_extract/page_*.json (all pages transcribed
via Claude vision from PDF pages 143-198), dedups against existing
vocab, categorizes, and appends to dictionaryEntries.

Run AFTER all visual transcription pages are complete.
"""
from __future__ import annotations
import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VOCAB = ROOT / "lib" / "data" / "awing_vocabulary.dart"
BACKUP = ROOT / "lib" / "data" / "awing_vocabulary.dart.bak_visual_merge"
EXTRACT_DIR = ROOT / "contributions" / "visual_extract"
REPORT = ROOT / "contributions" / "visual_merge_report.json"


# Reuse categorizer
BODY_KW = {"hand","arm","finger","leg","foot","toe","knee","elbow","head","hair","face","eye","ear","mouth","tooth","tongue","lip","nose","chin","jaw","forehead","skin","blood","bone","heart","stomach","belly","chest","breast","back","neck","throat","navel","hip","waist","thigh","calf","ankle","wrist","palm","sole","nail","skull","brain","spine","rib","womb","penis","vagina","urine","sweat","saliva","tear","mucus","scar","wound","corpse","body part","bladder","kidney","liver","lung","muscle","nerve","vein","beard","sole","ashes","abdomen"}
ANIMAL_KW = {"animal","dog","cat","cow","goat","sheep","pig","chicken","cock","hen","duck","bird","eagle","owl","hawk","parrot","snake","lizard","frog","toad","turtle","tortoise","fish","crab","shrimp","insect","ant","bee","wasp","fly","mosquito","spider","scorpion","worm","louse","flea","tick","butterfly","grasshopper","cricket","locust","lion","leopard","elephant","hippo","rhino","buffalo","antelope","gazelle","monkey","gorilla","chimp","baboon","squirrel","rat","mouse","rabbit","hare","mole","bat","crocodile","python","viper","cobra","horse","donkey","mule","camel","kid","puppy","kitten","calf","piglet","chick","tadpole","caterpillar","larva","rooster","hyena","jackal","fox","wolf","deer","reptile","mammal","amphibian","rodent","predator","prey","pangolin","snail","slug","centipede","millipede","beetle","cockroach","termite","boar","bull"}
NATURE_KW = {"water","fire","sun","moon","star","sky","cloud","rain","wind","storm","thunder","lightning","earth","ground","soil","sand","mud","rock","stone","mountain","hill","valley","river","stream","lake","ocean","sea","forest","tree","bush","grass","leaf","flower","fruit","seed","root","trunk","branch","bark","wood","plant","weed","crop","farm","field","garden","path","road","cave","cliff","beach","shore","desert","swamp","spring","waterfall","wave","tide","mist","fog","dew","frost","ice","snow","heat","cold","weather","season","rainbow","horizon","shadow","light","darkness","dust","ash","smoke","flame","ember","spark","sunshine","moonlight","eclipse","dawn","dusk","twilight","sunrise","sunset","morning","afternoon","evening","night","day","week","month","year","brook","baobab"}
FOOD_KW = {"food","meal","drink","milk","oil","salt","sugar","pepper","spice","sauce","soup","stew","rice","corn","maize","yam","cassava","cocoyam","banana","plantain","potato","tomato","onion","garlic","ginger","beans","peas","groundnut","peanut","wine","beer","tea","coffee","bread","cake","cookie","biscuit","fruit","vegetable","meat","fish","chicken","beef","pork","mutton","egg","cheese","butter","yogurt","honey","jam","syrup","porridge","gruel","kola","palm","mango","pawpaw","papaya","avocado","pineapple","orange","lemon","lime","grape","guava","coconut","apple","watermelon","carrot","cabbage","spinach","lettuce","cucumber","pumpkin","mushroom","beans"}
ACTION_KW = {"act of ","be ","become ","do ","make ","take ","give ","get ","go ","come ","walk ","run ","jump ","sit ","stand ","lie ","sleep ","wake ","eat ","drink ","cook ","wash ","clean ","bathe ","dress ","wear ","carry ","bring ","fetch ","pick ","throw ","catch ","push ","pull ","open ","close ","cut ","tear ","break ","fix ","build ","destroy ","say ","speak ","talk ","tell ","ask ","answer ","reply ","shout ","cry ","laugh ","smile ","sing ","dance ","play ","work ","rest ","buy ","sell ","pay ","steal ","help ","love ","hate ","like ","want ","need ","know ","learn ","teach ","remember ","forget ","think ","believe ","hope ","wish ","fear ","worry ","feel ","see ","hear ","smell ","taste ","touch ","look ","watch ","listen ","read ","write ","draw ","paint ","kill ","die ","live ","grow ","plant ","harvest ","hunt ","fish ","cook ","bake ","fry ","boil ","roast ","swallow ","chew ","spit ","vomit ","sneeze ","cough ","yawn ","blink ","wink ","nod ","wave ","point ","greet ","welcome ","leave ","depart ","arrive ","enter ","exit ","fall ","rise ","climb ","sink ","float ","fly ","swim ","crawl ","slide ","roll ","spin ","turn ","blow ","beat","bend","burn","bury","borrow","accept","accuse","accompany","admire","advise","announce","annoy","appear","apply","approach","argue","arrange","arrive","ask","assemble","attempt","avoid","babble","bake","bathe","blame","bleed","bless","blink","blow","boast","boil","bow","brag","braid","break","breathe","bribe","bring","build","blunt"}
FAMILY_KW = {"father","mother","parent","child","son","daughter","brother","sister","uncle","aunt","cousin","nephew","niece","grandfather","grandmother","grandchild","husband","wife","spouse","bride","groom","widow","widower","orphan","baby","infant","kid","boy","girl","man","woman","person","people","family","relative","friend","neighbour","neighbor","elder","chief","king","queen","leader","teacher","student","doctor","nurse","farmer","trader","guest","host","stranger","servant","master","worker","ancestor","forefather","clan","tribe","village","town","community","kin","in-law","stepmother","twin","sibling","barber","beggar","butcher","bachelor","ancestors","bachelor"}
DESCRIPTIVE_KW = {"big","small","tall","short","long","wide","narrow","thick","thin","fat","heavy","light","strong","weak","hard","soft","hot","cold","warm","cool","wet","dry","clean","dirty","old","new","young","good","bad","beautiful","ugly","kind","cruel","wise","foolish","rich","poor","happy","sad","angry","calm","brave","cowardly","honest","clever","stupid","quick","slow","early","late","easy","difficult","cheap","expensive","sweet","bitter","sour","salty","loud","quiet","bright","dark","red","blue","green","yellow","white","black","brown","grey","gray","purple","orange","pink","round","square","flat","sharp","blunt","smooth","rough","empty","full","alive","dead","real","fake","true","false","correct","wrong","right","left","up","down","near","far","alone","together","first","last","many","few","much","little","some","none","all","every","each","important","useless","beautiful","handsome","pretty","ugly","tasty","delicious","poisonous","dangerous","safe","peaceful","violent","quiet","noisy","bony","bold","blind"}
NUMBER_KW = {"one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve","twenty","thirty","forty","fifty","sixty","seventy","eighty","ninety","hundred","thousand","million","first","second","third","fourth","fifth"}


def categorize(english: str) -> str:
    e = english.lower()
    words = set(re.sub(r"[^a-z\s]", " ", e).split())
    if words & NUMBER_KW: return "numbers"
    if any(e.startswith(kw) for kw in ACTION_KW): return "actions"
    if words & BODY_KW: return "body"
    if words & ANIMAL_KW: return "animals"
    if words & NATURE_KW: return "nature"
    if words & FOOD_KW: return "food"
    if words & FAMILY_KW: return "family"
    if words & DESCRIPTIVE_KW: return "descriptive"
    return "things"


def detect_tone(awing: str) -> str | None:
    import unicodedata
    if not awing: return None
    nfd = unicodedata.normalize("NFD", awing)
    if "̌" in nfd: return "rising"
    if "̂" in nfd: return "falling"
    if "́" in nfd and "̀" in nfd: return "high-low"
    if "́" in nfd: return "high"
    if "̀" in nfd: return "low"
    if "̄" in nfd: return "mid"
    return None


def dart_escape(s):
    return s.replace("\\", "\\\\").replace("'", "\\'")


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


def parse_line_for_pair(line):
    if "AwingWord(" not in line: return None
    m_aw = re.search(r"awing:\s*'([^']*(?:\\.[^']*)*)'", line)
    m_en = re.search(r"english:\s*'([^']*(?:\\.[^']*)*)'", line)
    if m_aw and m_en:
        return (m_aw.group(1).replace("\\'", "'"),
                m_en.group(1).replace("\\'", "'"))
    return None


def main():
    src = VOCAB.read_text(encoding="utf-8")
    p, b, c = check_balance(src)
    if p or b or c:
        print(f"ERROR: vocab unbalanced (p={p} b={b} c={c})")
        return 1

    shutil.copy(VOCAB, BACKUP)
    print(f"Backup: {BACKUP.name}")

    # Existing pairs (exact match dedup)
    existing = set()
    for line in src.split("\n"):
        pair = parse_line_for_pair(line)
        if pair:
            existing.add(pair)
    print(f"Existing entries: {len(existing):,}")

    # Load all visual_extract page_*.json
    page_files = sorted(EXTRACT_DIR.glob("page_*.json"))
    print(f"Visual extract files: {len(page_files)}")
    raw_entries = []
    for pf in page_files:
        data = json.loads(pf.read_text(encoding="utf-8"))
        for e in data.get("entries", []):
            raw_entries.append({**e, "_pdf_page": data.get("pdf_page")})
    print(f"Raw visual entries: {len(raw_entries):,}")

    # Filter + categorize
    to_add = []
    skipped = 0
    seen_local = set()
    for e in raw_entries:
        awing = (e.get("awing") or "").strip()
        english = (e.get("english") or "").strip()
        if not awing or not english:
            skipped += 1
            continue
        # Clean english: strip "be ~" form, remove parentheticals at end
        en_clean = re.sub(r",?\s*be\s*~\s*", "", english).strip()
        en_clean = en_clean.rstrip(".,;")
        # Skip if pair exact-match in existing
        key = (awing, en_clean)
        if key in existing or key in seen_local:
            skipped += 1
            continue
        seen_local.add(key)

        category = categorize(en_clean)
        tone = detect_tone(awing)
        page = e.get("_pdf_page", "?")
        to_add.append({
            "awing": awing,
            "english": en_clean,
            "category": category,
            "tone": tone,
            "page": page,
        })

    print(f"To add: {len(to_add):,}")
    print(f"Skipped: {skipped:,}")

    if not to_add:
        print("Nothing new to add.")
        return 0

    # Build new lines + splice
    cat_counts = {}
    new_lines = []
    for e in to_add:
        cat_counts[e["category"]] = cat_counts.get(e["category"], 0) + 1
        fields = [
            f"awing: '{dart_escape(e['awing'])}'",
            f"english: '{dart_escape(e['english'])}'",
            f"category: '{e['category']}'",
        ]
        if e["tone"]:
            fields.append(f"tonePattern: '{e['tone']}'")
        fields.append("difficulty: 2")
        new_lines.append(f"  // index:p.{e['page']}")
        new_lines.append(f"  AwingWord({', '.join(fields)}),")

    lines = src.split("\n")
    # Find end of dictionaryEntries
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
        f"  // English-Awing index visual extraction ({len(to_add):,} entries)",
        "  // Source: 2007 Awing English Dictionary, CABTAL, pages 143-198",
        "  // Method: Claude vision PDF read at 300 DPI, manual transcription",
        f"  // Categories: {sorted(cat_counts.items(), key=lambda x: -x[1])}",
        "  // ============================================================",
    ]
    final = lines[:end_idx] + insertion + new_lines + lines[end_idx:]
    new_src = "\n".join(final)

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
    print(f"  Categories:")
    for cat, n in sorted(cat_counts.items(), key=lambda x: -x[1]):
        print(f"    {cat}: {n:,}")

    REPORT.parent.mkdir(exist_ok=True)
    REPORT.write_text(json.dumps({
        "before": n_before, "after": n_after, "added": n_after - n_before,
        "categories": cat_counts, "skipped": skipped,
    }, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"  Report: {REPORT.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
