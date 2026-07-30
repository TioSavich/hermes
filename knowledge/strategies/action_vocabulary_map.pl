/** <module> action_vocabulary_map -- a shared action alphabet for the strategy automata
 *
 * The extracted transition tables carry 638 distinct action labels across
 * 172 signatures, 547 of them confined to one signature. At that grain the
 * 69 execution-witnessed automata share no minimized structure and admit no
 * rooted homomorphism: string clustering finds nothing to join because the
 * labels were written one machine at a time. This file records an authored
 * semantic mapping of those labels onto a smaller alphabet of canonical
 * actions, so that what two machines DO at a step can be compared even when
 * their authors named it differently.
 *
 * Every mapping row was decided from the doing: which states the edge
 * connects, what the machine has already established when it fires, and what
 * the next edge needs. No row rests on the local label resembling the
 * canonical name. Where the doing at a position is genuinely two doings --
 * establish_base names the grouping base of a positional numeral in one
 * machine and the repeated factor of a power in another -- the two
 * occurrences carry different canonical actions.
 *
 * Two rules decided the hard cases, and both are stated so a reader can
 * disagree with them:
 *
 *   Position. A terminal edge into the accepting state whose label names
 *   what the strategy kept or lost maps to record_conservation or
 *   record_loss. The same word at an intermediate edge maps to what it does
 *   there -- retain_unchanged where it carries a quantity forward,
 *   verify_invariant where it certifies a relation. This is why
 *   preserve_data_set (a machine's first edge) is register_givens and
 *   preserve_whole_area (a machine's last) is record_conservation.
 *
 *   Slot. Where a deformation and its viable partner differ at one edge, the
 *   deformation's label is read against the slot the partner fills. This is
 *   how numerator_denominator_gap comes out as substitute_available_relation
 *   rather than as a reading of an attribute: it stands where
 *   benchmark_fraction_comparison judges against the benchmark.
 *
 * Risk gating. knowledge/crosswalk/vocabulary_licenses.pl marks 36 of its 79
 * entries HIGH -- same word for different things, or different words for the
 * same thing, in ways its author found likely to mislead students. No HIGH
 * entry licenses a merge here. Where a canonical action's citation names a
 * HIGH entry, it names it as the source of a term and records the
 * disambiguation obligation that comes with it. The clearest case is
 * division: vl005 (sharing) and vl006 (measurement) are both HIGH precisely
 * because students confuse them, so share_into_known_groups and
 * measure_out_group_size are two canonical actions and no label maps to both.
 *
 * Forty-three more machines arrived on 2026-07-25, when
 * knowledge/strategies/math/action_automata_registry.pl gained signature rows
 * for automata that had been implemented in the action-pair modules all along
 * and never declared, so the transition-table builder had never extracted
 * them. Among them are the Steffe/Olive/Hackenberg fraction schemes
 * splitting, solve_for_unit, recursive_partition and
 * improper_fraction_iteration. They brought 164 new labels and needed exactly
 * one new canonical action, misread_intermediate_value. That the other 163 fit
 * an alphabet authored before these machines were extractable is the first
 * evidence it generalizes past the corpus it was written on.
 *
 * Two genres. The computational actions describe steps that do something
 * to a quantity; the discursive actions describe steps that do something to
 * a deontic score, and they answer to machinery this repository already
 * carries -- formal/learner/deontic_scorekeeper.pl for commitment and
 * entitlement, formal/pml/mua_relations.pl for the meaning-use relations
 * between a vocabulary and the practice-or-ability that deploys it. The
 * automata that run the discursive actions are in
 * knowledge/discourse/commitment_automata.pl, in the same fact shape as the
 * strategy transition tables. The two genres share exactly one action name,
 * register_givens; action_kinship/3 records the pairs that do the same
 * thing to different material.
 *
 * The abstraction that makes the genres comparable is not the action name.
 * It is action_register/4's two axes. Projected to actions, 189 machines
 * across both genres spell 187 distinct words and share almost nothing.
 * Projected to stance, they spell 69 words, and 18 run-length arcs cover
 * every one of them, five of those arcs spanning both genres.
 * knowledge/strategies/action_grammar.pl carries the arcs, the
 * factorization, and the token-in-context verdicts.
 *
 * Retention splits by what the retention owes. retain_unchanged carried
 * eleven rows and three normative jobs: the strategy kept what it owed, or
 * kept something it was obliged to change, or carried a value the strategy
 * owed nothing to. Stance is a property of an action here, so an action whose
 * members disagree about stance can carry neither reading. It is three
 * actions now, and the inverting pair is the finding: retaining is conserving
 * in retain_what_must_survive, where change was not due, and deforming in
 * retain_where_change_was_due, where it was. Two machines that had looked
 * like they record nothing turn out to record a conservation --
 * division/measure_groups_of_size keeps the leftover its deformation partner
 * loses, and measurement/unit_preserving_measured_quantity_change keeps the
 * unit its partner discards.
 *
 * The overbroad action is gone. The first pass collected 27 labels under a
 * single substitute_available_relation, which the report that accompanied it
 * flagged as too wide to carry a finding. It is now seven actions, split on
 * what kind of thing is put in place of what the task requires: an
 * appearance for a measure, a count for a measure, one operation for
 * another, an additive difference for a multiplicative order, a reading of a
 * sign for the relation it writes, a name for a transformation, and a scalar
 * for a quantity that carried sign or spread.
 *
 * Strategies stay distinct. This file abstracts ACTIONS. If two
 * pedagogically distinct strategies turn out to be structurally coincident
 * once their actions are projected through this map, that is a finding to
 * report with both signatures named -- never a merge, and never a reason to
 * bend a mapping row toward or away from a coincidence.
 *
 * Boundary (quarantine): every fact here is review-pending data. Nothing in
 * this module is imported by hermes_worker.pl, the reader, the recognizers,
 * or any automaton, and the transition tables are read-only with respect to
 * it. The one consumer is the opt-in --mapping flag of
 * scripts/bigred/strategy_algebra/analyze_strategy_algebra.py, whose default
 * behaviour is unchanged. Adopting any row into a recognizer's label
 * matching, the reader's grammar, or a misconception mapping is a
 * formal-core change that needs its own reviewed slice.
 *
 * Every fact below was decided by hand, one label at a time, against the
 * tables. scripts/checks/action_vocabulary_map.py verifies the result: that
 * the alphabet covers every label in the census or names it as an explicit
 * remainder, that no canonical action goes unused, that every action carries
 * exactly one genre, register, and stance, that every kinship pair crosses
 * the genres, that the fields are well formed, and that the sharing and
 * measuring actions stay apart. Edit the facts here, then re-run the check.
 *
 * action_unmapped/4 is empty, and that is a change rather than an absence.
 * The first pass left perform_grounded_quantity_change unmapped because
 * every grounded operation in the alphabet asserted a direction the table
 * declines to assert. apply_quantity_change now names the direction-neutral
 * doing, which is what recording the remainder was for. The remainder that
 * stands open is on the other side: 24 of the 85 edges in
 * commitment_automata.pl carry provenance(authored(unmodelled(_))), meaning
 * the literature names that step and no predicate here runs it yet.
 */
:- module(action_vocabulary_map,
          [ canonical_action/3,
            action_register/4,
            action_kinship/3,
            action_maps/7,
            action_unmapped/4
          ]).

% No remainder stands open in this file at present; see the module note above.
:- discontiguous action_unmapped/4.

% canonical_action(Name, gloss(Text), citation(Source)) -- or coined(Reason)
% where the name is this house's, with the reason it was coined.
canonical_action(accept_without_check, gloss("Accept a structure without the verification it needs."),
                 citation("unequal-sized parts do not name fractional parts: Van de Walle ch. 15, Fractional Parts (state_vocabulary q_unequal_partition_piece_count)")).
canonical_action(accumulate_total, gloss("Add the counted or measured pieces into a running total."),
                 coined("house name; the tables accumulate in eight families and no framework term spans boundary length, partial quotients and column sums")).
canonical_action(acknowledge_commitment, gloss("Put a commitment on one's own score."),
                 citation("Brandom, Making It Explicit, ch. 3, the acknowledging side of scorekeeping; formal/learner/deontic_scorekeeper.pl:commitment/2")).
canonical_action(align_to_common_unit, gloss("Bring both quantities into a shared unit, denominator, or decimal scale so they can be measured against each other."),
                 citation("common partitioning: Shin & Lee 2018; co-measurement unit: Shin & Lee 2018, Nabors 2003 (state_vocabulary q_common_partition, q_measure_with_co_unit)")).
canonical_action(apply_quantity_change, gloss("Change a measured quantity where the strategy does not commit to the direction of the change."),
                 coined("house name. The task-125 report left perform_grounded_quantity_change unmapped because the alphabet's grounded operations were all directional; this action is direction-neutral on purpose, so the map no longer has to assert a direction the table declines to assert")).
canonical_action(apply_stored_rule, gloss("Carry out a remembered formula, rule, or prescribed procedural step."),
                 citation("standard algorithm as the endpoint of a progression: vocabulary_licenses vl050, risk MEDIUM")).
canonical_action(assign_roles, gloss("Bind each given to its structural role in the relation: which quantity is the whole and which the part, group count against group size, which term is the repeated factor, which coordinate comes first."),
                 coined("house name; the roles themselves are named by vocabulary_licenses vl005/vl006 and vl042, all risk HIGH, so the binding step is named here without borrowing their terms -- the disambiguation obligation those entries carry is recorded, never discharged into a synonym")).
canonical_action(assume_vindication_task, gloss("Take on the task-responsibility of vindicating the entitlement one has just claimed."),
                 citation("Brandom, Making It Explicit, ch. 3, the responsibility half of assertional force")).
canonical_action(attach_units_coordination, gloss("Attach to the result the level of units coordination it carries."),
                 citation("units coordination levels: Steffe & Olive 2010; Hackenberg 2013")).
canonical_action(attend_to_utterance, gloss("Take an utterance up as a move in a scorekeeping practice, before it is complete."),
                 citation("Brandom, Making It Explicit, ch. 3, on assertion as a move whose significance is its effect on a deontic score")).
canonical_action(attribute_commitment, gloss("Put a commitment on another speaker's score."),
                 citation("Brandom, Making It Explicit, ch. 3, the attributing side of scorekeeping; formal/learner/deontic_scorekeeper.pl:commitment/2")).
canonical_action(authorize_deferral, gloss("License others to defer to this assertion in vindicating their own entitlement."),
                 citation("Brandom, Making It Explicit, ch. 3, the authority half of assertional force")).
canonical_action(certify_meaning_use_relation, gloss("Certify that the meaning-use relation the machine traversed holds."),
                 citation("formal/pml/mua_relations.pl:kind_mua_coherence/3")).
canonical_action(challenge_entitlement, gloss("Demand that a commitment's entitlement be vindicated."),
                 citation("Brandom, Making It Explicit, ch. 4; formal/learner/deontic_scorekeeper.pl:requires_entitlement/1")).
canonical_action(combine_quantities, gloss("Join two quantities into their sum."),
                 citation("join / add to: vocabulary_licenses vl001, risk HIGH -- cited as the source of the term, recorded as a disambiguation obligation, never as a merge licence")).
canonical_action(commute_operands, gloss("Reorder the operands."),
                 citation("commutative property: vocabulary_licenses vl043, risk MEDIUM")).
canonical_action(compare_additive_gaps, gloss("Compare the additive distance between the two terms of each quantity."),
                 citation("gap thinking: Pearn & Stephens 2004, via Clarke & Roche 2009 (state_vocabulary q_gap_thinking)")).
canonical_action(compare_magnitudes, gloss("Decide the order relation between two quantities."),
                 citation("Compare: vocabulary_licenses vl004, risk MEDIUM -- the one comparison term the crosswalk marks substitutable across frameworks; reasoning about the relative size of the fractions: Van de Walle ch. 15 (state_vocabulary q_compare_relative_size)")).
canonical_action(compare_residuals, gloss("Compare what is left over between each quantity and the benchmark."),
                 citation("residual thinking: Clarke & Roche 2009; Post & Cramer 2002 (state_vocabulary q_residual_compare)")).
canonical_action(compose_expression, gloss("Assemble a symbolic expression, equation, diagram, or summary object out of the roled parts."),
                 coined("house name; the semantic-equation distinction vocabulary_licenses vl036, risk HIGH, names the product rather than the assembling -- disambiguation obligation recorded, and no row rests on that entry")).
canonical_action(compute_product, gloss("Multiply the operands as numerals."),
                 citation("standard algorithm: vocabulary_licenses vl050, risk MEDIUM")).
canonical_action(compute_quotient, gloss("Divide the operands as numerals."),
                 citation("standard algorithm: vocabulary_licenses vl050, risk MEDIUM")).
canonical_action(conflate_attribution_with_acknowledgement, gloss("Take what is attributed to another as acknowledged by oneself, or the reverse."),
                 citation("Brandom, Making It Explicit, ch. 3: the two sides of a score are not interchangeable, and collapsing them collapses the perspective scorekeeping keeps")).
canonical_action(conflate_roles, gloss("Collapse two structurally distinct roles into one."),
                 citation("the confusion vocabulary_licenses vl005 and vl006 record between sharing and measurement division, risk HIGH for both -- cited as the documented instance of this doing, never as a licence to merge the two")).
canonical_action(count_back_from, gloss("Count backward from the total by a held amount."),
                 citation("counting back: Van de Walle subtraction strategies; vocabulary_licenses vl052, risk HIGH -- disambiguation obligation recorded")).
canonical_action(count_on_from, gloss("Count forward from a value already held, rather than from one."),
                 citation("counting on: Van de Walle addition strategies; vocabulary_licenses vl052, risk HIGH -- the strategy names differ across frameworks, so the licence is recorded as a disambiguation obligation")).
canonical_action(count_units, gloss("Count how many units the iteration or the partition produced."),
                 citation("counting fractional parts, or iterating: Van de Walle ch. 15, Fractional Parts (state_vocabulary q_iterate_count_parts)")).
canonical_action(count_up_to_target, gloss("Count forward until a named target is reached, holding the distance travelled."),
                 citation("think addition / counting up: Van de Walle subtraction strategies; vocabulary_licenses vl052, risk HIGH -- disambiguation obligation recorded")).
canonical_action(decompose_by_place, gloss("Split a numeral into its base and ones components."),
                 citation("composing and decomposing base-ten representations: vocabulary_licenses vl048, risk HIGH -- cited as the source of the term, recorded as a disambiguation obligation, never as a merge licence")).
canonical_action(decompose_operand, gloss("Split one operand into pieces a later step can use, not along place boundaries."),
                 citation("break apart: vocabulary_licenses vl044, risk HIGH -- disambiguation obligation recorded, not a merge licence")).
canonical_action(decompose_region, gloss("Cut a figure into non-overlapping pieces, or unfold a solid into its net."),
                 coined("house name; Van de Walle treats decomposition as a strategy rather than naming the step")).
canonical_action(defer_to_asserter, gloss("Pass the demand for vindication to the speaker who asserted it."),
                 citation("Brandom, Making It Explicit, ch. 4, deferral as a route to entitlement")).
canonical_action(deploy_vocabulary_from_practice, gloss("Deploy a vocabulary out of a practice-or-ability sufficient for it."),
                 citation("Brandom, Between Saying and Doing, lecture 1, PV-sufficiency; formal/pml/mua_relations.pl:pv_sufficient/2")).
canonical_action(derive_consequent, gloss("Take the consequence the located inference licenses."),
                 citation("formal/learner/deontic_scorekeeper.pl:commitment_consequence/3")).
canonical_action(disembed_part, gloss("Take a part out of the whole while the part stays inside the whole."),
                 citation("disembedding: Hackenberg 2013; Steffe & Olive 2010 (state_vocabulary q_disembed, q_disembed_subset)")).
canonical_action(dispatch_to_kernel, gloss("Hand the step to another automaton and wait on it."),
                 coined("names a construction internal to this repository: the fraction tables delegate to the CGI kernel")).
canonical_action(distribute_over_partition, gloss("Apply the operator across the parts of a decomposition."),
                 citation("distributive property / break apart: vocabulary_licenses vl044, risk HIGH -- cited as the source of the term, recorded as a disambiguation obligation")).
canonical_action(double_count, gloss("Count the same unit or region more than once."),
                 coined("house name for the overlap-driven miscount")).
canonical_action(elaborate_practice_algorithmically, gloss("Elaborate one practice-or-ability from another by an algorithm."),
                 citation("Brandom, Between Saying and Doing, lecture 1, PP-sufficiency; formal/pml/mua_relations.pl:pp_sufficient/3")).
canonical_action(emit_result, gloss("Release the result from the machine."),
                 coined("house name for the terminal edge the comparison automata share")).
canonical_action(enumerate_candidates, gloss("Generate the candidate set a later step will filter."),
                 coined("house name; the search tables in geometry and multiplication generate before they filter")).
canonical_action(establish_reference_frame, gloss("Set up the frame against which locations or magnitudes will be read: axes, zero as origin, a vertex and initial ray, a value or frequency scale."),
                 coined("house name; the tables build frames in six families and no single framework term covers axes, origin, vertex and scale together")).
canonical_action(evaluate_expression, gloss("Compute the value of an expression from its parts."),
                 coined("house name; the algebraic tables evaluate each side as its own step")).
canonical_action(exchange_base_down, gloss("Trade one unit of the larger place for its full complement of the smaller."),
                 citation("regrouping / trading: vocabulary_licenses vl049, risk HIGH -- kept distinct from regroup_to_base for the reason that entry gives")).
canonical_action(exhaust_resource, gloss("Reach for a stored resource the strategy needs and find it absent, so a fallback has to run."),
                 coined("the ORR crisis step this repository already models: a resource limit met, which is not the same doing as a step skipped")).
canonical_action(explicate_practice_in_elaborated_vocabulary, gloss("Say, in the elaborated vocabulary, what the practice implicit in every vocabulary was already doing."),
                 citation("Brandom, Between Saying and Doing, lecture 1, universally LX vocabulary; formal/pml/mua_relations.pl:lx_for/3")).
canonical_action(filter_by_constraint, gloss("Keep only the candidates that satisfy a stated constraint."),
                 coined("house name, paired with enumerate_candidates")).
canonical_action(grant_entitlement, gloss("Grant entitlement to a commitment already held."),
                 citation("Brandom, Making It Explicit, ch. 4; formal/learner/deontic_scorekeeper.pl:grant_entitlement/2")).
canonical_action(grant_entitlement_without_grounding, gloss("Grant entitlement where the grounding the entitlement requires was never deployed."),
                 citation("formal/learner/deontic_scorekeeper.pl:ungrounded_grant_attempt/3, which already detects this case for the cross-multiplication example")).
canonical_action(halt_before_completion, gloss("Stop a required traversal, iteration, or recomposition before it finishes."),
                 coined("house name for the stop_before_* and drop_*_after_* edges")).
canonical_action(hold_incompatible_commitments, gloss("Keep commitments on the score that cannot be held together."),
                 citation("formal/learner/deontic_scorekeeper.pl:deontic_incoherent/2")).
canonical_action(inherit_entitlement, gloss("Take the entitlement the terminated deferral chain confers."),
                 citation("Brandom, Making It Explicit, ch. 4: a deferral chain confers entitlement only where it terminates")).
canonical_action(initiate, gloss("Enter the machine without yet doing mathematical work."),
                 coined("the extracted tables open several comparison automata with a contentless entry edge; the alphabet keeps it on the record rather than deleting a transition")).
canonical_action(inscribe_result, gloss("Write the result in notation."),
                 coined("house name, from the inscription vocabulary the counting and decimal tables already use")).
canonical_action(interrupt_before_completion, gloss("Stop the utterance at the token, rather than after the conclusion the token had already lost."),
                 coined("house name for the owner's tutoring move. It is the conserving counterpart of halt_before_completion: stopping a traversal that was required breaks something, and stopping one that had already broken keeps what is left")).
canonical_action(intersect_candidate_sets, gloss("Take what two candidate sets have in common."),
                 coined("house name for the common-factor step")).
canonical_action(isolate_unknown, gloss("Separate the unknown quantity from the known ones so that it stands alone."),
                 coined("house name; the same doing runs in the algebraic solution tables and in the symmetry-constrained side reconstruction")).
canonical_action(iterate_composite_unit, gloss("Repeat a composite unit -- a group held as one thing -- rather than its members."),
                 citation("units coordination: Steffe & Olive 2010; Hackenberg 2013 (the tradition state_vocabulary records for the constructivist display default)")).
canonical_action(iterate_unit, gloss("Repeat a unit to build or to measure a quantity."),
                 citation("iterating: Steffe/Olive/Hackenberg fraction-scheme vocabulary (state_vocabulary q_iterate_count_parts, q_mark_off_lengths); iteration: vocabulary_licenses vl015, risk MEDIUM")).
canonical_action(judge_against_benchmark, gloss("Judge each quantity against a shared reference point."),
                 citation("benchmarking: Clarke & Roche 2009; reference point: Behr, Wachsmuth, Post & Lesh 1984 (state_vocabulary q_select_benchmark)")).
canonical_action(let_the_utterance_run_on, gloss("Recognize the token and let the utterance reach the conclusion it had already lost."),
                 coined("house name; the counterpart of interrupt_before_completion, and the reason the interruption is worth naming at all")).
canonical_action(locate_material_inference, gloss("Find the material inference that would carry this commitment to its consequence."),
                 citation("Brandom, Articulating Reasons, ch. 1, material inference; formal/learner/deontic_scorekeeper.pl:material_inference/3")).
canonical_action(locate_position, gloss("Locate a value's position in the frame already established."),
                 citation("its endpoint locates the number a/b: CCSS 3.NF.A.2b, via Van de Walle (state_vocabulary q_locate_endpoint)")).
canonical_action(match_one_to_one, gloss("Pair the members of two collections against each other."),
                 coined("house name; Van de Walle names the comparison, not the pairing step")).
canonical_action(measure_out_group_size, gloss("Remove a known group size repeatedly to find how many groups the total holds."),
                 citation("measurement division, repeated subtraction: vocabulary_licenses vl006, risk HIGH -- kept distinct from share_into_known_groups for the reason that entry gives")).
canonical_action(measure_quantity, gloss("Determine a quantity's measure with the unit already established."),
                 citation("fraction as a measure: Simon et al. 2018 (state_vocabulary q_measure_with_unit_fraction); measurement construct: vocabulary_licenses vl032, risk HIGH -- disambiguation obligation recorded")).
canonical_action(misname_result, gloss("Name a value that answers a different question than the one asked."),
                 coined("house name; the tables carry these as name_X_as_answer and report_X_as_Y labels")).
canonical_action(misread_intermediate_value, gloss("Read a value the computation itself produced as a different value."),
                 coined("house name. Distinguished from misname_result, which is about the answer, and from the substitute_* family, which puts one relation in place of another: here a carry or a zero column is simply read wrong mid-computation, and the rest of the procedure runs correctly on it")).
canonical_action(name_result, gloss("Say which quantity the answer is."),
                 coined("house name; the tables distinguish naming the answer from writing it and from releasing it")).
canonical_action(name_the_incompatible_token, gloss("Name the word in the utterance whose use in this context is what will not go through."),
                 coined("house name for the owner's tutoring move; the verdicts it consults are knowledge/strategies/action_grammar.pl:interruption_license/6")).
canonical_action(omit_required_step, gloss("Skip a step the viable strategy needs."),
                 coined("house name for the omission edge; the tables carry these as omit_* and skip_* labels")).
canonical_action(omit_vindication_task, gloss("Assert and decline the task-responsibility the assertion carries."),
                 citation("Brandom, Making It Explicit, ch. 3: an assertion whose asserter declines the vindication task keeps its form and loses its force")).
canonical_action(order_by_magnitude, gloss("Put a collection of values in order."),
                 coined("house name; the statistics tables order before they summarise")).
canonical_action(partition_into_equal_parts, gloss("Cut the referent into parts the strategy treats as equal."),
                 citation("equi-partitioning: Steffe 2001, via Boyce & Norton 2017 (state_vocabulary q_partition); partitioning: Van de Walle ch. 15, Fractional Parts; vocabulary_licenses vl026, risk MEDIUM")).
canonical_action(re_express_equivalently, gloss("Rewrite a quantity or relation in a commensurate form without changing what it says."),
                 citation("commensurate: Steffe 2003 (state_vocabulary q_transform_commensurate_1/2); equivalent fractions: vocabulary_licenses vl027, risk LOW")).
canonical_action(read_operand_attribute, gloss("Read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
                 coined("house name for the attribute-reading step; the frameworks name the attributes, not the reading")).
canonical_action(receive_kernel_outcome, gloss("Take the delegated automaton's outcome back as this machine's step."),
                 coined("the return half of dispatch_to_kernel; kept separate because a hand-off and a hand-back are two edges")).
canonical_action(recompose_total, gloss("Put the parts of a decomposition back together into the whole."),
                 citation("composing and decomposing: vocabulary_licenses vl048, risk HIGH -- disambiguation obligation recorded")).
canonical_action(record_conservation, gloss("Record that the strategy kept the relation it was obliged to keep."),
                 coined("house name for the accepting edge of a viable strategy; the tables carry these as preserve_* labels")).
canonical_action(record_deontic_incoherence, gloss("Record which commitments the score could not hold together."),
                 citation("formal/learner/deontic_scorekeeper.pl:crisis_from_deontic_incoherence/3")).
canonical_action(record_deontic_score, gloss("Record the resulting score of commitments and entitlements."),
                 citation("formal/learner/deontic_scorekeeper.pl:scorecard/2")).
canonical_action(record_loss, gloss("Record which relation the strategy failed to keep."),
                 coined("house name for the accepting edge of a deformation; the tables carry these as lose_* labels. Loss names what a strategy did not preserve, never a deficit in the student")).
canonical_action(record_viability, gloss("Record whether the strategy is contextually correct for this input."),
                 coined("the viability context this repository's comparison automata already carry: contextually_correct against contextually_incorrect per input, not correct against wrong")).
canonical_action(register_givens, gloss("Hold the given quantities, figure, or data set as the operands the strategy will work on."),
                 coined("no framework names this step; it is the precondition every table's first edge performs")).
canonical_action(regress_deferral, gloss("Defer along a chain that returns to where it began."),
                 citation("Brandom, Making It Explicit, ch. 4: a deferral chain that closes on itself terminates in no entitlement")).
canonical_action(regroup_to_base, gloss("Trade a completed group of the smaller unit up into one of the larger."),
                 citation("regrouping / trading: vocabulary_licenses vl049, risk HIGH -- the entry records that 'carrying' and 'regrouping' are different words for what students meet as different things; cited as the source of the term, never as a licence to merge carrying with borrowing")).
canonical_action(remove_quantity, gloss("Take one quantity away from another."),
                 citation("separate / take from: vocabulary_licenses vl002, risk HIGH -- disambiguation obligation recorded")).
canonical_action(rename_in_place_of_transforming, gloss("A change of name stands in for the transformation that would have to accompany it."),
                 coined("house name. The task-125 report left this doing unnamed and forced two rows onto substitute_available_relation at low confidence; naming it is the fix that report asked for")).
canonical_action(repair_the_commitment, gloss("Put a revised commitment where the withdrawn one stood."),
                 citation("Brandom, Making It Explicit, ch. 3: what follows a withdrawal is a revised commitment rather than silence")).
canonical_action(replicate_equal_groups, gloss("Build the total as so many groups of so many."),
                 citation("equal groups / array / area: vocabulary_licenses vl009, risk MEDIUM")).
canonical_action(restore_adjustment, gloss("Undo the rounding or the compensation so the original total is recovered."),
                 coined("house name for the closing half of a compensation strategy; the frameworks name the strategy, not its two halves")).
canonical_action(retain_unchanged, gloss("Carry a quantity forward untouched where the strategy owes it nothing: the retention is working, not a conservation and not an omission."),
                 coined("house name, narrowed by the retention split. retain_what_must_survive carries what the strategy is obliged to keep and retain_where_change_was_due carries what it was obliged to change; this action is what is left when neither obligation is in play")).
canonical_action(retain_what_must_survive, gloss("Carry forward, unchanged, the quantity or relation the strategy is obliged not to lose."),
                 coined("house name. Distinguished from record_conservation, which closes a machine, and from retain_unchanged, which carries a value the strategy owes nothing to. Its members are the retentions whose deformation partners lose the same thing: measure_groups_of_size keeps the leftover where share_into_divisor_groups loses it, and unit_preserving_measured_quantity_change keeps the unit where drop_unit_from_measured_quantity_change discards it")).
canonical_action(retain_where_change_was_due, gloss("Carry a quantity forward unchanged where the step required it to change."),
                 coined("house name, and the inversion of retain_what_must_survive. The complement of rename_in_place_of_transforming: one keeps the value and changes the name, the other keeps both where the transformation was owed")).
canonical_action(retrieve_known_fact, gloss("Recall a stored fact instead of reconstructing it."),
                 citation("mastery, know from memory: vocabulary_licenses vl007, risk HIGH -- disambiguation obligation recorded; derived fact strategies: vl051, risk MEDIUM")).
canonical_action(round_to_landmark, gloss("Replace an operand with a nearby landmark value."),
                 citation("pretend-a-ten / use ten: Van de Walle addition strategies; vocabulary_licenses vl052, risk HIGH -- disambiguation obligation recorded")).
canonical_action(scale_multiplicatively, gloss("Multiply a quantity or a term by a factor, keeping the multiplicative relation."),
                 coined("house name; vocabulary_licenses vl034 (operator construct, risk MEDIUM) names the fraction case only")).
canonical_action(select_extremal, gloss("Pick the greatest or the least of the candidates."),
                 coined("house name for the greatest-common-factor and least-common-multiple steps")).
canonical_action(select_part, gloss("Pick out one part, subset, strip, side, or piece as the object of the next step."),
                 coined("house name for the selecting step; distinguished from disembed_part, which keeps the part inside the whole")).
canonical_action(select_unit_scale, gloss("Choose which unit, base, or scale to work in from among the available ones."),
                 coined("house name for the choosing step, distinguished from unitize_referent, which constitutes the unit rather than choosing among units")).
canonical_action(set_aside_irrelevant_attribute, gloss("Set aside a property the conclusion does not depend on."),
                 citation("nondefining attributes: Van de Walle ch. 20, shape classification -- the viable counterpart of treat_relevant_as_irrelevant, kept separate because setting aside orientation is correct where setting aside the referent whole is not")).
canonical_action(share_into_known_groups, gloss("Deal the total into a known number of groups to find how much each group holds."),
                 citation("partition division, sharing division: vocabulary_licenses vl005, risk HIGH -- the entry records that this and measurement division are confused precisely here, so the alphabet keeps them as two canonical actions and never merges them")).
canonical_action(specify_practice_in_vocabulary, gloss("Specify a practice-or-ability in a vocabulary sufficient to say what it is."),
                 citation("Brandom, Between Saying and Doing, lecture 1, VP-sufficiency; formal/pml/mua_relations.pl:vp_sufficient/2")).
canonical_action(substitute_additive_for_multiplicative, gloss("An additive difference stands in for a multiplicative or order relation."),
                 citation("gap thinking: Pearn & Stephens 2004, via Clarke & Roche 2009 (state_vocabulary q_gap_thinking); the additive/multiplicative divide: Vergnaud 1983, via Van de Walle ch. 18")).
canonical_action(substitute_appearance_for_measure, gloss("A figural or perceptual property of the presentation stands in for the quantity the task measures."),
                 citation("misleading perceptual cues in measurement: Van de Walle ch. 19; the prototype-orientation case is Van de Walle ch. 20, shape classification. The split from the other substitutions is this house's")).
canonical_action(substitute_authority_for_inference, gloss("Offer standing or reliability where an inference was what was asked for."),
                 citation("Brandom, Making It Explicit, ch. 4: authority is one of three routes to entitlement, and not a replacement for inference where inference was demanded")).
canonical_action(substitute_count_for_measure, gloss("A discrete count of parts stands in for the relational magnitude those parts make up."),
                 citation("whole number dominance: Behr, Wachsmuth, Post & Lesh 1984 (state_vocabulary q_unequal_partition_piece_count); count marks instead of intervals: Bright, Behr, Post & Wachsmuth 1988 (state_vocabulary q_count_marks_not_intervals) -- two named members of this one class")).
canonical_action(substitute_formal_schema_for_material_inference, gloss("Match the utterance's form to a valid schema where the material inference was what had to hold."),
                 citation("Brandom, Articulating Reasons, ch. 1: formal validity is not what makes a material inference good")).
canonical_action(substitute_operation, gloss("An operation the learner can already carry out stands in for the one the problem calls for."),
                 citation("the operation-choice confusions vocabulary_licenses vl001 through vl006 record, risk HIGH for five of the six -- cited as the documented instances, and the disambiguation obligation each carries is recorded, never discharged into a synonym")).
canonical_action(substitute_scalar_for_structured_quantity, gloss("A single unstructured value stands in for a quantity that carries sign, direction, or spread."),
                 coined("house name; the members are the unsigned-magnitude reading of signed number and the fixed-answer reading of a statistical question, which no one framework names together")).
canonical_action(substitute_symbol_reading, gloss("A reading of a notational sign stands in for the relation that sign writes."),
                 citation("operational against relational readings of the equals sign: Van de Walle ch. 14; the semantic-against-calculation equation distinction, vocabulary_licenses vl036, risk HIGH -- disambiguation obligation recorded")).
canonical_action(substitute_values, gloss("Replace the variables in an expression with their assigned values."),
                 coined("house name; the algebraic tables perform substitution as its own step")).
canonical_action(test_compatibility, gloss("Test whether the commitments now on the score can be held together."),
                 citation("Brandom, Making It Explicit, ch. 3, incompatibility as the material analogue of inconsistency; formal/learner/deontic_scorekeeper.pl:incompatible/2")).
canonical_action(test_criteria, gloss("Test whether the required attributes or conditions hold."),
                 coined("house name for the attribute test the geometry classification tables run")).
canonical_action(transfer_between_operands, gloss("Move an amount from one operand to the other so that the total is unchanged."),
                 citation("compensation: Van de Walle invented strategies; vocabulary_licenses vl051, risk MEDIUM")).
canonical_action(traverse_boundary, gloss("Walk along the sides or segments of a boundary in order."),
                 coined("house name for the perimeter and surface traversal step")).
canonical_action(treat_relevant_as_irrelevant, gloss("Treat a relation the result depends on as though it did not bear on the result."),
                 coined("house name; paired with set_aside_irrelevant_attribute, which does the same thing where it is correct")).
canonical_action(undertake_commitment, gloss("Undertake a commitment to a claim."),
                 citation("Brandom, Making It Explicit, ch. 3; formal/learner/deontic_scorekeeper.pl:undertake_commitment/2")).
canonical_action(unitize_referent, gloss("Constitute the whole or unit that all later measurement refers to."),
                 citation("unitizing: Olive 1999; Norton & Wilkins 2009 (via knowledge/strategies/math/state_vocabulary.pl q_unitize_whole). Referent unit: vocabulary_licenses vl014, risk HIGH -- recorded as a disambiguation obligation, never as a merge licence")).
canonical_action(verify_by_substitution, gloss("Check the result against the relation it has to satisfy."),
                 coined("house name for the check step; vocabulary_licenses vl036, risk HIGH, names the equation kinds rather than the checking -- disambiguation obligation recorded, and no row rests on that entry")).
canonical_action(verify_invariant, gloss("Check that the property the strategy must keep still holds."),
                 coined("house name; covers the coverage, balance, adjacency and closure checks the tables run before accepting")).
canonical_action(withdraw_commitment, gloss("Withdraw a commitment from the score."),
                 citation("Brandom, Making It Explicit, ch. 3, withdrawal as a legitimate move; formal/learner/deontic_scorekeeper.pl:withdraw_commitment/2")).

% action_register(Name, genre(G), register(R), stance(S)).
%
% genre    -- computational, where a step does something to a quantity, or
%             discursive, where a step does something to a deontic score.
% register -- what kind of doing the step is, whatever material it works on.
% stance   -- the step's own normative bearing: conserving where what has to
%             be kept is kept, deforming where it breaks, neutral where the
%             step carries no conservation load of its own.
%
% The two axes are orthogonal on purpose, and the pairs that differ only in
% stance are the point. assign_roles and conflate_roles are both
% constitution; set_aside_irrelevant_attribute and
% treat_relevant_as_irrelevant are both normative; halt_before_completion and
% interrupt_before_completion are both iteration. Each pair is one doing
% under two normative bearings, and collapsing either axis into the other
% would lose that.
%
% This is not PML. PML's three modes of validity and its compressive and
% expansive polarities classify discourse; these axes classify automaton
% actions. Whether the two schemes line up is an open question that nothing
% here answers.
action_register(accept_without_check, genre(computational), register(normative), stance(deforming)).
action_register(accumulate_total, genre(computational), register(iteration), stance(neutral)).
action_register(acknowledge_commitment, genre(discursive), register(constitution), stance(neutral)).
action_register(align_to_common_unit, genre(computational), register(transformation), stance(conserving)).
action_register(apply_quantity_change, genre(computational), register(operation), stance(neutral)).
action_register(apply_stored_rule, genre(computational), register(operation), stance(neutral)).
action_register(assign_roles, genre(computational), register(constitution), stance(neutral)).
action_register(assume_vindication_task, genre(discursive), register(normative), stance(conserving)).
action_register(attach_units_coordination, genre(computational), register(inscription), stance(conserving)).
action_register(attend_to_utterance, genre(discursive), register(constitution), stance(neutral)).
action_register(attribute_commitment, genre(discursive), register(constitution), stance(neutral)).
action_register(authorize_deferral, genre(discursive), register(operation), stance(conserving)).
action_register(certify_meaning_use_relation, genre(discursive), register(normative), stance(conserving)).
action_register(challenge_entitlement, genre(discursive), register(comparison), stance(neutral)).
action_register(combine_quantities, genre(computational), register(operation), stance(neutral)).
action_register(commute_operands, genre(computational), register(transformation), stance(conserving)).
action_register(compare_additive_gaps, genre(computational), register(comparison), stance(neutral)).
action_register(compare_magnitudes, genre(computational), register(comparison), stance(neutral)).
action_register(compare_residuals, genre(computational), register(comparison), stance(neutral)).
action_register(compose_expression, genre(computational), register(transformation), stance(neutral)).
action_register(compute_product, genre(computational), register(operation), stance(neutral)).
action_register(compute_quotient, genre(computational), register(operation), stance(neutral)).
action_register(conflate_attribution_with_acknowledgement, genre(discursive), register(constitution), stance(deforming)).
action_register(conflate_roles, genre(computational), register(constitution), stance(deforming)).
action_register(count_back_from, genre(computational), register(iteration), stance(neutral)).
action_register(count_on_from, genre(computational), register(iteration), stance(neutral)).
action_register(count_units, genre(computational), register(iteration), stance(neutral)).
action_register(count_up_to_target, genre(computational), register(iteration), stance(neutral)).
action_register(decompose_by_place, genre(computational), register(partition), stance(neutral)).
action_register(decompose_operand, genre(computational), register(partition), stance(neutral)).
action_register(decompose_region, genre(computational), register(partition), stance(neutral)).
action_register(defer_to_asserter, genre(discursive), register(delegation), stance(neutral)).
action_register(deploy_vocabulary_from_practice, genre(discursive), register(transformation), stance(neutral)).
action_register(derive_consequent, genre(discursive), register(comparison), stance(neutral)).
action_register(disembed_part, genre(computational), register(partition), stance(neutral)).
action_register(dispatch_to_kernel, genre(computational), register(delegation), stance(neutral)).
action_register(distribute_over_partition, genre(computational), register(transformation), stance(conserving)).
action_register(double_count, genre(computational), register(iteration), stance(deforming)).
action_register(elaborate_practice_algorithmically, genre(discursive), register(transformation), stance(neutral)).
action_register(emit_result, genre(computational), register(inscription), stance(neutral)).
action_register(enumerate_candidates, genre(computational), register(search), stance(neutral)).
action_register(establish_reference_frame, genre(computational), register(constitution), stance(neutral)).
action_register(evaluate_expression, genre(computational), register(operation), stance(neutral)).
action_register(exchange_base_down, genre(computational), register(transformation), stance(conserving)).
action_register(exhaust_resource, genre(computational), register(operation), stance(neutral)).
action_register(explicate_practice_in_elaborated_vocabulary, genre(discursive), register(transformation), stance(conserving)).
action_register(filter_by_constraint, genre(computational), register(search), stance(neutral)).
action_register(grant_entitlement, genre(discursive), register(operation), stance(conserving)).
action_register(grant_entitlement_without_grounding, genre(discursive), register(normative), stance(deforming)).
action_register(halt_before_completion, genre(computational), register(iteration), stance(deforming)).
action_register(hold_incompatible_commitments, genre(discursive), register(normative), stance(deforming)).
action_register(inherit_entitlement, genre(discursive), register(delegation), stance(neutral)).
action_register(initiate, genre(computational), register(constitution), stance(neutral)).
action_register(inscribe_result, genre(computational), register(inscription), stance(neutral)).
action_register(interrupt_before_completion, genre(discursive), register(iteration), stance(conserving)).
action_register(intersect_candidate_sets, genre(computational), register(search), stance(neutral)).
action_register(isolate_unknown, genre(computational), register(comparison), stance(neutral)).
action_register(iterate_composite_unit, genre(computational), register(iteration), stance(neutral)).
action_register(iterate_unit, genre(computational), register(iteration), stance(neutral)).
action_register(judge_against_benchmark, genre(computational), register(comparison), stance(neutral)).
action_register(let_the_utterance_run_on, genre(discursive), register(iteration), stance(deforming)).
action_register(locate_material_inference, genre(discursive), register(comparison), stance(neutral)).
action_register(locate_position, genre(computational), register(comparison), stance(neutral)).
action_register(match_one_to_one, genre(computational), register(comparison), stance(neutral)).
action_register(measure_out_group_size, genre(computational), register(operation), stance(neutral)).
action_register(measure_quantity, genre(computational), register(iteration), stance(neutral)).
action_register(misname_result, genre(computational), register(inscription), stance(deforming)).
action_register(misread_intermediate_value, genre(computational), register(constitution), stance(deforming)).
action_register(name_result, genre(computational), register(inscription), stance(neutral)).
action_register(name_the_incompatible_token, genre(discursive), register(comparison), stance(neutral)).
action_register(omit_required_step, genre(computational), register(normative), stance(deforming)).
action_register(omit_vindication_task, genre(discursive), register(normative), stance(deforming)).
action_register(order_by_magnitude, genre(computational), register(comparison), stance(neutral)).
action_register(partition_into_equal_parts, genre(computational), register(partition), stance(neutral)).
action_register(re_express_equivalently, genre(computational), register(transformation), stance(conserving)).
action_register(read_operand_attribute, genre(computational), register(constitution), stance(neutral)).
action_register(receive_kernel_outcome, genre(computational), register(delegation), stance(neutral)).
action_register(recompose_total, genre(computational), register(transformation), stance(conserving)).
action_register(record_conservation, genre(computational), register(normative), stance(conserving)).
action_register(record_deontic_incoherence, genre(discursive), register(normative), stance(deforming)).
action_register(record_deontic_score, genre(discursive), register(normative), stance(conserving)).
action_register(record_loss, genre(computational), register(normative), stance(deforming)).
action_register(record_viability, genre(computational), register(normative), stance(conserving)).
action_register(register_givens, genre(computational), register(constitution), stance(neutral)).
action_register(regress_deferral, genre(discursive), register(delegation), stance(deforming)).
action_register(regroup_to_base, genre(computational), register(transformation), stance(conserving)).
action_register(remove_quantity, genre(computational), register(operation), stance(neutral)).
action_register(rename_in_place_of_transforming, genre(computational), register(transformation), stance(deforming)).
action_register(repair_the_commitment, genre(discursive), register(transformation), stance(conserving)).
action_register(replicate_equal_groups, genre(computational), register(operation), stance(neutral)).
action_register(restore_adjustment, genre(computational), register(transformation), stance(conserving)).
action_register(retain_unchanged, genre(computational), register(transformation), stance(neutral)).
action_register(retain_what_must_survive, genre(computational), register(transformation), stance(conserving)).
action_register(retain_where_change_was_due, genre(computational), register(transformation), stance(deforming)).
action_register(retrieve_known_fact, genre(computational), register(operation), stance(neutral)).
action_register(round_to_landmark, genre(computational), register(transformation), stance(neutral)).
action_register(scale_multiplicatively, genre(computational), register(transformation), stance(neutral)).
action_register(select_extremal, genre(computational), register(search), stance(neutral)).
action_register(select_part, genre(computational), register(partition), stance(neutral)).
action_register(select_unit_scale, genre(computational), register(constitution), stance(neutral)).
action_register(set_aside_irrelevant_attribute, genre(computational), register(normative), stance(conserving)).
action_register(share_into_known_groups, genre(computational), register(operation), stance(neutral)).
action_register(specify_practice_in_vocabulary, genre(discursive), register(transformation), stance(neutral)).
action_register(substitute_additive_for_multiplicative, genre(computational), register(comparison), stance(deforming)).
action_register(substitute_appearance_for_measure, genre(computational), register(comparison), stance(deforming)).
action_register(substitute_authority_for_inference, genre(discursive), register(operation), stance(deforming)).
action_register(substitute_count_for_measure, genre(computational), register(iteration), stance(deforming)).
action_register(substitute_formal_schema_for_material_inference, genre(discursive), register(comparison), stance(deforming)).
action_register(substitute_operation, genre(computational), register(operation), stance(deforming)).
action_register(substitute_scalar_for_structured_quantity, genre(computational), register(transformation), stance(deforming)).
action_register(substitute_symbol_reading, genre(computational), register(constitution), stance(deforming)).
action_register(substitute_values, genre(computational), register(transformation), stance(neutral)).
action_register(test_compatibility, genre(discursive), register(normative), stance(conserving)).
action_register(test_criteria, genre(computational), register(normative), stance(conserving)).
action_register(transfer_between_operands, genre(computational), register(transformation), stance(conserving)).
action_register(traverse_boundary, genre(computational), register(iteration), stance(neutral)).
action_register(treat_relevant_as_irrelevant, genre(computational), register(normative), stance(deforming)).
action_register(undertake_commitment, genre(discursive), register(operation), stance(neutral)).
action_register(unitize_referent, genre(computational), register(constitution), stance(neutral)).
action_register(verify_by_substitution, genre(computational), register(normative), stance(conserving)).
action_register(verify_invariant, genre(computational), register(normative), stance(conserving)).
action_register(withdraw_commitment, genre(discursive), register(operation), stance(neutral)).

% action_kinship(Computational, Discursive, basis(Text)) -- the same doing on
% different material. The two genres share exactly one action name
% (register_givens); these pairs are why they can still be compared. Kinship
% is not identity: a kin pair may differ in stance, and the
% halt_before_completion / interrupt_before_completion pair does.
action_kinship(accept_without_check, grant_entitlement_without_grounding,
               basis("both accept a structure as usable where the check that would license it never ran")).
action_kinship(assign_roles, attribute_commitment,
               basis("both bind a given to a role in a relation the machine will then work on: a quantity to whole-or-part, an utterance to another speaker's score")).
action_kinship(conflate_roles, conflate_attribution_with_acknowledgement,
               basis("both collapse two structurally distinct roles into one: group count with share size, attributed with acknowledged")).
action_kinship(dispatch_to_kernel, defer_to_asserter,
               basis("both hand the step to another authority and wait on what comes back")).
action_kinship(halt_before_completion, interrupt_before_completion,
               basis("the same doing, stopping before the end, under opposite normative bearings: stopping a required traversal breaks it, stopping one whose relation was already lost keeps what is left. The pair is why stance and register have to be two axes rather than one")).
action_kinship(iterate_unit, elaborate_practice_algorithmically,
               basis("both repeat a unit to build something larger, where the unit is a quantity in one genre and a practice-or-ability in the other")).
action_kinship(omit_required_step, omit_vindication_task,
               basis("both decline a step the practice requires and carry on as though it had run")).
action_kinship(receive_kernel_outcome, inherit_entitlement,
               basis("both take back what the delegated authority returned and carry it as this machine's own")).
action_kinship(record_conservation, record_deontic_score,
               basis("both are the closing edge of a machine that kept what it had to keep")).
action_kinship(record_loss, record_deontic_incoherence,
               basis("both are the closing edge of a machine that did not, and both name what was not kept rather than a deficit in whoever ran it")).
action_kinship(set_aside_irrelevant_attribute, withdraw_commitment,
               basis("both remove something from what bears on the outcome, and in both the removal is a legitimate move rather than a loss")).
action_kinship(substitute_additive_for_multiplicative, substitute_formal_schema_for_material_inference,
               basis("both put an available form in place of the relation that had to hold: an additive difference for a multiplicative order, a valid schema for a material inference")).
action_kinship(substitute_operation, substitute_authority_for_inference,
               basis("both put a move the agent can already make in place of the one the task called for")).
action_kinship(verify_invariant, test_compatibility,
               basis("both check that what has to hold still holds before the machine closes: a geometric or numerical invariant, the compatibility of the commitments on a score")).

% action_maps(Family, Signature, LocalLabel, CanonicalName, confidence(C),
%             evidence(Text), status(review_pending)).
%
% confidence(high)   -- the doing at that position is the canonical action's
%                       doing, with no residue worth naming.
% confidence(medium) -- the canonical action names the doing but drops a
%                       distinction the local label carries, or the position
%                       rule decided between two defensible canonicals.
% confidence(low)    -- the canonical action is the closest of a poor fit; the
%                       row is a candidate for extending the alphabet.
action_maps(addition, append_column_sum_without_carrying, align_addends_by_place_value, align_to_common_unit,
            confidence(high),
            evidence("addition/append_column_sum_without_carrying, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. bring both quantities into a shared unit, denominator, or decimal scale so they can be measured against each other."),
            status(review_pending)).
action_maps(addition, append_column_sum_without_carrying, compute_raw_column_sums_without_regrouping, omit_required_step,
            confidence(high),
            evidence("addition/append_column_sum_without_carrying, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. sums each column with the regrouping the column algorithm requires never running"),
            status(review_pending)).
action_maps(addition, append_column_sum_without_carrying, concatenate_partial_sums, substitute_operation,
            confidence(high),
            evidence("addition/append_column_sum_without_carrying, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. juxtaposes the column sums as digits where the algorithm adds them at their places"),
            status(review_pending)).
action_maps(addition, append_column_sum_without_carrying, lose_base_ten_regrouping, record_loss,
            confidence(high),
            evidence("addition/append_column_sum_without_carrying, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(addition, append_column_sum_without_carrying, write_full_column_sums_in_place, inscribe_result,
            confidence(high),
            evidence("addition/append_column_sum_without_carrying, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. write the result in notation."),
            status(review_pending)).
action_maps(addition, base_ones_chunking, add_base_chunk, combine_quantities,
            confidence(high),
            evidence("addition/base_ones_chunking, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, witnessed. join two quantities into their sum."),
            status(review_pending)).
action_maps(addition, base_ones_chunking, add_ones_chunk, combine_quantities,
            confidence(high),
            evidence("addition/base_ones_chunking, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, witnessed. join two quantities into their sum."),
            status(review_pending)).
action_maps(addition, base_ones_chunking, decompose_second_addend, decompose_operand,
            confidence(high),
            evidence("addition/base_ones_chunking, q_start -> q_step_1: 1 of the machine's 4 distinct edges, witnessed. split one operand into pieces a later step can use, not along place boundaries."),
            status(review_pending)).
action_maps(addition, base_ones_chunking, preserve_all_decomposed_parts, record_conservation,
            confidence(high),
            evidence("addition/base_ones_chunking, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, witnessed. record that the strategy kept the relation it was obliged to keep."),
            status(review_pending)).
action_maps(addition, column_addition_with_carrying, align_addends_by_place_value, align_to_common_unit,
            confidence(high),
            evidence("addition/column_addition_with_carrying, q_start -> q_step_1: 1 of the machine's 6 distinct edges, witnessed. bring both quantities into a shared unit, denominator, or decimal scale so they can be measured against each other."),
            status(review_pending)).
action_maps(addition, column_addition_with_carrying, carry_final_column_if_needed, regroup_to_base,
            confidence(high),
            evidence("addition/column_addition_with_carrying, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges, witnessed. trade a completed group of the smaller unit up into one of the larger."),
            status(review_pending)).
action_maps(addition, column_addition_with_carrying, compose_column_sum, accumulate_total,
            confidence(high),
            evidence("addition/column_addition_with_carrying, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, witnessed. add the counted or measured pieces into a running total."),
            status(review_pending)).
action_maps(addition, column_addition_with_carrying, preserve_base_ten_regrouping, record_conservation,
            confidence(high),
            evidence("addition/column_addition_with_carrying, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, witnessed. record that the strategy kept the relation it was obliged to keep."),
            status(review_pending)).
action_maps(addition, column_addition_with_carrying, process_columns_right_to_left, apply_stored_rule,
            confidence(high),
            evidence("addition/column_addition_with_carrying, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, witnessed. carry out a remembered formula, rule, or prescribed procedural step."),
            status(review_pending)).
action_maps(addition, column_addition_with_carrying, write_place_digits, inscribe_result,
            confidence(high),
            evidence("addition/column_addition_with_carrying, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges, witnessed. write the result in notation."),
            status(review_pending)).
action_maps(addition, count_all_instead_of_known_fact, count_all_ticks, count_units,
            confidence(high),
            evidence("addition/count_all_instead_of_known_fact, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, witnessed. count how many units the iteration or the partition produced."),
            status(review_pending)).
action_maps(addition, count_all_instead_of_known_fact, fail_to_retrieve_stored_sum, exhaust_resource,
            confidence(high),
            evidence("addition/count_all_instead_of_known_fact, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, witnessed. reaches for the stored sum and finds none, which is what forces the count-all fallback at the next edge; not a step skipped but a resource met at its limit"),
            status(review_pending)).
action_maps(addition, count_all_instead_of_known_fact, preserve_result_but_lose_fact_fluency, record_loss,
            confidence(medium),
            evidence("addition/count_all_instead_of_known_fact, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, witnessed. terminal edge naming both a kept result and a lost norm; the map takes the loss clause, and the kept-result clause is a distinction the alphabet drops"),
            status(review_pending)).
action_maps(addition, count_all_instead_of_known_fact, recognize_number_combination, register_givens,
            confidence(high),
            evidence("addition/count_all_instead_of_known_fact, q_start -> q_step_1: 1 of the machine's 4 distinct edges, witnessed. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(addition, count_all_when_count_on_available, count_first_addend_from_zero, count_units,
            confidence(high),
            evidence("addition/count_all_when_count_on_available, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, witnessed. enumerates the first addend from zero rather than taking it as a composite already counted"),
            status(review_pending)).
action_maps(addition, count_all_when_count_on_available, count_second_addend_from_first_total, count_on_from,
            confidence(high),
            evidence("addition/count_all_when_count_on_available, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, witnessed. count forward from a value already held, rather than from one."),
            status(review_pending)).
action_maps(addition, count_all_when_count_on_available, preserve_result_but_lose_count_on_efficiency, record_loss,
            confidence(medium),
            evidence("addition/count_all_when_count_on_available, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, witnessed. terminal edge naming both a kept result and a lost norm; the map takes the loss clause, and the kept-result clause is a distinction the alphabet drops"),
            status(review_pending)).
action_maps(addition, count_all_when_count_on_available, reset_to_zero_instead_of_starting_from_composite, substitute_operation,
            confidence(high),
            evidence("addition/count_all_when_count_on_available, q_start -> q_step_1: 1 of the machine's 4 distinct edges, witnessed. counts from zero where the first addend was available as a composite to count on from"),
            status(review_pending)).
action_maps(addition, count_on_from_larger, choose_larger_addend_as_start, assign_roles,
            confidence(high),
            evidence("addition/count_on_from_larger, q_start -> q_step_1: 1 of the machine's 4 distinct edges, witnessed. bind each given to its structural role in the relation: which quantity is the whole and which the part, group count against group size, which term is the repeated factor, which coordinate comes first."),
            status(review_pending)).
action_maps(addition, count_on_from_larger, hold_other_addend_as_count, assign_roles,
            confidence(high),
            evidence("addition/count_on_from_larger, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, witnessed. bind each given to its structural role in the relation: which quantity is the whole and which the part, group count against group size, which term is the repeated factor, which coordinate comes first."),
            status(review_pending)).
action_maps(addition, count_on_from_larger, iterate_successor_ticks, count_on_from,
            confidence(high),
            evidence("addition/count_on_from_larger, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, witnessed. repeats the successor step from the chosen start, the held addend many times"),
            status(review_pending)).
action_maps(addition, count_on_from_larger, name_last_tick_as_sum, name_result,
            confidence(high),
            evidence("addition/count_on_from_larger, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, witnessed. say which quantity the answer is."),
            status(review_pending)).
action_maps(addition, derived_fact_adjustment, adjust_known_sum_by, combine_quantities,
            confidence(high),
            evidence("addition/derived_fact_adjustment, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. adds the target-to-anchor distance onto the recalled sum"),
            status(review_pending)).
action_maps(addition, derived_fact_adjustment, compare_target_to_anchor, compare_magnitudes,
            confidence(high),
            evidence("addition/derived_fact_adjustment, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. reads how far the target sits from the recalled anchor fact, which is the amount the next edge adjusts by"),
            status(review_pending)).
action_maps(addition, derived_fact_adjustment, preserve_problem_relation, record_conservation,
            confidence(high),
            evidence("addition/derived_fact_adjustment, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. record that the strategy kept the relation it was obliged to keep."),
            status(review_pending)).
action_maps(addition, derived_fact_adjustment, recall_nearby_known_fact, retrieve_known_fact,
            confidence(high),
            evidence("addition/derived_fact_adjustment, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. recall a stored fact instead of reconstructing it."),
            status(review_pending)).
action_maps(addition, drop_carry_to_next_column, align_addends_by_place_value, align_to_common_unit,
            confidence(high),
            evidence("addition/drop_carry_to_next_column, q_start -> q_step_1: 1 of the machine's 6 distinct edges, static only. bring both quantities into a shared unit, denominator, or decimal scale so they can be measured against each other."),
            status(review_pending)).
action_maps(addition, drop_carry_to_next_column, compose_column_sum_without_carry, accumulate_total,
            confidence(medium),
            evidence("addition/drop_carry_to_next_column, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, static only. accumulates the column results with the carries already discarded"),
            status(review_pending)).
action_maps(addition, drop_carry_to_next_column, discard_generated_carries, treat_relevant_as_irrelevant,
            confidence(high),
            evidence("addition/drop_carry_to_next_column, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges, static only. treat a relation the result depends on as though it did not bear on the result."),
            status(review_pending)).
action_maps(addition, drop_carry_to_next_column, lose_base_ten_regrouping, record_loss,
            confidence(high),
            evidence("addition/drop_carry_to_next_column, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(addition, drop_carry_to_next_column, process_columns_right_to_left, apply_stored_rule,
            confidence(high),
            evidence("addition/drop_carry_to_next_column, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, static only. carry out a remembered formula, rule, or prescribed procedural step."),
            status(review_pending)).
action_maps(addition, drop_carry_to_next_column, write_place_digits, inscribe_result,
            confidence(high),
            evidence("addition/drop_carry_to_next_column, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges, static only. write the result in notation."),
            status(review_pending)).
action_maps(addition, dropped_ones_chunk, add_base_chunk, combine_quantities,
            confidence(high),
            evidence("addition/dropped_ones_chunk, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. join two quantities into their sum."),
            status(review_pending)).
action_maps(addition, dropped_ones_chunk, decompose_second_addend, decompose_operand,
            confidence(high),
            evidence("addition/dropped_ones_chunk, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. split one operand into pieces a later step can use, not along place boundaries."),
            status(review_pending)).
action_maps(addition, dropped_ones_chunk, drop_ones_chunk, halt_before_completion,
            confidence(high),
            evidence("addition/dropped_ones_chunk, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. stops after the base chunk, leaving the ones chunk of the decomposition unused"),
            status(review_pending)).
action_maps(addition, dropped_ones_chunk, lose_decomposed_remainder, record_loss,
            confidence(high),
            evidence("addition/dropped_ones_chunk, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(addition, known_fact_retrieval, recognize_number_combination, register_givens,
            confidence(high),
            evidence("addition/known_fact_retrieval, q_start -> q_step_1: 1 of the machine's 3 distinct edges, witnessed. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(addition, known_fact_retrieval, retrieve_stored_sum, retrieve_known_fact,
            confidence(high),
            evidence("addition/known_fact_retrieval, q_step_1 -> q_step_2: 1 of the machine's 3 distinct edges, witnessed. recall a stored fact instead of reconstructing it."),
            status(review_pending)).
action_maps(addition, known_fact_retrieval, state_memorized_sum, name_result,
            confidence(high),
            evidence("addition/known_fact_retrieval, q_step_2 -> q_accept: 1 of the machine's 3 distinct edges, witnessed. say which quantity the answer is."),
            status(review_pending)).
action_maps(addition, make_base_transfer, count_distance_to_base, count_up_to_target,
            confidence(high),
            evidence("addition/make_base_transfer, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, witnessed. count forward until a named target is reached, holding the distance travelled."),
            status(review_pending)).
action_maps(addition, make_base_transfer, identify_target_base, select_unit_scale,
            confidence(high),
            evidence("addition/make_base_transfer, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, witnessed. choose which unit, base, or scale to work in from among the available ones."),
            status(review_pending)).
action_maps(addition, make_base_transfer, order_addends, assign_roles,
            confidence(high),
            evidence("addition/make_base_transfer, q_start -> q_step_1: 1 of the machine's 5 distinct edges, witnessed. orders the two addends so that the later transfer from smaller to larger is defined"),
            status(review_pending)).
action_maps(addition, make_base_transfer, preserve_total_by_balanced_transfer, record_conservation,
            confidence(high),
            evidence("addition/make_base_transfer, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, witnessed. record that the strategy kept the relation it was obliged to keep."),
            status(review_pending)).
action_maps(addition, make_base_transfer, transfer_from_smaller_to_larger, transfer_between_operands,
            confidence(high),
            evidence("addition/make_base_transfer, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, witnessed. move an amount from one operand to the other so that the total is unchanged."),
            status(review_pending)).
action_maps(addition, make_ten_drop_leftover, choose_addend_near_base, assign_roles,
            confidence(high),
            evidence("addition/make_ten_drop_leftover, q_start -> q_step_1: 1 of the machine's 5 distinct edges, witnessed. bind each given to its structural role in the relation: which quantity is the whole and which the part, group count against group size, which term is the repeated factor, which coordinate comes first."),
            status(review_pending)).
action_maps(addition, make_ten_drop_leftover, drop_leftover_after_making_base, halt_before_completion,
            confidence(high),
            evidence("addition/make_ten_drop_leftover, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, witnessed. stops after the base is made, leaving the second split part unused"),
            status(review_pending)).
action_maps(addition, make_ten_drop_leftover, lose_total_conservation, record_loss,
            confidence(high),
            evidence("addition/make_ten_drop_leftover, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, witnessed. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(addition, make_ten_drop_leftover, make_base, regroup_to_base,
            confidence(medium),
            evidence("addition/make_ten_drop_leftover, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, witnessed. composes the base unit out of the near-base addend and part of the split addend"),
            status(review_pending)).
action_maps(addition, make_ten_drop_leftover, split_other_addend, decompose_operand,
            confidence(high),
            evidence("addition/make_ten_drop_leftover, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, witnessed. split one operand into pieces a later step can use, not along place boundaries."),
            status(review_pending)).
action_maps(addition, make_ten_split_leftover, add_leftover_after_base, combine_quantities,
            confidence(high),
            evidence("addition/make_ten_split_leftover, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, witnessed. join two quantities into their sum."),
            status(review_pending)).
action_maps(addition, make_ten_split_leftover, choose_addend_near_base, assign_roles,
            confidence(high),
            evidence("addition/make_ten_split_leftover, q_start -> q_step_1: 1 of the machine's 5 distinct edges, witnessed. bind each given to its structural role in the relation: which quantity is the whole and which the part, group count against group size, which term is the repeated factor, which coordinate comes first."),
            status(review_pending)).
action_maps(addition, make_ten_split_leftover, make_base, regroup_to_base,
            confidence(medium),
            evidence("addition/make_ten_split_leftover, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, witnessed. composes the base unit out of the near-base addend and part of the split addend"),
            status(review_pending)).
action_maps(addition, make_ten_split_leftover, preserve_total_by_using_both_split_parts, record_conservation,
            confidence(high),
            evidence("addition/make_ten_split_leftover, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, witnessed. record that the strategy kept the relation it was obliged to keep."),
            status(review_pending)).
action_maps(addition, make_ten_split_leftover, split_other_addend, decompose_operand,
            confidence(high),
            evidence("addition/make_ten_split_leftover, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, witnessed. split one operand into pieces a later step can use, not along place boundaries."),
            status(review_pending)).
action_maps(addition, rote_derived_fact_rule_misfire, apply_verbal_rule_with_wrong_adjustment, apply_stored_rule,
            confidence(medium),
            evidence("addition/rote_derived_fact_rule_misfire, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. carries out a remembered verbal rule; that its adjustment is wrong is recorded at the machine's last edge"),
            status(review_pending)).
action_maps(addition, rote_derived_fact_rule_misfire, lose_problem_relation, record_loss,
            confidence(high),
            evidence("addition/rote_derived_fact_rule_misfire, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(addition, rote_derived_fact_rule_misfire, notice_that_numbers_are_near_but_not_how_near, read_operand_attribute,
            confidence(medium),
            evidence("addition/rote_derived_fact_rule_misfire, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. reads that the target is near the anchor without reading the distance, which is what the misfired rule then guesses"),
            status(review_pending)).
action_maps(addition, rote_derived_fact_rule_misfire, recall_nearby_known_fact, retrieve_known_fact,
            confidence(high),
            evidence("addition/rote_derived_fact_rule_misfire, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. recall a stored fact instead of reconstructing it."),
            status(review_pending)).
action_maps(addition, round_then_adjust, add_with_rounded_number, combine_quantities,
            confidence(high),
            evidence("addition/round_then_adjust, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, witnessed. join two quantities into their sum."),
            status(review_pending)).
action_maps(addition, round_then_adjust, adjust_back_by, restore_adjustment,
            confidence(high),
            evidence("addition/round_then_adjust, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, witnessed. undo the rounding or the compensation so the original total is recovered."),
            status(review_pending)).
action_maps(addition, round_then_adjust, choose_rounding_target, assign_roles,
            confidence(high),
            evidence("addition/round_then_adjust, q_start -> q_step_1: 1 of the machine's 5 distinct edges, witnessed. binds one operand to the role of the one to be rounded"),
            status(review_pending)).
action_maps(addition, round_then_adjust, identify_target_base, select_unit_scale,
            confidence(high),
            evidence("addition/round_then_adjust, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, witnessed. choose which unit, base, or scale to work in from among the available ones."),
            status(review_pending)).
action_maps(addition, round_then_adjust, round_up_by, round_to_landmark,
            confidence(high),
            evidence("addition/round_then_adjust, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, witnessed. replace an operand with a nearby landmark value."),
            status(review_pending)).
action_maps(addition, round_without_adjusting, add_with_rounded_number, combine_quantities,
            confidence(high),
            evidence("addition/round_without_adjusting, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges, witnessed. join two quantities into their sum."),
            status(review_pending)).
action_maps(addition, round_without_adjusting, choose_rounding_target, assign_roles,
            confidence(high),
            evidence("addition/round_without_adjusting, q_start -> q_step_1: 1 of the machine's 6 distinct edges, witnessed. binds one operand to the role of the one to be rounded"),
            status(review_pending)).
action_maps(addition, round_without_adjusting, identify_target_base, select_unit_scale,
            confidence(high),
            evidence("addition/round_without_adjusting, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, witnessed. choose which unit, base, or scale to work in from among the available ones."),
            status(review_pending)).
action_maps(addition, round_without_adjusting, lose_total_conservation, record_loss,
            confidence(high),
            evidence("addition/round_without_adjusting, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, witnessed. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(addition, round_without_adjusting, omit_adjustment, omit_required_step,
            confidence(high),
            evidence("addition/round_without_adjusting, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, witnessed. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(addition, round_without_adjusting, round_up_by, round_to_landmark,
            confidence(high),
            evidence("addition/round_without_adjusting, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges, witnessed. replace an operand with a nearby landmark value."),
            status(review_pending)).
action_maps(addition, unbalanced_make_base_compensation, add_compensation_to_larger, combine_quantities,
            confidence(high),
            evidence("addition/unbalanced_make_base_compensation, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges, static only. adds the compensation onto the larger addend; the balanced transfer would have taken it from the other, which the next edge declines to do"),
            status(review_pending)).
action_maps(addition, unbalanced_make_base_compensation, count_distance_to_base, count_up_to_target,
            confidence(high),
            evidence("addition/unbalanced_make_base_compensation, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges, static only. count forward until a named target is reached, holding the distance travelled."),
            status(review_pending)).
action_maps(addition, unbalanced_make_base_compensation, identify_target_base, select_unit_scale,
            confidence(high),
            evidence("addition/unbalanced_make_base_compensation, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, static only. choose which unit, base, or scale to work in from among the available ones."),
            status(review_pending)).
action_maps(addition, unbalanced_make_base_compensation, leave_other_addend_unchanged, retain_where_change_was_due,
            confidence(high),
            evidence("addition/unbalanced_make_base_compensation, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, static only. leaves the second addend untouched at the edge where a balanced transfer obliged it to give up what the first received"),
            status(review_pending)).
action_maps(addition, unbalanced_make_base_compensation, lose_total_conservation, record_loss,
            confidence(high),
            evidence("addition/unbalanced_make_base_compensation, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(addition, unbalanced_make_base_compensation, order_addends, assign_roles,
            confidence(high),
            evidence("addition/unbalanced_make_base_compensation, q_start -> q_step_1: 1 of the machine's 6 distinct edges, static only. orders the two addends so that the later transfer from smaller to larger is defined"),
            status(review_pending)).
action_maps(addition, wrong_carry_amount_to_next_column, align_addends_by_place_value, align_to_common_unit,
            confidence(high),
            evidence("addition/wrong_carry_amount_to_next_column, q_start -> q_step_1: 1 of the machine's 6 distinct edges, static only. bring both quantities into a shared unit, denominator, or decimal scale so they can be measured against each other."),
            status(review_pending)).
action_maps(addition, wrong_carry_amount_to_next_column, carry_final_column_if_needed, regroup_to_base,
            confidence(high),
            evidence("addition/wrong_carry_amount_to_next_column, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, static only. trade a completed group of the smaller unit up into one of the larger."),
            status(review_pending)).
action_maps(addition, wrong_carry_amount_to_next_column, lose_base_ten_regrouping, record_loss,
            confidence(high),
            evidence("addition/wrong_carry_amount_to_next_column, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(addition, wrong_carry_amount_to_next_column, misread_carry_amount, misread_intermediate_value,
            confidence(high),
            evidence("addition/wrong_carry_amount_to_next_column, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges, static only. reads the generated carry as a different amount; the columns are then processed correctly on the wrong figure"),
            status(review_pending)).
action_maps(addition, wrong_carry_amount_to_next_column, process_columns_right_to_left, apply_stored_rule,
            confidence(high),
            evidence("addition/wrong_carry_amount_to_next_column, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, static only. carry out a remembered formula, rule, or prescribed procedural step."),
            status(review_pending)).
action_maps(addition, wrong_carry_amount_to_next_column, write_place_digits, inscribe_result,
            confidence(high),
            evidence("addition/wrong_carry_amount_to_next_column, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges, static only. write the result in notation."),
            status(review_pending)).
action_maps(algebraic, balance_preserving_linear_solution, apply_balance_preserving_steps, re_express_equivalently,
            confidence(high),
            evidence("algebraic/balance_preserving_linear_solution, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. rewrites the equation without changing which assignments satisfy it"),
            status(review_pending)).
action_maps(algebraic, balance_preserving_linear_solution, isolate_unknown, isolate_unknown,
            confidence(high),
            evidence("algebraic/balance_preserving_linear_solution, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. separate the unknown quantity from the known ones so that it stands alone."),
            status(review_pending)).
action_maps(algebraic, balance_preserving_linear_solution, read_equation_as_relation, register_givens,
            confidence(medium),
            evidence("algebraic/balance_preserving_linear_solution, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. holds the equation as a relation between two expressions rather than as an instruction to compute"),
            status(review_pending)).
action_maps(algebraic, balance_preserving_linear_solution, verify_by_substitution, verify_by_substitution,
            confidence(high),
            evidence("algebraic/balance_preserving_linear_solution, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. check the result against the relation it has to satisfy."),
            status(review_pending)).
action_maps(algebraic, contextual_linear_equation_construction, assign_referent_roles, assign_roles,
            confidence(high),
            evidence("algebraic/contextual_linear_equation_construction, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, static only. bind each given to its structural role in the relation: which quantity is the whole and which the part, group count against group size, which term is the repeated factor, which coordinate comes first."),
            status(review_pending)).
action_maps(algebraic, contextual_linear_equation_construction, coordinate_constant_offset, compose_expression,
            confidence(high),
            evidence("algebraic/contextual_linear_equation_construction, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges, static only. assemble a symbolic expression, equation, diagram, or summary object out of the roled parts."),
            status(review_pending)).
action_maps(algebraic, contextual_linear_equation_construction, coordinate_repeated_unknown, compose_expression,
            confidence(high),
            evidence("algebraic/contextual_linear_equation_construction, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges, static only. assemble a symbolic expression, equation, diagram, or summary object out of the roled parts."),
            status(review_pending)).
action_maps(algebraic, contextual_linear_equation_construction, identify_unknown_quantity, assign_roles,
            confidence(high),
            evidence("algebraic/contextual_linear_equation_construction, q_start -> q_step_1: 1 of the machine's 6 distinct edges, static only. bind each given to its structural role in the relation: which quantity is the whole and which the part, group count against group size, which term is the repeated factor, which coordinate comes first."),
            status(review_pending)).
action_maps(algebraic, contextual_linear_equation_construction, inscribe_equation, inscribe_result,
            confidence(high),
            evidence("algebraic/contextual_linear_equation_construction, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, static only. write the result in notation."),
            status(review_pending)).
action_maps(algebraic, contextual_linear_equation_construction, relate_expression_to_total, compose_expression,
            confidence(high),
            evidence("algebraic/contextual_linear_equation_construction, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, static only. assemble a symbolic expression, equation, diagram, or summary object out of the roled parts."),
            status(review_pending)).
action_maps(algebraic, distributive_expression_rewrite, distribute_factor, distribute_over_partition,
            confidence(high),
            evidence("algebraic/distributive_expression_rewrite, q_step_2 -> q_step_3; q_step_3 -> q_step_4: 2 of the machine's 5 distinct edges, static only. apply the operator across the parts of a decomposition."),
            status(review_pending)).
action_maps(algebraic, distributive_expression_rewrite, identify_addends, read_operand_attribute,
            confidence(high),
            evidence("algebraic/distributive_expression_rewrite, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(algebraic, distributive_expression_rewrite, identify_common_factor, read_operand_attribute,
            confidence(high),
            evidence("algebraic/distributive_expression_rewrite, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(algebraic, distributive_expression_rewrite, join_partial_products, recompose_total,
            confidence(high),
            evidence("algebraic/distributive_expression_rewrite, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. put the parts of a decomposition back together into the whole."),
            status(review_pending)).
action_maps(algebraic, drop_distributed_term, distribute_factor, distribute_over_partition,
            confidence(high),
            evidence("algebraic/drop_distributed_term, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. apply the operator across the parts of a decomposition."),
            status(review_pending)).
action_maps(algebraic, drop_distributed_term, identify_common_factor, read_operand_attribute,
            confidence(high),
            evidence("algebraic/drop_distributed_term, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(algebraic, drop_distributed_term, lose_equivalent_expression, record_loss,
            confidence(high),
            evidence("algebraic/drop_distributed_term, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(algebraic, drop_distributed_term, stop_before_second_addend, halt_before_completion,
            confidence(high),
            evidence("algebraic/drop_distributed_term, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. stop a required traversal, iteration, or recomposition before it finishes."),
            status(review_pending)).
action_maps(algebraic, equation_truth_by_substitution, compare_values_for_equality, test_criteria,
            confidence(high),
            evidence("algebraic/equation_truth_by_substitution, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. test whether the required attributes or conditions hold."),
            status(review_pending)).
action_maps(algebraic, equation_truth_by_substitution, evaluate_left_expression, evaluate_expression,
            confidence(high),
            evidence("algebraic/equation_truth_by_substitution, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. compute the value of an expression from its parts."),
            status(review_pending)).
action_maps(algebraic, equation_truth_by_substitution, evaluate_right_expression, evaluate_expression,
            confidence(high),
            evidence("algebraic/equation_truth_by_substitution, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. compute the value of an expression from its parts."),
            status(review_pending)).
action_maps(algebraic, equation_truth_by_substitution, substitute_assignment_into_both_sides, substitute_values,
            confidence(high),
            evidence("algebraic/equation_truth_by_substitution, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. replace the variables in an expression with their assigned values."),
            status(review_pending)).
action_maps(algebraic, exponent_as_multiplier, multiply_base_by_exponent, compute_product,
            confidence(high),
            evidence("algebraic/exponent_as_multiplier, q_step_1 -> q_step_2: 1 of the machine's 3 distinct edges, static only. multiply the operands as numerals."),
            status(review_pending)).
action_maps(algebraic, exponent_as_multiplier, omit_repeated_factor_iteration, omit_required_step,
            confidence(high),
            evidence("algebraic/exponent_as_multiplier, q_step_2 -> q_accept: 1 of the machine's 3 distinct edges, static only. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(algebraic, exponent_as_multiplier, read_exponent_as_second_factor, conflate_roles,
            confidence(high),
            evidence("algebraic/exponent_as_multiplier, q_start -> q_step_1: 1 of the machine's 3 distinct edges, static only. collapse two structurally distinct roles into one."),
            status(review_pending)).
action_maps(algebraic, exponent_as_repeated_factor, establish_base, assign_roles,
            confidence(high),
            evidence("algebraic/exponent_as_repeated_factor, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. binds the given to the role of the factor that will be repeated; the same string names the grouping base of a positional numeral in counting/recursive_place_value_inscription and is mapped differently there"),
            status(review_pending)).
action_maps(algebraic, exponent_as_repeated_factor, establish_exponent, assign_roles,
            confidence(high),
            evidence("algebraic/exponent_as_repeated_factor, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. binds the given to the role of the iteration count for the repeated factor"),
            status(review_pending)).
action_maps(algebraic, exponent_as_repeated_factor, inscribe_expanded_product, inscribe_result,
            confidence(high),
            evidence("algebraic/exponent_as_repeated_factor, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. write the result in notation."),
            status(review_pending)).
action_maps(algebraic, exponent_as_repeated_factor, iterate_base_factor, iterate_unit,
            confidence(high),
            evidence("algebraic/exponent_as_repeated_factor, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. repeat a unit to build or to measure a quantity."),
            status(review_pending)).
action_maps(algebraic, exponential_equivalence_by_expansion, certify_equivalent, name_result,
            confidence(high),
            evidence("algebraic/exponential_equivalence_by_expansion, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. states the equivalence verdict the factor-structure test reached"),
            status(review_pending)).
action_maps(algebraic, exponential_equivalence_by_expansion, compare_factor_structures, test_criteria,
            confidence(medium),
            evidence("algebraic/exponential_equivalence_by_expansion, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. tests whether the two expansions are the same string of factors, an identity test rather than an ordering"),
            status(review_pending)).
action_maps(algebraic, exponential_equivalence_by_expansion, expand_left_powers, re_express_equivalently,
            confidence(high),
            evidence("algebraic/exponential_equivalence_by_expansion, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. rewrite a quantity or relation in a commensurate form without changing what it says."),
            status(review_pending)).
action_maps(algebraic, exponential_equivalence_by_expansion, expand_right_powers, re_express_equivalently,
            confidence(high),
            evidence("algebraic/exponential_equivalence_by_expansion, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. rewrite a quantity or relation in a commensurate form without changing what it says."),
            status(review_pending)).
action_maps(algebraic, guess_and_check_rule, apply_empirical_rule, apply_stored_rule,
            confidence(high),
            evidence("algebraic/guess_and_check_rule, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. carry out a remembered formula, rule, or prescribed procedural step."),
            status(review_pending)).
action_maps(algebraic, guess_and_check_rule, compare_with_contextual_rule, test_criteria,
            confidence(medium),
            evidence("algebraic/guess_and_check_rule, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. tests the guessed rule against the contextual one instead of deriving the contextual rule"),
            status(review_pending)).
action_maps(algebraic, guess_and_check_rule, lose_contextual_linear_relation, record_loss,
            confidence(high),
            evidence("algebraic/guess_and_check_rule, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(algebraic, guess_and_check_rule, read_empirical_rule, register_givens,
            confidence(medium),
            evidence("algebraic/guess_and_check_rule, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. takes a guessed rule as the given instead of deriving one from the context"),
            status(review_pending)).
action_maps(algebraic, linear_pattern_contextual_rule, add_initial_value, combine_quantities,
            confidence(high),
            evidence("algebraic/linear_pattern_contextual_rule, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, static only. join two quantities into their sum."),
            status(review_pending)).
action_maps(algebraic, linear_pattern_contextual_rule, compute_accumulated_change, compute_product,
            confidence(high),
            evidence("algebraic/linear_pattern_contextual_rule, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges, static only. multiplies the constant change by the counted increments"),
            status(review_pending)).
action_maps(algebraic, linear_pattern_contextual_rule, count_increments_from_first_row, count_units,
            confidence(high),
            evidence("algebraic/linear_pattern_contextual_rule, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges, static only. count how many units the iteration or the partition produced."),
            status(review_pending)).
action_maps(algebraic, linear_pattern_contextual_rule, identify_constant_change, read_operand_attribute,
            confidence(high),
            evidence("algebraic/linear_pattern_contextual_rule, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(algebraic, linear_pattern_contextual_rule, identify_initial_value, read_operand_attribute,
            confidence(high),
            evidence("algebraic/linear_pattern_contextual_rule, q_start -> q_step_1: 1 of the machine's 6 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(algebraic, linear_pattern_contextual_rule, preserve_contextual_linear_relation, record_conservation,
            confidence(high),
            evidence("algebraic/linear_pattern_contextual_rule, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, static only. record that the strategy kept the relation it was obliged to keep."),
            status(review_pending)).
action_maps(algebraic, one_sided_equation_operation, divide_remaining_expression_by, compute_quotient,
            confidence(high),
            evidence("algebraic/one_sided_equation_operation, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. divide the operands as numerals."),
            status(review_pending)).
action_maps(algebraic, one_sided_equation_operation, leave_right_side_unchanged, retain_where_change_was_due,
            confidence(high),
            evidence("algebraic/one_sided_equation_operation, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. leaves the right side untouched at the edge after the constant was removed from the left; the equation's balance obliged the same removal on both sides, so the retention is where the imbalance enters"),
            status(review_pending)).
action_maps(algebraic, one_sided_equation_operation, read_equals_as_instruction, substitute_symbol_reading,
            confidence(high),
            evidence("algebraic/one_sided_equation_operation, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. reads the equals sign as an instruction to compute rather than as a relation between two sides"),
            status(review_pending)).
action_maps(algebraic, one_sided_equation_operation, remove_constant_from_left_side_only, remove_quantity,
            confidence(high),
            evidence("algebraic/one_sided_equation_operation, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. removes the constant from one side; the other side is left untouched at the next edge, which is where the imbalance enters"),
            status(review_pending)).
action_maps(algebraic, one_sided_equation_operation, report_unbalanced_value, misname_result,
            confidence(high),
            evidence("algebraic/one_sided_equation_operation, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. name a value that answers a different question than the one asked."),
            status(review_pending)).
action_maps(algebraic, operational_equals_left_value, evaluate_left_expression, evaluate_expression,
            confidence(high),
            evidence("algebraic/operational_equals_left_value, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. compute the value of an expression from its parts."),
            status(review_pending)).
action_maps(algebraic, operational_equals_left_value, ignore_right_expression, treat_relevant_as_irrelevant,
            confidence(high),
            evidence("algebraic/operational_equals_left_value, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. treat a relation the result depends on as though it did not bear on the result."),
            status(review_pending)).
action_maps(algebraic, operational_equals_left_value, substitute_assignment_into_left_side, substitute_values,
            confidence(high),
            evidence("algebraic/operational_equals_left_value, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. replace the variables in an expression with their assigned values."),
            status(review_pending)).
action_maps(algebraic, operational_equals_left_value, treat_equals_as_answer_signal, substitute_symbol_reading,
            confidence(high),
            evidence("algebraic/operational_equals_left_value, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. reads the equals sign as the place the answer goes rather than as a relation"),
            status(review_pending)).
action_maps(algebraic, programming_expression_evaluation, identify_assignment, register_givens,
            confidence(high),
            evidence("algebraic/programming_expression_evaluation, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(algebraic, programming_expression_evaluation, identify_expression, register_givens,
            confidence(high),
            evidence("algebraic/programming_expression_evaluation, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(algebraic, programming_expression_evaluation, kernel_trace, receive_kernel_outcome,
            confidence(high),
            evidence("algebraic/programming_expression_evaluation, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. take the delegated automaton's outcome back as this machine's step."),
            status(review_pending)).
action_maps(algebraic, programming_expression_evaluation, report_value, name_result,
            confidence(high),
            evidence("algebraic/programming_expression_evaluation, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. say which quantity the answer is."),
            status(review_pending)).
action_maps(algebraic, programming_expression_evaluation, walk_expression_tree, evaluate_expression,
            confidence(high),
            evidence("algebraic/programming_expression_evaluation, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. compute the value of an expression from its parts."),
            status(review_pending)).
action_maps(algebraic, symbolic_expression_construction, declare_variables, assign_roles,
            confidence(high),
            evidence("algebraic/symbolic_expression_construction, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. bind each given to its structural role in the relation: which quantity is the whole and which the part, group count against group size, which term is the repeated factor, which coordinate comes first."),
            status(review_pending)).
action_maps(algebraic, symbolic_expression_construction, identify_quantity_roles, assign_roles,
            confidence(high),
            evidence("algebraic/symbolic_expression_construction, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. bind each given to its structural role in the relation: which quantity is the whole and which the part, group count against group size, which term is the repeated factor, which coordinate comes first."),
            status(review_pending)).
action_maps(algebraic, symbolic_expression_construction, inscribe_expression, inscribe_result,
            confidence(high),
            evidence("algebraic/symbolic_expression_construction, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. write the result in notation."),
            status(review_pending)).
action_maps(algebraic, symbolic_expression_construction, preserve_operand_structure, verify_invariant,
            confidence(medium),
            evidence("algebraic/symbolic_expression_construction, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. certifies the operand structure before the expression is inscribed"),
            status(review_pending)).
action_maps(algebraic, symbolic_expression_construction, select_operation, compose_expression,
            confidence(medium),
            evidence("algebraic/symbolic_expression_construction, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. chooses the operation that will join the declared variables into one expression"),
            status(review_pending)).
action_maps(calculus, factor_cancel_substitute, detect_zero_over_zero, test_criteria,
            confidence(high),
            evidence("calculus/factor_cancel_substitute, q_step_2 -> q_step_3: 1 of the machine's 8 distinct edges, static only. tests the indeterminate form, which is the precondition the cancelling routine needs"),
            status(review_pending)).
action_maps(calculus, factor_cancel_substitute, evaluate_reduced_at_point, evaluate_expression,
            confidence(high),
            evidence("calculus/factor_cancel_substitute, q_step_5 -> q_step_6: 1 of the machine's 8 distinct edges, static only. compute the value of an expression from its parts."),
            status(review_pending)).
action_maps(calculus, factor_cancel_substitute, factor_common_factor_x_minus_a, decompose_operand,
            confidence(high),
            evidence("calculus/factor_cancel_substitute, q_step_3 -> q_step_4: 1 of the machine's 8 distinct edges, static only. splits numerator and denominator into a product carrying the common factor"),
            status(review_pending)).
action_maps(calculus, factor_cancel_substitute, identify_limit_target, read_operand_attribute,
            confidence(high),
            evidence("calculus/factor_cancel_substitute, q_start -> q_step_1: 1 of the machine's 8 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(calculus, factor_cancel_substitute, kernel_trace, receive_kernel_outcome,
            confidence(high),
            evidence("calculus/factor_cancel_substitute, q_step_6 -> q_step_7: 1 of the machine's 8 distinct edges, static only. take the delegated automaton's outcome back as this machine's step."),
            status(review_pending)).
action_maps(calculus, factor_cancel_substitute, name_value_as_limit, name_result,
            confidence(high),
            evidence("calculus/factor_cancel_substitute, q_step_7 -> q_accept: 1 of the machine's 8 distinct edges, static only. say which quantity the answer is."),
            status(review_pending)).
action_maps(calculus, factor_cancel_substitute, substitute_target_into_expression, substitute_values,
            confidence(high),
            evidence("calculus/factor_cancel_substitute, q_step_1 -> q_step_2: 1 of the machine's 8 distinct edges, static only. replace the variables in an expression with their assigned values."),
            status(review_pending)).
action_maps(calculus, factor_cancel_substitute, substitute_target_into_reduced, substitute_values,
            confidence(high),
            evidence("calculus/factor_cancel_substitute, q_step_4 -> q_step_5: 1 of the machine's 8 distinct edges, static only. replace the variables in an expression with their assigned values."),
            status(review_pending)).
action_maps(calculus, factor_cancel_without_common_factor, apply_cancel_routine_anyway, apply_stored_rule,
            confidence(high),
            evidence("calculus/factor_cancel_without_common_factor, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges, static only. carry out a remembered formula, rule, or prescribed procedural step."),
            status(review_pending)).
action_maps(calculus, factor_cancel_without_common_factor, fail_to_detect_zero_over_zero, omit_required_step,
            confidence(high),
            evidence("calculus/factor_cancel_without_common_factor, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges, static only. the indeterminate-form test never runs, so the cancelling routine fires without its precondition"),
            status(review_pending)).
action_maps(calculus, factor_cancel_without_common_factor, identify_limit_target, read_operand_attribute,
            confidence(high),
            evidence("calculus/factor_cancel_without_common_factor, q_start -> q_step_1: 1 of the machine's 6 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(calculus, factor_cancel_without_common_factor, lose_precondition_check, record_loss,
            confidence(high),
            evidence("calculus/factor_cancel_without_common_factor, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(calculus, factor_cancel_without_common_factor, produce_misfire_result, misname_result,
            confidence(medium),
            evidence("calculus/factor_cancel_without_common_factor, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, static only. delivers a value the missing precondition does not license as the limit"),
            status(review_pending)).
action_maps(calculus, factor_cancel_without_common_factor, substitute_target_into_expression, substitute_values,
            confidence(high),
            evidence("calculus/factor_cancel_without_common_factor, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, static only. replace the variables in an expression with their assigned values."),
            status(review_pending)).
action_maps(counting, compare_cardinalities_one_to_one, conclude_count_relation, name_result,
            confidence(high),
            evidence("counting/compare_cardinalities_one_to_one, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. say which quantity the answer is."),
            status(review_pending)).
action_maps(counting, compare_cardinalities_one_to_one, establish_collections, register_givens,
            confidence(high),
            evidence("counting/compare_cardinalities_one_to_one, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(counting, compare_cardinalities_one_to_one, inspect_unmatched_surplus, read_operand_attribute,
            confidence(medium),
            evidence("counting/compare_cardinalities_one_to_one, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. reads which collection has members left over once the pairing is done"),
            status(review_pending)).
action_maps(counting, compare_cardinalities_one_to_one, match_objects_one_to_one, match_one_to_one,
            confidence(high),
            evidence("counting/compare_cardinalities_one_to_one, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. pair the members of two collections against each other."),
            status(review_pending)).
action_maps(counting, compare_ones_digits_only, compare_ones_digits, compare_magnitudes,
            confidence(high),
            evidence("counting/compare_ones_digits_only, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. decide the order relation between two quantities."),
            status(review_pending)).
action_maps(counting, compare_ones_digits_only, conclude_count_relation, name_result,
            confidence(high),
            evidence("counting/compare_ones_digits_only, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. say which quantity the answer is."),
            status(review_pending)).
action_maps(counting, compare_ones_digits_only, discard_higher_place_digits, treat_relevant_as_irrelevant,
            confidence(high),
            evidence("counting/compare_ones_digits_only, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. treat a relation the result depends on as though it did not bear on the result."),
            status(review_pending)).
action_maps(counting, compare_ones_digits_only, inscribe_in_common_base, align_to_common_unit,
            confidence(high),
            evidence("counting/compare_ones_digits_only, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. bring both quantities into a shared unit, denominator, or decimal scale so they can be measured against each other."),
            status(review_pending)).
action_maps(counting, inscribe_cardinality, choose_base, select_unit_scale,
            confidence(high),
            evidence("counting/inscribe_cardinality, q_step_1 -> q_step_2: 1 of the machine's 3 distinct edges, static only. choose which unit, base, or scale to work in from among the available ones."),
            status(review_pending)).
action_maps(counting, inscribe_cardinality, establish_cardinality, register_givens,
            confidence(high),
            evidence("counting/inscribe_cardinality, q_start -> q_step_1: 1 of the machine's 3 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(counting, inscribe_cardinality, project_counting_cycles_into_digits, inscribe_result,
            confidence(high),
            evidence("counting/inscribe_cardinality, q_step_2 -> q_accept: 1 of the machine's 3 distinct edges, static only. write the result in notation."),
            status(review_pending)).
action_maps(counting, omit_highest_place_regrouping, establish_positional_numeral, register_givens,
            confidence(high),
            evidence("counting/omit_highest_place_regrouping, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(counting, omit_highest_place_regrouping, omit_regrouping_action, omit_required_step,
            confidence(high),
            evidence("counting/omit_highest_place_regrouping, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(counting, omit_highest_place_regrouping, read_deformed_cardinality, misname_result,
            confidence(high),
            evidence("counting/omit_highest_place_regrouping, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. names the numeral the omitted regrouping produced as the cardinality"),
            status(review_pending)).
action_maps(counting, omit_highest_place_regrouping, select_highest_regrouped_place, select_part,
            confidence(medium),
            evidence("counting/omit_highest_place_regrouping, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. picks out the highest place that would have needed regrouping, which is the place the next edge then skips"),
            status(review_pending)).
action_maps(counting, place_value_comparison, align_places_by_unit, align_to_common_unit,
            confidence(high),
            evidence("counting/place_value_comparison, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. bring both quantities into a shared unit, denominator, or decimal scale so they can be measured against each other."),
            status(review_pending)).
action_maps(counting, place_value_comparison, compare_digits_at_that_place, compare_magnitudes,
            confidence(high),
            evidence("counting/place_value_comparison, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. decide the order relation between two quantities."),
            status(review_pending)).
action_maps(counting, place_value_comparison, conclude_count_relation, name_result,
            confidence(high),
            evidence("counting/place_value_comparison, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. say which quantity the answer is."),
            status(review_pending)).
action_maps(counting, place_value_comparison, inscribe_in_common_base, align_to_common_unit,
            confidence(high),
            evidence("counting/place_value_comparison, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. bring both quantities into a shared unit, denominator, or decimal scale so they can be measured against each other."),
            status(review_pending)).
action_maps(counting, place_value_comparison, locate_highest_differing_place, locate_position,
            confidence(medium),
            evidence("counting/place_value_comparison, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. locates the highest place at which the two numerals differ, the place the comparison then reads"),
            status(review_pending)).
action_maps(counting, recursive_place_value_inscription, establish_base, select_unit_scale,
            confidence(high),
            evidence("counting/recursive_place_value_inscription, q_step_1 -> q_step_2: 1 of the machine's 3 distinct edges, static only. chooses the grouping base the completed cycles are recollected into; the same string names the repeated factor of a power in algebraic/exponent_as_repeated_factor and is mapped differently there"),
            status(review_pending)).
action_maps(counting, recursive_place_value_inscription, establish_cardinality, register_givens,
            confidence(high),
            evidence("counting/recursive_place_value_inscription, q_start -> q_step_1: 1 of the machine's 3 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(counting, recursive_place_value_inscription, recollect_completed_base_cycles, regroup_to_base,
            confidence(high),
            evidence("counting/recursive_place_value_inscription, q_step_2 -> q_accept: 1 of the machine's 3 distinct edges, static only. collects the completed base cycles into the next place, which is what makes the inscription recursive"),
            status(review_pending)).
action_maps(counting, spatial_extent_as_cardinality, compare_spatial_extents, compare_magnitudes,
            confidence(high),
            evidence("counting/spatial_extent_as_cardinality, q_step_1 -> q_step_2: 1 of the machine's 3 distinct edges, static only. decide the order relation between two quantities."),
            status(review_pending)).
action_maps(counting, spatial_extent_as_cardinality, ignore_one_to_one_correspondence, treat_relevant_as_irrelevant,
            confidence(high),
            evidence("counting/spatial_extent_as_cardinality, q_start -> q_step_1: 1 of the machine's 3 distinct edges, static only. treat a relation the result depends on as though it did not bear on the result."),
            status(review_pending)).
action_maps(counting, spatial_extent_as_cardinality, substitute_extent_relation_for_count_relation, substitute_appearance_for_measure,
            confidence(high),
            evidence("counting/spatial_extent_as_cardinality, q_step_2 -> q_accept: 1 of the machine's 3 distinct edges, static only. puts the collections' spatial extent in place of their cardinality"),
            status(review_pending)).
action_maps(decimal, change_decimal_place_name_without_regrouping, change_decimal_unit_name, rename_in_place_of_transforming,
            confidence(high),
            evidence("decimal/change_decimal_place_name_without_regrouping, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. renames the decimal unit while the count is carried forward untouched at the next edge, where changing the unit would have required regrouping by the ten-to-one factor"),
            status(review_pending)).
action_maps(decimal, change_decimal_place_name_without_regrouping, identify_nested_decimal_units, read_operand_attribute,
            confidence(high),
            evidence("decimal/change_decimal_place_name_without_regrouping, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(decimal, change_decimal_place_name_without_regrouping, omit_regrouping_factor, omit_required_step,
            confidence(high),
            evidence("decimal/change_decimal_place_name_without_regrouping, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(decimal, change_decimal_place_name_without_regrouping, retain_original_count, retain_where_change_was_due,
            confidence(high),
            evidence("decimal/change_decimal_place_name_without_regrouping, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. carries the count forward untouched at the edge where changing the decimal unit's name obliged regrouping by the ten-to-one factor; the omission of that factor is recorded at the next edge"),
            status(review_pending)).
action_maps(decimal, decimal_add_unaligned_numerals, add_unaligned_numerals, combine_quantities,
            confidence(high),
            evidence("decimal/decimal_add_unaligned_numerals, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, witnessed. adds the numerals as written, the scale alignment having been omitted at the previous edge"),
            status(review_pending)).
action_maps(decimal, decimal_add_unaligned_numerals, lose_decimal_scale_relation, record_loss,
            confidence(high),
            evidence("decimal/decimal_add_unaligned_numerals, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, witnessed. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(decimal, decimal_add_unaligned_numerals, omit_decimal_scale_alignment, omit_required_step,
            confidence(high),
            evidence("decimal/decimal_add_unaligned_numerals, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, witnessed. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(decimal, decimal_add_unaligned_numerals, read_written_integer_numerals, register_givens,
            confidence(high),
            evidence("decimal/decimal_add_unaligned_numerals, q_start -> q_step_1: 1 of the machine's 5 distinct edges, witnessed. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(decimal, decimal_add_unaligned_numerals, reinscribe_at_larger_scale, inscribe_result,
            confidence(high),
            evidence("decimal/decimal_add_unaligned_numerals, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, witnessed. writes the result at the larger of the two scales, the alignment having been omitted"),
            status(review_pending)).
action_maps(decimal, decimal_addition_by_aligned_units, add_grounded_aligned_units, combine_quantities,
            confidence(high),
            evidence("decimal/decimal_addition_by_aligned_units, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, witnessed. join two quantities into their sum."),
            status(review_pending)).
action_maps(decimal, decimal_addition_by_aligned_units, align_decimal_units, align_to_common_unit,
            confidence(high),
            evidence("decimal/decimal_addition_by_aligned_units, q_step_2 -> q_step_3; q_step_3 -> q_step_4: 2 of the machine's 6 distinct edges, witnessed. bring both quantities into a shared unit, denominator, or decimal scale so they can be measured against each other."),
            status(review_pending)).
action_maps(decimal, decimal_addition_by_aligned_units, choose_common_decimal_scale, select_unit_scale,
            confidence(high),
            evidence("decimal/decimal_addition_by_aligned_units, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, witnessed. choose which unit, base, or scale to work in from among the available ones."),
            status(review_pending)).
action_maps(decimal, decimal_addition_by_aligned_units, identify_operand_scales, read_operand_attribute,
            confidence(high),
            evidence("decimal/decimal_addition_by_aligned_units, q_start -> q_step_1: 1 of the machine's 6 distinct edges, witnessed. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(decimal, decimal_addition_by_aligned_units, reinscribe_decimal_result, inscribe_result,
            confidence(high),
            evidence("decimal/decimal_addition_by_aligned_units, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, witnessed. write the result in notation."),
            status(review_pending)).
action_maps(decimal, decimal_comparison_by_aligned_units, align_decimal_units, align_to_common_unit,
            confidence(high),
            evidence("decimal/decimal_comparison_by_aligned_units, q_step_2 -> q_step_3; q_step_3 -> q_step_4: 2 of the machine's 5 distinct edges, witnessed. bring both quantities into a shared unit, denominator, or decimal scale so they can be measured against each other."),
            status(review_pending)).
action_maps(decimal, decimal_comparison_by_aligned_units, choose_common_decimal_scale, select_unit_scale,
            confidence(high),
            evidence("decimal/decimal_comparison_by_aligned_units, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, witnessed. choose which unit, base, or scale to work in from among the available ones."),
            status(review_pending)).
action_maps(decimal, decimal_comparison_by_aligned_units, compare_aligned_decimal_units, compare_magnitudes,
            confidence(high),
            evidence("decimal/decimal_comparison_by_aligned_units, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, witnessed. decide the order relation between two quantities."),
            status(review_pending)).
action_maps(decimal, decimal_comparison_by_aligned_units, identify_operand_scales, read_operand_attribute,
            confidence(high),
            evidence("decimal/decimal_comparison_by_aligned_units, q_start -> q_step_1: 1 of the machine's 5 distinct edges, witnessed. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(decimal, decimal_fraction_place_value_comparison, common_scale, align_to_common_unit,
            confidence(high),
            evidence("decimal/decimal_fraction_place_value_comparison, q_align_place_value_units -> q_compare_decimal_magnitudes: 1 of the machine's 6 distinct edges, witnessed. bring both quantities into a shared unit, denominator, or decimal scale so they can be measured against each other."),
            status(review_pending)).
action_maps(decimal, decimal_fraction_place_value_comparison, compare, compare_magnitudes,
            confidence(high),
            evidence("decimal/decimal_fraction_place_value_comparison, q_compare_decimal_magnitudes -> q_emit: 1 of the machine's 6 distinct edges, witnessed. decide the order relation between two quantities."),
            status(review_pending)).
action_maps(decimal, decimal_fraction_place_value_comparison, emit, emit_result,
            confidence(high),
            evidence("decimal/decimal_fraction_place_value_comparison, q_emit -> q_accept: 1 of the machine's 6 distinct edges, witnessed. release the result from the machine."),
            status(review_pending)).
action_maps(decimal, decimal_fraction_place_value_comparison, fractions, re_express_equivalently,
            confidence(high),
            evidence("decimal/decimal_fraction_place_value_comparison, q_express_as_fraction -> q_align_place_value_units: 1 of the machine's 6 distinct edges, witnessed. re-expresses the two decimals as fractions, a commensurate rewriting that changes neither value"),
            status(review_pending)).
action_maps(decimal, decimal_fraction_place_value_comparison, init, initiate,
            confidence(high),
            evidence("decimal/decimal_fraction_place_value_comparison, q_init -> q_identify_decimal_units: 1 of the machine's 6 distinct edges, witnessed. enter the machine without yet doing mathematical work."),
            status(review_pending)).
action_maps(decimal, decimal_fraction_place_value_comparison, scales, read_operand_attribute,
            confidence(high),
            evidence("decimal/decimal_fraction_place_value_comparison, q_identify_decimal_units -> q_express_as_fraction: 1 of the machine's 6 distinct edges, witnessed. reads the two decimals' place-value scales, which the next edge re-expresses as fractions"),
            status(review_pending)).
action_maps(decimal, decimal_multiplication_rule, compose_decimal_product, recompose_total,
            confidence(high),
            evidence("decimal/decimal_multiplication_rule, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, witnessed. reassembles the integer product and the placed mark into the decimal result"),
            status(review_pending)).
action_maps(decimal, decimal_multiplication_rule, identify_operand_place_counts, read_operand_attribute,
            confidence(high),
            evidence("decimal/decimal_multiplication_rule, q_start -> q_step_1: 1 of the machine's 6 distinct edges, witnessed. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(decimal, decimal_multiplication_rule, ignore_decimal_marks_momentarily, set_aside_irrelevant_attribute,
            confidence(high),
            evidence("decimal/decimal_multiplication_rule, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, witnessed. sets the marks aside only for the integer multiplication and restores them when the point is placed two edges later"),
            status(review_pending)).
action_maps(decimal, decimal_multiplication_rule, multiply_integer_numerals, compute_product,
            confidence(high),
            evidence("decimal/decimal_multiplication_rule, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges, witnessed. multiply the operands as numerals."),
            status(review_pending)).
action_maps(decimal, decimal_multiplication_rule, place_decimal_point, inscribe_result,
            confidence(high),
            evidence("decimal/decimal_multiplication_rule, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, witnessed. write the result in notation."),
            status(review_pending)).
action_maps(decimal, decimal_multiplication_rule, sum_fractional_place_counts, accumulate_total,
            confidence(high),
            evidence("decimal/decimal_multiplication_rule, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges, witnessed. add the counted or measured pieces into a running total."),
            status(review_pending)).
action_maps(decimal, decimal_numeral_comparison_without_scale_alignment, compare_unaligned_numerals, compare_magnitudes,
            confidence(high),
            evidence("decimal/decimal_numeral_comparison_without_scale_alignment, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, witnessed. decide the order relation between two quantities."),
            status(review_pending)).
action_maps(decimal, decimal_numeral_comparison_without_scale_alignment, lose_decimal_scale_relation, record_loss,
            confidence(high),
            evidence("decimal/decimal_numeral_comparison_without_scale_alignment, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, witnessed. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(decimal, decimal_numeral_comparison_without_scale_alignment, omit_decimal_scale_alignment, omit_required_step,
            confidence(high),
            evidence("decimal/decimal_numeral_comparison_without_scale_alignment, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, witnessed. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(decimal, decimal_numeral_comparison_without_scale_alignment, read_written_integer_numerals, register_givens,
            confidence(high),
            evidence("decimal/decimal_numeral_comparison_without_scale_alignment, q_start -> q_step_1: 1 of the machine's 4 distinct edges, witnessed. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(decimal, decimal_place_unit_regrouping, derive_regrouping_factor, read_operand_attribute,
            confidence(medium),
            evidence("decimal/decimal_place_unit_regrouping, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. reads the ten-to-one factor between the nested decimal units before the finer unit is iterated"),
            status(review_pending)).
action_maps(decimal, decimal_place_unit_regrouping, identify_nested_decimal_units, read_operand_attribute,
            confidence(high),
            evidence("decimal/decimal_place_unit_regrouping, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(decimal, decimal_place_unit_regrouping, iterate_finer_unit, iterate_unit,
            confidence(high),
            evidence("decimal/decimal_place_unit_regrouping, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. repeat a unit to build or to measure a quantity."),
            status(review_pending)).
action_maps(decimal, decimal_place_unit_regrouping, preserve_decimal_quantity, record_conservation,
            confidence(high),
            evidence("decimal/decimal_place_unit_regrouping, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. record that the strategy kept the relation it was obliged to keep."),
            status(review_pending)).
action_maps(decimal, decimal_point_rule_misapplication, identify_operand_place_counts, read_operand_attribute,
            confidence(high),
            evidence("decimal/decimal_point_rule_misapplication, q_start -> q_step_1: 1 of the machine's 5 distinct edges, witnessed. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(decimal, decimal_point_rule_misapplication, lose_fractional_place_count, record_loss,
            confidence(high),
            evidence("decimal/decimal_point_rule_misapplication, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, witnessed. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(decimal, decimal_point_rule_misapplication, multiply_integer_numerals, compute_product,
            confidence(high),
            evidence("decimal/decimal_point_rule_misapplication, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, witnessed. multiply the operands as numerals."),
            status(review_pending)).
action_maps(decimal, decimal_point_rule_misapplication, place_decimal_point, inscribe_result,
            confidence(high),
            evidence("decimal/decimal_point_rule_misapplication, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, witnessed. write the result in notation."),
            status(review_pending)).
action_maps(decimal, decimal_point_rule_misapplication, take_max_of_place_counts_instead_of_summing, substitute_operation,
            confidence(high),
            evidence("decimal/decimal_point_rule_misapplication, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, witnessed. takes the maximum of the two place counts where the rule sums them"),
            status(review_pending)).
action_maps(decimal, decimal_scale_loss_comparison, viability, record_viability,
            confidence(high),
            evidence("decimal/decimal_scale_loss_comparison, q_observed_5 -> q_observed_6: 1 of the machine's 13 distinct edges, witnessed. record whether the strategy is contextually correct for this input."),
            status(review_pending)).
action_maps(decimal, decimal_scale_loss_comparison, compare, compare_magnitudes,
            confidence(high),
            evidence("decimal/decimal_scale_loss_comparison, q_compare_decimal_magnitudes -> q_emit: 1 of the machine's 6 distinct edges, witnessed. decide the order relation between two quantities."),
            status(review_pending)).
action_maps(decimal, decimal_scale_loss_comparison, compare_written_numerals, compare_magnitudes,
            confidence(high),
            evidence("decimal/decimal_scale_loss_comparison, q_scale_loss -> q_compare_decimal_magnitudes: 1 of the machine's 6 distinct edges, witnessed. decide the order relation between two quantities."),
            status(review_pending)).
action_maps(decimal, decimal_scale_loss_comparison, emit, emit_result,
            confidence(high),
            evidence("decimal/decimal_scale_loss_comparison, q_emit -> q_accept: 1 of the machine's 6 distinct edges, witnessed. release the result from the machine."),
            status(review_pending)).
action_maps(decimal, decimal_scale_loss_comparison, init, initiate,
            confidence(high),
            evidence("decimal/decimal_scale_loss_comparison, q_init -> q_identify_decimal_units: 1 of the machine's 6 distinct edges, witnessed. enter the machine without yet doing mathematical work."),
            status(review_pending)).
action_maps(decimal, decimal_scale_loss_comparison, omitted, omit_required_step,
            confidence(high),
            evidence("decimal/decimal_scale_loss_comparison, q_express_as_fraction -> q_scale_loss: 1 of the machine's 6 distinct edges, witnessed. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(decimal, decimal_scale_loss_comparison, scales_seen_but_not_coordinated, accept_without_check,
            confidence(high),
            evidence("decimal/decimal_scale_loss_comparison, q_identify_decimal_units -> q_express_as_fraction: 1 of the machine's 6 distinct edges, witnessed. the two scales are read but never coordinated, and the machine proceeds as though they had been"),
            status(review_pending)).
action_maps(decimal, decimal_subtract_unaligned_numerals, lose_decimal_scale_relation, record_loss,
            confidence(high),
            evidence("decimal/decimal_subtract_unaligned_numerals, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, witnessed. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(decimal, decimal_subtract_unaligned_numerals, omit_decimal_scale_alignment, omit_required_step,
            confidence(high),
            evidence("decimal/decimal_subtract_unaligned_numerals, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, witnessed. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(decimal, decimal_subtract_unaligned_numerals, read_written_integer_numerals, register_givens,
            confidence(high),
            evidence("decimal/decimal_subtract_unaligned_numerals, q_start -> q_step_1: 1 of the machine's 5 distinct edges, witnessed. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(decimal, decimal_subtract_unaligned_numerals, reinscribe_at_larger_scale, inscribe_result,
            confidence(high),
            evidence("decimal/decimal_subtract_unaligned_numerals, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, witnessed. writes the result at the larger of the two scales, the alignment having been omitted"),
            status(review_pending)).
action_maps(decimal, decimal_subtract_unaligned_numerals, subtract_unaligned_numerals, remove_quantity,
            confidence(high),
            evidence("decimal/decimal_subtract_unaligned_numerals, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, witnessed. take one quantity away from another."),
            status(review_pending)).
action_maps(decimal, decimal_subtraction_by_aligned_units, align_decimal_units, align_to_common_unit,
            confidence(high),
            evidence("decimal/decimal_subtraction_by_aligned_units, q_step_2 -> q_step_3; q_step_3 -> q_step_4: 2 of the machine's 6 distinct edges, witnessed. bring both quantities into a shared unit, denominator, or decimal scale so they can be measured against each other."),
            status(review_pending)).
action_maps(decimal, decimal_subtraction_by_aligned_units, choose_common_decimal_scale, select_unit_scale,
            confidence(high),
            evidence("decimal/decimal_subtraction_by_aligned_units, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, witnessed. choose which unit, base, or scale to work in from among the available ones."),
            status(review_pending)).
action_maps(decimal, decimal_subtraction_by_aligned_units, identify_operand_scales, read_operand_attribute,
            confidence(high),
            evidence("decimal/decimal_subtraction_by_aligned_units, q_start -> q_step_1: 1 of the machine's 6 distinct edges, witnessed. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(decimal, decimal_subtraction_by_aligned_units, reinscribe_decimal_result, inscribe_result,
            confidence(high),
            evidence("decimal/decimal_subtraction_by_aligned_units, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, witnessed. write the result in notation."),
            status(review_pending)).
action_maps(decimal, decimal_subtraction_by_aligned_units, subtract_grounded_aligned_units, remove_quantity,
            confidence(high),
            evidence("decimal/decimal_subtraction_by_aligned_units, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, witnessed. take one quantity away from another."),
            status(review_pending)).
action_maps(decimal, decimal_whole_number_reading, ignore_decimal_mark, treat_relevant_as_irrelevant,
            confidence(high),
            evidence("decimal/decimal_whole_number_reading, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. treat a relation the result depends on as though it did not bear on the result."),
            status(review_pending)).
action_maps(decimal, decimal_whole_number_reading, ignore_fractional_place_value, treat_relevant_as_irrelevant,
            confidence(high),
            evidence("decimal/decimal_whole_number_reading, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. treat a relation the result depends on as though it did not bear on the result."),
            status(review_pending)).
action_maps(decimal, decimal_whole_number_reading, lose_decimal_scale, record_loss,
            confidence(high),
            evidence("decimal/decimal_whole_number_reading, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(decimal, decimal_whole_number_reading, name_decimal_as_whole_number, misname_result,
            confidence(high),
            evidence("decimal/decimal_whole_number_reading, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. name a value that answers a different question than the one asked."),
            status(review_pending)).
action_maps(decimal, decimal_whole_number_reading, see_digits_as_whole_number_string, register_givens,
            confidence(medium),
            evidence("decimal/decimal_whole_number_reading, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. holds the digit string as a whole number before the mark is set aside at the next edge"),
            status(review_pending)).
action_maps(decimal, ecuadorian_decimal_long_division, choose_maximum_place_count, select_unit_scale,
            confidence(high),
            evidence("decimal/ecuadorian_decimal_long_division, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, static only. choose which unit, base, or scale to work in from among the available ones."),
            status(review_pending)).
action_maps(decimal, ecuadorian_decimal_long_division, clear_decimal_points, apply_stored_rule,
            confidence(medium),
            evidence("decimal/ecuadorian_decimal_long_division, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges, static only. removes the marks once both operands have been scaled by the shared power of ten, a prescribed step of the written procedure"),
            status(review_pending)).
action_maps(decimal, ecuadorian_decimal_long_division, divide_as_integers, compute_quotient,
            confidence(high),
            evidence("decimal/ecuadorian_decimal_long_division, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, static only. divide the operands as numerals."),
            status(review_pending)).
action_maps(decimal, ecuadorian_decimal_long_division, identify_operand_place_counts, read_operand_attribute,
            confidence(high),
            evidence("decimal/ecuadorian_decimal_long_division, q_start -> q_step_1: 1 of the machine's 6 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(decimal, ecuadorian_decimal_long_division, name_decimal_quotient, name_result,
            confidence(high),
            evidence("decimal/ecuadorian_decimal_long_division, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, static only. say which quantity the answer is."),
            status(review_pending)).
action_maps(decimal, ecuadorian_decimal_long_division, scale_both_operands_by_shared_power_of_ten, scale_multiplicatively,
            confidence(high),
            evidence("decimal/ecuadorian_decimal_long_division, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges, static only. multiply a quantity or a term by a factor, keeping the multiplicative relation."),
            status(review_pending)).
action_maps(decimal, positional_decimal_reading, assign_fractional_place_value, assign_roles,
            confidence(high),
            evidence("decimal/positional_decimal_reading, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. binds each digit right of the mark to its fractional place"),
            status(review_pending)).
action_maps(decimal, positional_decimal_reading, compose_decimal_value, recompose_total,
            confidence(high),
            evidence("decimal/positional_decimal_reading, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. reassembles the whole part and the placed fractional digits into one value"),
            status(review_pending)).
action_maps(decimal, positional_decimal_reading, read_decimal_mark, read_operand_attribute,
            confidence(high),
            evidence("decimal/positional_decimal_reading, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(decimal, positional_decimal_reading, split_whole_and_fractional_parts, decompose_by_place,
            confidence(high),
            evidence("decimal/positional_decimal_reading, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. split a numeral into its base and ones components."),
            status(review_pending)).
action_maps(decimal, recalled_result_scaling, identify_dividend_scale_factor, read_operand_attribute,
            confidence(high),
            evidence("decimal/recalled_result_scaling, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(decimal, recalled_result_scaling, name_decimal_quotient, name_result,
            confidence(high),
            evidence("decimal/recalled_result_scaling, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. say which quantity the answer is."),
            status(review_pending)).
action_maps(decimal, recalled_result_scaling, propagate_scale_factor_through_quotient, scale_multiplicatively,
            confidence(high),
            evidence("decimal/recalled_result_scaling, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. multiply a quantity or a term by a factor, keeping the multiplicative relation."),
            status(review_pending)).
action_maps(decimal, recalled_result_scaling, recall_base_division_fact, retrieve_known_fact,
            confidence(high),
            evidence("decimal/recalled_result_scaling, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. recall a stored fact instead of reconstructing it."),
            status(review_pending)).
action_maps(division, divide_larger_by_smaller, read_dividend_and_divisor_as_numerals, register_givens,
            confidence(high),
            evidence("division/divide_larger_by_smaller, q_start -> q_step_1: 1 of the machine's 6 distinct edges. holds the problem-named dividend and divisor before the magnitude rule acts."),
            status(review_pending)).
action_maps(division, divide_larger_by_smaller, identify_larger_and_smaller, order_by_magnitude,
            confidence(high),
            evidence("division/divide_larger_by_smaller, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges. orders the two positive operands by magnitude."),
            status(review_pending)).
action_maps(division, divide_larger_by_smaller, replace_dividend_divisor_roles_with_magnitude_order, conflate_roles,
            confidence(high),
            evidence("division/divide_larger_by_smaller, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges. replaces the problem's dividend and divisor roles with larger and smaller, the documented deformation."),
            status(review_pending)).
action_maps(division, divide_larger_by_smaller, divide_reordered_operands, apply_stored_rule,
            confidence(high),
            evidence("division/divide_larger_by_smaller, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges. performs integer quotient-and-remainder division on the reordered operands."),
            status(review_pending)).
action_maps(division, divide_larger_by_smaller, name_quotient_and_remainder, name_result,
            confidence(high),
            evidence("division/divide_larger_by_smaller, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges. names the quotient and remainder in the productive partner's result schema."),
            status(review_pending)).
action_maps(division, divide_larger_by_smaller, record_dividend_divisor_role_viability, verify_invariant,
            confidence(high),
            evidence("division/divide_larger_by_smaller, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges. records whether magnitude ordering preserved or replaced the problem-named roles."),
            status(review_pending)).
action_maps(division, fair_share_equal_groups, deal_one_to_each_group_by_rounds, share_into_known_groups,
            confidence(high),
            evidence("division/fair_share_equal_groups, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, witnessed. deal the total into a known number of groups to find how much each group holds."),
            status(review_pending)).
action_maps(division, fair_share_equal_groups, name_items_per_group, name_result,
            confidence(high),
            evidence("division/fair_share_equal_groups, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, witnessed. say which quantity the answer is."),
            status(review_pending)).
action_maps(division, fair_share_equal_groups, preserve_equal_shares, verify_invariant,
            confidence(high),
            evidence("division/fair_share_equal_groups, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, witnessed. certifies the shares as equal after the dealing rounds; the edge is intermediate, so it is a check rather than a closing conservation"),
            status(review_pending)).
action_maps(division, fair_share_equal_groups, set_number_of_groups, assign_roles,
            confidence(high),
            evidence("division/fair_share_equal_groups, q_start -> q_step_1: 1 of the machine's 4 distinct edges, witnessed. binds the divisor to the number-of-groups role, which is what makes this sharing rather than measuring"),
            status(review_pending)).
action_maps(division, inverse_fact_decomposition, accumulate_partial_quotients, accumulate_total,
            confidence(high),
            evidence("division/inverse_fact_decomposition, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. add the counted or measured pieces into a running total."),
            status(review_pending)).
action_maps(division, inverse_fact_decomposition, apply_known_multiple_facts, measure_out_group_size,
            confidence(high),
            evidence("division/inverse_fact_decomposition, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. removes known multiples of the divisor from the total in turn"),
            status(review_pending)).
action_maps(division, inverse_fact_decomposition, load_known_multiples, retrieve_known_fact,
            confidence(high),
            evidence("division/inverse_fact_decomposition, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. brings the known multiples of the divisor to hand as the facts the decomposition will use"),
            status(review_pending)).
action_maps(division, inverse_fact_decomposition, name_fact_decomposition_result, name_result,
            confidence(high),
            evidence("division/inverse_fact_decomposition, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. say which quantity the answer is."),
            status(review_pending)).
action_maps(division, long_division, bring_down_dividend_digits_left_to_right, apply_stored_rule,
            confidence(high),
            evidence("division/long_division, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, witnessed. carry out a remembered formula, rule, or prescribed procedural step."),
            status(review_pending)).
action_maps(division, long_division, emit_each_quotient_digit_at_its_place_value_column, inscribe_result,
            confidence(high),
            evidence("division/long_division, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, witnessed. write the result in notation."),
            status(review_pending)).
action_maps(division, long_division, estimate_each_quotient_digit_by_trial_multiplication, apply_stored_rule,
            confidence(high),
            evidence("division/long_division, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges, witnessed. carry out a remembered formula, rule, or prescribed procedural step."),
            status(review_pending)).
action_maps(division, long_division, name_quotient_and_remainder, name_result,
            confidence(high),
            evidence("division/long_division, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, witnessed. say which quantity the answer is."),
            status(review_pending)).
action_maps(division, long_division, set_dividend_and_divisor, register_givens,
            confidence(high),
            evidence("division/long_division, q_start -> q_step_1: 1 of the machine's 6 distinct edges, witnessed. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(division, long_division, subtract_partial_product_with_borrow_then_bring_down, apply_stored_rule,
            confidence(high),
            evidence("division/long_division, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges, witnessed. carry out a remembered formula, rule, or prescribed procedural step."),
            status(review_pending)).
action_maps(division, measure_groups_of_size, count_measured_groups, count_units,
            confidence(high),
            evidence("division/measure_groups_of_size, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, witnessed. count how many units the iteration or the partition produced."),
            status(review_pending)).
action_maps(division, measure_groups_of_size, name_quotient_and_remainder, name_result,
            confidence(high),
            evidence("division/measure_groups_of_size, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, witnessed. say which quantity the answer is."),
            status(review_pending)).
action_maps(division, measure_groups_of_size, preserve_leftover_as_remainder, retain_what_must_survive,
            confidence(high),
            evidence("division/measure_groups_of_size, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, witnessed. carries the leftover forward as the remainder, which is exactly what division/share_into_divisor_groups loses at its own last edge (lose_measurement_remainder)"),
            status(review_pending)).
action_maps(division, measure_groups_of_size, repeatedly_remove_group_size, measure_out_group_size,
            confidence(high),
            evidence("division/measure_groups_of_size, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, witnessed. remove a known group size repeatedly to find how many groups the total holds."),
            status(review_pending)).
action_maps(division, measure_groups_of_size, set_group_size, assign_roles,
            confidence(high),
            evidence("division/measure_groups_of_size, q_start -> q_step_1: 1 of the machine's 5 distinct edges, witnessed. binds the divisor to the group-size role, which is what makes this measuring rather than sharing"),
            status(review_pending)).
action_maps(division, missing_factor_known_product_search, locate_matching_product, filter_by_constraint,
            confidence(high),
            evidence("division/missing_factor_known_product_search, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. keeps the candidate whose product matches the total"),
            status(review_pending)).
action_maps(division, missing_factor_known_product_search, name_missing_factor_as_quotient, name_result,
            confidence(high),
            evidence("division/missing_factor_known_product_search, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. say which quantity the answer is."),
            status(review_pending)).
action_maps(division, missing_factor_known_product_search, set_division_as_missing_factor, assign_roles,
            confidence(high),
            evidence("division/missing_factor_known_product_search, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. binds the division to the missing-factor role, so the search is for a factor rather than a share"),
            status(review_pending)).
action_maps(division, missing_factor_known_product_search, test_candidate_products, enumerate_candidates,
            confidence(high),
            evidence("division/missing_factor_known_product_search, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. generate the candidate set a later step will filter."),
            status(review_pending)).
action_maps(division, missing_factor_repeated_addition, count_by_factor_until_total, count_up_to_target,
            confidence(high),
            evidence("division/missing_factor_repeated_addition, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, witnessed. count forward until a named target is reached, holding the distance travelled."),
            status(review_pending)).
action_maps(division, missing_factor_repeated_addition, name_iteration_count_as_quotient, name_result,
            confidence(high),
            evidence("division/missing_factor_repeated_addition, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, witnessed. say which quantity the answer is."),
            status(review_pending)).
action_maps(division, missing_factor_repeated_addition, preserve_missing_factor_relation, record_conservation,
            confidence(high),
            evidence("division/missing_factor_repeated_addition, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, witnessed. record that the strategy kept the relation it was obliged to keep."),
            status(review_pending)).
action_maps(division, missing_factor_repeated_addition, set_factor, register_givens,
            confidence(high),
            evidence("division/missing_factor_repeated_addition, q_start -> q_step_1: 1 of the machine's 4 distinct edges, witnessed. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(division, name_group_count_as_share_size, confuse_number_of_groups_with_share_size, conflate_roles,
            confidence(high),
            evidence("division/name_group_count_as_share_size, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, witnessed. collapse two structurally distinct roles into one."),
            status(review_pending)).
action_maps(division, name_group_count_as_share_size, lose_items_per_group, record_loss,
            confidence(high),
            evidence("division/name_group_count_as_share_size, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, witnessed. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(division, name_group_count_as_share_size, name_group_count_as_answer, misname_result,
            confidence(high),
            evidence("division/name_group_count_as_share_size, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, witnessed. name a value that answers a different question than the one asked."),
            status(review_pending)).
action_maps(division, name_group_count_as_share_size, set_number_of_groups, assign_roles,
            confidence(high),
            evidence("division/name_group_count_as_share_size, q_start -> q_step_1: 1 of the machine's 4 distinct edges, witnessed. binds the divisor to the number-of-groups role, which is what makes this sharing rather than measuring"),
            status(review_pending)).
action_maps(division, name_reached_total_as_quotient, count_by_factor_until_total, count_up_to_target,
            confidence(high),
            evidence("division/name_reached_total_as_quotient, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, witnessed. count forward until a named target is reached, holding the distance travelled."),
            status(review_pending)).
action_maps(division, name_reached_total_as_quotient, lose_iteration_count, record_loss,
            confidence(high),
            evidence("division/name_reached_total_as_quotient, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, witnessed. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(division, name_reached_total_as_quotient, name_reached_total_as_answer, misname_result,
            confidence(high),
            evidence("division/name_reached_total_as_quotient, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, witnessed. name a value that answers a different question than the one asked."),
            status(review_pending)).
action_maps(division, name_reached_total_as_quotient, set_factor, register_givens,
            confidence(high),
            evidence("division/name_reached_total_as_quotient, q_start -> q_step_1: 1 of the machine's 4 distinct edges, witnessed. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(division, partial_quotient_chunking, accumulate_partial_quotients, accumulate_total,
            confidence(high),
            evidence("division/partial_quotient_chunking, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, witnessed. add the counted or measured pieces into a running total."),
            status(review_pending)).
action_maps(division, partial_quotient_chunking, choose_partial_quotient_multiples, select_unit_scale,
            confidence(high),
            evidence("division/partial_quotient_chunking, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, witnessed. chooses the multiples of the divisor that will serve as the chunks the dividend is measured out in"),
            status(review_pending)).
action_maps(division, partial_quotient_chunking, name_partial_quotient_result, name_result,
            confidence(high),
            evidence("division/partial_quotient_chunking, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, witnessed. say which quantity the answer is."),
            status(review_pending)).
action_maps(division, partial_quotient_chunking, set_divisor_as_chunk_unit, select_unit_scale,
            confidence(high),
            evidence("division/partial_quotient_chunking, q_start -> q_step_1: 1 of the machine's 5 distinct edges, witnessed. choose which unit, base, or scale to work in from among the available ones."),
            status(review_pending)).
action_maps(division, partial_quotient_chunking, subtract_partial_multiples, remove_quantity,
            confidence(high),
            evidence("division/partial_quotient_chunking, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, witnessed. take one quantity away from another."),
            status(review_pending)).
action_maps(division, reject_known_product_match, locate_matching_product, filter_by_constraint,
            confidence(high),
            evidence("division/reject_known_product_match, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. keeps the candidate whose product matches the total"),
            status(review_pending)).
action_maps(division, reject_known_product_match, lose_known_product_context, record_loss,
            confidence(high),
            evidence("division/reject_known_product_match, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(division, reject_known_product_match, reject_product_match_as_not_contextualized, treat_relevant_as_irrelevant,
            confidence(medium),
            evidence("division/reject_known_product_match, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. treats a product that does match as not bearing, because it arrived without its context"),
            status(review_pending)).
action_maps(division, reject_known_product_match, set_division_as_missing_factor, assign_roles,
            confidence(high),
            evidence("division/reject_known_product_match, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. binds the division to the missing-factor role, so the search is for a factor rather than a share"),
            status(review_pending)).
action_maps(division, reject_known_product_match, test_candidate_products, enumerate_candidates,
            confidence(high),
            evidence("division/reject_known_product_match, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. generate the candidate set a later step will filter."),
            status(review_pending)).
action_maps(division, share_into_divisor_groups, deal_total_into_groups, share_into_known_groups,
            confidence(high),
            evidence("division/share_into_divisor_groups, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, witnessed. deals the total into groups, the divisor having been reinterpreted as a group count at the previous edge"),
            status(review_pending)).
action_maps(division, share_into_divisor_groups, lose_measurement_remainder, record_loss,
            confidence(high),
            evidence("division/share_into_divisor_groups, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, witnessed. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(division, share_into_divisor_groups, name_items_in_first_group_as_number_of_groups, misname_result,
            confidence(high),
            evidence("division/share_into_divisor_groups, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, witnessed. name a value that answers a different question than the one asked."),
            status(review_pending)).
action_maps(division, share_into_divisor_groups, reinterpret_divisor_as_number_of_groups, conflate_roles,
            confidence(high),
            evidence("division/share_into_divisor_groups, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, witnessed. collapse two structurally distinct roles into one."),
            status(review_pending)).
action_maps(division, share_into_divisor_groups, set_group_size, assign_roles,
            confidence(high),
            evidence("division/share_into_divisor_groups, q_start -> q_step_1: 1 of the machine's 5 distinct edges, witnessed. binds the divisor to the group-size role, which is what makes this measuring rather than sharing"),
            status(review_pending)).
action_maps(division, stop_after_first_partial_quotient, choose_first_partial_multiple, select_unit_scale,
            confidence(high),
            evidence("division/stop_after_first_partial_quotient, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, witnessed. chooses only the first chunk; the halt before recomposition is recorded two edges later"),
            status(review_pending)).
action_maps(division, stop_after_first_partial_quotient, lose_partial_quotient_recomposition, record_loss,
            confidence(high),
            evidence("division/stop_after_first_partial_quotient, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, witnessed. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(division, stop_after_first_partial_quotient, name_incomplete_partial_quotient, misname_result,
            confidence(high),
            evidence("division/stop_after_first_partial_quotient, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, witnessed. name a value that answers a different question than the one asked."),
            status(review_pending)).
action_maps(division, stop_after_first_partial_quotient, set_divisor_as_chunk_unit, select_unit_scale,
            confidence(high),
            evidence("division/stop_after_first_partial_quotient, q_start -> q_step_1: 1 of the machine's 6 distinct edges, witnessed. choose which unit, base, or scale to work in from among the available ones."),
            status(review_pending)).
action_maps(division, stop_after_first_partial_quotient, stop_before_recomposing_remaining_total, halt_before_completion,
            confidence(high),
            evidence("division/stop_after_first_partial_quotient, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges, witnessed. stop a required traversal, iteration, or recomposition before it finishes."),
            status(review_pending)).
action_maps(division, stop_after_first_partial_quotient, subtract_first_partial_multiple, remove_quantity,
            confidence(high),
            evidence("division/stop_after_first_partial_quotient, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges, witnessed. take one quantity away from another."),
            status(review_pending)).
action_maps(division, stop_after_one_known_fact, apply_first_known_multiple_only, measure_out_group_size,
            confidence(medium),
            evidence("division/stop_after_one_known_fact, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. removes one known multiple where the decomposition iterates over several"),
            status(review_pending)).
action_maps(division, stop_after_one_known_fact, load_known_multiples, retrieve_known_fact,
            confidence(high),
            evidence("division/stop_after_one_known_fact, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. brings the known multiples of the divisor to hand as the facts the decomposition will use"),
            status(review_pending)).
action_maps(division, stop_after_one_known_fact, lose_iterative_fact_decomposition, record_loss,
            confidence(high),
            evidence("division/stop_after_one_known_fact, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(division, stop_after_one_known_fact, name_partial_quotient_and_remainder, misname_result,
            confidence(high),
            evidence("division/stop_after_one_known_fact, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. names the quotient reached after one fact, with the untouched remainder beside it, as the answer"),
            status(review_pending)).
action_maps(division, stop_after_one_known_fact, stop_with_remaining_total, halt_before_completion,
            confidence(high),
            evidence("division/stop_after_one_known_fact, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. stop a required traversal, iteration, or recomposition before it finishes."),
            status(review_pending)).
action_maps(division, stop_at_nearby_product_in_search, lose_exact_missing_factor, record_loss,
            confidence(high),
            evidence("division/stop_at_nearby_product_in_search, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(division, stop_at_nearby_product_in_search, name_nearby_factor_and_remainder, misname_result,
            confidence(high),
            evidence("division/stop_at_nearby_product_in_search, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. name a value that answers a different question than the one asked."),
            status(review_pending)).
action_maps(division, stop_at_nearby_product_in_search, set_division_as_missing_factor, assign_roles,
            confidence(high),
            evidence("division/stop_at_nearby_product_in_search, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. binds the division to the missing-factor role, so the search is for a factor rather than a share"),
            status(review_pending)).
action_maps(division, stop_at_nearby_product_in_search, stop_before_matching_product, halt_before_completion,
            confidence(high),
            evidence("division/stop_at_nearby_product_in_search, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. stop a required traversal, iteration, or recomposition before it finishes."),
            status(review_pending)).
action_maps(division, stop_at_nearby_product_in_search, test_candidate_products_until_nearby, enumerate_candidates,
            confidence(medium),
            evidence("division/stop_at_nearby_product_in_search, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. enumerates candidates only as far as one that comes close"),
            status(review_pending)).
action_maps(division, sum_dividend_and_divisor, collapse_the_bring_down_and_borrow_loop_to_one_step, omit_required_step,
            confidence(high),
            evidence("division/sum_dividend_and_divisor, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. the loop's steps do not run at all once the single addition has stood in for them"),
            status(review_pending)).
action_maps(division, sum_dividend_and_divisor, lose_quotient_recomposition, record_loss,
            confidence(high),
            evidence("division/sum_dividend_and_divisor, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(division, sum_dividend_and_divisor, name_digit_sum_as_answer, misname_result,
            confidence(high),
            evidence("division/sum_dividend_and_divisor, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. name a value that answers a different question than the one asked."),
            status(review_pending)).
action_maps(division, sum_dividend_and_divisor, read_dividend_and_divisor_as_numerals, register_givens,
            confidence(high),
            evidence("division/sum_dividend_and_divisor, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(division, sum_dividend_and_divisor, replace_coordinated_division_with_a_single_addition, substitute_operation,
            confidence(high),
            evidence("division/sum_dividend_and_divisor, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. adds the two numerals where the division coordinates a divide, multiply and subtract loop"),
            status(review_pending)).
action_maps(fraction, add_numerator_denominator_comparison, compare_unlike_sums, compare_magnitudes,
            confidence(high),
            evidence("fraction/add_numerator_denominator_comparison, q_compare_same_denominator -> q_emit_order: 1 of the machine's 7 distinct edges, witnessed. decide the order relation between two quantities."),
            status(review_pending)).
action_maps(fraction, add_numerator_denominator_comparison, emit, emit_result,
            confidence(high),
            evidence("fraction/add_numerator_denominator_comparison, q_emit_order -> q_accept: 1 of the machine's 7 distinct edges, witnessed. release the result from the machine."),
            status(review_pending)).
action_maps(fraction, add_numerator_denominator_comparison, first, combine_quantities,
            confidence(medium),
            evidence("fraction/add_numerator_denominator_comparison, q_add_numerator_denominator -> q_add_numerator_denominator: 1 of the machine's 7 distinct edges, witnessed. adds the first pair of terms at the self-loop on q_add_numerator_denominator, numerators and denominators alike"),
            status(review_pending)).
action_maps(fraction, add_numerator_denominator_comparison, init, initiate,
            confidence(high),
            evidence("fraction/add_numerator_denominator_comparison, q_init -> q_common_partition: 1 of the machine's 7 distinct edges, witnessed. enter the machine without yet doing mathematical work."),
            status(review_pending)).
action_maps(fraction, add_numerator_denominator_comparison, no_common_unit_constructed, omit_required_step,
            confidence(high),
            evidence("fraction/add_numerator_denominator_comparison, q_common_partition -> q_add_numerator_denominator: 1 of the machine's 7 distinct edges, witnessed. the common unit the comparison needs is never constructed; the edge leaves q_common_partition without doing the partitioning"),
            status(review_pending)).
action_maps(fraction, add_numerator_denominator_comparison, omitted, omit_required_step,
            confidence(high),
            evidence("fraction/add_numerator_denominator_comparison, q_measure_with_co_unit -> q_compare_same_denominator: 1 of the machine's 7 distinct edges, witnessed. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(fraction, add_numerator_denominator_comparison, second, combine_quantities,
            confidence(medium),
            evidence("fraction/add_numerator_denominator_comparison, q_add_numerator_denominator -> q_measure_with_co_unit: 1 of the machine's 7 distinct edges, witnessed. adds the second pair of terms in the same numerator-and-denominator manner"),
            status(review_pending)).
action_maps(fraction, add_numerator_denominator_sum, emit, emit_result,
            confidence(high),
            evidence("fraction/add_numerator_denominator_sum, q_emit_sum -> q_accept: 1 of the machine's 8 distinct edges, static only. release the result from the machine."),
            status(review_pending)).
action_maps(fraction, add_numerator_denominator_sum, init, initiate,
            confidence(high),
            evidence("fraction/add_numerator_denominator_sum, q_init -> q_rename_addends_as_counts: 1 of the machine's 8 distinct edges, static only. enter the machine without yet doing mathematical work."),
            status(review_pending)).
action_maps(fraction, add_numerator_denominator_sum, no_common_unit_constructed, omit_required_step,
            confidence(high),
            evidence("fraction/add_numerator_denominator_sum, q_common_partition -> q_add_numerator_denominator: 1 of the machine's 8 distinct edges, static only. skip a step the viable strategy needs: the slot where common_denominator_fraction_addition constructs the shared partition passes with nothing constructed, the same omission the comparison sibling records under this label."),
            status(review_pending)).
action_maps(fraction, add_numerator_denominator_sum, numerators_and_denominators_added, combine_quantities,
            confidence(medium),
            evidence("fraction/add_numerator_denominator_sum, q_add_numerator_denominator -> q_measure_with_co_unit: 1 of the machine's 8 distinct edges, static only. joins numerators into a numerator and denominators into a denominator; the combining itself is a true joining of quantities, and what is wrong -- the absent common unit -- is charged once at the omission edge before it, the same single-charge decision this file records for the comparison sibling's first and second rows."),
            status(review_pending)).
action_maps(fraction, add_numerator_denominator_sum, omitted, omit_required_step,
            confidence(high),
            evidence("fraction/add_numerator_denominator_sum, q_measure_with_co_unit -> q_between_check: 1 of the machine's 8 distinct edges, static only. skip a step the viable strategy needs: the co-measurement slot passes with no shared unit to measure in."),
            status(review_pending)).
action_maps(fraction, add_numerator_denominator_sum, record_betweenness, verify_invariant,
            confidence(high),
            evidence("fraction/add_numerator_denominator_sum, q_between_check -> q_viability_context: 1 of the machine's 8 distinct edges, static only. check that the property the strategy must keep still holds: an intermediate edge certifying the relation the mediant practice conserves, that the result stays inside the two addends' closed interval -- the Position rule's certify-a-relation case, not a terminal keep-or-lose record."),
            status(review_pending)).
action_maps(fraction, add_numerator_denominator_sum, record_viability, record_viability,
            confidence(high),
            evidence("fraction/add_numerator_denominator_sum, q_viability_context -> q_emit_sum: 1 of the machine's 8 distinct edges, static only. record whether the strategy is contextually correct for this input: the same per-input contextual verdict gap_thinking_fraction_comparison and decimal_scale_loss_comparison record under their viability label."),
            status(review_pending)).
action_maps(fraction, add_numerator_denominator_sum, renamings, re_express_equivalently,
            confidence(high),
            evidence("fraction/add_numerator_denominator_sum, q_rename_addends_as_counts -> q_common_partition: 1 of the machine's 8 distinct edges, static only. rewrite a quantity or relation in a commensurate form without changing what it says: printed mixed and whole addends are renamed as fraction counts before any deforming move fires."),
            status(review_pending)).
action_maps(fraction, area_model_fraction_comparison, co_measure, align_to_common_unit,
            confidence(high),
            evidence("fraction/area_model_fraction_comparison, q_compare_relative_size -> q_emit: 1 of the machine's 8 distinct edges, witnessed. bring both quantities into a shared unit, denominator, or decimal scale so they can be measured against each other."),
            status(review_pending)).
action_maps(fraction, area_model_fraction_comparison, congruent_unit_regions, unitize_referent,
            confidence(high),
            evidence("fraction/area_model_fraction_comparison, q_unitize_whole -> q_verify_same_size_whole: 1 of the machine's 8 distinct edges, witnessed. constitutes the drawn regions as congruent unit wholes, which is what the next edge then certifies"),
            status(review_pending)).
action_maps(fraction, area_model_fraction_comparison, emit, emit_result,
            confidence(high),
            evidence("fraction/area_model_fraction_comparison, q_emit -> q_accept: 1 of the machine's 8 distinct edges, witnessed. release the result from the machine."),
            status(review_pending)).
action_maps(fraction, area_model_fraction_comparison, equal_partitions, partition_into_equal_parts,
            confidence(high),
            evidence("fraction/area_model_fraction_comparison, q_partition -> q_disembed: 1 of the machine's 8 distinct edges, witnessed. cut the referent into parts the strategy treats as equal."),
            status(review_pending)).
action_maps(fraction, area_model_fraction_comparison, init, initiate,
            confidence(high),
            evidence("fraction/area_model_fraction_comparison, q_init -> q_unitize_whole: 1 of the machine's 8 distinct edges, witnessed. enter the machine without yet doing mathematical work."),
            status(review_pending)).
action_maps(fraction, area_model_fraction_comparison, iterations, iterate_unit,
            confidence(high),
            evidence("fraction/area_model_fraction_comparison, q_iterate_count_parts -> q_compare_relative_size: 1 of the machine's 8 distinct edges, witnessed. repeat a unit to build or to measure a quantity."),
            status(review_pending)).
action_maps(fraction, area_model_fraction_comparison, same_size_wholes_certified, verify_invariant,
            confidence(high),
            evidence("fraction/area_model_fraction_comparison, q_verify_same_size_whole -> q_partition: 1 of the machine's 8 distinct edges, witnessed. check that the property the strategy must keep still holds."),
            status(review_pending)).
action_maps(fraction, area_model_fraction_comparison, shaded_parts, disembed_part,
            confidence(high),
            evidence("fraction/area_model_fraction_comparison, q_disembed -> q_iterate_count_parts: 1 of the machine's 8 distinct edges, witnessed. take a part out of the whole while the part stays inside the whole."),
            status(review_pending)).
action_maps(fraction, area_model_part_of_part, count_small_rectangles_in_whole, count_units,
            confidence(high),
            evidence("fraction/area_model_part_of_part, q_step_5 -> q_step_6: 1 of the machine's 8 distinct edges, witnessed. count how many units the iteration or the partition produced."),
            status(review_pending)).
action_maps(fraction, area_model_part_of_part, count_small_rectangles_selected, count_units,
            confidence(high),
            evidence("fraction/area_model_part_of_part, q_step_6 -> q_step_7: 1 of the machine's 8 distinct edges, witnessed. count how many units the iteration or the partition produced."),
            status(review_pending)).
action_maps(fraction, area_model_part_of_part, establish_referent_whole, unitize_referent,
            confidence(high),
            evidence("fraction/area_model_part_of_part, q_start -> q_step_1: 1 of the machine's 8 distinct edges, witnessed. constitute the whole or unit that all later measurement refers to."),
            status(review_pending)).
action_maps(fraction, area_model_part_of_part, partition_each_strip_horizontally, partition_into_equal_parts,
            confidence(high),
            evidence("fraction/area_model_part_of_part, q_step_3 -> q_step_4: 1 of the machine's 8 distinct edges, witnessed. cut the referent into parts the strategy treats as equal."),
            status(review_pending)).
action_maps(fraction, area_model_part_of_part, partition_unit_square_vertically, partition_into_equal_parts,
            confidence(high),
            evidence("fraction/area_model_part_of_part, q_step_1 -> q_step_2: 1 of the machine's 8 distinct edges, witnessed. cut the referent into parts the strategy treats as equal."),
            status(review_pending)).
action_maps(fraction, area_model_part_of_part, read_off_part_of_part, name_result,
            confidence(high),
            evidence("fraction/area_model_part_of_part, q_step_7 -> q_accept: 1 of the machine's 8 distinct edges, witnessed. say which quantity the answer is."),
            status(review_pending)).
action_maps(fraction, area_model_part_of_part, select_first_fraction_strip, select_part,
            confidence(high),
            evidence("fraction/area_model_part_of_part, q_step_2 -> q_step_3: 1 of the machine's 8 distinct edges, witnessed. pick out one part, subset, strip, side, or piece as the object of the next step."),
            status(review_pending)).
action_maps(fraction, area_model_part_of_part, select_part_of_part_in_strip, select_part,
            confidence(high),
            evidence("fraction/area_model_part_of_part, q_step_4 -> q_step_5: 1 of the machine's 8 distinct edges, witnessed. pick out one part, subset, strip, side, or piece as the object of the next step."),
            status(review_pending)).
action_maps(fraction, area_model_unequal_partition_piece_count, drawn_regions_treated_as_wholes, accept_without_check,
            confidence(high),
            evidence("fraction/area_model_unequal_partition_piece_count, q_unitize_whole -> q_verify_same_size_whole: 1 of the machine's 9 distinct edges, witnessed. takes the drawn regions as wholes without constituting a referent whole, where area_model_fraction_comparison unitizes at the same slot"),
            status(review_pending)).
action_maps(fraction, area_model_unequal_partition_piece_count, emit, emit_result,
            confidence(high),
            evidence("fraction/area_model_unequal_partition_piece_count, q_emit -> q_accept: 1 of the machine's 9 distinct edges, witnessed. release the result from the machine."),
            status(review_pending)).
action_maps(fraction, area_model_unequal_partition_piece_count, init, initiate,
            confidence(high),
            evidence("fraction/area_model_unequal_partition_piece_count, q_init -> q_unitize_whole: 1 of the machine's 9 distinct edges, witnessed. enter the machine without yet doing mathematical work."),
            status(review_pending)).
action_maps(fraction, area_model_unequal_partition_piece_count, raw_piece_counts, count_units,
            confidence(high),
            evidence("fraction/area_model_unequal_partition_piece_count, q_iterate_count_parts -> q_compare_relative_size: 1 of the machine's 9 distinct edges, witnessed. counts the pieces as raw counts, the partition's equality never having been checked"),
            status(review_pending)).
action_maps(fraction, area_model_unequal_partition_piece_count, same_size_wholes_not_checked, accept_without_check,
            confidence(high),
            evidence("fraction/area_model_unequal_partition_piece_count, q_verify_same_size_whole -> q_partition: 1 of the machine's 9 distinct edges, witnessed. accept a structure without the verification it needs."),
            status(review_pending)).
action_maps(fraction, area_model_unequal_partition_piece_count, shaded_pieces_removed_from_partition_structure, treat_relevant_as_irrelevant,
            confidence(high),
            evidence("fraction/area_model_unequal_partition_piece_count, q_disembed -> q_iterate_count_parts: 1 of the machine's 9 distinct edges, witnessed. takes the shaded pieces out of the partition structure rather than disembedding them from it, so the pieces no longer answer to the partition that made them"),
            status(review_pending)).
action_maps(fraction, area_model_unequal_partition_piece_count, treat_unequal_pieces_as_equal_counts, substitute_count_for_measure,
            confidence(high),
            evidence("fraction/area_model_unequal_partition_piece_count, q_unequal_partition_piece_count -> q_disembed: 1 of the machine's 9 distinct edges, witnessed. counts pieces as though counting settled the matter, the partition's equality never having been checked"),
            status(review_pending)).
action_maps(fraction, area_model_unequal_partition_piece_count, unequal_partitions_accepted_without_equality_check, accept_without_check,
            confidence(high),
            evidence("fraction/area_model_unequal_partition_piece_count, q_partition -> q_unequal_partition_piece_count: 1 of the machine's 9 distinct edges, witnessed. accept a structure without the verification it needs."),
            status(review_pending)).
action_maps(fraction, area_model_unequal_partition_piece_count, whole_number_dominance, substitute_count_for_measure,
            confidence(high),
            evidence("fraction/area_model_unequal_partition_piece_count, q_compare_relative_size -> q_emit: 1 of the machine's 9 distinct edges, witnessed. orders by the whole-number piece counts in place of the fractional magnitudes"),
            status(review_pending)).
action_maps(fraction, benchmark_fraction_comparison, emit, emit_result,
            confidence(high),
            evidence("fraction/benchmark_fraction_comparison, q_emit -> q_accept; q_observed_6 -> q_accept: 2 of the machine's 14 distinct edges, witnessed. release the result from the machine."),
            status(review_pending)).
action_maps(fraction, benchmark_fraction_comparison, init, initiate,
            confidence(high),
            evidence("fraction/benchmark_fraction_comparison, q_init -> q_select_benchmark; q_init -> q_observed_1: 2 of the machine's 14 distinct edges, witnessed. enter the machine without yet doing mathematical work."),
            status(review_pending)).
action_maps(fraction, benchmark_fraction_comparison, judgment, judge_against_benchmark,
            confidence(high),
            evidence("fraction/benchmark_fraction_comparison, q_benchmark_first -> q_benchmark_second; q_benchmark_second -> q_residual_compare; q_observed_2 -> q_observed_3 (+1 more): 4 of the machine's 14 distinct edges, witnessed. judge each quantity against a shared reference point."),
            status(review_pending)).
action_maps(fraction, benchmark_fraction_comparison, opposite_sides, judge_against_benchmark,
            confidence(high),
            evidence("fraction/benchmark_fraction_comparison, q_observed_4 -> q_observed_5: 1 of the machine's 14 distinct edges, witnessed. records that the two fell on opposite sides of the benchmark; it fills the slot the static path fills with judgment"),
            status(review_pending)).
action_maps(fraction, benchmark_fraction_comparison, residual, compare_residuals,
            confidence(high),
            evidence("fraction/benchmark_fraction_comparison, q_residual_compare -> q_emit; q_observed_5 -> q_observed_6: 2 of the machine's 14 distinct edges, witnessed. compare what is left over between each quantity and the benchmark."),
            status(review_pending)).
action_maps(fraction, benchmark_fraction_comparison, same_side_requires_residual, judge_against_benchmark,
            confidence(high),
            evidence("fraction/benchmark_fraction_comparison, q_observed_4 -> q_observed_5: 1 of the machine's 14 distinct edges, witnessed. records that both fractions fell on the same side of the benchmark, which is what obliges the residual comparison at the next edge"),
            status(review_pending)).
action_maps(fraction, benchmark_fraction_comparison, selected, establish_reference_frame,
            confidence(high),
            evidence("fraction/benchmark_fraction_comparison, q_select_benchmark -> q_benchmark_first; q_observed_1 -> q_observed_2: 2 of the machine's 14 distinct edges, witnessed. the benchmark has been selected: it becomes the reference point both later judgments are made against"),
            status(review_pending)).
action_maps(fraction, clear_inner_referent, fail_to_relate_inner_part_to_original_whole, omit_required_step,
            confidence(high),
            evidence("fraction/clear_inner_referent, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(fraction, clear_inner_referent, lose_outer_referent, record_loss,
            confidence(high),
            evidence("fraction/clear_inner_referent, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(fraction, clear_inner_referent, name_inner_part_relative_to_outer_part, name_result,
            confidence(medium),
            evidence("fraction/clear_inner_referent, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. names the inner part against the outer part rather than against the whole, which is the referent the next edge fails to reach"),
            status(review_pending)).
action_maps(fraction, clear_inner_referent, partition_that_part_again, partition_into_equal_parts,
            confidence(high),
            evidence("fraction/clear_inner_referent, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. cut the referent into parts the strategy treats as equal."),
            status(review_pending)).
action_maps(fraction, clear_inner_referent, partition_whole_into_equal_units, partition_into_equal_parts,
            confidence(high),
            evidence("fraction/clear_inner_referent, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. cut the referent into parts the strategy treats as equal."),
            status(review_pending)).
action_maps(fraction, co_denominator_count_on_from_larger, attach_three_level_units_coordination, attach_units_coordination,
            confidence(high),
            evidence("fraction/co_denominator_count_on_from_larger, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, static only. attach to the result the level of units coordination it carries."),
            status(review_pending)).
action_maps(fraction, co_denominator_count_on_from_larger, cgi_kernel_outcome, receive_kernel_outcome,
            confidence(high),
            evidence("fraction/co_denominator_count_on_from_larger, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, static only. take the delegated automaton's outcome back as this machine's step."),
            status(review_pending)).
action_maps(fraction, co_denominator_count_on_from_larger, confirm_same_denominator, verify_invariant,
            confidence(high),
            evidence("fraction/co_denominator_count_on_from_larger, q_start -> q_step_1: 1 of the machine's 6 distinct edges, static only. check that the property the strategy must keep still holds."),
            status(review_pending)).
action_maps(fraction, co_denominator_count_on_from_larger, dispatch_to_cgi, dispatch_to_kernel,
            confidence(high),
            evidence("fraction/co_denominator_count_on_from_larger, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges, static only. hand the step to another automaton and wait on it."),
            status(review_pending)).
action_maps(fraction, co_denominator_count_on_from_larger, hold_referent_whole_at, unitize_referent,
            confidence(high),
            evidence("fraction/co_denominator_count_on_from_larger, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, static only. constitute the whole or unit that all later measurement refers to."),
            status(review_pending)).
action_maps(fraction, co_denominator_count_on_from_larger, hold_unit_fraction_at, select_unit_scale,
            confidence(high),
            evidence("fraction/co_denominator_count_on_from_larger, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges, static only. choose which unit, base, or scale to work in from among the available ones."),
            status(review_pending)).
action_maps(fraction, co_denominator_make_base_transfer, attach_three_level_units_coordination, attach_units_coordination,
            confidence(high),
            evidence("fraction/co_denominator_make_base_transfer, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, static only. attach to the result the level of units coordination it carries."),
            status(review_pending)).
action_maps(fraction, co_denominator_make_base_transfer, cgi_kernel_outcome, receive_kernel_outcome,
            confidence(high),
            evidence("fraction/co_denominator_make_base_transfer, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, static only. take the delegated automaton's outcome back as this machine's step."),
            status(review_pending)).
action_maps(fraction, co_denominator_make_base_transfer, confirm_same_denominator, verify_invariant,
            confidence(high),
            evidence("fraction/co_denominator_make_base_transfer, q_start -> q_step_1: 1 of the machine's 6 distinct edges, static only. check that the property the strategy must keep still holds."),
            status(review_pending)).
action_maps(fraction, co_denominator_make_base_transfer, dispatch_to_cgi, dispatch_to_kernel,
            confidence(high),
            evidence("fraction/co_denominator_make_base_transfer, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges, static only. hand the step to another automaton and wait on it."),
            status(review_pending)).
action_maps(fraction, co_denominator_make_base_transfer, hold_referent_whole_at, unitize_referent,
            confidence(high),
            evidence("fraction/co_denominator_make_base_transfer, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, static only. constitute the whole or unit that all later measurement refers to."),
            status(review_pending)).
action_maps(fraction, co_denominator_make_base_transfer, hold_unit_fraction_at, select_unit_scale,
            confidence(high),
            evidence("fraction/co_denominator_make_base_transfer, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges, static only. choose which unit, base, or scale to work in from among the available ones."),
            status(review_pending)).
action_maps(fraction, common_denominator_fraction_addition, co_measure, align_to_common_unit,
            confidence(high),
            evidence("fraction/common_denominator_fraction_addition, q_measure_with_co_unit -> q_combine_counts: 1 of the machine's 8 distinct edges, static only. bring both quantities into a shared unit, denominator, or decimal scale so they can be measured against each other."),
            status(review_pending)).
action_maps(fraction, common_denominator_fraction_addition, combined, combine_quantities,
            confidence(high),
            evidence("fraction/common_denominator_fraction_addition, q_combine_counts -> q_emit_sum: 1 of the machine's 8 distinct edges, static only. join two quantities into their sum: the two commensurate counts are joined over the shared unit the partition edge constructed, so the joining itself is the operation and the conservation rides on the alignment before it."),
            status(review_pending)).
action_maps(fraction, common_denominator_fraction_addition, emit, emit_result,
            confidence(high),
            evidence("fraction/common_denominator_fraction_addition, q_emit_sum -> q_accept: 1 of the machine's 8 distinct edges, static only. release the result from the machine."),
            status(review_pending)).
action_maps(fraction, common_denominator_fraction_addition, init, initiate,
            confidence(high),
            evidence("fraction/common_denominator_fraction_addition, q_init -> q_rename_addends_as_counts: 1 of the machine's 8 distinct edges, static only. enter the machine without yet doing mathematical work."),
            status(review_pending)).
action_maps(fraction, common_denominator_fraction_addition, partition, align_to_common_unit,
            confidence(high),
            evidence("fraction/common_denominator_fraction_addition, q_common_partition -> q_transform_commensurate_1: 1 of the machine's 8 distinct edges, static only. bring both quantities into a shared unit, denominator, or decimal scale so they can be measured against each other: the edge constructs the shared partition -- kept, refined, or cross-partitioned -- that both counts will be measured in, the doing align_to_common_unit's own citation already names at q_common_partition."),
            status(review_pending)).
action_maps(fraction, common_denominator_fraction_addition, renamings, re_express_equivalently,
            confidence(high),
            evidence("fraction/common_denominator_fraction_addition, q_rename_addends_as_counts -> q_common_partition: 1 of the machine's 8 distinct edges, static only. rewrite a quantity or relation in a commensurate form without changing what it says: mixed(1,5,8) becomes frac(13,8) and whole(3) becomes frac(3,1), each renaming carried in the trace with its printed form."),
            status(review_pending)).
action_maps(fraction, common_denominator_fraction_addition, transformed, re_express_equivalently,
            confidence(high),
            evidence("fraction/common_denominator_fraction_addition, q_transform_commensurate_1 -> q_transform_commensurate_2; q_transform_commensurate_2 -> q_measure_with_co_unit: 2 of the machine's 8 distinct edges, static only. rewrite a quantity or relation in a commensurate form without changing what it says."),
            status(review_pending)).
action_maps(fraction, common_denominator_fraction_subtraction, co_measure, align_to_common_unit,
            confidence(high),
            evidence("fraction/common_denominator_fraction_subtraction, q_measure_with_co_unit -> q_remove_counts: 1 of the machine's 8 distinct edges, static only. bring both quantities into a shared unit, denominator, or decimal scale so they can be measured against each other."),
            status(review_pending)).
action_maps(fraction, common_denominator_fraction_subtraction, emit, emit_result,
            confidence(high),
            evidence("fraction/common_denominator_fraction_subtraction, q_emit_difference -> q_accept: 1 of the machine's 8 distinct edges, static only. release the result from the machine."),
            status(review_pending)).
action_maps(fraction, common_denominator_fraction_subtraction, init, initiate,
            confidence(high),
            evidence("fraction/common_denominator_fraction_subtraction, q_init -> q_rename_addends_as_counts: 1 of the machine's 8 distinct edges, static only. enter the machine without yet doing mathematical work."),
            status(review_pending)).
action_maps(fraction, common_denominator_fraction_subtraction, partition, align_to_common_unit,
            confidence(high),
            evidence("fraction/common_denominator_fraction_subtraction, q_common_partition -> q_transform_commensurate_1: 1 of the machine's 8 distinct edges, static only. bring both quantities into a shared unit, denominator, or decimal scale so they can be measured against each other: the same constructed-partition doing as in the addition machine, and the count removed on the later edge is only meaningful inside it."),
            status(review_pending)).
action_maps(fraction, common_denominator_fraction_subtraction, removed, remove_quantity,
            confidence(high),
            evidence("fraction/common_denominator_fraction_subtraction, q_remove_counts -> q_emit_difference: 1 of the machine's 8 distinct edges, static only. take one quantity away from another: the subtrahend's commensurate count is taken from the minuend's within the shared unit, the direction-committed counterpart of the addition machine's combining edge."),
            status(review_pending)).
action_maps(fraction, common_denominator_fraction_subtraction, renamings, re_express_equivalently,
            confidence(high),
            evidence("fraction/common_denominator_fraction_subtraction, q_rename_addends_as_counts -> q_common_partition: 1 of the machine's 8 distinct edges, static only. rewrite a quantity or relation in a commensurate form without changing what it says: printed mixed and whole operands are renamed as fraction counts, the renaming kept in the trace."),
            status(review_pending)).
action_maps(fraction, common_denominator_fraction_subtraction, transformed, re_express_equivalently,
            confidence(high),
            evidence("fraction/common_denominator_fraction_subtraction, q_transform_commensurate_1 -> q_transform_commensurate_2; q_transform_commensurate_2 -> q_measure_with_co_unit: 2 of the machine's 8 distinct edges, static only. rewrite a quantity or relation in a commensurate form without changing what it says."),
            status(review_pending)).
action_maps(fraction, common_unit_fraction_comparison, co_measure, align_to_common_unit,
            confidence(high),
            evidence("fraction/common_unit_fraction_comparison, q_observed_4 -> q_observed_5: 1 of the machine's 14 distinct edges, witnessed. bring both quantities into a shared unit, denominator, or decimal scale so they can be measured against each other."),
            status(review_pending)).
action_maps(fraction, common_unit_fraction_comparison, common_denominator, align_to_common_unit,
            confidence(high),
            evidence("fraction/common_unit_fraction_comparison, q_observed_1 -> q_observed_2: 1 of the machine's 14 distinct edges, witnessed. bring both quantities into a shared unit, denominator, or decimal scale so they can be measured against each other."),
            status(review_pending)).
action_maps(fraction, common_unit_fraction_comparison, compare_counts, compare_magnitudes,
            confidence(high),
            evidence("fraction/common_unit_fraction_comparison, q_observed_5 -> q_observed_6: 1 of the machine's 14 distinct edges, witnessed. decide the order relation between two quantities."),
            status(review_pending)).
action_maps(fraction, common_unit_fraction_comparison, emit, emit_result,
            confidence(high),
            evidence("fraction/common_unit_fraction_comparison, q_emit_order -> q_accept; q_observed_6 -> q_accept: 2 of the machine's 14 distinct edges, witnessed. release the result from the machine."),
            status(review_pending)).
action_maps(fraction, common_unit_fraction_comparison, init, initiate,
            confidence(high),
            evidence("fraction/common_unit_fraction_comparison, q_init -> q_common_numerator; q_init -> q_observed_1: 2 of the machine's 14 distinct edges, witnessed. enter the machine without yet doing mathematical work."),
            status(review_pending)).
action_maps(fraction, common_unit_fraction_comparison, inverse_denominator_relation, compare_magnitudes,
            confidence(high),
            evidence("fraction/common_unit_fraction_comparison, q_compare_same_numerator -> q_emit_order: 1 of the machine's 14 distinct edges, static only. orders the two by the inverse relation between their denominators, the numerators being shared"),
            status(review_pending)).
action_maps(fraction, common_unit_fraction_comparison, same_count_different_unit_sizes, read_operand_attribute,
            confidence(high),
            evidence("fraction/common_unit_fraction_comparison, q_measure_with_co_unit -> q_compare_same_numerator: 1 of the machine's 14 distinct edges, static only. reads that the two carry the same count of differently sized units, which is what makes the inverse denominator relation decisive"),
            status(review_pending)).
action_maps(fraction, common_unit_fraction_comparison, shared_numerator, read_operand_attribute,
            confidence(high),
            evidence("fraction/common_unit_fraction_comparison, q_common_numerator -> q_transform_commensurate_1: 1 of the machine's 14 distinct edges, static only. reads that the two fractions carry the same numerator, the property the whole comparison then rests on"),
            status(review_pending)).
action_maps(fraction, common_unit_fraction_comparison, transformed, re_express_equivalently,
            confidence(high),
            evidence("fraction/common_unit_fraction_comparison, q_observed_2 -> q_observed_3; q_observed_3 -> q_observed_4: 2 of the machine's 14 distinct edges, witnessed. rewrite a quantity or relation in a commensurate form without changing what it says."),
            status(review_pending)).
action_maps(fraction, common_unit_fraction_comparison, unchanged, retain_unchanged,
            confidence(high),
            evidence("fraction/common_unit_fraction_comparison, q_transform_commensurate_1 -> q_transform_commensurate_2; q_transform_commensurate_2 -> q_measure_with_co_unit: 2 of the machine's 14 distinct edges, static only. carries the fraction through the commensurate-transformation slot untouched, the numerators already being shared, so the transformation has nothing to do"),
            status(review_pending)).
action_maps(fraction, cross_multiplication_rule_from_pattern, apply_cross_multiplication_pattern, apply_stored_rule,
            confidence(high),
            evidence("fraction/cross_multiplication_rule_from_pattern, q_step_1 -> q_step_2: 1 of the machine's 8 distinct edges, static only. carry out a remembered formula, rule, or prescribed procedural step."),
            status(review_pending)).
action_maps(fraction, cross_multiplication_rule_from_pattern, compute_denominator_product, compute_product,
            confidence(high),
            evidence("fraction/cross_multiplication_rule_from_pattern, q_step_3 -> q_step_4: 1 of the machine's 8 distinct edges, static only. multiply the operands as numerals."),
            status(review_pending)).
action_maps(fraction, cross_multiplication_rule_from_pattern, compute_numerator_product, compute_product,
            confidence(high),
            evidence("fraction/cross_multiplication_rule_from_pattern, q_step_2 -> q_step_3: 1 of the machine's 8 distinct edges, static only. multiply the operands as numerals."),
            status(review_pending)).
action_maps(fraction, cross_multiplication_rule_from_pattern, identify_denominator_product_as_whole_rectangle_area, assign_roles,
            confidence(high),
            evidence("fraction/cross_multiplication_rule_from_pattern, q_step_6 -> q_step_7: 1 of the machine's 8 distinct edges, static only. binds the denominator product to the whole rectangle's area in the returned area model"),
            status(review_pending)).
action_maps(fraction, cross_multiplication_rule_from_pattern, identify_numerator_product_as_selected_area, assign_roles,
            confidence(high),
            evidence("fraction/cross_multiplication_rule_from_pattern, q_step_7 -> q_accept: 1 of the machine's 8 distinct edges, static only. binds the numerator product to the selected region of that rectangle"),
            status(review_pending)).
action_maps(fraction, cross_multiplication_rule_from_pattern, identify_rule_pattern, read_operand_attribute,
            confidence(medium),
            evidence("fraction/cross_multiplication_rule_from_pattern, q_start -> q_step_1: 1 of the machine's 8 distinct edges, static only. reads the pattern in the two fractions that the cross-multiplication rule matches on"),
            status(review_pending)).
action_maps(fraction, cross_multiplication_rule_from_pattern, justify_via_area_model_part_of_part, dispatch_to_kernel,
            confidence(high),
            evidence("fraction/cross_multiplication_rule_from_pattern, q_step_5 -> q_step_6: 1 of the machine's 8 distinct edges, static only. hands the justification to fraction/area_model_part_of_part, which is a registered machine in its own right"),
            status(review_pending)).
action_maps(fraction, cross_multiplication_rule_from_pattern, propose_result, name_result,
            confidence(medium),
            evidence("fraction/cross_multiplication_rule_from_pattern, q_step_4 -> q_step_5: 1 of the machine's 8 distinct edges, static only. offers the product as the answer, before the area-model justification the next three edges supply"),
            status(review_pending)).
action_maps(fraction, cross_multiplication_rule_without_ground, apply_cross_multiplication_pattern, apply_stored_rule,
            confidence(high),
            evidence("fraction/cross_multiplication_rule_without_ground, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, static only. carry out a remembered formula, rule, or prescribed procedural step."),
            status(review_pending)).
action_maps(fraction, cross_multiplication_rule_without_ground, compute_denominator_product, compute_product,
            confidence(high),
            evidence("fraction/cross_multiplication_rule_without_ground, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges, static only. multiply the operands as numerals."),
            status(review_pending)).
action_maps(fraction, cross_multiplication_rule_without_ground, compute_numerator_product, compute_product,
            confidence(high),
            evidence("fraction/cross_multiplication_rule_without_ground, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges, static only. multiply the operands as numerals."),
            status(review_pending)).
action_maps(fraction, cross_multiplication_rule_without_ground, produce_result_without_area_model_ground, name_result,
            confidence(medium),
            evidence("fraction/cross_multiplication_rule_without_ground, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, static only. offers the same product the grounded machine offers; what is missing is named at the next edge, and the outcome's own validity field records the answer as correct"),
            status(review_pending)).
action_maps(fraction, cross_multiplication_rule_without_ground, recall_rule_pattern, retrieve_known_fact,
            confidence(high),
            evidence("fraction/cross_multiplication_rule_without_ground, q_start -> q_step_1: 1 of the machine's 6 distinct edges, static only. recall a stored fact instead of reconstructing it."),
            status(review_pending)).
action_maps(fraction, cross_multiplication_rule_without_ground, skip_area_model_justification, omit_required_step,
            confidence(high),
            evidence("fraction/cross_multiplication_rule_without_ground, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, static only. the area-model justification never runs, which is the case formal/learner/deontic_scorekeeper.pl treats as commitment without entitlement"),
            status(review_pending)).
action_maps(fraction, gap_thinking_fraction_comparison, compare_absolute_gaps, compare_additive_gaps,
            confidence(high),
            evidence("fraction/gap_thinking_fraction_comparison, q_gap_thinking -> q_transitive_compare; q_observed_4 -> q_observed_5: 2 of the machine's 17 distinct edges, witnessed. compare the additive distance between the two terms of each quantity."),
            status(review_pending)).
action_maps(fraction, gap_thinking_fraction_comparison, emit, emit_result,
            confidence(high),
            evidence("fraction/gap_thinking_fraction_comparison, q_emit -> q_accept; q_observed_8 -> q_accept: 2 of the machine's 17 distinct edges, witnessed. release the result from the machine."),
            status(review_pending)).
action_maps(fraction, gap_thinking_fraction_comparison, init, initiate,
            confidence(high),
            evidence("fraction/gap_thinking_fraction_comparison, q_init -> q_select_benchmark; q_init -> q_observed_1: 2 of the machine's 17 distinct edges, witnessed. enter the machine without yet doing mathematical work."),
            status(review_pending)).
action_maps(fraction, gap_thinking_fraction_comparison, numerator_denominator_gap, substitute_additive_for_multiplicative,
            confidence(high),
            evidence("fraction/gap_thinking_fraction_comparison, q_benchmark_first -> q_benchmark_second; q_benchmark_second -> q_gap_thinking; q_observed_2 -> q_observed_3 (+1 more): 4 of the machine's 17 distinct edges, witnessed. fills the slot benchmark_fraction_comparison fills with judgment: the additive numerator-denominator distance stands in for a judgment against the benchmark"),
            status(review_pending)).
action_maps(fraction, gap_thinking_fraction_comparison, omitted_external_value_relation, omit_required_step,
            confidence(high),
            evidence("fraction/gap_thinking_fraction_comparison, q_transitive_compare -> q_residual_compare; q_observed_5 -> q_observed_6: 2 of the machine's 17 distinct edges, witnessed. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(fraction, gap_thinking_fraction_comparison, selected, establish_reference_frame,
            confidence(high),
            evidence("fraction/gap_thinking_fraction_comparison, q_select_benchmark -> q_benchmark_first; q_observed_1 -> q_observed_2: 2 of the machine's 17 distinct edges, witnessed. the benchmark has been selected: it becomes the reference point both later judgments are made against"),
            status(review_pending)).
action_maps(fraction, gap_thinking_fraction_comparison, unscaled_residuals, compare_residuals,
            confidence(medium),
            evidence("fraction/gap_thinking_fraction_comparison, q_residual_compare -> q_emit; q_observed_6 -> q_observed_7: 2 of the machine's 17 distinct edges, witnessed. compares the residuals without scaling them to their wholes, which is what leaves the comparison unsound"),
            status(review_pending)).
action_maps(fraction, gap_thinking_fraction_comparison, viability, record_viability,
            confidence(high),
            evidence("fraction/gap_thinking_fraction_comparison, q_observed_7 -> q_observed_8: 1 of the machine's 17 distinct edges, witnessed. record whether the strategy is contextually correct for this input."),
            status(review_pending)).
action_maps(fraction, improper_fraction_chain_loss, establish_referent_whole, unitize_referent,
            confidence(high),
            evidence("fraction/improper_fraction_chain_loss, q_start -> q_step_1: 1 of the machine's 6 distinct edges, witnessed. constitute the whole or unit that all later measurement refers to."),
            status(review_pending)).
action_maps(fraction, improper_fraction_chain_loss, iterate_unit_past_whole, iterate_unit,
            confidence(high),
            evidence("fraction/improper_fraction_chain_loss, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, witnessed. iterates the unit fraction beyond the whole; the referent chain is dropped at the next edge, not here"),
            status(review_pending)).
action_maps(fraction, improper_fraction_chain_loss, kernel_trace, receive_kernel_outcome,
            confidence(high),
            evidence("fraction/improper_fraction_chain_loss, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, witnessed. take the delegated automaton's outcome back as this machine's step."),
            status(review_pending)).
action_maps(fraction, improper_fraction_chain_loss, lose_original_referent_whole_chain, treat_relevant_as_irrelevant,
            confidence(high),
            evidence("fraction/improper_fraction_chain_loss, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges, witnessed. intermediate edge, not a closing record: the referent whole is dropped here, and what the strategy lost is recorded at the machine's last edge"),
            status(review_pending)).
action_maps(fraction, improper_fraction_chain_loss, rename_result_to_new_whole, misname_result,
            confidence(high),
            evidence("fraction/improper_fraction_chain_loss, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, witnessed. renames the iterated amount as a new whole, the original referent chain having been dropped"),
            status(review_pending)).
action_maps(fraction, improper_fraction_chain_loss, reset_completion_norm, rename_in_place_of_transforming,
            confidence(high),
            evidence("fraction/improper_fraction_chain_loss, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges, witnessed. renames what counts as a completed whole so that the amount iterated past the whole reads as one"),
            status(review_pending)).
action_maps(fraction, improper_fraction_iteration, establish_referent_whole, unitize_referent,
            confidence(high),
            evidence("fraction/improper_fraction_iteration, q_start -> q_step_1: 1 of the machine's 6 distinct edges, static only. constitute the whole or unit that all later measurement refers to."),
            status(review_pending)).
action_maps(fraction, improper_fraction_iteration, hold_completion_marker, verify_invariant,
            confidence(high),
            evidence("fraction/improper_fraction_iteration, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges, static only. holds the whole's completion marker against the iteration so the count past the whole stays answerable to it"),
            status(review_pending)).
action_maps(fraction, improper_fraction_iteration, iterate_unit_past_whole_keeping_referent, iterate_unit,
            confidence(high),
            evidence("fraction/improper_fraction_iteration, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges, static only. iterates the unit fraction beyond the whole while the original referent stays in force, which is exactly what fraction/improper_fraction_chain_loss drops"),
            status(review_pending)).
action_maps(fraction, improper_fraction_iteration, kernel_trace, receive_kernel_outcome,
            confidence(high),
            evidence("fraction/improper_fraction_iteration, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, static only. take the delegated automaton's outcome back as this machine's step."),
            status(review_pending)).
action_maps(fraction, improper_fraction_iteration, name_improper_fraction_as_number, name_result,
            confidence(high),
            evidence("fraction/improper_fraction_iteration, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, static only. say which quantity the answer is."),
            status(review_pending)).
action_maps(fraction, improper_fraction_iteration, recover_unit_fraction, disembed_part,
            confidence(high),
            evidence("fraction/improper_fraction_iteration, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, static only. takes the unit fraction back out of the whole while it stays inside the whole, which is what makes the next edge's iteration meaningful"),
            status(review_pending)).
action_maps(fraction, iterate_given_overshoot, establish_referent_whole, unitize_referent,
            confidence(high),
            evidence("fraction/iterate_given_overshoot, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. constitute the whole or unit that all later measurement refers to."),
            status(review_pending)).
action_maps(fraction, iterate_given_overshoot, fail_to_recognize_partition_iterate_inverse, omit_required_step,
            confidence(high),
            evidence("fraction/iterate_given_overshoot, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. the mutual inverse of partitioning and iterating is never taken up, so nothing recovers the whole"),
            status(review_pending)).
action_maps(fraction, iterate_given_overshoot, iterate_given_part_forward, iterate_unit,
            confidence(high),
            evidence("fraction/iterate_given_overshoot, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. repeat a unit to build or to measure a quantity."),
            status(review_pending)).
action_maps(fraction, iterate_given_overshoot, overshoot_without_recovering_whole, record_loss,
            confidence(high),
            evidence("fraction/iterate_given_overshoot, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(fraction, iterate_only_no_reverse, cannot_run_inverse_edge_to_recover_unknown, exhaust_resource,
            confidence(high),
            evidence("fraction/iterate_only_no_reverse, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. reaches for the inverse edge and finds none available. The ORR crisis step: a resource met at its limit, not a step skipped"),
            status(review_pending)).
action_maps(fraction, iterate_only_no_reverse, fail_to_solve, record_loss,
            confidence(high),
            evidence("fraction/iterate_only_no_reverse, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(fraction, iterate_only_no_reverse, iterate_forward_only_build_total_from_a_unit, iterate_unit,
            confidence(medium),
            evidence("fraction/iterate_only_no_reverse, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. iterates a unit up to the total and only in that direction"),
            status(review_pending)).
action_maps(fraction, iterate_only_no_reverse, partitioning_consumed_in_activity_no_disembedded_part, omit_required_step,
            confidence(high),
            evidence("fraction/iterate_only_no_reverse, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. the partitioning happens and leaves no disembedded part behind, so there is nothing for the inverse to act on"),
            status(review_pending)).
action_maps(fraction, iterate_only_no_reverse, read_equation, register_givens,
            confidence(high),
            evidence("fraction/iterate_only_no_reverse, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(fraction, measurement_division, co_measure_both_with_a_shared_fractional_unit, align_to_common_unit,
            confidence(high),
            evidence("fraction/measurement_division, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, witnessed. bring both quantities into a shared unit, denominator, or decimal scale so they can be measured against each other."),
            status(review_pending)).
action_maps(fraction, measurement_division, count_how_many_group_sizes_fit, measure_out_group_size,
            confidence(high),
            evidence("fraction/measurement_division, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, witnessed. remove a known group size repeatedly to find how many groups the total holds."),
            status(review_pending)).
action_maps(fraction, measurement_division, establish_dividend_and_divisor, register_givens,
            confidence(high),
            evidence("fraction/measurement_division, q_start -> q_step_1: 1 of the machine's 5 distinct edges, witnessed. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(fraction, measurement_division, name_leftover_as_a_fraction_of_the_group_size, name_result,
            confidence(high),
            evidence("fraction/measurement_division, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, witnessed. say which quantity the answer is."),
            status(review_pending)).
action_maps(fraction, measurement_division, name_quotient_and_remainder, name_result,
            confidence(high),
            evidence("fraction/measurement_division, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, witnessed. say which quantity the answer is."),
            status(review_pending)).
action_maps(fraction, number_line_count_marks_not_intervals, co_measure, align_to_common_unit,
            confidence(high),
            evidence("fraction/number_line_count_marks_not_intervals, q_measure_with_unit_fraction -> q_compare_positions: 1 of the machine's 8 distinct edges, witnessed. bring both quantities into a shared unit, denominator, or decimal scale so they can be measured against each other."),
            status(review_pending)).
action_maps(fraction, number_line_count_marks_not_intervals, compare, compare_magnitudes,
            confidence(high),
            evidence("fraction/number_line_count_marks_not_intervals, q_compare_positions -> q_emit: 1 of the machine's 8 distinct edges, witnessed. decide the order relation between two quantities."),
            status(review_pending)).
action_maps(fraction, number_line_count_marks_not_intervals, emit, emit_result,
            confidence(high),
            evidence("fraction/number_line_count_marks_not_intervals, q_emit -> q_accept: 1 of the machine's 8 distinct edges, witnessed. release the result from the machine."),
            status(review_pending)).
action_maps(fraction, number_line_count_marks_not_intervals, init, initiate,
            confidence(high),
            evidence("fraction/number_line_count_marks_not_intervals, q_init -> q_identify_unit: 1 of the machine's 8 distinct edges, witnessed. enter the machine without yet doing mathematical work."),
            status(review_pending)).
action_maps(fraction, number_line_count_marks_not_intervals, mislocated_endpoints, locate_position,
            confidence(medium),
            evidence("fraction/number_line_count_marks_not_intervals, q_locate_endpoint -> q_measure_with_unit_fraction: 1 of the machine's 8 distinct edges, witnessed. locates the endpoints from the inflated mark count, so each falls one subunit off"),
            status(review_pending)).
action_maps(fraction, number_line_count_marks_not_intervals, overcount, substitute_count_for_measure,
            confidence(high),
            evidence("fraction/number_line_count_marks_not_intervals, q_count_marks_not_intervals -> q_locate_endpoint: 1 of the machine's 8 distinct edges, witnessed. fills the slot number_line_fraction_comparison fills with iterations: the partition marks are counted where the unit interval was to be iterated"),
            status(review_pending)).
action_maps(fraction, number_line_count_marks_not_intervals, partitions, partition_into_equal_parts,
            confidence(high),
            evidence("fraction/number_line_count_marks_not_intervals, q_partition_interval -> q_count_marks_not_intervals: 1 of the machine's 8 distinct edges, witnessed. cut the referent into parts the strategy treats as equal."),
            status(review_pending)).
action_maps(fraction, number_line_count_marks_not_intervals, unit_interval, unitize_referent,
            confidence(high),
            evidence("fraction/number_line_count_marks_not_intervals, q_identify_unit -> q_partition_interval: 1 of the machine's 8 distinct edges, witnessed. constitutes the unit interval as the whole the partition and the iteration both answer to"),
            status(review_pending)).
action_maps(fraction, number_line_fraction_comparison, co_measure, align_to_common_unit,
            confidence(high),
            evidence("fraction/number_line_fraction_comparison, q_measure_with_unit_fraction -> q_compare_positions: 1 of the machine's 8 distinct edges, witnessed. bring both quantities into a shared unit, denominator, or decimal scale so they can be measured against each other."),
            status(review_pending)).
action_maps(fraction, number_line_fraction_comparison, compare, compare_magnitudes,
            confidence(high),
            evidence("fraction/number_line_fraction_comparison, q_compare_positions -> q_emit: 1 of the machine's 8 distinct edges, witnessed. decide the order relation between two quantities."),
            status(review_pending)).
action_maps(fraction, number_line_fraction_comparison, emit, emit_result,
            confidence(high),
            evidence("fraction/number_line_fraction_comparison, q_emit -> q_accept: 1 of the machine's 8 distinct edges, witnessed. release the result from the machine."),
            status(review_pending)).
action_maps(fraction, number_line_fraction_comparison, endpoints, locate_position,
            confidence(high),
            evidence("fraction/number_line_fraction_comparison, q_locate_endpoint -> q_measure_with_unit_fraction: 1 of the machine's 8 distinct edges, witnessed. locate a value's position in the frame already established."),
            status(review_pending)).
action_maps(fraction, number_line_fraction_comparison, init, initiate,
            confidence(high),
            evidence("fraction/number_line_fraction_comparison, q_init -> q_identify_unit: 1 of the machine's 8 distinct edges, witnessed. enter the machine without yet doing mathematical work."),
            status(review_pending)).
action_maps(fraction, number_line_fraction_comparison, iterations, iterate_unit,
            confidence(high),
            evidence("fraction/number_line_fraction_comparison, q_mark_off_lengths -> q_locate_endpoint: 1 of the machine's 8 distinct edges, witnessed. repeat a unit to build or to measure a quantity."),
            status(review_pending)).
action_maps(fraction, number_line_fraction_comparison, partitions, partition_into_equal_parts,
            confidence(high),
            evidence("fraction/number_line_fraction_comparison, q_partition_interval -> q_mark_off_lengths: 1 of the machine's 8 distinct edges, witnessed. cut the referent into parts the strategy treats as equal."),
            status(review_pending)).
action_maps(fraction, number_line_fraction_comparison, unit_interval, unitize_referent,
            confidence(high),
            evidence("fraction/number_line_fraction_comparison, q_identify_unit -> q_partition_interval: 1 of the machine's 8 distinct edges, witnessed. constitutes the unit interval as the whole the partition and the iteration both answer to"),
            status(review_pending)).
action_maps(fraction, recursive_partition, disembed_unit_fraction, disembed_part,
            confidence(high),
            evidence("fraction/recursive_partition, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, static only. take a part out of the whole while the part stays inside the whole."),
            status(review_pending)).
action_maps(fraction, recursive_partition, name_part_of_part_relative_to_whole, name_result,
            confidence(high),
            evidence("fraction/recursive_partition, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges, static only. say which quantity the answer is."),
            status(review_pending)).
action_maps(fraction, recursive_partition, partition_that_part_again, partition_into_equal_parts,
            confidence(high),
            evidence("fraction/recursive_partition, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges, static only. cut the referent into parts the strategy treats as equal."),
            status(review_pending)).
action_maps(fraction, recursive_partition, partition_whole_into_equal_units, partition_into_equal_parts,
            confidence(high),
            evidence("fraction/recursive_partition, q_start -> q_step_1: 1 of the machine's 6 distinct edges, static only. cut the referent into parts the strategy treats as equal."),
            status(review_pending)).
action_maps(fraction, recursive_partition, recognize_composite_base_as_product, verify_invariant,
            confidence(high),
            evidence("fraction/recursive_partition, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, static only. certifies that the composite base is the product of the two partitions, which is the relation the recursive partition preserves"),
            status(review_pending)).
action_maps(fraction, recursive_partition, recursive_partition_trace, receive_kernel_outcome,
            confidence(high),
            evidence("fraction/recursive_partition, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, static only. take the delegated automaton's outcome back as this machine's step."),
            status(review_pending)).
action_maps(fraction, reversible_measurement_division, establish_dividend_and_divisor, register_givens,
            confidence(high),
            evidence("fraction/reversible_measurement_division, q_start -> q_step_1: 1 of the machine's 5 distinct edges, witnessed. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(fraction, reversible_measurement_division, form_one_group_from_the_generator_units, replicate_equal_groups,
            confidence(medium),
            evidence("fraction/reversible_measurement_division, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, witnessed. builds one group out of the recovered generator units so the total can then be measured in groups"),
            status(review_pending)).
action_maps(fraction, reversible_measurement_division, measure_the_total_in_generator_scale, measure_quantity,
            confidence(high),
            evidence("fraction/reversible_measurement_division, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, witnessed. determine a quantity's measure with the unit already established."),
            status(review_pending)).
action_maps(fraction, reversible_measurement_division, read_quotient_as_total_ticks_over_group_ticks, name_result,
            confidence(high),
            evidence("fraction/reversible_measurement_division, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, witnessed. say which quantity the answer is."),
            status(review_pending)).
action_maps(fraction, reversible_measurement_division, recover_the_unit_generator_of_the_divisor, select_unit_scale,
            confidence(medium),
            evidence("fraction/reversible_measurement_division, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, witnessed. recovers the unit that generates the divisor so both total and group can be measured in it"),
            status(review_pending)).
action_maps(fraction, set_model_fraction_comparison, co_measure, align_to_common_unit,
            confidence(high),
            evidence("fraction/set_model_fraction_comparison, q_compare_relative_size -> q_emit: 1 of the machine's 8 distinct edges, witnessed. bring both quantities into a shared unit, denominator, or decimal scale so they can be measured against each other."),
            status(review_pending)).
action_maps(fraction, set_model_fraction_comparison, collections_as_single_wholes, unitize_referent,
            confidence(high),
            evidence("fraction/set_model_fraction_comparison, q_unitize_set -> q_verify_same_whole: 1 of the machine's 8 distinct edges, witnessed. constitutes each collection as one whole, the set-model counterpart of unitizing a region"),
            status(review_pending)).
action_maps(fraction, set_model_fraction_comparison, commensurable_collections_certified, verify_invariant,
            confidence(high),
            evidence("fraction/set_model_fraction_comparison, q_verify_same_whole -> q_partition_set: 1 of the machine's 8 distinct edges, witnessed. check that the property the strategy must keep still holds."),
            status(review_pending)).
action_maps(fraction, set_model_fraction_comparison, denominator_counts, count_units,
            confidence(high),
            evidence("fraction/set_model_fraction_comparison, q_count_equal_sets -> q_disembed_subset: 1 of the machine's 8 distinct edges, witnessed. count how many units the iteration or the partition produced."),
            status(review_pending)).
action_maps(fraction, set_model_fraction_comparison, emit, emit_result,
            confidence(high),
            evidence("fraction/set_model_fraction_comparison, q_emit -> q_accept: 1 of the machine's 8 distinct edges, witnessed. release the result from the machine."),
            status(review_pending)).
action_maps(fraction, set_model_fraction_comparison, equal_shares, partition_into_equal_parts,
            confidence(high),
            evidence("fraction/set_model_fraction_comparison, q_partition_set -> q_count_equal_sets: 1 of the machine's 8 distinct edges, witnessed. cut the referent into parts the strategy treats as equal."),
            status(review_pending)).
action_maps(fraction, set_model_fraction_comparison, init, initiate,
            confidence(high),
            evidence("fraction/set_model_fraction_comparison, q_init -> q_unitize_set: 1 of the machine's 8 distinct edges, witnessed. enter the machine without yet doing mathematical work."),
            status(review_pending)).
action_maps(fraction, set_model_fraction_comparison, selected_shares, disembed_part,
            confidence(high),
            evidence("fraction/set_model_fraction_comparison, q_disembed_subset -> q_compare_relative_size: 1 of the machine's 8 distinct edges, witnessed. take a part out of the whole while the part stays inside the whole."),
            status(review_pending)).
action_maps(fraction, set_model_subset_size_focus, collections_as_single_wholes, unitize_referent,
            confidence(high),
            evidence("fraction/set_model_subset_size_focus, q_unitize_set -> q_verify_same_whole: 1 of the machine's 9 distinct edges, witnessed. constitutes each collection as one whole, the set-model counterpart of unitizing a region"),
            status(review_pending)).
action_maps(fraction, set_model_subset_size_focus, commensurable_collections_not_checked, accept_without_check,
            confidence(high),
            evidence("fraction/set_model_subset_size_focus, q_verify_same_whole -> q_partition_set: 1 of the machine's 9 distinct edges, witnessed. accept a structure without the verification it needs."),
            status(review_pending)).
action_maps(fraction, set_model_subset_size_focus, compare_raw_subset_sizes, compare_magnitudes,
            confidence(high),
            evidence("fraction/set_model_subset_size_focus, q_compare_relative_size -> q_emit: 1 of the machine's 9 distinct edges, witnessed. decide the order relation between two quantities."),
            status(review_pending)).
action_maps(fraction, set_model_subset_size_focus, confuse_counters_with_share_name, conflate_roles,
            confidence(high),
            evidence("fraction/set_model_subset_size_focus, q_count_equal_sets -> q_disembed_subset: 1 of the machine's 9 distinct edges, witnessed. collapse two structurally distinct roles into one."),
            status(review_pending)).
action_maps(fraction, set_model_subset_size_focus, emit, emit_result,
            confidence(high),
            evidence("fraction/set_model_subset_size_focus, q_emit -> q_accept: 1 of the machine's 9 distinct edges, witnessed. release the result from the machine."),
            status(review_pending)).
action_maps(fraction, set_model_subset_size_focus, equal_share_structure_ignored, omit_required_step,
            confidence(high),
            evidence("fraction/set_model_subset_size_focus, q_partition_set -> q_count_equal_sets: 1 of the machine's 9 distinct edges, witnessed. leaves q_partition_set without establishing the equal-share structure the fractional share would be read from"),
            status(review_pending)).
action_maps(fraction, set_model_subset_size_focus, focus_on_subset_counts, substitute_count_for_measure,
            confidence(high),
            evidence("fraction/set_model_subset_size_focus, q_disembed_subset -> q_subset_size_focus: 1 of the machine's 9 distinct edges, witnessed. attends to the subset's raw size in place of the fractional share it names"),
            status(review_pending)).
action_maps(fraction, set_model_subset_size_focus, init, initiate,
            confidence(high),
            evidence("fraction/set_model_subset_size_focus, q_init -> q_unitize_set: 1 of the machine's 9 distinct edges, witnessed. enter the machine without yet doing mathematical work."),
            status(review_pending)).
action_maps(fraction, set_model_subset_size_focus, subset_count_replaces_fractional_share, substitute_count_for_measure,
            confidence(high),
            evidence("fraction/set_model_subset_size_focus, q_subset_size_focus -> q_compare_relative_size: 1 of the machine's 9 distinct edges, witnessed. puts the subset count in place of the fractional share as what the comparison ranks"),
            status(review_pending)).
action_maps(fraction, solve_for_unit, iterate_recovered_part_by_denominator, iterate_unit,
            confidence(high),
            evidence("fraction/solve_for_unit, q_step_3 -> q_step_4: 1 of the machine's 7 distinct edges, static only. repeat a unit to build or to measure a quantity."),
            status(review_pending)).
action_maps(fraction, solve_for_unit, partition_total_into_numerator_parts, partition_into_equal_parts,
            confidence(high),
            evidence("fraction/solve_for_unit, q_step_2 -> q_step_3: 1 of the machine's 7 distinct edges, static only. cut the referent into parts the strategy treats as equal."),
            status(review_pending)).
action_maps(fraction, solve_for_unit, read_equation, register_givens,
            confidence(high),
            evidence("fraction/solve_for_unit, q_start -> q_step_1: 1 of the machine's 7 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(fraction, solve_for_unit, recognize_partition_undoes_iteration_on_the_unknown, verify_invariant,
            confidence(high),
            evidence("fraction/solve_for_unit, q_step_5 -> q_step_6: 1 of the machine's 7 distinct edges, static only. check that the property the strategy must keep still holds."),
            status(review_pending)).
action_maps(fraction, solve_for_unit, recover_unknown, isolate_unknown,
            confidence(high),
            evidence("fraction/solve_for_unit, q_step_4 -> q_step_5: 1 of the machine's 7 distinct edges, static only. separate the unknown quantity from the known ones so that it stands alone."),
            status(review_pending)).
action_maps(fraction, solve_for_unit, solve_trace, receive_kernel_outcome,
            confidence(high),
            evidence("fraction/solve_for_unit, q_step_6 -> q_accept: 1 of the machine's 7 distinct edges, static only. take the delegated automaton's outcome back as this machine's step."),
            status(review_pending)).
action_maps(fraction, solve_for_unit, treat_unknown_as_iterable_partitionable_quantity, assign_roles,
            confidence(high),
            evidence("fraction/solve_for_unit, q_step_1 -> q_step_2: 1 of the machine's 7 distinct edges, static only. binds the unknown to a role that can be both partitioned and iterated, which is what makes it solvable by the inverse"),
            status(review_pending)).
action_maps(fraction, splitting, disembed_unit_fraction, disembed_part,
            confidence(high),
            evidence("fraction/splitting, q_step_1 -> q_step_2: 1 of the machine's 8 distinct edges, static only. take a part out of the whole while the part stays inside the whole."),
            status(review_pending)).
action_maps(fraction, splitting, iterate_trace, receive_kernel_outcome,
            confidence(high),
            evidence("fraction/splitting, q_step_7 -> q_accept: 1 of the machine's 8 distinct edges, static only. take the delegated automaton's outcome back as this machine's step."),
            status(review_pending)).
action_maps(fraction, splitting, iterate_unit_fraction_back_to_whole, iterate_unit,
            confidence(high),
            evidence("fraction/splitting, q_step_2 -> q_step_3: 1 of the machine's 8 distinct edges, static only. repeat a unit to build or to measure a quantity."),
            status(review_pending)).
action_maps(fraction, splitting, open_improper_fraction_domain, attach_units_coordination,
            confidence(medium),
            evidence("fraction/splitting, q_step_5 -> q_step_6: 1 of the machine's 8 distinct edges, static only. attaches to the result what the established inverse now licenses: counts past the whole. The canonical action names attaching a coordination level, and the level here is a domain rather than a units level"),
            status(review_pending)).
action_maps(fraction, splitting, partition_trace, receive_kernel_outcome,
            confidence(high),
            evidence("fraction/splitting, q_step_6 -> q_step_7: 1 of the machine's 8 distinct edges, static only. take the delegated automaton's outcome back as this machine's step."),
            status(review_pending)).
action_maps(fraction, splitting, partition_whole_into_equal_units, partition_into_equal_parts,
            confidence(high),
            evidence("fraction/splitting, q_start -> q_step_1: 1 of the machine's 8 distinct edges, static only. cut the referent into parts the strategy treats as equal."),
            status(review_pending)).
action_maps(fraction, splitting, recognize_partition_iterate_as_mutual_inverse, verify_invariant,
            confidence(high),
            evidence("fraction/splitting, q_step_3 -> q_step_4: 1 of the machine's 8 distinct edges, static only. certifies partitioning and iterating as mutual inverses, which is the splitting scheme's whole content"),
            status(review_pending)).
action_maps(fraction, splitting, recover_whole, recompose_total,
            confidence(high),
            evidence("fraction/splitting, q_step_4 -> q_step_5: 1 of the machine's 8 distinct edges, static only. rebuilds the whole from the iterated unit fractions"),
            status(review_pending)).
action_maps(fraction, unit_fraction_iteration, coordinate_iteration_with_completion_marker, verify_invariant,
            confidence(medium),
            evidence("fraction/unit_fraction_iteration, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, witnessed. checks the iteration against the whole's completion marker so that the count stops at the whole"),
            status(review_pending)).
action_maps(fraction, unit_fraction_iteration, establish_referent_whole, unitize_referent,
            confidence(high),
            evidence("fraction/unit_fraction_iteration, q_start -> q_step_1: 1 of the machine's 5 distinct edges, witnessed. constitute the whole or unit that all later measurement refers to."),
            status(review_pending)).
action_maps(fraction, unit_fraction_iteration, iterate_unit_fraction, iterate_unit,
            confidence(high),
            evidence("fraction/unit_fraction_iteration, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, witnessed. repeat a unit to build or to measure a quantity."),
            status(review_pending)).
action_maps(fraction, unit_fraction_iteration, kernel_trace, receive_kernel_outcome,
            confidence(high),
            evidence("fraction/unit_fraction_iteration, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, witnessed. take the delegated automaton's outcome back as this machine's step."),
            status(review_pending)).
action_maps(fraction, unit_fraction_iteration, recover_unit_fraction, disembed_part,
            confidence(high),
            evidence("fraction/unit_fraction_iteration, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, witnessed. takes the unit fraction back out of the whole while it stays inside the whole, which is what makes the next edge's iteration meaningful"),
            status(review_pending)).
action_maps(fraction, unit_fraction_partition, establish_referent_whole, unitize_referent,
            confidence(high),
            evidence("fraction/unit_fraction_partition, q_start -> q_step_1: 1 of the machine's 5 distinct edges, witnessed. constitute the whole or unit that all later measurement refers to."),
            status(review_pending)).
action_maps(fraction, unit_fraction_partition, kernel_trace, receive_kernel_outcome,
            confidence(high),
            evidence("fraction/unit_fraction_partition, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, witnessed. take the delegated automaton's outcome back as this machine's step."),
            status(review_pending)).
action_maps(fraction, unit_fraction_partition, partition_whole_into_equal_units, partition_into_equal_parts,
            confidence(high),
            evidence("fraction/unit_fraction_partition, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, witnessed. cut the referent into parts the strategy treats as equal."),
            status(review_pending)).
action_maps(fraction, unit_fraction_partition, preserve_inside_and_iterable_status, verify_invariant,
            confidence(high),
            evidence("fraction/unit_fraction_partition, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, witnessed. certifies that the selected part is still inside the whole and still iterable, the two conditions the unit fraction has to meet"),
            status(review_pending)).
action_maps(fraction, unit_fraction_partition, select_one_partition_as_unit_fraction, disembed_part,
            confidence(high),
            evidence("fraction/unit_fraction_partition, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, witnessed. take a part out of the whole while the part stays inside the whole."),
            status(review_pending)).
action_maps(fraction, whole_number_grab, establish_referent_whole, unitize_referent,
            confidence(high),
            evidence("fraction/whole_number_grab, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. constitute the whole or unit that all later measurement refers to."),
            status(review_pending)).
action_maps(fraction, whole_number_grab, ignore_unit_fraction_denominator, treat_relevant_as_irrelevant,
            confidence(high),
            evidence("fraction/whole_number_grab, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. treat a relation the result depends on as though it did not bear on the result."),
            status(review_pending)).
action_maps(fraction, whole_number_grab, lose_referent_unit, record_loss,
            confidence(high),
            evidence("fraction/whole_number_grab, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(fraction, whole_number_grab, name_count_as_whole_number, misname_result,
            confidence(high),
            evidence("fraction/whole_number_grab, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. name a value that answers a different question than the one asked."),
            status(review_pending)).
action_maps(fraction, whole_number_grab, notice_visible_iteration_count, read_operand_attribute,
            confidence(high),
            evidence("fraction/whole_number_grab, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(geometry, angle_additive_composition, establish_shared_vertex, establish_reference_frame,
            confidence(high),
            evidence("geometry/angle_additive_composition, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. set up the frame against which locations or magnitudes will be read: axes, zero as origin, a vertex and initial ray, a value or frequency scale."),
            status(review_pending)).
action_maps(geometry, angle_additive_composition, preserve_adjacent_turns, verify_invariant,
            confidence(high),
            evidence("geometry/angle_additive_composition, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. certifies the two turns as adjacent, which is the condition under which their measures add"),
            status(review_pending)).
action_maps(geometry, angle_additive_composition, sum_part_measures, accumulate_total,
            confidence(high),
            evidence("geometry/angle_additive_composition, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. add the counted or measured pieces into a running total."),
            status(review_pending)).
action_maps(geometry, angle_additive_composition, verify_whole_angle, verify_invariant,
            confidence(high),
            evidence("geometry/angle_additive_composition, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. check that the property the strategy must keep still holds."),
            status(review_pending)).
action_maps(geometry, angle_as_ray_length, misread_visual_extent_as_angle_magnitude, substitute_appearance_for_measure,
            confidence(high),
            evidence("geometry/angle_as_ray_length, q_step_2 -> q_accept: 1 of the machine's 3 distinct edges, static only. puts the ray's drawn length in place of the turn the angle measures"),
            status(review_pending)).
action_maps(geometry, angle_as_ray_length, preserve_turn, retain_what_must_survive,
            confidence(high),
            evidence("geometry/angle_as_ray_length, q_start -> q_step_1: 1 of the machine's 3 distinct edges, static only. holds the angle's turn fixed while the next edge stretches the ray. The turn surviving unchanged is the whole reason the machine is a deformation: nothing about the angle changed, and the closing edge reads the changed extent as a changed magnitude"),
            status(review_pending)).
action_maps(geometry, angle_as_ray_length, stretch_ray_length, scale_multiplicatively,
            confidence(medium),
            evidence("geometry/angle_as_ray_length, q_step_1 -> q_step_2: 1 of the machine's 3 distinct edges, static only. lengthens the ray while the turn is held; the substitution of extent for turn is recorded at the next edge, not here"),
            status(review_pending)).
action_maps(geometry, angle_turn_measurement, establish_fixed_vertex, establish_reference_frame,
            confidence(high),
            evidence("geometry/angle_turn_measurement, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. set up the frame against which locations or magnitudes will be read: axes, zero as origin, a vertex and initial ray, a value or frequency scale."),
            status(review_pending)).
action_maps(geometry, angle_turn_measurement, establish_initial_ray, establish_reference_frame,
            confidence(high),
            evidence("geometry/angle_turn_measurement, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. set up the frame against which locations or magnitudes will be read: axes, zero as origin, a vertex and initial ray, a value or frequency scale."),
            status(review_pending)).
action_maps(geometry, angle_turn_measurement, iterate_degree_turn, iterate_unit,
            confidence(high),
            evidence("geometry/angle_turn_measurement, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. repeat a unit to build or to measure a quantity."),
            status(review_pending)).
action_maps(geometry, angle_turn_measurement, locate_terminal_ray, locate_position,
            confidence(high),
            evidence("geometry/angle_turn_measurement, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. locate a value's position in the frame already established."),
            status(review_pending)).
action_maps(geometry, angle_turn_measurement, read_angle_measure, name_result,
            confidence(high),
            evidence("geometry/angle_turn_measurement, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. say which quantity the answer is."),
            status(review_pending)).
action_maps(geometry, area_as_perimeter_count, establish_rectangle, register_givens,
            confidence(high),
            evidence("geometry/area_as_perimeter_count, q_start -> q_step_1: 1 of the machine's 4 distinct edges, witnessed. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(geometry, area_as_perimeter_count, ignore_interior_coverage, treat_relevant_as_irrelevant,
            confidence(high),
            evidence("geometry/area_as_perimeter_count, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, witnessed. treat a relation the result depends on as though it did not bear on the result."),
            status(review_pending)).
action_maps(geometry, area_as_perimeter_count, substitute_boundary_count_for_area, substitute_appearance_for_measure,
            confidence(high),
            evidence("geometry/area_as_perimeter_count, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, witnessed. puts the boundary's length in place of the interior's coverage"),
            status(review_pending)).
action_maps(geometry, area_as_perimeter_count, traverse_boundary_instead, traverse_boundary,
            confidence(high),
            evidence("geometry/area_as_perimeter_count, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, witnessed. walks the boundary where interior coverage was what the area asked for"),
            status(review_pending)).
action_maps(geometry, area_preserving_polygon_decomposition, decompose_into_nonoverlapping_pieces, decompose_region,
            confidence(high),
            evidence("geometry/area_preserving_polygon_decomposition, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. cut a figure into non-overlapping pieces, or unfold a solid into its net."),
            status(review_pending)).
action_maps(geometry, area_preserving_polygon_decomposition, establish_polygon, register_givens,
            confidence(high),
            evidence("geometry/area_preserving_polygon_decomposition, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(geometry, area_preserving_polygon_decomposition, measure_piece_areas, measure_quantity,
            confidence(high),
            evidence("geometry/area_preserving_polygon_decomposition, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. determine a quantity's measure with the unit already established."),
            status(review_pending)).
action_maps(geometry, area_preserving_polygon_decomposition, preserve_whole_area, record_conservation,
            confidence(high),
            evidence("geometry/area_preserving_polygon_decomposition, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. record that the strategy kept the relation it was obliged to keep."),
            status(review_pending)).
action_maps(geometry, area_preserving_polygon_decomposition, sum_piece_areas, accumulate_total,
            confidence(high),
            evidence("geometry/area_preserving_polygon_decomposition, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. add the counted or measured pieces into a running total."),
            status(review_pending)).
action_maps(geometry, area_unit_covering, count_covered_cells, count_units,
            confidence(high),
            evidence("geometry/area_unit_covering, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. count how many units the iteration or the partition produced."),
            status(review_pending)).
action_maps(geometry, area_unit_covering, establish_unit_square, unitize_referent,
            confidence(high),
            evidence("geometry/area_unit_covering, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. constitute the whole or unit that all later measurement refers to."),
            status(review_pending)).
action_maps(geometry, area_unit_covering, place_equal_unit_squares, iterate_unit,
            confidence(high),
            evidence("geometry/area_unit_covering, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. lays the unit square over the region repeatedly, the covering form of iterating a unit"),
            status(review_pending)).
action_maps(geometry, area_unit_covering, report_area_in_square_units, name_result,
            confidence(high),
            evidence("geometry/area_unit_covering, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. say which quantity the answer is."),
            status(review_pending)).
action_maps(geometry, area_unit_covering, verify_distinct_coverage, verify_invariant,
            confidence(high),
            evidence("geometry/area_unit_covering, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. check that the property the strategy must keep still holds."),
            status(review_pending)).
action_maps(geometry, area_unit_scale_selection, classify_area_referent_extent, read_operand_attribute,
            confidence(high),
            evidence("geometry/area_unit_scale_selection, q_start -> q_step_1: 1 of the machine's 3 distinct edges, static only. reads how large the region to be measured is, which is what lets a matching square unit be chosen"),
            status(review_pending)).
action_maps(geometry, area_unit_scale_selection, compare_candidate_square_unit_scales, compare_magnitudes,
            confidence(medium),
            evidence("geometry/area_unit_scale_selection, q_step_1 -> q_step_2: 1 of the machine's 3 distinct edges, static only. compares the candidate square units against the region's extent so that one can be chosen"),
            status(review_pending)).
action_maps(geometry, area_unit_scale_selection, select_matching_square_unit, select_unit_scale,
            confidence(high),
            evidence("geometry/area_unit_scale_selection, q_step_2 -> q_accept: 1 of the machine's 3 distinct edges, static only. choose which unit, base, or scale to work in from among the available ones."),
            status(review_pending)).
action_maps(geometry, axis_aligned_coordinate_distance, hold_other_coordinate_fixed, retain_unchanged,
            confidence(high),
            evidence("geometry/axis_aligned_coordinate_distance, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. holds one coordinate while the other varies, which is what makes the difference a length along one axis"),
            status(review_pending)).
action_maps(geometry, axis_aligned_coordinate_distance, plot_endpoint, locate_position,
            confidence(high),
            evidence("geometry/axis_aligned_coordinate_distance, q_start -> q_step_1; q_step_1 -> q_step_2: 2 of the machine's 5 distinct edges, static only. locate a value's position in the frame already established."),
            status(review_pending)).
action_maps(geometry, axis_aligned_coordinate_distance, subtract_varying_coordinates, remove_quantity,
            confidence(high),
            evidence("geometry/axis_aligned_coordinate_distance, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. take one quantity away from another."),
            status(review_pending)).
action_maps(geometry, axis_aligned_coordinate_distance, take_absolute_coordinate_change, apply_stored_rule,
            confidence(medium),
            evidence("geometry/axis_aligned_coordinate_distance, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. takes the coordinate difference's absolute value so the result is a length, filling the slot directed_difference_as_coordinate_distance leaves empty"),
            status(review_pending)).
action_maps(geometry, choose_first_area_unit_without_scale, ignore_area_referent_extent, treat_relevant_as_irrelevant,
            confidence(high),
            evidence("geometry/choose_first_area_unit_without_scale, q_start -> q_step_1: 1 of the machine's 3 distinct edges, static only. treat a relation the result depends on as though it did not bear on the result."),
            status(review_pending)).
action_maps(geometry, choose_first_area_unit_without_scale, omit_unit_scale_comparison, omit_required_step,
            confidence(high),
            evidence("geometry/choose_first_area_unit_without_scale, q_step_2 -> q_accept: 1 of the machine's 3 distinct edges, static only. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(geometry, choose_first_area_unit_without_scale, select_first_familiar_unit, select_unit_scale,
            confidence(high),
            evidence("geometry/choose_first_area_unit_without_scale, q_step_1 -> q_step_2: 1 of the machine's 3 distinct edges, static only. takes the first familiar unit, the region's extent having been set aside at the previous edge"),
            status(review_pending)).
action_maps(geometry, compare_solid_volume_by_cube_count, compare_cubic_unit_counts, compare_magnitudes,
            confidence(high),
            evidence("geometry/compare_solid_volume_by_cube_count, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. decide the order relation between two quantities."),
            status(review_pending)).
action_maps(geometry, compare_solid_volume_by_cube_count, count_cubes_in_solid, count_units,
            confidence(high),
            evidence("geometry/compare_solid_volume_by_cube_count, q_step_1 -> q_step_2; q_step_2 -> q_step_3: 2 of the machine's 5 distinct edges, static only. count how many units the iteration or the partition produced."),
            status(review_pending)).
action_maps(geometry, compare_solid_volume_by_cube_count, establish_unit_cube_as_volume_unit, unitize_referent,
            confidence(high),
            evidence("geometry/compare_solid_volume_by_cube_count, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. constitute the whole or unit that all later measurement refers to."),
            status(review_pending)).
action_maps(geometry, compare_solid_volume_by_cube_count, ignore_arrangement_extent, set_aside_irrelevant_attribute,
            confidence(high),
            evidence("geometry/compare_solid_volume_by_cube_count, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. sets the cubes' arrangement aside, which the cube count does not depend on"),
            status(review_pending)).
action_maps(geometry, compare_solid_volume_by_visible_extent, compare_bounding_extents, compare_magnitudes,
            confidence(high),
            evidence("geometry/compare_solid_volume_by_visible_extent, q_step_2 -> q_accept: 1 of the machine's 3 distinct edges, static only. decide the order relation between two quantities."),
            status(review_pending)).
action_maps(geometry, compare_solid_volume_by_visible_extent, ignore_unit_cube_counts, treat_relevant_as_irrelevant,
            confidence(high),
            evidence("geometry/compare_solid_volume_by_visible_extent, q_step_1 -> q_step_2: 1 of the machine's 3 distinct edges, static only. treat a relation the result depends on as though it did not bear on the result."),
            status(review_pending)).
action_maps(geometry, compare_solid_volume_by_visible_extent, inspect_visible_extent, read_operand_attribute,
            confidence(high),
            evidence("geometry/compare_solid_volume_by_visible_extent, q_start -> q_step_1: 1 of the machine's 3 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(geometry, composite_prism_volume_sum, calculate_component_volumes, measure_quantity,
            confidence(high),
            evidence("geometry/composite_prism_volume_sum, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. determine a quantity's measure with the unit already established."),
            status(review_pending)).
action_maps(geometry, composite_prism_volume_sum, certify_disjoint_prism_decomposition, verify_invariant,
            confidence(high),
            evidence("geometry/composite_prism_volume_sum, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. check that the property the strategy must keep still holds."),
            status(review_pending)).
action_maps(geometry, composite_prism_volume_sum, preserve_composite_volume, record_conservation,
            confidence(high),
            evidence("geometry/composite_prism_volume_sum, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. record that the strategy kept the relation it was obliged to keep."),
            status(review_pending)).
action_maps(geometry, composite_prism_volume_sum, sum_component_volumes, accumulate_total,
            confidence(high),
            evidence("geometry/composite_prism_volume_sum, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. add the counted or measured pieces into a running total."),
            status(review_pending)).
action_maps(geometry, count_overlapping_area_tiles, count_tile_placements, count_units,
            confidence(high),
            evidence("geometry/count_overlapping_area_tiles, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. counts placements rather than covered cells, the overlap check having been omitted at the previous edge"),
            status(review_pending)).
action_maps(geometry, count_overlapping_area_tiles, double_count_covered_cells, double_count,
            confidence(high),
            evidence("geometry/count_overlapping_area_tiles, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. count the same unit or region more than once."),
            status(review_pending)).
action_maps(geometry, count_overlapping_area_tiles, omit_overlap_check, omit_required_step,
            confidence(high),
            evidence("geometry/count_overlapping_area_tiles, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(geometry, count_overlapping_area_tiles, place_unit_squares, iterate_unit,
            confidence(high),
            evidence("geometry/count_overlapping_area_tiles, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. lays unit squares over the region; the overlap check is omitted at the next edge"),
            status(review_pending)).
action_maps(geometry, decomposition_with_gap_or_overlap, accept_unchecked_pieces, accept_without_check,
            confidence(high),
            evidence("geometry/decomposition_with_gap_or_overlap, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. takes the decomposition's pieces as usable before any gap-or-overlap test has run"),
            status(review_pending)).
action_maps(geometry, decomposition_with_gap_or_overlap, establish_polygon, register_givens,
            confidence(high),
            evidence("geometry/decomposition_with_gap_or_overlap, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(geometry, decomposition_with_gap_or_overlap, lose_whole_area, record_loss,
            confidence(high),
            evidence("geometry/decomposition_with_gap_or_overlap, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(geometry, decomposition_with_gap_or_overlap, omit_gap_overlap_test, omit_required_step,
            confidence(high),
            evidence("geometry/decomposition_with_gap_or_overlap, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(geometry, decomposition_with_gap_or_overlap, sum_piece_areas, accumulate_total,
            confidence(high),
            evidence("geometry/decomposition_with_gap_or_overlap, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. add the counted or measured pieces into a running total."),
            status(review_pending)).
action_maps(geometry, dimensional_measure_unit_coordination, coordinate_unit_iteration_power, assign_roles,
            confidence(medium),
            evidence("geometry/dimensional_measure_unit_coordination, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. binds the measure's dimension to the exponent its unit will carry"),
            status(review_pending)).
action_maps(geometry, dimensional_measure_unit_coordination, identify_measure_dimension, read_operand_attribute,
            confidence(high),
            evidence("geometry/dimensional_measure_unit_coordination, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(geometry, dimensional_measure_unit_coordination, identify_measure_name, read_operand_attribute,
            confidence(high),
            evidence("geometry/dimensional_measure_unit_coordination, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(geometry, dimensional_measure_unit_coordination, inscribe_unit_exponent, inscribe_result,
            confidence(high),
            evidence("geometry/dimensional_measure_unit_coordination, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. write the result in notation."),
            status(review_pending)).
action_maps(geometry, directed_difference_as_coordinate_distance, omit_absolute_value, omit_required_step,
            confidence(high),
            evidence("geometry/directed_difference_as_coordinate_distance, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(geometry, directed_difference_as_coordinate_distance, plot_endpoint, locate_position,
            confidence(high),
            evidence("geometry/directed_difference_as_coordinate_distance, q_start -> q_step_1; q_step_1 -> q_step_2: 2 of the machine's 5 distinct edges, static only. locate a value's position in the frame already established."),
            status(review_pending)).
action_maps(geometry, directed_difference_as_coordinate_distance, report_directed_change_as_length, misname_result,
            confidence(high),
            evidence("geometry/directed_difference_as_coordinate_distance, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. name a value that answers a different question than the one asked."),
            status(review_pending)).
action_maps(geometry, directed_difference_as_coordinate_distance, subtract_varying_coordinates, remove_quantity,
            confidence(high),
            evidence("geometry/directed_difference_as_coordinate_distance, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. take one quantity away from another."),
            status(review_pending)).
action_maps(geometry, divide_volume_by_one_dimension, divide_volume_by_length_only, compute_quotient,
            confidence(high),
            evidence("geometry/divide_volume_by_one_dimension, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. divides by the retained length alone, the second base dimension having been dropped at the previous edge"),
            status(review_pending)).
action_maps(geometry, divide_volume_by_one_dimension, drop_second_base_dimension, treat_relevant_as_irrelevant,
            confidence(high),
            evidence("geometry/divide_volume_by_one_dimension, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. treat a relation the result depends on as though it did not bear on the result."),
            status(review_pending)).
action_maps(geometry, divide_volume_by_one_dimension, report_partial_quotient_as_height, misname_result,
            confidence(high),
            evidence("geometry/divide_volume_by_one_dimension, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. name a value that answers a different question than the one asked."),
            status(review_pending)).
action_maps(geometry, divide_volume_by_one_dimension, retain_one_known_dimension, retain_unchanged,
            confidence(high),
            evidence("geometry/divide_volume_by_one_dimension, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. carries one base dimension forward; the deformation is at the next edge, where the second is dropped"),
            status(review_pending)).
action_maps(geometry, ignore_perimeter_rectangle_constraint, establish_area_constraint, register_givens,
            confidence(high),
            evidence("geometry/ignore_perimeter_rectangle_constraint, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(geometry, ignore_perimeter_rectangle_constraint, ignore_perimeter_constraint, treat_relevant_as_irrelevant,
            confidence(high),
            evidence("geometry/ignore_perimeter_rectangle_constraint, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. treat a relation the result depends on as though it did not bear on the result."),
            status(review_pending)).
action_maps(geometry, ignore_perimeter_rectangle_constraint, report_unfiltered_rectangles, misname_result,
            confidence(high),
            evidence("geometry/ignore_perimeter_rectangle_constraint, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. name a value that answers a different question than the one asked."),
            status(review_pending)).
action_maps(geometry, ignore_perimeter_rectangle_constraint, retain_all_area_factor_pairs, retain_where_change_was_due,
            confidence(high),
            evidence("geometry/ignore_perimeter_rectangle_constraint, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. carries the whole candidate set forward unfiltered at the slot where geometry/rectangle_area_perimeter_constraint_search filters by the perimeter constraint; keeping everything is the deformation, not a step before it"),
            status(review_pending)).
action_maps(geometry, ignore_symmetry_multiplicity, count_each_orbit_once, count_units,
            confidence(high),
            evidence("geometry/ignore_symmetry_multiplicity, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. counts one representative per reflection orbit, the reflected copies having been set aside at the previous edge"),
            status(review_pending)).
action_maps(geometry, ignore_symmetry_multiplicity, establish_perimeter, register_givens,
            confidence(high),
            evidence("geometry/ignore_symmetry_multiplicity, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(geometry, ignore_symmetry_multiplicity, ignore_reflected_side_copies, treat_relevant_as_irrelevant,
            confidence(high),
            evidence("geometry/ignore_symmetry_multiplicity, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. treat a relation the result depends on as though it did not bear on the result."),
            status(review_pending)).
action_maps(geometry, ignore_symmetry_multiplicity, subtract_flat_known_total, remove_quantity,
            confidence(high),
            evidence("geometry/ignore_symmetry_multiplicity, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. subtracts the known total once, the reflected copies having been ignored at the previous edge"),
            status(review_pending)).
action_maps(geometry, linear_unit_for_area_or_volume, identify_measure_dimension, read_operand_attribute,
            confidence(high),
            evidence("geometry/linear_unit_for_area_or_volume, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(geometry, linear_unit_for_area_or_volume, ignore_dimension_power, treat_relevant_as_irrelevant,
            confidence(high),
            evidence("geometry/linear_unit_for_area_or_volume, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. treat a relation the result depends on as though it did not bear on the result."),
            status(review_pending)).
action_maps(geometry, linear_unit_for_area_or_volume, lose_unit_exponent, record_loss,
            confidence(high),
            evidence("geometry/linear_unit_for_area_or_volume, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(geometry, linear_unit_for_area_or_volume, write_linear_unit, inscribe_result,
            confidence(high),
            evidence("geometry/linear_unit_for_area_or_volume, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. write the result in notation."),
            status(review_pending)).
action_maps(geometry, omit_half_in_triangle_area, multiply_base_by_height, compute_product,
            confidence(high),
            evidence("geometry/omit_half_in_triangle_area, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. multiply the operands as numerals."),
            status(review_pending)).
action_maps(geometry, omit_half_in_triangle_area, omit_halving, omit_required_step,
            confidence(high),
            evidence("geometry/omit_half_in_triangle_area, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(geometry, omit_half_in_triangle_area, omit_matching_copy_relation, omit_required_step,
            confidence(high),
            evidence("geometry/omit_half_in_triangle_area, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(geometry, omit_half_in_triangle_area, report_parallelogram_area_for_triangle, misname_result,
            confidence(high),
            evidence("geometry/omit_half_in_triangle_area, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. name a value that answers a different question than the one asked."),
            status(review_pending)).
action_maps(geometry, omit_unlabeled_boundary_side, omit_side_length, omit_required_step,
            confidence(high),
            evidence("geometry/omit_unlabeled_boundary_side, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(geometry, omit_unlabeled_boundary_side, read_labeled_sides, register_givens,
            confidence(high),
            evidence("geometry/omit_unlabeled_boundary_side, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(geometry, omit_unlabeled_boundary_side, report_partial_boundary, misname_result,
            confidence(high),
            evidence("geometry/omit_unlabeled_boundary_side, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. name a value that answers a different question than the one asked."),
            status(review_pending)).
action_maps(geometry, omit_unlabeled_boundary_side, stop_before_boundary_closure, halt_before_completion,
            confidence(high),
            evidence("geometry/omit_unlabeled_boundary_side, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. stop a required traversal, iteration, or recomposition before it finishes."),
            status(review_pending)).
action_maps(geometry, ordered_pair_coordinate_plot, establish_cartesian_axes, establish_reference_frame,
            confidence(high),
            evidence("geometry/ordered_pair_coordinate_plot, q_start -> q_step_1: 1 of the machine's 3 distinct edges, static only. set up the frame against which locations or magnitudes will be read: axes, zero as origin, a vertex and initial ray, a value or frequency scale."),
            status(review_pending)).
action_maps(geometry, ordered_pair_coordinate_plot, locate_first_then_second_for_each_pair, locate_position,
            confidence(high),
            evidence("geometry/ordered_pair_coordinate_plot, q_step_2 -> q_accept: 1 of the machine's 3 distinct edges, static only. locate a value's position in the frame already established."),
            status(review_pending)).
action_maps(geometry, ordered_pair_coordinate_plot, preserve_coordinate_order, retain_what_must_survive,
            confidence(high),
            evidence("geometry/ordered_pair_coordinate_plot, q_step_1 -> q_step_2: 1 of the machine's 3 distinct edges, static only. carries the pair's order forward from the axes to the plotting step. Ordered-pair plotting is answerable for exactly that order -- it is why (3,5) and (5,3) are two points -- so the retention is the conservation, and geometry/ordered_pair_coordinate_plot has no other edge that records one"),
            status(review_pending)).
action_maps(geometry, orientation_bound_shape_classification, observe_attributes, read_operand_attribute,
            confidence(high),
            evidence("geometry/orientation_bound_shape_classification, q_start -> q_step_1: 1 of the machine's 3 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(geometry, orientation_bound_shape_classification, privilege_prototype_orientation, substitute_appearance_for_measure,
            confidence(high),
            evidence("geometry/orientation_bound_shape_classification, q_step_1 -> q_step_2: 1 of the machine's 3 distinct edges, static only. puts the prototype's orientation in place of the defining attributes as the criterion"),
            status(review_pending)).
action_maps(geometry, orientation_bound_shape_classification, reject_after_rotation, misname_result,
            confidence(medium),
            evidence("geometry/orientation_bound_shape_classification, q_step_2 -> q_accept: 1 of the machine's 3 distinct edges, static only. terminal edge; states a non-membership the figure's defining attributes do not support, the prototype orientation having been privileged"),
            status(review_pending)).
action_maps(geometry, parallelogram_area_base_height, cut_and_translate_to_rectangle, decompose_region,
            confidence(high),
            evidence("geometry/parallelogram_area_base_height, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. cuts the parallelogram and translates the piece, so the figure becomes a rectangle of the same area"),
            status(review_pending)).
action_maps(geometry, parallelogram_area_base_height, distinguish_height_from_slanted_side, test_criteria,
            confidence(high),
            evidence("geometry/parallelogram_area_base_height, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. tests which segment is perpendicular to the chosen base"),
            status(review_pending)).
action_maps(geometry, parallelogram_area_base_height, identify_base, assign_roles,
            confidence(high),
            evidence("geometry/parallelogram_area_base_height, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. binds one side of the figure to the base role, which is what makes a height question answerable"),
            status(review_pending)).
action_maps(geometry, parallelogram_area_base_height, multiply_base_by_perpendicular_height, compute_product,
            confidence(high),
            evidence("geometry/parallelogram_area_base_height, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. multiply the operands as numerals."),
            status(review_pending)).
action_maps(geometry, perimeter_two_sides_only, report_partial_boundary, misname_result,
            confidence(high),
            evidence("geometry/perimeter_two_sides_only, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. name a value that answers a different question than the one asked."),
            status(review_pending)).
action_maps(geometry, perimeter_two_sides_only, stop_before_opposite_sides, halt_before_completion,
            confidence(high),
            evidence("geometry/perimeter_two_sides_only, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. stop a required traversal, iteration, or recomposition before it finishes."),
            status(review_pending)).
action_maps(geometry, perimeter_two_sides_only, traverse_side, traverse_boundary,
            confidence(high),
            evidence("geometry/perimeter_two_sides_only, q_start -> q_step_1; q_step_1 -> q_step_2: 2 of the machine's 4 distinct edges, static only. walk along the sides or segments of a boundary in order."),
            status(review_pending)).
action_maps(geometry, perimeter_uses_area_formula, multiply_dimensions, compute_product,
            confidence(high),
            evidence("geometry/perimeter_uses_area_formula, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. multiply the operands as numerals."),
            status(review_pending)).
action_maps(geometry, perimeter_uses_area_formula, observe_dimensions, read_operand_attribute,
            confidence(high),
            evidence("geometry/perimeter_uses_area_formula, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(geometry, perimeter_uses_area_formula, report_area_value_as_perimeter, misname_result,
            confidence(high),
            evidence("geometry/perimeter_uses_area_formula, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. name a value that answers a different question than the one asked."),
            status(review_pending)).
action_maps(geometry, perimeter_uses_area_formula, select_area_formula_by_surface_association, substitute_appearance_for_measure,
            confidence(high),
            evidence("geometry/perimeter_uses_area_formula, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. picks the formula by what the figure looks like rather than by what the question measures"),
            status(review_pending)).
action_maps(geometry, polygon_perimeter_boundary_accumulation, accumulate_complete_boundary, accumulate_total,
            confidence(high),
            evidence("geometry/polygon_perimeter_boundary_accumulation, q_step_2 -> q_accept: 1 of the machine's 3 distinct edges, static only. add the counted or measured pieces into a running total."),
            status(review_pending)).
action_maps(geometry, polygon_perimeter_boundary_accumulation, establish_closed_polygon_boundary, register_givens,
            confidence(medium),
            evidence("geometry/polygon_perimeter_boundary_accumulation, q_start -> q_step_1: 1 of the machine's 3 distinct edges, static only. holds the polygon's closed boundary as the object the traversal will walk"),
            status(review_pending)).
action_maps(geometry, polygon_perimeter_boundary_accumulation, traverse_side_lengths_in_order, traverse_boundary,
            confidence(high),
            evidence("geometry/polygon_perimeter_boundary_accumulation, q_step_1 -> q_step_2: 1 of the machine's 3 distinct edges, static only. walk along the sides or segments of a boundary in order."),
            status(review_pending)).
action_maps(geometry, polyhedron_surface_area_from_net, enumerate_all_face_areas, measure_quantity,
            confidence(medium),
            evidence("geometry/polyhedron_surface_area_from_net, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. measures every face of the unfolded net; the label carries an enumeration the canonical action drops"),
            status(review_pending)).
action_maps(geometry, polyhedron_surface_area_from_net, identify_polyhedron, register_givens,
            confidence(high),
            evidence("geometry/polyhedron_surface_area_from_net, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(geometry, polyhedron_surface_area_from_net, sum_each_face_exactly_once, accumulate_total,
            confidence(high),
            evidence("geometry/polyhedron_surface_area_from_net, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. accumulates the face areas with each face entering once, which is the check the net buys"),
            status(review_pending)).
action_maps(geometry, polyhedron_surface_area_from_net, unfold_to_net, decompose_region,
            confidence(high),
            evidence("geometry/polyhedron_surface_area_from_net, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. cut a figure into non-overlapping pieces, or unfold a solid into its net."),
            status(review_pending)).
action_maps(geometry, rectangle_area_perimeter_constraint_search, enumerate_area_factor_pairs, enumerate_candidates,
            confidence(high),
            evidence("geometry/rectangle_area_perimeter_constraint_search, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. generate the candidate set a later step will filter."),
            status(review_pending)).
action_maps(geometry, rectangle_area_perimeter_constraint_search, establish_area_constraint, register_givens,
            confidence(high),
            evidence("geometry/rectangle_area_perimeter_constraint_search, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(geometry, rectangle_area_perimeter_constraint_search, establish_perimeter_constraint, register_givens,
            confidence(high),
            evidence("geometry/rectangle_area_perimeter_constraint_search, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(geometry, rectangle_area_perimeter_constraint_search, report_constrained_rectangles, name_result,
            confidence(high),
            evidence("geometry/rectangle_area_perimeter_constraint_search, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. say which quantity the answer is."),
            status(review_pending)).
action_maps(geometry, rectangle_area_perimeter_constraint_search, retain_pairs_with_perimeter, filter_by_constraint,
            confidence(high),
            evidence("geometry/rectangle_area_perimeter_constraint_search, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. keep only the candidates that satisfy a stated constraint."),
            status(review_pending)).
action_maps(geometry, rectangle_area_unit_iteration, coordinate_square_units, iterate_composite_unit,
            confidence(high),
            evidence("geometry/rectangle_area_unit_iteration, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, witnessed. holds the row iteration and the column iteration together so that each cell counts as one square unit"),
            status(review_pending)).
action_maps(geometry, rectangle_area_unit_iteration, count_square_units, count_units,
            confidence(high),
            evidence("geometry/rectangle_area_unit_iteration, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, witnessed. count how many units the iteration or the partition produced."),
            status(review_pending)).
action_maps(geometry, rectangle_area_unit_iteration, establish_rectangle, register_givens,
            confidence(high),
            evidence("geometry/rectangle_area_unit_iteration, q_start -> q_step_1: 1 of the machine's 5 distinct edges, witnessed. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(geometry, rectangle_area_unit_iteration, iterate_columns, iterate_unit,
            confidence(high),
            evidence("geometry/rectangle_area_unit_iteration, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, witnessed. repeat a unit to build or to measure a quantity."),
            status(review_pending)).
action_maps(geometry, rectangle_area_unit_iteration, iterate_rows, iterate_unit,
            confidence(high),
            evidence("geometry/rectangle_area_unit_iteration, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, witnessed. repeat a unit to build or to measure a quantity."),
            status(review_pending)).
action_maps(geometry, rectangle_factor_pair_search, enumerate_whole_number_side_lengths, enumerate_candidates,
            confidence(high),
            evidence("geometry/rectangle_factor_pair_search, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. generate the candidate set a later step will filter."),
            status(review_pending)).
action_maps(geometry, rectangle_factor_pair_search, establish_target_area, register_givens,
            confidence(high),
            evidence("geometry/rectangle_factor_pair_search, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(geometry, rectangle_factor_pair_search, identify_rotations_as_commutative_pairs, commute_operands,
            confidence(medium),
            evidence("geometry/rectangle_factor_pair_search, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. recognises a rotated rectangle as the commuted factor pair, so the pair is retained once"),
            status(review_pending)).
action_maps(geometry, rectangle_factor_pair_search, retain_products_equal_to_area, filter_by_constraint,
            confidence(high),
            evidence("geometry/rectangle_factor_pair_search, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. keep only the candidates that satisfy a stated constraint."),
            status(review_pending)).
action_maps(geometry, rectangle_factor_pair_search, satisfy_factor_scope, verify_invariant,
            confidence(medium),
            evidence("geometry/rectangle_factor_pair_search, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. certifies that the search covered the whole factor scope"),
            status(review_pending)).
action_maps(geometry, rectangle_missing_side_from_area, divide_area_by_known_side, compute_quotient,
            confidence(high),
            evidence("geometry/rectangle_missing_side_from_area, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. divide the operands as numerals."),
            status(review_pending)).
action_maps(geometry, rectangle_missing_side_from_area, establish_area_product, register_givens,
            confidence(high),
            evidence("geometry/rectangle_missing_side_from_area, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(geometry, rectangle_missing_side_from_area, reconstruct_rectangle, verify_invariant,
            confidence(medium),
            evidence("geometry/rectangle_missing_side_from_area, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. rebuilds the rectangle from the recovered side, which is what checks the area product back"),
            status(review_pending)).
action_maps(geometry, rectangle_missing_side_from_area, retain_known_side, retain_unchanged,
            confidence(high),
            evidence("geometry/rectangle_missing_side_from_area, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. carries the known side forward as the divisor of the area product"),
            status(review_pending)).
action_maps(geometry, rectangle_missing_side_from_perimeter, coordinate_opposite_side_pairs, assign_roles,
            confidence(high),
            evidence("geometry/rectangle_missing_side_from_perimeter, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. binds the four sides into the two opposite pairs the halving then uses"),
            status(review_pending)).
action_maps(geometry, rectangle_missing_side_from_perimeter, establish_target_perimeter, register_givens,
            confidence(high),
            evidence("geometry/rectangle_missing_side_from_perimeter, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(geometry, rectangle_missing_side_from_perimeter, halve_perimeter, compute_quotient,
            confidence(high),
            evidence("geometry/rectangle_missing_side_from_perimeter, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. divide the operands as numerals."),
            status(review_pending)).
action_maps(geometry, rectangle_missing_side_from_perimeter, subtract_known_side, remove_quantity,
            confidence(high),
            evidence("geometry/rectangle_missing_side_from_perimeter, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. take one quantity away from another."),
            status(review_pending)).
action_maps(geometry, rectangle_missing_side_from_perimeter, verify_rectangle_boundary, verify_invariant,
            confidence(high),
            evidence("geometry/rectangle_missing_side_from_perimeter, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. check that the property the strategy must keep still holds."),
            status(review_pending)).
action_maps(geometry, rectangle_perimeter_boundary_traversal, accumulate_boundary_length, accumulate_total,
            confidence(high),
            evidence("geometry/rectangle_perimeter_boundary_traversal, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, static only. add the counted or measured pieces into a running total."),
            status(review_pending)).
action_maps(geometry, rectangle_perimeter_boundary_traversal, establish_rectangle, register_givens,
            confidence(high),
            evidence("geometry/rectangle_perimeter_boundary_traversal, q_start -> q_step_1: 1 of the machine's 6 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(geometry, rectangle_perimeter_boundary_traversal, traverse_opposite_side, traverse_boundary,
            confidence(high),
            evidence("geometry/rectangle_perimeter_boundary_traversal, q_step_3 -> q_step_4; q_step_4 -> q_step_5: 2 of the machine's 6 distinct edges, static only. walk along the sides or segments of a boundary in order."),
            status(review_pending)).
action_maps(geometry, rectangle_perimeter_boundary_traversal, traverse_side, traverse_boundary,
            confidence(high),
            evidence("geometry/rectangle_perimeter_boundary_traversal, q_step_1 -> q_step_2; q_step_2 -> q_step_3: 2 of the machine's 6 distinct edges, static only. walk along the sides or segments of a boundary in order."),
            status(review_pending)).
action_maps(geometry, rectangle_perimeter_side_pair_search, enumerate_positive_side_pairs, enumerate_candidates,
            confidence(high),
            evidence("geometry/rectangle_perimeter_side_pair_search, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. generate the candidate set a later step will filter."),
            status(review_pending)).
action_maps(geometry, rectangle_perimeter_side_pair_search, establish_target_perimeter, register_givens,
            confidence(high),
            evidence("geometry/rectangle_perimeter_side_pair_search, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(geometry, rectangle_perimeter_side_pair_search, halve_for_length_plus_width, compute_quotient,
            confidence(high),
            evidence("geometry/rectangle_perimeter_side_pair_search, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. divide the operands as numerals."),
            status(review_pending)).
action_maps(geometry, rectangle_perimeter_side_pair_search, retain_complete_boundaries, filter_by_constraint,
            confidence(high),
            evidence("geometry/rectangle_perimeter_side_pair_search, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. keep only the candidates that satisfy a stated constraint."),
            status(review_pending)).
action_maps(geometry, rectangle_perimeter_side_pair_search, satisfy_side_scope, verify_invariant,
            confidence(medium),
            evidence("geometry/rectangle_perimeter_side_pair_search, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. certifies that the search covered the whole side scope"),
            status(review_pending)).
action_maps(geometry, rectangular_prism_missing_dimension_from_volume, coordinate_known_base, register_givens,
            confidence(high),
            evidence("geometry/rectangular_prism_missing_dimension_from_volume, q_start -> q_step_1: 1 of the machine's 3 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(geometry, rectangular_prism_missing_dimension_from_volume, divide_volume_by_base_area, compute_quotient,
            confidence(high),
            evidence("geometry/rectangular_prism_missing_dimension_from_volume, q_step_1 -> q_step_2: 1 of the machine's 3 distinct edges, static only. divide the operands as numerals."),
            status(review_pending)).
action_maps(geometry, rectangular_prism_missing_dimension_from_volume, reconstruct_unit_cube_stack, verify_invariant,
            confidence(medium),
            evidence("geometry/rectangular_prism_missing_dimension_from_volume, q_step_2 -> q_accept: 1 of the machine's 3 distinct edges, static only. rebuilds the cube stack from the recovered dimension, which is what checks the volume back"),
            status(review_pending)).
action_maps(geometry, rectangular_prism_volume_layer_iteration, coordinate_base, unitize_referent,
            confidence(medium),
            evidence("geometry/rectangular_prism_volume_layer_iteration, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. constitutes the base layer as the composite the height layers will iterate"),
            status(review_pending)).
action_maps(geometry, rectangular_prism_volume_layer_iteration, count_cubic_units, count_units,
            confidence(high),
            evidence("geometry/rectangular_prism_volume_layer_iteration, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. count how many units the iteration or the partition produced."),
            status(review_pending)).
action_maps(geometry, rectangular_prism_volume_layer_iteration, establish_unit_cube_as_volume_unit, unitize_referent,
            confidence(high),
            evidence("geometry/rectangular_prism_volume_layer_iteration, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. constitute the whole or unit that all later measurement refers to."),
            status(review_pending)).
action_maps(geometry, rectangular_prism_volume_layer_iteration, iterate_height_layers, iterate_composite_unit,
            confidence(high),
            evidence("geometry/rectangular_prism_volume_layer_iteration, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. repeat a composite unit -- a group held as one thing -- rather than its members."),
            status(review_pending)).
action_maps(geometry, rigid_shape_composition, establish_bounded_region, unitize_referent,
            confidence(high),
            evidence("geometry/rigid_shape_composition, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. constitute the whole or unit that all later measurement refers to."),
            status(review_pending)).
action_maps(geometry, rigid_shape_composition, inspect_coverage_without_gaps_or_overlaps, verify_invariant,
            confidence(high),
            evidence("geometry/rigid_shape_composition, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. check that the property the strategy must keep still holds."),
            status(review_pending)).
action_maps(geometry, rigid_shape_composition, place_parts_by_rigid_motion, recompose_total,
            confidence(medium),
            evidence("geometry/rigid_shape_composition, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. assembles the rigid parts into the bounded region by positioning each one"),
            status(review_pending)).
action_maps(geometry, rigid_shape_composition, preserve_rigid_parts, verify_invariant,
            confidence(high),
            evidence("geometry/rigid_shape_composition, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. certifies the parts as rigid, which is the condition under which placing them preserves their areas"),
            status(review_pending)).
action_maps(geometry, shape_classification_by_defining_attributes, ignore_nondefining_orientation, set_aside_irrelevant_attribute,
            confidence(high),
            evidence("geometry/shape_classification_by_defining_attributes, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. sets orientation aside, which the defining attributes of the category do not depend on"),
            status(review_pending)).
action_maps(geometry, shape_classification_by_defining_attributes, observe_attributes, read_operand_attribute,
            confidence(high),
            evidence("geometry/shape_classification_by_defining_attributes, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(geometry, shape_classification_by_defining_attributes, retain_hierarchical_categories, record_conservation,
            confidence(medium),
            evidence("geometry/shape_classification_by_defining_attributes, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. terminal edge; keeps every category whose defining attributes the figure satisfies, so the hierarchy survives the classification"),
            status(review_pending)).
action_maps(geometry, shape_classification_by_defining_attributes, test_required_attributes, test_criteria,
            confidence(high),
            evidence("geometry/shape_classification_by_defining_attributes, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. test whether the required attributes or conditions hold."),
            status(review_pending)).
action_maps(geometry, slanted_side_as_parallelogram_height, identify_base, assign_roles,
            confidence(high),
            evidence("geometry/slanted_side_as_parallelogram_height, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. binds one side of the figure to the base role, which is what makes a height question answerable"),
            status(review_pending)).
action_maps(geometry, slanted_side_as_parallelogram_height, multiply_base_by_slanted_side, compute_product,
            confidence(high),
            evidence("geometry/slanted_side_as_parallelogram_height, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. multiply the operands as numerals."),
            status(review_pending)).
action_maps(geometry, slanted_side_as_parallelogram_height, omit_perpendicularity_check, omit_required_step,
            confidence(high),
            evidence("geometry/slanted_side_as_parallelogram_height, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(geometry, slanted_side_as_parallelogram_height, select_slanted_side_as_height, conflate_roles,
            confidence(high),
            evidence("geometry/slanted_side_as_parallelogram_height, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. binds the slanted side to the height role, collapsing the side and the perpendicular height into one"),
            status(review_pending)).
action_maps(geometry, subtract_side_from_area, establish_area_as_total, register_givens,
            confidence(high),
            evidence("geometry/subtract_side_from_area, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(geometry, subtract_side_from_area, omit_inverse_multiplication, omit_required_step,
            confidence(high),
            evidence("geometry/subtract_side_from_area, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(geometry, subtract_side_from_area, report_additive_remainder_as_side, misname_result,
            confidence(high),
            evidence("geometry/subtract_side_from_area, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. name a value that answers a different question than the one asked."),
            status(review_pending)).
action_maps(geometry, subtract_side_from_area, subtract_known_side, remove_quantity,
            confidence(high),
            evidence("geometry/subtract_side_from_area, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. take one quantity away from another."),
            status(review_pending)).
action_maps(geometry, sum_overlapping_prism_volumes, calculate_component_volumes, measure_quantity,
            confidence(high),
            evidence("geometry/sum_overlapping_prism_volumes, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. determine a quantity's measure with the unit already established."),
            status(review_pending)).
action_maps(geometry, sum_overlapping_prism_volumes, double_count_shared_cubes, double_count,
            confidence(high),
            evidence("geometry/sum_overlapping_prism_volumes, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. count the same unit or region more than once."),
            status(review_pending)).
action_maps(geometry, sum_overlapping_prism_volumes, omit_overlap_correction, omit_required_step,
            confidence(high),
            evidence("geometry/sum_overlapping_prism_volumes, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(geometry, sum_overlapping_prism_volumes, report_component_sum, misname_result,
            confidence(high),
            evidence("geometry/sum_overlapping_prism_volumes, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. reports the components' sum as the composite volume, the shared cubes having been counted twice"),
            status(review_pending)).
action_maps(geometry, symmetry_constrained_side_reconstruction, accumulate_known_orbits, accumulate_total,
            confidence(high),
            evidence("geometry/symmetry_constrained_side_reconstruction, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. add the counted or measured pieces into a running total."),
            status(review_pending)).
action_maps(geometry, symmetry_constrained_side_reconstruction, establish_perimeter, register_givens,
            confidence(high),
            evidence("geometry/symmetry_constrained_side_reconstruction, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(geometry, symmetry_constrained_side_reconstruction, group_sides_into_reflection_orbits, assign_roles,
            confidence(medium),
            evidence("geometry/symmetry_constrained_side_reconstruction, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. binds each side to its reflection orbit, so the known orbits can be accumulated apart from the unknown one"),
            status(review_pending)).
action_maps(geometry, symmetry_constrained_side_reconstruction, isolate_unknown_orbit, isolate_unknown,
            confidence(high),
            evidence("geometry/symmetry_constrained_side_reconstruction, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. separate the unknown quantity from the known ones so that it stands alone."),
            status(review_pending)).
action_maps(geometry, symmetry_constrained_side_reconstruction, partition_remaining_boundary, share_into_known_groups,
            confidence(medium),
            evidence("geometry/symmetry_constrained_side_reconstruction, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. deals the boundary left after the known orbits among the sides of the unknown orbit"),
            status(review_pending)).
action_maps(geometry, triangle_area_half_base_height, compose_matching_triangle_copy, recompose_total,
            confidence(medium),
            evidence("geometry/triangle_area_half_base_height, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. joins a congruent copy to the given triangle so the pair forms one parallelogram"),
            status(review_pending)).
action_maps(geometry, triangle_area_half_base_height, form_parallelogram_product, compute_product,
            confidence(high),
            evidence("geometry/triangle_area_half_base_height, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. multiply the operands as numerals."),
            status(review_pending)).
action_maps(geometry, triangle_area_half_base_height, identify_base, assign_roles,
            confidence(high),
            evidence("geometry/triangle_area_half_base_height, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. binds one side of the figure to the base role, which is what makes a height question answerable"),
            status(review_pending)).
action_maps(geometry, triangle_area_half_base_height, identify_perpendicular_height, assign_roles,
            confidence(high),
            evidence("geometry/triangle_area_half_base_height, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. binds the perpendicular segment to the height role"),
            status(review_pending)).
action_maps(geometry, triangle_area_half_base_height, take_one_of_two_equal_triangles, select_part,
            confidence(high),
            evidence("geometry/triangle_area_half_base_height, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. takes one of the two equal triangles the parallelogram product covers"),
            status(review_pending)).
action_maps(geometry, visible_faces_only_surface_area, enumerate_visible_faces, enumerate_candidates,
            confidence(high),
            evidence("geometry/visible_faces_only_surface_area, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. enumerates only the faces the single view exposes"),
            status(review_pending)).
action_maps(geometry, visible_faces_only_surface_area, inspect_solid_view, register_givens,
            confidence(medium),
            evidence("geometry/visible_faces_only_surface_area, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. holds only what one view of the solid exposes as the given, which is why the hidden face can be omitted later"),
            status(review_pending)).
action_maps(geometry, visible_faces_only_surface_area, omit_hidden_face, omit_required_step,
            confidence(high),
            evidence("geometry/visible_faces_only_surface_area, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(geometry, visible_faces_only_surface_area, report_partial_surface_area, misname_result,
            confidence(high),
            evidence("geometry/visible_faces_only_surface_area, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. name a value that answers a different question than the one asked."),
            status(review_pending)).
action_maps(integer, drop_sign_use_magnitude_sum, drop_signs, treat_relevant_as_irrelevant,
            confidence(high),
            evidence("integer/drop_sign_use_magnitude_sum, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges, static only. treat a relation the result depends on as though it did not bear on the result."),
            status(review_pending)).
action_maps(integer, drop_sign_use_magnitude_sum, identify_magnitudes, read_operand_attribute,
            confidence(high),
            evidence("integer/drop_sign_use_magnitude_sum, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(integer, drop_sign_use_magnitude_sum, identify_signs, read_operand_attribute,
            confidence(high),
            evidence("integer/drop_sign_use_magnitude_sum, q_start -> q_step_1: 1 of the machine's 6 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(integer, drop_sign_use_magnitude_sum, lose_sign_relation, record_loss,
            confidence(high),
            evidence("integer/drop_sign_use_magnitude_sum, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(integer, drop_sign_use_magnitude_sum, name_magnitude_sum_as_answer, misname_result,
            confidence(high),
            evidence("integer/drop_sign_use_magnitude_sum, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, static only. name a value that answers a different question than the one asked."),
            status(review_pending)).
action_maps(integer, drop_sign_use_magnitude_sum, sum_magnitudes_only, combine_quantities,
            confidence(high),
            evidence("integer/drop_sign_use_magnitude_sum, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges, static only. adds the magnitudes, the signs having been dropped at the previous edge"),
            status(review_pending)).
action_maps(integer, inequality_as_boundary_point, identify_boundary, read_operand_attribute,
            confidence(high),
            evidence("integer/inequality_as_boundary_point, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(integer, inequality_as_boundary_point, ignore_relation_direction, treat_relevant_as_irrelevant,
            confidence(high),
            evidence("integer/inequality_as_boundary_point, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. treat a relation the result depends on as though it did not bear on the result."),
            status(review_pending)).
action_maps(integer, inequality_as_boundary_point, omit_solution_ray, omit_required_step,
            confidence(high),
            evidence("integer/inequality_as_boundary_point, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(integer, inequality_as_boundary_point, report_boundary_as_only_solution, misname_result,
            confidence(high),
            evidence("integer/inequality_as_boundary_point, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. name a value that answers a different question than the one asked."),
            status(review_pending)).
action_maps(integer, inequality_solution_set_representation, choose_endpoint_inclusion, test_criteria,
            confidence(medium),
            evidence("integer/inequality_solution_set_representation, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. tests whether the boundary point itself satisfies the relation, which decides open against closed"),
            status(review_pending)).
action_maps(integer, inequality_solution_set_representation, extend_ray_over_all_solutions, inscribe_result,
            confidence(high),
            evidence("integer/inequality_solution_set_representation, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. draws the whole solution ray rather than its boundary alone"),
            status(review_pending)).
action_maps(integer, inequality_solution_set_representation, identify_boundary, read_operand_attribute,
            confidence(high),
            evidence("integer/inequality_solution_set_representation, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(integer, inequality_solution_set_representation, interpret_relation_direction, read_operand_attribute,
            confidence(high),
            evidence("integer/inequality_solution_set_representation, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(integer, order_by_magnitude_ignore_sign, establish_zero_as_origin, establish_reference_frame,
            confidence(high),
            evidence("integer/order_by_magnitude_ignore_sign, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. set up the frame against which locations or magnitudes will be read: axes, zero as origin, a vertex and initial ray, a value or frequency scale."),
            status(review_pending)).
action_maps(integer, order_by_magnitude_ignore_sign, lose_directional_order, record_loss,
            confidence(high),
            evidence("integer/order_by_magnitude_ignore_sign, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(integer, order_by_magnitude_ignore_sign, order_magnitudes_only, order_by_magnitude,
            confidence(high),
            evidence("integer/order_by_magnitude_ignore_sign, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. orders the magnitudes, the signed locations having been replaced by distances at the previous edge"),
            status(review_pending)).
action_maps(integer, order_by_magnitude_ignore_sign, replace_signed_locations_with_distances, substitute_scalar_for_structured_quantity,
            confidence(high),
            evidence("integer/order_by_magnitude_ignore_sign, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. replaces each signed location with its unsigned distance from zero, so direction stops bearing on the order"),
            status(review_pending)).
action_maps(integer, signed_addition_with_sign_relation, assign_result_sign, assign_roles,
            confidence(high),
            evidence("integer/signed_addition_with_sign_relation, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, witnessed. binds the determined sign to the combined magnitude"),
            status(review_pending)).
action_maps(integer, signed_addition_with_sign_relation, combine_magnitudes_by_sign_relation, combine_quantities,
            confidence(high),
            evidence("integer/signed_addition_with_sign_relation, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges, witnessed. join two quantities into their sum."),
            status(review_pending)).
action_maps(integer, signed_addition_with_sign_relation, determine_sign_relation, read_operand_attribute,
            confidence(high),
            evidence("integer/signed_addition_with_sign_relation, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges, witnessed. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(integer, signed_addition_with_sign_relation, identify_magnitudes, read_operand_attribute,
            confidence(high),
            evidence("integer/signed_addition_with_sign_relation, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, witnessed. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(integer, signed_addition_with_sign_relation, identify_signs, read_operand_attribute,
            confidence(high),
            evidence("integer/signed_addition_with_sign_relation, q_start -> q_step_1: 1 of the machine's 6 distinct edges, witnessed. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(integer, signed_addition_with_sign_relation, preserve_sign_relation, record_conservation,
            confidence(high),
            evidence("integer/signed_addition_with_sign_relation, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, witnessed. record that the strategy kept the relation it was obliged to keep."),
            status(review_pending)).
action_maps(integer, signed_number_location_and_order, establish_zero_as_origin, establish_reference_frame,
            confidence(high),
            evidence("integer/signed_number_location_and_order, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. set up the frame against which locations or magnitudes will be read: axes, zero as origin, a vertex and initial ray, a value or frequency scale."),
            status(review_pending)).
action_maps(integer, signed_number_location_and_order, locate_each_signed_value, locate_position,
            confidence(high),
            evidence("integer/signed_number_location_and_order, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. locate a value's position in the frame already established."),
            status(review_pending)).
action_maps(integer, signed_number_location_and_order, preserve_direction_from_zero, verify_invariant,
            confidence(high),
            evidence("integer/signed_number_location_and_order, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. certifies that each location keeps its direction from zero before the order is read off"),
            status(review_pending)).
action_maps(integer, signed_number_location_and_order, read_locations_left_to_right, order_by_magnitude,
            confidence(high),
            evidence("integer/signed_number_location_and_order, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. reads the order off the frame, left to right, from the located signed values"),
            status(review_pending)).
action_maps(measurement, change_unit_label_without_scaling, change_unit_label, rename_in_place_of_transforming,
            confidence(high),
            evidence("measurement/change_unit_label_without_scaling, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. relabels the measurement unit, the iteration by the conversion factor having been omitted two edges earlier"),
            status(review_pending)).
action_maps(measurement, change_unit_label_without_scaling, omit_iteration_by_factor, omit_required_step,
            confidence(high),
            evidence("measurement/change_unit_label_without_scaling, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(measurement, change_unit_label_without_scaling, preserve_numeral, retain_where_change_was_due,
            confidence(high),
            evidence("measurement/change_unit_label_without_scaling, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. carries the numeral forward untouched where the conversion factor obliged it to scale; the iteration by that factor was omitted two edges earlier"),
            status(review_pending)).
action_maps(measurement, change_unit_label_without_scaling, read_conversion_factor, read_operand_attribute,
            confidence(high),
            evidence("measurement/change_unit_label_without_scaling, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(measurement, count_marks_not_intervals, count_marks_instead_of_spaces, substitute_count_for_measure,
            confidence(high),
            evidence("measurement/count_marks_not_intervals, q_step_1 -> q_step_2: 1 of the machine's 3 distinct edges, static only. counts the boundary marks in place of the intervals between them"),
            status(review_pending)).
action_maps(measurement, count_marks_not_intervals, expose_interval_boundary_marks, register_givens,
            confidence(medium),
            evidence("measurement/count_marks_not_intervals, q_start -> q_step_1: 1 of the machine's 3 distinct edges, static only. makes the scale's boundary marks available as what the next edge counts"),
            status(review_pending)).
action_maps(measurement, count_marks_not_intervals, overcount_by_one_subunit, record_loss,
            confidence(medium),
            evidence("measurement/count_marks_not_intervals, q_step_2 -> q_accept: 1 of the machine's 3 distinct edges, static only. terminal edge; records the count coming out one too high because the marks were counted in place of the intervals"),
            status(review_pending)).
action_maps(measurement, drop_unit_from_measured_quantity_change, discard_measurement_unit, treat_relevant_as_irrelevant,
            confidence(high),
            evidence("measurement/drop_unit_from_measured_quantity_change, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. treat a relation the result depends on as though it did not bear on the result."),
            status(review_pending)).
action_maps(measurement, drop_unit_from_measured_quantity_change, perform_grounded_quantity_change, apply_quantity_change,
            confidence(high),
            evidence("measurement/drop_unit_from_measured_quantity_change, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. carries out the change on the measured amount; both machines that use it differ in whether the unit survives the change, not in its direction, and the canonical action is direction-neutral for that reason"),
            status(review_pending)).
action_maps(measurement, drop_unit_from_measured_quantity_change, read_quantity_numerals, register_givens,
            confidence(high),
            evidence("measurement/drop_unit_from_measured_quantity_change, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(measurement, drop_unit_from_measured_quantity_change, report_bare_numeral, misname_result,
            confidence(high),
            evidence("measurement/drop_unit_from_measured_quantity_change, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. name a value that answers a different question than the one asked."),
            status(review_pending)).
action_maps(measurement, linear_unit_iteration, establish_length_attribute, read_operand_attribute,
            confidence(high),
            evidence("measurement/linear_unit_iteration, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. picks out length as the attribute to be measured, before any unit is established"),
            status(review_pending)).
action_maps(measurement, linear_unit_iteration, establish_unit, unitize_referent,
            confidence(high),
            evidence("measurement/linear_unit_iteration, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. constitute the whole or unit that all later measurement refers to."),
            status(review_pending)).
action_maps(measurement, linear_unit_iteration, iterate_interval_from_zero, iterate_unit,
            confidence(high),
            evidence("measurement/linear_unit_iteration, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. repeat a unit to build or to measure a quantity."),
            status(review_pending)).
action_maps(measurement, linear_unit_iteration, partition_unit_into_equal_intervals, partition_into_equal_parts,
            confidence(high),
            evidence("measurement/linear_unit_iteration, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. cut the referent into parts the strategy treats as equal."),
            status(review_pending)).
action_maps(measurement, linear_unit_iteration, read_accumulated_length, name_result,
            confidence(high),
            evidence("measurement/linear_unit_iteration, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. say which quantity the answer is."),
            status(review_pending)).
action_maps(measurement, liquid_volume_count_marks_not_intervals, count_marks_instead_of_volume_intervals, substitute_count_for_measure,
            confidence(high),
            evidence("measurement/liquid_volume_count_marks_not_intervals, q_step_1 -> q_step_2: 1 of the machine's 3 distinct edges, static only. counts the scale's marks in place of the volume intervals between them"),
            status(review_pending)).
action_maps(measurement, liquid_volume_count_marks_not_intervals, expose_volume_scale_marks, register_givens,
            confidence(medium),
            evidence("measurement/liquid_volume_count_marks_not_intervals, q_start -> q_step_1: 1 of the machine's 3 distinct edges, static only. makes the volume scale's marks available as what the next edge counts"),
            status(review_pending)).
action_maps(measurement, liquid_volume_count_marks_not_intervals, overcount_liquid_volume_by_one_subunit, record_loss,
            confidence(medium),
            evidence("measurement/liquid_volume_count_marks_not_intervals, q_step_2 -> q_accept: 1 of the machine's 3 distinct edges, static only. terminal edge; records the volume count coming out one subunit too high for the same reason"),
            status(review_pending)).
action_maps(measurement, liquid_volume_scale_reading, establish_liquid_volume_attribute, read_operand_attribute,
            confidence(high),
            evidence("measurement/liquid_volume_scale_reading, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. picks out liquid volume as the attribute to be measured, before any unit is established"),
            status(review_pending)).
action_maps(measurement, liquid_volume_scale_reading, establish_volume_unit, unitize_referent,
            confidence(high),
            evidence("measurement/liquid_volume_scale_reading, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. constitute the whole or unit that all later measurement refers to."),
            status(review_pending)).
action_maps(measurement, liquid_volume_scale_reading, locate_fill_level_after_intervals, locate_position,
            confidence(high),
            evidence("measurement/liquid_volume_scale_reading, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. locate a value's position in the frame already established."),
            status(review_pending)).
action_maps(measurement, liquid_volume_scale_reading, partition_volume_scale, partition_into_equal_parts,
            confidence(high),
            evidence("measurement/liquid_volume_scale_reading, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. cut the referent into parts the strategy treats as equal."),
            status(review_pending)).
action_maps(measurement, liquid_volume_scale_reading, read_liquid_volume, name_result,
            confidence(high),
            evidence("measurement/liquid_volume_scale_reading, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. say which quantity the answer is."),
            status(review_pending)).
action_maps(measurement, unit_conversion_by_iteration, establish_equivalence, register_givens,
            confidence(medium),
            evidence("measurement/unit_conversion_by_iteration, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. holds the conversion equivalence as the given relation the iteration will use"),
            status(review_pending)).
action_maps(measurement, unit_conversion_by_iteration, iterate_conversion_group, iterate_composite_unit,
            confidence(high),
            evidence("measurement/unit_conversion_by_iteration, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. repeat a composite unit -- a group held as one thing -- rather than its members."),
            status(review_pending)).
action_maps(measurement, unit_conversion_by_iteration, multiply_unit_count, compute_product,
            confidence(high),
            evidence("measurement/unit_conversion_by_iteration, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. multiply the operands as numerals."),
            status(review_pending)).
action_maps(measurement, unit_conversion_by_iteration, relabel_as_smaller_unit, name_result,
            confidence(high),
            evidence("measurement/unit_conversion_by_iteration, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. names the multiplied count in the smaller unit, the iteration having done the scaling"),
            status(review_pending)).
action_maps(measurement, unit_preserving_measured_quantity_change, establish_common_measurement_unit, select_unit_scale,
            confidence(high),
            evidence("measurement/unit_preserving_measured_quantity_change, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. choose which unit, base, or scale to work in from among the available ones."),
            status(review_pending)).
action_maps(measurement, unit_preserving_measured_quantity_change, perform_grounded_quantity_change, apply_quantity_change,
            confidence(high),
            evidence("measurement/unit_preserving_measured_quantity_change, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. carries out the change on the measured amount; both machines that use it differ in whether the unit survives the change, not in its direction, and the canonical action is direction-neutral for that reason"),
            status(review_pending)).
action_maps(measurement, unit_preserving_measured_quantity_change, report_unit_bearing_result, name_result,
            confidence(high),
            evidence("measurement/unit_preserving_measured_quantity_change, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. say which quantity the answer is."),
            status(review_pending)).
action_maps(measurement, unit_preserving_measured_quantity_change, retain_measurement_unit, retain_what_must_survive,
            confidence(high),
            evidence("measurement/unit_preserving_measured_quantity_change, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. carries the measurement unit through the quantity change, which is exactly what measurement/drop_unit_from_measured_quantity_change discards at the same position"),
            status(review_pending)).
action_maps(multiplication, add_counts_without_composite_unit, add_uncoordinated_counts, substitute_operation,
            confidence(high),
            evidence("multiplication/add_counts_without_composite_unit, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. adds the two counts where the equal-group structure calls for iterating one over the other"),
            status(review_pending)).
action_maps(multiplication, add_counts_without_composite_unit, count_groups_as_items, substitute_count_for_measure,
            confidence(high),
            evidence("multiplication/add_counts_without_composite_unit, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. counts the groups as though they were items, so the composite unit stops bearing"),
            status(review_pending)).
action_maps(multiplication, add_counts_without_composite_unit, count_items_as_items, count_units,
            confidence(high),
            evidence("multiplication/add_counts_without_composite_unit, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. count how many units the iteration or the partition produced."),
            status(review_pending)).
action_maps(multiplication, add_counts_without_composite_unit, lose_composite_unit, record_loss,
            confidence(high),
            evidence("multiplication/add_counts_without_composite_unit, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(multiplication, add_counts_without_composite_unit, see_groups_and_items, register_givens,
            confidence(high),
            evidence("multiplication/add_counts_without_composite_unit, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(multiplication, add_instead_of_multiply, add_uncoordinated_counts, substitute_operation,
            confidence(high),
            evidence("multiplication/add_instead_of_multiply, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. adds the two counts where the equal-group structure calls for iterating one over the other"),
            status(review_pending)).
action_maps(multiplication, add_instead_of_multiply, lose_equal_group_iteration, record_loss,
            confidence(high),
            evidence("multiplication/add_instead_of_multiply, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(multiplication, add_instead_of_multiply, read_equal_groups, register_givens,
            confidence(high),
            evidence("multiplication/add_instead_of_multiply, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(multiplication, add_instead_of_multiply, treat_group_count_and_group_size_as_addends, conflate_roles,
            confidence(high),
            evidence("multiplication/add_instead_of_multiply, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. collapse two structurally distinct roles into one."),
            status(review_pending)).
action_maps(multiplication, add_numbers_as_common_multiple, add_inputs, combine_quantities,
            confidence(high),
            evidence("multiplication/add_numbers_as_common_multiple, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, witnessed. join two quantities into their sum."),
            status(review_pending)).
action_maps(multiplication, add_numbers_as_common_multiple, omit_divisibility_check, omit_required_step,
            confidence(high),
            evidence("multiplication/add_numbers_as_common_multiple, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, witnessed. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(multiplication, add_numbers_as_common_multiple, read_two_numbers, register_givens,
            confidence(high),
            evidence("multiplication/add_numbers_as_common_multiple, q_start -> q_step_1: 1 of the machine's 4 distinct edges, witnessed. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(multiplication, add_numbers_as_common_multiple, substitute_addition_for_multiple_generation, substitute_operation,
            confidence(high),
            evidence("multiplication/add_numbers_as_common_multiple, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, witnessed. adds the two numbers where a common multiple was to be generated"),
            status(review_pending)).
action_maps(multiplication, common_factor_intersection, enumerate_positive_divisors, enumerate_candidates,
            confidence(high),
            evidence("multiplication/common_factor_intersection, q_start -> q_step_1; q_step_1 -> q_step_2: 2 of the machine's 4 distinct edges, witnessed. generate the candidate set a later step will filter."),
            status(review_pending)).
action_maps(multiplication, common_factor_intersection, intersect_factor_sets, intersect_candidate_sets,
            confidence(high),
            evidence("multiplication/common_factor_intersection, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, witnessed. take what two candidate sets have in common."),
            status(review_pending)).
action_maps(multiplication, common_factor_intersection, select_greatest_common_factor, select_extremal,
            confidence(high),
            evidence("multiplication/common_factor_intersection, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, witnessed. pick the greatest or the least of the candidates."),
            status(review_pending)).
action_maps(multiplication, common_multiple_sequence, coordinate_multiples_of, enumerate_candidates,
            confidence(high),
            evidence("multiplication/common_multiple_sequence, q_start -> q_step_1: 1 of the machine's 4 distinct edges, witnessed. generate the candidate set a later step will filter."),
            status(review_pending)).
action_maps(multiplication, common_multiple_sequence, iterate_common_multiple_generator, iterate_composite_unit,
            confidence(high),
            evidence("multiplication/common_multiple_sequence, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, witnessed. repeat a composite unit -- a group held as one thing -- rather than its members."),
            status(review_pending)).
action_maps(multiplication, common_multiple_sequence, locate_least_common_multiple, select_extremal,
            confidence(high),
            evidence("multiplication/common_multiple_sequence, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, witnessed. pick the greatest or the least of the candidates."),
            status(review_pending)).
action_maps(multiplication, common_multiple_sequence, retain_lcm_as_composite_iteration_unit, select_unit_scale,
            confidence(high),
            evidence("multiplication/common_multiple_sequence, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, witnessed. holds the least common multiple as the composite unit the next edge iterates"),
            status(review_pending)).
action_maps(multiplication, commute_factors_preserve_product, commute_factors, commute_operands,
            confidence(high),
            evidence("multiplication/commute_factors_preserve_product, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, witnessed. reorder the operands."),
            status(review_pending)).
action_maps(multiplication, commute_factors_preserve_product, compare_factor_orders, register_givens,
            confidence(medium),
            evidence("multiplication/commute_factors_preserve_product, q_start -> q_step_1: 1 of the machine's 5 distinct edges, witnessed. holds the two factor orders as the pair whose products the next two edges compute"),
            status(review_pending)).
action_maps(multiplication, commute_factors_preserve_product, compute_commuted_product, compute_product,
            confidence(high),
            evidence("multiplication/commute_factors_preserve_product, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, witnessed. multiply the operands as numerals."),
            status(review_pending)).
action_maps(multiplication, commute_factors_preserve_product, compute_original_product, compute_product,
            confidence(high),
            evidence("multiplication/commute_factors_preserve_product, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, witnessed. multiply the operands as numerals."),
            status(review_pending)).
action_maps(multiplication, commute_factors_preserve_product, preserve_product_under_commutation, record_conservation,
            confidence(high),
            evidence("multiplication/commute_factors_preserve_product, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, witnessed. record that the strategy kept the relation it was obliged to keep."),
            status(review_pending)).
action_maps(multiplication, context_free_fact_family_guess, answer_from_context_free_fact_family, misname_result,
            confidence(medium),
            evidence("multiplication/context_free_fact_family_guess, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. names a product from the fact family that answers no question the context asked"),
            status(review_pending)).
action_maps(multiplication, context_free_fact_family_guess, lose_referent_units, record_loss,
            confidence(high),
            evidence("multiplication/context_free_fact_family_guess, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(multiplication, context_free_fact_family_guess, recognize_target_factor_pair, register_givens,
            confidence(high),
            evidence("multiplication/context_free_fact_family_guess, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(multiplication, context_free_fact_family_guess, retrieve_product_without_referent_units, retrieve_known_fact,
            confidence(medium),
            evidence("multiplication/context_free_fact_family_guess, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. recalls the product; that it arrives without its referent units is recorded at the machine's last edge"),
            status(review_pending)).
action_maps(multiplication, context_free_fact_family_guess, substitute_alternate_factor_pair, substitute_operation,
            confidence(medium),
            evidence("multiplication/context_free_fact_family_guess, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. answers from a different pair in the same fact family, a fact the learner has to hand in place of the one the task names"),
            status(review_pending)).
action_maps(multiplication, coordinate_groups_items, coordinate_group_count_with_item_count, assign_roles,
            confidence(high),
            evidence("multiplication/coordinate_groups_items, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, witnessed. binds the group count and the item count to their two levels before the composite unit is iterated"),
            status(review_pending)).
action_maps(multiplication, coordinate_groups_items, form_equal_groups, replicate_equal_groups,
            confidence(medium),
            evidence("multiplication/coordinate_groups_items, q_start -> q_step_1: 1 of the machine's 4 distinct edges, witnessed. forms the equal-group structure; the coordination of its two levels runs at the next edge"),
            status(review_pending)).
action_maps(multiplication, coordinate_groups_items, iterate_composite_unit, iterate_composite_unit,
            confidence(high),
            evidence("multiplication/coordinate_groups_items, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, witnessed. repeat a composite unit -- a group held as one thing -- rather than its members."),
            status(review_pending)).
action_maps(multiplication, coordinate_groups_items, name_total_items, name_result,
            confidence(high),
            evidence("multiplication/coordinate_groups_items, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, witnessed. say which quantity the answer is."),
            status(review_pending)).
action_maps(multiplication, distribute_group_size_split, compute_partial_product, compute_product,
            confidence(high),
            evidence("multiplication/distribute_group_size_split, q_step_1 -> q_step_2; q_step_2 -> q_step_3: 2 of the machine's 5 distinct edges, witnessed. multiply the operands as numerals."),
            status(review_pending)).
action_maps(multiplication, distribute_group_size_split, preserve_distributed_groups, record_conservation,
            confidence(high),
            evidence("multiplication/distribute_group_size_split, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, witnessed. record that the strategy kept the relation it was obliged to keep."),
            status(review_pending)).
action_maps(multiplication, distribute_group_size_split, recompose_partial_products, recompose_total,
            confidence(high),
            evidence("multiplication/distribute_group_size_split, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, witnessed. put the parts of a decomposition back together into the whole."),
            status(review_pending)).
action_maps(multiplication, distribute_group_size_split, split_group_size, decompose_operand,
            confidence(high),
            evidence("multiplication/distribute_group_size_split, q_start -> q_step_1: 1 of the machine's 5 distinct edges, witnessed. split one operand into pieces a later step can use, not along place boundaries."),
            status(review_pending)).
action_maps(multiplication, drop_regrouping_remainder, drop_regrouping_leftover, halt_before_completion,
            confidence(high),
            evidence("multiplication/drop_regrouping_remainder, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. stop a required traversal, iteration, or recomposition before it finishes."),
            status(review_pending)).
action_maps(multiplication, drop_regrouping_remainder, form_equal_groups, replicate_equal_groups,
            confidence(medium),
            evidence("multiplication/drop_regrouping_remainder, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. forms the equal-group structure; the coordination of its two levels runs at the next edge"),
            status(review_pending)).
action_maps(multiplication, drop_regrouping_remainder, lose_regrouping_remainder, record_loss,
            confidence(high),
            evidence("multiplication/drop_regrouping_remainder, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(multiplication, drop_regrouping_remainder, name_only_full_base_bundles, misname_result,
            confidence(high),
            evidence("multiplication/drop_regrouping_remainder, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. name a value that answers a different question than the one asked."),
            status(review_pending)).
action_maps(multiplication, drop_regrouping_remainder, regroup_total_as_base_bundles, regroup_to_base,
            confidence(high),
            evidence("multiplication/drop_regrouping_remainder, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. trade a completed group of the smaller unit up into one of the larger."),
            status(review_pending)).
action_maps(multiplication, drop_second_partial_product, compute_partial_product, compute_product,
            confidence(high),
            evidence("multiplication/drop_second_partial_product, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. multiply the operands as numerals."),
            status(review_pending)).
action_maps(multiplication, drop_second_partial_product, lose_distributed_part, record_loss,
            confidence(high),
            evidence("multiplication/drop_second_partial_product, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(multiplication, drop_second_partial_product, omit_partial_product, omit_required_step,
            confidence(high),
            evidence("multiplication/drop_second_partial_product, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(multiplication, drop_second_partial_product, split_group_size, decompose_operand,
            confidence(high),
            evidence("multiplication/drop_second_partial_product, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. split one operand into pieces a later step can use, not along place boundaries."),
            status(review_pending)).
action_maps(multiplication, factors_of_first_number_only, enumerate_positive_divisors, enumerate_candidates,
            confidence(high),
            evidence("multiplication/factors_of_first_number_only, q_start -> q_step_1: 1 of the machine's 4 distinct edges, witnessed. generate the candidate set a later step will filter."),
            status(review_pending)).
action_maps(multiplication, factors_of_first_number_only, omit_divisor_search_for, omit_required_step,
            confidence(high),
            evidence("multiplication/factors_of_first_number_only, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, witnessed. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(multiplication, factors_of_first_number_only, omit_factor_set_intersection, omit_required_step,
            confidence(high),
            evidence("multiplication/factors_of_first_number_only, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, witnessed. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(multiplication, factors_of_first_number_only, report_first_factor_set_as_common, misname_result,
            confidence(high),
            evidence("multiplication/factors_of_first_number_only, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, witnessed. name a value that answers a different question than the one asked."),
            status(review_pending)).
action_maps(multiplication, known_product_adjustment, adjust_known_product, combine_quantities,
            confidence(high),
            evidence("multiplication/known_product_adjustment, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. join two quantities into their sum."),
            status(review_pending)).
action_maps(multiplication, known_product_adjustment, compute_extra_equal_group_product, compute_product,
            confidence(high),
            evidence("multiplication/known_product_adjustment, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. multiply the operands as numerals."),
            status(review_pending)).
action_maps(multiplication, known_product_adjustment, identify_missing_equal_groups, read_operand_attribute,
            confidence(high),
            evidence("multiplication/known_product_adjustment, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. reads how many equal groups separate the target from the recalled product"),
            status(review_pending)).
action_maps(multiplication, known_product_adjustment, preserve_equal_group_adjustment, record_conservation,
            confidence(high),
            evidence("multiplication/known_product_adjustment, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. record that the strategy kept the relation it was obliged to keep."),
            status(review_pending)).
action_maps(multiplication, known_product_adjustment, recall_nearby_known_product, retrieve_known_fact,
            confidence(high),
            evidence("multiplication/known_product_adjustment, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. recall a stored fact instead of reconstructing it."),
            status(review_pending)).
action_maps(multiplication, known_product_without_adjustment, answer_with_nearby_product, misname_result,
            confidence(high),
            evidence("multiplication/known_product_without_adjustment, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. name a value that answers a different question than the one asked."),
            status(review_pending)).
action_maps(multiplication, known_product_without_adjustment, identify_missing_equal_groups, read_operand_attribute,
            confidence(high),
            evidence("multiplication/known_product_without_adjustment, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. reads how many equal groups separate the target from the recalled product"),
            status(review_pending)).
action_maps(multiplication, known_product_without_adjustment, lose_equal_group_adjustment, record_loss,
            confidence(high),
            evidence("multiplication/known_product_without_adjustment, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(multiplication, known_product_without_adjustment, omit_extra_equal_group_product, omit_required_step,
            confidence(high),
            evidence("multiplication/known_product_without_adjustment, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(multiplication, known_product_without_adjustment, recall_nearby_known_product, retrieve_known_fact,
            confidence(high),
            evidence("multiplication/known_product_without_adjustment, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. recall a stored fact instead of reconstructing it."),
            status(review_pending)).
action_maps(multiplication, multiplication_fact_retrieval, bind_product_to_factor_pair, assign_roles,
            confidence(high),
            evidence("multiplication/multiplication_fact_retrieval, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, witnessed. binds the retrieved product back to the factor pair it answers, so the product keeps its referent units"),
            status(review_pending)).
action_maps(multiplication, multiplication_fact_retrieval, preserve_referent_units_for_product, record_conservation,
            confidence(high),
            evidence("multiplication/multiplication_fact_retrieval, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, witnessed. record that the strategy kept the relation it was obliged to keep."),
            status(review_pending)).
action_maps(multiplication, multiplication_fact_retrieval, recognize_factor_pair, register_givens,
            confidence(high),
            evidence("multiplication/multiplication_fact_retrieval, q_start -> q_step_1: 1 of the machine's 4 distinct edges, witnessed. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(multiplication, multiplication_fact_retrieval, retrieve_known_multiplication_fact, retrieve_known_fact,
            confidence(high),
            evidence("multiplication/multiplication_fact_retrieval, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, witnessed. recall a stored fact instead of reconstructing it."),
            status(review_pending)).
action_maps(multiplication, regroup_to_base_preserving_total, form_equal_groups, replicate_equal_groups,
            confidence(medium),
            evidence("multiplication/regroup_to_base_preserving_total, q_start -> q_step_1: 1 of the machine's 4 distinct edges, witnessed. forms the equal-group structure; the coordination of its two levels runs at the next edge"),
            status(review_pending)).
action_maps(multiplication, regroup_to_base_preserving_total, name_total_from_bundles_and_leftover, name_result,
            confidence(high),
            evidence("multiplication/regroup_to_base_preserving_total, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, witnessed. say which quantity the answer is."),
            status(review_pending)).
action_maps(multiplication, regroup_to_base_preserving_total, preserve_leftover_after_regrouping, retain_what_must_survive,
            confidence(high),
            evidence("multiplication/regroup_to_base_preserving_total, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, witnessed. carries the leftover forward so that the total can be named from bundles and leftover together; the machine's own name records that the total is what is preserved"),
            status(review_pending)).
action_maps(multiplication, regroup_to_base_preserving_total, regroup_total_as_base_bundles, regroup_to_base,
            confidence(high),
            evidence("multiplication/regroup_to_base_preserving_total, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, witnessed. trade a completed group of the smaller unit up into one of the larger."),
            status(review_pending)).
action_maps(multiplication, repeat_equal_groups, add_equal_group_repeatedly, replicate_equal_groups,
            confidence(high),
            evidence("multiplication/repeat_equal_groups, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, witnessed. build the total as so many groups of so many."),
            status(review_pending)).
action_maps(multiplication, repeat_equal_groups, hold_group_size_as_repeated_addend, assign_roles,
            confidence(high),
            evidence("multiplication/repeat_equal_groups, q_start -> q_step_1: 1 of the machine's 4 distinct edges, witnessed. bind each given to its structural role in the relation: which quantity is the whole and which the part, group count against group size, which term is the repeated factor, which coordinate comes first."),
            status(review_pending)).
action_maps(multiplication, repeat_equal_groups, hold_number_of_groups_as_iterations, assign_roles,
            confidence(high),
            evidence("multiplication/repeat_equal_groups, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, witnessed. bind each given to its structural role in the relation: which quantity is the whole and which the part, group count against group size, which term is the repeated factor, which coordinate comes first."),
            status(review_pending)).
action_maps(multiplication, repeat_equal_groups, name_accumulated_total, name_result,
            confidence(high),
            evidence("multiplication/repeat_equal_groups, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, witnessed. say which quantity the answer is."),
            status(review_pending)).
action_maps(multiplication, repeat_group_size_by_itself, add_equal_group_repeatedly, replicate_equal_groups,
            confidence(high),
            evidence("multiplication/repeat_group_size_by_itself, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, witnessed. build the total as so many groups of so many."),
            status(review_pending)).
action_maps(multiplication, repeat_group_size_by_itself, hold_group_size_as_repeated_addend, assign_roles,
            confidence(high),
            evidence("multiplication/repeat_group_size_by_itself, q_start -> q_step_1: 1 of the machine's 4 distinct edges, witnessed. bind each given to its structural role in the relation: which quantity is the whole and which the part, group count against group size, which term is the repeated factor, which coordinate comes first."),
            status(review_pending)).
action_maps(multiplication, repeat_group_size_by_itself, lose_group_count_role, record_loss,
            confidence(high),
            evidence("multiplication/repeat_group_size_by_itself, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, witnessed. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(multiplication, repeat_group_size_by_itself, use_group_size_as_iteration_count, conflate_roles,
            confidence(high),
            evidence("multiplication/repeat_group_size_by_itself, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, witnessed. collapse two structurally distinct roles into one."),
            status(review_pending)).
action_maps(multiplication, rigid_factor_order_roles, compare_factor_orders, register_givens,
            confidence(medium),
            evidence("multiplication/rigid_factor_order_roles, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. holds the two factor orders as the pair whose products the next two edges compute"),
            status(review_pending)).
action_maps(multiplication, rigid_factor_order_roles, keep_multiplier_multiplicand_roles_fixed, retain_where_change_was_due,
            confidence(high),
            evidence("multiplication/rigid_factor_order_roles, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. holds the multiplier and multiplicand roles where commuting the factors obliged them to swap, which is why the machine then demands a recomputation"),
            status(review_pending)).
action_maps(multiplication, rigid_factor_order_roles, lose_factor_order_equivalence, record_loss,
            confidence(high),
            evidence("multiplication/rigid_factor_order_roles, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(multiplication, rigid_factor_order_roles, reject_commuted_factor_order, treat_relevant_as_irrelevant,
            confidence(medium),
            evidence("multiplication/rigid_factor_order_roles, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. treats the commuted order as not bearing on the product it in fact leaves unchanged"),
            status(review_pending)).
action_maps(multiplication, rigid_factor_order_roles, require_recomputation_in_original_order, omit_required_step,
            confidence(medium),
            evidence("multiplication/rigid_factor_order_roles, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. the shortcut the commutation licenses is never taken, so the product is computed twice"),
            status(review_pending)).
action_maps(multiplication, sequential_recompute_commuted_products, compare_factor_orders, register_givens,
            confidence(medium),
            evidence("multiplication/sequential_recompute_commuted_products, q_start -> q_step_1: 1 of the machine's 6 distinct edges, static only. holds the two factor orders as the pair whose products the next two edges compute"),
            status(review_pending)).
action_maps(multiplication, sequential_recompute_commuted_products, compare_final_products, compare_magnitudes,
            confidence(high),
            evidence("multiplication/sequential_recompute_commuted_products, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, static only. decide the order relation between two quantities."),
            status(review_pending)).
action_maps(multiplication, sequential_recompute_commuted_products, compute_commuted_product, compute_product,
            confidence(high),
            evidence("multiplication/sequential_recompute_commuted_products, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges, static only. multiply the operands as numerals."),
            status(review_pending)).
action_maps(multiplication, sequential_recompute_commuted_products, compute_original_product, compute_product,
            confidence(high),
            evidence("multiplication/sequential_recompute_commuted_products, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges, static only. multiply the operands as numerals."),
            status(review_pending)).
action_maps(multiplication, sequential_recompute_commuted_products, lose_commutative_shortcut, record_loss,
            confidence(high),
            evidence("multiplication/sequential_recompute_commuted_products, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(multiplication, sequential_recompute_commuted_products, miss_structural_commutative_equivalence, omit_required_step,
            confidence(high),
            evidence("multiplication/sequential_recompute_commuted_products, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, static only. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(probability, equiprobable_endpoint_counting, compare_with_weighted_terminal_sum, compare_magnitudes,
            confidence(high),
            evidence("probability/equiprobable_endpoint_counting, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. decide the order relation between two quantities."),
            status(review_pending)).
action_maps(probability, equiprobable_endpoint_counting, count_terminal_endpoints, count_units,
            confidence(high),
            evidence("probability/equiprobable_endpoint_counting, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. count how many units the iteration or the partition produced."),
            status(review_pending)).
action_maps(probability, equiprobable_endpoint_counting, identify_terminal_winners, read_operand_attribute,
            confidence(high),
            evidence("probability/equiprobable_endpoint_counting, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(probability, equiprobable_endpoint_counting, read_terminal_paths, register_givens,
            confidence(high),
            evidence("probability/equiprobable_endpoint_counting, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(probability, equiprobable_endpoint_counting, treat_endpoints_as_equiprobable, substitute_count_for_measure,
            confidence(high),
            evidence("probability/equiprobable_endpoint_counting, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. counts the terminal endpoints where the weighted probability mass was what the split turns on"),
            status(review_pending)).
action_maps(probability, terminal_tree_endpoint_probability_sum, allocate_stake, name_result,
            confidence(high),
            evidence("probability/terminal_tree_endpoint_probability_sum, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. terminal edge; delivers the stake split the summed probabilities determine"),
            status(review_pending)).
action_maps(probability, terminal_tree_endpoint_probability_sum, identify_terminal_winners, read_operand_attribute,
            confidence(high),
            evidence("probability/terminal_tree_endpoint_probability_sum, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(probability, terminal_tree_endpoint_probability_sum, read_terminal_paths, register_givens,
            confidence(high),
            evidence("probability/terminal_tree_endpoint_probability_sum, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(probability, terminal_tree_endpoint_probability_sum, sum_terminal_probabilities, accumulate_total,
            confidence(high),
            evidence("probability/terminal_tree_endpoint_probability_sum, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. add the counted or measured pieces into a running total."),
            status(review_pending)).
action_maps(ratio, additive_extension_of_ratio, add_first_term_increment_to_second_term, combine_quantities,
            confidence(high),
            evidence("ratio/additive_extension_of_ratio, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, witnessed. adds the first term's additive increment onto the second term, which is what makes the extension additive rather than multiplicative"),
            status(review_pending)).
action_maps(ratio, additive_extension_of_ratio, compose_additive_pair, compose_expression,
            confidence(high),
            evidence("ratio/additive_extension_of_ratio, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, witnessed. assemble a symbolic expression, equation, diagram, or summary object out of the roled parts."),
            status(review_pending)).
action_maps(ratio, additive_extension_of_ratio, compute_first_term_increment, remove_quantity,
            confidence(medium),
            evidence("ratio/additive_extension_of_ratio, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, witnessed. finds the increment on the first term as a difference between the given and the base ratio"),
            status(review_pending)).
action_maps(ratio, additive_extension_of_ratio, identify_base_ratio, register_givens,
            confidence(high),
            evidence("ratio/additive_extension_of_ratio, q_start -> q_step_1: 1 of the machine's 5 distinct edges, witnessed. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(ratio, additive_extension_of_ratio, lose_multiplicative_unit_ratio, record_loss,
            confidence(high),
            evidence("ratio/additive_extension_of_ratio, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, witnessed. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(ratio, construct_referent_ratio_diagram, construct_ratio_diagram, compose_expression,
            confidence(high),
            evidence("ratio/construct_referent_ratio_diagram, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. assemble a symbolic expression, equation, diagram, or summary object out of the roled parts."),
            status(review_pending)).
action_maps(ratio, construct_referent_ratio_diagram, coordinate_referent_counts, assign_roles,
            confidence(high),
            evidence("ratio/construct_referent_ratio_diagram, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. bind each given to its structural role in the relation: which quantity is the whole and which the part, group count against group size, which term is the repeated factor, which coordinate comes first."),
            status(review_pending)).
action_maps(ratio, construct_referent_ratio_diagram, establish_first_referent, assign_roles,
            confidence(high),
            evidence("ratio/construct_referent_ratio_diagram, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. bind each given to its structural role in the relation: which quantity is the whole and which the part, group count against group size, which term is the repeated factor, which coordinate comes first."),
            status(review_pending)).
action_maps(ratio, construct_referent_ratio_diagram, establish_second_referent, assign_roles,
            confidence(high),
            evidence("ratio/construct_referent_ratio_diagram, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. bind each given to its structural role in the relation: which quantity is the whole and which the part, group count against group size, which term is the repeated factor, which coordinate comes first."),
            status(review_pending)).
action_maps(ratio, construct_referent_ratio_diagram, inscribe_ordered_ratio, inscribe_result,
            confidence(high),
            evidence("ratio/construct_referent_ratio_diagram, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. write the result in notation."),
            status(review_pending)).
action_maps(ratio, reverse_ratio_referent_order, establish_counts_without_order, register_givens,
            confidence(high),
            evidence("ratio/reverse_ratio_referent_order, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. holds the two counts with neither bound to its referent, which is what the next edge then reverses"),
            status(review_pending)).
action_maps(ratio, reverse_ratio_referent_order, inscribe_reversed_ratio, inscribe_result,
            confidence(high),
            evidence("ratio/reverse_ratio_referent_order, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. write the result in notation."),
            status(review_pending)).
action_maps(ratio, reverse_ratio_referent_order, lose_ordered_referent_relation, record_loss,
            confidence(high),
            evidence("ratio/reverse_ratio_referent_order, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(ratio, reverse_ratio_referent_order, reverse_term_referent_alignment, conflate_roles,
            confidence(high),
            evidence("ratio/reverse_ratio_referent_order, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. swaps which count belongs to which referent, so the ordered pair's two roles no longer hold apart"),
            status(review_pending)).
action_maps(ratio, scale_ratio_unit, compose_equivalent_ratio, compose_expression,
            confidence(high),
            evidence("ratio/scale_ratio_unit, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, witnessed. assemble a symbolic expression, equation, diagram, or summary object out of the roled parts."),
            status(review_pending)).
action_maps(ratio, scale_ratio_unit, identify_base_ratio, register_givens,
            confidence(high),
            evidence("ratio/scale_ratio_unit, q_start -> q_step_1: 1 of the machine's 6 distinct edges, witnessed. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(ratio, scale_ratio_unit, identify_scale_factor, read_operand_attribute,
            confidence(high),
            evidence("ratio/scale_ratio_unit, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, witnessed. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(ratio, scale_ratio_unit, preserve_multiplicative_unit_ratio, record_conservation,
            confidence(high),
            evidence("ratio/scale_ratio_unit, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, witnessed. record that the strategy kept the relation it was obliged to keep."),
            status(review_pending)).
action_maps(ratio, scale_ratio_unit, scale_first_term_multiplicatively, scale_multiplicatively,
            confidence(high),
            evidence("ratio/scale_ratio_unit, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges, witnessed. multiply a quantity or a term by a factor, keeping the multiplicative relation."),
            status(review_pending)).
action_maps(ratio, scale_ratio_unit, scale_second_term_multiplicatively, scale_multiplicatively,
            confidence(high),
            evidence("ratio/scale_ratio_unit, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges, witnessed. multiply a quantity or a term by a factor, keeping the multiplicative relation."),
            status(review_pending)).
action_maps(statistics, box_plot_from_five_number_summary, construct_five_number_summary, compose_expression,
            confidence(medium),
            evidence("statistics/box_plot_from_five_number_summary, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. assembles the five located values into the summary object the plot is drawn from"),
            status(review_pending)).
action_maps(statistics, box_plot_from_five_number_summary, draw_quartile_box_and_whiskers, inscribe_result,
            confidence(high),
            evidence("statistics/box_plot_from_five_number_summary, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. write the result in notation."),
            status(review_pending)).
action_maps(statistics, box_plot_from_five_number_summary, order_values, order_by_magnitude,
            confidence(high),
            evidence("statistics/box_plot_from_five_number_summary, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. put a collection of values in order."),
            status(review_pending)).
action_maps(statistics, box_plot_from_five_number_summary, place_all_five_values_on_common_scale, align_to_common_unit,
            confidence(high),
            evidence("statistics/box_plot_from_five_number_summary, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. bring both quantities into a shared unit, denominator, or decimal scale so they can be measured against each other."),
            status(review_pending)).
action_maps(statistics, box_plot_from_five_number_summary, preserve_data_set, register_givens,
            confidence(high),
            evidence("statistics/box_plot_from_five_number_summary, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. holds the data set as the given the summary steps work from; the label reads as a conservation but the edge is the machine's first, not its last"),
            status(review_pending)).
action_maps(statistics, categorical_frequency_bar_representation, classify_observations_by_category, assign_roles,
            confidence(medium),
            evidence("statistics/categorical_frequency_bar_representation, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. binds each observation to its category before any category is counted"),
            status(review_pending)).
action_maps(statistics, categorical_frequency_bar_representation, count_each_category, count_units,
            confidence(high),
            evidence("statistics/categorical_frequency_bar_representation, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. count how many units the iteration or the partition produced."),
            status(review_pending)).
action_maps(statistics, categorical_frequency_bar_representation, establish_frequency_scale, establish_reference_frame,
            confidence(high),
            evidence("statistics/categorical_frequency_bar_representation, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. set up the frame against which locations or magnitudes will be read: axes, zero as origin, a vertex and initial ray, a value or frequency scale."),
            status(review_pending)).
action_maps(statistics, categorical_frequency_bar_representation, raise_separated_bar_for_each_category, inscribe_result,
            confidence(high),
            evidence("statistics/categorical_frequency_bar_representation, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. write the result in notation."),
            status(review_pending)).
action_maps(statistics, distribution_summary_selection, inspect_declared_profile, read_operand_attribute,
            confidence(high),
            evidence("statistics/distribution_summary_selection, q_step_1 -> q_accept: 1 of the machine's 2 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(statistics, distribution_summary_selection, preserve_data_set, register_givens,
            confidence(high),
            evidence("statistics/distribution_summary_selection, q_start -> q_step_1: 1 of the machine's 2 distinct edges, static only. holds the data set as the given the summary steps work from; the label reads as a conservation but the edge is the machine's first, not its last"),
            status(review_pending)).
action_maps(statistics, dot_plot_frequency_representation, establish_value_axis, establish_reference_frame,
            confidence(high),
            evidence("statistics/dot_plot_frequency_representation, q_start -> q_step_1: 1 of the machine's 3 distinct edges, static only. set up the frame against which locations or magnitudes will be read: axes, zero as origin, a vertex and initial ray, a value or frequency scale."),
            status(review_pending)).
action_maps(statistics, dot_plot_frequency_representation, preserve_one_mark_per_observation, verify_invariant,
            confidence(high),
            evidence("statistics/dot_plot_frequency_representation, q_step_1 -> q_step_2: 1 of the machine's 3 distinct edges, static only. certifies one mark for each observation before the marks are stacked"),
            status(review_pending)).
action_maps(statistics, dot_plot_frequency_representation, stack_marks_at_equal_values, inscribe_result,
            confidence(high),
            evidence("statistics/dot_plot_frequency_representation, q_step_2 -> q_accept: 1 of the machine's 3 distinct edges, static only. write the result in notation."),
            status(review_pending)).
action_maps(statistics, five_number_summary_and_iqr, locate_quartiles, locate_position,
            confidence(high),
            evidence("statistics/five_number_summary_and_iqr, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. locate a value's position in the frame already established."),
            status(review_pending)).
action_maps(statistics, five_number_summary_and_iqr, order_values, order_by_magnitude,
            confidence(high),
            evidence("statistics/five_number_summary_and_iqr, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. put a collection of values in order."),
            status(review_pending)).
action_maps(statistics, five_number_summary_and_iqr, preserve_data_set, register_givens,
            confidence(high),
            evidence("statistics/five_number_summary_and_iqr, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. holds the data set as the given the summary steps work from; the label reads as a conservation but the edge is the machine's first, not its last"),
            status(review_pending)).
action_maps(statistics, five_number_summary_and_iqr, split_around_median, partition_into_equal_parts,
            confidence(high),
            evidence("statistics/five_number_summary_and_iqr, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. splits the ordered values into halves at the median so the quartiles can be located"),
            status(review_pending)).
action_maps(statistics, five_number_summary_and_iqr, subtract_quartiles, remove_quantity,
            confidence(high),
            evidence("statistics/five_number_summary_and_iqr, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. take one quantity away from another."),
            status(review_pending)).
action_maps(statistics, histogram_equal_interval_representation, choose_equal_bin_width, select_unit_scale,
            confidence(high),
            evidence("statistics/histogram_equal_interval_representation, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. choose which unit, base, or scale to work in from among the available ones."),
            status(review_pending)).
action_maps(statistics, histogram_equal_interval_representation, count_each_observation_once, count_units,
            confidence(high),
            evidence("statistics/histogram_equal_interval_representation, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. counts each observation into exactly one bin, which is the check the histogram's contiguity buys"),
            status(review_pending)).
action_maps(statistics, histogram_equal_interval_representation, draw_touching_interval_bars, inscribe_result,
            confidence(high),
            evidence("statistics/histogram_equal_interval_representation, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. write the result in notation."),
            status(review_pending)).
action_maps(statistics, histogram_equal_interval_representation, establish_contiguous_intervals, partition_into_equal_parts,
            confidence(high),
            evidence("statistics/histogram_equal_interval_representation, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. cuts the value range into the contiguous equal bins the counting then fills"),
            status(review_pending)).
action_maps(statistics, histogram_equal_interval_representation, preserve_data_set, register_givens,
            confidence(high),
            evidence("statistics/histogram_equal_interval_representation, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. holds the data set as the given the summary steps work from; the label reads as a conservation but the edge is the machine's first, not its last"),
            status(review_pending)).
action_maps(statistics, mean_absolute_deviation, average_distances, compute_quotient,
            confidence(high),
            evidence("statistics/mean_absolute_deviation, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. divides the accumulated absolute distances by the count of values"),
            status(review_pending)).
action_maps(statistics, mean_absolute_deviation, locate_mean, locate_position,
            confidence(medium),
            evidence("statistics/mean_absolute_deviation, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. locates the mean in the data's own value frame, which is what the deviation steps then measure from"),
            status(review_pending)).
action_maps(statistics, mean_absolute_deviation, measure_signed_deviations, measure_quantity,
            confidence(high),
            evidence("statistics/mean_absolute_deviation, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. measures each value's signed distance from the mean"),
            status(review_pending)).
action_maps(statistics, mean_absolute_deviation, preserve_data_set, register_givens,
            confidence(high),
            evidence("statistics/mean_absolute_deviation, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. holds the data set as the given the summary steps work from; the label reads as a conservation but the edge is the machine's first, not its last"),
            status(review_pending)).
action_maps(statistics, mean_absolute_deviation, take_absolute_distances, apply_stored_rule,
            confidence(medium),
            evidence("statistics/mean_absolute_deviation, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. takes each signed deviation's absolute value before they are averaged, filling the slot mean_deviation_without_absolute_value leaves empty"),
            status(review_pending)).
action_maps(statistics, mean_as_balance_point, locate_mean, locate_position,
            confidence(medium),
            evidence("statistics/mean_as_balance_point, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. locates the mean in the data's own value frame, which is what the deviation steps then measure from"),
            status(review_pending)).
action_maps(statistics, mean_as_balance_point, measure_signed_deviations, measure_quantity,
            confidence(high),
            evidence("statistics/mean_as_balance_point, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. measures each value's signed distance from the mean"),
            status(review_pending)).
action_maps(statistics, mean_as_balance_point, preserve_data_set, register_givens,
            confidence(high),
            evidence("statistics/mean_as_balance_point, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. holds the data set as the given the summary steps work from; the label reads as a conservation but the edge is the machine's first, not its last"),
            status(review_pending)).
action_maps(statistics, mean_as_balance_point, verify_balanced_deviations, verify_invariant,
            confidence(high),
            evidence("statistics/mean_as_balance_point, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. check that the property the strategy must keep still holds."),
            status(review_pending)).
action_maps(statistics, mean_as_fair_share, collect_total, accumulate_total,
            confidence(high),
            evidence("statistics/mean_as_fair_share, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. add the counted or measured pieces into a running total."),
            status(review_pending)).
action_maps(statistics, mean_as_fair_share, count_values, count_units,
            confidence(high),
            evidence("statistics/mean_as_fair_share, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. count how many units the iteration or the partition produced."),
            status(review_pending)).
action_maps(statistics, mean_as_fair_share, preserve_data_set, register_givens,
            confidence(high),
            evidence("statistics/mean_as_fair_share, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. holds the data set as the given the summary steps work from; the label reads as a conservation but the edge is the machine's first, not its last"),
            status(review_pending)).
action_maps(statistics, mean_as_fair_share, redistribute_total_equally, share_into_known_groups,
            confidence(high),
            evidence("statistics/mean_as_fair_share, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. deal the total into a known number of groups to find how much each group holds."),
            status(review_pending)).
action_maps(statistics, mean_deviation_without_absolute_value, average_signed_deviations, compute_quotient,
            confidence(high),
            evidence("statistics/mean_deviation_without_absolute_value, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. divides the accumulated signed deviations by the count, which is why the sum cancels"),
            status(review_pending)).
action_maps(statistics, mean_deviation_without_absolute_value, locate_mean, locate_position,
            confidence(medium),
            evidence("statistics/mean_deviation_without_absolute_value, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. locates the mean in the data's own value frame, which is what the deviation steps then measure from"),
            status(review_pending)).
action_maps(statistics, mean_deviation_without_absolute_value, measure_signed_deviations, measure_quantity,
            confidence(high),
            evidence("statistics/mean_deviation_without_absolute_value, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. measures each value's signed distance from the mean"),
            status(review_pending)).
action_maps(statistics, mean_deviation_without_absolute_value, omit_absolute_value, omit_required_step,
            confidence(high),
            evidence("statistics/mean_deviation_without_absolute_value, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(statistics, median_as_ordered_middle, order_values, order_by_magnitude,
            confidence(high),
            evidence("statistics/median_as_ordered_middle, q_step_1 -> q_accept: 1 of the machine's 2 distinct edges, static only. put a collection of values in order."),
            status(review_pending)).
action_maps(statistics, median_as_ordered_middle, preserve_data_set, register_givens,
            confidence(high),
            evidence("statistics/median_as_ordered_middle, q_start -> q_step_1: 1 of the machine's 2 distinct edges, static only. holds the data set as the given the summary steps work from; the label reads as a conservation but the edge is the machine's first, not its last"),
            status(review_pending)).
action_maps(statistics, mode_as_maximal_frequency, count_equal_values, count_units,
            confidence(high),
            evidence("statistics/mode_as_maximal_frequency, q_step_1 -> q_step_2: 1 of the machine's 3 distinct edges, static only. count how many units the iteration or the partition produced."),
            status(review_pending)).
action_maps(statistics, mode_as_maximal_frequency, preserve_data_set, register_givens,
            confidence(high),
            evidence("statistics/mode_as_maximal_frequency, q_start -> q_step_1: 1 of the machine's 3 distinct edges, static only. holds the data set as the given the summary steps work from; the label reads as a conservation but the edge is the machine's first, not its last"),
            status(review_pending)).
action_maps(statistics, mode_as_maximal_frequency, retain_all_maximal_frequencies, name_result,
            confidence(high),
            evidence("statistics/mode_as_maximal_frequency, q_step_2 -> q_accept: 1 of the machine's 3 distinct edges, static only. the set of maximal-frequency values is what the machine answers with; keeping all of them is the answer, not a filter step"),
            status(review_pending)).
action_maps(statistics, question_without_variability, classify_as_nonstatistical_question, name_result,
            confidence(high),
            evidence("statistics/question_without_variability, q_step_2 -> q_accept: 1 of the machine's 3 distinct edges, static only. say which quantity the answer is."),
            status(review_pending)).
action_maps(statistics, question_without_variability, identify_measured_variable, read_operand_attribute,
            confidence(high),
            evidence("statistics/question_without_variability, q_start -> q_step_1: 1 of the machine's 3 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(statistics, question_without_variability, replace_varied_responses_with_one_fixed_answer, substitute_scalar_for_structured_quantity,
            confidence(high),
            evidence("statistics/question_without_variability, q_step_1 -> q_step_2: 1 of the machine's 3 distinct edges, static only. replaces the expected spread of responses with a single fixed answer, so variability stops bearing on the classification"),
            status(review_pending)).
action_maps(statistics, statistical_question_variability_classification, anticipate_varied_responses, test_criteria,
            confidence(high),
            evidence("statistics/statistical_question_variability_classification, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. tests the variability criterion that decides whether the question is a statistical one"),
            status(review_pending)).
action_maps(statistics, statistical_question_variability_classification, classify_as_statistical_question, name_result,
            confidence(high),
            evidence("statistics/statistical_question_variability_classification, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. say which quantity the answer is."),
            status(review_pending)).
action_maps(statistics, statistical_question_variability_classification, identify_measured_variable, read_operand_attribute,
            confidence(high),
            evidence("statistics/statistical_question_variability_classification, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(statistics, statistical_question_variability_classification, identify_population, register_givens,
            confidence(high),
            evidence("statistics/statistical_question_variability_classification, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. hold the given quantities, figure, or data set as the operands the strategy will work on."),
            status(review_pending)).
action_maps(subtraction, add_instead_of_subtract_column, add_bases_instead_of_subtracting, substitute_operation,
            confidence(high),
            evidence("subtraction/add_instead_of_subtract_column, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, witnessed. adds at the base place where the problem calls for removal"),
            status(review_pending)).
action_maps(subtraction, add_instead_of_subtract_column, add_ones_instead_of_subtracting, substitute_operation,
            confidence(high),
            evidence("subtraction/add_instead_of_subtract_column, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, witnessed. adds at the ones place where the problem calls for removal"),
            status(review_pending)).
action_maps(subtraction, add_instead_of_subtract_column, decompose_numbers, decompose_by_place,
            confidence(high),
            evidence("subtraction/add_instead_of_subtract_column, q_start -> q_step_1: 1 of the machine's 5 distinct edges, witnessed. split a numeral into its base and ones components."),
            status(review_pending)).
action_maps(subtraction, add_instead_of_subtract_column, lose_operation_direction, record_loss,
            confidence(high),
            evidence("subtraction/add_instead_of_subtract_column, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, witnessed. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(subtraction, add_instead_of_subtract_column, recompose_as_sum, recompose_total,
            confidence(high),
            evidence("subtraction/add_instead_of_subtract_column, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, witnessed. put the parts of a decomposition back together into the whole."),
            status(review_pending)).
action_maps(subtraction, answer_as_endpoint_count_up, count_up_by_bases, count_up_to_target,
            confidence(high),
            evidence("subtraction/answer_as_endpoint_count_up, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges, witnessed. count forward until a named target is reached, holding the distance travelled."),
            status(review_pending)).
action_maps(subtraction, answer_as_endpoint_count_up, count_up_by_ones, count_up_to_target,
            confidence(high),
            evidence("subtraction/answer_as_endpoint_count_up, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges, witnessed. count forward until a named target is reached, holding the distance travelled."),
            status(review_pending)).
action_maps(subtraction, answer_as_endpoint_count_up, lose_distance_as_count, record_loss,
            confidence(high),
            evidence("subtraction/answer_as_endpoint_count_up, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, witnessed. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(subtraction, answer_as_endpoint_count_up, name_endpoint_as_answer, misname_result,
            confidence(high),
            evidence("subtraction/answer_as_endpoint_count_up, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, witnessed. name a value that answers a different question than the one asked."),
            status(review_pending)).
action_maps(subtraction, answer_as_endpoint_count_up, start_at_subtrahend, assign_roles,
            confidence(high),
            evidence("subtraction/answer_as_endpoint_count_up, q_start -> q_step_1: 1 of the machine's 6 distinct edges, witnessed. bind each given to its structural role in the relation: which quantity is the whole and which the part, group count against group size, which term is the repeated factor, which coordinate comes first."),
            status(review_pending)).
action_maps(subtraction, answer_as_endpoint_count_up, target_minuend, assign_roles,
            confidence(high),
            evidence("subtraction/answer_as_endpoint_count_up, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, witnessed. bind each given to its structural role in the relation: which quantity is the whole and which the part, group count against group size, which term is the repeated factor, which coordinate comes first."),
            status(review_pending)).
action_maps(subtraction, borrow_across_zero_cascade, borrow_into_ones_after_cascade, exchange_base_down,
            confidence(high),
            evidence("subtraction/borrow_across_zero_cascade, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, static only. the ones column receives its base, closing the cascade"),
            status(review_pending)).
action_maps(subtraction, borrow_across_zero_cascade, cascade_borrow_from_donor_column, exchange_base_down,
            confidence(high),
            evidence("subtraction/borrow_across_zero_cascade, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges, static only. takes one unit from the donor column, the first of the three edges this exchange runs over"),
            status(review_pending)).
action_maps(subtraction, borrow_across_zero_cascade, convert_zero_columns_to_nines, exchange_base_down,
            confidence(high),
            evidence("subtraction/borrow_across_zero_cascade, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges, static only. the intervening zero columns each take a full base as the borrow passes, which is what makes them nines"),
            status(review_pending)).
action_maps(subtraction, borrow_across_zero_cascade, decompose_columns, decompose_by_place,
            confidence(high),
            evidence("subtraction/borrow_across_zero_cascade, q_start -> q_step_1: 1 of the machine's 6 distinct edges, static only. split a numeral into its base and ones components."),
            status(review_pending)).
action_maps(subtraction, borrow_across_zero_cascade, identify_zero_cascade, read_operand_attribute,
            confidence(high),
            evidence("subtraction/borrow_across_zero_cascade, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, static only. reads which columns are zero and which is the nearest nonzero donor"),
            status(review_pending)).
action_maps(subtraction, borrow_across_zero_cascade, subtract_after_zero_cascade, remove_quantity,
            confidence(high),
            evidence("subtraction/borrow_across_zero_cascade, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, static only. take one quantity away from another."),
            status(review_pending)).
action_maps(subtraction, borrow_across_zero_no_cascade, decompose_columns, decompose_by_place,
            confidence(high),
            evidence("subtraction/borrow_across_zero_no_cascade, q_start -> q_step_1: 1 of the machine's 8 distinct edges, static only. split a numeral into its base and ones components."),
            status(review_pending)).
action_maps(subtraction, borrow_across_zero_no_cascade, identify_zero_cascade, read_operand_attribute,
            confidence(high),
            evidence("subtraction/borrow_across_zero_no_cascade, q_step_1 -> q_step_2: 1 of the machine's 8 distinct edges, static only. reads which columns are zero and which is the nearest nonzero donor"),
            status(review_pending)).
action_maps(subtraction, borrow_across_zero_no_cascade, lose_hundreds_borrow, record_loss,
            confidence(high),
            evidence("subtraction/borrow_across_zero_no_cascade, q_step_7 -> q_accept: 1 of the machine's 8 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(subtraction, borrow_across_zero_no_cascade, note_zero_tens_column, read_operand_attribute,
            confidence(high),
            evidence("subtraction/borrow_across_zero_no_cascade, q_step_2 -> q_step_3: 1 of the machine's 8 distinct edges, static only. read one property of a given -- its sign, magnitude, scale, place count, dimension, or labelling -- without yet operating on it."),
            status(review_pending)).
action_maps(subtraction, borrow_across_zero_no_cascade, recompose_without_zero_cascade, recompose_total,
            confidence(high),
            evidence("subtraction/borrow_across_zero_no_cascade, q_step_6 -> q_step_7: 1 of the machine's 8 distinct edges, static only. put the parts of a decomposition back together into the whole."),
            status(review_pending)).
action_maps(subtraction, borrow_across_zero_no_cascade, skip_donor_decrement, omit_required_step,
            confidence(high),
            evidence("subtraction/borrow_across_zero_no_cascade, q_step_5 -> q_step_6: 1 of the machine's 8 distinct edges, static only. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(subtraction, borrow_across_zero_no_cascade, skip_hundreds_decrement, omit_required_step,
            confidence(high),
            evidence("subtraction/borrow_across_zero_no_cascade, q_step_4 -> q_step_5: 1 of the machine's 8 distinct edges, static only. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(subtraction, borrow_across_zero_no_cascade, treat_zero_as_full_base, misread_intermediate_value,
            confidence(high),
            evidence("subtraction/borrow_across_zero_no_cascade, q_step_3 -> q_step_4: 1 of the machine's 8 distinct edges, static only. reads the zero column as though it already held a full base, so no borrow is thought to be needed from it"),
            status(review_pending)).
action_maps(subtraction, borrow_without_reducing_bases, add_base_to_ones_without_removing_base, omit_required_step,
            confidence(high),
            evidence("subtraction/borrow_without_reducing_bases, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges, static only. the ones column receives a base and the base column is never decremented, so the exchange gives without taking"),
            status(review_pending)).
action_maps(subtraction, borrow_without_reducing_bases, decompose_numbers, decompose_by_place,
            confidence(high),
            evidence("subtraction/borrow_without_reducing_bases, q_start -> q_step_1: 1 of the machine's 6 distinct edges, static only. split a numeral into its base and ones components."),
            status(review_pending)).
action_maps(subtraction, borrow_without_reducing_bases, lose_exchange_conservation, record_loss,
            confidence(high),
            evidence("subtraction/borrow_without_reducing_bases, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(subtraction, borrow_without_reducing_bases, recompose_with_unreduced_bases, recompose_total,
            confidence(high),
            evidence("subtraction/borrow_without_reducing_bases, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, static only. put the parts of a decomposition back together into the whole."),
            status(review_pending)).
action_maps(subtraction, borrow_without_reducing_bases, subtract_base_components, remove_quantity,
            confidence(high),
            evidence("subtraction/borrow_without_reducing_bases, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, static only. take one quantity away from another."),
            status(review_pending)).
action_maps(subtraction, borrow_without_reducing_bases, subtract_ones, remove_quantity,
            confidence(high),
            evidence("subtraction/borrow_without_reducing_bases, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges, static only. take one quantity away from another."),
            status(review_pending)).
action_maps(subtraction, compare_by_matching_difference, count_unmatched_as_difference, count_units,
            confidence(high),
            evidence("subtraction/compare_by_matching_difference, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, witnessed. count how many units the iteration or the partition produced."),
            status(review_pending)).
action_maps(subtraction, compare_by_matching_difference, identify_larger_and_smaller, assign_roles,
            confidence(high),
            evidence("subtraction/compare_by_matching_difference, q_start -> q_step_1: 1 of the machine's 5 distinct edges, witnessed. bind each given to its structural role in the relation: which quantity is the whole and which the part, group count against group size, which term is the repeated factor, which coordinate comes first."),
            status(review_pending)).
action_maps(subtraction, compare_by_matching_difference, name_difference_not_larger_total, name_result,
            confidence(high),
            evidence("subtraction/compare_by_matching_difference, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, witnessed. say which quantity the answer is."),
            status(review_pending)).
action_maps(subtraction, compare_by_matching_difference, pair_objects_one_to_one, match_one_to_one,
            confidence(high),
            evidence("subtraction/compare_by_matching_difference, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, witnessed. pair the members of two collections against each other."),
            status(review_pending)).
action_maps(subtraction, compare_by_matching_difference, remove_matched_pairs, remove_quantity,
            confidence(high),
            evidence("subtraction/compare_by_matching_difference, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, witnessed. take one quantity away from another."),
            status(review_pending)).
action_maps(subtraction, compare_returns_larger_count, identify_larger_and_smaller, assign_roles,
            confidence(high),
            evidence("subtraction/compare_returns_larger_count, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. bind each given to its structural role in the relation: which quantity is the whole and which the part, group count against group size, which term is the repeated factor, which coordinate comes first."),
            status(review_pending)).
action_maps(subtraction, compare_returns_larger_count, ignore_matched_pairs, treat_relevant_as_irrelevant,
            confidence(high),
            evidence("subtraction/compare_returns_larger_count, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. treat a relation the result depends on as though it did not bear on the result."),
            status(review_pending)).
action_maps(subtraction, compare_returns_larger_count, lose_surplus_as_unmatched_remainder, record_loss,
            confidence(high),
            evidence("subtraction/compare_returns_larger_count, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(subtraction, compare_returns_larger_count, pair_objects_one_to_one, match_one_to_one,
            confidence(high),
            evidence("subtraction/compare_returns_larger_count, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. pair the members of two collections against each other."),
            status(review_pending)).
action_maps(subtraction, compare_returns_larger_count, report_larger_count_as_difference, misname_result,
            confidence(high),
            evidence("subtraction/compare_returns_larger_count, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. name a value that answers a different question than the one asked."),
            status(review_pending)).
action_maps(subtraction, count_up_missing_addend, count_up_by_bases, count_up_to_target,
            confidence(high),
            evidence("subtraction/count_up_missing_addend, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, witnessed. count forward until a named target is reached, holding the distance travelled."),
            status(review_pending)).
action_maps(subtraction, count_up_missing_addend, count_up_by_ones, count_up_to_target,
            confidence(high),
            evidence("subtraction/count_up_missing_addend, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, witnessed. count forward until a named target is reached, holding the distance travelled."),
            status(review_pending)).
action_maps(subtraction, count_up_missing_addend, name_distance_not_endpoint, name_result,
            confidence(high),
            evidence("subtraction/count_up_missing_addend, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, witnessed. say which quantity the answer is."),
            status(review_pending)).
action_maps(subtraction, count_up_missing_addend, start_at_subtrahend, assign_roles,
            confidence(high),
            evidence("subtraction/count_up_missing_addend, q_start -> q_step_1: 1 of the machine's 5 distinct edges, witnessed. bind each given to its structural role in the relation: which quantity is the whole and which the part, group count against group size, which term is the repeated factor, which coordinate comes first."),
            status(review_pending)).
action_maps(subtraction, count_up_missing_addend, target_minuend, assign_roles,
            confidence(high),
            evidence("subtraction/count_up_missing_addend, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, witnessed. bind each given to its structural role in the relation: which quantity is the whole and which the part, group count against group size, which term is the repeated factor, which coordinate comes first."),
            status(review_pending)).
action_maps(subtraction, decompose_base_for_ones, decompose_numbers, decompose_by_place,
            confidence(high),
            evidence("subtraction/decompose_base_for_ones, q_start -> q_step_1: 1 of the machine's 5 distinct edges, witnessed. split a numeral into its base and ones components."),
            status(review_pending)).
action_maps(subtraction, decompose_base_for_ones, exchange_one_base_for_ones, exchange_base_down,
            confidence(high),
            evidence("subtraction/decompose_base_for_ones, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, witnessed. trade one unit of the larger place for its full complement of the smaller."),
            status(review_pending)).
action_maps(subtraction, decompose_base_for_ones, recompose_difference, recompose_total,
            confidence(high),
            evidence("subtraction/decompose_base_for_ones, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, witnessed. put the parts of a decomposition back together into the whole."),
            status(review_pending)).
action_maps(subtraction, decompose_base_for_ones, subtract_base_components, remove_quantity,
            confidence(high),
            evidence("subtraction/decompose_base_for_ones, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, witnessed. take one quantity away from another."),
            status(review_pending)).
action_maps(subtraction, decompose_base_for_ones, subtract_ones, remove_quantity,
            confidence(high),
            evidence("subtraction/decompose_base_for_ones, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, witnessed. take one quantity away from another."),
            status(review_pending)).
action_maps(subtraction, drop_ones_after_base_takeaway, count_back_by_base_chunk, count_back_from,
            confidence(high),
            evidence("subtraction/drop_ones_after_base_takeaway, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, static only. count backward from the total by a held amount."),
            status(review_pending)).
action_maps(subtraction, drop_ones_after_base_takeaway, decompose_subtrahend, decompose_operand,
            confidence(high),
            evidence("subtraction/drop_ones_after_base_takeaway, q_start -> q_step_1: 1 of the machine's 4 distinct edges, static only. split one operand into pieces a later step can use, not along place boundaries."),
            status(review_pending)).
action_maps(subtraction, drop_ones_after_base_takeaway, drop_ones_chunk, halt_before_completion,
            confidence(high),
            evidence("subtraction/drop_ones_after_base_takeaway, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, static only. stops after the base chunk, leaving the ones chunk of the decomposition unused"),
            status(review_pending)).
action_maps(subtraction, drop_ones_after_base_takeaway, lose_subtracted_remainder, record_loss,
            confidence(high),
            evidence("subtraction/drop_ones_after_base_takeaway, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(subtraction, slide_subtrahend_only, count_slide_amount, count_up_to_target,
            confidence(high),
            evidence("subtraction/slide_subtrahend_only, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. count forward until a named target is reached, holding the distance travelled."),
            status(review_pending)).
action_maps(subtraction, slide_subtrahend_only, identify_subtrahend_target_base, select_unit_scale,
            confidence(high),
            evidence("subtraction/slide_subtrahend_only, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. chooses the base the subtrahend will be slid to"),
            status(review_pending)).
action_maps(subtraction, slide_subtrahend_only, lose_constant_difference, record_loss,
            confidence(high),
            evidence("subtraction/slide_subtrahend_only, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(subtraction, slide_subtrahend_only, slide_subtrahend_without_minuend, omit_required_step,
            confidence(high),
            evidence("subtraction/slide_subtrahend_only, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. slides the subtrahend and not the minuend, so the compensating move on the other operand never runs"),
            status(review_pending)).
action_maps(subtraction, slide_subtrahend_only, subtract_unbalanced_pair, remove_quantity,
            confidence(high),
            evidence("subtraction/slide_subtrahend_only, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. take one quantity away from another."),
            status(review_pending)).
action_maps(subtraction, sliding_constant_difference, count_slide_amount, count_up_to_target,
            confidence(high),
            evidence("subtraction/sliding_constant_difference, q_step_1 -> q_step_2: 1 of the machine's 5 distinct edges, static only. count forward until a named target is reached, holding the distance travelled."),
            status(review_pending)).
action_maps(subtraction, sliding_constant_difference, identify_subtrahend_target_base, select_unit_scale,
            confidence(high),
            evidence("subtraction/sliding_constant_difference, q_start -> q_step_1: 1 of the machine's 5 distinct edges, static only. chooses the base the subtrahend will be slid to"),
            status(review_pending)).
action_maps(subtraction, sliding_constant_difference, preserve_constant_difference, record_conservation,
            confidence(high),
            evidence("subtraction/sliding_constant_difference, q_step_4 -> q_accept: 1 of the machine's 5 distinct edges, static only. record that the strategy kept the relation it was obliged to keep."),
            status(review_pending)).
action_maps(subtraction, sliding_constant_difference, slide_both_numbers, transfer_between_operands,
            confidence(high),
            evidence("subtraction/sliding_constant_difference, q_step_2 -> q_step_3: 1 of the machine's 5 distinct edges, static only. moves both numbers by the same amount, which is what leaves the difference unchanged"),
            status(review_pending)).
action_maps(subtraction, sliding_constant_difference, subtract_adjusted_pair, remove_quantity,
            confidence(high),
            evidence("subtraction/sliding_constant_difference, q_step_3 -> q_step_4: 1 of the machine's 5 distinct edges, static only. take one quantity away from another."),
            status(review_pending)).
action_maps(subtraction, smaller_from_larger_in_column, decompose_numbers, decompose_by_place,
            confidence(high),
            evidence("subtraction/smaller_from_larger_in_column, q_start -> q_step_1: 1 of the machine's 6 distinct edges, witnessed. split a numeral into its base and ones components."),
            status(review_pending)).
action_maps(subtraction, smaller_from_larger_in_column, lose_minuend_subtrahend_roles, record_loss,
            confidence(high),
            evidence("subtraction/smaller_from_larger_in_column, q_step_5 -> q_accept: 1 of the machine's 6 distinct edges, witnessed. record which relation the strategy failed to keep."),
            status(review_pending)).
action_maps(subtraction, smaller_from_larger_in_column, recompose_without_role_preservation, recompose_total,
            confidence(high),
            evidence("subtraction/smaller_from_larger_in_column, q_step_4 -> q_step_5: 1 of the machine's 6 distinct edges, witnessed. reassembles the columns without keeping the minuend and subtrahend roles; the loss is recorded at the next edge"),
            status(review_pending)).
action_maps(subtraction, smaller_from_larger_in_column, skip_borrow_procedure, omit_required_step,
            confidence(high),
            evidence("subtraction/smaller_from_larger_in_column, q_step_1 -> q_step_2: 1 of the machine's 6 distinct edges, witnessed. skip a step the viable strategy needs."),
            status(review_pending)).
action_maps(subtraction, smaller_from_larger_in_column, subtract_smaller_from_larger_in_bases, substitute_operation,
            confidence(high),
            evidence("subtraction/smaller_from_larger_in_column, q_step_3 -> q_step_4: 1 of the machine's 6 distinct edges, witnessed. takes the smaller base digit from the larger regardless of which is minuend, for the same reason"),
            status(review_pending)).
action_maps(subtraction, smaller_from_larger_in_column, subtract_smaller_from_larger_in_ones, substitute_operation,
            confidence(high),
            evidence("subtraction/smaller_from_larger_in_column, q_step_2 -> q_step_3: 1 of the machine's 6 distinct edges, witnessed. takes the smaller ones digit from the larger regardless of which is minuend, an order-free difference in place of the positional one"),
            status(review_pending)).
action_maps(subtraction, take_away_base_ones, count_back_by_base_chunk, count_back_from,
            confidence(high),
            evidence("subtraction/take_away_base_ones, q_step_1 -> q_step_2: 1 of the machine's 4 distinct edges, witnessed. count backward from the total by a held amount."),
            status(review_pending)).
action_maps(subtraction, take_away_base_ones, count_back_by_ones, count_back_from,
            confidence(high),
            evidence("subtraction/take_away_base_ones, q_step_2 -> q_step_3: 1 of the machine's 4 distinct edges, witnessed. count backward from the total by a held amount."),
            status(review_pending)).
action_maps(subtraction, take_away_base_ones, decompose_subtrahend, decompose_operand,
            confidence(high),
            evidence("subtraction/take_away_base_ones, q_start -> q_step_1: 1 of the machine's 4 distinct edges, witnessed. split one operand into pieces a later step can use, not along place boundaries."),
            status(review_pending)).
action_maps(subtraction, take_away_base_ones, preserve_all_subtracted_parts, record_conservation,
            confidence(high),
            evidence("subtraction/take_away_base_ones, q_step_3 -> q_accept: 1 of the machine's 4 distinct edges, witnessed. record that the strategy kept the relation it was obliged to keep."),
            status(review_pending)).

% action_unmapped(Family, Signature, LocalLabel, reason(Text)) -- a label the
% alphabet declines to cover. An honest remainder is a finding: it names a
% doing the alphabet has no canonical action for, and says so rather than
% forcing the nearest fit.
