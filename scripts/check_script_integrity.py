#!/usr/bin/env python3
"""Catch truncated build scripts before they silently do nothing.

Why this exists
---------------
scripts/sync_recordings.py ended mid-token at

    args = parser.parse_a

from commit 2dd032fa (2026-06-02) until 2026-10-05. The file had grown
701 -> 743 lines and lost its last 11 lines in a truncated write.

Nothing caught it for four months, because that fragment is VALID
PYTHON -- an attribute access on `parser`. py_compile passes. The import
passes. The failure is an AttributeError raised at run time before the
script prints its first line, so build_and_run.bat saw a non-zero exit
with no output and printed its generic "common causes" list, which named
ffmpeg and the network. The real cause was neither, and step [1b/7]
silently synced nothing for four months.

What this checks
----------------
A truncated write loses the trailing newline. That one byte is a
reliable signature and costs nothing to test: across all 103 scripts in
this repo the check has zero false positives.

It also compiles each file, which catches the louder truncations that do
break syntax (the recurring Edit-tool pattern documented in Sessions
49c / 60 / 61+).

Exit 0 = clean, 1 = something is damaged.
"""
import glob
import os
import py_compile
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))


def main():
    truncated, uncompilable = [], []

    for path in sorted(glob.glob(os.path.join(SCRIPT_DIR, '*.py'))):
        if os.path.getsize(path) == 0:
            continue
        rel = os.path.relpath(path, os.path.dirname(SCRIPT_DIR))

        with open(path, 'rb') as f:
            f.seek(-1, os.SEEK_END)
            if f.read(1) not in (b'\n', b'\r'):
                with open(path, 'r', encoding='utf-8', errors='replace') as t:
                    last = t.read().splitlines()[-1][-60:]
                truncated.append((rel, last))

        try:
            py_compile.compile(path, doraise=True, quiet=2)
        except Exception as e:
            uncompilable.append((rel, str(e)[:120]))

    if not truncated and not uncompilable:
        print('       All build scripts intact.')
        return 0

    print()
    print('=' * 66)
    print('  ERROR: a build script looks truncated.')
    print('=' * 66)
    for rel, last in truncated:
        print(f'  {rel}')
        print(f'      no trailing newline; last line ends: ...{last!r}')
    for rel, err in uncompilable:
        print(f'  {rel}')
        print(f'      does not compile: {err}')
    print()
    print('  A truncated script can still be valid Python and will then')
    print('  fail at run time with no output, which is how sync_recordings.py')
    print('  synced nothing for four months. Restore it from git before')
    print('  building:')
    print('      git log --oneline -- <file>')
    print('      git show <commit>:<file> | tail -20')
    print('=' * 66)
    return 1


if __name__ == '__main__':
    sys.exit(main())
