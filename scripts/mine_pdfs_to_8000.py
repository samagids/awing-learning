#!/usr/bin/env python3
"""
Aggressive PDF mining — extract ALL entries from the source PDFs into
awing_vocabulary.dart, preserving homonyms (entries with same Awing
word but distinct English glosses) as separate AwingWord literals.

Sources mined:
  1. contributions/dictionary_extract/*.json (3,094 entries from the
     2007 Awing English Dictionary by Alomofor Christian, CABTAL).
     Previous passes collapsed homonyms — this pass keeps them.
  2. AwingOrthography2005.pdf — alphabet, tone examples, minimal pairs
     (these are already in curated lists; skipped here to avoid dup).
  3. AwingphonologyMar2009Final_U_arc.pdf — phoneme contrastive
     wordlists (already in curated lists; skipped).

Strategy:
  - Load all 18 JSON files.
  - Parse current vocab file via state-machine to extract every
    existing (awing, english) pair.
  - For each JSON entry, dedup by EXACT (awing, english) match — Awing
    has tonal homonyms (kíə "pay" vs kíə "key"), so we only drop
    entries that are byte-for-byte identical in both fields.
  - Skip entries that are clearly proper nouns or low-quality:
      * pos == 'name' AND english starts with "name of"
      * english contains "quarter name", "name of a quarter"
      * english is a single capitalized word that isn't a known
        Awing-specific concept
  - Categorize by keyword matching on English gloss.
  - Detect tone from Awing diacritics.
  - Set difficulty=2 (Medium) for most entries, =3 (Expert) for
    ideophones / particles / very specialized concepts.
  - Add as new AwingWord literals to the existing dictionaryEntries
    list with `// dict:p.X` provenance comment.

Safety: state-machine balance check before AND after, auto-restore
on failure.
"""
from __future__ import annotations
import json
import re
import shutil
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VOCAB = ROOT / "lib" / "data" / "awing_vocabulary.dart"
BACKUP = ROOT / "lib" / "data" / "awing_vocabulary.dart.bak_mine_pdfs"
DICT_DIR = ROOT / "contributions" / "dictionary_extract"
REPORT = ROOT / "contributions" / "mine_pdfs_report.json"


