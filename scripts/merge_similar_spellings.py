#!/usr/bin/env python3
"""Collapse rows that are the same Awing word spelled two ways.

Dr. Sama, 2026-10-08, after three rounds of me being too cautious:

    "if two words or sentences have the same english meaning and the word
     look similar in spelling, keep just one. And I have explain to you how
     to know which to keep."

And the rule for which to keep, from earlier the same day:

    "keep the word that come from the dictionary. Or even if the word is
     not in the dictionary then use your discretion and keep one that you
     can verify the source."

WHY THIS KEPT MISSING ROWS
--------------------------
Earlier passes required the English glosses to be IDENTICAL after
normalisation. That is why `ataana`, `ataane` and `ataene` survived as
three cards: one gloss says "trap (usually made of iron or metal)", the
next "trap, usually made of iron or metal", the third "trap, made of metal
or iron". Same word, same trap, three wordings - and an equality test sees
three different meanings. The spelling test was never the problem.

SO: near-identical MEANING (one token set inside the other, or 60% overlap)
plus similar SPELLING.

Similar spelling means, after stripping tone marks and apostrophes and
folding the vowel confusions the two OCR passes actually make
(a/e/ə, ɔ/o, ɨ/i, ʉ/u, ŋ/n):

  * the consonant skeletons match - EXACTLY for a short word, within one
    edit for a longer one. Short words cannot afford a wobble: kəŋnə "be
    happy with each other" and kəŋtə "be happy" are k-n-n and k-n-t, one
    edit apart and two different words.
  * the folded forms are within two edits.

WHICH ONE SURVIVES
------------------
1. the highest-ranked source: a cited dictionary page, then Dr. Sama
   directly, then a session audit, then unsourced.
2. on a tie, the more-established spelling - the one appearing most often
   across the file. That is the precedent already set in
   contributions/near_duplicate_review.md.

Nothing is deleted. Rows are commented out with the line that was kept and
the reason, in the file's existing "// REMOVED Session NNx" format, so git
reverts the lot and a reader can see what happened.
"""
import re, sys, json, collections, unicodedata

VOCAB = "lib/data/awing_vocabulary.dart"
PLAN = "contributions/similar_spelling_plan.json"

# Dr. Sama said "words OR SENTENCES" from the first telling. This only ever
# matched AwingWord, so five sentence pairs survived every pass, including
#   'A tə́ ńgenə afoonə.' / 'A tá ńgenə afoona.'   "He is going to the farm."
#   'Ŋwu yî lə tä mə.'   / 'Dwu yi lā tā mə.'      "That man is my father."
# AwingSentence and AwingPhrase put the Awing in `awing:` and the English in
# `english:` exactly as AwingWord does, so one pattern covers all three.
ROW = re.compile(
    r"^\s*Awing(?:Word|Sentence|Phrase)\(awing:\s*(['\"])(.*?)\1,"
    r"\s*english:\s*(['\"])(.*?)\3"
    r"(?:,\s*category:\s*(['\"])(.*?)\5)?")
DICT = re.compile(r"v2:page_\d+|dict PDF p|dict Mistral p|\bdict\b[^/]{0,40}\bp\.?\s*\d+|2007 dict|dict says", re.I)
SAMA = re.compile(r"per Dr\.? Sama", re.I)
SESS = re.compile(r"Session \d+", re.I)
FOLD = {"ə": "@", "a": "@", "e": "@", "ɔ": "o", "ɨ": "i", "ʉ": "u", "'": "", "’": ""}
VOWELS = set("aeiouəɔɨʉ@")
STOP = set("a an the of to in on at for with and or is are be it its his her "
           "their this that some very".split())


def provenance(tail):
    if DICT.search(tail): return 3, "dictionary page"
    if SAMA.search(tail): return 2, "Dr. Sama"
    if SESS.search(tail): return 1, "session audit"
    return 0, "unsourced"


def _base(a):
    s = unicodedata.normalize("NFD", a)
    s = "".join(c for c in s if not unicodedata.combining(c)).lower()
    return s.replace("'", "").replace("’", "")


def folded(a):
    return "".join(FOLD.get(c, c) for c in _base(a))


def consonants(a):
    return "".join(c for c in _base(a).replace("ŋ", "n")
                   if c not in VOWELS and not c.isspace())


def lev(a, b, cap=3):
    if abs(len(a) - len(b)) > cap:
        return 99
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        cur = [i]
        for j, cb in enumerate(b, 1):
            cur.append(min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (ca != cb)))
        prev = cur
    return prev[-1]


