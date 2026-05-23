#!/usr/bin/env python3
"""Build a self-contained HTML family voice recorder.

Reads the Awing Dart source files and emits family_recorder.html in the
project root. Every Awing item (phrase, sentence, vocab entry) gets six
microphone buttons -- one per family member.

Alphabet letters are intentionally NOT included; family members do not need
to record them individually (vowel and consonant sounds are already
exercised through whole-word recordings).

Words flagged as inappropriate-for-kids are forced to difficulty 3 (Expert)
so kid recorders (filtered to Beginner / Medium) don't see them.

Family voice mapping:
  Adults  -> Dr. Guidion Sama (man),   Berlin Sama (woman)
  Boy     -> Joel, Janelle
  Girls   -> Joyce, Jadyne

Recordings auto-download as {voice}_{name}__{audio_key}.webm, matching the
audio key convention used by generate_audio_edge.py.
"""

from __future__ import annotations

import json
import re
import sys
import unicodedata
from pathlib import Path

ROOT          = Path(__file__).resolve().parent.parent
VOCAB_DART    = ROOT / "lib" / "data" / "awing_vocabulary.dart"
SENTENCES_DART = ROOT / "lib" / "screens" / "medium" / "sentences_screen.dart"
OUTPUT_HTML   = ROOT / "family_recorder.html"


# ----------------------------------------------------------------------
# Audio-key helpers (mirror generate_audio_edge.py)
# ----------------------------------------------------------------------

def audio_key(awing):
    s = unicodedata.normalize("NFD", awing)
    s = "".join(c for c in s if not unicodedata.combining(c))
    table = {
        "ɛ": "e", "Ɛ": "E",   # ɛ Ɛ
        "ɔ": "o", "Ɔ": "O",   # ɔ Ɔ
        "ə": "e", "Ə": "E",   # ə Ə
        "ɨ": "i", "Ɨ": "I",   # ɨ Ɨ
        "ŋ": "ng", "Ŋ": "NG", # ŋ Ŋ
        "ɣ": "g", "Ɣ": "G",   # ɣ Ɣ
    }
    s = "".join(table.get(c, c) for c in s)
    for ap in ("'", "’", "‘", "ʼ", "ʹ"):
        s = s.replace(ap, "")
    s = s.lower()
    s = re.sub(r"\s+", "_", s)
    s = re.sub(r"[^a-z0-9_]", "", s)
    return s


def unescape_dart(s):
    return (s.replace("\\'", "'")
             .replace('\\"', '"')
             .replace("\\\\", "\\")
             .replace("\\n", "\n")
             .replace("\\t", "\t"))


def read(path):
    return path.read_text(encoding="utf-8")


def strip_comments(src):
    src = re.sub(r"/\*.*?\*/", "", src, flags=re.DOTALL)
    out = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if c in ("'", '"'):
            quote = c
            out.append(c)
            i += 1
            while i < n:
                ch = src[i]
                out.append(ch)
                if ch == "\\" and i + 1 < n:
                    out.append(src[i + 1])
                    i += 2
                    continue
                i += 1
                if ch == quote:
                    break
        elif c == "/" and i + 1 < n and src[i + 1] == "/":
            while i < n and src[i] != "\n":
                i += 1
        else:
            out.append(c)
            i += 1
    return "".join(out)


# ----------------------------------------------------------------------
# Inappropriate-for-kids keyword filter
# ----------------------------------------------------------------------
# When an English gloss matches ANY of these patterns the item's
# difficulty is forced to 3 (Expert) regardless of its source value.
# Per Session 60: keep insults, body fluids, etc. usable for the adult
# Expert tier, but hide them from beginner/medium filters that kids use.

