# PROPOSAL — Projection frontiers: what the encoded commitments demand in five unreached domains

Date: 2026-07-29. A projection study, not an implementation plan. The discipline
throughout: read what the code does today, name the structural commitments it has
earned, and work out what those commitments demand — and where they stop — in
domains the code has not reached. "Would" and "could" are licensed in this
directory; every claim about the present tree carries a `file:line` and was
checked against the working tree on 2026-07-29. Nothing here edits code, rules,
or generated artifacts.

## 0. Verification of the premises

Several premises carried into this task reproduce with corrections. The corrected
numbers are the ones used below.

| Premise carried in | What the tree says |
| --- | --- |
| 40 earned entailments | yes — 40 `incompatibility_earned_entails/3` facts (`formal/incompatibility/incompatibility_entailment_order.pl:1539-1578`), 20 sparse-witness / 20 multi-profile (`:3194-3195`); 19 of the 40 relate `o(context(...))` atoms contributed by the a-fortiori closure (`:1553-1571`) |
| 189 machines, 18 normative arcs | stale header prose (`knowledge/strategies/action_grammar.pl:12-19`). Measured today: 214 computational + 18 discursive `machine_grammar/6` rows (232), 24 `normative_arc/3` rows; five arcs are spelled by both genres (`work_then_keep`, `work_then_break`, `keep_then_break`, `keep_work_keep`, `break_recover_break`) |
| 18 discourse automata never run against a transcript | true of the discursive genre — its consumers are index and check builders only (`scripts/research/build_corpus_window.py:15`, `build_action_grammar.py:47`, `scripts/checks/corpus_window.py:23`, `utterance_layers.py:51`). The computational genre has already met TalkMoves: `scripts/research/talkmoves_recognizer_sweep.py:1-29` sweeps the strategy recognizer over student turns, abstention-first, derived counts only |
| all 820 wired misconceptions in one PML cell | yes — 820 `misconception_pml/2` facts, every one `s(comp_nec(unlicensed(_)))` (`knowledge/misconceptions/pml_wire.pl`, counted today) |
| the valid_domain column is empty | not empty — mostly uncoded. `error_instances` in `data/research/research_shared.db`, measured live: 3,621 rows; `valid_domain_status` = stated 10, inferred 181, none_found 12, not_yet_coded 3,418. Two slices (fraction_comparison 81, decimal 228) already ran the full coding pipeline and yielded 91 triples (`formal/incompatibility/error_rule_inferences.pl:1-22`, `error_rule_warrant` count 91) |
| grades 7-8 reached only by resonance | too strong. Ledger measured today: G7 143 lessons, 28 with strategy evidence, 15 diagnostic_ready; G8 134 lessons, 0 and 0. Ratio and integer automata exist with deformation partners (`knowledge/strategies/transition_tables/ratio.pl`, `integer.pl`), and both productive/deformation pairs are already declared hyperedges (`incompatibility_entailment_order.pl:73,92`). What is resonance-only is the misconception reach (`hermes/mcp/server.py:81`) and the G8 lesson-evidence lane |
| 27 no-automaton lessons | yes — task-175 §G-5, seven sub-classes summing to 27 (`.superpowers/sdd/task-175-input-strategy-vocab.md:261-283`) |

## 1. The commitments being projected

Five, each named from running code rather than from the manuscript.

1. **Entailment is earned, never assumed.** A strict entailment holds only when
   replacement preserves every profile context, witnessed edge by edge
   (`incompatibility_entailment_order.pl:26-34`); containment against an empty
   profile is recorded separately as vacuous (`:36-40`). Two warrants are kept
   apart: jointly incoherent as mathematics vs incoherent relative to a named
   community's sanction (`error_rule_inferences.pl:16-21`).
2. **Viability is per input, not per rule.** `gap_viability/3` returns
   `contextually_correct` or `incorrect` for each input pair, with the condition
   named (`knowledge/strategies/math/smr_frac_benchmark_compare.pl:75-83`); the
   sequent engine relativizes contradiction to a perspective, so a student can
   hold what the mathematics negates without the context exploding
   (`docs/research/2026-07-28-pml-status.md:151-158`).
3. **Every productive machine carries its deformation partner** as data, not as
   commentary (`knowledge/strategies/math/measurement_action_pairs.pl:292-304`;
   registry union at `action_automata_registry.pl:974-1004`).
