#!/usr/bin/env python3
"""check_version_codes.py -- query Play Console + ASC for the highest
existing version/bundle code, compare to pubspec.yaml, optionally
auto-bump.

WHY: pubspec.yaml is our local source of truth, but Play Console and
App Store Connect both reserve version codes server-side in ways
pubspec can't see:

  - retag-at-HEAD after a successful upload (Sessions 58, 60, 61)
  - partial uploads that fail mid-stream still burn the slot
  - manual drafts on Play Console

Result: `git push origin v1.18.1+87` then CI says "Version code 87
has already been used" or TestFlight says "bundle version already
uploaded". This script lets us pre-detect that BEFORE the push.

WHAT IT DOES:
  1. Parses pubspec.yaml's `version: X.Y.Z+N` -> current build = N
  2. Queries Play Console Developer API for the highest versionCode
     across internal/alpha/beta/production tracks (current releases).
  3. Queries App Store Connect API for the highest TestFlight bundle
     version across builds for the iOS app.
  4. Computes max_remote = max(play_max, asc_max).
  5. If max_remote >= N (local), prints a "would bump to {max_remote+1}"
     plan. With --auto, applies the bump to pubspec.yaml AND runs
     scripts/sync_version.py to propagate to the 3 Dart mirrors (the
     Session 48 4-place sync protocol).

CREDENTIALS (gracefully skipped if absent):
  Play: PLAY_SERVICE_ACCOUNT_JSON env (raw JSON content) OR
        config/play-service-account.json file (gitignored)
  ASC:  ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_BASE64 env vars
        (or all three under config/asc-credentials.json with same keys)

CLI:
  python scripts/check_version_codes.py            # report only
  python scripts/check_version_codes.py --auto     # apply bump
  python scripts/check_version_codes.py --skip-play
  python scripts/check_version_codes.py --skip-asc
  python scripts/check_version_codes.py --strict   # fail if creds missing
  python scripts/check_version_codes.py --show-all # print every code found

EXIT CODES:
  0  -- no bump needed (local +N is already higher than all remotes)
  0  -- bump applied (only with --auto)
  2  -- bump needed but --auto not set (so preflight can fail loudly)
  3  -- credentials missing and --strict set
  4  -- API error (network, auth, rate limit)
"""
from __future__ import annotations
import argparse
import base64
import json
import os
import re
import subprocess
import sys
import time
import urllib.request
import urllib.error
from pathlib import Path
from typing import Optional

REPO = Path(__file__).resolve().parent.parent
PUBSPEC = REPO / "pubspec.yaml"
CONFIG_DIR = REPO / "config"
PLAY_SA_PATH = CONFIG_DIR / "play-service-account.json"
ASC_CRED_PATH = CONFIG_DIR / "asc-credentials.json"

ANDROID_PACKAGE = "com.awing.learning"
IOS_BUNDLE = "com.awing.awingAiLearning"


# ====================================================================
# pubspec.yaml parsing + bumping
# ====================================================================

VERSION_RE = re.compile(r"^(version:\s*)(\d+\.\d+\.\d+)\+(\d+)\s*$", re.M)


def parse_pubspec() -> tuple[str, int]:
    """Return (semver, build_number) from pubspec.yaml."""
    src = PUBSPEC.read_text(encoding="utf-8")
    m = VERSION_RE.search(src)
    if not m:
        raise SystemExit("ERROR: cannot parse version: from pubspec.yaml")
    return m.group(2), int(m.group(3))


def write_pubspec_build(new_build: int) -> None:
    """Rewrite pubspec.yaml with a new build number, preserving line endings.

    The Windows-side pubspec.yaml uses CRLF; we must NOT normalize to LF or
    git will report the entire file as modified. Read + write as binary,
    operate on the decoded text only for regex substitution.
    """
    raw = PUBSPEC.read_bytes()
    text = raw.decode("utf-8")
    new_text = VERSION_RE.sub(
        lambda m: f"{m.group(1)}{m.group(2)}+{new_build}",
        text,
    )
    if new_text == text:
        raise SystemExit("ERROR: version regex matched but substitution produced no change")
    new_raw = new_text.encode("utf-8")
    PUBSPEC.write_bytes(new_raw)


# ====================================================================
# Play Console (Android Publisher API v3)
# ====================================================================

