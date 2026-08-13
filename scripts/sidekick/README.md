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
| `shadow_scorer.py` | Runs the G5 read-only two-round diagnostic beside a frozen one-round transcript and cross-tabs sequential-navigation outcomes without computing floors or moving bars. |
| `train_sidekick.py` | LoRA on the text tower with the mask above. Phase 0 runs it only as the law-zero proof. |
| `run_lawzero_smoke.slurm` | That proof on `gpu-debug`: steps, checkpoint, resume, adapter confirmed as a file. |

## Display-marker culling contract

Lesson pages may add `$...$` around arithmetic expressions for MathJax. Those
delimiters belong only to the display layer. Stored curriculum rows remain
verbatim, and training conversations must not teach either Markdown or TeX
delimiters as part of ordinary lesson language.

`training_text.py:cull_display_math_markers` recursively removes paired
display markers containing a mathematical operator. `Row.messages()` applies that
cull after the conversation is assembled and before chat-template rendering,
mask construction, token counting, or training. Currency such as `$5` is not a
paired arithmetic marker and is retained. A future extractor that bypasses
`Row.messages()` must apply the same cull before writing a training artifact.

## Wave 2 dataset build

`triples.py --base <phase-1-triples>` copies the executed phase-1 bank byte for
byte and appends the wave-2 A-recognize, B-repair, and D multi-call pools. This
path avoids re-executing the phase-1 monitoring-chart pool, whose worker call
can stall, and preserves the order-dependent teacher cache keys.

`build_dataset.py` now targets A/B/C/D at 25/15/40/20 percent. Its class-C trim
is controlled separately at C3 960, C1 arithmetic 400, C1 definition 200, C4
480, and C2 360 for a 6,000-row candidate. The 77 reviewed definitions and 130
new out-of-scope subjects live in `wave2_pools.py`; definition replies are
authored there and the teacher writes only their framings. Use the offline plan
before opening the teacher channel:

```sh
export PYTHONPATH=scripts/sidekick
python3 scripts/sidekick/triples.py --base <phase-1-triples> --output <wave2-triples>
python3 scripts/sidekick/build_dataset.py --offline --plan-only \
  --triples <wave2-triples> --cache <copied-teacher-cache>
```

The plan reports the exact class census, raw class-C framing slots after the
class-C1 core check, and capacity discounted by the authored 0.65 admission
floor. Cached batches contribute the turns they actually hold; uncached batches
contribute the turns their prompts request. The report fails if any discounted
class-C bucket misses its fixed target, before a teacher channel is opened.

After the exact trim, the builder runs the dataset gates and 4,096-token
ceiling. If either check drops a row, a bounded five-round refill draws only
from unselected rows in the same seeded bucket and applies the same checks to
those additions. The final exact-census checks still refuse any short bucket.

## Wave 3 per-round build

`build_wave3_sequences.py` reads the frozen wave-2 rows and emits one training
sequence per assistant round. It requires the collected M-1 artifact to
recompute outcome (c) over call-bearing records before building. Call sequences
end with the measured token ids `[50, 1]`; reply, relay, and class-C sequences
keep the canonical turn close.

The builder checks four normalization shapes before the full pass: renderer
arguments are mappings, HTTP wire arguments are JSON strings, and normalizing
the wire objects back to mappings preserves token ids. Its mask check treats
closed historical tool-response spans separately from the terminal `[50, 1]`
state. It also reruns the 13-gram benchmark and 8-gram held-out gates, refuses
any sequence over 4,096 tokens, checks the exact 10,860-sequence census, and
re-renders the final JSONL for token accounting.

```sh
export PYTHONPATH=scripts/sidekick
python3 scripts/sidekick/build_wave3_sequences.py
```

The outputs are `datasets/sidekick-wave3-seqs.jsonl` and
`datasets/sidekick-wave3-seqs-gates.json` under the ignored sidekick runtime.

## G5 two-round shadow scorer

`shadow_scorer.py` is a separate diagnostic runner. It imports the frozen
instrument's chat transport, assistant echo, worker execution, reply scoring,
probe reader, and backend fingerprint. It does not import the threshold table
or judge and refuses command-line requests containing `floor`, `judge`, or
`threshold` options.

Each item may execute calls from the first two assistant responses. A response
without calls is the final reply and ends the item unchanged. When the second
response calls tools, the runner executes those calls and requests one final
reply. Any call emitted in that final response is recorded and left unexecuted.

Follow-up requests accumulate the full message history by default, preserving
the original G5 behavior. `--context isolated` instead constructs every
follow-up from only the system prompt, original user turn, and tool results;
the model's earlier assistant response is absent. Transcript records, the
top-level summary, and each arm summary label the selected context mode so the
same four metric columns can be compared between separate accumulating and
isolated runs over the same probe and frozen one-round transcript.

The required one-round transcript supplies item outcomes for the cross-tab:

```sh
export PYTHONPATH=scripts/sidekick
python3 scripts/sidekick/shadow_scorer.py \
  --one-round-transcript hermes/app/runtime/experiments/sidekick/floors/floors-<run>.jsonl
```

The E2 isolated-context comparison uses the same inputs:

```sh
python3 scripts/sidekick/shadow_scorer.py \
  --context isolated \
  --one-round-transcript hermes/app/runtime/experiments/sidekick/floors/floors-<run>.jsonl \
  --label wave3-isolated
```

The transcript and summary are written beside the floors files as
`shadow-<timestamp>.jsonl` and `shadow-<timestamp>.json`. Every cut reports
second-call emission, second-call executability, final relay, and final grounded
reply. The cross-tab names one-round relay misses recovered after bounded
navigation and one-round formulation hits that never execute the probe's
requested operation. These columns are diagnostic; the summary records
`bars_moved: false` and `verdict_floors_computed: false`.

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
