#!/usr/bin/env python3
"""
v2: Add vocabulary using EXACT-match dedup (preserves tone variants).

Lesson from v1: stripping tone diacritics for dedup collapses legitimate
Awing tonal pairs (lá/là, kɔ/kɔ́, etc.). Awing IS tonal — each variant
is a distinct word. v2 uses lowercase-only matching, keeps tones.

Also: lower Bible freq threshold to 1 to maximize legitimate additions.
"""
from __future__ import annotations
import json
import re
import shutil
import unicodedata
import glob
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VOCAB = ROOT / "lib" / "data" / "awing_vocabulary.dart"
BACKUP = ROOT / "lib" / "data" / "awing_vocabulary.dart.bak_addvocab_v2"
REPORT = ROOT / "contributions" / "add_vocab_v2_report.json"
PARALLEL = ROOT / "corpus" / "parallel" / "nt_aligned.json"
DICT_DIR = ROOT / "contributions" / "dictionary_extract"

RELIGIOUS_GLOSSES = {
    "god","gods","lord","lords","christ","jesus","messiah","spirit","holy",
    "heaven","heavens","hell","kingdom","sin","sins","sinner","saved",
    "savior","saviour","salvation","demon","demons","satan","devil",
    "beelzebub","disciple","disciples","apostle","apostles","prophet",
    "prophets","angel","angels","archangel","cherub","scripture","scriptures",
    "gospel","covenant","amen","hallelujah","hosanna","parable","pharisee",
    "pharisees","sadducee","sadducees","priest","priests","levite","levites",
    "gentile","gentiles","jew","jews","heathen","heathens","synagogue",
    "tabernacle","passover","pentecost","sabbath","sabbaths","altar",
    "sacrifice","righteous","righteousness","unrighteous","wicked","godly",
    "blameless","blasphemy","preach","worship","worshiped","praying",
    "prayed","prayer","blessed","crucify","crucified","resurrection",
    "baptize","baptized","anoint","anointed","forgive","forgiven","centurion",
    "woe","tribulation","scourge","betray","betrayed","circumcise",
    "circumcision","redeemer","redeemed","atone","atonement",
}
PROPER_NOUN_GLOSSES = {
    "abraham","isaac","jacob","moses","aaron","david","solomon","elijah",
    "isaiah","daniel","jeremiah","ezekiel","jonah","mary","joseph","peter",
    "paul","john","james","matthew","mark","luke","timothy","titus","silas",
    "barnabas","stephen","ananias","cornelius","caiaphas","herod","caesar",
    "pilate","felix","festus","agrippa","jerusalem","judea","samaria",
    "galilee","nazareth","bethlehem","egypt","rome","corinth","ephesus",
    "athens","babylon","sodom","gomorrah","damascus","antioch","philippi",
    "thessalonica","berea","tyre","sidon","tarsus","macedonia","achaia",
    "cilicia","galatia","cappadocia","pontus","bithynia","mysia","troas",
    "miletus","rhodes","cyprus","crete","malta","syracuse","attalia","perga",
    "derbe","lystra","iconium","colosse","laodicea","sardis","pergamum",
    "smyrna","thyatira","philadelphia","israel","jacinth","jasper","amethyst",
    "topaz","beryl","onyx","chalcedony","carnelian","sardonyx","chrysolite",
    "chrysoprase","emerald","sapphire","ruby","sardius","abba","selah",
    "alleluia","maranatha","gehenna","hades","sheol",
}


def parse_line(line: str):
    """Extract awing from single-line AwingWord literal."""
    if "AwingWord(" not in line: return None
    start = line.find("AwingWord(") + len("AwingWord(")
    pos = start
    while pos < len(line) and line[pos] in " \t": pos += 1
    if not line[pos:].startswith("awing"): return None
    while pos < len(line) and line[pos] not in ":": pos += 1
    pos += 1
    while pos < len(line) and line[pos] in " \t": pos += 1
    if pos >= len(line) or line[pos] not in ("'", '"'): return None
    quote = line[pos]; pos += 1
    out = []
    while pos < len(line):
        c = line[pos]
        if c == "\\" and pos+1 < len(line):
            out.append(line[pos+1]); pos += 2; continue
        if c == quote: return "".join(out)
        out.append(c); pos += 1
    return None


def check_balance(src: str):
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


