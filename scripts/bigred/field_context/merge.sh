#!/usr/bin/env bash
# Merge a collected, complete partial set without replacing the in-tree cache.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${BIGRED_REPO_ROOT:-$(cd "$HERE/../../.." && pwd)}"
PARTIALS_DIR="${1:-${FIELD_CONTEXT_PARTIALS_DIR:-$REPO_ROOT/.bigred-output/field-context/partials}}"
OUTPUT_PATH="${2:-${FIELD_CONTEXT_MERGE_OUTPUT:-$REPO_ROOT/.bigred-output/field-context/field_context_cache.json}}"

[ "$#" -le 2 ] || {
  echo "usage: $0 [PARTIALS_DIR [OUTPUT_PATH]]" >&2
  exit 2
}

mkdir -p "$(dirname "$OUTPUT_PATH")"
python3 "$REPO_ROOT/scripts/research/build_field_context_cache.py" \
  --partials-dir "$PARTIALS_DIR" \
  --merge-only \
  --require-complete \
  --output "$OUTPUT_PATH"
printf 'Merged field-context cache: %s\n' "$OUTPUT_PATH"
