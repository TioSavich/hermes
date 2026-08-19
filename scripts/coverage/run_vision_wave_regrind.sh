#!/bin/bash
# Orchestrates the 2026-08-18 vision-wave regrind: rebuilds vision_wave_targets.jsonl
# from the finished vision_recovery_checkpoints.jsonl, then fans the propose_verify_driver.py
# figure_context regrind out across N parallel REALLMS shards (text-only calls; the
# recovered image content already rode into caption_context as text).
set -euo pipefail
cd /Users/tio/Documents/GitHub/hermes

GRIND=hermes/app/runtime/experiments/coverage_grind
SHARDS=8
OUTDIR=/tmp/vision_wave_shards
mkdir -p "$OUTDIR"

echo "== rebuilding vision_wave_targets.jsonl with full recovery data =="
python3 scripts/coverage/build_vision_wave_targets.py

echo "== launching $SHARDS parallel regrind shards =="
for i in $(seq 0 $((SHARDS - 1))); do
  nohup python3 scripts/coverage/propose_verify_driver.py \
    --targets "$GRIND/vision_wave_targets.jsonl" \
    --output "$OUTDIR/shard_$i.jsonl" \
    --backend reallms --max-tokens 3000 --timeout 180 \
    --shard "$i/$SHARDS" \
    > "$OUTDIR/shard_$i.log" 2>&1 &
  echo "shard $i pid $!"
done
wait
echo "== all shards finished =="
for i in $(seq 0 $((SHARDS - 1))); do
  echo "-- shard $i tail --"
  tail -3 "$OUTDIR/shard_$i.log"
done
