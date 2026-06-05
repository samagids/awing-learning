#!/usr/bin/env python3
"""caption_real_screenshots.py — v1.0.0 (A3 path)

Premium-quality App Store screenshots: real captured screens placed
inside a colored marketing layout with a big headline above each
screenshot. Style matches what Duolingo/Khan Academy/etc. ship.

Reads raw screenshots from store_listing/raw/ (capture them first
via `adb shell screencap` — see frame_real_screenshots.py docstring)
and produces 5 captioned compositions at both Apple iPhone sizes.

Each output has:
  • Awing-green top band with a big white marketing headline
  • Sub-headline in smaller white text
  • Real app screenshot scaled to fit, rounded corners, slight shadow
  • Awing-green bottom margin

Headlines for the 5 screenshots are hard-coded below — edit
HEADLINES if you re-shoot different screens.

Usage:
  venv\\Scripts\\python.exe scripts\\caption_real_screenshots.py

Output:
  store_listing/ios/iphone_6_9/screenshot_1.png ... screenshot_5.png
  store_listing/ios/iphone_6_5/screenshot_1.png ... screenshot_5.png

WARNING: Overwrites existing files. Run A1 (generate_apple_screenshots.py)
or this script — not both — for the same screenshot number.
"""
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import sys

REPO = Path(__file__).resolve().parent.parent
RAW_DIR = REPO / "store_listing" / "raw"
OUT_69 = REPO / "store_listing" / "ios" / "iphone_6_9"
OUT_65 = REPO / "store_listing" / "ios" / "iphone_6_5"

SIZE_69 = (1320, 2868)
SIZE_65 = (1284, 2778)

AWING_GREEN = (0, 100, 50)
AWING_DARK = (0, 70, 35)
CARD_WHITE = (255, 255, 255)
SHADOW_BLACK = (0, 0, 0, 80)  # rgba — semi-transparent shadow

# Headline + subhead per screenshot (1..5)
# Edit these to match what's captured in store_listing/raw/screenshot_N.png
HEADLINES = {
    1: ("8,000+ Awing words",        "Learn the language of Cameroon"),
    2: ("Learn the alphabet",         "31 letters with native pronunciation"),
    3: ("Build your vocabulary",      "Hundreds of native speaker recordings"),
    4: ("Test what you know",         "Fun quizzes for every level"),
    5: ("Six character voices",       "Pick the voice that fits your child"),
}


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


def _wrap(draw, text, font, max_width):
    """Return list of lines that fit within max_width."""
    if not text:
        return []
    words = text.split()
    lines = []
    current = ""
    for w in words:
        trial = (current + " " + w).strip()
        bbox = draw.textbbox((0, 0), trial, font=font)
        if bbox[2] - bbox[0] > max_width and current:
            lines.append(current)
            current = w
        else:
            current = trial
    if current:
        lines.append(current)
    return lines


