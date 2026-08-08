# Neurosymbolic ceiling study: what would have to change before 100% is a meaningful target

Date: 2026-08-06

## Scope and conclusion

No measured architecture in this tree supports a claim that Hermes can reach
100% on the tutoring benchmarks. The remaining errors do not form one arithmetic
gap. They divide into disposition, extraction, quantity modelling, exact
location, and pedagogical response generation. The smallest architecture that
addresses the first of those is disposition-free: the system always runs the
symbolic pass on mathematical student work, while an E2B- or E4B-class model is
limited to constrained extraction and response wording.

This report treats E2B/E4B as the tutor-facing hardware boundary specified by the
brief. The existing laptop claim is narrower: the E2B checkpoint is 5.1B at
Q4_K_M, 7.2 GB, and was run through Ollama on one laptop
(`docs/research/2026-07-26-mathtutorbench-nine-columns.md:3-12`). The E4B scripts
preserve the E2B serving configuration so the comparison varies model size, but
they do not establish a laptop benchmark result
(`hermes/app/runtime/experiments/gemma4_tutor/run_mistake_location_naked_e4b_resume.slurm:12-25`).
Larger models remain diagnosis-side controls: the held-out diagnosis artifact
records 0.3894 for 31B against a 0.2853 majority floor, while the E2B held-out
artifact records 0.2996 against the same floor
(`hermes/app/runtime/experiments/gemma4_tutor/runs/diagnosis-heldout-reallms31b/summary-diagnosis.json:2-18`;
`hermes/app/runtime/experiments/gemma4_tutor/runs/diagnosis-heldout-e2b/summary-diagnosis.json:2-19`).

## 1. Failure decomposition

### 1.1 Tutor-turn generation: scaffolding and pedagogy following

The one-pass E2B baseline on the stored 360-item scaffolding slice is 165/360,
or 0.4583. The iterative arm is 282/360, or 0.7833, but it bundles retrieval,
structured notes, iteration, response constraints, and substantially more model
calls. It is an architecture-level contrast, not an isolated symbolic effect
(`hermes/app/runtime/experiments/gemma4_tutor/runs/fleet_report.json:41-50,63-72`;
`.superpowers/sdd/task-215-report.md:14-24`). On the later held-out run, the four
generation win rates were 0.313, 0.380, 0.357, and 0.511; their constant-response
floors were not measured, and their mean reward margins all favored the human
turn (`docs/research/2026-08-01-mathtutorbench-heldout-with-floors.md:179-190,223-238`).

Remaining loss:

- **Disposition and query formation.** Optional tool access did not cause
  consultation. The model used tools only under an explicit mandate, and its
  story-shaped queries matched 0 of 12 where mathematical topic queries matched
  13 of 15 (`docs/research/2026-07-26-mathtutorbench-nine-columns.md:264-293`).
- **Pedagogical generation.** The symbolic evidence can constrain what is said,
  but the reward-model columns assess the teacher turn. Exact arithmetic does
  not by itself select a useful next question.
- **Metric uncertainty.** The four generation columns have no measured
  input-insensitive floor in the stored run. They must not be treated as direct
  probabilities of pedagogical correctness.

The 0.4583 value is an unassisted model baseline, not a mathematical floor.

### 1.2 Problem solving and solution correctness

On the 300-item held-out prefix, E2B reached 0.880 problem-solving accuracy and
0.807 solution-correctness F1, with solution-correctness accuracy 0.817. The
sample-specific always-Yes F1 floor was 0.681
(`docs/research/2026-08-01-mathtutorbench-heldout-with-floors.md:179-186`). The
benchmark construction makes solution correctness reducible to independently
solving the problem and comparing final answers; it does not test whether a
different correct route is sound
(`docs/research/2026-07-26-mathtutorbench-nine-columns.md:204-214`).

Remaining loss:

- **Quantity modelling and extraction.** The solver must decide what the story's
  quantities mean before arithmetic can help. The repository's concrete example
  is `45/(5+3) = 5.625`: the arithmetic is exact, but 45 counts only the red
  candles (`docs/research/2026-07-26-mathtutorbench-nine-columns.md:156-164`).
- **Transport starvation.** A correct internal derivation is unavailable when
  the final channel is empty or length-truncated. This is a control-flow failure,
  not evidence for or against the mathematical model.
