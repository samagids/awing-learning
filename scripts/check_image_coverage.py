#!/usr/bin/env python3
"""check_image_coverage.py — find vocabulary entries missing PNG images.

Compares awing_vocabulary.dart entries against actual files in
android/install_time_assets/src/main/assets/images/vocabulary/.

Image key format (matches lib/services/image_service.dart):
    {audio_key(awing)}__{english_slug(english)}.{png|webp}

Run: python scripts/check_image_coverage.py [--list]
"""

from __future__ import annotations

import argparse
import re
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VOCAB = ROOT / "lib" / "data" / "awing_vocabulary.dart"
IMAGES = ROOT / "android" / "install_time_assets" / "src" / "main" / "assets" / "images" / "vocabulary"


# THE KEY IS NOT REIMPLEMENTED HERE.
#
# This file used to carry its own audio_key() and english_slug(). They were
# the ORIGINAL format - english_slug() took only the first word of the gloss
# - and they were never updated when the key became
# audio_key(awing) + "__" + english_slug(whole gloss, truncated at 32),
# which is what scripts/awing_key.py, scripts/generate_images.py and
# lib/services/image_service.dart all use.
#
# So this checker measured the pack with a ruler nothing else used. On
# 2026-10-08, mid-generation, it reported "6,003 expected, 5,430 missing,
# 1,403 orphan" when 2,607 of the 4,600 rows simply hashed to a different
# name here than everywhere else. A coverage checker that disagrees with
# the thing it is checking is worse than no checker: it sends you looking
# for 4,000 images that are already on disk.
#
# RULE: awing_key.py is the only implementation. Import it.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from awing_key import audio_key, english_slug, image_key  # noqa: E402


# An awing word containing an apostrophe is written with double quotes in
# the Dart source ("afa'e apimne"), so a single-quote-only pattern silently
# skipped every one of them.
AWINGWORD_LINE = re.compile(
    r"""AwingWord\(\s*awing:\s*(?:'((?:[^'\\]|\\.)*?)'|"([^"]*?)")\s*,"""
    r"""\s*english:\s*'((?:[^'\\]|\\.)*?)'"""
)


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--list", action="store_true",
                   help="List every missing image key")
    p.add_argument("--write-keys", metavar="PATH", default=None,
                   help="Write every missing key, one per line, to PATH - "
                        "feed it straight to generate_images.py --keys-file. "
                        "Rule 1: every word must have an image.")
    args = p.parse_args()

    if not VOCAB.exists():
        print(f"ERROR: {VOCAB} not found", file=sys.stderr)
        return 1
    if not IMAGES.exists():
        print(f"ERROR: {IMAGES} not found", file=sys.stderr)
        return 1

    text = VOCAB.read_text(encoding="utf-8")

    # Session 66u commented out ~3,900 duplicate rows rather than deleting
    # them, so the file still CONTAINS them. Counting a commented row as a
    # word to illustrate inflated "expected" from 4,600 to 8,551 and turned
    # a nearly-finished run into "4,005 missing". A commented row is not a
    # card in the app; drop it before anything else.
    live = "\n".join(l for l in text.splitlines()
                     if not l.lstrip().startswith("//"))
    entries = AWINGWORD_LINE.findall(live)

    expected_keys = set()
    entry_to_key = []
    for awing_sq, awing_dq, english_raw in entries:
        awing = (awing_sq or awing_dq).replace(r"\'", "'")
        english = english_raw.replace(r"\'", "'")
        if not audio_key(awing) or not english_slug(english):
            continue
        key = image_key(awing, english)
        expected_keys.add(key)
        entry_to_key.append((awing, english, key))

    # Stems only, across both extensions — the library is WebP from
    # v1.24.0 on, with PNGs still around from older builds and from
    # apply_contributions.py.
    actual_files = {f.stem for f in IMAGES.glob("*.png")}
    actual_files |= {f.stem for f in IMAGES.glob("*.webp")}

    missing = expected_keys - actual_files
    extra = actual_files - expected_keys
    have = expected_keys & actual_files

    print(f"Vocabulary entries: {len(entries)}")
    print(f"Expected unique image keys: {len(expected_keys)}")
    print(f"Existing image files: {len(actual_files)}")
    print(f"  - covered (expected ∩ actual): {len(have)}")
    print(f"  - missing (need to generate): {len(missing)}")
    # Sentence and phrase cards are not in awing_vocabulary.dart - they
    # live in the screens - so counting them as orphans here is noise, and
    # noise is what gets a checker ignored.
    sent = {k for k in extra if k.startswith(("sentence_", "phrase_"))}
    real = extra - sent
    print(f"  - sentence/phrase images (not checked here): {len(sent)}")
    print(f"  - orphan (image with no live vocabulary row): {len(real)}")
    if real:
        print(f"      these are rows that were commented out; prune with:")
        print(f"      python scripts/generate_images.py prune")

    if args.write_keys:
        out = Path(args.write_keys)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text("\n".join(sorted(missing)) + "\n", encoding="utf-8")
        print(f"\n  wrote {len(missing)} missing keys -> {out}")

    if args.list and missing:
        print()
        print("Missing image keys (first 50):")
        # Show missing entries with their awing + english for context
        missing_with_context = [
            (a, e, k) for (a, e, k) in entry_to_key if k in missing
        ]
        for awing, english, key in missing_with_context[:50]:
            print(f"  {key}.*  ←  {awing!r} / {english[:40]!r}")
        if len(missing_with_context) > 50:
            print(f"  ... and {len(missing_with_context) - 50} more")

    return 0


if __name__ == "__main__":
    sys.exit(main())
