#!/usr/bin/env bash
#SBATCH --job-name=hermes-diagnosis
#SBATCH --account=r01990
#SBATCH --partition=gpu
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=96G
#SBATCH --gres=gpu:1
#SBATCH --output=work/%x_%j.out
#SBATCH --error=work/%x_%j.err

# Hermes on the whole mistake-location test. One run, one number.
#
# The test asks for the step number of the first error, or 0 if the solution is
# correct. 2,004 items, exactly balanced: 1,002 carry an error and 1,002 do not,
# so ALWAYS ANSWERING 0 SCORES 0.5000. That is the number this has to beat and
# the only comparison that matters.
#
# What runs is Hermes, not a prompt. For each item the model compiles the
# problem text into referent facts, compiles it a second time under a different
# frame as an independent guard, and binds the student's numerals to referents
# from its own lexicon. SWI-Prolog then saturates the problem-side facts and
# answers the first step whose bound referent derives a different value. The
# model represents; the engine decides. No arm, no ablation, no second reading.
#
# Leakage: no benchmark content travels with any prompt. The compile exemplar is
# an invented crates-and-jars problem, verified absent from all 2,004 items, and
# no six-word window of any prompt occurs anywhere in the corpus. The task's own
# shipped few-shot block is not used, because it contains worked dataset
# examples with their answers.
#
# Checkpoints per item. A timeout resumes where it stopped rather than starting
# over.

set -euo pipefail

REPO="${SIDEKICK_REPO:-/N/scratch/tmsavich/hermes}"
WEIGHTS="${TUNED_GGUF:-/N/slate/tmsavich/sidekick/runs/wave5-7945580/sidekick-wave5-Q4_K_M.gguf}"
ITEMS="${DIAG_ITEMS:-$REPO/hermes/app/runtime/experiments/sidekick/datasets/mistake_location_full.json}"
RUN_DIR="${RUN_DIR_OVERRIDE:-$REPO/.bigred-output/hermes-diagnosis-${SLURM_JOB_ID}}"
PORT="${LLAMA_PORT:-$((21000 + SLURM_JOB_ID % 1000))}"

CONDA_PY=/N/u/tmsavich/BigRed200/.conda/envs/umedcta/bin/python3
export HERMES_SWIPL=/N/u/tmsavich/BigRed200/.conda/envs/umedcta/bin/swipl
export PATH="/N/u/tmsavich/BigRed200/.conda/envs/umedcta/bin:$PATH"
export PYTHONPATH="$REPO/scripts/sidekick:$REPO"

mkdir -p "$REPO/work" "$RUN_DIR"
test -r "$WEIGHTS" || { echo "missing weights: $WEIGHTS" >&2; exit 1; }
test -r "$ITEMS"   || { echo "missing items: $ITEMS" >&2; exit 1; }
test -x "$HERMES_SWIPL" || { echo "missing swipl" >&2; exit 1; }

echo "weights: $WEIGHTS"
echo "items:   $ITEMS"
echo "run dir: $RUN_DIR"
sha256sum "$WEIGHTS" | tee "$RUN_DIR/served-identity.txt"

module purge
module load llamacpp/gpu/06182026

# Reasoning off: these rows trained as plain replies, and a thinking budget
# inside the reply cap returns empty content that reads as a refusal.
llama-server -m "$WEIGHTS" --host 127.0.0.1 --port "$PORT" \
  -ngl 99 -c 8192 -np 1 --jinja --reasoning off --no-ui \
  >"$RUN_DIR/llama-server.log" 2>&1 &
SERVER_PID=$!
cleanup() { kill "$SERVER_PID" 2>/dev/null || true; wait "$SERVER_PID" 2>/dev/null || true; }
trap cleanup EXIT

for _ in $(seq 1 300); do
  curl --silent --fail "http://127.0.0.1:$PORT/health" >/dev/null && break
  sleep 2
done
curl --silent --fail "http://127.0.0.1:$PORT/health" >/dev/null
echo "llama-server healthy on $PORT"

"$CONDA_PY" "$REPO/scripts/sidekick/run_diagnosis_arms.py" \
  --items "$ITEMS" \
  --arm adjudicated \
  --endpoint "http://127.0.0.1:$PORT/v1/chat/completions" \
  --model sidekick-wave5-Q4_K_M \
  --out "$RUN_DIR"

# An artifact is the criterion, never a pipeline's exit status.
test -s "$RUN_DIR/summary-adjudicated.json" || {
  echo "no summary written" >&2; exit 1; }

echo "HERMES_DIAGNOSIS_DONE $RUN_DIR"
cat "$RUN_DIR/summary-adjudicated.json"
