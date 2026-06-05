#!/usr/bin/env python3
"""normalize_text.py — Awing orthographic normalization for TTS training/inference

The Bible corpus (training source) and our vocabulary (inference source) use
slightly different orthographic conventions. To make the trained model
generalize correctly, BOTH must be normalized to the same representation
before being fed to the model.

This module is shared by:
  - scripts/ml/tts/prep_training_data.py   (applied to Bible verses)
  - scripts/ml/tts/generate_vocab_clips.py (applied to vocab words at inference)

Normalizations applied (in order)
---------------------------------
1. NFC normalization → consistent precomposed Unicode (â stays â, never
   "a" + combining circumflex). Many downstream tools assume one form or
   the other; NFC is the cross-platform default.
2. Curly quotes → ASCII apostrophe (' / ' / ʼ → ').
3. Strip leading whitespace, collapse internal multiple spaces.
4. Fix OCR-corrupted Greek letters from the Session 29 dictionary extraction:
   ε (U+03B5 Greek epsilon) → ɛ (U+025B Latin epsilon)
   ʉ (U+0289 IPA close central rounded) → u  (assume keyboard slip)
   ã, õ, ł, ø, ž, š (foreign characters) → strip diacritic where possible
5. ŋg cluster → ng (Bible convention; the model learns the velar nasal+g
   sound from "ng" examples and applies it to either spelling).
6. Vowel-schwa diphthongs (aə, eə, ɨə, oə) → keep as-is (the model can
   learn these from the audio even if the Bible writes them differently;
   no good single normalization exists).
7. Strip grave accent (low-tone marker) only at INFERENCE time. The Bible
   doesn't mark low tone, so the model never sees the grave-accent
   diacritic. At inference, we strip it before sending to the model.

For training:  normalize_for_training(text) — keeps tones, normalizes spelling
For inference: normalize_for_inference(text) — additionally strips grave
                                                accents
"""
from __future__ import annotations

import re
import unicodedata

# ===== Constants =====

# OCR / encoding cleanup: characters that should be replaced
OCR_FIXES = {
    "ε": "ɛ",  # Greek epsilon → Latin epsilon (ɛ)
    "ʉ": "u",       # IPA close central rounded → u
    "ã": "a",       # ã (foreign loanword variant)
    "õ": "o",       # õ
    "ł": "l",       # ł
    "ø": "o",       # ø
    "ž": "z",       # ž
    "š": "s",       # š
    "ç": "c",       # ç
    "ı": "i",       # ı (Turkish dotless i)
}

# Curly quote variants → ASCII apostrophe (glottal stop in Awing)
QUOTE_VARIANTS = {
    "‘": "'",  # left single
    "’": "'",  # right single
    "ʼ": "'",  # modifier letter apostrophe
    "ʻ": "'",  # modifier letter turned comma
    "“": '"',  # left double
    "”": '"',  # right double
}

# Combining grave accent (low tone) — stripped at inference
COMBINING_GRAVE = "̀"
# Precomposed grave-accented vowels (also stripped at inference)
GRAVE_VOWELS = {
    "à": "a",   # à
    "è": "e",   # è
    "ì": "i",   # ì
    "ò": "o",   # ò
    "ù": "u",   # ù
}


def normalize_for_training(text: str) -> str:
    """Apply training-time normalization (used on Bible corpus only).

    Returns NFC-normalized text with OCR fixes, quote unification, and
    cluster normalization applied. Preserves all tone diacritics.
    Also strips:
      - Digits (Bible cross-references like "9.13Mal 1.1-2", verse numbers)
      - Non-Awing Latin diacritic variants (ë, ï, ö, ü) that are typos/OCR
      - Bracketed annotations [...] and parenthetical Bible references
    All of these previously surfaced as 'Character N not found in
    vocabulary. Discarding it.' warnings during Coqui auto-vocab build.
    """
    # Decompose first so we can apply char-level fixes
    text = unicodedata.normalize("NFD", text)

    # Curly quotes → ASCII apostrophe
    for k, v in QUOTE_VARIANTS.items():
        text = text.replace(k, v)

    # OCR / foreign char cleanup
    for k, v in OCR_FIXES.items():
        text = text.replace(k, v)

    # Strip umlauts/dieresis on Latin vowels (ë, ï, ö, ü, ä, ÿ — not Awing)
    # Done in decomposed form: strip combining diaeresis U+0308
    text = text.replace("̈", "")

    # Strip Greek Latin-look-alikes that are NOT Awing's open-mid vowels
    # Ɛ (U+0190 LATIN CAPITAL LETTER OPEN E) is genuinely Awing — keep it.
    # But Greek capital Epsilon Ε (U+0395) is NOT — Bible OCR sometimes
    # mixes them. Below mapping only fires if the lookup-table key matches.

    # Re-compose to NFC
    text = unicodedata.normalize("NFC", text)

    # ŋg cluster → ng (case-insensitive)
    text = text.replace("ŋg", "ng").replace("Ŋg", "Ng").replace("ŋG", "nG")

    # Strip Bible cross-reference patterns BEFORE digit removal so
    # patterns like "9.13Mal 1.1-2" don't leave orphan ".13".
    # Matches: digit(s).digit(s), optional space + 2-4 letter book + numbers
    text = re.sub(r"\d+[\.:\-]\d+(?:[\.:\-]\d+)?", " ", text)
    # Strip any remaining digits
    text = re.sub(r"\d+", " ", text)
    # Strip bracketed annotations
    text = re.sub(r"\[[^\]]*\]", " ", text)

    # Collapse multiple spaces, strip
    text = re.sub(r"\s+", " ", text).strip()

    return text


def normalize_for_inference(text: str) -> str:
    """Apply inference-time normalization (used on vocab words before TTS).

    Includes everything in normalize_for_training PLUS strips low-tone
    grave accents (since the Bible never marked them, the model never
    learned to associate them with audio).
    """
    text = normalize_for_training(text)

    # Strip precomposed grave-accented vowels
    for k, v in GRAVE_VOWELS.items():
        text = text.replace(k, v)

    # Strip combining grave accent (decomposed form)
    text = unicodedata.normalize("NFD", text)
    text = text.replace(COMBINING_GRAVE, "")
    text = unicodedata.normalize("NFC", text)

    return text


# ===== Self-test =====

if __name__ == "__main__":
    cases = [
        # (input, expected training output, expected inference output)
        ("ŋgóonɛ́", "ngóonɛ́", "ngóonɛ́"),
        ("pɔ̀ŋɔ́", "pɔ̀ŋɔ́", "pɔŋɔ́"),  # grave stripped at inference
        ("Klisto", "Klisto", "Klisto"),
        ("apεnə", "apɛnə", "apɛnə"),  # Greek ε → Latin ɛ
        ("Don't", "Don't", "Don't"),  # curly quote → ASCII
    ]
    print("normalize_text.py self-test")
    print("=" * 60)
    failed = 0
    for inp, exp_train, exp_inf in cases:
        got_train = normalize_for_training(inp)
        got_inf = normalize_for_inference(inp)
        ok = (got_train == exp_train) and (got_inf == exp_inf)
        mark = "✓" if ok else "✗"
        if not ok:
            failed += 1
        print(f"  {mark} {inp!r}")
        print(f"      training:  {got_train!r}  (expected {exp_train!r})")
        print(f"      inference: {got_inf!r}  (expected {exp_inf!r})")
    print()
    print(f"  {len(cases) - failed}/{len(cases)} tests passed")
