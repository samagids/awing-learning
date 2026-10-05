#!/usr/bin/env python3
"""build_image_manifest.py — write assets/image_manifest.json.

Scans the PAD asset pack images directory and produces a tiny JSON manifest
of every image filename stem (without the extension). The Flutter app
loads this
manifest at startup so it can synchronously check whether an image exists
BEFORE selecting a vocabulary word for a game / quiz / exam round.

Without the manifest, the only "does this image exist?" check is async via
the platform channel into the PAD pack, which can't be used in a sync
List.where() filter. With the manifest, games filter cleanly:
    final eligible = vocab.where((w) =>
        ImageService.instance.hasImageSync(w.awing, w.english));

Output: assets/image_manifest.json
Schema:
  {
    "generated_at": "2026-05-27T01:23:45Z",
    "count": 7182,
    "keys": ["azoangwune__yam_sort_of", "achi__sign", ...]
  }

The manifest is bundled in the MAIN app bundle (not the PAD pack) so it's
available immediately on app launch — before PAD asset loads complete.

Run this from:
  • scripts/pack_and_upload_assets.sh (auto, on every tarball repack)
  • scripts/build_and_run.bat        (auto, every local build)
  • Manually:  python scripts/build_image_manifest.py
"""

import json
import os
import sys
from datetime import datetime, timezone

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG_DIR = os.path.join(
    REPO_ROOT,
    'android', 'install_time_assets', 'src', 'main', 'assets',
    'images', 'vocabulary',
)
OUTPUT = os.path.join(REPO_ROOT, 'assets', 'image_manifest.json')


def main():
    if not os.path.isdir(IMG_DIR):
        print(f'✗ Image dir not found: {IMG_DIR}')
        print('  Run scripts/generate_images.py first.')
        return 1

    # Accept both extensions. v1.24.0 regenerates the library as WebP, but
    # PNGs linger (older builds, community images installed by
    # apply_contributions.py), and during a partial regeneration the SAME
    # stem can exist as both — hence the set, so the manifest never lists a
    # key twice. ImageService._imageExtensions must accept the same set.
    exts = ('.webp', '.png')
    stems = set()
    for fn in os.listdir(IMG_DIR):
        for ext in exts:
            if fn.endswith(ext):
                stems.add(fn[:-len(ext)])
                break
    keys = sorted(stems)

    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
    payload = {
        'generated_at': datetime.now(timezone.utc).isoformat(),
        'count': len(keys),
        'keys': keys,
    }
    with open(OUTPUT, 'w', encoding='utf-8') as f:
        # Compact JSON — keys is a long list, no need for pretty indent.
        # Save ~30% file size on a 7000-entry manifest.
        json.dump(payload, f, ensure_ascii=False, separators=(',', ':'))

    size_kb = os.path.getsize(OUTPUT) / 1024
    print(f'✓ Wrote {len(keys)} image keys to:')
    print(f'  {OUTPUT}')
    print(f'  ({size_kb:.1f} KB)')
    return 0


if __name__ == '__main__':
    sys.exit(main() or 0)
