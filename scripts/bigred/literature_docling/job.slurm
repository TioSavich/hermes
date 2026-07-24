#!/usr/bin/env bash
# One checkpointed Docling task per literature journal directory.
#SBATCH --job-name=hermes-literature
#SBATCH --account=REPLACE_WITH_BIG_RED_ACCOUNT
#SBATCH --partition=general
#SBATCH --array=0-11
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=48G
#SBATCH --output=scripts/bigred/literature_docling/logs/%x_%A_%a.out
#SBATCH --error=scripts/bigred/literature_docling/logs/%x_%A_%a.err

set -euo pipefail

REPO_ROOT="${SLURM_SUBMIT_DIR:?submit from the Big Red Hermes checkout root}"
cd "$REPO_ROOT"

LOG_DIR="$REPO_ROOT/scripts/bigred/literature_docling/logs"
OUTPUT_ROOT="${LITERATURE_OUTPUT_ROOT:-$REPO_ROOT/.bigred-output/literature}"
mkdir -p "$LOG_DIR" "$OUTPUT_ROOT"

ARRAY_INDEX="${SLURM_ARRAY_TASK_ID:?this script must run as a Slurm array}"
JOURNALS=(ESM FLM IJEMST IJMEST IJSME JMB JMTE JRME MERJ MTL RME ZDM)
if [ "$ARRAY_INDEX" -ge "${#JOURNALS[@]}" ]; then
  echo "ERROR: unsupported array index: $ARRAY_INDEX" >&2
  exit 2
fi
JOURNAL="${JOURNALS[$ARRAY_INDEX]}"

CORPUS_ROOT="${LITERATURE_CORPUS_ROOT:-$REPO_ROOT/research_corpus/pdfs}"
CORPUS_BIB="${LITERATURE_CORPUS_BIB:-$REPO_ROOT/research_corpus/references.bib}"
REPO_BIB="$REPO_ROOT/data/research/references.bib"
PDF_TIMEOUT="${LITERATURE_PDF_TIMEOUT:-1800}"
TASK_LOG="$LOG_DIR/${SLURM_JOB_NAME}_${SLURM_ARRAY_JOB_ID}_${ARRAY_INDEX}.log"
exec > >(tee -a "$TASK_LOG") 2>&1

if ! command -v module >/dev/null 2>&1 && [ -r /opt/cray/pe/lmod/lmod/init/bash ]; then
  source /opt/cray/pe/lmod/lmod/init/bash
fi
set +u
module purge
module load conda/25.3.0
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${HERMES_ENV:-umedcta}"
set -u

echo "[$(date -Is)] journal=$JOURNAL host=$(hostname) python=$(command -v python3)"
python3 scripts/research/literature_intake.py \
  --journal-dir "$CORPUS_ROOT/$JOURNAL" \
  --journal "$JOURNAL" \
  --output-root "$OUTPUT_ROOT" \
  --corpus-root "$CORPUS_ROOT" \
  --corpus-bib "$CORPUS_BIB" \
  --repo-bib "$REPO_BIB" \
  --per-pdf-timeout "$PDF_TIMEOUT" \
  --threads "${SLURM_CPUS_PER_TASK:-8}" \
  --resume
echo "[$(date -Is)] journal=$JOURNAL complete output=$OUTPUT_ROOT/$JOURNAL"
