# The prolog-assisted diagnosis arm, run for the first time

The 2026-08-01 diagnosis report ended with an arm that could not be run: no
responder could reach the item, and nothing in any benchmark had ever called
swipl. Both gaps are closed tonight. A new responder, `prolog_kb`
(`scripts/research/mtb_kb_responder.py`, commit `986ac7a`), makes two model
calls around one Prolog call: the model writes a single SWI-Prolog goal, the
goal runs through the same `prolog_query` surface the MCP tool serves — same
sandbox, same read-only guard, same knowledge scope, caps widened through the
environment and reported in every reply — and the model then names the error
category with the query and its result in front of it.

Both arms ran on Big Red on the same served checkpoint,
`gemma-4-E2B-it_Q4_K_M` under `llama-server --jinja --reasoning on`, thinking
extracted to `reasoning_content`, 4096 generation tokens, dev split, all 301
items, zero unparsed replies in either arm. The unassisted arm is job
7871500; the assisted arm is job 7871497. They are separate jobs on separate
nodes with identical serving flags; job 7871465, queued for the morning,
re-runs both arms inside one job as the run-to-run check.

## Results

Floors and tests as in the 2026-08-01 diagnosis report: the floor is the
majority-class share, and `p` is an exact McNemar test against the
constant-answer predictor on the same items.

| arm | n | accuracy | floor | lift | macro-F1 | p vs constant |
|---|---:|---:|---:|---:|---:|---:|
| unassisted | 301 | 0.2957 | 0.2890 | +0.0066 | 0.157 | 0.851 |
| prolog_kb | 301 | 0.2924 | 0.2890 | +0.0033 | 0.165 | 1.000 |

Paired head to head: 223 of 301 predictions are identical, 22 items only the
unassisted arm gets right, 21 items only the assisted arm gets right,
p = 1.000. **Three nulls: neither arm clears its floor, and the arms do not
differ.** The laptop route had already measured the unassisted checkpoint at
0.3023 on this split through Ollama; two serving routes now agree that the
deployable checkpoint diagnoses at its floor, and tonight adds that one
caller-formed Prolog consultation per item does not move it.

Per category, correct counts (base → assisted): Misunderstanding of a
question 74 → 71, Extra or missing quantity 3 → 5, Calculation error 3 → 4,
Reached correct solution but proceeded further 1 → 3, Missing or wrong
factual knowledge 4 → 1, None of the above 3 → 3, Unit conversion 1 → 1.
Every movement is within noise at these counts.

## What the model asked, when it could ask anything

The trace (`kb_trace.jsonl` beside each run) records every goal, status, and
binding count. Across 327 formed goals on 301 items:

- **Every goal was an arithmetic check.** Offered two forms — an arithmetic
  verification and a keyword probe over 3,346 documented misconception rows
  (`misconception_mentions/2`, new in `knowledge/misconceptions/
  query_probes.pl`) — the model chose the corpus probe zero times. The
  capacity-without-disposition pattern reported for tool calling reappears
  one level up: given a door and a keyhole, it walks to the same keyhole
  every time.
- Statuses: 281 `ok`, 29 `execution_error`, 16 `parse_error`, 1 item formed
  no goal at all. 26 items used the one retry, which feeds the refusal text
  back; the retry repaired goals like `compute R is (60+40-60)/4, R =:= 10`
  into parseable ones.
- The failures have a shape worth keeping: lowercase letters used as
  variables (`x =:= 5` is an atom and a type error), comparisons against
  unbound variables (`20 =:= S`), prose prefixed to the goal. Every one
  returned as a named status, never as an answer.
- The mechanism works when the arithmetic is actually wrong: in the pilot,
  `135 =:= 90` failing steered the model to name a calculation error. But
  most items in this corpus fail by misreading the question, not by
  miscomputing, so a correct arithmetic check returns `ok, 1 solution` and
  tells the model nothing that separates the seven categories.

## What this does not license

- No claim that Prolog assistance is useless here. The 31B checkpoint earns
  +0.104 over this floor unassisted; whether consultation moves *that* model
  was not measured tonight. What was measured is that the E2B checkpoint
  cannot diagnose at floor-clearing level with or without one arithmetic
  check per item.
- No claim about the misconception corpus as an assist, because the model
  never consulted it. An arm that forces or prompts the keyword probe would
  measure that; tonight's arm measured the model's own choice.
- The two arms ran in different jobs. Serving flags are identical and both
  summaries carry the model id, but the same-job pair (7871465) is the
  cleaner artifact and lands in the morning.
- n=40 rehearsal numbers (jobs 7871496) exist in the collected artifacts and
  are parser-audit evidence only: all routes `exact`, zero unparsed, at a
  40-item floor that belongs to a different category than the corpus floor.

## Provenance

Artifacts: `.bigred-collected/2026-08-01-diagnosis-prolog/` locally
(gitignored; per-item jsonl, summaries, kb traces for jobs 7871496, 7871497,
7871500), and `runs/` under the gemma4_tutor experiment tree on Big Red
scratch. Serving and both benchmark invocations:
`hermes/app/runtime/experiments/gemma4_tutor/run_diagnosis_prolog.slurm`
(gitignored runtime; arms and limits parameterized by environment). The
responder, the query server, the corpus probe, and the environment-widened
caps are commit `986ac7a`.