def _b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def _play_service_account() -> Optional[dict]:
    """Load Play service account JSON from env or file."""
    raw = os.environ.get("PLAY_SERVICE_ACCOUNT_JSON")
    if raw:
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            # Could be a path (some CI setups write it that way).
            p = Path(raw)
            if p.is_file():
                return json.loads(p.read_text(encoding="utf-8"))
            raise SystemExit("ERROR: PLAY_SERVICE_ACCOUNT_JSON is set but not valid JSON or a path")
    if PLAY_SA_PATH.is_file():
        return json.loads(PLAY_SA_PATH.read_text(encoding="utf-8"))
    return None


def _play_access_token(sa: dict) -> str:
    """Exchange a service-account JWT for an OAuth bearer token."""
    try:
        from cryptography.hazmat.primitives import serialization, hashes
        from cryptography.hazmat.primitives.asymmetric import padding
    except ImportError:
        raise SystemExit(
            "ERROR: 'cryptography' not installed.\n"
            "  Run: venv\\Scripts\\pip install cryptography PyJWT\n"
            "  Or:  pip install -r scripts/requirements.txt"
        )

    now = int(time.time())
    header = {"alg": "RS256", "typ": "JWT"}
    payload = {
        "iss": sa["client_email"],
        "scope": "https://www.googleapis.com/auth/androidpublisher",
        "aud": "https://oauth2.googleapis.com/token",
        "iat": now,
        "exp": now + 3600,
    }
    h_b = _b64url(json.dumps(header, separators=(",", ":")).encode())
    p_b = _b64url(json.dumps(payload, separators=(",", ":")).encode())
    msg = f"{h_b}.{p_b}".encode("ascii")

    key = serialization.load_pem_private_key(sa["private_key"].encode(), password=None)
    sig = key.sign(msg, padding.PKCS1v15(), hashes.SHA256())
    jwt = f"{h_b}.{p_b}.{_b64url(sig)}"

    body = f"grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion={jwt}".encode("ascii")
    req = urllib.request.Request(
        "https://oauth2.googleapis.com/token",
        data=body,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=20) as resp:
        tok = json.loads(resp.read())
    return tok["access_token"]


