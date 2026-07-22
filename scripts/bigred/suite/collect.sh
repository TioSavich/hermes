#!/usr/bin/env bash
# Pull the suite output to one local tarball without deleting remote results.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${LOCAL_REPO_ROOT:-$(cd "$HERE/../../.." && pwd)}"
REMOTE_HOST="${BIGRED_HOST:?set BIGRED_HOST, e.g. owner@bigred200.uits.iu.edu}"
REMOTE_DIR="${BIGRED_DIR:?set BIGRED_DIR to the scratch checkout root}"
LOCAL_ROOT="${BIGRED_COLLECT_ROOT:-$REPO_ROOT/.bigred-collected/task-80-suite}"
STAMP="$(date +%Y%m%d-%H%M)"

mkdir -p "$LOCAL_ROOT"
rsync -az "$REMOTE_HOST:$REMOTE_DIR/.bigred-output/" "$LOCAL_ROOT/"
tar -C "$LOCAL_ROOT" -czf "$REPO_ROOT/hermes-bigred-suite-results-$STAMP.tar.gz" .
printf 'Collected suite results: %s\n' "$REPO_ROOT/hermes-bigred-suite-results-$STAMP.tar.gz"
