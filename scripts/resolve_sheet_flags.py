#!/usr/bin/env python3
"""Turn the by-eye sheet review into two files the pipeline can act on.

contributions/_sheets/flags.txt is written by hand while looking at the
contact sheets. Each line is

    <sheet> <tag> <tile>,<tile>,...

with tag W (white/light-skinned person, or non-Black hair), U (unclear -
an abstract blob, scattered icons, an empty frame), T (text rendered into
the picture) or D (duplicate of a neighbouring tile).

THE SPLIT IS THE POINT.

  W  -> scripts/_reshoot_white.txt
         The prompt for these changed: the skin clause, the Black-hair
         clause and the negative prompt all moved in Session 66v. Shooting
         them again produces a different picture.

  U/T/D -> contributions/needs_prompt_visual.json
         The prompt for these is the problem. "a partnership work" will
         render as an abstract blob every time it is shot, with any seed.
         These need a written scene in PROMPT_OVERRIDES. Reshooting them
         is how three earlier rounds were spent.

Usage:
    python scripts/resolve_sheet_flags.py
"""
import json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHEETS = os.path.join(ROOT, 'contributions', '_sheets')
VOCAB = os.path.join(ROOT, 'lib', 'data', 'awing_vocabulary.dart')

index = json.load(open(os.path.join(SHEETS, 'index.json'), encoding='utf-8'))

# key -> english, for the needs-a-prompt file. Without the gloss the list
# is unusable: you cannot write a scene for a filename.
gloss = {}
row = re.compile(
    r"^\s*AwingWord\(awing: (?:'((?:[^'\\]|\\.)*)'|\"([^\"]*)\"), "
    r"english: '((?:[^'\\]|\\.)*)'.*?category: '(\w+)'", re.M)
sys.path.insert(0, os.path.join(ROOT, 'scripts'))
try:
    from awing_key import image_key
except Exception:
    image_key = None
if image_key:
    for a, b, e, c in row.findall(open(VOCAB, encoding='utf-8').read()):
        gloss[image_key((a or b), e)] = {'english': e, 'category': c,
                                         'awing': (a or b)}

buckets = {'W': [], 'U': [], 'T': [], 'D': [], 'X': []}
path = os.path.join(SHEETS, 'flags.txt')
for line in open(path, encoding='utf-8'):
    line = line.strip()
    if not line or line.startswith('#'):
        continue
    parts = line.split()
    if len(parts) != 3 or parts[1] not in buckets:
        print(f'  ?? skipped: {line}')
        continue
    sheet, tag, tiles = parts
    for t in tiles.split(','):
        if not t.strip():
            continue
        ref = f's{int(sheet):03d}t{int(t):02d}'
        fn = index.get(ref)
        if not fn:
            print(f'  ?? no image at {ref}')
            continue
        buckets[tag].append(os.path.splitext(fn)[0])

# X first: a weapon or a bare body on a children's card is not a quality
# problem, it is a shipping blocker. These are listed on their own so they
# cannot be lost inside a list of 400 keys, and the entry should be gated
# in _ADULT_ENTRY / the negative prompt rather than just reshot.
if buckets['X']:
    out_x = os.path.join(ROOT, 'contributions', 'unsafe_images.txt')
    with open(out_x, 'w', encoding='utf-8') as f:
        f.write('\n'.join(sorted(set(buckets['X']))) + '\n')
    print(f'  UNSAFE - look at these first -> '
          f'{os.path.relpath(out_x, ROOT)}  ({len(set(buckets["X"]))} keys)')

out_keys = os.path.join(ROOT, 'scripts', '_reshoot_white.txt')
with open(out_keys, 'w', encoding='utf-8') as f:
    f.write('\n'.join(sorted(set(buckets['W']) | set(buckets['X']))) + '\n')

needs = {}
for tag in ('U', 'T', 'D'):
    why = {'U': 'does not show a recognisable object',
           'T': 'text rendered into the picture',
           'D': 'duplicate of a neighbouring card'}[tag]
    for k in buckets[tag]:
        needs.setdefault(k, dict(gloss.get(k, {}), why=why))
out_needs = os.path.join(ROOT, 'contributions', 'needs_prompt_visual.json')
json.dump(needs, open(out_needs, 'w', encoding='utf-8'),
          indent=2, ensure_ascii=False)

print(f'  reviewed tiles flagged: '
      f"W={len(buckets['W'])} U={len(buckets['U'])} "
      f"T={len(buckets['T'])} D={len(buckets['D'])}")
print(f'  RESHOOT (a new shot fixes these) -> '
      f'{os.path.relpath(out_keys, ROOT)}  ({len(set(buckets["W"]))} keys)')
print(f'  NEEDS A PROMPT (reshooting will not) -> '
      f'{os.path.relpath(out_needs, ROOT)}  ({len(needs)} keys)')
