# MathTutorBench: what its assessment columns measure, and a held-out run read against their floors

Two things are reported here. The first is a property of the benchmark: on both
of its balanced assessment columns, most published entries score at or below what
an answerer that ignores its input reaches. That holds without reference to
anything this project built. The second is a held-out run of an unassisted
quantized checkpoint, which finished on 2026-07-26 (Slurm job `mtb-7792778`) and
which no document reported until now. It is reported against its own floors only.
It is **not** comparable to the leaderboard, for a reason established below.

## The floors

A floor here is the score reached by an answerer with no sensitivity to its input.

StepVerify holds 1002 rows, and both classification tasks generate two items per
row, one carrying an error and one carrying none. Over the resulting 2004 items
the floors are exact rather than estimated:

- `mistake_location`, always answering 0: micro-F1 exactly **1002/2004 = 0.500**.
- `solution_correctness`, always answering Yes: f1 exactly **2/3 = 0.667**
  (precision 0.5, recall 1.0), accuracy 0.500.

Metric identity had to be established from outside the vendored copy, because the
shipped `compute_metrics` returns three averagings for `mistake_location` and the
vendored page names none. Both the paper's Table 2 metric row (arXiv 2502.18940,
identically in the EMNLP camera-ready) and the current leaderboard's legend give
`micro-F1`. The legend reads: "Problem Solving: accuracy · Socratic Questioning:
BLEU · Solution Correctness: F1 · Mistake Location: micro-F1 · Mistake Correction:
accuracy · remaining columns: reward-model win rate."

This matters more than it looks. Had the column been macro-F1, the constant-zero
floor would be 0.067, no published entry would sit below it, and everything in the
next section would evaporate. The shipped code does not carry the fact that
decides it.

Because every item carries exactly one label, sklearn's micro-F1 equals accuracy
here. The column is exact-step-match accuracy under another name.

## The published table against those floors

Fourteen rows, read from the `MODELS` array of the live leaderboard
(`eth-lre/mathtutorbench`, `index.html`). The vendored snapshot at
`vendor/index.html` carries only the paper's original eight and has no metric
legend; it is stale and should not be used for this comparison. Cells at or below
their column's floor are marked `[floor]`.

| Model | Prob.Solv. | Socratic | Sol.Corr. | Mist.Loc. | Mist.Corr. |
|---|---:|---:|---:|---:|---:|
| LLaMA3.2-3B-Instruct | 0.60 | 0.29 | 0.67 `[floor]` | 0.41 `[floor]` | 0.13 |
| LLaMA3.1-8B-Instruct | 0.70 | 0.29 | 0.63 `[floor]` | 0.29 `[floor]` | 0.09 |
| LLaMA3.1-70B-Instruct | 0.91 | 0.29 | 0.71 | 0.56 | 0.19 |
| "GPT-4o" (actually gpt-4o-mini) | 0.90 | 0.48 | 0.67 `[floor]` | 0.37 `[floor]` | 0.84 |
| LearnLM-1.5-Pro | 0.94 | 0.32 | 0.75 | 0.57 | 0.74 |
| Llemma-7B-ScienceTutor | 0.62 | 0.29 | 0.66 `[floor]` | 0.29 `[floor]` | 0.16 |
| Qwen2.5-7B-SocraticLM | 0.73 | 0.32 | 0.05 `[floor]` | 0.39 `[floor]` | 0.23 |
| Qwen2.5-Math-7B-Instruct | 0.88 | 0.35 | 0.43 `[floor]` | 0.47 `[floor]` | 0.49 |
| apertus-ai/Apertus-v1.5-8B | 0.76 | 0.27 | 0.35 `[floor]` | 0.46 `[floor]` | 0.07 |
| zai-org/GLM-4.7-Flash | 0.78 | 0.29 | 0.59 `[floor]` | 0.41 `[floor]` | 0.09 |
| Qwen/Qwen3.6-27B | 0.97 | 0.28 | 0.80 | 0.71 | 0.89 |
| google/gemini-2.5-pro | 0.88 | 0.30 | 0.86 | 0.72 | 0.59 |
| eth-nlped/TutorRL-7B | 0.77 | 0.23 | 0.65 `[floor]` | 0.36 `[floor]` | 0.75 |
| anthropic/claude-sonnet-4.6 | 0.91 | 0.32 | 0.80 | 0.55 | 0.79 |
| **floor** | none | 0.13 | **0.667** | **0.500** | none |

