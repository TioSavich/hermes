#!/usr/bin/env bash
#SBATCH --job-name=sidekick-mtb
#SBATCH --account=r01990
#SBATCH --partition=gpu
#SBATCH --time=06:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=96G
#SBATCH --gres=gpu:1
#SBATCH --output=work/%x_%j.out
#SBATCH --error=work/%x_%j.err

# Does the wave-5 sidekick teach better than garbage?
#
# The held-out scoring said the tune matches a keyword-and-regex extractor at
# writing Prolog. That measurement cannot separate a tutor from a script, so
# this job asks the benchmark whose questions Tio has read.
#
# Everything is node-local: llama-server holds the weights, SWI-Prolog answers
# the tool calls from the umedcta env, and the reward model scores at the end.
# Compute nodes have no network, so every model and dataset below is already in
# the scratch HF cache.
#
# Four arms on the scaffolding-generation held-out slice, and each one answers
# a different question:
#
#   naked_on       reasoning on, no tools. The only arm comparable to the
#                  stored 0.458 naked-E2B floor, which was measured with
#                  reasoning on. Answers: did the tune damage teaching?
#   naked_off      reasoning off, no tools. The condition the tune was built
#                  for, since every wave-5 row trained as a plain reply.
#   agent_tutor    tools offered. Answers: does it reach for Hermes?
#   agent_mandated tools mandated. Answers: when it must consult, is the
#                  consultation worth anything? Capacity and disposition are
#                  separate findings and this pair is what splits them.
#
# The two agent arms run a bounded subset. Their first items are the naked
# arms' first items, because the split is frozen and the offset is zero, so
# the four arms compare on identical questions.

set -euo pipefail

REPO="${SIDEKICK_REPO:-/N/scratch/tmsavich/hermes}"
TUNED="${TUNED_GGUF:-/N/slate/tmsavich/sidekick/runs/wave5-7945580/sidekick-wave5-Q4_K_M.gguf}"
TASK="${MTB_TASK:-scaffolding_generation}"
SPLIT="${MTB_SPLIT:-heldout}"
AGENT_LIMIT="${MTB_AGENT_LIMIT:-120}"
RUN_DIR="${RUN_DIR_OVERRIDE:-$REPO/.bigred-output/sidekick-mtb-${SLURM_JOB_ID}}"

CONDA_PY=/N/u/tmsavich/BigRed200/.conda/envs/umedcta/bin/python3
SCORE_PY=/usr/bin/python3.12
export HERMES_SWIPL=/N/u/tmsavich/BigRed200/.conda/envs/umedcta/bin/swipl
export HF_HOME="${HF_HOME:-/N/scratch/tmsavich/.cache/huggingface}"
export PYTHONPATH="$REPO/scripts/research:$REPO"

PORT_ON="${PORT_ON:-$((20000 + SLURM_JOB_ID % 1000))}"
PORT_OFF="${PORT_OFF:-$((PORT_ON + 1))}"

mkdir -p "$REPO/work" "$RUN_DIR"
test -r "$TUNED" || { echo "missing weights: $TUNED" >&2; exit 1; }
test -x "$HERMES_SWIPL" || { echo "missing swipl: $HERMES_SWIPL" >&2; exit 1; }

echo "repo:      $REPO"
echo "weights:   $TUNED"
echo "task:      $TASK  split=$SPLIT  agent_limit=$AGENT_LIMIT"
echo "run dir:   $RUN_DIR"
sha256sum "$TUNED" | tee "$RUN_DIR/served-identity.txt"

module purge
module load llamacpp/gpu/06182026

serve() {
  local port="$1" reasoning="$2" tag="$3"
  llama-server \
    -m "$TUNED" \
    --host 127.0.0.1 --port "$port" \
    -ngl 99 -c 16384 -np 1 \
    --jinja --reasoning "$reasoning" --no-ui \
    >"$RUN_DIR/llama-${tag}.log" 2>&1 &
  echo $!
}

PID_ON="$(serve "$PORT_ON" on on)"
PID_OFF="$(serve "$PORT_OFF" off off)"
cleanup() {
  kill "$PID_ON" "$PID_OFF" 2>/dev/null || true
  wait "$PID_ON" "$PID_OFF" 2>/dev/null || true
}
trap cleanup EXIT

for port in "$PORT_ON" "$PORT_OFF"; do
  for _ in $(seq 1 300); do
    curl --silent --fail "http://127.0.0.1:$port/health" >/dev/null && break
    sleep 2
  done
  curl --silent --fail "http://127.0.0.1:$port/health" >/dev/null
  echo "llama-server healthy on $port"
done

# One arm. Its own output directory, because the reward scorer names an arm
# after the generations file it finds and every arm writes the same task name.
arm() {
  local name="$1" responder="$2" port="$3" limit="$4"
  local out="$RUN_DIR/$name"
  mkdir -p "$out"
  echo "=== arm $name (responder=$responder port=$port limit=${limit:-all}) ==="
  local extra=()
  test -n "$limit" && extra=(--limit "$limit")
  "$CONDA_PY" "$REPO/scripts/research/mtb_official_runner.py" \
    --tasks "$TASK" --split "$SPLIT" "${extra[@]}" \
    --responder "$responder" \
    --model "sidekick-wave5-Q4_K_M" \
    --responder-arg backend=llama \
    --responder-arg "endpoint=http://127.0.0.1:$port/v1/chat/completions" \
    --responder-arg stop_mode=post \
    --out "$out" --progress-every 20 \
    >"$out/run.log" 2>"$out/run.err"
  # An artifact, not an exit status: a pipeline's status has faked a pass here
  # before.
  test -s "$out/generations-$TASK.json" || {
    echo "arm $name produced no generations" >&2
    tail -20 "$out/run.err" >&2
    return 1
  }
  echo "arm $name wrote $(wc -c <"$out/generations-$TASK.json") bytes"
}

arm naked_on       unassisted           "$PORT_ON"  ""
arm naked_off      unassisted           "$PORT_OFF" ""
arm agent_tutor    agent_tutor          "$PORT_OFF" "$AGENT_LIMIT"
arm agent_mandated agent_tutor_mandated "$PORT_OFF" "$AGENT_LIMIT"

cleanup
trap - EXIT

# The reward model is the published pairwise judge; the number it returns is a
# win rate against the curriculum's own teacher utterance.
for name in naked_on naked_off agent_tutor agent_mandated; do
  echo "=== scoring $name ==="
  "$SCORE_PY" "$REPO/hermes/app/runtime/experiments/gemma4_tutor/score_official.py" \
    --runs "$RUN_DIR/$name" || { echo "scoring failed for $name" >&2; continue; }
done

echo "SIDEKICK_MTB_DONE $RUN_DIR"
for name in naked_on naked_off agent_tutor agent_mandated; do
  test -s "$RUN_DIR/$name/reward-summary.json" && {
    echo "--- $name ---"
    cat "$RUN_DIR/$name/reward-summary.json"
  }
done
