#!/usr/bin/env bash
#SBATCH --job-name=sidekick-floors
#SBATCH --account=r01990
#SBATCH --partition=gpu
#SBATCH --time=03:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=48G
#SBATCH --gres=gpu:1
#SBATCH --output=/N/scratch/tmsavich/hermes/work/%x_%j.out
#SBATCH --error=/N/scratch/tmsavich/hermes/work/%x_%j.err

# 2026-08-18 sidekick disposition floors, cluster edition. The laptop run
# of this probe was killed at the owner's request (CPU heat); the same
# measurement runs here against the same tuned GGUF, served node-local.
# measure_floors.py checkpoints per item and resumes, so a requeue loses
# nothing. FLOORS_LIMIT / FLOORS_ARMS narrow the run for smokes.

set -euo pipefail

REPO="${FLOORS_REPO:-/N/scratch/tmsavich/hermes}"
ENV_BIN="/N/u/tmsavich/BigRed200/.conda/envs/umedcta/bin"
PYTHON="$ENV_BIN/python3"
MODEL="${FLOORS_MODEL:-$REPO/hermes/app/runtime/experiments/sidekick/models/sidekick-Q4_K_M.gguf}"
LIMIT="${FLOORS_LIMIT:-0}"
ARMS="${FLOORS_ARMS:-offered mandated}"
LABEL="${FLOORS_LABEL:-tuned-bigred-probev1}"
PORT="${LLAMA_PORT:-$((19000 + SLURM_JOB_ID % 10000))}"

mkdir -p "$REPO/work"
test -x "$PYTHON" || { echo "missing python: $PYTHON" >&2; exit 1; }
test -r "$MODEL" || { echo "missing model: $MODEL" >&2; exit 1; }

echo "model: $MODEL"
echo "arms:  $ARMS  limit: $LIMIT  label: $LABEL"

module purge
module load llamacpp/gpu/06182026
export PATH="$ENV_BIN:$PATH"

# The laptop-validated recipe: one slot, 8192 context, template from the
# GGUF via --jinja, reasoning off so a thinking budget cannot eat the reply.
llama-server \
  -m "$MODEL" \
  --host 127.0.0.1 --port "$PORT" \
  -ngl 99 -c 8192 -np 1 \
  --jinja --reasoning off --no-ui \
  >"${TMPDIR:-/tmp}/llama-floors-${SLURM_JOB_ID}.log" 2>&1 &
SERVER_PID=$!
cleanup() {
  kill "$SERVER_PID" 2>/dev/null || true
  wait "$SERVER_PID" 2>/dev/null || true
  cp "${TMPDIR:-/tmp}/llama-floors-${SLURM_JOB_ID}.log" \
     "$REPO/work/llama-floors-${SLURM_JOB_ID}.log" 2>/dev/null || true
}
trap cleanup EXIT

for _ in $(seq 1 180); do
  curl -sf "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1 && { echo "server up"; break; }
  sleep 5
done
curl -sf "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1 || {
  echo "llama-server never became healthy" >&2
  tail -40 "${TMPDIR:-/tmp}/llama-floors-${SLURM_JOB_ID}.log" >&2 || true
  exit 1
}

# One visible round-trip before the probe: non-empty content proves the
# template and the reasoning flag took, per the local validation.
curl -sf "http://127.0.0.1:${PORT}/v1/chat/completions" \
  -H 'Content-Type: application/json' \
  -d '{"model":"local","messages":[{"role":"user","content":"What is 3 + 4? Answer with the number only."}],"max_tokens":30,"temperature":0}' \
  | "$PYTHON" -c 'import json,sys; c=json.load(sys.stdin)["choices"][0]["message"]["content"]; print("round-trip content:", repr(c)); sys.exit(0 if c.strip() else 1)'

cd "$REPO"
LIMIT_ARGS=()
if [ "$LIMIT" != "0" ]; then LIMIT_ARGS=(--limit "$LIMIT"); fi
# shellcheck disable=SC2086
"$PYTHON" scripts/sidekick/measure_floors.py \
  --backend openai \
  --endpoint "http://127.0.0.1:${PORT}/v1/chat/completions" \
  --model local \
  --arms $ARMS \
  --timeout 600 \
  --label "$LABEL" \
  "${LIMIT_ARGS[@]}"
echo "floors run finished"
