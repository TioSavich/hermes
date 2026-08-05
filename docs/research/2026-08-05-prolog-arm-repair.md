# The Prolog arm was throwing away programs that were right

The `problem_solving` arm asks a checkpoint for a SWI-Prolog program, screens
it, runs `solve/1`, and reports whatever the interpreter binds. When any step
of that fails, the strict arm returns the empty string and the guarded arm
falls back to the plain model. Nothing between the model and the interpreter
ever tried a second time.

This document reports what that costs, on an authored corpus rather than on the
benchmark, and closes the part of it that is the harness's fault rather than the
model's. **No model was called for anything below, no benchmark item was read,
and no benchmark number moved.** What changed is that a program a checkpoint
wrote correctly now gets to run.

## The gap this started from

Two things are true of this repository on 2026-08-05.

The first is that the failure shapes are already recorded. The prolog-assisted
diagnosis arm logged every goal it formed, and
`docs/research/2026-08-01-diagnosis-prolog-arm.md` names what came back:
45 of 327 formed goals failed, and "the failures have a shape worth keeping:
lowercase letters used as variables (`x =:= 5` is an atom and a type error),
comparisons against unbound variables (`20 =:= S`), prose prefixed to the goal."
Three named shapes, all three syntactic, none of them a claim about quantities.

The second is that **no document in this repository reports a `prolog_solve`
score.** The responder, its unit tests, its probe, and its report script all
exist and are commit `fe253e7` or older. The failure taxonomy the responder
prints on `close()` — `no_program`, `rejected_unsafe`, `syntax_error`,
`runtime_error`, `no_solution`, `timeout`, `nonnumeric` — has seven ways for an
item to end with no answer, and no artifact here says how often each fires.
An arm that is never scored cannot be improved, and the first thing built here
is the instrument, not the repair.

## The corpus

`scripts/research/prolog_repair_corpus.py` holds 29 replies. Every word problem
and every program in it was written for that file. None is a benchmark item, a
dataset row, or any model's actual output, and nothing in it is ever scored
against a benchmark target — it measures whether the harness runs a program,
never whether the program is right about a question the benchmark asked.

Each case carries one of four verdicts, and the ladder is only worth having if
all four hold at once:

| verdict | n | what must happen |
|---|---:|---|
| `runs` | 7 | runs as written; repair must not fire, and the value must not move |
| `harness` | 12 | a correct quantity model the arm discards; repair must recover it at the value it already meant |
| `model` | 5 | determines no answer; repair must not manufacture one |
| `unsafe` | 5 | the screen refuses it; every rung must be refused too |

`scripts/checks/prolog_repair.py` runs all 29 through the arm's own extract,
screen, and run path, once with the ladder off and once with it on, and fails
if any verdict is broken. It calls no model and needs only `swipl`.

## What the harness was losing

| case | what the checkpoint wrote | outcome before |
|---|---|---|
| `declarative_goal_order` | the relation before the quantities it reads | `runtime_error` |
| `declarative_order_in_a_helper` | the same, one clause down | `runtime_error` |
| `comparison_before_its_binding` | the question's test before the quantity | `runtime_error` |
| `trailing_query_line` | `?- solve(X), write(X).` after the program | `rejected_unsafe` |
| `initialization_and_main` | a `main/0` that prints the answer | `rejected_unsafe` |
| `output_goal_inside_solve` | `format/2` at the end of `solve/1` | `rejected_unsafe` |
| `dynamic_declaration` | `:- dynamic stops/1.` | `rejected_unsafe` |
| `facts_gathered_inside_findall` | facts reached only from a meta-goal | `rejected_unsafe` |
| `lowercase_words_as_variables` | `chairs is rows * per_row` | `no_solution` |
| `answer_predicate_renamed` | the root predicate called `answer/1` | `runtime_error` |
| `braces_without_the_import` | `{Boxes = 25 * 32}` and no `use_module` | `runtime_error` |
| `query_and_prose_and_bad_order` | three of the above at once | `runtime_error` |

Seven ways to end with no answer, and on these twelve items every one of them
fires on a program whose arithmetic is already correct. The `no_solution` case
is the worst of them: `chairs is rows * per_row` evaluates the right side and
then tries to unify a number with an atom, so the clause fails without raising
anything at all, and the arm records a quantity model that simply had no
solution.

## The ladder

`scripts/research/mtb_prolog_repair.py` returns the programs to try after the
text as written, cheapest repair first. Rung 0 is always the original, and the
ladder is entered **only when rung 0 did not answer**, so a program that already
runs is never rewritten and no repair can move a value the arm already had.

**Rung 1, normalization.** Strip comments. Drop `?-` query lines and every
directive but an allowed `use_module`. Drop goals that only write to a stream.
Rename an atom used as the target of `is/2` to the variable it meant. Alias
`solve/1` to the program's root predicate when it has exactly one, or to the
last argument of a single `solve/N`. Keep only what `solve/1` can reach,
following calls nested inside meta-goals. Add the clpq import a program with
brace constraints forgot.

**Rung 2, dataflow order.** Sort each conjunctive body so a goal runs after
whatever binds the variables it reads. The sort is stable and only ever delays
arithmetic and comparisons; a generator keeps its place ahead of the test that
consumes it, and a body that already runs is returned untouched. A body with a
disjunction or an if-then is left alone entirely.

**Rung 3, constraints.** Rewrite `X is Expr` as `{X = Expr}` where `Expr` stays
inside clpq's rationals, which removes goal order from the question altogether.
Integer division, `mod`, truncation, and the named functions have no clpq
reading and are declined.

