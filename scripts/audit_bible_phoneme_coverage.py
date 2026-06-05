#!/usr/bin/env python3
"""audit_bible_phoneme_coverage.py — v1.0.0 (Phase 1 of Bible→TTS pipeline)

Before spending cloud-GPU money fine-tuning XTTS v2 on the Bible corpus, this
script answers ONE question:

    "Does the Bible audio + text contain enough examples of every Awing
    phoneme/grapheme that appears in our 8,000+ word vocabulary?"

If yes → cloud GPU fine-tune is worth doing. The TTS will learn to pronounce
ALL our vocab words by combining phoneme patterns it heard in Bible verses.

If no → identify the gap phonemes. We either record Dr. Sama saying ~50
specific words covering those phonemes, OR skip TTS and stay with the current
Edge TTS Swahili fallback for the gap words.

Methodology
-----------
1. Extract every word from lib/data/awing_vocabulary.dart.
2. Decompose each Awing word into its meaningful orthographic units:
   - 9 vowels (a, e, ɛ, ə, i, ɨ, o, ɔ, u)
   - 22 consonants
   - 5 tone marks (high/low/falling/rising/mid)
   - Prenasalized clusters (mb, nd, ng, nj, mp, nt, nk)
   - Palatalized clusters (ty, ky, py, ny)
   - Labialized clusters (tw, kw, bw, pw)
   - Long vowels (aa, oo, ee, etc.)
   - Diphthongs (iə, ɨə, uə)
   - Glottal stop (')
3. Count occurrences in vocab.
4. Do the same for every verse in corpus/aligned/piper/{train,eval}/metadata.csv.
5. Compute coverage: for each phoneme that vocab needs, how many Bible
   occurrences? Anything <10 occurrences = thin coverage, model may not
   learn it.
6. Report per-phoneme stats + overall vocab-word coverage (% of vocab
   words made entirely of "well-covered" phonemes).

Run from anywhere:
    python scripts\\audit_bible_phoneme_coverage.py
"""
from __future__ import annotations

import re
import sys
import unicodedata
from collections import Counter, defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
VOCAB_FILE = REPO / "lib" / "data" / "awing_vocabulary.dart"
TRAIN_META = REPO / "corpus" / "aligned" / "piper" / "train" / "metadata.csv"
EVAL_META = REPO / "corpus" / "aligned" / "piper" / "eval" / "metadata.csv"

# ===== Awing orthography decomposition =====

# Prenasalized consonant clusters — must be detected BEFORE individual chars
# because "ng" is a single phoneme, not n+g
PRENASALIZED = ["ŋg", "ŋk", "mb", "mp", "nd", "nt", "nk", "nj", "ng"]
PALATALIZED = ["ty", "ky", "py", "ny", "by", "my"]
LABIALIZED = ["tw", "kw", "bw", "pw", "mw", "gw"]
DIGRAPHS = ["sh", "ch", "ts", "dz", "gh"]  # gh = /ɣ/

# Special single chars
SPECIAL_VOWELS = ["ɛ", "ɔ", "ə", "ɨ"]
BASIC_VOWELS = ["a", "e", "i", "o", "u"]
NG_CONSONANT = "ŋ"

# Tone diacritics (Unicode combining marks)
TONE_HIGH = "́"      # combining acute
TONE_LOW = "̀"       # combining grave
TONE_FALLING = "̂"   # combining circumflex
TONE_RISING = "̌"    # combining caron
# unmarked vowel = MID tone (default)

# Glottal stop (Awing uses ' / curly quote variants)
GLOTTAL_VARIANTS = ["'", "’", "‘", "ʼ"]


