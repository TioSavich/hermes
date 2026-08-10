/** <module> Ceremony-admitted learner-path edges
 *
 * Admission licenses only the coincidence sub-region cited by each row.  It
 * does not license the receiver over its full domain.  Rejected candidates
 * seed nothing: only facts in this store extend admitted reachability.
 *
 * Generated mechanically by scripts/bigred/loops/build_admitted_edges.py from
 * the cited admission docket under the cited ceremony draft.  One dated block
 * records one admission wave.
 */

:- module(admitted_edges,
          [ crisis_release/8,
            admitted_edge_dict/1,
            registered_machine/2
          ]).

:- use_module(math(action_automata_registry),
              [ action_automaton_signature/4 ]).

registered_machine(Family, Kind) :-
    action_automaton_signature(Family, Kind, _Input, _Output).

admitted_edge_dict(_{
        edge_type:crisis_release,
        source:_{family:SourceFamily, kind:SourceKind},
        target:_{family:TargetFamily, kind:TargetKind},
        released_region:_{
            released_count:ReleasedCount,
            contextually_correct_count:ContextuallyCorrectCount,
            incorrect_count:IncorrectCount,
            first_witness:FirstWitness,
            last_witness:LastWitness
        },
        condition:Condition,
        lens:Lens,
        wave:Wave,
        provenance:_{docket:Docket, ceremony_draft:CeremonyDraft},
        mua_type:MuaType
    }) :-
    crisis_release(
        source(SourceFamily, SourceKind),
        target(TargetFamily, TargetKind),
        released_region(
            released_count(ReleasedCount),
            contextually_correct_count(ContextuallyCorrectCount),
            incorrect_count(IncorrectCount),
            first_witness(FirstWitness),
            last_witness(LastWitness)
        ),
        condition(Condition),
        lens(Lens),
        wave(Wave),
        provenance(docket(Docket), ceremony_draft(CeremonyDraft)),
        mua_type(MuaType)
    ).

