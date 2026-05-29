#!/usr/bin/env python3
"""upload_to_play_alpha.py — upload a locally-built AAB to the Google Play
Console closed-testing (alpha) track via the androidpublisher v3 API.

Use this when CI's PAD asset bundle is out of date and you need to ship
audio/image assets that only exist in your LOCAL build. The web UI's
file picker takes ~10 min on a slow upload; this script does the same
job programmatically without leaving the terminal.

Auth: same pattern as promote_alpha_to_production.py — reads
PLAY_SERVICE_ACCOUNT_JSON env var (the same service account secret your
GitHub Actions workflow uses). Set it once per shell:
    $env:PLAY_SERVICE_ACCOUNT_JSON = Get-Content -Raw path\to\key.json

Usage:
    python scripts/upload_to_play_alpha.py
        # Uploads build/app/outputs/bundle/release/app-release.aab to
        # alpha track. Reads version from pubspec.yaml. Default release
        # notes ("v{X.Y.Z+N} update").

    python scripts/upload_to_play_alpha.py --aab path/to/other.aab
    python scripts/upload_to_play_alpha.py --track internal
    python scripts/upload_to_play_alpha.py --status draft
    python scripts/upload_to_play_alpha.py --notes "What's new in this build"
    python scripts/upload_to_play_alpha.py --notes-file path/to/notes.txt
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

# Force UTF-8 stdout — see same block in sync_recordings.py.
for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, 'reconfigure'):
        try:
            _stream.reconfigure(encoding='utf-8', errors='replace')
        except Exception:
            pass

try:
    from googleapiclient.discovery import build
    from googleapiclient.http import MediaFileUpload
    from google.oauth2 import service_account
except ImportError:
    print('✗ Missing google-api-python-client + google-auth packages.')
    print('  Install with:')
    print('    pip install google-api-python-client google-auth-httplib2 google-auth')
    sys.exit(1)

REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_AAB = REPO_ROOT / 'build' / 'app' / 'outputs' / 'bundle' / 'release' / 'app-release.aab'
PUBSPEC = REPO_ROOT / 'pubspec.yaml'
PACKAGE_NAME = 'com.awing.learning'

VALID_TRACKS = {'internal', 'alpha', 'beta', 'production'}
VALID_STATUSES = {'draft', 'inProgress', 'halted', 'completed'}


def banner(line):
    print()
    print('=' * 72)
    print(' ' + line)
    print('=' * 72)


def load_version_from_pubspec():
    """Returns (version_name, version_code) from pubspec.yaml.
    Format: version: 1.13.4+64"""
    if not PUBSPEC.exists():
        return ('unknown', None)
    for raw in PUBSPEC.read_text(encoding='utf-8').splitlines():
        m = re.match(r'^\s*version:\s*([\d.]+)\+(\d+)\s*$', raw)
        if m:
            return (m.group(1), int(m.group(2)))
    return ('unknown', None)


def load_service():
    """Build an androidpublisher v3 client from PLAY_SERVICE_ACCOUNT_JSON."""
    sa_json = os.environ.get('PLAY_SERVICE_ACCOUNT_JSON', '').strip()
    if not sa_json:
        print('✗ PLAY_SERVICE_ACCOUNT_JSON env var is empty.')
        print('  Set it for this shell:')
        print('    $env:PLAY_SERVICE_ACCOUNT_JSON = Get-Content -Raw '
              'C:\\path\\to\\play-service-account.json')
        print('  Or copy from GitHub repo secrets > PLAY_SERVICE_ACCOUNT_JSON.')
        sys.exit(2)
    try:
        info = json.loads(sa_json)
    except json.JSONDecodeError as e:
        print(f'✗ PLAY_SERVICE_ACCOUNT_JSON is not valid JSON: {e}')
        sys.exit(2)
    creds = service_account.Credentials.from_service_account_info(
        info,
        scopes=['https://www.googleapis.com/auth/androidpublisher'],
    )
    return build('androidpublisher', 'v3', credentials=creds,
                 cache_discovery=False)


def load_notes(args, version_name, version_code):
    """Resolve release notes from --notes, --notes-file, or default."""
    if args.notes_file:
        path = Path(args.notes_file)
        if not path.exists():
            print(f'✗ --notes-file {path} does not exist')
            sys.exit(2)
        text = path.read_text(encoding='utf-8').strip()
    elif args.notes:
        text = args.notes.strip()
    else:
        text = (f'v{version_name}+{version_code} update — per-kid voice '
                f'bucketing, Record-tab status badges, recorder name '
                f'normalization, webhook self-heal. Joel + Joyce native '
                f'recordings now bucket correctly.')
    # Play store limit is 500 chars per release-notes entry.
    if len(text) > 500:
        print(f'⚠ Release notes truncated from {len(text)} to 500 chars')
        text = text[:497] + '...'
    return text


def main():
    ap = argparse.ArgumentParser(
        description=__doc__.splitlines()[0],
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument('--aab', default=str(DEFAULT_AAB),
                    help=f'Path to AAB file (default: {DEFAULT_AAB.relative_to(REPO_ROOT)})')
    ap.add_argument('--track', default='alpha', choices=sorted(VALID_TRACKS),
                    help='Play Console track (default: alpha)')
    ap.add_argument('--status', default='completed',
                    choices=sorted(VALID_STATUSES),
                    help='Release status (default: completed — testers see it immediately)')
    ap.add_argument('--rollout-fraction', type=float, default=None,
                    help='Staged rollout fraction (0.01..1.0). Default: full (1.0). '
                         'Only valid with --status inProgress.')
    ap.add_argument('--notes', default=None,
                    help='Release notes text (max 500 chars)')
    ap.add_argument('--notes-file', default=None,
                    help='Path to a file containing release notes')
    ap.add_argument('--language', default='en-US',
                    help='Release notes language code (default: en-US)')
    args = ap.parse_args()

    aab_path = Path(args.aab)
    if not aab_path.exists():
        print(f'✗ AAB file not found: {aab_path}')
        print(f'  Build one first: flutter build appbundle --release')
        sys.exit(2)
    aab_size_mb = aab_path.stat().st_size / 1024 / 1024

    version_name, version_code = load_version_from_pubspec()
    notes_text = load_notes(args, version_name, version_code)

    banner('Awing AI Learning — Play Console AAB upload')
    print(f'  Package: {PACKAGE_NAME}')
    print(f'  AAB:     {aab_path.relative_to(REPO_ROOT)} ({aab_size_mb:.1f} MB)')
    print(f'  Version: v{version_name}+{version_code}')
    print(f'  Track:   {args.track}')
    print(f'  Status:  {args.status}')
    if args.rollout_fraction:
        print(f'  Rollout: {args.rollout_fraction * 100:.0f}%')
    print(f'  Notes ({len(notes_text)} chars): {notes_text[:80]}...')

    print('\n→ Authenticating with Play Developer API ...')
    service = load_service()
    edits = service.edits()

    print('→ Creating edit ...')
    edit = edits.insert(packageName=PACKAGE_NAME, body={}).execute()
    edit_id = edit['id']
    print(f'  ← edit_id={edit_id}')

    # Upload bundle. resumable=True so the 850 MB upload doesn't try to
    # buffer the whole thing in RAM.
    print(f'\n→ Uploading AAB ({aab_size_mb:.1f} MB) — this takes ~3-8 min '
          f'depending on upload speed ...')
    media = MediaFileUpload(
        str(aab_path),
        mimetype='application/octet-stream',
        chunksize=10 * 1024 * 1024,  # 10 MB chunks
        resumable=True,
    )
    request = edits.bundles().upload(
        packageName=PACKAGE_NAME,
        editId=edit_id,
        media_body=media,
    )

    # Progress loop
    response = None
    last_pct = -1
    while response is None:
        status, response = request.next_chunk()
        if status:
            pct = int(status.progress() * 100)
            if pct != last_pct and pct % 5 == 0:
                print(f'  ... {pct}% uploaded', flush=True)
                last_pct = pct
    bundle_version_code = response.get('versionCode')
    print(f'  ✓ Upload complete. versionCode={bundle_version_code}')

    if version_code and bundle_version_code != version_code:
        print(f'  ⚠ Mismatch: pubspec says +{version_code} but '
              f'bundle is +{bundle_version_code}.')

    # Track update
    print(f'\n→ Assigning to track={args.track} status={args.status} ...')
    release = {
        'name': f'v{version_name}+{bundle_version_code}',
        'versionCodes': [str(bundle_version_code)],
        'status': args.status,
        'releaseNotes': [{
            'language': args.language,
            'text': notes_text,
        }],
    }
    if args.rollout_fraction is not None:
        if args.status != 'inProgress':
            print('  ⚠ --rollout-fraction is only meaningful with --status inProgress; ignoring')
        else:
            release['userFraction'] = args.rollout_fraction

    edits.tracks().update(
        packageName=PACKAGE_NAME,
        editId=edit_id,
        track=args.track,
        body={'releases': [release]},
    ).execute()
    print('  ✓ Track updated')

    # Commit the edit (otherwise the upload is just a draft and won't ship)
    print(f'\n→ Committing edit (this publishes to Play Console) ...')
    result = edits.commit(packageName=PACKAGE_NAME, editId=edit_id).execute()
    print(f'  ✓ Committed. edit_id={result.get("id")}')

    banner(f'Done — v{version_name}+{bundle_version_code} is on the {args.track} track')
    print(f'  Play Console: https://play.google.com/console/u/0/developers/'
          f'6314956170777288607/app/4973990484782301500/tracks/'
          f'4700170610785668398')
    print(f'  Testers will see the update within ~30 min as the bundle '
          f'finishes processing.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
