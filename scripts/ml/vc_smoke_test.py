#!/usr/bin/env python3
"""
Voice-conversion smoke test for the "Bible pronunciation in Dr. Sama's
voice" idea.

What this does
--------------
1. Loads the MAT_001 word-alignment manifest produced by
   scripts/ml/word_align_chapter.py.
2. Picks N high-confidence words (default 10).
3. Loads kNN-VC (bshall/knn-vc) via torch.hub. kNN-VC is the simplest
   VC tool to set up -- it's pip-free, downloads ~250 MB of model
   weights on first call, and reuses WavLM features.
4. Builds a "matching set" of voice references from Dr. Sama's
   recordings (training_data/recordings/*.wav).
5. For each selected word, converts the Bible-narrator audio to Dr.
   Sama's timbre. Saves the output WAV.
6. ALSO generates the same word via Edge TTS (the current production
   path) so the viewer can A/B/C compare.
7. Emits an HTML side-by-side comparison page.

Usage
-----
    # End-to-end (preferred):
    python scripts/ml/vc_smoke_test.py both MAT_001

    # Just the VC + Edge TTS (no viewer yet):
    python scripts/ml/vc_smoke_test.py run MAT_001 --max-words 10

    # Just rebuild the viewer from existing outputs:
    python scripts/ml/vc_smoke_test.py viewer MAT_001

Picking the verdict
-------------------
The HTML viewer offers three audio bars per word:
  - Bible (original source)             — native pronunciation, narrator voice
  - VC output                            — Bible pronunciation, your voice
  - Edge TTS Swahili                     — current production approximation

A row of rating buttons records which one sounds MOST LIKE CORRECT
AWING. Ratings save to localStorage + download as JSON. Goal: validate
whether VC preserves Awing pronunciation well enough to commit to the
OpenVoice v2 full rollout.

Notes
-----
- kNN-VC is the "easy mode" VC tool. If results are promising but
  voice quality feels mediocre, OpenVoice v2 is the high-quality
  upgrade -- same pipeline, different model.
- License: the VC OUTPUT is your voice + Bible-derived content/timing.
  Don't ship the output until CABTAL permission is sorted (Session 56).
- All audio paths in the HTML are relative; the viewer works via
  file:// URLs.
"""

import argparse
import json
import os
import re
import sys
import unicodedata
from html import escape
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
ALIGN_BASE = REPO / "corpus" / "word_level"
NATIVE_RECS_DIR = REPO / "training_data" / "recordings"
NATIVE_MANIFEST = NATIVE_RECS_DIR / "manifest.json"


def _ensure_venv():
    if sys.prefix != sys.base_prefix:
        return
    for py in (REPO / "venv" / "Scripts" / "python.exe",
               REPO / "venv" / "bin" / "python",
               Path.home() / "awing_venv" / "bin" / "python"):
        if py.exists():
            os.execv(str(py), [str(py)] + sys.argv)


def _slug(text):
    nfd = unicodedata.normalize("NFD", text)
    s = "".join(c for c in nfd if not unicodedata.combining(c))
    s = (s.replace("ɛ", "e").replace("ɔ", "o").replace("ə", "e")
          .replace("ɨ", "i").replace("ŋ", "ng").replace("ɣ", "gh"))
    return re.sub(r"[^a-zA-Z0-9]", "", s).lower() or "x"


