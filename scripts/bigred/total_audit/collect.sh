#!/usr/bin/env bash
# collect.sh — bring the run's artifacts home and verify before believing.
set -euo pipefail

LOCAL_REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
SSHCFG=/Users/tio/Desktop/BigRed-Local/bigred.sshconfig
RUN=/N/scratch/tmsavich/hermes/.bigred-output/2026-08-19-total-audit
DEST="$LOCAL_REPO/.bigred-collected/2026-08-19-total-audit"

mkdir -p "$DEST"
rsync -az -e "ssh -F $SSHCFG" bigred:"$RUN/" "$DEST/"

echo "[collect] artifacts:"
ls -la "$DEST" | sed -n '2,40p'
for f in pl_census.jsonl load_probe.jsonl sweep_results.jsonl \
         http_results.jsonl audit_ledger.json; do
  if [ -s "$DEST/$f" ]; then
    echo "[collect] $f: $(grep -c . "$DEST/$f" 2>/dev/null || echo '?') lines"
  else
    echo "[collect] MISSING OR EMPTY: $f"
  fi
done
if [ -s "$DEST/audit_ledger.md" ]; then
  echo; echo "===== audit_ledger.md (head) ====="
  head -40 "$DEST/audit_ledger.md"
fi
