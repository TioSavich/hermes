#!/usr/bin/env bash
# dynamic_cov_probe.sh — INSTRUMENT CHECK (widening spec section b, task
# 0820D). Runs one incompatibility_contexts call under the existing
# cov_worker.pl harness, LOCALLY, and reports whether library(prolog_coverage)
# emits any cl(...) record naming a file whose predicate the call actually
# reads is declared `:- dynamic`.
#
# incompatibility_contexts dispatches to
# incompatibility_sets:a_fortiori_context_nesting_inventory/2, which reads
# a_fortiori_context_nesting/4 — declared dynamic in
# formal/incompatibility/incompatibility_sets.pl and populated by consulting
# formal/incompatibility/incompatibility_sets_a_fortiori_context_closure.pl.
# That is one of the three stores section (b) names (the other two,
# incompatibility_sets_discovered.pl and incompatibility_sets_error_rules.pl,
# populate discovered_set_fact/2, discovered_set_kind/3, and
# error_rule_crosstalk_defeat_count/3 — also declared dynamic in the same
# owning file). The three share one instrument question, so one call answers
# for all three: does a fresh clause asserted into a `:- dynamic` predicate
# after load ever show up in library(prolog_coverage)'s per-clause records?
#
# Usage (from the repo root):
#   bash scripts/bigred/total_audit/dynamic_cov_probe.sh [OUTDIR]
#
# macOS has no `timeout`; this reuses the clean-EOF recipe launch.sh's law
# zero already verified works for cov_worker.pl (pipe one request, close
# stdin, let cov_main's at_halt hook save on EOF) rather than a background
# PID + SIGTERM dance, which is only needed to test kill survival.
set -uo pipefail

REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
OUT="${1:-$REPO/.bigred-collected/dynamic-cov-probe-local}"
SWIPL="${HERMES_SWIPL:-swipl}"
mkdir -p "$OUT"
cd "$REPO" || exit 1

SEG="$OUT/dynamic_probe.dat"
ERR="$OUT/dynamic_probe.stderr"
rm -f "$SEG" "$ERR"

echo "[dynamic_cov_probe] running one incompatibility_contexts call under cov_worker.pl"
printf '{"id":"1","op":"incompatibility_contexts","context":"all"}\n' | \
  HERMES_COV_SEGMENT="$SEG" "$SWIPL" -q -l hermes_worker.pl \
    -l scripts/bigred/total_audit/cov_worker.pl -g cov_main \
    > "$OUT/dynamic_probe.out" 2> "$ERR"

if [ ! -s "$SEG" ]; then
  echo "[dynamic_cov_probe] FAIL: no coverage segment saved ($SEG empty or missing)"
  echo "[dynamic_cov_probe] stderr tail:"
  tail -20 "$ERR" 2>/dev/null
  exit 1
fi

echo "[dynamic_cov_probe] segment saved: $SEG ($(wc -c < "$SEG" | tr -d ' ') bytes)"

# The three files under test, and the module that declares their predicates
# `:- dynamic` (which is where the load-time facts and the after-load
# discoverer/consultation traffic both land).
TARGETS=(
  "formal/incompatibility/incompatibility_sets_a_fortiori_context_closure.pl"
  "formal/incompatibility/incompatibility_sets_discovered.pl"
  "formal/incompatibility/incompatibility_sets_error_rules.pl"
  "formal/incompatibility/incompatibility_sets.pl"
)

echo "[dynamic_cov_probe] cl(...) records naming the dynamic-predicate stores:"
found=0
for t in "${TARGETS[@]}"; do
  n=$(grep -c "'$t'" "$SEG" 2>/dev/null || true)
  n=${n:-0}
  echo "  $t: $n"
  if [ "$n" -gt 0 ]; then found=1; fi
done

total_cl=$(grep -c '^cl(' "$SEG" 2>/dev/null || true)
echo "[dynamic_cov_probe] total cl(...) records in this segment: ${total_cl:-0}"

if [ "$found" -eq 1 ]; then
  echo "[dynamic_cov_probe] ANSWER: YES — a dynamic-predicate file DOES appear in coverage records."
  echo "[dynamic_cov_probe] run-2 may claim these stores; verify the specific predicate rows separately."
  exit 0
else
  echo "[dynamic_cov_probe] ANSWER: NO — no dynamic-predicate file appears in coverage records."
  echo "[dynamic_cov_probe] library(prolog_coverage) is not observed to instrument :- dynamic predicates"
  echo "[dynamic_cov_probe] here; run-2 must document this as a limitation, not claim these stores covered."
  exit 2
fi
