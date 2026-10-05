#!/usr/bin/env python3
"""Decide whether the PAD asset bundle on GitHub is stale.

Why this exists
---------------
CI does NOT build from this machine's asset tree. It downloads
pad-assets.tar.gz from the 'pad-assets' GitHub release. On 2026-07-05 that
tarball stopped being refreshed, and on 2026-10-04 v1.24.0+143 shipped a
958 MB AAB built from July's assets — old PNGs, the Edge TTS voices that
release removed, none of the regenerated images. The local build of the
same commit was 292.5 MB.

Nothing caught it because every guard tested PRESENCE, not freshness. A
stale bundle is indistinguishable from a fresh one by "does the release
exist". This script is the freshness test, and build_and_run.bat uses it
to re-upload automatically when new approved audio or images land.

How the fingerprint works
-------------------------
sha256 over sorted "<relpath>\\t<size>" lines for every file in the asset
dir. Only stat() is called — nothing is read — so it is fast over ~9k
files even on a OneDrive-backed path.

Size, not mtime: mtime churns when OneDrive re-syncs or files are copied,
and a spurious 10-30 minute upload is a real cost. Any genuine change —
a new recording, a regenerated image, a deleted stem — changes the file
list or a file's size. A re-record that lands on the identical byte count
AND the identical path is the one thing this misses; --force covers it.

Exit codes (build_and_run.bat branches on these):
    0   up to date — the release already has this exact tree
    10  changed — pack_and_upload_assets.sh needs to run
    1   error
"""
import hashlib
import json
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
ASSET_DIR = os.path.join(
    PROJECT_DIR, 'android', 'install_time_assets', 'src', 'main', 'assets')
STATE_FILE = os.path.join(PROJECT_DIR, 'config', 'asset_bundle_state.json')

# Never let an editor swap file or an OS artefact flip the fingerprint.
IGNORED_NAMES = {'.DS_Store', 'Thumbs.db', 'desktop.ini'}
IGNORED_SUFFIXES = ('.tmp', '.part', '.crdownload', '~')


def compute(asset_dir=ASSET_DIR):
    """Return (hexdigest, file_count, total_bytes) for the asset tree."""
    if not os.path.isdir(asset_dir):
        raise FileNotFoundError(asset_dir)

    entries = []
    total = 0
    for root, dirs, files in os.walk(asset_dir):
        dirs.sort()
        for name in sorted(files):
            if name in IGNORED_NAMES or name.endswith(IGNORED_SUFFIXES):
                continue
            path = os.path.join(root, name)
            try:
                size = os.stat(path).st_size
            except OSError:
                # A file that vanished mid-walk is a changed tree by
                # definition; let the next line record it as such.
                continue
            rel = os.path.relpath(path, asset_dir).replace(os.sep, '/')
            entries.append(f'{rel}\t{size}')
            total += size

    h = hashlib.sha256()
    for line in entries:
        h.update(line.encode('utf-8'))
        h.update(b'\n')
    return h.hexdigest(), len(entries), total


def load_state():
    try:
        with open(STATE_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception:
        return {}


def human(n):
    for unit in ('B', 'KB', 'MB', 'GB'):
        if n < 1024 or unit == 'GB':
            return f'{n:.1f} {unit}' if unit != 'B' else f'{n} B'
        n /= 1024.0


def main(argv):
    force = '--force' in argv
    record = '--record' in argv

    tarball = None
    if '--tarball' in argv:
        i = argv.index('--tarball')
        if i + 1 < len(argv):
            tarball = argv[i + 1]

    try:
        digest, count, total = compute()
    except FileNotFoundError as e:
        print(f'  asset dir not found: {e}')
        return 1

    if record:
        state = {
            'fingerprint': digest,
            'files': count,
            'bytes': total,
            'recorded_at': __import__('datetime').datetime.now(
                __import__('datetime').timezone.utc).isoformat(),
        }
        if tarball and os.path.exists(tarball):
            # The tarball hash is what you compare against the sha256
            # GitHub prints on the release asset. Presence on the release
            # page proves nothing — that is what the July tarball had.
            th = hashlib.sha256()
            with open(tarball, 'rb') as f:
                for chunk in iter(lambda: f.read(1 << 20), b''):
                    th.update(chunk)
            state['tarball_sha256'] = th.hexdigest()
            state['tarball_bytes'] = os.path.getsize(tarball)
        os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
        with open(STATE_FILE, 'w', encoding='utf-8') as f:
            json.dump(state, f, indent=2)
            f.write('\n')
        print(f'  Recorded asset bundle state: {count} files, '
              f'{human(total)}, {digest[:16]}...')
        if 'tarball_sha256' in state:
            print(f'  Tarball sha256: {state["tarball_sha256"]}')
            print('  Compare that against the sha256 GitHub shows on the '
                  'pad-assets release asset.')
        return 0

    state = load_state()
    previous = state.get('fingerprint')

    if force:
        print('  --force: upload required regardless of fingerprint.')
        return 10

    if not previous:
        print(f'  No recorded upload state ({count} files, {human(total)}).')
        print('  Treating the release bundle as STALE — it has never been '
              'verified from this checkout.')
        return 10

    if previous == digest:
        print(f'  Asset bundle unchanged since last upload '
              f'({count} files, {human(total)}).')
        return 0

    pf, pb = state.get('files', 0), state.get('bytes', 0)
    print(f'  Asset bundle CHANGED since last upload:')
    print(f'    files {pf} -> {count}   ({count - pf:+d})')
    print(f'    size  {human(pb)} -> {human(total)}')
    print('  CI builds from the pad-assets release, not this tree, so the')
    print('  bundle must be re-uploaded or the next build ships old assets.')
    return 10


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