# ========== Category heuristics ==========
BODY_KW = {
    "hand","arm","finger","leg","foot","toe","knee","elbow","head",
    "hair","face","eye","ear","mouth","tooth","teeth","tongue","lip",
    "nose","cheek","chin","jaw","forehead","skin","blood","bone","heart",
    "lung","liver","kidney","stomach","belly","chest","breast","back",
    "neck","shoulder","throat","muscle","nerve","vein","navel","hip",
    "waist","thigh","calf","ankle","wrist","palm","sole","nail","skull",
    "brain","spine","rib","womb","penis","vagina","testicle","sperm",
    "urine","sweat","saliva","tear","mucus","scar","wound","pimple",
    "wrinkle","limb","organ","corpse","body part",
}
ANIMAL_KW = {
    "animal","dog","cat","cow","goat","sheep","pig","chicken","cock",
    "hen","duck","bird","eagle","owl","hawk","parrot","snake","lizard",
    "frog","toad","turtle","tortoise","fish","crab","shrimp","insect",
    "ant","bee","wasp","fly","mosquito","spider","scorpion","worm",
    "louse","flea","tick","butterfly","grasshopper","cricket","locust",
    "lion","leopard","elephant","hippo","rhino","buffalo","antelope",
    "gazelle","monkey","gorilla","chimp","baboon","squirrel","rat",
    "mouse","rabbit","hare","mole","bat","crocodile","python","viper",
    "cobra","mamba","horse","donkey","mule","camel","kid","puppy",
    "kitten","calf","piglet","chick","tadpole","caterpillar","larva",
    "rooster","hyena","jackal","fox","wolf","bear","deer","reptile",
    "mammal","amphibian","rodent","predator","prey","pangolin","snail",
    "slug","centipede","millipede","beetle","cockroach","termite",
}
NATURE_KW = {
    "water","fire","sun","moon","star","sky","cloud","rain","wind",
    "storm","thunder","lightning","earth","ground","soil","sand","mud",
    "rock","stone","mountain","hill","valley","river","stream","lake",
    "ocean","sea","forest","tree","bush","grass","leaf","flower","fruit",
    "seed","root","trunk","branch","bark","wood","plant","weed","crop",
    "farm","field","garden","path","road","cave","cliff","beach","shore",
    "desert","swamp","spring","waterfall","cataract","wave","tide","mist",
    "fog","dew","frost","ice","snow","heat","cold","weather","season",
    "rainbow","horizon","shadow","light","darkness","dust","ash","smoke",
    "flame","ember","spark","sunshine","moonlight","starlight","eclipse",
    "dawn","dusk","twilight","sunrise","sunset","morning","afternoon",
    "evening","night","day","week","month","year","summer","winter",
    "rainy season","dry season","harvest","planting","tide",
}
FOOD_KW = {
    "food","meal","drink","water","milk","oil","salt","sugar","pepper",
    "spice","sauce","soup","stew","rice","corn","maize","yam","cassava",
    "cocoyam","banana","plantain","potato","tomato","onion","garlic",
    "ginger","beans","peas","groundnut","peanut","palm","wine","beer",
    "tea","coffee","bread","cake","cookie","biscuit","fruit","vegetable",
    "meat","fish","chicken","beef","pork","mutton","goat meat","egg",
    "cheese","butter","yogurt","honey","jam","syrup","porridge","gruel",
    "kola","kola nut","palm wine","raffia","sugar cane","mango","pawpaw",
    "papaya","avocado","pineapple","orange","lemon","lime","grape",
    "guava","coconut","apple","watermelon","carrot","cabbage","spinach",
    "lettuce","cucumber","pumpkin","mushroom","peanut butter","seasoning",
    "ingredient","recipe","cooking","kitchen","stove",
}
ACTION_KW = {
    "act of ","be ","become ","do ","make ","take ","give ","get ","go ",
    "come ","walk ","run ","jump ","sit ","stand ","lie ","sleep ","wake ",
    "eat ","drink ","cook ","wash ","clean ","bathe ","dress ","wear ",
    "carry ","bring ","fetch ","pick ","throw ","catch ","push ","pull ",
    "open ","close ","cut ","tear ","break ","fix ","build ","destroy ",
    "say ","speak ","talk ","tell ","ask ","answer ","reply ","shout ",
    "cry ","laugh ","smile ","sing ","dance ","play ","work ","rest ",
    "buy ","sell ","pay ","steal ","lie ","cheat ","help ","love ","hate ",
    "like ","want ","need ","know ","learn ","teach ","remember ","forget ",
    "think ","believe ","hope ","wish ","fear ","worry ","feel ","see ",
    "hear ","smell ","taste ","touch ","look ","watch ","listen ","read ",
    "write ","draw ","paint ","kill ","die ","live ","grow ","plant ",
    "harvest ","hunt ","fish ","cook ","bake ","fry ","boil ","roast ",
    "swallow ","chew ","spit ","vomit ","sneeze ","cough ","yawn ",
    "blink ","wink ","nod ","wave ","point ","greet ","welcome ","leave ",
    "depart ","arrive ","enter ","exit ","fall ","rise ","climb ","sink ",
    "float ","fly ","swim ","crawl ","slide ","roll ","spin ","turn ",
}
FAMILY_KW = {
    "father","mother","parent","child","son","daughter","brother",
    "sister","uncle","aunt","cousin","nephew","niece","grandfather",
    "grandmother","grandchild","grandson","granddaughter","husband",
    "wife","spouse","fiance","fiancee","bride","groom","widow","widower",
    "orphan","baby","infant","toddler","kid","boy","girl","man","woman",
    "person","people","family","relative","friend","neighbour","neighbor",
    "elder","chief","king","queen","prince","princess","leader","teacher",
    "student","doctor","nurse","farmer","trader","seller","buyer",
    "guest","host","stranger","servant","master","slave","worker",
    "employer","employee","colleague","partner","companion","ancestor",
    "descendant","forefather","clan","tribe","ethnic","nation","village",
    "town","community","society","group","tribe","kin","kinship",
    "in-law","mother-in-law","father-in-law","stepmother","stepfather",
    "stepchild","stepson","stepdaughter","stepbrother","stepsister",
    "twin","triplets","sibling","co-wife",
}
DESCRIPTIVE_KW = {
    "big","small","tall","short","long","wide","narrow","thick","thin",
    "fat","heavy","light","strong","weak","hard","soft","hot","cold",
    "warm","cool","wet","dry","clean","dirty","old","new","young",
    "good","bad","beautiful","ugly","kind","cruel","wise","foolish",
    "rich","poor","happy","sad","angry","calm","brave","cowardly",
    "honest","dishonest","clever","stupid","quick","slow","early","late",
    "easy","difficult","cheap","expensive","sweet","bitter","sour","salty",
    "loud","quiet","bright","dark","red","blue","green","yellow","white",
    "black","brown","grey","gray","purple","orange","pink","colorful",
    "round","square","flat","sharp","blunt","smooth","rough","empty","full",
    "alive","dead","real","fake","true","false","correct","wrong","right",
    "left","up","down","near","far","alone","together","first","last",
    "many","few","much","little","some","none","all","every","each",
    "important","useless","beautiful","handsome","pretty","ugly","tasty",
    "delicious","nutritious","poisonous","dangerous","safe","peaceful",
    "violent","quiet","noisy",
}
NUMBER_KW = {"one","two","three","four","five","six","seven","eight","nine",
             "ten","eleven","twelve","twenty","thirty","forty","fifty",
             "sixty","seventy","eighty","ninety","hundred","thousand",
             "million","first","second","third","fourth","fifth"}