def decompose_awing(text: str) -> list[str]:
    """Return ordered list of meaningful orthographic units in the text.

    Each item is one of:
      - "cluster:mb", "cluster:ŋg" (prenasalized/palatalized/labialized)
      - "digraph:gh", "digraph:sh"
      - "longvowel:aa" (any doubled vowel)
      - "diphthong:iə"
      - "vowel:a", "vowel:ɛ"
      - "consonant:p", "consonant:l"
      - "tone:high", "tone:low", "tone:falling", "tone:rising"
      - "glottal"
    Skips spaces, digits, punctuation.

    CRITICAL: NFD-normalizes input so precomposed tone-marked vowels (â, ê,
    ǐ, etc.) are split into base + combining mark, which the loop below can
    then handle correctly. Without this, "â" hits the catch-all consonant
    branch and gets misclassified.
    """
    # Decompose precomposed chars to base + combining marks (NFD)
    text = unicodedata.normalize("NFD", text)
    # Normalize curly quotes / glottal variants to single ASCII apostrophe
    for g in GLOTTAL_VARIANTS:
        text = text.replace(g, "'")

    units = []
    i = 0
    # Use lowercase for matching but preserve original chars for vowel ID
    s = text.lower()
    while i < len(s):
        c = s[i]
        # Glottal stop
        if c == "'":
            units.append("glottal")
            i += 1
            continue
        # Skip punctuation, digits, spaces
        if c in " ,.!?;:\"\n\t\r0123456789()[]{}-—–_/\\":
            i += 1
            continue
        # Skip combining tone marks here — they'll be attached to vowel below
        if c in (TONE_HIGH, TONE_LOW, TONE_FALLING, TONE_RISING):
            # Should have been consumed by the preceding vowel; skip
            i += 1
            continue
        # Try multi-character clusters first (longest match wins)
        matched = False
        for cluster_list, prefix in [
            (PRENASALIZED, "cluster"),
            (PALATALIZED, "cluster"),
            (LABIALIZED, "cluster"),
            (DIGRAPHS, "digraph"),
        ]:
            for cluster in cluster_list:
                if s[i : i + len(cluster)] == cluster:
                    units.append(f"{prefix}:{cluster}")
                    i += len(cluster)
                    matched = True
                    break
            if matched:
                break
        if matched:
            continue
        # Long vowel detection: any vowel repeated
        if c in BASIC_VOWELS or c in SPECIAL_VOWELS:
            # Look ahead for repeat
            if i + 1 < len(s) and s[i + 1] == c:
                units.append(f"longvowel:{c}{c}")
                # Capture tone if any on the second vowel
                if i + 2 < len(s) and s[i + 2] in (TONE_HIGH, TONE_LOW, TONE_FALLING, TONE_RISING):
                    tone_map = {TONE_HIGH: "high", TONE_LOW: "low",
                                TONE_FALLING: "falling", TONE_RISING: "rising"}
                    units.append(f"tone:{tone_map[s[i + 2]]}")
                    i += 1
                i += 2
                continue
            # Diphthong: vowel + special vowel (e.g. iə, uə)
            if i + 1 < len(s) and s[i + 1] in SPECIAL_VOWELS and c != s[i + 1]:
                units.append(f"diphthong:{c}{s[i + 1]}")
                i += 2
                continue
            # Single vowel
            units.append(f"vowel:{c}")
            # Attached tone?
            if i + 1 < len(s) and s[i + 1] in (TONE_HIGH, TONE_LOW, TONE_FALLING, TONE_RISING):
                tone_map = {TONE_HIGH: "high", TONE_LOW: "low",
                            TONE_FALLING: "falling", TONE_RISING: "rising"}
                units.append(f"tone:{tone_map[s[i + 1]]}")
                i += 1
            i += 1
            continue
        # ŋ as standalone consonant
        if c == NG_CONSONANT:
            units.append("consonant:ŋ")
            i += 1
            continue
        # Other consonants (a-z minus vowels)
        if c.isalpha():
            units.append(f"consonant:{c}")
            i += 1
            continue
        # Unknown char — log and skip
        i += 1
    return units


# ===== Vocabulary loader =====

def load_vocab_words() -> list[str]:
    """Parse awing_vocabulary.dart and return all Awing words."""
    sq = r"'((?:\\.|[^'\\])*)'"
    dq = r'"((?:\\.|[^"\\])*)"'
    s = rf"(?:{sq}|{dq})"
    pat = re.compile(rf"AwingWord\(\s*awing:\s*{s}", re.DOTALL)
    content = VOCAB_FILE.read_text(encoding="utf-8")
    words = []
    for m in pat.finditer(content):
        # Skip commented lines
        line_start = content.rfind("\n", 0, m.start()) + 1
        if "//" in content[line_start : m.start()]:
            continue
        awing = (m.group(1) if m.group(1) is not None else m.group(2) or "")
        awing = awing.replace("\\'", "'")
        if awing:
            words.append(awing)
    return words


# ===== Bible loader =====

def load_bible_text() -> list[str]:
    """Load all verses from train + eval metadata.csv."""
    verses = []
    for path in (TRAIN_META, EVAL_META):
        if not path.exists():
            print(f"  ! Missing {path}")
            continue
        for line in path.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or "|" not in line:
                continue
            # LJSpeech format: clip_id|text
            parts = line.split("|", 1)
            if len(parts) >= 2:
                verses.append(parts[1])
    return verses


# ===== Audit =====