KID_INAPPROPRIATE_PATTERNS = [
    # Adult anatomy
    r"\bpenis\b", r"\bvagina\b", r"\btesticle", r"\bscrotum\b",
    r"\bclitor", r"\bgenital", r"\bnipple", r"\bbreast(s| milk)?\b",
    r"\bgroin\b", r"\banus\b", r"\bbutt", r"\bbuttock",

    # Sex / reproduction
    r"\bsex(ual)?\b", r"\bcopulat", r"\bintercourse\b", r"\bfornicat",
    r"\bmasturbat", r"\bsemen\b", r"\bsperm\b", r"\borgasm",
    r"\berection\b", r"\bmenstruat", r"\bpregnan",
    r"\brape\b", r"\bprostitut", r"\bbrothel", r"\badulter",
    r"\bharlot\b", r"\bwhore\b", r"\bnaked", r"\bnudity\b",

    # Body fluids / waste
    r"\burine\b", r"\burinat", r"\bexcrement\b", r"\bfeces\b",
    r"\bdefecat", r"\bshit\b", r"\bpiss\b", r"\bvomit",
    r"\bmucus\b", r"\bsnot\b", r"\bpus\b", r"\bfart\b",
    r"\bbelch\b", r"\bphlegm\b", r"\bhernia\b", r"\bsaliva\b",

    # Violence / killing
    r"\bcorpse\b", r"\bdead body\b", r"\bkill(ing|s|er)?\b",
    r"\bmurder", r"\bslaughter", r"\bmassacre",
    r"\bstab", r"\bshoot\b", r"\bshot dead\b", r"\bgun\b",
    r"\brifle\b", r"\bbullet", r"\bweapon", r"\bspear\b",
    r"\bwhip\b", r"\bflog", r"\btorture",
    r"\bbleed\b", r"\bblood(y)?\b",
    r"\bcastrat", r"\bbehead",

    # Disease
    r"\bleprosy\b", r"\bsyphilis\b", r"\bgonorrhea\b",
    r"\babscess\b", r"\bhemorrhoid", r"\bulcer\b", r"\btumour\b",
    r"\btumor\b", r"\bcancer\b",

    # Insults / curses
    r"\bfool\b", r"\bidiot\b", r"\bstupid\b",
    r"\bmad person\b", r"\blunatic\b", r"\bdumb person\b",
    r"\bdamn", r"\bcurse(d)?\b", r"\bhate(s|d)?\b",

    # Drugs / alcohol
    r"\bdrunk\b", r"\bdrunkard\b", r"\balcoholic\b",
    r"\bcigarette\b", r"\btobacco\b", r"\bopium\b",
    r"\bsmoking\b",

    # Occult / witchcraft
    r"\bwitchcraft\b", r"\bwitch\b", r"\bsorcer",
    r"\bjuju\b", r"\bfetish\b", r"\bdemon\b", r"\bdevil\b",
    r"\bhell\b", r"\bsorcery\b", r"\bconjure", r"\bnecromanc",
    r"\bdivinat", r"\bcharm( for)?\b", r"\bspell( on)?\b",

    # Death / mourning
    r"\bfuneral\b", r"\bmourning\b", r"\bwidow", r"\borphan\b",
    r"\bburial\b", r"\bgrave\b", r"\bcemetery\b", r"\bcoffin\b",
    r"\bdying\b", r"\bdeath\b", r"\bdeceased\b",
]

KID_INAPPROPRIATE_RE = re.compile("|".join(KID_INAPPROPRIATE_PATTERNS), re.IGNORECASE)


def is_inappropriate(english):
    return bool(KID_INAPPROPRIATE_RE.search(english))


# ----------------------------------------------------------------------
# Regex parsers
# ----------------------------------------------------------------------

WORD_RE = re.compile(
    r"AwingWord\s*\(\s*"
    r"awing:\s*(?P<awq>['\"])(?P<awing>(?:[^\\]|\\.)*?)(?P=awq)"
    r".*?english:\s*(?P<enq>['\"])(?P<english>(?:[^\\]|\\.)*?)(?P=enq)"
    r".*?category:\s*(?P<cq>['\"])(?P<category>(?:[^\\]|\\.)*?)(?P=cq)"
    r"(?P<rest>[^)]*)\)",
    re.DOTALL,
)

