#!/usr/bin/env python3
"""
OpenVoice v2 voice-conversion smoke test.

Same picker + same viewer as scripts/ml/vc_smoke_test.py (kNN-VC), but
swaps the VC backend for OpenVoice v2's ToneColorConverter. OpenVoice
uses flow-matching synthesis and produces meaningfully cleaner timbre
transfer than kNN-VC, with less metallic vocoder coloration. If the
ceiling is still "Bible source artifacts bleed through", we'll know
because both backends produce comparable output -- and we stop the
Bible-VC line cleanly. If OpenVoice meaningfully exceeds kNN-VC, we
plan a production rollout.

INSTALL (one-time, Windows PowerShell)
--------------------------------------
1. Create a separate venv to avoid disturbing your main `venv`:
       python -m venv venv_openvoice
       .\venv_openvoice\Scripts\activate
2. Install PyTorch w/ CUDA (matches your existing venv config):
       pip install torch torchvision torchaudio \\
         --index-url https://download.pytorch.org/whl/cu128
3. Clone OpenVoice and pip-install it editable:
       if (-not (Test-Path tools)) { mkdir tools }
       cd tools
       git clone https://github.com/myshell-ai/OpenVoice.git
       cd OpenVoice
       pip install -e .
       cd ..\\..
4. Install the rest of the deps OpenVoice needs (subset of full reqs):
       pip install librosa==0.9.1 faster-whisper soundfile numpy==1.26 \\
         wavmark==0.0.3 edge-tts pydub
5. Download checkpoints (~600 MB):
       Invoke-WebRequest -Uri "https://myshell-public-repo-host.s3.amazonaws.com/openvoice/checkpoints_v2_0417.zip" `
           -OutFile checkpoints_v2.zip
       Expand-Archive checkpoints_v2.zip -DestinationPath .
       Remove-Item checkpoints_v2.zip

That puts the converter at `checkpoints_v2/converter/{config.json, checkpoint.pth}`.

RUN
---
    .\\venv_openvoice\\Scripts\\activate
    python scripts/ml/vc_openvoice_smoke.py both MAT_001 --max-words 15

What this produces
------------------
- corpus/word_level/MAT_001/vc_smoke/_drsama_ov_ref.wav  — concatenated
  voice reference (5-10 of your recordings as one WAV)
- corpus/word_level/MAT_001/vc_smoke/<usfm>_<idx>_<slug>__ov.wav  —
  OpenVoice conversion per word
- corpus/word_level/MAT_001/vc_smoke/smoke_manifest.json  — updated in
  place to add `ov_clip` per item (alongside existing `vc_clip` from
  kNN-VC and `edge_clip` from Edge TTS)
- corpus/word_level/MAT_001/vc_smoke/vc_smoke.html  — extended viewer
  now has FOUR audio columns: Bible / kNN-VC / OpenVoice / Edge TTS
"""

import argparse
import json
import os
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
CHECKPOINTS_DIR = REPO / "checkpoints_v2" / "converter"
OPENVOICE_REPO = REPO / "tools" / "OpenVoice"
NATIVE_RECS_DIR = REPO / "training_data" / "recordings"
NATIVE_MANIFEST = NATIVE_RECS_DIR / "manifest.json"


def _ensure_venv():
    """Re-exec into venv_openvoice if we're not already there."""
    if sys.prefix != sys.base_prefix and "venv_openvoice" in sys.prefix.lower():
        return
    for py in (REPO / "venv_openvoice" / "Scripts" / "python.exe",
               REPO / "venv_openvoice" / "bin" / "python"):
        if py.exists():
            os.execv(str(py), [str(py)] + sys.argv)
    print("ERROR: venv_openvoice not found. Run the INSTALL steps in this "
          "script's docstring first:")
    print(f"    {Path(__file__).relative_to(REPO)}")
    sys.exit(1)


