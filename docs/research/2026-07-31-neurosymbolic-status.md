# Neurosymbolic status, 2026-07-31

Companion to the session handoff. Written to be read cold: it assumes no
memory of the session that produced it.

All counts were taken by execution on 2026-07-31 against the **working tree**,
which at that moment sat at commit `befdd71` with uncommitted parallel work in
flight — including modifications to `curriculum/im/generated/compiled_task_instances.pl`
and to the PUSU and action-seam scripts. So the counts describe the tree as it
stood mid-wave, not a committed state, and `compiled_task_instance_summary` in
particular should be re-read after that wave lands. Where a count comes from
reading rather than running, the sentence says so. Section 7 separates what was
checked from what was accepted on citation.

Everything in sections 1 through 3 describes code and data that exist today.
Everything in sections 4 and 5 marked **PROPOSAL** does not exist and is not
being described as if it does.

---

## 1. Where Hermes stands neurosymbolically

### 1a. The symbolic side carries the reasoning; the model never does

The production server calls Gemma from exactly one function,
`call_api_messages` in `hermes/app/llm.py`, and its request body has two
keys:

```python
payload = {
    "model": model,
    "messages": messages,
}
```

There is no `tools` key, no `tool_choice`, no `functions`, at any of the five
call sites declared in `hermes/app/routes/llm.py` (`/api/chat`, `/api/help`,
`/api/transcript_report`, `/api/media_transcribe`, `/api/pml_score`). This is
not an oversight. `RouteLogic._handle_chat` in `hermes/app/routes/logic.py`
retrieves symbolic facts before the model is called at all, and says why in
the code:

```python
# Retrieve symbolic facts FIRST, so the answer is grounded in the KB
# (and so the UI can show what it was grounded in) — neuro-symbolic, not
# a free-associating chatbot. Best-effort; chat still works ungrounded.
```

`_handle_transcript_report` states the same shape for the two-pass path:
blind speakers locally, pass 1 math extraction by Gemma, Prolog adjudication
of every typed claim, deterministic mask, pass 2 posture read over the
residue. Two model calls, and the verdicts are computed rather than
generated. A request that supplies pre-extracted claims skips both model
calls.

**The architecture is retrieve-then-generate, one direction, with the model
downstream of adjudication.** Section 2 gives the published reason this is
the right shape at this model size.

### 1b. The tool surface, and what it refuses

`hermes/mcp/server.py` (727 lines, stdlib only) serves 17 core tools over
newline-delimited JSON-RPC on stdio, with no network listener. Verified by
extracting the `CORE_TOOLS` tuple on 2026-07-31:

    monitoring_chart, monitoring_chart_detail, lesson_deformation_chart,
    lesson_deformation_chart_detail, check_math_claim, deontic_scorecard,
    deontic_consequences, deontic_up_level, commitment_match,
    strategy_recognize, strategy_trace, misconception_lookup,
    misconception_search_rows, resonance_neighbors,
    incompatibility_entailments, incompatibility_profile,
    incompatibility_contexts

All 17 carry `{"readOnlyHint": true, "idempotentHint": true}`. The
`initialize` result declares `capabilities: {"tools": {}}` with no
`instructions`, no `prompts`, no `resources`. Everything a model learns about
Hermes arrives through those 17 description strings.

The refusal that matters: **a caller never names a predicate.** A request
carries a registered `op` atom; `dispatch_spec/4` selects the module and
predicate. The `math_claim` converter in `hermes_worker.pl` states the
boundary in a comment and then enforces it:

```prolog
% Typed math claims arrive as source text, but this boundary only accepts the
% finite grammar the checker registers.  It never turns a caller-provided term
% into a goal: the resulting term is data passed to check_math_claim/2.
```

`safe_math_claim/1` requires `ground`, `acyclic_term`, and a whitelisted
functor shape. `validate_dispatch_spec/0` throws at load time if any spec
names an unknown converter, of the 19 registered.

Scale of that layer on 2026-07-31: 147 `dispatch_spec/4` rows in
`hermes/dispatch_spec.pl`, 55 ops enumerated by `dispatch_irregular/1` in
`hermes_worker.pl`. (`CLAUDE.md` still says 139 and "26 render + 29
irregular"; that is stale and is noted here rather than edited, since this
document may not modify other files.)

### 1c. The runnable models

This is the property that distinguishes Hermes from the tradition described
in section 2a, so the numbers matter. All taken 2026-07-31:

