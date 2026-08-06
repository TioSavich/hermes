/** <module> Literature labels for comparison-automaton states
 *
 * Automata use stable state atoms.  This table keeps historically distinct
 * literature labels attached to those atoms rather than choosing a false
 * synonym.  Display labels prefer the Steffe/Olive/Hackenberg constructivist
 * line, then Van de Walle, and finally the atom itself.  Every other label
 * remains queryable as an alternate with its provenance.
 */

:- module(state_vocabulary,
          [ state_label/4,
            display_default_tradition/2,
            state_display_label/2,
            state_display_label/4,
            state_labels/3
          ]).

:- use_module(library(apply), [exclude/3]).

% state_label(StateAtom, Tradition, Label, Citation).

% Area-model ordering.
state_label(q_unitize_whole, constructivist, "unitizing",
            "Olive 1999; Norton & Wilkins 2009").
state_label(q_unitize_whole, van_de_walle, "the whole or unit",
            "Van de Walle, ch. 15, Models for Fractions").
state_label(q_verify_same_size_whole, van_de_walle, "same-size whole",
            "Van de Walle, ch. 15, Comparing Fractions").
state_label(q_verify_same_size_whole, van_de_walle, "fraction size is relative",
            "Van de Walle, ch. 15, Fractional Parts").
state_label(q_partition, constructivist, "equi-partitioning",
            "Steffe 2001, via Boyce & Norton 2017").
state_label(q_partition, van_de_walle, "partitioning",
            "Van de Walle, ch. 15, Fractional Parts").
state_label(q_disembed, constructivist, "disembedding",
            "Hackenberg 2013; Steffe & Olive 2010").
state_label(q_iterate_count_parts, constructivist, "iterating",
            "Steffe/Olive/Hackenberg fraction-scheme vocabulary").
state_label(q_iterate_count_parts, van_de_walle,
            "counting fractional parts, or iterating",
            "Van de Walle, ch. 15, Fractional Parts").
state_label(q_compare_relative_size, van_de_walle,
            "reasoning about the relative size of the fractions",
            "Van de Walle, ch. 15, Comparing Fractions").
state_label(q_compare_relative_size, behr_post_lesh,
            "numerator and denominator strategy",
            "Behr, Wachsmuth, Post & Lesh 1984").
state_label(q_unequal_partition_piece_count, behr_post_lesh,
            "whole number dominance", "Behr et al. 1984").
state_label(q_unequal_partition_piece_count, van_de_walle,
            "unequal-sized parts do not name fractional parts",
            "Van de Walle, ch. 15, Fractional Parts").

% Number-line placement and comparison.
state_label(q_identify_unit, bright_behr_post_wachsmuth, "the unit",
            "Bright, Behr, Post & Wachsmuth 1988").
state_label(q_identify_unit, van_de_walle, "the unit (whole)",
            "Van de Walle, ch. 15; Shaughnessy 2011").
state_label(q_partition_interval, van_de_walle,
            "partition a number line into equal parts",
            "Van de Walle, ch. 15, Fractional Parts").
state_label(q_partition_interval, ccss, "partition a number line into fourths",
            "CCSS 3.NF.A.2b, via Van de Walle").
state_label(q_mark_off_lengths, constructivist, "iterating",
            "Steffe/Olive/Hackenberg fraction-scheme vocabulary; Van de Walle, ch. 15").
state_label(q_mark_off_lengths, ccss, "marking off lengths 1/b from 0",
            "CCSS 3.NF.A.2b, via Van de Walle").
state_label(q_locate_endpoint, ccss, "its endpoint locates the number a/b",
            "CCSS 3.NF.A.2b, via Van de Walle").
state_label(q_locate_endpoint, van_de_walle,
            "locating a fractional value on a number line",
            "Van de Walle, ch. 15").
state_label(q_measure_with_unit_fraction, constructivist,
            "fraction as a measure", "Simon et al. 2018").
state_label(q_compare_positions, van_de_walle,
            "compare the relative size of numbers on a number line",
            "Van de Walle, ch. 15, Models for Fractions").
state_label(q_count_marks_not_intervals, bright_behr_post_wachsmuth,
            "count marks instead of intervals",
            "Bright, Behr, Post & Wachsmuth 1988").
