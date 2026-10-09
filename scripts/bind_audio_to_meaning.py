#!/usr/bin/env python3
"""Bind each native clip to the MEANING it was actually recorded for.

THE PROBLEM
-----------
A clip is named from the Awing spelling alone, and audio_key() strips
tone, so nine different words share one file:

    mbaŋə  rain                              -> mbange.opus
    mbáŋə  maggot-like insect in raffia palm -> mbange.opus
    mbaŋə̂ tumor                             -> mbange.opus
    mbaŋə  cane / walking stick / ...        -> mbange.opus

176 clips answer for 604 cards, so 428 cards play a recording of a
different word. The IMAGE key never had this: it is
audio_key + '__' + english_slug.

WHY NOT JUST RE-RECORD
----------------------
Dr. Sama: "some of this word are recorded by natives. I will not have
them rerecord." The recordings are irreplaceable. The job is to attach
each one to the right meaning, not to replace it.

WHERE THE ANSWER ALREADY IS
---------------------------
Two records say what each clip was recorded for:

  training_data/recordings/manifest.json   key + awing + english
  contributions/applied/*.json             targetWord + englishMeaning

Between them they name the exact meaning for 133 of the 176, with no
disagreement on any of them.

WHAT THIS WRITES
----------------
1. A COPY of each resolved clip under its gloss-aware name. A copy, not
   a rename: the bare name must stay, because AwingAudioButton - the
   shared playback widget - does not know the meaning and would find
   nothing. Nothing is ever allowed to go silent by accident.

2. lib/data/audio_clip_claims.dart - bare key -> the meaning that owns
   the recording. PronunciationService uses it to refuse the bare clip
   when the word being spoken is NOT the one in the recording.

   Silence is the right answer there. The app already treats it that
   way ("there is no synthetic fallback any more"), and on a vocabulary
   card for a child, hearing nothing is better than hearing a different
   word.

    python scripts/bind_audio_to_meaning.py --dry-run
    python scripts/bind_audio_to_meaning.py --apply
"""
import argparse, collections, glob, io, json, os, re, shutil, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'scripts'))
from awing_key import audio_key, english_slug          # noqa: E402

NATIVE = os.path.join(ROOT, 'android', 'install_time_assets', 'src', 'main',
                      'assets', 'audio', 'native', 'vocabulary')
VOCAB = os.path.join(ROOT, 'lib', 'data', 'awing_vocabulary.dart')
OUT_DART = os.path.join(ROOT, 'lib', 'data', 'audio_clip_claims.dart')

ROW = (r"AwingWord\(\s*awing:\s*(?:'((?:[^'\\]|\\.)*?)'|\"([^\"]*?)\")\s*,"
       r"\s*english:\s*(?:'((?:[^'\\]|\\.)*?)'|\"([^\"]*?)\")")


def live_rows():
    t = io.open(VOCAB, encoding='utf-8').read()
    body = "\n".join(l for l in t.splitlines()
                     if not l.lstrip().startswith('//'))
    return [((a or b).replace("\\'", "'"), (e1 or e2).replace("\\'", "'"))
            for a, b, e1, e2 in re.findall(ROW, body)]


def provenance():
    """key -> {english}, from both records of what was recorded."""
    out = collections.defaultdict(set)
    man = os.path.join(ROOT, 'training_data', 'recordings', 'manifest.json')
    if os.path.exists(man):
        m = json.load(io.open(man, encoding='utf-8'))
        recs = m if isinstance(m, list) else m.get('recordings',
                                                   list(m.values()))
        for r in recs:
            if isinstance(r, dict) and r.get('key') and r.get('english'):
                out[r['key']].add(str(r['english']).strip())
    for f in glob.glob(os.path.join(ROOT, 'contributions', 'applied',
                                    '*.json')):
        try:
            d = json.load(io.open(f, encoding='utf-8'))
        except Exception:
            continue
        items = d if isinstance(d, list) else d.get('contributions',
                                                    d.get('items', []))
        if isinstance(items, dict):
            items = list(items.values())
        for it in items:
            if not isinstance(it, dict) or not it.get('audioUrl'):
                continue
            tw, em = it.get('targetWord'), it.get('englishMeaning')
            if tw and em:
                out[audio_key(tw)].add(str(em).strip())
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--apply', action='store_true')
    ap.add_argument('--dry-run', action='store_true')
    args = ap.parse_args()
    apply = args.apply and not args.dry_run

    by = collections.defaultdict(list)
    for aw, en in live_rows():
        by[audio_key(aw)].append((aw, en))
    have = {os.path.splitext(os.path.basename(f))[0]
            for f in glob.glob(os.path.join(NATIVE, '*.opus'))}
    prov = provenance()

    collided = [k for k in sorted(have)
                if k in by and len({e for _, e in by[k]}) > 1]
    resolved, unknown = {}, []
    for k in collided:
        hit = {e for e in prov.get(k, set())} & {e for _, e in by[k]}
        if len(hit) == 1:
            resolved[k] = next(iter(hit))
        else:
            unknown.append(k)

    copied = 0
    for k, en in sorted(resolved.items()):
        target = f'{k}__{english_slug(en)}'
        for ext in ('.opus', '.wav'):
            src = os.path.join(NATIVE, k + ext)
            dst = os.path.join(NATIVE, target + ext)
            if os.path.exists(src) and not os.path.exists(dst):
                if apply:
                    shutil.copy2(src, dst)
                copied += 1

    lines = [
        '// GENERATED by scripts/bind_audio_to_meaning.py - do not edit.',
        '//',
        '// Which meaning each shared native clip was actually recorded for.',
        '// A clip is named from the Awing spelling alone and audio_key()',
        '// strips tone, so one file answers for several words - mbange.opus',
        '// is claimed by rain, tumor, cane, walking stick and five more.',
        '//',
        '// Recovered from training_data/recordings/manifest.json and',
        '// contributions/applied/*.json, which both record the gloss that',
        '// was on screen when the recording was made. Nobody re-recorded',
        '// anything: these are the same irreplaceable native clips, bound',
        '// to the right word.',
        '//',
        '// PronunciationService refuses the bare clip when the word being',
        '// spoken is not the one named here. Silence beats the wrong word.',
        'const Map<String, String> kAudioClipClaims = {',
    ]
    for k, en in sorted(resolved.items()):
        lines.append("  '%s': '%s'," % (k, en.replace("\\", r"\\")
                                        .replace("'", r"\'")))
    lines += ['};', '']
    if apply:
        io.open(OUT_DART, 'w', encoding='utf-8').write('\n'.join(lines))

    print(f'  collided clips                        {len(collided)}')
    print(f'  bound to one meaning from provenance  {len(resolved)}')
    print(f'  no record of what was recorded        {len(unknown)}')
    print(f'  clip copies {"written" if apply else "that would be written"}'
          f'           {copied}')
    print(f'  {OUT_DART.replace(ROOT + os.sep, "")}'
          f' {"written" if apply else "NOT written (dry run)"}')
    if unknown:
        print('\n  these still need your ear (no provenance):')
        for k in unknown[:12]:
            print(f'    {k:<14} {" | ".join(sorted({e for _, e in by[k]}))[:66]}')
        if len(unknown) > 12:
            print(f'    ... and {len(unknown) - 12} more')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