- **Limited adjudication reach.** In the matched assisted arms, the checker saw
  68, 56, 46, and 64 equations and refuted 0, 1, 2, and 0 respectively
  (`hermes/app/runtime/experiments/gemma4_tutor/runs/mtb-assisted-40/run.log:39,80,119,152`).
  Widening arithmetic syntax does not address steps that assert a wrongly
  modelled quantity through otherwise valid arithmetic.

The earlier claim that Prolog adjudicated 99% of extracted equations is present
in prose, but the repository's later audit says its counters were written to
uncaptured stderr and no artifact survives. It is therefore not used here as a
measured result
(`docs/research/2026-08-01-mathtutorbench-heldout-with-floors.md:343-360`).
What survives is narrower: the arithmetic route is broad by construction, while
the benchmark loss is usually outside an explicit arithmetic contradiction.

### 1.3 Mistake detection versus exact mistake location

The full 2,004-item artifacts separate two abilities that micro-F1 collapses.
Counting only the stored target and prediction fields:

- Naked E2B correctly classified whether an error existed on 1,573/2,004 items,
  but named the exact target on 1,237/2,004, the reported 0.6173. It accused an
  erroneous solution 817 times, landed on the exact step 481 times, and accused
  246 correct solutions.
- Naked E4B correctly classified whether an error existed on 1,761/2,004 items,
  but named the exact target on 1,424/2,004, the reported 0.7106. It accused an
  erroneous solution 896 times, landed on the exact step 559 times, and accused
  137 correct solutions.

These aggregates are derived directly from
`.bigred-collected/2026-08-04-naked-e2b/mistake_location.jsonl` and
`.bigred-collected/2026-08-04-naked-e4b/mistake_location.jsonl`; the official
micro-F1 summaries are at
`.bigred-collected/2026-08-04-naked-e2b/summary.json:2-10` and
`.bigred-collected/2026-08-04-naked-e4b/summary.json:2-10`.

The graph did not close the location gap. The E2B graph filter scored 0.4686;
running a second neural locator only on its 233 accusations raised the pipeline
to 0.5205. Running that same second stage over all 2,004 items, with the graph
filter disabled, reached 0.5858
(`.bigred-collected/2026-08-04-stage2-e2b/summary.json:2-19`;
`.bigred-collected/2026-08-04-pureneuro-e2b/summary.json:2-19`). E4B shows the
same direction: graph-only 0.5274, graph-plus-second-stage 0.5389, naked E4B
0.7106
(`.bigred-collected/2026-08-04-graph-think-e4b/summary.json:2-10`;
`.bigred-collected/2026-08-04-stage2-e4b/summary.json:2-19`;
`.bigred-collected/2026-08-04-naked-e4b/summary.json:2-10`). A graph veto is
also too blunt: it retracted 979 E4B accusations, including 528 exact hits, and
reduced accuracy from 0.7106 to 0.5115
(`.bigred-collected/2026-08-04-graph-veto-e4b/summary.json:2-22`).

One earlier official task-object arm, `prolog_subtract`, scored 0.498503 on all
2,004 items, just below the always-0 floor of 0.500
(`.bigred-collected/2026-08-02-mistake-location/summary.json:2-10`;
`docs/research/2026-08-01-mathtutorbench-heldout-with-floors.md:15-20`). It was
not a naked unassisted arm, so it should be named by its responder rather than
folded into the later naked E2B result.

Remaining loss: error existence is easier than exact location; exact location
requires faithful step extraction and a quantity relation that distinguishes the
student's step from a correct one. The current graph is useful evidence but has
insufficient recall to serve as a filter or veto.

### 1.4 Mistake correction

The held-out E2B arm reached 0.677 on 300 items
(`docs/research/2026-08-01-mathtutorbench-heldout-with-floors.md:179-186`). In the
matched 40-item experiment, the assisted correction arm checked 64 equations,
refuted none, and moved only one item over the unassisted arm in its first run;
the replicate reversed the direction
(`docs/research/2026-07-26-mathtutorbench-nine-columns.md:106-121`;
`hermes/app/runtime/experiments/gemma4_tutor/runs/mtb-assisted-40/run.log:152`).

Remaining loss is inherited from solving and location: a correction cannot be
reliable when the system has modelled the wrong quantities or located the wrong
step. Exact arithmetic is a guard on explicit claims, not a correction policy.

### 1.5 Socratic questioning

The held-out E2B result was BLEU 0.230 against a measured constant-question
floor of 0.132. It tied the lowest published row in the comparison recorded by
the repository
(`docs/research/2026-08-01-mathtutorbench-heldout-with-floors.md:179-182,208-216`).

