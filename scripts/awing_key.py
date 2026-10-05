#!/usr/bin/env python3
"""The ONE Awing -> filename key derivation. Port of Dart's
PronunciationService._audioKey(), kept byte-identical to it.

Why this file exists
--------------------
There were three derivations in this repo and two of them disagreed with
the app:

    Dart  PronunciationService._audioKey : strips every non-[a-z0-9]
    Python _audio_key (manifest/recordings): re.sub(r"[^a-zA-Z0-9_-]+","_")

So Python wrote `afae_apimne.opus` while the app asked for `afaeapimne`.
119 of 396 clip keys on disk contained a character the app's key function
can never produce, which is why recorded, converted, shipped audio was
unreachable.

Dart also deleted any pre-composed letter missing from its map, because
the final strip is a catch-all. Dropping a leftover combining mark is
right ('kə̌' -> 'ke'); deleting a whole letter is not. 'apʉə' keyed to
'ape' and played a different word's recording.

Change this file and the Dart function together, never one alone.
"""
import re

_TONE = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ǎ': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ě': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ǐ': 'i',
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'ǒ': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ǔ': 'u',
}

# Order matters: the accented forms must go before the bare letter.
_SPECIAL = [
    ('ɛ́', 'e'), ('ɛ̂', 'e'), ('ɛ̌', 'e'), ('ɛ', 'e'),
    ('ə́', 'e'), ('ə̂', 'e'), ('ə̌', 'e'), ('ə', 'e'),
    ('ɔ́', 'o'), ('ɔ̂', 'o'), ('ɔ̌', 'o'), ('ɔ', 'o'),
    ('ɨ́', 'i'), ('ɨ̂', 'i'), ('ɨ̌', 'i'), ('ɨ', 'i'),
    ('ŋ', 'ng'),
]

# Pre-composed letters that reach the end otherwise. Counted from
# lib/data, not guessed. Some are OCR damage (Greek ε for ɛ; ł, ø, ğ) but
# a sensible base letter still beats deleting the character.
_EXTRA = [
    ('ʃ', 'sh'), ('ɣ', 'gh'),
    ('ń', 'n'),
    ('ü', 'u'), ('ʉ', 'u'), ('ū', 'u'), ('ŭ', 'u'),
    ('ś', 's'), ('š', 's'),
    ('ä', 'a'), ('ā', 'a'), ('ă', 'a'), ('ạ', 'a'),
    ('ō', 'o'), ('õ', 'o'), ('ø', 'o'),
    ('ī', 'i'),
    ('ē', 'e'), ('ĕ', 'e'), ('ε', 'e'), ('έ', 'e'),
    ('ł', 'l'), ('ğ', 'g'),
]

# Glottal stop and modifier apostrophe join the plain apostrophe; the
# aspiration modifier carries no segment.
_DROP = ("'", '’', '‘', 'ʼ', 'ʔ', 'ʰ')


def audio_key(awing_word):
    """Awing text -> the filename key the app looks up. Never returns
    None; an empty result means the input had no usable letters."""
    if not awing_word:
        return ''
    key = str(awing_word).lower()
    for src, dst in _TONE.items():
        key = key.replace(src, dst)
    for src, dst in _SPECIAL:
        key = key.replace(src, dst)
    for src, dst in _EXTRA:
        key = key.replace(src, dst)
    for ch in _DROP:
        key = key.replace(ch, '')
    # Everything left, spaces included, goes. The app does exactly this,
    # so a space must NOT become '_'.
    return re.sub(r'[^a-z0-9]', '', key)


if __name__ == '__main__':
    import sys
    for arg in sys.argv[1:]:
        print(f'{arg!r} -> {audio_key(arg)!r}')
