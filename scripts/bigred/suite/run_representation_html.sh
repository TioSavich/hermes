#!/usr/bin/env bash
# Generate the two offline lesson-gallery trees.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${BIGRED_REPO_ROOT:-$(cd "$HERE/../../.." && pwd)}"
OUTPUT_ROOT="${BIGRED_OUTPUT_ROOT:-$REPO_ROOT/.bigred-output/representation-html}"
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
for command in python3 swipl node; do
  command -v "$command" >/dev/null 2>&1 || { echo "ERROR: required command is unavailable: $command" >&2; exit 2; }
done
mkdir -p "$OUTPUT_ROOT"

if [ "$LIMIT" -gt 0 ]; then
  python3 hermes/app/scripts/export_lesson_deformation_charts.py --lean --limit "$LIMIT" --out "$OUTPUT_ROOT/lesson_deformation_charts"
  python3 hermes/app/scripts/export_notation_charts.py --limit "$LIMIT" --out "$OUTPUT_ROOT/notation_lesson_charts"
else
  python3 hermes/app/scripts/export_lesson_deformation_charts.py --lean --out "$OUTPUT_ROOT/lesson_deformation_charts"
  python3 hermes/app/scripts/export_notation_charts.py --out "$OUTPUT_ROOT/notation_lesson_charts"
fi
find "$OUTPUT_ROOT" -type f | sort > "$OUTPUT_ROOT/files.txt"
touch "$OUTPUT_ROOT/COMPLETE"
printf 'Representation HTML complete: %s\n' "$OUTPUT_ROOT"
