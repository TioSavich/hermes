#!/usr/bin/env bash
#SBATCH --job-name=hermes-audit-reader
#SBATCH --account=r01990
#SBATCH --partition=gpu
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --gres=gpu:1
#SBATCH --output=/N/scratch/tmsavich/hermes/.bigred-output/2026-08-22-total-audit-run3/stageB_%j.out
#SBATCH --error=/N/scratch/tmsavich/hermes/.bigred-output/2026-08-22-total-audit-run3/stageB_%j.err

# Stage B — the bounded model pass over untouched stores. Runs after Stage A
# (submit with --dependency=afterok:<stageA jobid>). Serves gemma-4-26B-A4B
# node-local and lets model_reader.py checkpoint per store.
set -euo pipefail

REPO=/N/scratch/tmsavich/hermes
RUN=$REPO/.bigred-output/2026-08-22-total-audit-run3
ENVBIN=/N/u/tmsavich/BigRed200/.conda/envs/umedcta/bin
MODEL=/N/scratch/datahub/nvme/llms/quantized/gemma-4-26B-A4B-it/gemma-4-26B-A4B-it_Q4_K_M.gguf
PORT=8088
cd "$REPO"
mkdir -p "$RUN"

set +u
module purge
module load llamacpp/gpu/06182026
set -u
export PATH="$ENVBIN:$PATH"

llama-server -m "$MODEL" \
  --host 127.0.0.1 --port "$PORT" \
  -ngl 99 -c 16384 -np 1 \
  --jinja --reasoning off --no-ui \
  > "$RUN/llama-server.log" 2>&1 &
SERVER_PID=$!
cleanup() { kill "$SERVER_PID" 2>/dev/null || true; wait "$SERVER_PID" 2>/dev/null || true; }
trap cleanup EXIT

for _ in $(seq 1 120); do
  if curl --silent --fail "http://127.0.0.1:$PORT/health" >/dev/null; then
    break
  fi
  sleep 5
done
curl --silent --fail "http://127.0.0.1:$PORT/health" >/dev/null

"$ENVBIN/python3" -u scripts/bigred/total_audit/model_reader.py \
  --out "$RUN" --llama "http://127.0.0.1:$PORT"
echo "[stageB] complete $(date -Is)"
