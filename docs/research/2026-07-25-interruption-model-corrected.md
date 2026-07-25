# The 43 missing automata are already written, and my interruption model was wrong

Model: `claude-opus-5[1m]` (Opus 5, 1M context).
Date: 2026-07-25. Continues `2026-07-25-answerability-and-incompatibility.md`.

Files changed: `scripts/research/build_action_grammar.py`,
`knowledge/strategies/action_grammar.pl`, `scripts/checks/action_grammar.py`,
this report.

## The 43 missing tables do not need writing

The owner pointed at the NotebookLM `old umedca` notebook, where transition tables
for the SMR and SAR automata were articulated for the second Hermeneutic
Calculator and an IMERS 2024 presentation, with the caveat that this iteration is
probably quite different and the tables might have to be written.

They do not. All 43 are already implemented Prolog in this repository.

`knowledge/strategies/math/action_automata_registry.pl` declares 172
`action_automaton_signature/4` rows across 13 operations and it `use_module`s the
`sar_add`, `sar_sub`, `smr_mult` and `smr_div` pair files without declaring a
single signature from them. `build_transition_tables.py` takes its signature list
from that registry. So the 43 signatures the pairings name have no table for one
reason: nobody registered them.

Checked one by one, every one of the 43 has a runner clause, an
`action_outcome/2`, and a `Trace = [...]` list:

| module | signatures | of which productive |
|---|---:|---:|
| `fraction_action_pairs.pl` | 10 | 5 — `splitting`, `solve_for_unit`, `recursive_partition`, `improper_fraction_iteration`, `cross_multiplication_rule_from_pattern` |
| `smr_mult_action_pairs.pl` | 9 | 1 — `known_product_adjustment` |
| `sar_add_action_pairs.pl` | 7 | 1 — `derived_fact_adjustment` |
| `sar_sub_action_pairs.pl` | 7 | 2 — `sliding_constant_difference`, `borrow_across_zero_cascade` |
| `smr_div_action_pairs.pl` | 6 | 2 — `inverse_fact_decomposition`, `missing_factor_known_product_search` |
| `calculus_limits_action_pairs.pl` | 2 | 1 |
| `probability_action_pairs.pl` | 2 | 1 |

`splitting`, `solve_for_unit`, `recursive_partition` are the Steffe/Olive/Hackenberg
fraction schemes, written and running and invisible to every layer above them.
Three of the 43 even carry an `invariant/1` the answerability layer would pick up
immediately: `cascade_borrow_to_next_nonzero_column`,
`match_dividend_as_product`, `add_missing_equal_group`.

So I did not query NotebookLM. It would have been the fourth time this session I
went looking for something the tree already held.

### Why registering them is its own slice and not the tail of this one

A signature row is typed: `action_automaton_signature(Operation, Signature, inputs(Type, Type), OutputType)`.
Forty-three of those means forty-three input-contract decisions, and
`knowledge/strategies/automaton_input_contracts.pl` carries a `verified(...)` field
meaning contracts are checked against live runs. Registering also changes:

- the transition tables, all 171 of them regenerated, under the
  byte-identical-rerun gate;
- the strategy-algebra analyzer, which hard-asserts
  `len(observed) != 69` and will refuse to run the moment a newly registered
  signature acquires an observed edge;
- whatever else reads signature counts — the capability registry, the atlas page,
  the worker's dispatch.

`build_transition_tables.py` has no `--output`, so there is no dry run: the first
experiment writes the tables. That is a formal-core change wanting hash proofs
and an error-corpus diff, per the house rule, and it wants a slice where that is
the whole job. Scoped, not started.

## My interruption model encoded a policy the owner does not practice

Asked whether he interrupts on setup or on error, he answered something better
than either. He interrupts **infrequently**: when a student is in a contradiction
loop he can point out **so they can recognize it**, or when a student is
frustrated and has no idea and starts saying things that are very irrelevant.
Sometimes on setup, sometimes on error, and rarely. And: *sometimes people
unexpectedly land in the right place and I learn something.*

Measured against that, what I had built was wrong three ways.

**It fires far too often.** The derived `stop` verdicts fire on **59 of 189
machines, 31%**. His contradiction-loop condition fires on **1 of 189**. That is
not a threshold to tune.

**It fires on the wrong thing.** Every one of my sixteen stops was a token whose
stance is already deforming — the model was "a deformation is present, therefore
speak." He does not interrupt because a move is wrong. He interrupts because a
student is going in a circle, or has come loose from the task.

**It forecloses.** A `stop` verdict says which reading is running. The last
sentence of his answer says the parser must never be able to say that, because
the surprise is where the instructor learns. A model that cannot be surprised
cannot do the thing the practice is for.

### What replaced it

`interruption_license/5` is gone. Four families stand where it was.

