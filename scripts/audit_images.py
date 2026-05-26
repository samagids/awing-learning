#!/usr/bin/env python3
"""audit_images.py — find vocabulary entries with no corresponding PNG.

Image keys are computed via image_key(awing, english) — same convention
as scripts/generate_images.py. Output: image_gap_report.json + console
summary.
"""

import re
import unicodedata
import os
import json
import hashlib
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VOCAB = os.path.join(REPO_ROOT, 'lib', 'data', 'awing_vocabulary.dart')
IMG_DIR = os.path.join(
    REPO_ROOT,
    'android', 'install_time_assets', 'src', 'main', 'assets',
    'images', 'vocabulary',
)
REPORT = os.path.join(REPO_ROOT, 'image_gap_report.json')
ENGLISH_SLUG_MAX = 32

# MUST match scripts/generate_images.py::audio_key() AND
# lib/services/image_service.dart::audioKey() byte-for-byte.
#
# Critical: unknown non-ASCII chars (e.g. ʉ U+0289) are DELETED here,
# not replaced by '_'. Mismatching this in the audit produces false
# positives — looking for af_e__... when the real file is afe__....
_CHAR_MAP = {
    'ɛ': 'e',
    'ɔ': 'o',
    'ə': 'e',
    'ɨ': 'i',
    'ŋ': 'ng',
    "'": '', '"': '', "’": '', "‘": '',
    # Tone-marked Latin vowels
    'á': 'a', 'à': 'a', 'â': 'a', 'ǎ': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ě': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ǐ': 'i',
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'ǒ': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ǔ': 'u',
    # Pre-composed tone-marked Awing vowels
    'ɛ́': 'e', 'ɛ̂': 'e', 'ɛ̌': 'e',
    'ə́': 'e', 'ə̂': 'e', 'ə̌': 'e',
    'ɔ́': 'o', 'ɔ̂': 'o', 'ɔ̌': 'o',
    'ɨ́': 'i', 'ɨ̂': 'i', 'ɨ̌': 'i',
}


def audio_key(awing):
    if not awing:
        return ''
    result = ''
    for ch in awing:
        result += _CHAR_MAP.get(ch, ch)
    result = result.lower()
    # Critical: DELETE non-[a-z0-9], don't replace with '_'.
    result = re.sub(r'[^a-z0-9]', '', result)
    return result or '_'


def english_slug(english):
    s = english.lower()
    s = unicodedata.normalize('NFD', s)
    s = ''.join(c for c in s if unicodedata.category(c) != 'Mn')
    s = re.sub(r'[^a-z0-9]+', '_', s)
    s = s.strip('_')
    if not s:
        s = hashlib.md5(english.encode('utf-8')).hexdigest()[:8]
    if len(s) > ENGLISH_SLUG_MAX:
        s = s[:ENGLISH_SLUG_MAX].rstrip('_')
    return s


def image_key(awing, english):
    return f"{audio_key(awing)}__{english_slug(english)}"


def dart_unescape(s):
    # Undo Dart's single-quoted-string escapes: \' \" \\ \n \t
    return (s
            .replace("\\'", "'")
            .replace('\\"', '"')
            .replace('\\n', '\n')
            .replace('\\t', '\t')
            .replace('\\\\', '\\'))


def main():
    with open(VOCAB, 'r', encoding='utf-8') as f:
        txt = f.read()

    pattern = re.compile(
        r"AwingWord\s*\(\s*"
        r"awing:\s*(?P<q1>['\"])(?P<awing>(?:\\.|(?!(?P=q1)).)*?)(?P=q1)"
        r"\s*,\s*"
        r"english:\s*(?P<q2>['\"])(?P<english>(?:\\.|(?!(?P=q2)).)*?)(?P=q2)",
        re.DOTALL,
    )

    entries = []
    for m in pattern.finditer(txt):
        a = dart_unescape(m.group('awing'))
        e = dart_unescape(m.group('english'))
        entries.append((a, e))

    print(f'Parsed {len(entries)} AwingWord entries')

    by_key = {}
    for a, e in entries:
        k = image_key(a, e)
        if k not in by_key:
            by_key[k] = (a, e)
    print(f'  {len(by_key)} unique image_keys')

    existing = set()
    if os.path.isdir(IMG_DIR):
        for fn in os.listdir(IMG_DIR):
            if fn.endswith('.png'):
                existing.add(fn[:-4])
    print(f'  {len(existing)} PNG files on disk')

    missing = sorted(k for k in by_key if k not in existing)
    print(f'\n=== MISSING IMAGES: {len(missing)} ===')
    for k in missing[:30]:
        a, e = by_key[k]
        print(f'  {k}.png  <-  {a!r} = {e!r}')
    if len(missing) > 30:
        print(f'  ... and {len(missing) - 30} more')

    orphans = sorted(p for p in existing if p not in by_key)
    print(f'\n=== ORPHAN PNGS: {len(orphans)} ===')

    with open(REPORT, 'w', encoding='utf-8') as f:
        json.dump({
            'parsed_entries': len(entries),
            'unique_image_keys': len(by_key),
            'existing_pngs': len(existing),
            'missing_count': len(missing),
            'orphan_count': len(orphans),
            'missing': [
                {'key': k, 'awing': by_key[k][0], 'english': by_key[k][1]}
                for k in missing
            ],
        }, f, indent=2, ensure_ascii=False)
    print(f'\nReport -> {REPORT}')


if __name__ == '__main__':
    sys.exit(main() or 0)
