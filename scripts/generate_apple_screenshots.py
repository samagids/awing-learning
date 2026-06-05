#!/usr/bin/env python3
"""generate_apple_screenshots.py — v1.0.0 (A1 path)

Generates 5 stylized App Store screenshots at both Apple iPhone sizes:
  • 1320 x 2868 (iPhone 6.9" — required for current submission)
  • 1284 x 2778 (iPhone 6.5"/6.7" — accepted as fallback)

These are stylized marketing mockups (not real device captures) with
current v1.17.x copy ("8,000+ Awing words", "Native speaker recordings",
"Six character voices", etc.). Uses only solid colors and text — no
emoji rendering, so no Unicode placeholder squares that broke the old
mockups in store_listing/ios/.

Usage:
  venv\\Scripts\\python.exe scripts\\generate_apple_screenshots.py

Output:
  store_listing/ios/iphone_6_9/screenshot_1.png ... screenshot_5.png
  store_listing/ios/iphone_6_5/screenshot_1.png ... screenshot_5.png

Overwrites existing files. Run again any time the copy needs to change.
"""
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import sys

# ===== Constants =====

REPO = Path(__file__).resolve().parent.parent
OUT_69 = REPO / "store_listing" / "ios" / "iphone_6_9"  # 1320 x 2868
OUT_65 = REPO / "store_listing" / "ios" / "iphone_6_5"  # 1284 x 2778

SIZE_69 = (1320, 2868)
SIZE_65 = (1284, 2778)

# Awing brand palette
AWING_GREEN = (0, 100, 50)         # #006432 — primary
AWING_DARK = (0, 70, 35)            # darker green for header
AWING_LIGHT = (16, 167, 91)         # lighter green for accents
AWING_GOLD = (218, 165, 32)         # #DAA520 — accent
BG_GRAY = (245, 245, 245)
CARD_WHITE = (255, 255, 255)
DARK_TEXT = (33, 33, 33)
MED_TEXT = (97, 97, 97)
LIGHT_TEXT = (158, 158, 158)
DIVIDER = (224, 224, 224)


# ===== Font helpers =====

