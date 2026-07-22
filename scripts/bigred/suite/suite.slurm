#!/usr/bin/env bash
# Offline Big Red scenario suite. Replace account and email before submit.
#SBATCH --job-name=hermes-scenario-suite
#SBATCH --account=REPLACE_WITH_BIG_RED_ACCOUNT
#SBATCH --partition=general
#SBATCH --time=8:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --output=scripts/bigred/suite/work/logs/%x_%j.out
#SBATCH --error=scripts/bigred/suite/work/logs/%x_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=REPLACE_WITH_OWNER_EMAIL

set -euo pipefail
REPO_ROOT="${SLURM_SUBMIT_DIR:?submit from the scratch checkout root}"
cd "$REPO_ROOT"
mkdir -p scripts/bigred/suite/work/logs

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

echo "[$(date -Is)] host=$(hostname) python=$(command -v python3) swipl=$(command -v swipl) node=$(command -v node)"
bash scripts/bigred/suite/run_field_context.sh
bash scripts/bigred/suite/run_learner_paths.sh
bash scripts/bigred/suite/run_hyperedges.sh
bash scripts/bigred/suite/run_search_traces.sh
bash scripts/bigred/suite/run_predicate_carving.sh
bash scripts/bigred/suite/run_representation_html.sh
