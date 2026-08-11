/** <module> Ceremony-admitted typed contract bridges
 *
 * This store records 594 band-1 contract_bridge admissions.  Class P licenses
 * transport of the named role only.  It licenses neither equivalence between
 * the machines nor correctness of the transported value.
 *
 * The ruled partition is 594 admitted, 507 held because their evidence is
 * thin, 152 held because the carried value arrives as the sole element of a
 * collection, and 9 held because the target answer is degenerate.  The 507
 * thin rows wait on grid repairs and re-collection.  The 152 singleton rows
 * wait on a design change because no R4 evidence can thicken them.  Held rows
 * have no facts here.
 *
 * All 46 seam-4 admissions are decimal-to-decimal renames.  This wave does not
 * meet the seam's fraction-to-decimal request.
 * The ruling is plans/2026-08-11-r4-admission-band1-draft.md.
 * contract_bridge remains distinct from crisis_release in admitted_edges.pl.
 *
 * Generated mechanically by scripts/checks/admitted_bridges_store.py from
 * docs/research/internal/2026-08-10-r4-admission-docket.json
 * for 2026-08-10 R4 admission ceremony.
 */

:- module(admitted_bridges,
          [ admitted_bridge/1
          ]).

% Adapter: carry_measured_magnitude
admitted_bridge(
    bridge{
        adapter:'carry_measured_magnitude',
        license_class:'u',
        source:json{family:'geometry', kind:'perimeter_two_sides_only'},
        target:json{family:'geometry', kind:'perimeter_uses_area_formula'},
        carried_role:'the magnitude with its unit centimeter written into the target''s unit slot',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.width', value:1}], [json{path:'.width', value:4}], [json{path:'.width', value:12}]],
        witness:json{adapted_input:json{kind:'rectangle_with_unit', length:2, unit:'centimeter', width:1}, carried_value_exact:'2', input:json{kind:'rectangle_with_unit', length:1, unit:'centimeter', width:1}, source_result:'length(2,centimeter)', target_result:'result(length(2,centimeter),length(6,centimeter),incorrect)', transform:'the magnitude with its unit centimeter written into the target''s unit slot'},
        seam_flags:[6],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'carry_measured_magnitude',
        license_class:'u',
        source:json{family:'geometry', kind:'perimeter_two_sides_only'},
        target:json{family:'geometry', kind:'rectangle_perimeter_boundary_traversal'},
        carried_role:'the magnitude with its unit centimeter written into the target''s unit slot',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.width', value:1}], [json{path:'.width', value:4}], [json{path:'.width', value:12}]],
        witness:json{adapted_input:json{kind:'rectangle_with_unit', length:2, unit:'centimeter', width:1}, carried_value_exact:'2', input:json{kind:'rectangle_with_unit', length:1, unit:'centimeter', width:1}, source_result:'length(2,centimeter)', target_result:'result(length(6,centimeter),length(6,centimeter),correct)', transform:'the magnitude with its unit centimeter written into the target''s unit slot'},
        seam_flags:[6],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'carry_measured_magnitude',
        license_class:'u',
        source:json{family:'geometry', kind:'rectangle_perimeter_boundary_traversal'},
        target:json{family:'geometry', kind:'perimeter_two_sides_only'},
        carried_role:'the magnitude with its unit centimeter written into the target''s unit slot',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.width', value:1}], [json{path:'.width', value:4}], [json{path:'.width', value:12}]],
        witness:json{adapted_input:json{kind:'rectangle_with_unit', length:4, unit:'centimeter', width:1}, carried_value_exact:'4', input:json{kind:'rectangle_with_unit', length:1, unit:'centimeter', width:1}, source_result:'length(4,centimeter)', target_result:'result(length(5,centimeter),length(10,centimeter),incorrect)', transform:'the magnitude with its unit centimeter written into the target''s unit slot'},
        seam_flags:[6],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'carry_measured_magnitude',
        license_class:'u',
        source:json{family:'geometry', kind:'rectangle_perimeter_boundary_traversal'},
        target:json{family:'geometry', kind:'perimeter_uses_area_formula'},
        carried_role:'the magnitude with its unit centimeter written into the target''s unit slot',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.width', value:1}], [json{path:'.width', value:4}], [json{path:'.width', value:12}]],
        witness:json{adapted_input:json{kind:'rectangle_with_unit', length:4, unit:'centimeter', width:1}, carried_value_exact:'4', input:json{kind:'rectangle_with_unit', length:1, unit:'centimeter', width:1}, source_result:'length(4,centimeter)', target_result:'result(length(4,centimeter),length(10,centimeter),incorrect)', transform:'the magnitude with its unit centimeter written into the target''s unit slot'},
        seam_flags:[6],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'carry_measured_magnitude',
        license_class:'u',
        source:json{family:'measurement', kind:'unit_preserving_measured_quantity_change'},
        target:json{family:'measurement', kind:'drop_unit_from_measured_quantity_change'},
        carried_role:'the magnitude with its unit centimeter written into the target''s unit slot',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.operation', value:'add'}, json{path:'.b', value:0}], [json{path:'.operation', value:'add'}, json{path:'.b', value:10}], [json{path:'.operation', value:'add'}, json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:0, b:0, kind:'measured_change', operation:'add', unit:'centimeter'}, carried_value_exact:'0', input:json{a:0, b:0, kind:'measured_change', operation:'add', unit:'centimeter'}, source_result:'quantity(0,centimeter)', target_result:'result(0,quantity(0,centimeter),incorrect)', transform:'the magnitude with its unit centimeter written into the target''s unit slot'},
        seam_flags:[6],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).

% Adapter: integer_over_one_to_fraction_object
admitted_bridge(
    bridge{
        adapter:'integer_over_one_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'co_denominator_count_on_from_larger'},
        target:json{family:'fraction', kind:'add_numerator_denominator_comparison'},
        carried_role:'the whole number as the fraction over one',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:1}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:0}, json{path:'.right.d', value:2}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-1]', input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'0', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the whole number as the fraction over one'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'integer_over_one_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'co_denominator_count_on_from_larger'},
        target:json{family:'fraction', kind:'add_numerator_denominator_sum'},
        carried_role:'the whole number as the fraction over one',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:1}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:0}, json{path:'.right.d', value:2}]],
        witness:json{adapted_input:json{kind:'fraction_addend_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-1]', input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'0', target_result:'result(fraction(0,2),fraction(0,1),contextually_correct)', transform:'the whole number as the fraction over one'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'integer_over_one_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'co_denominator_count_on_from_larger'},
        target:json{family:'fraction', kind:'benchmark_fraction_comparison'},
        carried_role:'the whole number as the fraction over one',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:1}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:0}, json{path:'.right.d', value:2}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-1]', input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'0', target_result:'result(equivalent,equivalent,correct)', transform:'the whole number as the fraction over one'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'integer_over_one_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'co_denominator_count_on_from_larger'},
        target:json{family:'fraction', kind:'common_denominator_fraction_addition'},
        carried_role:'the whole number as the fraction over one',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:1}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:0}, json{path:'.right.d', value:2}]],
        witness:json{adapted_input:json{kind:'fraction_addend_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-1]', input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'0', target_result:'result(fraction(0,1),fraction(0,1),correct)', transform:'the whole number as the fraction over one'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'integer_over_one_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'co_denominator_count_on_from_larger'},
        target:json{family:'fraction', kind:'common_denominator_fraction_subtraction'},
        carried_role:'the whole number as the fraction over one',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:1}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:0}, json{path:'.right.d', value:2}]],
        witness:json{adapted_input:json{kind:'fraction_minuend_subtrahend', left:json{d:1, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-1]', input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'0', target_result:'result(fraction(0,1),fraction(0,1),correct)', transform:'the whole number as the fraction over one'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'integer_over_one_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'co_denominator_count_on_from_larger'},
        target:json{family:'fraction', kind:'common_unit_fraction_comparison'},
        carried_role:'the whole number as the fraction over one',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:1}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:0}, json{path:'.right.d', value:2}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-1]', input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'0', target_result:'result(equivalent,equivalent,correct)', transform:'the whole number as the fraction over one'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'integer_over_one_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'co_denominator_count_on_from_larger'},
        target:json{family:'fraction', kind:'gap_thinking_fraction_comparison'},
        carried_role:'the whole number as the fraction over one',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:1}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:0}, json{path:'.right.d', value:2}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-1]', input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'0', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the whole number as the fraction over one'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'integer_over_one_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'co_denominator_count_on_from_larger'},
        target:json{family:'fraction', kind:'number_line_count_marks_not_intervals'},
        carried_role:'the whole number as the fraction over one',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:1}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:0}, json{path:'.right.d', value:2}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-1]', input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'0', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the whole number as the fraction over one'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'integer_over_one_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'co_denominator_count_on_from_larger'},
        target:json{family:'fraction', kind:'number_line_fraction_comparison'},
        carried_role:'the whole number as the fraction over one',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:1}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:0}, json{path:'.right.d', value:2}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-1]', input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'0', target_result:'result(equivalent,equivalent,correct)', transform:'the whole number as the fraction over one'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).

