#!/usr/bin/env bash
# Copy the synthetic example roster + discussion paste into runtime/ so you can
# exercise the workflow off-campus (launch with HERMES_GATE_OVERRIDE=1).
set -euo pipefail
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$APP_DIR/runtime/input"
cp "$APP_DIR/examples/roster.csv" "$APP_DIR/runtime/roster.csv"
cp "$APP_DIR/examples/All_Discussions.txt" "$APP_DIR/runtime/input/All_Discussions.txt"
echo "seeded: runtime/roster.csv + runtime/input/All_Discussions.txt (synthetic)"
