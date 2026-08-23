#!/usr/bin/env bash
# launch.sh — stage and submit the total audit run, from the laptop.
#
# Order of operations (each gate must pass before the next runs):
#   1. channel check          — the ControlMaster window is open
#   2. file list              — git is the only denominator; generated here
#   3. coherent sync          — delta-rsync the tree (never mid-edit)
#   4. law zero               — imports, one item of every lane, and the
#                               SIGTERM coverage-save check, on the login node
#   5. submit                 — Stage A; Stage B with afterok dependency
#
# Usage: bash scripts/bigred/total_audit/launch.sh
set -euo pipefail

LOCAL_REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
SSHCFG=/Users/tio/Desktop/BigRed-Local/bigred.sshconfig
REMOTE_REPO=/N/scratch/tmsavich/hermes
RUN=$REMOTE_REPO/.bigred-output/2026-08-22-total-audit-run3
ENVBIN=/N/u/tmsavich/BigRed200/.conda/envs/umedcta/bin

say() { echo "[launch] $*"; }

# 1. channel
ssh -F "$SSHCFG" -o BatchMode=yes -o ConnectTimeout=10 bigred 'echo channel-ok' \
  || { echo "channel closed: run  ! bash ~/Desktop/BigRed-Local/connect.sh" >&2; exit 1; }

# 2. file list (local git is the denominator)
cd "$LOCAL_REPO"
if [ -n "$(git status --porcelain)" ]; then
  say "WARNING: working tree is not clean; the run will test the synced bytes,"
  say "which will not correspond to any commit."
fi
STAGE="$(mktemp -d)"
git ls-files '*.pl' > "$STAGE/filelist_pl.txt"
say "$(wc -l < "$STAGE/filelist_pl.txt" | tr -d ' ') tracked .pl files"

# 3. coherent sync
say "rsync tree -> $REMOTE_REPO"
rsync -az --delete -e "ssh -F $SSHCFG" \
  --exclude .git --exclude node_modules --exclude .venv \
  --exclude .superpowers --exclude .env --exclude .bigred-output \
  --exclude .bigred-collected --exclude .bigred-staging \
  --exclude '__pycache__' --exclude .claude \
  "$LOCAL_REPO/" bigred:"$REMOTE_REPO/"
ssh -F "$SSHCFG" -o BatchMode=yes bigred "mkdir -p $RUN"
rsync -az -e "ssh -F $SSHCFG" "$STAGE/filelist_pl.txt" bigred:"$RUN/filelist_pl.txt"
rm -rf "$STAGE"

# 4. law zero, on the login node, each probe light and artifact-checked
say "law zero: prolog_coverage present"
ssh -F "$SSHCFG" -o BatchMode=yes bigred \
  "$ENVBIN/swipl -q -g 'use_module(library(prolog_coverage)), writeln(cov_ok), halt(0)' -t 'halt(1)'" \
  | grep -q cov_ok

say "law zero: parse census on three files"
ssh -F "$SSHCFG" -o BatchMode=yes bigred "cd $REMOTE_REPO && head -3 $RUN/filelist_pl.txt > $RUN/lz_list.txt && $ENVBIN/swipl -q -g main scripts/bigred/total_audit/parse_census.pl -- $RUN/lz_list.txt $RUN/lz_census.jsonl && [ -s $RUN/lz_census.jsonl ] && echo census-ok"

say "law zero: one coverage segment via clean EOF"
ssh -F "$SSHCFG" -o BatchMode=yes bigred "cd $REMOTE_REPO && printf '{\"id\":\"1\",\"op\":\"health\"}\n' | HERMES_COV_SEGMENT=$RUN/lz_eof.dat $ENVBIN/swipl -q -l hermes_worker.pl -l scripts/bigred/total_audit/cov_worker.pl -g cov_main > /dev/null 2> $RUN/lz_eof.stderr; [ -s $RUN/lz_eof.dat ] && echo eof-save-ok"

say "law zero: coverage segment survives SIGTERM"
ssh -F "$SSHCFG" -o BatchMode=yes bigred "cd $REMOTE_REPO && rm -f $RUN/lz_term.dat && (mkfifo $RUN/lz_fifo 2>/dev/null || true) && (HERMES_COV_SEGMENT=$RUN/lz_term.dat $ENVBIN/swipl -q -l hermes_worker.pl -l scripts/bigred/total_audit/cov_worker.pl -g cov_main < $RUN/lz_fifo > $RUN/lz_term.out 2>&1 & echo \$! > $RUN/lz_pid) && exec 9> $RUN/lz_fifo && printf '{\"id\":\"1\",\"op\":\"health\"}\n' >&9 && for i in \$(seq 1 60); do [ -s $RUN/lz_term.out ] && break; sleep 5; done && kill -TERM \$(cat $RUN/lz_pid) && sleep 15 && exec 9>&- ; rm -f $RUN/lz_fifo; [ -s $RUN/lz_term.dat ] && echo term-save-ok || echo TERM-SAVE-MISSING"

say "law zero: server boots under the audit hook"
ssh -F "$SSHCFG" -o BatchMode=yes bigred "cd $REMOTE_REPO && rm -f $RUN/lz_opens.jsonl && HERMES_AUDIT_OPENS=$RUN/lz_opens.jsonl HERMES_SWIPL=$ENVBIN/swipl PYTHONPATH=$REMOTE_REPO nohup $ENVBIN/python3 -u scripts/bigred/total_audit/audit_boot.py --host 127.0.0.1 --port 8809 > $RUN/lz_server.log 2>&1 & echo \$! > $RUN/lz_srv_pid; for i in \$(seq 1 60); do curl -sf http://127.0.0.1:8809/ > /dev/null && break; sleep 2; done; curl -sf http://127.0.0.1:8809/ > /dev/null && echo boot-ok; for i in \$(seq 1 10); do [ -s $RUN/lz_opens.jsonl ] && break; sleep 3; done; [ -s $RUN/lz_opens.jsonl ] && echo opens-ok; kill -TERM \$(cat $RUN/lz_srv_pid) 2>/dev/null || true; sleep 1; kill -KILL \$(cat $RUN/lz_srv_pid) 2>/dev/null || true; [ -s $RUN/lz_opens.jsonl ]"

# 5. submit
say "submitting Stage A"
A=$(ssh -F "$SSHCFG" -o BatchMode=yes bigred \
  "cd $REMOTE_REPO && sbatch --parsable scripts/bigred/total_audit/audit_stageA.sbatch")
say "Stage A job: $A"
B=$(ssh -F "$SSHCFG" -o BatchMode=yes bigred \
  "cd $REMOTE_REPO && sbatch --parsable --dependency=afterok:$A scripts/bigred/total_audit/judge_stageB.sbatch")
say "Stage B job: $B (afterok:$A)"
say "watch:  ssh -F $SSHCFG bigred 'sacct -j $A,$B --format=JobID,State,Elapsed --noheader'"
say "collect when done:  bash scripts/bigred/total_audit/collect.sh"
