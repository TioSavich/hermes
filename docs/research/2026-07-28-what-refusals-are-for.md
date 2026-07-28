# What refusals are for — a census, a carving, and the true/false answer

2026-07-28. Every count below was measured against the live tree today; where a
number depends on what its reader believed about the rows it counted, that
belief is stated beside it. Nothing is inherited from the commissioning brief:
where the brief's numbers and today's tree disagree, today's tree is cited and
the disagreement named.

One number to correct at the outset: the brief carried "42 true/false spans
across 41 lessons" from the task-158 report, whose readers ran before commit
`8324adf` landed the expression recovery. At HEAD the same question answers
41 spans across 40 lessons. The task-158 report was right about its tree; this
report is about this one.

## The carving

Six kinds of refusal are in the tree, and they differ in what should happen
next. A seventh row is included because testing the thesis exposed it, and it
is the inverse of a refusal: an acceptance that should have been one.

| # | Kind | Count (measured today) | Disposition |
|---|------|--------|-------------|
| 1 | Judgement spans over stated claims | 85 span rows, 80 lessons | **Stalled input.** The consuming vocabulary exists; the consumer does not. |
| 2 | Prompts that state no computation | 225 question-only rows (of 401 `quantities_carry_no_operand_pair`); 794 `prompt_states_no_computation` | **Terminal, correctly typed.** Consumed as absence receipts. |
| 3a | Receipts rejected on reading | 59 gate-accepted keys absent from the merged register (22/13/11/13 across passes 1–4) | **Terminal as receipts.** Their patterns are already harvested into the drafting prompt. |
| 3b | Model abstentions with stated reasons | 22 in pass 4 | **Stalled input in one respect:** several reasons name strategy-vocabulary boundaries, and the reasons live only in `run_report.json`. |
| 4 | Identity-drift refusals | 124 spans across 93 lessons | **Correct refusal that discards its own evidence.** The recovered text is thrown away at refusal time. |
| 5 | Counterexampled vocabulary upgrades | 2 (the LX refusals) | **Terminal as proposed edges.** Each names the machine that would earn an honest L. |
| 6 | Duplication refusal | 1 (`equal_groups`, task 158) | **Terminal-correct; a controller decision is pending**, not a refusal to keep. |
| 7 | Truncating acceptance (not a refusal) | reader defect, measured below | **Defect.** The claim reader emits confident fragments where a refusal would be correct. |

### Kind 1: judgement spans over stated claims

Reader belief: a `task_span_receipt/4` row counts if the lowercase string
"true or false" occurs in its cited physical line range read from the live
guide file, or in its recovered/tracked text in
`curriculum/im/generated/recovered_task_spans.json`. The cited ranges include
the right-column teacher notes, so a handful of rows may carry the phrase in
Launch text rather than the student statement; the recovered texts are
student-facing and clean.

By registry status: 41 in `coverage_gap(no_task_grammar_for_quantity_pair)`
(40 lessons), 38 in `broken_pipeline(void_operand_slots)`, 3 in
`broken_pipeline(imperative_without_quantity)`, 2 in
`not_applicable(quantities_carry_no_operand_pair)`, 1 in
`coverage_gap(no_task_grammar_for_single_quantity)`. 28 of the 85 have their
drawn equations decoded back into text by the recovery pass — the false claims
already exist as text in the tree, e.g. `IM-G1-U5-L11`: "Decide if each
statement is true or false. … 24 + 3 = 54 … 42 + 5 = 47 … 42 + 30 = 45".

Across the 80 lessons: 50 lack `structured_negative`; readiness distribution
is 62 `strategy_attached`, 8 `diagnostic_ready`, 5 `event_ready`, 5
`standard_action_candidate`. Exactly one (`IM-G4-U7-L2`) is missing only
`structured_negative`, and its true/false content is geometric card-sorting,
not stated arithmetic claims — so no honest proposal below promises any
`diagnostic_ready` movement today.

