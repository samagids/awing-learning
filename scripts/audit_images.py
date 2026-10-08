#!/usr/bin/env python3
"""Audit every pack image against the English meaning it is supposed to show.

WHY THIS EXISTS
---------------
Dr. Sama, 2026-10-08, on finding a picture of a girl on the card for "hump":
"audit all pictures and ensure all picture match the english meaning of
every words or sentences".

The cause of that one was legible in the prompt. `búsbága` is categorised
`body`, and the body template is "{people} showing their {word}" where
{people} is an eighty-word description of a Cameroonian girl. Three words
of "hump" against eighty words of girl, at 4 diffusion steps and guidance
1.5, draws a girl. 258 of the 416 body words have no hand-written prompt
and go through that same template.

There are 9,002 images. Nobody is going to look at them one at a time, and
a threshold on "does this look right" is not something a script can decide.
So this does the part a machine is good at - RANKING - and hands a human
the short end of the list.

HOW IT DECIDES
--------------
CLIP embeds images and captions into one space. The naive use is an
absolute similarity score, which is useless here: scores are not comparable
across concepts, and "a cartoon tooth" and "a cartoon neck" sit at
different baselines for reasons that have nothing to do with correctness.

So this uses RETRIEVAL RANK instead. For each image, its own gloss competes
against a large random sample of other glosses from the same corpus. If the
picture really shows a tooth, "tooth" should beat "bicycle", "grandmother"
and 498 others easily. When an image's own gloss lands in the bottom of its
own competition, the picture is not showing what it claims to.

That is robust to the baseline problem, needs no tuned threshold, and
produces a ranking a person can walk down until the results stop being
wrong.

TWO CHECKS THAT NEED NO GPU
---------------------------
  duplicates  Perceptual-hash clusters. When a template defeats the subject
              - as it did for "hump" - many different words collapse onto
              near-identical pictures. Synonyms legitimately cluster
              ("neck" five ways), so a cluster is only reported when its
              glosses are NOT near-synonyms.
  template    Which images came from a person-leading category with no
              hand-written PROMPT_OVERRIDE. These are the ones structurally
              at risk, whatever CLIP says.

OUTPUT
------
  contributions/image_audit.json          every image, scored and ranked
  contributions/image_audit/sheet_*.png   contact sheets, worst first,
                                          each tile captioned with its gloss

The contact sheets are the point. 9,002 images is unreviewable; 40 sheets
of the 2,000 least-convincing, captioned and worst-first, is an afternoon.

USAGE
    # structural only, no GPU, seconds
    python scripts/audit_images.py --structural

    # full audit, needs the venv with torch + transformers
    python scripts/audit_images.py --limit 0 --sheets 40

    # re-sheet an existing run without recomputing
    python scripts/audit_images.py --sheets-only
"""

from __future__ import annotations

import argparse
import json
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMAGES_DIR = os.path.join(
    PROJECT_DIR, 'android', 'install_time_assets', 'src', 'main',
    'assets', 'images', 'vocabulary')
CONTRIB_DIR = os.path.join(PROJECT_DIR, 'contributions')
REPORT_PATH = os.path.join(CONTRIB_DIR, 'image_audit.json')
SHEET_DIR = os.path.join(CONTRIB_DIR, 'image_audit')

# How many other glosses each image's own gloss has to beat. 500 keeps the
# whole matrix small while making a bottom-decile rank meaningful.
DISTRACTORS = 500

# Caption template. Deliberately plainer than the generation prompt: we are
# asking "is this a picture of X", not reproducing the art direction.
CAPTION = 'a cartoon illustration of {}'


def _entries():
    """key -> {awing, english, category} across all four namespaces."""
    import importlib.util
    spec = importlib.util.spec_from_file_location(
        'gi', os.path.join(os.path.dirname(os.path.abspath(__file__)),
                           'generate_images.py'))
    gi = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(gi)
    return gi._all_image_keys(), gi


def _image_for(key):
    for ext in ('.webp', '.png', '.jpg', '.jpeg'):
        p = os.path.join(IMAGES_DIR, key + ext)
        if os.path.exists(p):
            return p
    return None


# ---------------------------------------------------------------------------
# Structural checks (no GPU)
# ---------------------------------------------------------------------------

def _dhash(path, size=8):
    from PIL import Image
    im = Image.open(path).convert('L').resize((size + 1, size), Image.LANCZOS)
    px = list(im.getdata())
    bits = 0
    for r in range(size):
        for c in range(size):
            bits = (bits << 1) | (px[r * (size + 1) + c] <
                                  px[r * (size + 1) + c + 1])
    return bits


def _norm_words(text):
    import re
    return set(re.findall(r'[a-z]+', text.lower()))


