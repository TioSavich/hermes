#!/usr/bin/env bash
# Launch the Hermes teaching console. Reads this repo's live Prolog KB.
set -euo pipefail
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$APP_DIR/../.." && pwd)"

export UMEDCTA_ROOT="${UMEDCTA_ROOT:-$REPO_ROOT}"
export PYTHONPATH="$REPO_ROOT:${PYTHONPATH:-}"
HOST="${HERMES_HOST:-127.0.0.1}"
PORT="${HERMES_PORT:-8765}"

# FERPA gate default follows the bind host: loopback stays open for local
# testing, while non-loopback binds start gated unless HERMES_GATE is explicit.
if [ -z "${HERMES_GATE+x}" ]; then
  case "$HOST" in
    ""|"127.0.0.1"|"localhost"|"::1") export HERMES_GATE=off ;;
    *) export HERMES_GATE=on ;;
  esac
fi

# Load the key (gitignored) if present; the app's "Set key" button also works.
if [ -f "$APP_DIR/runtime/.env" ]; then set -a; . "$APP_DIR/runtime/.env"; set +a; fi

# Testing override (off by default): open the gate for synthetic/public-data
# testing off-campus. The console shows a red "testing only" banner.
#   HERMES_GATE_OVERRIDE=1 ./hermes/app/launch.sh

( sleep 2; (open "http://$HOST:$PORT" 2>/dev/null || xdg-open "http://$HOST:$PORT" 2>/dev/null || true) ) &
exec python3 -m hermes.app.server --host "$HOST" --port "$PORT"
