#!/usr/bin/env bash
# load_probe.sh — load every tracked Prolog file individually into a fresh
# SWI-Prolog and record what happens. This EXECUTES directives, so it runs
# only inside a disposable checkout (the cluster scratch tree), never against
# the working repo on a laptop.
#
#   bash scripts/bigred/total_audit/load_probe.sh FILELIST OUT.jsonl [JOBS]
#
# Skip list (loaded files that must never be probed, each with its reason):
#   formal/learner/server*.pl        — bind ports on load
#   geometry/geometry_bridge.pl      — deliberate gate comparison point
#   knowledge/**/literature_canonical_mappings.pl — include-active; a direct
#                                      load double-declares what its includer
#                                      already owns
# Skipped files still get a JSONL record with status "skipped" and the reason,
# so the denominator never silently shrinks.
set -uo pipefail

FILELIST="${1:?usage: load_probe.sh FILELIST OUT.jsonl [JOBS]}"
OUT="${2:?usage: load_probe.sh FILELIST OUT.jsonl [JOBS]}"
JOBS="${3:-8}"
SWIPL="${HERMES_SWIPL:-swipl}"
PY="${HERMES_PYTHON:-python3}"
RECDIR="$(mktemp -d "${TMPDIR:-/tmp}/load_probe.XXXXXX")"
export SWIPL PY RECDIR

probe_one() {
  f="$1"
  rec="$RECDIR/$(echo "$f" | tr '/' '_').json"
  case "$f" in
    formal/learner/server*.pl) reason="binds ports on load" ;;
    geometry/geometry_bridge.pl) reason="gate comparison point; stays unloaded by design" ;;
    */literature_canonical_mappings.pl) reason="include-active; loaded through its includer" ;;
    *) reason="" ;;
  esac
  if [ -n "$reason" ]; then
    "$PY" -c 'import json,sys; print(json.dumps({"path":sys.argv[1],"status":"skipped","reason":sys.argv[2]}))' \
      "$f" "$reason" > "$rec"
    return 0
  fi
  errf="$RECDIR/$(echo "$f" | tr '/' '_').err"
  start=$(date +%s.%N)
  if command -v timeout >/dev/null 2>&1; then
    timeout 120 "$SWIPL" -q \
      -g "consult('paths.pl'), catch(load_files('$f',[qcompile(never)]),E,(print_message(error,E),halt(2))),halt(0)" \
      -t 'halt(3)' </dev/null >/dev/null 2>"$errf"
    code=$?
  else
    # macOS smoke path only; the cluster has coreutils timeout.
    "$SWIPL" -q \
      -g "consult('paths.pl'), catch(load_files('$f',[qcompile(never)]),E,(print_message(error,E),halt(2))),halt(0)" \
      -t 'halt(3)' </dev/null >/dev/null 2>"$errf"
    code=$?
  fi
  end=$(date +%s.%N)
  "$PY" -c '
import json, sys
path, code, start, end, errf = sys.argv[1], int(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4]), sys.argv[5]
tail = open(errf, encoding="utf-8", errors="replace").read()[-2000:]
status = {0: "ok", 2: "load_error", 3: "load_failed", 124: "timeout"}.get(code, "error")
if status == "ok" and tail.strip():
    status = "warnings"
print(json.dumps({"path": path, "status": status, "exit": code,
                  "seconds": round(end - start, 2), "stderr_tail": tail}))
' "$f" "$code" "$start" "$end" "$errf" > "$rec"
}
export -f probe_one

grep -v '^\s*$' "$FILELIST" | xargs -P "$JOBS" -I{} bash -c 'probe_one "$@"' _ {}

cat "$RECDIR"/*.json > "$OUT"
n_total=$(grep -c . "$FILELIST" || true)
n_out=$(grep -c . "$OUT" || true)
echo "load_probe: $n_out records for $n_total files -> $OUT"
[ "$n_out" -eq "$n_total" ] || { echo "load_probe: record count mismatch" >&2; exit 1; }
rm -rf "$RECDIR"
