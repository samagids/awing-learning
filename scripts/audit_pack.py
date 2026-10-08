#!/usr/bin/env python3
"""One pass over the finished image pack, against Dr. Sama's three rules.

    1. Every word must have an image.
    2. The object in the image must match the English meaning.
    3. Any human in any image must be black or brown.

Each rule already has a checker. This runs all three, merges what they
find, and splits the result by WHAT WOULD ACTUALLY FIX IT - which is the
part that kept getting lost:

  REGENERATE   The key is missing, or the picture has a white person in
               it. The prompt is fine; the model's output is not. A new
               shot of the same prompt fixes it, so these go into a
               --keys-file.

  NEEDS A PROMPT   The picture does not show its meaning, or a crowd of
               different words collapsed onto one picture. Reshooting
               changes nothing here, because the prompt is what is wrong.
               These go into a JSON file with their glosses, to be read
               and turned into PROMPT_OVERRIDES by hand.

Shooting the second group is how three earlier rounds were spent.

USAGE
    # everything (needs the venv with torch + transformers, and the GPU)
    .\\venv\\Scripts\\python.exe scripts\\audit_pack.py

    # no GPU: rule 1 and the duplicate scan only, a few seconds
    python scripts/audit_pack.py --no-gpu

    # how deep to cut rule 2; 80 = "beaten by 80% of the corpus"
    python scripts/audit_pack.py --worst 80
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRIPTS = ROOT / "scripts"
CONTRIB = ROOT / "contributions"

COVERAGE_KEYS = CONTRIB / "missing_image_keys.txt"
SKIN_KEYS = CONTRIB / "wrong_skin_keys.txt"
AUDIT_JSON = CONTRIB / "image_audit.json"


def run(label: str, argv: list[str]) -> bool:
    """Run a checker. Returns False if it failed; never raises."""
    print(f"\n{'=' * 64}\n{label}\n{'=' * 64}")
    try:
        r = subprocess.run([sys.executable, *argv], cwd=ROOT)
    except Exception as e:                      # noqa: BLE001
        print(f"  !! could not run: {e}")
        return False
    if r.returncode != 0:
        print(f"  !! exited {r.returncode} - its results are not included")
        return False
    return True


def read_keys(path: Path) -> set[str]:
    if not path.exists():
        return set()
    return {
        line.strip()
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--no-gpu", action="store_true",
                    help="skip the two CLIP checks (rules 2 and 3)")
    ap.add_argument("--worst", type=int, default=80,
                    help="rule 2 cut: flag images whose own meaning is "
                         "beaten by this percent of the corpus (default 80)")
    ap.add_argument("--tag", default=date.today().strftime("%Y%m%d"))
    args = ap.parse_args()

    CONTRIB.mkdir(parents=True, exist_ok=True)
    ok_cov = ok_skin = ok_match = False

    # ---- rule 1: every word must have an image ----------------------
    ok_cov = run("RULE 1  every word must have an image",
                 [str(SCRIPTS / "check_image_coverage.py"),
                  "--write-keys", str(COVERAGE_KEYS)])
    missing = read_keys(COVERAGE_KEYS) if ok_cov else set()

    # ---- rule 3: any human must be black or brown -------------------
    wrong_skin: set[str] = set()
    if not args.no_gpu:
        ok_skin = run("RULE 3  any human in any image must be black or brown",
                      [str(SCRIPTS / "check_people_skin.py"), "--regen-list"])
        wrong_skin = read_keys(SKIN_KEYS) if ok_skin else set()

    # ---- rule 2: the picture must match the meaning -----------------
    bad_match: list[dict] = []
    dup_clusters: list[list[dict]] = []
    if not args.no_gpu:
        ok_match = run("RULE 2  the picture must match the English meaning",
                       [str(SCRIPTS / "audit_images.py"), "--limit", "0"])
    else:
        ok_match = run("RULE 2 (structural only)  duplicates and templates",
                       [str(SCRIPTS / "audit_images.py"), "--structural"])
    if ok_match and AUDIT_JSON.exists():
        rep = json.loads(AUDIT_JSON.read_text(encoding="utf-8"))
        bad_match = [r for r in rep.get("images", [])
                     if r.get("percentile", -1) >= args.worst]
        dup_clusters = rep.get("duplicate_clusters", [])

    # ---- split by what would fix it ---------------------------------
    regenerate = sorted(missing | wrong_skin)

    needs_prompt: dict[str, dict] = {}
    for r in bad_match:
        needs_prompt[r["key"]] = {
            "english": r.get("english", ""),
            "awing": r.get("awing", ""),
            "category": r.get("category", ""),
            "why": f"own meaning beaten by {r['percentile']}% of the corpus",
        }
    for cluster in dup_clusters:
        for m in cluster:
            needs_prompt.setdefault(m["key"], {
                "english": m.get("english", ""),
                "awing": "",
                "category": "",
                "why": "shares a picture with "
                       f"{len(cluster) - 1} other word(s)",
            })
    # A key that is simply absent cannot also need a better prompt yet.
    for k in missing:
        needs_prompt.pop(k, None)

    keys_path = SCRIPTS / f"_reshoot_{args.tag}.txt"
    prompt_path = CONTRIB / f"needs_prompt_{args.tag}.json"
    keys_path.write_text("\n".join(regenerate) + "\n", encoding="utf-8")
    prompt_path.write_text(
        json.dumps(needs_prompt, indent=2, ensure_ascii=False),
        encoding="utf-8")

    # ---- the only output that matters -------------------------------
    print(f"\n{'=' * 64}\nRESULT\n{'=' * 64}")
    if not ok_cov:
        print("  rule 1 did not run - the counts below are incomplete")
    if not args.no_gpu and not ok_skin:
        print("  rule 3 did not run - the counts below are incomplete")
    if not ok_match:
        print("  rule 2 did not run - the counts below are incomplete")

    print(f"\n  REGENERATE ({len(regenerate)})   a new shot fixes these")
    print(f"      missing image          {len(missing)}")
    print(f"      white person in it     {len(wrong_skin)}")
    print(f"      -> {keys_path.relative_to(ROOT)}")

    print(f"\n  NEEDS A PROMPT ({len(needs_prompt)})   reshooting will NOT "
          f"fix these")
    print(f"      does not show its meaning  {len(bad_match)}")
    print(f"      shares a picture           "
          f"{sum(len(c) for c in dup_clusters)} in "
          f"{len(dup_clusters)} clusters")
    print(f"      -> {prompt_path.relative_to(ROOT)}")

    if regenerate:
        rel = keys_path.relative_to(ROOT)
        print(f"\n  Reshoot the first group with:\n")
        print(f"      .\\venv\\Scripts\\python.exe scripts\\generate_images.py "
              f"generate `\n          --keys-file {rel} "
              f"--format webp --quality 82")
    print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
