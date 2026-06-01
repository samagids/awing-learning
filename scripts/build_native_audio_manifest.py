#!/usr/bin/env python3
"""build_native_audio_manifest.py — scan the install_time_assets audio tree
and emit a flat manifest of which (audioKey, recorder) pairs have a clip.

The Dev Mode Record tab loads this manifest at runtime to:
  1. Show per-item badges (which recorders have recorded each word).
  2. Power the new "Missing from [active recorder]" filter so the dev
     can quickly find words that the currently-selected recorder
     hasn't covered yet.
  3. Distinguish "Dr. Sama recorded it" (canonical native/) from
     "kid X recorded it" (native_kids/<slug>/) — important because
     under the new architecture (post-2026-05-27) kid recordings
     NEVER land in canonical, so a kid's voice for word X means
     ONLY that the per-kid file exists.

Manifest format:
    {
      "version": 1,
      "generated_at": "ISO8601",
      "categories": {
        "vocabulary": {
          "apo":   {"canonical": true, "kids": ["joel", "joyce"]},
          "atue":  {"canonical": false, "kids": ["joel"]},
          ...
        },
        "alphabet": {
          "a": {"canonical": true, "kids": []},
          ...
        }
      }
    }

Hooks into build_and_run.bat after apply_recordings_as_audio.py
(Step 1d). The output file ships as a Flutter asset (assets/), bundled
into the main APK — NOT into the install_time_assets PAD pack, since
the app needs it at startup before PAD downloads finish.
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

# Force UTF-8 stdout/stderr so log lines don't crash on Windows when
# piped (cp1252 fallback). See identical block in sync_recordings.py.
for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, 'reconfigure'):
        try:
            _stream.reconfigure(encoding='utf-8', errors='replace')
        except Exception:
            pass

REPO_ROOT = Path(__file__).resolve().parents[1]
AUDIO_ROOT = REPO_ROOT / "android" / "install_time_assets" / "src" / "main" / "assets" / "audio"
NATIVE_DIR = AUDIO_ROOT / "native"
KIDS_DIR = AUDIO_ROOT / "native_kids"
OUTPUT = REPO_ROOT / "assets" / "native_audio_manifest.json"
RECORDINGS_MANIFEST = REPO_ROOT / "training_data" / "recordings" / "manifest.json"

# Same recorder-slug normalization as sync_recordings.py.
# Returned values are used to identify WHICH adult owns each canonical
# audio clip so the Dev Mode Record tab can show distinct S (Dr. Sama)
# vs B (Berlin) dots instead of a single ambiguous "someone recorded
# this" indicator.
_RECORDER_ALIASES = {
    'joel': 'joel', 'janelle': 'janelle',
    'joyce': 'joyce', 'jadyne': 'jadyne',
    'sama': 'samagids', 'samagids': 'samagids',
    'samagids@gmail.com': 'samagids',
    'samagidshop@gmail.com': 'samagids',
    'guidion': 'samagids', 'guidion sama': 'samagids',
    'dr guidion sama': 'samagids', 'dr. guidion sama': 'samagids',
    'dr. sama': 'samagids', 'dr sama': 'samagids',
    'berlin': 'berlin', 'berlin sama': 'berlin',
}


def _normalize_recorder(name):
    if not name:
        return None
    norm = str(name).strip().lower()
    if not norm:
        return None
    if norm in _RECORDER_ALIASES:
        return _RECORDER_ALIASES[norm]
    first = norm.split()[0] if norm else ''
    return _RECORDER_ALIASES.get(first)


def scan_canonical():
    """Walk audio/native/<category>/*.mp3. Returns dict[category -> set[key]]."""
    out = {}
    if not NATIVE_DIR.exists():
        return out
    for cat_dir in sorted(NATIVE_DIR.iterdir()):
        if not cat_dir.is_dir():
            continue
        category = cat_dir.name
        keys = {p.stem for p in cat_dir.glob("*.mp3")}
        if keys:
            out[category] = keys
    return out


def scan_kids():
    """Walk audio/native_kids/<slug>/<category>/*.mp3.
    Returns dict[category -> dict[key -> set[slug]]]."""
    out = {}  # category -> key -> set[slug]
    if not KIDS_DIR.exists():
        return out
    for slug_dir in sorted(KIDS_DIR.iterdir()):
        if not slug_dir.is_dir():
            continue
        slug = slug_dir.name
        for cat_dir in slug_dir.iterdir():
            if not cat_dir.is_dir():
                continue
            category = cat_dir.name
            for mp3 in cat_dir.glob("*.mp3"):
                key = mp3.stem
                out.setdefault(category, {}).setdefault(key, set()).add(slug)
    return out


def scan_canonical_owners():
    """Cross-reference training_data/recordings/manifest.json to figure
    out which ADULT recorded each canonical audio clip. Without this,
    the Dev Mode Record tab can't distinguish Dr. Sama from Berlin Sama
    in the coverage dots — both write to the same canonical path.

    Returns dict[audio_key -> adult_slug] where adult_slug is one of
    'samagids' / 'berlin' / None (unknown contributor). Newest entry per
    audio_key wins, since canonical only stores one MP3 per word and
    later writes overwrite earlier ones.
    """
    owners = {}  # audio_key -> (slug, downloaded_at)
    if not RECORDINGS_MANIFEST.exists():
        return {}
    try:
        with RECORDINGS_MANIFEST.open(encoding='utf-8') as f:
            data = json.load(f)
    except (json.JSONDecodeError, OSError):
        return {}
    if not isinstance(data, list):
        return {}
    for entry in data:
        if not isinstance(entry, dict):
            continue
        slug = _normalize_recorder(entry.get('recorder'))
        # Skip kid recorders — they don't write to canonical (per the
        # apply_recordings_as_audio.py architecture). Only adults
        # (Dr. Sama, Berlin Sama) and unknowns own canonical entries.
        if slug in {'joel', 'janelle', 'joyce', 'jadyne'}:
            continue
        awing = (entry.get('awing') or '').strip()
        if not awing:
            continue
        # The audio_key in the manifest entries isn't always present;
        # re-derive it the same way apply_recordings_as_audio.py does.
        # Mirrors the audio_key() function there exactly.
        key = _audio_key(awing)
        ts = entry.get('downloaded_at') or ''
        existing = owners.get(key)
        if existing is None or ts > existing[1]:
            owners[key] = (slug, ts)
    return {k: v[0] for k, v in owners.items()}


_TONE_DIACRITICS = {"́", "̀", "̂", "̌", "̃", "̄"}
_REPLACEMENTS = {
    "ɛ": "e", "Ɛ": "E", "ɔ": "o", "Ɔ": "O",
    "ə": "e", "Ə": "E", "ɨ": "i", "Ɨ": "I",
    "ŋ": "ng", "Ŋ": "Ng", "ɣ": "g", "Ɣ": "G",
    "ʼ": "", "’": "", "‘": "", "'": "",
}


def _audio_key(awing):
    """Same audio_key derivation as scripts/apply_recordings_as_audio.py
    so canonical owner lookups match the actual MP3 filenames on disk."""
    import unicodedata
    import re
    if not awing:
        return ''
    decomp = unicodedata.normalize("NFD", awing)
    decomp = "".join(c for c in decomp if c not in _TONE_DIACRITICS)
    s = unicodedata.normalize("NFC", decomp)
    for src, dst in _REPLACEMENTS.items():
        s = s.replace(src, dst)
    s = re.sub(r"[^a-zA-Z0-9_-]+", "_", s)
    s = re.sub(r"_+", "_", s).strip("_")
    return s.lower() or "_"


def build_manifest():
    canonical = scan_canonical()
    kids = scan_kids()
    canonical_owners = scan_canonical_owners()

    # Union all categories + keys we saw in either tree.
    categories = {}
    all_cats = set(canonical.keys()) | set(kids.keys())
    for cat in sorted(all_cats):
        cat_canonical = canonical.get(cat, set())
        cat_kids = kids.get(cat, {})
        all_keys = cat_canonical | set(cat_kids.keys())
        category_entries = {}
        for key in sorted(all_keys):
            entry = {
                "canonical": key in cat_canonical,
                "kids": sorted(cat_kids.get(key, set())),
            }
            # Tag canonical-owning adult slug when we know it. Lets
            # the Record-tab UI distinguish S (Dr. Sama) vs B (Berlin)
            # dots. None means "canonical exists but no manifest entry
            # records who" (older Dr. Sama recordings predating the
            # downloaded_at field, or process_family_recordings.py
            # legacy writes).
            if key in cat_canonical:
                owner = canonical_owners.get(key)
                if owner:
                    entry["canonical_recorder"] = owner
            category_entries[key] = entry
        if category_entries:
            categories[cat] = category_entries

    manifest = {
        "version": 2,  # bumped: now includes canonical_recorder
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "categories": categories,
    }
    return manifest


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--quiet", action="store_true",
                    help="Suppress per-category counts; only print summary.")
    args = ap.parse_args()

    manifest = build_manifest()
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    # Summary
    total_keys = 0
    canonical_count = 0
    kid_totals = {}
    for cat, entries in manifest["categories"].items():
        if not args.quiet:
            cat_canonical = sum(1 for e in entries.values() if e["canonical"])
            cat_kids = sum(1 for e in entries.values() if e["kids"])
            print(f"  {cat:12s}  {len(entries):4d} keys  "
                  f"({cat_canonical} canonical, {cat_kids} with kid recordings)")
        for key, info in entries.items():
            total_keys += 1
            if info["canonical"]:
                canonical_count += 1
            for slug in info["kids"]:
                kid_totals[slug] = kid_totals.get(slug, 0) + 1

    size_kb = OUTPUT.stat().st_size / 1024
    print()
    print(f"✓ Wrote {total_keys} entries to:")
    print(f"  {OUTPUT.relative_to(REPO_ROOT)}")
    print(f"  ({size_kb:.1f} KB)")
    print(f"  Canonical: {canonical_count}")
    if kid_totals:
        print(f"  Per-kid:   {kid_totals}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
