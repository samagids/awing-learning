#!/usr/bin/env python3
"""promote_testflight_to_production.py — auto-release App Store versions
that Apple has already approved and are sitting in PENDING_DEVELOPER_RELEASE
state, once they've soaked long enough on TestFlight / alpha.

Runs daily via .github/workflows/promote-testflight-to-production.yml. This
is the iOS twin of promote_alpha_to_production.py. Same 7-day-default soak
so Play and App Store production releases land the same day on each tag.

Session 61 said "intentionally no cron auto-releaser for iOS because Apple's
review timing is unpredictable." That reasoning is defused here by ONLY
touching versions already in PENDING_DEVELOPER_RELEASE state — Apple has
approved, we just haven't clicked the button. Review-in-flight versions
(IN_REVIEW / WAITING_FOR_REVIEW), rejected versions, and mid-processing
versions all have different states and are skipped.

Decision flow per version currently in PENDING_DEVELOPER_RELEASE:
  1. Look up the associated build number (via the .build relationship)
  2. Compute the git tag: v{versionString}+{buildNumber}
  3. Skip if that tag doesn't exist in the repo (safety: don't release
     something we didn't consciously tag from CI)
  4. Skip if that tag is younger than IOS_SOAK_DAYS days
  5. Otherwise: POST /v1/appStoreVersionReleaseRequests → release live

Environment:
  ASC_KEY_ID        App Store Connect API key id (10-char alphanumeric)
  ASC_ISSUER_ID     App Store Connect API issuer (UUID)
  ASC_KEY_BASE64    Base64 of the .p8 private key file
                    (or all three under config/asc-credentials.json)
  IOS_SOAK_DAYS     (optional, default '7') minimum tag age in days
                    before a PENDING version is eligible.
  DRY_RUN           (optional, default 'false') set to 'true' to list
                    candidates without calling the release endpoint.

Exit code 0 on success (including "nothing to release"). Exit code 1 on
unrecoverable errors (auth failure, malformed input, API exception).
"""
from __future__ import annotations

import base64
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Optional

REPO = Path(__file__).resolve().parent.parent
CONFIG_DIR = REPO / "config"
ASC_CRED_PATH = CONFIG_DIR / "asc-credentials.json"

IOS_BUNDLE = "com.awing.awingAiLearning"

SOAK_DAYS = int(os.environ.get("IOS_SOAK_DAYS", "7"))
DRY_RUN = os.environ.get("DRY_RUN", "false").lower() == "true"

# Match git tags like v1.18.4+92. Captures semver and build number.
TAG_VERSION_RE = re.compile(r"^v(\d+\.\d+\.\d+)\+(\d+)$")

# States we care about. Apple documents these on AppStoreVersion.appStoreState.
STATE_PENDING = "PENDING_DEVELOPER_RELEASE"
STATE_LIVE = "READY_FOR_SALE"

ASC_BASE = "https://api.appstoreconnect.apple.com"


# =====================================================================
# Logging helpers
# =====================================================================

def banner(line: str) -> None:
    bar = "=" * 64
    print(bar)
    print(line)
    print(bar)


def gh_error(msg: str) -> None:
    """Emit an error visible in the GitHub Actions summary panel."""
    print(f"::error::{msg}")


def gh_warning(msg: str) -> None:
    print(f"::warning::{msg}")


# =====================================================================
# Git tag scan (identical shape to Play promoter for consistency)
# =====================================================================

def get_recent_tags(window_days: int = 90) -> dict[str, datetime]:
    """Return {tag_name: created_dt_utc} for v*+N tags created within
    the last `window_days` days.
    """
    try:
        out = subprocess.check_output(
            [
                "git",
                "for-each-ref",
                "--sort=-creatordate",
                "--format=%(refname:short)|%(creatordate:iso8601)",
                "refs/tags",
            ],
            text=True,
        )
    except subprocess.CalledProcessError as e:
        gh_error(f"git for-each-ref failed: {e}")
        sys.exit(1)

    cutoff = datetime.now(timezone.utc) - timedelta(days=window_days)
    tags: dict[str, datetime] = {}
    for line in out.splitlines():
        line = line.strip()
        if not line or "|" not in line:
            continue
        name, iso = line.split("|", 1)
        if not TAG_VERSION_RE.match(name):
            continue
        # git for-each-ref emits '2026-07-05 12:34:56 +0000'; datetime
        # can't parse the space-separated form directly, so normalize.
        iso_norm = iso.strip().replace(" ", "T", 1)
        # Convert final ' +0000' → '+0000' if present as space-separated
        if " " in iso_norm:
            iso_norm = iso_norm.replace(" ", "")
        try:
            dt = datetime.fromisoformat(iso_norm)
        except ValueError:
            # As a fallback try python's %Y-%m-%dT%H:%M:%S%z
            try:
                dt = datetime.strptime(iso_norm, "%Y-%m-%dT%H:%M:%S%z")
            except ValueError:
                continue
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        if dt < cutoff:
            continue
        tags[name] = dt
    return tags


