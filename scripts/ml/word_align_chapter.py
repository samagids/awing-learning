#!/usr/bin/env python3
"""
Word-level forced alignment for a single Bible chapter, with a browser
viewer so you can listen to each extracted word clip and validate that
the alignment landed on the right audio.

Uses torchaudio.pipelines.MMS_FA (Meta Massively Multilingual Speech --
Forced Alignment). It's a Wav2Vec2 CTC model that produces frame-level
emissions; the aligner walks the most likely path through the emission
matrix that matches the transcript tokens. Output is a list of token
spans per word with start/end frames + score.

Usage
-----
    # Align Matthew chapter 1 (24 verses)
    python scripts/ml/word_align_chapter.py align MAT_001

    # Build a browser viewer to validate the alignment
    python scripts/ml/word_align_chapter.py viewer MAT_001

    # Or both in one shot
    python scripts/ml/word_align_chapter.py both MAT_001

    # Single-verse smoke test
    python scripts/ml/word_align_chapter.py align MAT_001 --max-verses 1

Output
------
    corpus/word_level/MAT_001/
        manifest.json                                # all words + timings
        MAT_001_001_00_le.wav                        # word 0 of verse 1
        MAT_001_001_01_ndzang.wav                    # word 1 of verse 1
        ...
        index.html                                   # browser viewer

Notes
-----
- Audio path: corpus/aligned/piper/train/wav/{USFM}.wav (22050 Hz mono).
  MMS_FA expects 16 kHz so we resample inline.
- Awing special chars (ɛ ɔ ə ɨ ŋ ɣ) and tone diacritics are romanized
  per-word before tokenization. The text we DISPLAY is the original
  Awing; only the tokenizer sees the romanized form.
- The viewer also references the verse-level WAV via relative path so
  you can A/B the word clip vs the verse context.
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
CORPUS_WAV  = REPO / "corpus" / "aligned" / "piper" / "train" / "wav"
CORPUS_META = REPO / "corpus" / "aligned" / "piper" / "train" / "metadata.csv"
OUT_BASE    = REPO / "corpus" / "word_level"
# Verse-level English parallel (Session 57): 7,871 verse pairs from WEB.
BIBLE_PARALLEL = REPO / "corpus" / "parallel" / "nt_aligned.json"
# App vocabulary (~9,445 AwingWord pairs) for per-word English gloss lookup.
VOCAB_DART = REPO / "lib" / "data" / "awing_vocabulary.dart"


def _ensure_venv():
    """Re-exec inside an Awing venv if we're using the system Python."""
    if sys.prefix != sys.base_prefix:
        return
    candidates = [
        REPO / "venv" / "Scripts" / "python.exe",
        REPO / "venv" / "bin" / "python",
        Path.home() / "awing_venv" / "bin" / "python",
    ]
    for py in candidates:
        if py.exists():
            os.execv(str(py), [str(py)] + sys.argv)


def _slug(text):
    """Awing word -> ASCII filename slug (matches pronunciation_service._audioKey)."""
    nfd = unicodedata.normalize("NFD", text)
    s = "".join(c for c in nfd if not unicodedata.combining(c))
    s = (s.replace("ɛ", "e").replace("ɔ", "o").replace("ə", "e")
          .replace("ɨ", "i").replace("ŋ", "ng").replace("ɣ", "gh"))
    s = re.sub(r"[^a-zA-Z0-9]", "", s)
    return s.lower() or "x"


def _romanize_for_mms(word):
    """Strip tone marks + map Awing special chars to Latin for MMS_FA
    tokenizer. The DISPLAY text stays original; only this output is fed
    to the tokenizer."""
    nfd = unicodedata.normalize("NFD", word)
    s = "".join(c for c in nfd if not unicodedata.combining(c))
    replacements = [
        ("Ɛ", "E"), ("ɛ", "e"),
        ("Ɔ", "O"), ("ɔ", "o"),
        ("Ə", "E"), ("ə", "e"),
        ("Ɨ", "I"), ("ɨ", "i"),
        ("Ŋ", "Ng"), ("ŋ", "ng"),
        ("ɣ", "g"),
        ("ʼ", ""), ("’", ""), ("‘", ""), ("'", ""),
    ]
    for old, new in replacements:
        s = s.replace(old, new)
    return s.lower().strip()