def play_max_version_code(verbose: bool = False) -> Optional[int]:
    """Highest versionCode across all Play tracks (internal/alpha/beta/production)."""
    sa = _play_service_account()
    if not sa:
        print("  [Play] no service account JSON (env PLAY_SERVICE_ACCOUNT_JSON or config/play-service-account.json) — skipped")
        return None

    print(f"  [Play] authenticating as {sa.get('client_email','?')} ...")
    token = _play_access_token(sa)
    headers = {"Authorization": f"Bearer {token}"}

    base = f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{ANDROID_PACKAGE}"
    edit_req = urllib.request.Request(f"{base}/edits", headers=headers, method="POST",
                                       data=b"")
    edit_req.add_header("Content-Length", "0")
    try:
        with urllib.request.urlopen(edit_req, timeout=20) as resp:
            edit = json.loads(resp.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", "replace")[:500]
        raise SystemExit(f"ERROR: Play edit creation failed: HTTP {e.code} {body}")
    edit_id = edit["id"]

    tracks_req = urllib.request.Request(f"{base}/edits/{edit_id}/tracks", headers=headers)
    with urllib.request.urlopen(tracks_req, timeout=20) as resp:
        tracks = json.loads(resp.read())

    # Best-effort: delete the edit so we don't leave a draft lying around.
    try:
        del_req = urllib.request.Request(f"{base}/edits/{edit_id}", headers=headers, method="DELETE")
        urllib.request.urlopen(del_req, timeout=10).read()
    except Exception:
        pass

    all_codes: list[int] = []
    for track in tracks.get("tracks", []):
        track_name = track.get("track", "?")
        for release in track.get("releases", []):
            for vc in release.get("versionCodes", []):
                try:
                    code = int(vc)
                    all_codes.append(code)
                    if verbose:
                        print(f"    {track_name} {release.get('name','?')} -> {code}")
                except (TypeError, ValueError):
                    pass

    if not all_codes:
        print("  [Play] no version codes found in any track")
        return None
    mx = max(all_codes)
    print(f"  [Play] highest versionCode across tracks = {mx}  ({len(all_codes)} codes seen)")
    return mx


# ====================================================================
# App Store Connect API (TestFlight builds)
# ====================================================================

def _asc_credentials() -> Optional[tuple[str, str, bytes]]:
    """Return (key_id, issuer_id, p8_bytes) or None if missing."""
    key_id = os.environ.get("ASC_KEY_ID")
    issuer = os.environ.get("ASC_ISSUER_ID")
    key_b64 = os.environ.get("ASC_KEY_BASE64")
    if not (key_id and issuer and key_b64) and ASC_CRED_PATH.is_file():
        cfg = json.loads(ASC_CRED_PATH.read_text(encoding="utf-8"))
        key_id = key_id or cfg.get("ASC_KEY_ID") or cfg.get("key_id")
        issuer = issuer or cfg.get("ASC_ISSUER_ID") or cfg.get("issuer_id")
        key_b64 = key_b64 or cfg.get("ASC_KEY_BASE64") or cfg.get("key_base64")
    if not (key_id and issuer and key_b64):
        return None
    try:
        p8 = base64.b64decode(key_b64)
    except Exception:
        raise SystemExit("ERROR: ASC_KEY_BASE64 is not valid base64")
    return key_id, issuer, p8


def _asc_jwt(key_id: str, issuer: str, p8: bytes) -> str:
    """Build an ES256 JWT for the App Store Connect API."""
    try:
        from cryptography.hazmat.primitives import serialization, hashes
        from cryptography.hazmat.primitives.asymmetric import ec, utils
    except ImportError:
        raise SystemExit(
            "ERROR: 'cryptography' not installed.\n"
            "  Run: venv\\Scripts\\pip install cryptography\n"
        )

    now = int(time.time())
    header = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
    payload = {
        "iss": issuer,
        "iat": now,
        "exp": now + 1100,  # < 20 min per Apple docs
        "aud": "appstoreconnect-v1",
    }
    h_b = _b64url(json.dumps(header, separators=(",", ":")).encode())
    p_b = _b64url(json.dumps(payload, separators=(",", ":")).encode())
    msg = f"{h_b}.{p_b}".encode("ascii")

    key = serialization.load_pem_private_key(p8, password=None)
    der_sig = key.sign(msg, ec.ECDSA(hashes.SHA256()))
    # Convert DER signature to raw r||s for JWT.
    r, s = utils.decode_dss_signature(der_sig)
    raw_sig = r.to_bytes(32, "big") + s.to_bytes(32, "big")
    return f"{h_b}.{p_b}.{_b64url(raw_sig)}"


def _asc_app_id(jwt_token: str) -> Optional[str]:
    """Look up our app's ASC numeric id from bundle id."""
    url = (
        f"https://api.appstoreconnect.apple.com/v1/apps"
        f"?filter[bundleId]={IOS_BUNDLE}&limit=1"
    )
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {jwt_token}"})
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = json.loads(resp.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", "replace")[:500]
        raise SystemExit(f"ERROR: ASC app lookup failed: HTTP {e.code} {body}")
    if not data.get("data"):
        print(f"  [ASC] app not found by bundle id {IOS_BUNDLE}")
        return None
    return data["data"][0]["id"]


def asc_max_bundle_version(verbose: bool = False) -> Optional[int]:
    """Highest bundle version across TestFlight builds for our iOS app."""
    creds = _asc_credentials()
    if not creds:
        print("  [ASC] no credentials (env ASC_KEY_ID/ASC_ISSUER_ID/ASC_KEY_BASE64 or config/asc-credentials.json) — skipped")
        return None
    key_id, issuer, p8 = creds

    print(f"  [ASC] authenticating with key {key_id} ...")
    jwt_token = _asc_jwt(key_id, issuer, p8)

    app_id = _asc_app_id(jwt_token)
    if not app_id:
        return None

    # List builds, paginated. We sort by -version (highest version string
    # first) but version strings are not strictly numeric so we always
    # iterate at least one page and pick the numeric max ourselves.
    url = (
        f"https://api.appstoreconnect.apple.com/v1/builds"
        f"?filter[app]={app_id}&sort=-uploadedDate&limit=200"
    )
    versions: list[int] = []
    pages = 0
    while url and pages < 5:  # cap pagination defensively
        req = urllib.request.Request(url, headers={"Authorization": f"Bearer {jwt_token}"})
        try:
            with urllib.request.urlopen(req, timeout=20) as resp:
                data = json.loads(resp.read())
        except urllib.error.HTTPError as e:
            body = e.read().decode("utf-8", "replace")[:500]
            raise SystemExit(f"ERROR: ASC builds list failed: HTTP {e.code} {body}")
        for build in data.get("data", []):
            v = build.get("attributes", {}).get("version")
            try:
                n = int(v)
                versions.append(n)
                if verbose:
                    print(f"    build version {n}")
            except (TypeError, ValueError):
                pass
        url = data.get("links", {}).get("next")
        pages += 1

    if not versions:
        print("  [ASC] no builds found")
        return None
    mx = max(versions)
    print(f"  [ASC] highest bundle version on TestFlight = {mx}  ({len(versions)} builds seen)")
    return mx


# ====================================================================
# Auto-bump
# ====================================================================

def apply_bump(new_build: int) -> None:
    """Update pubspec.yaml and propagate via sync_version.py."""
    write_pubspec_build(new_build)
    print(f"  pubspec.yaml: version bumped to +{new_build}")
    sync = REPO / "scripts" / "sync_version.py"
    if not sync.is_file():
        print("  [warn] scripts/sync_version.py not found — Dart mirrors NOT updated")
        return
    print("  running scripts/sync_version.py to propagate to Dart mirrors ...")
    r = subprocess.run([sys.executable, str(sync)], capture_output=True, text=True)
    print(r.stdout.rstrip() or "    (sync_version.py produced no output)")
    if r.returncode != 0:
        print(r.stderr.rstrip())
        raise SystemExit(f"ERROR: sync_version.py exited {r.returncode}")


# ====================================================================
# Main
# ====================================================================

def main() -> int:
    ap = argparse.ArgumentParser(description="Pre-tag version-code check against Play + ASC.")
    ap.add_argument("--auto", action="store_true",
                    help="Apply the bump to pubspec.yaml + run sync_version.py")
    ap.add_argument("--skip-play", action="store_true",
                    help="Don't query Play Console")
    ap.add_argument("--skip-asc", action="store_true",
                    help="Don't query App Store Connect")
    ap.add_argument("--strict", action="store_true",
                    help="Fail (exit 3) if credentials are missing")
    ap.add_argument("--show-all", action="store_true",
                    help="Print every version code / build version found")
    args = ap.parse_args()

    semver, local_build = parse_pubspec()
    print(f"Local pubspec.yaml = {semver}+{local_build}")
    print()

    play_max = None if args.skip_play else play_max_version_code(verbose=args.show_all)
    asc_max = None if args.skip_asc else asc_max_bundle_version(verbose=args.show_all)

    if args.strict and (play_max is None and not args.skip_play):
        return 3
    if args.strict and (asc_max is None and not args.skip_asc):
        return 3

    remotes = [v for v in (play_max, asc_max) if v is not None]
    if not remotes:
        print("\nNo remote data — nothing to check.")
        return 0

    remote_max = max(remotes)
    print(f"\nHighest remote version code = {remote_max}")
    print(f"Local build number          = {local_build}")

    if local_build > remote_max:
        print(f"\nOK: local +{local_build} is already higher than remote max {remote_max}. No bump needed.")
        return 0

    suggested = remote_max + 1
    if args.auto:
        print(f"\nAPPLYING: bump pubspec from +{local_build} -> +{suggested}")
        apply_bump(suggested)
        print(f"\nDone. New version: {semver}+{suggested}")
        print("Next: commit pubspec.yaml + the 3 Dart mirrors, then tag.")
        return 0

    print(f"\nBUMP REQUIRED: pubspec.yaml is at +{local_build} but remote already has +{remote_max}.")
    print(f"  Suggested new build = +{suggested}")
    print()
    print(f"  Re-run with --auto to apply:")
    print()
    print(f"  Re-run with --auto to apply:")
    print(f"    python scripts\\check_version_codes.py --auto")
    return 2


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\nInterrupted.")
        sys.exit(130)
    except urllib.error.URLError as e:
        print(f"\nNETWORK ERROR: {e}")
        sys.exit(4)
