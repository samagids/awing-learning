#!/usr/bin/env python3
"""frame_real_screenshots.py — v1.0.0 (A2 path)

Takes raw screenshots captured from the running app (emulator or real
device) and frames them to Apple's required iPhone screenshot sizes.

Raw screenshots are usually 1080x2400 (Android phone), 1290x2796
(iPhone 6.7"), 1320x2868 (iPhone 6.9"), or 1242x2688 (iPhone 6.5").
This script:
  1. Scales the raw image proportionally to fit within target aspect.
  2. Letterboxes any difference with Awing green (#006432) padding.
  3. Adds a small "Awing AI Learning" label band at the top so the
     screenshot reads as a marketing asset, not a raw capture.

Usage:
  1. Capture raw screenshots from the running app (5 screens):
       adb shell screencap -p /sdcard/shot_1.png
       adb pull /sdcard/shot_1.png store_listing\\raw\\screenshot_1.png
     (Repeat for screenshot_2.png ... screenshot_5.png)
  2. Run this script:
       venv\\Scripts\\python.exe scripts\\frame_real_screenshots.py

Outputs:
  store_listing/ios/iphone_6_9/screenshot_1.png ... screenshot_5.png (1320x2868)
  store_listing/ios/iphone_6_5/screenshot_1.png ... screenshot_5.png (1284x2778)

Overwrites existing files in those directories.
"""
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import sys

REPO = Path(__file__).resolve().parent.parent
RAW_DIR = REPO / "store_listing" / "raw"
OUT_69 = REPO / "store_listing" / "ios" / "iphone_6_9"
OUT_65 = REPO / "store_listing" / "ios" / "iphone_6_5"

SIZE_69 = (1320, 2868)
SIZE_65 = (1284, 2778)

AWING_GREEN = (0, 100, 50)
CARD_WHITE = (255, 255, 255)
HEADER_HEIGHT = 200   # branded band at top
FOOTER_PAD = 60       # bottom margin


def _find_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates_bold = [
        "C:/Windows/Fonts/arialbd.ttf",
        "C:/Windows/Fonts/segoeuib.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    ]
    candidates_norm = [
        "C:/Windows/Fonts/arial.ttf",
        "C:/Windows/Fonts/segoeui.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for f in (candidates_bold if bold else candidates_norm):
        if Path(f).exists():
            try:
                return ImageFont.truetype(f, size)
            except OSError:
                continue
    return ImageFont.load_default()


def frame_one(raw_path: Path, target_size: tuple[int, int]) -> Image.Image:
    """Take a raw screenshot, scale to fit, add Awing green padding,
    and stamp a branded header band at the top."""
    raw = Image.open(raw_path).convert("RGB")
    tw, th = target_size

    # Available area for the screenshot is below the header
    avail_w = tw - 80          # 40px margin each side
    avail_h = th - HEADER_HEIGHT - FOOTER_PAD

    # Scale raw to fit inside avail box, preserving aspect
    rw, rh = raw.size
    scale = min(avail_w / rw, avail_h / rh)
    nw = int(rw * scale)
    nh = int(rh * scale)
    scaled = raw.resize((nw, nh), Image.LANCZOS)

    # Build canvas
    canvas = Image.new("RGB", target_size, AWING_GREEN)

    # Header band
    draw = ImageDraw.Draw(canvas)
    title_font = _find_font(86, bold=True)
    sub_font = _find_font(48)
    title = "Awing AI Learning"
    sub = "Learn the Awing language"
    bbox = draw.textbbox((0, 0), title, font=title_font)
    tw_text = bbox[2] - bbox[0]
    draw.text(((tw - tw_text) // 2, 50), title, font=title_font, fill=CARD_WHITE)
    bbox = draw.textbbox((0, 0), sub, font=sub_font)
    sw_text = bbox[2] - bbox[0]
    draw.text(((tw - sw_text) // 2, 145), sub, font=sub_font, fill=CARD_WHITE)

    # White content area below header
    content_y = HEADER_HEIGHT
    content_h = th - HEADER_HEIGHT
    draw.rectangle([(0, content_y), (tw, th)], fill=CARD_WHITE)

    # Paste the scaled screenshot, centered in the available area
    paste_x = (tw - nw) // 2
    paste_y = content_y + (avail_h - nh) // 2 + (HEADER_HEIGHT // 2 - HEADER_HEIGHT // 2)
    canvas.paste(scaled, (paste_x, content_y + 40))

    return canvas


def main():
    if not RAW_DIR.exists():
        RAW_DIR.mkdir(parents=True)
        print(f"Created {RAW_DIR}")
        print()
        print("No raw screenshots found. Capture them first:")
        print("  1. Connect device or start emulator with v1.17.x")
        print("  2. Navigate to the screen you want to capture")
        print("  3. adb shell screencap -p /sdcard/shot.png")
        print(f"  4. adb pull /sdcard/shot.png {RAW_DIR}/screenshot_1.png")
        print("  5. Repeat for screenshot_2.png ... screenshot_5.png")
        print("  6. Re-run this script")
        return 1

    raw_files = sorted(RAW_DIR.glob("screenshot_*.png"))
    if not raw_files:
        print(f"No screenshot_*.png files in {RAW_DIR}")
        return 1

    OUT_69.mkdir(parents=True, exist_ok=True)
    OUT_65.mkdir(parents=True, exist_ok=True)

    print(f"Framing {len(raw_files)} screenshots to Apple sizes...")
    for raw_path in raw_files:
        name = raw_path.name
        img69 = frame_one(raw_path, SIZE_69)
        img65 = frame_one(raw_path, SIZE_65)
        out69 = OUT_69 / name
        out65 = OUT_65 / name
        img69.save(out69, "PNG", optimize=True)
        img65.save(out65, "PNG", optimize=True)
        print(f"  ✓ {name} -> {out69.parent.name}/ and {out65.parent.name}/")

    print()
    print("Done. Upload via App Store Connect:")
    print("  Distribution > Previews and Screenshots > iPhone tab")
    return 0


if __name__ == "__main__":
    sys.exit(main())
