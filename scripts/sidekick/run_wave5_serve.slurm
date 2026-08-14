#!/usr/bin/env bash
#SBATCH --job-name=sidekick-wave5-serve
#SBATCH --account=r01990
#SBATCH --partition=gpu
#SBATCH --time=03:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --gres=gpu:1
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

# Serve both wave-5 arms so the scoring harness can reach them.
#
# The harness executes every emitted program through SWI-Prolog against the
# live encyclopedia, and neither is installed on this cluster. So this job
# holds the two models on the GPU and does no scoring: the controller opens a
# tunnel to the ports below and runs `run_wave5_f1.py` where swipl lives. The
# heavy half stays here, which is the standing rule for this cluster.
#
# Two arms, identical serving conditions, so the only difference between them
# is the weights and the frame:
#   tuned    port TUNED_PORT   zero-shot, the checkpoint job 7945580 produced
#   untuned  port UNTUNED_PORT eight-shot, the same base the tune started from
#
# The frozen F1 floor was measured through ollama against an earlier pairs
# file. It is a third, differently-conditioned point and not this comparison.

set -euo pipefail

STAGE="${SIDEKICK_STAGE:-/N/slate/tmsavich/sidekick}"
TUNED="${TUNED_GGUF:-$STAGE/runs/wave5-7945580/sidekick-wave5-Q4_K_M.gguf}"
UNTUNED="${UNTUNED_GGUF:-/N/scratch/datahub/nvme/llms/quantized/gemma-4-E2B-it/gemma-4-E2B-it_Q4_K_M.gguf}"
TUNED_PORT="${TUNED_PORT:-$((19000 + SLURM_JOB_ID % 1000))}"
UNTUNED_PORT="${UNTUNED_PORT:-$((TUNED_PORT + 1))}"
# Reasoning off on both. These rows trained as plain replies, and a thinking
# budget inside the 256-token reply cap returns empty content that reads as
# refusal rather than as an exhausted budget.
REASONING="${SET_REASONING:-off}"
HOLD_SECONDS="${HOLD_SECONDS:-10200}"

for path in "$TUNED" "$UNTUNED"; do
  test -r "$path" || { echo "missing weights: $path" >&2; exit 1; }
done

echo "node:          $(hostname)"
echo "tuned:         $TUNED"
echo "tuned port:    $TUNED_PORT"
echo "untuned:       $UNTUNED"
echo "untuned port:  $UNTUNED_PORT"
echo "reasoning:     $REASONING"

module purge
module load llamacpp/gpu/06182026

serve() {
  local weights="$1" port="$2" tag="$3"
  llama-server \
    -m "$weights" \
    --host 0.0.0.0 --port "$port" \
    -ngl 99 -c 8192 -np 1 \
    --jinja --reasoning "$REASONING" --no-ui \
    >"$STAGE/logs/llama-${tag}-${SLURM_JOB_ID}.log" 2>&1 &
  echo $!
}

TUNED_PID="$(serve "$TUNED" "$TUNED_PORT" tuned)"
UNTUNED_PID="$(serve "$UNTUNED" "$UNTUNED_PORT" untuned)"

cleanup() {
  kill "$TUNED_PID" "$UNTUNED_PID" 2>/dev/null || true
  wait "$TUNED_PID" "$UNTUNED_PID" 2>/dev/null || true
}
trap cleanup EXIT

for port in "$TUNED_PORT" "$UNTUNED_PORT"; do
  for _ in $(seq 1 300); do
    curl --silent --fail "http://127.0.0.1:$port/health" >/dev/null && break
    sleep 2
  done
  curl --silent --fail "http://127.0.0.1:$port/health" >/dev/null
  echo "healthy on $port"
done

# The identity of what is being served, recorded beside the run so a later
# reader can tell which bytes answered.
sha256sum "$TUNED" "$UNTUNED" | tee "$STAGE/runs/wave5-7945580/served-identity-${SLURM_JOB_ID}.txt"

cat <<EOF
WAVE5_SERVE_READY node=$(hostname) tuned_port=$TUNED_PORT untuned_port=$UNTUNED_PORT job=$SLURM_JOB_ID
tunnel from the controller with:
  ssh -F <sshconfig> -N -L 19080:$(hostname):$TUNED_PORT -L 19081:$(hostname):$UNTUNED_PORT bigred
EOF

# Hold the allocation while the controller scores. A sentinel file ends the
# job early so the GPU is not held after the harness finishes.
SENTINEL="$STAGE/runs/wave5-7945580/serve-${SLURM_JOB_ID}.stop"
for _ in $(seq 1 "$((HOLD_SECONDS / 10))"); do
  test -e "$SENTINEL" && { echo "sentinel seen; stopping"; break; }
  sleep 10
done
echo "WAVE5_SERVE_DONE"
