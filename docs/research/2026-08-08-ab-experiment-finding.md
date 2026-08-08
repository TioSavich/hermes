# The compiler won the registered first tier; coverage remained narrow

Measured 2026-08-08. The pre-registered paired experiment compared the shipped
typed quantity compiler with the shipped questionnaire on 60 frozen student
solutions and their paired correct solutions. Both arms used the same
`gemma-4-E2B-it Q4_K_M` checkpoint with reasoning disabled. The corpus, leakage
boundary, receipt definition, tier order, and later pre-launch amendments are
fixed in `.superpowers/sdd/task-2026-08-08-ab-experiment-spec.md:1-249`.

The registered decision selected the compiler at **T1: 2 correct-solution
accusations against the questionnaire's 26**. The registered falsifier says that zero licensed
differentiating receipts from arm Q across all 60 pairs falsifies the
questionnaire for this corpus shape, and zero from both arms falsifies both
candidates at the extraction seam. It fired for neither arm.

The registered tier sequence did not reach T2 or T3. For registered description
only, T2 held **8 licensed differentiating receipts for the compiler and 11 for
the questionnaire**. The registered falsifier fired for neither arm because both
receipt counts were nonzero. The registered receipt reach, expressed as receipt
count over the 60 pairs, was therefore 8/60 and 11/60; the questionnaire's 11
receipts occupied 10 pairs because one pair supplied two receipts. These counts
come from
`hermes/app/runtime/experiments/ab_2026_08/summary-ab-2026-08-08-jobs-7919599-7919600.json:1-40`.

## Frozen decision trace

The scorer emitted these seven lines. They are reproduced verbatim.

```text
INSTRUMENT DEFAULT: arm=compiler absent_ran_events=378 rows=120 rule=symbolic-event-implies-attempted
INSTRUMENT: arm=compiler cause=attempted-and-comparable attempted=378 comparable=378
INSTRUMENT: arm=questionnaire cause=attempted-and-comparable attempted=150 comparable=116
T1 correct-solution accusations: compiler=2 questionnaire=26
T1 decision: compiler
T2 decision: not reached
T3 decision: not reached
```

The first line records the conservative compatibility rule for compiler ledgers
written while amendment A5 was being added: a symbolic event without `ran` is
treated as attempted. Both arms passed the instrument precondition. The scorer
ran offline, after collection, and did not use a model or network path
(`.superpowers/sdd/task-2026-08-08-ab-experiment-spec.md:133-155`; scored summary
lines 10-35).

## Post-hoc row-level diagnosis

This diagnosis comes from a post-hoc row-level reading of the frozen ledgers.
It explains the registered result but does not revise the pre-registered tiers,
counts, falsifier, or decision.

### The questionnaire's 26 correct-solution accusations

All 26 accusations trace to operand-slot transcription errors. None trace to
representative-kind divergence, and `got` was faithful to the step's stated
result in 26 of 26 rows.

| Operand-binding defect | Rows |
|---|---:|
| result numeral transcribed into both operand slots | 13 |
| result numeral transcribed into one operand slot | 5 |
| one true operand duplicated into both slots | 7 |
| gate routed a step with no arithmetic operation | 1 |
| **all correct-solution accusations** | **26** |

The presence gate could confirm that each transcribed numeral occurred in the
step, but it could not confirm that the numeral occupied the requested role.
The one gate misroute sent an operator-free equality to subtraction. In every
inspected leaf, `expected` remained the correct arithmetic result for the bound
operands. The registered representative strategy therefore did not cause these
accusations; the operand bindings did.

### The questionnaire's 11 registered licensed receipts

Post-hoc content reading changes the interpretation of the registered count,
not the count itself. Zero of the 11 receipts carry correct content. Two of the
11 sit on genuine student errors by accident; their accusations do not identify
those errors. The other nine accuse arithmetic that is correct as written.

The questionnaire accused 29 of 93 computed leaves on the incorrect side,
31.2%, and 26 of 82 on the correct side, 31.7%. These rates provide no observed
discrimination between incorrect and correct work. Condition (iv) nevertheless
licensed 11 receipts because 199 of 233 schema bindings had exactly one
candidate. The resulting normalized tuples were nearly constant. A stochastic
misbinding passed whenever the paired-correct run happened not to produce the
same accusation.