Remaining loss is mainly response selection and reference sensitivity. A
symbolic receipt can state what is licensed, but it does not determine which
short question resembles the benchmark's references.

### 1.6 Seven-way diagnosis

This is a repository-defined task over StepVerify, not an official
MathTutorBench column. Held-out E2B reached 0.2996 against a 0.2853 majority
floor; on the two quantity categories it reached 0.0725
(`hermes/app/runtime/experiments/gemma4_tutor/runs/diagnosis-heldout-e2b/summary-diagnosis.json:2-19`).
The Prolog-assisted dev arm reached 0.2924 against a 0.2890 floor, did not differ
from unassisted, and formed 327 goals. Every goal was an arithmetic check; the
model chose the misconception corpus probe zero times
(`docs/research/2026-08-01-diagnosis-prolog-arm.md:21-38,46-70`).

Remaining loss:

- **Disposition.** The misconception probe existed and was never selected.
- **Extraction and query formation.** The model repeatedly formed arithmetic
  goals for errors caused by reading the problem.
- **Quantity modelling.** The quantity categories are the E2B arm's weakest
  measured slice, not a solved special case.
- **Category adjudication.** An `ok` arithmetic result does not distinguish the
  seven diagnosis labels.

### 1.7 Strategy recognition as the extraction benchmark

The repository's recognition benchmark reads literature-language rows much
better than student-language rows: literature recall@1 is 89.9%, student recall@1
is 6.5%, and 107 of 139 student rows abstain
(`docs/research/2026-07-25-recognition-benchmark.md:3-22`). After the later
discrimination repair, held-out negative abstention rose to 0.977 and no negative
reached `partial_trace`, but student-prose top-1 remained 0.042
(`docs/research/2026-08-01-strategy-recognize-discrimination.md:282-301,338-348`).

Remaining loss is student-register extraction. The executable strategy inventory
is not the binding limit when ordinary student descriptions do not route to it.

## 2. Transport and thinking-budget constraints

The architecture must treat response transport as typed control flow. The shared
REALLMS client now distinguishes `ok`, `empty_content`, `truncated`, HTTP failure,
and transport failure. A length-finished response is retained only for diagnosis;
the string wrapper returns an empty string and never substitutes reasoning text
(`hermes/app/llm.py:214-254,324-360`). Requests carry an explicit token budget,
defaulting to 8,192 (`hermes/app/llm.py:15-24,363-389`).

The stored smoke demonstrates the starvation shape: at a 100-token budget the
service put unfinished reasoning in `content`, returned `finish_reason: length`,
and the client classified it `truncated`
(`hermes/app/runtime/experiments/reallms_transport_smoke/2026-08-05/02_starvation_leak.json:1-16,35-59`).
The held-out E2B run shows a second channel asymmetry: median decoded tokens were
894 for mistake location and 648 for solution correctness, while the parser saw
one and two final-channel characters respectively
(`docs/research/2026-08-01-mathtutorbench-heldout-with-floors.md:128-155`).

Consequences for every candidate below:

1. only an `ok` final channel may become a fact or answer;
2. empty and truncated extraction produce named abstention, not a default fact;
3. token budgets and retry bounds travel in the receipt;
4. reasoning text may be retained for diagnostics but never promoted to a
   student-facing answer or symbolic assertion.

## 3. Architecture candidates

### Candidate A — mandatory typed quantity compiler

**Claim.** The largest remaining assessment and diagnosis loss is the missing
quantity model. If every mathematical turn is compiled into typed quantities,
relations, operations, and source spans before any response is generated, the
symbolic core can adjudicate the thing it currently misses. E4B is the preferred
parser within the hardware ruling; E2B remains a cheaper fallback. Neither model
decides whether the compiler runs.

**Component.** Reuse the construction-only structured decoders and their live
input contracts, `hermes/quantity_claim.pl`, `check_math_claim`,
`check_solution_steps`, and `strategy_trace`. The current decoder work reports
246 registered contract pairs with no gap
(`.superpowers/sdd/task-2026-08-06-decoders-report.md:5-11,15-52`).
`quantity_claim.pl` already accepts typed expression trees, preserves verbatim
source spans, returns `not_checked` for unbound quantities, and centralizes kind
arithmetic (`hermes/quantity_claim.pl:20-40,76-98,134-177`). What is missing is a
general problem-and-solution compiler into that vocabulary.

