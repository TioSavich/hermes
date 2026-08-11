#!/bin/bash
# R3 depth-2 kernel composition sweep over the 209 eligible depth-1 rows.
# step0_manifests.py --r3-depth2 derives that population from the collected
# depth-1 rows, records all exclusions, and writes 53 shards at 4 machines per
# task into .bigred-output/2026-08-10-loops-wave3-r3-depth2:
#
#   2,700 s machine budget + 120 s watchdog margin  -> --watchdog-s 2820
#   2,820 s watchdog       +  30 s reap grace       -> 2,850 s per machine
#   14,400 s wall - 1,800 s startup reserve         -> 12,600 s usable
#   12,600 / 2,850 = 4 machines per shard; 209 / 4 = 53 shards -> 0-52
#
# Before submitting, generate and inspect the local artifacts:
#   python3 scripts/bigred/loops/step0_manifests.py --r3-depth2
#   python3 scripts/bigred/loops/run_loop_array.py \
#     --manifest .bigred-output/2026-08-10-loops-wave3-r3-depth2/r3_shard_0000.jsonl \
#     --output /tmp/r3_depth2_lawzero.jsonl --limit 1 --watchdog-s 2820 \
#     --driver scripts/bigred/loops/r3_driver.pl
#   test -s /tmp/r3_depth2_lawzero.jsonl
#
# Re-run step 0 and use its printed range if the depth-1 collection changes.

#SBATCH --job-name=hermes_r3_depth2
#SBATCH --account=r01990
#SBATCH --partition=general
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=4:00:00
#SBATCH --array=0-52%32
#SBATCH --output=work/%x_%A_%a.out
#SBATCH --error=work/%x_%A_%a.err

set -euo pipefail

REPO="${HERMES_REPO:-$SLURM_SUBMIT_DIR}"
RUN_DIR="${HERMES_RUN_DIR:-$REPO/.bigred-output/2026-08-10-loops-wave3-r3-depth2}"
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