state_label(q_count_marks_not_intervals, shaughnessy,
            "count the tick marks rather than the space between the marks",
            "Shaughnessy 2011, via Van de Walle").

% Set-model comparison.
state_label(q_unitize_set, constructivist, "unitizing",
            "Steffe/Olive/Hackenberg fraction-scheme vocabulary").
state_label(q_unitize_set, van_de_walle,
            "the whole is understood to be a set of objects",
            "Van de Walle, ch. 15, Models for Fractions").
state_label(q_verify_same_whole, van_de_walle, "fraction size is relative",
            "Van de Walle, ch. 15, Fractional Parts").
state_label(q_partition_set, van_de_walle, "partition sets of objects",
            "Van de Walle, ch. 15, Fractional Parts").
state_label(q_count_equal_sets, van_de_walle,
            "the number of equal sets in the whole",
            "Van de Walle, ch. 15").
state_label(q_disembed_subset, constructivist, "disembedding",
            "Hackenberg 2014").
state_label(q_disembed_subset, van_de_walle,
            "subsets of the whole make up fractional parts",
            "Van de Walle, ch. 15, Models for Fractions").
state_label(q_subset_size_focus, van_de_walle,
            "focus on the size of a subset rather than the number of equal sets",
            "Van de Walle, ch. 15, Models for Fractions").

% Benchmark comparison.
state_label(q_select_benchmark, clarke_roche, "benchmarking",
            "Clarke & Roche 2009").
state_label(q_select_benchmark, behr_post_lesh, "reference point",
            "Behr, Wachsmuth, Post & Lesh 1984").
state_label(q_benchmark_first, van_de_walle,
            "more than or less than one-half or one",
            "Van de Walle, ch. 15, Comparing Fractions").
state_label(q_benchmark_second, van_de_walle,
            "more than or less than one-half or one",
            "Van de Walle, ch. 15, Comparing Fractions").
state_label(q_transitive_compare, post_cramer, "transitive",
            "Post et al. 1986; Cramer, Post & delMas 2002").
state_label(q_residual_compare, clarke_roche, "residual thinking",
            "Clarke & Roche 2009; Post & Cramer 2002").
state_label(q_residual_compare, cramer_post_delmas, "residual",
            "Cramer, Post & delMas 2002").
state_label(q_residual_compare, van_de_walle,
            "closeness to one-half or one",
            "Van de Walle, ch. 15, Comparing Fractions").
state_label(q_residual_compare, riddle_rodzwell, "filling up the whole",
            "Riddle & Rodzwell 2000, via Clarke & Roche 2009").
state_label(q_gap_thinking, clarke_roche, "gap thinking",
            "Pearn & Stephens 2004, via Clarke & Roche 2009").

% Common-denominator / equivalence-based ordering.
state_label(q_common_partition, constructivist, "common partitioning",
            "Shin & Lee 2018").
state_label(q_common_partition, clarke_roche,
            "converts to common denominator", "Clarke & Roche 2009").
state_label(q_common_partition, van_de_walle, "find a common denominator",
            "Van de Walle, ch. 15").
state_label(q_transform_commensurate_1, constructivist, "commensurate",
            "Steffe 2003").
state_label(q_transform_commensurate_1, van_de_walle,
            "equivalent-fraction procedure", "Van de Walle, ch. 15").
state_label(q_transform_commensurate_2, constructivist, "commensurate",
            "Steffe 2003").
state_label(q_transform_commensurate_2, van_de_walle,
            "equivalent-fraction procedure", "Van de Walle, ch. 15").
state_label(q_measure_with_co_unit, constructivist, "co-measurement unit",
            "Shin & Lee 2018; Nabors 2003").
state_label(q_compare_same_denominator, van_de_walle,
            "same denominator strategy", "Van de Walle, ch. 15").
state_label(q_compare_same_denominator, cramer_post_delmas,
            "same denominator", "Cramer, Post & delMas 2002").
state_label(q_compare_same_denominator, clarke_roche,
            "denominator the same and compares numerator",
            "Clarke & Roche 2009").
state_label(q_compare_same_denominator, behr_post_lesh,
            "numerator and denominator strategy",
            "Behr, Wachsmuth, Post & Lesh 1984").
state_label(q_common_numerator, van_de_walle, "common numerator",
            "Burns 1999, via Van de Walle, ch. 15").