4. **A refusal with a counterexample is a result.** `smr_div_long` at any digit
   bound renders 1/32 and 1/3 in the same shape, so termination is decided by a
   different machine whose halt is a pigeonhole proof, and ill-typed input
   returns `refused(Reason)` rather than a verdict
   (`knowledge/strategies/math/smr_div_remainder_cycle.pl:16-31,44-46`).
5. **Contexts nest a fortiori.** A rule defeated throughout a broad input class
   is defeated in every reviewed subclass, and the nesting facts keep their
   epistemic status on their sleeve
   (`formal/incompatibility/incompatibility_sets_a_fortiori_context_closure.pl:1-14`).

The projections below ask what each unreached domain does to these five.

## 2. Domain 1 — the 27 no-automaton curricular classes

Task-175 §G-5 measured seven sub-classes no rule text can reach because no
automaton exists for the compiler to name. They are not one domain; they project
differently.

### 2.1 Whole-number number line (6 lessons, all G2-U4)

**(a) What the commitments demand.** The whole-number number line is length
measurement with unit 1, and the tree already holds that practice's
productive/deformation pair: `linear_unit_iteration` beside
`count_marks_not_intervals` (`measurement_action_pairs.pl:292-294`), with the
deformation's state label cited to the number-line literature itself — "count
marks instead of intervals," Bright, Behr, Post & Wachsmuth 1988
(`knowledge/strategies/math/state_vocabulary.pl:78-80`). The G2-U4 lessons match
addition and subtraction expressions to number-line diagrams (task-175:281-283).
The demanded machine walks: locate the origin, mark unit intervals, locate the
first operand, iterate unit jumps, name the landing point. Its material
incompatibilities are already in the register's vocabulary: naming the landing
point when the question asked for the jump count is the number-line form of
`answer_as_endpoint_count_up`, a declared hyperedge with
`count_up_missing_addend` (`incompatibility_entailment_order.pl:74`). The
viability context is exact: endpoint-naming agrees with jump-counting on every
input that starts at zero and diverges on every input that does not —
`o(context(the_jump_sequence_starts_at_zero))` is a legible input class in
precisely the form the a-fortiori closure consumes, and it nests (starts-at-zero
sits inside starts-at-a-labeled-mark).

**(b) Where it resists.** Nowhere structural. This is a missing lane with its
partner machinery on the shelf.

**(c) Readiness.** First in this domain. Smallest slice: one automaton pair
(productive jump-iteration, deformation mark-counting) in the counting or
measurement family, rule text from the verbatim guide phrase ("addition and
subtraction expressions and number line diagrams"), refusal control extended so
the unit's game-day lessons stay on the floor.

### 2.2 Clock and elapsed time (6 lessons)

**(a)** Time arithmetic is regrouping in a mixed radix (60, 60, 12). The base-10
regrouping incompatibilities transfer by structure: the register already holds
`borrow_across_zero_no_cascade` against `borrow_across_zero_cascade`
(`incompatibility_entailment_order.pl:76`), and the sexagesimal counterpart is
the documented elapsed-time error — subtract the minute numerals by magnitude
instead of borrowing an hour as sixty minutes. The material incompatibility of
that error, concretely: the rule "subtract the smaller minutes from the larger"
is incompatible with "elapsed minutes across an hour boundary," and it is
contextually correct on every interval that stays inside one hour. That context
— `the_interval_stays_within_one_hour` — is a viability predicate in
`gap_viability`'s exact shape, and it nests a fortiori (crossing noon sits
inside crossing an hour). The elapsed-time lessons' quantity-change half is
already covered in genre: `unit_preserving_measured_quantity_change` fits them
(task-175:269) and carries `drop_unit_from_measured_quantity_change` as its
partner (`measurement_action_pairs.pl:301-304`). What no machine carries is the
cyclical carry itself. Clock *reading* — the other lessons — is a
display-reading practice (the minute hand between marks is marks-vs-intervals
again) and belongs to Domain 4's lane, not this one.

**(b)** Resists only in the reading half; the arithmetic half is a missing lane.

**(c)** Second in this domain. Smallest slice: an `elapsed_time_regrouping`
automaton with deformation `subtract_clock_numerals_by_magnitude` and the
within-one-hour viability context.

### 2.3 Direct comparison — "lining up the endpoints" (4 lessons)

