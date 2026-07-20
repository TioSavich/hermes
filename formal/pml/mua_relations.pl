/** <module> Meaning-Use Relations (MUA) for action automata
 *
 * Brandom's *Between Saying and Doing* distinguishes several relations
 * between practices-or-abilities (P) and vocabularies (V):
 *
 *   - PP-sufficient(P1, P2): mastering P1 is sufficient for P2.
 *   - PP-necessary(P1, P2): P1 must be in place for P2 to be deployed.
 *   - PV-sufficient(P, V):  deploying P is sufficient to deploy V.
 *   - VP-sufficient(V, P):  V is sufficient to specify P.
 *   - VV-relation(V1, V2):  relations between vocabularies.
 *   - LX(V_meta, V_base, Principle): V_meta is *elaborated-explicating* for V_base.
 *     The practices that deploy V_meta both elaborate the practices that
 *     deploy V_base (PP-sufficiency) *and* make explicit -- as expressible
 *     content in V_meta -- the inferential commitments that are merely
 *     implicit in the practices of V_base.
 *
 * This module exposes those relations as first-class Prolog facts so the
 * action-automata registry's productive/deformation pairs can be queried
 * not only as PP-relations (the existing productive/deformation surface)
 * but also as PV/VP/LX relations. Two consequences:
 *
 *   1. The deformation `cross_multiplication_rule_without_ground` is
 *      not merely a wrong-answer move; it is the practice of deploying
 *      the cross-multiplication vocabulary *without* the LX-elaboration
 *      that would make its inferential commitments explicit. The
 *      productive `cross_multiplication_rule_from_pattern` IS that
 *      LX-elaboration: it preserves the area-model justification while
 *      executing the rule.
 *
 *   2. The auto_tentative DB bindings can be triaged by MUA-coherence:
 *      a row whose vocabulary overlaps the practice it is bound to, and
 *      whose neighbors deploy vocabularies in the same LX-chain, is more
 *      likely a true binding than one that scores high on a few stray
 *      phrases without supporting MUA structure.
 *
 * Seeded from:
 *   - The action-automata registry's `action_automaton_cluster/3` and
 *     `action_automaton_vocabulary/3` (practice and vocabulary names).
 *   - LK_RB_Synthesis `data/strategy_metadata.json` (curated PP/LX names).
 *   - Lakoff & Núñez grounding metaphors (`Metaphor_Knowledge_Base.md`).
 *
 * Forward-compatible: as new automata land, asserting more `lx_for/3`,
 * `pp_necessary/2`, and `grounding_metaphor/2` facts here lets the
 * triage tool and the dashboard reason about them without changing the
 * mapper code.
 */

:- module(mua_relations,
          [ practice/2,
            vocabulary/2,
            practice_kind/3,
            practice_predicate/2,
            pv_sufficient/2,
            vp_sufficient/2,
            pp_necessary/2,
            pp_sufficient/3,
            lx_for/3,
            grounding_metaphor/2,
            metaphor_breaks_at/2,
            kind_vocabulary_terms/2,
            kind_mua_coherence_witness/4,
            kind_mua_coherence/3
          ]).

:- use_module(formalization(grounding_metaphors),
              [ grounding_metaphor_definition/4,
                metaphor_target_practice/2,
                metaphor_breaks_at/3,
                metaphor_repair/4
              ]).


%% ----------------------------------------------------------------------
%% Vocabularies
%%
%% Each vocabulary is a named set of terms used to specify some
%% practice. Vocabularies are derived from
%% `action_automaton_vocabulary/3` in the registry; this layer gives
%% them MUA-relevant names and descriptions.

%!  vocabulary(?Vocabulary, ?Description) is nondet.
vocabulary(v_counting,
           "Counting words and the count-from-one practice. Source domain vocabulary for the Object-Collection metaphor.").
vocabulary(v_counting_on,
           "The Counting-On vocabulary: start at the larger addend and count the smaller. Implicit associativity but no explicit decomposition.").
vocabulary(v_make_base_transfer,
           "Compensation / making-a-base vocabulary. Names the base, the decomposition, the transfer, and the conservation of total.").
vocabulary(v_direct_modeling,
           "Direct base-ten modeling vocabulary: physical units, base rods, exchanges between adjacent place values, and represented quantity.").
