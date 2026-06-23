#!/usr/bin/env python3
"""
Apply a corrections JSON exported from the word-alignment viewer to
lib/data/awing_vocabulary.dart.

Workflow
--------
1. Dr. Sama opens corpus/word_level/MAT_001/index.html in browser.
2. Reviews each word, marks status (verified/added/fixed), edits gloss.
3. Clicks "Download corrections" -> corrections_MAT_001.json.
4. Moves file to contributions/word_corrections/.
5. Runs:
     python scripts/apply_word_corrections.py \
         contributions/word_corrections/corrections_MAT_001.json

What this does
--------------
- status=verified: logged only (current gloss is fine, no change)
- status=added:    appends a NEW AwingWord to lib/data/awing_vocabulary.dart
                   in a dedicated `bibleVerifiedExtras` block at the end
                   (created on first run). Skipped if (awing, english)
                   already exists exactly.
- status=fixed:    finds the existing AwingWord(awing: '<X>', english:
                   '<Y>', ...) entry and updates its english field.
                   Only the FIRST exact match is updated; ambiguous
                   cases (multiple matches) are listed for review.

Safety
------
- Writes .bak_word_corrections backup of vocab.dart before any edit
- Dart string literals are quoted with the apostrophe-safe rule:
  if value contains a `'`, the literal is double-quoted; otherwise
  single-quoted. Both styles escape backslashes and the matching
  outer quote.
- Awing field is restricted to NFD-base chars + tone marks + the
  glottal apostrophe + Awing-only graphemes. English field is plain
  ASCII + common punctuation. Any payload that fails the regex check
  is rejected with a loud warning.

Re-running with --dry-run shows what would change without writing.
"""

import argparse
import json
import re
import shutil
import sys
import unicodedata
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
VOCAB_DART = REPO / "lib" / "data" / "awing_vocabulary.dart"
ARCHIVE_DIR = REPO / "contributions" / "word_corrections" / "applied"

# Allowlists -- mirror apply_contributions.py's defense-in-depth posture.
AWING_RE  = re.compile(r"^[A-Za-zɛɔəɨŋɣÆ̀-ͯʼ'’‘\s\-]+$")
ENGLISH_RE = re.compile(r"^[A-Za-z0-9 ,.;:!?\(\)\-'\"‘’“”/]+$")

BIBLE_SECTION_MARKER = "// === BEGIN bibleVerifiedExtras (auto-applied by apply_word_corrections.py) ==="
BIBLE_SECTION_END    = "// === END bibleVerifiedExtras ==="


def _dart_literal(s: str) -> str:
    """Quote a string for safe Dart embedding. Picks the quote style
    based on whether the value contains an apostrophe."""
    if "'" in s:
        # Use double quotes; escape any internal double quote and backslash
        body = s.replace("\\", "\\\\").replace('"', '\\"')
        return f'"{body}"'
    body = s.replace("\\", "\\\\")
    return f"'{body}'"


def _allowlist_ok(awing: str, english: str) -> tuple[bool, str]:
    if not awing or not english:
        return False, "empty awing or english"
    if not AWING_RE.match(awing):
        return False, f"awing contains disallowed character ({awing!r})"
    if not ENGLISH_RE.match(english):
        return False, f"english contains disallowed character ({english!r})"
    if len(awing) > 60:
        return False, "awing > 60 chars"
    if len(english) > 200:
        return False, "english > 200 chars"
    return True, ""


def _norm_awing(s: str) -> str:
    """Strip tone diacritics + lowercase. Used for dedup checks against
    existing vocab entries (homonyms with different tone marks count as
    separate entries; same-tone same-text duplicates are skipped)."""
    nfd = unicodedata.normalize("NFD", s)
    return "".join(c for c in nfd if not unicodedata.combining(c)).lower()


def load_existing_pairs(vocab_src: str) -> set[tuple[str, str]]:
    """Return set of (awing_lower_no_tone, english_lower) already in
    vocab.dart so we can skip exact duplicates."""
    seen = set()
    for m in re.finditer(
        r"""AwingWord\(\s*awing:\s*['"]([^'"]+)['"][^)]*english:\s*['"]([^'"]+)['"]""",
        vocab_src,
    ):
        seen.add((_norm_awing(m.group(1)), m.group(2).lower().strip()))
    return seen


