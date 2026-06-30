#!/usr/bin/env python3
"""release_gate.py — 72-hour public release gate for App Store + Play.

Designed to be called from .github/workflows/release-gate.yml on a 6h
cron schedule. On every run it:

1. Reads the latest tag (by creator date) from git history and parses
   the version+build pair from its name (vX.Y.Z+N).
2. Computes the tag's age in hours from its tagger timestamp.
3. If age < 72h, exits 0 with a notice. Tester channels (TestFlight,
   Play alpha) already have the build; public release waits.
4. If age >= 72h:
   - iOS: queries App Store Connect for any version in
     PENDING_DEVELOPER_RELEASE state. If one of them has a build whose
     `version` attribute equals N, calls the release endpoint. Older
     pending releases for stale tags are ignored (superseded).
   - Android: queries Play Console for the current alpha track. If the
     active alpha release has versionCode N AND production track is
     NOT already on N, promotes alpha -> production using the same
     release notes already attached to alpha.
5. Idempotent — re-running after a successful release is a no-op
   (Apple won't double-release, Play sees prod already on N).
6. Skips rejected builds: if Apple has REJECTED state for that build,
   we never auto-release it. Next eligible tag wins (option a).

Designed to fail loudly: any unexpected API error returns non-zero so
the CI run goes red and the developer notices.

CLI:
  python scripts/release_gate.py            # run the gate
  python scripts/release_gate.py --dry-run  # report only, no API writes
  python scripts/release_gate.py --skip-ios # only run Play gate
  python scripts/release_gate.py --skip-android

CREDENTIALS (required in CI env, no local-file fallback for this
script — it only runs in CI):
  PLAY_SERVICE_ACCOUNT_JSON  (JSON content)
  ASC_KEY_ID
  ASC_ISSUER_ID
  ASC_KEY_BASE64

EXIT CODES:
  0  — no action taken (age <72h, or nothing to release, or all done)
  0  — successful release
  4  — API error (network, auth, unexpected state)
  5  — git history doesn't have any tags yet
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
from typing import Optional

ANDROID_PACKAGE = "com.awing.learning"
IOS_BUNDLE = "com.awing.awingAiLearning"
GATE_HOURS = 72


# ====================================================================
# Utilities shared with check_version_codes.py
# ====================================================================

def _b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def _http_request(method: str, url: str, headers: dict,
                  data: Optional[bytes] = None,
                  timeout: int = 20) -> dict:
    """JSON GET/POST/PATCH/DELETE. Raises on HTTP error with body."""
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read()
            if not raw:
                return {}
            try:
                return json.loads(raw)
            except json.JSONDecodeError:
                return {"_raw": raw.decode("utf-8", "replace")}
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", "replace")[:800]
        raise SystemExit(f"ERROR: HTTP {e.code} {method} {url}\n{body}")


# ====================================================================
# Git / tag inspection
# ====================================================================

VERSION_RE = re.compile(r"^v?(\d+\.\d+\.\d+)\+(\d+)$")


def get_latest_tag() -> Optional[tuple[str, str, int, int]]:
    """Return (raw_tag, semver, build, tagger_unix_ts) for the most
    recently created tag matching vX.Y.Z+N. None if no such tag exists.
    """
    try:
        tags = subprocess.check_output(
            ["git", "tag", "--sort=-creatordate"],
            text=True,
        ).splitlines()
    except subprocess.CalledProcessError:
        return None

    for raw in tags:
        raw = raw.strip()
        m = VERSION_RE.match(raw)
        if not m:
            continue
        semver = m.group(1)
        build = int(m.group(2))
        # Use the tag's creator date (taggerdate for annotated, creator
        # for lightweight). Falls back to the tagged commit's date.
        try:
            ts_str = subprocess.check_output(
                ["git", "for-each-ref", "--format=%(creatordate:unix)",
                 f"refs/tags/{raw}"],
                text=True,
            ).strip()
            ts = int(ts_str)
        except (subprocess.CalledProcessError, ValueError):
            ts = int(subprocess.check_output(
                ["git", "log", "-1", "--format=%ct", raw],
                text=True,
            ).strip())
        return raw, semver, build, ts
    return None


def age_hours(unix_ts: int) -> float:
    return (time.time() - unix_ts) / 3600.0


# ====================================================================
# App Store Connect — release Pending Developer Release
# ====================================================================

def _asc_jwt() -> str:
    key_id = os.environ.get("ASC_KEY_ID")
    issuer = os.environ.get("ASC_ISSUER_ID")
    key_b64 = os.environ.get("ASC_KEY_BASE64")
    missing = [k for k, v in [("ASC_KEY_ID", key_id),
                              ("ASC_ISSUER_ID", issuer),
                              ("ASC_KEY_BASE64", key_b64)] if not v]
    if missing:
        raise SystemExit(f"ERROR: missing ASC env vars: {missing}")

    try:
        from cryptography.hazmat.primitives import serialization, hashes
        from cryptography.hazmat.primitives.asymmetric import ec, utils
    except ImportError:
        raise SystemExit(
            "ERROR: 'cryptography' not installed.\n"
            "  pip install -r scripts/requirements.txt"
        )

    p8 = base64.b64decode(key_b64)
    now = int(time.time())
    header = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
    payload = {"iss": issuer, "iat": now, "exp": now + 1100,
               "aud": "appstoreconnect-v1"}
    h_b = _b64url(json.dumps(header, separators=(",", ":")).encode())
    p_b = _b64url(json.dumps(payload, separators=(",", ":")).encode())
    msg = f"{h_b}.{p_b}".encode("ascii")

    key = serialization.load_pem_private_key(p8, password=None)
    der_sig = key.sign(msg, ec.ECDSA(hashes.SHA256()))
    r, s = utils.decode_dss_signature(der_sig)
    raw_sig = r.to_bytes(32, "big") + s.to_bytes(32, "big")
    return f"{h_b}.{p_b}.{_b64url(raw_sig)}"


def ios_release_if_eligible(build_n: int, dry_run: bool) -> str:
    """Look for an App Store version in PENDING_DEVELOPER_RELEASE whose
    attached build has version == build_n. If found, trigger the
    release. Return a one-line status string."""
    print(f"  [iOS] looking for PENDING_DEVELOPER_RELEASE matching build {build_n}")
    jwt_token = _asc_jwt()
    headers = {"Authorization": f"Bearer {jwt_token}"}

    apps = _http_request(
        "GET",
        f"https://api.appstoreconnect.apple.com/v1/apps"
        f"?filter[bundleId]={IOS_BUNDLE}&limit=1",
        headers=headers,
    )
    if not apps.get("data"):
        return f"app not found by bundle id {IOS_BUNDLE}"
    app_id = apps["data"][0]["id"]
    print(f"  [iOS] app id = {app_id}")

    versions = _http_request(
        "GET",
        f"https://api.appstoreconnect.apple.com/v1/apps/{app_id}/appStoreVersions"
        f"?filter[appStoreState]=PENDING_DEVELOPER_RELEASE&limit=20",
        headers=headers,
    )
    candidates = versions.get("data", [])
    if not candidates:
        return "no versions in PENDING_DEVELOPER_RELEASE state"

    for v in candidates:
        v_id = v["id"]
        v_state = v.get("attributes", {}).get("appStoreState", "?")
        v_str = v.get("attributes", {}).get("versionString", "?")
        # Get the build attached to this version
        build_link = _http_request(
            "GET",
            f"https://api.appstoreconnect.apple.com/v1/appStoreVersions/{v_id}/build",
            headers=headers,
        )
        if not build_link.get("data"):
            print(f"  [iOS] version {v_str} ({v_id}) has no build attached, skipping")
            continue
        b_id = build_link["data"]["id"]
        b = _http_request(
            "GET",
            f"https://api.appstoreconnect.apple.com/v1/builds/{b_id}",
            headers=headers,
        )
        b_ver = b.get("data", {}).get("attributes", {}).get("version", "?")
        print(f"  [iOS] candidate version {v_str} -> build {b_ver}")

        if str(b_ver) != str(build_n):
            continue

        # Match. Trigger release.
        if dry_run:
            return f"WOULD release App Store version {v_str} (build {build_n}) [dry-run]"

        release_body = json.dumps({
            "data": {
                "type": "appStoreVersionReleaseRequests",
                "relationships": {
                    "appStoreVersion": {
                        "data": {"type": "appStoreVersions", "id": v_id}
                    }
                }
            }
        }).encode()
        _http_request(
            "POST",
            "https://api.appstoreconnect.apple.com/v1/appStoreVersionReleaseRequests",
            headers={**headers, "Content-Type": "application/json"},
            data=release_body,
        )
        return f"released App Store version {v_str} (build {build_n})"

    return f"no PENDING_DEVELOPER_RELEASE version matches build {build_n}"


# ====================================================================
# Play Console — promote alpha -> production
# ====================================================================

def _play_access_token() -> str:
    raw = os.environ.get("PLAY_SERVICE_ACCOUNT_JSON")
    if not raw:
        raise SystemExit("ERROR: PLAY_SERVICE_ACCOUNT_JSON env not set")
    try:
        sa = json.loads(raw)
    except json.JSONDecodeError:
        raise SystemExit("ERROR: PLAY_SERVICE_ACCOUNT_JSON is not valid JSON")

    try:
        from cryptography.hazmat.primitives import serialization, hashes
        from cryptography.hazmat.primitives.asymmetric import padding
    except ImportError:
        raise SystemExit("ERROR: 'cryptography' not installed.")

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

    body = (f"grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer"
            f"&assertion={jwt}").encode("ascii")
    req = urllib.request.Request(
        "https://oauth2.googleapis.com/token",
        data=body,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=20) as resp:
        return json.loads(resp.read())["access_token"]


def android_promote_if_eligible(build_n: int, dry_run: bool) -> str:
    """Look at Play alpha track. If its active release has versionCode
    build_n AND production isn't already on build_n, copy the alpha
    release into production track and commit the edit."""
    print(f"  [Android] looking for alpha release with versionCode {build_n}")
    token = _play_access_token()
    headers = {"Authorization": f"Bearer {token}"}
    base = (f"https://androidpublisher.googleapis.com/androidpublisher/v3"
            f"/applications/{ANDROID_PACKAGE}")

    edit = _http_request(
        "POST", f"{base}/edits",
        headers={**headers, "Content-Length": "0"},
        data=b"",
    )
    edit_id = edit["id"]

    def _delete_edit():
        try:
            _http_request("DELETE", f"{base}/edits/{edit_id}", headers=headers)
        except Exception:
            pass

    try:
        # 1. Check production — is it already on build_n?
        prod = _http_request("GET", f"{base}/edits/{edit_id}/tracks/production",
                              headers=headers)
        prod_codes: list[int] = []
        for rel in prod.get("releases", []):
            for vc in rel.get("versionCodes", []):
                try:
                    prod_codes.append(int(vc))
                except (TypeError, ValueError):
                    pass
        if build_n in prod_codes:
            _delete_edit()
            return f"production already on build {build_n} — nothing to do"
        print(f"  [Android] production version codes: {prod_codes}")

        # 2. Find alpha release with build_n
        alpha = _http_request("GET", f"{base}/edits/{edit_id}/tracks/alpha",
                               headers=headers)
        matching_release = None
        for rel in alpha.get("releases", []):
            codes = [int(vc) for vc in rel.get("versionCodes", []) if str(vc).isdigit()]
            if build_n in codes:
                matching_release = rel
                break
        if not matching_release:
            _delete_edit()
            alpha_codes = sorted({int(vc) for rel in alpha.get("releases", [])
                                   for vc in rel.get("versionCodes", [])
                                   if str(vc).isdigit()})
            return f"no alpha release with build {build_n} (alpha has {alpha_codes})"
        print(f"  [Android] found alpha release with build {build_n}")

        if dry_run:
            _delete_edit()
            return (f"WOULD promote alpha release with build {build_n} "
                    f"to production [dry-run]")

        # 3. Build a production release mirroring the alpha one
        new_prod_release = {
            "name": matching_release.get("name") or f"{build_n}",
            "versionCodes": [str(build_n)],
            "status": "completed",
        }
        if matching_release.get("releaseNotes"):
            new_prod_release["releaseNotes"] = matching_release["releaseNotes"]

        update_body = json.dumps({
            "track": "production",
            "releases": [new_prod_release],
        }).encode()
        _http_request(
            "PUT", f"{base}/edits/{edit_id}/tracks/production",
            headers={**headers, "Content-Type": "application/json"},
            data=update_body,
        )

        # 4. Commit the edit. Without this, the changes don't apply.
        _http_request("POST", f"{base}/edits/{edit_id}:commit",
                       headers={**headers, "Content-Length": "0"},
                       data=b"")
        # Edit is now committed — don't try to delete.
        return f"promoted alpha release (build {build_n}) to production"
    except SystemExit:
        _delete_edit()
        raise


# ====================================================================
# Main
# ====================================================================

def main() -> int:
    ap = argparse.ArgumentParser(description="3-day release gate.")
    ap.add_argument("--dry-run", action="store_true",
                    help="Report what would happen; don't call any release/promote endpoint.")
    ap.add_argument("--skip-ios", action="store_true")
    ap.add_argument("--skip-android", action="store_true")
    args = ap.parse_args()

    info = get_latest_tag()
    if not info:
        print("::warning::No tags matching vX.Y.Z+N — nothing to gate.")
        return 5
    tag, semver, build, ts = info
    hours = age_hours(ts)
    print(f"Latest tag: {tag}  ->  semver={semver}  build={build}  "
          f"age={hours:.1f}h  (gate: {GATE_HOURS}h)")

    if hours < GATE_HOURS:
        print(f"::notice::Tag {tag} is only {hours:.1f}h old. Gate is {GATE_HOURS}h. "
              f"Skipping release; testers already have the build.")
        return 0

    print(f"::notice::Tag {tag} is {hours:.1f}h old — past the {GATE_HOURS}h gate. "
          f"Checking store states...")
    failures: list[str] = []

    if not args.skip_ios:
        try:
            ios_result = ios_release_if_eligible(build, args.dry_run)
            print(f"  [iOS] result: {ios_result}")
            if ios_result.startswith("released") or ios_result.startswith("WOULD"):
                print(f"::notice::iOS gate: {ios_result}")
            else:
                print(f"::notice::iOS gate: {ios_result} (nothing to do)")
        except SystemExit as e:
            msg = str(e)
            failures.append(f"iOS: {msg}")
            print(f"::error::iOS gate error: {msg}")

    if not args.skip_android:
        try:
            android_result = android_promote_if_eligible(build, args.dry_run)
            print(f"  [Android] result: {android_result}")
            if android_result.startswith("promoted") or android_result.startswith("WOULD"):
                print(f"::notice::Android gate: {android_result}")
            else:
                print(f"::notice::Android gate: {android_result}")
        except SystemExit as e:
            msg = str(e)
            failures.append(f"Android: {msg}")
            print(f"::error::Android gate error: {msg}")

    if failures:
        print(f"\n{len(failures)} side(s) errored:")
        for f in failures:
            print(f"  - {f}")
        return 4
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\nInterrupted.")
        sys.exit(130)
    except urllib.error.URLError as e:
        print(f"\nNETWORK ERROR: {e}")
        sys.exit(4)