_vocab_keys_cache = None
def _vocab_keys():
    """Return frozenset of NFD-stripped lowercase Awing forms that exist
    in lib/data/awing_vocabulary.dart. Used by --only-in-vocab to skip
    words that aren't part of the app's PDF-verified word list."""
    global _vocab_keys_cache
    if _vocab_keys_cache is not None:
        return _vocab_keys_cache
    import unicodedata as _u
    vocab_path = REPO / "lib" / "data" / "awing_vocabulary.dart"
    if not vocab_path.exists():
        _vocab_keys_cache = frozenset()
        return _vocab_keys_cache
    text = vocab_path.read_text(encoding="utf-8")
    import re as _re
    keys = set()
    for m in _re.finditer(
        r"""AwingWord\(\s*awing:\s*['"]([^'"]+)['"]""", text):
        w = m.group(1).strip()
        # Normalize: NFD-strip + lowercase + strip trailing punctuation
        nfd = _u.normalize("NFD", w).lower()
        clean = "".join(c for c in nfd if not _u.combining(c))
        clean = _re.sub(r"^[^a-zɛɔəɨŋɣ]+|[^a-zɛɔəɨŋɣ]+$", "", clean)
        if clean:
            keys.add(clean)
        # Also store any pluralForm
    for m in _re.finditer(
        r"""pluralForm:\s*['"]([^'"]+)['"]""", text):
        w = m.group(1).strip()
        nfd = _u.normalize("NFD", w).lower()
        clean = "".join(c for c in nfd if not _u.combining(c))
        clean = _re.sub(r"^[^a-zɛɔəɨŋɣ]+|[^a-zɛɔəɨŋɣ]+$", "", clean)
        if clean:
            keys.add(clean)
    _vocab_keys_cache = frozenset(keys)
    return _vocab_keys_cache


def _is_in_vocab(word: str) -> bool:
    """True if `word` (with surrounding punctuation stripped) matches an
    Awing form in vocab.dart. Tone marks ignored for matching."""
    import unicodedata as _u
    import re as _re
    nfd = _u.normalize("NFD", word).lower()
    clean = "".join(c for c in nfd if not _u.combining(c))
    clean = _re.sub(r"^[^a-zɛɔəɨŋɣ]+|[^a-zɛɔəɨŋɣ]+$", "", clean)
    return clean in _vocab_keys()


def _is_proper_noun(word: str) -> bool:
    """Heuristic: drop biblical proper nouns from the smoke test set.
    True if the word looks like Aminadab / Jotan / Azolə / Salmon / Yeso --
    i.e. starts with an uppercase letter, contains only ASCII letters
    (no Awing-only graphemes ɛ ɔ ə ɨ ŋ ɣ), and carries no tone marks
    on lowercase vowels. Trailing punctuation is stripped first.
    The goal isn't perfect linguistic classification -- it's "skip the
    list of biblical names that dominate the genealogy chapters" so
    the listener evaluates VC on real Awing words instead."""
    import unicodedata as _u
    stripped = word.strip(",.;:!?\"")
    if not stripped:
        return False
    # First character must be uppercase letter
    first = stripped[0]
    if not first.isalpha() or first != first.upper():
        return False
    # Check for any Awing-only graphemes or tone diacritics
    for ch in _u.normalize("NFD", stripped):
        if ch in "ɛɔəɨŋɣÆÊÔÛɃƎƷ":
            return False
        # Combining tone marks
        if ch in "\u0301\u0300\u0302\u030C\u0303":
            return False
    # All ASCII letters + no tones = probably a transliterated proper noun
    return all(ord(c) < 128 or c == "'" for c in stripped)


def _feature_tags(word: str) -> list[str]:
    """Return the linguistic-feature labels the word exercises. Used by
    the stratified picker AND surfaced in the viewer so the listener
    knows what each row is testing."""
    import unicodedata as _u
    tags = []
    nfd = _u.normalize("NFD", word)
    chars = list(nfd)
    # Tone: 5 combining diacritics
    tone_marks = {"\u0301": "tone:high", "\u0300": "tone:low",
                  "\u0302": "tone:falling", "\u030C": "tone:rising"}
    found_tone = False
    for c in chars:
        if c in tone_marks:
            tags.append(tone_marks[c])
            found_tone = True
    if not found_tone:
        tags.append("tone:mid")
    # Glottal stop
    if any(c in word for c in "\u02bc\u2019\u2018'"):
        tags.append("glottal")
    # /ɣ/ voiced velar fricative -> spelled "gh"
    if "gh" in word.lower() or "ɣ" in word:
        tags.append("gh")
    # Prenasalized clusters
    lw = word.lower()
    for clus in ("mb", "nd", "nj", "nk", "nt", "ng", "ny", "nz", "ns"):
        if clus in lw:
            tags.append(f"prenasal:{clus}")
            break
    # Special vowels (Awing-only)
    for v, lbl in (("ɛ", "vowel:ɛ"), ("ɔ", "vowel:ɔ"),
                    ("ə", "vowel:ə"), ("ɨ", "vowel:ɨ")):
        if v in word:
            tags.append(lbl)
    # Polysyllabic heuristic: vowel runs as proxy for syllable count
    vcount = sum(1 for ch in nfd.lower() if ch in "aeiouɛɔəɨ")
    if vcount >= 3:
        tags.append("polysyll")
    return tags or ["plain"]