def structural(entries, gi, verbose=True):
    """Duplicate clusters and template risk. Returns a dict keyed by image."""
    flags = {}

    # --- template risk ----------------------------------------------------
    # The categories whose prompt leads with a described person. For these,
    # a word with no override competes against eighty words of girl.
    person_categories = {'body', 'actions', 'family', 'descriptive'}
    at_risk = 0
    for key, meta in entries.items():
        cat = meta.get('category', '')
        if cat not in person_categories:
            continue
        english = meta.get('english', '')
        clean = gi.shorten_english_for_prompt(english)
        if clean in gi.PROMPT_OVERRIDES or english in gi.PROMPT_OVERRIDES:
            continue
        flags.setdefault(key, []).append('template_risk')
        at_risk += 1

    # --- near-duplicate clusters -----------------------------------------
    # Numeral cards are EXCLUDED from duplicate detection. Above
    # _MAX_TILED_COUNT generate_counting_image draws the digits instead of
    # tiling sprites, so "13" and "50" are two mostly-white cards with a
    # small dark glyph in the middle - a perceptual hash calls them
    # identical and they are both perfectly correct. The first run of this
    # audit reported "45 different meanings, one picture" for the numbers
    # and it was wrong. Verified by eye before the claim was made.
    hashes = {}
    for key in entries:
        if gi.parse_count(entries[key].get('english', '')) is not None:
            continue
        p = _image_for(key)
        if not p:
            continue
        try:
            hashes[key] = _dhash(p)
        except Exception:
            continue

    buckets = {}
    for key, h in hashes.items():
        buckets.setdefault(h >> 40, []).append(key)   # cheap prefilter

    clusters, seen = [], set()
    for bucket in buckets.values():
        for i, a in enumerate(bucket):
            if a in seen:
                continue
            grp = [a]
            for b in bucket[i + 1:]:
                if b in seen:
                    continue
                if bin(hashes[a] ^ hashes[b]).count('1') <= 6:
                    grp.append(b)
            if len(grp) > 1:
                # Synonyms SHOULD share a picture. Only report a cluster
                # whose glosses do not overlap in wording - that is the
                # signature of a template beating its subjects.
                words = [_norm_words(entries[k].get('english', '')) for k in grp]
                shared = set.intersection(*words) if words else set()
                if not shared:
                    clusters.append(grp)
                    seen.update(grp)

    for grp in clusters:
        for key in grp:
            flags.setdefault(key, []).append('duplicate')

    if verbose:
        print(f'  images on disk:            {len(hashes)}')
        print(f'  person-template, no override: {at_risk}')
        print(f'  non-synonym duplicate clusters: {len(clusters)}'
              f'  ({sum(len(c) for c in clusters)} images)')
        for grp in sorted(clusters, key=len, reverse=True)[:6]:
            print(f'\n    {len(grp)} different meanings, one picture:')
            for k in grp[:8]:
                print(f'       {k:<46} {entries[k].get("english","")[:40]}')
    return flags, clusters


# ---------------------------------------------------------------------------
# CLIP pass
# ---------------------------------------------------------------------------

def clip_rank(entries, limit=0, batch=64, seed=11):
    import torch
    from PIL import Image
    from transformers import CLIPModel, CLIPProcessor

    name = 'openai/clip-vit-base-patch32'
    device = 'cuda' if torch.cuda.is_available() else 'cpu'
    print(f'  loading {name} on {device} (first run downloads ~600 MB)')
    model = CLIPModel.from_pretrained(name).to(device).eval()
    proc = CLIPProcessor.from_pretrained(name)

    keys = [k for k in entries if _image_for(k)]
    keys.sort()
    if limit:
        keys = keys[:limit]
    print(f'  scoring {len(keys)} images')

    # --- text embeddings, one per distinct gloss --------------------------
    glosses = sorted({entries[k].get('english', '') for k in keys})
    gidx = {g: i for i, g in enumerate(glosses)}
    tvecs = []
    with torch.no_grad():
        for i in range(0, len(glosses), 256):
            chunk = [CAPTION.format(g) for g in glosses[i:i + 256]]
            tok = proc(text=chunk, return_tensors='pt', padding=True,
                       truncation=True, max_length=77).to(device)
            v = model.get_text_features(**tok)
            tvecs.append(torch.nn.functional.normalize(v, dim=-1).cpu())
            print(f'    text {min(i + 256, len(glosses))}/{len(glosses)}',
                  end='\r')
    tvecs = torch.cat(tvecs)
    print()

    rng = random.Random(seed)
    results = []
    with torch.no_grad():
        for i in range(0, len(keys), batch):
            part = keys[i:i + batch]
            imgs = []
            for k in part:
                try:
                    imgs.append(Image.open(_image_for(k)).convert('RGB'))
                except Exception:
                    imgs.append(Image.new('RGB', (64, 64)))
            px = proc(images=imgs, return_tensors='pt').to(device)
            iv = model.get_image_features(**px)
            iv = torch.nn.functional.normalize(iv, dim=-1).cpu()

            for j, k in enumerate(part):
                own = entries[k].get('english', '')
                oi = gidx.get(own)
                if oi is None:
                    continue
                pool = rng.sample(range(len(glosses)),
                                  min(DISTRACTORS, len(glosses)))
                if oi not in pool:
                    pool[0] = oi
                sims = iv[j] @ tvecs[pool].T
                own_sim = float(iv[j] @ tvecs[oi])
                rank = int((sims > own_sim).sum())
                results.append({
                    'key': k,
                    'english': own,
                    'category': entries[k].get('category', ''),
                    'awing': entries[k].get('awing', ''),
                    'similarity': round(own_sim, 4),
                    'rank': rank,
                    'pool': len(pool),
                    'percentile': round(100.0 * rank / len(pool), 1),
                })
            print(f'    images {min(i + batch, len(keys))}/{len(keys)}',
                  end='\r')
    print()
    return results