### The compiler's two correct-solution accusations

The compiler's two false accusations had different causes. Index/step 1/2 was a
chained-equation misparse. Index/step 169/2 was kind-label drift within one
problem:
`currency`, `amount`, and `value` were treated as incommensurable labels for
correct arithmetic. The same pair-169 label artifact occurred on both sides of
the pair, so condition (iv) cancelled it.

The engineer's law is: paired controls cancel deterministic artifacts and
launder stochastic ones into signal. Here the compiler's repeated artifact
self-cancelled, while stochastic questionnaire misbindings passed the pairing
sieve 11 times.

### What T1 measured in this corpus

Genuine arithmetic slips are approximately zero in this corpus. Wrong-plan,
correct-arithmetic solutions dominate, consistent with the 2026-08-02
`mistake_location` finding that 997 misses had that form. The corpus mainly
contains errors in operand or operation choice for the situation, while the
questionnaire's `strategy_trace` probes arithmetic-level misconceptions once
operands are given. T1 therefore measured extraction fidelity, not
error-finding. The registered T1 result of 2 compiler accusations and 26
questionnaire accusations favors deterministic extraction at that seam.

## What the review prevented

Three independent review rounds preceded approval for submission. Their repairs
are recorded in the specification's pre-launch amendments and in
`.superpowers/sdd/task-2026-08-08-ab-driver-report.md:196-249,330-463`. The first
wave found a licensed-result inversion in arm Q. A misconception automaton can
return both the licensed `expected` value and the result produced by the
misconception trace. The initial reader treated that misconception result as the
licensed answer. On the fixture `47 + 28`, it would have accused the correct 75
and accepted the planted 615. That is a structural inversion: the trace's
produced result is evidence about the modeled strategy, not the value against
which the student's claim should be licensed.

Before launch, the reader was repaired to use `expected`; an absent or
non-comparable licensed value became an abstention. The later rounds also made
paired-absence effective by eliding operand values, fixed one-accusation-per-step
grain, distinguished a dead symbolic core from an extraction-seam abstention,
re-derived source steps during scoring, and guarded torn ledgers. The tier order,
corpus, leakage boundary, and falsifier did not change
(`.superpowers/sdd/task-2026-08-08-ab-experiment-spec.md:195-249`).

## Abstentions retained in the ledgers

The tables below count both JSONL ledgers directly. “Incorrect” and “correct”
are the two sides of each frozen pair. The terminal tables are mutually
exclusive within each lane.

The compiler made one binding call for each of 484 steps. Its quantity lane
emitted no quantity verdict on 226 steps and returned whole-expression
`not_checked` on 245. Those are its two quantity-lane abstention classes. The
remaining 13 steps received a checked quantity verdict. All 484 outer binding
transports had status `ok`; the arithmetic reader completed all 120
solution-side checks; neither class recorded an execution abstention or a
conflict.

| Compiler quantity-lane outcome | Incorrect | Correct | All |
|---|---:|---:|---:|
| no quantity verdict emitted | 176 | 50 | 226 |
| `not_checked` | 101 | 144 | 245 |
| **quantity-lane abstentions** | **277** | **194** | **471** |
| checked quantity verdict, not an abstention | 9 | 4 | 13 |
| step opportunities | 286 | 198 | 484 |

The registered falsifier fired for neither arm; these compiler abstentions
describe reach and do not change its nonzero licensed differentiating receipt
count.

Arm Q's terminal count assigns every one of the same 484 step opportunities to
one outcome. Its 368 abstentions leave 116 comparable symbolic leaves, matching
the scored instrument summary.

| Questionnaire terminal outcome | Incorrect | Correct | All |
|---|---:|---:|---:|
| L0 skip: no numerals | 27 | 1 | 28 |
| extraction incomplete | 139 | 102 | 241 |
| family not covered | 27 | 13 | 40 |
| leaf route completed but emitted no symbolic leaf | 14 | 11 | 25 |
| licensed value was non-numeric | 19 | 15 | 34 |
| **terminal abstentions** | **226** | **142** | **368** |
| comparable symbolic leaf, not an abstention | 60 | 56 | 116 |
| step opportunities | 286 | 198 | 484 |

