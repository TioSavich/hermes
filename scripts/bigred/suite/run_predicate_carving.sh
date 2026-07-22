#!/usr/bin/env bash
# Materialize finite lesson, operation, and containment tables.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${BIGRED_REPO_ROOT:-$(cd "$HERE/../../.." && pwd)}"
OUTPUT_ROOT="${BIGRED_OUTPUT_ROOT:-$REPO_ROOT/.bigred-output/predicate-carving}"
LIMIT=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --limit) LIMIT="${2:?--limit requires a value}"; shift 2 ;;
    *) echo "usage: $0 [--limit N]" >&2; exit 2 ;;
  esac
done

case "$LIMIT" in ''|*[!0-9]*) echo "--limit must be a nonnegative integer" >&2; exit 2 ;; esac
[ -f "$OUTPUT_ROOT/COMPLETE" ] && { echo "already complete: $OUTPUT_ROOT"; exit 0; }
cd "$REPO_ROOT"
command -v swipl >/dev/null 2>&1 || { echo "ERROR: required command is unavailable: swipl" >&2; exit 2; }
mkdir -p "$OUTPUT_ROOT"
BIGRED_OUTPUT_DIR="$OUTPUT_ROOT" BIGRED_LIMIT="$LIMIT" \
  swipl -q -l paths.pl -s scripts/bigred/suite/suite_batch.pl -g 'suite_batch:main(predicate_carving)' -t halt
touch "$OUTPUT_ROOT/COMPLETE"