**On `mistake_location`, nine of the fourteen published entries score at or below
0.500**, the score of a system that answers "0" to every item without reading it.
The row the benchmark labels `GPT-4o` is among them at 0.37. Five entries clear
the floor: LLaMA3.1-70B at 0.56, LearnLM-1.5-Pro at 0.57, claude-sonnet-4.6 at
0.55, Qwen3.6-27B at 0.71, gemini-2.5-pro at 0.72.

**On `solution_correctness`, seven of the fourteen fall strictly below f1 0.667**,
and two more sit at 0.67, which is the floor at the precision the board displays.
The same five models clear both columns.

Scale matters not at all to this. A 70B model and a 3B model both sit under the
floor on `mistake_location`; so does a frontier closed model. What separates the
five that clear it is not size.

That is the finding, and it stands whether or not any run of ours exists.

## Why `solution_correctness` has the floor it has

This is worth naming on its own, because nothing on the leaderboard or in the
paper records it.

The legend says "F1". The code computes binary F1 with `pos_label=True`
(`tasks/solution_correctness.py:91`), and `True` means *the solution is
incorrect*. The two constant answerers are therefore not symmetric: always-Yes
reaches f1 0.667 on a balanced set, and always-No reaches f1 **0.000**. The
column's floor is not a property of the data alone but of which way a degenerate
model happens to fail.

`parse_response` then leans one way:

```python
if "yes" in response:   return True
elif "no" in response:  return False
else:                   return True   # "Default to marking as incorrect"
```

An unparseable reply, an empty string, a refusal, or a reply whose formatting the
matcher misses is all scored as a confident "this solution is incorrect", which is
the positive class. Parse failure therefore pushes a model *toward* the 0.667
floor rather than toward zero. A model that emits nothing usable scores 0.667; a
model that reliably answers "No" scores 0.000. Qwen2.5-7B-SocraticLM's 0.05 is
what the second failure mode looks like on the board.

Reading this column as a capability measure requires knowing which of those a
given row is, and no published artifact records it.

## The held-out run, and why it cannot be ranked

| | |
|---|---|
| model | `gemma-4-E2B-it_Q4_K_M.gguf` (5.1B at Q4_K_M, 7.2 GB) |
| serving | `llama-server --jinja --reasoning on`, chat-completions route |
| host | Big Red 200, one GPU. **Not a laptop.** |
| responder | `unassisted`. No Prolog, no Hermes, no tools. |
| decoding | temperature 0, `max_tokens` 2048 |
| stop lists | applied to the reply, not at decode time |
| split | seed 20260726, 30% dev, first 300 held-out indexes |
| task objects | the benchmark's own configs, parsers, and `compute_metrics` |

All nine summary files reproduce exactly from their own per-item `.jsonl`,
including the sacrebleu mean and the GSM8K float comparison. Responder errors are
0 on every column.

### The run reasoned. The board did not.

The leaderboard states: "All models are evaluated with thinking/reasoning
**disabled** (`is_thinking` option). The only exception is `google/gemini-2.5-pro`,
which uses its default adaptive thinking."

This run set `SET_REASONING=on` (`scripts/bigred/run_mathtutorbench.slurm:31-35`),
which reaches `llama-server` as `--reasoning on`. The server log confirms it took
effect at startup: `srv init: init: chat template, thinking = 1`, with a template
carrying a `<|think|>` turn.

What that did is measurable rather than inferable. The log records decoded token
counts per request, 2558 of them, one per item across the nine columns in run
order. Set beside the length of the string the parser actually received:

| column | median tokens decoded | median length of parsed reply |
|---|---:|---:|
| mistake_location | **894** | **1 character** |
| solution_correctness | **648** | **2 characters** |
| socratic_questioning | 466 | 178 characters |
| problem_solving | 684 | 662 characters |
| mistake_correction | 1348 | 1594 characters |

On `mistake_location` the checkpoint generated roughly 894 tokens per item and the
benchmark's parser received a single digit. The reasoning went into
`reasoning_content` and `mtb_responders.py:135` reads `content`. The two
assessment columns are, in this run, several hundred tokens of chain-of-thought
per item with the thought discarded before scoring.

Every published entry except `gemini-2.5-pro` ran with that disabled, through the
completion API, where any such text would have landed in the parsed string and
`parse_response` would have taken the first integer it found anywhere in it.

**So the comparison is not like-for-like and is dropped.** No sentence in this
document ranks our number against a leaderboard row. The one entry that did reason,
`gemini-2.5-pro`, scores 0.72 on `mistake_location` against our 0.623, which is the
only roughly comparable pairing available and is not one we win.

### The columns, against their own floors

Intervals are Wilson 95% for proportions. Where items cluster (two per StepVerify
row; 106 of 194 source rows contribute both), the interval is a cluster bootstrap
over source rows, the more conservative construction. It agrees with Wilson to
within 0.003 here. BLEU carries a 10,000-draw item bootstrap.

The floors below are recomputed **on our exact 300 items**, not carried over from
the 2004. The seeded split cuts pairs apart, so our held-out prefix is not
perfectly balanced: 144 of 300 `mistake_location` targets are 0 and 155 of 300
`solution_correctness` targets are Yes. A floor computed on one sample does not
transfer to another, which is the error this document exists to avoid committing.

| column | n | metric | value | 95% interval | floor here | lift |
|---|---:|---|---:|---|---:|---:|
| problem_solving | 300 | accuracy | 0.880 | 0.838 – 0.912 | none defined | — |
| socratic_questioning | 300 | sacrebleu | 0.230 | 0.214 – 0.246 | 0.132 | +0.098 |
| solution_correctness | 300 | f1 | 0.807 | 0.754 – 0.856 | 0.681 | **+0.126** |
| solution_correctness | 300 | accuracy | 0.817 | 0.771 – 0.861 | 0.517 | +0.300 |
| mistake_location | 300 | micro-F1 | 0.623 | 0.569 – 0.674 | 0.480 | **+0.143** |
| mistake_correction | 300 | accuracy | 0.677 | 0.622 – 0.727 | none defined | — |
| scaffolding_generation | 300 | reward win | 0.313 | 0.264 – 0.368 | not measured | — |
| scaffolding_generation_hard | 229 | reward win | 0.380 | 0.320 – 0.444 | not measured | — |
| pedagogy_following | 300 | reward win | 0.357 | 0.305 – 0.412 | not measured | — |
| pedagogy_following_hard | 229 | reward win | 0.511 | 0.447 – 0.575 | not measured | — |

The two lifts in bold carry paired intervals, computed by resampling items and
scoring the arm and its floor on the same draw:

- `mistake_location` over always-0: **+0.143**, bootstrap 0.083 – 0.207.
- `solution_correctness` f1 over always-Yes: **+0.126**, bootstrap 0.063 – 0.190.

Both exclude zero. Those two are the whole of what this run supports.

`mistake_location` also records macro-F1 0.419 (bootstrap 0.322 – 0.509) and
weighted-F1 0.623. Its floor under macro averaging is 0.081, not 0.500. The two
numbers belong to different averagings and must never be set against each other.

The 15 empty replies on `mistake_location` are not a source of free credit: they
parse to 0, four of the fifteen happen to be right, and accuracy on the 285
non-empty replies is 0.642, above the full-sample 0.623.

### Floors: defined, undefined, unmeasured

