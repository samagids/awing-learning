#!/usr/bin/env python3
"""sync_recordings.py — pull native recordings from any device into the
workflow folder.

Session 61b feature. The new Dev Mode Record tab and the family/native
speaker HTML recorders submit audio via the contributions webhook
(`action=submit` with `audioBase64`). Each submission tagged "Native
recording" in its notes is treated as a candidate for the workflow folder.

Pipeline:
  1. Calls the contributions webhook `action=fetch_all` (authenticated
     with SCRIPT_SECRET) to enumerate every pronunciationFix submission.
  2. Filters to the ones whose notes contain "Native recording" — those
     are the rows produced by the new family-recorder-style UI.
  3. Deduplicates by audio_key (same word, multiple recorders) — keeps
     the newest submission, unless --keep-all is passed.
  4. Calls `action=fetch_audio` to get the Drive URLs.
  5. Downloads each m4a, converts to WAV via ffmpeg, saves to
       training_data/recordings/<audio_key>.wav
  6. Writes/updates training_data/recordings/manifest.json as a LIST of
     entries with the same schema apply_recordings_as_audio.py expects
     (awing, english, source, wav_path).

Run order in build_and_run.bat:
  Step 1: apply_contributions.py    (approved spelling/word fixes)
  Step 2: sync_recordings.py        (THIS — native audio from webhook)
  Step 3: apply_recordings_as_audio (training_data/recordings/ → PAD)
  Step 4: generate_audio_edge.py    (Edge TTS fills the gaps)
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone

# Force UTF-8 stdout/stderr so the script doesn't crash on Windows when
# its output is piped (Tee-Object, Select-Object, redirect to a file).
# Python defaults to cp1252 on Windows for piped streams, which can't
# encode the → ✓ ✗ ⤷ characters we use in log lines. Without this, the
# script works fine interactively but explodes the moment you pipe it.
# Available on Python 3.7+; guarded for older interpreters.
for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, 'reconfigure'):
        try:
            _stream.reconfigure(encoding='utf-8', errors='replace')
        except Exception:
            pass

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
WEBHOOKS_FILE = os.path.join(PROJECT_DIR, 'config', 'webhooks.json')
RECORDINGS_DIR = os.path.join(PROJECT_DIR, 'training_data', 'recordings')
MANIFEST_PATH = os.path.join(RECORDINGS_DIR, 'manifest.json')

# Marker substring written by the Dev Mode Record tab's submit() call.
NATIVE_RECORDING_MARKER = 'Native recording'

# Map the Dev Mode "source" tag → apply_recordings_as_audio's expected
# value (which then maps to the audio/native/<category>/ subdir).
_SOURCE_MAP = {
    'word': 'vocabulary',
    'phrase': 'phrases',
    'letter': 'alphabet',
    'sentence': 'sentences',
    'story': 'stories',
}

# Known kid slugs (mirrors scripts/apply_recordings_as_audio.py::KID_SLUGS
# and lib/services/pronunciation_service.dart::kidVoicesByCharacter).
# Kid recordings get prefixed WAV filenames so Joyce's apo.wav doesn't
# overwrite Joel's apo.wav on disk — both must survive so the per-kid
# bucketing in apply_recordings_as_audio.py can copy each to
# audio/native_kids/<slug>/<category>/<key>.mp3. Dr. Sama / Berlin Sama /
# unknown contributors keep the un-prefixed canonical filename.
_KID_SLUGS = {'joel', 'janelle', 'joyce', 'jadyne'}

# Canonical-name normalization. The Dev Mode Record picker, the email
# address, and historical handwritten profile values all produce
# DIFFERENT strings for the same person — and the dedup bucket key uses
# the slug, so without normalization "sama" + "Dr. Guidion Sama" would
# count as two distinct recorders. This map collapses all known
# variations so dedup treats them as one.
_RECORDER_ALIASES = {
    # Kids — must match _KID_SLUGS exactly for routing to audio/native_kids/
    'joel': 'joel',
    'janelle': 'janelle',
    'joyce': 'joyce',
    'jadyne': 'jadyne',
    # Dr. Guidion Sama (the developer) — every variation we've seen in
    # the Submissions sheet to date. Canonical slug 'samagids' (the dev's
    # email prefix). Sammy/sam aliases NOT added on purpose — those
    # could be real names of other contributors.
    'sama': 'samagids',
    'samagids': 'samagids',
    'samagids@gmail.com': 'samagids',
    'samagidshop@gmail.com': 'samagids',
    'guidion': 'samagids',
    'guidion sama': 'samagids',
    'dr guidion sama': 'samagids',
    'dr. guidion sama': 'samagids',
    'dr. sama': 'samagids',
    'dr sama': 'samagids',
    # Berlin Sama (adult woman). No per-kid bucket today, but
    # normalizing the name now means dedup is correct when we add a
    # Berlin override later.
    'berlin': 'berlin',
    'berlin sama': 'berlin',
}

# Reverse map for display. Use the most natural full name per slug.
_RECORDER_DISPLAY = {
    'joel': 'Joel',
    'janelle': 'Janelle',
    'joyce': 'Joyce',
    'jadyne': 'Jadyne',
    'samagids': 'Dr. Guidion Sama',
    'berlin': 'Berlin Sama',
}


def _normalize_recorder(name):
    """Map any known profileName variation to a single canonical slug.
    Returns the slug ('joel', 'samagids', 'berlin', etc.) or None when
    the recorder is unknown — None routes to the '_default' dedup
    bucket so unknown contributors share one canonical entry per word."""
    if not name:
        return None
    norm = name.strip().lower()
    if not norm:
        return None
    if norm in _RECORDER_ALIASES:
        return _RECORDER_ALIASES[norm]
    # Try first token (handles "Joel Sama", "Dr. Guidion Sama extra...")
    first = norm.split()[0]
    if first in _RECORDER_ALIASES:
        return _RECORDER_ALIASES[first]
    return None


def _display_name(name):
    """Pretty name for log lines. Falls back to the raw input when the
    recorder isn't a known family member."""
    slug = _normalize_recorder(name)
    if slug and slug in _RECORDER_DISPLAY:
        return _RECORDER_DISPLAY[slug]
    return name or 'Unknown'



