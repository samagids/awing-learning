#!/usr/bin/env python3
"""Fail when the PAD asset bundle does not match what this commit expects.

WHY THIS EXISTS
---------------
v1.24.0+143 was tagged, went green, and uploaded a 958 MB AAB to the Play
alpha track. The local build of the same commit was 292.5 MB. CI does not
build from the dev machine: it downloads pad-assets.tar.gz from the
'pad-assets' GitHub release, and that tarball had not been re-uploaded since
2026-07-05. The alpha shipped July's assets.

Every guard that existed tested PRESENCE ("did the release download?"). A
stale bundle passes that test perfectly. 369 native audio files recorded
after July were missing too, so v1.23.5 and v1.23.6 almost certainly shipped
without them and nobody noticed.

The property that actually matters is: the bundle contains exactly what the
two committed manifests say the app will look for. Those manifests are
regenerated from local disk by build_and_run.bat and by
pack_and_upload_assets.sh, and they ship in the MAIN app bundle — so a
mismatch is a runtime bug (hasImageSync lies, audio buttons point at nothing)
as well as a staleness signal.

Usage:
    python3 scripts/verify_asset_bundle.py <asset-root>

<asset-root> is the directory the tarball was extracted into:
    android/install_time_assets/src/main/assets   (Android)
    ios/Runner/PADAssets                          (iOS)
"""
import json
import os
import sys

SAMPLE = 5


def stems(d, cache={}):
    if d not in cache:
        cache[d] = ({os.path.splitext(f)[0] for f in os.listdir(d)}
                    if os.path.isdir(d) else set())
    return cache[d]


def main(base):
    problems = []
    notes = []

    # ---- images -------------------------------------------------------
    img_dir = os.path.join(base, "images", "vocabulary")
    if not os.path.isdir(img_dir):
        problems.append(f"no image directory at {img_dir}")
    else:
        files = os.listdir(img_dir)
        disk = {os.path.splitext(f)[0] for f in files}
        man = set(json.load(open("assets/image_manifest.json",
                                 encoding="utf-8"))["keys"])
        webp = sum(1 for f in files if f.lower().endswith(".webp"))
        notes.append(f"images: manifest {len(man)}, pack {len(disk)}, "
                     f"webp {webp}/{len(files)}")
        missing, extra = man - disk, disk - man
        if missing:
            problems.append(
                f"{len(missing)} image key(s) in assets/image_manifest.json are "
                f"NOT in the pack, e.g. {sorted(missing)[:SAMPLE]}")
        if extra:
            problems.append(
                f"{len(extra)} image file(s) in the pack are NOT in "
                f"assets/image_manifest.json, e.g. {sorted(extra)[:SAMPLE]}")
        # v1.24.0 moved the pack to WebP. A PNG-era tarball fails here even
        # if the key sets happen to line up, because the stems are the same.
        if files and webp / len(files) < 0.95:
            problems.append(
                f"only {webp}/{len(files)} images are WebP — this looks like a "
                f"pre-v1.24.0 PNG pack")

    # ---- native audio -------------------------------------------------
    audio_dir = os.path.join(base, "audio")
    nm = json.load(open("assets/native_audio_manifest.json", encoding="utf-8"))
    missing_canonical, missing_kid = [], []
    canonical_total = kid_total = 0
    for cat, entries in (nm.get("categories") or {}).items():
        have = stems(os.path.join(audio_dir, "native", cat))
        for key, info in entries.items():
            if info.get("canonical"):
                canonical_total += 1
                if key not in have:
                    missing_canonical.append(f"{cat}/{key}")
            for kid in info.get("kids") or []:
                kid_total += 1
                # kid recordings are filed per CATEGORY under the kid, the
                # same shape as native/: audio/native_kids/<kid>/<cat>/<key>
                if key not in stems(
                        os.path.join(audio_dir, "native_kids", kid, cat)):
                    missing_kid.append(f"{kid}/{key}")
    notes.append(f"audio: {canonical_total} canonical, {kid_total} kid "
                 f"recording(s) expected")
    if missing_canonical:
        problems.append(
            f"{len(missing_canonical)} canonical recording(s) in "
            f"assets/native_audio_manifest.json are NOT in the pack, e.g. "
            f"{sorted(missing_canonical)[:SAMPLE]}")
    if missing_kid:
        problems.append(
            f"{len(missing_kid)} kid recording(s) in "
            f"assets/native_audio_manifest.json are NOT in the pack, e.g. "
            f"{sorted(missing_kid)[:SAMPLE]}")

    for n in notes:
        print(n)
    if problems:
        for p in problems:
            print("::error::" + p)
        print("::error::pad-assets is STALE or incomplete. Run "
              "scripts/pack_and_upload_assets.sh from the dev machine, then "
              "re-run this build.")
        return 1
    print("Asset bundle matches this commit.")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
