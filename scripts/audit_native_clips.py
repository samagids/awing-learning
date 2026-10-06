#!/usr/bin/env python3
"""Quality gate for the native-speaker clips that ship in the PAD pack.

WHY THIS IS SEPARATE FROM trim_silence.py
-----------------------------------------
scripts/trim_silence.py deliberately mirrors lib/utils/silence_trim.dart
sample-for-sample, because the on-device pronunciation grader and the
server-side ingestion must agree. Its threshold is RELATIVE to the clip's
own peak (max(peak * 0.05, 0.005)). That is the right call for grading a
kid's attempt, but it has two consequences for shipped native audio:

  1. A clip whose loudest moment is itself quiet (a distant or fumbled
     take) has a correspondingly low threshold, so its room noise reads
     as speech and nothing gets trimmed.
  2. When a clip is judged entirely silent the trimmer returns the
     ORIGINAL array untouched, so a dud recording still ships. The app
     then shows the word as having native audio and plays nothing, which
     is worse than honestly showing no audio.

Changing those parameters would change pronunciation grading, so this
script does not touch them. It is an independent audit that uses an
ABSOLUTE dBFS gate, the way a listener hears the clip.

WHAT IT CHECKS
--------------
  empty           under 10% of the clip is above the silence gate. There
                  is no take in there to rescue; the word needs
                  re-recording.
  quiet           the take is fine but was recorded far from the mic, so
                  its peak is below --peak-floor. A gain problem, not a
                  content problem.
  head/tail       more than --max-head / --max-tail of silence at the
                  edges. Safe to fix: nothing audible is removed.
  multi-utterance a long clip with internal gaps, i.e. the speaker said
                  the word twice, or it is a legitimate multi-word
                  phrase. REPORTED ONLY. Cutting a phrase down to its
                  first word would be a silent data-loss bug, so a human
                  confirms these.

WHAT --fix DOES
---------------
  head/tail  -> trims the dead air, keeping --pad either side.
  quiet      -> peak-normalises up to --target-peak.
  both       -> done in ONE ffmpeg pass, to avoid a second generation of
                lossy loss. Always applied to .opus (48k mono) and .wav
                (16k mono) together: the .opus is what the child hears
                and the .wav is what the pronunciation grader scores
                against, so the two must never drift apart.
  empty      -> moves every format of the clip to
                contributions/quarantined_clips/<category>/ and leaves a
                note in contributions/clip_quarantine.json. After this,
                re-run scripts/build_native_audio_manifest.py so the
                manifest stops advertising audio for those words. An
                honest "no audio yet" beats a button that plays nothing.
  multi      -> never touched.

USAGE
    python scripts/audit_native_clips.py                  # report
    python scripts/audit_native_clips.py --fix            # apply safe fixes
    python scripts/audit_native_clips.py --json out.json
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
NATIVE_DIR = ROOT / 'android' / 'install_time_assets' / 'src' / 'main' / 'assets' / 'audio' / 'native'
KIDS_DIR = NATIVE_DIR.parent / 'native_kids'
QUARANTINE_DIR = ROOT / 'contributions' / 'quarantined_clips'
QUARANTINE_LOG = ROOT / 'contributions' / 'clip_quarantine.json'

# Absolute gates. These describe what a listener hears, and are
# intentionally unrelated to the relative threshold in trim_silence.py.
SILENCE_DB = -32.0        # anything below this is silence for our purposes
MIN_SILENCE_RUN = 0.15    # seconds, shorter runs are stop consonants
DEFAULT_PEAK_FLOOR = -14.0   # below this the clip is too quiet on a phone
DEFAULT_MAX_HEAD = 0.35
DEFAULT_MAX_TAIL = 0.45
DEFAULT_PAD = 0.05
DEFAULT_TARGET_PEAK = -3.0   # peak-normalise quiet clips up to this
EMPTY_SPEECH_RATIO = 0.10    # under this there is nothing to normalise
MULTI_MIN_DUR = 1.5
MULTI_MIN_GAP = 0.30

# The gate used to DECIDE a clip has dead edges (-32dB) is deliberately
# looser than the gate used to CUT them (-36dB). Detecting at -32dB finds
# the clips worth fixing; cutting 4dB lower means a breathy onset or a
# nasal release survives the trim, and the --pad either side covers the
# rest. -40dB was tried first and was too strict: on these recordings the
# room floor sits around -38dB, so the cut gate found no dead air at all
# and clips with a visible half-second of silence went unfixed forever.
TRIM_GATE_DB = -36.0

# How far from the very start (or end) a silence run may begin and still
# count as an edge. ffmpeg's silencedetect reports the run's start on a
# window boundary, so a clip that is dead air from sample zero routinely
# reports silence_start: 0.0502. A 0.05 tolerance therefore reads it as
# an interior gap and the clip never gets trimmed. Anything audible in
# the first 120ms of a word recording is a click or a mic thump, not a
# syllable onset, so treating it as part of the edge is also correct.
EDGE_TOLERANCE = 0.12


def _run(cmd: list[str]) -> str:
    return subprocess.run(cmd, capture_output=True, text=True).stderr


def probe(path: Path) -> dict | None:
    """Return duration, peak dBFS, and the silence intervals of a clip."""
    out = subprocess.run(
        ['ffprobe', '-v', 'error', '-show_entries', 'format=duration',
         '-of', 'csv=p=0', str(path)],
        capture_output=True, text=True)
    try:
        dur = float(out.stdout.strip())
    except ValueError:
        return None

    vol = _run(['ffmpeg', '-i', str(path), '-af', 'volumedetect', '-f', 'null', '-'])
    peak = mean = None
    for line in vol.splitlines():
        if 'max_volume:' in line:
            peak = float(line.split('max_volume:')[1].replace('dB', '').strip())
        elif 'mean_volume:' in line:
            mean = float(line.split('mean_volume:')[1].replace('dB', '').strip())

    det = _run(['ffmpeg', '-i', str(path), '-af',
                f'silencedetect=noise={SILENCE_DB}dB:d={MIN_SILENCE_RUN}',
                '-f', 'null', '-'])
    ivs, start = [], None
    for line in det.splitlines():
        if 'silence_start:' in line:
            start = float(line.split('silence_start:')[1].strip())
        elif 'silence_end:' in line and start is not None:
            ivs.append((start, float(line.split('silence_end:')[1].split('|')[0].strip())))
            start = None
    if start is not None:
        ivs.append((start, dur))

    head = ivs[0][1] if ivs and ivs[0][0] <= EDGE_TOLERANCE else 0.0
    tail = (dur - ivs[-1][0]) if ivs and ivs[-1][1] >= dur - EDGE_TOLERANCE else 0.0
    inner = [iv for iv in ivs
             if iv[0] > EDGE_TOLERANCE and iv[1] < dur - EDGE_TOLERANCE
             and (iv[1] - iv[0]) >= MULTI_MIN_GAP]
    speech = dur - sum(e - s for s, e in ivs)
    return {
        'duration': dur, 'peak_db': peak, 'mean_db': mean,
        'head': head, 'tail': tail, 'inner_gaps': len(inner),
        'speech_ratio': (speech / dur) if dur else 0.0,
    }


def classify(info: dict, args) -> list[str]:
    """Sort one clip into the buckets that decide what happens to it.

    'empty' and 'quiet' are kept apart on purpose. A clip can sit at
    -17dB peak and still be a perfectly good take that was simply
    recorded far from the mic - 100% of it is above the silence gate.
    That is a gain problem, and quarantining it would throw away a real
    recording. Only a clip that is almost entirely silence has nothing
    to recover, and only that one gets pulled from the pack.
    """
    flags = []
    if info['peak_db'] is None or info['speech_ratio'] < EMPTY_SPEECH_RATIO:
        return ['empty']
    if info['head'] > args.max_head:
        flags.append('head')
    if info['tail'] > args.max_tail:
        flags.append('tail')
    if info['peak_db'] < args.peak_floor:
        flags.append('quiet')
    if info['duration'] > MULTI_MIN_DUR and info['inner_gaps'] >= 1:
        flags.append('multi')
    return flags


def dead_edges(path: Path, duration: float) -> tuple[float, float]:
    """Head and tail silence measured at the conservative cutting gate."""
    det = _run(['ffmpeg', '-i', str(path), '-af',
                f'silencedetect=noise={TRIM_GATE_DB}dB:d={MIN_SILENCE_RUN}',
                '-f', 'null', '-'])
    ivs, start = [], None
    for line in det.splitlines():
        if 'silence_start:' in line:
            start = float(line.split('silence_start:')[1].strip())
        elif 'silence_end:' in line and start is not None:
            ivs.append((start, float(line.split('silence_end:')[1].split('|')[0].strip())))
            start = None
    if start is not None:
        ivs.append((start, duration))
    head = ivs[0][1] if ivs and ivs[0][0] <= EDGE_TOLERANCE else 0.0
    tail = (duration - ivs[-1][0]) if ivs and ivs[-1][1] >= duration - EDGE_TOLERANCE else 0.0
    return head, tail


def rewrite(path: Path, info: dict, pad: float, trim: bool, gain_db: float) -> bool:
    """Re-encode one clip, optionally trimming its edges and applying gain.

    Trim and gain are applied in a single pass so a clip that needs both
    is encoded once rather than twice - every extra opus round-trip is a
    further generation of lossy loss.
    """
    start, end = 0.0, info['duration']
    if trim:
        head, tail = dead_edges(path, info['duration'])
        if head > pad:
            start = head - pad
        if tail > pad:
            end = info['duration'] - (tail - pad)
    if end - start < 0.15:
        return False
    if start == 0.0 and end >= info['duration'] - 1e-6 and abs(gain_db) < 0.1:
        return False

    args_in = ['-i', str(path)]
    filt = [] if abs(gain_db) < 0.1 else ['-af', f'volume={gain_db:.2f}dB']
    is_wav = path.suffix == '.wav'
    codec = ['-ar', '16000', '-ac', '1'] if is_wav else \
            ['-c:a', 'libopus', '-b:a', '24k', '-ar', '48000', '-ac', '1']
    # ffmpeg picks the muxer from the output extension, so the temp file
    # must keep the real suffix LAST. 'x.opus.tmp' fails with
    # "Unable to find a suitable output format"; 'x.tmp.opus' works.
    tmp = path.with_name(path.stem + '.tmp' + path.suffix)
    r = subprocess.run(
        ['ffmpeg', '-y', '-v', 'error', *args_in,
         '-ss', f'{start:.3f}', '-to', f'{end:.3f}', *filt, *codec, str(tmp)],
        capture_output=True, text=True)
    if r.returncode != 0 or not tmp.exists() or tmp.stat().st_size == 0:
        tmp.unlink(missing_ok=True)
        print(f'    ! ffmpeg failed on {path.name}: {r.stderr.strip()[:120]}')
        return False
    tmp.replace(path)
    return True


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--fix', action='store_true',
                    help='apply the safe fixes (edge trim + quarantine)')
    ap.add_argument('--include-kids', action='store_true',
                    help='also audit native_kids/ (off by default: those are '
                         'children, whose takes are expected to be rougher)')
    ap.add_argument('--peak-floor', type=float, default=DEFAULT_PEAK_FLOOR)
    ap.add_argument('--max-head', type=float, default=DEFAULT_MAX_HEAD)
    ap.add_argument('--max-tail', type=float, default=DEFAULT_MAX_TAIL)
    ap.add_argument('--pad', type=float, default=DEFAULT_PAD)
    ap.add_argument('--target-peak', type=float, default=DEFAULT_TARGET_PEAK,
                    help='peak dBFS that quiet clips are lifted to')
    ap.add_argument('--json', help='write the full report to this path')
    args = ap.parse_args()

    roots = [NATIVE_DIR] + ([KIDS_DIR] if args.include_kids else [])
    clips: list[Path] = []
    for root in roots:
        if root.exists():
            clips += sorted(root.rglob('*.opus'))
    if not clips:
        print(f'No clips found under {NATIVE_DIR}')
        return 0

    print(f'Auditing {len(clips)} clips  (silence gate {SILENCE_DB}dB, '
          f'peak floor {args.peak_floor}dB)')

    report: dict[str, dict] = {}
    buckets: dict[str, list[str]] = {'empty': [], 'head': [], 'tail': [],
                                     'quiet': [], 'multi': []}
    for p in clips:
        info = probe(p)
        if info is None:
            print(f'  ! unreadable: {p.relative_to(ROOT)}')
            continue
        flags = classify(info, args)
        if not flags:
            continue
        rel = str(p.relative_to(NATIVE_DIR.parent))
        info['flags'] = flags
        report[rel] = info
        for f in flags:
            buckets[f].append(rel)

    print(f'\n  clean: {len(clips) - len(report)} / {len(clips)}')
    for name, title in (('empty', 'EMPTY - nothing to recover, will be quarantined'),
                        ('quiet', 'QUIET - will be peak-normalised'),
                        ('head', 'HEAD silence - will be trimmed'),
                        ('tail', 'TAIL silence - will be trimmed'),
                        ('multi', 'MULTI-UTTERANCE - review by hand, never auto-cut')):
        rels = buckets[name]
        print(f'\n{title}: {len(rels)}')
        for rel in rels:
            i = report[rel]
            print(f'    {rel:<46} {i["duration"]:>5.2f}s  peak {i["peak_db"]:>6.1f}dB  '
                  f'head {i["head"]:.2f}  tail {i["tail"]:.2f}  speech {i["speech_ratio"]:.0%}')

    if args.json:
        Path(args.json).write_text(json.dumps(report, indent=2), encoding='utf-8')
        print(f'\nFull report -> {args.json}')

    if not args.fix:
        if report:
            print('\nReport only. Re-run with --fix to trim the edges, '
                  'normalise the quiet clips and quarantine the empty ones.')
        return 0

    changed = quarantined = 0
    work = [r for r in report
            if {'head', 'tail', 'quiet'} & set(report[r]['flags'])]
    if work:
        print(f'\nRewriting {len(work)} clips (.opus and .wav together, '
              f'single ffmpeg pass each)')
    for rel in work:
        flags = set(report[rel]['flags'])
        trim = bool({'head', 'tail'} & flags)
        opus = NATIVE_DIR.parent / rel
        # Both formats are measured and rewritten, because the .opus feeds
        # playback and the .wav feeds the on-device pronunciation grader.
        # Letting them drift apart would mean the child hears one clip and
        # is scored against another.
        for path in (opus, opus.with_suffix('.wav')):
            if not path.exists():
                continue
            info = probe(path)
            if info is None or info['peak_db'] is None:
                continue
            gain = 0.0
            if 'quiet' in flags and info['peak_db'] < args.peak_floor:
                gain = args.target_peak - info['peak_db']
            if rewrite(path, info, args.pad, trim, gain):
                changed += 1
                bits = []
                if trim:
                    bits.append('trimmed')
                if gain:
                    bits.append(f'+{gain:.1f}dB')
                print(f'    {path.name:<42} {" ".join(bits)}')

    empty = buckets['empty']
    if empty:
        print(f'\nQuarantining {len(empty)} empty clips')
        log = []
        if QUARANTINE_LOG.exists():
            try:
                log = json.loads(QUARANTINE_LOG.read_text(encoding='utf-8'))
            except json.JSONDecodeError:
                log = []
        for rel in empty:
            opus = NATIVE_DIR.parent / rel
            dest_dir = QUARANTINE_DIR / Path(rel).parent
            dest_dir.mkdir(parents=True, exist_ok=True)
            moved = []
            for path in (opus, opus.with_suffix('.wav'), opus.with_suffix('.mp3')):
                if path.exists():
                    shutil.move(str(path), str(dest_dir / path.name))
                    moved.append(path.name)
            quarantined += 1
            log.append({'clip': rel, 'moved': moved,
                        'peak_db': report[rel]['peak_db'],
                        'mean_db': report[rel]['mean_db'],
                        'speech_ratio': round(report[rel]['speech_ratio'], 3),
                        'reason': 'almost entirely silence - needs re-recording'})
            print(f'    quarantined {rel}  ({", ".join(moved)})')
        QUARANTINE_LOG.write_text(json.dumps(log, indent=2), encoding='utf-8')
        print(f'    log -> {QUARANTINE_LOG.relative_to(ROOT)}')

    print(f'\nDone. {changed} files rewritten, {quarantined} clips quarantined.')
    if quarantined:
        print('NEXT: re-run scripts/build_native_audio_manifest.py so the manifest '
              'stops advertising audio for the quarantined words,')
        print('      then scripts/pack_and_upload_assets.sh to publish the pack.')
    elif changed:
        print('NEXT: scripts/pack_and_upload_assets.sh to publish the pack.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
