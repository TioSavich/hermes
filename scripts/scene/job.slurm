#!/usr/bin/env bash
# The full smattering: one SVG per item from gemma-4-E2B-it through llama.cpp.
#
# The model never sees a PNG. It is handed the figure's written description and
# the Hermes rows a tool call returns, and asked to draw the mathematics. So no
# image corpus is staged here and the job needs nothing off the node once
# llama-server is up.
#
# Runs on the gpu partition: the cluster's llama.cpp build links libcuda at
# load, so it cannot start on the login node or the general partition at all
# (measured 2026-07-31: "error while loading shared libraries: libcuda.so.1").
# Every recorded E2B run here used gpu + gres, and this job follows them.
# The two-hour wall clock is for model load and a wide margin, not because
# the batch needs it.
#
#SBATCH --job-name=hermes-scene-pilot
#SBATCH --account=r01990
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=48G
#SBATCH --output=scripts/research/svg_pilot/logs/%x_%j.out
#SBATCH --error=scripts/research/svg_pilot/logs/%x_%j.err

# The two log paths above must exist BEFORE sbatch is called. Slurm does not
# create them and a job whose output file cannot be opened dies without saying
# why. The launch sequence in the task report does the mkdir first; keep it.

set -euo pipefail

REPO_ROOT="${SLURM_SUBMIT_DIR:?submit from the Big Red checkout root}"
cd "$REPO_ROOT"

PILOT_DIR="${PILOT_DIR:-$REPO_ROOT/scripts/research/svg_pilot}"
LOG_DIR="$PILOT_DIR/logs"
RUN_LABEL="${RUN_LABEL:-bigred-${SLURM_JOB_ID}}"
OUT_DIR="${OUT_DIR:-$PILOT_DIR/out}"
mkdir -p "$LOG_DIR" "$OUT_DIR"

MODEL="${GEMMA_MODEL:-/N/scratch/datahub/nvme/llms/quantized/gemma-4-E2B-it/gemma-4-E2B-it_Q4_K_M.gguf}"
PORT="${LLAMA_PORT:-$((19000 + SLURM_JOB_ID % 9000))}"
REASONING="${SET_REASONING:-on}"
TEMPERATURE="${PILOT_TEMPERATURE:-0.3}"
MAX_TOKENS="${PILOT_MAX_TOKENS:-6000}"

# On the gpu partition the layers offload; LLAMA_NGL=0 remains available for a
# hypothetical CPU host whose build does not link libcuda. Both are set before
# the banner prints them: `set -u` turns a reference to a not-yet-assigned
# variable into an immediate exit, which is a job that dies at second one for
# no visible reason.
NGL="${LLAMA_NGL:-99}"
THREADS="${SLURM_CPUS_PER_TASK:-16}"

echo "[$(date -Is)] host=$(hostname) job=$SLURM_JOB_ID"
echo "model:  $MODEL"
echo "port:   $PORT   reasoning=$REASONING   ngl=$NGL threads=$THREADS"
echo "run:    $RUN_LABEL -> $OUT_DIR/$RUN_LABEL"

module purge
module load llamacpp/gpu/06182026

# ---------------------------------------------------------------------------
# Preflight, on this node, in this interpreter, before anything long starts.
# ---------------------------------------------------------------------------
echo "[$(date -Is)] preflight"
python3 "$PILOT_DIR/preflight_v2.py" \
  --items "$PILOT_DIR/items/items.jsonl" \
  --model-path "$MODEL"
echo "[$(date -Is)] preflight passed"

# ---------------------------------------------------------------------------
# llama-server, bound to loopback. Nothing here reaches off the node.
# ---------------------------------------------------------------------------
llama-server \
  -m "$MODEL" \
  --host 127.0.0.1 --port "$PORT" \
  -ngl "$NGL" -t "$THREADS" -c 16384 -np 1 \
  --jinja --reasoning "$REASONING" --no-ui \
  >"$LOG_DIR/llama-server-${SLURM_JOB_ID}.log" 2>&1 &
SERVER_PID=$!
cleanup() {
  kill "$SERVER_PID" 2>/dev/null || true
  wait "$SERVER_PID" 2>/dev/null || true
}
trap cleanup EXIT

echo "[$(date -Is)] waiting for llama-server on 127.0.0.1:$PORT"
for _ in $(seq 1 300); do
  if curl --silent --fail "http://127.0.0.1:$PORT/health" >/dev/null; then
    echo "[$(date -Is)] server up"
    break
  fi
  sleep 2
done
curl --silent --fail "http://127.0.0.1:$PORT/health" >/dev/null || {
  echo "ERROR: llama-server never became healthy; see $LOG_DIR/llama-server-${SLURM_JOB_ID}.log" >&2
  exit 3
}

# Probe the endpoint now that it is live, so a broken chat route is a preflight
# failure rather than fifteen consecutive item failures.
python3 "$PILOT_DIR/preflight_v2.py" \
  --items "$PILOT_DIR/items/items.jsonl" \
  --base-url "http://127.0.0.1:$PORT/v1"

# ---------------------------------------------------------------------------
# The batch. Each item is written the moment it returns, so a job that dies
# part way leaves finished items behind and --resume continues from there.
# ---------------------------------------------------------------------------
echo "[$(date -Is)] generating"
# ONLY_ITEM turns this same file into the one-item compute-node rehearsal:
#   sbatch --time=00:30:00 --export=ALL,ONLY_ITEM=M1,RUN_LABEL=rehearsal-gpu job.slurm
python3 -u "$PILOT_DIR/run_scene_pilot.py" \
  --items "$PILOT_DIR/items/items.jsonl" \
  --out "$OUT_DIR" \
  --base-url "http://127.0.0.1:$PORT/v1" \
  --model "gemma-4-E2B-it" \
  --temperature "$TEMPERATURE" \
  --max-tokens "$MAX_TOKENS" \
  --run-label "$RUN_LABEL" \
  ${ONLY_ITEM:+--only "$ONLY_ITEM"} \
  --resume

echo "[$(date -Is)] complete. results at $OUT_DIR/$RUN_LABEL/results.jsonl"
echo "Build the side-by-side page on the laptop, where the PNGs live:"
echo "  python3 build_compare_html.py --run out/$RUN_LABEL"
