# Can these be judged?

Date: 2026-07-25. Assessed against the live tree: the two proposal files, the
corpus index, the generators that wrote them, the review surface, and
`research_shared.db`. No review decisions exist yet (`review_decisions.jsonl`
is absent; every record is `unreviewed`).

## The answer first

The owner said he won't know how to make these decisions. On the queue as
constituted, he is right, and the fault is in the proposals. Roughly 61% of
the corpus bindings carry no evidence that could distinguish accept from
reject, and 54% of the lesson pairings were generated from a candidate list
the generator had silently truncated, so a verdict on them would be a verdict
on an accident of alphabetization. These items are not hard to judge. They are
not judgeable, by him or by anyone, because the fact that would settle them
was never put into the record.

The set that genuinely needs his knowledge is small: on the order of 30 to 50
corpus rows, almost all fraction-scheme material, and it needs him only after
the questions are re-posed and the full source rows are attached. The rest
divides between what a script can settle now and what any careful reader can
settle with the machine steps at hand.

The recommendation at the end is concrete: discard nothing, promote nothing,
run the mechanical triage, regenerate the distorted half of the pairing file,
and re-pose both question sets at the grain the data actually has. The 1,010
item queue becomes roughly 180 decisions, of which his are a few dozen.

## What is actually in the queue

`review_queue.pl` serves 1,010 items: 733 lesson pairings plus 9 gap-only
lessons from `grade78_pairing_proposals.jsonl`, and 268 corpus bindings from
`corpus_binding_proposals.json`. Its ranking tiers come out as:

| source | tier | count | stated reason |
|---|---|---:|---|
| lesson_pairings | 0 | 9 | no pairing; judge the stated gap |
| lesson_pairings | 1 | 104 | "the index did not retain this machine" |
| lesson_pairings | 2 | 153 | proposals span machine families |
| lesson_pairings | 3 | 476 | inside the candidate set, one family |
| corpus_bindings | 0 | 6 | no recorded source |
| corpus_bindings | 1 | 113 | score tied the runner-up |
| corpus_bindings | 2 | 148 | generator marked tentative |
| corpus_bindings | 3 | 1 | generator's strongest confidence |

One tier is mislabeled outright. All 104 tier-1 pairing items come from the
35 lessons whose `lesson_topics/2` result is empty; zero come from a machine
the index examined and rejected. For those lessons the driver fell back to
`sorted(rows)[:60]` — the alphabetical prefix of the whole corpus, addition
through the first three discourse machines, with no geometry, probability,
ratio, or statistics machine in the offer — and then recorded
`was_candidate: false` for everything, because the pruned set it compares
against was empty. The tier's copy asserts an index judgment that never
happened. Under the house rule that placeholders resolve underneath, the fix
is the topic gap in those 35 lessons, then the copy.

## 1. Are the decisions well-posed?

A decision is well-posed here if some fact in or derivable from the
repository makes one verdict correct. Working through samples from both
files, the items fall into four classes. Proportions are estimates from the
counts below, and the sampling bias is stated in the spot-check section.

**Class A — well-posed and settled by evidence in the tree.** The machine's
step structure, the lesson's standards, or the corpus row's own text entails
the verdict. Example: binding row 44168 (Hill 2008) reads "a student carries
a 1 instead of a 2 to the tens column" and is bound to
`addition/drop_carry_to_next_column`, whose closure is
`treat_relevant_as_irrelevant + record_loss` — the carry is ignored. The
excerpt describes a carry that is performed with the wrong amount, which is a
different machine in the same family, `wrong_carry_amount_to_next_column`
(`misread_intermediate_value` in its shell). The binding is wrong, and the
two machines' step lists are the fact that makes it wrong. About a quarter of
the corpus set and perhaps 40% of the clean-basis pairings are class A.

**Class B — well-posed but the settling fact was withheld from the record.**
The 240-character excerpt cap (260 of 268 corpus excerpts hit it), the
four-standard 200-character cap in the pairing prompt, and the unit-level
titles on 137 of 271 lessons mean the item as served cannot be judged even
where a determinate answer exists in the database or the lesson text. The
review page shows the capped excerpt as the entire corpus evidence.

**Class C — not well-posed because the generator was answering a different
question.** The pairing driver filled a quota (218 of 271 lessons return
exactly three pairings; the same ratio trio appears verbatim on 17 lessons)
against a candidate list truncated to 60 by alphabet on 114 lessons. The
binding generator proposed only for signatures with no existing binding, so a
row whose best machine is already bound gets assigned to the nearest unbound
one — rescoring every proposal against the full signature set under the
generator's own metric, 38 of 268 (14.2%) are beaten by an already-bound
signature. Rows 46701 and 47123 describe smaller-from-larger subtraction;
`subtraction/smaller_from_larger_in_column` exists and is bound; both rows
were pushed onto `addition/drop_carry_to_next_column`. A reviewer asked
"is this binding right?" is being asked to ratify a constraint, and neither
verdict expresses what happened.

