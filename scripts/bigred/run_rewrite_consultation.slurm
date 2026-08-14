#!/usr/bin/env bash
#SBATCH --job-name=hermes-rewrite-consult
#SBATCH --account=r01990
#SBATCH --partition=gpu
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --gres=gpu:1
#SBATCH --output=/N/scratch/tmsavich/hermes/work/%x_%j.out
#SBATCH --error=/N/scratch/tmsavich/hermes/work/%x_%j.err

# Ask a node-local model to restate every sentence the deterministic reader
# refused, then let SWI-Prolog decide whether the restatement can be read.
# Numerals and names are checked in Python before Prolog ever sees a candidate,
# so a restatement that quietly changed a number never reaches the gate.
#
# The valuable output is not only the admissions.  A faithful restatement the
# reader still refuses names a missing grammar class with a minimal example,
# and those accumulate into the demand list that grammar work follows.

set -euo pipefail

REPO="${SIDEKICK_REPO:-/N/scratch/tmsavich/hermes}"
ENV_BIN="/N/u/tmsavich/BigRed200/.conda/envs/umedcta/bin"
PYTHON="$ENV_BIN/python3"
MODEL="${CONSULT_MODEL:-/N/scratch/datahub/nvme/llms/quantized/gemma-4-26B-A4B-it/gemma-4-26B-A4B-it_Q4_K_M.gguf}"
SLOTS="${CONSULT_SLOTS:-6}"
PER_SLOT_CONTEXT="${CONSULT_CONTEXT:-8192}"
LIMIT="${CONSULT_LIMIT:-4000}"
GRADES="${CONSULT_GRADES:-}"
SOURCE="${CONSULT_SOURCE:-ledger}"
PORT="${LLAMA_PORT:-$((19000 + SLURM_JOB_ID % 10000))}"
OUT="${CONSULT_OUT:-$REPO/hermes/app/runtime/experiments/language/rewrite_consultation_bigred.jsonl}"

mkdir -p "$REPO/work" "$(dirname "$OUT")"
test -x "$PYTHON" || { echo "missing python: $PYTHON" >&2; exit 1; }
test -r "$MODEL" || { echo "missing model: $MODEL" >&2; exit 1; }
test -x "$ENV_BIN/swipl" || { echo "missing swipl" >&2; exit 1; }
if [ "$SOURCE" = "structure" ]; then
  test -r "$REPO/curriculum/im/generated/structure_task_rows.jsonl" || {
    echo "missing the anchored structure rows" >&2; exit 1;
  }
else
  test -r "$REPO/hermes/app/runtime/experiments/language/pusu_results.jsonl" || {
    echo "missing the PUSU ledger the refused sentences come from" >&2; exit 1;
  }
fi

# llama.cpp divides -c across -np slots. Ask for the product so a slot never
# silently receives a quarter of its context.
TOTAL_CONTEXT=$((PER_SLOT_CONTEXT * SLOTS))

echo "model:  $MODEL"
echo "slots:  $SLOTS at $PER_SLOT_CONTEXT each (total $TOTAL_CONTEXT)"
echo "limit:  $LIMIT sentences"
echo "source: $SOURCE"
echo "out:    $OUT"

module purge
module load llamacpp/gpu/06182026
export PATH="$ENV_BIN:$PATH"
export PYTHONPATH="$REPO:$REPO/scripts/language"

llama-server \
  -m "$MODEL" \
  --host 127.0.0.1 --port "$PORT" \
  -ngl 99 -c "$TOTAL_CONTEXT" -np "$SLOTS" \
  --jinja --reasoning off --no-ui \
  >"${TMPDIR:-/tmp}/llama-consult-${SLURM_JOB_ID}.log" 2>&1 &
SERVER_PID=$!
cleanup() {
  kill "$SERVER_PID" 2>/dev/null || true
  wait "$SERVER_PID" 2>/dev/null || true
  cp "${TMPDIR:-/tmp}/llama-consult-${SLURM_JOB_ID}.log" \
     "$REPO/work/llama-consult-${SLURM_JOB_ID}.log" 2>/dev/null || true
}
trap cleanup EXIT

for _ in $(seq 1 180); do
  curl -sf "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1 && { echo "server up"; break; }
  sleep 5
done
curl -sf "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1 || {
  echo "llama-server never became healthy" >&2
  tail -40 "${TMPDIR:-/tmp}/llama-consult-${SLURM_JOB_ID}.log" >&2 || true
  exit 1
}

cd "$REPO"
"$PYTHON" scripts/language/rewrite_consultation.py \
  --endpoint "http://127.0.0.1:${PORT}" \
  --model local \
  --limit "$LIMIT" \
  --grades "$GRADES" \
  --source "$SOURCE" \
  --workers "$SLOTS" \
  --max-tokens 1024 \
  --timeout 300 \
  --out "$OUT"

echo "consultations written: $(wc -l < "$OUT")"