| artefact | count | where |
|---|---:|---|
| `action_automaton_signature/4` rows | 219 | `knowledge/strategies/math/*.pl` |
| `automaton_input_contract/5` rows | 116 | `knowledge/strategies/automaton_input_contracts.pl` |
| `automaton_tuple/6` rows | 218 | `knowledge/strategies/transition_tables/*.pl` |
| `automaton_transition/6` rows | 2,142 | same, of which 1,088 carry `provenance(observed(...))` |
| `productive_*_deformation/3` pairing rows | 105 | `knowledge/strategies/math/*.pl` |

A trace is a list of act terms, not a computation record. From
`sar_add_action_pairs.pl`, the productive strategy and its paired
deformation:

```prolog
Trace = [ choose_larger_addend_as_start(Start),
          hold_other_addend_as_count(Count),
          iterate_successor_ticks(TickValues),
          name_last_tick_as_sum(ExistingResult) ].
```

```prolog
Trace = [ reset_to_zero_instead_of_starting_from_composite(Start),
          count_first_addend_from_zero(A, FirstAddendTicks),
          count_second_addend_from_first_total(B, AllTicks),
          preserve_result_but_lose_count_on_efficiency(Result) ].
```

The second one gets the right answer and is still classified
`deformation`, with `validity(correct_but_inefficient)`. Inefficiency is
recorded at trace level as a normative matter, not scored as an error.

**The 103-row gap between 219 signatures and 116 input contracts is the
authoring cost of runnable models, showing up as a measured number.** Section
2a is about what that cost buys.

### 1d. The formal core

`formal/formalization/grounded_arithmetic.pl` encodes counting as a doing:
numbers are `recollection(ListOfTallies)`, `successor/2` conses a tally and
calls `incur_cost(unit_count)`, subtraction fails rather than going negative.
`hermes/math_claim_checker.pl` decides truth by
`grounded_arithmetic:equal_to/2` over recollections and imports only grounded
predicates, so the no-`is/2` discipline is structural at the verdict boundary
rather than enforced by a repo-wide scan. There is no `is/2` check in the
gate chain; the discipline is carried by module imports, by per-module
comments naming each deliberate exception, and by review policy.

`formal/incompatibility/brandomian_incompatibility.pl` models Brandom's
relation with incompatibility as primitive data (`incompatible_set/1`) rather
than derived from negation, and with no explosion rule.
`incompatibility_entails/2` refuses the vacuous case explicitly.

The entailment register, `incompatibility_entailment_order.pl`, records its
own counts (read on 2026-07-31):

    declared_input_hyperedges  699      earned_entailments        44
    minimal_hyperedges         314      sparse_witness            22
    contents                   385      multi_profile_witness     22
    vacuous_entailments      1,536      equivalent_pairs           9
                                        nonterminating_excluded    1

44 earned out of 699 declared input hyperedges is the honest ratio, and the
1,536 vacuous cases are published rather than dropped.

### 1e. The corpora

| store | size | date read |
|---|---:|---|
| `explicit_lesson_strategy/4` rows | 1,553 | 2026-07-31 |
| `explicit_lesson_misconception/4` rows | 563 | 2026-07-31 |
| `compiled_task_instance_summary` | 401 lessons, 2,041 task instances | 2026-07-31 |
| `hand_authored_chart_lesson/5` facts | 3 | 2026-07-31 |
| `research_shared.db` `action_trace_deltas` | 115 rows | 2026-07-31 |
| `research_shared.db` `strategy_moves` | 8,950 rows | 2026-07-31 |
| `research_shared.db` `strategy_instances` | 2,276 rows | 2026-07-31 |
| `research_shared.db` `error_instances` | 3,621 rows | 2026-07-31 |
| `.bigred-collected/2026-07-30-atlas383/shards` | 383 shard files, 5,766 JSONL records | read, not re-counted |

Every `compiled_lesson_task_instance/3` row carries a receipt back to a guide
line: `rule / source(file, lines(a,b)) / position / excerpt`.

Two asymmetries are load-bearing for what follows. First, in the atlas383 run
the role distribution is roughly 5,667 productive against about 99 across ten
named deformation roles, out of 5,766 records. Second,
`lesson_deformation_chart`'s own tool description states that of the 78
lesson codes it serves, only a handful are hand-authored and the rest take
one fixed default fraction set which "reports nothing about what that lesson
asks children to model," with the instruction that "no coverage number may
cite this chart." The repo publishes this hole in the surface a model reads.

---

## 2. What the literature establishes, and what it asserts

### 2a. The sibling tradition: constraint-based modelling

