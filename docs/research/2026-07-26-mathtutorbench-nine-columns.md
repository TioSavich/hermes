# MathTutorBench, nine columns: what a laptop-scale checkpoint reaches, and what the symbolic core adds

Measured 2026-07-26. Model `gemma4:e2b` through Ollama on one laptop, beside
SWI-Prolog 9.2.9. Every number below comes from the benchmark's own task
objects — its configs, its response parsers, its metric functions — through
`scripts/research/mtb_official_runner.py`.

The checkpoint should be named accurately, because the headline depends on
it. Ollama reports **5.1B parameters** at Q4_K_M, 7.2 GB on disk. `E2B` is an
*effective* 2B budget in the Gemma-3n sense, not a dense 2B network, and the
checkpoint reasons before answering. "Runs on a teacher's laptop" is the
supportable claim; "a 2B model" is not.

## What was wrong before any of this could be measured

The benchmark ships nine task configs, a registry, parsers and metrics. None
of it had ever been run here; one bespoke driver had covered
`scaffolding_generation` and nothing else. Running it exposed two protocol
problems that governed every number.

**The checkpoint reasons before it answers, and the stop lists kill it
mid-thought.** MathTutorBench's configs carry stop sequences meant to keep a
completion model from running on into the next few-shot example —
`["Problem:", "Q:"]` for `mistake_location`. Ollama hands those to the
sampler. This checkpoint restates the prompt's own words while reasoning,
trips its own stop within roughly two dozen tokens, and returns the empty
string, which the benchmark then parses as an answer.

| stop enforcement | empty rate | f1_micro |
|---|---:|---:|
| decode-time, the naive run | **0.900** *(unreproducible)* | 0.475 *(unreproducible)* |
| applied to the reply afterwards | 0.000 *(recomputable)* | **0.575** |

**Audited 2026-08-01.** Only 0.575 has an artifact
(`runs/mtb-unassisted-40/summary-mistake_location.json`). No file on disk holds
0.475 or any empty-rate field; the 0.900 survives only as prose in a docstring at
`mtb_responders.py:58`. The 0.000 is recomputable from
`runs/mtb-unassisted-40/mistake_location.jsonl` but was never recorded. Worse,
that run's `stop_mode` is recorded nowhere and the code default is `decode`, so
the row cannot prove its own label. This table should not be quoted until the
ablation is re-run with both arms written to disk.

Every published model answers immediately, so those stops were harmless for
them. A stop sequence is a decoding convenience whose intent is to bound the
answer; applying it to the reply reproduces that intent for a checkpoint that
reasons first. Both modes are available in `mtb_responders.ollama_complete`
and both are reported. The naive one is what a careless run gives, and saying
so is part of the result.

**`raw=true` is not the faithful analogue of a vllm completion run.** It
scores 0.050 on `problem_solving` against 0.875 templated, because without a
chat template the checkpoint continues text instead of answering. This was a
guess worth testing and it was wrong.

**Audited 2026-08-01: unreproducible.** No artifact holds a `problem_solving`
accuracy of 0.050, and `mtb_responders.py` has no `raw` mode. The comparison has
no code path in the current tree.

## The floors that any number here has to be read against

The two assessment columns are balanced by construction, so a constant answer
scores well. Over the full 2004 items:

- `mistake_location`, always answering 0: **f1_micro 0.500**, macro 0.067,
  weighted 0.333.
- `solution_correctness`, always answering Yes: **f1 0.667**, accuracy 0.500.

The constant answer beats the 0.37 published under the label `GPT-4o` on
`mistake_location` and sits just under LearnLM's 0.57. Most of that column is
models failing to abstain. LLaMA3.2-3B's published 0.67 on
`solution_correctness` is exactly the always-Yes f1. No number from either
column should appear without its floor.

Two corrections from 2026-08-01. The row the benchmark labels `GPT-4o` is
`gpt-4o-mini-2024-07-18` by its own Appendix B.1; repeating the label repeats
the benchmark's error. And the leaderboard now carries fourteen rows, not eight,
on which **nine of fourteen** sit at or below the `mistake_location` floor. The
full re-scoring lives in
`docs/research/2026-08-01-mathtutorbench-heldout-with-floors.md`.