def _find_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    """Return a TTF font of the requested size, walking platform candidates."""
    if bold:
        candidates = [
            "C:/Windows/Fonts/arialbd.ttf",
            "C:/Windows/Fonts/seguibl.ttf",     # Segoe UI Black
            "C:/Windows/Fonts/segoeuib.ttf",    # Segoe UI Bold
            "C:/Windows/Fonts/calibrib.ttf",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
            "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        ]
    else:
        candidates = [
            "C:/Windows/Fonts/arial.ttf",
            "C:/Windows/Fonts/segoeui.ttf",
            "C:/Windows/Fonts/calibri.ttf",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
            "/System/Library/Fonts/Supplemental/Arial.ttf",
        ]
    for f in candidates:
        if Path(f).exists():
            try:
                return ImageFont.truetype(f, size)
            except OSError:
                continue
    print(f"  WARN: no TTF font found, falling back to bitmap default (size {size} ignored)")
    return ImageFont.load_default()


# ===== Drawing helpers =====

def _draw_centered_text(draw, text, y, font, fill, canvas_w):
    """Center text horizontally at y."""
    bbox = draw.textbbox((0, 0), text, font=font)
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    draw.text(((canvas_w - w) // 2, y), text, font=font, fill=fill)
    return y + h


def _draw_wrapped_text(draw, text, x, y, font, fill, max_width):
    """Word-wrap text within max_width. Returns final y."""
    words = text.split()
    lines = []
    current = ""
    for word in words:
        trial = (current + " " + word).strip()
        bbox = draw.textbbox((0, 0), trial, font=font)
        if (bbox[2] - bbox[0]) > max_width and current:
            lines.append(current)
            current = word
        else:
            current = trial
    if current:
        lines.append(current)
    for line in lines:
        draw.text((x, y), line, font=font, fill=fill)
        bbox = draw.textbbox((0, 0), line, font=font)
        y += (bbox[3] - bbox[1]) + 8
    return y


def _rounded_rect(draw, xy, radius, fill, outline=None, width=0):
    """Filled rounded rectangle."""
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)


def _draw_status_bar(draw, canvas_w, font):
    """Tiny status bar at top — just a thin Awing-green strip with no clutter.
    Apple discourages fake iOS chrome in screenshots, so we keep it minimal."""
    draw.rectangle([(0, 0), (canvas_w, 50)], fill=AWING_DARK)


def _draw_app_header(draw, canvas_w, y, title, font_title, font_sub):
    """Big green app header band with white title."""
    h = 240
    draw.rectangle([(0, y), (canvas_w, y + h)], fill=AWING_GREEN)
    title_y = y + 70
    bbox = draw.textbbox((0, 0), title, font=font_title)
    tw = bbox[2] - bbox[0]
    draw.text(((canvas_w - tw) // 2, title_y), title, font=font_title, fill=CARD_WHITE)
    return y + h


def _draw_tagline_band(draw, canvas_w, canvas_h, tagline, font):
    """Bottom tagline strip — Awing green band with white text."""
    h = 200
    y = canvas_h - h
    draw.rectangle([(0, y), (canvas_w, canvas_h)], fill=AWING_GREEN)
    bbox = draw.textbbox((0, 0), tagline, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.text(((canvas_w - tw) // 2, y + (h - th) // 2 - 10),
              tagline, font=font, fill=CARD_WHITE)


# ===== Screenshot 1: Hero / Title =====

def screenshot_hero(canvas_w, canvas_h):
    img = Image.new("RGB", (canvas_w, canvas_h), CARD_WHITE)
    draw = ImageDraw.Draw(img)

    title_font = _find_font(108, bold=True)
    subtitle_font = _find_font(56)
    tile_label_font = _find_font(80, bold=True)
    tile_sub_font = _find_font(40)
    tagline_font = _find_font(64, bold=True)

    # Top status strip
    _draw_status_bar(draw, canvas_w, None)
    _draw_centered_text(draw, "Awing AI Learning", 130, title_font,
                        AWING_GREEN, canvas_w)
    _draw_centered_text(draw, "Learn the Awing language", 290,
                        subtitle_font, MED_TEXT, canvas_w)

    # 4 mode tiles in a 2x2 grid — larger and centered vertically
    tiles = [
        ("Beginner", "Alphabet, words, tones", AWING_LIGHT),
        ("Medium",   "Sentences, grammar",     (255, 153, 51)),
        ("Expert",   "Conversations & quizzes",(220, 53, 53)),
        ("Stories",  "Read along in Awing",    (0, 121, 167)),
    ]
    tile_w = (canvas_w - 200) // 2
    tile_h = 700
    gap = 40
    grid_x = 100
    grid_y = 540
    for i, (label, sub, color) in enumerate(tiles):
        row = i // 2
        col = i % 2
        x0 = grid_x + col * (tile_w + gap)
        y0 = grid_y + row * (tile_h + gap)
        _rounded_rect(draw, [(x0, y0), (x0 + tile_w, y0 + tile_h)],
                      radius=36, fill=color)
        bbox = draw.textbbox((0, 0), label, font=tile_label_font)
        lw = bbox[2] - bbox[0]
        draw.text((x0 + (tile_w - lw) // 2, y0 + tile_h // 2 - 110),
                  label, font=tile_label_font, fill=CARD_WHITE)
        bbox = draw.textbbox((0, 0), sub, font=tile_sub_font)
        sw = bbox[2] - bbox[0]
        draw.text((x0 + (tile_w - sw) // 2, y0 + tile_h // 2 + 40),
                  sub, font=tile_sub_font, fill=CARD_WHITE)

    _draw_tagline_band(draw, canvas_w, canvas_h,
                       "8,000+ Awing words for kids", tagline_font)
    return img


# ===== Screenshot 2: Alphabet =====

def screenshot_alphabet(canvas_w, canvas_h):
    img = Image.new("RGB", (canvas_w, canvas_h), BG_GRAY)
    draw = ImageDraw.Draw(img)

    title_font = _find_font(108, bold=True)
    subtitle_font = _find_font(56)
    section_font = _find_font(72, bold=True)
    tile_letter_font = _find_font(220, bold=True)
    tile_caption_font = _find_font(44)
    tagline_font = _find_font(64, bold=True)

    _draw_status_bar(draw, canvas_w, None)
    _draw_centered_text(draw, "Awing AI Learning", 130, title_font,
                        AWING_GREEN, canvas_w)
    _draw_centered_text(draw, "Learn the Awing language", 290,
                        subtitle_font, MED_TEXT, canvas_w)

    # Section header band
    sec_y = 450
    draw.rectangle([(0, sec_y), (canvas_w, sec_y + 120)], fill=AWING_GREEN)
    draw.text((60, sec_y + 30), "Alphabet Lesson",
              font=section_font, fill=CARD_WHITE)

    # 2x2 grid of letter tiles — much taller, fills the canvas
    letters = [
        ("A", "Tap to hear", AWING_LIGHT),
        ("B", "Tap to hear", AWING_GREEN),
        ("E", "Tap to hear", AWING_LIGHT),
        ("ɛ", "Tap to hear", AWING_GREEN),  # ɛ (epsilon)
    ]
    tile_w = (canvas_w - 200) // 2
    tile_h = 880
    gap = 40
    grid_x = 100
    grid_y = sec_y + 200
    for i, (letter, cap, color) in enumerate(letters):
        row = i // 2
        col = i % 2
        x0 = grid_x + col * (tile_w + gap)
        y0 = grid_y + row * (tile_h + gap)
        _rounded_rect(draw, [(x0, y0), (x0 + tile_w, y0 + tile_h)],
                      radius=36, fill=color)
        bbox = draw.textbbox((0, 0), letter, font=tile_letter_font)
        lw = bbox[2] - bbox[0]
        lh = bbox[3] - bbox[1]
        draw.text((x0 + (tile_w - lw) // 2, y0 + (tile_h - lh) // 2 - 80),
                  letter, font=tile_letter_font, fill=CARD_WHITE)
        bbox = draw.textbbox((0, 0), cap, font=tile_caption_font)
        cw = bbox[2] - bbox[0]
        draw.text((x0 + (tile_w - cw) // 2, y0 + tile_h - 90),
                  cap, font=tile_caption_font, fill=CARD_WHITE)

    _draw_tagline_band(draw, canvas_w, canvas_h,
                       "31 letters with tone guidance", tagline_font)
    return img


# ===== Screenshot 3: Vocabulary card =====

def screenshot_vocabulary(canvas_w, canvas_h):
    img = Image.new("RGB", (canvas_w, canvas_h), BG_GRAY)
    draw = ImageDraw.Draw(img)

    title_font = _find_font(108, bold=True)
    subtitle_font = _find_font(56)
    section_font = _find_font(72, bold=True)
    awing_word_font = _find_font(160, bold=True)
    english_font = _find_font(72)
    button_font = _find_font(56, bold=True)
    tagline_font = _find_font(64, bold=True)

    _draw_status_bar(draw, canvas_w, None)
    _draw_centered_text(draw, "Awing AI Learning", 130, title_font,
                        AWING_GREEN, canvas_w)
    _draw_centered_text(draw, "Learn the Awing language", 290,
                        subtitle_font, MED_TEXT, canvas_w)

    # Section header
    sec_y = 450
    draw.rectangle([(0, sec_y), (canvas_w, sec_y + 120)], fill=AWING_GREEN)
    draw.text((60, sec_y + 30), "Vocabulary",
              font=section_font, fill=CARD_WHITE)

    # Big flashcard — taller to fill canvas
    card_x = 100
    card_y = sec_y + 200
    card_w = canvas_w - 200
    card_h = 1200
    _rounded_rect(draw, [(card_x, card_y), (card_x + card_w, card_y + card_h)],
                  radius=36, fill=CARD_WHITE,
                  outline=AWING_LIGHT, width=6)

    # Picture area (left half) — colored block representing the photo
    pic_w = card_w // 2
    _rounded_rect(draw,
                  [(card_x, card_y), (card_x + pic_w, card_y + card_h)],
                  radius=36, fill=AWING_LIGHT)
    # Stylized "fruit" shape: yellow oval for banana, since the example word is banana
    fruit_cx = card_x + pic_w // 2
    fruit_cy = card_y + card_h // 2
    fruit_w = pic_w - 200
    fruit_h = 280
    draw.ellipse([(fruit_cx - fruit_w // 2, fruit_cy - fruit_h // 2),
                  (fruit_cx + fruit_w // 2, fruit_cy + fruit_h // 2)],
                 fill=AWING_GOLD)

    # Word + meaning (right half)
    text_x = card_x + pic_w + 50
    text_w = card_w - pic_w - 100
    # Awing word — centered vertically in card
    draw.text((text_x, card_y + 380), "apɛnə",
              font=awing_word_font, fill=AWING_GREEN)
    # English
    draw.text((text_x, card_y + 620), "(banana)",
              font=english_font, fill=DARK_TEXT)

    # Hear It button — centered horizontally below card
    btn_w = 540
    btn_h = 160
    btn_x = (canvas_w - btn_w) // 2
    btn_y = card_y + card_h + 80
    _rounded_rect(draw,
                  [(btn_x, btn_y), (btn_x + btn_w, btn_y + btn_h)],
                  radius=40, fill=AWING_GREEN)
    bbox = draw.textbbox((0, 0), "Hear it", font=button_font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.text((btn_x + (btn_w - tw) // 2, btn_y + (btn_h - th) // 2 - 8),
              "Hear it", font=button_font, fill=CARD_WHITE)

    _draw_tagline_band(draw, canvas_w, canvas_h,
                       "Native speaker recordings", tagline_font)
    return img


# ===== Screenshot 4: Quiz =====

def screenshot_quiz(canvas_w, canvas_h):
    img = Image.new("RGB", (canvas_w, canvas_h), BG_GRAY)
    draw = ImageDraw.Draw(img)

    title_font = _find_font(108, bold=True)
    subtitle_font = _find_font(56)
    section_font = _find_font(72, bold=True)
    question_font = _find_font(72)
    awing_font = _find_font(120, bold=True)
    choice_font = _find_font(64, bold=True)
    tagline_font = _find_font(64, bold=True)

    _draw_status_bar(draw, canvas_w, None)
    _draw_centered_text(draw, "Awing AI Learning", 130, title_font,
                        AWING_GREEN, canvas_w)
    _draw_centered_text(draw, "Learn the Awing language", 290,
                        subtitle_font, MED_TEXT, canvas_w)

    # Section header
    sec_y = 450
    draw.rectangle([(0, sec_y), (canvas_w, sec_y + 120)], fill=AWING_GREEN)
    draw.text((60, sec_y + 30), "Quiz Time",
              font=section_font, fill=CARD_WHITE)

    # Question card
    qcard_y = sec_y + 200
    qcard_h = 500
    _rounded_rect(draw, [(100, qcard_y), (canvas_w - 100, qcard_y + qcard_h)],
                  radius=36, fill=CARD_WHITE,
                  outline=DIVIDER, width=4)
    _draw_centered_text(draw, "What does this mean?", qcard_y + 90,
                        question_font, MED_TEXT, canvas_w)
    _draw_centered_text(draw, "apɛnə", qcard_y + 240,
                        awing_font, AWING_GREEN, canvas_w)

    # 4 answer tiles in 2x2 — bigger to fill canvas
    answers = [
        ("Banana",  AWING_LIGHT, True),
        ("Apple",   CARD_WHITE,  False),
        ("Orange",  CARD_WHITE,  False),
        ("Mango",   CARD_WHITE,  False),
    ]
    tile_w = (canvas_w - 240) // 2
    tile_h = 380
    gap = 50
    grid_x = 120
    grid_y = qcard_y + qcard_h + 100
    for i, (label, color, correct) in enumerate(answers):
        row = i // 2
        col = i % 2
        x0 = grid_x + col * (tile_w + gap)
        y0 = grid_y + row * (tile_h + gap)
        _rounded_rect(draw, [(x0, y0), (x0 + tile_w, y0 + tile_h)],
                      radius=32, fill=color,
                      outline=AWING_LIGHT if not correct else None,
                      width=4 if not correct else 0)
        bbox = draw.textbbox((0, 0), label, font=choice_font)
        lw = bbox[2] - bbox[0]
        lh = bbox[3] - bbox[1]
        text_color = CARD_WHITE if correct else DARK_TEXT
        draw.text((x0 + (tile_w - lw) // 2, y0 + (tile_h - lh) // 2 - 8),
                  label, font=choice_font, fill=text_color)

    _draw_tagline_band(draw, canvas_w, canvas_h,
                       "Quizzes, games & stories", tagline_font)
    return img


# ===== Screenshot 5: Six Character Voices =====

def screenshot_voices(canvas_w, canvas_h):
    img = Image.new("RGB", (canvas_w, canvas_h), BG_GRAY)
    draw = ImageDraw.Draw(img)

    title_font = _find_font(108, bold=True)
    subtitle_font = _find_font(56)
    section_font = _find_font(72, bold=True)
    voice_label_font = _find_font(56, bold=True)
    voice_role_font = _find_font(40)
    tagline_font = _find_font(64, bold=True)

    _draw_status_bar(draw, canvas_w, None)
    _draw_centered_text(draw, "Awing AI Learning", 130, title_font,
                        AWING_GREEN, canvas_w)
    _draw_centered_text(draw, "Learn the Awing language", 290,
                        subtitle_font, MED_TEXT, canvas_w)

    # Section header
    sec_y = 450
    draw.rectangle([(0, sec_y), (canvas_w, sec_y + 120)], fill=AWING_GREEN)
    draw.text((60, sec_y + 30), "Choose a voice",
              font=section_font, fill=CARD_WHITE)

    # 6 voice avatars in a 3x2 grid — bigger to fill the canvas
    voices = [
        ("Boy",         "Beginner", AWING_LIGHT),
        ("Girl",        "Beginner", (255, 153, 153)),
        ("Young Man",   "Medium",   (51, 153, 51)),
        ("Young Woman", "Medium",   (204, 102, 204)),
        ("Father",      "Expert",   (87, 84, 64)),
        ("Mother",      "Expert",   (179, 102, 51)),
    ]
    cols = 3
    rows = 2
    cell_w = (canvas_w - 160) // cols
    cell_h = 880
    gap = 30
    grid_x = 80
    grid_y = sec_y + 220
    for i, (label, role, color) in enumerate(voices):
        row = i // cols
        col = i % cols
        x0 = grid_x + col * (cell_w + gap)
        y0 = grid_y + row * (cell_h + gap)
        # Circle avatar — much bigger
        avatar_r = 200
        cx = x0 + cell_w // 2
        cy = y0 + 280
        draw.ellipse([(cx - avatar_r, cy - avatar_r),
                      (cx + avatar_r, cy + avatar_r)], fill=color)
        # Initial inside circle
        initial = label[0]
        initial_font = _find_font(220, bold=True)
        bbox = draw.textbbox((0, 0), initial, font=initial_font)
        iw = bbox[2] - bbox[0]
        ih = bbox[3] - bbox[1]
        draw.text((cx - iw // 2, cy - ih // 2 - 12),
                  initial, font=initial_font, fill=CARD_WHITE)
        # Name
        bbox = draw.textbbox((0, 0), label, font=voice_label_font)
        nw = bbox[2] - bbox[0]
        draw.text((cx - nw // 2, y0 + 560),
                  label, font=voice_label_font, fill=DARK_TEXT)
        # Role
        bbox = draw.textbbox((0, 0), role, font=voice_role_font)
        rw = bbox[2] - bbox[0]
        draw.text((cx - rw // 2, y0 + 680),
                  role, font=voice_role_font, fill=MED_TEXT)

    _draw_tagline_band(draw, canvas_w, canvas_h,
                       "Six character voices for kids", tagline_font)
    return img


# ===== Driver =====

SCREENSHOTS = [
    ("screenshot_1.png", screenshot_hero),
    ("screenshot_2.png", screenshot_alphabet),
    ("screenshot_3.png", screenshot_vocabulary),
    ("screenshot_4.png", screenshot_quiz),
    ("screenshot_5.png", screenshot_voices),
]


def render_all():
    OUT_69.mkdir(parents=True, exist_ok=True)
    OUT_65.mkdir(parents=True, exist_ok=True)

    for fname, fn in SCREENSHOTS:
        # Generate at 6.9" canvas
        img69 = fn(SIZE_69[0], SIZE_69[1])
        out69 = OUT_69 / fname
        img69.save(out69, "PNG", optimize=True)
        print(f"  ✓ {out69} ({SIZE_69[0]}x{SIZE_69[1]})")

        # Resize to 6.5"/6.7" — tiny aspect change (0.4604 vs 0.4622)
        # but Apple accepts both as canonical iPhone sizes.
        img65 = img69.resize(SIZE_65, Image.LANCZOS)
        out65 = OUT_65 / fname
        img65.save(out65, "PNG", optimize=True)
        print(f"  ✓ {out65} ({SIZE_65[0]}x{SIZE_65[1]})")


def main():
    print("Generating Apple App Store screenshots (5 x 2 sizes)...")
    render_all()
    print()
    print("Done. Upload via App Store Connect:")
    print('  1) Distribution > Previews and Screenshots')
    print('  2) iPhone tab > 6.9-inch slot > Choose File > select all 5 from')
    print('     store_listing/ios/iphone_6_9/')
    print('  3) Repeat for 6.5-inch slot using iphone_6_5/ files')
    return 0


if __name__ == "__main__":
    sys.exit(main())
