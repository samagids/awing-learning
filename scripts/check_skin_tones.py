#!/usr/bin/env python3
"""Flag pack images that look like they contain light/caucasian skin.

Dr. Sama, repeatedly, and finally: "still white people in one of the
images. this should not happen in the generate all run."

Every previous fix has been on the PROMPT side, and every one of them was
me widening a list of words until he found the next miss. A prompt check
cannot prove the output is right. This checks the output.

HOW IT DECIDES
--------------
Skin pixels are found with the standard RGB rule (Kovac et al.): red
dominant, red-green separation, all channels bright enough. That catches
skin of any tone. Among those pixels, the ones that are LIGHT - high
luminance with low saturation - are counted.

An image is flagged when it has a meaningful amount of skin at all and
more than LIGHT_SHARE of it is light. The threshold is deliberately loose:
this is a list for a human to look at, not a verdict. Cartoon shading,
palms, highlights and pale clothing all produce false positives.

It cannot be a build gate for the same reason, and it is not wired into
build_and_run - run it after a generation pass and look at what it names.

    python scripts/check_skin_tones.py            # whole pack
    python scripts/check_skin_tones.py --since 6  # files touched in 6h
"""
import argparse, os, sys, json, time
from pathlib import Path

IMAGES = Path("android/install_time_assets/src/main/assets/images/vocabulary")
OUT = "contributions/light_skin_suspects.json"
MIN_SKIN_SHARE = 0.015      # at least this much of the image reads as skin
LIGHT_SHARE = 0.45          # ...and this much of that skin is light
SAMPLE = 96                 # downscale; we want tone, not detail


def is_skin(r, g, b):
    mx, mn = max(r, g, b), min(r, g, b)
    return (r > 95 and g > 40 and b > 20 and mx - mn > 15
            and abs(r - g) > 15 and r > g and r > b)


def is_light(r, g, b):
    # Rec. 601 luma, and a low spread means washed-out rather than deep.
    y = 0.299 * r + 0.587 * g + 0.114 * b
    return y > 170 and (max(r, g, b) - min(r, g, b)) < 90


def scan(path):
    from PIL import Image
    try:
        im = Image.open(path).convert("RGB").resize((SAMPLE, SAMPLE))
    except Exception:
        return None
    px = list(im.getdata())
    skin = [p for p in px if is_skin(*p)]
    if len(skin) / len(px) < MIN_SKIN_SHARE:
        return None
    light = sum(1 for p in skin if is_light(*p))
    share = light / len(skin)
    if share < LIGHT_SHARE:
        return None
    return {"file": path.name, "skin_px": len(skin),
            "skin_share": round(len(skin) / len(px), 3),
            "light_share": round(share, 3)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--since", type=float, default=None,
                    help="only files modified in the last N hours")
    ap.add_argument("--dir", default=str(IMAGES))
    args = ap.parse_args()
    root = Path(args.dir)
    files = sorted(list(root.glob("*.webp")) + list(root.glob("*.png")))
    if args.since:
        cut = time.time() - args.since * 3600
        files = [f for f in files if f.stat().st_mtime >= cut]
    print(f"scanning {len(files)} images in {root}")
    hits = []
    for i, f in enumerate(files, 1):
        r = scan(f)
        if r:
            hits.append(r)
        if i % 500 == 0:
            print(f"  {i}/{len(files)}  flagged {len(hits)}", end="\r")
    hits.sort(key=lambda h: -h["light_share"])
    print(f"\nflagged {len(hits)} of {len(files)}")
    os.makedirs("contributions", exist_ok=True)
    json.dump(hits, open(OUT, "w"), indent=1)
    print(f"-> {OUT}")
    for h in hits[:30]:
        print(f"  light {h['light_share']:.2f}  skin {h['skin_share']:.3f}  {h['file']}")


if __name__ == "__main__":
    main()