**Class D — not well-posed because the question has no truth condition at
this grain.** "Could a student's work in this lesson run
`discourse/entitlement_by_inference`?" Any lesson in which a student justifies
a claim could. The discourse machines (67 pairings) attach to nearly
everything, and nothing recorded about a lesson could refute one. Similarly,
one corpus row (strategy 2273, a set-model reading of the area formula) is
proposed for six different geometry signatures, five of them at tied scores;
at most one is the machine that excerpt runs, and the six-way fan is the
scorer admitting it cannot tell. 48 of the 195 distinct corpus rows fan to
more than one signature.

The proportions, roughly: class A perhaps 30% across both files, class B
another 15%, classes C and D the majority — and C/D items are the ones that
made the owner say he wouldn't know how to decide. He is not failing the
items. The items are failing him.

## 2. What settles mechanically

Each rule below was either executed during this assessment or is directly
implementable from predicates and files already in the tree.

**Corpus bindings — executed.** Union of three checks flags 163 of 268
(61%), leaving 105 for reading:

- *Score ties* (116): `score == runner_up_score` means the evidence terms
  could not prefer the proposed signature over another. The choice between
  them was arbitrary; auto-defer, or re-pose as a choice among the tied set.
- *Displacement* (38): rescore the row against every signature including the
  68 already bound (I ran this with the generator's own `score()` and
  `domain_agrees()`); when a bound signature strictly outscores the proposal,
  the row was force-fit. These want re-posing against the full corpus, and
  several are flat rejections a script can make: an addition-family binding
  whose excerpt contains "subtracting" and no addition verb, or a
  strategy row whose machine ends in `record_loss` while the excerpt records
  a correct answer (row 167: 889 + 499 = 1388 computed correctly, bound to a
  machine whose run must end in loss).
- *Fan surplus* (73): keep the argmax proposal per corpus row, defer the
  rest. One row per six signatures cannot be six findings.

Also settled mechanically, in the good direction: every one of the 139
distinct `bibtex_key` values resolves against `articles.bibtex_key` in
`research_shared.db`. Citation verification needs no human at all. The six
`unattributed` rows are a data gap in the source table, and the review page
already says so honestly.

**Lesson pairings — implementable.** The distorted-basis test is one
comparison per lesson: `machines_surviving > candidates_offered` (114
lessons, 5,665 candidate slots cut by the 60-cap) or `topics == []` (35
lessons). Together: 149 of 271 lessons, carrying 393 of 733 pairings and 23
of the 32 gap texts. Nothing on these lessons should be reviewed, because
the generator never held the sanctioned candidate set. Regeneration is the
verdict, and a script can issue it.

The gap claims are partially mechanical too. The corpus index has no machine
for the Pythagorean theorem, square roots, scatter plots, or scientific
notation, so the gap texts on the nine zero-pairing lessons are mostly
correct and checkable by name against `corpus_window.txt`. Two failure modes
sit beside them. `IM-G7-U1-L1`'s gap asks for "a machine for calculating the
lengths of scaled copies using a multiplicative scale factor" —
`ratio/scale_ratio_unit` is that machine, survives the lesson's topic
pruning when recomputed today, and was paired with high confidence by the
neighboring lesson L2; the run that produced L1 recorded 90 survivors cut to
60 alphabetically, and ratio sorts after the cut. And in grade 8 unit 7,
lessons L5 and L7 declare exponent-law gaps while L12 pairs three
`algebraic/exponent_*` machines — L5's topics were tagged `integer` and L7's
`ratio`, so the pruner removed the algebraic family from their offers. The
same unit contradicts itself because the topic tags routed different lessons
to different slices of the corpus.

## 3. What genuinely needs this reviewer

After the mechanical triage, 105 corpus proposals remain, 57 distinct
signatures. Their family breakdown: 30 fraction, 21 geometry, 11 algebraic,
9 integer, 8 counting, and a tail. Two different competences are needed:

*Careful reading with the machine steps at hand* — no scheme-theoretic
training required. My spot checks settled the Chernoff tree-diagram binding,
the Ryan whole-number-reading binding, and the area-model fan without any
knowledge the index page doesn't carry. Every sampled binding with score
≥ 4.5 checked out; the 33 remaining proposals in that band are most of an
afternoon for any careful reader, including a future automated one.