**Cheap falsifier.** On paired correct and incorrect solutions, the compiler
either fails to bind the decisive quantities or produces similar contradiction
rates on both sides. A correct-solution false accusation is decisive evidence
against the current extractor even if it sometimes names the benchmark's target
step.

**Cheating to refuse.** Supplying a reference solution, final answer, incorrect
step index, diagnosis label, or a per-item kind map derived from those labels;
routing by benchmark column; adding benchmark-specific phrases to the compiler
after inspecting failures.

### Candidate B — mandatory parallel branch ensemble with local adjudication

**Claim.** Quantity structure is necessary but not sufficient. Every applicable
symbolic branch should run under a system policy, and an E4B adjudicator should
compare their typed receipts with the original question. This attacks
adjudication reach without asking one small model to invent the right query or
choose one branch.

**Component.** Reuse the branch carving, generated MCP schemas, exact tool-call
validation, trace collection, and retry ledger in
`hermes/mcp/branch_agents.py`. Its syntax catalog generates instructions from
live schemas and strategy contracts (`hermes/mcp/branch_agents.py:272-336`), and
its executor records the call, raw verdict, trace, and adjudication
(`hermes/mcp/branch_agents.py:517-595`). Change only the control rule: replace the
model-selected dispatch at lines 459-482 with deterministic fan-out over
applicable branches. Quantity, arithmetic, and student-work recognition branches
run whenever their required fields are present. Retrieval-only branches may
abstain. The adjudicator cannot suppress receipts; it can only state which ones
bear on the original question.

**Cheap falsifier.** On a non-scored paired corpus, the extra branches yield no
additional executable, span-grounded distinctions over Candidate A, or the
adjudicator accepts a verdict for a different question. Either result rejects
the added complexity.

**Cheating to refuse.** One agent per benchmark label; target-informed branch
selection; prompts that name the correct diagnosis category; an adjudicator that
receives the reference answer or teacher turn; hiding conflicts or abstentions
from the final ledger.

### Candidate C — graph proposals without graph filtering or veto

**Claim.** The deformation graph may still be useful as a bounded proposal
source if it supplies zero or more candidate machines to Candidate B and never
removes a neural or quantity-based hypothesis. Its contribution would be a
source-cited deformation trace, not authority over whether an error exists.

**Component.** Reuse the full-graph MCP tools and the `graph_only` catalog
renderer. The graph surface exposes machine states, edges, canonical actions,
stance, and provenance without starting Prolog
(`.superpowers/sdd/task-2026-08-04g-graph-mcp-report.md:3-32,86-110`). Retain
multiple candidates with their source spans. Do not reuse the existing hard
filter or veto decision.

**Cheap falsifier.** On stored student-work rows, the correct deformation family
is absent from the bounded proposal set often enough that the added branch cannot
improve any receipt. The existing full-corpus filter and veto results are already
strong negative evidence: both discarded useful neural location signal.

**Cheating to refuse.** Building the graph from benchmark labels, selecting a
machine with the target step, adding a machine because a benchmark item needs it,
or treating shared canonical actions as proof that two student doings are
equivalent.

### Candidate D — deterministic fact packet before tutor generation

**Claim.** For scaffolding, pedagogy following, and Socratic questioning, a
small model should receive a compact packet of accepted facts, refusals, and
unresolved items before it writes a teacher turn. This does not solve diagnosis;
it prevents the generator from having to rediscover what upstream components
already established.

**Component.** Production chat already retrieves before generation and renders a
bounded vocabulary of strategies, misconceptions, standards, geometry,
metaphors, and literature-derived incompatibilities
(`hermes/app/routes/logic.py:309-335,382-425,796-825`). Make that pass mandatory
for student-work routes and add the typed quantity and branch receipts from A or
B. Preserve `not_checked`, `unsupported`, and transport failures as first-class
facts. E2B or E4B then writes the response under a short, fixed output contract.

**Cheap falsifier.** A blinded comparison on an existing non-benchmark transcript
corpus finds no increase in source-grounded next questions, or the fact packet
causes the generator to repeat internal labels and verdicts rather than respond
to the student.

**Cheating to refuse.** Supplying the human teacher turn, reference solution, or
reward-model preference; retrieving by target answer; benchmark-shaped response
templates; silently dropping abstentions so the packet appears complete.

## 4. The disposition problem