def _is_community_contributor(name):
    """Returns True when the profileName signals 'this submission came
    via the Contribute screen and should land in audio/community/, not
    audio/native/'. The Contribute screen sends 'default <FirstName>'
    (or just 'default' when no name) so a single prefix check identifies
    all such submissions, regardless of the contributor's actual name —
    even if it accidentally matches a registered kid slug."""
    if not name:
        return False
    return name.strip().lower().startswith('default')


def _recorder_to_kid_slug(name):
    """Returns the KID slug only (joel/janelle/joyce/jadyne) for routing
    recordings to audio/native_kids/<slug>/. Adults (Dr. Sama, Berlin)
    and unknowns return None so they route to canonical audio/native/."""
    slug = _normalize_recorder(name)
    return slug if slug in _KID_SLUGS else None


# ---------------------------------------------------------------------------
# audio_key() — MUST match the Dart side. apply_recordings_as_audio.py uses
# a slightly different convention (keeps non-alphanum as `_`), so we use
# ITS convention here so the downstream pipeline finds the WAV by filename.
# Keep in lockstep with apply_recordings_as_audio.py::audio_key().
# ---------------------------------------------------------------------------

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
    """ASCII-safe filename derived from Awing text. Mirrors the
    convention used by apply_recordings_as_audio.py::audio_key."""
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


# ---------------------------------------------------------------------------
# Auth + HTTP helpers (mirror apply_contributions.py)
# ---------------------------------------------------------------------------

def _load_webhook_url():
    if not os.path.exists(WEBHOOKS_FILE):
        return None
    try:
        with open(WEBHOOKS_FILE, 'r', encoding='utf-8') as f:
            config = json.load(f)
        return (config.get('contributions_url') or '').strip() or None
    except Exception as e:
        print(f'  ⚠ Could not read {WEBHOOKS_FILE}: {e}')
        return None


def _get_script_secret():
    secret = os.environ.get('AWING_SCRIPT_SECRET', '').strip()
    if secret:
        return secret
    if os.path.exists(WEBHOOKS_FILE):
        try:
            with open(WEBHOOKS_FILE, 'r', encoding='utf-8') as f:
                config = json.load(f)
            secret = (config.get('script_secret') or '').strip()
            if secret:
                return secret
        except Exception:
            pass
    home_secret = os.path.expanduser('~/.awing_script_secret')
    if os.path.exists(home_secret):
        try:
            with open(home_secret, 'r', encoding='utf-8') as f:
                secret = f.read().strip()
            if secret:
                return secret
        except Exception:
            pass
    return None


