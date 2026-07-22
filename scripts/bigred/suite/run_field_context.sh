#!/usr/bin/env bash
# Rebuild the whole-curriculum field-context cache on the cluster.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${BIGRED_REPO_ROOT:-$(cd "$HERE/../../.." && pwd)}"
OUTPUT_ROOT="${BIGRED_OUTPUT_ROOT:-$REPO_ROOT/.bigred-output/field-context}"

[ "$#" -eq 0 ] || { echo "usage: $0" >&2; exit 2; }
[ -f "$OUTPUT_ROOT/COMPLETE" ] && { echo "already complete: $OUTPUT_ROOT"; exit 0; }

cd "$REPO_ROOT"
for command in python3 swipl; do
  command -v "$command" >/dev/null 2>&1 || { echo "ERROR: required command is unavailable: $command" >&2; exit 2; }
done
mkdir -p "$OUTPUT_ROOT"

# The builder has one canonical in-tree destination.  Preserve that result for
# the controller's drift-check cycle and return a copy in the collected output.
python3 scripts/research/build_field_context_cache.py
cp curriculum/im/generated/field_context_cache.json "$OUTPUT_ROOT/field_context_cache.json"
touch "$OUTPUT_ROOT/COMPLETE"
printf 'Field-context rebuild complete: %s\n' "$OUTPUT_ROOT/field_context_cache.json"