The diagnosis arm makes the problem explicit: a misconception probe was offered
and selected 0 times across 327 formed goals. The smaller six-item tool probe
shows the same shape: 0/6 under a plain prompt, 0/6 when told tools were available
and useful, and 6/6 under a direct mandate
(`scripts/research/mtb_agent_responder.py:95-121`). The model can form a function
call. It does not reliably decide that consultation is needed.

Existing forcing mechanisms are not equivalent:

1. **Structured decoders** force a finite JSON shape into typed Prolog operands.
   They remove free-form term construction but do not decide when a decoder is
   invoked.
2. **Mandated tool prompts** force a call, but they leave query formation to the
   model. The 0-of-12 story-query result shows why this is insufficient.
3. **The gated MCP protocol** restricts a branch model to one listed tool and a
   validated schema, then records the verdict and retries. It still uses a model
   for initial dispatch unless a caller supplies the branch
   (`hermes/mcp/branch_agents.py:459-487`).
4. **The production fact vocabulary** retrieves symbolic facts before generation.
   This is the closest existing disposition-free mechanism, although the present
   route is best-effort and may continue ungrounded.

The smallest disposition-free architecture is therefore:

```text
student work
  -> forced structured extraction
  -> typed fact ledger with source spans
  -> deterministic applicability rules
  -> run every applicable symbolic checker
  -> retain verdicts, refusals, conflicts, and transport outcomes
  -> E2B/E4B writes a bounded tutor response from that ledger
```

The system's trigger is simple: every route that contains mathematical student
work runs the extraction and applicability pass. The model never emits a tool
call, chooses a branch, or decides that checking would help. A model may still be
used inside the forced extractor, so extraction fidelity remains a measured
liability. An incomplete parse yields `not_checked`; it does not skip the pass or
manufacture a fact.

This removes disposition. It does not remove extraction, quantity modelling, or
adjudication limits, and it should not be described as doing so.

## 5. One decidable next experiment

Compare Candidate A with Candidate B on the existing frozen 60-index quantity
corpus and its paired correct solutions. The index set is already recorded at
`scripts/research/quantity_binding_out/summary.json:2-66`. Do not invoke the
MathTutorBench runner, task parser, reward model, or official metric.

Protocol:

1. For each index, pass only the visible problem and one solution to each arm.
   Run both the incorrect solution and its paired correct solution. Keep the
   final answer, incorrect-step index, category label, and human teacher turn out
   of every prompt, tool call, and routing decision.
2. Candidate A runs the mandatory typed quantity compiler and its deterministic
   checks. Candidate B receives the identical quantity output and adds forced
   arithmetic, strategy/deformation, and misconception-retrieval branches. Use
   E4B only for the constrained parses or adjudication that require a model.
3. A **licensed differentiating receipt** must contain a verbatim source span, a
   registered typed operation or tool call, and a non-`not_checked` verdict that
   appears on the incorrect solution but not its paired correct solution. Count
   these receipts without using the labelled target step.
4. Record correct-solution accusations, licensed differentiating receipts,
   empty/truncated parses, model calls, and tokens. Preserve every abstention and
   conflict.

Decision rule, fixed before the run:

- first prefer the arm with fewer correct-solution accusations;
- if tied, prefer the arm with more licensed differentiating receipts;
- if still tied, prefer the arm with fewer model calls and tokens.

This is not a benchmark run: it produces no task accuracy, micro-F1, reward-model
score, or leaderboard comparison. It decides whether parallel symbolic reach
adds anything over the typed quantity compiler before another benchmark is
justified. If neither arm produces paired distinctions without false
accusations, both candidates are falsified at the extraction seam.

One existing path must be excluded explicitly. `HUMAN_KIND_MAP` was authored
from the problems and labelled first-wrong steps, so using it would route target
knowledge into the extractor
(`scripts/research/quantity_binding_probe.py:43-48`). The experiment may reuse
the frozen texts and indexes, but not that map or any stored target-bearing
binding artifact.

## Decision

Candidate A is the top candidate because it removes disposition with the fewest
moving parts and targets the measured quantity-modelling loss. Candidate B is
second because it broadens adjudication reach while preserving the same forced
quantity pass. Candidate C remains a proposal-only evidence branch because the
measured filter and veto forms lost signal. Candidate D is the response layer to
evaluate after A or B produces trustworthy receipts.

No architecture here earns a 100% forecast. It defines a path on which each
remaining failure has a named stage, a cheap falsifier, and an explicit leakage
boundary.

IMPLEMENTATION_COMPLETE