def _post_json(url, payload, timeout=45):
    """POST JSON, follow Apps Script's 302→GET pattern, return parsed."""
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
            if loc:
                next_url = loc
                for _ in range(5):
                    get_req = urllib.request.Request(next_url, method='GET')
                    try:
                        with opener.open(get_req, timeout=timeout) as r2:
                            return json.loads(r2.read().decode('utf-8'))
                    except urllib.error.HTTPError as e2:
                        if e2.code in (301, 302):
                            next_url = e2.headers.get('Location')
                            if not next_url:
                                raise
                            continue
                        raise
                raise RuntimeError('Too many redirects')
        raise


_DRIVE_VIEW_URL_RE = re.compile(
    r'https://drive\.google\.com/file/d/([a-zA-Z0-9_-]+)/(?:view|edit|preview)',
    re.IGNORECASE,
)


def _normalize_drive_url(url):
    """Convert a Drive view URL (HTML preview) into a direct-download URL.

    v1.13.3 fix: webhook v<1.13.3 stored `file.getUrl()` which returns
        https://drive.google.com/file/d/{ID}/view?usp=drivesdk
    That URL serves an HTML preview page when fetched programmatically.
    The 22 already-stored Native recording rows still point at the old
    format, so we rewrite them client-side:
        https://drive.google.com/uc?export=download&id={ID}
    which serves the raw blob for files <100 MB. Our m4a clips are
    < 500 KB so we never hit the virus-scan interstitial. Server now
    stores getDownloadUrl() directly so future submissions skip this.
    """
    if not url:
        return url
    m = _DRIVE_VIEW_URL_RE.match(url)
    if m:
        file_id = m.group(1)
        return 'https://drive.google.com/uc?export=download&id=' + file_id
    return url


def _download_to(url, dest_path, timeout=60):
    """Download `url` to `dest_path`. Follows redirects (urllib default).
    Detects HTML payloads so we don't hand them to ffmpeg. Returns
    (ok, size_bytes).
    """
    url = _normalize_drive_url(url)
    try:
        req = urllib.request.Request(
            url,
            method='GET',
            # Drive's anon endpoints are friendlier to UA-bearing clients.
            headers={'User-Agent': 'awing-sync/1.13.3'},
        )
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            data = resp.read()
            content_type = (resp.headers.get('Content-Type') or '').lower()
    except Exception as e:
        print(f'    ✗ download failed: {e}')
        return False, 0

    # Detect HTML interstitial (Drive virus-scan warning, login redirect,
    # view-preview page). The magic-bytes test is more reliable than
    # Content-Type alone since Drive sometimes mislabels the content.
    head = data[:512].lstrip()
    is_html = (
        head[:9].lower() == b'<!doctype'
        or head[:5].lower() == b'<html'
        or b'<head' in head[:200].lower()
        or 'text/html' in content_type
    )
    if is_html:
        # Save the HTML for forensic inspection.
        debug_path = dest_path + '.html'
        try:
            with open(debug_path, 'wb') as f:
                f.write(data)
        except Exception:
            pass
        snippet = head[:120].decode('utf-8', errors='replace')
        print(f'    ✗ Drive returned HTML, not audio '
              f'(len={len(data)}, ct={content_type!r}). '
              f'Saved to {os.path.basename(debug_path)}. '
              f'First bytes: {snippet!r}')
        return False, len(data)

    try:
        with open(dest_path, 'wb') as f:
            f.write(data)
    except Exception as e:
        print(f'    ✗ write failed: {e}')
        return False, 0
    return True, len(data)


def _have_ffmpeg():
    return shutil.which('ffmpeg') is not None


def _convert_m4a_to_wav(m4a_path, wav_path):
    """ffmpeg → 22050 Hz mono PCM WAV. Auto-detects input format (m4a,
    webm, ogg, wav, mp3) — we let ffmpeg sniff content rather than
    trusting the extension. Returns True on success.
    """
    # Defensive size check — if download_to produced a 0-byte file
    # somehow, ffmpeg's error is opaque. Surface it cleanly here.
    try:
        in_size = os.path.getsize(m4a_path)
    except OSError as e:
        print(f'    ✗ cannot stat input: {e}')
        return False
    if in_size < 256:
        print(f'    ✗ input too small ({in_size} bytes) — likely corrupt')
        return False

    try:
        result = subprocess.run(
            ['ffmpeg', '-y', '-loglevel', 'error',
             '-i', m4a_path,
             '-acodec', 'pcm_s16le',
             '-ar', '22050',
             '-ac', '1',
             wav_path],
            capture_output=True,
            check=False,
        )
        if result.returncode != 0:
            # v1.13.3: print full stderr (was 200-char-truncated, which
            # hid both the file path and the real diagnostic).
            err = result.stderr.decode('utf-8', errors='replace').strip()
            print(f'    ✗ ffmpeg (input {in_size} bytes):')
            for line in err.splitlines()[:6]:
                print(f'      {line}')
            return False
        return os.path.exists(wav_path) and os.path.getsize(wav_path) > 1024
    except FileNotFoundError:
        print('    ✗ ffmpeg not on PATH')
        return False