**(a)** Comparison without a unit. Task-175 named why the existing machine
refuses: `linear_unit_iteration` requires `establish_unit` and
`iterate_interval_from_zero`, and "lining up the endpoints iterates nothing"
(task-175:269). The practice's own conservation is the shared origin; its
deformation is comparing free ends without aligning origins, where a protrusion
licenses nothing — the license "A protrudes past B, therefore A is longer" is
itself context-gated on alignment. Here is where the two-negations distinction
becomes executable. The machine can produce the determinate exclusion — "A is
not longer than B," an incompatibility with its witness — and it must *refuse*
"how much longer," because without a unit the difference question is not
answered badly, it is outside the practice's expressive reach. Those are
different negations: `validity(incorrect)` with a named condition
(`smr_frac_benchmark_compare.pl:79-83`) versus `refused(Reason)` with the failed
condition in the history (`smr_div_remainder_cycle.pl:44-46`). A
direct-comparison automaton that returned a magnitude would repeat the defect
class the float-equality checker was: an instrument answering a question its
inputs cannot carry.

**(b)** The magnitude refusal is not a gap to fill later — it is the automaton's
content. When unit iteration arrives (the very next lessons in the measurement
sequence), the refusal is what the new machine discharges, which makes the pair
a modeled instance of the ORR resource limit: the crisis that motivates the
unit is the direct-comparison machine's own refusal.

**(c)** Fifth in this domain by lesson count, but cheap, and the refusal makes a
natural test target in the `strategy_task_span_refusal.py` genre.

### 2.4 Decomposition enumeration (GK-U5, 4 lessons)

**(a)** "No automaton enumerates the decompositions of a number"
(task-175:271). An enumeration machine's accept state is a completeness
certificate — *all* decompositions of N — and the tree already holds the
precedent for halting-as-proof: the remainder pigeonhole, where the bound is an
invariant of the machine's own record, not a precision setting
(`smr_div_remainder_cycle.pl:16-22`). For N into two addends the certificate is
the same shape (at most N+1 ordered pairs). The deformation is the corpus's
stop-early family (`stop_after_first_partial_quotient`,
`stop_after_one_known_fact` — `incompatibility_entailment_order.pl:125-126`)
applied to enumeration: stop before exhaustion. And the domain carries a genuine
per-input viability context in the referent: whether 2+3 and 3+2 are one
decomposition or two depends on what the task individuates — arrangements of
cubes or unordered partitions. A rule that identifies them is contextually
correct for partitions and incorrect for arrangements, verdict per input. The
rejected rule `compose (and|or) decompose numbers` (reach 4, task-175:478)
becomes admissible the day this machine exists.

**(b)** No structural resistance; the completeness certificate is new genre work
(the existing automata certify a run, not an exhaustion) and should be authored
as such rather than squeezed into a counting machine.

**(c)** Third in this domain.

### 2.5 Pattern rules (3 lessons), money (2), coordinate familiarity (2)

The repeating-shape pattern is a cyclic structure — position n carries
block[n mod k] — so the repeating block is the remainder cycle's repeating block
with shapes for digits; the deformation (extend by nearest neighbor or
reflection instead of by block) is contextually correct wherever the block is a
palindrome, verdict per input again. `linear_pattern_contextual_rule` already
holds the two additive-rule lessons (task-175:272). Money is composite-unit
counting in a non-uniform radix; its token/value deformation (count coins,
report the count as the value) is contextually correct exactly when every coin
is a penny — the child promoted from penny-counting carries a rule with a real
viability domain, which is viability-not-deficit in miniature. But two lessons
sit below task-175's own three-lesson noise threshold, so money waits for the
misconception corpus to demand the pair rather than the floor. Coordinate
familiarity does not plot (task-175:273); it is a reading/orientation practice
and belongs with Domain 4's lane — forcing `ordered_pair_coordinate_plot` to
accept non-plotting work would repeat the mistake R6 declined.

The 15 §G-6 lessons (Center Days, tool explorations, student-authored routines)
are not in this domain at all: the floor is not a defect for them, and the
refusal controls that hold two of them today should grow to hold the rest
(task-175:285-299,544-549). No projection here may swallow them.

## 3. Domain 2 — the 18 commitment automata against TalkMoves

