#!/usr/bin/env bash
# Start the local sidekick model server (llama-server) for the Sidekick chat
# page. The console never spawns this; when it is not running, the page says
# so and answers from the knowledge base alone. See hermes/app/SIDEKICK.md.
#
# The serving flags are the measured configuration
# (scripts/bigred/run_diagnosis_full.slurm and the laptop log at
# hermes/app/runtime/experiments/sidekick/floors/llama-server-laptop.log).
# --reasoning off is deliberate: a thinking budget inside a small reply cap
# returns empty content that reads as refusal.
set -euo pipefail
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MODEL="${HERMES_SIDEKICK_GGUF:-$APP_DIR/runtime/experiments/sidekick/models/sidekick-Q4_K_M.gguf}"
PORT="${HERMES_SIDEKICK_PORT:-8080}"

if ! command -v llama-server >/dev/null 2>&1; then
  echo "llama-server is not on PATH. Install llama.cpp (brew install llama.cpp)." >&2
  exit 1
fi
if [ ! -f "$MODEL" ]; then
  echo "No model file at $MODEL." >&2
  echo "The checkpoint is not tracked in git; hermes/app/SIDEKICK.md says how to place it." >&2
  exit 1
fi

exec llama-server -m "$MODEL" --host 127.0.0.1 --port "$PORT" \
  -ngl 99 -c 8192 -np 1 --jinja --reasoning off --no-ui
