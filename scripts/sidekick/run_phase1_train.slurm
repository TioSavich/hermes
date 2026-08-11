#!/usr/bin/env bash
#SBATCH --job-name=sidekick-phase1
#SBATCH --account=r01990
#SBATCH --partition=gpu
#SBATCH --time=4:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=96G
#SBATCH --gres=gpu:1
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# Phase 1: LoRA the disposition to ask, then make the artifact the project
# actually reports — a Q4_K_M GGUF a teacher's laptop can serve.
#
# The sequence is: a short smoke at the new sequence length to confirm the
# activation headroom that ruling 4 declined to assume, then the full run, then
# merge, convert, and quantize. Each step is judged by an artifact on disk
# rather than by an exit status.
#
# The run ends by writing sidekick-Q4_K_M.gguf.sha256 beside the weights. On the
# receiving side, compare before serving:
#
#   shasum -a 256 sidekick-Q4_K_M.gguf | cut -d" " -f1
#   # must equal the first field of the .sha256 written here
#
# Artifact identity then reproduces from this file rather than from anyone
# remembering which copy was measured.

set -euo pipefail

STAGE="${SIDEKICK_STAGE:-/N/slate/tmsavich/sidekick}"
VENV="$STAGE/envs/umedcta-tune"
PY="$VENV/bin/python3"
RUN_DIR="$STAGE/runs/phase1-${SLURM_JOB_ID:-local}"
SNAPSHOT=/N/scratch/tmsavich/hf/hub/models--google--gemma-4-E2B-it/snapshots/3e22461f65e89153144f8adb70e3b8c2cc9845a7
ROWS="$STAGE/data/sidekick-6000.jsonl"
TOOLS="$STAGE/data/core_tools.json"
EPOCHS="${EPOCHS:-3}"

export HF_HOME=/N/scratch/tmsavich/hf
export HF_HUB_OFFLINE=1
export TRANSFORMERS_OFFLINE=1
export TOKENIZERS_PARALLELISM=false
export SIDEKICK_GEMMA_ASSETS="$SNAPSHOT"
export PYTHONPATH="$STAGE/scripts"

mkdir -p "$STAGE/logs" "$RUN_DIR"
[ -s "$ROWS" ] || { echo "no rows at $ROWS"; exit 1; }
[ -s "$SNAPSHOT/model.safetensors" ] || { echo "no base weights at $SNAPSHOT"; exit 1; }
[ -x "$PY" ] || { echo "no tuning environment at $VENV"; exit 1; }

nvidia-smi --query-gpu=name,memory.total --format=csv,noheader

echo "[1] twenty steps at 4096 — the headroom check ruling 4 asked for"
"$PY" "$STAGE/scripts/train_sidekick.py" \
  --rows "$ROWS" --tools "$TOOLS" --model "$SNAPSHOT" \
  --output "$RUN_DIR/smoke" --max-steps 20 --save-steps 10 --max-length 4096
[ -s "$RUN_DIR/smoke/adapter/adapter_model.safetensors" ] || { echo "smoke produced no adapter"; exit 1; }
nvidia-smi --query-gpu=memory.used --format=csv,noheader

echo "[2] the full run"
"$PY" "$STAGE/scripts/train_sidekick.py" \
  --rows "$ROWS" --tools "$TOOLS" --model "$SNAPSHOT" \
  --output "$RUN_DIR/full" --epochs "$EPOCHS" --save-steps 50 --max-length 4096 --resume
ADAPTER="$RUN_DIR/full/adapter"
[ -s "$ADAPTER/adapter_model.safetensors" ] || { echo "no adapter at $ADAPTER"; exit 1; }
cat "$RUN_DIR/full/throughput.json"

echo "[3] merge the adapter into the base weights"
"$PY" "$STAGE/scripts/merge_adapter.py" --base "$SNAPSHOT" --adapter "$ADAPTER" --output "$RUN_DIR/merged"
[ -s "$RUN_DIR/merged/config.json" ] || { echo "merge wrote no config"; exit 1; }

echo "[4] convert to GGUF and quantize to Q4_K_M"
set +u
module purge
module load llamacpp/gpu/06182026
set -u
"$PY" "$STAGE/llama.cpp/convert_hf_to_gguf.py" "$RUN_DIR/merged" \
  --outfile "$RUN_DIR/sidekick-f16.gguf" --outtype f16
[ -s "$RUN_DIR/sidekick-f16.gguf" ] || { echo "conversion produced no gguf"; exit 1; }
llama-quantize "$RUN_DIR/sidekick-f16.gguf" "$RUN_DIR/sidekick-Q4_K_M.gguf" Q4_K_M
[ -s "$RUN_DIR/sidekick-Q4_K_M.gguf" ] || { echo "quantization produced no gguf"; exit 1; }

# The identity of the file that gets served, recorded where the file is.
sha256sum "$RUN_DIR/sidekick-Q4_K_M.gguf" | tee "$RUN_DIR/sidekick-Q4_K_M.gguf.sha256"
[ -s "$RUN_DIR/sidekick-Q4_K_M.gguf.sha256" ] || { echo "no checksum written"; exit 1; }

ls -la "$RUN_DIR"/*.gguf "$RUN_DIR"/*.sha256
echo "PHASE1_TRAIN_DONE $RUN_DIR"
