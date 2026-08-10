# sidekick — phase 0

Phase 0 of the sidekick program trains nothing. It measures what the untuned
`gemma-4-E2B-it` checkpoint does when Hermes is on the table, and it builds the
measurement and trace machinery the later phases need. The design it implements
is `.superpowers/sdd/task-2026-08-10-sidekick-design.md`; the phase-0 report is
`.superpowers/sdd/task-2026-08-10-sidekick-phase0-report.md`.

## What is here

| File | What it does |
|---|---|
| `chat_format.py` | Renders conversations through the checkpoint's own `chat_template.jinja` and `tokenizer.json`, checks the ten marker token ids, samples per-example menus, and counts what a menu costs. |
| `supervision.py` | Builds the loss mask and asserts its two load-bearing properties: no supervised token inside a tool-response span, and no call marker in a no-call row's own turn. |
| `contamination.py` | Builds the 13-gram index over the benchmark's three sources and the run suites, and checks a provenance record for forbidden sources. |
| `dataset.py` | The row schema, the three response classes, and the six gates a row passes before it can train. |
| `build_pilot.py` | Builds pilot rows backward from executed worker calls, in the design's four decision classes. |
| `build_probe.py` | Authors the disposition probe and executes the reference call behind each item. |
| `measure_floors.py` | Runs the probe through the untuned checkpoint in two arms, executes every call it emits, and scores disposition, formulation, refusal relay, and confabulation. |
| `train_sidekick.py` | LoRA on the text tower with the mask above. Phase 0 runs it only as the law-zero proof. |
| `run_lawzero_smoke.slurm` | That proof on `gpu-debug`: steps, checkpoint, resume, adapter confirmed as a file. |

## Running it

The renderer needs the checkpoint's template and vocabulary, which are not in
the tree. Copy `chat_template.jinja` and `tokenizer.json` from the ungated
`google/gemma-4-E2B-it` snapshot into
`hermes/app/runtime/experiments/sidekick/gemma4-e2b-assets/`, or point
`SIDEKICK_GEMMA_ASSETS` at a directory holding them. Everything the scripts
produce lands under `hermes/app/runtime/experiments/sidekick/`, which is
outside version control.

```sh
export PYTHONPATH=scripts/sidekick
python3 scripts/sidekick/contamination.py build      # once, ~4 s
python3 scripts/sidekick/build_pilot.py --rows 200   # executes every call
python3 scripts/sidekick/dataset.py hermes/app/runtime/experiments/sidekick/datasets/pilot-200.jsonl
python3 scripts/sidekick/build_probe.py
python3 scripts/sidekick/measure_floors.py           # needs Ollama serving gemma4:e2b
```

`dataset.py` exits non-zero unless all six gates are green over every row.