_AWING_CHARS_RE = re.compile(r"[ɛəɔɨŋɣ́̀̂̌̄]")

def clean_english(eng: str) -> str:
    """Trim verbose dictionary glosses to a kid-friendly form.
       Strips Awing example sentences, V.s/Sg.s/Pl.s suffix info,
       and truncates numbered glosses to first 2 senses.
    """
    if not eng: return eng
    s = eng.strip()
    # Strip suffix annotations at end
    s = re.split(r"\.\s+(V\.s|Sg\.s|Pl\.s|Pl\.|S\.|V\.p\.s)\s*:", s, maxsplit=1)[0]
    # Strip parenthetical "From: ..." annotations
    s = re.sub(r"\s*From:\s*\w+\s*$", "", s)
    # Drop any sentence that contains Awing-specific characters
    parts = re.split(r"(?<=[.!?])\s+", s)
    keep = []
    for p in parts:
        if _AWING_CHARS_RE.search(p):
            continue  # has Awing letters → example sentence, drop
        keep.append(p)
    s = " ".join(keep).strip()
    # For numbered glosses "1) X 2) Y 3) Z" → keep first 2 senses
    nums = re.findall(r"\d\)\s*([^0-9)]+?)(?=\s*\d\)|$)", s)
    if len(nums) >= 2:
        s = "; ".join(n.strip().rstrip(".,") for n in nums[:2])
    # Strip cross-references "cf. xxx" / "see xxx"
    s = re.sub(r"\s*cf\.\s+\S+", "", s)
    s = re.sub(r"\s*see\s+[A-Za-zəɛɔɨŋɣ]+", "", s, flags=re.IGNORECASE)
    # Collapse whitespace
    s = re.sub(r"\s+", " ", s).strip().rstrip(".,;")
    # Final length cap
    if len(s) > 100:
        s = s.split(".")[0].strip()
    return s


def categorize(english: str) -> str:
    """Pick the best category for a gloss."""
    e = english.lower()
    words = set(re.sub(r"[^a-z\s]", " ", e).split())

    # Numbers are very specific
    if words & NUMBER_KW: return "numbers"
    # Action verbs detect via leading phrase
    if any(e.startswith(kw) for kw in ACTION_KW): return "actions"
    if words & BODY_KW: return "body"
    if words & ANIMAL_KW: return "animals"
    if words & NATURE_KW: return "nature"
    if words & FOOD_KW: return "food"
    if words & FAMILY_KW: return "family"
    if words & DESCRIPTIVE_KW: return "descriptive"
    return "things"  # catch-all