# ---------------------------------------------------------------------------
# Contact sheets
# ---------------------------------------------------------------------------

def contact_sheets(rows, sheets=40, per_sheet=48, cols=8, tile=180):
    from PIL import Image, ImageDraw
    os.makedirs(SHEET_DIR, exist_ok=True)
    worst = [r for r in rows if r.get('percentile') is not None]
    worst.sort(key=lambda r: -r['percentile'])
    made = 0
    cap_h = 34
    for s in range(sheets):
        part = worst[s * per_sheet:(s + 1) * per_sheet]
        if not part:
            break
        rows_n = (len(part) + cols - 1) // cols
        sheet = Image.new('RGB', (cols * tile, rows_n * (tile + cap_h)),
                          'white')
        d = ImageDraw.Draw(sheet)
        for i, r in enumerate(part):
            p = _image_for(r['key'])
            x, y = (i % cols) * tile, (i // cols) * (tile + cap_h)
            if p:
                try:
                    im = Image.open(p).convert('RGB').resize((tile, tile))
                    sheet.paste(im, (x, y))
                except Exception:
                    pass
            cap = r['english'][:30]
            d.text((x + 3, y + tile + 2), cap, fill='black')
            d.text((x + 3, y + tile + 16),
                   f"worse than {r['percentile']:.0f}%", fill='red')
        out = os.path.join(SHEET_DIR, f'sheet_{s + 1:02d}.png')
        sheet.save(out)
        made += 1
    print(f'  wrote {made} contact sheet(s) to '
          f'{os.path.relpath(SHEET_DIR, PROJECT_DIR)}')
    return made


def main():
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--structural', action='store_true',
                    help='duplicate + template checks only, no GPU')
    ap.add_argument('--sheets-only', action='store_true',
                    help='rebuild contact sheets from an existing report')
    ap.add_argument('--limit', type=int, default=0,
                    help='score only the first N images (0 = all)')
    ap.add_argument('--sheets', type=int, default=40)
    ap.add_argument('--batch', type=int, default=64)
    args = ap.parse_args()

    os.makedirs(CONTRIB_DIR, exist_ok=True)
    print('Reading vocabulary, phrases, sentences, stories...')
    entries, gi = _entries()
    print(f'  {len(entries)} keys that should have an image\n')

    if args.sheets_only:
        with open(REPORT_PATH, encoding='utf-8') as f:
            rows = json.load(f)['images']
        contact_sheets(rows, sheets=args.sheets)
        return 0

    print('Structural checks:')
    flags, clusters = structural(entries, gi)
    print()

    rows = []
    if not args.structural:
        print('CLIP pass:')
        rows = clip_rank(entries, limit=args.limit, batch=args.batch)
        for r in rows:
            r['flags'] = flags.get(r['key'], [])
    else:
        for key in entries:
            if _image_for(key):
                rows.append({
                    'key': key,
                    'english': entries[key].get('english', ''),
                    'category': entries[key].get('category', ''),
                    'awing': entries[key].get('awing', ''),
                    'flags': flags.get(key, []),
                })

    report = {
        'images': rows,
        'duplicate_clusters': [
            [{'key': k, 'english': entries[k].get('english', '')} for k in c]
            for c in clusters
        ],
    }
    with open(REPORT_PATH, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    print(f'  report -> {os.path.relpath(REPORT_PATH, PROJECT_DIR)}')

    if rows and not args.structural:
        scored = [r for r in rows if 'percentile' in r]
        bad = [r for r in scored if r['percentile'] >= 50]
        awful = [r for r in scored if r['percentile'] >= 80]
        print(f'\n  scored:                 {len(scored)}')
        print(f'  own meaning beaten by half the corpus: {len(bad)}')
        print(f'  beaten by 80% of it:                   {len(awful)}')
        print()
        contact_sheets(rows, sheets=args.sheets)
        print('\nWalk the sheets worst-first and stop when they stop being '
              'wrong. Everything above that line needs a PROMPT_OVERRIDE, a '
              'category change, or a native photo.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