Constraint-based modelling (CBM) is the closest published relative to what
Hermes is doing, and it took the opposite architectural bet. Ohlsson's
founding paper is explicit about the selling point: the approach "promises to
eliminate the need for runnable models of either the expert or the student
and to reduce the computations required for student modeling to pattern
matching" [1]. The tutorial framing describes constraints as "units that are
more prescriptive than descriptive and that primarily support evaluation and
judgment instead of inference or prediction" [2].

Hermes declines that promise. Its automata are runnable and running, and the
act sequences are the object of study rather than a means to a verdict. That
choice has a published price and a published payoff, and the fair thing is to
state both.

**What CBM demonstrates.** SQL-Tutor and its successors are among the
best-evidenced ITS results in the field: three classroom evaluation studies
with significant learning gains [3], more than thirty classroom studies over
fifteen years [4], and a specific authoring claim from 1998 that "the time
needed to acquire, implement and test a constraint is less than times
reported for the acquisition of production rules" [5]. The authoring-cost
advantage is not a marketing claim; it has been measured repeatedly.

**What the head-to-head comparison found.** Kodaganallur, Weitz and Rosenthal
built both a model-tracing and a constraint-based tutor for the same domain
(statistical hypothesis testing) and reported three conclusions [6]. First,
CBM "is feasible only for domains in which the solution itself is rich in
information," with no such restriction on model tracing. Second, "model
tracing demonstrates superiority with respect to the ability to provide
targeted, high-quality remediation; this superiority increases with the
complexity of the solution process goal structure." Third, model tracing
costs more to build, and that extra cost is what buys the better remediation.

This is contested rather than settled. Mitrovic and Ohlsson published a
critique of that comparison, and Kodaganallur et al. published a response
refuting the critique and offering a broader assessment of CBM [7]. Anyone
citing the comparison should cite the exchange.

**What this means for Hermes, concretely.** K-8 arithmetic strategy is a
domain with a complex solution-process goal structure and solutions that are
often information-poor (a single number). Both of Kodaganallur's conditions
point the same way, toward runnable models. The 103-row signature gap in
section 1c is the predicted development cost arriving on schedule. So the
repo is paying the price the literature says this choice costs, in the domain
where the literature says the price buys the most.

**Where CBM's critique lands on Hermes anyway.** Ohlsson's own 2016
retrospective names the limit of his approach — "CBM is limited in its focus
on learning from errors" [8] — and Hermes is not limited that way, since its
productive strategies run in their own right. But the atlas asymmetry in
section 1e is the CBM critique arriving empirically from the other side:
about 99 deformation records out of 5,766 means the deformation half of the
pairing is where the runnable-model cost has not been paid. A constraint does
not need a runnable buggy model to catch a violation. That is a genuine,
cheap complement, and section 5 proposes it.

**And the adjudication problem has a name in this tradition.** There is a
published argument that constraints alone cannot meet student-modelling
requirements when many error explanations compete for the same observation
[9]. Hermes already holds a position on this: the engine computes every
split and agents never adjudicate, recorded as the PUSU contrast-semantics
ruling. Naming the published version is useful because it means the position
is answerable to a literature rather than only to the repo.

### 2b. The LLM-plus-solver line, which is where the small-model bet lives

LINC is the strongest published support for the architecture Hermes already
runs. The LLM acts only as a semantic parser from natural language to
first-order logic; an external theorem prover performs the deduction. On
ProofWriter, "augmenting the comparatively small open-source StarCoder+ (15.5B
parameters) with LINC even outperforms GPT-3.5 and GPT-4 with Chain-of-Thought
(CoT) prompting by an absolute 38% and 10%, respectively" [10]. The paper also
reports that LINC and CoT "exhibit distinct and complementary failure modes,"
which is a finding about architecture rather than about scale.

Two qualifications before this gets quoted in a proposal. ProofWriter is a
synthetic deduction benchmark, not a classroom task, and the FOLIO results in
the same paper are weaker (GPT-4 with LINC performs "comparatively" to CoT
there rather than better). The 38% and 10% figures are absolute differences on
one dataset, and they are the paper's headline rather than its average.

The broader line is consistent and large. Logic-LM reports an average gain of
39.2% over standard prompting and 18.4% over CoT across five logical
reasoning datasets, with a self-refinement module driven by the solver's own
error messages [11]. Later entries add iterative refinement (Logic-LM++ [12]),
proof-level guarantees from meta-interpreters [13], and Prolog specifically
in the inference pipeline for arithmetic-heavy problems [14]. A SemEval-2026
system report describes a modular parser-plus-prover pipeline built on 4B
reasoning models that beats zero-shot baselines in that parameter range [15].