The refusal itself held corpus-wide: **zero** of the 1,691 compiled task
instances cite a position that is a true/false span. No false statement was
strip-mined into a task. The implementer's judgement is enforced everywhere,
not just where it was argued.

### Kind 2: prompts that state no computation

Verified exactly: 225 of the 401 `not_applicable(quantities_carry_no_operand_pair)`
rows carry `quantities(>=2)`, `computational_demand(false)`,
`printed_arithmetic(false)`, `void_slots(0)`, `question_mark(true)` — the
question-mark-only population commit `24bd8be` retyped. These are terminal for
task compilation and they are not unconsumed: the registry row with its
evidence list is their consumption. Whether "What do you notice?" prompts are
input to some future discourse vocabulary is a different question with no
present machinery behind it, and this report declines to manufacture a queue
for it.

### Kind 3: rejected receipts and abstentions

The merged register (`scripts/curriculum/lesson_negative_receipts.json`,
schema v3) holds 109 receipts. Measured at the `(lesson, alternative)` key
level, gate-accepted receipts absent from it: pass 1: 22 of 73, pass 2: 13 of
68, pass 3: 11 of 22, pass 4: 13 of 18. The pass-4 figure matches the brief's
"13 of 18 rejected on review today," but note what is and is not in the tree:
pass 3's review is recorded (`pass3/review_decisions.json`: reviewed 22, kept
6, rejected 16); pass 1's lives in the session memory (22/17/34); **no review
record for pass 2 or pass 4 exists in the tree** — for those, key-absence from
the merged register is the only durable evidence, and it undercounts
rejections when another pass merged a receipt with the same key.

These rejects are terminal as receipts. Their residual value was already
extracted: the rejection patterns moved into the drafting prompt and took keep
rate 53% to 72% (memory: `receipt-drafting-what-works`). What is *not*
extracted: pass 4's 22 model abstentions carry stated reasons, and several
name the same fact from different lessons — the strategy vocabulary has no
automaton for the mathematics the lesson does (signed multiplication,
reciprocal-based equation solving, ratio work). Those are correct refusals
whose reasons constitute a small census of vocabulary boundaries, currently
held nowhere but one run report.

### Kind 4: identity-drift refusals

`scripts/curriculum/build_recovered_task_spans.py` refuses per-span when the
recovered text's word signature differs from the tracked markdown's: 124 spans
across 93 contributing lessons. The refusal is correct — it protects every
physical-line citation in the tree — but the code discards the recovered text
at the moment of refusal and keeps only the position name
(`spans_refused_drifted`). A refusal that destroys its own evidence cannot be
re-adjudicated without rerunning the whole recovery. The fix is retention, not
relaxation.

### Kinds 5 and 6: counterexampled upgrades and duplication

The two LX refusals (memory: `lx-refusals-with-counterexamples`) are terminal
as proposed edges and productive as results: explication-without-elaboration
is a real Brandomian status that is not LX, and `smr_div_long` truncates at
`max_decimal_digits(4)` so 1/32 is indistinguishable from 1/3 — not a tuning
problem, since termination detection needs remainder tracking, a machine the
repo does not have. The refusal names the machine that would earn the L.

The `equal_groups` refusal (task 158, `IMPLEMENTATION_BLOCKED`) is
terminal-correct: three promoted parsers
(`equal_groups_pronoun_each`, `equal_groups_each_has`,
`equal_groups_each_contains`, verified in
`scripts/curriculum/compile_action_mappings.py`) already route the family. The
open item is the controller's re-scope question, a queue entry rather than a
refusal.

## The thesis, measured

The thesis: a true/false item is a judgement about a claim, and the repo
already has a vocabulary for claims. **The first half is established. The
second half is established for the claim layer and refused for the deontic
scoreboard as a direct landing place.**

### What already works, run today

