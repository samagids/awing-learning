#!/usr/bin/env python3
"""
Extract embedded Awing example sentences from dictionary Format B entries.

Format B english fields embed example sentences like:
  "1) big. Pi pə́ wiŋ pó chîə á Ndəwálə̌ náənə. There are many great
   people in Douala. 2) great. 3) adjective for VIP. Sg.s: wiŋ"

We extract these (Awing-sentence, English-sentence) pairs, filter out
religious content, dedup, categorize by length, and write to
contributions/dict_extracted_sentences.json for review/integration.

Output is a JSON list of:
  { "awing": "...", "english": "...", "source_word": "...", "page": N,
    "length_bucket": "short|medium|long" }
"""
from __future__ import annotations
import json
import re
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DICT_DIR = ROOT / "contributions" / "dictionary_extract"
OUT_FILE = ROOT / "contributions" / "dict_extracted_sentences.json"

# Awing-specific characters — at least one must appear in extracted Awing
AWING_CHARS_RE = re.compile(r"[əɛɔɨŋɣÆ]|[̀-ͯ]")  # NFD tone marks

# Religious filter — drop sentences whose ENGLISH side mentions God,
# Jesus, sacrifice, etc.
RELIGIOUS_RE = re.compile(
    r"\b(god|jesus|christ|messiah|gospel|scripture|bible|apostle|prophet|"
    r"disciple|pharisee|sadducee|centurion|baptism|baptize|crucify|"
    r"resurrection|covenant|tabernacle|pharaoh|sin|satan|devil|heaven|hell|"
    r"holy spirit|kingdom of god|lord)\b", re.IGNORECASE
)

# Also drop sentences with these Awing religious-vocab tokens
AWING_RELIGIOUS_RE = re.compile(
    r"\b(Yésə|Klistə|Əsê|Pɔlə|Pəjus|Jɛlusalɛm|Yelusalemə|nəwùə Yésə)\b"
)


def find_sentence_pairs(english_field: str):
    """
    Find (Awing, English) sentence pairs embedded in a dictionary english
    field. Pattern: Awing sentence ends with period, immediately followed by
    English sentence ending with period.
    """
    pairs = []
    # Strip leading "1) big. " style numbered prefix
    text = english_field

    # Find sentences. Heuristic: split on `. ` and look for Awing-then-English
    # pairs. Awing sentences contain at least one Awing-specific character.
    # We split keeping sentence-terminating punctuation:
    parts = re.split(r"(?<=[.!?])\s+", text)

    i = 0
    while i < len(parts) - 1:
        candidate_awing = parts[i].strip().rstrip(".,;:")
        candidate_eng = parts[i + 1].strip().rstrip(".,;:")

        # Awing candidate must:
        #  - Have at least one Awing-specific character
        #  - Be at least 12 chars (avoid single-word noise)
        #  - Be at most 200 chars (avoid runaway captures)
        #  - Start with a capital letter (sentence start)
        #  - Have at least one space (multi-word)
        if (AWING_CHARS_RE.search(candidate_awing)
            and 12 <= len(candidate_awing) <= 200
            and " " in candidate_awing
            and candidate_awing[0:1].isupper()):

            # English candidate must:
            #  - Be at least 10 chars
            #  - Be mostly ASCII (no Awing chars)
            #  - Not be a verb-form annotation (V.s: / Sg.s:)
            #  - Start with a capital
            if (10 <= len(candidate_eng) <= 250
                and not AWING_CHARS_RE.search(candidate_eng)
                and not re.match(r"^(V\.s|V\.p\.s|Sg\.s|Pl\.s|Pl\.|S\.|Sg\.|cf\.)", candidate_eng)
                and candidate_eng[0:1].isupper()):
                pairs.append((candidate_awing + ".", candidate_eng + "."))
                i += 2  # advance past both
                continue
        i += 1
    return pairs


def length_bucket(awing: str) -> str:
    word_count = len(awing.split())
    if word_count <= 6: return "short"
    if word_count <= 12: return "medium"
    return "long"


def main():
    # Load all Format B JSON files (only they have the embedded example
    # sentences — Format A is just headword/gloss)
    json_files = sorted(DICT_DIR.glob("pages_*.json"))
    all_pairs = []
    seen = set()
    n_files_processed = 0
    n_format_b = 0
    skipped_religious = 0

    for jf in json_files:
        try:
            data = json.loads(jf.read_text(encoding="utf-8"))
        except Exception:
            continue
        n_files_processed += 1

        # Only Format B has wrapper + embedded examples
        if not isinstance(data, dict) or "entries" not in data:
            continue
        n_format_b += 1

        page_label = data.get("dict_pages", data.get("pages", "?"))
        for entry in data.get("entries", []):
            if not isinstance(entry, dict): continue
            eng_field = entry.get("english", "")
            headword = entry.get("awing", "")
            if not eng_field: continue

            for awing_sent, eng_sent in find_sentence_pairs(eng_field):
                # Religious filter
                if RELIGIOUS_RE.search(eng_sent) or AWING_RELIGIOUS_RE.search(awing_sent):
                    skipped_religious += 1
                    continue
                # Dedup by (awing, english)
                key = (awing_sent, eng_sent)
                if key in seen: continue
                seen.add(key)
                all_pairs.append({
                    "awing": awing_sent,
                    "english": eng_sent,
                    "source_word": headword,
                    "page": page_label,
                    "length_bucket": length_bucket(awing_sent),
                })

    # Bucket counts
    buckets = {"short": 0, "medium": 0, "long": 0}
    for p in all_pairs:
        buckets[p["length_bucket"]] += 1

    print(f"Files scanned: {n_files_processed}")
    print(f"Format B files (have example sentences): {n_format_b}")
    print(f"Religious sentences skipped: {skipped_religious}")
    print(f"\nClean sentence pairs extracted: {len(all_pairs):,}")
    print(f"  short  (≤6 Awing words):  {buckets['short']:,}")
    print(f"  medium (7-12 Awing words): {buckets['medium']:,}")
    print(f"  long   (>12 Awing words):  {buckets['long']:,}")

    OUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    OUT_FILE.write_text(
        json.dumps(all_pairs, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"\nSaved: {OUT_FILE.relative_to(ROOT)}")
    print(f"\nNEXT STEP: review the file, then a small splice script will")
    print(f"add the short ones to sentences_screen.dart, medium to expert")
    print(f"quiz paragraphs, long to stories.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
