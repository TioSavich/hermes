#!/usr/bin/env bash
# Task 75: lean lesson deformation gallery on IU Big Red.
# Replace the account and email placeholders before submitting.
#SBATCH --job-name=hermes-deformation-gallery
#SBATCH --account=REPLACE_WITH_BIG_RED_ACCOUNT
#SBATCH --partition=general
#SBATCH --time=2:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --output=scripts/bigred/deformation_gallery/work/logs/%x_%j.out
#SBATCH --error=scripts/bigred/deformation_gallery/work/logs/%x_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=REPLACE_WITH_OWNER_EMAIL

set -euo pipefail
REPO_ROOT="${SLURM_SUBMIT_DIR:?submit from the scratch checkout root}"
cd "$REPO_ROOT"
mkdir -p scripts/bigred/deformation_gallery/work/logs

if ! command -v module >/dev/null 2>&1 && [ -r /opt/cray/pe/lmod/lmod/init/bash ]; then
  # shellcheck disable=SC1091
  source /opt/cray/pe/lmod/lmod/init/bash
fi
module purge
module load conda/25.3.0
module load sqlite/3.50.3
# shellcheck disable=SC1091
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${HERMES_ENV:-umedcta}"

echo "[$(date -Is)] host=$(hostname) python=$(command -v python3) swipl=$(command -v swipl) node=$(command -v node)"
bash scripts/bigred/deformation_gallery/run.sh
