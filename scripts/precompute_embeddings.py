#!/usr/bin/env python3
"""
precompute_embeddings.py
------------------------
Run the sentence-transformers all-MiniLM-L6-v2 model ONCE offline to
generate embeddings for every (awing, english) pair in the vocab. Saves
the result as a packed binary file the Flutter app loads at runtime —
no need to re-tokenize+infer 9000 entries on every app launch.

Output: assets/vocab_embeddings.bin
        Format: <4-byte little-endian uint32: N entries>
                <repeated N times>
                  <4-byte uint32: key_length>
                  <key_length bytes: utf-8 'awing|english'>
                  <384 × 4-byte little-endian float32: embedding>

Size: ~14 MB for 9000 entries.

Also outputs: assets/vocab_embeddings_keys.txt
              (one 'awing|english' key per line, in same order as binary)

Usage:
    python scripts/precompute_embeddings.py

Auto-activates venv_tf (the env used by convert_model.py).
"""

import os
import sys
import re
import struct
from pathlib import Path

SCRIPT_DIR = Path(os.path.dirname(os.path.abspath(__file__)))
REPO_ROOT = SCRIPT_DIR.parent

# Auto-activate venv_tf
VENV_DIR = REPO_ROOT / "venv_tf"
if not VENV_DIR.exists():
    VENV_DIR = REPO_ROOT / "venv"
if VENV_DIR.exists() and sys.prefix == sys.base_prefix:
    import subprocess
    if sys.platform == "win32":
        venv_python = str(VENV_DIR / "Scripts" / "python.exe")
    else:
        venv_python = str(VENV_DIR / "bin" / "python")
    if os.path.exists(venv_python) and \
            os.path.abspath(venv_python) != os.path.abspath(sys.executable):
        print("  Auto-activating virtual environment...")
        result = subprocess.run([venv_python] + sys.argv)
        sys.exit(result.returncode)

VOCAB_FILE = REPO_ROOT / "lib" / "data" / "awing_vocabulary.dart"
OUTPUT_BIN = REPO_ROOT / "android" / "install_time_assets" / "src" / \
    "main" / "assets" / "vocab_embeddings.bin"
OUTPUT_KEYS = REPO_ROOT / "android" / "install_time_assets" / "src" / \
    "main" / "assets" / "vocab_embeddings_keys.txt"
EMBED_DIM = 384


def parse_vocabulary():
    """Read all active AwingWord literals from the Dart vocab file.
    Returns a list of (awing, english) tuples in source order, with
    exact duplicates collapsed (matches the app's lookup behavior)."""
    sq = r"'((?:\\.|[^'\\])*)'"
    dq = r'"((?:\\.|[^"\\])*)"'
    s = rf"(?:{sq}|{dq})"
    pat = re.compile(
        rf"AwingWord\(\s*awing:\s*{s}\s*,\s*english:\s*{s}\s*,\s*category:\s*{s}",
        re.DOTALL,
    )

    content = VOCAB_FILE.read_text(encoding='utf-8')
    seen_keys = set()
    entries = []
    for m in pat.finditer(content):
        # Skip commented lines
        line_start = content.rfind('\n', 0, m.start()) + 1
        if '//' in content[line_start:m.start()]:
            continue
        awing = (m.group(1) if m.group(1) else m.group(2) or '').strip()
        english = (m.group(3) if m.group(3) else m.group(4) or '').strip()
        if not awing or not english:
            continue
        # Unescape
        awing = awing.replace("\\'", "'").replace('\\"', '"').replace('\\\\', '\\')
        english = english.replace("\\'", "'").replace('\\"', '"').replace('\\\\', '\\')
        key = f"{awing}|{english}"
        if key in seen_keys:
            continue
        seen_keys.add(key)
        entries.append((awing, english))
    return entries


def main():
    try:
        from sentence_transformers import SentenceTransformer
    except ImportError:
        print("Missing dep: pip install sentence-transformers")
        sys.exit(1)

    print(f"Loading sentence-transformers/all-MiniLM-L6-v2...")
    model = SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2")

    print(f"Parsing {VOCAB_FILE}...")
    entries = parse_vocabulary()
    print(f"  Got {len(entries)} unique (awing, english) pairs")

    # The model embeds the ENGLISH glosses (it's an English-only model).
    # Awing is the lookup key but the semantic content is in the English.
    texts = [e[1] for e in entries]

    print(f"Computing embeddings (this may take a few minutes)...")
    embeds = model.encode(
        texts,
        batch_size=64,
        show_progress_bar=True,
        normalize_embeddings=True,
    )
    print(f"  Got {len(embeds)} × {EMBED_DIM} embeddings")
    assert embeds.shape[1] == EMBED_DIM

    # Pack to binary
    OUTPUT_BIN.parent.mkdir(parents=True, exist_ok=True)
    print(f"Writing {OUTPUT_BIN}...")
    with open(OUTPUT_BIN, "wb") as f:
        f.write(struct.pack("<I", len(entries)))
        for (awing, english), vec in zip(entries, embeds):
            key = f"{awing}|{english}".encode("utf-8")
            f.write(struct.pack("<I", len(key)))
            f.write(key)
            f.write(struct.pack(f"<{EMBED_DIM}f", *vec.tolist()))

    # Keys file (for sanity-checking + Dart-side debug)
    print(f"Writing {OUTPUT_KEYS}...")
    with open(OUTPUT_KEYS, "w", encoding="utf-8") as f:
        for awing, english in entries:
            f.write(f"{awing}|{english}\n")

    size_mb = OUTPUT_BIN.stat().st_size / (1024 * 1024)
    print(f"\nDone. {len(entries)} embeddings → {size_mb:.1f} MB")


if __name__ == "__main__":
    main()
