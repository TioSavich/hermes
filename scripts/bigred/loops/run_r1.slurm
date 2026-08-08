#!/bin/bash
# R1 — equalizer atlas. One array task walks 25 machine pairs over their
# authored grid and records, per pair, where the two machines agree and where
# they separate.
#
# Pure Prolog on CPU. No GPU, no llamacpp module, no model, no network.
#
# BEFORE SUBMITTING, on the login node:
#   1. mkdir -p work .bigred-output/2026-08-08-loops-wave1/rows
#      Slurm does not create the log directory and a missing one loses the job
#      silently.
#   2. python3 scripts/bigred/loops/step0_manifests.py --pair-filter <ruled>
#      It prints the shard count; the array range below must match it.
#   3. Law zero — run ONE item end to end and judge it by the artifact:
#      python3 scripts/bigred/loops/run_loop_array.py \
#        --manifest .bigred-output/2026-08-08-loops-wave1/r1_shard_0000.jsonl \
#        --output   /tmp/lawzero.jsonl --limit 1
#      [ -s /tmp/lawzero.jsonl ] && echo LAW_ZERO_OK
#
# The array range is set at submit time because it comes from the manifest:
#   sbatch --array=0-107%64 scripts/bigred/loops/run_r1.slurm
# The directive below is the fallback for a submit that names no range.

#SBATCH --job-name=hermes_r1_atlas
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
RUN_DIR="${HERMES_RUN_DIR:-$REPO/.bigred-output/2026-08-08-loops-wave1}"
SHARD_ID=$(printf '%04d' "${SLURM_ARRAY_TASK_ID:-0}")
MANIFEST="$RUN_DIR/r1_shard_${SHARD_ID}.jsonl"
OUTPUT="$RUN_DIR/rows/r1_rows_${SHARD_ID}.jsonl"

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
