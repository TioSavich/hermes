#!/bin/bash
# R3 depth-1 kernel re-derivation sweep over all 246 contracted machines.
# step0_manifests.py --r3 writes 62 cost-interleaved shards at 4 machines per
# task into .bigred-output/2026-08-10-loops-wave3-r3, and prints the same
# arithmetic the array range below rests on:
#
#   2,700 s machine budget + 120 s watchdog margin  -> --watchdog-s 2820
#   2,820 s watchdog       +  30 s reap grace       -> 2,850 s per machine
#   14,400 s wall - 1,800 s startup reserve         -> 12,600 s usable
#   12,600 / 2,850 = 4 machines per shard; 246 / 4 = 62 shards -> 0-61
#
# Before submitting, generate and inspect the local artifacts:
#   python3 scripts/bigred/loops/step0_manifests.py --r3
#   python3 scripts/bigred/loops/run_loop_array.py \
#     --manifest .bigred-output/2026-08-10-loops-wave3-r3/r3_shard_0000.jsonl \
#     --output /tmp/r3_lawzero.jsonl --limit 1 --watchdog-s 2820 \
#     --driver scripts/bigred/loops/r3_driver.pl
#   test -s /tmp/r3_lawzero.jsonl
#
# Re-run step0 and re-read its printed range if the machine population moves;
# a range copied from a stale manifest silently drops the tail shards, which is
# how the 2026-08-08 launch lost 64 of them.

#SBATCH --job-name=hermes_r3
#SBATCH --account=r01990
#SBATCH --partition=general
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=4:00:00
#SBATCH --array=0-61%32
#SBATCH --output=work/%x_%A_%a.out
#SBATCH --error=work/%x_%A_%a.err

set -euo pipefail

REPO="${HERMES_REPO:-$SLURM_SUBMIT_DIR}"
RUN_DIR="${HERMES_RUN_DIR:-$REPO/.bigred-output/2026-08-10-loops-wave3-r3}"
SHARD_ID=$(printf '%04d' "${SLURM_ARRAY_TASK_ID:-0}")
MANIFEST="$RUN_DIR/r3_shard_${SHARD_ID}.jsonl"
OUTPUT="$RUN_DIR/rows/r3_rows_${SHARD_ID}.jsonl"

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
  --driver scripts/bigred/loops/r3_driver.pl \
  --watchdog-s 2820

if [ -s "$OUTPUT" ]; then
  echo "SHARD_OK $(wc -l < "$OUTPUT") rows"
else
  echo "SHARD_EMPTY no rows at $OUTPUT" >&2
  exit 3
fi
