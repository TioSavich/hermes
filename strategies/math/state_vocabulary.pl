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
