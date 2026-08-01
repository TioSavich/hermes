# Scene machinery — rescued from a temp scratchpad, 2026-08-01

This is the production line that made `best.html`. It ran three rounds on
2026-07-31 and then sat in
`/private/tmp/claude-501/.../eb956062-.../scratchpad/t228v2/`, outside the
repository, where a temp purge would have destroyed the only copy. The
task-233 report says so in its own words: "Everything is built under [that
path], which sits outside the repository and cannot be committed."

Rescued here at 460 KB. The 17 MB of `out/` was left behind; those artifacts
regenerate. What could not be regenerated is below.

## What each piece does

| File | Role |
|---|---|
| `SCHEMA.md` | the coordinate-free scene vocabulary: ten node types, scene / panel / eight blocks |
| `scene_schema.py` | the schema as code |
| `gate_scene.py` | validity gate; a scene either passes or is refused |
| `typeset.py` | measure-then-place typesetter. Every x and y is decided here, never by the model |
| `prompt_v3.py` | the per-item contract sent to the model |
| `build_items_v2.py` | builds one self-contained record per figure |
| `write_grounding_v2.py`, `grounding_v2.json` | the Hermes MCP rows embedded per item |
| `preflight_v2.py` | checks an item before it is sent |
| `regate_scenes.py` | re-runs the gate over produced scenes |
| `codex-arm.sh` | the codex driver |
| `codex-fixloop.sh` | the round-3 repair loop that fixed all 16 at source |
| `build_compare*.py` | the HTML and PDF assembly |
| `run_scene_pilot.py`, `selftest.py`, `job.slurm` | runner, self-test, cluster job |
| `items/items.jsonl` | the 16 pilot records |
| `reports/` | what the codex arm and the fix loop each reported |

## Why the split matters

Round 1 asked a model for SVG and got mathematics that was named correctly and
then destroyed by coordinates. The answer was not a better model. The model now
writes a scene in a vocabulary that **has no way to express a position**, and
`typeset.py` decides every coordinate. Overlap and overflow stop being failure
modes the pipeline can have.

The repo already runs this split elsewhere: `notation_scene.pl` computes and the
drawer places.

## Two edits this needs before it runs again

Tio ruled on 2026-08-01 that there is one arm and it is codex.

1. `codex-arm.sh` opens with "You are the comparison arm of a two-model
   experiment." That is now false. Rewrite the prompt as the primary and only
   pass.
2. Its retry budget is set "matching Gemma's retry budget." Gemma is not in this
   pipeline any more. Choose the budget on its own merits.

## Scale

The pilot ran 16 items. The corpus is 1,359 figures across 342 articles. See
`.superpowers/sdd/task-234-brief.md` for the three joins each item needs: the
article text (341 of 342 keys), the figure's page from the docling sidecar (334
of 341), and the Hermes rows.