vocabulary(v_explicit_trade,
           "Explicit-trade vocabulary: written place-value columns, crossed-out units, decomposed pieces, and inverse exchanges between adjacent places.").
vocabulary(v_column_algorithm,
           "Place-value column-algorithm vocabulary. Names columns, carries, regroupings, place-values.").
vocabulary(v_fraction_unit,
           "Fraction-as-unit vocabulary. Names the referent whole, equal partitions, the unit fraction, and iteration of the unit.").
vocabulary(v_area_model,
           "Area-model vocabulary for fraction multiplication. Names the unit square, side-partitions, sub-rectangles, and selected area as part-of-part.").
vocabulary(v_cross_multiplication_rule,
           "The rule (a/b) * (c/d) = (a*c)/(b*d) as a pure pattern. Names numerators, denominators, and the multiply-across operation. Without a kernel justification this vocabulary is held without an LX-elaboration.").
vocabulary(v_decimal_positional,
           "Decimal-positional notation: whole part, fractional part, place-unit, decimal point.").
vocabulary(v_decimal_multiplication_rule,
           "The decimal-multiplication rule: multiply digits as integers, place the decimal by summing fractional-place counts.").
vocabulary(v_inverse_multiplication,
           "Validation by inverse multiplication: the divisor times a proposed quotient must not exceed the dividend.").
vocabulary(v_distributive_decomposition,
           "Validation by distributive decomposition: a product is validated by summing partial products over an additive decomposition of one factor.").
vocabulary(v_bijective_counting,
           "Bijective counting and the five counting principles: one-to-one correspondence, stable order, cardinal, abstraction, order-irrelevance.").
vocabulary(v_area_justification,
           "Area-model justification vocabulary: re-grounds a procedural fraction rule by deriving its output from the area-model kernel and comparing.").
vocabulary(v_error_magnitude_comparison,
           "Comparison-of-rounding-errors vocabulary: names what each candidate estimate omits and selects the estimate whose omission has the smaller magnitude.").
vocabulary(v_function_limit,
           "Function-limit vocabulary: substitution at a continuous point, factor-cancel reduction, tail bound.").
vocabulary(v_sequence_convergence,
           "Sequence-convergence vocabulary: bounded numerator, diverging denominator, epsilon-N tail bound.").
vocabulary(v_algebraic_expression,
           "Algebraic-expression vocabulary: variables, literals, operators, assignments, sub-expressions, evaluation.").
vocabulary(v_relational_equals_balance,
           "Relational-equals balance vocabulary: equation sides as equal quantities and same-operation moves that preserve equality.").
vocabulary(v_signed_addition_with_sign_relation,
           "Signed-addition vocabulary that coordinates magnitudes by the sign relation between addends.").
vocabulary(v_ratio_scaling,
           "Multiplicative ratio scaling: scale factor preserves the unit ratio across both terms.").
vocabulary(v_hermes_event_scoring,
           "Hermes event-scoring vocabulary: lifts runtime-event commitments, entitlements, and question candidates.").
vocabulary(v_deontic_scorekeeper,
           "Deontic status scoreboard: tracks commitments, entitlements, and incoherences per agent.").


%% ----------------------------------------------------------------------
%% Practices
%%
%% Each action-automaton kind is a practice. The third argument records
%% the registry coordinates so other modules can look up the executable
%% kernel.

%!  practice(?Practice, ?Description) is nondet.
practice(p_count_on_from_larger,
         "Counting-On from the larger addend: a strategy that says nothing explicit about commutativity but presupposes it.").
practice(p_make_ten_split_leftover,
         "Make-Ten and split the leftover. PP-sufficient for the base-bridging move.").
practice(p_make_base_transfer,
         "Compensation/Make-A-Base transfer. Productive partner of the unbalanced compensation deformation.").
practice(p_base_ones_chunking,
         "Decompose and recombine by base-and-ones place value.").
practice(p_round_then_adjust,
         "Round to a base, then adjust by the rounding amount.").
practice(p_column_addition_with_carrying,
         "Column-by-column addition with carrying. LX-elaboration of base-ones chunking with explicit carry vocabulary.").
practice(p_decompose_base_for_ones,
         "Borrow / decompose a base into smaller units for subtraction.").
