#!/usr/bin/env bash
#SBATCH --job-name=hermes-questions-admission
#SBATCH --account=r01990
#SBATCH --partition=gpu
#SBATCH --time=06:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --gres=gpu:1
#SBATCH --output=/N/scratch/tmsavich/hermes/.bigred-output/2026-08-20-questions-admission/judge_%j.out
#SBATCH --error=/N/scratch/tmsavich/hermes/.bigred-output/2026-08-20-questions-admission/judge_%j.err

# Mechanical question admission, stage 2 -- the bounded model pass. Serves
# gemma-4-26B-A4B-it Q4_K_M node-local (the same checkpoint judge_stageB.sbatch
# uses, so testimony names one model) and lets judge.py checkpoint per row.
# No end-of-run dump exists in judge.py (append+flush per row), so there is
# no SIGTERM save race to guard against here.
set -euo pipefail

REPO=/N/scratch/tmsavich/hermes
RUN=$REPO/.bigred-output/2026-08-20-questions-admission
ENVBIN=/N/u/tmsavich/BigRed200/.conda/envs/umedcta/bin
MODEL=/N/scratch/datahub/nvme/llms/quantized/gemma-4-26B-A4B-it/gemma-4-26B-A4B-it_Q4_K_M.gguf
PORT=8089
cd "$REPO"
mkdir -p "$RUN"

set +u
module purge
module load llamacpp/gpu/06182026
set -u
export PATH="$ENVBIN:$PATH"

llama-server -m "$MODEL" \
  --host 127.0.0.1 --port "$PORT" \
  -ngl 99 -c 16384 -np 4 \
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

"$ENVBIN/python3" -u scripts/bigred/questions_admission/judge.py \
  --llama "http://127.0.0.1:$PORT" \
  --job "${SLURM_JOB_ID:-unknown}" \
  --verdicts "$RUN/verdicts.jsonl" \
  --pass-void "$RUN/pass_void.json"
echo "[judge] complete $(date -Is)"
