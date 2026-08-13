#!/usr/bin/env bash
#SBATCH --job-name=sidekick-wave5
#SBATCH --account=r01990
#SBATCH --partition=gpu
#SBATCH --time=8:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=96G
#SBATCH --gres=gpu:1
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# Wave 5 trains the untuned E2B checkpoint on three legs of plain replies:
# solution programs, curriculum questions, and the untuned checkpoint's own
# answers to ordinary teaching prompts. No row calls a tool.
#
# Two parameters move from wave 3, both pre-registered. The adapter rank drops
# from 32 to 16, the forgetting-guard trade named in the wave-5 design. The
# scaling factor alpha holds its wave-3 relation to the rank (alpha = 2r), so
# lowering the rank lowers capacity without also doubling the update scale.
# Every other training parameter is held: 3 epochs, 4096 max_seq_len, batch 1,
# accumulation 32, dropout 0.05, learning rate 1e-4, drop-not-truncate.
#
# A short smoke runs before the full pass, and each stage must leave its
# expected artifact on disk before the next stage starts.

set -euo pipefail

STAGE="${SIDEKICK_STAGE:-/N/slate/tmsavich/sidekick}"
VENV="$STAGE/envs/umedcta-tune"
PY="$VENV/bin/python3"
RUN_DIR="$STAGE/runs/wave5-${SLURM_JOB_ID:-local}"
SNAPSHOT=/N/scratch/tmsavich/hf/hub/models--google--gemma-4-E2B-it/snapshots/3e22461f65e89153144f8adb70e3b8c2cc9845a7
SEQUENCES="$STAGE/data/sidekick-wave5-seqs.jsonl"
DATASET_SHA=dd1b688d6e875dec1a292798ecd236771e8029e260ba0a385cf0179d5810a0bd
TOOLS="$STAGE/data/core_tools.json"
EPOCHS=3
RANK=16
ALPHA=32

export HF_HOME=/N/scratch/tmsavich/hf
export HF_HUB_OFFLINE=1
export TRANSFORMERS_OFFLINE=1
export TOKENIZERS_PARALLELISM=false
export SIDEKICK_GEMMA_ASSETS="$SNAPSHOT"
export PYTHONPATH="$STAGE/scripts"

mkdir -p "$STAGE/logs" "$RUN_DIR"
[ -s "$SEQUENCES" ] || { echo "no sequences at $SEQUENCES"; exit 1; }
[ -s "$TOOLS" ] || { echo "no tool declarations at $TOOLS"; exit 1; }
[ -s "$SNAPSHOT/model.safetensors" ] || { echo "no base weights at $SNAPSHOT"; exit 1; }
[ -x "$PY" ] || { echo "no tuning environment at $VENV"; exit 1; }

ACTUAL_DATASET_SHA="$(sha256sum "$SEQUENCES" | cut -d" " -f1)"
[ "$ACTUAL_DATASET_SHA" = "$DATASET_SHA" ] || {
  echo "sequence dataset sha mismatch: expected $DATASET_SHA got $ACTUAL_DATASET_SHA"
  exit 1
}

echo "[0] the mask checker meets four deliberate corruptions before any training"
"$PY" - <<'PYCHECK'
import os
import sys

sys.path.insert(0, os.environ["PYTHONPATH"])
from chat_format import GemmaChatFormat
from supervision import check_plain_reply_corruptions

caught = check_plain_reply_corruptions(GemmaChatFormat())
if caught != 4:
    raise SystemExit(f"the plain-reply mask checker caught {caught} of 4 corruptions")
print(f"mask checker caught {caught} of 4 corruptions")
PYCHECK

GPU_INVENTORY="$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader)"
echo "$GPU_INVENTORY"
case "$GPU_INVENTORY" in
  *A100*) ;;
  *) echo "wave 5 requires an A100"; exit 1 ;;
esac

echo "[1] twenty steps at 4096 for A100 headroom"
"$PY" "$STAGE/scripts/train_sidekick.py" \
  --sequences "$SEQUENCES" --dataset-sha "$DATASET_SHA" \
  --tools "$TOOLS" --model "$SNAPSHOT" \
  --output "$RUN_DIR/smoke" --max-steps 20 --save-steps 10 --max-length 4096 \
  --batch-size 1 --accumulation 32 --rank "$RANK" --alpha "$ALPHA" --dropout 0.05 \
  --learning-rate 1e-4
[ -s "$RUN_DIR/smoke/adapter/adapter_model.safetensors" ] || {
  echo "smoke produced no adapter"
  exit 1
}
nvidia-smi --query-gpu=memory.used --format=csv,noheader

echo "[2] three held epochs with resumable checkpoints"
"$PY" "$STAGE/scripts/train_sidekick.py" \
  --sequences "$SEQUENCES" --dataset-sha "$DATASET_SHA" \
  --tools "$TOOLS" --model "$SNAPSHOT" \
  --output "$RUN_DIR/full" --epochs "$EPOCHS" --save-steps 50 \
  --max-length 4096 --batch-size 1 --accumulation 32 --rank "$RANK" --alpha "$ALPHA" \
  --dropout 0.05 --learning-rate 1e-4 --resume
ADAPTER="$RUN_DIR/full/adapter"
[ -s "$ADAPTER/adapter_model.safetensors" ] || { echo "no adapter at $ADAPTER"; exit 1; }
[ -s "$RUN_DIR/full/throughput.json" ] || { echo "no throughput record"; exit 1; }
cat "$RUN_DIR/full/throughput.json"

echo "[3] merge the adapter into the base weights"
"$PY" "$STAGE/scripts/merge_adapter.py" \
  --base "$SNAPSHOT" --adapter "$ADAPTER" --output "$RUN_DIR/merged"
[ -s "$RUN_DIR/merged/config.json" ] || { echo "merge wrote no config"; exit 1; }

echo "[4] convert merged weights to f16 GGUF"
set +u
module purge
module load llamacpp/gpu/06182026
set -u
"$PY" "$STAGE/llama.cpp/convert_hf_to_gguf.py" "$RUN_DIR/merged" \
  --outfile "$RUN_DIR/sidekick-wave5-f16.gguf" --outtype f16
[ -s "$RUN_DIR/sidekick-wave5-f16.gguf" ] || { echo "conversion produced no f16 GGUF"; exit 1; }

echo "[5] quantize f16 GGUF to Q4_K_M"
llama-quantize \
  "$RUN_DIR/sidekick-wave5-f16.gguf" \
  "$RUN_DIR/sidekick-wave5-Q4_K_M.gguf" \
  Q4_K_M
[ -s "$RUN_DIR/sidekick-wave5-Q4_K_M.gguf" ] || { echo "quantization produced no Q4_K_M GGUF"; exit 1; }

echo "[6] write the served-weight identity beside the weights"
sha256sum "$RUN_DIR/sidekick-wave5-Q4_K_M.gguf" \
  | tee "$RUN_DIR/sidekick-wave5-Q4_K_M.gguf.sha256"
[ -s "$RUN_DIR/sidekick-wave5-Q4_K_M.gguf.sha256" ] || { echo "no checksum written"; exit 1; }

ls -la "$RUN_DIR"/*.gguf "$RUN_DIR"/*.sha256
echo "WAVE5_TRAIN_DONE $RUN_DIR"