**Settled 2026-08-01: the column is micro-F1.** The paper's Table 2 metric row
(arXiv 2502.18940, and the EMNLP camera-ready) reads `accuracy | bleu | F1 |
micro F1 | accuracy | win rate ...`, and the current leaderboard carries a metric
legend the vendored snapshot lacks: "Mistake Location: micro-F1". Because every
item carries one label, sklearn's micro-F1 equals accuracy here. All three
averagings are recorded; comparisons use micro. Macro must never be set beside a
published value, and its floor is 0.081, not 0.500.

## The four assessment columns

40 dev items, matched — the same items, the same parsers, the same metrics,
differing only in the responder. Published column bests are from the
benchmark's own leaderboard, vendored at `vendor/index.html`.

The assisted arm was run **twice** under identical recorded configuration
(`runs/mtb-assisted-40/` and `runs/mtb-assisted-40b/`; same responder, model,
split, limit, and seed). Both runs are reported. An earlier version of this
document reported run A alone, which inverted one of the two headline
comparisons.

Published column bests below are from the leaderboard as it stood on 2026-07-26.
The board has since grown from eight rows to fourteen and several of these
"bests" are no longer the best; see the 2026-08-01 document for the current
table.

| Task | trivial | published best | unassisted | assisted A | assisted B |
|---|---:|---:|---:|---:|---:|
| problem_solving | — | 0.94 LearnLM | 0.925 | 0.875 | 0.900 |
| solution_correctness (acc) | 0.500 | 0.75 LearnLM | 0.900 | 0.875 | 0.875 |
| solution_correctness (f1) | 0.667 | 0.75 LearnLM | 0.875 | 0.872 | 0.872 |
| mistake_location (f1_micro) | 0.500 | 0.57 LearnLM | 0.575 | 0.625 | 0.600 |
| mistake_correction | — | 0.84 gpt-4o-mini | 0.600 | 0.625 | 0.550 |

n=40. **The assisted arm does not replicate.** On `mistake_correction` the two
runs of the same configuration differ by 0.075, which is three times the 0.025
that run A stood above the unassisted arm, and run B sits 0.050 *below* it. The
sign of that comparison is set by which run gets reported. On
`mistake_location` the A-over-unassisted gap of 0.050 halves to 0.025 in run B.
`solution_correctness` is identical across both runs. Nothing here establishes
an assisted effect in either direction, and the run-to-run spread is the size of
the effect being looked for.

The unassisted checkpoint sits at or above the published best of the day on two
of the four columns and within 0.015 on a third. Two limits govern reading that.
The checkpoint is 5.1B at Q4_K_M, not "a 2B model" (see the opening section).
And these dev-40 numbers cannot be ranked against the leaderboard at all: that
board evaluates with reasoning disabled, and this checkpoint reasons. The
protocol audit is in
`docs/research/2026-08-01-mathtutorbench-heldout-with-floors.md`.

## Is the core under-covered, or badly interfaced, or aimed elsewhere?

Asked directly, and measured three ways over 200 items in each half.

**Coverage is not the problem.** Prolog adjudicates **99%** of every equation
the reader hands it — 471 of 478 from incorrect student solutions, 462 of 466
from reference solutions. *(Audited 2026-08-01: these three counts are
unreproducible. `mtb_prolog_responder.py` prints them to stderr as
`MTB_PROLOG_STATS` and no run captured a log. The claim below about the
`arithmetic_equation` clause is checkable from source and stands.)* The `arithmetic_equation` clause routes through SWI
`=:=`, so any ground arithmetic is in scope. Probed directly, it returns
`holds` for `7*10+5*25 = 195`, `200+200/2 = 200+100`, and `2*3-1 = 5`. More
claim families would change nothing.

**The interface had one real defect, and it was the costly kind.**
`_render_expression` folded a chain left to right and bracketed each step.
That is correct for one precedence — `24-1-3` — and wrong the moment two
appear: `7*10+5*25` became `((7 * 10) + 5) * 25` and a true line was refuted.
Two truncations did the same from the other side, reading `3 - 1= 5` out of
`2 students * 3 - 1= 5` and `1/2 = 237` out of `158 * 1 1/2 = 237`. Each of
those tells a student their sound arithmetic is broken, which is the worst
thing this component can do. Precedence now belongs to Prolog and the reader
abstains when an operand has been cut off. Refutations in reference solutions
fell from 8 to 3 of about 465, 1.7% to 0.6%, with extraction unchanged.