practice(p_explicit_trade_method,
         "Written explicit-trade method: records a base-ten exchange in place-value columns before the standard subtraction algorithm.").
practice(p_unit_fraction_partition,
         "Partition a referent whole into equal units and select one.").
practice(p_unit_fraction_iteration,
         "Iterate a unit fraction to produce m/n. May extend beyond the whole.").
practice(p_area_model_part_of_part,
         "Partition the unit square into B vertical strips, take A; partition each into D horizontal slices, take C. Names the part-of-part.").
practice(p_unit_fraction_denominator_product_rule,
         "Grounds (a/b)*(c/d) in unit-fraction logic: 1/b partitioned into d gives 1/(b*d); iterate a*c times.").
practice(p_cross_multiplication_rule_from_pattern,
         "Productive cross-multiplication: executes the rule AND carries an area-model justification. LX-elaboration of the area-model practice.").
practice(p_cross_multiplication_rule_without_ground,
         "Deformation: the cross-multiplication rule held without the area-model justification. Procedurally correct, inferentially hollow.").
practice(p_decimal_multiplication_rule,
         "Multiply digits as integers, place decimal by summing place counts. LX for decimal-positional notation.").
practice(p_ecuadorian_decimal_long_division,
         "Scale both operands by a power of ten, divide as integers.").
practice(p_recalled_result_scaling,
         "Recall a base division fact and scale the quotient by a power of ten.").
practice(p_multiplicative_bound_invalidation,
         "Diagnostic validation by inverse multiplication: reject the candidate quotient when divisor * proposed exceeds dividend.").
practice(p_decomposed_divisor_product,
         "Diagnostic validation by distributive decomposition: validate a product by summing partial products.").
practice(p_small_area_justification,
         "Diagnostic justification: re-ground a procedural fraction rule by invoking the area-model kernel on the same inputs.").
practice(p_rigorous_counting_procedure,
         "Diagnostic cardinality: establish a collection's cardinal by bijective counting under the five counting principles.").
practice(p_error_magnitude_estimate_comparison,
         "Diagnostic validation across two candidate estimates: compare their omitted partial products and select the smaller-omission estimate.").
practice(p_direct_substitution,
         "Limit of a continuous function at a point by substitution.").
practice(p_factor_cancel_substitute,
         "Limit at a removable discontinuity by factoring, cancelling the common factor, then substituting.").
practice(p_factor_cancel_without_common_factor,
         "Deformation: applying factor-cancel-substitute when there is no common factor. Rule-without-its-precondition.").
practice(p_bounded_numerator_over_diverging_denominator,
         "Sequence convergence: bounded numerator over diverging denominator goes to zero via epsilon-N tail bound.").
practice(p_programming_expression_evaluation,
         "Walk an algebraic expression as a program: substitute variables, evaluate sub-expressions, combine via arithmetic primitives.").
practice(p_relational_equals_balance_preservation,
         "Relational-equals solving: treat an equation as a balance and preserve equality by making the same move to both sides.").
practice(p_signed_addition_with_sign_relation,
         "Productive signed addition that coordinates magnitude via the sign relation between addends.").
practice(p_scale_ratio_unit,
         "Productive proportional reasoning: multiplicative scaling of both ratio terms preserves the unit ratio.").
practice(p_hermes_event_scoring,
         "Hermes runtime event-scoring: lift commitments, entitlements, and question candidates from a runtime discourse event. Its executable lives in the Hermes scoring surface, not the action-automata registry.").
practice(p_deontic_scorekeeping,
         "Deontic scorekeeping: inspect an agent's commitments, entitlements, and incoherences through the learner scorekeeper runtime surface. This is the executable practice behind the deontic-scorekeeper vocabulary.").

