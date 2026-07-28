#!/usr/bin/env bash
# The Atlas aggregate job, afterok the sweep array. Two steps: the traversal-
# audit coverage record, then the merge into landscape, fact store, and summary.
# Replace the account and email placeholders before submitting.
#SBATCH --job-name=hermes-atlas-aggregate
#SBATCH --account=REPLACE_WITH_BIG_RED_ACCOUNT
#SBATCH --partition=general
# 4h, not 1h: the coverage step runs the full K-6 traversal audit, which
# executes every instanced lesson's routes; over a 151-lesson alphabet that
# exceeded 1h on a cluster core.
#SBATCH --time=4:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --output=scripts/bigred/atlas/work/logs/%x_%j.out
#SBATCH --error=scripts/bigred/atlas/work/logs/%x_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=REPLACE_WITH_OWNER_EMAIL

set -eo pipefail
REPO_ROOT="${SLURM_SUBMIT_DIR:?submit from the scratch checkout root}"
cd "$REPO_ROOT"

HERE_REL="scripts/bigred/atlas"
mkdir -p "${ATLAS_WORK:-${HERE_REL}/work}/logs"

if ! command -v module >/dev/null 2>&1 && [ -r /opt/cray/pe/lmod/lmod/init/bash ]; then
  # shellcheck disable=SC1091
  source /opt/cray/pe/lmod/lmod/init/bash
fi
module purge
module load conda/25.3.0
# shellcheck disable=SC1091
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${HERMES_ENV:-umedcta}"

echo "[$(date -Is)] host=$(hostname) swipl=$(command -v swipl)"
bash "${HERE_REL}/run.sh" --aggregate
