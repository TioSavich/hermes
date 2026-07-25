#!/bin/bash
#SBATCH --job-name=lit-embed
#SBATCH --account=r01990
#SBATCH --partition=general
#SBATCH --array=0-11
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --time=03:00:00
#SBATCH --mem=32G
#SBATCH --output=/N/scratch/tmsavich/hermes/logs/embed/embed_%A_%a.out
#SBATCH --error=/N/scratch/tmsavich/hermes/logs/embed/embed_%A_%a.err

# One journal per array task. Each writes its own .npy/.jsonl pair atomically and
# skips work already complete, so a resubmission after a wall-clock kill costs
# only the journal that was in flight.
set +u
module load conda
conda activate umedcta
set -u

cd /N/scratch/tmsavich/hermes
export OMP_NUM_THREADS=8
export HF_HUB_OFFLINE=1          # compute nodes have no network; the cache is warm

echo "BATCH_START task=${SLURM_ARRAY_TASK_ID} host=$(hostname) $(date -Is)"
python scripts/bigred/literature_embeddings/embed_corpus.py \
  --corpus .bigred-output/literature \
  --out .bigred-output/lit-embeddings \
  --journal-index "${SLURM_ARRAY_TASK_ID}"
status=$?
echo "BATCH_COMPLETE task=${SLURM_ARRAY_TASK_ID} status=${status} $(date -Is)"
exit $status
