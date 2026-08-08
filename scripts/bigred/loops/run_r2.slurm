#!/bin/bash
# R2 — refusal-genesis sweep as a directed replay. One array task walks 12
# machine pairs over their authored grid and records, PER SIDE, which machine
# refused each point and which computed it. One walk, two directed censuses.
#
# R1 counted refusals jointly, so the asymmetry R2 needs was never retained
# and cannot be recovered from the R1 collection. That is why this replays
# rather than reads.
#
# Pure Prolog on CPU. No GPU, no llamacpp module, no model, no network.
#
# BEFORE SUBMITTING, on the login node:
#   1. mkdir -p work .bigred-output/2026-08-08-loops-wave2/rows
#      Slurm does not create the log directory and a missing one loses the job
#      silently.
#   2. python3 scripts/bigred/loops/step0_manifests.py --r2
#      R2 needs no --pair-filter: schema-only was ruled after R1, and R2
#      replays exactly the pairs R1 walked. It prints the shard count; the
#      array range below must match it.
#   3. Law zero — run ONE item end to end and judge it by the artifact:
#      python3 scripts/bigred/loops/run_loop_array.py \
#        --manifest .bigred-output/2026-08-08-loops-wave2/r2_shard_0000.jsonl \
#        --output   /tmp/lawzero.jsonl --limit 1
#      [ -s /tmp/lawzero.jsonl ] && echo LAW_ZERO_OK
#
# The array range is set at submit time because it comes from the manifest:
#   sbatch --array=0-224%64 scripts/bigred/loops/run_r2.slurm
# The directive below is the fallback for a submit that names no range.

#SBATCH --job-name=hermes_r2_crisis
#SBATCH --account=r01990
#SBATCH --partition=general
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=4:00:00
#SBATCH --array=0-0%64
#SBATCH --output=work/%x_%A_%a.out
#SBATCH --error=work/%x_%A_%a.err

set -euo pipefail

REPO="${HERMES_REPO:-$SLURM_SUBMIT_DIR}"
RUN_DIR="${HERMES_RUN_DIR:-$REPO/.bigred-output/2026-08-08-loops-wave2}"
SHARD_ID=$(printf '%04d' "${SLURM_ARRAY_TASK_ID:-0}")
MANIFEST="$RUN_DIR/r2_shard_${SHARD_ID}.jsonl"
OUTPUT="$RUN_DIR/rows/r2_rows_${SHARD_ID}.jsonl"

# lmod and conda setup scripts read unset shell variables such as PS1, so the
# nounset guard comes off around them and goes straight back on.
set +u
source /geode2/soft/hps/sles15sp6/conda/25.3.0/etc/profile.d/conda.sh
conda activate "${HERMES_ENV:-umedcta}"
set -u

# Pin the interpreter by absolute prefix path. `conda activate` alone has put
# the login node's python at the front of PATH before now, and the resulting
# job fails on an import that works everywhere else.
CONDA_PREFIX_PINNED="${HERMES_CONDA_PREFIX:-/N/u/tmsavich/BigRed200/.conda/envs/umedcta}"
PYTHON="$CONDA_PREFIX_PINNED/bin/python"
export PATH="$CONDA_PREFIX_PINNED/bin:$PATH"

echo "host        : $(hostname)"
echo "shard       : $SHARD_ID"
echo "manifest    : $MANIFEST"
echo "output      : $OUTPUT"
echo "python      : $PYTHON"
echo "swipl       : $(command -v swipl || echo MISSING)"

mkdir -p "$RUN_DIR/rows"

if [ ! -s "$MANIFEST" ]; then
  echo "manifest missing or empty: $MANIFEST" >&2
  exit 2
fi

cd "$REPO"
"$PYTHON" scripts/bigred/loops/run_loop_array.py \
  --manifest "$MANIFEST" \
  --output   "$OUTPUT" \
  --watchdog-s 720

# Judge the task by its artifact, never by an exit status.
if [ -s "$OUTPUT" ]; then
  echo "SHARD_OK $(wc -l < "$OUTPUT") rows"
else
  echo "SHARD_EMPTY no rows at $OUTPUT" >&2
  exit 3
fi