*Scheme knowledge* — the set that is actually his. Whether Kylie's "four
times twenty-five is a hundred-ninths" (Simon 2016) evidences
`fraction/co_denominator_count_on_from_larger` turns on whether iterating a
non-unit fraction under a preserved denominator is the co-denominator scheme
with a multiplication kernel or a units-coordination move that the corpus's
two co-denominator machines (both addition-kernel) do not model. Whether the
Steffe 2004 perturbation row is a run of `fraction/clear_inner_referent`
turns on what the commensurate-unit-fraction conflict does to the referent.
These are Steffe/Olive/Hackenberg/Tillema questions, they are answerable in
seconds by someone who carries that literature, and there are roughly 30 to
50 of them — the fraction rows plus a handful of counting and
units-coordination rows. That is the whole of the set that needs him. His
worry dissolves into a list that fits on two pages, provided the excerpt cap
is lifted so each item carries its full source row.

For the pairing file, after regeneration of the distorted half, the
clean-basis remainder is 122 lessons. Nothing there requires fraction-scheme
expertise; grade 7–8 IM content against machine step lists is within reach
of any mathematically careful reader, and most verdicts are class A. His
participation is optional there, and a delegated or automated pass with
spot-auditing would be defensible.

## 4. Are these the right questions?

**The pairing question conflates possibility with warrant.** "Could a
student's work in this lesson actually run this machine?" has no truth
condition: students run decimal addition in every grade-7 lesson that
mentions money (`IM-G7-U9-L1` pairs `decimal/decimal_addition_by_aligned_units`,
which is true and tells nobody anything). The question that has one is fixed
by what acceptance does. A promoted pairing becomes
`explicit_lesson_strategy/4`, which `lesson_monitoring` consumes; the
operative question is therefore: *when Hermes reads student work from this
lesson, should this machine be in the set it tries first?* That is a
recognition-set question, it is about the few machines most diagnostic of
the lesson's mathematics, and its natural unit is the lesson, or honestly
the unit — the data already collapsed to unit grain, with 137 lessons
carrying unit-level titles and pairing trios repeating verbatim across a
unit. Asked per lesson as a set ("do these three belong?"), the pairing file
is 271 decisions. Asked per unit first with lesson-level exceptions, it is
17.

**The binding question conflates instance with coverage.** The generator's
goal was coverage — give each of the 76 unreached signatures a literature
anchor — but the reviewer is asked a per-row instance question, and the
mismatch is why one row fans to six signatures and why displaced rows land
on machines they do not describe. The answerable question is per signature:
*of these candidate rows, is any one an instance of this machine's run?*
with "none" as a first-class answer, exactly as the pairing driver already
grants for gaps. That is 57 signature-level decisions over the surviving
105 proposals, each needing the full row text, and "none" honestly recorded
leaves the signature in `signatures_unreached` where it belongs. The
present form instead invites accepting a wrong anchor to retire a coverage
debt.

## 5. Spot checks

Twenty-nine judgments: 13 on pairings (12 pairings, 1 gap claim), 16 on
bindings (counting the six-way fan as six). Sampling was deliberately
adversarial on the binding side — I over-weighted the score-floor band where
the structural problems live — so these totals must not be read as an error
rate for either file.

**Pairings: 9 right, 2 wrong, 2 undecidable.**

| item | verdict | ground |
|---|---|---|
| G7-U1-L2 → ratio/scale_ratio_unit | right | 7.G.A.1 computes actual lengths multiplicatively; machine scales and records conservation |
| G7-U1-L2 → ratio/additive_extension_of_ratio | right | the documented additive-scale error; machine removes/combines and records loss |
| G7-U1-L3 → geometry/angle_as_ray_length | right | scaled copies preserve angles; the machine scales what must survive |
| G7-U3-L6 → geometry/area_unit_covering | right | the lesson is grid-square estimation of area |
| G8-U3-L1 → ratio/scale_ratio_unit | right | understanding proportional relationships |
| G7-U6-L4 → algebraic/contextual_linear_equation_construction | right | tape diagrams to equations is the lesson |
| G8-U5-L2 → algebraic/symbolic_expression_construction | right | writing input-output rules |
| G7-U8-L4 → statistics/dot_plot_frequency_representation | right | repeated trials recorded as frequencies |
| G7-U9-L1 → decimal/decimal_addition_by_aligned_units | right, vacuous | true of any lesson with prices; diagnostic of nothing |
| G8-U5-L2 → algebraic/exponent_as_repeated_factor | wrong | reason cites "volume formulas as examples of functions"; volume enters the unit a dozen lessons later — unit-blurb bleed |
| G7-U1-L1 gap claim | wrong | the requested machine exists, survives pruning, and was paired by L2; cut by the 60-cap |
| G8-U1-L2 → discourse/entitlement_by_inference | undecidable | attaches to any lesson where claims are justified; no recorded fact could refute it |
| G8-U5-L17 → geometry/compare_solid_volume_by_visible_extent | undecidable | plausible speculation; nothing in the record supports or refutes |

