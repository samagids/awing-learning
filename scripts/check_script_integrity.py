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
import re
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))


def _build_path_scripts():
    """The scripts build_and_run.bat actually invokes.

    A defect in one of those must fail the build. A defect in a diagnostic
    or one-off script is worth reporting but must not block shipping - the
    first run of the undefined-name check found a real one in
    build_bible_parallel.py, a Bible-corpus tool that has not been part of
    this app since v1.12.3+59.
    """
    bat = os.path.join(SCRIPT_DIR, 'build_and_run.bat')
    names = set()
    try:
        with open(bat, encoding='utf-8', errors='replace') as f:
            for m in re.finditer(r'python\s+scripts.([A-Za-z0-9_]+\.py)', f.read()):
                names.add(m.group(1))
    except OSError:
        pass
    return names


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

    # py_compile is not enough. On 2026-10-05 a patch to generate_images.py
    # replaced audio_key() and ran to the next 'def', swallowing the
    # ENGLISH_SLUG_MAX constant that sat between the two functions. The file
    # still compiled and still ended with a newline, so both checks above
    # passed, and the build died at [4/7] with
    #     NameError: name 'ENGLISH_SLUG_MAX' is not defined
    # pyflakes catches exactly this, in milliseconds, without importing the
    # module (which would pull in torch).
    undefined = []
    try:
        from pyflakes.api import check as _pf_check
        from pyflakes.reporter import Reporter as _PfReporter
        import io as _io

        for path in sorted(glob.glob(os.path.join(SCRIPT_DIR, '*.py'))):
            if os.path.getsize(path) == 0:
                continue
            out, err = _io.StringIO(), _io.StringIO()
            try:
                with open(path, encoding='utf-8', errors='replace') as f:
                    src = f.read()
                _pf_check(src, path, _PfReporter(out, err))
            except Exception:
                continue
            for line in out.getvalue().splitlines():
                if 'undefined name' in line:
                    undefined.append(
                        os.path.relpath(line.split(':')[0],
                                        os.path.dirname(SCRIPT_DIR))
                        + ':' + ':'.join(line.split(':')[1:]).strip())
    except ImportError:
        print('       (pyflakes not installed - skipping the undefined-name '
              'check; pip install pyflakes)')

    build_path = _build_path_scripts()
    blocking = [u for u in undefined
                if os.path.basename(u.split(':')[0]) in build_path]
    advisory = [u for u in undefined if u not in blocking]

    if advisory:
        print('       NOTE: undefined names in scripts the build does not run:')
        for u in advisory:
            print(f'         {u}')

    if not truncated and not uncompilable and not blocking:
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
    for u in blocking:
        print(f'  {u}')
        print('      undefined name - a constant or import was probably lost')
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
