#!/usr/bin/env bash
#SBATCH --job-name=mtb-nine-columns
#SBATCH --account=r01990
#SBATCH --partition=gpu
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --gres=gpu:1
#SBATCH --output=work/%x_%j.out
#SBATCH --error=work/%x_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=tsavich@gmail.com

# Every MathTutorBench column through the one measured path, on a GPU, so the
# laptop stays free. The laptop remains the deployment claim; it is a poor
# place to answer 10,602 benchmark items at roughly a minute each.
#
# REASONING IS ON HERE, deliberately. The older jobs in this scratch tree ran
# `--reasoning off`, which makes a different checkpoint of the same weights:
# it answers immediately, and the benchmark's stop lists behave as they do for
# every published model. The laptop measurements all have reasoning on. Mixing
# the two silently would put two conditions in one table, so this job matches
# the laptop and `SET_REASONING=off` is available to measure the other arm on
# purpose.

set -euo pipefail

REPO_ROOT="${SLURM_SUBMIT_DIR:?submit from the repository root on scratch}"
MODEL="${GEMMA_MODEL:-/N/scratch/datahub/nvme/llms/quantized/gemma-4-E2B-it/gemma-4-E2B-it_Q4_K_M.gguf}"
TASKS="${MTB_TASKS:-all}"
SPLIT="${MTB_SPLIT:-heldout}"
LIMIT="${MTB_LIMIT:-}"
RESPONDER="${MTB_RESPONDER:-unassisted}"
STOP_MODE="${MTB_STOP_MODE:-post}"
REASONING="${SET_REASONING:-on}"
PORT="${LLAMA_PORT:-$((18000 + SLURM_JOB_ID % 10000))}"
RUN_DIR="${RUN_DIR_OVERRIDE:-$REPO_ROOT/.bigred-output/mtb-${SLURM_JOB_ID}}"
mkdir -p "$REPO_ROOT/work" "$RUN_DIR"

echo "model:     $MODEL"
echo "tasks:     $TASKS   split=$SPLIT limit=${LIMIT:-all}"
echo "responder: $RESPONDER   stop_mode=$STOP_MODE   reasoning=$REASONING"
echo "run dir:   $RUN_DIR"

module purge
module load llamacpp/gpu/06182026
export PATH="/N/u/tmsavich/BigRed200/.conda/envs/umedcta/bin:$PATH"

llama-server \
  -m "$MODEL" \
  --host 127.0.0.1 --port "$PORT" \
  -ngl 99 -c 16384 -np 1 \
  --jinja --reasoning "$REASONING" --no-ui \
  >"${TMPDIR:?}/llama-server-${SLURM_JOB_ID}.log" 2>&1 &
SERVER_PID=$!
cleanup() {
  kill "$SERVER_PID" 2>/dev/null || true
  wait "$SERVER_PID" 2>/dev/null || true
  cp "${TMPDIR:?}/llama-server-${SLURM_JOB_ID}.log" "$RUN_DIR/llama-server.log" 2>/dev/null || true
}
trap cleanup EXIT

for _ in $(seq 1 300); do
  curl --silent --fail "http://127.0.0.1:$PORT/health" >/dev/null && break
  sleep 2
done
curl --silent --fail "http://127.0.0.1:$PORT/health" >/dev/null
echo "llama-server healthy on $PORT"

# The datasets must already be in the node's HF cache; this job does not reach
# the network. prepare_mathtutorbench_scratch.sh stages them on the login node.
export HF_HOME="${MTB_HF_HOME:-/N/scratch/tmsavich/.cache/huggingface}"
export HF_HUB_OFFLINE=1

LIMIT_ARG=()
[ -n "$LIMIT" ] && LIMIT_ARG=(--limit "$LIMIT")

python3 "$REPO_ROOT/scripts/research/mtb_official_runner.py" \
  --tasks "$TASKS" \
  --split "$SPLIT" \
  --responder "$RESPONDER" \
  --model "$(basename "$MODEL")" \
  --out "$RUN_DIR" \
  --progress-every 50 \
  "${LIMIT_ARG[@]}" \
  --responder-arg backend=llama \
  --responder-arg "endpoint=http://127.0.0.1:$PORT/v1/chat/completions" \
  --responder-arg "stop_mode=$STOP_MODE"

cleanup
trap - EXIT

# The four generation columns are win rates, not the shipped question-mark
# heuristic, so they need the reward model. It runs after the GPU work.
if compgen -G "$RUN_DIR/generations-*.json" >/dev/null; then
  module purge
  export PATH="/N/u/tmsavich/BigRed200/.conda/envs/umedcta/bin:$PATH"
  REWARD_CACHE="${REWARD_MODEL_CACHE_SOURCE:-/N/scratch/tmsavich/.cache/huggingface/hub/models--eth-nlped--Qwen2.5-1.5B-pedagogical-rewardmodel}"
  if [ -d "$REWARD_CACHE" ]; then
    NODE_HF_HOME="${TMPDIR:?}/hf-${SLURM_JOB_ID}"
    mkdir -p "$NODE_HF_HOME/hub"
    cp -a "$REWARD_CACHE" "$NODE_HF_HOME/hub/"
    export HF_HOME="$NODE_HF_HOME"
    export HF_HUB_OFFLINE=1
    python3 "$REPO_ROOT/scripts/research/mtb_reward_score.py" --runs "$RUN_DIR"
  else
    echo "reward-model cache absent at $REWARD_CACHE; generation columns unscored" >&2
  fi
fi

echo "done: $RUN_DIR"
