#!/usr/bin/env python3
"""promote_alpha_to_production.py — auto-promote soaked alpha releases.

Runs daily via .github/workflows/promote-alpha-to-production.yml. Walks the
v*+N git tags, picks ones older than ALPHA_SOAK_DAYS, and promotes their
corresponding alpha-track release to production with a staged rollout.

Decision flow per recent tag (v1.13.0+60 etc.):
  1. Skip if tag is younger than ALPHA_SOAK_DAYS days
  2. Skip if its version code is NOT in the alpha track (never reached CI?)
  3. Skip if its alpha release status is not 'completed'
  4. Skip if its version code is already in the production track
  5. Otherwise: promote alpha → production with userFraction (default 0.2)

Why git-tag-based rather than Play-API-track-creation-date:
  • Track release objects don't carry a reliable "uploaded at" timestamp
    via the public androidpublisher v3 API. The most trustworthy
    timestamp we have is the Git tag's creator date.
  • Using tags also means a release that was uploaded but never tagged
    (manual upload) won't get auto-promoted. That's the right safety
    default — if you didn't tag it, you didn't decide to ship it.

Environment:
  PLAY_SERVICE_ACCOUNT_JSON  full service-account JSON, scoped to the
                             androidpublisher API for com.awing.learning
  ALPHA_SOAK_DAYS            (optional, default '7') minimum age in days
                             before an alpha release is eligible
  PROMOTE_ROLLOUT            (optional, default '0.2') initial userFraction
                             for production. Values 0..1. The release ships
                             as status=inProgress at this fraction; Google's
                             "Increase rollout" controls take it to 100%.
  DRY_RUN                    (optional, default 'false') set to 'true' to
                             list candidates without touching the Play track.

Exit code 0 on success (including "nothing to promote"). Exit code 1 on
unrecoverable errors (auth failure, malformed input, API exception).
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from datetime import datetime, timedelta, timezone

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

PACKAGE_NAME = 'com.awing.learning'
SOAK_DAYS = int(os.environ.get('ALPHA_SOAK_DAYS', '7'))
DRY_RUN = os.environ.get('DRY_RUN', 'false').lower() == 'true'
USER_FRACTION = float(os.environ.get('PROMOTE_ROLLOUT', '0.2'))

# Match git tags like v1.13.0+60. Captures version_name and version_code.
TAG_VERSION_RE = re.compile(r'^v(\d+\.\d+\.\d+)\+(\d+)$')


def banner(line):
    bar = '=' * 64
    print(bar)
    print(line)
    print(bar)


def get_recent_tags(window_days=60):
    """Return list of (tag_name, version_code, created_dt) tuples for
    v*+N tags created within the last `window_days`, newest first."""
    try:
        out = subprocess.check_output(
            [
                'git',
                'for-each-ref',
                '--sort=-creatordate',
                '--format=%(refname:short)|%(creatordate:iso8601)',
                'refs/tags',
            ],
            text=True,
        )
    except subprocess.CalledProcessError as e:
        print(f'✗ git for-each-ref failed: {e}')
        return []

    cutoff = datetime.now(timezone.utc) - timedelta(days=window_days)
    tags = []
    for line in out.strip().split('\n'):
        if not line:
            continue
        try:
            name, date_str = line.split('|', 1)
        except ValueError:
            continue
        m = TAG_VERSION_RE.match(name)
        if not m:
            continue
        # Parse ISO 8601 with optional timezone like "+0000"
        # `creatordate:iso8601` emits e.g. "2026-05-26 23:54:12 -0400".
        # Normalize to ISO 8601 by replacing the first space with 'T' and
        # the second space with nothing (since the offset already has a
        # leading sign).
        try:
            parts = date_str.strip().split(' ')
            if len(parts) >= 2:
                iso = parts[0] + 'T' + parts[1]
                if len(parts) >= 3:
                    iso += parts[2]
                created = datetime.fromisoformat(iso)
            else:
                created = datetime.fromisoformat(date_str.strip())
        except ValueError as e:
            print(f'  ⚠ could not parse date {date_str!r} for tag {name}: {e}')
            continue
        if created.tzinfo is None:
            created = created.replace(tzinfo=timezone.utc)
        if created < cutoff:
            # Tags are sorted newest first, so we can stop scanning.
            break
        tags.append((name, int(m.group(2)), created))
    return tags


def load_service():
    sa_json = os.environ.get('PLAY_SERVICE_ACCOUNT_JSON', '').strip()
    if not sa_json:
        print('✗ PLAY_SERVICE_ACCOUNT_JSON env var is empty.')
        sys.exit(1)
    try:
        info = json.loads(sa_json)
    except json.JSONDecodeError as e:
        print(f'✗ PLAY_SERVICE_ACCOUNT_JSON is not valid JSON: {e}')
        sys.exit(1)
    creds = service_account.Credentials.from_service_account_info(
        info,
        scopes=['https://www.googleapis.com/auth/androidpublisher'],
    )
    return build('androidpublisher', 'v3', credentials=creds,
                 cache_discovery=False)


def main():
    banner(f'promote_alpha_to_production.py'
           f' (soak_days={SOAK_DAYS}, rollout={USER_FRACTION:.0%},'
           f' dry_run={DRY_RUN})')

    tags = get_recent_tags()
    if not tags:
        print('\nNo recent v*+N tags found in the last 60 days. Done.')
        return 0

    now = datetime.now(timezone.utc)
    threshold = now - timedelta(days=SOAK_DAYS)

    print(f'\nFound {len(tags)} candidate tag(s):')
    ready = []
    for name, vc, created in tags:
        age = (now - created).total_seconds() / 86400.0
        is_ready = created <= threshold
        marker = '✓ ready ' if is_ready else '⏳ soak  '
        print(f'  {marker} {name:18s} vc={vc:<4} age={age:6.2f}d'
              f'   created={created.isoformat()}')
        if is_ready:
            ready.append((name, vc, created))

    if not ready:
        print(f'\nNo tags are older than {SOAK_DAYS} days yet. Done.')
        return 0

    service = load_service()

    print('\nOpening Play API edit...')
    try:
        edit = service.edits().insert(
            packageName=PACKAGE_NAME, body={}
        ).execute()
    except HttpError as e:
        print(f'✗ Could not create Play API edit: {e}')
        return 1
    edit_id = edit['id']

    try:
        # Read current alpha + production track state
        alpha = service.edits().tracks().get(
            packageName=PACKAGE_NAME, editId=edit_id, track='alpha'
        ).execute()
        prod = service.edits().tracks().get(
            packageName=PACKAGE_NAME, editId=edit_id, track='production'
        ).execute()

        # Map versionCode → alpha release dict
        alpha_releases_by_vc = {}
        for r in alpha.get('releases', []):
            for vc in r.get('versionCodes', []):
                alpha_releases_by_vc[int(vc)] = r

        # Set of versionCodes already present in production (any status)
        prod_vcs = set()
        for r in prod.get('releases', []):
            for vc in r.get('versionCodes', []):
                prod_vcs.add(int(vc))

        promoted_any = False
        for tag_name, vc, created in ready:
            if vc in prod_vcs:
                print(f'  ⊘ {tag_name} (vc={vc}) — already in production')
                continue

            alpha_release = alpha_releases_by_vc.get(vc)
            if alpha_release is None:
                print(f'  ⊘ {tag_name} (vc={vc}) — not present in alpha')
                continue

            status = alpha_release.get('status')
            if status != 'completed':
                print(f"  ⊘ {tag_name} (vc={vc}) — alpha status is "
                      f"'{status}', expected 'completed'")
                continue

            print(f'  → Promoting {tag_name} (vc={vc}) → production '
                  f'@ {USER_FRACTION:.0%} staged rollout')

            new_release = {
                'versionCodes': [str(vc)],
                'status': 'inProgress',
                'userFraction': USER_FRACTION,
                'releaseNotes': alpha_release.get('releaseNotes', []),
            }

            if DRY_RUN:
                print('    (dry-run — skipping API write)')
                promoted_any = True
                continue

            # Replace production track releases with this new one.
            # Google auto-supersedes older production releases for us.
            try:
                service.edits().tracks().update(
                    packageName=PACKAGE_NAME,
                    editId=edit_id,
                    track='production',
                    body={
                        'track': 'production',
                        'releases': [new_release],
                    },
                ).execute()
                print('    ✓ added to production track in edit')
                promoted_any = True
                # Update prod_vcs so we don't try to promote the same
                # vc again in this loop if it appears in multiple tags.
                prod_vcs.add(vc)
            except HttpError as e:
                print(f'    ✗ API error promoting vc={vc}: {e}')

        if promoted_any and not DRY_RUN:
            print('\nCommitting edit...')
            try:
                service.edits().commit(
                    packageName=PACKAGE_NAME, editId=edit_id
                ).execute()
                print('✓ Edit committed. Google review queue will pick up '
                      'these promotions; auto-publish kicks in when '
                      'approved (managed publishing is off).')
            except HttpError as e:
                print(f'✗ Commit failed: {e}')
                return 1
        else:
            if DRY_RUN:
                print('\nDry run — discarding edit.')
            else:
                print('\nNothing promoted — discarding edit.')
            try:
                service.edits().delete(
                    packageName=PACKAGE_NAME, editId=edit_id
                ).execute()
            except HttpError:
                pass

    except Exception:
        # Clean up the edit on any unexpected error
        try:
            service.edits().delete(
                packageName=PACKAGE_NAME, editId=edit_id
            ).execute()
        except HttpError:
            pass
        raise

    return 0


if __name__ == '__main__':
    sys.exit(main() or 0)
