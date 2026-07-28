#!/usr/bin/env bash
# Run the Atlas export for ONE lesson shard.
#
#   bash scripts/bigred/atlas/run_cell.sh <LESSON_CODE> [OUT_PATH]
#
# One cell = one lesson = one swipl process, on the laptop and on the cluster
# alike. Consults THROUGH paths.pl (not flat): task_transition ->
# activity_contract resolves lessons()/math()/render()/standards()/geometry()/
# crosswalk() via file_search_path, so paths.pl must load first.
#
# The per-transition wall limit lives inside the Prolog (ATLAS_CELL_SECONDS);
# `timeout` here is only a whole-cell backstop and is used when available (Linux
# / Big Red). macOS has no `timeout`, so a local run relies on the Prolog limit.
set -eo pipefail

# ---- path vocabulary, named once -------------------------------------------
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
HERE_REL="scripts/bigred/atlas"
PATHS_PL="paths.pl"
WORK_REL="${HERE_REL}/work"

LESSON="${1:?usage: run_cell.sh <LESSON_CODE> [OUT_PATH]}"
OUT="${2:-${WORK_REL}/shards/${LESSON}.jsonl}"

cd "${REPO_ROOT}"
mkdir -p "$(dirname "$OUT")"

GOAL="atlas_export:run('${LESSON}', '${OUT}'), halt"

MAYBE_TIMEOUT=()
if command -v timeout >/dev/null 2>&1; then
  MAYBE_TIMEOUT=(timeout "${ATLAS_CELL_WALL:-4800}")
fi

# ATLAS_STACK_LIMIT bounds the Prolog stacks. A bound is what makes a runaway
# transition (a large-operand instance grinding a unit-iteration machine through
# GC stints the 20s alarm cannot interrupt) overflow early and catchably, so the
# guard records resource_error and the cell survives -- found live on cell
# IM-G7-U2-L8, multiply(1500, 30000).
#
# The default is 4g, not the vendored 1g. At 1g this laptop records
# resource_error on the last 13 transitions of IM-G6-U3-L13 and IM-G6-U3-L6 --
# the four multiply(...) instances that sort after 51 divide(...) transitions in
# the same process -- where the cluster solved all 13. Raising the bound closes
# every one of them and reproduces the cluster's records exactly. The bound is
# still a bound; it sits below the 8G the sweep job requests.
"${MAYBE_TIMEOUT[@]}" swipl -q --stack_limit="${ATLAS_STACK_LIMIT:-4g}" \
  -l "${PATHS_PL}" -l "${HERE_REL}/export_atlas.pl" \
  -g "${GOAL}" -t "halt(1)"

echo "[atlas/cell] ${LESSON} -> ${OUT} ($(wc -l < "$OUT" | tr -d ' ') records)"