%!  practice_kind(?Practice, ?Operation, ?Kind) is nondet.
%
%   Map an MUA practice id to the registry coordinates so consumers can
%   call `run_action_automaton(Operation, Kind, ...)`.
practice_kind(p_count_on_from_larger, addition, count_on_from_larger).
practice_kind(p_make_ten_split_leftover, addition, make_ten_split_leftover).
practice_kind(p_make_base_transfer, addition, make_base_transfer).
practice_kind(p_base_ones_chunking, addition, base_ones_chunking).
practice_kind(p_round_then_adjust, addition, round_then_adjust).
practice_kind(p_column_addition_with_carrying, addition, column_addition_with_carrying).
practice_kind(p_decompose_base_for_ones, subtraction, decompose_base_for_ones).
practice_kind(p_explicit_trade_method, subtraction, decompose_base_for_ones).
practice_kind(p_unit_fraction_partition, fraction, unit_fraction_partition).
practice_kind(p_unit_fraction_iteration, fraction, unit_fraction_iteration).
practice_kind(p_area_model_part_of_part, fraction, area_model_part_of_part).
practice_kind(p_unit_fraction_denominator_product_rule, fraction, unit_fraction_denominator_product_rule).
practice_kind(p_cross_multiplication_rule_from_pattern, fraction, cross_multiplication_rule_from_pattern).
practice_kind(p_cross_multiplication_rule_without_ground, fraction, cross_multiplication_rule_without_ground).
practice_kind(p_decimal_multiplication_rule, decimal, decimal_multiplication_rule).
practice_kind(p_ecuadorian_decimal_long_division, decimal, ecuadorian_decimal_long_division).
practice_kind(p_recalled_result_scaling, decimal, recalled_result_scaling).
practice_kind(p_multiplicative_bound_invalidation, diagnostic, multiplicative_bound_invalidation).
practice_kind(p_decomposed_divisor_product, diagnostic, decomposed_divisor_product).
practice_kind(p_small_area_justification, diagnostic, small_area_justification).
practice_kind(p_rigorous_counting_procedure, diagnostic, rigorous_counting_procedure).
practice_kind(p_error_magnitude_estimate_comparison, diagnostic, error_magnitude_estimate_comparison).
practice_kind(p_direct_substitution, calculus, direct_substitution).
practice_kind(p_factor_cancel_substitute, calculus, factor_cancel_substitute).
practice_kind(p_factor_cancel_without_common_factor, calculus, factor_cancel_without_common_factor).
practice_kind(p_bounded_numerator_over_diverging_denominator, calculus, bounded_numerator_over_diverging_denominator).
practice_kind(p_programming_expression_evaluation, algebraic, programming_expression_evaluation).
practice_kind(p_signed_addition_with_sign_relation, integer, signed_addition_with_sign_relation).
practice_kind(p_scale_ratio_unit, ratio, scale_ratio_unit).


%!  practice_predicate(?Practice, ?Module:Name/Arity) is nondet.
%
%   For practices whose executable kernel lives OUTSIDE the action-automata
%   registry (so practice_kind/3 + run_action_automaton does not reach them) —
%   e.g. runtime discourse scoring. Lets the codebook-health guard demonstrate
%   them against their real surface instead of flagging a false gap.
practice_predicate(p_hermes_event_scoring, hermes_event_scoring:score_event/2).
practice_predicate(p_deontic_scorekeeping, deontic_scorekeeper:scorecard/2).
practice_predicate(p_relational_equals_balance_preservation,
                   balance_scale_scene:balance_solve_witness/4).


%% ----------------------------------------------------------------------
%% PV-sufficiency: practice deploys vocabulary