**(a) What the commitments demand.** The 18 discursive machines
(`knowledge/discourse/commitment_automata.pl:47-186`) take actions that are
already move-shaped: `undertake_commitment`, `challenge_entitlement`,
`assume_vindication_task`, `attribute_commitment`, `defer_to_asserter`,
`withdraw_commitment`. The TalkMoves corpus codes moves at sentence level
(teacher and student move labels over 567 K-12 transcripts;
`~/Documents/GitHub/TalkMoves/data/`, CC BY-NC-SA — derived counts only, never
vendored text, the standing practice the recognizer sweep already observes,
`talkmoves_recognizer_sweep.py:26-29`). The demanded bridge is an authored,
checkable mapping table in the `action_mapping_rules.json` genre: a student
claim code maps to `undertake_commitment`; an evidence/reasoning code to
`assume_vindication_task`; a press-for-reasoning code to
`challenge_entitlement`; restating/revoicing codes to `attribute_commitment`.
With that table, what runs is walk-matching: does a coded transcript, read as a
move sequence with speaker turns, walk any machine's action sequence? Claim,
press, evidence walks `assertional_commitment` through its vindication arc;
claim, press, topic-change walks `assertion_without_vindication_task`
(`commitment_automata.pl:47-60`). The honest output is the recognizer sweep's
shape transposed to the second genre: matched-walk counts per machine per
transcript, and the abstention rate, with silence reported as the interesting
half. The first result is a number this proposal deliberately does not guess:
*how many of the 18 machines are walkable from the coding scheme at all.*