**The load-bearing observation across every one of these: the solver call is
not a decision the model makes.** The pipeline calls it. Not one of these
systems asks the model whether it would like to consult the symbolic side.

The one paper that comes closest to model-decided invocation is Xu et al.
2025, which reports that "LLMs are effective at predicting the necessary
formal reasoning strategies with an accuracy above 90 percent" [16]. Read
carefully: that is choosing *which* solver, after formalization has already
been assumed. It is not deciding *whether* to reach for one. The same paper
reports that "smaller models struggle with adaptive neuro-symbolic reasoning"
and names post-training as the path, which is directly relevant to section 4.

### 2c. The education-side numbers, with their denominators where published

The LLM-generated-feedback baseline is sobering and worth keeping on hand.
Reddig et al., analysing GPT-4 feedback on student errors from the Apprentice
Tutor College Algebra ITS, report that "35% of the hints were too general,
incorrect, or give away the correct answer," and that "only 35% of feedback
passes automated helpfulness evaluations" [17]. The abstract does not state
the item count, so the denominator behind both percentages is not established
here and should be pulled from the full text before either number is quoted
in a proposal.

Two further anchors bear on Hermes's misconception layer and are recorded
here as leads rather than as established findings, since only their abstracts
were consulted: incorporating a misconception into a knowledge-component
model improved model fit on a fraction-arithmetic dataset [18]; and
instruction-tuning an LLM on misconceptions degrades its correct
problem-solving unless the correct-to-misconception ratio is held low, with
0.25 reported as a calibrated value [19]. The second is a direct caution
against any future fine-tune built on the misconception corpus, and it
belongs in the file when that question comes up.

There is also a published precedent for the exact hybrid Hermes could build:
an LLM dialogue tutor that uses constraint-based domain modelling to
constrain LLM-generated feedback, on the stated reasoning that
"incorporating human-written domain knowledge, the system could potentially
reduce the problem of LLMs in generating solutions that may be factually
incorrect" [20]. It is a design paper rather than an evaluation, so it
establishes that the pattern has been tried, not that it works.

---

## 3. Disposition and query formation are two problems, and only one is binding

The repo holds the measurement. From
`docs/research/2026-07-26-mathtutorbench-nine-columns.md`, six items with the
functions held identical and only the wording changed:

| framing | items calling a tool |
|---|---|
| plain tutoring prompt | 0 of 6 |
| "two tools are available … use them when they would help" | 0 of 6 |
| "before replying, check … do not rely on memory" | 6 of 6 |

And four arms on the same 20 scaffolding dev items, scored together in one
reward-model process:

| arm | win rate | calls/item | tool calls |
|---|---:|---:|---:|
| unassisted | 0.45 | 1.0 | — |
| `tutor_ledger`, evidence injected | 0.70 | 2.1 | n/a |
| `agent_tutor`, tools offered | 0.65 | 1.6 | 0 |
| `agent_tutor_mandated`, tools required | 0.50 | 2.2 | 9 |

The document disciplines its own numbers and that discipline must travel with
them: "n=20 and the intervals overlap heavily; none of these differences is
established. What is established is the tool-call count." The win-rate column
should not be quoted without that sentence.

**The disposition finding.** The checkpoint emits well-formed tool calls and
never decides it needs one. Capacity without disposition. That is real and it
is recorded in `scripts/research/mtb_agent_responder.py` as the reason
`MANDATED_CONSULT` exists.

**The finding underneath it, which is the one that should drive work.** When
the mandate produced calls, the calls failed for a different reason. Asked in
mathematical terms, the cluster lookup answers: 13 of 15 topics matched.
Asked as the model formed the query, it matched 0 of 12 — the model sent the
story back (`ignatius friend different`, `located beside river`, `drought
household gallons`) and the lookup abstained correctly every time.

So there are two distinct failures, and they need different fixes:

1. **Disposition.** The model does not decide to consult. Fixable in
   principle by fine-tuning, or removable by not making it a decision.
2. **Query formation.** When it does consult, it queries the narrative rather
   than the mathematics. Not fixable by mandating anything.

**Query formation is binding.** Fixing disposition alone yields more calls
that match 0 of 12. The nine-columns document already draws the conclusion:
"Deriving the topic from the operations already adjudicated would serve the
same rows without the model guessing — which is injection again, aimed
better, and should be described that way rather than as an agent."

That is the sharpest available statement of where the work is, and it is
already written down. This document's contribution is to say that it also
settles the sequencing question, in section 4.

---

## 4. The sequencing decision, evaluated