def caption_one(raw_path: Path, headline: str, subhead: str,
                target_size: tuple[int, int]) -> Image.Image:
    """Compose a captioned App Store screenshot."""
    tw, th = target_size
    canvas = Image.new("RGB", (tw, th), AWING_GREEN)
    draw = ImageDraw.Draw(canvas)

    # ===== Top caption area =====
    cap_h = int(th * 0.28)  # ~28% of canvas height for caption block
    headline_font = _find_font(110 if tw == 1320 else 104, bold=True)
    sub_font = _find_font(54 if tw == 1320 else 50)

    margin = 80
    max_text_w = tw - 2 * margin

    headline_lines = _wrap(draw, headline, headline_font, max_text_w)
    sub_lines = _wrap(draw, subhead, sub_font, max_text_w)

    # Vertically center caption block within cap_h
    total_h = 0
    line_h_head = 0
    for line in headline_lines:
        bbox = draw.textbbox((0, 0), line, font=headline_font)
        line_h = (bbox[3] - bbox[1]) + 12
        line_h_head = line_h
        total_h += line_h
    total_h += 30  # gap between headline and subhead
    line_h_sub = 0
    for line in sub_lines:
        bbox = draw.textbbox((0, 0), line, font=sub_font)
        line_h = (bbox[3] - bbox[1]) + 8
        line_h_sub = line_h
        total_h += line_h

    y = (cap_h - total_h) // 2 + 30
    for line in headline_lines:
        bbox = draw.textbbox((0, 0), line, font=headline_font)
        lw = bbox[2] - bbox[0]
        draw.text(((tw - lw) // 2, y), line, font=headline_font, fill=CARD_WHITE)
        y += line_h_head
    y += 30
    for line in sub_lines:
        bbox = draw.textbbox((0, 0), line, font=sub_font)
        lw = bbox[2] - bbox[0]
        draw.text(((tw - lw) // 2, y), line, font=sub_font, fill=(200, 230, 215))
        y += line_h_sub

    # ===== Screenshot area =====
    raw = Image.open(raw_path).convert("RGB")
    avail_w = tw - 160
    avail_h = th - cap_h - 160
    rw, rh = raw.size
    scale = min(avail_w / rw, avail_h / rh)
    nw = int(rw * scale)
    nh = int(rh * scale)
    scaled = raw.resize((nw, nh), Image.LANCZOS)

    # Round corners on the scaled screenshot
    mask = Image.new("L", scaled.size, 0)
    mask_draw = ImageDraw.Draw(mask)
    radius = 48
    mask_draw.rounded_rectangle([(0, 0), scaled.size], radius=radius, fill=255)
    rounded = Image.new("RGBA", scaled.size, (0, 0, 0, 0))
    rounded.paste(scaled, (0, 0), mask)

    # Drop shadow (RGBA layer behind the screenshot)
    shadow = Image.new("RGBA", (nw + 60, nh + 60), (0, 0, 0, 0))
    sh_draw = ImageDraw.Draw(shadow)
    sh_draw.rounded_rectangle([(30, 30), (nw + 30, nh + 30)],
                              radius=radius, fill=(0, 0, 0, 100))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=20))

    # Paste shadow then rounded screenshot
    paste_x = (tw - nw) // 2
    paste_y = cap_h + 80
    canvas_rgba = canvas.convert("RGBA")
    canvas_rgba.paste(shadow, (paste_x - 30, paste_y - 30), shadow)
    canvas_rgba.paste(rounded, (paste_x, paste_y), rounded)

    return canvas_rgba.convert("RGB")


def main():
    if not RAW_DIR.exists():
        RAW_DIR.mkdir(parents=True)
        print(f"Created {RAW_DIR}")
        print()
        print("No raw screenshots found. Capture them first:")
        print(f"  1. Connect device with v1.17.x app installed via TestFlight")
        print(f"     (or emulator + bundletool --local-testing AAB)")
        print(f"  2. Navigate to each screen you want to capture:")
        for n, (head, sub) in HEADLINES.items():
            print(f"     screenshot_{n}: {head}")
        print(f"  3. adb shell screencap -p /sdcard/shot_N.png")
        print(f"  4. adb pull /sdcard/shot_N.png {RAW_DIR}/screenshot_N.png")
        print(f"  5. Re-run this script")
        return 1

    raw_files = {p.name: p for p in RAW_DIR.glob("screenshot_*.png")}
    if not raw_files:
        print(f"No screenshot_*.png files in {RAW_DIR}")
        return 1

    OUT_69.mkdir(parents=True, exist_ok=True)
    OUT_65.mkdir(parents=True, exist_ok=True)

    print(f"Compositing {len(raw_files)} captioned screenshots...")
    for n in range(1, 6):
        name = f"screenshot_{n}.png"
        if name not in raw_files:
            print(f"  ! skipping {name}: not in {RAW_DIR}")
            continue
        head, sub = HEADLINES.get(n, ("Awing AI Learning", "Learn the Awing language"))
        img69 = caption_one(raw_files[name], head, sub, SIZE_69)
        img65 = caption_one(raw_files[name], head, sub, SIZE_65)
        (OUT_69 / name).write_bytes(b"")  # touch to ensure overwrite
        img69.save(OUT_69 / name, "PNG", optimize=True)
        img65.save(OUT_65 / name, "PNG", optimize=True)
        print(f"  ✓ {name}: \"{head}\"")

    print()
    print("Done. Upload via App Store Connect:")
    print("  Distribution > Previews and Screenshots > iPhone tab")
    return 0


if __name__ == "__main__":
    sys.exit(main())