**Measured, for BLEU.** `socratic_questioning` admits a constant floor: score one
fixed question against every item's references. On our 300 items, "How many are
there in total?" reaches **0.132**, and the best constant drawn from the reference
pool itself (120 sampled) reaches 0.130. A generic counting question is worth
about 0.13 BLEU with no reading of the problem. Every published entry clears it,
and so does ours at 0.230, which ties the lowest published value
(`eth-nlped/TutorRL-7B` at 0.23) and sits below the other thirteen.

**None defined.** `problem_solving` and `mistake_correction` are scored by exact
numeric match against a free-form answer. The best single constant on our items is
0.037 and 0.047. There is no constant answerer worth naming; both columns are
informative from zero.

**Definable but not measured, for the four generation columns.** These are win
rates: how often `eth-nlped/Qwen2.5-1.5B-pedagogical-rewardmodel` scores the
produced teacher turn above the turn the human teacher actually wrote. A floor is
definable in principle, by scoring one fixed teacher utterance against every
item's human turn. It has not been run and no artifact holds it. The obstacle is
procedural rather than conceptual: `mtb_reward_score.py:9-12` records that
rescoring already-scored items on a different machine has drifted by as much as
0.45 reward points, so a floor is only comparable if scored in the same process as
the arm it floors. Computing one means a fresh reward-model pass. **These four
columns are reported without a floor and no claim here rests on them.**

The per-item score pairs reproduce the win rates exactly (94/300, 87/229, 107/300,
117/229), and no item has an empty teacher turn or an empty generation. The mean
reward margin is negative on all four arms (−3.15, −1.94, −2.76, −0.83): even
where the win rate reaches 0.511, the reward model prefers the human teacher by a
margin on average.

**A trap in these four columns.** The `match` field in `summary-*.json` is not the
win rate. The shipped `compute_metrics` for these tasks returns the fraction of
replies ending in a question mark (`tasks/scaffolding_generation.py:34`). On this
run it reads 0.45, 0.511, 0.64, and 0.812, roughly double the win rates. Each
summary file carries a `note` saying so. Reading these columns off `match` reports
a result twice as good as the one that happened.

## Sample identity

The published numbers are over whole test sets: 2004 items for the two
classification columns, 1002 for `mistake_correction`, 1319 for the two GSM8K
columns, 1150 and 327 for the MathDial columns. The shipped `main.py` iterates
`get_test_examples()` with no cap, no shuffle, and no seed. The leaderboard states
no evaluation sample size for any row.

Ours is 300 items, and not a random 300. `select_indexes` takes the first `limit`
entries of the *sorted* held-out index list, so the 300 are the low-index held-out
members of roughly the first fifth of each dataset (`mistake_location` indexes run
0 to 430 of 2004). It is a prefix, not a draw. Whether these datasets carry
ordering structure has not been checked.

Two columns are exceptions: `scaffolding_generation_hard` and
`pedagogy_following_hard` at n=229 are the entire held-out portion of the 327-item
hard split.

The benchmark's own replication is contested. Issue #4 on `eth-lre/mathtutorbench`
("Help to replicate results in Leaderboard", 2026-07-28) reports failure to
reproduce published values at temperature 0 with `--seed 42`; the maintainer's
reply names `is_chat` sensitivity, and no evaluation seed is disclosed. Rows added
after the paper arrive through a submission process that asks submitters to "copy
the results from the local run of the model."

## Contamination

What can be ruled out: nothing, by any evidence available here.

- `problem_solving` and `socratic_questioning` run on the GSM8K **test** split.
  An 0.880 from a 5.1B checkpoint is inside the range memorization would produce
  and this run cannot separate the two.
- The three StepVerify columns set `test_split: train`, so the evaluation items
  are that public dataset's only split.
- The scaffolding and pedagogy columns run on MathDialBridge, vendored as plain
  JSON here and derived from the public MathDial corpus.
- This repository holds no training-data statement, no cutoff, and no
  decontamination report for the `gemma-4-E2B-it` checkpoint.

What is unaffected: the floors. A constant answerer cannot be contaminated, so the
nine-of-fourteen finding holds regardless. Contamination, if present, inflates our
lifts and inflates every published entry by an unknown and differing amount, which
is one more reason the ranking is not the part worth carrying.