def _load_chapter_verses(chapter_id):
    """Return list of (usfm, original_text, wav_path) for the requested chapter."""
    prefix = chapter_id + "_"
    rows = []
    with open(CORPUS_META, encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            if not line.startswith(prefix):
                continue
            if "|" not in line:
                continue
            usfm, text = line.split("|", 1)
            wav = CORPUS_WAV / f"{usfm}.wav"
            if wav.exists():
                rows.append((usfm, text.strip(), wav))
    return rows


def cmd_align(chapter_id, max_verses=None):
    _ensure_venv()
    try:
        import torch
        import torchaudio
        import soundfile as sf
    except ImportError as e:
        print(f"ERROR: missing dependency {e.name}. Install via the venv.")
        return 1

    verses = _load_chapter_verses(chapter_id)
    if max_verses:
        verses = verses[:max_verses]
    if not verses:
        print(f"No verses found for {chapter_id} in {CORPUS_META.relative_to(REPO)}")
        return 1
    print(f"Aligning {len(verses)} verses for {chapter_id}")

    out_dir = OUT_BASE / chapter_id
    out_dir.mkdir(parents=True, exist_ok=True)

    bundle = torchaudio.pipelines.MMS_FA
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Device: {device}, MMS_FA sample rate: {bundle.sample_rate}")
    print("Loading MMS_FA model (first run downloads ~1.1 GB)...")
    model = bundle.get_model(with_star=False).to(device)
    model.eval()
    tokenizer = bundle.get_tokenizer()
    aligner = bundle.get_aligner()

    manifest = []
    skipped = 0

    for i, (usfm, text, wav_path) in enumerate(verses, 1):
        # Load + downmix + resample
        audio, sr = sf.read(str(wav_path), dtype="float32")
        if audio.ndim > 1:
            audio = audio.mean(axis=1)
        if sr != bundle.sample_rate:
            audio_t = torch.from_numpy(audio).unsqueeze(0)
            audio_t = torchaudio.functional.resample(audio_t, sr, bundle.sample_rate)
            audio = audio_t.squeeze(0).numpy()
            sr = bundle.sample_rate

        # Tokenize words. Display = original; tokenizer-input = romanized.
        display_words = [w for w in re.split(r"\s+", text) if w]
        # Strip leading/trailing punctuation per token (commas, periods, etc.)
        clean_pairs = []
        for w in display_words:
            disp = w
            romanized = _romanize_for_mms(w)
            # Drop leading/trailing punctuation from the romanized token
            romanized = re.sub(r"^[^a-z]+|[^a-z]+$", "", romanized)
            if not romanized:
                continue  # punctuation-only token
            clean_pairs.append((disp, romanized))
        if not clean_pairs:
            print(f"  [{i}] {usfm}: SKIP (no romanizable words)")
            skipped += 1
            continue

        try:
            audio_t = torch.from_numpy(audio).unsqueeze(0).to(device)
            with torch.inference_mode():
                emission, _ = model(audio_t)
                emission = emission[0].cpu()
            tokens = tokenizer([romanized for _, romanized in clean_pairs])
            spans = aligner(emission, tokens)
        except Exception as e:
            print(f"  [{i}] {usfm}: alignment FAILED: {e}")
            skipped += 1
            continue

        duration_s = len(audio) / sr
        frames_per_sec = emission.shape[0] / duration_s

        verse_entry = {
            "usfm": usfm,
            "text": text,
            "wav": str(wav_path.relative_to(REPO)).replace("\\", "/"),
            "duration_s": round(duration_s, 3),
            "words": [],
        }

        for w_idx, ((display_word, _rom), word_spans) in enumerate(zip(clean_pairs, spans)):
            if not word_spans:
                continue
            start_f = word_spans[0].start
            end_f = word_spans[-1].end
            start_s = start_f / frames_per_sec
            end_s   = end_f   / frames_per_sec
            confidence = sum(s.score for s in word_spans) / max(len(word_spans), 1)

            start_sample = int(start_s * sr)
            end_sample = int(end_s * sr)
            word_audio = audio[start_sample:end_sample]
            if len(word_audio) < 100:
                continue  # < 6ms = bogus

            clip_name = f"{usfm}_{w_idx:02d}_{_slug(display_word)}.wav"
            sf.write(str(out_dir / clip_name), word_audio, sr)

            verse_entry["words"].append({
                "word_idx": w_idx,
                "word": display_word,
                "start_s": round(start_s, 3),
                "end_s":   round(end_s, 3),
                "confidence": round(float(confidence), 3),
                "clip": clip_name,
            })

        manifest.append(verse_entry)
        print(f"  [{i}/{len(verses)}] {usfm}: {len(verse_entry['words'])} words "
              f"({duration_s:.1f}s audio)")

    manifest_path = out_dir / "manifest.json"
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"\nManifest: {manifest_path.relative_to(REPO)}")
    print(f"Aligned: {len(manifest)} verses, skipped: {skipped}")
    print(f"Word clips: {len(list(out_dir.glob('*.wav')))}")
    return 0