% ---------------------------------------------------------------------------
% Admission wave 2026-08-09-wave1
% ---------------------------------------------------------------------------
crisis_release(
    source('addition', 'wrong_carry_amount_to_next_column'),
    target('addition', 'append_column_sum_without_carrying'),
    released_region(
        released_count(45),
        contextually_correct_count(45),
        incorrect_count(0),
        first_witness(input{a:1, b:9}),
        last_witness(input{a:9, b:9})
    ),
    condition('raw_column_concatenation_preserves_place_value'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('addition', 'append_column_sum_without_carrying'),
    target('addition', 'dropped_ones_chunk'),
    released_region(
        released_count(1375),
        contextually_correct_count(250),
        incorrect_count(1125),
        first_witness(input{a:0, b:0}),
        last_witness(input{a:49, b:40})
    ),
    condition('decomposed_addend_has_no_ones_chunk'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('addition', 'count_all_instead_of_known_fact'),
    target('addition', 'dropped_ones_chunk'),
    released_region(
        released_count(2269),
        contextually_correct_count(217),
        incorrect_count(2052),
        first_witness(input{a:0, b:21}),
        last_witness(input{a:49, b:49})
    ),
    condition('decomposed_addend_has_no_ones_chunk'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('addition', 'derived_fact_adjustment'),
    target('addition', 'dropped_ones_chunk'),
    released_region(
        released_count(2212),
        contextually_correct_count(223),
        incorrect_count(1989),
        first_witness(input{a:0, b:0}),
        last_witness(input{a:49, b:49})
    ),
    condition('decomposed_addend_has_no_ones_chunk'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('addition', 'drop_carry_to_next_column'),
    target('addition', 'dropped_ones_chunk'),
    released_region(
        released_count(1375),
        contextually_correct_count(250),
        incorrect_count(1125),
        first_witness(input{a:0, b:0}),
        last_witness(input{a:49, b:40})
    ),
    condition('decomposed_addend_has_no_ones_chunk'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('addition', 'known_fact_retrieval'),
    target('addition', 'dropped_ones_chunk'),
    released_region(
        released_count(2269),
        contextually_correct_count(217),
        incorrect_count(2052),
        first_witness(input{a:0, b:21}),
        last_witness(input{a:49, b:49})
    ),
    condition('decomposed_addend_has_no_ones_chunk'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('addition', 'make_ten_drop_leftover'),
    target('addition', 'dropped_ones_chunk'),
    released_region(
        released_count(619),
        contextually_correct_count(160),
        incorrect_count(459),
        first_witness(input{a:0, b:0}),
        last_witness(input{a:49, b:0})
    ),
    condition('decomposed_addend_has_no_ones_chunk'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('addition', 'make_ten_split_leftover'),
    target('addition', 'dropped_ones_chunk'),
    released_region(
        released_count(619),
        contextually_correct_count(160),
        incorrect_count(459),
        first_witness(input{a:0, b:0}),
        last_witness(input{a:49, b:0})
    ),
    condition('decomposed_addend_has_no_ones_chunk'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('addition', 'rote_derived_fact_rule_misfire'),
    target('addition', 'dropped_ones_chunk'),
    released_region(
        released_count(2310),
        contextually_correct_count(232),
        incorrect_count(2078),
        first_witness(input{a:0, b:0}),
        last_witness(input{a:49, b:49})
    ),
    condition('decomposed_addend_has_no_ones_chunk'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('addition', 'wrong_carry_amount_to_next_column'),
    target('addition', 'dropped_ones_chunk'),
    released_region(
        released_count(1420),
        contextually_correct_count(250),
        incorrect_count(1170),
        first_witness(input{a:0, b:0}),
        last_witness(input{a:49, b:40})
    ),
    condition('decomposed_addend_has_no_ones_chunk'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('addition', 'append_column_sum_without_carrying'),
    target('addition', 'unbalanced_make_base_compensation'),
    released_region(
        released_count(960),
        contextually_correct_count(204),
        incorrect_count(756),
        first_witness(input{a:0, b:10}),
        last_witness(input{a:49, b:40})
    ),
    condition('selected_addend_already_at_target_base'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('addition', 'count_all_instead_of_known_fact'),
    target('addition', 'unbalanced_make_base_compensation'),
    released_region(
        released_count(1999),
        contextually_correct_count(181),
        incorrect_count(1818),
        first_witness(input{a:0, b:30}),
        last_witness(input{a:49, b:49})
    ),
    condition('selected_addend_already_at_target_base'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('addition', 'derived_fact_adjustment'),
    target('addition', 'unbalanced_make_base_compensation'),
    released_region(
        released_count(1825),
        contextually_correct_count(180),
        incorrect_count(1645),
        first_witness(input{a:0, b:10}),
        last_witness(input{a:49, b:49})
    ),
    condition('selected_addend_already_at_target_base'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('addition', 'drop_carry_to_next_column'),
    target('addition', 'unbalanced_make_base_compensation'),
    released_region(
        released_count(960),
        contextually_correct_count(204),
        incorrect_count(756),
        first_witness(input{a:0, b:10}),
        last_witness(input{a:49, b:40})
    ),
    condition('selected_addend_already_at_target_base'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('addition', 'known_fact_retrieval'),
    target('addition', 'unbalanced_make_base_compensation'),
    released_region(
        released_count(1999),
        contextually_correct_count(181),
        incorrect_count(1818),
        first_witness(input{a:0, b:30}),
        last_witness(input{a:49, b:49})
    ),
    condition('selected_addend_already_at_target_base'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('addition', 'make_ten_drop_leftover'),
    target('addition', 'unbalanced_make_base_compensation'),
    released_region(
        released_count(204),
        contextually_correct_count(204),
        incorrect_count(0),
        first_witness(input{a:0, b:10}),
        last_witness(input{a:40, b:40})
    ),
    condition('selected_addend_already_at_target_base'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('addition', 'make_ten_split_leftover'),
    target('addition', 'unbalanced_make_base_compensation'),
    released_region(
        released_count(204),
        contextually_correct_count(204),
        incorrect_count(0),
        first_witness(input{a:0, b:10}),
        last_witness(input{a:40, b:40})
    ),
    condition('selected_addend_already_at_target_base'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('addition', 'rote_derived_fact_rule_misfire'),
    target('addition', 'unbalanced_make_base_compensation'),
    released_region(
        released_count(1913),
        contextually_correct_count(188),
        incorrect_count(1725),
        first_witness(input{a:0, b:10}),
        last_witness(input{a:49, b:49})
    ),
    condition('selected_addend_already_at_target_base'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('addition', 'wrong_carry_amount_to_next_column'),
    target('addition', 'unbalanced_make_base_compensation'),
    released_region(
        released_count(1005),
        contextually_correct_count(204),
        incorrect_count(801),
        first_witness(input{a:0, b:10}),
        last_witness(input{a:49, b:40})
    ),
    condition('selected_addend_already_at_target_base'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('division', 'missing_factor_known_product_search'),
    target('division', 'stop_after_one_known_fact'),
    released_region(
        released_count(43),
        contextually_correct_count(39),
        incorrect_count(4),
        first_witness(input{a:3, b:2}),
        last_witness(input{a:12, b:11})
    ),
    condition('first_known_fact_completes_quotient_and_remainder'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('division', 'reject_known_product_match'),
    target('division', 'stop_after_one_known_fact'),
    released_region(
        released_count(43),
        contextually_correct_count(39),
        incorrect_count(4),
        first_witness(input{a:3, b:2}),
        last_witness(input{a:12, b:11})
    ),
    condition('first_known_fact_completes_quotient_and_remainder'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('division', 'stop_at_nearby_product_in_search'),
    target('division', 'stop_after_one_known_fact'),
    released_region(
        released_count(43),
        contextually_correct_count(39),
        incorrect_count(4),
        first_witness(input{a:3, b:2}),
        last_witness(input{a:12, b:11})
    ),
    condition('first_known_fact_completes_quotient_and_remainder'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('fraction', 'area_model_fraction_comparison'),
    target('fraction', 'add_numerator_denominator_comparison'),
    released_region(
        released_count(225),
        contextually_correct_count(165),
        incorrect_count(60),
        first_witness(input{kind:'fraction_pair', left:_{d:1, n:0}, right:_{d:1, n:0}}),
        last_witness(input{kind:'fraction_pair', left:_{d:5, n:4}, right:_{d:5, n:0}})
    ),
    condition('numerator_denominator_sum_order_agrees_with_common_unit_order'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('fraction', 'area_model_unequal_partition_piece_count'),
    target('fraction', 'add_numerator_denominator_comparison'),
    released_region(
        released_count(225),
        contextually_correct_count(165),
        incorrect_count(60),
        first_witness(input{kind:'fraction_pair', left:_{d:1, n:0}, right:_{d:1, n:0}}),
        last_witness(input{kind:'fraction_pair', left:_{d:5, n:4}, right:_{d:5, n:0}})
    ),
    condition('numerator_denominator_sum_order_agrees_with_common_unit_order'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('fraction', 'set_model_fraction_comparison'),
    target('fraction', 'add_numerator_denominator_comparison'),
    released_region(
        released_count(225),
        contextually_correct_count(165),
        incorrect_count(60),
        first_witness(input{kind:'fraction_pair', left:_{d:1, n:0}, right:_{d:1, n:0}}),
        last_witness(input{kind:'fraction_pair', left:_{d:5, n:4}, right:_{d:5, n:0}})
    ),
    condition('numerator_denominator_sum_order_agrees_with_common_unit_order'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('fraction', 'set_model_subset_size_focus'),
    target('fraction', 'add_numerator_denominator_comparison'),
    released_region(
        released_count(225),
        contextually_correct_count(165),
        incorrect_count(60),
        first_witness(input{kind:'fraction_pair', left:_{d:1, n:0}, right:_{d:1, n:0}}),
        last_witness(input{kind:'fraction_pair', left:_{d:5, n:4}, right:_{d:5, n:0}})
    ),
    condition('numerator_denominator_sum_order_agrees_with_common_unit_order'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('fraction', 'area_model_fraction_comparison'),
    target('fraction', 'gap_thinking_fraction_comparison'),
    released_region(
        released_count(225),
        contextually_correct_count(145),
        incorrect_count(80),
        first_witness(input{kind:'fraction_pair', left:_{d:1, n:0}, right:_{d:1, n:0}}),
        last_witness(input{kind:'fraction_pair', left:_{d:5, n:4}, right:_{d:5, n:0}})
    ),
    condition('gap_order_coincides_with_fraction_order'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('fraction', 'area_model_unequal_partition_piece_count'),
    target('fraction', 'gap_thinking_fraction_comparison'),
    released_region(
        released_count(225),
        contextually_correct_count(145),
        incorrect_count(80),
        first_witness(input{kind:'fraction_pair', left:_{d:1, n:0}, right:_{d:1, n:0}}),
        last_witness(input{kind:'fraction_pair', left:_{d:5, n:4}, right:_{d:5, n:0}})
    ),
    condition('gap_order_coincides_with_fraction_order'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('fraction', 'set_model_fraction_comparison'),
    target('fraction', 'gap_thinking_fraction_comparison'),
    released_region(
        released_count(225),
        contextually_correct_count(145),
        incorrect_count(80),
        first_witness(input{kind:'fraction_pair', left:_{d:1, n:0}, right:_{d:1, n:0}}),
        last_witness(input{kind:'fraction_pair', left:_{d:5, n:4}, right:_{d:5, n:0}})
    ),
    condition('gap_order_coincides_with_fraction_order'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('fraction', 'set_model_subset_size_focus'),
    target('fraction', 'gap_thinking_fraction_comparison'),
    released_region(
        released_count(225),
        contextually_correct_count(145),
        incorrect_count(80),
        first_witness(input{kind:'fraction_pair', left:_{d:1, n:0}, right:_{d:1, n:0}}),
        last_witness(input{kind:'fraction_pair', left:_{d:5, n:4}, right:_{d:5, n:0}})
    ),
    condition('gap_order_coincides_with_fraction_order'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('fraction', 'area_model_fraction_comparison'),
    target('fraction', 'number_line_count_marks_not_intervals'),
    released_region(
        released_count(225),
        contextually_correct_count(181),
        incorrect_count(44),
        first_witness(input{kind:'fraction_pair', left:_{d:1, n:0}, right:_{d:1, n:0}}),
        last_witness(input{kind:'fraction_pair', left:_{d:5, n:4}, right:_{d:5, n:0}})
    ),
    condition('mark_count_order_agrees_with_interval_measure'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('fraction', 'area_model_unequal_partition_piece_count'),
    target('fraction', 'number_line_count_marks_not_intervals'),
    released_region(
        released_count(225),
        contextually_correct_count(181),
        incorrect_count(44),
        first_witness(input{kind:'fraction_pair', left:_{d:1, n:0}, right:_{d:1, n:0}}),
        last_witness(input{kind:'fraction_pair', left:_{d:5, n:4}, right:_{d:5, n:0}})
    ),
    condition('mark_count_order_agrees_with_interval_measure'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('fraction', 'set_model_fraction_comparison'),
    target('fraction', 'number_line_count_marks_not_intervals'),
    released_region(
        released_count(225),
        contextually_correct_count(181),
        incorrect_count(44),
        first_witness(input{kind:'fraction_pair', left:_{d:1, n:0}, right:_{d:1, n:0}}),
        last_witness(input{kind:'fraction_pair', left:_{d:5, n:4}, right:_{d:5, n:0}})
    ),
    condition('mark_count_order_agrees_with_interval_measure'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).

crisis_release(
    source('fraction', 'set_model_subset_size_focus'),
    target('fraction', 'number_line_count_marks_not_intervals'),
    released_region(
        released_count(225),
        contextually_correct_count(181),
        incorrect_count(44),
        first_witness(input{kind:'fraction_pair', left:_{d:1, n:0}, right:_{d:1, n:0}}),
        last_witness(input{kind:'fraction_pair', left:_{d:5, n:4}, right:_{d:5, n:0}})
    ),
    condition('mark_count_order_agrees_with_interval_measure'),
    lens(l2),
    wave('2026-08-09-wave1'),
    provenance(
        docket('docs/research/internal/2026-08-09-admission-docket.json'),
        ceremony_draft('plans/2026-08-09-admission-ceremony-wave1-draft.md')
    ),
    mua_type(untyped)
).
