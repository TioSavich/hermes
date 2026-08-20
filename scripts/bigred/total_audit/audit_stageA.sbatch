#!/usr/bin/env bash
#SBATCH --job-name=hermes-total-audit
#SBATCH --account=r01990
#SBATCH --partition=general
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --output=/N/scratch/tmsavich/hermes/.bigred-output/2026-08-19-total-audit/stageA_%j.out
#SBATCH --error=/N/scratch/tmsavich/hermes/.bigred-output/2026-08-19-total-audit/stageA_%j.err

# Stage A — the deterministic lanes: closure, census, load probe, op sweep
# under clause coverage, HTTP sweep, ledger. Every step leaves a done-marker
# so a resubmit resumes instead of recomputing; the sweep and HTTP lanes
# additionally checkpoint per item inside their own result files.
set -euo pipefail

REPO=/N/scratch/tmsavich/hermes
RUN=$REPO/.bigred-output/2026-08-19-total-audit
ENVBIN=/N/u/tmsavich/BigRed200/.conda/envs/umedcta/bin
export HERMES_SWIPL=$ENVBIN/swipl
export HERMES_PYTHON=$ENVBIN/python3
export PATH="$ENVBIN:$PATH"
mkdir -p "$RUN"
cd "$REPO"

step() {  # step NAME CMD... — run once, marker-gated, timed, loud
  local name=$1; shift
  local marker=$RUN/.done_$name
  if [ -e "$marker" ]; then echo "[stageA] $name: already done"; return 0; fi
  echo "[stageA] $name: start $(date -Is)"
  "$@"
  touch "$marker"
  echo "[stageA] $name: done $(date -Is)"
}

closure() {
  "$HERMES_SWIPL" -q -l hermes_worker.pl \
    -g 'load_runtime, forall(source_file(F), writeln(F)), halt(0)' \
    -t 'halt(1)' > "$RUN/closure.txt" 2> "$RUN/closure.stderr"
  [ -s "$RUN/closure.txt" ]
}

shipped() {
  grep '\.pl$' scripts/bundle/app_manifest.txt > "$RUN/shipped.txt" || true
  [ -s "$RUN/shipped.txt" ]
}

census() {
  "$HERMES_SWIPL" -q -g main scripts/bigred/total_audit/parse_census.pl -- \
    "$RUN/filelist_pl.txt" "$RUN/pl_census.jsonl"
  [ -s "$RUN/pl_census.jsonl" ]
}

probe() {
  bash scripts/bigred/total_audit/load_probe.sh \
    "$RUN/filelist_pl.txt" "$RUN/load_probe.jsonl" 12
}

sweep() {
  "$HERMES_PYTHON" -u scripts/bigred/total_audit/sweep_driver.py \
    --out "$RUN" --max-per-op 2000 --item-timeout 180
  [ -s "$RUN/sweep_results.jsonl" ]
}

http() {
  "$HERMES_PYTHON" -u scripts/bigred/total_audit/http_sweep.py \
    --out "$RUN" --port 8801 --domains "$RUN/domains.json"
  [ -s "$RUN/http_results.jsonl" ]
}

ledger() {
  "$HERMES_PYTHON" -u scripts/bigred/total_audit/coverage_ledger.py --out "$RUN"
  [ -s "$RUN/audit_ledger.json" ]
}

step closure closure
step shipped shipped
step census census
step probe probe
step sweep sweep
step http http
step ledger ledger
echo "[stageA] complete $(date -Is)"