**What remains is aimed elsewhere.** After the fix, inside solutions labelled
incorrect, 4.0% of adjudicated equations are refuted against that 0.6% floor
of genuine dataset typos — about 3.4% of real signal. Roughly half of student
steps assert a derived quantity without showing any computation, so there is
nothing for an equation checker to read there at all, and that is exactly
where the modelling errors live. `45/(5+3) = 5.625` is exact and
pedagogically wrong because 45 counts only the red candles. Reaching that
needs a representation of the problem's quantity structure, not a wider
arithmetic vocabulary.

## What the symbolic core actually did

This is the part that matters for the architecture, and it is a negative.

`check_solution_steps` ran on every item of every assisted arm. Per 40 items
it adjudicated 46 to 68 equations. It refuted **0, 1, 2, and 0** of them
across the four arms. On `problem_solving` — 68 equations checked across 40
solutions, including every wrong one — it refuted nothing.

The reason is measurable and is not a defect in the checker. Across 123
recorded solutions this checkpoint made no arithmetic error worth catching:
its wrong answers come from mis-modelling the question, not from miscomputing
it. The same holds of the students in the data. Of stepverify's 1002 flagged
first-wrong steps, only **2.5%** have arithmetic that is actually wrong;
**69.6%** compute correctly and are wrong about what the question asked;
27.9% carry no checkable equation. The error categories say the same thing —
misunderstanding the question 28.6%, extra or missing quantity 24.0%, wrong
factual knowledge 14.0%.

*(Audited 2026-08-01: unreproducible. The 1002 and the 28.6% are asserted in a
docstring at `scripts/research/diagnosis_benchmark.py:7,15`; the 2.5 / 69.6 /
27.9 and the 24.0 / 14.0 appear nowhere but this document. The argument they
support is also carried by the refutation counts below, which are backed.)*

So an arithmetic verifier, however exact, has almost nothing to adjudicate
here. The claim that a Prolog core raises accuracy on this benchmark is not
supported. What small gain the assisted arm shows on `mistake_location` and
`mistake_correction` comes from the architecture around the checker — solve
the problem independently, compare final answers, and only then look for a
divergent step — not from the checker firing.

A crude rule confirms the shape of the problem from the other side. Given the
reference solution as an oracle, "the first step asserting a quantity absent
from the problem and the correct chain" matches the labelled first-wrong step
on only 42.0% of items. Locating a modelling error is not a lookup.
*(Audited 2026-08-01: unreproducible. No script in the tree implements this rule
and no artifact holds 42.0%.)*

## Where the assessment tasks actually reduce to

Every one of stepverify's 1002 incorrect solutions ends on a final answer that
differs from the reference, and the no-error half of the task is built from
the reference solution itself. So `solution_correctness` reduces exactly to
solving the problem and comparing final answers, and a perfect solver would
score 1.000.

That is worth naming as a limit of the benchmark rather than a result. The
task as constructed never asks whether a *correct but different* route is
sound, which is the judgement a tutor actually makes.

## The four generation columns, where the headroom is

Reward-model win rate over the human teacher's turn, which is the published
metric; the question-mark rate the shipped `compute_metrics` returns is not it.
40 dev items, unassisted:

| column | unassisted | published best (2026-07-26 board) |
|---|---:|---:|
| scaffolding_generation | 0.325 | 0.64 |
| scaffolding_generation_hard | 0.325 | 0.66 LearnLM |
| pedagogy_following | 0.350 | 0.82 gpt-4o-mini |
| pedagogy_following_hard | 0.500 | 0.70 gpt-4o-mini |

These four unassisted values are backed by
`runs/mtb-gen-40/reward-summary.json` and are the reward-model win rate, not the
shipped `match` heuristic. The published bests are as of 2026-07-26 and have
since moved; `claude-sonnet-4.6` now leads `pedagogy_following` at 0.85 and
`pedagogy_following_hard` at 0.80.