CAT_KW = {
    "actions": {"go","walk","eat","drink","sleep","sit","stand","speak","tell",
                "cry","laugh","wash","cook","help","work","play","read","write",
                "sing","dance","build","carry","give","send","throw","catch",
                "fall","rise","wait","listen","buy","sell","find","love","hate",
                "like","want","need","touch","push","pull","open","close",
                "break","answer","ask","follow","gather","greet","heal","hold",
                "jump","leave","lift","plant","remember","return","save",
                "serve","show","stop","swim","teach","wake","weep","run",
                "reach","smile","clap","wave","kill","ate","drank","slept",
                "sat","stood","spoke","told","cried","laughed","cooked","helped",
                "worked","played","sang","danced","built","carried","gave",
                "sent","threw","caught","fell","rose","waited","listened",
                "bought","sold","found","loved","wanted","needed","touched",
                "pushed","pulled","opened","closed","broke","answered","asked",
                "followed","gathered","greeted","healed","held","jumped",
                "left","lifted","planted","remembered","returned","saved",
                "served","showed","stopped","swam","taught","woke","wept",
                "ran","reached","smiled","clapped","waved","killed","forget",
                "forgot","know","knew","hear","heard","see","saw","look",
                "watch","watched","feel","felt","said"},
    "body": {"head","hand","hands","foot","feet","eye","eyes","ear","ears",
             "mouth","tooth","teeth","tongue","tongues","hair","skin","finger",
             "fingers","nose","face","arm","arms","leg","legs","heart","knee",
             "elbow","cheek","throat","chest","shoulder","stomach","neck",
             "back","forehead","chin","scalp","navel","liver","womb","kidney",
             "intestine","bone","bones","muscle","nail","palm","wrist","ankle",
             "jaw","lip","lips","breast","spine","rib","fingernail","toenail",
             "skull"},
    "animals": {"dog","dogs","cat","cats","cow","cows","goat","goats","sheep",
                "pig","chicken","bird","birds","fish","snake","snakes","lion",
                "elephant","horse","donkey","camel","frog","rat","mouse",
                "spider","ant","bee","butterfly","worm","scorpion","calf",
                "lamb","ox","oxen","hen","rooster","cock","eagle","dove",
                "beast","cattle","sparrow","snail","fox","bear","wolf","owl",
                "duck","goose","hawk","raven","tortoise","insect","mosquito"},
    "nature": {"water","fire","sun","moon","star","stars","sky","cloud",
               "clouds","rain","wind","earth","stone","stones","rock","rocks",
               "mountain","mountains","river","rivers","sea","seas","lake",
               "lakes","tree","trees","leaf","leaves","flower","flowers",
               "fruit","seed","grass","sand","forest","valley","road","path",
               "field","fields","garden","ground","soil","dust","cave","stream",
               "wave","mud","ocean","shore","hill","hills","wilderness",
               "desert","darkness","light","lightning","thunder","storm",
               "shadow","heat","fog","ice","snow","frost","mist","dew",
               "sunshine","moonlight","sunrise","sunset","dawn","spring",
               "summer","autumn","winter","reed","bush","branch","root",
               "wood","plant","plants"},
    "food": {"food","meal","bread","loaves","meat","milk","wine","honey","salt",
             "sugar","oil","corn","rice","beans","banana","mango","orange",
             "vegetable","egg","eggs","soup","drink","fruit","apple","grain",
             "grape","fig","yam","cassava","sauce","pepper","feast","dinner",
             "supper","cheese","butter"},
    "family": {"mother","father","sister","wife","husband","son","daughter",
               "child","children","baby","cousin","aunt","uncle","friend",
               "friends","family","neighbor","grandfather","grandmother",
               "king","queen","servant","master","leader","elder","boy","girl",
               "villager","relative","brother","brothers","sisters"},
    "descriptive": {"big","small","tall","short","fat","thin","good","bad",
                    "beautiful","strong","weak","new","old","young","happy",
                    "sad","angry","tired","sick","well","cold","hot","wet",
                    "dry","clean","dirty","fast","slow","quiet","loud",
                    "bright","dark","heavy","light","empty","full","sharp",
                    "soft","hard","sweet","sour","bitter","white","black",
                    "red","green","blue","yellow","brave","kind","gentle",
                    "afraid","brown","grey","gray","orange","near","far",
                    "high","low","wide","narrow","first","last","early","late",
                    "easy","more","less","precious","valuable","rich","poor",
                    "wealthy","ripe","unripe","fresh","stale","ancient","modern"},
    "numbers": {"one","two","three","four","five","six","seven","eight","nine",
                "ten","eleven","twelve","thirteen","fourteen","fifteen",
                "sixteen","seventeen","eighteen","nineteen","twenty","thirty",
                "forty","fifty","sixty","seventy","eighty","ninety","hundred",
                "thousand","million","first","second","third","fourth","fifth",
                "sixth","seventh","eighth","ninth","tenth","many","few","several",
                "half","whole","double","triple","dozen","score"},
    "pronouns": {"who","what","where","when","why","how","which","myself",
                 "himself","herself","themselves","yourself","ourselves","each",
                 "every","whoever","anyone","everyone","nobody","someone",
                 "something","whatever","i","you","he","she","it","we","they",
                 "me","him","her","us","them","this","that","these","those",
                 "mine","yours","his","hers","ours","theirs"},
}


