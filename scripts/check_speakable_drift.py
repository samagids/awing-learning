#!/usr/bin/env python3
"""
Detect words whose awing_to_speakable() output changed since the last build,
so we can regenerate ONLY those audio clips instead of force-regenerating
all 9,000+ words.

How it works
------------
1. Walks lib/data/awing_vocabulary.dart (via generate_audio_edge._load_*
   helpers) to enumerate every Awing string currently in the app.
2. Computes awing_to_speakable(word) for each using the CURRENT rule set.
3. Compares against the cached output stored in scripts/_speakable_cache.json
   from the previous build.
4. Words whose cached output differs from the current output are "drifted" --
   their audio MP3s were baked with old rules and need regen.
5. Writes the drift list to contributions/rule_drift_words.json in the
   format generate_audio_edge.cmd_regenerate() expects:
       [{"awing": "..."}, {"awing": "..."}, ...]
6. Updates the cache to reflect the new outputs.

Bootstrap behaviour
-------------------
- Empty cache (first run, or cache deleted) -> populate cache, write
  EMPTY drift list. We don't force-regen 9k words on first adoption;
  the assumption is the existing baked audio matches the rules that
  were in effect when it was generated.
- New words in vocab (not in cache) -> NOT marked as drifted. They'll
  be picked up by the next normal `generate` run.

Exit code
---------
Always 0. Drift is informational, not an error. The build_and_run.sh
wrapper decides whether to fire `regenerate` based on the count it
reads back from rule_drift_words.json.

Usage
-----
    python scripts/check_speakable_drift.py            # update cache + write drift list
    python scripts/check_speakable_drift.py --dry-run  # print drift without writing
    python scripts/check_speakable_drift.py --reset    # wipe cache (next run is a bootstrap)
"""

import argparse
import json
import os
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent.resolve()
PROJECT_DIR = SCRIPT_DIR.parent
CACHE_PATH = SCRIPT_DIR / "_speakable_cache.json"
DRIFT_PATH = PROJECT_DIR / "contributions" / "rule_drift_words.json"

# Add scripts/ to sys.path so we can reuse the canonical phonetic mapping
# function -- this is the same code path generate_audio_edge.py uses, so
# any drift we detect is real and not a re-implementation drift.
sys.path.insert(0, str(SCRIPT_DIR))


def _import_generator():
    """Import generate_audio_edge lazily so this script doesn't pull in
    edge-tts at import time. (apply_contributions and similar scripts run
    in environments without edge-tts installed.)"""
    import importlib
    return importlib.import_module("generate_audio_edge")


def _enumerate_app_awing_texts(gae):
    """Return dict {audio_key: awing_text} for every Awing string the
    app generates audio for. Pulls from the same dart-parsing helpers
    generate_audio_edge uses for the production pipeline."""
    items = {}

    # Vocabulary (~9k words)
    for key, (awing, _difficulty) in gae._load_vocabulary_from_dart().items():
        items[key] = awing

    # Phrases (~40)
    try:
        for key, awing in gae._load_phrases_from_dart().items():
            items[key] = awing
    except Exception as e:
        print(f"  warning: phrases load failed: {e}", file=sys.stderr)

    return items


def _load_cache():
    if not CACHE_PATH.exists():
        return {}
    try:
        with open(CACHE_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
        # Cache shape: {audio_key: speakable_output_string}
        if isinstance(data, dict):
            return data
    except Exception as e:
        print(f"  warning: cache read failed ({e}); treating as empty", file=sys.stderr)
    return {}


def _save_cache(cache):
    CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(CACHE_PATH, "w", encoding="utf-8") as f:
        json.dump(cache, f, ensure_ascii=False, indent=2, sort_keys=True)


def _write_drift_list(drifted_awing_texts):
    DRIFT_PATH.parent.mkdir(parents=True, exist_ok=True)
    payload = [{"awing": t} for t in drifted_awing_texts]
    with open(DRIFT_PATH, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true",
                        help="Print drift detection without writing cache or drift list.")
    parser.add_argument("--reset", action="store_true",
                        help="Delete the cache and exit. Next run will bootstrap.")
    args = parser.parse_args()

    if args.reset:
        if CACHE_PATH.exists():
            CACHE_PATH.unlink()
            print(f"Deleted {CACHE_PATH}")
        if DRIFT_PATH.exists():
            DRIFT_PATH.unlink()
            print(f"Deleted {DRIFT_PATH}")
        return 0

    gae = _import_generator()

    items = _enumerate_app_awing_texts(gae)
    print(f"Enumerated {len(items)} Awing strings from app data")

    old_cache = _load_cache()
    bootstrap = len(old_cache) == 0
    if bootstrap:
        print("Cache empty -- BOOTSTRAP run. No regen will be triggered;")
        print("populating cache with current speakable outputs.")

    drifted = []
    new_words = 0
    new_cache = {}

    for key, awing in items.items():
        speakable = gae.awing_to_speakable(awing)
        new_cache[key] = speakable

        if bootstrap:
            continue

        if key not in old_cache:
            # New word -- not drift, will be picked up by next generate run
            new_words += 1
            continue

        if old_cache[key] != speakable:
            drifted.append(awing)

    print()
    print(f"  drifted (rule output changed): {len(drifted)}")
    print(f"  new words (never seen before): {new_words}")
    print(f"  total tracked: {len(new_cache)}")

    if drifted:
        print()
        print("  sample drifted words:")
        for w in drifted[:10]:
            print(f"    {w!r:30s} -> new speakable: {gae.awing_to_speakable(w)!r}")
        if len(drifted) > 10:
            print(f"    ... + {len(drifted)-10} more")

    if args.dry_run:
        print("\n[dry-run] cache + drift list NOT written.")
        return 0

    _save_cache(new_cache)
    _write_drift_list(drifted)
    print()
    print(f"  cache    -> {CACHE_PATH}")
    print(f"  drift    -> {DRIFT_PATH}  ({len(drifted)} entries)")
    print()
    if drifted:
        print("Next step (manual or automated by build_and_run.sh):")
        print(f"  python scripts/generate_audio_edge.py regenerate \\")
        print(f"    --regenerate-file {DRIFT_PATH.relative_to(PROJECT_DIR)}")
    else:
        print("No regen needed -- all speakable outputs match cache.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