%!  pv_sufficient(?Practice, ?Vocabulary) is nondet.
%
%   Deploying the practice is sufficient to deploy the vocabulary -- the
%   practice picks the vocabulary terms out.
pv_sufficient(p_count_on_from_larger,                       v_counting_on).
pv_sufficient(p_make_base_transfer,                         v_make_base_transfer).
pv_sufficient(p_decompose_base_for_ones,                    v_direct_modeling).
pv_sufficient(p_explicit_trade_method,                      v_explicit_trade).
pv_sufficient(p_column_addition_with_carrying,              v_column_algorithm).
pv_sufficient(p_unit_fraction_partition,                    v_fraction_unit).
pv_sufficient(p_unit_fraction_iteration,                    v_fraction_unit).
pv_sufficient(p_area_model_part_of_part,                    v_area_model).
pv_sufficient(p_unit_fraction_denominator_product_rule,     v_fraction_unit).
pv_sufficient(p_cross_multiplication_rule_from_pattern,     v_cross_multiplication_rule).
pv_sufficient(p_cross_multiplication_rule_from_pattern,     v_area_model).
pv_sufficient(p_cross_multiplication_rule_without_ground,   v_cross_multiplication_rule).
pv_sufficient(p_decimal_multiplication_rule,                v_decimal_multiplication_rule).
pv_sufficient(p_ecuadorian_decimal_long_division,           v_decimal_positional).
pv_sufficient(p_multiplicative_bound_invalidation,          v_inverse_multiplication).
pv_sufficient(p_decomposed_divisor_product,                 v_distributive_decomposition).
pv_sufficient(p_rigorous_counting_procedure,                v_bijective_counting).
pv_sufficient(p_small_area_justification,                   v_area_justification).
pv_sufficient(p_error_magnitude_estimate_comparison,        v_error_magnitude_comparison).
pv_sufficient(p_direct_substitution,                        v_function_limit).
pv_sufficient(p_factor_cancel_substitute,                   v_function_limit).
pv_sufficient(p_bounded_numerator_over_diverging_denominator, v_sequence_convergence).
pv_sufficient(p_programming_expression_evaluation,          v_algebraic_expression).
pv_sufficient(p_relational_equals_balance_preservation,     v_relational_equals_balance).
pv_sufficient(p_signed_addition_with_sign_relation,         v_signed_addition_with_sign_relation).
pv_sufficient(p_scale_ratio_unit,                           v_ratio_scaling).
pv_sufficient(p_hermes_event_scoring,                       v_hermes_event_scoring).
pv_sufficient(p_deontic_scorekeeping,                       v_deontic_scorekeeper).


%% ----------------------------------------------------------------------
%% VP-sufficiency: vocabulary specifies practice
%%
%% A vocabulary V is VP-sufficient for practice P when knowing V is
%% enough to characterise what P does without performing it.

vp_sufficient(v_area_model,                                p_area_model_part_of_part).
vp_sufficient(v_cross_multiplication_rule,                 p_cross_multiplication_rule_from_pattern).
vp_sufficient(v_inverse_multiplication,                    p_multiplicative_bound_invalidation).
vp_sufficient(v_distributive_decomposition,                p_decomposed_divisor_product).
vp_sufficient(v_decimal_positional,                        p_decimal_multiplication_rule).
vp_sufficient(v_decimal_multiplication_rule,               p_decimal_multiplication_rule).
vp_sufficient(v_bijective_counting,                        p_rigorous_counting_procedure).
vp_sufficient(v_relational_equals_balance,                 p_relational_equals_balance_preservation).


%% ----------------------------------------------------------------------
%% PP-necessity / PP-sufficiency
%%
%% Curated from LK_RB_Synthesis `data/strategy_metadata.json` and from
%% the existing automaton elaboration graph.

%!  pp_necessary(?BasePractice, ?ElaboratedPractice) is nondet.
pp_necessary(p_count_on_from_larger,            p_make_base_transfer).
pp_necessary(p_count_on_from_larger,            p_make_ten_split_leftover).
pp_necessary(p_make_ten_split_leftover,         p_make_base_transfer).
pp_necessary(p_unit_fraction_partition,         p_unit_fraction_iteration).
pp_necessary(p_unit_fraction_iteration,         p_area_model_part_of_part).
pp_necessary(p_area_model_part_of_part,         p_unit_fraction_denominator_product_rule).
pp_necessary(p_area_model_part_of_part,         p_cross_multiplication_rule_from_pattern).
pp_necessary(p_decompose_base_for_ones,         p_column_addition_with_carrying).
pp_necessary(p_signed_addition_with_sign_relation, p_decimal_multiplication_rule).
pp_necessary(p_direct_substitution,             p_factor_cancel_substitute).


%!  pp_sufficient(?BasePractice, ?ElaboratedPractice, ?Mechanism) is nondet.
%
%   Mastering BasePractice is PP-sufficient for ElaboratedPractice via
%   the named Mechanism.
pp_sufficient(p_count_on_from_larger,
              p_make_base_transfer,
              algorithmic_elaboration_decomposition_and_transfer).
pp_sufficient(p_base_ones_chunking,
              p_column_addition_with_carrying,
              algorithmic_elaboration_explicit_carry_vocabulary).
pp_sufficient(p_unit_fraction_iteration,
              p_area_model_part_of_part,
              metaphor_lifting_object_construction).
pp_sufficient(p_area_model_part_of_part,
              p_cross_multiplication_rule_from_pattern,
              rule_extraction_from_invariant_in_the_model).