def _build_gloss_lookup():
    """Parse lib/data/awing_vocabulary.dart and return a dict mapping
    tone-stripped lowercase Awing -> English. Used by the viewer to
    show a small caption under each word chip. Returns first-seen
    English per normalized key (homonyms: arbitrary but stable)."""
    if not VOCAB_DART.exists():
        return {}
    src = VOCAB_DART.read_text(encoding="utf-8")
    pairs = re.findall(
        r"""AwingWord\(\s*awing:\s*['"]([^'"]+)['"][^)]*english:\s*['"]([^'"]+)['"]""",
        src,
    )
    lookup = {}
    def _norm(s):
        nfd = unicodedata.normalize("NFD", s).lower()
        return "".join(c for c in nfd if not unicodedata.combining(c))
    for awing, english in pairs:
        k = _norm(awing.strip())
        if k and k not in lookup:
            lookup[k] = english.strip()
    return lookup


def _load_verse_english_map():
    """corpus/parallel/nt_aligned.json -> dict mapping {USFM_001_001:
    english_translation}. The JSON uses dotted refs (MAT.1.1) so we
    convert to our underscored USFM keys (MAT_001_001)."""
    if not BIBLE_PARALLEL.exists():
        return {}
    try:
        data = json.loads(BIBLE_PARALLEL.read_text(encoding="utf-8"))
    except Exception:
        return {}
    out = {}
    for v in data:
        ref = v.get("ref", "")
        eng = v.get("english", "")
        if not ref or not eng:
            continue
        parts = ref.split(".")
        if len(parts) == 3:
            book, ch, vs = parts
            usfm = f"{book}_{int(ch):03d}_{int(vs):03d}"
            out[usfm] = eng
    return out