% Adapter: project_quotient
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'addition', kind:'base_ones_chunking'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(31,31,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'addition', kind:'column_addition_with_carrying'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(31,31,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'addition', kind:'count_all_when_count_on_available'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(31,31,correct_but_inefficient)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'addition', kind:'count_on_from_larger'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(31,31,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'addition', kind:'dropped_ones_chunk'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(30,31,incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'addition', kind:'round_then_adjust'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(31,31,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'addition', kind:'round_without_adjusting'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(40,31,incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'division', kind:'inverse_fact_decomposition'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(quotient_remainder(0,0),quotient_remainder(0,0),correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'division', kind:'long_division'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(long_division_result("0",0),long_division_result("0",0),correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'division', kind:'partial_quotient_chunking'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(quotient_remainder(0,0),quotient_remainder(0,0),correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'division', kind:'sum_dividend_and_divisor'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(digit_sum_numeral(31),quotient_remainder(0,0),incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'integer', kind:'signed_addition_with_sign_relation'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(31,31,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[3],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'multiplication', kind:'add_counts_without_composite_unit'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(31,0,incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'multiplication', kind:'add_instead_of_multiply'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(31,0,incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'multiplication', kind:'commute_factors_preserve_product'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(0,0,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'multiplication', kind:'coordinate_groups_items'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(0,0,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'multiplication', kind:'distribute_group_size_split'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(0,0,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'multiplication', kind:'multiplication_fact_retrieval'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(0,0,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'multiplication', kind:'repeat_equal_groups'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(0,0,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'multiplication', kind:'repeat_group_size_by_itself'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(961,0,incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'multiplication', kind:'rigid_factor_order_roles'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(rejected_commutation(31,0),0,incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'multiplication', kind:'sequential_recompute_commuted_products'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(recomputed_both_products(0,0),structural_equivalence(0),incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'subtraction', kind:'add_instead_of_subtract_column'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:2}], [json{path:'.a', value:28}], [json{path:'.a', value:0}]],
        witness:json{adapted_input:json{a:2, b:0}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(2,2,incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'subtraction', kind:'answer_as_endpoint_count_up'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:2}], [json{path:'.a', value:28}], [json{path:'.a', value:0}]],
        witness:json{adapted_input:json{a:2, b:0}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(2,2,incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'subtraction', kind:'compare_by_matching_difference'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(31,31,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'subtraction', kind:'compare_returns_larger_count'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(31,31,incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'subtraction', kind:'count_up_missing_addend'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:2}], [json{path:'.a', value:28}], [json{path:'.a', value:0}]],
        witness:json{adapted_input:json{a:2, b:0}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(2,2,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'subtraction', kind:'take_away_base_ones'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:2}], [json{path:'.a', value:28}], [json{path:'.a', value:0}]],
        witness:json{adapted_input:json{a:2, b:0}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(2,2,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'addition', kind:'base_ones_chunking'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(31,31,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'addition', kind:'column_addition_with_carrying'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(31,31,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'addition', kind:'count_all_when_count_on_available'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(31,31,correct_but_inefficient)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'addition', kind:'count_on_from_larger'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(31,31,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'addition', kind:'dropped_ones_chunk'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(30,31,incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'addition', kind:'round_then_adjust'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(31,31,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'addition', kind:'round_without_adjusting'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(40,31,incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'division', kind:'inverse_fact_decomposition'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(quotient_remainder(0,0),quotient_remainder(0,0),correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'division', kind:'long_division'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(long_division_result("0",0),long_division_result("0",0),correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'division', kind:'measure_groups_of_size'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(quotient_remainder(0,0),quotient_remainder(0,0),correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'division', kind:'sum_dividend_and_divisor'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(digit_sum_numeral(31),quotient_remainder(0,0),incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'integer', kind:'signed_addition_with_sign_relation'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(31,31,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[3],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'multiplication', kind:'add_counts_without_composite_unit'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(31,0,incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'multiplication', kind:'add_instead_of_multiply'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(31,0,incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'multiplication', kind:'commute_factors_preserve_product'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(0,0,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'multiplication', kind:'coordinate_groups_items'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(0,0,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'multiplication', kind:'distribute_group_size_split'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(0,0,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'multiplication', kind:'multiplication_fact_retrieval'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(0,0,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'multiplication', kind:'repeat_equal_groups'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(0,0,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'multiplication', kind:'repeat_group_size_by_itself'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(961,0,incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'multiplication', kind:'rigid_factor_order_roles'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(rejected_commutation(31,0),0,incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'multiplication', kind:'sequential_recompute_commuted_products'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(recomputed_both_products(0,0),structural_equivalence(0),incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'subtraction', kind:'add_instead_of_subtract_column'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:2}], [json{path:'.a', value:28}], [json{path:'.a', value:0}]],
        witness:json{adapted_input:json{a:2, b:0}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(2,2,incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'subtraction', kind:'answer_as_endpoint_count_up'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:2}], [json{path:'.a', value:28}], [json{path:'.a', value:0}]],
        witness:json{adapted_input:json{a:2, b:0}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(2,2,incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'subtraction', kind:'compare_by_matching_difference'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(31,31,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'subtraction', kind:'compare_returns_larger_count'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:0, b:31}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(31,31,incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'subtraction', kind:'count_up_missing_addend'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:2}], [json{path:'.a', value:28}], [json{path:'.a', value:0}]],
        witness:json{adapted_input:json{a:2, b:0}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(2,2,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'subtraction', kind:'take_away_base_ones'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:2}], [json{path:'.a', value:28}], [json{path:'.a', value:0}]],
        witness:json{adapted_input:json{a:2, b:0}, carried_value_exact:'0', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(2,2,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'addition', kind:'base_ones_chunking'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(8,8,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'addition', kind:'column_addition_with_carrying'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(8,8,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'addition', kind:'count_all_when_count_on_available'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(8,8,correct_but_inefficient)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'addition', kind:'count_on_from_larger'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(8,8,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'addition', kind:'dropped_ones_chunk'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(1,8,incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'addition', kind:'round_then_adjust'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(8,8,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'addition', kind:'round_without_adjusting'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(11,8,incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'division', kind:'divide_larger_by_smaller'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(quotient_remainder(7,0),quotient_remainder(0,1),incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'division', kind:'inverse_fact_decomposition'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(quotient_remainder(0,1),quotient_remainder(0,1),correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'division', kind:'long_division'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(long_division_result("0.1428",4),long_division_result("0.1428",4),correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'division', kind:'measure_groups_of_size'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(quotient_remainder(0,1),quotient_remainder(0,1),correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'division', kind:'partial_quotient_chunking'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(quotient_remainder(0,1),quotient_remainder(0,1),correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'division', kind:'sum_dividend_and_divisor'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(digit_sum_numeral(8),quotient_remainder(0,1),incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'fraction', kind:'clear_inner_referent'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(fraction(1,7),fraction(1,7),incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[1],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'fraction', kind:'recursive_partition'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(fraction(1,7),fraction(1,7),correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[1],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'fraction', kind:'unit_fraction_iteration'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(fraction(1,7),fraction(1,7),correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[1],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'fraction', kind:'whole_number_grab'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(whole_number(1),fraction(1,7),incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[1],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'geometry', kind:'area_as_perimeter_count'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(boundary_units(16),square_units(7),incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(square_units(7),square_units(7),correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'integer', kind:'signed_addition_with_sign_relation'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(8,8,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[3],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'add_counts_without_composite_unit'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(8,7,incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'add_instead_of_multiply'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(8,7,incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(candidate_common_multiple(8),common_multiples(generator(step(7)),witnesses([7,14,21,28,35]),least(7)),incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'common_multiple_sequence'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(common_multiples(generator(step(7)),witnesses([7,14,21,28,35]),least(7)),common_multiples(generator(step(7)),witnesses([7,14,21,28,35]),least(7)),correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'commute_factors_preserve_product'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(7,7,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'coordinate_groups_items'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(7,7,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'distribute_group_size_split'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(7,7,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'multiplication_fact_retrieval'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(7,7,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'repeat_equal_groups'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(7,7,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'repeat_group_size_by_itself'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(49,7,incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'rigid_factor_order_roles'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(rejected_commutation(7,1),7,incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'sequential_recompute_commuted_products'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(recomputed_both_products(7,7),structural_equivalence(7),incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'ratio', kind:'additive_extension_of_ratio'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(ratio_pair(2,8),ratio_pair(2,14),incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'ratio', kind:'scale_ratio_unit'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(ratio_pair(2,14),ratio_pair(2,14),correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'subtraction', kind:'compare_by_matching_difference'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(6,6,correct)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_quotient',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'subtraction', kind:'compare_returns_larger_count'},
        carried_role:'the quotient role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:1, b:7}, carried_value_exact:'1', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(7,6,incorrect)', transform:'the quotient role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).

% Adapter: project_remainder
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'addition', kind:'base_ones_chunking'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(33,33,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'addition', kind:'column_addition_with_carrying'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(33,33,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'addition', kind:'count_all_when_count_on_available'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(33,33,correct_but_inefficient)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'addition', kind:'count_on_from_larger'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(33,33,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'addition', kind:'dropped_ones_chunk'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(32,33,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'addition', kind:'round_then_adjust'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(33,33,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'addition', kind:'round_without_adjusting'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(41,33,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'division', kind:'inverse_fact_decomposition'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(quotient_remainder(0,2),quotient_remainder(0,2),correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'division', kind:'long_division'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(long_division_result("0.0645",5),long_division_result("0.0645",5),correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'division', kind:'partial_quotient_chunking'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(quotient_remainder(0,2),quotient_remainder(0,2),correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'division', kind:'sum_dividend_and_divisor'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(digit_sum_numeral(33),quotient_remainder(0,2),incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'integer', kind:'signed_addition_with_sign_relation'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(33,33,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[3],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'multiplication', kind:'add_counts_without_composite_unit'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(33,62,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'multiplication', kind:'add_instead_of_multiply'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(33,62,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'multiplication', kind:'commute_factors_preserve_product'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(62,62,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'multiplication', kind:'coordinate_groups_items'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(62,62,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'multiplication', kind:'distribute_group_size_split'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(62,62,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'multiplication', kind:'multiplication_fact_retrieval'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(62,62,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'multiplication', kind:'repeat_equal_groups'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(62,62,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'multiplication', kind:'repeat_group_size_by_itself'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(961,62,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'multiplication', kind:'rigid_factor_order_roles'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(rejected_commutation(31,2),62,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'multiplication', kind:'sequential_recompute_commuted_products'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(recomputed_both_products(62,62),structural_equivalence(62),incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'subtraction', kind:'add_instead_of_subtract_column'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:2}], [json{path:'.a', value:28}], [json{path:'.a', value:0}]],
        witness:json{adapted_input:json{a:2, b:2}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(4,0,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'subtraction', kind:'answer_as_endpoint_count_up'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:2}], [json{path:'.a', value:28}], [json{path:'.a', value:0}]],
        witness:json{adapted_input:json{a:2, b:2}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(2,0,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'subtraction', kind:'compare_by_matching_difference'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(29,29,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'measure_groups_of_size'},
        target:json{family:'subtraction', kind:'compare_returns_larger_count'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(31,29,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'addition', kind:'base_ones_chunking'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(33,33,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'addition', kind:'column_addition_with_carrying'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(33,33,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'addition', kind:'count_all_when_count_on_available'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(33,33,correct_but_inefficient)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'addition', kind:'count_on_from_larger'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(33,33,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'addition', kind:'dropped_ones_chunk'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(32,33,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'addition', kind:'round_then_adjust'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(33,33,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'addition', kind:'round_without_adjusting'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(41,33,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'division', kind:'inverse_fact_decomposition'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(quotient_remainder(0,2),quotient_remainder(0,2),correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'division', kind:'long_division'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(long_division_result("0.0645",5),long_division_result("0.0645",5),correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'division', kind:'measure_groups_of_size'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(quotient_remainder(0,2),quotient_remainder(0,2),correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'division', kind:'sum_dividend_and_divisor'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(digit_sum_numeral(33),quotient_remainder(0,2),incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'integer', kind:'signed_addition_with_sign_relation'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(33,33,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[3],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'multiplication', kind:'add_counts_without_composite_unit'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(33,62,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'multiplication', kind:'add_instead_of_multiply'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(33,62,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'multiplication', kind:'commute_factors_preserve_product'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(62,62,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'multiplication', kind:'coordinate_groups_items'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(62,62,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'multiplication', kind:'distribute_group_size_split'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(62,62,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'multiplication', kind:'multiplication_fact_retrieval'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(62,62,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'multiplication', kind:'repeat_equal_groups'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(62,62,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'multiplication', kind:'repeat_group_size_by_itself'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(961,62,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'multiplication', kind:'rigid_factor_order_roles'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(rejected_commutation(31,2),62,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'multiplication', kind:'sequential_recompute_commuted_products'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(recomputed_both_products(62,62),structural_equivalence(62),incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'subtraction', kind:'add_instead_of_subtract_column'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:2}], [json{path:'.a', value:28}], [json{path:'.a', value:0}]],
        witness:json{adapted_input:json{a:2, b:2}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(4,0,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'subtraction', kind:'answer_as_endpoint_count_up'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:2}], [json{path:'.a', value:28}], [json{path:'.a', value:0}]],
        witness:json{adapted_input:json{a:2, b:2}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(2,0,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'subtraction', kind:'compare_by_matching_difference'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(29,29,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'partial_quotient_chunking'},
        target:json{family:'subtraction', kind:'compare_returns_larger_count'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:1}]],
        witness:json{adapted_input:json{a:2, b:31}, carried_value_exact:'2', input:json{a:2, b:31}, source_result:'quotient_remainder(0,2)', target_result:'result(31,29,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'addition', kind:'base_ones_chunking'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(13,13,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'addition', kind:'column_addition_with_carrying'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(13,13,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'addition', kind:'count_all_when_count_on_available'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(13,13,correct_but_inefficient)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'addition', kind:'count_on_from_larger'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(13,13,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'addition', kind:'dropped_ones_chunk'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(6,13,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'addition', kind:'round_then_adjust'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(13,13,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'addition', kind:'round_without_adjusting'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(16,13,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'division', kind:'divide_larger_by_smaller'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(quotient_remainder(1,1),quotient_remainder(0,6),incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'division', kind:'inverse_fact_decomposition'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(quotient_remainder(0,6),quotient_remainder(0,6),correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'division', kind:'long_division'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(long_division_result("0.8571",3),long_division_result("0.8571",3),correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'division', kind:'measure_groups_of_size'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(quotient_remainder(0,6),quotient_remainder(0,6),correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'division', kind:'partial_quotient_chunking'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(quotient_remainder(0,6),quotient_remainder(0,6),correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'division', kind:'stop_after_one_known_fact'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:13}], [json{path:'.a', value:21}], [json{path:'.a', value:13}]],
        witness:json{adapted_input:json{a:13, b:6}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(quotient_remainder(2,1),quotient_remainder(2,1),contextually_correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'division', kind:'sum_dividend_and_divisor'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(digit_sum_numeral(13),quotient_remainder(0,6),incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'fraction', kind:'clear_inner_referent'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(fraction(1,7),fraction(1,42),incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[1],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'fraction', kind:'improper_fraction_chain_loss'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:13}], [json{path:'.a', value:21}], [json{path:'.a', value:13}]],
        witness:json{adapted_input:json{a:13, b:6}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(reset_fraction(fraction(13,13)),fraction(13,6),incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[1],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'fraction', kind:'improper_fraction_iteration'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:13}], [json{path:'.a', value:21}], [json{path:'.a', value:13}]],
        witness:json{adapted_input:json{a:13, b:6}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(fraction(13,6),fraction(13,6),correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[1],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'fraction', kind:'iterate_given_overshoot'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:13}], [json{path:'.a', value:21}], [json{path:'.a', value:13}]],
        witness:json{adapted_input:json{a:13, b:6}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(overshot(fraction(13,6)),whole_recovered(unit(whole)),incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[1],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'fraction', kind:'recursive_partition'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(fraction(1,42),fraction(1,42),correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[1],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'fraction', kind:'unit_fraction_iteration'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(fraction(6,7),fraction(6,7),correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[1],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'fraction', kind:'whole_number_grab'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(whole_number(6),fraction(6,7),incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[1],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'geometry', kind:'area_as_perimeter_count'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(boundary_units(26),square_units(42),incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(square_units(42),square_units(42),correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'integer', kind:'signed_addition_with_sign_relation'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(13,13,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[3],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'add_counts_without_composite_unit'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(13,42,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'add_instead_of_multiply'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(13,42,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(candidate_common_multiple(13),common_multiples(generator(step(42)),witnesses([42,84,126,168,210]),least(42)),incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'common_multiple_sequence'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(common_multiples(generator(step(42)),witnesses([42,84,126,168,210]),least(42)),common_multiples(generator(step(42)),witnesses([42,84,126,168,210]),least(42)),correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'commute_factors_preserve_product'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(42,42,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'coordinate_groups_items'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(42,42,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'distribute_group_size_split'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(42,42,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'drop_regrouping_remainder'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:13}], [json{path:'.a', value:21}], [json{path:'.a', value:13}]],
        witness:json{adapted_input:json{a:13, b:6}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(70,78,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'factors_of_first_number_only'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:13}], [json{path:'.a', value:21}], [json{path:'.a', value:13}]],
        witness:json{adapted_input:json{a:13, b:6}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(common_factors([1,13]),common_factors([1],greatest(1)),incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'known_product_adjustment'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:13}], [json{path:'.a', value:21}], [json{path:'.a', value:13}]],
        witness:json{adapted_input:json{a:13, b:6}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(78,78,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'known_product_without_adjustment'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:13}], [json{path:'.a', value:21}], [json{path:'.a', value:13}]],
        witness:json{adapted_input:json{a:13, b:6}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(72,78,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'multiplication_fact_retrieval'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(42,42,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'repeat_equal_groups'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(42,42,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'repeat_group_size_by_itself'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(49,42,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'rigid_factor_order_roles'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(rejected_commutation(7,6),42,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'multiplication', kind:'sequential_recompute_commuted_products'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(recomputed_both_products(42,42),structural_equivalence(42),incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'ratio', kind:'additive_extension_of_ratio'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(ratio_pair(12,13),ratio_pair(12,14),incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'ratio', kind:'scale_ratio_unit'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(ratio_pair(12,14),ratio_pair(12,14),correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'subtraction', kind:'add_instead_of_subtract_column'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:13}], [json{path:'.a', value:21}], [json{path:'.a', value:13}]],
        witness:json{adapted_input:json{a:13, b:6}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(19,7,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'subtraction', kind:'answer_as_endpoint_count_up'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:13}], [json{path:'.a', value:21}], [json{path:'.a', value:13}]],
        witness:json{adapted_input:json{a:13, b:6}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(13,7,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'subtraction', kind:'compare_by_matching_difference'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(1,1,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'subtraction', kind:'compare_returns_larger_count'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:7}], [json{path:'.b', value:1}], [json{path:'.b', value:9}]],
        witness:json{adapted_input:json{a:6, b:7}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(7,1,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'subtraction', kind:'count_up_missing_addend'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:13}], [json{path:'.a', value:21}], [json{path:'.a', value:13}]],
        witness:json{adapted_input:json{a:13, b:6}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(7,7,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'subtraction', kind:'slide_subtrahend_only'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:13}], [json{path:'.a', value:21}], [json{path:'.a', value:13}]],
        witness:json{adapted_input:json{a:13, b:6}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(3,7,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'subtraction', kind:'sliding_constant_difference'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:13}], [json{path:'.a', value:21}], [json{path:'.a', value:13}]],
        witness:json{adapted_input:json{a:13, b:6}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(7,7,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_first_partial_quotient'},
        target:json{family:'subtraction', kind:'take_away_base_ones'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:13}], [json{path:'.a', value:21}], [json{path:'.a', value:13}]],
        witness:json{adapted_input:json{a:13, b:6}, carried_value_exact:'6', input:json{a:13, b:7}, source_result:'quotient_remainder(1,6)', target_result:'result(7,7,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_one_known_fact'},
        target:json{family:'fraction', kind:'improper_fraction_chain_loss'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:4}], [json{path:'.a', value:9}], [json{path:'.a', value:11}]],
        witness:json{adapted_input:json{a:4, b:2}, carried_value_exact:'2', input:json{a:4, b:1}, source_result:'quotient_remainder(2,2)', target_result:'result(reset_fraction(fraction(4,4)),fraction(4,2),incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[1],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_one_known_fact'},
        target:json{family:'fraction', kind:'improper_fraction_iteration'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:4}], [json{path:'.a', value:9}], [json{path:'.a', value:11}]],
        witness:json{adapted_input:json{a:4, b:2}, carried_value_exact:'2', input:json{a:4, b:1}, source_result:'quotient_remainder(2,2)', target_result:'result(fraction(4,2),fraction(4,2),correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[1],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_one_known_fact'},
        target:json{family:'fraction', kind:'iterate_given_overshoot'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:4}], [json{path:'.a', value:9}], [json{path:'.a', value:11}]],
        witness:json{adapted_input:json{a:4, b:2}, carried_value_exact:'2', input:json{a:4, b:1}, source_result:'quotient_remainder(2,2)', target_result:'result(overshot(fraction(4,2)),whole_recovered(unit(whole)),incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[1],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_one_known_fact'},
        target:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:4}], [json{path:'.a', value:9}], [json{path:'.a', value:11}]],
        witness:json{adapted_input:json{a:4, b:2}, carried_value_exact:'2', input:json{a:4, b:1}, source_result:'quotient_remainder(2,2)', target_result:'result(candidate_common_multiple(6),common_multiples(generator(step(4)),witnesses([4,8,12,16,20]),least(4)),incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_one_known_fact'},
        target:json{family:'multiplication', kind:'factors_of_first_number_only'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:4}], [json{path:'.a', value:9}], [json{path:'.a', value:11}]],
        witness:json{adapted_input:json{a:4, b:2}, carried_value_exact:'2', input:json{a:4, b:1}, source_result:'quotient_remainder(2,2)', target_result:'result(common_factors([1,2,4]),common_factors([1,2],greatest(2)),incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_one_known_fact'},
        target:json{family:'multiplication', kind:'known_product_adjustment'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:4}], [json{path:'.a', value:9}], [json{path:'.a', value:11}]],
        witness:json{adapted_input:json{a:4, b:2}, carried_value_exact:'2', input:json{a:4, b:1}, source_result:'quotient_remainder(2,2)', target_result:'result(8,8,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_one_known_fact'},
        target:json{family:'multiplication', kind:'known_product_without_adjustment'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:4}], [json{path:'.a', value:9}], [json{path:'.a', value:11}]],
        witness:json{adapted_input:json{a:4, b:2}, carried_value_exact:'2', input:json{a:4, b:1}, source_result:'quotient_remainder(2,2)', target_result:'result(6,8,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_one_known_fact'},
        target:json{family:'ratio', kind:'additive_extension_of_ratio'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:4}], [json{path:'.a', value:9}], [json{path:'.a', value:11}]],
        witness:json{adapted_input:json{a:4, b:2}, carried_value_exact:'2', input:json{a:4, b:1}, source_result:'quotient_remainder(2,2)', target_result:'result(ratio_pair(8,6),ratio_pair(8,4),incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_one_known_fact'},
        target:json{family:'subtraction', kind:'add_instead_of_subtract_column'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:4}], [json{path:'.a', value:9}], [json{path:'.a', value:11}]],
        witness:json{adapted_input:json{a:4, b:2}, carried_value_exact:'2', input:json{a:4, b:1}, source_result:'quotient_remainder(2,2)', target_result:'result(6,2,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_one_known_fact'},
        target:json{family:'subtraction', kind:'answer_as_endpoint_count_up'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:4}], [json{path:'.a', value:9}], [json{path:'.a', value:11}]],
        witness:json{adapted_input:json{a:4, b:2}, carried_value_exact:'2', input:json{a:4, b:1}, source_result:'quotient_remainder(2,2)', target_result:'result(4,2,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_one_known_fact'},
        target:json{family:'subtraction', kind:'compare_returns_larger_count'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:4}], [json{path:'.a', value:9}], [json{path:'.a', value:11}]],
        witness:json{adapted_input:json{a:4, b:2}, carried_value_exact:'2', input:json{a:4, b:1}, source_result:'quotient_remainder(2,2)', target_result:'result(4,2,incorrect)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_one_known_fact'},
        target:json{family:'subtraction', kind:'count_up_missing_addend'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:4}], [json{path:'.a', value:9}], [json{path:'.a', value:11}]],
        witness:json{adapted_input:json{a:4, b:2}, carried_value_exact:'2', input:json{a:4, b:1}, source_result:'quotient_remainder(2,2)', target_result:'result(2,2,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_one_known_fact'},
        target:json{family:'subtraction', kind:'sliding_constant_difference'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:4}], [json{path:'.a', value:9}], [json{path:'.a', value:11}]],
        witness:json{adapted_input:json{a:4, b:2}, carried_value_exact:'2', input:json{a:4, b:1}, source_result:'quotient_remainder(2,2)', target_result:'result(2,2,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_remainder',
        license_class:'p',
        source:json{family:'division', kind:'stop_after_one_known_fact'},
        target:json{family:'subtraction', kind:'take_away_base_ones'},
        carried_role:'the remainder role of quotient_remainder/2',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:4}], [json{path:'.a', value:9}], [json{path:'.a', value:11}]],
        witness:json{adapted_input:json{a:4, b:2}, carried_value_exact:'2', input:json{a:4, b:1}, source_result:'quotient_remainder(2,2)', target_result:'result(2,2,correct)', transform:'the remainder role of quotient_remainder/2'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).

% Adapter: project_wrapped_magnitude
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'counting', kind:'enumerate_collection_one_to_one'},
        target:json{family:'counting', kind:'inscribe_cardinality'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.base', value:2}], [json{path:'.base', value:9}], [json{path:'.base', value:5}]],
        witness:json{adapted_input:json{base:2, count:4, kind:'cardinality'}, carried_value_exact:'4', input:json{base:2, count:4, kind:'cardinality'}, source_result:'cardinality(4)', target_result:'result(numeral(2,positive,radix(3),[digit(1,"1"),digit(0,"0"),digit(0,"0")]),numeral(2,positive,radix(3),[digit(1,"1"),digit(0,"0"),digit(0,"0")]),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'counting', kind:'enumerate_collection_one_to_one'},
        target:json{family:'counting', kind:'recursive_place_value_inscription'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.base', value:2}], [json{path:'.base', value:9}], [json{path:'.base', value:5}]],
        witness:json{adapted_input:json{base:2, count:4, kind:'cardinality'}, carried_value_exact:'4', input:json{base:2, count:4, kind:'cardinality'}, source_result:'cardinality(4)', target_result:'result(numeral(2,positive,radix(3),[digit(1,"1"),digit(0,"0"),digit(0,"0")]),numeral(2,positive,radix(3),[digit(1,"1"),digit(0,"0"),digit(0,"0")]),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'addition', kind:'base_ones_chunking'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(2,2,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'addition', kind:'column_addition_with_carrying'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(2,2,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'addition', kind:'count_all_when_count_on_available'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(2,2,correct_but_inefficient)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'addition', kind:'count_on_from_larger'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(2,2,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'addition', kind:'dropped_ones_chunk'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(1,2,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'addition', kind:'round_then_adjust'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(2,2,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'addition', kind:'round_without_adjusting'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(11,2,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'division', kind:'divide_larger_by_smaller'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(quotient_remainder(1,0),quotient_remainder(1,0),contextually_correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'division', kind:'inverse_fact_decomposition'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(quotient_remainder(1,0),quotient_remainder(1,0),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'division', kind:'long_division'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(long_division_result("1",0),long_division_result("1",0),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'division', kind:'measure_groups_of_size'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(quotient_remainder(1,0),quotient_remainder(1,0),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'division', kind:'partial_quotient_chunking'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(quotient_remainder(1,0),quotient_remainder(1,0),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'fraction', kind:'clear_inner_referent'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(fraction(1,1),fraction(1,1),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[1],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'fraction', kind:'recursive_partition'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(fraction(1,1),fraction(1,1),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[1],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'fraction', kind:'unit_fraction_iteration'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(fraction(1,1),fraction(1,1),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[1],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'fraction', kind:'whole_number_grab'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(whole_number(1),fraction(1,1),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[1],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'geometry', kind:'area_as_perimeter_count'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(boundary_units(4),square_units(1),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(square_units(1),square_units(1),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'integer', kind:'signed_addition_with_sign_relation'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(2,2,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[3],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'multiplication', kind:'add_counts_without_composite_unit'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(2,1,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'multiplication', kind:'add_instead_of_multiply'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(2,1,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'multiplication', kind:'common_factor_intersection'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(common_factors([1],greatest(1)),common_factors([1],greatest(1)),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'multiplication', kind:'common_multiple_sequence'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(common_multiples(generator(step(1)),witnesses([1,2,3,4,5]),least(1)),common_multiples(generator(step(1)),witnesses([1,2,3,4,5]),least(1)),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'multiplication', kind:'commute_factors_preserve_product'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(1,1,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'multiplication', kind:'coordinate_groups_items'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(1,1,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'multiplication', kind:'distribute_group_size_split'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(1,1,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'multiplication', kind:'multiplication_fact_retrieval'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(1,1,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'multiplication', kind:'repeat_equal_groups'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(1,1,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'multiplication', kind:'repeat_group_size_by_itself'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(1,1,contextually_correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'multiplication', kind:'rigid_factor_order_roles'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(rejected_commutation(1,1),1,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'multiplication', kind:'sequential_recompute_commuted_products'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(recomputed_both_products(1,1),structural_equivalence(1),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'ratio', kind:'scale_ratio_unit'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(ratio_pair(2,2),ratio_pair(2,2),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'subtraction', kind:'add_instead_of_subtract_column'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(2,0,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'subtraction', kind:'answer_as_endpoint_count_up'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(1,0,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'subtraction', kind:'compare_by_matching_difference'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(0,0,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'subtraction', kind:'compare_returns_larger_count'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:0}], [json{path:'.a', value:6}], [json{path:'.a', value:12}]],
        witness:json{adapted_input:json{a:0, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(1,1,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'subtraction', kind:'count_up_missing_addend'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(0,0,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'division', kind:'sum_dividend_and_divisor'},
        target:json{family:'subtraction', kind:'take_away_base_ones'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:10}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:0, b:1}, source_result:'digit_sum_numeral(1)', target_result:'result(0,0,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'addition', kind:'base_ones_chunking'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(2,2,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'addition', kind:'column_addition_with_carrying'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(2,2,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'addition', kind:'count_all_when_count_on_available'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(2,2,correct_but_inefficient)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'addition', kind:'count_on_from_larger'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(2,2,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'addition', kind:'dropped_ones_chunk'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(1,2,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'addition', kind:'round_then_adjust'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(2,2,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'addition', kind:'round_without_adjusting'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(11,2,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'division', kind:'divide_larger_by_smaller'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(quotient_remainder(1,0),quotient_remainder(1,0),contextually_correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[1],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'division', kind:'inverse_fact_decomposition'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(quotient_remainder(1,0),quotient_remainder(1,0),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[1],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'division', kind:'long_division'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(long_division_result("1",0),long_division_result("1",0),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[1],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'division', kind:'measure_groups_of_size'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(quotient_remainder(1,0),quotient_remainder(1,0),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[1],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'division', kind:'partial_quotient_chunking'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(quotient_remainder(1,0),quotient_remainder(1,0),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[1],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'division', kind:'sum_dividend_and_divisor'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(digit_sum_numeral(2),quotient_remainder(1,0),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[1],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'fraction', kind:'clear_inner_referent'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(fraction(1,1),fraction(1,1),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'fraction', kind:'recursive_partition'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(fraction(1,1),fraction(1,1),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'fraction', kind:'unit_fraction_iteration'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(fraction(1,1),fraction(1,1),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'geometry', kind:'area_as_perimeter_count'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(boundary_units(4),square_units(1),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(square_units(1),square_units(1),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'integer', kind:'signed_addition_with_sign_relation'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(2,2,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'multiplication', kind:'add_counts_without_composite_unit'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(2,1,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'multiplication', kind:'add_instead_of_multiply'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(2,1,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'multiplication', kind:'common_factor_intersection'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(common_factors([1],greatest(1)),common_factors([1],greatest(1)),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'multiplication', kind:'common_multiple_sequence'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(common_multiples(generator(step(1)),witnesses([1,2,3,4,5]),least(1)),common_multiples(generator(step(1)),witnesses([1,2,3,4,5]),least(1)),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'multiplication', kind:'commute_factors_preserve_product'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(1,1,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'multiplication', kind:'coordinate_groups_items'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(1,1,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'multiplication', kind:'distribute_group_size_split'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(1,1,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'multiplication', kind:'multiplication_fact_retrieval'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(1,1,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'multiplication', kind:'repeat_equal_groups'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(1,1,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'multiplication', kind:'repeat_group_size_by_itself'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(1,1,contextually_correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'multiplication', kind:'rigid_factor_order_roles'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(rejected_commutation(1,1),1,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'multiplication', kind:'sequential_recompute_commuted_products'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(recomputed_both_products(1,1),structural_equivalence(1),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'ratio', kind:'scale_ratio_unit'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(ratio_pair(2,2),ratio_pair(2,2),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'fraction', kind:'whole_number_grab'},
        target:json{family:'subtraction', kind:'compare_by_matching_difference'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:1}], [json{path:'.b', value:4}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:1, b:1}, carried_value_exact:'1', input:json{a:1, b:1}, source_result:'whole_number(1)', target_result:'result(0,0,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'addition', kind:'base_ones_chunking'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(97,97,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'addition', kind:'column_addition_with_carrying'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(97,97,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'addition', kind:'count_all_when_count_on_available'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(97,97,correct_but_inefficient)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'addition', kind:'count_on_from_larger'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(97,97,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'addition', kind:'dropped_ones_chunk'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(96,97,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'addition', kind:'round_then_adjust'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(97,97,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'addition', kind:'round_without_adjusting'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(101,97,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'division', kind:'divide_larger_by_smaller'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(quotient_remainder(2,4),quotient_remainder(2,4),contextually_correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'division', kind:'inverse_fact_decomposition'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(quotient_remainder(2,4),quotient_remainder(2,4),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'division', kind:'long_division'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(long_division_result("2.1290",10),long_division_result("2.1290",10),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'division', kind:'measure_groups_of_size'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(quotient_remainder(2,4),quotient_remainder(2,4),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'division', kind:'partial_quotient_chunking'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(quotient_remainder(2,4),quotient_remainder(2,4),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'division', kind:'share_into_divisor_groups'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:2}], [json{path:'.a', value:28}], [json{path:'.a', value:2}]],
        witness:json{adapted_input:json{a:2, b:66}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(1,quotient_remainder(0,2),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'division', kind:'stop_after_first_partial_quotient'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(quotient_remainder(2,4),quotient_remainder(2,4),contextually_correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'division', kind:'stop_after_one_known_fact'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(quotient_remainder(2,4),quotient_remainder(2,4),contextually_correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'division', kind:'sum_dividend_and_divisor'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(digit_sum_numeral(97),quotient_remainder(2,4),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'fraction', kind:'clear_inner_referent'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(fraction(1,31),fraction(1,2046),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'fraction', kind:'improper_fraction_chain_loss'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(reset_fraction(fraction(66,66)),fraction(66,31),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'fraction', kind:'improper_fraction_iteration'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(fraction(66,31),fraction(66,31),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'fraction', kind:'iterate_given_overshoot'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(overshot(fraction(66,31)),whole_recovered(unit(whole)),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'fraction', kind:'recursive_partition'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(fraction(1,2046),fraction(1,2046),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'fraction', kind:'unit_fraction_iteration'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(fraction(66,31),fraction(66,31),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'fraction', kind:'whole_number_grab'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(whole_number(66),fraction(66,31),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'geometry', kind:'angle_as_ray_length'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[], [], []],
        witness:json{adapted_input:json{degrees:66, kind:'angle_measure'}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(misread_as_larger(angle_measure(66)),angle_measure(66),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[6],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'geometry', kind:'angle_turn_measurement'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[], [], []],
        witness:json{adapted_input:json{degrees:66, kind:'angle_measure'}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(angle_measure(66),angle_measure(66),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[6],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(square_units(2046),square_units(2046),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[6],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'integer', kind:'signed_addition_with_sign_relation'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(97,97,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'multiplication', kind:'add_counts_without_composite_unit'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(97,2046,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'multiplication', kind:'add_instead_of_multiply'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(97,2046,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(candidate_common_multiple(97),common_multiples(generator(step(2046)),witnesses([2046,4092,6138,8184,10230]),least(2046)),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'multiplication', kind:'common_factor_intersection'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(common_factors([1],greatest(1)),common_factors([1],greatest(1)),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'multiplication', kind:'common_multiple_sequence'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(common_multiples(generator(step(2046)),witnesses([2046,4092,6138,8184,10230]),least(2046)),common_multiples(generator(step(2046)),witnesses([2046,4092,6138,8184,10230]),least(2046)),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'multiplication', kind:'commute_factors_preserve_product'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(2046,2046,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'multiplication', kind:'context_free_fact_family_guess'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(alternate_factor_pair(2,1023,2046),factor_pair(66,31,2046),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'multiplication', kind:'coordinate_groups_items'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(2046,2046,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'multiplication', kind:'distribute_group_size_split'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(2046,2046,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'multiplication', kind:'drop_second_partial_product'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(660,2046,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'multiplication', kind:'factors_of_first_number_only'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(common_factors([1,2,3,6,11,22,33,66]),common_factors([1],greatest(1)),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'multiplication', kind:'known_product_adjustment'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(2046,2046,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'multiplication', kind:'known_product_without_adjustment'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(2015,2046,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'multiplication', kind:'multiplication_fact_retrieval'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(2046,2046,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'multiplication', kind:'repeat_equal_groups'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(2046,2046,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'multiplication', kind:'repeat_group_size_by_itself'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(961,2046,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'multiplication', kind:'rigid_factor_order_roles'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(rejected_commutation(31,66),2046,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'multiplication', kind:'sequential_recompute_commuted_products'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(recomputed_both_products(2046,2046),structural_equivalence(2046),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'ratio', kind:'additive_extension_of_ratio'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(ratio_pair(132,97),ratio_pair(132,62),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'ratio', kind:'scale_ratio_unit'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(ratio_pair(132,62),ratio_pair(132,62),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'subtraction', kind:'add_instead_of_subtract_column'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(97,35,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'subtraction', kind:'answer_as_endpoint_count_up'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(66,35,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'subtraction', kind:'compare_by_matching_difference'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(35,35,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'subtraction', kind:'compare_returns_larger_count'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(66,35,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'subtraction', kind:'count_up_missing_addend'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(35,35,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'area_as_perimeter_count'},
        target:json{family:'subtraction', kind:'take_away_base_ones'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:66, b:31}, carried_value_exact:'66', input:json{a:2, b:31}, source_result:'boundary_units(66)', target_result:'result(35,35,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'addition', kind:'base_ones_chunking'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(93,93,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'addition', kind:'column_addition_with_carrying'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(93,93,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'addition', kind:'count_all_when_count_on_available'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(93,93,correct_but_inefficient)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'addition', kind:'count_on_from_larger'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(93,93,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'addition', kind:'dropped_ones_chunk'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(92,93,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'addition', kind:'round_then_adjust'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(93,93,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'addition', kind:'round_without_adjusting'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(101,93,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'division', kind:'divide_larger_by_smaller'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(quotient_remainder(2,0),quotient_remainder(2,0),contextually_correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'division', kind:'fair_share_equal_groups'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(2,2,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'division', kind:'inverse_fact_decomposition'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(quotient_remainder(2,0),quotient_remainder(2,0),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'division', kind:'long_division'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(long_division_result("2",0),long_division_result("2",0),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'division', kind:'measure_groups_of_size'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(quotient_remainder(2,0),quotient_remainder(2,0),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'division', kind:'missing_factor_known_product_search'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(2,2,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'division', kind:'missing_factor_repeated_addition'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(2,2,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'division', kind:'name_group_count_as_share_size'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(31,2,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'division', kind:'name_reached_total_as_quotient'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(62,2,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'division', kind:'partial_quotient_chunking'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(quotient_remainder(2,0),quotient_remainder(2,0),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'division', kind:'reject_known_product_match'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(rejected_known_product(31,2,62),2,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'division', kind:'share_into_divisor_groups'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:2}], [json{path:'.a', value:28}], [json{path:'.a', value:2}]],
        witness:json{adapted_input:json{a:2, b:62}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(1,quotient_remainder(0,2),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'division', kind:'stop_at_nearby_product_in_search'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(quotient_remainder(1,31),2,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'division', kind:'sum_dividend_and_divisor'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(digit_sum_numeral(93),quotient_remainder(2,0),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'fraction', kind:'clear_inner_referent'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(fraction(1,31),fraction(1,1922),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'fraction', kind:'improper_fraction_chain_loss'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(reset_fraction(fraction(62,62)),fraction(62,31),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'fraction', kind:'improper_fraction_iteration'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(fraction(62,31),fraction(62,31),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'fraction', kind:'iterate_given_overshoot'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(overshot(fraction(62,31)),whole_recovered(unit(whole)),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'fraction', kind:'recursive_partition'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(fraction(1,1922),fraction(1,1922),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'fraction', kind:'unit_fraction_iteration'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(fraction(62,31),fraction(62,31),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'fraction', kind:'whole_number_grab'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(whole_number(62),fraction(62,31),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'integer', kind:'signed_addition_with_sign_relation'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(93,93,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'multiplication', kind:'add_counts_without_composite_unit'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(93,1922,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'multiplication', kind:'add_instead_of_multiply'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(93,1922,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(candidate_common_multiple(93),common_multiples(generator(step(62)),witnesses([62,124,186,248,310]),least(62)),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'multiplication', kind:'common_factor_intersection'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(common_factors([1,31],greatest(31)),common_factors([1,31],greatest(31)),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'multiplication', kind:'common_multiple_sequence'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(common_multiples(generator(step(62)),witnesses([62,124,186,248,310]),least(62)),common_multiples(generator(step(62)),witnesses([62,124,186,248,310]),least(62)),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'multiplication', kind:'commute_factors_preserve_product'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(1922,1922,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'multiplication', kind:'context_free_fact_family_guess'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(alternate_factor_pair(2,961,1922),factor_pair(62,31,1922),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'multiplication', kind:'distribute_group_size_split'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(1922,1922,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'multiplication', kind:'drop_second_partial_product'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(620,1922,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'multiplication', kind:'factors_of_first_number_only'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(common_factors([1,2,31,62]),common_factors([1,31],greatest(31)),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'multiplication', kind:'known_product_adjustment'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(1922,1922,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'multiplication', kind:'known_product_without_adjustment'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(1891,1922,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'multiplication', kind:'multiplication_fact_retrieval'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(1922,1922,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'multiplication', kind:'repeat_equal_groups'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(1922,1922,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'multiplication', kind:'repeat_group_size_by_itself'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(961,1922,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'multiplication', kind:'rigid_factor_order_roles'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(rejected_commutation(31,62),1922,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'multiplication', kind:'sequential_recompute_commuted_products'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(recomputed_both_products(1922,1922),structural_equivalence(1922),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'ratio', kind:'additive_extension_of_ratio'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(ratio_pair(124,93),ratio_pair(124,62),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'ratio', kind:'scale_ratio_unit'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(ratio_pair(124,62),ratio_pair(124,62),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'subtraction', kind:'add_instead_of_subtract_column'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(93,31,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'subtraction', kind:'answer_as_endpoint_count_up'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(62,31,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'subtraction', kind:'compare_by_matching_difference'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(31,31,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'subtraction', kind:'compare_returns_larger_count'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(62,31,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'subtraction', kind:'count_up_missing_addend'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(31,31,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        target:json{family:'subtraction', kind:'take_away_base_ones'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:32}]],
        witness:json{adapted_input:json{a:62, b:31}, carried_value_exact:'62', input:json{a:2, b:31}, source_result:'square_units(62)', target_result:'result(31,31,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'geometry', kind:'rectangular_prism_volume_layer_iteration'},
        target:json{family:'geometry', kind:'rectangular_prism_missing_dimension_from_volume'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.length', value:1}, json{path:'.width', value:1}], [json{path:'.length', value:6}, json{path:'.width', value:3}], [json{path:'.length', value:10}, json{path:'.width', value:10}]],
        witness:json{adapted_input:json{kind:'volume_known_base', length:1, volume:1, width:1}, carried_value_exact:'1', input:json{height:1, kind:'rectangular_prism', length:1, width:1}, source_result:'cubic_units(1)', target_result:'result(dimension(1),dimension(1),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[6],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'addition', kind:'base_ones_chunking'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(64,64,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'addition', kind:'column_addition_with_carrying'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(64,64,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'addition', kind:'count_all_when_count_on_available'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(64,64,correct_but_inefficient)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'addition', kind:'count_on_from_larger'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(64,64,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'addition', kind:'dropped_ones_chunk'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(63,64,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'addition', kind:'round_then_adjust'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(64,64,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'addition', kind:'round_without_adjusting'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(71,64,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'algebraic', kind:'one_sided_equation_operation'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.a', value:2}, json{path:'.b', value:31}], [json{path:'.a', value:28}, json{path:'.b', value:46}], [json{path:'.a', value:5}, json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:2, b:31, c:33, kind:'linear_equation'}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(value(33r2),value(1),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'division', kind:'divide_larger_by_smaller'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(quotient_remainder(1,2),quotient_remainder(1,2),contextually_correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'division', kind:'inverse_fact_decomposition'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(quotient_remainder(1,2),quotient_remainder(1,2),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'division', kind:'long_division'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(long_division_result("1.0645",5),long_division_result("1.0645",5),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'division', kind:'measure_groups_of_size'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(quotient_remainder(1,2),quotient_remainder(1,2),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'division', kind:'partial_quotient_chunking'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(quotient_remainder(1,2),quotient_remainder(1,2),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'division', kind:'share_into_divisor_groups'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(2,quotient_remainder(1,2),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'division', kind:'stop_after_first_partial_quotient'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(quotient_remainder(1,2),quotient_remainder(1,2),contextually_correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'division', kind:'stop_after_one_known_fact'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(quotient_remainder(1,2),quotient_remainder(1,2),contextually_correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'division', kind:'sum_dividend_and_divisor'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(digit_sum_numeral(64),quotient_remainder(1,2),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'fraction', kind:'clear_inner_referent'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(fraction(1,31),fraction(1,1023),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'fraction', kind:'improper_fraction_chain_loss'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(reset_fraction(fraction(33,33)),fraction(33,31),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'fraction', kind:'improper_fraction_iteration'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(fraction(33,31),fraction(33,31),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'fraction', kind:'iterate_given_overshoot'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(overshot(fraction(33,31)),whole_recovered(unit(whole)),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'fraction', kind:'recursive_partition'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(fraction(1,1023),fraction(1,1023),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'fraction', kind:'unit_fraction_iteration'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(fraction(33,31),fraction(33,31),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'fraction', kind:'whole_number_grab'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(whole_number(33),fraction(33,31),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'geometry', kind:'angle_as_ray_length'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[], [], []],
        witness:json{adapted_input:json{degrees:33, kind:'angle_measure'}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(misread_as_larger(angle_measure(33)),angle_measure(33),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'geometry', kind:'angle_turn_measurement'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[], [], []],
        witness:json{adapted_input:json{degrees:33, kind:'angle_measure'}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(angle_measure(33),angle_measure(33),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'geometry', kind:'area_as_perimeter_count'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(boundary_units(128),square_units(1023),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'geometry', kind:'rectangle_area_unit_iteration'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(square_units(1023),square_units(1023),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'integer', kind:'signed_addition_with_sign_relation'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(64,64,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'multiplication', kind:'add_counts_without_composite_unit'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(64,1023,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'multiplication', kind:'add_instead_of_multiply'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(64,1023,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'multiplication', kind:'common_factor_intersection'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(common_factors([1],greatest(1)),common_factors([1],greatest(1)),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'multiplication', kind:'common_multiple_sequence'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(common_multiples(generator(step(1023)),witnesses([1023,2046,3069,4092,5115]),least(1023)),common_multiples(generator(step(1023)),witnesses([1023,2046,3069,4092,5115]),least(1023)),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'multiplication', kind:'commute_factors_preserve_product'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(1023,1023,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'multiplication', kind:'coordinate_groups_items'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(1023,1023,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'multiplication', kind:'distribute_group_size_split'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(1023,1023,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'multiplication', kind:'drop_second_partial_product'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(330,1023,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'multiplication', kind:'factors_of_first_number_only'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(common_factors([1,3,11,33]),common_factors([1],greatest(1)),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'multiplication', kind:'known_product_adjustment'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(1023,1023,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'multiplication', kind:'known_product_without_adjustment'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(992,1023,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'multiplication', kind:'multiplication_fact_retrieval'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(1023,1023,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'multiplication', kind:'repeat_equal_groups'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(1023,1023,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'multiplication', kind:'repeat_group_size_by_itself'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(961,1023,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'multiplication', kind:'rigid_factor_order_roles'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(rejected_commutation(31,33),1023,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'multiplication', kind:'sequential_recompute_commuted_products'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(recomputed_both_products(1023,1023),structural_equivalence(1023),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'ratio', kind:'additive_extension_of_ratio'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(ratio_pair(66,64),ratio_pair(66,62),incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'ratio', kind:'scale_ratio_unit'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(ratio_pair(66,62),ratio_pair(66,62),correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'subtraction', kind:'add_instead_of_subtract_column'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(64,2,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'subtraction', kind:'answer_as_endpoint_count_up'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(33,2,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'subtraction', kind:'compare_by_matching_difference'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(2,2,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'subtraction', kind:'compare_returns_larger_count'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(33,2,incorrect)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'subtraction', kind:'count_up_missing_addend'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(2,2,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'project_wrapped_magnitude',
        license_class:'p',
        source:json{family:'multiplication', kind:'add_numbers_as_common_multiple'},
        target:json{family:'subtraction', kind:'take_away_base_ones'},
        carried_role:'the magnitude read out of 1 arity-one wrapper(s)',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.b', value:31}], [json{path:'.b', value:46}], [json{path:'.b', value:12}]],
        witness:json{adapted_input:json{a:33, b:31}, carried_value_exact:'33', input:json{a:2, b:31}, source_result:'candidate_common_multiple(33)', target_result:'result(2,2,correct)', transform:'the magnitude read out of 1 arity-one wrapper(s)'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).

% Adapter: rename_decimal_to_decimal_object
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_add_unaligned_numerals'},
        target:json{family:'decimal', kind:'decimal_addition_by_aligned_units'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(decimal(0,fractional_digits(0,1),tenths),decimal(0,fractional_digits(0,1),tenths),correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_add_unaligned_numerals'},
        target:json{family:'decimal', kind:'decimal_comparison_by_aligned_units'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(equal,equal,correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_add_unaligned_numerals'},
        target:json{family:'decimal', kind:'decimal_fraction_place_value_comparison'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(equivalent,equivalent,correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_add_unaligned_numerals'},
        target:json{family:'decimal', kind:'decimal_multiplication_rule'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(decimal(0,fractional_digits(0,2),hundredths),decimal(0,fractional_digits(0,2),hundredths),correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_add_unaligned_numerals'},
        target:json{family:'decimal', kind:'decimal_numeral_comparison_without_scale_alignment'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(equal,equal,accidentally_correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_add_unaligned_numerals'},
        target:json{family:'decimal', kind:'decimal_point_rule_misapplication'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(decimal(0,fractional_digits(0,1),tenths),decimal(0,fractional_digits(0,2),hundredths),incorrect)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_add_unaligned_numerals'},
        target:json{family:'decimal', kind:'decimal_scale_loss_comparison'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(equivalent,equivalent,accidentally_correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_addition_by_aligned_units'},
        target:json{family:'decimal', kind:'decimal_add_unaligned_numerals'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(decimal(0,fractional_digits(0,1),tenths),decimal(0,fractional_digits(0,1),tenths),accidentally_correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_addition_by_aligned_units'},
        target:json{family:'decimal', kind:'decimal_comparison_by_aligned_units'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(equal,equal,correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_addition_by_aligned_units'},
        target:json{family:'decimal', kind:'decimal_fraction_place_value_comparison'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(equivalent,equivalent,correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_addition_by_aligned_units'},
        target:json{family:'decimal', kind:'decimal_multiplication_rule'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(decimal(0,fractional_digits(0,2),hundredths),decimal(0,fractional_digits(0,2),hundredths),correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_addition_by_aligned_units'},
        target:json{family:'decimal', kind:'decimal_numeral_comparison_without_scale_alignment'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(equal,equal,accidentally_correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_addition_by_aligned_units'},
        target:json{family:'decimal', kind:'decimal_point_rule_misapplication'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(decimal(0,fractional_digits(0,1),tenths),decimal(0,fractional_digits(0,2),hundredths),incorrect)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_addition_by_aligned_units'},
        target:json{family:'decimal', kind:'decimal_scale_loss_comparison'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(equivalent,equivalent,accidentally_correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_addition_by_aligned_units'},
        target:json{family:'decimal', kind:'decimal_subtract_unaligned_numerals'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(decimal(0,fractional_digits(0,1),tenths),decimal(0,fractional_digits(0,1),tenths),accidentally_correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_addition_by_aligned_units'},
        target:json{family:'decimal', kind:'decimal_subtraction_by_aligned_units'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(decimal(0,fractional_digits(0,1),tenths),decimal(0,fractional_digits(0,1),tenths),correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_multiplication_rule'},
        target:json{family:'decimal', kind:'decimal_add_unaligned_numerals'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 100',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:100}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-100]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,2),hundredths)', target_result:'result(decimal(0,fractional_digits(0,2),hundredths),decimal(0,fractional_digits(0,2),hundredths),accidentally_correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 100'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_multiplication_rule'},
        target:json{family:'decimal', kind:'decimal_addition_by_aligned_units'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 100',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:100}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-100]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,2),hundredths)', target_result:'result(decimal(0,fractional_digits(0,2),hundredths),decimal(0,fractional_digits(0,2),hundredths),correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 100'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_multiplication_rule'},
        target:json{family:'decimal', kind:'decimal_comparison_by_aligned_units'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 100',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:100}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-100]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,2),hundredths)', target_result:'result(equal,equal,correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 100'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_multiplication_rule'},
        target:json{family:'decimal', kind:'decimal_fraction_place_value_comparison'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 100',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:100}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-100]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,2),hundredths)', target_result:'result(equivalent,equivalent,correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 100'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_multiplication_rule'},
        target:json{family:'decimal', kind:'decimal_numeral_comparison_without_scale_alignment'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 100',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:100}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-100]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,2),hundredths)', target_result:'result(equal,equal,accidentally_correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 100'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_multiplication_rule'},
        target:json{family:'decimal', kind:'decimal_point_rule_misapplication'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 100',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:100}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-100]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,2),hundredths)', target_result:'result(decimal(0,fractional_digits(0,2),hundredths),decimal(0,fractional_digits(0,3),thousandths),incorrect)', transform:'the whole part and the fractional digits as one numeral 0 over scale 100'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_multiplication_rule'},
        target:json{family:'decimal', kind:'decimal_scale_loss_comparison'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 100',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:100}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-100]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,2),hundredths)', target_result:'result(equivalent,equivalent,accidentally_correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 100'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_point_rule_misapplication'},
        target:json{family:'decimal', kind:'decimal_add_unaligned_numerals'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(decimal(0,fractional_digits(0,1),tenths),decimal(0,fractional_digits(0,1),tenths),accidentally_correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_point_rule_misapplication'},
        target:json{family:'decimal', kind:'decimal_addition_by_aligned_units'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(decimal(0,fractional_digits(0,1),tenths),decimal(0,fractional_digits(0,1),tenths),correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_point_rule_misapplication'},
        target:json{family:'decimal', kind:'decimal_comparison_by_aligned_units'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(equal,equal,correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_point_rule_misapplication'},
        target:json{family:'decimal', kind:'decimal_fraction_place_value_comparison'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(equivalent,equivalent,correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_point_rule_misapplication'},
        target:json{family:'decimal', kind:'decimal_multiplication_rule'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(decimal(0,fractional_digits(0,2),hundredths),decimal(0,fractional_digits(0,2),hundredths),correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_point_rule_misapplication'},
        target:json{family:'decimal', kind:'decimal_numeral_comparison_without_scale_alignment'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(equal,equal,accidentally_correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_point_rule_misapplication'},
        target:json{family:'decimal', kind:'decimal_scale_loss_comparison'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:8}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(equivalent,equivalent,accidentally_correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_subtract_unaligned_numerals'},
        target:json{family:'decimal', kind:'decimal_add_unaligned_numerals'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:7}, json{path:'.right.scale', value:10}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(decimal(0,fractional_digits(0,1),tenths),decimal(0,fractional_digits(0,1),tenths),accidentally_correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_subtract_unaligned_numerals'},
        target:json{family:'decimal', kind:'decimal_addition_by_aligned_units'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:7}, json{path:'.right.scale', value:10}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(decimal(0,fractional_digits(0,1),tenths),decimal(0,fractional_digits(0,1),tenths),correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_subtract_unaligned_numerals'},
        target:json{family:'decimal', kind:'decimal_comparison_by_aligned_units'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:7}, json{path:'.right.scale', value:10}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(equal,equal,correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_subtract_unaligned_numerals'},
        target:json{family:'decimal', kind:'decimal_fraction_place_value_comparison'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:7}, json{path:'.right.scale', value:10}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(equivalent,equivalent,correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_subtract_unaligned_numerals'},
        target:json{family:'decimal', kind:'decimal_multiplication_rule'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:7}, json{path:'.right.scale', value:10}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(decimal(0,fractional_digits(0,2),hundredths),decimal(0,fractional_digits(0,2),hundredths),correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_subtract_unaligned_numerals'},
        target:json{family:'decimal', kind:'decimal_numeral_comparison_without_scale_alignment'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:7}, json{path:'.right.scale', value:10}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(equal,equal,accidentally_correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_subtract_unaligned_numerals'},
        target:json{family:'decimal', kind:'decimal_point_rule_misapplication'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:7}, json{path:'.right.scale', value:10}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(decimal(0,fractional_digits(0,1),tenths),decimal(0,fractional_digits(0,2),hundredths),incorrect)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_subtract_unaligned_numerals'},
        target:json{family:'decimal', kind:'decimal_scale_loss_comparison'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:12}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:7}, json{path:'.right.scale', value:10}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(equivalent,equivalent,accidentally_correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_subtraction_by_aligned_units'},
        target:json{family:'decimal', kind:'decimal_add_unaligned_numerals'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:2}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:4}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(decimal(0,fractional_digits(0,1),tenths),decimal(0,fractional_digits(0,1),tenths),accidentally_correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_subtraction_by_aligned_units'},
        target:json{family:'decimal', kind:'decimal_addition_by_aligned_units'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:2}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:4}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(decimal(0,fractional_digits(0,1),tenths),decimal(0,fractional_digits(0,1),tenths),correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_subtraction_by_aligned_units'},
        target:json{family:'decimal', kind:'decimal_comparison_by_aligned_units'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:2}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:4}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(equal,equal,correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_subtraction_by_aligned_units'},
        target:json{family:'decimal', kind:'decimal_fraction_place_value_comparison'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:2}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:4}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(equivalent,equivalent,correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_subtraction_by_aligned_units'},
        target:json{family:'decimal', kind:'decimal_multiplication_rule'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:2}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:4}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(decimal(0,fractional_digits(0,2),hundredths),decimal(0,fractional_digits(0,2),hundredths),correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_subtraction_by_aligned_units'},
        target:json{family:'decimal', kind:'decimal_numeral_comparison_without_scale_alignment'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:2}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:4}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(equal,equal,accidentally_correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_subtraction_by_aligned_units'},
        target:json{family:'decimal', kind:'decimal_point_rule_misapplication'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:2}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:4}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(decimal(0,fractional_digits(0,1),tenths),decimal(0,fractional_digits(0,2),hundredths),incorrect)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_decimal_to_decimal_object',
        license_class:'r',
        source:json{family:'decimal', kind:'decimal_subtraction_by_aligned_units'},
        target:json{family:'decimal', kind:'decimal_scale_loss_comparison'},
        carried_role:'the whole part and the fractional digits as one numeral 0 over scale 10',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.numeral', value:0}, json{path:'.right.scale', value:10}], [json{path:'.right.numeral', value:2}, json{path:'.right.scale', value:100}], [json{path:'.right.numeral', value:4}, json{path:'.right.scale', value:100}]],
        witness:json{adapted_input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, carried_value_exact:'[numeral-0,scale-10]', input:json{kind:'decimal_pair', left:json{numeral:0, scale:10}, right:json{numeral:0, scale:10}}, source_result:'decimal(0,fractional_digits(0,1),tenths)', target_result:'result(equivalent,equivalent,accidentally_correct)', transform:'the whole part and the fractional digits as one numeral 0 over scale 10'},
        seam_flags:[4],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).

% Adapter: rename_fraction_to_fraction_object
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'add_numerator_denominator_sum'},
        target:json{family:'fraction', kind:'add_numerator_denominator_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:0}, json{path:'.right.d', value:4}], [json{path:'.right.n', value:4}, json{path:'.right.d', value:5}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-2]', input:json{kind:'fraction_addend_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'fraction(0,2)', target_result:'result(greater_than,less_than,incorrect)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'add_numerator_denominator_sum'},
        target:json{family:'fraction', kind:'benchmark_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:0}, json{path:'.right.d', value:4}], [json{path:'.right.n', value:4}, json{path:'.right.d', value:5}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-2]', input:json{kind:'fraction_addend_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'fraction(0,2)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'add_numerator_denominator_sum'},
        target:json{family:'fraction', kind:'common_denominator_fraction_addition'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:0}, json{path:'.right.d', value:4}], [json{path:'.right.n', value:4}, json{path:'.right.d', value:5}]],
        witness:json{adapted_input:json{kind:'fraction_addend_pair', left:json{d:2, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-2]', input:json{kind:'fraction_addend_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'fraction(0,2)', target_result:'result(fraction(0,2),fraction(0,2),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'add_numerator_denominator_sum'},
        target:json{family:'fraction', kind:'common_unit_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:0}, json{path:'.right.d', value:4}], [json{path:'.right.n', value:4}, json{path:'.right.d', value:5}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-2]', input:json{kind:'fraction_addend_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'fraction(0,2)', target_result:'result(less_than,less_than,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'add_numerator_denominator_sum'},
        target:json{family:'fraction', kind:'gap_thinking_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:0}, json{path:'.right.d', value:4}], [json{path:'.right.n', value:4}, json{path:'.right.d', value:5}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-2]', input:json{kind:'fraction_addend_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'fraction(0,2)', target_result:'result(less_than,equivalent,incorrect)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'add_numerator_denominator_sum'},
        target:json{family:'fraction', kind:'number_line_count_marks_not_intervals'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:0}, json{path:'.right.d', value:4}], [json{path:'.right.n', value:4}, json{path:'.right.d', value:5}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-2]', input:json{kind:'fraction_addend_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'fraction(0,2)', target_result:'result(less_than,equivalent,incorrect)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'add_numerator_denominator_sum'},
        target:json{family:'fraction', kind:'number_line_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:0}, json{path:'.right.d', value:4}], [json{path:'.right.n', value:4}, json{path:'.right.d', value:5}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-2]', input:json{kind:'fraction_addend_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'fraction(0,2)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'area_model_part_of_part'},
        target:json{family:'fraction', kind:'add_numerator_denominator_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'area_model_part_of_part'},
        target:json{family:'fraction', kind:'add_numerator_denominator_sum'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_addend_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction(2,4),fraction(2,2),incorrect)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'area_model_part_of_part'},
        target:json{family:'fraction', kind:'area_model_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'area_model_part_of_part'},
        target:json{family:'fraction', kind:'area_model_unequal_partition_piece_count'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'area_model_part_of_part'},
        target:json{family:'fraction', kind:'benchmark_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'area_model_part_of_part'},
        target:json{family:'fraction', kind:'common_denominator_fraction_addition'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_addend_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction(2,2),fraction(2,2),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'area_model_part_of_part'},
        target:json{family:'fraction', kind:'common_unit_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'area_model_part_of_part'},
        target:json{family:'fraction', kind:'cross_multiplication_rule_from_pattern'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction(1,4),fraction(1,4),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'area_model_part_of_part'},
        target:json{family:'fraction', kind:'cross_multiplication_rule_without_ground'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction(1,4),fraction(1,4),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'area_model_part_of_part'},
        target:json{family:'fraction', kind:'gap_thinking_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'area_model_part_of_part'},
        target:json{family:'fraction', kind:'measurement_division'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction_division_quotient(fraction(1,2),fraction(1,2),whole_groups(1),remainder(fraction(0,1))),fraction_division_quotient(fraction(1,2),fraction(1,2),whole_groups(1),remainder(fraction(0,1))),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'area_model_part_of_part'},
        target:json{family:'fraction', kind:'number_line_count_marks_not_intervals'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'area_model_part_of_part'},
        target:json{family:'fraction', kind:'number_line_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'area_model_part_of_part'},
        target:json{family:'fraction', kind:'reversible_measurement_division'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction_division_quotient(fraction(1,2),fraction(1,2),quotient(fraction(1,1))),fraction_division_quotient(fraction(1,2),fraction(1,2),quotient(fraction(1,1))),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'area_model_part_of_part'},
        target:json{family:'fraction', kind:'set_model_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'area_model_part_of_part'},
        target:json{family:'fraction', kind:'set_model_subset_size_focus'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'area_model_part_of_part'},
        target:json{family:'fraction', kind:'unit_fraction_denominator_product_rule'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction(1,4),fraction(1,4),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'common_denominator_fraction_addition'},
        target:json{family:'fraction', kind:'add_numerator_denominator_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:0}, json{path:'.right.d', value:4}], [json{path:'.right.n', value:4}, json{path:'.right.d', value:5}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-1]', input:json{kind:'fraction_addend_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'fraction(0,1)', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'common_denominator_fraction_addition'},
        target:json{family:'fraction', kind:'add_numerator_denominator_sum'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:0}, json{path:'.right.d', value:4}], [json{path:'.right.n', value:4}, json{path:'.right.d', value:5}]],
        witness:json{adapted_input:json{kind:'fraction_addend_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-1]', input:json{kind:'fraction_addend_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'fraction(0,1)', target_result:'result(fraction(0,2),fraction(0,1),contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'common_denominator_fraction_addition'},
        target:json{family:'fraction', kind:'benchmark_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:0}, json{path:'.right.d', value:4}], [json{path:'.right.n', value:4}, json{path:'.right.d', value:5}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-1]', input:json{kind:'fraction_addend_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'fraction(0,1)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'common_denominator_fraction_addition'},
        target:json{family:'fraction', kind:'common_denominator_fraction_subtraction'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:0}, json{path:'.right.d', value:4}], [json{path:'.right.n', value:4}, json{path:'.right.d', value:5}]],
        witness:json{adapted_input:json{kind:'fraction_minuend_subtrahend', left:json{d:1, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-1]', input:json{kind:'fraction_addend_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'fraction(0,1)', target_result:'result(fraction(0,1),fraction(0,1),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'common_denominator_fraction_addition'},
        target:json{family:'fraction', kind:'common_unit_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:0}, json{path:'.right.d', value:4}], [json{path:'.right.n', value:4}, json{path:'.right.d', value:5}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-1]', input:json{kind:'fraction_addend_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'fraction(0,1)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'common_denominator_fraction_addition'},
        target:json{family:'fraction', kind:'gap_thinking_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:0}, json{path:'.right.d', value:4}], [json{path:'.right.n', value:4}, json{path:'.right.d', value:5}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-1]', input:json{kind:'fraction_addend_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'fraction(0,1)', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'common_denominator_fraction_addition'},
        target:json{family:'fraction', kind:'number_line_count_marks_not_intervals'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:0}, json{path:'.right.d', value:4}], [json{path:'.right.n', value:4}, json{path:'.right.d', value:5}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-1]', input:json{kind:'fraction_addend_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'fraction(0,1)', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'common_denominator_fraction_addition'},
        target:json{family:'fraction', kind:'number_line_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:0}, json{path:'.right.d', value:4}], [json{path:'.right.n', value:4}, json{path:'.right.d', value:5}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-1]', input:json{kind:'fraction_addend_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'fraction(0,1)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'common_denominator_fraction_subtraction'},
        target:json{family:'fraction', kind:'add_numerator_denominator_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:1}, json{path:'.right.d', value:4}], [json{path:'.right.n', value:4}, json{path:'.right.d', value:5}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-1]', input:json{kind:'fraction_minuend_subtrahend', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'fraction(0,1)', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'common_denominator_fraction_subtraction'},
        target:json{family:'fraction', kind:'add_numerator_denominator_sum'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:1}, json{path:'.right.d', value:4}], [json{path:'.right.n', value:4}, json{path:'.right.d', value:5}]],
        witness:json{adapted_input:json{kind:'fraction_addend_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-1]', input:json{kind:'fraction_minuend_subtrahend', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'fraction(0,1)', target_result:'result(fraction(0,2),fraction(0,1),contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'common_denominator_fraction_subtraction'},
        target:json{family:'fraction', kind:'benchmark_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:1}, json{path:'.right.d', value:4}], [json{path:'.right.n', value:4}, json{path:'.right.d', value:5}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-1]', input:json{kind:'fraction_minuend_subtrahend', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'fraction(0,1)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'common_denominator_fraction_subtraction'},
        target:json{family:'fraction', kind:'common_denominator_fraction_addition'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:1}, json{path:'.right.d', value:4}], [json{path:'.right.n', value:4}, json{path:'.right.d', value:5}]],
        witness:json{adapted_input:json{kind:'fraction_addend_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-1]', input:json{kind:'fraction_minuend_subtrahend', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'fraction(0,1)', target_result:'result(fraction(0,1),fraction(0,1),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'common_denominator_fraction_subtraction'},
        target:json{family:'fraction', kind:'common_unit_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:1}, json{path:'.right.d', value:4}], [json{path:'.right.n', value:4}, json{path:'.right.d', value:5}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-1]', input:json{kind:'fraction_minuend_subtrahend', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'fraction(0,1)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'common_denominator_fraction_subtraction'},
        target:json{family:'fraction', kind:'gap_thinking_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:1}, json{path:'.right.d', value:4}], [json{path:'.right.n', value:4}, json{path:'.right.d', value:5}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-1]', input:json{kind:'fraction_minuend_subtrahend', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'fraction(0,1)', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'common_denominator_fraction_subtraction'},
        target:json{family:'fraction', kind:'number_line_count_marks_not_intervals'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:1}, json{path:'.right.d', value:4}], [json{path:'.right.n', value:4}, json{path:'.right.d', value:5}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-1]', input:json{kind:'fraction_minuend_subtrahend', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'fraction(0,1)', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'common_denominator_fraction_subtraction'},
        target:json{family:'fraction', kind:'number_line_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:0}, json{path:'.right.d', value:1}], [json{path:'.right.n', value:1}, json{path:'.right.d', value:4}], [json{path:'.right.n', value:4}, json{path:'.right.d', value:5}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:1, n:0}, right:json{d:1, n:0}}, carried_value_exact:'[n-0,d-1]', input:json{kind:'fraction_minuend_subtrahend', left:json{d:1, n:0}, right:json{d:1, n:0}}, source_result:'fraction(0,1)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_from_pattern'},
        target:json{family:'fraction', kind:'add_numerator_denominator_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_from_pattern'},
        target:json{family:'fraction', kind:'add_numerator_denominator_sum'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_addend_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction(2,4),fraction(2,2),incorrect)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_from_pattern'},
        target:json{family:'fraction', kind:'area_model_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_from_pattern'},
        target:json{family:'fraction', kind:'area_model_part_of_part'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction(1,4),fraction(1,4),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_from_pattern'},
        target:json{family:'fraction', kind:'area_model_unequal_partition_piece_count'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_from_pattern'},
        target:json{family:'fraction', kind:'benchmark_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_from_pattern'},
        target:json{family:'fraction', kind:'common_denominator_fraction_addition'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_addend_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction(2,2),fraction(2,2),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_from_pattern'},
        target:json{family:'fraction', kind:'common_unit_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_from_pattern'},
        target:json{family:'fraction', kind:'cross_multiplication_rule_without_ground'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction(1,4),fraction(1,4),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_from_pattern'},
        target:json{family:'fraction', kind:'gap_thinking_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_from_pattern'},
        target:json{family:'fraction', kind:'measurement_division'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction_division_quotient(fraction(1,2),fraction(1,2),whole_groups(1),remainder(fraction(0,1))),fraction_division_quotient(fraction(1,2),fraction(1,2),whole_groups(1),remainder(fraction(0,1))),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_from_pattern'},
        target:json{family:'fraction', kind:'number_line_count_marks_not_intervals'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_from_pattern'},
        target:json{family:'fraction', kind:'number_line_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_from_pattern'},
        target:json{family:'fraction', kind:'reversible_measurement_division'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction_division_quotient(fraction(1,2),fraction(1,2),quotient(fraction(1,1))),fraction_division_quotient(fraction(1,2),fraction(1,2),quotient(fraction(1,1))),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_from_pattern'},
        target:json{family:'fraction', kind:'set_model_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_from_pattern'},
        target:json{family:'fraction', kind:'set_model_subset_size_focus'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_from_pattern'},
        target:json{family:'fraction', kind:'unit_fraction_denominator_product_rule'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction(1,4),fraction(1,4),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_without_ground'},
        target:json{family:'fraction', kind:'add_numerator_denominator_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_without_ground'},
        target:json{family:'fraction', kind:'add_numerator_denominator_sum'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_addend_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction(2,4),fraction(2,2),incorrect)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_without_ground'},
        target:json{family:'fraction', kind:'area_model_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_without_ground'},
        target:json{family:'fraction', kind:'area_model_part_of_part'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction(1,4),fraction(1,4),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_without_ground'},
        target:json{family:'fraction', kind:'area_model_unequal_partition_piece_count'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_without_ground'},
        target:json{family:'fraction', kind:'benchmark_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_without_ground'},
        target:json{family:'fraction', kind:'common_denominator_fraction_addition'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_addend_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction(2,2),fraction(2,2),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_without_ground'},
        target:json{family:'fraction', kind:'common_unit_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_without_ground'},
        target:json{family:'fraction', kind:'cross_multiplication_rule_from_pattern'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction(1,4),fraction(1,4),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_without_ground'},
        target:json{family:'fraction', kind:'gap_thinking_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_without_ground'},
        target:json{family:'fraction', kind:'measurement_division'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction_division_quotient(fraction(1,2),fraction(1,2),whole_groups(1),remainder(fraction(0,1))),fraction_division_quotient(fraction(1,2),fraction(1,2),whole_groups(1),remainder(fraction(0,1))),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_without_ground'},
        target:json{family:'fraction', kind:'number_line_count_marks_not_intervals'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_without_ground'},
        target:json{family:'fraction', kind:'number_line_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_without_ground'},
        target:json{family:'fraction', kind:'reversible_measurement_division'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction_division_quotient(fraction(1,2),fraction(1,2),quotient(fraction(1,1))),fraction_division_quotient(fraction(1,2),fraction(1,2),quotient(fraction(1,1))),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_without_ground'},
        target:json{family:'fraction', kind:'set_model_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_without_ground'},
        target:json{family:'fraction', kind:'set_model_subset_size_focus'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'cross_multiplication_rule_without_ground'},
        target:json{family:'fraction', kind:'unit_fraction_denominator_product_rule'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction(1,4),fraction(1,4),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'unit_fraction_denominator_product_rule'},
        target:json{family:'fraction', kind:'add_numerator_denominator_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'unit_fraction_denominator_product_rule'},
        target:json{family:'fraction', kind:'add_numerator_denominator_sum'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_addend_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction(2,4),fraction(2,2),incorrect)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'unit_fraction_denominator_product_rule'},
        target:json{family:'fraction', kind:'area_model_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'unit_fraction_denominator_product_rule'},
        target:json{family:'fraction', kind:'area_model_part_of_part'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction(1,4),fraction(1,4),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'unit_fraction_denominator_product_rule'},
        target:json{family:'fraction', kind:'area_model_unequal_partition_piece_count'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'unit_fraction_denominator_product_rule'},
        target:json{family:'fraction', kind:'benchmark_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'unit_fraction_denominator_product_rule'},
        target:json{family:'fraction', kind:'common_denominator_fraction_addition'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_addend_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction(2,2),fraction(2,2),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'unit_fraction_denominator_product_rule'},
        target:json{family:'fraction', kind:'common_unit_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'unit_fraction_denominator_product_rule'},
        target:json{family:'fraction', kind:'cross_multiplication_rule_from_pattern'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction(1,4),fraction(1,4),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'unit_fraction_denominator_product_rule'},
        target:json{family:'fraction', kind:'cross_multiplication_rule_without_ground'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction(1,4),fraction(1,4),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'unit_fraction_denominator_product_rule'},
        target:json{family:'fraction', kind:'gap_thinking_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'unit_fraction_denominator_product_rule'},
        target:json{family:'fraction', kind:'measurement_division'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction_division_quotient(fraction(1,2),fraction(1,2),whole_groups(1),remainder(fraction(0,1))),fraction_division_quotient(fraction(1,2),fraction(1,2),whole_groups(1),remainder(fraction(0,1))),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'unit_fraction_denominator_product_rule'},
        target:json{family:'fraction', kind:'number_line_count_marks_not_intervals'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'unit_fraction_denominator_product_rule'},
        target:json{family:'fraction', kind:'number_line_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'unit_fraction_denominator_product_rule'},
        target:json{family:'fraction', kind:'reversible_measurement_division'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(fraction_division_quotient(fraction(1,2),fraction(1,2),quotient(fraction(1,1))),fraction_division_quotient(fraction(1,2),fraction(1,2),quotient(fraction(1,1))),correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'unit_fraction_denominator_product_rule'},
        target:json{family:'fraction', kind:'set_model_fraction_comparison'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).
admitted_bridge(
    bridge{
        adapter:'rename_fraction_to_fraction_object',
        license_class:'r',
        source:json{family:'fraction', kind:'unit_fraction_denominator_product_rule'},
        target:json{family:'fraction', kind:'set_model_subset_size_focus'},
        carried_role:'the two arguments named by the target''s own n and d keys',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.right.n', value:1}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:2}], [json{path:'.right.n', value:3}, json{path:'.right.d', value:4}]],
        witness:json{adapted_input:json{kind:'fraction_pair', left:json{d:2, n:1}, right:json{d:2, n:1}}, carried_value_exact:'[n-1,d-2]', input:json{kind:'fraction_pair', left:json{d:1, n:1}, right:json{d:2, n:1}}, source_result:'fraction(1,2)', target_result:'result(equivalent,equivalent,contextually_correct)', transform:'the two arguments named by the target''s own n and d keys'},
        seam_flags:[],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'}
    }
).

% Adapter: unit_relabel_with_scaling_witness
admitted_bridge(
    bridge{
        adapter:'unit_relabel_with_scaling_witness',
        license_class:'u',
        source:json{family:'measurement', kind:'unit_conversion_by_iteration'},
        target:json{family:'measurement', kind:'change_unit_label_without_scaling'},
        carried_role:'relabelled from foot on the inverse of the declared witness scaling(yard,foot,9) of factor 1r9',
        candidate_strength:'contract_bridge',
        distinct_adapted_inputs:20,
        companion_values:[[json{path:'.to_unit', value:'foot'}, json{path:'.factor', value:9}], [json{path:'.to_unit', value:'foot'}, json{path:'.factor', value:11}], [json{path:'.to_unit', value:'foot'}, json{path:'.factor', value:6}]],
        witness:json{adapted_input:json{count:0, factor:9, from_unit:'yard', kind:'quantity_conversion', to_unit:'foot'}, carried_value_exact:'0', input:json{count:0, factor:9, from_unit:'yard', kind:'quantity_conversion', to_unit:'foot'}, source_result:'quantity(0,foot)', target_result:'result(quantity(0,foot),quantity(0,foot),incorrect)', transform:'relabelled from foot on the inverse of the declared witness scaling(yard,foot,9) of factor 1r9'},
        seam_flags:[6],
        provenance:json{collection_directory:'.bigred-collected/2026-08-10-loops-wave4-r4/rows', docket:'docs/research/internal/2026-08-10-r4-admission-docket.json', generated_for:'2026-08-10 R4 admission ceremony', ruling:'plans/2026-08-11-r4-admission-band1-draft.md'},
        adapted_input_equals_source_input_in_all_retained_witnesses:true
    }
).
