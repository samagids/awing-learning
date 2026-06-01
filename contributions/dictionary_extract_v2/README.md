# Dictionary Extraction v2 — Completion Workflow

## Current state (end of Session 61)

- Total active vocabulary entries: ~5,518 (was 5,458 before v2 merge)
- v2 extraction has covered: 3 of ~125 pages (pages 48, 88, 92)
- Pages already rendered as PNG: `outputs/dict_pages_v2/p-013.png` through `p-138.png`
- Merge script in place: `scripts/merge_dict_v2.py`

## What's left

About 122 more pages to extract from the Awing→English section.
Per Alomofor's claim of ~12,000 entries vs Session 50's 3,094, each page
likely has ~50-90 entries (including sub-entries, V.s/Pl./Sg.s forms).
Each page takes ~5 min of careful Claude vision extraction.

## Per-page workflow (for future Claude sessions)

1. Read the rendered PNG:
   `Read outputs/dict_pages_v2/p-NNN.png`

2. For each entry visible on the page, capture:
   - `awing`: the headword (Awing word)
   - `phonetic`: text in [phonetic brackets]
   - `pos`: part-of-speech marker (n., v., adj., adv., num., ideo., etc)
   - `noun_class`: if shown (e.g. "1/2", "9/6")
   - `english`: meaning (truncated to ~80 chars; keep multiple senses)
   - `plural`: from Pl.: marker
   - `vs`: from V.s: marker (verb stem)
   - `shortform`: from S.: marker if present

3. Save to JSON:
   `contributions/dictionary_extract_v2/page_NNN.json`

4. Run merge (skips entries already in vocab):
   `python3 scripts/merge_dict_v2.py --dry-run` (verify count)
   `python3 scripts/merge_dict_v2.py` (apply)

## Decoded OCR mapping (for reference)

The dictionary PDF is a scan. OCR consistently transforms:
- `nə` → `na` (schwa → a at word start)
- `-ə` final → `-a`
- `ô` → `d` or `o` (tone lost)
- `ú` → `t` or `i`
- `ŋ` → `n` or `Hg` or `hg`
- Tone diacritics → lost or wrong

When reading the rendered image directly, ignore the OCR and transcribe
what you SEE in the rendered glyphs. Awing characters: ɛ, ɔ, ə, ɨ, ŋ, ɣ.
Tones: ´ (high) ` (low) ^ (falling) ˇ (rising) (mid = unmarked).

## What this gains the app

- Vision extraction captures sub-entries (V.s, Pl., S.) that Session 50 missed
- Per-page yield: ~40-50 entries vs Session 50's 20-30/page (~50% more)
- Estimated additional entries when complete: ~2,500-4,000
- Total after completion: ~8,000-9,500 (closer to Alomofor's 12,000)

## Honest caveat

We won't hit 12,000 even with perfect extraction because:
1. Many "entries" Alomofor counts may include example phrases / senses
2. Dialectal alternates not in the formal dictionary
3. Compound phrases used as proverbs

Realistic ceiling: ~9,000-10,000 unique vocabulary entries.
