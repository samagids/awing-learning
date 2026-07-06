#!/usr/bin/env python3
"""sync_version.py -- propagate pubspec.yaml's version to in-app mirrors.

pubspec.yaml is the SINGLE SOURCE OF TRUTH. This script reads
`version: X.Y.Z+N` from it and writes the same values into the three
Dart files that historically drift out of sync:

  1. lib/screens/about_screen.dart   -- appVersion, buildNumber
  2. lib/services/analytics_service.dart -- _appVersion
  3. lib/services/cloud_backup_service.dart -- _kAppVersion

Idempotent: running twice in a row is a no-op the second time.
Exits 0 even when no changes are needed; exits non-zero only on
parse errors or write failures.

Run:
  python scripts/sync_version.py             # auto-fix
  python scripts/sync_version.py --check     # report drift only, exit 1 if drift
"""
from __future__ import annotations
import argparse
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PUBSPEC = REPO / "pubspec.yaml"

# (path, regex pattern with one capture group, replacement template)
# `{semver}` and `{build}` are the substitution placeholders.
TARGETS = [
    (REPO / "lib" / "screens" / "about_screen.dart",
     r"(static const String appVersion = ')([\d.]+)(';)",
     "{semver}"),
    (REPO / "lib" / "screens" / "about_screen.dart",
     r"(static const String buildNumber = ')(\d+)(';)",
     "{build}"),
    (REPO / "lib" / "services" / "analytics_service.dart",
     r"(static const String _appVersion = ')([\d.]+)(';)",
     "{semver}"),
    (REPO / "lib" / "services" / "cloud_backup_service.dart",
     r"(const String _kAppVersion = ')([\d.+]+)(';)",
     "{semver}+{build}"),
]


def parse_pubspec_version() -> tuple[str, str]:
    src = PUBSPEC.read_text(encoding="utf-8")
    m = re.search(r"^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$", src, re.M)
    if not m:
        raise SystemExit("Cannot find 'version: X.Y.Z+N' in pubspec.yaml")
    return m.group(1), m.group(2)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true",
                    help="Report drift without writing. Exit 1 if drift.")
    args = ap.parse_args()

    semver, build = parse_pubspec_version()
    print(f"pubspec.yaml: {semver}+{build}")

    drift = []
    for path, pattern, value_tpl in TARGETS:
        if not path.exists():
            print(f"  [skip] {path.relative_to(REPO)} -- not found")
            continue
        src = path.read_text(encoding="utf-8")
        regex = re.compile(pattern)
        m = regex.search(src)
        if not m:
            print(f"  [warn] {path.relative_to(REPO)} -- pattern not found")
            continue
        wanted = value_tpl.format(semver=semver, build=build)
        current = m.group(2)
        if current == wanted:
            print(f"  [ok]   {path.relative_to(REPO)} -- {current}")
            continue
        drift.append((path, current, wanted))
        if args.check:
            print(f"  [DRIFT] {path.relative_to(REPO)}: {current} -> {wanted}")
        else:
            new_src = regex.sub(lambda m: m.group(1) + wanted + m.group(3),
                                src, count=1)
            # Guard: sync_version.py must NEVER shrink a file. If the new
            # source has fewer lines than the source we read, something
            # went wrong (OneDrive delivered a truncated file for read,
            # regex captured too much, etc.). Refuse the write and let
            # the caller investigate. Prevents the v1.18.4+93 truncation
            # incident (2026-07-05) from ever recurring silently.
            old_lines = src.count("\n")
            new_lines = new_src.count("\n")
            if new_lines < old_lines:
                raise SystemExit(
                    f"ERROR: sync_version.py would shrink "
                    f"{path.relative_to(REPO)} from {old_lines} lines "
                    f"to {new_lines} lines. Refusing to write. "
                    f"Check the file for truncation (likely OneDrive "
                    f"sync race or Edit-tool corruption) and restore "
                    f"from git before re-running."
                )
            path.write_text(new_src, encoding="utf-8")
            # Strip any trailing NULs from Edit-tool truncation regressions
            raw = path.read_bytes().rstrip(b"\x00 \t\r\n") + b"\n"
            # Second guard on the round-tripped file: if read_bytes came
            # back short of what we just wrote, refuse the write.
            if raw.count(b"\n") < new_lines:
                raise SystemExit(
                    f"ERROR: {path.relative_to(REPO)} shrank on "
                    f"read-after-write (wrote {new_lines} lines, read "
                    f"back {raw.count(b'/n')} lines). Likely OneDrive "
                    f"partial write. File may be corrupt — restore from "
                    f"git and re-run."
                )
            path.write_bytes(raw)
            print(f"  [fixed] {path.relative_to(REPO)}: {current} -> {wanted}")

    if args.check and drift:
        print(f"\n{len(drift)} file(s) out of sync with pubspec.yaml.")
        return 1
    if not drift:
        print("\nAll in sync.")
    else:
        print(f"\nWrote {len(drift)} fix(es).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
