#!/usr/bin/env bash
#SBATCH --job-name=hermes-lesson-structure
#SBATCH --account=r01990
#SBATCH --partition=gpu
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --gres=gpu:1
#SBATCH --output=/N/scratch/tmsavich/hermes/work/%x_%j.out
#SBATCH --error=/N/scratch/tmsavich/hermes/work/%x_%j.err

# Read every IM lesson guide for its document structure with a node-local
# model.  Compute nodes carry no external network, so the model is served on
# the node and the driver speaks to it over loopback.  The driver checkpoints
# one JSONL row per lesson and resumes, so a wall-clock limit costs nothing
# but the lesson in flight.

set -euo pipefail

REPO="${SIDEKICK_REPO:-/N/scratch/tmsavich/hermes}"
ENV_BIN="/N/u/tmsavich/BigRed200/.conda/envs/umedcta/bin"
PYTHON="$ENV_BIN/python3"
MODEL="${STRUCTURE_MODEL:-/N/scratch/datahub/nvme/llms/quantized/gemma-4-26B-A4B-it/gemma-4-26B-A4B-it_Q4_K_M.gguf}"
SLOTS="${STRUCTURE_SLOTS:-4}"
PER_SLOT_CONTEXT="${STRUCTURE_CONTEXT:-32768}"
SAMPLE="${STRUCTURE_SAMPLE:-900}"
PORT="${LLAMA_PORT:-$((18000 + SLURM_JOB_ID % 10000))}"
OUT="${STRUCTURE_OUT:-$REPO/hermes/app/runtime/experiments/language/lesson_structure_bigred.jsonl}"

mkdir -p "$REPO/work" "$(dirname "$OUT")"
test -x "$PYTHON" || { echo "missing python: $PYTHON" >&2; exit 1; }
test -r "$MODEL" || { echo "missing model: $MODEL" >&2; exit 1; }
test -d "$REPO/curriculum/im_teacher_guides" || { echo "missing guides" >&2; exit 1; }

# llama.cpp divides -c across -np slots, so ask for slots times the per-slot
# context and never less.  A slot that silently receives a quarter of the
# context truncates the lesson and the reply reads as caution.
TOTAL_CONTEXT=$((PER_SLOT_CONTEXT * SLOTS))

echo "model:    $MODEL"
echo "slots:    $SLOTS at $PER_SLOT_CONTEXT each (total $TOTAL_CONTEXT)"
echo "out:      $OUT"

module purge
module load llamacpp/gpu/06182026
export PATH="$ENV_BIN:$PATH"
export PYTHONPATH="$REPO:$REPO/scripts/research"

llama-server \
  -m "$MODEL" \
  --host 127.0.0.1 --port "$PORT" \
  -ngl 99 -c "$TOTAL_CONTEXT" -np "$SLOTS" \
  --jinja --reasoning off --no-ui \
  >"${TMPDIR:-/tmp}/llama-server-${SLURM_JOB_ID}.log" 2>&1 &
SERVER_PID=$!
cleanup() {
  kill "$SERVER_PID" 2>/dev/null || true
  wait "$SERVER_PID" 2>/dev/null || true
  cp "${TMPDIR:-/tmp}/llama-server-${SLURM_JOB_ID}.log" \
     "$REPO/work/llama-server-${SLURM_JOB_ID}.log" 2>/dev/null || true
}
trap cleanup EXIT

# Wait for the server rather than guessing at a sleep.  Artifacts, not
# elapsed time, establish that it is up.
for _ in $(seq 1 180); do
  if curl -sf "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1; then
    echo "server up"
    break
  fi
  sleep 5
done
curl -sf "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1 || {
  echo "llama-server never became healthy" >&2
  tail -40 "${TMPDIR:-/tmp}/llama-server-${SLURM_JOB_ID}.log" >&2 || true
  exit 1
}

cd "$REPO"
"$PYTHON" scripts/curriculum/discover_lesson_structure.py \
  --endpoint "http://127.0.0.1:${PORT}" \
  --model local \
  --sample "$SAMPLE" \
  --workers "$SLOTS" \
  --max-tokens 16384 \
  --out "$OUT"

echo "rows written: $(wc -l < "$OUT")"
