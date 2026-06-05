#!/bin/bash
# setup_runpod.sh — One-shot RunPod A100 environment bootstrap
#
# Run this INSIDE the RunPod pod (NOT on your local machine).
# Spins up a fresh Python venv with everything needed to fine-tune Piper
# on the Bible corpus.
#
# Usage on the pod:
#   cd /workspace
#   tar -xzf bible_corpus_normalized.tar.gz
#   bash setup_runpod.sh
#
# Expected wall time: ~5-10 minutes (downloading torch, piper-train, etc.)
# Expected disk: ~8 GB (mostly torch + piper checkpoints)

set -euo pipefail

echo "============================================================"
echo " RunPod A100 — Piper Bible fine-tune environment setup"
echo "============================================================"

# 1. Sanity: GPU present?
echo
echo "[1/5] Verifying GPU..."
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader | head -1 \
    || { echo "  ✗ no GPU detected — abort"; exit 1; }

# 2. System deps
echo
echo "[2/5] Installing system packages..."
apt-get update -qq
apt-get install -yqq python3-venv python3-pip ffmpeg sox libsndfile1 git \
    > /dev/null
echo "  ✓ apt packages installed"

# 3. Python venv
echo
echo "[3/5] Creating Python venv at /workspace/venv_piper..."
cd /workspace
python3 -m venv venv_piper
source venv_piper/bin/activate
pip install --quiet --upgrade pip setuptools wheel

# 4. Piper training dependencies
# Pinned versions known-good as of 2025 (Piper development is loose; pinning
# avoids surprise breaking changes).
echo
echo "[4/5] Installing PyTorch + Piper training stack (~5 min)..."
# PyTorch with CUDA 12.1 — works on RunPod A100 default images
pip install --quiet \
    torch==2.4.1 torchvision==0.19.1 torchaudio==2.4.1 \
    --index-url https://download.pytorch.org/whl/cu121

# Piper training fork (the one that actually trains, not the playback CLI)
pip install --quiet \
    "piper-train==1.0.0" \
    "librosa>=0.10" \
    "numpy<2" \
    "scipy" \
    "soundfile" \
    "tensorboard" \
    "pytorch-lightning>=2.0,<2.5"

echo "  ✓ Piper + dependencies installed"

# 5. Download base Piper checkpoint (Akoose — the only Cameroon Bantu model
# in Piper's library; provides Bantu phonology foundation)
echo
echo "[5/5] Downloading base Piper Akoose checkpoint..."
mkdir -p /workspace/piper_base
cd /workspace/piper_base
if [[ ! -f sw_CD-lanfrica-medium.onnx ]]; then
    wget -q --show-progress \
        "https://huggingface.co/rhasspy/piper-voices/resolve/main/sw/sw_CD/lanfrica/medium/sw_CD-lanfrica-medium.onnx" \
        -O sw_CD-lanfrica-medium.onnx
    wget -q --show-progress \
        "https://huggingface.co/rhasspy/piper-voices/resolve/main/sw/sw_CD/lanfrica/medium/sw_CD-lanfrica-medium.onnx.json" \
        -O sw_CD-lanfrica-medium.onnx.json
fi
echo "  ✓ base checkpoint ready ($(du -h sw_CD-lanfrica-medium.onnx | cut -f1))"

echo
echo "============================================================"
echo " Setup complete. Activate the venv before running training:"
echo "   source /workspace/venv_piper/bin/activate"
echo "   python /workspace/finetune_bible.py"
echo "============================================================"