`hermes/math_claim_checker.pl` exposes `check_math_claim/2`, dispatched as the
worker tool `check_math_claim` and reachable over MCP. Handed the three claims
from `curriculum/im_teacher_guides/grade3/unit3/lesson9.md:95-103` as terms,
it adjudicates all three correctly with traces:

```
arithmetic_equation(4*5, 5*4)        -> holds
arithmetic_equation(125+200, 200+125) -> holds
arithmetic_equation(300-100, 100-300) -> refuted
```

The worker's intake (`safe_math_claim_shape/1`, `hermes_worker.pl:1826`)
accepts `arithmetic_equation/2` with compound expressions on both sides,
including negatives. The judgement vocabulary the true/false routine needs —
a claim, a verdict, a trace — exists and is live.

### What does not work, run today

`hermes/math_claim_language.pl` (`math_claims_in_text/2`) is the only route
from span text to claim terms, and it has three measured boundaries. All 85
true/false spans were run through it with their exact text; 41 spans yielded
100 claims, 75 refuted and 25 holding. **Those verdict counts cannot be
believed**, for reasons the run itself exposed:

1. **No expression-equals-expression production.** `expression_equation`
   (line 683) requires a single value or parenthesized expression on the
   right. `4 x 5 = 20` parses; `10 + 4 = 7 + 3 + 4` and
   `300 - 100 = 100 - 300` return nothing. The checker accepts the shape the
   reader cannot produce.
2. **Typographic operators orphan their left operand.** `4 × 5 = 20` (the
   multiplication sign the guides actually print) parses to
   `arithmetic_equation(5,20)` and is *refuted* — a true claim mis-adjudicated
   because × is not a token the grammar recognizes and the fragment parse is
   emitted anyway. Measured on the corpus: `IM-G3-U4-L17`'s four claims
   (`2 × 40 = 2 × 4 × 10`, three of them true) all came back refuted as
   fragments like `arithmetic_equation(40,2)`. This is row 7 of the carving:
   where the task compiler refused, the claim reader accepts and misrepresents
   — precisely the outcome the task-158 implementer refused to produce.
   Runtime consumers of this grammar (`hermes/solution_step_check.pl` and
   `hermes/encyclopedia.pl` via `math_readings_in_text/2`,
   `scripts/research/local_neurosymbolic_loop.py` via `math_claims_in_text/2`)
   inherit the defect wherever their input carries × or ÷;
   `knowledge/index/research_measurement_registry.pl` names the check script
   in receipts but does not run the reader.
3. **List separators decide parseability.** Bullet- and semicolon-separated
   equation lists parse; newline- and period-separated lists return nothing.
   The tracked markdown separates equations by newlines.

### Where the guides supply the other half

The guides print sanctioned verdicts with grounds, in their own voice, in the
Student Response block. `grade1/unit8/lesson5.md:89-104`:

> • 57 + 20 = 59 … • 66 − 4 = 62 … • 17 + 76 = 59
> **False**: 59 is 2 more than 57, not 20 more. **True**: 6 − 4 is 2 …
> **False**: The sum can't be less than 76.

The checker's verdicts on those three (refuted, holds, refuted) agree with the
guide's. That agreement is the gate a claim compiler gets for free: two
independent sources per claim, the grounded checker and the curriculum's
printed answer, with disagreement as a quarantine signal. The recovery pass
supplies a live example of why the gate is needed: `IM-G5-U2-L11`'s decoded
text carries `10 ÷ 3 = 101/3`, a decode artifact (the PDF's mixed number
`10 1/3` collapsed), which no single-source pipeline would catch.

### Where true/false spans do not land

