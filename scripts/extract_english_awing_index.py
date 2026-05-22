#!/usr/bin/env python3
"""
Extract the English-Awing index section of the Awing English Dictionary
(2007, Alomofor Christian, CABTAL) — pages 142-198 of the PDF (which
correspond to dictionary pages 140-196).

The index is a 2-column layout where each line maps:
  english_word    awing_word1, awing_word2, ...

Many English words have multiple Awing translations. Each Awing word
becomes its own AwingWord entry.

Output: contributions/dictionary_extract/index_pages_NNN-NNN.json

Usage:
    python scripts\\extract_english_awing_index.py
"""
from __future__ import annotations
import json
import re
import sys
from pathlib import Path

# Auto-activate venv (matches pattern used by other scripts)
ROOT = Path(__file__).resolve().parent.parent
VENV_PY = ROOT / "venv" / "Scripts" / "python.exe"
if VENV_PY.exists() and sys.executable.lower() != str(VENV_PY).lower():
    import subprocess
    sys.exit(subprocess.run([str(VENV_PY), __file__] + sys.argv[1:]).returncode)

PDF = ROOT / "awing-english-dictionary-and-english-awing-index_compress.pdf"
OUT_DIR = ROOT / "contributions" / "dictionary_extract"

# Page range: PDF pages 142-198 = dictionary pages 140-196
# (PDF has 2-page front matter prefix per Session 29 mapping)
PDF_PAGE_START = 142
PDF_PAGE_END = 198


def main():
    if not PDF.exists():
        print(f"ERROR: PDF not found at {PDF}")
        return 1

    # Lazy-import PyMuPDF so we can prompt for install on missing dep
    try:
        import fitz  # PyMuPDF
    except ImportError:
        print("PyMuPDF (fitz) not installed. Installing...")
        import subprocess
        r = subprocess.run(
            [sys.executable, "-m", "pip", "install", "pymupdf", "--quiet"],
            capture_output=True, text=True,
        )
        if r.returncode != 0:
            print(f"pip install failed: {r.stderr}")
            return 1
        import fitz  # noqa

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    doc = fitz.open(str(PDF))
    total_pages = doc.page_count
    print(f"PDF: {total_pages} pages total")
    end = min(PDF_PAGE_END, total_pages)
    print(f"Extracting English-Awing index pages {PDF_PAGE_START}-{end}")
    print()

    # ---------- Helper: parse a single page ----------
    # Strategy: extract text in reading order. Lines typically look like:
    #     english_word    awing_form (notes)
    # or:
    #     english_word    awing1, awing2, awing3
    # Header lines are letters A, B, C, etc. (single uppercase letter).
    # Skip header lines, footer page numbers, and continuation lines.

    # Regex for a candidate index line:
    # - Starts with lowercase English word (possibly hyphenated)
    # - Followed by whitespace
    # - Followed by Awing form (containing Awing-specific chars OR
    #   common Awing letter patterns)
    LINE_RE = re.compile(
        r"^([a-z][a-z\-' ]*[a-z])\s{2,}(.+)$",
        re.IGNORECASE,
    )
    # Lines that are page numbers / headers / decorations to skip
    SKIP_RE = re.compile(
        r"^(\d+\s*$|[A-Z]\s*$|[A-Z][A-Z]+\s*$|Page\s+\d+|.{0,2}$)",
    )

    all_entries = []
    raw_lines_kept = 0
    raw_lines_skipped = 0

    for pno in range(PDF_PAGE_START - 1, end):  # fitz is 0-indexed
        page = doc.load_page(pno)
        # blocks=text gives best column-merge for 2-col index
        text = page.get_text("text")
        page_num_in_dict = pno + 1 - 2  # dictionary numbering offset

        for raw_line in text.split("\n"):
            line = raw_line.strip()
            if not line:
                continue
            if SKIP_RE.match(line):
                raw_lines_skipped += 1
                continue
            # Try the 2-column pattern
            m = LINE_RE.match(line)
            if not m:
                raw_lines_skipped += 1
                continue
            english = m.group(1).strip().lower()
            awing_raw = m.group(2).strip()

            # Strip parenthetical notes from awing field
            # "njuə (also: tə njuə)" → primary form only
            awing_clean = re.sub(r"\([^)]*\)", "", awing_raw).strip()
            # Split multiple Awing translations on comma or semicolon
            awing_parts = re.split(r"[,;]\s*", awing_clean)

            for awing in awing_parts:
                awing = awing.strip().rstrip(".,;")
                if not awing:
                    continue
                # Skip purely-numeric, single-letter, or clearly malformed
                if len(awing) < 2:
                    continue
                if awing.isdigit():
                    continue
                # Skip if no Awing characters AND no vowel — likely garbage
                if not re.search(r"[aeiouɛəɔɨəa-z]", awing.lower()):
                    continue
                all_entries.append({
                    "awing": awing,
                    "english": english,
                    "page": page_num_in_dict,
                    "source": "english_awing_index",
                })
                raw_lines_kept += 1

    print(f"Extracted {len(all_entries):,} (Awing, English) pairs")
    print(f"Lines kept: {raw_lines_kept:,}")
    print(f"Lines skipped: {raw_lines_skipped:,}")

    # Dedup exact duplicates within the index itself
    seen = set()
    deduped = []
    for e in all_entries:
        key = (e["awing"], e["english"])
        if key in seen: continue
        seen.add(key)
        deduped.append(e)
    print(f"After internal dedup: {len(deduped):,}")

    # Chunk into separate JSON files matching the existing convention
    # Roughly 350 entries per file
    chunk_size = 400
    chunks = [deduped[i:i+chunk_size] for i in range(0, len(deduped), chunk_size)]
    for idx, chunk in enumerate(chunks):
        out_path = OUT_DIR / f"index_chunk_{idx+1:02d}.json"
        out_path.write_text(
            json.dumps(chunk, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
        print(f"  Wrote {out_path.name}: {len(chunk):,} entries")

    print()
    print(f"✓ Done. {len(deduped):,} index entries in {len(chunks)} JSON files.")
    print(f"  Next: rerun python scripts\\mine_pdfs_to_8000.py")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