# ---------------------------------------------------------------------------
# Manifest read/write — list-of-entries format matching the existing
# apply_recordings_as_audio.py expectations.
# ---------------------------------------------------------------------------

def _load_manifest():
    if not os.path.exists(MANIFEST_PATH):
        return []
    try:
        with open(MANIFEST_PATH, 'r', encoding='utf-8') as f:
            data = json.load(f)
        if isinstance(data, list):
            return data
        # Tolerate the old dict-keyed-by-key format from earlier drafts.
        if isinstance(data, dict):
            return [
                dict(entry, audio_key=k) for k, entry in data.items()
            ]
        return []
    except Exception as e:
        print(f'  ⚠ manifest read error: {e} — starting from empty')
        return []


def _save_manifest(entries):
    os.makedirs(os.path.dirname(MANIFEST_PATH), exist_ok=True)
    with open(MANIFEST_PATH, 'w', encoding='utf-8') as f:
        json.dump(entries, f, indent=2, ensure_ascii=False)


def _merge_manifest_entry(entries, new_entry):
    """Replace any existing entry with the same audio_key/wav_path; else
    append. Keeps the manifest tidy under repeat sync runs."""
    new_path = new_entry.get('wav_path')
    out = [e for e in entries if e.get('wav_path') != new_path]
    out.append(new_entry)
    return out


# ---------------------------------------------------------------------------
# Main flow
# ---------------------------------------------------------------------------

