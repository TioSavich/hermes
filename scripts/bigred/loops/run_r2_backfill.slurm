#!/bin/bash
# R2 closure backfill for the 136 timeout or missing-direction pairs from the
# 2026-08-08 collection. admission_docket.py writes 12 cost-interleaved shards
# at 12 pairs per task with a 1,200-second pair budget.
#
# Before submitting, generate and inspect the local artifacts:
#   python3 scripts/bigred/loops/admission_docket.py
#   python3 scripts/bigred/loops/run_loop_array.py \
#     --manifest .bigred-output/2026-08-09-loops-wave2-r2-backfill/r2_shard_0000.jsonl \
#     --output /tmp/r2_backfill_lawzero.jsonl --limit 1 --watchdog-s 1320
#   test -s /tmp/r2_backfill_lawzero.jsonl
#
# The generated shard count fixes the array range at 0-11.
# Twelve items can each use the 1,320-second watchdog and 30-second reap grace:
# 12 * (1,320 + 30) = 16,200 seconds (4:30:00). The six-hour request leaves
# 1:30:00 for startup, checkpoint writes, and scheduler variation.

#SBATCH --job-name=hermes_r2_backfill
#SBATCH --account=r01990
#SBATCH --partition=general
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=6:00:00
#SBATCH --array=0-11%64
#SBATCH --output=work/%x_%A_%a.out
#SBATCH --error=work/%x_%A_%a.err

set -euo pipefail

REPO="${HERMES_REPO:-$SLURM_SUBMIT_DIR}"
RUN_DIR="${HERMES_RUN_DIR:-$REPO/.bigred-output/2026-08-09-loops-wave2-r2-backfill}"
SHARD_ID=$(printf '%04d' "${SLURM_ARRAY_TASK_ID:-0}")
MANIFEST="$RUN_DIR/r2_shard_${SHARD_ID}.jsonl"
OUTPUT="$RUN_DIR/rows/r2_rows_${SHARD_ID}.jsonl"

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
  --output "$OUTPUT" \
  --watchdog-s 1320

if [ -s "$OUTPUT" ]; then
  echo "SHARD_OK $(wc -l < "$OUTPUT") rows"
else
  echo "SHARD_EMPTY no rows at $OUTPUT" >&2
  exit 3
fi