pp_sufficient(p_decompose_base_for_ones,
              p_column_addition_with_carrying,
              symmetric_grounding_for_inverse_operations).
pp_sufficient(p_decompose_base_for_ones,
              p_explicit_trade_method,
              written_record_of_inverse_place_value_exchange).
pp_sufficient(p_direct_substitution,
              p_factor_cancel_substitute,
              extension_to_removable_discontinuities).


%% ----------------------------------------------------------------------
%% LX relations
%%
%% lx_for(V_meta, V_base, Principle): the practices that deploy V_meta
%% are PP-sufficient to elaborate the practices that deploy V_base
%% (algorithmic elaboration), and V_meta makes explicit -- as expressible
%% content -- the Principle that was merely implicit in the practices of
%% V_base. The seed set here records the LX-elaborations the registry
%% already supports; the dashboard and triage tool query this graph.

%!  lx_for(?MetaVocabulary, ?BaseVocabulary, ?Principle) is nondet.
lx_for(v_make_base_transfer,
       v_counting_on,
       makes_explicit(associativity_decomposition_and_base_bridging)).
lx_for(v_explicit_trade,
       v_direct_modeling,
       makes_explicit(positional_decomposition_as_inverse_exchange)).
lx_for(v_column_algorithm,
       v_make_base_transfer,
       makes_explicit(positional_place_value_carry_propagation)).
lx_for(v_area_model,
       v_fraction_unit,
       makes_explicit(part_of_part_as_iterated_partition)).
lx_for(v_cross_multiplication_rule,
       v_area_model,
       makes_explicit(numerator_and_denominator_product_invariance)).
lx_for(v_decimal_multiplication_rule,
       v_decimal_positional,
       makes_explicit(place_count_summation_rule_for_decimal_products)).
lx_for(v_inverse_multiplication,
       v_counting_on,
       makes_explicit(division_quotient_validation_against_dividend_bound)).
lx_for(v_distributive_decomposition,
       v_make_base_transfer,
       makes_explicit(distributivity_of_multiplication_over_addition)).
lx_for(v_area_justification,
       v_cross_multiplication_rule,
       makes_explicit(rule_groundedness_against_the_area_model)).
lx_for(v_error_magnitude_comparison,
       v_counting_on,
       makes_explicit(rounded_estimate_error_as_omitted_partial_product)).
lx_for(v_function_limit,
       v_algebraic_expression,
       makes_explicit(continuity_and_removable_discontinuity_at_a_point)).
lx_for(v_sequence_convergence,
       v_counting_on,
       makes_explicit(epsilon_N_tail_bound_for_eventual_behaviour)).
lx_for(v_hermes_event_scoring,
       v_deontic_scorekeeper,
       makes_explicit(runtime_event_deontics)).


%% ----------------------------------------------------------------------
%% Grounding metaphors (Lakoff & Núñez)
%%
%% Each practice is grounded in one or more of the four arithmetic
%% grounding metaphors (Object Collection, Object Construction,
%% Measuring Stick, Motion Along a Path) plus geometry-side metaphors
%% where applicable. Sourced from `Metaphor_Knowledge_Base.md` and from
%% the L&N strategy mapping.

%!  grounding_metaphor(?Practice, ?Metaphor) is nondet.
grounding_metaphor(p_count_on_from_larger,                      motion_along_path).
grounding_metaphor(p_count_on_from_larger,                      object_collection).
grounding_metaphor(p_make_ten_split_leftover,                   object_construction).
grounding_metaphor(p_make_base_transfer,                        object_construction).
grounding_metaphor(p_base_ones_chunking,                        object_construction).
grounding_metaphor(p_round_then_adjust,                         motion_along_path).
grounding_metaphor(p_column_addition_with_carrying,             object_construction).
grounding_metaphor(p_decompose_base_for_ones,                   object_construction).
grounding_metaphor(p_unit_fraction_partition,                   object_construction).
grounding_metaphor(p_unit_fraction_iteration,                   object_collection).
grounding_metaphor(p_unit_fraction_iteration,                   measuring_stick).
grounding_metaphor(p_area_model_part_of_part,                   object_construction).
grounding_metaphor(p_unit_fraction_denominator_product_rule,    object_construction).
grounding_metaphor(p_cross_multiplication_rule_from_pattern,    object_construction).
grounding_metaphor(p_cross_multiplication_rule_without_ground,  no_metaphor_grounding).
grounding_metaphor(p_decimal_multiplication_rule,               measuring_stick).
grounding_metaphor(p_ecuadorian_decimal_long_division,          measuring_stick).
grounding_metaphor(p_signed_addition_with_sign_relation,        motion_along_path).
grounding_metaphor(p_scale_ratio_unit,                          measuring_stick).
grounding_metaphor(p_bounded_numerator_over_diverging_denominator, motion_along_path).
grounding_metaphor(p_programming_expression_evaluation,         object_collection).
grounding_metaphor(p_relational_equals_balance_preservation,    balance_preservation_schema).
grounding_metaphor(p_rigorous_counting_procedure,               object_collection).