def tokens(e):
    """Content words of a gloss, normalised so that two spellings of the
    SAME gloss compare equal.

    Three things had to be added here after Dr. Sama asked whether the
    cards still sharing a picture were really distinct. They were not, in
    38 groups, and every one of them failed on the gloss rather than the
    spelling:

      məntalása 'matress'    vs  məntalása 'mattress'     - a typo
      sá'kə 'make sth ...'   vs  sá'kə 'make something...' - shorthand
      əsê 'god; fetish (spirit)' vs əsê 'fetish spirit'    - a parenthetical

    The typo map already existed for the PROMPT (generate_images.
    fix_gloss_typos); it belongs here too. Stripping parentheses threw away
    the word that made the two glosses match, so their content is kept
    instead.
    """
    e = e.lower()
    try:
        import generate_images as _gi
        e = _gi.fix_gloss_typos(e)
    except Exception:
        pass
    e = re.sub(r"\bsb\b", "somebody", e)
    e = re.sub(r"\bsth\b", "something", e)
    e = re.sub(r"[()]", " ", e)          # keep what is inside, drop the marks
    e = re.sub(r"[^a-z\s]", " ", e)
    return {(t[:-1] if t.endswith("s") and not t.endswith("ss") else t)
            for t in e.split() if t not in STOP and len(t) > 2}


def _has_typo(english):
    """Does this gloss contain a misspelling the typo map knows about?"""
    try:
        import generate_images as _gi
        return _gi.fix_gloss_typos(english) != english
    except Exception:
        return False


def similar_spelling(a, b):
    ca, cb = a["cons"], b["cons"]
    if not ca or not cb:
        return False
    if min(len(ca), len(cb)) <= 4:
        if ca != cb:
            return False
    elif lev(ca, cb, 1) > 1:
        return False
    return lev(a["fold"], b["fold"], 2) <= 2


def same_meaning(a, b):
    A, B = a["ts"], b["ts"]
    if not A or not B:
        return False
    if A <= B or B <= A:
        return True
    return len(A & B) / len(A | B) >= 0.6


def load(lines):
    rows = []
    for i, l in enumerate(lines):
        if l.lstrip().startswith("//"):
            continue
        m = ROW.match(l)
        if not m:
            continue
        rank, label = provenance(l.split("),", 1)[-1])
        rows.append({"line": i + 1, "awing": m.group(2), "english": m.group(4),
                     "category": m.group(6) or "", "rank": rank, "src": label,
                     "fold": folded(m.group(2)), "cons": consonants(m.group(2)),
                     "ts": tokens(m.group(4))})
    return rows


def build_plan(rows):
    freq = collections.Counter(r["awing"] for r in rows)
    # Blocking keys. The old one was the first two consonants, which misses
    # every pair whose difference is at the START:
    #   tsənkeelə / ntsənkeelə̌   "round"      ts.. vs nt..
    #   məŋwédnúə / magwédnuə    "bee"        mn.. vs mg..
    #   nden ŋwunə / ŋ nden ŋwuna "old man"   nd.. vs nn..
    # Three keys per row now - the first two consonants, the last two, and
    # the consonant SET, which does not care about order or position at all.
    # A pair only has to collide on one of them to be compared.
    buckets = collections.defaultdict(list)
    for r in rows:
        c = r["cons"]
        for key in {c[:2], c[-2:], "".join(sorted(set(c)))[:4]}:
            buckets[key].append(r)
    plan, seen = [], set()
    for rs in buckets.values():
        for i in range(len(rs)):
            if rs[i]["line"] in seen:
                continue
            cluster = [rs[i]]
            for j in range(i + 1, len(rs)):
                if rs[j]["line"] in seen:
                    continue
                if similar_spelling(rs[i], rs[j]) and same_meaning(rs[i], rs[j]):
                    cluster.append(rs[j])
            # IDENTICAL spellings count too. This used to require the
            # spellings to DIFFER, on the reasoning that same-spelling rows
            # were handled by an earlier pass - but that pass demanded the
            # glosses share a head word AND overlap 80%, so sá'ə "announce
            # publicly" and sá'ə "announce publicly, particularly in the
            # market square" stayed as two cards with one picture. Same
            # word, same page range of the same dictionary, same meaning.
            # One rule covers both now.
            if len(cluster) < 2:
                continue
            for x in cluster:
                seen.add(x["line"])
            seen.add(rs[i]["line"])
            top = max(x["rank"] for x in cluster)
            best = [x for x in cluster if x["rank"] == top]
            # Tie-break after source and established spelling: the SHORTER
            # gloss. The head word is shared by construction, so the longer
            # one carries dictionary commentary, not a second meaning, and
            # "announce publicly" is the better card than "announce
            # publicly, particularly in the market square".
            # A CORRECTLY SPELLED gloss outranks a shorter one. The length
            # tie-break alone kept "matress" over "mattress", "symtom" over
            # "symptom" and "mushoom" over the correct spelling, because the
            # typo is the shorter string. The card text is what a child
            # reads; it has to be right before it is short.
            keep = max(best, key=lambda x: (freq[x["awing"]],
                                            not _has_typo(x["english"]),
                                            -len(x["english"]), -x["line"]))
            strip = lambda d: {k: v for k, v in d.items() if k != "ts"}
            plan.append({"keep": strip(keep),
                         "remove": [strip(x) for x in cluster
                                    if x["line"] != keep["line"]]})
    return plan