def audit():
    print("=" * 70)
    print(" Bible → TTS Phoneme Coverage Audit")
    print("=" * 70)
    print()

    print("Loading vocabulary...")
    vocab_words = load_vocab_words()
    print(f"  → {len(vocab_words):,} Awing words in vocab")

    print("Loading Bible corpus...")
    bible_verses = load_bible_text()
    print(f"  → {len(bible_verses):,} Bible verses (train + eval)")
    print()

    # Decompose everything
    print("Decomposing vocab into phonemes...")
    vocab_counter = Counter()
    vocab_word_phonemes = []  # list of (word, set-of-phonemes)
    for w in vocab_words:
        phonemes = decompose_awing(w)
        vocab_counter.update(phonemes)
        vocab_word_phonemes.append((w, set(phonemes)))

    print("Decomposing Bible into phonemes (this takes ~30s)...")
    bible_counter = Counter()
    for v in bible_verses:
        bible_counter.update(decompose_awing(v))

    # Per-phoneme coverage report
    print()
    print("=" * 70)
    print(" Phoneme coverage")
    print("=" * 70)
    print(f"{'Phoneme':<28} {'In vocab':>10} {'In Bible':>10} {'Verdict':<20}")
    print("-" * 70)

    GOOD_THRESHOLD = 100   # plenty of examples for the model to learn
    THIN_THRESHOLD = 10    # marginal — may or may not generalize
    # else: BAD (model won't learn it)

    # Sort: vocab phonemes first, by vocab count descending
    all_phonemes = set(vocab_counter.keys()) | set(bible_counter.keys())
    sorted_phonemes = sorted(
        all_phonemes,
        key=lambda p: (-vocab_counter.get(p, 0), p),
    )

    well_covered = set()
    thin_covered = set()
    bad_covered = set()

    for p in sorted_phonemes:
        v_count = vocab_counter.get(p, 0)
        b_count = bible_counter.get(p, 0)
        if v_count == 0:
            continue  # not used by vocab, ignore
        if b_count >= GOOD_THRESHOLD:
            verdict = "✓ GOOD"
            well_covered.add(p)
        elif b_count >= THIN_THRESHOLD:
            verdict = "~ THIN"
            thin_covered.add(p)
        else:
            verdict = "✗ BAD"
            bad_covered.add(p)
        print(f"{p:<28} {v_count:>10,} {b_count:>10,} {verdict:<20}")

    # Word-level coverage: what % of vocab words are made entirely of GOOD
    # phonemes?
    print()
    print("=" * 70)
    print(" Vocab word coverage")
    print("=" * 70)
    fully_good = 0
    has_thin = 0
    has_bad = 0
    affected_by_bad = defaultdict(int)
    for w, phones in vocab_word_phonemes:
        if not phones:
            continue
        if phones.issubset(well_covered):
            fully_good += 1
        elif phones & bad_covered:
            has_bad += 1
            for bp in phones & bad_covered:
                affected_by_bad[bp] += 1
        else:
            has_thin += 1
    total = len(vocab_word_phonemes)
    print(f"  Fully covered (all phonemes GOOD): {fully_good:,} / {total:,} ({100*fully_good/total:.1f}%)")
    print(f"  Contains a THIN phoneme:           {has_thin:,} / {total:,} ({100*has_thin/total:.1f}%)")
    print(f"  Contains a BAD phoneme:            {has_bad:,} / {total:,} ({100*has_bad/total:.1f}%)")
    print()

    if affected_by_bad:
        print("Top BAD phonemes by # of vocab words affected:")
        for p, count in sorted(affected_by_bad.items(), key=lambda x: -x[1])[:15]:
            print(f"  {p}: {count:,} vocab words")
        print()

    # Final verdict
    coverage_pct = 100 * (fully_good + has_thin) / total
    print("=" * 70)
    print(" Recommendation")
    print("=" * 70)
    if coverage_pct >= 95:
        print(f"  ✓ {coverage_pct:.1f}% coverage — GREEN-LIGHT cloud GPU fine-tune.")
        print(f"  The TTS will learn to pronounce essentially all vocab words.")
    elif coverage_pct >= 85:
        print(f"  ~ {coverage_pct:.1f}% coverage — PROCEED WITH CAUTION.")
        print(f"  Fine-tune will work for most words. BAD-phoneme words may")
        print(f"  fall back to current Edge TTS Swahili.")
    else:
        print(f"  ✗ {coverage_pct:.1f}% coverage — DO NOT spend cloud GPU money yet.")
        print(f"  Too many vocab words use phonemes the Bible barely contains.")
        print(f"  Record gap-fill words first (~50 words covering BAD phonemes),")
        print(f"  then re-audit.")
    print()
    return 0


if __name__ == "__main__":
    sys.exit(audit())