The mirror image of the assessment columns. There the checkpoint needed no
help; here it is far below the board.

Four arms on the same 20 scaffolding dev items, scored together in one
reward-model process:

| arm | win rate | calls/item | tool calls | artifact |
|---|---:|---:|---:|---|
| unassisted | 0.45 | 1.0 | — | recomputable, not recorded |
| `tutor_ledger`, evidence injected | **0.70** | 2.1 | n/a | **none** |
| `agent_tutor`, tools offered | 0.65 | 1.6 | **0** | **none** |
| `agent_tutor_mandated`, tools required | 0.50 | 2.2 | 9 | `runs/mtb-mandated-20/` |

n=20 and the intervals overlap heavily; none of these differences is
established.

**Audited 2026-08-01.** Two of the four win rates have no artifact anywhere.
`runs/mtb-tutor-40/` holds a single 27-row `.jsonl` and no score of any kind, so
`tutor_ledger`'s 0.70 is unreproducible; no `agent_tutor` run directory exists at
all, so 0.65 is unreproducible. The mandated 0.50 is exact
(`runs/mtb-mandated-20/reward-summary.json`, wilson 0.299–0.701). The unassisted
0.45 is recomputable as 9 of 20 from the first twenty records of
`runs/mtb-gen-40/reward-scaffolding_generation.json`, which carry the same source
indexes in the same order, confirming the "same 20 items" claim. **Every entry in
the calls/item and tool-call columns is unreproducible**: those counters print to
stderr and only `mtb-assisted-40` captured a log, so the sentence below overstates
what survives. The four-arm table must not be quoted until the two missing arms
are re-run to disk.

## Capacity without disposition

The checkpoint emits well-formed tool calls. Asked to check `5+3=9` with a
function available, it calls the function and does not answer from memory.

It nevertheless never asked. Six items, functions identical, wording varied:

| framing | items calling a tool |
|---|---|
| plain tutoring prompt | 0/6 |
| "two tools are available … use them when they would help" | 0/6 |
| "before replying, check … do not rely on memory" | 6/6 |

Telling it the tools exist and are useful changes nothing. It uses a function
when told to and never decides that it needs one.

Requiring the consultation produced calls and cost 0.15 of win rate. The
reason is not missing data. Asked in mathematical terms the lookup answers —
division 2 clusters, fractions 14, measurement 6, area 6, place value 3,
subtraction 4, **13 of 15 topics matched**. Asked as the model asked it,
nothing: it sent the story back — `ignatius friend different`, `located beside
river`, `drought household gallons` — and **0 of 12 matched**. The lookup
abstained correctly every time.

The checkpoint reads the narrative and not the mathematics, and a lookup keyed
to mathematics receives a story. So injection beat asking here, not because
being asked is worse in principle but because this checkpoint cannot form the
query. Deriving the topic from the operations already adjudicated would serve
the same rows without the model guessing — which is injection again, aimed
better, and should be described that way rather than as an agent.

## Measured since

All numbers in this document are dev-split, n=40, frozen by seed 20260726 at 30%
dev. **The held-out split has since been run at n=300 on all nine columns**
(Slurm job `mtb-7792778`, `runs/bigred-heldout-300/`). Those results, each column
against a floor recomputed on its own items, are in
`docs/research/2026-08-01-mathtutorbench-heldout-with-floors.md`. That document
also records the protocol audit which establishes that neither the dev nor the
held-out arm can be ranked against the leaderboard: the board evaluates with
reasoning disabled, and on `mistake_location` this checkpoint decoded a median of
894 tokens per item while the benchmark's parser received one character.

The earlier bespoke driver's 0.783 on 360 scaffolding items is **backed**
(`runs/fleet_report.json`, arm `iterative`, 282 wins of 360, wilson 0.738–0.823),
with an unassisted baseline of 0.458 at the same n. It was produced under a
different driver and a different reward-scoring invocation than the numbers above,
so it is not set beside them.

`socratic_questioning` is scored by sacrebleu against reference questions and has
a low ceiling for everyone on the board (0.23 to 0.48). A single constant question
reaches 0.13 of it.
