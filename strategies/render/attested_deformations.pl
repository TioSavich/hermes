/** <module> attested_deformations
 *
 * GENERATED, additive metavocabulary over strategies/render/representation_grammar.pl.
 * Do NOT hand-edit; do NOT edit representation_grammar.pl.
 * Companion to strategies/render/attested_objects.pl (same corpus, same membership).
 *
 * Source: REALLMs figure classifications
 *   docs/research_assets/research/docling_classifications.json
 *   joined to bibkey via the crop directory name.
 * Membership: figures REALLMs flagged as student work
 *   (has_handwriting_or_student_work = true), same rule as the per-figure file
 *   and attested_objects.pl. Transplant rows are student work by construction.
 *
 * This layer GENERALISES the per-figure ground facts in
 * lessons/im/docling_figures_interpreted.pl up to the language / pattern level.
 * It produces only facts the data supports, and is honest about gaps.
 *
 * Two generalisations:
 *   (1) attested deformations: transplant cases (foreign primitive on illicit
 *       host) and a generalised attested_representation_error/4 over a small
 *       controlled ErrorPattern vocabulary.
 *   (2) grounding validation: corpus-attested use vs the claimed Lakoff-Nunez
 *       blend, via representation_grounding/2 and blend_entails/2 in the grammar.
 */
:- module(attested_deformations,
          [ attested_transplant/5,
            attested_representation_error/4,
            attested_representation_error_scope/5,
            attested_error_pattern/1,
            grounding_attested/3,
            grounding_mismatch/4 ]).

:- use_module(render(representation_grammar)).

% grounding_attested/3 and grounding_mismatch/4 are emitted in representation_language
% order, so the two predicates interleave by design.
:- discontiguous attested_deformations:grounding_attested/3.
:- discontiguous attested_deformations:grounding_mismatch/4.

% --- (1a) Attested transplants -------------------------------------------
% attested_transplant(Language, ForeignPrimitive, IllicitHost, Bibkey, Figure)
% Each row is a figure REALLMs flagged is_hybridized_transplant = true. Shaped
% to join representation_grammar:deformation_spec_evidence/4 hybridization rows
% (foreign_primitive / illicit_host); one corpus instance per fact.
attested_transplant(area_model, rectangle_grid_partition, circle_region, 'ESM_Cadez_2018_How', 'p14_2.png').
attested_transplant(area_model, circle_radial_partition, rectangle_area_model, 'MERJ_Zhang_2015_Enriching', 'p18_1.png').
attested_transplant(fraction_bars, circle_radial_partition, submarine_sandwich_region, 'ZDM_Garderen_2014_Challenges', 'p9_1.png').

% --- (1b) Generalised attested representation errors ----------------------
% attested_representation_error(Language, ErrorPattern, FigureCount, Examples)
% Examples = up to 3 tag(Bibkey, Figure) witnesses. Aggregated to the
% (language, pattern) level over a small controlled ErrorPattern vocabulary.
% Honest scope: most flagged errors carry representation_language = none (raw
% symbolic/algebraic work with no diagram); only a handful sit in the
% diagrammatic languages. 'unspecified_error' is the residual bucket for a
% flagged error that matches no named pattern.

attested_error_pattern(arithmetic_or_transcription_slip).
attested_error_pattern(cross_multiply_without_ground).
attested_error_pattern(unequal_partition).
attested_error_pattern(miscount_partition).
attested_error_pattern(shade_wrong_count).
attested_error_pattern(wrong_referent_whole).
attested_error_pattern(factoring_or_root_error).
attested_error_pattern(flagged_self_correction).
attested_error_pattern(impossible_or_invalid_claim).
attested_error_pattern(order_of_operations_error).
attested_error_pattern(sqrt_distributes_over_addition).
attested_error_pattern(unspecified_error).

