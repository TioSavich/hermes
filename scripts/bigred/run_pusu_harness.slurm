#!/usr/bin/env bash
#SBATCH --job-name=hermes-pusu
#SBATCH --account=r01990
#SBATCH --partition=general
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=24G
#SBATCH --output=/N/scratch/tmsavich/hermes/%x_%j.out
#SBATCH --error=/N/scratch/tmsavich/hermes/%x_%j.err

# Parse and attempt to complete every eligible defragged IM task statement.
# This is CPU-only.  The JSONL ledger checkpoints after every statement, so a
# later invocation resumes the same corpus rather than beginning again.

set -euo pipefail

REPO="${SIDEKICK_REPO:-/N/scratch/tmsavich/hermes}"
ENV_BIN="/N/u/tmsavich/BigRed200/.conda/envs/umedcta/bin"
PYTHON="$ENV_BIN/python3"
export PATH="$ENV_BIN:$PATH"
export PYTHONPATH="$REPO/scripts/language:$REPO"

OUT_DIR="$REPO/hermes/app/runtime/experiments/language"
RESULTS="$OUT_DIR/pusu_results.jsonl"
SUMMARY="$OUT_DIR/pusu_summary.json"

mkdir -p "$OUT_DIR"
test -x "$PYTHON" || { echo "missing Python: $PYTHON" >&2; exit 1; }
test -x "$ENV_BIN/swipl" || { echo "missing swipl: $ENV_BIN/swipl" >&2; exit 1; }
test -r "$REPO/curriculum/im/generated/compiled_defragged_task_instances.pl" || {
  echo "missing defragged task corpus" >&2; exit 1;
}

cd "$REPO"
"$PYTHON" scripts/language/pusu_harness.py \
  --output "$RESULTS" \
  --summary "$SUMMARY" \
  --progress-every 25

# Artifacts, not the process status alone, establish that the run finished.
test -s "$RESULTS" || { echo "no PUSU result ledger written" >&2; exit 1; }
test -s "$SUMMARY" || { echo "no PUSU summary written" >&2; exit 1; }
"$PYTHON" -c 'import json,sys; d=json.load(open(sys.argv[1])); assert d["progress"]["numerator"] == d["progress"]["denominator"] == 2129' "$SUMMARY"

echo "PUSU_HARNESS_DONE $RESULTS $SUMMARY"
