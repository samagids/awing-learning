#!/usr/bin/env python3
"""cleanup_assets.py — PAD asset diet, v1.17.x

Two-stage cleanup with --tier flag:

  --tier 1 (default)
    Delete orphan vocabulary images — entries on disk that no longer have
    a matching (awing, english) row in lib/data/awing_vocabulary.dart.
    Saves ~376 MB at last audit.

  --tier 2
    Re-encode every audio/*.mp3 in the PAD pack to OPUS at 32 kbps mono
    with VoIP-tuned encoder. Saves ~120 MB (roughly 50% of audio
    weight). Updates pronunciation_service.dart's extension lookup
    from .mp3 → .opus in the same run so the app finds the new files.

Usage:
  python scripts\\cleanup_assets.py --tier 1
  python scripts\\cleanup_assets.py --tier 2
  python scripts\\cleanup_assets.py --tier all       # both, in order

Tier 2 requires ffmpeg in PATH (already installed for the Edge TTS
pipeline). The conversion is multi-process — uses os.cpu_count()
workers, completes ~18k clips in 3-6 min on a fast machine.

After running, re-execute:
  bash scripts/pack_and_upload_assets.sh
to push the slimmer PAD to GitHub Releases.
"""
import argparse
import concurrent.futures
import os
import re
import shutil
import subprocess
import sys
import time
import unicodedata
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
VOCAB_FILE = REPO / 'lib' / 'data' / 'awing_vocabulary.dart'
IMAGES_DIR = REPO / 'android' / 'install_time_assets' / 'src' / 'main' / 'assets' / 'images' / 'vocabulary'
AUDIO_ROOT = REPO / 'android' / 'install_time_assets' / 'src' / 'main' / 'assets' / 'audio'
PRONUNCIATION_DART = REPO / 'lib' / 'services' / 'pronunciation_service.dart'


# ===== shared image_key (mirror generate_images.py) =====

_REPL = {"ɛ":"e","Ɛ":"E","ɔ":"o","Ɔ":"O","ə":"e","Ə":"E",
         "ɨ":"i","Ɨ":"I","ŋ":"ng","Ŋ":"Ng","ɣ":"g","Ɣ":"G"}

def audio_key(awing):
    s = awing.replace("'", "").replace("ʼ", "").replace("’", "").replace("‘", "")
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if not unicodedata.combining(c))
    for k, v in _REPL.items():
        s = s.replace(k, v)
    s = re.sub(r"[^A-Za-z0-9]+", "_", s).strip("_").lower()
    return s

def english_slug(eng):
    s = re.sub(r"[^A-Za-z0-9]+", "_", eng.lower()).strip("_")
    return s[:40]

def image_key(awing, english):
    return f"{audio_key(awing)}__{english_slug(english)}"


# ===== Tier 1 — orphan image delete =====

def needed_image_keys():
    sq = r"'((?:\\.|[^'\\])*)'"
    dq = r'"((?:\\.|[^"\\])*)"'
    s = rf"(?:{sq}|{dq})"
    pat = re.compile(
        rf"AwingWord\(\s*awing:\s*{s}\s*,\s*english:\s*{s}",
        re.DOTALL,
    )
    content = VOCAB_FILE.read_text(encoding='utf-8')
    keys = set()
    for m in pat.finditer(content):
        line_start = content.rfind('\n', 0, m.start()) + 1
        if '//' in content[line_start:m.start()]:
            continue
        awing = (m.group(1) if m.group(1) is not None else m.group(2) or '').replace("\\'", "'")
        english = (m.group(3) if m.group(3) is not None else m.group(4) or '').replace("\\'", "'")
        if awing and english:
            keys.add(image_key(awing, english))
    return keys


def tier1_orphan_delete(dry_run=False):
    print(f"=== Tier 1: orphan image delete ===")
    if not IMAGES_DIR.exists():
        print(f"  ERROR: {IMAGES_DIR} does not exist")
        return 1
    needed = needed_image_keys()
    print(f"  Vocab needs: {len(needed):,} image keys")
    on_disk = {p.stem for p in IMAGES_DIR.glob('*.png')}
    orphans = sorted(on_disk - needed)
    print(f"  On disk:     {len(on_disk):,} PNGs")
    print(f"  Orphans:     {len(orphans):,}")
    if not orphans:
        print(f"  Nothing to delete. Done.")
        return 0
    total_bytes = sum((IMAGES_DIR / f'{k}.png').stat().st_size for k in orphans)
    print(f"  Would free:  {total_bytes/1024/1024:.1f} MB")
    if dry_run:
        print(f"  [DRY RUN — no files deleted]")
        return 0
    deleted = 0
    freed = 0
    for k in orphans:
        p = IMAGES_DIR / f'{k}.png'
        try:
            freed += p.stat().st_size
            p.unlink()
            deleted += 1
        except OSError as e:
            print(f"  ! couldn't delete {p.name}: {e}")
    print(f"  Deleted:     {deleted:,}")
    print(f"  Freed:       {freed/1024/1024:.1f} MB")
    return 0


# ===== Tier 2 — MP3 → OPUS conversion =====