PHRASE_RE = re.compile(
    r"AwingPhrase\s*\(\s*"
    r"awing:\s*(?P<awq>['\"])(?P<awing>(?:[^\\]|\\.)*?)(?P=awq)"
    r".*?english:\s*(?P<enq>['\"])(?P<english>(?:[^\\]|\\.)*?)(?P=enq)"
    r"(?:.*?category:\s*(?P<cq>['\"])(?P<category>(?:[^\\]|\\.)*?)(?P=cq))?"
    r"[^)]*\)",
    re.DOTALL,
)

SENTENCE_RE = re.compile(
    r"AwingSentence\s*\(\s*"
    r"awing:\s*(?P<awq>['\"])(?P<awing>(?:[^\\]|\\.)*?)(?P=awq)"
    r"\s*,\s*english:\s*(?P<enq>['\"])(?P<english>(?:[^\\]|\\.)*?)(?P=enq)",
    re.DOTALL,
)


def extract_words(src):
    seen, items = set(), []
    for m in WORD_RE.finditer(src):
        awing = unescape_dart(m.group("awing")).strip()
        english = unescape_dart(m.group("english")).strip()
        category = m.group("category").strip()
        if not awing:
            continue
        diff_m = re.search(r"difficulty:\s*(\d+)", m.group("rest") or "")
        difficulty = int(diff_m.group(1)) if diff_m else 1
        # Force inappropriate content to Expert tier
        if is_inappropriate(english):
            difficulty = 3
        key = audio_key(awing)
        sig = (key, english.lower())
        if sig in seen:
            continue
        seen.add(sig)
        items.append({
            "kind": "word",
            "awing": awing,
            "english": english,
            "category": category,
            "difficulty": difficulty,
            "key": key,
        })
    return items


def extract_phrases(src):
    seen, items = set(), []
    for m in PHRASE_RE.finditer(src):
        awing = unescape_dart(m.group("awing")).strip()
        english = unescape_dart(m.group("english")).strip()
        category = (m.group("category") or "phrase").strip()
        if not awing:
            continue
        key = audio_key(awing)
        if key in seen:
            continue
        seen.add(key)
        items.append({
            "kind": "phrase",
            "awing": awing,
            "english": english,
            "category": category,
            "difficulty": 1,
            "key": key,
        })
    return items


def extract_sentences(src):
    seen, items = set(), []
    for m in SENTENCE_RE.finditer(src):
        awing = unescape_dart(m.group("awing")).strip()
        english = unescape_dart(m.group("english")).strip()
        if not awing:
            continue
        key = audio_key(awing)
        if key in seen:
            continue
        seen.add(key)
        items.append({
            "kind": "sentence",
            "awing": awing,
            "english": english,
            "category": "sentence",
            "difficulty": 2,
            "key": key,
        })
    return items


def merge_homonyms(items):
    merged = {}
    order = []
    for it in items:
        sig = it["awing"]
        if sig not in merged:
            merged[sig] = dict(it)
            merged[sig]["english_list"] = [it["english"]]
            order.append(sig)
        else:
            existing = merged[sig]
            if it["english"] not in existing["english_list"]:
                existing["english_list"].append(it["english"])
            # If ANY sense is inappropriate, the whole merged card becomes Expert
            if is_inappropriate(it["english"]):
                existing["difficulty"] = 3
            elif it.get("difficulty", 3) < existing.get("difficulty", 3) \
                    and existing.get("difficulty", 3) != 3:
                existing["difficulty"] = it["difficulty"]
                existing["category"]   = it["category"]
    out = []
    for sig in order:
        m = merged[sig]
        m["english"] = "; ".join(m["english_list"])
        del m["english_list"]
        # Final re-check: if combined English contains any flagged term, mark Expert
        if is_inappropriate(m["english"]):
            m["difficulty"] = 3
        out.append(m)
    return out