def apply_added(vocab_src: str, additions: list[dict]) -> tuple[str, int]:
    """Append a `bibleVerifiedExtras` list (or extend if already present)
    with the new AwingWord entries. Inserts the list at end of file
    just before the closing of the global declarations area."""
    if not additions:
        return vocab_src, 0

    existing_pairs = load_existing_pairs(vocab_src)
    new_entries = []
    skipped = 0
    for c in additions:
        awing = c["awing"].strip()
        english = c["english"].strip()
        key = (_norm_awing(awing), english.lower())
        if key in existing_pairs:
            skipped += 1
            continue
        # Build the AwingWord literal
        # category guess: 'family' if english has father/mother/etc, 'descriptive' else
        category = "things"
        el = english.lower()
        if any(k in el for k in ["father", "mother", "child", "son", "daughter",
                                  "brother", "sister", "elder", "family", "uncle",
                                  "aunt", "grandfather", "grandmother", "ancestor"]):
            category = "family"
        elif any(k in el for k in ["go ", "come", "eat", "drink", "say", "speak",
                                    "see", "hear", "give", "take", "make", "do "]):
            category = "actions"
        notes = c.get("notes", "").strip()
        ref = c.get("usfm", "").replace("_", ".") or c.get("context", "")
        comment_bits = []
        if ref:
            comment_bits.append(f"bible:{ref}")
        if c.get("reviewer"):
            comment_bits.append(f"reviewer={c['reviewer']}")
        if notes:
            comment_bits.append(notes[:80])
        comment = " // " + "; ".join(comment_bits) if comment_bits else ""
        new_entries.append(
            f"  AwingWord(awing: {_dart_literal(awing)}, "
            f"english: {_dart_literal(english)}, "
            f"category: '{category}', difficulty: 1),{comment}"
        )

    if not new_entries:
        return vocab_src, skipped

    # Insert into existing section or create new one at file end
    if BIBLE_SECTION_MARKER in vocab_src:
        before, after = vocab_src.split(BIBLE_SECTION_END, 1)
        vocab_src = before.rstrip() + "\n" + "\n".join(new_entries) + "\n" + BIBLE_SECTION_END + after
    else:
        block = [
            "",
            BIBLE_SECTION_MARKER,
            "// Native-speaker-verified entries from Bible word-alignment review.",
            "// Each entry comes from corpus/word_level/<CHAPTER>/index.html where",
            "// Dr. Sama (or another reviewer) listened to the audio + verified the",
            "// English meaning. Source ref recorded in the trailing comment.",
            "final List<AwingWord> bibleVerifiedExtras = [",
            *new_entries,
            "];",
            BIBLE_SECTION_END,
            "",
        ]
        vocab_src = vocab_src.rstrip() + "\n" + "\n".join(block) + "\n"
    return vocab_src, skipped