state_label(q_compare_same_numerator, cramer_post_delmas, "same numerator",
            "Cramer, Post & delMas 2002").
state_label(q_compare_same_numerator, clarke_roche,
            "numerator the same and compares denominator",
            "Clarke & Roche 2009").
state_label(q_add_numerator_denominator, behr_post_lesh, "addition",
            "Behr, Wachsmuth, Post & Lesh 1984").

% Decimal comparison. These labels describe doings visible in the coded G4Q2
% legend rather than assigning a literature taxonomy the source does not give.
state_label(q_identify_decimal_units, asktm_g4q2, "refers to a whole",
            "ASKTM G4Q2 coded legend, A2/A3").
state_label(q_express_as_fraction, asktm_g4q2, "converts decimals to fractions",
            "ASKTM G4Q2 coded legend, A2/A3").
state_label(q_align_place_value_units, asktm_g4q2, "place value reasoning",
            "ASKTM G4Q2 coded legend, A2/A3").
state_label(q_compare_decimal_magnitudes, asktm_g4q2,
            "uses < or >", "ASKTM G4Q2 coded legend, A1/A2").
state_label(q_scale_loss, asktm_g4q2, "misnomer of quantity",
            "ASKTM G4Q2 coded legend, A2/B2").

% Division operand-role ordering.  The state name records the doing; the label
% is the literature's rule, not a diagnosis of a learner.
state_label(q_order_division_operands_by_magnitude, bonotto,
            "larger number as dividend",
            "Cinzia Bonotto 2005, Mathematical Thinking and Learning, p. 318; research corpus row 40632").

% INTEGER lane state labels.
state_label(unknown_addend_arrow_then_additive_inverse,
            illustrative_mathematics,
            "rewrite as an unknown addend, then add the additive inverse",
            "Illustrative Mathematics Grade 7 Unit 5 Lesson 5 teacher guide").
state_label(swap_roles_to_retain_nonnegative_difference,
            illustrative_mathematics,
            "subtract the lesser number from the greater number",
            "Illustrative Mathematics Grade 7 Unit 5 Lesson 6 teacher guide").
state_label(name_unsigned_distance_as_signed_difference,
            illustrative_mathematics,
            "difference and distance are not interchangeable",
            "Illustrative Mathematics Grade 7 Unit 5 Lesson 7 teacher guide").
state_label(continue_product_pattern_then_name_sign_rule,
            illustrative_mathematics,
            "continue a product pattern across zero",
            "Illustrative Mathematics Grade 7 Unit 5 Lesson 9 teacher guide").
state_label(reverse_product_sign_relation,
            illustrative_mathematics,
            "reverse the sign relation in a signed product",
            "Illustrative Mathematics Grade 7 Unit 5 Lesson 10, Making Mistakes").
state_label(rewrite_as_unknown_factor_then_name_quotient_sign,
            illustrative_mathematics,
            "rewrite as an unknown-factor product and name the quotient sign",
            "Illustrative Mathematics Grade 7 Unit 5 Lesson 11 teacher guide").
state_label(reverse_quotient_sign_relation,
            none_recorded,
            "none_recorded",
            "No separately cited division-error label; the machine transfers Lesson 10's attested reversal only through Lesson 11's explicit product-quotient sign-pattern equivalence").

% RATIO lane state labels.
state_label(equivalent_ratio_scaling, van_de_walle,
            "multiplicative comparison and scaling",
            "Vergnaud 1983, via Van de Walle, ch. 18; action_vocabulary_map substitute_additive_for_multiplicative citation").
state_label(q_unit_rate_normalization, constructivist,
            "unitizing a rate",
            "Lamon 1996, Development of Unitizing; research corpus JRME_Lamon_1996_Development").
state_label(q_unit_rate_direction_ignored, christou_philippou,
            "larger-divided-by-smaller unit-rate setup",
            "Christou & Philippou 2002, Journal of Mathematical Behavior, pp. 327-328; research corpus row 38316").
state_label(q_proportional_relation_test, arican,
            "distinguishing proportional and nonproportional relationships",
            "Arican 2018, International Journal of Science and Mathematics Education; research corpus row 40430").
state_label(q_proportional_equation_setup_and_use, none_recorded,
            none_recorded,
            none_recorded).