def disambiguate_keys(items):
    seen = {}
    for it in items:
        base = it["key"]
        n = seen.get(base, 0) + 1
        seen[base] = n
        if n > 1:
            it["key"] = base + "__" + str(n)
            it["disambiguated"] = True
    return items


def build_dataset():
    if not VOCAB_DART.exists():
        sys.exit("Missing source: " + str(VOCAB_DART))

    vocab_src    = strip_comments(read(VOCAB_DART))
    sentence_src = strip_comments(read(SENTENCES_DART)) if SENTENCES_DART.exists() else ""

    phrases   = extract_phrases(vocab_src)
    sentences = extract_sentences(sentence_src)
    words     = extract_words(vocab_src)

    # Drop any vocab word whose Awing form already appears as a phrase/sentence
    used_awings = {x["awing"] for x in (phrases + sentences)}
    words = [w for w in words if w["awing"] not in used_awings]

    pre = (len(phrases), len(sentences), len(words))
    phrases   = merge_homonyms(phrases)
    sentences = merge_homonyms(sentences)
    words     = merge_homonyms(words)

    all_items = phrases + sentences + words
    disambiguate_keys(all_items)

    bumped = sum(1 for w in words if w["difficulty"] == 3 and is_inappropriate(w["english"]))
    print("Pre-merge:    {} phrases, {} sentences, {} words".format(*pre))
    print("Post-merge:   {} phrases, {} sentences, {} words (total {})".format(
        len(phrases), len(sentences), len(words),
        len(phrases) + len(sentences) + len(words)))
    print("Disambiguated keys:                       {}".format(
        sum(1 for it in all_items if it.get("disambiguated"))))
    print("Words routed to Expert (inappropriate):   {}".format(bumped))

    return {
        "letters": [],          # intentionally empty -- alphabet removed
        "phrases": phrases,
        "sentences": sentences,
        "words": words,
    }


FAMILY = [
    {"id": "guidion", "name": "Dr. Guidion Sama", "role": "Adult -- Man",   "voice": "man",   "color": "#0d47a1"},
    {"id": "berlin",  "name": "Berlin Sama",      "role": "Adult -- Woman", "voice": "woman", "color": "#880e4f"},
    {"id": "joel",    "name": "Joel",             "role": "Boy",            "voice": "boy",   "color": "#1565c0"},
    {"id": "janelle", "name": "Janelle",          "role": "Boy",            "voice": "boy",   "color": "#3949ab"},
    {"id": "joyce",   "name": "Joyce",            "role": "Girl",           "voice": "girl",  "color": "#7b1fa2"},
    {"id": "jadyne",  "name": "Jadyne",           "role": "Girl",           "voice": "girl",  "color": "#c2185b"},
]


TEMPLATE_PATH = Path(__file__).resolve().parent / "family_recorder_template.html"


def emit_html(dataset):
    items = []
    items.extend(dataset["letters"])
    items.extend(dataset["phrases"])
    items.extend(dataset["sentences"])
    items.extend(sorted(dataset["words"], key=lambda w: (w["difficulty"], w["awing"])))

    if not TEMPLATE_PATH.exists():
        sys.exit("Missing template: " + str(TEMPLATE_PATH))
    template = TEMPLATE_PATH.read_text(encoding="utf-8")
    html = (template
            .replace("__FAMILY_JSON__", json.dumps(FAMILY, ensure_ascii=False))
            .replace("__ITEMS_JSON__",  json.dumps(items, ensure_ascii=False)))
    OUTPUT_HTML.write_text(html, encoding="utf-8")
    size_kb = OUTPUT_HTML.stat().st_size / 1024
    print("Wrote {} ({:.1f} KB, {} items)".format(OUTPUT_HTML, size_kb, len(items)))


if __name__ == "__main__":
    emit_html(build_dataset())
