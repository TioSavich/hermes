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
| decode-time, the naive run | **0.900** | 0.475 |
| applied to the reply afterwards | 0.000 | **0.575** |

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

## The floors that any number here has to be read against

The two assessment columns are balanced by construction, so a constant answer
scores well. Over the full 2004 items:

- `mistake_location`, always answering 0: **f1_micro 0.500**, macro 0.067,
  weighted 0.333.
- `solution_correctness`, always answering Yes: **f1 0.667**, accuracy 0.500.

The constant answer beats GPT-4o's published 0.37 on `mistake_location` and
sits just under LearnLM's 0.57. Most of that column is models failing to
abstain. LLaMA3.2-3B's published 0.67 on `solution_correctness` is exactly the
always-Yes f1. No number from either column should appear without its floor.

The leaderboard does not say which of f1_micro/macro/weighted it reports.
Magnitudes fit f1_micro. All three are recorded; comparisons here use micro.

## The four assessment columns

40 dev items, matched — the same items, the same parsers, the same metrics,
differing only in the responder. Published column bests are from the
benchmark's own leaderboard, vendored at `vendor/index.html`.

| Task | trivial | published best | unassisted | Hermes assisted |
|---|---:|---:|---:|---:|
| problem_solving | — | 0.94 LearnLM | **0.925** | 0.875 |
| solution_correctness (acc) | 0.500 | 0.75 LearnLM | **0.900** | 0.875 |
| solution_correctness (f1) | 0.667 | 0.75 LearnLM | **0.875** | 0.872 |
| mistake_location (f1_micro) | 0.500 | 0.57 LearnLM | 0.575 | **0.625** |
| mistake_correction | — | 0.84 GPT-4o | 0.600 | **0.625** |

n=40. Every difference between the two arms is one or two items and none of
them is significant. The comparison against the published column is the
part worth attention; the comparison between the arms is not yet decided.

**The unassisted checkpoint, run correctly, is at or above the published best
on two of the four columns** and within 0.015 of it on a third. That is a 2B
model on a laptop against LearnLM-1.5-Pro and GPT-4o. On `mistake_correction`
it trails the frontier badly (0.60 against 0.84) while sitting far above every
published open model (0.09 to 0.49).

## Is the core under-covered, or badly interfaced, or aimed elsewhere?

Asked directly, and measured three ways over 200 items in each half.

**Coverage is not the problem.** Prolog adjudicates **99%** of every equation
the reader hands it — 471 of 478 from incorrect student solutions, 462 of 466
from reference solutions. The `arithmetic_equation` clause routes through SWI
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

## Where the assessment tasks actually reduce to

Every one of stepverify's 1002 incorrect solutions ends on a final answer that
differs from the reference, and the no-error half of the task is built from
the reference solution itself. So `solution_correctness` reduces exactly to
solving the problem and comparing final answers, and a perfect solver would
score 1.000.

That is worth naming as a limit of the benchmark rather than a result. The
task as constructed never asks whether a *correct but different* route is
sound, which is the judgement a tutor actually makes.

## Not yet measured

The four generation columns — `scaffolding_generation`, its hard split,
`pedagogy_following`, its hard split — are scored by the published reward
model as a win rate over the human teacher's turn, not by the question-mark
heuristic the shipped `compute_metrics` returns. They are running.
An earlier bespoke driver reached 0.783 on 360 scaffolding items against a
published best of 0.64, under a six-to-eight call evidence ledger whose
reference-answer handling was audited here and does not enter any prompt.
Whether that survives this measurement path is open.

`socratic_questioning` is scored by sacrebleu against reference questions and
has a low ceiling for everyone on the board (0.29 to 0.48).

All numbers here are dev-split, n=40. The split is frozen by seed 20260726 at
30% dev; the held-out remainder has not been looked at.