attested_representation_error(none, unspecified_error, 33, [tag('ESM_Baruk_1987_Realite', 'p30_1.png'), tag('ESM_Caglayan_2010_Eighth', 'p16_1.png'), tag('ESM_Depaepe_2018_Stimulating', 'p14_1.png')]).
attested_representation_error(none, arithmetic_or_transcription_slip, 10, [tag('ESM_Baruk_1987_Realite', 'p10_1.png'), tag('ESM_Baruk_1987_Realite', 'p14_2.png'), tag('ESM_Baruk_1987_Realite', 'p17_1.png')]).
attested_representation_error(none, flagged_self_correction, 3, [tag('ESM_Baruk_1987_Realite', 'p23_2.png'), tag('ESM_Baruk_1987_Realite', 'p28_1.png'), tag('ESM_Streefland_1982_Subtracting', 'p17_1.png')]).
attested_representation_error(none, impossible_or_invalid_claim, 2, [tag('ESM_Baruk_1987_Realite', 'p16_2.png'), tag('ESM_Baruk_1987_Realite', 'p26_2.png')]).
attested_representation_error(none, cross_multiply_without_ground, 2, [tag('ESM_Baruk_1987_Realite', 'p26_1.png'), tag('ESM_Baruk_1987_Realite', 'p6_3.png')]).
attested_representation_error(none, factoring_or_root_error, 1, [tag('ESM_Baruk_1987_Realite', 'p13_1.png')]).
attested_representation_error(none, order_of_operations_error, 1, [tag('ESM_Baruk_1987_Realite', 'p21_1.png')]).
attested_representation_error(none, sqrt_distributes_over_addition, 1, [tag('ESM_Baruk_1987_Realite', 'p4_1.png')]).
attested_representation_error(area_model, unspecified_error, 4, [tag('ESM_Heuvelpanhuizen_1994_Improvement', 'p29_1.png'), tag('JMB_Lin_2013_Enhancing', 'p13_1.png'), tag('JMB_Wickstrom_2017_Pre-service', 'p2_1.png')]).
attested_representation_error(area_model, arithmetic_or_transcription_slip, 1, [tag('ESM_Baturo_1996_Student', 'p20_1.png')]).
attested_representation_error(set_grouping, unspecified_error, 2, [tag('ESM_Turner_2013_Latino', 'p16_1.png'), tag('IJMEST_Herrera_2011_Addition', 'p15_1.png')]).
attested_representation_error(set_grouping, flagged_self_correction, 1, [tag('JMB_Singer_2008_Between', 'p11_1.png')]).
attested_representation_error(base_ten_blocks, flagged_self_correction, 1, [tag('MTL_Whitenack_2001_Coordinating', 'p24_1.png')]).

%! attested_representation_error_scope(?Language, ?ErrorPattern, ?FigureCount,
%!                                     -Scope, -Why) is nondet.
%
%  Classify the aggregated corpus buckets for coverage reporting. These rows
%  witness literature/corpus evidence; they are not scene geometry and must not
%  be counted as live rendered misconception scenes.
attested_representation_error_scope(Language, Pattern, FigureCount, evidence_pointer, Why) :-
    attested_representation_error(Language, Pattern, FigureCount, _Examples),
    (   Language == none
    ->  Why = no_representation_language
    ;   representation_grammar:representation_render_status(Language, renderable(_))
    ->  Why = renderable_representation_no_scene_geometry
    ;   Why = representation_not_renderable_no_scene_geometry
    ).

% --- (2) Grounding validation --------------------------------------------
% For each grammar representation_language, compare corpus-attested spatial use
% against the blend representation_grounding/2 claims (via blend_entails/2).
% grounding_attested(Language, Blend, supports): dominant corpus use is
%   consistent with what the blend entails.
% grounding_mismatch(Language, Blend, CorpusUseSummary, Note): the corpus shows
%   the representation doing something the blend does not entail.
%
% CorpusUseSummary = use(N, PartWholeCount, DominantElements)
%   N = student-work figures in that language
%   PartWholeCount = figures carrying partition/equal_part (part-whole signal)

grounding_attested(set_grouping, blend(object_collection, object_construction), supports).
grounding_attested(base_ten_blocks, blend(object_collection, place_value_grouping), supports).
grounding_mismatch(number_line, blend(measuring_stick, source_path_goal), use(151, 31, [axis-144, jump-109, partition-31]),
    path_blend_entails_ordered_magnitude_on_path_not_common_partitioned_whole_but_corpus_partitions_the_line_for_fractions_and_double_number_lines).
grounding_mismatch(place_value_chart, blend(writing_system, place_value_grouping), use(12, 1, [digit_column-12, ten_rod-4, unit_cube-3]),
    writing_system_blend_entails_positional_digit_places_but_corpus_mixes_in_physical_blocks_and_counters_collapsing_positional_chart_toward_object_collection).
grounding_attested(fraction_bars, blend(measuring_stick, part_whole), supports).
grounding_attested(area_model, blend(container, measuring_stick), supports).
grounding_attested(balance_scale, blend(balance_equilibrium, equation_as_balance), supports).
