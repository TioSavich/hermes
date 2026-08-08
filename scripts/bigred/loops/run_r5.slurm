#!/bin/bash
# R5 — misconception reproduction census over the 6-8 harvest.
#
# THIS JOB HAS NO MANIFEST TO RUN, and the reason is a corpus gap rather than
# a defect in this file. R5 asks which wired misconception machines reproduce
# a RECORDED WRONG ANSWER by trace. The 6-8 harvest records carry the lesson
# excerpt, a prose description of the doing, the numeric operands, and their
# provenance — and no answer of any kind. Measured by
# `python3 scripts/bigred/loops/step0_manifests.py --census`: 6,247 task
# records, 2,859 with two or more operands, 0 with a recorded answer.
#
# So step0_manifests.py writes no R5 manifest, and this job exits 2 when the
# manifest is absent rather than producing rows nothing can score. The job
# shape is authored and ready; what it waits on is a corpus with recorded
# student answers, which is authoring work, not compute.
#
# Pure Prolog on CPU when it does run. No GPU, no llamacpp module, no model,
# no network.
#
# BEFORE SUBMITTING, on the login node:
#   1. mkdir -p work .bigred-output/2026-08-08-loops-wave1/rows
#   2. python3 scripts/bigred/loops/step0_manifests.py --census
#      Confirm the scorable-record count is above zero. If it is zero, this
#      job must not be submitted.
#   3. Law zero — one item end to end, judged by the artifact:
#      [ -s /tmp/lawzero_r5.jsonl ] && echo LAW_ZERO_OK

#SBATCH --job-name=hermes_r5_reproduction
#SBATCH --account=r01990
#SBATCH --partition=general
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=1:00:00
#SBATCH --array=0-39%64
#SBATCH --output=work/%x_%A_%a.out
#SBATCH --error=work/%x_%A_%a.err

set -euo pipefail

REPO="${HERMES_REPO:-$SLURM_SUBMIT_DIR}"
RUN_DIR="${HERMES_RUN_DIR:-$REPO/.bigred-output/2026-08-08-loops-wave1}"
SHARD_ID=$(printf '%04d' "${SLURM_ARRAY_TASK_ID:-0}")
MANIFEST="$RUN_DIR/r5_shard_${SHARD_ID}.jsonl"
OUTPUT="$RUN_DIR/rows/r5_rows_${SHARD_ID}.jsonl"

set +u
source /geode2/soft/hps/sles15sp6/conda/25.3.0/etc/profile.d/conda.sh
conda activate "${HERMES_ENV:-umedcta}"
set -u

CONDA_PREFIX_PINNED="${HERMES_CONDA_PREFIX:-/N/u/tmsavich/BigRed200/.conda/envs/umedcta}"
PYTHON="$CONDA_PREFIX_PINNED/bin/python"
export PATH="$CONDA_PREFIX_PINNED/bin:$PATH"

echo "host        : $(hostname)"
echo "shard       : $SHARD_ID"
echo "manifest    : $MANIFEST"
echo "python      : $PYTHON"
echo "swipl       : $(command -v swipl || echo MISSING)"

mkdir -p "$RUN_DIR/rows"

if [ ! -s "$MANIFEST" ]; then
  echo "no R5 manifest at $MANIFEST." >&2
  echo "The 6-8 harvest records no answers, so a reproduction census has" >&2
  echo "nothing to score against. Run step0_manifests.py --census." >&2
  exit 2
fi

cd "$REPO"
"$PYTHON" scripts/bigred/loops/run_loop_array.py \
  --manifest "$MANIFEST" \
  --output   "$OUTPUT" \
  --watchdog-s 300

if [ -s "$OUTPUT" ]; then
  echo "SHARD_OK $(wc -l < "$OUTPUT") rows"
else
  echo "SHARD_EMPTY no rows at $OUTPUT" >&2
  exit 3
fi