% GEOSTAT lane state labels.
% Literature labels for GEOSTAT automaton_state atoms.

state_label(co_measure_diameter_and_circumference_with_pi, constructivist,
            "co-measurement unit for diameter and circumference",
            "Shin & Lee 2018; Nabors 2003; IM-G7-U3-L3").
state_label(treat_diameter_as_radius_before_circle_scaling,
            illustrative_mathematics,
            "diameter used as if it were the radius",
            "IM-G7-U3-L10, Building on Student Thinking").
state_label(classify_three_measure_triangle_conditions,
            illustrative_mathematics,
            "one triangle, more than one, or none",
            "IM-G7-U7-L9 and L10; CCSS 7.G.A.2").
state_label(compose_angle_relation_and_isolate_unknown,
            illustrative_mathematics,
            "compose angle measures to determine an unknown angle",
            "IM-G7-U7-L4; CCSS 7.G.B.5").
state_label(estimate_probability_from_cumulative_relative_frequency,
            illustrative_mathematics,
            "cumulative relative frequency as a probability estimate",
            "IM-G7-U8-L4, Goals and Activity Synthesis").
state_label(promote_finite_relative_frequency_to_exact_probability,
            illustrative_mathematics,
            "finite relative frequency treated as an exact probability",
            "IM-G7-U8-L4 and L5, long-run and short-term comparison").
state_label(compare_sample_and_population_shape_center_spread,
            illustrative_mathematics,
            "compare sample and population shape, center, and spread",
            "IM-G7-U8-L13, Goals and Lesson Narrative").

% ALGEBRAIC lane state labels.
% These source-facing labels quote or closely retain the curriculum's named
% doings. They are not assigned to a historical constructivist tradition that
% the cited source does not claim.

state_label(coordinate_diagram_parts_with_equation_relation,
            illustrative_mathematics,
            "match equations and diagrams that represent the same relationship",
            "Illustrative Mathematics Grade 7, Unit 6, Lessons 2-3").
state_label(split_repeated_variable_label_into_distinct_roles,
            illustrative_mathematics,
            "repeated variable occurrences read as different values",
            "Illustrative Mathematics Grade 7, Unit 6, Lesson 2, Building on Student Thinking").
state_label(compose_percent_multiplier_with_amount,
            illustrative_mathematics,
            "coordinate percent change with a multiplier of the original",
            "Illustrative Mathematics Grade 7, Unit 4, Lesson 6").
state_label(rewrite_and_combine_signed_like_terms,
            illustrative_mathematics,
            "rewrite subtraction as adding the opposite, then combine like terms",
            "Illustrative Mathematics Grade 7, Unit 6, Lessons 18, 20, and 21").
state_label(combine_unlike_terms_as_one_coefficient,
            illustrative_mathematics,
            "a variable term and a number combined as if they were like terms",
            "Illustrative Mathematics Grade 7, Unit 6, Lesson 20, Activity Synthesis").

% Display-default policy.  The final atom_name row is deliberately a fallback,
% including for the three neutral GAP states, which have no state_label fact.
display_default_tradition(constructivist, 1).
display_default_tradition(van_de_walle, 2).
display_default_tradition(atom_name, 3).

%! state_display_label(+StateAtom, -Label) is det.
state_display_label(State, Label) :-
    state_display_label(State, _, Label, _).

%! state_display_label(+StateAtom, -Tradition, -Label, -Citation) is det.
state_display_label(State, constructivist, Label, Citation) :-
    state_label(State, constructivist, Label, Citation),
    !.
state_display_label(State, van_de_walle, Label, Citation) :-
    state_label(State, van_de_walle, Label, Citation),
    !.
state_display_label(State, atom_name, State, "canonical state atom fallback").

%! state_labels(+StateAtom, -DefaultLabel, -Alternates) is det.
%
%  Alternates are label(Tradition, Label, Citation) terms.  If the display
%  default is the atom fallback, every literature label remains an alternate.
state_labels(State, Default, Alternates) :-
    state_display_label(State, Default),
    findall(label(Tradition, Label, Citation),
            state_label(State, Tradition, Label, Citation),
            Labels),
    exclude(matches_default(Default), Labels, Alternates).

matches_default(Default, label(_, Label, _)) :-
    Label == Default.