def _check_setup():
    if not OPENVOICE_REPO.exists():
        sys.exit(f"ERROR: OpenVoice repo not found at {OPENVOICE_REPO.relative_to(REPO)}.\n"
                 f"Run: cd tools && git clone https://github.com/myshell-ai/OpenVoice.git")
    if not CHECKPOINTS_DIR.exists():
        sys.exit(f"ERROR: checkpoints not found at "
                 f"{CHECKPOINTS_DIR.relative_to(REPO)}.\n"
                 f"Run the download step in the INSTALL section.")
    sys.path.insert(0, str(OPENVOICE_REPO))


def _build_voice_reference(out_path: Path, num_clips: int = 8):
    """Concat the first N Dr. Sama recordings into a single voice
    reference. OpenVoice's get_se expects ~10-30 seconds of reference
    audio; concatenating 8 of his 2-3s recordings gives ~20s."""
    import soundfile as sf
    import numpy as np
    data = json.loads(NATIVE_MANIFEST.read_text(encoding="utf-8"))
    chunks = []
    sr_out = None
    n = 0
    for entry in data:
        if entry.get("duration_s", 0) < 1.0:
            continue
        wav = REPO / entry["wav_path"]
        if not wav.exists():
            continue
        audio, sr = sf.read(str(wav), dtype="float32")
        if audio.ndim > 1:
            audio = audio.mean(axis=1)
        if sr_out is None:
            sr_out = sr
        elif sr != sr_out:
            # Resample to first-seen sr
            import torch
            import torchaudio
            t = torch.from_numpy(audio).unsqueeze(0)
            t = torchaudio.functional.resample(t, sr, sr_out)
            audio = t.squeeze(0).numpy()
        chunks.append(audio)
        # Small silence between
        chunks.append(np.zeros(int(0.2 * sr_out), dtype="float32"))
        n += 1
        if n >= num_clips:
            break
    cat = np.concatenate(chunks)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    sf.write(str(out_path), cat, sr_out)
    print(f"  voice reference: {n} clips concatenated -> "
          f"{out_path.relative_to(REPO)} ({len(cat)/sr_out:.1f}s)")
    return out_path


