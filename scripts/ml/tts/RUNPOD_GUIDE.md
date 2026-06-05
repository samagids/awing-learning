# RunPod A100 — Bible TTS Fine-Tune Walkthrough (Coqui VITS)

Step-by-step guide to train a Coqui VITS TTS model on the 22-hour Awing
Bible corpus, then synthesize all 8,000+ vocab words in the Bible
narrator's voice.

**Total cost: ~$5–15. Total wall time: ~6 hours (most of it the GPU
training, which you don't have to babysit).**

> **Why Coqui VITS, not Piper?** Tried Piper first — `pip install
> piper-train==1.0.0` doesn't exist on PyPI. Coqui TTS has a clean pip
> install (`coqui-tts>=0.27` from idiap fork) and a well-documented VITS
> recipe. See CLAUDE.md Session 60 for the burn-rate timeline.

---

## Prerequisites (one-time, ~10 min)

1. **RunPod account** with $20 credit at https://runpod.io.
2. **runpodctl CLI** (recommended — much faster file upload than web UI):
   ```powershell
   # Direct download (winget doesn't have it)
   Invoke-WebRequest "https://github.com/runpod/runpodctl/releases/latest/download/runpodctl-windows-amd64.exe" -OutFile runpodctl.exe
   ```
3. **API key paired** with runpodctl. Get the key from
   https://runpod.io/console/user/settings → API Keys, then:
   ```powershell
   .\runpodctl.exe config --apiKey <YOUR_KEY>
   ```

## Step 1 — Prep the corpus on Windows (~5 min)

```powershell
cd C:\Users\samag\OneDrive\Documents\Claude\Awing
venv\Scripts\python.exe scripts\ml\tts\prep_training_data.py
```

This:
- Normalizes Bible text via `normalize_text.py`
- Copies WAVs into `corpus/aligned/normalized/`
- Packs everything into `corpus/aligned/bible_corpus_normalized.tar.gz`
  (~2-3 GB compressed)

## Step 2 — Spin up the RunPod A100

1. Go to https://runpod.io/console/pods
2. Click **+ Deploy**
3. Filter: **Secure Cloud > A100 SXM 80GB** (~$1.49/hr)
   - A100 PCIe 40GB ($0.69/hr) is fine too if 80GB unavailable
4. Template: **PyTorch 2.4** (`runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404`)
5. Container disk: **30 GB** (default)
6. Network volume: **50 GB** (RunPod often auto-creates this — keep it,
   it preserves your corpus across stop/start cycles for ~$0.005/hr)
7. Click **Deploy On-Demand**

Wait ~2 minutes for the pod to boot. Click **Connect → Web Terminal**
when the green dot appears.

## Step 3 — Upload corpus + scripts to the pod (~5 min)

```powershell
# On Windows — sends print a code like "abc-def-ghi"
.\runpodctl.exe send corpus\aligned\bible_corpus_normalized.tar.gz
.\runpodctl.exe send scripts\ml\tts\setup_runpod_coqui.sh
.\runpodctl.exe send scripts\ml\tts\finetune_vits_bible.py
```

```bash
# On the pod (web terminal) — paste each code as prompted
cd /workspace
runpodctl receive abc-def-ghi   # corpus
runpodctl receive xyz-...        # setup script
runpodctl receive pqr-...        # train script
```

## Step 4 — Run setup + training (one block, then walk away ~3-6 hours)

In the pod terminal:

```bash
cd /workspace

# Extract corpus (creates /workspace/bible_corpus_normalized/)
tar -xzf bible_corpus_normalized.tar.gz

# Bootstrap Coqui TTS env (~5 min)
bash setup_runpod_coqui.sh

# Activate venv and start training
source venv_coqui/bin/activate
nohup python finetune_vits_bible.py > /workspace/train.log 2>&1 &

# Verify training started
sleep 30
tail -30 /workspace/train.log
```

Healthy startup looks like:
- "GPU: NVIDIA A100-SXM4-80GB / VRAM: 80 GB"
- "✓ VITS config built / batch_size: 32"
- "→ 7,410 training samples / → 390 eval samples"
- Loss numbers appearing every 50 steps

**You can close your laptop now.** Training runs unattended. Set a
phone alarm for ~6 hours to come back and stop the pod.

Monitor mid-training (any new terminal):

```bash
tail -f /workspace/train.log                    # live training log
watch -n 5 nvidia-smi                            # GPU 80-95% = healthy
```

If it crashes with "out of memory": edit `finetune_vits_bible.py`,
change `BATCH_SIZE = 32` to `BATCH_SIZE = 16`, restart.

## Step 5 — Download the trained model (~2 min)

When `finetune_vits_bible.py` finishes, it prints:

```
✓ Model:  /workspace/awing_vits_voice.pth  (XXX MB)
✓ Config: /workspace/awing_vits_voice.json
DOWNLOAD these to your local machine, then STOP THE POD.
```

```bash
# On the pod — send each file
runpodctl send /workspace/awing_vits_voice.pth
runpodctl send /workspace/awing_vits_voice.json
```

```powershell
# On Windows
cd C:\Users\samag\OneDrive\Documents\Claude\Awing
mkdir models\awing_bible_voice
cd models\awing_bible_voice
..\..\runpodctl.exe receive <code-from-pod>   # .pth (~100-150 MB)
..\..\runpodctl.exe receive <code-from-pod>   # .json
```

## Step 6 — Stop the pod (CRITICAL — stops the billing meter)

1. https://runpod.io/console/pods
2. Click your pod → **Stop** (preserves data on network volume for
   ~$0.005/hr) or **Terminate** (deletes everything, $0 ongoing)

If you forget: $1.49/hr × 24 hr = $36/day. Set a phone alarm.

## Step 7 — Local test on 10 words (~2 min)

```powershell
cd C:\Users\samag\OneDrive\Documents\Claude\Awing
venv\Scripts\python.exe scripts\ml\tts\generate_vocab_clips.py --limit 10
```

Listen to one of the outputs:
```powershell
Start-Process android\install_time_assets\src\main\assets\audio\bible_trained\vocabulary\apene__banana.mp3
```

**Decision point:**
- **Sounds like the Bible narrator pronouncing Awing →** proceed to Step 8.
- **Sounds wrong / noise →** training likely didn't converge enough.
  Options: (a) re-deploy pod and resume training with more epochs,
  (b) ship current state, revisit later.

## Step 8 — Generate all 8k words (~45 min on GPU, ~5 hr on CPU)

```powershell
venv\Scripts\python.exe scripts\ml\tts\generate_vocab_clips.py
```

Resumable — skips already-generated files.

## Step 9 — Ship in the next app build

```powershell
.\scripts\build_and_run.bat
```

Build pipeline auto-detects `audio/bible_trained/`, runs Tier 2 OPUS
conversion on the new MP3s, packages into the PAD pack. Update
`pubspec.yaml` to `1.18.0+76` first (per 4-place version sync —
Session 48).

## What this gives you

- **8,000+ words pronounced in authentic Awing phonetics** (single
  Bible narrator voice)
- Edge TTS Swahili continues to handle ~1,095 words with rare phonemes
- Dr. Sama / family recordings still take priority for the words
  they covered
- Audio source priority order (`pronunciation_service.dart`):
  1. Community contributions (`audio/community/`)
  2. Native Dr. Sama / family (`audio/native/`)
  3. **Bible-trained Coqui VITS (`audio/bible_trained/`)** ← new
  4. Character voices (boy/girl/young_man/etc — Edge TTS Swahili)

## Troubleshooting

| Symptom | Fix |
|---|---|
| Pod won't deploy ("no capacity") | Try A100 PCIe 40GB instead |
| Out of memory during training | Edit `finetune_vits_bible.py`: `BATCH_SIZE = 16` |
| `coqui-tts` install fails | Pin pip first: `pip install pip==24.0` |
| Trained model produces noise | Need more epochs — re-run, monitor val_loss curve |
| ffmpeg missing locally | `winget install Gyan.FFmpeg` |

---

*Last updated: Session 60+ — Coqui VITS replacement after Piper
package abandonment. If RunPod's UI changes, check
https://docs.runpod.io.*
