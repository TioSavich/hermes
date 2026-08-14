#!/usr/bin/env bash
#SBATCH --job-name=mtb-score-arms
#SBATCH --account=r01990
#SBATCH --partition=gpu
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=48G
#SBATCH --gres=gpu:1
#SBATCH --output=work/%x_%j.out
#SBATCH --error=work/%x_%j.err

# Score already-generated MathTutorBench arms with the published reward model.
#
# Why this exists separately from the generation job: generation succeeded and
# scoring did not, so re-running generation to reach the scorer would spend an
# hour of GPU reproducing artifacts that are already on disk.
#
# The fault it works around: `transformers` 5.14.1 imports torchaudio while
# loading any Qwen2 model, through loss_rnnt. The torchaudio on this system is
# built against a different torch than the one in the user site-packages, so
# `libtorchaudio.so` fails to load and the import dies far from its cause. The
# reward model is a sequence classifier and never touches audio, so a stub
# module with a real __spec__ satisfies the import and changes no arithmetic.
# transformers checks availability with importlib.util.find_spec, which raises
# on a module whose __spec__ is None; hence the spec rather than a bare
# ModuleType.
#
# `score_official.py` is left untouched: it produced the stored floors, and a
# scorer edited to fix an unrelated environment fault stops being the same
# instrument. The stub is installed by the caller instead.

set -euo pipefail

REPO="${SIDEKICK_REPO:-/N/scratch/tmsavich/hermes}"
RUN_DIR="${MTB_RUN_DIR:?set MTB_RUN_DIR to the generation run directory}"
ARMS="${MTB_ARMS:-naked_on naked_off agent_tutor agent_mandated}"
SCORER="$REPO/hermes/app/runtime/experiments/gemma4_tutor/score_official.py"

export HF_HOME="${HF_HOME:-/N/scratch/tmsavich/.cache/huggingface}"
mkdir -p "$REPO/work"
test -r "$SCORER" || { echo "missing scorer: $SCORER" >&2; exit 1; }

module purge

for arm in $ARMS; do
  out="$RUN_DIR/$arm"
  test -s "$out"/generations-*.json || { echo "no generations for $arm; skipping" >&2; continue; }
  echo "=== scoring $arm ==="
  /usr/bin/python3.12 - "$SCORER" "$out" <<'PY'
import importlib.machinery as machinery
import runpy
import sys
import types

for name in ("torchaudio", "torchaudio.functional", "torchaudio.transforms"):
    module = types.ModuleType(name)
    module.__spec__ = machinery.ModuleSpec(name, loader=None)
    module.__version__ = "0.0.0-stub"
    sys.modules[name] = module

scorer, run_dir = sys.argv[1], sys.argv[2]
sys.argv = [scorer, "--runs", run_dir]
runpy.run_path(scorer, run_name="__main__")
PY
done

echo "MTB_SCORE_DONE $RUN_DIR"
for arm in $ARMS; do
  summary="$RUN_DIR/$arm/reward-summary.json"
  test -s "$summary" && { echo "--- $arm ---"; cat "$summary"; }
done