def _pick_words_confidence(manifest, max_words, exclude_names=True, only_in_vocab=False):
    """Original picker: top-N by confidence, deduped by word text.
    Used when --strategy=confidence (default for back-compat)."""
    import unicodedata as _u
    candidates = []
    for verse in manifest:
        for w in verse["words"]:
            dur = w["end_s"] - w["start_s"]
            if dur < 0.18 or dur > 1.5:
                continue
            if w["confidence"] < 0.55:
                continue
            if exclude_names and _is_proper_noun(w["word"]):
                continue
            if only_in_vocab and not _is_in_vocab(w["word"]):
                continue
            candidates.append({
                "usfm": verse["usfm"],
                "word_idx": w["word_idx"],
                "word": w["word"],
                "conf": w["confidence"],
                "clip": w["clip"],
                "dur": dur,
            })
    candidates.sort(key=lambda c: -c["conf"])
    seen = set()
    picked = []
    for c in candidates:
        norm = "".join(ch for ch in _u.normalize("NFD", c["word"].lower())
                        if not _u.combining(ch))
        if norm in seen:
            continue
        seen.add(norm)
        c["features"] = _feature_tags(c["word"])
        picked.append(c)
        if len(picked) >= max_words:
            break
    return picked


def _pick_words_stratified(manifest, max_words, exclude_names=True, only_in_vocab=False):
    """Stratified picker: spread `max_words` across linguistic feature
    classes so every tone, glottal stop case, /ɣ/, prenasalized cluster,
    special vowel, and polysyllabic word gets coverage. Lets the
    listener evaluate whether VC handles each case, not just the easy
    high-confidence words.

    Budget: roughly equal share per feature class up to max_words.
    Within a class, picks highest-confidence available words first,
    deduped by surface text. A word can contribute to multiple buckets
    (e.g. ŋgɔ̌ʼə̌ counts for tone:rising + glottal + prenasal + vowel:ɔ
    + vowel:ə) but is only picked ONCE; we just verify the bucket
    targets get filled overall.
    """
    import unicodedata as _u
    # Build all candidates with their feature tags
    candidates = []
    for verse in manifest:
        for w in verse["words"]:
            dur = w["end_s"] - w["start_s"]
            if dur < 0.18 or dur > 1.5:
                continue
            if w["confidence"] < 0.5:
                continue
            if exclude_names and _is_proper_noun(w["word"]):
                continue
            if only_in_vocab and not _is_in_vocab(w["word"]):
                continue
            tags = _feature_tags(w["word"])
            candidates.append({
                "usfm": verse["usfm"],
                "word_idx": w["word_idx"],
                "word": w["word"],
                "conf": w["confidence"],
                "clip": w["clip"],
                "dur": dur,
                "features": tags,
            })
    candidates.sort(key=lambda c: -c["conf"])

    # Define target feature classes + per-class budget
    feature_classes = [
        "tone:high", "tone:low", "tone:falling", "tone:rising", "tone:mid",
        "glottal", "gh",
        "vowel:ɛ", "vowel:ɔ", "vowel:ə", "vowel:ɨ",
        "prenasal:mb", "prenasal:nd", "prenasal:ng", "prenasal:nk",
        "polysyll",
    ]
    # Roughly equal budget; under-budget the abundant classes (mid tone)
    bias = {"tone:mid": 0.4, "tone:high": 1.2, "tone:low": 1.2}
    raw_budget = {cls: max(1, int(max_words * bias.get(cls, 1) / len(feature_classes)))
                  for cls in feature_classes}

    picked = []
    seen_words = set()
    used_class_count = {cls: 0 for cls in feature_classes}

    def _norm_key(w):
        return "".join(ch for ch in _u.normalize("NFD", w.lower())
                        if not _u.combining(ch))

    # Phase 1: each class gets its budget filled with the highest-conf
    # word that exercises that class
    for cls in feature_classes:
        for c in candidates:
            if used_class_count[cls] >= raw_budget[cls]:
                break
            if cls not in c["features"]:
                continue
            nk = _norm_key(c["word"])
            if nk in seen_words:
                # Already picked under another class; still counts for
                # this class's coverage
                used_class_count[cls] += 1
                continue
            seen_words.add(nk)
            picked.append(c)
            for f in c["features"]:
                if f in used_class_count:
                    used_class_count[f] += 1
            if len(picked) >= max_words:
                return picked

    # Phase 2: fill remainder with highest-confidence unseen words
    for c in candidates:
        if len(picked) >= max_words:
            break
        nk = _norm_key(c["word"])
        if nk in seen_words:
            continue
        seen_words.add(nk)
        picked.append(c)

    return picked


