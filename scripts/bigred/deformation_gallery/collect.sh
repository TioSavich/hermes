#!/usr/bin/env bash
# Pull generated gallery trees from Big Red into this checkout; never deletes local files.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${LOCAL_REPO_ROOT:-$(cd "$HERE/../../.." && pwd)}"
REMOTE_HOST="${BIGRED_HOST:?set BIGRED_HOST, e.g. owner@bigred200.uits.iu.edu}"
REMOTE_DIR="${BIGRED_DIR:?set BIGRED_DIR to the scratch checkout root}"
REMOTE_OUTPUT="${BIGRED_OUTPUT_ROOT:-$REMOTE_DIR/.bigred-output/task-75-deformation-gallery}"
LOCAL_GENERATED_ROOT="${LOCAL_GENERATED_ROOT:-$REPO_ROOT/hermes/app/web/generated}"

mkdir -p "$LOCAL_GENERATED_ROOT/lesson_deformation_charts" "$LOCAL_GENERATED_ROOT/notation_lesson_charts"
rsync -az "$REMOTE_HOST:$REMOTE_OUTPUT/lesson_deformation_charts/" "$LOCAL_GENERATED_ROOT/lesson_deformation_charts/"
if [ "${INCLUDE_NOTATION_CHARTS:-1}" = "1" ]; then
  rsync -az "$REMOTE_HOST:$REMOTE_OUTPUT/notation_lesson_charts/" "$LOCAL_GENERATED_ROOT/notation_lesson_charts/"
fi
printf 'Collected generated gallery trees into %s\n' "$LOCAL_GENERATED_ROOT"