**The decision on the table.** Strengthen the symbolic side first — breadth,
abstraction, pruning, refactoring predicates — and only then consider
fine-tuning a Gemma-4 E2B-class model. In the owner's words: "while the
symbolic side is still in flux, it seems like a mistake to worry too much
about fine-tuning."

**Verdict: correct, and correct for a stronger reason than the one usually
given.**

### 4a. The moving-target argument is true but under-powered

The argument offered alongside the decision runs: the binding constraint is
query formation; query formation is downstream of the symbolic vocabulary; a
fine-tune against a moving vocabulary bakes in a moving target. Every step is
true. The vocabulary did move in the last wave, and it will move again.

But the argument proves less than it seems to. If query formation is fixed
the way section 3 recommends — by deriving the query from operations already
adjudicated — then the model never forms the query, and there is nothing for
a query-formation fine-tune to learn. The moving-target argument tells you to
wait; it does not tell you what you would be waiting *for*.

### 4b. The stronger argument is structural: there is nowhere for a fine-tune to land

A tool-calling fine-tune produces a model that emits tool calls. The
production server has no surface that would receive them. `call_api_messages`
sends `{"model", "messages"}` and nothing else, at all five call sites. The
only code in the tree that offers functions to a model is
`scripts/research/mtb_agent_responder.py`, a research harness that talks to
Ollama, offers exactly two functions, and exists to measure the disposition
question rather than to serve anyone.

So the fine-tune would train a capability that no route exposes, to solve a
problem (disposition) that is not the binding one (query formation), against
a vocabulary that is still moving. Three independent reasons, and the
structural one holds even if the other two were repaired tomorrow.

### 4c. The positive argument, which matters more than either

LINC is the reason to spend on the symbolic side rather than the model side,
and it is a reason rather than a hedge. If the model's job is parsing and the
symbolic side carries the deduction, then **every hour spent widening what the
symbolic side can decide raises the ceiling for every model that will ever be
attached to it, while every hour spent on model disposition raises nothing if
the parse target is unstable.** StarCoder+ at 15.5B beating GPT-4 with CoT by
10 absolute points on ProofWriter [10] is the published form of that claim,
and the 4B SemEval pipeline [15] is the small-model form.

The put-up-or-shut-up framing is therefore not a detour from the neurosymbolic
research question. It is the neurosymbolic research question, in the only form
the literature has evidence for at this model size.

### 4d. The stability trigger, and a correction to it

"Done" is the wrong bar; the symbolic side will never be done. A measurable
trigger is the right replacement. The version proposed alongside the decision
was: a full wave landing with zero verdict-name changes, zero registry-shape
changes, and no tool-surface edits.

Two objections, then a repair.

*Objection 1: one wave is a weak signal.* Wave scope varies. A quiet wave can
be quiet because it was small, which would fire the trigger for the wrong
reason.

*Objection 2, and this one is serious: as stated, the trigger can never
fire.* The strategy enum is supposed to grow. 219 signatures against 116
input contracts means 103 automata are waiting for contracts, and closing
that gap is the coverage campaign itself. A trigger that treats any change to
the enum as instability would forbid the very work the sequencing decision
calls for.

**PROPOSAL — the repaired trigger.** A fine-tune depends on exactly three
surfaces, and only those three need to be stable:

1. the 17 MCP tool names and their input schemas (`CORE_TOOLS` in
   `hermes/mcp/server.py`);
2. the verdict and status vocabulary appearing in tool output;
3. the strategy-name enum backing `strategy_trace`'s `oneOf` (116 consts on
   2026-07-31, from `automaton_input_contracts.pl`).

The trigger fires when, across **two consecutive landed waves**, those three
surfaces show **no renames and no removals**. Additions are permitted and
expected — growth is not instability, and a trigger that forbids growth
forbids the project.

It should be mechanized rather than remembered: a hash-and-diff check over
those three artefacts, in the style of the existing
`scripts/extract_capability_registry.py --check`, so the trigger fires by
measurement and prints what moved when it does not. Nothing of the kind exists
today.

### 4e. The distinction that actually governs what to do now

The useful cut is not "symbolic work versus model work." It is:

- **Work that assumes a frozen surface** — fine-tuning, tool-call training
  data, anything that encodes today's names into weights. Premature, by 4b.
- **Work that consumes whatever surface exists** — deriving the query from
  already-adjudicated operations, measuring parse faithfulness, learning
  rules from traces. Safe now, because it re-derives itself when the
  vocabulary moves.

That cut is the organising principle of section 5.

---

## 5. Safe now, and what should wait

