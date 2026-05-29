#!/usr/bin/env python3
"""find_orphan_recordings.py — locate words that ONE recorder has but a
SIBLING recorder is missing, surfacing candidate rows with non-matching
profileName so the dev can re-tag them in the Submissions sheet.

Primary use case: Joel and Joyce both recorded the same word list (e.g.
the alphabet + first 41 vocabulary). Joyce's profileName came through
correctly as "Joyce" so all 45 of her recordings bucketed into
audio/native_kids/joyce/. Joel only got 29 of 41 — the other 12 have
profileName set to something else (Developer, samagids@gmail.com, etc.)
from before the Dev Mode recorder picker shipped in v1.13.3+63.

This script:
  1. Pulls every Native Recording submission via the contributions
     webhook (with SCRIPT_SECRET auth).
  2. Buckets entries by (audio_key, recorder_slug).
  3. For each (kidA, kidB) pair in {joel/janelle vs joyce/jadyne and
     vice versa}, lists words that kidA has but kidB doesn't, AND
     suggests candidate rows (same audio_key, profileName isn't
     kidB's, but timestamp is close to kidA's recording).
  4. Prints contribution IDs so the dev can update profileName in the
     Sheet directly, or delete them.

Usage:
    python scripts/find_orphan_recordings.py
        # Default: compare Joyce -> Joel (Joyce's wordlist, missing
        # from Joel)

    python scripts/find_orphan_recordings.py --have joyce --missing joel
        # Same as default — explicit form

    python scripts/find_orphan_recordings.py --have jadyne --missing janelle
        # Different sibling pair
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import unicodedata
import urllib.request

# Force UTF-8 stdout so Awing characters render in piped output.
for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, 'reconfigure'):
        try:
            _stream.reconfigure(encoding='utf-8', errors='replace')
        except Exception:
            pass

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
WEBHOOKS_FILE = os.path.join(PROJECT_DIR, 'config', 'webhooks.json')

# Recorder normalization — mirrors sync_recordings.py exactly so the
# "missing" comparison uses the same bucket identity as the actual
# audio pipeline.
_KID_SLUGS = {'joel', 'janelle', 'joyce', 'jadyne'}
_ALIASES = {
    'joel': 'joel', 'janelle': 'janelle',
    'joyce': 'joyce', 'jadyne': 'jadyne',
    'sama': 'samagids', 'samagids': 'samagids',
    'samagids@gmail.com': 'samagids',
    'samagidshop@gmail.com': 'samagids',
    'guidion': 'samagids', 'guidion sama': 'samagids',
    'dr guidion sama': 'samagids', 'dr. guidion sama': 'samagids',
    'dr. sama': 'samagids', 'dr sama': 'samagids',
    'berlin': 'berlin', 'berlin sama': 'berlin',
}

_TONE_DIACRITICS = {"́", "̀", "̂", "̌", "̃", "̄"}
_REPLACEMENTS = {
    "ɛ": "e", "Ɛ": "E",
    "ɔ": "o", "Ɔ": "O",
    "ə": "e", "Ə": "E",
    "ɨ": "i", "Ɨ": "I",
    "ŋ": "ng", "Ŋ": "Ng",
    "ɣ": "g", "Ɣ": "G",
    "ʼ": "", "’": "", "‘": "", "'": "",
}


def audio_key(awing):
    if not awing:
        return ''
    decomp = unicodedata.normalize("NFD", awing)
    decomp = "".join(c for c in decomp if c not in _TONE_DIACRITICS)
    s = unicodedata.normalize("NFC", decomp)
    for src, dst in _REPLACEMENTS.items():
        s = s.replace(src, dst)
    s = re.sub(r"[^a-zA-Z0-9_-]+", "_", s)
    s = re.sub(r"_+", "_", s).strip("_")
    return s.lower() or "_"


def normalize_recorder(name):
    if not name:
        return None
    norm = name.strip().lower()
    if not norm:
        return None
    if norm in _ALIASES:
        return _ALIASES[norm]
    first = norm.split()[0]
    return _ALIASES.get(first)


# ---------------------------------------------------------------------------
# Webhook fetch (mirrors sync_recordings.py)
# ---------------------------------------------------------------------------

def _load_webhook_url():
    with open(WEBHOOKS_FILE, 'r', encoding='utf-8') as f:
        config = json.load(f)
    return (config.get('contributions_url') or '').strip()


def _get_script_secret():
    secret = os.environ.get('AWING_SCRIPT_SECRET', '').strip()
    if secret:
        return secret
    if os.path.exists(WEBHOOKS_FILE):
        with open(WEBHOOKS_FILE, 'r', encoding='utf-8') as f:
            config = json.load(f)
        secret = (config.get('script_secret') or '').strip()
        if secret:
            return secret
    home_secret = os.path.expanduser('~/.awing_script_secret')
    if os.path.exists(home_secret):
        with open(home_secret, 'r', encoding='utf-8') as f:
            return f.read().strip()
    return None


def _post_json(url, payload, timeout=45):
    body = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(
        url,
        data=body,
        headers={'Content-Type': 'application/json; charset=utf-8'},
        method='POST',
    )

    class NoRedirect(urllib.request.HTTPRedirectHandler):
        def redirect_request(self, req_, fp, code, msg, headers, newurl):
            return None

    opener = urllib.request.build_opener(NoRedirect)
    try:
        with opener.open(req, timeout=timeout) as resp:
            return json.loads(resp.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        if e.code in (301, 302):
            loc = e.headers.get('Location')
            for _ in range(5):
                get_req = urllib.request.Request(loc, method='GET')
                try:
                    with opener.open(get_req, timeout=timeout) as r2:
                        return json.loads(r2.read().decode('utf-8'))
                except urllib.error.HTTPError as e2:
                    if e2.code in (301, 302):
                        loc = e2.headers.get('Location')
                        continue
                    raise
        raise


def fetch_native_recordings():
    webhook = _load_webhook_url()
    secret = _get_script_secret()
    if not webhook or not secret:
        print('Missing webhook URL or SCRIPT_SECRET — check config/webhooks.json')
        sys.exit(1)
    result = _post_json(webhook, {'action': 'fetch_all', 'scriptSecret': secret})
    if result.get('status') != 'ok':
        print(f"Webhook error: {result.get('message', 'unknown')}")
        sys.exit(1)
    return [c for c in (result.get('contributions') or [])
            if c.get('type') == 'pronunciationFix'
            and 'Native recording' in (c.get('notes') or '')]


# ---------------------------------------------------------------------------
# Analysis
# ---------------------------------------------------------------------------

def analyze(natives, have_slug, missing_slug):
    """For each audio_key the `have_slug` recorder covered, list:
    - whether `missing_slug` has it too (covered)
    - if not, find CANDIDATE rows for the same key with a non-matching
      profileName (these are the rows the dev should re-tag or delete).
    """
    # Group by (audio_key, recorder_slug)
    by_key = {}  # audio_key -> list[(recorder_slug, contribution_dict)]
    for c in natives:
        key = audio_key(c.get('targetWord', ''))
        if not key:
            continue
        slug = normalize_recorder(c.get('profileName'))
        by_key.setdefault(key, []).append((slug, c))

    have_words = []
    missing_words = []
    for key, entries in sorted(by_key.items()):
        slugs = {s for s, _ in entries}
        if have_slug not in slugs:
            continue
        have_words.append(key)
        if missing_slug not in slugs:
            missing_words.append((key, entries))

    return have_words, missing_words


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('--have', default='joyce',
                    help='Recorder slug who recorded the wordlist '
                         '(default: joyce)')
    ap.add_argument('--missing', default='joel',
                    help='Recorder slug who SHOULD have but is missing '
                         '(default: joel)')
    args = ap.parse_args()

    have = args.have.lower()
    missing = args.missing.lower()
    if have not in _KID_SLUGS or missing not in _KID_SLUGS:
        print(f'Both --have and --missing must be one of {sorted(_KID_SLUGS)}')
        sys.exit(2)

    print('=' * 64)
    print(f'Orphan finder: words {have.title()} recorded that '
          f'{missing.title()} is missing')
    print('=' * 64)

    print('\n→ Fetching all native recordings from webhook ...')
    natives = fetch_native_recordings()
    print(f'  ← {len(natives)} native recording entries on server')

    have_words, missing_words = analyze(natives, have, missing)
    print(f'  ← {have.title()} recorded {len(have_words)} unique words')
    print(f'  ← {missing.title()} is missing {len(missing_words)} of them')

    if not missing_words:
        print(f'\n✓ {missing.title()} has covered every word {have.title()} '
              f'recorded. Nothing to do.')
        return 0

    print(f'\n{"=" * 64}')
    print(f'Candidate rows to re-tag as "{missing.title()}" in Submissions sheet:')
    print(f'(These are submissions for {have.title()}\'s words where the '
          f'profileName is something other than "{missing.title()}".)')
    print('=' * 64)

    for i, (key, entries) in enumerate(missing_words, 1):
        # Find the targetWord display (any entry's targetWord — they
        # should all match by definition of "same audio_key").
        target = entries[0][1].get('targetWord', '?')
        # All entries for this key, sorted by timestamp
        sorted_entries = sorted(
            entries,
            key=lambda e: e[1].get('submittedAt') or '',
            reverse=True,
        )
        print(f'\n  {i:2d}. {target!r}  (audio_key={key})')
        for slug, c in sorted_entries:
            slug_str = slug or '_default'
            marker = '  ← CANDIDATE' if slug != missing and slug != have else ''
            print(f'      profileName={c.get("profileName", "?")!r:40s}'
                  f'  slug={slug_str:12s}'
                  f'  submittedAt={c.get("submittedAt", "?")}'
                  f'  id={c.get("id", "?")}{marker}')

    print(f'\n{"=" * 64}')
    print(f'How to fix:')
    print(f'  Open the Awing Contributions Submissions sheet.')
    print(f'  For each CANDIDATE row above (those marked ← CANDIDATE):')
    print(f'    1. Edit the Profile Name column from current value '
          f'(e.g. "samagids", "Developer") to "{missing.title()}"')
    print(f'    2. Save — the sheet auto-saves')
    print(f'  Then re-run:')
    print(f'    python scripts/sync_recordings.py')
    print(f'    python scripts/apply_recordings_as_audio.py')
    print(f'  Verify with this script — should report 0 missing.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