def guess_category(en: str) -> str:
    cleaned = re.sub(r"[^a-zA-Z\s]", " ", en.lower())
    words = set(cleaned.split())
    if not words: return "things"
    for cat, kws in CAT_KW.items():
        if words & kws: return cat
    return "things"


def dart_str(s: str) -> str:
    if "'" not in s and '"' not in s:
        return f"'{s}'"
    if '"' not in s:
        return '"' + s.replace("\\", "\\\\") + '"'
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'") + "'"


def main():
    src = VOCAB.read_text(encoding="utf-8")
    p, b, c = check_balance(src)
    if p or b or c:
        print(f"ERROR: unbalanced (p={p} b={b} c={c})")
        return 1

    shutil.copy(VOCAB, BACKUP)
    print(f"Backup: {BACKUP.name}")

    # KEY CHANGE: exact match (lowercase only, tones preserved)
    current = set()
    for line in src.split("\n"):
        aw = parse_line(line)
        if aw:
            current.add(aw.lower())
    print(f"Current unique awing forms (case-insensitive): {len(current):,}")

    # Source 1: dictionary entries (EXACT match)
    dict_entries = []
    for f in sorted(glob.glob(str(DICT_DIR / "*.json"))):
        data = json.load(open(f, encoding="utf-8"))
        if isinstance(data, list):
            dict_entries.extend(data)
        elif isinstance(data, dict) and "entries" in data:
            dict_entries.extend(data["entries"])

    new_dict = []
    for e in dict_entries:
        aw = e.get("awing", "").strip()
        en = e.get("english", "").strip()
        if not aw or not en: continue
        if aw.lower() in current: continue
        en_lower = en.lower()
        en_words = set(re.sub(r"[^a-zA-Z\s]", " ", en_lower).split())
        if en_words and en_words.issubset(RELIGIOUS_GLOSSES | PROPER_NOUN_GLOSSES):
            continue
        new_dict.append({"aw": aw, "en": en, "page": e.get("page", "?")})
        current.add(aw.lower())
    print(f"Dictionary entries to add: {len(new_dict):,}")

    # Source 2: Bible NT — drop tone-normalization, freq≥1
    verses = json.load(open(PARALLEL, encoding="utf-8"))
    bible_freq = Counter()
    bible_co = defaultdict(Counter)
    bible_ex = {}

    eng_stop = {"the","a","an","is","are","was","were","be","been","being",
                "to","of","in","on","at","by","for","with","from","as",
                "and","or","but","not","no","yes","i","you","he","she",
                "it","we","they","him","her","them","us","me","my","your",
                "his","their","our","this","that","these","those","have",
                "has","had","do","does","did","will","would","shall","should",
                "may","might","can","could","must","if","when","while",
                "what","which","who","whom","where","why","how","there",
                "here","now","then","very","so","also","just","only","one",
                "two","three","into","out","up","down","over","under",
                "through","more","like","than","such","said","came","come",
                "went","made","take","took","give","gave","get","got"}

    def en_content(s):
        cleaned = re.sub(r"[^a-zA-Z\s]", " ", s.lower())
        return {w for w in cleaned.split() if w not in eng_stop and len(w) > 2}

    for v in verses:
        toks = set()
        for tok in re.split(r"[\s.,!?;:\"\(\)\[\]…—–'']+", v["awing"]):
            if tok and len(tok) >= 2 and not any(c.isdigit() for c in tok):
                toks.add(tok)
        eng_words = en_content(v["english"])
        for tok in toks:
            if tok.lower() in current: continue
            bible_freq[tok] += 1
            if tok not in bible_ex:
                bible_ex[tok] = v["ref"]
            for ew in eng_words:
                if ew in RELIGIOUS_GLOSSES or ew in PROPER_NOUN_GLOSSES:
                    continue
                bible_co[tok][ew] += 1

    # Add Bible candidates that have at least one non-religious gloss candidate
    bible_new = []
    for tok, freq in bible_freq.most_common():
        if not bible_co[tok]: continue
        top_gloss, _ = bible_co[tok].most_common(1)[0]
        bible_new.append({
            "aw": tok,
            "en": top_gloss,
            "freq": freq,
            "ref": bible_ex[tok],
        })
        current.add(tok.lower())
    print(f"Bible entries to add (freq≥1): {len(bible_new):,}")

    print(f"\nTotal new: {len(new_dict) + len(bible_new):,}")

    # Build block
    block_lines = ["",
        "  // ====================================================================",
        "  // v2 vocab additions — tone-variant-preserving (exact-match dedup).",
        "  // Bible additions at freq≥1 (any occurrence) per Dr. Sama 8,000+ goal.",
        "  // ====================================================================",
        ""]
    block_lines.append("  // ---- From 2007 Awing English Dictionary (v2 exact-match) ----")
    for e in new_dict:
        cat = guess_category(e["en"])
        en = e["en"][:97] + "..." if len(e["en"]) > 100 else e["en"]
        block_lines.append(
            f"  // dict:p.{e['page']}\n"
            f"  AwingWord(awing: {dart_str(e['aw'])}, english: {dart_str(en)}, "
            f"category: '{cat}', difficulty: 2),"
        )
    block_lines.append("")
    block_lines.append("  // ---- From Bible NT corpus (freq≥1, auto-glossed) ----")
    for c in bible_new:
        cat = guess_category(c["en"])
        review = " // needs review" if c["freq"] == 1 else ""
        block_lines.append(
            f"  // bible:{c['ref']}, freq={c['freq']}{review}\n"
            f"  AwingWord(awing: {dart_str(c['aw'])}, english: {dart_str(c['en'])}, "
            f"category: '{cat}', difficulty: 3),"
        )

    block = "\n".join(block_lines) + "\n"

    # Insert before closing ];
    m = re.search(r"(const|final)\s+List<AwingWord>\s+dictionaryEntries\s*=\s*\[", src)
    if not m:
        print("ERROR: dictionaryEntries not found")
        return 1
    depth = 0
    i = m.end() - 1
    end_pos = None
    while i < len(src):
        ch = src[i]
        if ch == "[": depth += 1
        elif ch == "]":
            depth -= 1
            if depth == 0: end_pos = i; break
        i += 1
    if end_pos is None:
        print("ERROR: closing ] not found")
        return 1

    new_src = src[:end_pos] + block + src[end_pos:]
    new_src = new_src.rstrip("\x00 \t\r\n") + "\n"

    p2, b2, c2 = check_balance(new_src)
    if p2 or b2 or c2:
        print(f"✗ ABORT: unbalanced (p={p2} b={b2} c={c2})")
        shutil.copy(BACKUP, VOCAB)
        return 1

    VOCAB.write_text(new_src, encoding="utf-8")
    n_before = sum(1 for ln in src.split("\n") if "AwingWord(" in ln)
    n_after = sum(1 for ln in new_src.split("\n") if "AwingWord(" in ln)
    print(f"\n✓ SUCCESS")
    print(f"  Before: {n_before:,}")
    print(f"  After:  {n_after:,} (+{n_after - n_before})")
    print(f"  Bytes: {len(new_src):,}")

    REPORT.parent.mkdir(exist_ok=True)
    REPORT.write_text(json.dumps({
        "summary": {
            "before": n_before,
            "after": n_after,
            "added": n_after - n_before,
            "dictionary_added": len(new_dict),
            "bible_added": len(bible_new),
        },
    }, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"  Report: {REPORT.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
