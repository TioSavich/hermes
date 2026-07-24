#!/usr/bin/env bash
# Offline strategy-algebra analysis. Replace account and email before submit.
# BEFORE sbatch, create: scripts/bigred/strategy_algebra/work/logs
# Slurm opens --output/--error before this script begins; mkdir here is too late.
#SBATCH --job-name=hermes-strategy-algebra
#SBATCH --account=REPLACE_WITH_BIG_RED_ACCOUNT
#SBATCH --partition=general
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --output=scripts/bigred/strategy_algebra/work/logs/%x_%j.out
#SBATCH --error=scripts/bigred/strategy_algebra/work/logs/%x_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=REPLACE_WITH_OWNER_EMAIL

set -eo pipefail
REPO_ROOT="${SLURM_SUBMIT_DIR:?submit from the scratch checkout root}"
cd "$REPO_ROOT"

# lmod and conda setup scripts read unset shell variables such as PS1.
set +u
if ! command -v module >/dev/null 2>&1 && [ -r /opt/cray/pe/lmod/lmod/init/bash ]; then
  source /opt/cray/pe/lmod/lmod/init/bash
fi
module purge
module load conda/25.3.0
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${HERMES_ENV:-umedcta}"
set -u

OUTPUT_ROOT="${STRATEGY_ALGEBRA_OUTPUT:-$REPO_ROOT/.bigred-output/strategy-algebra}"
mkdir -p "$OUTPUT_ROOT"
echo "[$(date -Is)] host=$(hostname) python=$(command -v python3)"
python3 scripts/bigred/strategy_algebra/analyze_strategy_algebra.py \
  --output "$OUTPUT_ROOT"
