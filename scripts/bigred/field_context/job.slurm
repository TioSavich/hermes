#!/usr/bin/env bash
# Checkpointed field-context grade-band array. Replace account and email.
#SBATCH --job-name=hermes-field-context
#SBATCH --account=REPLACE_WITH_BIG_RED_ACCOUNT
#SBATCH --partition=general
#SBATCH --array=0-2
#SBATCH --time=18:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --output=scripts/bigred/field_context/%x_%A_%a.out
#SBATCH --error=scripts/bigred/field_context/%x_%A_%a.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=REPLACE_WITH_OWNER_EMAIL

set -euo pipefail
REPO_ROOT="${SLURM_SUBMIT_DIR:?submit from the scratch checkout root}"
cd "$REPO_ROOT"

LOG_DIR="$REPO_ROOT/scripts/bigred/field_context/work/logs"
PARTIALS_DIR="${FIELD_CONTEXT_PARTIALS_DIR:-$REPO_ROOT/.bigred-output/field-context/partials}"
mkdir -p "$LOG_DIR" "$PARTIALS_DIR"

ARRAY_INDEX="${SLURM_ARRAY_TASK_ID:?this script must run as a Slurm array}"
BANDS=("K-2" "3-5" "6-8")
if [ "$ARRAY_INDEX" -ge "${#BANDS[@]}" ]; then
  echo "ERROR: unsupported array index: $ARRAY_INDEX" >&2
  exit 2
fi
BAND="${BANDS[$ARRAY_INDEX]}"
TASK_LOG="$LOG_DIR/${SLURM_JOB_NAME}_${SLURM_ARRAY_JOB_ID}_${ARRAY_INDEX}.log"
exec > >(tee -a "$TASK_LOG") 2>&1

if ! command -v module >/dev/null 2>&1 && [ -r /opt/cray/pe/lmod/lmod/init/bash ]; then
  source /opt/cray/pe/lmod/lmod/init/bash
fi
set +u  # lmod/conda setup scripts reference unset vars (PS1)
module purge
module load conda/25.3.0
module load sqlite/3.50.3
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${HERMES_ENV:-umedcta}"
set -u

echo "[$(date -Is)] band=$BAND host=$(hostname) python=$(command -v python3) swipl=$(command -v swipl)"
# External wall: terminate and resume a batch that produces no completed lesson
# within this many seconds, then isolate and record the single stalled lesson.
# The in-Prolog 120s limit cannot preempt native builtin sections, so this outer
# wall is what keeps one pathological lesson from stalling the whole band.
LESSON_TIMEOUT="${FIELD_CONTEXT_LESSON_TIMEOUT:-600}"
python3 scripts/research/build_field_context_cache.py \
  --partials-dir "$PARTIALS_DIR" \
  --grade-band "$BAND" \
  --jobs "${SLURM_CPUS_PER_TASK:-8}" \
  --lesson-timeout "$LESSON_TIMEOUT" \
  --resume \
  --collect-only
echo "[$(date -Is)] band=$BAND complete partials=$PARTIALS_DIR"