That third rung is the one idea taken from outside. The Prolog-annotated GSM8K
work (`Thomas-X-Yang/gsm8k-prolog`, and the Prolog-generation-and-permutation
paper behind it) augments its training data by permuting facts and permuting
the goals inside `solve`, on the reasoning that a Prolog program's declarative
content does not depend on either order. Its dataset was not read, downloaded,
or copied, and nothing here is trained; what was taken is the observation that
**goal order is the model's problem only because `is/2` makes it the
interpreter's problem.** A constraint has no order to get wrong. Where the
arithmetic admits a constraint, the arm now stops punishing a checkpoint for
writing the sentences down in the order the word problem said them.

### The screen is unchanged

Repair never widens what may run. `screen_program` is applied to every repaired
program exactly as it is applied to the text as written, the repairs only ever
delete, reorder, or rename, and the one construct any of them introduces is a
brace constraint. Five corpus cases exist to hold this: one of them hides
`shell/1` inside `solve/1` behind a `main/0` that pruning removes, so the rung
that cleans the program up must still be refused. Deliberately bypassing the
screen for repaired programs makes the check fail on nine cases.

## What the check reports

```
$ python3 scripts/checks/prolog_repair.py
PASS 7 running programs untouched, 12 harness losses recovered at the authored
value, 5 undetermined programs left unanswered, 5 refused programs still refused
PASS answered 7/29 without the ladder, 19/29 with it
```

The check is not vacuous, and this was measured rather than assumed. Disabling
the reorder rung fails 1 case; disabling normalization fails 8; bypassing the
screen fails 9; replacing the ladder with a rung that answers `42` fails 21.
Reorder fails only one because the constraint rung independently repairs most
of what a bad goal order breaks; the case it cannot reach is a comparison,
which has no constraint reading.

## The second lever, built and unmeasured

An interpreter is a verifier the arm was not using. A program that does not run
casts no vote, so sampling k programs and taking the value the most executed
ones agree on filters through execution rather than through a second opinion.
`samples=k` does this and records the tally per item; `samples=1` is greedy and
is what every recorded run used. **No k>1 run has been made.** The vote's
tie-breaking, its treatment of programs that fail, and its plumbing are unit
tested; its effect on any score is not measured and no claim is made for it.

## Reproducing the arm as it was

`repair=off` restores the arm exactly as it ran before the ladder existed, and
`samples=1` with `temperature=0` is the old decoding. The two are an ablation
rather than a replacement, every run records which it was in
`MTB_PROLOG_STATS`, and every item records the rung and the named steps that
produced its answer. `prolog_arm_report.py` now crosses those against
correctness, because recovering a wrong program is a real cost: an item the arm
used to leave blank becomes an item it gets wrong.

```sh
python3 scripts/checks/prolog_repair.py            # offline, needs swipl
python3 -m unittest discover -s scripts/research -p "test_mtb_prolog_responder.py"
python3 scripts/research/prolog_arm_probe.py --scratch-dir ... --repair off
python3 scripts/research/prolog_arm_probe.py --scratch-dir ... --samples 5
```

## What this does not license

- **It is not a benchmark result and there is not one here.** Nothing was run
  against MathTutorBench, GSM8K, or any dataset. The `problem_solving` column
  is unchanged and unmeasured under repair.
- **7 of 29 is not the arm's rate on real items.** The mix of the corpus was
  chosen by whoever wrote it, and the choice was to cover each failure shape
  once, not to reproduce how often each occurs. Twelve recoveries out of
  twenty-nine authored cases predicts nothing about how many items on a real
  split are lost this way. That number is unknown, and the report script and
  the `repair=off` ablation now exist to obtain it.
- **A recovered program is not a correct answer.** Repair is syntactic. A
  program that says the wrong thing about the quantities and now runs returns
  a wrong number where the arm used to return nothing, which is worse than
  nothing wherever a blank was scoring better than a guess. The repaired/correct
  cross in `prolog_arm_report.py` exists to catch that, and it has not been run.
- **The three shapes cited from the diagnosis arm were logged by a different
  responder.** `prolog_kb` asks for one goal, not a program. That its goals
  failed those ways is evidence the shapes are real for this checkpoint; it is
  not a measurement of how a program-generating arm fails.
- **Nothing here says the arm will clear the unassisted baseline.** The
  unassisted checkpoint reached 0.880 accuracy on a 300-item held-out prefix
  (`docs/research/2026-08-01-mathtutorbench-heldout-with-floors.md`), on a run
  that is not comparable to the leaderboard for reasons that document gives. A
  Prolog arm has to beat *that*, and no run reported here or anywhere else in
  this repository has tried.

## Provenance

- `scripts/research/mtb_prolog_repair.py` — the reader and the three rungs.
- `scripts/research/prolog_repair_corpus.py` — 29 authored replies, four verdicts.
- `scripts/checks/prolog_repair.py` — the offline check, in `run_all.sh`.
- `scripts/research/mtb_prolog_responder.py` — `repair`, `samples`,
  `temperature`, per-attempt transcripts, rung and step counters in the summary.
- `scripts/research/prolog_arm_report.py` — the repaired-against-correct cross.
- `scripts/research/test_mtb_prolog_responder.py` — 54 tests, of which 39 are new.

The repair module carries its own tokenizer. The screen's reads `12.` at the end
of a clause as a decimal number, which costs the screen nothing because it only
inspects atoms, and would silently merge two clauses for anything that moves
them. `screen_program` was left exactly as it is: it is the one authority on
what may run, its behaviour has been measured, and a reader is not the place to
change it.