Ranked. Each item carries the smallest result that would show it was wrong.

### Safe now

**1. Derive the symbolic query from operations already adjudicated.**
Highest value because it addresses the binding constraint identified in
section 3. Consumes the surface rather than assuming it frozen: if verdict
names change, the derivation changes with them and no weights are stale.
Would touch `scripts/research/mtb_agent_responder.py` first, and
`RouteLogic._ground_message` (`hermes/app/routes/logic.py`) if it holds.
*Falsifier:* take the 12 items whose model-formed queries matched 0 clusters,
derive the topic from the operations `check_math_claim` already returned,
re-run the lookup. Fewer than 8 of 12 matching means query formation was not
the bottleneck, and disposition returns as a live question.

**2. PROPOSAL — a constraint layer for the deformation long tail.** The
sibling tradition's actual contribution, aimed at a measured hole. About 99
deformation records out of 5,766 in atlas383 means most lessons have no
runnable deformation. A constraint catches a violation without a runnable
buggy model [1], which is precisely the case CBM was built for. This is
symbolic-side strengthening, so it is what the sequencing decision asks for.
*Falsifier:* author constraints for one operation family where deformation
automata are absent, and check them against the deformation traces that do
exist for a neighbouring family. If the constraints cannot reproduce
classifications the automata already make, they will not carry the tail
either.

**3. PROPOSAL — inductive logic programming against the `default_fill` hole.**
Upstream Popper (Cropper & Morel; SWI-Prolog is already a dependency) learns
Horn clauses from positive and negative examples plus background knowledge.
Target: which deformation a lesson affords. Features already exist as ground
facts — 2,041 task instances over 401 lessons, each with a receipt to a guide
line. Labels exist independently of those features (563
`explicit_lesson_misconception/4` rows, 105 pairing rows), which is what makes
this non-circular. The output is a Prolog clause a teacher-educator can read
and reject, and it needs no model at all.
*Falsifier:* hold out the 3 `hand_authored_chart_lesson/5` lessons, learn from
the rest, and check whether the induced rules recover their charted
deformations. If they do not, stop — and report it, since failure would be a
finding about whether guide text carries the signal.
*Known risk to state in advance:* negatives would come from closed-world
complement over a hand-coding known to be incomplete, so a learned rule is a
proposal for review with its supporting instances attached, never a chart row.

**4. PROPOSAL — per-fact faithfulness scoring for the Gemma extraction pass.**
Imported from the arXiv service-placement paper's RQ2 and from the wider
autoformalization line, where translation correctness is repeatedly the
bottleneck [21]. Build a reference set of typed claims for a small transcript
set and diff pass-1 output fact by fact. Measures the surface; does not assume
it frozen.
*Falsifier:* cannot be falsified, only found uninformative. If faithfulness is
already above 0.95 on 5 transcripts, do not industrialise it.

**5. PROPOSAL — populate MCP `instructions`, and add a `resources` capability.**
Cheapest change available (`hermes/mcp/server.py` `initialize` result).
Correct on its own terms, since the server currently ships no prose about
itself. Ranked last of the safe items because it is exactly the intervention
already measured to do nothing for this model class: "two tools are available,
use them when they would help" produced 0 of 6. The beneficiary is a
large-model client.
*Falsifier for the disposition claim, if wanted:* re-run the 6-item probe with
`instructions` populated. 6 of 6 would overturn the recorded finding.

### Should wait

**6. Fine-tuning an E2B-class model for tool-call disposition.** Three
independent reasons in section 4, the structural one being decisive: no
production route would receive the calls. Xu et al. name post-training as the
path for smaller models [16], but for solver *selection* once formalization is
assumed, which is not the problem here. Revisit when the section 4d trigger
fires and item 1 has failed its falsifier.

**7. Generating tool-call training data.** Same reasoning, one step earlier in
the pipeline, and it would encode today's 17 tool names into a dataset.

**8. Grammar-constrained decoding for tool calls.** Fixes malformed calls.
The checkpoint's calls are not malformed. Constrained decoding has real
results for small models on structure-generation tasks, but that is a
different failure than the one measured here.

**9. Instruction-tuning on the misconception corpus.** Deferred with a
specific published caution attached: this degrades correct problem-solving
unless the correct-to-misconception ratio is calibrated low [19]. If it is
ever attempted, that ratio is a design parameter and not an afterthought.

---

## 6. What would change my mind

- **Item 1 fails its falsifier** (fewer than 8 of 12 derived queries match).
  Then query formation was not the bottleneck, disposition is back on the
  table, and the case for waiting on a fine-tune loses its strongest leg.