def apply_fixed(vocab_src: str, fixes: list[dict], dry_run: bool = False) -> tuple[str, int, list[str]]:
    """For each fix, find the FIRST AwingWord whose awing matches
    (NFD-normalized) and update the english value. Reports ambiguous
    cases (multiple matches with different glosses) without changing."""
    changed = 0
    warnings: list[str] = []
    for c in fixes:
        target_awing_norm = _norm_awing(c["awing"].strip())
        new_english = c["english"].strip()
        # Find candidates
        matches = []
        for m in re.finditer(
            r"""(AwingWord\(\s*awing:\s*)(['"])([^'"]+)\2([^)]*english:\s*)(['"])([^'"]+)\5""",
            vocab_src,
        ):
            if _norm_awing(m.group(3)) == target_awing_norm:
                matches.append((m.start(), m.end(), m.group(0), m.group(6)))
        if not matches:
            warnings.append(f"fix: '{c['awing']}' -> '{new_english}': NO existing match in vocab.dart")
            continue
        # Distinct english values among matches
        distinct = {x[3] for x in matches}
        if len(distinct) > 1:
            warnings.append(
                f"fix: '{c['awing']}' has {len(matches)} matches with {len(distinct)} different glosses: "
                + ", ".join(repr(d) for d in distinct)
                + " -- update SKIPPED (resolve homonyms manually)"
            )
            continue
        start, end, original, old_english = matches[0]
        if old_english == new_english:
            continue  # already correct, no-op
        if dry_run:
            warnings.append(f"DRY-RUN fix: '{c['awing']}' english '{old_english}' -> '{new_english}'")
            changed += 1
            continue
        replacement = original.replace(
            f"english: {_dart_literal(old_english)}",
            f"english: {_dart_literal(new_english)}",
            1,
        )
        # Fallback: original may have used double quotes for english; rebuild conservatively
        if replacement == original:
            replacement = re.sub(
                r"english:\s*(['\"])[^'\"]+\1",
                f"english: {_dart_literal(new_english)}",
                original,
                count=1,
            )
        vocab_src = vocab_src[:start] + replacement + vocab_src[end:]
        changed += 1
    return vocab_src, changed, warnings


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("corrections_path",
                    help="Path to corrections_<CHAPTER>.json exported from the viewer.")
    ap.add_argument("--dry-run", action="store_true",
                    help="Print what would change without writing vocab.dart.")
    ap.add_argument("--no-archive", action="store_true",
                    help="Don't move the corrections file into contributions/word_corrections/applied/ after success.")
    args = ap.parse_args()

    corr_path = Path(args.corrections_path)
    if not corr_path.exists():
        print(f"ERROR: corrections file not found: {corr_path}")
        return 1

    payload = json.loads(corr_path.read_text(encoding="utf-8"))
    chapter = payload.get("chapter_id", "?")
    reviewer = payload.get("reviewer", "?")
    raw_corrs = payload.get("corrections", [])
    print(f"Chapter: {chapter}  Reviewer: {reviewer}  Corrections: {len(raw_corrs)}")

    # Allowlist filter + bucket by status
    verified, added, fixed = [], [], []
    rejected = 0
    for c in raw_corrs:
        status = c.get("status", "")
        if status == "verified":
            verified.append(c)
            continue
        # added or fixed require english
        ok, why = _allowlist_ok(c.get("awing", ""), c.get("english", ""))
        if not ok:
            print(f"  REJECT [{c.get('awing','?')}]: {why}")
            rejected += 1
            continue
        if status == "added":
            added.append(c)
        elif status == "fixed":
            fixed.append(c)
        else:
            print(f"  REJECT [{c.get('awing','?')}]: unknown status {status!r}")
            rejected += 1

    print(f"  verified: {len(verified)}, added: {len(added)}, fixed: {len(fixed)}, rejected: {rejected}")

    if not added and not fixed:
        print("Nothing to write to vocab.dart.")
        if not args.dry_run:
            _archive(corr_path, args.no_archive, chapter)
        return 0

    vocab_src = VOCAB_DART.read_text(encoding="utf-8")
    if not args.dry_run:
        bak = VOCAB_DART.with_suffix(".dart.bak_word_corrections")
        shutil.copy(VOCAB_DART, bak)
        print(f"  backup -> {bak.relative_to(REPO)}")

    new_src = vocab_src
    new_src, fixed_count, fix_warnings = apply_fixed(new_src, fixed, dry_run=args.dry_run)
    for w in fix_warnings:
        print(f"  {w}")
    new_src, added_skipped = apply_added(new_src, added)
    added_written = len(added) - added_skipped

    if args.dry_run:
        print(f"\n[DRY-RUN] would add: {added_written} (skip {added_skipped} dupes), fix: {fixed_count}")
        return 0

    if new_src != vocab_src:
        VOCAB_DART.write_text(new_src, encoding="utf-8")
        print(f"\nWrote vocab.dart: +{added_written} added, {fixed_count} fixed, {added_skipped} skipped (dupes)")
    else:
        print("\nNo net changes to vocab.dart.")

    _archive(corr_path, args.no_archive, chapter)
    return 0


def _archive(corr_path: Path, no_archive: bool, chapter: str):
    if no_archive:
        return
    ARCHIVE_DIR.mkdir(parents=True, exist_ok=True)
    ts = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    dest = ARCHIVE_DIR / f"{chapter}_{ts}_{corr_path.name}"
    shutil.move(str(corr_path), str(dest))
    print(f"  archived corrections -> {dest.relative_to(REPO)}")


if __name__ == "__main__":
    sys.exit(main())