The registered falsifier fired for neither arm; arm Q produced 11 licensed
differentiating receipts despite the terminal abstentions.

The questionnaire ledger also retains internal system-abstention events. These
events are non-exclusive: a single step can exhaust several operand slots before
reaching one terminal outcome, so the 1,131 events below must not be added to the
368 terminal abstentions.

| Questionnaire internal system-abstention event | Incorrect | Correct | All |
|---|---:|---:|---:|
| L1 abstention exit | 15 | 0 | 15 |
| L2 abstention exit | 13 | 3 | 16 |
| L3 no conforming schema | 44 | 17 | 61 |
| L3 binary abstention exit | 17 | 6 | 23 |
| L3 binary residual tie unresolved | 12 | 12 | 24 |
| L4 binding retries exhausted | 589 | 191 | 780 |
| L4/L5 equation-binding retries exhausted | 73 | 72 | 145 |
| L5 result-binding retries exhausted | 48 | 19 | 67 |
| **internal system-abstention events** | **811** | **320** | **1,131** |

Of those internal records, 64 model transports carried `abstention=true`: 54
were explicit navigation or binary exits and 10 were truncated L4/L5
transcriptions. The ledgers recorded zero conflict events. The registered
falsifier still fired for neither arm.

## Why arm Q was a live instrument at all

The questionnaire did not use multiple choice for every act. The E2B rotation
grid had measured navigation as content-anchored while measuring a strong
position effect for numeral binding; it also found that the model never chose
the offered abstention exit. The resulting law kept single-letter forms only for
L1/L2 navigation, moved binding to constrained verbatim transcription, selected
schemas in the system where possible, and derived abstentions from validation
and binding failures. That measured design history is reported in
`docs/research/2026-08-07-questionnaire-architecture.md:275-358`. Without those
changes, the experiment would have compared the compiler with an instrument
already known to misbind its first operand and decline no opaque choice.

## What this licenses

For this corpus shape, with this matched checkpoint, the compiler made fewer
accusations against paired correct work and therefore won the registered first
tier. The registered receipt reach remained 8/60 for the compiler and 11/60 for
the questionnaire. The licensed claim stops there. Most incorrect solutions
passed each instrument unaccused, and more than half passed both unaccused.

The post-hoc row-level diagnosis narrows the result's interpretation. Because
genuine arithmetic slips are approximately zero and wrong-plan,
correct-arithmetic work dominates this corpus, T1 measures extraction fidelity
at the tested seam. It does not establish error-finding performance. The
questionnaire's 11 registered licensed receipts do not extend that claim: the
post-hoc reading found correct diagnostic content in 0 of 11.

The experiment uses one frozen corpus shape: short steps from story-problem
solutions, paired with final-line-dropped reference solutions. The matched-E2B
design removes model size from the arm comparison. Model-size claims fall
outside what it licenses. The two independent GPU jobs, 7919599 and 7919600,
completed in the controller-recorded 4–6 minute GPU window. That cost supports
small paired reruns. The finding remains bounded to this corpus and checkpoint.

This paired instrument comparison reports receipt reach, false accusations on
paired correct work, abstentions, and the frozen decision trace. General
tutoring quality is outside its measured scope.

## Provenance

- Protocol and amendments:
  `.superpowers/sdd/task-2026-08-08-ab-experiment-spec.md:1-249`.
- Scored result:
  `hermes/app/runtime/experiments/ab_2026_08/summary-ab-2026-08-08-jobs-7919599-7919600.json`.
- Raw ledgers, 120 rows each:
  `.bigred-collected/2026-08-08-ab/compiler.jsonl` and
  `.bigred-collected/2026-08-08-ab/questionnaire.jsonl`.
- Driver and repair history:
  `.superpowers/sdd/task-2026-08-08-ab-driver-report.md`.
- Post-hoc row-level diagnosis:
  `.superpowers/sdd/task-2026-08-08-engineer-defense.md`.
- Questionnaire measurement and architecture:
  `docs/research/2026-08-07-questionnaire-architecture.md:275-358`.