## What these numbers do not license

**This is an unassisted checkpoint result and says nothing about Hermes.** The
responder is `unassisted`. No Prolog ran, no lookup was consulted, no tool was
offered. Whatever is good here belongs to a quantized Gemma checkpoint and the
benchmark's own prompts. It is not evidence for a symbolic core, a neurosymbolic
architecture, or anything this project built.

**The Hermes-assisted claim does not replicate.** Two runs with identical recorded
configuration (`responder: hermes_correction`, `model: gemma4:e2b`, `split: dev`,
`limit: 40`, `split_seed: 20260726`) scored `mistake_correction` at **0.625**
(`runs/mtb-assisted-40/correction/`) and **0.550** (`runs/mtb-assisted-40b/correction/`).
Both files were read directly. The spread between two runs of the same thing is
0.075. The "win" that `2026-07-26-mathtutorbench-nine-columns.md` reported from
run A alone was 0.025 over the 0.600 unassisted arm. Run B sits *below* the
unassisted arm, so the sign of the effect is set by which run gets reported. The
same pair moves `mistake_location` 0.625 to 0.600 and `problem_solving` 0.875 to
0.900; `solution_correctness` is identical across both. That document has been
corrected in place.

**No ranking against the leaderboard is licensed, in either direction.** Reasoning
enabled against reasoning disabled, a chat template against a completion API, a
300-item prefix against whole test sets, and a partly self-reported comparison set.
Any sentence containing "above every published entry" is unsupported. On the
current fourteen-row board our 0.623 would sit below Qwen3.6-27B's 0.71 and
gemini-2.5-pro's 0.72 in any case.

**0.623 does not separate from LearnLM's 0.57 even on our own arithmetic.** The
interval on 187/300 is 0.569 to 0.674 by Wilson and by cluster bootstrap alike. It
contains 0.57, before any allowance for the published value's own uncertainty.

**0.623 was not measured on a laptop.** It was measured on a Big Red 200 GPU node
through `llama-server`. The laptop measurements are the dev-40 runs through Ollama.
`mtb_responders.py:113` states in the present tense that `mtb_scale_check.py`
re-runs a laptop-measured slice and compares the two routes, "because a number
from one route may not be set beside a number from the other until they have been
shown to agree." **That file does not exist anywhere in this repository.** The two
routes have never been shown to agree. The checkpoint is laptop-runnable and that
deployment claim survives; the sentence "scores 0.623 on a laptop" does not.

**`socratic_questioning` is at the bottom of the board**, at 0.230 against a
published range of 0.23 to 0.48. It ties the lowest entry and clears the 0.13
constant-question floor, and nothing more than that.

**The four generation columns are the weak half**, reported without floors and
with every mean reward margin negative. Against the fourteen published rows,
`scaffolding_generation` at 0.313 and `pedagogy_following` at 0.357 each exceed
only two entries; `scaffolding_generation_hard` at 0.380 exceeds four;
`pedagogy_following_hard` at 0.511 is mid-board. Those placements are recorded
for orientation and are subject to the same reasoning mismatch that voids the
assessment-column comparison.

## Numbers quoted elsewhere with no surviving artifact

Flagged, not chased. Each was searched for across the whole `runs/` tree.