%!  metaphor_breaks_at(?Metaphor, ?Inference) is nondet.
%
%   L&N record where each grounding metaphor *fails* to support an
%   inference its target domain nevertheless validates. The break points
%   are precisely the places where an LX-elaboration must add explicit
%   structure to fix what the metaphor leaves out.
metaphor_breaks_at(object_collection,    subtraction_of_larger_from_smaller).
metaphor_breaks_at(object_collection,    fractions_of_a_unit).
metaphor_breaks_at(object_collection,    irrational_numbers).
metaphor_breaks_at(object_construction,  zero_as_an_object).
metaphor_breaks_at(object_construction,  irrational_numbers).
metaphor_breaks_at(measuring_stick,      negative_numbers).
metaphor_breaks_at(measuring_stick,      product_of_two_negative_quantities).
metaphor_breaks_at(motion_along_path,    product_of_two_negative_steps).
metaphor_breaks_at(motion_along_path,    irrationals_without_completeness).


%% ----------------------------------------------------------------------
%% Triage helpers
%%
%% These predicates expose enough structure for the auto_tentative
%% triage tool to score a candidate binding.

:- use_module(math(action_automata_registry)).


%!  kind_vocabulary_terms(?Kind, -Terms) is det.
%
%   Returns the vocabulary terms attached to a registry kind. Combines:
%
%     1. Terms registered directly in the action-automata registry via
%        `action_automaton_vocabulary/3` (across every operation). This
%        covers every productive and deformation kind authoritatively
%        without requiring a parallel MUA `practice_kind/3` fact per kind.
%     2. Terms attached via the MUA `pv_sufficient/2` -> `vocabulary_terms_for_voc/2`
%        path, which adds curated synonyms not in the registry list.
%
%   Union is sorted so the triage tool sees a stable term set.
kind_vocabulary_terms(Kind, Terms) :-
    findall(T,
            ( action_automaton_vocabulary(_Op, Kind, RegistryTerms),
              member(T, RegistryTerms)
            ),
            FromRegistry),
    findall(T,
            ( practice_kind(Practice, _Operation, Kind),
              pv_sufficient(Practice, Vid),
              vocabulary_terms_for_voc(Vid, MuaTerms),
              member(T, MuaTerms)
            ),
            FromMua),
    append(FromRegistry, FromMua, All),
    sort(All, Terms).


%!  vocabulary_terms_for_voc(+VocabularyId, -Terms) is det.
%
%   Vocabulary id -> a small list of atomic terms that are likely to
%   appear in a corpus row deploying this vocabulary. Drawn from the
%   registry `action_automaton_vocabulary/3` lists plus a few synonyms.
vocabulary_terms_for_voc(v_counting,
                         [counting, count, one_to_one, cardinal]).
vocabulary_terms_for_voc(v_counting_on,
                         [counting_on, count_on, larger_addend, start_at]).
vocabulary_terms_for_voc(v_make_base_transfer,
                         [compensation, make_a_base, make_ten, base, transfer]).
vocabulary_terms_for_voc(v_column_algorithm,
                         [column, carry, regroup, place_value, ten]).
vocabulary_terms_for_voc(v_fraction_unit,
                         [unit_fraction, partition, iteration, denominator, referent_whole]).
vocabulary_terms_for_voc(v_area_model,
                         [unit_square, area_model, part_of_part, rectangle, side_partition,
                          numerator_product, denominator_product]).
