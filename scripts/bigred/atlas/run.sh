#!/usr/bin/env bash
# The Atlas sweep: one step of f_{t,c} for every compiled task event x every
# licensed learner stage, sharded by lesson.
#
#   bash scripts/bigred/atlas/run.sh --local [N]     # sequential, this laptop
#   bash scripts/bigred/atlas/run.sh --cells         # cell list only
#   bash scripts/bigred/atlas/run.sh --merge         # merge existing shards
#   bash scripts/bigred/atlas/run.sh --coverage      # the traversal-audit record
#   bash scripts/bigred/atlas/run.sh --aggregate     # coverage, then merge
#   bash scripts/bigred/atlas/run.sh --go            # submit the sbatch chain
#
# --local is the deliverable path: it generates the cell list, runs the first N
# lesson shards in one process each, one after another, then merges. N defaults
# to every cell. Nothing about it needs SLURM.
#
# --local does NOT run coverage. Coverage executes the full traversal audit over
# every instanced lesson and does not finish inside ten minutes on a laptop at
# the default grade ceiling of 6; the landscape does not depend on it, and only
# the summary's gap accounting does. Run --coverage separately (or lower
# ATLAS_GRADE_MAX) and then --merge to fold it in.
#
# --go keeps the cluster route: an array job over the cells and, afterok, the
# aggregate. Identical shards either way; only the scheduler differs.
#
# Env knobs, defined in export_atlas.pl: ATLAS_STAGES, ATLAS_POLICY,
# ATLAS_CELL_SECONDS, ATLAS_GRADE_MAX, ATLAS_CELL_WALL, ATLAS_STACK_LIMIT.
# ATLAS_WORK redirects the whole work tree, which is how a comparison run writes
# somewhere other than the tracked output.
set -eo pipefail

# ---- path vocabulary, named once -------------------------------------------
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
HERE_REL="scripts/bigred/atlas"
PATHS_PL="paths.pl"
WORK="${ATLAS_WORK:-${HERE_REL}/work}"
CELLS="${WORK}/cells.json"

cd "${REPO_ROOT}"

gen_cells() {
  mkdir -p "${WORK}/shards" "${WORK}/logs"
  ATLAS_COMMIT="$(git rev-parse HEAD 2>/dev/null || echo unknown)" \
  ATLAS_DATE="$(date +%F)" \
  swipl -q -l "${PATHS_PL}" -l "${HERE_REL}/generate_cells.pl" \
    -g 'atlas_cells:main, halt' -t 'halt(1)' -- "${CELLS}"
}

cell_count() {
  python3 -c "import json;print(len(json.load(open('${CELLS}'))['cells']))"
}

nth_lesson() {
  python3 -c "import json;print(json.load(open('${CELLS}'))['cells'][$1]['lesson'])"
}

coverage() {
  echo "[atlas] coverage through grade ${ATLAS_GRADE_MAX:-6} (the slow step)"
  swipl -q -l "${PATHS_PL}" -l "${HERE_REL}/export_atlas.pl" \
    -g "atlas_export:coverage('${WORK}/audit_coverage.json'), halt" \
    -t "halt(1)" || echo "[atlas] coverage failed; the summary marks it absent"
}

merge() {
  echo "[atlas] merge shards"
  python3 "${HERE_REL}/aggregate.py" --repo . --work "${WORK}"
}

case "${1:-}" in
  --cells)
    gen_cells
    ;;

  --local)
    gen_cells
    TOTAL="$(cell_count)"
    N="${2:-${TOTAL}}"
    LIMIT="${N}"; [ "${LIMIT}" -gt "${TOTAL}" ] && LIMIT="${TOTAL}"
    echo "[atlas] local sweep: ${LIMIT}/${TOTAL} cells, sequential, no SLURM"
    rm -f "${WORK}"/shards/*.jsonl 2>/dev/null || true
    for i in $(seq 0 $((LIMIT - 1))); do
      LESSON="$(nth_lesson "${i}")"
      bash "${HERE_REL}/run_cell.sh" "${LESSON}" "${WORK}/shards/${LESSON}.jsonl"
    done
    merge
    ;;

  --merge)
    merge
    ;;

  --coverage)
    coverage
    ;;

  --aggregate)
    coverage
    merge
    ;;

  --go)
    gen_cells
    N="$(cell_count)"
    if [ "${N}" -lt 1 ]; then echo "[atlas] no cells; nothing to submit"; exit 1; fi
    ARR=$((N - 1))
    echo "[atlas] cells=${N}; submitting array 0-${ARR}"
    SWEEP_JOB=$(sbatch --parsable --array=0-"${ARR}" "${HERE_REL}/job.slurm")
    echo "[atlas] sweep array job: ${SWEEP_JOB}"
    AGG_JOB=$(sbatch --parsable --dependency=afterok:"${SWEEP_JOB}" "${HERE_REL}/aggregate.slurm")
    echo "[atlas] aggregate job (afterok ${SWEEP_JOB}): ${AGG_JOB}"
    echo "[atlas] monitor: squeue -u ${USER}"
    echo "[atlas] artifacts: ${WORK}/atlas_landscape.jsonl, atlas_facts.pl, atlas_summary.json"
    ;;

  *)
    echo "usage: run.sh --local [N] | --cells | --merge | --coverage | --aggregate | --go"
    exit 0
    ;;
esac
