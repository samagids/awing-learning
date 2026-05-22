#!/usr/bin/env python3
"""Dump raw lines from PDF pages 142-145 of the dictionary so we can see
what PyMuPDF text extraction actually produces. Diagnostic only."""
from __future__ import annotations
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VENV_PY = ROOT / "venv" / "Scripts" / "python.exe"
if VENV_PY.exists() and sys.executable.lower() != str(VENV_PY).lower():
    import subprocess
    sys.exit(subprocess.run([str(VENV_PY), __file__] + sys.argv[1:]).returncode)

import fitz
PDF = ROOT / "awing-english-dictionary-and-english-awing-index_compress.pdf"

doc = fitz.open(str(PDF))
for pno in (141, 142, 143, 144):  # 0-indexed, so PDF pages 142-145
    page = doc.load_page(pno)
    text = page.get_text("text")
    print(f"\n========== PDF PAGE {pno+1} ==========")
    lines = text.split("\n")
    print(f"Total lines on page: {len(lines)}")
    print(f"--- First 60 lines (raw, with repr) ---")
    for i, ln in enumerate(lines[:60]):
        print(f"  {i:3d} | {ln!r}")
    if len(lines) > 60:
        print(f"  ... ({len(lines)-60} more lines)")