def cmd_viewer(chapter_id):
    out_dir = OUT_BASE / chapter_id
    manifest_path = out_dir / "manifest.json"
    if not manifest_path.exists():
        print(f"No manifest at {manifest_path}. Run `align` first.")
        return 1
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    gloss   = _build_gloss_lookup()
    verse_english = _load_verse_english_map()

    def _gloss_of(word):
        nfd = unicodedata.normalize("NFD", word).lower()
        k = "".join(c for c in nfd if not unicodedata.combining(c))
        k = re.sub(r"^[^a-zɛɔəɨŋɣ]+|[^a-zɛɔəɨŋɣ]+$", "", k)
        return gloss.get(k, "")

    # Build a JSON payload of per-word data the JS will use to render
    # and persist corrections. Embedded directly in the HTML so the
    # viewer is a single self-contained file.
    js_words = []
    for v_idx, verse in enumerate(manifest):
        for w in verse["words"]:
            js_words.append({
                "id":      f"{verse['usfm']}_{w['word_idx']:02d}",
                "v_idx":   v_idx,
                "usfm":    verse["usfm"],
                "context": verse["usfm"].replace("_", ".").replace(".0", "."),
                "awing":   w["word"],
                "gloss":   _gloss_of(w["word"]),
                "conf":    w["confidence"],
                "clip":    w["clip"],
                "start_s": w["start_s"],
                "end_s":   w["end_s"],
            })

    js_verses = []
    for verse in manifest:
        js_verses.append({
            "usfm":      verse["usfm"],
            "text":      verse["text"],
            "wav":       "../../" + verse["wav"],
            "english":   verse_english.get(verse["usfm"], ""),
            "duration":  verse["duration_s"],
            "word_ids":  [f"{verse['usfm']}_{w['word_idx']:02d}" for w in verse["words"]],
        })

    css = """
    body{font-family:Georgia,serif;max-width:1180px;margin:1em auto;padding:0 1em;line-height:1.7;color:#222;background:#fafafa}
    h1{font-size:1.5em;color:#333;border-bottom:2px solid #555;padding-bottom:0.3em;margin-bottom:0.4em}
    .toolbar{position:sticky;top:0;background:#fff;border:1px solid #ccc;border-radius:6px;padding:0.6em 0.9em;margin:0.5em 0 1em 0;display:flex;flex-wrap:wrap;gap:0.5em;align-items:center;z-index:10;box-shadow:0 2px 4px rgba(0,0,0,0.05)}
    .toolbar label{font-size:0.9em;color:#555}
    .toolbar input[type=text]{padding:4px 8px;border:1px solid #aaa;border-radius:4px;font-size:0.95em;width:160px}
    .toolbar button{padding:5px 12px;border:1px solid #888;background:#f0f0f0;border-radius:4px;cursor:pointer;font-size:0.9em}
    .toolbar button:hover{background:#e0e0e0}
    .toolbar button.primary{background:#449944;color:#fff;border-color:#337733;font-weight:bold}
    .toolbar button.primary:hover{background:#337733}
    .toolbar .stats{margin-left:auto;font-size:0.85em;color:#666}
    .intro{background:#fff;padding:0.8em 1.2em;border-radius:6px;border:1px solid #ddd;margin-bottom:1em;font-size:0.92em}
    .intro ul{margin:0.4em 0;padding-left:1.4em}
    .verse{margin:1em 0;padding:0.9em 1.1em;background:#fff;border-left:5px solid #888;border-radius:5px;box-shadow:0 1px 2px rgba(0,0,0,0.04)}
    .verse-id{font-weight:bold;color:#555;font-size:0.82em;margin-bottom:0.3em;font-family:monospace}
    .verse-audio audio{width:100%;max-width:560px;height:34px;margin:0.2em 0}
    .verse-eng{font-style:italic;color:#555;font-size:0.95em;margin:0.4em 0 0.7em 0;padding:0.4em 0.7em;background:#f6f0e0;border-left:3px solid #c8a040;border-radius:3px}
    .word-grid{display:flex;flex-wrap:wrap;gap:6px 8px;margin:0.4em 0}
    .word-unit{display:inline-flex;flex-direction:column;align-items:center;min-width:50px;max-width:170px;text-align:center;position:relative;cursor:pointer}
    .word-unit:hover .edit-icon{opacity:1}
    .word{display:inline-block;padding:3px 9px;background:#fff;border:2px solid #ccc;border-radius:5px;cursor:pointer;transition:all 0.12s;font-family:Georgia,serif;color:#222;font-size:1.02em;white-space:nowrap;position:relative}
    .word:hover{background:#fff3cd;border-color:#cc9900}
    .word.playing{background:#a9d99e;border-color:#449900;color:#000;font-weight:bold}
    .conf-hi{border-color:#449944}
    .conf-med{border-color:#cc9944}
    .conf-low{border-color:#cc4444;background:#fee4e4}
    .gloss{font-size:0.74em;color:#666;margin-top:2px;line-height:1.2;max-width:160px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
    .gloss.no-gloss{color:#bbb}
    .gloss.user-set{color:#226622;font-weight:bold}
    .word-unit.reviewed .word{box-shadow:0 0 0 2px #6699cc inset}
    .word-unit.added .word{box-shadow:0 0 0 2px #66bb66 inset}
    .word-unit.fixed .word{box-shadow:0 0 0 2px #cc9933 inset}
    .status-mark{position:absolute;top:-7px;right:-7px;background:#fff;border-radius:50%;width:18px;height:18px;font-size:11px;line-height:18px;text-align:center;border:1px solid #888;font-weight:bold}
    .status-mark.verified{background:#cce5ff;color:#003388;border-color:#3366cc}
    .status-mark.added{background:#d4edda;color:#1f5f1f;border-color:#449944}
    .status-mark.fixed{background:#fff3cd;color:#664400;border-color:#cc9933}
    .edit-icon{position:absolute;top:-6px;left:-6px;opacity:0;transition:opacity 0.1s;background:#fff;border:1px solid #888;border-radius:50%;width:18px;height:18px;font-size:11px;line-height:18px;text-align:center;cursor:pointer}
    /* Modal */
    .modal-backdrop{position:fixed;top:0;left:0;width:100vw;height:100vh;background:rgba(0,0,0,0.4);display:none;z-index:100;align-items:center;justify-content:center}
    .modal-backdrop.show{display:flex}
    .modal{background:#fff;border-radius:8px;padding:1.2em 1.6em;width:min(90vw,520px);box-shadow:0 6px 24px rgba(0,0,0,0.3)}
    .modal h2{margin:0 0 0.4em 0;font-size:1.3em;color:#333}
    .modal .field{margin:0.6em 0}
    .modal label{display:block;font-size:0.85em;color:#555;margin-bottom:0.2em;font-weight:bold}
    .modal input[type=text], .modal textarea{width:100%;padding:6px 10px;border:1px solid #aaa;border-radius:4px;font-size:0.95em;font-family:Georgia,serif}
    .modal textarea{height:60px;resize:vertical}
    .modal .ctx{font-size:0.85em;color:#777;margin:0.3em 0}
    .modal .ctx code{background:#eee;padding:1px 5px;border-radius:3px}
    .modal .radios label{display:inline-block;margin-right:1em;font-weight:normal}
    .modal .actions{margin-top:1em;display:flex;gap:0.5em;justify-content:flex-end}
    .modal .actions button{padding:6px 14px;border-radius:4px;cursor:pointer;font-size:0.95em;border:1px solid #888}
    .modal .actions .save{background:#449944;color:#fff;border-color:#337733;font-weight:bold}
    .modal .actions .cancel{background:#f0f0f0}
    .modal .actions .delete{background:#cc4444;color:#fff;border-color:#883333;margin-right:auto}
    .legend .word{margin:0 6px}
    """

    intro_html = """
    <div class='intro'>
    <p><b>How to review:</b></p>
    <ul>
      <li>Audio bar plays the <b>full verse</b>; click any <span class='word conf-hi'>word</span> to hear it alone.</li>
      <li>Click anywhere on a word card to <b>edit/verify</b> its English meaning. A dialog opens with the current gloss (or empty if missing).</li>
      <li>Pick <b>Verified</b> if the existing gloss is correct, <b>Add new</b> if the word is missing from vocab.dart, or <b>Fix existing</b> if the gloss is wrong.</li>
      <li>Corrections save to browser storage automatically. Click <b>Download corrections</b> when done to export a JSON file. Move it into <code>contributions/word_corrections/</code> and run the apply script to update vocab.dart.</li>
      <li>Resume work later by reloading this page (corrections persist) or clicking <b>Load corrections</b> with the JSON file.</li>
    </ul>
    <p class='legend'>Border color = MMS_FA alignment confidence: <span class='word conf-hi'>green</span> &gt; 0.5, <span class='word conf-med'>amber</span> 0.2-0.5, <span class='word conf-low'>red</span> &lt; 0.2. Inset highlight = your review status: blue&nbsp;✓ verified, green&nbsp;+ added, amber&nbsp;✎ fixed.</p>
    </div>
    """

    body = []
    body.append(f"<h1>{chapter_id} &mdash; Word-Level Validation + Corrections</h1>")
    body.append("<div class='toolbar'>")
    body.append("  <label>Reviewer: <input type='text' id='reviewer' placeholder='e.g. Dr. Sama'></label>")
    body.append("  <button id='btn-download' class='primary'>Download corrections (JSON)</button>")
    body.append("  <button id='btn-load'>Load corrections...</button>")
    body.append("  <input type='file' id='file-load' accept='.json' style='display:none'>")
    body.append("  <button id='btn-clear'>Clear all</button>")
    body.append("  <span class='stats' id='stats'>0 reviewed</span>")
    body.append("</div>")
    body.append(intro_html)
    body.append("<audio id='player' preload='none'></audio>")
    body.append("<div id='verses'></div>")
    # Modal
    body.append("""
    <div class='modal-backdrop' id='modal-backdrop'>
      <div class='modal'>
        <h2 id='modal-title'>Edit word</h2>
        <div class='ctx'>Context: <code id='modal-context'></code> &middot; Awing: <b id='modal-awing'></b></div>
        <div class='field'>
          <label>Current gloss in vocab.dart:</label>
          <div id='modal-current-gloss' style='font-size:0.95em;color:#555;padding:4px 0'></div>
        </div>
        <div class='field radios'>
          <label>Status:</label>
          <label><input type='radio' name='status' value='verified'> Verified (current gloss is correct)</label>
          <label><input type='radio' name='status' value='added'> Add new (word missing from vocab)</label>
          <label><input type='radio' name='status' value='fixed'> Fix existing (gloss is wrong)</label>
        </div>
        <div class='field'>
          <label>English meaning <span id='english-required' style='color:#cc4444;display:none'>(required for add/fix)</span>:</label>
          <input type='text' id='modal-english' placeholder='e.g. story; account; the way that...'>
        </div>
        <div class='field'>
          <label>Notes (optional):</label>
          <textarea id='modal-notes' placeholder='e.g. plural of tǎ; Bible-context particle, not the lexical meaning'></textarea>
        </div>
        <div class='actions'>
          <button class='delete' id='modal-delete' style='display:none'>Delete correction</button>
          <button class='cancel' id='modal-cancel'>Cancel</button>
          <button class='save' id='modal-save'>Save</button>
        </div>
      </div>
    </div>
    """)

    js_data = json.dumps({
        "chapter_id": chapter_id,
        "verses": js_verses,
        "words": js_words,
    }, ensure_ascii=False)

    script = """
    <script>
    const DATA = """ + js_data + """;
    const STORAGE_KEY = 'awing_corrections_' + DATA.chapter_id;
    const $ = (id) => document.getElementById(id);

    // ---- State ----
    let state = loadState();
    function loadState() {
        try {
            const raw = localStorage.getItem(STORAGE_KEY);
            if (raw) return JSON.parse(raw);
        } catch (e) { /* ignore */ }
        return { reviewer: '', chapter_id: DATA.chapter_id, started_at: new Date().toISOString(), corrections: {} };
    }
    function saveState() {
        try { localStorage.setItem(STORAGE_KEY, JSON.stringify(state)); } catch (e) { console.warn(e); }
    }
    function escape(s) {
        return String(s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'})[c]);
    }
    function confClass(c) {
        return c > 0.5 ? 'conf-hi' : (c > 0.2 ? 'conf-med' : 'conf-low');
    }
    function renderAll() {
        const root = $('verses');
        root.innerHTML = '';
        for (const verse of DATA.verses) {
            const div = document.createElement('div');
            div.className = 'verse';
            div.innerHTML = `
                <div class='verse-id'>${escape(verse.usfm)} &middot; ${verse.duration}s &middot; ${verse.word_ids.length} words</div>
                <div class='verse-audio'><audio controls preload='none' src='${escape(verse.wav)}'></audio></div>
                ${verse.english ? `<div class='verse-eng'>${escape(verse.english)}</div>` : ''}
                <div class='word-grid' data-verse='${verse.usfm}'></div>
            `;
            const grid = div.querySelector('.word-grid');
            for (const wid of verse.word_ids) {
                const w = DATA.words.find(x => x.id === wid);
                if (!w) continue;
                grid.appendChild(renderWord(w));
            }
            root.appendChild(div);
        }
        updateStats();
    }
    function renderWord(w) {
        const c = state.corrections[w.id];
        const unit = document.createElement('span');
        unit.className = 'word-unit';
        if (c) unit.classList.add(c.status); // verified / added / fixed
        unit.dataset.id = w.id;

        const displayGloss = c && c.english ? c.english : w.gloss;
        const glossClass = (c && c.english) ? 'gloss user-set' : (w.gloss ? 'gloss' : 'gloss no-gloss');
        const glossText = displayGloss || '—';

        let statusMark = '';
        if (c) {
            const sym = c.status === 'verified' ? '✓' : (c.status === 'added' ? '+' : '✎');
            statusMark = `<span class='status-mark ${c.status}' title='${c.status}'>${sym}</span>`;
        }

        unit.innerHTML = `
            <span class='word ${confClass(w.conf)}' data-clip='${escape(w.clip)}'
                  title='${w.start_s}s-${w.end_s}s, conf=${w.conf}'>${escape(w.awing)}${statusMark}</span>
            <span class='${glossClass}' title='${escape(displayGloss)}'>${escape(glossText)}</span>
        `;
        // Click on word -> play; click anywhere else on unit -> edit
        unit.querySelector('.word').addEventListener('click', e => {
            e.stopPropagation();
            playClip(unit.querySelector('.word'), w.clip);
        });
        unit.addEventListener('click', e => {
            // Already handled by the word's own listener; only fire if user clicked the gloss area
            if (e.target.closest('.word')) return;
            openModal(w);
        });
        return unit;
    }
    function playClip(el, clip) {
        const player = $('player');
        document.querySelectorAll('.word.playing').forEach(n => n.classList.remove('playing'));
        el.classList.add('playing');
        player.src = clip;
        player.play();
        player.onended = () => el.classList.remove('playing');
    }
    function updateStats() {
        const total = DATA.words.length;
        const rev = Object.keys(state.corrections).length;
        const verified = Object.values(state.corrections).filter(c => c.status === 'verified').length;
        const added = Object.values(state.corrections).filter(c => c.status === 'added').length;
        const fixed = Object.values(state.corrections).filter(c => c.status === 'fixed').length;
        $('stats').textContent = `${rev}/${total} reviewed (${verified} verified, ${added} added, ${fixed} fixed)`;
    }

    // ---- Modal ----
    let currentWord = null;
    function openModal(w) {
        currentWord = w;
        const c = state.corrections[w.id];
        $('modal-awing').textContent = w.awing;
        $('modal-context').textContent = w.context;
        $('modal-current-gloss').textContent = w.gloss || '(none in vocab.dart)';
        $('modal-english').value = c ? (c.english || '') : '';
        $('modal-notes').value = c ? (c.notes || '') : '';
        document.querySelectorAll("input[name='status']").forEach(r => {
            r.checked = c ? (r.value === c.status) : false;
        });
        if (!c) {
            // Default suggestion: if vocab has a gloss, default to 'verified'
            document.querySelector(`input[name='status'][value='${w.gloss ? 'verified' : 'added'}']`).checked = true;
        }
        $('modal-delete').style.display = c ? 'inline-block' : 'none';
        $('modal-backdrop').classList.add('show');
        setTimeout(() => $('modal-english').focus(), 50);
    }
    function closeModal() {
        $('modal-backdrop').classList.remove('show');
        currentWord = null;
    }
    function saveCorrection() {
        if (!currentWord) return;
        const status = document.querySelector("input[name='status']:checked");
        if (!status) { alert('Pick a status (verified, added, or fixed).'); return; }
        const english = $('modal-english').value.trim();
        const notes = $('modal-notes').value.trim();
        if ((status.value === 'added' || status.value === 'fixed') && !english) {
            alert('English meaning required for add/fix.');
            return;
        }
        state.corrections[currentWord.id] = {
            id: currentWord.id,
            usfm: currentWord.usfm,
            awing: currentWord.awing,
            english: english || currentWord.gloss || '',
            status: status.value,
            notes: notes,
            reviewer: $('reviewer').value.trim() || state.reviewer || '',
            verified_at: new Date().toISOString(),
        };
        state.reviewer = $('reviewer').value.trim() || state.reviewer || '';
        saveState();
        closeModal();
        renderAll();
    }
    function deleteCorrection() {
        if (!currentWord) return;
        delete state.corrections[currentWord.id];
        saveState();
        closeModal();
        renderAll();
    }

    // ---- Toolbar ----
    function downloadJSON() {
        if (Object.keys(state.corrections).length === 0) {
            alert('No corrections to download yet.');
            return;
        }
        const payload = {
            chapter_id: DATA.chapter_id,
            reviewer: $('reviewer').value.trim() || state.reviewer || '',
            exported_at: new Date().toISOString(),
            corrections: Object.values(state.corrections),
        };
        const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `corrections_${DATA.chapter_id}.json`;
        a.click();
        URL.revokeObjectURL(url);
    }
    function loadJSON(file) {
        const reader = new FileReader();
        reader.onload = () => {
            try {
                const payload = JSON.parse(reader.result);
                if (payload.chapter_id !== DATA.chapter_id) {
                    if (!confirm(`File is for chapter ${payload.chapter_id}, current viewer is ${DATA.chapter_id}. Load anyway?`)) return;
                }
                let n = 0;
                for (const c of payload.corrections || []) {
                    if (!c.id) continue;
                    state.corrections[c.id] = c;
                    n++;
                }
                if (payload.reviewer) {
                    state.reviewer = payload.reviewer;
                    $('reviewer').value = payload.reviewer;
                }
                saveState();
                renderAll();
                alert(`Loaded ${n} corrections.`);
            } catch (e) {
                alert('Failed to parse JSON: ' + e.message);
            }
        };
        reader.readAsText(file);
    }
    function clearAll() {
        if (!confirm('Clear ALL corrections for this chapter? This cannot be undone.')) return;
        state.corrections = {};
        saveState();
        renderAll();
    }

    // ---- Wire up ----
    document.addEventListener('DOMContentLoaded', () => {
        $('reviewer').value = state.reviewer || '';
        $('reviewer').addEventListener('change', e => {
            state.reviewer = e.target.value.trim();
            saveState();
        });
        $('btn-download').addEventListener('click', downloadJSON);
        $('btn-load').addEventListener('click', () => $('file-load').click());
        $('file-load').addEventListener('change', e => {
            if (e.target.files[0]) loadJSON(e.target.files[0]);
        });
        $('btn-clear').addEventListener('click', clearAll);
        $('modal-save').addEventListener('click', saveCorrection);
        $('modal-cancel').addEventListener('click', closeModal);
        $('modal-delete').addEventListener('click', deleteCorrection);
        $('modal-backdrop').addEventListener('click', e => {
            if (e.target === $('modal-backdrop')) closeModal();
        });
        document.addEventListener('keydown', e => {
            if (e.key === 'Escape' && $('modal-backdrop').classList.contains('show')) closeModal();
            if (e.key === 'Enter' && e.ctrlKey && $('modal-backdrop').classList.contains('show')) saveCorrection();
        });
        renderAll();
    });
    </script>
    """

    parts = []
    parts.append("<!DOCTYPE html><html><head><meta charset='utf-8'>")
    parts.append(f"<title>{chapter_id} word-level corrections</title>")
    parts.append("<style>" + css + "</style>")
    parts.append("</head><body>")
    parts.extend(body)
    parts.append(script)
    parts.append("</body></html>")

    viewer_path = out_dir / "index.html"
    viewer_path.write_text("\n".join(parts), encoding="utf-8")
    print(f"Viewer: {viewer_path.relative_to(REPO)}")
    print(f"Open in browser:")
    abs_path = str(viewer_path.resolve()).replace("\\", "/")
    print(f"  file:///{abs_path}")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("command", choices=("align", "viewer", "both"))
    ap.add_argument("chapter_id", help="USFM chapter prefix, e.g. MAT_001")
    ap.add_argument("--max-verses", type=int, default=None,
                    help="Process only first N verses (smoke test).")
    args = ap.parse_args()

    if args.command in ("align", "both"):
        rc = cmd_align(args.chapter_id, args.max_verses)
        if rc != 0:
            return rc
    if args.command in ("viewer", "both"):
        rc = cmd_viewer(args.chapter_id)
        if rc != 0:
            return rc
    return 0


if __name__ == "__main__":
    sys.exit(main())