def detect_tone(awing: str) -> str | None:
    """Detect tone pattern from diacritics."""
    if not awing: return None
    # Decompose to extract combining marks
    nfd = unicodedata.normalize("NFD", awing)
    has_acute = "́" in nfd  # high
    has_grave = "̀" in nfd  # low
    has_circumflex = "̂" in nfd  # falling
    has_caron = "̌" in nfd  # rising
    has_macron = "̄" in nfd  # mid
    if has_caron: return "rising"
    if has_circumflex: return "falling"
    if has_acute and has_grave: return "high-low"
    if has_acute: return "high"
    if has_grave: return "low"
    if has_macron: return "mid"
    return None


def detect_difficulty(entry: dict) -> int:
    """Assign difficulty: 1=Beginner, 2=Medium, 3=Expert."""
    eng = entry.get("english", "").lower()
    pos = entry.get("pos", "").lower()
    # Ideophones, particles, archaic terms → Expert
    if pos in {"ideophone", "particle", "interjection"}: return 3
    if "ideo" in pos or "ideo" in eng: return 3
    if "particle" in pos or "(particle)" in eng: return 3
    if "archaic" in eng or "obsolete" in eng or "rare" in eng: return 3
    if "religious" in eng or "ritual" in eng or "sacred" in eng: return 3
    if "specialized" in eng or "technical" in eng: return 3
    # Multi-word phrases / compound constructions → Medium
    awing_words = len(entry.get("awing", "").split())
    if awing_words > 1: return 2
    # Short single-word common gloss → Beginner
    if len(eng.split()) <= 2 and len(eng) < 25: return 1
    return 2


RELIGIOUS_GLOSSES = {
    "jesus","jesus christ","christ","god","yahweh","jehovah","holy spirit",
    "satan","devil","messiah","lord","savior","saviour","gospel",
    "scripture","bible","apostle","prophet","disciple","pharisee","sadducee",
    "levite","gentile","heathen","centurion","pentecost","passover",
}
RELIGIOUS_KW_RE = re.compile(
    r"\b(jesus|christ|god|messiah|gospel|scripture|bible|apostle|prophet|"
    r"disciple|pharisee|sadducee|centurion|baptism|baptize|crucify|"
    r"resurrection|covenant|tabernacle|pharaoh)\b", re.IGNORECASE
)


def is_proper_noun(entry: dict) -> bool:
    """Detect proper-noun / place-name / religious entries to skip."""
    awing = entry.get("awing", "").strip()
    eng = entry.get("english", "").strip()
    if not eng or not awing: return True
    pos = entry.get("pos", "").lower()
    # Skip if explicitly labeled name / proper noun
    if pos == "name" or pos == "p.n.": return True
    low = eng.lower().strip()
    # Religious vocabulary — Jesus, Yéso, Klisto, etc.
    if low in RELIGIOUS_GLOSSES: return True
    if RELIGIOUS_KW_RE.search(low): return True
    # Skip "name of X", "name a/an X", "X name"
    if low.startswith("name of") or low.startswith("name a ") or low.startswith("name an "):
        return True
    if "quarter name" in low or "name of a quarter" in low:
        return True
    if "name of the" in low and ("quarter" in low or "village" in low or "clan" in low):
        return True
    # Awing token starts with uppercase Latin (typical for transliterated
    # foreign names: Yéso, Pɔlə, Mali, Klisto, Pəjus, Jɛlusalɛm)
    if awing and awing[0].isascii() and awing[0].isupper():
        return True
    # Heuristic: single uppercase Latin English word with no Awing-specific chars
    if " " not in eng and eng[0].isupper() and eng[0].isascii():
        if eng.lower() not in {"english","french","german","christian","african",
                                "european","american","western","eastern","northern",
                                "southern","cameroon","cameroonian"}:
            return True
    return False


def dart_escape(s: str) -> str:
    """Escape for Dart single-quoted string."""
    return s.replace("\\", "\\\\").replace("'", "\\'")