**`interruption_trigger/4`** — two conditions, authored from his description, each
with its condition, its purpose, and a citation naming him.

`contradiction_loop`: the trace returns to a commitment it has already made
without the incompatibility having been discharged. In an automaton, a cycle
reachable from the start. Its purpose is recorded as the student's own
recognition, not the correction — *an interruption that supplies the answer has
answered the wrong question*. Its formal neighbour already exists:
`deontic_scorekeeper:deontic_incoherent/2` detects the incoherent state and not
the loop, which is a real difference and is written down.

`unmoored_utterance`: the utterance stops answering to anything the exchange has
established — tokens belonging to no strategy in play. He described the condition
and not the aim, so the aim is marked as inferred.

**`trigger_instance/5`** — where this corpus exhibits a trigger. One row.
`fraction/add_numerator_denominator_comparison` returns to
`q_add_numerator_denominator` after three states. `unmoored_utterance` has **no
instances, and that is the finding**: the corpus is closed by construction, every
token in it belongs to a strategy, so the condition cannot arise here at all. The
trigger is defined against discourse this repository does not hold. Declaring it
with zero instances is how that gets said.

**`reading_held_open/5`** — 65 rows, one per diverged pair, and the default with
no exceptions. Both readings of a diverged trace stay live: a trace on the
deformation reading may still terminate where the productive one does, and the
corpus cannot say it will not. This is the fact family form of *sometimes people
unexpectedly land in the right place*.

**`token_loss_rate/4`** — the old derivation, demoted from policy to evidence. Of
the machines carrying an action, how many end on a deforming step. Fifty-nine
rows, actions carried by fewer than four machines omitted rather than reported at
a scale that cannot bear them. It says where losses cluster and nothing about
when to speak.

### The check enforces the absence

`scripts/checks/action_grammar.py` now fails if a `verdict(_)` reappears anywhere
in the grammar. Not a style rule: a verdict forecloses the reading he reports
being surprised by, so its absence is a property worth holding against future
edits, mine included. The check also re-tests every `contradiction_loop` instance
for a cycle reachable from the start, requires that every cycle in the corpus have
an instance, requires every incompatible pair to have its reading held open, and
re-derives every census row from the corpus.

## What this says about where the parser has to look

The last report ended with the register census and a question: setup or error?
The answer is both, rarely, and on a different criterion than either. Which means
the constitution-register finding — 36 of 65 divergences have the productive side
in constitution — is real about **where readings diverge** and does not license
**watch the constitution register and interrupt there**. Those are two claims and
I had been sliding between them.

What the corrected model needs, and what this corpus cannot give it:

- **A loop needs a trace with repetition.** The corpus has 189 machines and one
  cycle, because a machine is a strategy and a strategy does not loop; a student
  does. Detecting a contradiction loop needs a trace over turns, with the same
  commitment recurring, which is discourse data.
- **Unmoored needs an open vocabulary.** The condition is defined by tokens
  belonging to no strategy, and every token here belongs to one by construction.
  It needs utterances that can fall outside.

Both triggers are therefore correctly specified and currently unrunnable, and
that is a better place to be than a policy that runs on 31% of the corpus and
answers the wrong question.

## Verification

- `run_all.sh` passes end to end.
- `scripts/checks/action_grammar.py` (exit 0), twelve assertions including the
  three new ones: the interruption model carries no verdicts; every
  `contradiction_loop` instance has a cycle and every cycle has an instance; all
  65 diverged pairs hold both readings open and every census row matches the
  corpus.
- Builder rerun byte-identical, twice.
- No change to the alphabet this slice, so the analyzer's default path is
  untouched.

## Honest limits

- **The two triggers are one person's practice, stated once.** They are cited to
  him and dated, not derived from anything. A second instructor might interrupt on
  different conditions and the family would need to carry more than one practice.
- **`unmoored_utterance`'s purpose is inferred.** He gave the condition. I wrote
  the aim and marked it inferred; it is the weakest row in the file.
- **The loop detector is structural, not semantic.** A cycle reachable from the
  start is not the same thing as an undischarged incompatibility recurring. For
  the one instance in this corpus the two coincide; over real traces they will
  not, and the condition text says which of the two it means.
- **Nothing here is wired into anything.** Still review-pending data with no
  consumer, and the parser these families specify does not exist.

## Result

- **The 43 missing automata need no writing.** All implemented with runners,
  outcomes, and traces; unregistered in
  `action_automata_registry.pl`, which is why no tables exist. NotebookLM not
  needed. Registration scoped as a formal-core slice with a named blast radius.
- **The interruption model is replaced.** 16 stop verdicts firing on 31% of the
  corpus, gone; two authored conditions in their place, 1 instance, and 65
  readings held open as the default.
- **A verdict cannot come back** without the check failing, because being unable
  to say which reading is running is the property the practice requires.
