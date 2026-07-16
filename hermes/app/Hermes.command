#!/usr/bin/env bash
# Double-click launcher for the Hermes teaching console.
set -euo pipefail
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$APP_DIR/launch.sh"
