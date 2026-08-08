#!/usr/bin/env bash
# Submit from scripts/research/ab_experiment after preparing the Slurm log path:
#   mkdir -p work
#   sbatch --export=ALL,ARM=compiler run_ab.slurm
#   sbatch --export=ALL,ARM=questionnaire run_ab.slurm
#SBATCH --job-name=hermes-ab
#SBATCH --account=r01990
#SBATCH --partition=gpu
#SBATCH --time=4:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --gres=gpu:1
#SBATCH --output=work/%x_%j.out
#SBATCH --error=work/%x_%j.err

set -euo pipefail

ARM="${ARM:?set ARM=compiler or ARM=questionnaire}"
case "$ARM" in
  compiler|questionnaire) ;;
  *) echo "ARM must be compiler or questionnaire"; exit 2 ;;
esac

REPO="${HERMES_REPO:-/N/scratch/tmsavich/hermes}"
DRIVER="$REPO/scripts/research/ab_experiment"
OUTPUT_ROOT="$REPO/hermes/app/runtime/experiments/ab_2026_08"
MODEL_TAG="${MODEL_TAG:-gemma-4-E2B-it}"
MODEL="/N/scratch/datahub/nvme/llms/quantized/${MODEL_TAG}/${MODEL_TAG}_Q4_K_M.gguf"
PORT="${LLAMA_PORT:-$((21000 + SLURM_JOB_ID % 900))}"
RUN_DIR="${RESUME_DIR:-$OUTPUT_ROOT/${ARM}-${SLURM_JOB_ID}}"
case "$RUN_DIR" in
  "$OUTPUT_ROOT"/*) ;;
  *) echo "RESUME_DIR must be under $OUTPUT_ROOT"; exit 2 ;;
esac
mkdir -p "$OUTPUT_ROOT" "$RUN_DIR"
[ -s "$MODEL" ] || { echo "no weights at $MODEL"; exit 1; }

export HF_HOME=/N/scratch/tmsavich/.cache/huggingface
export HF_HUB_OFFLINE=1
export HF_DATASETS_OFFLINE=1

set +u
module purge
module load conda/25.3.0
module load llamacpp/gpu/06182026
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${HERMES_ENV:-umedcta}"
set -u
echo "environment: python=$(command -v python3) swipl=$(command -v swipl)"

SERVER_PID=""
SERVER_LOG="${TMPDIR:?}/llama-server-${SLURM_JOB_ID}.log"
cleanup() {
  [ -n "$SERVER_PID" ] && kill "$SERVER_PID" 2>/dev/null || true
  cp "$SERVER_LOG" "$RUN_DIR/llama-server.log" 2>/dev/null || true
}
trap cleanup EXIT

start_server() {
  : > "$SERVER_LOG"
  llama-server -m "$MODEL" --host 127.0.0.1 --port "$PORT" \
    -ngl 99 -c 8192 -np 1 --jinja --no-ui "$@" \
    >>"$SERVER_LOG" 2>&1 &
  SERVER_PID=$!
  for _ in $(seq 1 240); do
    kill -0 "$SERVER_PID" 2>/dev/null || return 1
    if curl --silent --fail "http://127.0.0.1:$PORT/health" >/dev/null; then
      return 0
    fi
    sleep 2
  done
  return 1
}

REASONING_FLAG="--reasoning off"
if ! start_server --reasoning off; then
  [ -n "$SERVER_PID" ] && kill "$SERVER_PID" 2>/dev/null || true
  SERVER_PID=""
  REASONING_FLAG="--reasoning-budget 0"
  start_server --reasoning-budget 0 || {
    echo "llama-server did not become healthy with either reasoning-off spelling"
    tail -40 "$SERVER_LOG"
    exit 1
  }
fi
echo "llama-server healthy on port $PORT with -c 8192 -np 1 $REASONING_FLAG"

cd "$REPO"
ENDPOINT="http://127.0.0.1:$PORT/v1/chat/completions"
python3 "$DRIVER/preflight.py" --model "$MODEL_TAG" --endpoint "$ENDPOINT"
python3 "$DRIVER/arm_${ARM}.py" \
  --model "$MODEL_TAG" \
  --endpoint "$ENDPOINT" \
  --ledger "$RUN_DIR/${ARM}.jsonl"
echo "AB ARM COMPLETE arm=$ARM run_dir=$RUN_DIR"
