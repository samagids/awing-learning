#!/bin/bash
# setup_runpod_coqui.sh — Coqui TTS VITS training environment
#
# Replaces the failed Piper attempt. Coqui TTS has a clean pip install
# and a well-documented VITS training recipe — no GitHub source builds,
# no exotic dependencies.
#
# Run inside the pod:
#   cd /workspace && bash setup_runpod_coqui.sh

set -euo pipefail

echo "============================================================"
echo " RunPod A100 — Coqui VITS Bible fine-tune environment"
echo "============================================================"

# 1. GPU sanity
echo
echo "[1/4] Verifying GPU..."
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader | head -1

# 2. System deps
echo
echo "[2/4] Installing system packages..."
apt-get update -qq
apt-get install -yqq python3-venv python3-pip ffmpeg libsndfile1 sox > /dev/null
echo "  ✓ apt packages installed"

# 3. Python venv with --system-site-packages so we inherit the pod's
# pre-installed torch + torchcodec (matched to the pod's CUDA libs).
# DO NOT pip-install torch in the venv — it grabs the latest wheel
# whose torchcodec build references libnvrtc.so.13 (CUDA 13), but
# RunPod base images ship CUDA 12.8 (libnvrtc.so.12). That mismatch
# burned ~30 min of dep churn before we figured this out.
echo
echo "[3/4] Creating Python venv at /workspace/venv_coqui (with system packages)..."
cd /workspace
if [[ -d venv_coqui ]]; then
    rm -rf venv_coqui
fi
python3 -m venv --system-site-packages venv_coqui
source venv_coqui/bin/activate
pip install --quiet --upgrade pip setuptools wheel

echo
echo "[4/4] Installing Coqui TTS on top of inherited torch (~3 min)..."

# Verify the pod's torch was inherited (sanity check before installing)
python3 -c "import torch; print(f'  inherited torch={torch.__version__}, CUDA={torch.cuda.is_available()}')"
python3 -c "import torchcodec; print(f'  inherited torchcodec={torchcodec.__version__}')"

# Coqui TTS (active fork at idiap/coqui-ai-TTS).
# Critical pins (DO NOT relax without verifying — Sessions 54+60 burned hours):
#   - NO "torch" listed — inherited from system Python, version-matched
#     to the pod's CUDA. Listing torch here pulls a wheel that mismatches
#     libnvrtc.so version.
#   - NO "trainer" — old PyPI package caps at Python <3.12. Idiap fork
#     uses `coqui-tts-trainer` (pulled transitively by coqui-tts).
#   - NO [codec] extra — torchcodec is already in the system Python.
#   - transformers MUST be >=4.55,<5.0 — narrow window where coqui-tts
#     0.27 can find BOTH `is_torchcodec_available` (added in 4.55) AND
#     `isin_mps_friendly` (removed in 5.0 but still imported by
#     TTS.tts.layers.tortoise.autoregressive).
pip install --quiet \
    "coqui-tts>=0.27" \
    "transformers>=4.55,<5.0" \
    "librosa>=0.10" \
    "numpy<2" \
    "scipy" \
    "soundfile" \
    "tensorboard" \
    "matplotlib"

echo "  ✓ Coqui TTS installed"

# Verify imports work (TTS module + trainer pulled in transitively)
python3 -c "from TTS.tts.configs.vits_config import VitsConfig; print('  ✓ TTS import OK')"
python3 -c "from trainer import Trainer; print('  ✓ trainer import OK')"

echo
echo "============================================================"
echo " Setup complete. Next step:"
echo "   source /workspace/venv_coqui/bin/activate"
echo "   python /workspace/finetune_vits_bible.py"
echo "============================================================"