**Not the deontic scoreboard, today.** `formal/learner/deontic_scorekeeper.pl`
contains no reference to the claim checker (verified by search). Its
`incompatible/2` covers `result_of` conflicts, explicit `P`/`not(P)` pairs,
and registry-backed misconception pairs; nothing derives `not(Claim)` from a
checker refutation. More decisive than the missing wire: the scoreboard
consumes an *agent's* commitments, and a curriculum span is nobody's
commitment. The span states a claim; a *student endorsing it* would be the
scoreboard's input. No producer of endorsement events exists in the tree, so
building the bridge now would be aspirational accumulation. The bridge is
named in the proposals as deferred, with its exact clause, for when the dialog
runtime produces endorsements.

**Not the error-rule triples.** The 90 `material_inference` rows in
`formal/incompatibility/error_rule_inferences.pl` live at the granularity of
rules and divergence contexts coded from research literature, not stated
equations. A student endorsing `300 − 100 = 100 − 300` is plausibly running a
rule in that family's *spirit* — `rule_subtract_the_smaller_from_the_larger`
exists among the 90 — but its coded divergence context is
`the_problem_asks_for_a_quotient`, and no commutativity-of-subtraction rule
was coded. The true/false corpus is potential future *coding input* for that
pipeline, not present join material.

**Not the negative-receipt register as schemed.** `_validated_negative_receipts`
(`scripts/curriculum/build_lesson_evidence.py:327`) requires each receipt's
`intended_action` to be an (operation, kind) already mapped for the lesson and
an `alternative` naming a deformation. A printed false equation carries
neither. Forcing it into that schema would borrow bookkeeping the content does
not have; the honest holder is a register of its own, which the evidence
builder can then union as a third `structured_negative` source.

### The verdict

A true/false span is natural input to the **claim layer** — reader, checker,
and a register that does not yet exist — and the corpus of curriculum-stated
false equations has exactly the value the commission suspected: each is a
sanctioned negative example, cited to physical lines, in the curriculum's own
voice, with the guide's ground for rejection printed beside it. The repo's 90
error rules were mined from research literature at rule granularity; this
corpus is instance-granular and needs no mining, only a reader that refuses
fragments. The measured floor today is 35 spans carrying at least one
checker-refuted claim; that number is contaminated in both directions by the
reader defects above, and the honest corpus size is measurable only after the
reader repairs land. No proposal below cites a projected size.

## Telling stalled from terminal without re-adjudicating

A refusal is **stalled pipeline input** when its receipt names content the
tree still carries and a vocabulary that exists without a consumer: true/false
spans (claims exist, checker exists, no compiler), abstention reasons (stated,
held only in a run report), drifted spans (the one kind whose receipt
*destroys* the content, which is why retention is proposed).

A refusal is **terminal** when its receipt states a property of the text
(no quantities, no stated relation), a counterexample (the LX pair), or a
duplication (equal_groups). Terminal refusals are consumed by being recorded;
their receipts are the deliverable.

A **defect wears a refusal's clothes** when two readers disagree about the
same rows. Today's instance is the inverse — an acceptance wearing
competence's clothes: the claim reader emits fragments the checker then
solemnly adjudicates. The test that catches both directions is the one this
session ran: hand the same text to the reader and the source to a person, and
compare what each believes the row says.

## What the repo has no way to hold

1. **Claim instances**: (lesson, position, claim term, checker verdict, trace,
   guide's sanctioned verdict, citation). No register holds these; this is the
   artifact the true/false corpus becomes.
2. **The guide's grounds for rejection** ("The sum can't be less than 76") —
   determinate-negation prose, citable, currently unheld; a fragment field on
   the claim instance row holds it without a new artifact.
3. **Endorsement events** — a student's answer to a true/false item. The
   scoreboard vocabulary for them exists (`undertake_commitment/2`); no
   producer does.
4. **Drifted recovered text** — currently destroyed at refusal time.
5. **Abstention reasons as a census** — stated per run, aggregated nowhere.

Proposals, ranked with controls and verification commands, are in
`~/.claude/projects/-Users-tio-Documents-GitHub-hermes/plans/2026-07-28-refusal-actions.md`.
