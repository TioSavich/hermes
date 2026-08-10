#!/bin/bash
# R4 contract-bridge adapter search over the statically compatible ordered
# machine pairs. step0_manifests.py --r4 measures the pair list rather than
# assuming it and prints the same arithmetic the array range below rests on:
#
#   147 of 246 machines have a MEASURED output carrier; 23 do not compute on
#   their own verified example and 76 answer with a shape the authored library
#   deliberately does not read (r4_adapters:uncarried/2 names each class).
#   8,268 statically compatible ordered pairs -> 9,772 (pair, adapter) items.
#
#     300 s (pair, adapter) budget + 120 s watchdog margin -> --watchdog-s 420
#     420 s watchdog             +  30 s reap grace        -> 450 s per item
#   7,200 s wall                 - 600 s startup reserve   -> 6,600 s usable
#   6,600 / 450 = 14 items per shard; 9,772 / 14 = 698 shards -> 0-697
#
# The design's wave table row 4 reads "array <=100 at 50 pairs/task". That
# predates the measurement: 50 items reserve 22,500 s against a 7,200 s wall,
# and the measured item count is 9,772 rather than the estimated 5,000. The
# guard arithmetic is what the manifest and this file use; step 0 prints the
# wave-table sizing beside it, and --items-per-task overrides.
#
# THE LIBRARY IS REVIEWED BEFORE THIS JOB IS SUBMITTED. scripts/bigred/loops/
# r4_adapters.pl is authored semantics, not sweep output; the design's wave
# table makes an opus review of it the gate to launch.
#
# Before submitting, generate and inspect the local artifacts:
#   python3 scripts/bigred/loops/step0_manifests.py --r4
#   python3 scripts/bigred/loops/run_loop_array.py \
#     --manifest .bigred-output/2026-08-10-loops-wave4-r4/r4_shard_0000.jsonl \
#     --output /tmp/r4_lawzero.jsonl --limit 1 --watchdog-s 420 \
#     --driver scripts/bigred/loops/r4_driver.pl
#   test -s /tmp/r4_lawzero.jsonl
#
# And `mkdir -p work` in the repo root FIRST. Slurm opens work/%x_%A_%a.out
# before the job body runs, so a missing directory fails every array task
# before a single line of this script executes.
#
# Re-run step0 and re-read its printed range if the machine population moves;
# a range copied from a stale manifest silently drops the tail shards, which is
# how the 2026-08-08 launch lost 64 of them.

#SBATCH --job-name=hermes_r4
#SBATCH --account=r01990
#SBATCH --partition=general
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=2:00:00
#SBATCH --array=0-697%64
#SBATCH --output=work/%x_%A_%a.out
#SBATCH --error=work/%x_%A_%a.err

set -euo pipefail

REPO="${HERMES_REPO:-$SLURM_SUBMIT_DIR}"
RUN_DIR="${HERMES_RUN_DIR:-$REPO/.bigred-output/2026-08-10-loops-wave4-r4}"
SHARD_ID=$(printf '%04d' "${SLURM_ARRAY_TASK_ID:-0}")
MANIFEST="$RUN_DIR/r4_shard_${SHARD_ID}.jsonl"
OUTPUT="$RUN_DIR/rows/r4_rows_${SHARD_ID}.jsonl"

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
  --driver scripts/bigred/loops/r4_driver.pl \
  --watchdog-s 420

if [ -s "$OUTPUT" ]; then
  echo "SHARD_OK $(wc -l < "$OUTPUT") rows"
else
  echo "SHARD_EMPTY no rows at $OUTPUT" >&2
  exit 3
fi
