#!/usr/bin/env bash
#SBATCH --job-name=hermes-recovery-wave
#SBATCH --account=r01990
#SBATCH --partition=gpu
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --gres=gpu:1
#SBATCH --output=/N/scratch/tmsavich/hermes/work/%x_%j.out
#SBATCH --error=/N/scratch/tmsavich/hermes/work/%x_%j.err

# 2026-08-18 coverage-recovery wave: three modes (figure_context, render_spec,
# explanation_form) over 1,844 records the base coverage grind never
# addressed, sharing the proven grind job's structure (run_coverage_grind.slurm)
# — one node-local llama-server, N parallel driver shards, per-item
# checkpoint/resume. render_spec additionally shells out to a standalone
# Prolog gate (render_spec_gate.pl) per candidate that never loads the
# worker, only the one render module the proposed op names.

set -euo pipefail

REPO="${GRIND_REPO:-/N/scratch/tmsavich/hermes}"
ENV_BIN="/N/u/tmsavich/BigRed200/.conda/envs/umedcta/bin"
PYTHON="$ENV_BIN/python3"
SWIPL="$ENV_BIN/swipl"
MODEL="${GRIND_MODEL:-/N/scratch/datahub/nvme/llms/quantized/gemma-4-26B-A4B-it/gemma-4-26B-A4B-it_Q4_K_M.gguf}"
SLOTS="${GRIND_SLOTS:-6}"
PER_SLOT_CONTEXT="${GRIND_CONTEXT:-8192}"
LIMIT="${GRIND_LIMIT:-0}"
PORT="${LLAMA_PORT:-$((19000 + SLURM_JOB_ID % 10000))}"
TARGETS="${GRIND_TARGETS:-$REPO/coverage_grind/recovery_wave_targets.jsonl}"
GATE_SCRIPT="${GRIND_GATE_SCRIPT:-$REPO/scripts/coverage/render_spec_gate.pl}"
OUTDIR="$REPO/coverage_grind/recovery_out_${SLURM_JOB_ID}"

mkdir -p "$REPO/work" "$OUTDIR"
test -x "$PYTHON" || { echo "missing python: $PYTHON" >&2; exit 1; }
test -x "$SWIPL" || { echo "missing swipl: $SWIPL" >&2; exit 1; }
test -r "$MODEL" || { echo "missing model: $MODEL" >&2; exit 1; }
test -r "$TARGETS" || { echo "missing targets jsonl" >&2; exit 1; }
test -r "$GATE_SCRIPT" || { echo "missing render_spec_gate.pl" >&2; exit 1; }

TOTAL_CONTEXT=$((PER_SLOT_CONTEXT * SLOTS))
echo "model:  $MODEL"
echo "slots:  $SLOTS at $PER_SLOT_CONTEXT each (total $TOTAL_CONTEXT)"
echo "targets: $(wc -l < "$TARGETS")  limit: $LIMIT"
echo "outdir: $OUTDIR"

module purge
module load llamacpp/gpu/06182026
export PATH="$ENV_BIN:$PATH"

llama-server \
  -m "$MODEL" \
  --host 127.0.0.1 --port "$PORT" \
  -ngl 99 -c "$TOTAL_CONTEXT" -np "$SLOTS" \
  --jinja --reasoning off --no-ui \
  >"${TMPDIR:-/tmp}/llama-recovery-${SLURM_JOB_ID}.log" 2>&1 &
SERVER_PID=$!
cleanup() {
  kill "$SERVER_PID" 2>/dev/null || true
  wait "$SERVER_PID" 2>/dev/null || true
  cp "${TMPDIR:-/tmp}/llama-recovery-${SLURM_JOB_ID}.log" \
     "$REPO/work/llama-recovery-${SLURM_JOB_ID}.log" 2>/dev/null || true
}
trap cleanup EXIT

for _ in $(seq 1 180); do
  curl -sf "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1 && { echo "server up"; break; }
  sleep 5
done
curl -sf "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1 || {
  echo "llama-server never became healthy" >&2
  tail -40 "${TMPDIR:-/tmp}/llama-recovery-${SLURM_JOB_ID}.log" >&2 || true
  exit 1
}

cd "$REPO"
LIMIT_ARGS=()
if [ "$LIMIT" != "0" ]; then LIMIT_ARGS=(--limit "$LIMIT"); fi
PIDS=()
for i in $(seq 0 $((SLOTS - 1))); do
  "$PYTHON" scripts/coverage/propose_verify_driver.py \
    --targets "$TARGETS" \
    --output "$OUTDIR/recovery_shard_${i}.jsonl" \
    --backend openai \
    --endpoint "http://127.0.0.1:${PORT}/v1/chat/completions" \
    --model local \
    --shard "${i}/${SLOTS}" \
    --max-tokens 1800 \
    --timeout 300 \
    --swipl-bin "$SWIPL" \
    --render-gate-script "$GATE_SCRIPT" \
    --root "$REPO" \
    "${LIMIT_ARGS[@]}" \
    >"$OUTDIR/shard_${i}.log" 2>&1 &
  PIDS+=($!)
done
FAIL=0
for pid in "${PIDS[@]}"; do
  wait "$pid" || FAIL=1
done
echo "rows written: $(cat "$OUTDIR"/recovery_shard_*.jsonl | wc -l)"
exit "$FAIL"
