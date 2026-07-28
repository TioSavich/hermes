#!/usr/bin/env bash
# The Atlas sweep, one array task per lesson cell. run.sh --go supplies
# --array=0-(N-1) after reading work/cells.json.
# Replace the account and email placeholders before submitting.
#SBATCH --job-name=hermes-atlas-sweep
#SBATCH --account=REPLACE_WITH_BIG_RED_ACCOUNT
#SBATCH --partition=general
# 90 min and a 4800s cell wall: the heaviest cell (IM-G7-U2-L8, 20 instances
# with large proportionality operands) needs ~20 min on a cluster core, and a
# 600s backstop killed it mid-sweep even though every transition was
# individually guarded and being recorded.
#SBATCH --time=1:30:00
#SBATCH --cpus-per-task=1
# 8G, above the 4g Prolog stack bound run_cell.sh sets, so a transition that
# reaches its bound raises a catchable resource_error instead of being killed.
#SBATCH --mem=8G
#SBATCH --output=scripts/bigred/atlas/work/logs/%x_%A_%a.out
#SBATCH --error=scripts/bigred/atlas/work/logs/%x_%A_%a.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=REPLACE_WITH_OWNER_EMAIL

set -eo pipefail
REPO_ROOT="${SLURM_SUBMIT_DIR:?submit from the scratch checkout root}"
cd "$REPO_ROOT"

# ---- path vocabulary, named once -------------------------------------------
HERE_REL="scripts/bigred/atlas"
WORK="${ATLAS_WORK:-${HERE_REL}/work}"
CELLS="${WORK}/cells.json"

mkdir -p "${WORK}/shards" "${WORK}/logs"

if ! command -v module >/dev/null 2>&1 && [ -r /opt/cray/pe/lmod/lmod/init/bash ]; then
  # shellcheck disable=SC1091
  source /opt/cray/pe/lmod/lmod/init/bash
fi
module purge
module load conda/25.3.0
# shellcheck disable=SC1091
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${HERMES_ENV:-umedcta}"

export ATLAS_CELL_WALL="${ATLAS_CELL_WALL:-4800}"

IDX="${SLURM_ARRAY_TASK_ID:-0}"
LESSON=$(python3 -c "
import json
cells = json.load(open('${CELLS}'))['cells']
i = ${IDX}
print(cells[i]['lesson'] if 0 <= i < len(cells) else '')
")

if [ -z "${LESSON}" ]; then
  echo "[atlas] index ${IDX} out of range (${CELLS}); nothing to do"
  exit 0
fi

echo "[$(date -Is)] host=$(hostname) idx=${IDX} lesson=${LESSON} swipl=$(command -v swipl)"
bash "${HERE_REL}/run_cell.sh" "${LESSON}" "${WORK}/shards/${LESSON}.jsonl"