def _pick_words(manifest, max_words, strategy="confidence",
                exclude_names=True, only_in_vocab=False):
    if strategy == "stratified":
        return _pick_words_stratified(manifest, max_words,
                                       exclude_names=exclude_names,
                                       only_in_vocab=only_in_vocab)
    return _pick_words_confidence(manifest, max_words,
                                   exclude_names=exclude_names,
                                   only_in_vocab=only_in_vocab)


def _pick_voice_references(num_refs=12):
    """Return list of WAV paths from Dr. Sama's recordings for the
    kNN-VC matching set. Skips very short clips."""
    if not NATIVE_MANIFEST.exists():
        raise SystemExit(f"Missing {NATIVE_MANIFEST.relative_to(REPO)}")
    data = json.loads(NATIVE_MANIFEST.read_text(encoding="utf-8"))
    refs = []
    for entry in data:
        if entry.get("duration_s", 0) < 1.0:
            continue
        p = REPO / entry["wav_path"]
        if p.exists():
            refs.append(str(p))
        if len(refs) >= num_refs:
            break
    return refs


def _awing_to_speakable_proxy(text):
    """Import the canonical mapping from generate_audio_edge.py so the
    Edge TTS comparison uses the same phonetic rules as production."""
    import importlib.util
    spec = importlib.util.spec_from_file_location(
        "generate_audio_edge",
        REPO / "scripts" / "generate_audio_edge.py",
    )
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.awing_to_speakable(text)