| number | where quoted | status |
|---|---|---|
| stop-mode ablation, naive row: empty rate 0.900, f1_micro 0.475 | `2026-07-26-...md:29-32` | **unreproducible.** No file holds 0.475 or any empty-rate field. The 0.900 exists only as prose in `mtb_responders.py:58`. |
| stop-mode ablation, post row: f1_micro 0.575 | same | value backed by `runs/mtb-unassisted-40/summary-mistake_location.json`; the 0.000 empty rate is recomputable but unrecorded. **The run's `stop_mode` is recorded nowhere**, and the code default is `decode`, so that row cannot prove its own label. |
| `raw=true` scores 0.050 on problem_solving | `2026-07-26-...md:42-43` | **unreproducible.** No artifact holds 0.050, and `mtb_responders.py` has no `raw` mode. The comparison has no code path in the current tree. |
| four-arm 20-item table: `tutor_ledger` 0.70, `agent_tutor` 0.65 | `2026-07-26-...md:183-187`, `2026-07-31-neurosymbolic-status.md:349-352` | **unreproducible.** `runs/mtb-tutor-40/` holds one `.jsonl` of 27 rows and no score of any kind; no `agent_tutor` run directory exists. |
| same table: `agent_tutor_mandated` 0.50 | same | backed by `runs/mtb-mandated-20/reward-summary.json` (n=20, wilson 0.299–0.701). |
| same table: unassisted 0.45 | same | recomputable from the first 20 records of `runs/mtb-gen-40/reward-scaffolding_generation.json` (9 of 20), which carry the same source indexes in the same order; not recorded as a value. |
| same table: calls/item 1.0 / 2.1 / 1.6 / 2.2, tool calls 0 and 9 | same | **unreproducible.** The counters print to stderr and only `mtb-assisted-40` captured a log. |
| Prolog adjudicates 99%, 471 of 478, 462 of 466 | `2026-07-26-...md:91-96` | **unreproducible.** No artifact; the counters print to an uncaptured stderr. |
| stepverify 1002 flagged steps; 2.5% / 69.6% / 27.9%; categories 28.6 / 24.0 / 14.0 | `2026-07-26-...md:129-136` | **unreproducible.** 1002 and 28.6 are asserted in a docstring at `scripts/research/diagnosis_benchmark.py:7,15`; the rest appear nowhere but the document. |
| crude first-wrong-step rule matches 42.0% | `2026-07-26-...md:148` | **unreproducible.** No script implements the rule. |
| earlier bespoke driver reached 0.783 on 360 scaffolding items | `2026-07-26-...md:228-230` | **backed.** `runs/fleet_report.json`, arm `iterative`, n=360, 282 wins, 0.7833, wilson 0.738–0.823; same values in `runs/7772992/baseline_vs_suite.json`. Its unassisted baseline is 0.458 at n=360. |
| refuted 0, 1, 2, 0 across four arms; 46 to 68 equations checked | `2026-07-26-...md:123-126` | **backed** by the `MTB_HERMES_STATS` lines in `runs/mtb-assisted-40/run.log`. |

`knowledge/index/research_measurement_registry.pl` carries a receipt for each of
these lines (317-339 for the source document, 538-541 for the status document) and
records `none_recorded / none_recorded / method_not_recorded` for all of them
alike. The registry does not separate the backed rows from the unbacked ones,
which is a gap in the registry rather than in the receipts.

## The sentences this work supports

> On MathTutorBench's `mistake_location` column, nine of the fourteen published
> entries score at or below 0.500, which is what a system reaches by answering "0"
> to every item without reading it. The row the benchmark labels `GPT-4o` is among
> them at 0.37. On `solution_correctness`, seven of the fourteen fall strictly
> below the f1 of 0.667 that an always-"incorrect" answerer reaches, and two more
> sit at that value to the displayed precision. The same five entries clear both.

> That column's floor is also asymmetric in a way no published artifact records:
> f1 is computed with "incorrect" as the positive class, so an always-"incorrect"
> answerer scores 0.667 while an always-"correct" one scores 0.000, and the
> response parser defaults every unparseable reply to "incorrect".

And, separately and much more weakly:

> An unassisted quantized 5.1B checkpoint clears both floors on a 300-item
> held-out sample: micro-F1 0.623 against an always-0 floor of 0.480 (paired lift
> +0.143, 95% 0.083–0.207), and f1 0.807 against an always-Yes floor of 0.681
> (paired lift +0.126, 95% 0.063–0.190). This arm ran with reasoning enabled while
> the leaderboard's entries ran with it disabled, so it is not comparable to them
> and is not ranked against them.

Not a ranking, not a laptop, not Hermes.
