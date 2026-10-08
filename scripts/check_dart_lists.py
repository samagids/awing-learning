#!/usr/bin/env python3
"""Structural check on the Dart data files the merge scripts edit.

flutter analyze caught what I did not: commenting out a row that also
closes its list ( `...difficulty: 1)];` ) removes the list's "]" and the
file stops compiling. Two lists broke that way, bodyParts and numbers,
and the error surfaced 500 seconds into an analyze run on the user's
machine rather than here.

This is the cheap version of that check, runnable in a second after any
scripted edit:

It checks exactly one thing: no commented-out row carries a `];` list
terminator without the terminator being restored on the line below.
"""
import re, sys

FILES = ["lib/data/awing_vocabulary.dart",
         "lib/screens/medium/sentences_screen.dart"]
OPEN_LIST = re.compile(r"^\s*(?:const|final)\s+(?:List<\w+>\s+)?(\w+)\s*=\s*\[")


def check(path):
    """One check, the one that actually broke the build.

    An earlier version also counted brackets and matched list declarations
    against closing lines. Both produced false alarms on this file - string
    literals full of apostrophes, multi-line constructors, lists closed on
    the same line as their last element - and a check that cries wolf gets
    ignored, which is worse than no check. flutter analyze is the authority
    on whether the Dart compiles; this exists only to catch the specific
    scripted-edit mistake in one second instead of eight minutes.
    """
    bad = []
    try:
        lines = open(path, encoding="utf-8").read().split("\n")
    except FileNotFoundError:
        return [f"{path}: missing"]
    for i, l in enumerate(lines):
        if not l.lstrip().startswith("//"):
            continue
        if not re.search(r"\)\s*\]\s*;", l):
            continue
        # The row carried its list's terminator. That is only safe if the
        # terminator was put back on a following line.
        nxt = ""
        for j in range(i + 1, min(i + 3, len(lines))):
            if lines[j].strip():
                nxt = lines[j].strip()
                break
        if nxt != "];":
            bad.append(f"{path}:{i + 1}: a commented-out row carries the list "
                       f"terminator ']' and nothing closes the list below it")
    return bad


def main():
    problems = []
    for f in FILES:
        problems += check(f)
    if problems:
        print("STRUCTURAL PROBLEMS:")
        for p in problems:
            print("  " + p)
        sys.exit(1)
    print("dart data files: lists closed, brackets balanced")


if __name__ == "__main__":
    main()
