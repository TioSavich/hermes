# The diagnosis benchmark, first run

`scripts/research/diagnosis_benchmark.py` was written on 2026-07-26 and had
never been run. It is scored here for the first time. One arm covers all 1002
items of `eth-nlped/stepverify`; the other has finished its 301 dev items and
is still working through the 701 held out.

The task is a seven-way naming of the error category behind a student's wrong
solution. It is defined in this repository over the benchmark's data and its
annotators' labels. **It is not a MathTutorBench column and must never be
reported as one.** The nine official columns ask a reward model whether a
teacher turn sounds like good tutoring; none of them asks whether the
diagnosis behind that turn is right.

## The floor, before any model was called

Every accuracy below is set against the share of the split held by its most
common label. A system that answers the same category every time scores the
floor, so an accuracy under it is worse than a constant.

| split | n | most common label | floor | constant-answer macro-F1 |
|---|---:|---|---:|---:|
| dev | 301 | Misunderstanding of a question | 0.2890 | 0.0641 |
| heldout | 701 | Misunderstanding of a question | 0.2853 | 0.0634 |
| all | 1002 | Misunderstanding of a question | 0.2864 | 0.0636 |

Computed from the labels alone. The harness recomputes the same floor per run
and the two agree.

## The parser audit, which had to come first

`parse_category` took a reply and returned a category or the empty string. Its
first pass looks for a category's exact wording; its fallback scores word
overlap and accepts anything at or above 0.5. Three ways that fallback can
turn a non-answer into an answer were reproduced directly, before any run:

- `"None of these apply."` returned `None of the above`. Two of that
  category's words are longer than three characters, so one word carries the
  threshold. A refusal is scored as a positive prediction.
- `"The student answered the question asked."` returned
  `Misunderstanding of a question` — the majority class — for the same reason.
- A reply that restates the whole option list returned the first category in
  source order, again the majority class, because the exact-wording pass
  returned on its first hit.

So the route each prediction came by is now recorded per item and counted in
the summary (`classify_reply`, `parse_routes`). Over the 1343 distinct replies
scored for this report:

| route | count | reading |
|---|---:|---|
| `exact` | 1334 | the reply names one category verbatim |
| `overlap` | 5 | every one was the reply `"Missing quantity"`, an abbreviation of `Extra quantity or Missing quantity`; the parser read all five that way |
| `exact_ambiguous` | 0 | never fired |
| `empty` | 4 | the reply was the empty string, and is counted unparsed |

**Measured misparse rate: 0 of 1343.** The hazard is real and reachable, and
it did not fire. All five `overlap` firings are correct readings of an
abbreviated answer rather than manufactured predictions; one of the five is
scored wrong against its label, which is a model error and not a parse error.
Because the parser was not converting abstentions into predictions, it was
instrumented rather than changed: **no prediction in this report differs from
what the original code would have returned.**

The four `empty` replies are not abstentions either. Re-calling one directly
returns `done_reason: "length"` with `eval_count: 2048`: the checkpoint spent
its whole token budget reasoning and emitted nothing. The harness already
counts these as unparsed, which is the right treatment, but the cause was not
recorded anywhere until now.

## Compute, and two different models

| arm | checkpoint | route | per item |
|---|---|---|---:|
| local | `gemma4:e2b` (5.1B, Q4_K_M) | Ollama on the laptop, 4 workers | 18.11 s |
| hosted | `gemma-4-31B-it` | REALLMS `/direct/`, 6 workers | 1.30 s |

The local arm is the same checkpoint as the unreported nine-column held-out
n=300 run in `runs/bigred-heldout-300/`, so its number belongs beside those.
The hosted arm is **a different and much larger model**. Its numbers are a
second arm, never the first arm obtained faster, and the model id travels in
every summary file.

`--workers` was added to the harness because the laptop route puts 1002 items
at more than five hours. Forty dev items re-run at `--workers 4` returned all
forty replies byte-identical to `--workers 1`, and the gain is 1.21x, so
concurrency buys about an hour and changes nothing else.

## Results

Every accuracy carries its floor and the lift over it. `p` is a McNemar test
against the constant-answer predictor on the same items.

| arm | split | n | accuracy | floor | **lift** | macro-F1 | unparsed | p |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| `gemma-4-31B-it` | dev | 301 | 0.3920 | 0.2890 | **+0.1030** | 0.2961 | 0 | 0.00053 |
| `gemma-4-31B-it` | heldout | 701 | 0.3894 | 0.2853 | **+0.1041** | 0.2880 | 0 | 7.3e-9 |
| `gemma4:e2b` | dev-40 pilot | 40 | 0.2500 | 0.2750 | **−0.0250** | 0.1034 | 1 | 1.0 |
| `gemma4:e2b` | dev | 301 | 0.3023 | 0.2890 | **+0.0133** | 0.1548 | 3 | 0.56 |
| `gemma4:e2b` | heldout | 701 | still running | 0.2853 | — | — | — | — |

Nothing was tuned on heldout. The two hosted splits were run from the same
code with no change between them, and they agree to within 0.003.