def sync_recordings(keep_all=False, dry_run=False, verbose=False, force: bool = False):
    print('=' * 64)
    print('sync_recordings.py — pull native audio into workflow folder')
    print('=' * 64)

    webhook = _load_webhook_url()
    if not webhook:
        print('✗ No contributions webhook URL in config/webhooks.json')
        return 1

    secret = _get_script_secret()
    if not secret:
        print('✗ SCRIPT_SECRET not configured')
        print('   Set one of:')
        print('     • AWING_SCRIPT_SECRET env var')
        print('     • config/webhooks.json `script_secret` key')
        print('     • ~/.awing_script_secret file')
        return 1

    if not _have_ffmpeg() and not dry_run:
        print('✗ ffmpeg not found on PATH — required to convert m4a → wav')
        print('   Install with `winget install Gyan.FFmpeg` on Windows.')
        return 1

    os.makedirs(RECORDINGS_DIR, exist_ok=True)

    # 1. fetch_all
    print('\n→ Listing all contributions from webhook ...')
    try:
        result = _post_json(webhook, {
            'action': 'fetch_all',
            'scriptSecret': secret,
        })
    except Exception as e:
        print(f'✗ fetch_all failed: {e}')
        return 1
    if result.get('status') != 'ok':
        print(f"✗ Webhook said: {result.get('message', 'unknown error')}")
        return 1

    all_contribs = result.get('contributions', []) or []
    print(f'  ← {len(all_contribs)} contribution(s) total on server')

    # 2. Filter to native recordings
    native = []
    for c in all_contribs:
        notes = c.get('notes') or ''
        ctype = c.get('type') or ''
        if ctype != 'pronunciationFix':
            continue
        if NATIVE_RECORDING_MARKER not in notes:
            continue
        native.append(c)
    print(f'  ← {len(native)} tagged "{NATIVE_RECORDING_MARKER}"')

    if not native:
        print('\nNothing to sync. Done.')
        return 0

    # 3. Dedup by (audio_key, recorder_slug) — latest per pair wins.
    # CRITICAL: Joel + Joyce both record the same word? Both must survive
    # so the per-kid bucketing downstream can copy each to its own
    # audio/native_kids/<slug>/ directory. Old per-key dedup collapsed
    # them into one (whoever recorded last), losing the other entirely.
    # Recorders that aren't a known kid slug (Dr. Sama / Berlin Sama /
    # blank / unknown) all dedup together under the same "_default"
    # bucket — only one canonical recording per word from the
    # non-kid pool, latest-wins.
    if keep_all:
        kept = native
    else:
        by_key_recorder = {}
        for c in native:
            key = audio_key(c.get('targetWord', ''))
            if not key:
                continue
            # Normalize recorder so "sama" + "Dr. Guidion Sama" +
            # "samagids@gmail.com" all collapse into one bucket
            # ('samagids'). Unknown recorders share '_default' for
            # the canonical-tier dedup.
            slug = _normalize_recorder(c.get('profileName'))
            bucket = slug or '_default'
            compound_key = (key, bucket)
            ts = c.get('submittedAt') or c.get('reviewedAt') or ''
            existing = by_key_recorder.get(compound_key)
            if existing is None or ts > existing.get('_ts', ''):
                c['_ts'] = ts
                by_key_recorder[compound_key] = c
        kept = list(by_key_recorder.values())
    # Count distinct words AND total entries (latter > former when same
    # word was recorded by multiple kids — that's the new correct behavior).
    distinct_keys = {audio_key(c.get('targetWord', '')) for c in kept}
    print(f'  ← {len(kept)} entries after dedup '
          f'({len(distinct_keys)} distinct words across '
          f'{len(kept) - len(distinct_keys)} extra per-kid copies)')

    if dry_run:
        print('\nDry-run mode — would sync:')
        for c in kept:
            key = audio_key(c.get('targetWord', ''))
            print(f'    • {key}.wav  ←  {c.get("targetWord")}  '
                  f'(from {c.get("profileName", "Unknown")})')
        return 0

    # 3.5. Skip entries whose destination WAV already exists on disk.
    # This is the BIG speedup for re-syncs — without it, every sync
    # re-fetches and re-downloads the same 188 URLs. We compute the
    # same wav_filename used below at write time (kid prefix when
    # appropriate) and check existence + non-zero size.
    if not force:
        before = len(kept)
        filtered = []
        for c in kept:
            target = c.get('targetWord', '')
            recorder = c.get('profileName', 'Unknown')
            key = audio_key(target)
            kid_slug = _recorder_to_kid_slug(recorder)
            is_community = _is_community_contributor(recorder)
            if kid_slug:
                wav_filename = f'{kid_slug}__{key}.wav'
            elif is_community:
                wav_filename = f'community__{key}.wav'
            else:
                wav_filename = f'{key}.wav'
            wav_path = os.path.join(RECORDINGS_DIR, wav_filename)
            if os.path.exists(wav_path) and os.path.getsize(wav_path) > 0:
                continue
            filtered.append(c)
        skipped_existing = before - len(filtered)
        if skipped_existing:
            print(f'  ⤷ {skipped_existing} already on disk — skipping fetch+download')
        kept = filtered
        if not kept:
            print('Nothing new to sync. Done.')
            return 0

    # 4. fetch_audio
    ids = [c.get('id') for c in kept if c.get('id')]
    print(f'\n→ Fetching {len(ids)} audio URL(s) ...')
    try:
        audio_result = _post_json(webhook, {
            'action': 'fetch_audio',
            'ids': ids,
            'scriptSecret': secret,
        })
    except Exception as e:
        print(f'✗ fetch_audio failed: {e}')
        return 1
    if audio_result.get('status') != 'ok':
        print(f"✗ Webhook error: {audio_result.get('message', 'unknown')}")
        return 1
    audio_by_id = audio_result.get('audio') or {}
    print(f'  ← got {len(audio_by_id)} audio URL(s)')

    # 5. Download + convert + manifest
    manifest = _load_manifest()
    downloaded = 0
    skipped = 0

    with tempfile.TemporaryDirectory(prefix='awing_sync_') as tmpdir:
        for c in kept:
            cid = c.get('id')
            target = c.get('targetWord', '')
            english = c.get('englishMeaning', '') or ''
            category = c.get('category', '') or ''
            recorder = c.get('profileName', 'Unknown')
            url = audio_by_id.get(cid)
            key = audio_key(target)

            # Map dev mode source → apply_recordings_as_audio source
            source = _SOURCE_MAP.get(category, 'vocabulary')

            if not key:
                if verbose:
                    print(f'  ⚠ Empty key for "{target}" — skipping')
                skipped += 1
                continue
            if not url:
                if verbose:
                    print(f'  ⚠ No audio URL for "{target}" — skipping')
                skipped += 1
                continue

            # When recorder is a known kid, prefix the WAV filename so
            # joel__apo.wav doesn't overwrite joyce__apo.wav on disk —
            # both must survive so apply_recordings_as_audio.py can copy
            # each into its own audio/native_kids/<slug>/ tree. Dr. Sama /
            # Berlin Sama / unknown contributors keep the canonical
            # un-prefixed name (backwards compatible with existing
            # manifest entries from previous runs).
            kid_slug = _recorder_to_kid_slug(recorder)
            wav_filename = (f'{kid_slug}__{key}.wav'
                            if kid_slug else f'{key}.wav')

            # Tempdir m4a uses the same prefixing so multiple kids in the
            # same batch don't overwrite each other's downloads in tmp.
            if kid_slug:
                m4a_filename = f'{kid_slug}__{key}.m4a'
            elif is_community:
                m4a_filename = f'community__{key}.m4a'
            else:
                m4a_filename = f'{key}.m4a'
            m4a_path = os.path.join(tmpdir, m4a_filename)
            ok, size = _download_to(url, m4a_path)
            if not ok:
                # Forensic dump so the dev can identify the broken row
                # in the Submissions sheet and delete it manually.
                # Otherwise every sync re-fails on the same row.
                print(f'    ⤷ contribution_id={cid}')
                print(f'    ⤷ submittedAt={c.get("submittedAt", "?")}')
                print(f'    ⤷ profileName={c.get("profileName", "?")}')
                print(f'    ⤷ audioUrl={url[:80]}...')
                skipped += 1
                continue

            wav_path = os.path.join(RECORDINGS_DIR, wav_filename)
            if not _convert_m4a_to_wav(m4a_path, wav_path):
                # Same forensic dump for conversion failures (the file
                # downloaded but isn't valid audio — typically a
                # truncated upload that ffmpeg can't decode).
                print(f'    ⤷ contribution_id={cid}')
                print(f'    ⤷ submittedAt={c.get("submittedAt", "?")}')
                print(f'    ⤷ profileName={c.get("profileName", "?")}')
                print(f'    ⤷ audioUrl={url[:80]}...')
                print(f'    ⤷ ACTION: delete this row from the Submissions '
                      f'sheet so future syncs skip it.')
                skipped += 1
                continue

            downloaded += 1
            wav_size = os.path.getsize(wav_path)
            wav_rel = os.path.relpath(wav_path, PROJECT_DIR).replace('\\', '/')
            # Display the canonical form ("Dr. Guidion Sama") rather
            # than the raw profile string ("sama", "samagids@gmail.com",
            # etc) so the log reads consistently across submissions.
            display_recorder = _display_name(recorder)
            print(f'  ✓ {os.path.basename(wav_path)}  ({wav_size:,} bytes)  '
                  f'←  "{target}" by {display_recorder}')

            # Also normalize the manifest's `recorder` field. Downstream
            # (apply_recordings_as_audio.py) does its own _recorder_to_kid_slug
            # mapping, which already accepts any variation — but keeping
            # a single canonical form in the manifest makes it readable
            # and prevents the (key, recorder) dedup from drifting when
            # we re-sync after a profileName cleanup in the sheet.
            manifest = _merge_manifest_entry(manifest, {
                'awing': target,
                'english': english,
                'source': source,
                'wav_path': wav_rel,
                'recorder': display_recorder,
                'contribution_id': cid,
                'downloaded_at': datetime.now(timezone.utc).isoformat(),
            })

    if downloaded > 0:
        _save_manifest(manifest)

    print(f'\n=== Summary ===')
    print(f'  Downloaded: {downloaded}')
    print(f'  Skipped:    {skipped}')
    print(f'  Folder:     {RECORDINGS_DIR}')
    print(f'  Manifest:   {MANIFEST_PATH}')
    return 0


def main():
    parser = argparse.ArgumentParser(
        description='Pull native recordings from the contributions '
                    'webhook into training_data/recordings/.')
    parser.add_argument('--dry-run', action='store_true',
        help='List what would be downloaded without writing any files.')
    parser.add_argument('--keep-all', action='store_true',
        help='Keep every submission even if multiple recorders covered '
             'the same audio_key. By default only newest-per-key is kept.')
    parser.add_argument('--verbose', action='store_true',
        help='Print per-item skip reasons.')
    parser.add_argument('--force', action='store_true',
        help='Re-fetch + re-download every entry, even WAVs already on disk. '
             'Default: skip entries whose target WAV already exists locally '
             '(big speedup for re-syncs).')
    args = parser.parse_a