# =====================================================================
# App Store Connect credentials + JWT (mirror of check_version_codes.py)
# =====================================================================

def _b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


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
        gh_error("ASC_KEY_BASE64 is not valid base64")
        sys.exit(1)
    return key_id, issuer, p8


def _asc_jwt(key_id: str, issuer: str, p8: bytes) -> str:
    """Build an ES256 JWT for the App Store Connect API."""
    try:
        from cryptography.hazmat.primitives import serialization, hashes
        from cryptography.hazmat.primitives.asymmetric import ec, utils
    except ImportError:
        gh_error("'cryptography' not installed. pip install cryptography")
        sys.exit(1)

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
    r, s = utils.decode_dss_signature(der_sig)
    raw_sig = r.to_bytes(32, "big") + s.to_bytes(32, "big")
    return f"{h_b}.{p_b}.{_b64url(raw_sig)}"


# =====================================================================
# App Store Connect HTTP helpers
# =====================================================================

def _http_get(url: str, jwt_token: str) -> dict:
    req = urllib.request.Request(
        url,
        headers={"Authorization": f"Bearer {jwt_token}", "Accept": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", "replace")[:500]
        gh_error(f"ASC GET {url} → HTTP {e.code}: {body}")
        sys.exit(1)


def _http_post(url: str, jwt_token: str, body: dict) -> tuple[int, dict]:
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        method="POST",
        headers={
            "Authorization": f"Bearer {jwt_token}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            payload = resp.read()
            return resp.getcode(), (json.loads(payload) if payload else {})
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", "replace")[:1000]
        return e.code, {"__error_body": body}


def _asc_app_id(jwt_token: str) -> Optional[str]:
    """Look up our app's ASC numeric id from bundle id."""
    url = f"{ASC_BASE}/v1/apps?filter[bundleId]={IOS_BUNDLE}&limit=1"
    data = _http_get(url, jwt_token)
    if not data.get("data"):
        gh_error(f"App not found by bundle id {IOS_BUNDLE}")
        return None
    return data["data"][0]["id"]


# =====================================================================
# App Store Version discovery
# =====================================================================

def list_pending_versions(jwt_token: str, app_id: str) -> list[dict]:
    """Return a list of {version_id, semver, build_number, state,
    created_dt} for iOS App Store versions currently in
    PENDING_DEVELOPER_RELEASE state, ordered newest-first.

    Uses ?include=build to get the associated build's version number in
    the same round trip. The build's "version" field is the CFBundleVersion
    integer (the +N in v1.18.4+92).
    """
    url = (
        f"{ASC_BASE}/v1/apps/{app_id}/appStoreVersions"
        f"?filter[platform]=IOS"
        f"&filter[appStoreState]={STATE_PENDING}"
        f"&include=build"
        f"&limit=20"
    )
    data = _http_get(url, jwt_token)

    # Index included builds by id → attributes.version
    build_versions: dict[str, str] = {}
    for inc in data.get("included", []):
        if inc.get("type") == "builds":
            v = inc.get("attributes", {}).get("version")
            if v:
                build_versions[inc["id"]] = v

    results = []
    for v in data.get("data", []):
        attrs = v.get("attributes", {}) or {}
        semver = attrs.get("versionString")
        state = attrs.get("appStoreState")
        created = attrs.get("createdDate")
        try:
            created_dt = datetime.fromisoformat(created.replace("Z", "+00:00")) if created else None
        except (ValueError, AttributeError):
            created_dt = None

        # Extract associated build's version via .build relationship.
        rels = v.get("relationships", {}) or {}
        build_rel = ((rels.get("build") or {}).get("data") or {})
        build_id = build_rel.get("id")
        build_number = build_versions.get(build_id) if build_id else None

        results.append({
            "version_id": v.get("id"),
            "semver": semver,
            "build_number": build_number,
            "state": state,
            "created_dt": created_dt,
        })
    return results


def release_version(jwt_token: str, version_id: str) -> bool:
    """POST /v1/appStoreVersionReleaseRequests to release an approved
    version live. Returns True on 201 Created, False otherwise."""
    url = f"{ASC_BASE}/v1/appStoreVersionReleaseRequests"
    body = {
        "data": {
            "type": "appStoreVersionReleaseRequests",
            "relationships": {
                "appStoreVersion": {
                    "data": {
                        "type": "appStoreVersions",
                        "id": version_id,
                    }
                }
            },
        }
    }
    code, resp = _http_post(url, jwt_token, body)
    if code == 201:
        return True
    err = resp.get("__error_body", resp)
    gh_error(f"Release POST failed: HTTP {code}: {err}")
    return False


# =====================================================================
# Main flow
# =====================================================================

def main() -> int:
    banner(
        f"Promote TestFlight → App Store production (soak={SOAK_DAYS}d, "
        f"dry_run={DRY_RUN})"
    )

    creds = _asc_credentials()
    if not creds:
        gh_error(
            "App Store Connect credentials missing. Set env vars "
            "ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_BASE64 (or drop "
            "config/asc-credentials.json)."
        )
        return 1

    key_id, issuer, p8 = creds
    print(f"[auth] authenticating with ASC key {key_id} ...")
    jwt_token = _asc_jwt(key_id, issuer, p8)

    app_id = _asc_app_id(jwt_token)
    if not app_id:
        return 1
    print(f"[auth] app id = {app_id}")

    print("[git] scanning recent v*+N tags ...")
    tag_dates = get_recent_tags(90)
    print(f"[git] {len(tag_dates)} candidate tags in last 90 days")

    print(f"[asc] listing versions in {STATE_PENDING} state ...")
    pending = list_pending_versions(jwt_token, app_id)
    if not pending:
        print("Nothing to release. Exiting cleanly.")
        return 0
    print(f"[asc] {len(pending)} version(s) awaiting developer release")

    # Server-side sort was rejected by Apple with HTTP 400
    # PARAMETER_ERROR.ILLEGAL "The parameter 'sort' can not be used
    # with this request" (Session 62 first cron tick, 2026-07-06).
    # Sort client-side by createdDate desc so the "release newest
    # first, one per run" semantic below is preserved.
    pending.sort(
        key=lambda v: v.get("created_dt") or datetime.min.replace(tzinfo=timezone.utc),
        reverse=True,
    )

    now = datetime.now(timezone.utc)
    released_any = False

    for v in pending:
        semver = v["semver"]
        build = v["build_number"]
        version_id = v["version_id"]

        if not semver or not build:
            gh_warning(
                f"AppStoreVersion {version_id} missing semver or build number "
                f"({semver}+{build}) — skipping"
            )
            continue

        tag = f"v{semver}+{build}"
        tag_date = tag_dates.get(tag)
        if not tag_date:
            print(
                f"  {tag}: no matching git tag in last 90 days — "
                f"skipping (safety: only release consciously tagged versions)"
            )
            continue

        age_days = (now - tag_date).days
        if age_days < SOAK_DAYS:
            print(
                f"  {tag}: age={age_days}d < soak={SOAK_DAYS}d — soaking "
                f"(would release in {SOAK_DAYS - age_days}d)"
            )
            continue

        print(
            f"  {tag}: age={age_days}d ≥ soak={SOAK_DAYS}d + "
            f"state={STATE_PENDING} → RELEASE"
        )
        if DRY_RUN:
            print(
                f"    DRY_RUN: would POST appStoreVersionReleaseRequests "
                f"for versionId={version_id}"
            )
            released_any = True
            continue

        ok = release_version(jwt_token, version_id)
        if ok:
            print(f"    ✅ RELEASED {tag} (version id {version_id})")
            released_any = True
            # Only release one per run so the cron behavior mirrors the
            # Play promoter: newest-first, one hop per day. Prevents an
            # unrelated backlog of stuck-PENDING versions from all firing
            # at once.
            break
        else:
            gh_error(f"    Release POST failed for {tag}")
            return 1

    if not released_any:
        print("No eligible versions this run.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