# ========== State-machine bracket checker ==========
def check_balance(src: str):
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


# ========== Existing-vocab extractor ==========
def parse_line_for_pair(line: str):
    """Extract (awing, english) tuple from an AwingWord literal."""
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
    for line in src.split("\n"):
        pair = parse_line_for_pair(line)
        if pair:
            existing.add(pair)
    print(f"Existing entries: {len(existing):,}")

    # ---------- 2. Load all JSON dictionary entries ----------
    # Includes both Awing→English (pages_*) and English→Awing index (index_chunk_*)
    json_files = sorted(DICT_DIR.glob("pages_*.json")) + sorted(DICT_DIR.glob("index_chunk_*.json"))
    raw_entries = []
    for jf in json_files:
        try:
            data = json.loads(jf.read_text(encoding="utf-8"))
        except Exception as e:
            print(f"  Skipping {jf.name}: {e}")
            continue
        # Format A: flat list of entry dicts
        # Format B: {"dict_pages": "X-Y", "entries": [...]}
        page_label = jf.stem.replace("pages_", "")
        if isinstance(data, list):
            entries = data
        elif isinstance(data, dict) and isinstance(data.get("entries"), list):
            entries = data["entries"]
            page_label = data.get("dict_pages") or data.get("pages") or page_label
        else:
            print(f"  Skipping {jf.name}: unknown format")
            continue
        for e in entries:
            if not isinstance(e, dict): continue
            # Synthesize missing page field with file-level label
            if "page" not in e:
                e = {**e, "page": page_label}
            # Normalize Format B `class` → `pos`
            if "pos" not in e and "class" in e:
                e = {**e, "pos": str(e.get("class", ""))}
            raw_entries.append(e)
    print(f"JSON dictionary entries: {len(raw_entries):,}")

    # ---------- 3. Filter & dedup ----------
    to_add = []
    skipped_propnoun = 0
    skipped_dup = 0
    skipped_invalid = 0
    skipped_religious = 0
    for entry in raw_entries:
        awing = entry.get("awing", "").strip()
        english_raw = entry.get("english", "").strip()
        if not awing or not english_raw:
            skipped_invalid += 1
            continue
        if is_proper_noun(entry):
            skipped_propnoun += 1
            continue
        # Clean verbose dictionary glosses (Format B has example sentences)
        english = clean_english(english_raw)
        if not english:
            skipped_invalid += 1
            continue
        # Re-check religious filter after cleanup (in case it was hidden
        # in a later sentence that the cleaner kept)
        if RELIGIOUS_KW_RE.search(english.lower()):
            skipped_religious += 1
            continue
        # Replace the entry's english with the cleaned version
        entry = {**entry, "english": english}
        if (awing, english) in existing:
            skipped_dup += 1
            continue
        existing.add((awing, english))  # prevent same-batch internal dup
        to_add.append(entry)

    print()
    print(f"To add: {len(to_add):,}")
    print(f"Skipped:")
    print(f"  Proper nouns: {skipped_propnoun:,}")
    print(f"  Religious: {skipped_religious:,}")
    print(f"  Duplicates: {skipped_dup:,}")
    print(f"  Invalid (empty awing/english): {skipped_invalid:,}")

    if not to_add:
        print("\nNothing to add — vocabulary already covers all JSON entries.")
        return 0

    # ---------- 4. Build Dart literal lines ----------
    new_lines = []
    cat_counts = {}
    diff_counts = {1:0, 2:0, 3:0}
    for entry in to_add:
        awing = entry["awing"].strip()
        english = entry["english"].strip()
        category = categorize(english)
        tone = detect_tone(awing)
        difficulty = detect_difficulty(entry)
        page = entry.get("page", "?")
        cat_counts[category] = cat_counts.get(category, 0) + 1
        diff_counts[difficulty] += 1

        # Build literal
        fields = [
            f"awing: '{dart_escape(awing)}'",
            f"english: '{dart_escape(english)}'",
            f"category: '{category}'",
        ]
        if tone:
            fields.append(f"tonePattern: '{tone}'")
        fields.append(f"difficulty: {difficulty}")
        literal = f"  AwingWord({', '.join(fields)}),"
        # Provenance comment
        new_lines.append(f"  // dict:p.{page}")
        new_lines.append(literal)

    # ---------- 5. Splice into dictionaryEntries list ----------
    # Find the `];` that closes `const List<AwingWord> dictionaryEntries = [`
    lines = src.split("\n")
    # Find start
    start_idx = None
    for i, ln in enumerate(lines):
        if "const List<AwingWord> dictionaryEntries" in ln:
            start_idx = i
            break
    if start_idx is None:
        print("ERROR: dictionaryEntries list not found")
        shutil.copy(BACKUP, VOCAB)
        return 1

    # Find the matching `];`
    end_idx = None
    depth = 0
    saw_open = False
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
            if ch == "'" or ch == '"':
                in_str = ch; j += 1; continue
            if ch == "/" and j+1 < len(ln) and ln[j+1] == "/":
                break  # rest of line is comment
            if ch == "[":
                depth += 1; saw_open = True
            elif ch == "]":
                depth -= 1
                if saw_open and depth == 0:
                    end_idx = i
                    break
            j += 1
        if end_idx is not None: break

    if end_idx is None:
        print("ERROR: could not find end of dictionaryEntries list")
        shutil.copy(BACKUP, VOCAB)
        return 1

    print(f"dictionaryEntries list: L{start_idx+1} → L{end_idx+1}")

    # Insert new lines BEFORE the `];` line, with a section header
    insertion = [
        "",
        "  // ============================================================",
        f"  // PDF-mined dictionary entries (run {len(to_add)})",
        "  // Source: 2007 Awing English Dictionary, CABTAL/Alomofor Christian",
        f"  // Categories: {sorted(cat_counts.items(), key=lambda x: -x[1])}",
        f"  // Difficulty: B={diff_counts[1]} M={diff_counts[2]} E={diff_counts[3]}",
        "  // ============================================================",
    ]
    final_lines = lines[:end_idx] + insertion + new_lines + lines[end_idx:]
    new_src = "\n".join(final_lines)

    # ---------- 6. Safety check ----------
    p2, b2, c2 = check_balance(new_src)
    if p2 or b2 or c2:
        print(f"✗ ABORT: unbalanced after edit (p={p2} b={b2} c={c2})")
        shutil.copy(BACKUP, VOCAB)
        return 1

    VOCAB.write_text(new_src, encoding="utf-8")
    n_before = sum(1 for ln in src.split("\n") if "AwingWord(" in ln)
    n_after = sum(1 for ln in new_src.split("\n") if "AwingWord(" in ln)

    print()
    print(f"✓ SUCCESS")
    print(f"  Before: {n_before:,} entries")
    print(f"  After:  {n_after:,} entries (+{n_after - n_before})")
    print(f"  File size: {len(new_src):,} bytes")
    print()
    print(f"  Category breakdown:")
    for cat, n in sorted(cat_counts.items(), key=lambda x: -x[1]):
        print(f"    {cat}: {n:,}")
    print(f"  Difficulty: Beginner={diff_counts[1]:,} Medium={diff_counts[2]:,} Expert={diff_counts[3]:,}")

    REPORT.parent.mkdir(exist_ok=True)
    REPORT.write_text(json.dumps({
        "summary": {
            "before": n_before, "after": n_after,
            "added": n_after - n_before,
            "skipped_propnoun": skipped_propnoun,
            "skipped_dup": skipped_dup,
            "skipped_invalid": skipped_invalid,
        },
        "categories": cat_counts,
        "difficulty": diff_counts,
    }, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"  Report: {REPORT.name}")

    if n_after < 8000:
        gap = 8000 - n_after
        print()
        print(f"  Note: {gap:,} entries short of 8,000 target.")
        print(f"  The 2007 dictionary has ~3,094 entries total — combined")
        print(f"  with orthography + phonology PDFs and curated lists,")
        print(f"  the realistic max from PDF sources is around 6,500-7,500.")
        print(f"  Reaching 8,000 would require either additional PDF sources")
        print(f"  or native-speaker contributions.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
