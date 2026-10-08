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

ROW = re.compile(r"^\s*AwingWord\(awing:\s*(['\"])(.*?)\1,\s*english:\s*(['\"])(.*?)\3,\s*category:\s*(['\"])(.*?)\5")
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
    e = re.sub(r"\s*\(.*?\)", " ", e.lower())
    e = re.sub(r"[^a-z\s]", " ", e)
    return {(t[:-1] if t.endswith("s") and not t.endswith("ss") else t)
            for t in e.split() if t not in STOP and len(t) > 2}


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
                     "category": m.group(6), "rank": rank, "src": label,
                     "fold": folded(m.group(2)), "cons": consonants(m.group(2)),
                     "ts": tokens(m.group(4))})
    return rows


def build_plan(rows):
    freq = collections.Counter(r["awing"] for r in rows)
    buckets = collections.defaultdict(list)
    for r in rows:
        buckets[r["cons"][:2]].append(r)
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
            top = max(x["rank"] for x in cluster)
            best = [x for x in cluster if x["rank"] == top]
            # Tie-break after source and established spelling: the SHORTER
            # gloss. The head word is shared by construction, so the longer
            # one carries dictionary commentary, not a second meaning, and
            # "announce publicly" is the better card than "announce
            # publicly, particularly in the market square".
            keep = max(best, key=lambda x: (freq[x["awing"]], -len(x["english"]), -x["line"]))
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


if __name__ == "__main__":
    main()