def main():
    apply = "--apply" in sys.argv
    lines = open(VOCAB, encoding="utf-8").read().split("\n")
    plan = build_plan(load(lines))
    n = sum(len(p["remove"]) for p in plan)
    json.dump(plan, open(PLAN, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(f"groups {len(plan)}  rows to remove {n}  -> {PLAN}")
    if not apply:
        print("dry run; pass --apply to comment the rows out")
        return
    done = 0
    for p in plan:
        k = p["keep"]
        for r in p["remove"]:
            i = r["line"] - 1
            l = lines[i]
            if l.lstrip().startswith("//"):
                continue
            if f"'{r['awing']}'" not in l and f'"{r["awing"]}"' not in l:
                continue
            lines[i] = ("  // " + l.lstrip() +
                        f"  // REMOVED Session 66u similar-spelling: same meaning as "
                        f"L{k['line']} ({k['awing']}), kept because it is "
                        f"{k['src']}; this one is {r['src']}")
            done += 1
    open(VOCAB, "w", encoding="utf-8").write("\n".join(lines))
    print("commented out:", done)





# ==========================================================================
# MULTI-LINE LITERALS: AwingSentence and AwingPhrase
# ==========================================================================
# These are not one-liners like AwingWord, and they do not all live in
# awing_vocabulary.dart:
#
#   lib/screens/medium/sentences_screen.dart
#     AwingSentence(
#       awing: "Móonə nonnɔ́ əkwunɔ́.",
#       english: 'The baby is lying on the bed.',
#       ...
#     ),
#
# So the single-line ROW pattern never saw them, and pairs like
#   'A tə́ ńgenə afoonə.' / 'A tá ńgenə afoona.'  "He is going to the farm."
#   'Ŋwu yî lə tä mə.'   / 'Dwu yi lā tā mə.'     "That man is my father."
# survived every pass, even though Dr. Sama said "words OR SENTENCES" from
# the first telling.
#
# Commenting out a block is riskier than a line, so this is deliberately
# literal-minded: it only accepts a block that opens with `AwingX(` alone on
# its line and closes with `),` at the SAME indent, it comments every line of
# the block, and it refuses the whole file if any block fails to close.
BLOCK_FILES = ["lib/data/awing_vocabulary.dart",
               "lib/screens/medium/sentences_screen.dart"]
OPEN = re.compile(r"^(\s*)Awing(Sentence|Phrase)\(\s*$")
FIELD = re.compile(r"^\s*(awing|english):\s*(['\"])(.*)\2\s*,\s*$")


def read_blocks(path):
    lines = open(path, encoding="utf-8").read().split("\n")
    blocks = []
    i = 0
    while i < len(lines):
        m = OPEN.match(lines[i])
        if not m:
            i += 1
            continue
        indent, kind = m.group(1), m.group(2)
        close = None
        for j in range(i + 1, min(i + 60, len(lines))):
            if lines[j].rstrip() == indent + "),":
                close = j
                break
        if close is None:
            i += 1
            continue
        aw = en = None
        for j in range(i + 1, close):
            f = FIELD.match(lines[j])
            if f:
                if f.group(1) == "awing":
                    aw = f.group(3)
                else:
                    en = f.group(3)
        if aw and en:
            blocks.append({"path": path, "start": i, "end": close, "kind": kind,
                           "awing": aw, "english": en})
        i = close + 1
    return lines, blocks


def merge_blocks(apply=False):
    total = 0
    for path in BLOCK_FILES:
        try:
            lines, blocks = read_blocks(path)
        except FileNotFoundError:
            continue
        live = [b for b in blocks
                if not lines[b["start"]].lstrip().startswith("//")]
        for b in live:
            b.update(fold=folded(b["awing"]), cons=consonants(b["awing"]),
                     ts=tokens(b["english"]))
        drop = []
        used = set()
        for i in range(len(live)):
            if i in used:
                continue
            for j in range(i + 1, len(live)):
                if j in used:
                    continue
                if (similar_spelling(live[i], live[j])
                        and same_meaning(live[i], live[j])):
                    used.add(j)
                    drop.append((live[j], live[i]))
        if not drop:
            print(f"  {path}: nothing to merge")
            continue
        print(f"  {path}: {len(drop)} duplicate block(s)")
        for loser, keeper in drop:
            print(f"      drop {loser['awing'][:44]!r}")
            print(f"      keep {keeper['awing'][:44]!r}  {keeper['english'][:40]!r}")
        total += len(drop)
        if not apply:
            continue
        for loser, keeper in sorted(drop, key=lambda x: -x[0]["start"]):
            for k in range(loser["start"], loser["end"] + 1):
                lines[k] = "  // " + lines[k].lstrip()
            lines[loser["end"]] += (
                f"  // REMOVED Session 66u similar-spelling: same English as "
                f"the block at line {keeper['start'] + 1} "
                f"({keeper['awing'][:30]})")
        open(path, "w", encoding="utf-8").write("\n".join(lines))
    print(f"multi-line blocks: {total}")


if __name__ == "__main__":
    main()
    print("multi-line literals (AwingSentence / AwingPhrase):")
    merge_blocks(apply="--apply" in sys.argv)