**(b) Where it resists.** The deontic verdict layer. `incompatible/2` is a
relation between commitment *contents*; TalkMoves labels are content-free move
kinds. No count over labels can witness `hold_incompatible_commitments`, the
deferral regress (which needs the deferral chain's target), or the tutorial
interruption's `name_the_incompatible_token` (which needs the token). This is a
missing lane rather than a boundary — the tm_0071 reading shows a human with
MCP adjudication can supply contents for one transcript
(`scripts/research/talkmoves_rerun_out/mcp_analysis_tm0071/data_and_methods.md`)
— but the lane is per-transcript labor, and a walk-count study that quietly
promoted move-sequence matches into deontic verdicts would be the
reader-asking-a-different-question pattern all over again. The two claims must
stay typed apart: "this transcript's moves walk the vindication arc" is
arc-level; "this student held incompatible commitments" needs contents no label
carries.

**(c) Readiness.** A derived-counts slice is small and legal: the mapping table,
a walker, Big Red for the 567, counts and abstentions out. Ranked below the
curricular domains only because its strongest layer (the verdicts) stays out of
reach of the corpus's own coding.

## 4. Domain 3 — valid_domain, and what filling it does to the PML cell

**(a) What the commitments demand.** The collapse fact is arity, not
annotation: all 820 wire rows sit in `s(comp_nec(unlicensed(_)))`
(`knowledge/misconceptions/pml_wire.pl`), and a one-place predicate can never
form a triple, so the wire contributes no hyperedges beyond pairs. The tree has
already demonstrated the repair, twice: a coding with a valid domain and a
divergence yields
`[s(comp_nec(rule(R))), o(licensed_consequence(C)), o(context(D))]`
(`formal/incompatibility/error_rule_inferences.pl:25-33`) — an arity-3
hyperedge that enters the register's profile machinery — and the a-fortiori
closure then earns strict entailments between the context atoms: 19 of the 40
earned rows are `o(context(...))` to `o(context(...))`
(`incompatibility_entailment_order.pl:1553-1571`). So filling `valid_domain` is
the one measured route by which documented errors leave the single cell:
3,418 of 3,621 `error_instances` rows are `not_yet_coded` today, 191 carry a
domain (10 stated, 181 inferred), 12 are honestly `none_found` and contribute
nothing — "a rule valid nowhere yields a pair, and a pair cannot be emergent...
a result about the vocabulary, not a gap in the coding"
(`error_rule_inferences.pl:11-15`; the exclusion is enforced at
`scripts/extract_error_rule_incompatibility.py:107`).

Which cells the filled rows would occupy is already decided by the generator,
and the decision deserves stating because it is not the obvious one: the
student's rule stays S-compressive, and everything viability contributes lands
in O-mode *ground atoms* — `o(context(...))` — not in operator polarity. The
expansive cells stay empty (`o(exp_poss(` occurs zero times in the tree;
census at `docs/research/2026-07-28-pml-status.md:111-129`). A valid domain is
the one column whose content is expansion-shaped — "this rule opens a class
where it succeeds" — so the design question a scaling slice must answer once,
in the generator and argued in the commit, is whether a filled row also stamps
an expansive reading or whether polarity stays coarse while the context
vocabulary grows fine. The current answer (contexts as atoms, operators
untouched) has a real virtue: the entailment order runs on content-level
exclusions and owes nothing to the twelve cells
(`2026-07-28-pml-status.md:173-179`), so the cells cannot silently take credit
for what the contexts earned. The cost is that the twelve-cell space remains a
coding policy rather than a measurement. Either answer is defensible; choosing
by default is not.

**(b) Where it resists.** In the labor, and in one discipline: `none_found` must
stay visible and non-counting. The pressure at scale will be to infer a domain
for every row because domains are what produce triples; the 12 honest
`none_found` rows are the control group that keeps "inferred" meaning
something. Emergence has the same gate the absorption analysis named: an
arity-3 triple absorbs only if a remainder pair recurs, so earned entailment
moves with corpus growth here and nowhere else.

**(c) Readiness.** The pipeline exists end-to-end (coder, hand review, database
write, extraction, closure); what gates it is review labor, which is owner
time. Smallest slice: one whole-number batch — the wire's densest domain
(`knowledge/misconceptions/misconceptions_whole_number.pl`) — through the same
coder-plus-review, then measure how many of the 820 wire tags join a coded
triple afterward. That join count is the abstraction deliverable the wave owes.

## 5. Domain 4 — reading a display is not building one

**(a) What the commitments demand.** Start from why R6 was refused: the
construction automaton accepts only after `raise_separated_bar_for_each_category`,
and a lesson that reads a finished graph raises no bar (task-175:385-390). The
refusal was right because reading conserves something else: the symbol-to-value
mapping. A reading automaton would walk: identify the display kind, establish
the scale unit (one picture stands for five), map symbol counts to values,
compare category values, answer the question asked. Its deformation is to skip
the scale step and read symbol count as value — and that deformation carries
the cleanest viability context in any of these five domains, because the
curriculum itself staged it: the rule "count the pictures" is contextually
correct across the entire unscaled K-2 picture-graph sequence and loses its
domain at exactly the word "scaled," which is IM's own vocabulary for the
boundary (the G-2 quotes: "Interpret data represented in a picture graph,"
grade2/unit1/lesson8; "scaled picture graph," grade3/unit1/lesson4;
task-175:161-180). The same token/value structure as marks-vs-intervals, so the
deformation vocabulary already exists in genre. A second deformation — answer
"how many more" by counting icons across categories without scaling — sits in
the same context class. The `dot_plot` fraction exclusion stays where task-175
left it: fractional line plots belong to a fraction machine, not here
(task-175:456-459).

**(b) Where the formalization honestly resists — and stops.** "Determine the
information needed... Ask (orally) questions to elicit that information"
(grade5/unit6/lesson15, task-175:296-298), and every notice-and-wonder launch:
these practices have no unlicensed-move set. Any noticing is licensed by the
practice's own norms. The register already states, formally, what that means:
a content whose minimal profile is empty entails only vacuously — the
otherwise-free containment case, recorded apart from earned entailment
precisely because it is free (`incompatibility_entailment_order.pl:36-40`).
Where nothing excludes anything, incompatibility semantics assigns no content;
`unlicensed/1` has an empty extension there not as a coverage gap but by the
grammar of the practice. This is an arche-trace-shaped boundary: the worth of a
noticing is settled by uptake — which contribution the room takes up and works
on — and that judgment is the teacher's, not a profile's. The honest formal
output is silence, and the boundary should be marked the way the tree already
marks such things: a refusal control naming those lessons (the
`strategy_task_span_refusal.py` genre), never a machine that pretends to
adjudicate wonder.

**(c) Readiness.** Second overall. Smallest slice: one
`categorical_display_reading` automaton with the scale-skip deformation; R6's
first two patterns re-pointed at the new kind (they measured floor 5); the
refusal control extended to the information-elicitation lessons in the same
commit, so the lane and its boundary land together.

## 6. Domain 5 — grades 7 and 8

**(a) What the commitments demand.** The corrected premise first: structure
already exists at the automaton level. The ratio family holds
`scale_ratio_unit` with `additive_extension_of_ratio` and
`reverse_ratio_referent_order` beside it; the integer family holds
`signed_addition_with_sign_relation` with `drop_sign_use_magnitude_sum` and
`order_by_magnitude_ignore_sign` (`knowledge/strategies/transition_tables/ratio.pl`,
`integer.pl`), and both productive/deformation pairs are declared hyperedges
(`incompatibility_entailment_order.pl:73,92`). What the commitments demand is
the viability layer those pairs do not yet carry, and the literature rows have
half-written it: adding a constant to both terms of a ratio is the mediant
combination, coded *productive* for betweenness and proportional-reasoning rows
and *deficit* for fraction addition
(`knowledge/misconceptions/literature_incompatibility_facts.pl:2730,1813,1429`)
— the corpus itself refuses one verdict for the rule. The executable form is a
per-input predicate in `gap_viability`'s exact shape: `additive_extension_of_ratio`
is contextually correct precisely when the added pair itself stands in the
ratio (adding multiples of (a,b) preserves a:b); on any other pair it produces
the mediant, which lands strictly between — the right answer to a betweenness
question and the wrong answer to an equivalence question, verdict per input,
with context classes that nest a fortiori (added-pair-is-the-unit-ratio inside
added-pair-preserves-the-ratio). Signed numbers give viability-not-deficit its
sharpest instance in the whole projection: `drop_sign_use_magnitude_sum` is
contextually correct on the entire non-negative corner of its domain — which
is the child's whole K-6 history of sanctioned practice — and the
incompatibility opens only where a negative operand arrives. Six years of
being right is not a deficit; it is a valid domain waiting for its column.

**(b) Where the formalization genuinely resists.** G8 irrationals. The
entailment lane's inputs are integer ratios, and the remainder-cycle machine
states its own absence: it has no input whose expansion is non-terminating and
aperiodic (`smr_div_remainder_cycle.pl:48-51`). Every witness any machine in
this tree can produce is periodic. "Know that there are numbers that are not
rational" therefore cannot be witnessed at execution level here;
`o(irrational_demanded)` enters the register only through the Lakoff-Núñez
defeasible lane (`incompatibility_entailment_order.pl:105`, earned rows
`:1573-1574`) — metaphor-level, not machine-level. The demand for an
irrational arrives from outside the practice these machines run, which is the
same boundary shape as the erasure point: the formal lane stops at
periodicity, and the step past it is a reorganization no oracle inside the
lane can supply. The projection stops there; authoring an "irrational number
automaton" would paper the boundary the tree currently marks. (G8
transformations may be reachable through the geometry family's rigid-motion
actions — `place_parts_by_rigid_motion`, task-175:117 — but that is unmeasured
here and stated only as a direction.)

