#!/bin/bash
# Build the Big Red transfer tarball. Non-interactive by design: run it,
# get one file and the three commands that move it. No heredocs, no
# environment variables required, no shell left open.
#
# Usage: bash scripts/bigred/package.sh [output-directory]
# Default output directory: the owner's Desktop.
set -euo pipefail

cd "$(cd "$(dirname "$0")/../.." && pwd)"
OUT_DIR="${1:-$HOME/Desktop}"
STAMP="$(date +%Y%m%d-%H%M)"
TARBALL="$OUT_DIR/hermes-bigred-$STAMP.tar.gz"

# COPYFILE_DISABLE keeps macOS AppleDouble (._*) files out of the archive.
# .env stays home: credentials never travel to a shared cluster.
COPYFILE_DISABLE=1 tar -czf "$TARBALL" \
  --exclude='./.git' \
  --exclude='./node_modules' \
  --exclude='./.venv' \
  --exclude='./.superpowers' \
  --exclude='./.env' \
  --exclude='./.bigred-output' \
  --exclude='./hermes/app/web/generated' \
  --exclude='./scripts/research/talkmoves_rerun_out' \
  --exclude='./scripts/research/churn_out' \
  --exclude='__pycache__' \
  .

COUNT="$(tar -tzf "$TARBALL" | wc -l | tr -d ' ')"
SIZE="$(du -h "$TARBALL" | cut -f1)"
echo "built: $TARBALL ($SIZE, $COUNT entries; archive lists and reads back cleanly)"
echo ""
echo "Next steps (fill OWNER):"
echo "  scp '$TARBALL' OWNER@bigred200.uits.iu.edu:/N/scratch/OWNER/"
echo "  ssh OWNER@bigred200.uits.iu.edu 'mkdir -p /N/scratch/OWNER/hermes && tar -xzf /N/scratch/OWNER/$(basename "$TARBALL") -C /N/scratch/OWNER/hermes'"
echo "  # then fill ACCOUNT/EMAIL in scripts/bigred/deformation_gallery/job.slurm and sbatch it"