def cmd_run(chapter_id, max_words):
    _ensure_venv()
    _check_setup()
    import torch
    try:
        from openvoice.api import ToneColorConverter
    except ImportError as e:
        sys.exit(f"ERROR importing ToneColorConverter: {e}\n"
                 f"Did you run `pip install --no-deps -e tools/OpenVoice`?")
    # We deliberately do NOT import openvoice.se_extractor here because
    # it pulls in faster-whisper -> av==10.* which doesn't build on
    # modern Cython/Windows. Instead we use the converter's own
    # extract_se() method (or a minimal local replacement) below.

    # Reuse the word-picker from the kNN-VC smoke test (same filters)
    sys.path.insert(0, str(REPO / "scripts" / "ml"))
    import vc_smoke_test as kk
    align_dir = REPO / "corpus" / "word_level" / chapter_id
    manifest_path = align_dir / "manifest.json"
    if not manifest_path.exists():
        sys.exit(f"No manifest at {manifest_path.relative_to(REPO)}. Run "
                 f"word_align_chapter.py align {chapter_id} first.")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    words = kk._pick_words(manifest, max_words, strategy="stratified",
                            exclude_names=True, only_in_vocab=True)
    print(f"Selected {len(words)} words for OpenVoice smoke test:")
    for w in words:
        feat = "+".join(w.get("features", []))
        print(f"  {w['usfm']} '{w['word']:15s}' conf={w['conf']:.2f}  [{feat}]")

    # Load OpenVoice
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"\nLoading OpenVoice v2 ToneColorConverter (device={device})...")
    converter = ToneColorConverter(
        str(CHECKPOINTS_DIR / "config.json"), device=device)
    converter.load_ckpt(str(CHECKPOINTS_DIR / "checkpoint.pth"))

    # Build voice reference + extract target SE
    out_dir = align_dir / "vc_smoke"
    out_dir.mkdir(parents=True, exist_ok=True)
    ref_path = out_dir / "_drsama_ov_ref.wav"
    _build_voice_reference(ref_path, num_clips=8)

    # Use converter.extract_se() directly (no faster-whisper dep).
    # Returns the averaged speaker embedding for the reference clip.
    def _extract_se(audio_path):
        # Newer OpenVoice (>=v2): converter.extract_se(refs: List[str])
        if hasattr(converter, "extract_se"):
            return converter.extract_se([str(audio_path)])
        # Older OpenVoice fallback: load + encode manually
        import librosa as _lib
        import torch as _t
        sr = converter.hps.data.sampling_rate
        audio, _ = _lib.load(str(audio_path), sr=sr)
        with _t.no_grad():
            y = _t.from_numpy(audio).unsqueeze(0).to(converter.device)
            from openvoice.mel_processing import spectrogram_torch
            spec = spectrogram_torch(
                y,
                converter.hps.data.filter_length,
                sr,
                converter.hps.data.hop_length,
                converter.hps.data.win_length,
                center=False,
            )
            g = converter.model.ref_enc(spec.transpose(1, 2)).unsqueeze(-1)
        return g

    print("Extracting target speaker embedding (Dr. Sama)...")
    target_se = _extract_se(ref_path)

    # Convert each word
    print(f"\nConverting {len(words)} words...")
    converted = []
    for i, w in enumerate(words, 1):
        src = align_dir / w["clip"]
        if not src.exists():
            print(f"  [{i}/{len(words)}] missing source {src.name}")
            continue
        try:
            source_se = _extract_se(src)
            out_path = out_dir / f"{Path(w['clip']).stem}__ov.wav"
            converter.convert(
                audio_src_path=str(src),
                src_se=source_se,
                tgt_se=target_se,
                output_path=str(out_path),
                message="@MyShell",
            )
            print(f"  [{i}/{len(words)}] {w['word']:15s} -> {out_path.name}")
            converted.append({**w, "ov_clip": out_path.name})
        except Exception as e:
            print(f"  [{i}/{len(words)}] {w['word']}: OV FAILED -- {e}")

    # Merge into existing smoke_manifest.json so the viewer surfaces
    # OpenVoice clips ALONGSIDE the kNN-VC clips for direct comparison
    smoke_path = out_dir / "smoke_manifest.json"
    if smoke_path.exists():
        sm = json.loads(smoke_path.read_text(encoding="utf-8"))
        # Index by usfm + word_idx
        for item in sm["items"]:
            stem = Path(item["clip"]).stem
            ov_name = f"{stem}__ov.wav"
            if (out_dir / ov_name).exists():
                item["ov_clip"] = ov_name
        # Also append OpenVoice-converted words that AREN'T in the existing
        # manifest (e.g. if only-in-vocab filter included new picks)
        existing_clips = {item["clip"] for item in sm["items"]}
        for c in converted:
            if c["clip"] not in existing_clips:
                sm["items"].append(c)
        smoke_path.write_text(
            json.dumps(sm, ensure_ascii=False, indent=2), encoding="utf-8")
    else:
        # No prior smoke run; write a fresh manifest with OV-only entries
        sm = {"chapter_id": chapter_id, "items": converted}
        smoke_path.write_text(
            json.dumps(sm, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"\nSmoke manifest updated: {smoke_path.relative_to(REPO)}")
    return 0


def cmd_viewer(chapter_id):
    """Build the 4-column viewer: Bible / kNN-VC / OpenVoice / Edge."""
    align_dir = REPO / "corpus" / "word_level" / chapter_id
    out_dir = align_dir / "vc_smoke"
    smoke_path = out_dir / "smoke_manifest.json"
    if not smoke_path.exists():
        sys.exit(f"No smoke manifest at {smoke_path.relative_to(REPO)}. Run "
                 f"`vc_openvoice_smoke.py run {chapter_id}` first.")
    data = json.loads(smoke_path.read_text(encoding="utf-8"))
    items = data["items"]
    from html import escape

    parts = []
    parts.append("<!DOCTYPE html><html><head><meta charset='utf-8'>")
    parts.append(f"<title>{chapter_id} VC bake-off (kNN-VC vs OpenVoice)</title>")
    parts.append("""<style>
body{font-family:Georgia,serif;max-width:1400px;margin:1em auto;padding:0 1em;line-height:1.6;color:#222;background:#fafafa}
h1{font-size:1.4em;color:#333;border-bottom:2px solid #555;padding-bottom:0.3em}
.intro{background:#fff;padding:0.8em 1.2em;border-radius:6px;border:1px solid #ddd;margin-bottom:1em;font-size:0.92em}
.toolbar{position:sticky;top:0;background:#fff;border:1px solid #ccc;border-radius:6px;padding:0.5em 0.8em;margin:0.5em 0 1em 0;display:flex;gap:0.6em;align-items:center;z-index:10;box-shadow:0 2px 4px rgba(0,0,0,0.05)}
.toolbar button{padding:5px 12px;border:1px solid #888;background:#f0f0f0;border-radius:4px;cursor:pointer;font-size:0.9em}
.toolbar button.primary{background:#449944;color:#fff;border-color:#337733;font-weight:bold}
.stats{margin-left:auto;font-size:0.85em;color:#666}
table{width:100%;border-collapse:collapse;background:#fff;border-radius:6px;overflow:hidden;box-shadow:0 1px 3px rgba(0,0,0,0.08)}
th{background:#444;color:#fff;padding:0.6em 0.4em;text-align:left;font-size:0.85em}
td{padding:0.6em 0.4em;border-top:1px solid #eee;vertical-align:middle;font-size:0.92em}
tr.rated-bible td{background:#f5fff5}
tr.rated-knnvc td{background:#fff8e0}
tr.rated-openvoice td{background:#e0f0ff}
tr.rated-edge  td{background:#f0f4ff}
tr.rated-equal td{background:#f8f8f8}
tr.rated-bad   td{background:#ffe4e4}
.awing{font-size:1.05em;font-weight:bold;color:#222}
.meta{font-size:0.72em;color:#888;font-family:monospace}
.feat{font-size:0.68em;color:#1f6fcc;margin-top:3px;font-family:monospace;font-weight:bold}
audio{width:170px;height:30px;display:block}
.rate-row{display:flex;gap:3px;flex-wrap:wrap}
.rate-row button{font-size:0.74em;padding:3px 6px;border:1px solid #999;background:#fff;border-radius:4px;cursor:pointer;color:#333}
.rate-row button.active{background:#449944;color:#fff;border-color:#337733;font-weight:bold}
.rate-row button[data-rating=knnvc].active{background:#cc9933;border-color:#996600}
.rate-row button[data-rating=openvoice].active{background:#3366cc;border-color:#1f4488}
.rate-row button[data-rating=edge].active{background:#7755aa;border-color:#552288}
.rate-row button[data-rating=equal].active{background:#666;border-color:#444}
.rate-row button[data-rating=bad].active{background:#cc4444;border-color:#883333}
</style></head><body>""")
    parts.append(f"<h1>{chapter_id} &mdash; VC Bake-off (kNN-VC vs OpenVoice v2)</h1>")
    parts.append("""<div class='intro'>
<p><b>Four audio columns to compare:</b></p>
<ul>
  <li><b>Bible</b>: original CABTAL recording.</li>
  <li><b>kNN-VC</b>: WavLM features + frozen HiFiGAN. Easy mode, metallic.</li>
  <li><b>OpenVoice v2</b>: flow-matching converter. Higher quality target.</li>
  <li><b>Edge TTS</b>: current production app voice (Swahili neural).</li>
</ul>
<p><b>Click the audio bars + rate.</b> If OpenVoice noticeably beats kNN-VC on the same words, the upgrade is worth a full rollout. If they sound about the same, the source-clip artifacts are the bottleneck and we drop the Bible-VC line.</p>
</div>""")
    parts.append("""<div class='toolbar'>
<button id='btn-download' class='primary'>Download ratings (JSON)</button>
<button id='btn-clear'>Clear</button>
<span class='stats' id='stats'>0 rated</span>
</div>""")
    parts.append("<table>")
    parts.append("<tr><th>#</th><th>Word</th><th>Bible (source)</th><th>kNN-VC</th><th>OpenVoice v2</th><th>Edge TTS</th><th>Best</th></tr>")
    for i, item in enumerate(items, 1):
        src_rel = f"../{item['clip']}"
        knn_rel = item.get("vc_clip", "")
        ov_rel  = item.get("ov_clip", "")
        edge_rel = item.get("edge_clip", "")
        feats = " ".join(escape(f) for f in item.get("features", []))
        rid = item['usfm'] + '_' + str(item.get('word_idx', 0))
        parts.append(f"<tr data-id='{escape(rid)}'>")
        parts.append(f"<td>{i}</td>")
        parts.append(f"<td><div class='awing'>{escape(item['word'])}</div>"
                     f"<div class='meta'>{escape(item['usfm'])} conf={item['conf']:.2f}</div>"
                     f"<div class='feat'>{feats}</div></td>")
        def _aud(rel):
            return ('<audio controls preload="none" src="' + escape(rel) + '"></audio>'
                    if rel else '<i style="color:#bbb">—</i>')
        parts.append("<td>" + _aud(src_rel) + "</td>")
        parts.append("<td>" + _aud(knn_rel) + "</td>")
        parts.append("<td>" + _aud(ov_rel) + "</td>")
        parts.append("<td>" + _aud(edge_rel) + "</td>")
        parts.append("<td><div class='rate-row'>"
                     "<button data-rating='bible'>Bible</button>"
                     "<button data-rating='knnvc'>kNN-VC</button>"
                     "<button data-rating='openvoice'>OpenVoice</button>"
                     "<button data-rating='edge'>Edge</button>"
                     "<button data-rating='equal'>All ok</button>"
                     "<button data-rating='bad'>None ok</button>"
                     "</div></td>")
        parts.append("</tr>")
    parts.append("</table>")
    parts.append("""<script>
const KEY = 'vc_bakeoff_ratings_""" + chapter_id + """';
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
    const counts = {bible:0,knnvc:0,openvoice:0,edge:0,equal:0,bad:0};
    Object.values(ratings).forEach(r => counts[r] = (counts[r]||0)+1);
    document.getElementById('stats').textContent =
        `${rated}/${total} rated -- Bible:${counts.bible} kNN-VC:${counts.knnvc} OpenVoice:${counts.openvoice} Edge:${counts.edge} all-ok:${counts.equal} bad:${counts.bad}`;
}
function save() { localStorage.setItem(KEY, JSON.stringify(ratings)); render(); }
document.addEventListener('click', e => {
    const b = e.target.closest('.rate-row button');
    if (!b) return;
    const tr = b.closest('tr[data-id]');
    if (!tr) return;
    const id = tr.dataset.id;
    if (ratings[id] === b.dataset.rating) { delete ratings[id]; }
    else { ratings[id] = b.dataset.rating; }
    save();
});
document.getElementById('btn-download').addEventListener('click', () => {
    if (Object.keys(ratings).length === 0) { alert('No ratings.'); return; }
    const payload = { chapter_id: '""" + chapter_id + """', rated_at: new Date().toISOString(), ratings };
    const blob = new Blob([JSON.stringify(payload, null, 2)], {type:'application/json'});
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = 'vc_bakeoff_ratings_""" + chapter_id + """.json';
    a.click(); URL.revokeObjectURL(a.href);
});
document.getElementById('btn-clear').addEventListener('click', () => {
    if (!confirm('Clear?')) return; ratings = {}; save();
});
render();
</script></body></html>""")

    viewer_path = out_dir / "vc_bakeoff.html"
    viewer_path.write_text("\n".join(parts), encoding="utf-8")
    print(f"Viewer: {viewer_path.relative_to(REPO)}")
    print(f"Open: file:///{str(viewer_path.resolve()).replace(chr(92), '/')}")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("command", choices=("run", "viewer", "both"))
    ap.add_argument("chapter_id")
    ap.add_argument("--max-words", type=int, default=15)
    args = ap.parse_args()
    if args.command in ("run", "both"):
        rc = cmd_run(args.chapter_id, args.max_words)
        if rc != 0:
            return rc
    if args.command in ("viewer", "both"):
        rc = cmd_viewer(args.chapter_id)
        if rc != 0:
            return rc
    return 0


if __name__ == "__main__":
    sys.exit(main())
