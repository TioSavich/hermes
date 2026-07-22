#!/usr/bin/env bash
# Run only execution-contracted registry signatures; never invent inputs.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${BIGRED_REPO_ROOT:-$(cd "$HERE/../../.." && pwd)}"
OUTPUT_ROOT="${BIGRED_OUTPUT_ROOT:-$REPO_ROOT/.bigred-output/modeling}"
LIMIT=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --limit) LIMIT="${2:?--limit requires a value}"; shift 2 ;;
    *) echo "usage: $0 [--limit N]" >&2; exit 2 ;;
  esac
done
case "$LIMIT" in ''|*[!0-9]*) echo "--limit must be a nonnegative integer" >&2; exit 2 ;; esac
cd "$REPO_ROOT"
mkdir -p "$OUTPUT_ROOT"
python3 "$HERE/run_modeling.py" --limit "$LIMIT" --output "$OUTPUT_ROOT"
