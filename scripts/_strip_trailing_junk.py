#!/usr/bin/env python3
"""Defensive trailing-junk stripper.

Session 49c documented a class of bug where Edit/Write tool calls (and
sometimes OneDrive sync) leave hundreds-to-thousands of trailing NUL
bytes after a file write. The bytes are invisible to most editors but
cause Dart compile errors like:

  lib/data/awing_vocabulary.dart:N:M: Error: The control character
  U+0000 can only be used in strings and comments.

Any script that writes lib/data/*.dart should call strip_trailing_junk()
on the file after the write. Cheap (~5ms even on 1MB files), invisible
when no junk exists.
"""
from pathlib import Path

def strip_trailing_junk(path: Path) -> int:
    """Remove trailing NUL bytes / spaces / tabs / CR / LF (except a
    single final LF). Returns the number of junk bytes removed."""
    p = Path(path)
    data = p.read_bytes()
    cleaned = data.rstrip(b"\x00 \t\r\n") + b"\n"
    removed = len(data) - len(cleaned)
    if removed > 0:
        p.write_bytes(cleaned)
    return removed