vocabulary_terms_for_voc(v_cross_multiplication_rule,
                         [cross_multiplication, multiply_across, numerator,
                          denominator, multiply_tops, multiply_bottoms]).
vocabulary_terms_for_voc(v_decimal_positional,
                         [decimal_point, place_value, tenths, hundredths,
                          whole_part, fractional_part]).
vocabulary_terms_for_voc(v_decimal_multiplication_rule,
                         [decimal_multiplication, count_decimal_places,
                          sum_place_counts, place_the_decimal]).
vocabulary_terms_for_voc(v_inverse_multiplication,
                         [inverse_multiplication, check_by_multiplication,
                          divisor_times_quotient, upper_bound, validate_quotient]).
vocabulary_terms_for_voc(v_distributive_decomposition,
                         [distributive, partial_product, decompose_factor,
                          sum_of_partials, distributive_validation]).
vocabulary_terms_for_voc(v_bijective_counting,
                         [bijective, one_to_one_correspondence, stable_order,
                          cardinal_principle, abstraction, order_irrelevance,
                          five_counting_principles]).
vocabulary_terms_for_voc(v_area_justification,
                         [area_justification, re_ground, area_model_check,
                          model_based_justification]).
vocabulary_terms_for_voc(v_error_magnitude_comparison,
                         [comparing_rounding_errors, omitted_partial_product,
                          smaller_error, closer_estimate, comparing_weights]).
vocabulary_terms_for_voc(v_function_limit,
                         [limit, direct_substitution, factor_cancel,
                          removable_discontinuity, continuous_at]).
vocabulary_terms_for_voc(v_sequence_convergence,
                         [sequence, converge, convergence, bounded,
                          tail, epsilon, eventually]).
vocabulary_terms_for_voc(v_algebraic_expression,
                         [algebraic_expression, evaluate, variable,
                          substitute, sub_expression, expression_tree]).
vocabulary_terms_for_voc(v_relational_equals_balance,
                         [relational_equals, balance_preservation, same_operation,
                          both_sides, equation_as_balance]).
vocabulary_terms_for_voc(v_signed_addition_with_sign_relation,
                         [signed_addition, sign_relation, magnitude,
                          opposite_signs, same_sign, zero_pair]).
vocabulary_terms_for_voc(v_ratio_scaling,
                         [scale_ratio, equivalent_ratio, scale_factor,
                          multiplicative_scaling, ratio_table]).


%!  kind_mua_coherence_witness(+Kind, +RowText, -Score, -Witness) is det.
%
%   Positive witness for MUA-coherence scoring. The score is the number of
%   vocabulary terms for Kind that appear in RowText; the witness keeps both the
%   candidate term set and the actual hits inspectable.
kind_mua_coherence_witness(Kind, RowText, Score,
                           _{ kind: mua_kind_coherence,
                              registry_kind: Kind,
                              row_text_scope: lower_cased_corpus_row_text,
                              vocabulary_terms: Terms,
                              hits: Hits,
                              score: Score }) :-
    kind_vocabulary_terms(Kind, Terms),
    findall(T,
            ( member(T, Terms),
              term_in_text(T, RowText)
            ),
            Hits0),
    sort(Hits0, Hits),
    length(Hits, Score).


%!  kind_mua_coherence(+Kind, +RowText, -Score) is det.
%
%   Given a registry kind and the lower-cased text of a corpus row (an
%   atom), score the MUA-coherence of binding the row to that kind.
%   Score 0..N where N is the number of vocabulary terms the row uses
%   that are PV-sufficient for the kind. The triage tool combines this
%   score with the mapper score to make tier-promotion decisions.
kind_mua_coherence(Kind, RowText, Score) :-
    kind_mua_coherence_witness(Kind, RowText, Score, _).


%!  term_in_text(+Term, +Text) is semidet.
%
%   The vocabulary term (a snake_case atom) appears in the text either
%   as itself or with underscores replaced by spaces. Text is assumed
%   already lower-cased by the caller.
term_in_text(Term, Text) :-
    atom(Term),
    atom_string(Term, S1),
    sub_string(Text, _, _, _, S1), !.
term_in_text(Term, Text) :-
    atom(Term),
    atom_string(Term, S1),
    re_replace("_"/g, " ", S1, S2),
    sub_string(Text, _, _, _, S2).
