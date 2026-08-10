#!/usr/bin/env bash
#SBATCH --job-name=sidekick-lawzero
#SBATCH --account=r01990
#SBATCH --partition=gpu-debug
#SBATCH --time=0:55:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --gres=gpu:1
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# Law zero for the sidekick program: one end-to-end proof before any long
# job. Load the base weights, take a few steps, write a checkpoint, resume
# from it, and confirm the adapter exists as a file rather than as an exit
# status. It also reports tokens per second, which replaces the design's
# estimate band.
#
# The login node has no GPU, so this proof runs on gpu-debug (one hour).

set -euo pipefail

STAGE="${SIDEKICK_STAGE:-/N/slate/tmsavich/sidekick}"
VENV="$STAGE/envs/umedcta-tune"
RUN_DIR="$STAGE/runs/lawzero-${SLURM_JOB_ID:-local}"
SNAPSHOT=/N/scratch/tmsavich/hf/hub/models--google--gemma-4-E2B-it/snapshots/3e22461f65e89153144f8adb70e3b8c2cc9845a7

export HF_HOME=/N/scratch/tmsavich/hf
export HF_HUB_OFFLINE=1
export TRANSFORMERS_OFFLINE=1
export TOKENIZERS_PARALLELISM=false
export SIDEKICK_GEMMA_ASSETS="$SNAPSHOT"
export PYTHONPATH="$STAGE/scripts"

mkdir -p "$STAGE/logs" "$RUN_DIR"
[ -s "$SNAPSHOT/model.safetensors" ] || { echo "no base weights at $SNAPSHOT"; exit 1; }
[ -x "$VENV/bin/python3" ] || { echo "no tuning environment at $VENV"; exit 1; }

nvidia-smi --query-gpu=name,memory.total --format=csv,noheader

echo "[1] twenty steps from the base weights"
"$VENV/bin/python3" "$STAGE/scripts/train_sidekick.py" \
  --rows "$STAGE/data/pilot-200.jsonl" \
  --tools "$STAGE/data/core_tools.json" \
  --model "$SNAPSHOT" \
  --output "$RUN_DIR" \
  --max-steps 20 --save-steps 10

CHECKPOINT="$(ls -d "$RUN_DIR"/checkpoint-* 2>/dev/null | sort -t- -k2 -n | tail -1 || true)"
[ -n "$CHECKPOINT" ] || { echo "no checkpoint written"; exit 1; }
echo "[2] checkpoint present: $CHECKPOINT"
ls -la "$CHECKPOINT" | head -20

echo "[3] resume from that checkpoint for ten more steps"
"$VENV/bin/python3" "$STAGE/scripts/train_sidekick.py" \
  --rows "$STAGE/data/pilot-200.jsonl" \
  --tools "$STAGE/data/core_tools.json" \
  --model "$SNAPSHOT" \
  --output "$RUN_DIR" \
  --max-steps 30 --save-steps 10 --resume

ADAPTER="$RUN_DIR/adapter/adapter_model.safetensors"
[ -s "$ADAPTER" ] || { echo "no adapter file at $ADAPTER"; exit 1; }
echo "[4] adapter present: $(du -h "$ADAPTER" | cut -f1) $ADAPTER"
cat "$RUN_DIR/throughput.json"
echo "LAWZERO_PASS $RUN_DIR"