- **A production route needs tool calling for an independent reason.** The
  structural argument in 4b is contingent on `call_api_messages` sending only
  `{"model", "messages"}`. If a genuine product requirement adds a tool
  surface, the fine-tune calculus changes that day.
- **A replication at n ≥ 100 puts the mandated arm above the injection arm.**
  The current arms are n=20 with overlapping intervals and establish nothing
  but the tool-call count. A properly powered reversal would overturn the
  injection-first stance.
- **The deformation asymmetry closes on its own.** If deformation roles pass
  roughly 20% of atlas records through automaton authoring, the CBM
  complement (item 2) becomes redundant and should be dropped rather than
  built.
- **The stability trigger fires and nothing downstream wants it.** If the three
  surfaces hold still for two waves and no one can name what the fine-tune
  would do, that is evidence the trigger measures the wrong thing, and the
  trigger should change rather than the plan.

---

## 7. What was checked, and what was accepted on citation

**Verified by execution against the mid-wave working tree on 2026-07-31** (base
commit `befdd71`, uncommitted parallel work present — see the header note):
147 `dispatch_spec/4` rows; 55 `dispatch_irregular/1` ops; the 17-name
`CORE_TOOLS` list; 116 `automaton_input_contract/5` rows; 219
`action_automaton_signature/4` rows; 2,142 `automaton_transition/6` rows with
1,088 `provenance(observed(...))`; 218 `automaton_tuple/6` rows; 105
`productive_*_deformation/3` rows; 1,553 `explicit_lesson_strategy/4` rows;
563 `explicit_lesson_misconception/4` rows;
`compiled_task_instance_summary(401, 2041)`; 3 `hand_authored_chart_lesson/5`
facts; the twelve `incompatibility_order_count/2` values; the four
`research_shared.db` table counts; the absence of `tools`/`tool_choice` in
`hermes/app/llm.py`; the five routes in `hermes/app/routes/llm.py`.

**Verified by reading the file:** the `_handle_chat` grounding comment and
message construction; the `math_claim` converter comment and
`safe_math_claim/1`; `validate_dispatch_spec/0`; the grounded-arithmetic
predicates; `brandomian_incompatibility.pl`'s primitive-incompatibility
header and vacuity guard; the entailment register's earning criterion; the
two trace lists in `sar_add_action_pairs.pl`; the MTB tables and the
"capacity without disposition" section of
`docs/research/2026-07-26-mathtutorbench-nine-columns.md`; the
`MANDATED_CONSULT` block and its comment in
`scripts/research/mtb_agent_responder.py`.

**Read but not re-counted this session:** the atlas383 shard counts and role
distribution, and the `lesson_deformation_chart` provenance wording, both
carried forward from the structural sweep earlier in the session.

**Accepted on citation — abstracts consulted, full texts not read:** all
numbered references below. In particular the LINC figures (38% and 10%
absolute over GPT-3.5 and GPT-4 with CoT on ProofWriter), the Logic-LM
averages (39.2% and 18.4%), the Xu et al. >90% strategy-prediction accuracy,
and the Reddig et al. 35% / 35% feedback figures come from abstracts. The
Reddig denominators are not stated in the abstract and must be pulled from
the full text before either percentage is quoted in a proposal. The
knowledge-component fit result [18] and the 0.25 ratio [19] were supplied as
leads and their abstracts were not independently retrieved.

**Maturity caveats, stated so they are not lost:** the arXiv service-placement
paper referenced in section 5 item 4 is explicitly pre-experimental — no
dataset, no baseline, no number. The `prolog-mcp` prototype examined earlier
in this session is 264 lines with no test file and a performance table with no
harness. Neither should be described as a system that works.

---

## References

