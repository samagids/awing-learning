#!/usr/bin/env python3
"""generate_store_graphics.py — Google Play feature graphic and 512px icon.

Replaces scripts/_deprecated/generate_store_graphics.py, which could no
longer run: its OUTPUT_DIR was hardcoded to a dead sandbox path
(/sessions/vibrant-lucid-albattani/...) and its font lookup was Linux-only,
so on Windows it fell through to ImageFont.load_default() — an 11px bitmap
face — and would have produced a 1024x500 banner with unreadable text.

Design is deliberately unchanged from the graphic currently on the Play
listing (vertical green gradient, four outlined circles, centred title and
subtitle, three white speech bubbles). The ONLY change is the name:
"Awing AI Learning" -> "Awing Learning", per NACDA DMV.

    python scripts/generate_store_graphics.py              # both
    python scripts/generate_store_graphics.py --feature    # banner only
    python scripts/generate_store_graphics.py --icon       # icon only
"""

import argparse
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

REPO_ROOT = Path(__file__).resolve().parent.parent
OUTPUT_DIR = REPO_ROOT / "store_listing"

APP_NAME = "Awing Learning"
TAGLINE = "Learn the Awing Language"

COLOR_DARK_GREEN = (0, 100, 50)      # #006432 - matches the in-app wordmark
COLOR_LIGHT_GREEN = (0, 168, 107)
COLOR_MEDIUM_GREEN = (0, 130, 80)
COLOR_WHITE = (255, 255, 255)

# Tried in order. The Linux paths are for the dev container / WSL, the
# Windows ones for a normal PowerShell run. Falling through to
# load_default() is treated as an ERROR rather than a silent downgrade -
# a bitmap font at size 80 is not a smaller version of the design, it is a
# broken image that would go straight onto the store.
_FONT_CANDIDATES = {
    "bold": [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        r"C:\Windows\Fonts\arialbd.ttf",
        r"C:\Windows\Fonts\segoeuib.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    ],
    "regular": [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        r"C:\Windows\Fonts\arial.ttf",
        r"C:\Windows\Fonts\segoeui.ttf",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
    ],
}


def font(weight: str, size: int) -> ImageFont.FreeTypeFont:
    for path in _FONT_CANDIDATES[weight]:
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    raise SystemExit(
        f"No {weight} TrueType font found. Tried:\n  "
        + "\n  ".join(_FONT_CANDIDATES[weight])
        + "\nRefusing to fall back to the bitmap default — it would render "
          "the title illegibly at this size."
    )


def _gradient(img: Image.Image, top, bottom) -> None:
    px = img.load()
    w, h = img.size
    for y in range(h):
        t = y / max(1, h - 1)
        row = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        for x in range(w):
            px[x, y] = row


def _centered(draw, text, y, fnt, canvas_w, fill=COLOR_WHITE) -> None:
    box = draw.textbbox((0, 0), text, font=fnt)
    draw.text(((canvas_w - (box[2] - box[0])) // 2 - box[0], y),
              text, font=fnt, fill=fill)


def create_feature_graphic(out: Path) -> Path:
    W, H = 1024, 500
    img = Image.new("RGB", (W, H))
    _gradient(img, COLOR_DARK_GREEN, COLOR_LIGHT_GREEN)
    draw = ImageDraw.Draw(img)

    for x, y, r in [(150, 100, 80), (900, 350, 90), (100, 400, 70), (800, 150, 100)]:
        draw.ellipse([x - r, y - r, x + r, y + r], outline=COLOR_WHITE, width=2)

    _centered(draw, APP_NAME, 80, font("bold", 80), W)
    _centered(draw, TAGLINE, 200, font("regular", 40), W)

    for bx in (150, 450, 750):
        draw.ellipse([bx, 320, bx + 50, 370],
                     fill=COLOR_WHITE, outline=COLOR_LIGHT_GREEN, width=2)

    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, "PNG", optimize=True)
    return out


def create_icon_512(out: Path) -> Path:
    S = 512
    img = Image.new("RGB", (S, S))
    _gradient(img, COLOR_DARK_GREEN, COLOR_MEDIUM_GREEN)
    draw = ImageDraw.Draw(img)
    draw.ellipse([56, 56, S - 56, S - 56], fill=COLOR_WHITE)
    fnt = font("bold", 260)
    box = draw.textbbox((0, 0), "A", font=fnt)
    draw.text(((S - (box[2] - box[0])) // 2 - box[0],
               (S - (box[3] - box[1])) // 2 - box[1]),
              "A", font=fnt, fill=COLOR_DARK_GREEN)
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, "PNG", optimize=True)
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--feature", action="store_true")
    ap.add_argument("--icon", action="store_true")
    ap.add_argument("--output-dir", default=str(OUTPUT_DIR))
    a = ap.parse_args()
    outdir = Path(a.output_dir)
    both = not (a.feature or a.icon)

    if a.feature or both:
        p = create_feature_graphic(outdir / "feature_graphic.png")
        print(f"  wrote {p}  (1024x500, name: {APP_NAME!r})")
    if a.icon or both:
        p = create_icon_512(outdir / "icon_512.png")
        print(f"  wrote {p}  (512x512)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
