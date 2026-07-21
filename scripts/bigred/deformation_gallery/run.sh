#!/usr/bin/env bash
# Run from a Hermes checkout on Big Red. It installs nothing.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${BIGRED_REPO_ROOT:-$(cd "$HERE/../../.." && pwd)}"
OUTPUT_ROOT="${BIGRED_OUTPUT_ROOT:-$REPO_ROOT/.bigred-output/task-75-deformation-gallery}"
cd "$REPO_ROOT"
for command in python3 swipl node; do
  command -v "$command" >/dev/null 2>&1 || { echo "ERROR: required command is unavailable: $command" >&2; exit 2; }
done

rm -rf "$OUTPUT_ROOT"
mkdir -p "$OUTPUT_ROOT"
python3 hermes/app/scripts/export_lesson_deformation_charts.py --lean --out "$OUTPUT_ROOT/lesson_deformation_charts"

# Optional because it uses the same render harness and is comparatively small.
if [ "${INCLUDE_NOTATION_CHARTS:-1}" = "1" ]; then
  python3 hermes/app/scripts/export_notation_charts.py --out "$OUTPUT_ROOT/notation_lesson_charts"
fi
find "$OUTPUT_ROOT" -maxdepth 2 -type f | sort > "$OUTPUT_ROOT/files.txt"
printf 'Generated trees are ready under %s\n' "$OUTPUT_ROOT"