[1] [Constraint-Based Student Modeling](https://consensus.app/papers/details/60df3e0f3a4f58eabc5820bfc088c7a5/) (Ohlsson, 1994, 349 citations)
[2] [Constraint-Based Modeling: An Introduction](https://consensus.app/papers/details/0c536041611c5e3ca735e3ac7a7aa9fd/) (Mitrovic & Ohlsson, 2006)
[3] [Using Evaluation to Shape ITS Design: Results and Experiences with SQL-Tutor](https://consensus.app/papers/details/a63f24b521e456d581b27da1d904a4f6/) (Mitrovic et al., 2002, 130 citations, User Modeling and User-Adapted Interaction)
[4] [Fifteen years of constraint-based tutors: what we have achieved and where we are going](https://consensus.app/papers/details/385dd369335d537d9b658ce02a7ee480/) (Mitrovic, 2012, 129 citations, User Modeling and User-Adapted Interaction)
[5] [Experiences in Implementing Constraint-Based Modeling in SQL-Tutor](https://consensus.app/papers/details/63a8690caed25fdd9eb6dcf60b70970b/) (Mitrovic, 1998, 120 citations)
[6] [A Comparison of Model-Tracing and Constraint-Based Intelligent Tutoring Paradigms](https://consensus.app/papers/details/1a48f2a4ef0f58369bfe365f81829d10/) (Kodaganallur et al., 2005, 98 citations, Int. J. Artif. Intell. Educ.)
[7] [An Assessment of Constraint-Based Tutors: A Response to Mitrovic and Ohlsson's Critique](https://consensus.app/papers/details/f84e6a586aff5830b5404760f94e287f/) (Kodaganallur et al., 2006, 15 citations, Int. J. Artif. Intell. Educ.)
[8] [Constraint-Based Modeling: From Cognitive Theory to Computer Tutoring – and Back Again](https://consensus.app/papers/details/20265b1545d5576d95dd28694b28e397/) (Ohlsson, 2016, 28 citations, Int. J. Artif. Intell. Educ.)
[9] [On the ambiguity of constraints for student modelling](https://consensus.app/papers/details/755867b39d65544b88276ddbac99c4d3/) (supplied lead; abstract not independently retrieved)
[10] [LINC: A Neurosymbolic Approach for Logical Reasoning by Combining Language Models with First-Order Logic Provers](https://consensus.app/papers/details/be65fc22ffd05f96b5c8f03f27c66961/) (Olausson et al., 2023, 264 citations)
[11] [Logic-LM: Empowering Large Language Models with Symbolic Solvers for Faithful Logical Reasoning](https://consensus.app/papers/details/48d96a15894e5e8b9859c60ea8f0f774/) (Pan et al., 2023, 585 citations)
[12] [LOGIC-LM++: Multi-Step Refinement for Symbolic Formulations](https://consensus.app/papers/details/e42ed7f7e5e3516ab247bfe5230d7870/) (Kirtania et al., 2024, 25 citations)
[13] [Neuro-Symbolic Integration Brings Causal and Reliable Reasoning Proofs](https://consensus.app/papers/details/f4ce86a45bc853b6ac648689950f3d9b/) (Yang et al., 2025, 31 citations)
[14] [Reliable Reasoning Beyond Natural Language](https://consensus.app/papers/details/e785b836c3dc58e3a1805386aad9c3ff/) (Borazjanizadeh et al., 2024, 17 citations)
[15] [UFAL-CUNI at SemEval-2026 Task 11: An Efficient Modular Neuro-symbolic Method for Syllogistic Reasoning](https://consensus.app/papers/details/581252ea05ad5ed4a5c88f9f6184aa6f/) (Kartáč et al., 2026, 0 citations)
[16] [Adaptive LLM-Symbolic Reasoning via Dynamic Logical Solver Composition](https://consensus.app/papers/details/bb33d7b22a315f2bb375caf3e1d02fdc/) (Xu et al., 2025, 6 citations)
[17] [Generating In-Context, Personalized Feedback for Intelligent Tutors with Large Language Models](https://consensus.app/papers/details/0eb8ad5628fe5da6aa31899c5a12ce0c/) (Reddig et al., 2025, 17 citations, Int. J. Artif. Intell. Educ.)
[18] [Knowledge-component model incorporating a misconception, fraction arithmetic](https://consensus.app/papers/details/ca66e12cbf555e70a8908a5be565b250/) (supplied lead; abstract not independently retrieved)
[19] [Instruction-tuning on misconceptions and the correct-to-misconception ratio](https://consensus.app/papers/details/79f3c432041a54d5ad08f84c9aa764df/) (supplied lead; abstract not independently retrieved)
[20] [Designing an LLM-Based Dialogue Tutoring System for Novice Programming](https://consensus.app/papers/details/54d3495a3b7d57bf9c3d92ce4743858e/) (Perez et al., 2024, 6 citations, ICCE)
[21] [Automated Theorem Provers Help Improve Large Language Model Reasoning](https://consensus.app/papers/details/138f6108e21555ba92260e831b4e12f0/) (McGinness et al., 2024, 11 citations)

Further context consulted this session but not cited above: a design-patterns
/ boxology vocabulary for LLM neurosymbolic systems, and Scallop (Datalog with
provenance semirings), both supplied as leads for placing Hermes in a
taxonomy. Neither was read; both remain open.