**The laptop checkpoint does not clear its floor.** Its lift on dev is 0.013
over 301 items, and McNemar against the constant-answer predictor returns
p = 0.56: the arm and a system that answers "Misunderstanding of a question"
every time disagree on 26 items and split those 15 to 11. That is a null. The
40-item pilot pointed the same way, and the full dev split is the measurement
that settles it. The heldout half of the same arm was still running at the
time of writing; at 18.1 s an item it finishes around 21:05 local, and its
artifacts land in `runs/diagnosis-heldout-e2b/`. Held-out items were never
consulted for anything, so that run can only confirm or refute the dev
result, never revise how it was obtained.

The 40-item pilot is reported for the parser audit it was run for, not as a
measurement. At n=40 the majority label is not even the corpus majority label,
and its floor of 0.2750 belongs to a different category than the corpus floor.

## The quantity slice

`Extra quantity or Missing quantity` and `Unit conversion error` are 290 of
1002 items (28.9%). The harness reports them separately on the reasoning that
a checker binding a magnitude to the kind it measures could in principle name
these two and not the other five.

| arm | split | slice n | slice accuracy | whole-split accuracy |
|---|---|---:|---:|---:|
| `gemma-4-31B-it` | dev | 83 | 0.3494 | 0.3920 |
| `gemma-4-31B-it` | heldout | 207 | 0.3575 | 0.3894 |
| `gemma4:e2b` | dev | 83 | 0.0723 | 0.3023 |

The slice runs below the whole in all three cases, never above it, and on the
laptop arm it collapses to 0.072. Whatever makes these two categories
tractable for a symbolic checker does not make them easier for a language
model, which is a reason for a later wave to test the checker directly and is
not evidence that the checker would help. A constant-answer system scores
exactly 0.000 on this slice, so the slice's own floor is zero and both arms
clear it; that is a low bar and is reported so the 0.072 is not mistaken for
sub-floor.

Per-category recall on heldout records where the hosted arm's competence
actually sits:

| category | n | precision | recall | F1 |
|---|---:|---:|---:|---:|
| Reached correct solution but proceeded further | 42 | 0.571 | 0.571 | 0.571 |
| Misunderstanding of a question | 200 | 0.358 | 0.795 | 0.494 |
| Extra quantity or Missing quantity | 177 | 0.519 | 0.384 | 0.442 |
| Unit conversion error | 30 | 0.188 | 0.200 | 0.194 |
| Calculation error easily solved by a calculator | 89 | 0.368 | 0.079 | 0.130 |
| None of the above | 63 | 0.235 | 0.063 | 0.100 |
| Missing / Wrong factual knowledge | 100 | 0.312 | 0.050 | 0.086 |

Dev puts the same three categories on top in the same order; below them the
ranking reshuffles, which is what four F1 values between 0.04 and 0.20 do. The
arm answers the majority class on 444 of 701 items. On four of the seven
categories its recall is at or under 0.20, and on two of those under 0.08. The
lift over the floor is carried by one structurally obvious category and one
quantity category, not by a general capacity to name a student's error.

## The assisted arm that could not be run

The brief allowed a Hermes-assisted arm if the unassisted arm cleared its
floor with room. No such arm can be run today, and this was measured rather
than inferred:

- `hermes_location` on the diagnosis task abstained on 2 of 2 items with
  `abstain_task_mismatch` and made zero model calls. All four `hermes_*` arms
  map their arm name to one official task and abstain on anything else.
- `prolog_solve` raises before it starts without `scratch_dir`, and its
  `respond` raises `prolog responders support only problem_solving` for any
  other task name.
- Independently of both, `diagnosis_benchmark.run` passes `example={}`, so no
  responder can reach the problem or the student's solution through the field
  every assisted arm reads.

Running an assisted arm here is therefore new machinery — a diagnosis arm plus
a change to how the harness hands an item to a responder — not a run of
existing code. It was not built.

## What this does not license

- It is not a MathTutorBench result. It shares the benchmark's data and none
  of its scoring.
- The two arms are two models. The hosted arm's lift says nothing about what
  the laptop checkpoint can do, and the laptop checkpoint is the one the
  deployment claim rests on. On the split where both were measured, the
  hosted arm is +0.103 over its floor and the laptop arm is +0.013 at
  p = 0.56. Reporting the +0.103 without naming which model produced it would
  be a claim about a laptop that the laptop did not earn.
- A lift of about 0.10 over a 0.29 floor is a system that is wrong about six
  times in ten and answers the most common category on two thirds of items. It
  does not support any claim that a diagnosis is being named reliably.
- The quantity slice result is a null. It neither supports nor refutes the
  claim that a symbolic checker could name those two categories; it only
  records that a language model finds them no easier than the rest.
- Nothing here was run twice at the same configuration except the 40-item
  parser check. Run-to-run spread on this repository's assisted arms has
  already been measured at 0.075 on n=40, larger than differences that have
  been reported as wins. No single number below n=300 should be treated as a
  result.