def cmd_run(chapter_id, max_words, strategy="confidence", exclude_names=True, only_in_vocab=False):
    _ensure_venv()
    try:
        import torch
        import torchaudio
        import soundfile as sf
        import numpy as np
    except ImportError as e:
        print(f"ERROR: missing {e.name}. Install in your venv first.")
        return 1

    # ----- Source clip normalization for kNN-VC -----
    # kNN-VC's HiFiGAN can only handle feature sequences in a narrow
    # band. Empirically: clips ~0.4-0.8s succeed; clips < 0.4s fail
    # with "tensor dim 1 size N max 2880". Pad short clips with silence
    # on each side until they hit the floor. Also downmix to mono and
    # resample to 16 kHz to match WavLM's expected input.
    TARGET_SR = 16000
    MIN_DUR_S = 0.50  # pad if below
    MAX_DUR_S = 0.90  # trim if above
    def _normalize_source(src_path, dst_path):
        audio, sr = sf.read(str(src_path), dtype="float32")
        if audio.ndim > 1:
            audio = audio.mean(axis=1)
        if sr != TARGET_SR:
            audio_t = torch.from_numpy(audio).unsqueeze(0)
            audio_t = torchaudio.functional.resample(audio_t, sr, TARGET_SR)
            audio = audio_t.squeeze(0).numpy()
        n = len(audio)
        min_n = int(MIN_DUR_S * TARGET_SR)
        max_n = int(MAX_DUR_S * TARGET_SR)
        if n < min_n:
            pad = min_n - n
            left = pad // 2
            right = pad - left
            audio = np.concatenate(
                [np.zeros(left, dtype="float32"), audio,
                 np.zeros(right, dtype="float32")])
        elif n > max_n:
            # Center crop to MAX_DUR_S
            start = (n - max_n) // 2
            audio = audio[start:start + max_n]
        sf.write(str(dst_path), audio, TARGET_SR)
        return dst_path

    # ----- torchaudio.load <-> torchcodec workaround -----
    # On Windows + torch 2.11+, torchaudio.load() requires the optional
    # torchcodec package + FFmpeg shared libs that don't install cleanly
    # (Session 56 documented this). kNN-VC calls torchaudio.load()
    # internally, so we shim it to use soundfile + a tiny tensor wrap.
    # Output shape matches torchaudio's (channels, samples) at the file's
    # native sample rate. kNN-VC handles resampling downstream.
    _orig_torchaudio_load = torchaudio.load
    def _sf_torchaudio_load(path, normalize=True, **kwargs):
        audio, sr = sf.read(str(path), dtype="float32")
        # Force mono. kNN-VC choked on stereo inputs (samples appeared
        # to be 2x the expected count, breaking HiFiGAN chunking).
        if audio.ndim > 1:
            audio = audio.mean(axis=1)
        tensor = torch.from_numpy(audio).unsqueeze(0)
        return tensor, sr
    torchaudio.load = _sf_torchaudio_load
    print("(applied torchaudio.load -> soundfile shim for Windows compatibility)")

    align_dir = ALIGN_BASE / chapter_id
    manifest_path = align_dir / "manifest.json"
    if not manifest_path.exists():
        print(f"No manifest at {manifest_path.relative_to(REPO)}. Run "
              f"`word_align_chapter.py align {chapter_id}` first.")
        return 1

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    words = _pick_words(manifest, max_words, strategy=strategy, exclude_names=exclude_names, only_in_vocab=only_in_vocab)
    if not words:
        print("No high-confidence words found in manifest. Lower the threshold "
              "in _pick_words() or re-run alignment.")
        return 1
    name_note = " (names filtered)" if exclude_names else " (names included)"
    vocab_note = ""
    if only_in_vocab:
        n = len(_vocab_keys())
        vocab_note = f" (vocab.dart filter ON: {n} known Awing forms)"
    print(f"Selected {len(words)} words for smoke test "
          f"(strategy={strategy}){name_note}{vocab_note}:")
    for w in words:
        feat = "+".join(w.get("features", []))
        print(f"  {w['usfm']} '{w['word']:15s}' conf={w['conf']:.2f} dur={w['dur']:.2f}s  [{feat}]")

    refs = _pick_voice_references(num_refs=12)
    print(f"\nVoice references (Dr. Sama): {len(refs)} clips")
    if not refs:
        print("No voice references found. Aborting.")
        return 1

    # Load kNN-VC. First call downloads weights (~250 MB).
    print("\nLoading kNN-VC (bshall/knn-vc) -- first run downloads ~250 MB...")
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Device: {device}")
    try:
        knn_vc = torch.hub.load(
            "bshall/knn-vc",
            "knn_vc",
            prematched=True,
            trust_repo=True,
            pretrained=True,
            device=device,
        )
    except Exception as e:
        print(f"ERROR loading kNN-VC: {e}")
        print("Hint: this needs the venv to have torch + torchaudio installed.")
        return 1

    # Build the matching set once
    print("Building matching set from voice references...")
    matching_set = knn_vc.get_matching_set(refs)
    print(f"  matching set tensor: {matching_set.shape}")

    out_dir = align_dir / "vc_smoke"
    out_dir.mkdir(parents=True, exist_ok=True)
    vc_meta = []

    # Normalize all source clips to TARGET_SR mono + within
    # [MIN_DUR_S, MAX_DUR_S] before feeding kNN-VC. Bypasses the
    # "tensor dim 1 size N max 2880" HiFiGAN constraint.
    norm_dir = out_dir / "_normalized_sources"
    norm_dir.mkdir(parents=True, exist_ok=True)

    for i, w in enumerate(words, 1):
        source_path = align_dir / w["clip"]
        if not source_path.exists():
            print(f"  [{i}/{len(words)}] missing source {source_path.name}")
            continue
        try:
            norm_path = norm_dir / Path(w["clip"]).name
            _normalize_source(source_path, norm_path)
            query_seq = knn_vc.get_features(str(norm_path))
            out_wav = knn_vc.match(query_seq, matching_set, topk=4)
            vc_path = out_dir / f"{Path(w['clip']).stem}__vc.wav"
            sf.write(str(vc_path), out_wav.cpu().numpy(), 16000)
            print(f"  [{i}/{len(words)}] {w['word']:15s} -> {vc_path.name}")
            vc_meta.append({**w, "vc_clip": vc_path.name})
        except Exception as e:
            print(f"  [{i}/{len(words)}] {w['word']}: VC FAILED -- {e}")

    if not vc_meta:
        print("No VC outputs produced. Aborting Edge TTS step.")
        return 1

    # Edge TTS comparison
    print("\nGenerating Edge TTS comparison clips...")
    try:
        import asyncio
        import edge_tts
    except ImportError:
        print("  edge-tts not installed; skipping comparison clips.")
        edge_tts = None

    if edge_tts is not None:
        async def _gen_edge(text, out_path):
            speakable = _awing_to_speakable_proxy(text)
            # Use sw-TZ-DaudiNeural (man voice) at default rate/pitch
            com = edge_tts.Communicate(speakable, "sw-TZ-DaudiNeural",
                                        rate="-15%", pitch="-5Hz")
            await com.save(str(out_path))

        async def _run_all():
            for m in vc_meta:
                edge_path = out_dir / f"{Path(m['clip']).stem}__edge.mp3"
                try:
                    await _gen_edge(m["word"], edge_path)
                    m["edge_clip"] = edge_path.name
                    print(f"  edge -> {edge_path.name}")
                except Exception as e:
                    print(f"  edge FAILED for {m['word']}: {e}")

        asyncio.run(_run_all())

    # Save smoke-test manifest
    (out_dir / "smoke_manifest.json").write_text(
        json.dumps({"chapter_id": chapter_id, "items": vc_meta},
                   ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"\nSmoke manifest: {(out_dir / 'smoke_manifest.json').relative_to(REPO)}")
    return 0


def cmd_viewer(chapter_id):
    align_dir = ALIGN_BASE / chapter_id
    out_dir = align_dir / "vc_smoke"
    smoke_path = out_dir / "smoke_manifest.json"
    if not smoke_path.exists():
        print(f"No smoke manifest at {smoke_path.relative_to(REPO)}. Run "
              f"`vc_smoke_test.py run {chapter_id}` first.")
        return 1
    data = json.loads(smoke_path.read_text(encoding="utf-8"))
    items = data["items"]

    parts = []
    parts.append("<!DOCTYPE html><html><head><meta charset='utf-8'>")
    parts.append(f"<title>{chapter_id} voice-conversion A/B/C smoke test</title>")
    parts.append("""<style>
body{font-family:Georgia,serif;max-width:1200px;margin:1em auto;padding:0 1em;line-height:1.6;color:#222;background:#fafafa}
h1{font-size:1.4em;color:#333;border-bottom:2px solid #555;padding-bottom:0.3em}
.intro{background:#fff;padding:0.8em 1.2em;border-radius:6px;border:1px solid #ddd;margin-bottom:1em;font-size:0.92em}
.toolbar{position:sticky;top:0;background:#fff;border:1px solid #ccc;border-radius:6px;padding:0.5em 0.8em;margin:0.5em 0 1em 0;display:flex;gap:0.6em;align-items:center;z-index:10;box-shadow:0 2px 4px rgba(0,0,0,0.05)}
.toolbar button{padding:5px 12px;border:1px solid #888;background:#f0f0f0;border-radius:4px;cursor:pointer;font-size:0.9em}
.toolbar button.primary{background:#449944;color:#fff;border-color:#337733;font-weight:bold}
.stats{margin-left:auto;font-size:0.85em;color:#666}
table{width:100%;border-collapse:collapse;background:#fff;border-radius:6px;overflow:hidden;box-shadow:0 1px 3px rgba(0,0,0,0.08)}
th{background:#444;color:#fff;padding:0.6em 0.4em;text-align:left;font-size:0.9em}
td{padding:0.7em 0.5em;border-top:1px solid #eee;vertical-align:middle}
tr.rated-bible td{background:#f5fff5}
tr.rated-vc    td{background:#fff8e0}
tr.rated-edge  td{background:#f0f4ff}
tr.rated-equal td{background:#f8f8f8}
tr.rated-bad   td{background:#ffe4e4}
.awing{font-size:1.1em;font-weight:bold;color:#222}
.meta{font-size:0.75em;color:#888;font-family:monospace}
.feat{font-size:0.7em;color:#1f6fcc;margin-top:3px;font-family:monospace;font-weight:bold}
audio{width:200px;height:32px;display:block}
.rate-row{display:flex;gap:4px;flex-wrap:wrap}
.rate-row button{font-size:0.78em;padding:3px 7px;border:1px solid #999;background:#fff;border-radius:4px;cursor:pointer;color:#333}
.rate-row button.active{background:#449944;color:#fff;border-color:#337733;font-weight:bold}
.rate-row button[data-rating=vc].active{background:#cc9933;border-color:#996600}
.rate-row button[data-rating=edge].active{background:#3366cc;border-color:#1f4488}
.rate-row button[data-rating=equal].active{background:#666;border-color:#444}
.rate-row button[data-rating=bad].active{background:#cc4444;border-color:#883333}
</style></head><body>""")
    parts.append(f"<h1>{chapter_id} &mdash; Voice-Conversion Smoke Test</h1>")
    parts.append("""<div class='intro'>
<p><b>What you're hearing:</b></p>
<ul>
  <li><b>Bible (source)</b>: original CABTAL recording -- the native Awing pronunciation we want to preserve.</li>
  <li><b>VC output</b>: Bible audio re-rendered in Dr. Sama's voice via kNN-VC. Same pronunciation + tone, your timbre.</li>
  <li><b>Edge TTS</b>: what the app says today (Swahili neural voice + awing_to_speakable rules).</li>
</ul>
<p><b>What to rate</b>: for each word, click the audio buttons and pick which one sounds <i>most like the correct Awing word</i>. Pick <b>VC</b> if it preserves pronunciation but in your voice (the win we're testing for). Pick <b>Edge</b> if Edge TTS sounds equally good or better. Pick <b>None acceptable</b> if all three are unintelligible.</p>
<p>Results auto-save to browser storage and can be downloaded as JSON.</p>
</div>""")
    parts.append("""<div class='toolbar'>
<button id='btn-download' class='primary'>Download ratings (JSON)</button>
<button id='btn-clear'>Clear ratings</button>
<span class='stats' id='stats'>0 rated</span>
</div>""")
    parts.append("<table>")
    parts.append("<tr><th>#</th><th>Word</th><th>Bible (source)</th><th>VC (your voice)</th><th>Edge TTS</th><th>Best match</th></tr>")
    for i, item in enumerate(items, 1):
        src_rel  = f"../{item['clip']}"
        vc_rel   = item.get("vc_clip", "")
        edge_rel = item.get("edge_clip", "")
        parts.append(f"<tr data-idx='{i}' data-id='{escape(item['usfm'] + '_' + str(item.get('word_idx',0)))}'>")
        parts.append(f"<td>{i}</td>")
        feats = " ".join(escape(f) for f in item.get("features", []))
        parts.append(f"<td><div class='awing'>{escape(item['word'])}</div>"
                     f"<div class='meta'>{escape(item['usfm'])} &middot; conf={item['conf']:.2f}</div>"
                     f"<div class='feat'>{feats}</div></td>")
        parts.append(f"<td><audio controls preload='none' src='{escape(src_rel)}'></audio></td>")
        if vc_rel:
            parts.append(f"<td><audio controls preload='none' src='{escape(vc_rel)}'></audio></td>")
        else:
            parts.append("<td><i style='color:#999'>—</i></td>")
        if edge_rel:
            parts.append(f"<td><audio controls preload='none' src='{escape(edge_rel)}'></audio></td>")
        else:
            parts.append("<td><i style='color:#999'>—</i></td>")
        parts.append("<td><div class='rate-row'>"
                     "<button data-rating='bible'>Bible</button>"
                     "<button data-rating='vc'>VC</button>"
                     "<button data-rating='edge'>Edge</button>"
                     "<button data-rating='equal'>All good</button>"
                     "<button data-rating='bad'>None OK</button>"
                     "</div></td>")
        parts.append("</tr>")
    parts.append("</table>")

    parts.append("""<script>
const KEY = 'vc_smoke_ratings_""" + chapter_id + """';
let ratings = {};
try { ratings = JSON.parse(localStorage.getItem(KEY) || '{}'); } catch(e){}

function render() {
    document.querySelectorAll('tr[data-id]').forEach(tr => {
        const id = tr.dataset.id;
        const r = ratings[id];
        tr.className = '';
        if (r) tr.classList.add('rated-' + r);
        tr.querySelectorAll('.rate-row button').forEach(b => {
            b.classList.toggle('active', r && b.dataset.rating === r);
        });
    });
    const total = document.querySelectorAll('tr[data-id]').length;
    const rated = Object.keys(ratings).length;
    const counts = {bible:0,vc:0,edge:0,equal:0,bad:0};
    Object.values(ratings).forEach(r => counts[r] = (counts[r]||0)+1);
    document.getElementById('stats').textContent =
        `${rated}/${total} rated -- Bible: ${counts.bible}, VC: ${counts.vc}, Edge: ${counts.edge}, All good: ${counts.equal}, None OK: ${counts.bad}`;
}
function save() { localStorage.setItem(KEY, JSON.stringify(ratings)); render(); }

document.addEventListener('click', e => {
    const b = e.target.closest('.rate-row button');
    if (!b) return;
    const tr = b.closest('tr[data-id]');
    if (!tr) return;
    const id = tr.dataset.id;
    if (ratings[id] === b.dataset.rating) {
        delete ratings[id];
    } else {
        ratings[id] = b.dataset.rating;
    }
    save();
});

document.getElementById('btn-download').addEventListener('click', () => {
    if (Object.keys(ratings).length === 0) { alert('No ratings yet.'); return; }
    const payload = {
        chapter_id: '""" + chapter_id + """',
        rated_at: new Date().toISOString(),
        ratings: ratings,
    };
    const blob = new Blob([JSON.stringify(payload, null, 2)], {type:'application/json'});
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = 'vc_smoke_ratings_""" + chapter_id + """.json';
    a.click();
    URL.revokeObjectURL(a.href);
});
document.getElementById('btn-clear').addEventListener('click', () => {
    if (!confirm('Clear all ratings?')) return;
    ratings = {};
    save();
});
render();
</script></body></html>""")

    viewer_path = out_dir / "vc_smoke.html"
    viewer_path.write_text("\n".join(parts), encoding="utf-8")
    print(f"Viewer: {viewer_path.relative_to(REPO)}")
    abs_path = str(viewer_path.resolve()).replace("\\", "/")
    print(f"Open in browser:")
    print(f"  file:///{abs_path}")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("command", choices=("run", "viewer", "both"))
    ap.add_argument("chapter_id", help="USFM chapter prefix, e.g. MAT_001")
    ap.add_argument("--max-words", type=int, default=25,
                    help="How many words to convert (default 25)")
    ap.add_argument("--strategy", choices=("confidence", "stratified"),
                    default="stratified",
                    help="confidence = top-N most confidently aligned words "
                         "(easy mode). stratified = spread across tones, "
                         "glottal stops, /ɣ/, prenasalized clusters, special "
                         "vowels, polysyllabic words (recommended for "
                         "quality evaluation; default).")
    ap.add_argument("--include-names", action="store_true",
                    help="Don't filter out biblical proper nouns (Aminadab, "
                         "Salmon, Jotan, etc.). Default filters them out so "
                         "the smoke test evaluates VC on real Awing words.")
    ap.add_argument("--no-vocab-filter", action="store_true",
                    help="By default the picker only keeps words that ALSO "
                         "appear in lib/data/awing_vocabulary.dart (i.e. "
                         "PDF-verified Awing vocab). Pass this flag to "
                         "include any aligned Bible word regardless of vocab "
                         "membership.")
    args = ap.parse_args()

    if args.command in ("run", "both"):
        rc = cmd_run(args.chapter_id, args.max_words, strategy=args.strategy,
                     exclude_names=not args.include_names,
                     only_in_vocab=not args.no_vocab_filter)
        if rc != 0:
            return rc
    if args.command in ("viewer", "both"):
        rc = cmd_viewer(args.chapter_id)
        if rc != 0:
            return rc
    return 0


if __name__ == "__main__":
    sys.exit(main())