def _convert_one(mp3_path: Path):
    """Convert one MP3 to OPUS at 32k mono. Returns (success, bytes_in, bytes_out, err)."""
    opus_path = mp3_path.with_suffix('.opus')
    if opus_path.exists() and opus_path.stat().st_size > 0:
        # Already converted — skip
        return ('skip', mp3_path.stat().st_size, opus_path.stat().st_size, None)
    try:
        result = subprocess.run(
            [
                'ffmpeg', '-y', '-loglevel', 'error',
                '-i', str(mp3_path),
                '-c:a', 'libopus',
                '-b:a', '32k',
                '-ac', '1',  # force mono
                '-application', 'voip',  # speech-tuned
                str(opus_path),
            ],
            check=False,
            capture_output=True,
            timeout=30,
        )
        if result.returncode != 0:
            return ('err', mp3_path.stat().st_size, 0,
                    result.stderr.decode('utf-8', errors='replace')[:200])
        if not opus_path.exists() or opus_path.stat().st_size == 0:
            return ('err', mp3_path.stat().st_size, 0, 'output file empty')
        return ('ok', mp3_path.stat().st_size, opus_path.stat().st_size, None)
    except Exception as e:
        return ('err', mp3_path.stat().st_size, 0, str(e)[:200])


def tier2_mp3_to_opus(dry_run=False, delete_mp3=True, workers=None):
    print(f"=== Tier 2: MP3 → OPUS ===")
    if not shutil.which('ffmpeg'):
        print(f"  ERROR: ffmpeg not in PATH. Install via winget: winget install Gyan.FFmpeg")
        return 1
    mp3s = list(AUDIO_ROOT.rglob('*.mp3'))
    if not mp3s:
        print(f"  No .mp3 files found under {AUDIO_ROOT}")
        return 0
    total_in = sum(p.stat().st_size for p in mp3s)
    print(f"  MP3 files:   {len(mp3s):,} ({total_in/1024/1024:.1f} MB total)")
    if dry_run:
        print(f"  [DRY RUN — no conversions]")
        return 0
    workers = workers or max(1, (os.cpu_count() or 4) - 1)
    print(f"  Converting with {workers} workers...")
    total_out = 0
    ok = 0
    skipped = 0
    err = 0
    err_samples = []
    t0 = time.time()
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as pool:
        for i, (status, in_sz, out_sz, errmsg) in enumerate(
                pool.map(_convert_one, mp3s)):
            total_out += out_sz
            if status == 'ok':
                ok += 1
            elif status == 'skip':
                skipped += 1
            else:
                err += 1
                if len(err_samples) < 5:
                    err_samples.append((mp3s[i].name, errmsg))
            if (i + 1) % 500 == 0:
                elapsed = time.time() - t0
                rate = (i + 1) / elapsed
                eta = (len(mp3s) - i - 1) / rate
                pct = (i + 1) * 100 // len(mp3s)
                print(f"  [{pct:3d}%] {i+1:,}/{len(mp3s):,}  "
                      f"({rate:.0f}/s, ETA {eta:.0f}s)")
    elapsed = time.time() - t0
    print(f"\n  Converted:   {ok:,}")
    print(f"  Skipped:     {skipped:,} (already had .opus)")
    print(f"  Errors:      {err:,}")
    for fname, e in err_samples:
        print(f"    ! {fname}: {e}")
    print(f"  Time:        {elapsed:.0f}s")
    if total_out > 0:
        ratio = total_out / total_in * 100
        print(f"  Size before: {total_in/1024/1024:.1f} MB")
        print(f"  Size after:  {total_out/1024/1024:.1f} MB ({ratio:.0f}% of original)")
        print(f"  Saved:       {(total_in - total_out)/1024/1024:.1f} MB")
    if not delete_mp3:
        print(f"  [--keep-mp3 set; .mp3 files remain on disk]")
        return 0
    # Only delete MP3s for which the OPUS exists
    deleted = 0
    for p in mp3s:
        opus = p.with_suffix('.opus')
        if opus.exists() and opus.stat().st_size > 0:
            try:
                p.unlink()
                deleted += 1
            except OSError:
                pass
    print(f"  Deleted MP3: {deleted:,} (kept the {err:,} where OPUS failed)")

    # Patch pronunciation_service.dart to use .opus extension
    _patch_pronunciation_service()
    return 0


def _patch_pronunciation_service():
    """Update lib/services/pronunciation_service.dart to load .opus instead of .mp3."""
    if not PRONUNCIATION_DART.exists():
        print(f"  ! {PRONUNCIATION_DART} not found — skipping Dart patch")
        return
    text = PRONUNCIATION_DART.read_text(encoding='utf-8')
    new = text.replace("$key.mp3'", "$key.opus'")
    if new == text:
        print(f"  pronunciation_service.dart: no .mp3 path references found "
              f"(already patched or different pattern)")
        return
    PRONUNCIATION_DART.write_text(new, encoding='utf-8')
    changes = text.count("$key.mp3'") - new.count("$key.mp3'")
    print(f"  pronunciation_service.dart: patched {changes} .mp3 → .opus")


# ===== CLI =====

def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--tier', choices=['1', '2', 'all'], default='1')
    p.add_argument('--dry-run', action='store_true',
                   help='Report what would happen without changing files.')
    p.add_argument('--keep-mp3', action='store_true',
                   help='Tier 2: convert to OPUS but keep original MP3 files.')
    args = p.parse_args()

    rc = 0
    if args.tier in ('1', 'all'):
        rc = tier1_orphan_delete(dry_run=args.dry_run) or rc
    if args.tier in ('2', 'all'):
        rc = tier2_mp3_to_opus(dry_run=args.dry_run,
                               delete_mp3=not args.keep_mp3) or rc
    return rc


if __name__ == '__main__':
    sys.exit(main())