**(c) Readiness.** Gated not on automata but on provenance: the G6-8 harvest is
excluded by reader provenance and 304 lessons are genuinely unchecked (the
vision-harvest boundary; G8 measures 0 strategy evidence on the ledger today).
Smallest slice: verify one G7 proportionality unit's guide text by hand against
the excluded harvest, then rule text mapping its lessons onto the four existing
ratio kinds — evidence-lane work in the task-166/175 ceremony, no new machine
required. G7 before G8; within G8, signed and linear content before
irrationals, which end at the boundary above.

## 7. Ranking

| Rank | Domain | Why here | Smallest first slice |
| --- | --- | --- | --- |
| 1 | No-automaton curricular classes (§2) | partner machinery on the shelf; ceremony proven; 27 lessons measured | whole-number number-line pair + rule text + refusal control (§2.1) |
| 2 | Display reading (§5) | one automaton unlocks a measured 5-lesson floor class plus the K-2/G3 scale boundary; its own limit is nameable in the same commit | `categorical_display_reading` + scale-skip deformation + refusal control |
| 3 | valid_domain arity-raising (§4) | highest evidential yield per row — the only measured route out of the one-cell collapse; gated on review labor | one whole-number coding batch + wire-join count |
| 4 | Grades 7-8 (§6) | structure exists; blocked on harvest provenance, and G8 ends at a genuine boundary | hand-verify one G7 unit, then rule text onto existing ratio kinds |
| 5 | Discourse vs TalkMoves (§3) | a cheap, legal derived-counts slice; but the verdict layer is unreachable from content-free labels | move-code mapping table + walk counts on Big Red |

## 8. What this proposal does not claim

- Not that any of these automata, once authored, would attach lessons beyond
  the floor counts task-175 measured; collateral is unknown until patterns are
  run.
- Not that the walk-count study says anything about deontic score. Arc-level
  matches and verdict-level claims are different types, and the study is only
  honest if it keeps them apart.
- Not that filling `valid_domain` moves earned entailment by any predictable
  amount. Absorption needs recurring remainder pairs; the count is an outcome,
  not a target.
- Not that the boundaries named here (notice-and-wonder, G8 irrationals, the
  direct-comparison magnitude refusal) are permanent. They are where the
  present formal lanes stop for reasons the code states about itself; a future
  lane with different inputs would have to re-derive them, not inherit them.
- Not that the single examples used above (10:45 to 11:20, 2+3 vs 3+2, one
  picture stands for five) are the classes they illustrate. Each teaches a
  class; the rule text that eventually lands must be measured against the
  corpus the way task-175 measured R1-R8.