**Bindings: 5 right, 9 wrong, 2 undecidable.**

Right: Chernoff 2011 → `probability/terminal_tree_endpoint_probability_sum`
(score 8.5; the excerpt is a tree-endpoint probability sum, the machine
accumulates and names — the strongest binding in the file); Ryan 2002 →
`decimal/decimal_whole_number_reading` (7.5; ordering decimals as digit
strings, and the machine's double `treat_relevant_as_irrelevant` is exactly
place value ignored); Mack 2000 → `fraction/recursive_partition` (7.0; Lee
partitioning each fourth of three-fourths is recursive partitioning in the
Steffe/Olive sense, and the machine partitions, disembeds, partitions);
Almeida 2016 → `fraction/cross_multiplication_rule_without_ground` (5.0);
row 2273 → `geometry/rectangle_area_unit_iteration` (4.5, the one member of
the six-way fan whose steps — iterate units, iterate composite units, count —
match the set-model reading of the formula).

Wrong: the four `addition/drop_carry_to_next_column` bindings dissected in
sections 1 and 2 (a wrong-carry-amount row, two smaller-from-larger
subtraction rows, a correct-answer row bound to a loss-recording machine);
the five surplus members of the 2273 fan, each tied at the floor and each
describing the same excerpt the sixth already claimed.

Undecidable: Simon 2016 → `fraction/co_denominator_count_on_from_larger`
and Steffe 2004 → `fraction/clear_inner_referent`, both discussed in
section 3 — the two items in the sample that genuinely need the owner, and
neither is answerable from a 240-character excerpt.

The band structure is the finding: every sampled binding at score ≥ 4.5 was
right; every sampled binding at ≤ 3.5 was wrong or undecidable. 207 of 268
proposals sit at ≤ 4.0. The generator's floor (`MIN_SCORE = 3.0`) admits six
generic single words — "place", "value", "column", "next", "digit", "number"
reach it — and most of the file lives just above that floor.

## 6. Limits of this assessment

Twenty-nine judged items out of 1,010 is a 3% sample, chosen adversarially
rather than at random, and my verdicts on the fraction-scheme items are
deferrals, which is the point of section 3 but also a limit of the tally.
The displacement rescoring uses the generator's own keyword metric, which
this report argues is weak; 14.2% is therefore a lower bound on force-fit,
established with a tool that under-detects it. The pruning recomputation for
`IM-G7-U1-L1` returns 58 survivors where the recorded run logged 90 — the
negation index has been rebuilt since the run, so my claim about what the
60-cap cut at run time is an inference from the recorded counts and the
alphabetical sort order, verified on today's index. IM lesson content beyond
what the tree records (titles, standards, unit blurbs) comes from my general
knowledge of the curriculum and could err at the individual-lesson level;
the G8-U5-L2 "wrong" verdict depends on volume entering unit 5 late, which
the unit blurb in the field context itself supports.

## 7. What to do

1. **Do not open the review page on the queue as constituted.** A verdict
   recorded on a distorted-basis pairing or a tied binding ratifies noise,
   and `review_decisions.jsonl` permits one verdict per item.
2. **Run the mechanical triage on the bindings** — ties, displacement,
   fan-surplus, operation-word contradiction — and write its verdicts into a
   machine-attributed decision log, not the human one. 163 of 268 leave the
   human queue. The rescoring script from this assessment is a working
   draft of it.
3. **Regenerate the 149 distorted-basis lessons** with candidates ranked by
   relevance rather than truncated by alphabet, and with the 35 empty-topic
   lessons given topics first (that is the placeholder resolving underneath).
   The regeneration is also the moment to re-pose per lesson as a
   recognition-set question.
4. **Re-pose the surviving bindings per signature** — 57 questions of the
   form "is any of these rows an instance of this machine's run, or none?" —
   with full row text from `research_shared.db` replacing the 240-character
   excerpt on the review page.
5. **Hand the owner only the scheme set**: the ~30 fraction rows and their
   counting/units-coordination neighbors, each with its full source row and
   both candidate machines' step lists. That is the set his knowledge is for,
   and it is an evening, not a thousand-item text file.

The proposals should not be discarded; the high-scoring band is good and the
gap claims found real holes in the corpus. But as review material they were
posed at the wrong grain, on evidence caps that withhold the settling facts,
under generation constraints that pre-decided some answers. The owner's
sentence — that he wouldn't know how to make these decisions — is accurate
testimony about the questions, and this report's use of it is as a
specification: a reviewable question is one where knowing more mathematics
education makes the decision easier. Most of these, as posed, fail that
test. The re-posed versions pass it.
