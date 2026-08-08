:- encoding(utf8).
/** <module> loop_driver — shared substrate S0 for the Big Red connection loops
 *
 * Three driver predicates and one item entry point, authored for the run
 * design in `.superpowers/sdd/task-2026-08-08-engineer-bigred-loops.md`.
 * Nothing here proposes a connection on its own: the loops enumerate, a
 * reviewed ceremony admits, and only admitted rows reach the tracked stores.
 *
 * WHAT EACH PREDICATE DOES.
 *
 *   grid_input/3     One authored `grid_plan/3` row per distinct schema
 *                    string in automaton_input_contract/5, behind one
 *                    generic expander — the same shape hermes/dispatch_spec.pl
 *                    uses for its dispatch rows. A schema with no plan makes
 *                    grid_input/3 FAIL, and the caller records
 *                    uninstantiated(schema). Scale cannot supply a grid the
 *                    contract never described, and the refusal list is a
 *                    product of the run rather than a defect in it.
 *
 *   aa_run/4         One machine on one input, through the same seam the
 *                    console's strategy_trace uses: the worker's decoder
 *                    (hermes_encyclopedia:trace_inputs/3) turns the JSON
 *                    input into the two structured operands, and
 *                    action_automata_registry:run_action_automaton/6 runs the
 *                    machine. No HTTP, no model, no network.
 *
 *   same_archetype/2 The pair filter, as the design words it. READ
 *                    `family_probe_archetype/2` below before trusting it:
 *                    its second conjunct rests on a relation this checkout
 *                    does not carry, and the measured consequence is recorded
 *                    there.
 *
 * REFUSAL AND ERROR ARE DIFFERENT THINGS, and the split is load-bearing for
 * the later runs. run_action_automaton/6 FAILING means the machine declines
 * this input — whole-number subtraction on 3 − 5, whole-number addition on
 * −4 + 9. That is the crisis signal R2 is built to harvest, so it is
 * `refused(domain(...))`. An exception, or an input the decoder cannot read,
 * is `error(...)`: a fault in the substrate, never a machine's judgment.
 *
 * TIME. No time limit here preempts a native builtin (the Big Red law), so
 * the binding guard is the Python watchdog in run_loop_array.py. The
 * per-input `call_with_time_limit/2` below is a best-effort inner bound that
 * catches runaway pure-Prolog loops and nothing else; the per-pair budget is
 * checked between inputs, where checking is cheap and reliable.
 *
 * Load with paths.pl first and nothing from formal/learner/server*.pl:
 *
 *   swipl -q -l paths.pl -l scripts/bigred/loops/loop_driver.pl \
 *         -g loop_driver:main_item -t halt
 */

:- module(loop_driver,
          [ grid_plan/3,
            grid_input/3,
            grid_status/2,
            grid_point_count/2,
            contract_schema/1,
            contracted_machine/1,
            machine_schema/2,
            aa_run/4,
            same_result/2,
            registered_deformation/2,
            family_alphabet/2,
            machine_canonical_actions/3,
            r2_rows/2,
            same_schema/2,
            family_probe_archetype/2,
            same_archetype/2,
            pair/3,
            main_item/0
          ]).

:- use_module(library(lists)).
:- use_module(library(time), [call_with_time_limit/2]).
:- use_module(library(http/json)).

:- use_module(strategies(automaton_input_contracts),
              [ automaton_input_contract/5 ]).
:- use_module(strategies('math/action_automata_registry'), []).
:- use_module(hermes(encyclopedia), []).
% R2's lens data. All three are fact tables; none binds a port or runs a
% server. deformation_validity/8 and action_automaton_pair/4 say whether a
% receiver is a REGISTERED deformation; action_maps/7 carries each machine's
% canonical actions, which is how a release is seen to cross families.
:- use_module(strategies(deformation_validity), [ deformation_validity/8 ]).
:- use_module(strategies(action_vocabulary_map), [ action_maps/7 ]).


% ==========================================================================
% 1. THE MACHINE POPULATION
% ==========================================================================

%!  contracted_machine(?Machine) is nondet.
%
%   Machine is machine(Family, Kind) for each row of automaton_input_contract/5.
contracted_machine(machine(Family, Kind)) :-
    automaton_input_contract(Family, Kind, _, _, _).

%!  machine_schema(?Machine, ?SchemaString) is nondet.
machine_schema(machine(Family, Kind), Schema) :-
    automaton_input_contract(Family, Kind, Schema, _, _).

%!  contract_schema(?SchemaString) is nondet.
%
%   Each distinct schema string, once.
contract_schema(Schema) :-
    setof(S, F^K^E^V^automaton_input_contract(F, K, S, E, V), Schemas),
    member(Schema, Schemas).


% ==========================================================================
% 2. grid_input/3 — the authored grids
%
% grid_plan(SchemaString, bounds(Name, Points), Template).
%
% Template language, expanded by expand_template/2 below:
%   obj([Key-Template, ...])   a JSON object
%   arr([Template, ...])       a JSON array
%   lit(Value)                 a ground literal, taken from the schema itself
%   vary(ints(Lo, Hi))         a varying integer leaf
%   vary(members([T, ...]))    a varying leaf over authored alternatives
%
% Bound choices, and why they are what they are. The integer pair carries the
% design's own grid, 0..49 by 0..49. Every other schema is held at or under a
% thousand points, and the domains are shrunk toward each other rather than
% back to front, so a fraction pair varies both denominators instead of
% pinning one. A `scale` leaf takes powers of ten: an arbitrary positive
% integer there would build a grid the decimal machines cannot read. An
% `atom` leaf takes the value the contract's own verified example carries,
% because the contract records no domain to range over. A list leaf varies by
% which elements it holds, and keeps the element shape the example fixed.
%
% Three schemas carry no plan and are named at the end of this block: their
% variability is not a bounded product over numeric leaves, and authoring a
% grid for them would be inventing a domain rather than reading one.
% ==========================================================================

%  69 machine(s); 2500 grid points.
grid_plan('{\"a\":\"integer\",\"b\":\"integer\"}',
          bounds(a_b, 2500),
          obj([a-vary(ints(0,49)), b-vary(ints(0,49))])).

%  19 machine(s); 625 grid points.
grid_plan('{\"kind\":\"fraction_pair\",\"left\":{\"n\":\"integer\",\"d\":\"positive_integer\"},\"right\":{\"n\":\"integer\",\"d\":\"positive_integer\"}}',
          bounds(fraction_pair, 625),
          obj([kind-lit("fraction_pair"), left-obj([n-vary(ints(0,4)), d-vary(ints(1,5))]), right-obj([n-vary(ints(0,4)), d-vary(ints(1,5))])])).

%  10 machine(s); 156 grid points.
grid_plan('{\"a\":\"integer\",\"b\":\"positive_integer\"}',
          bounds(a_b, 156),
          obj([a-vary(ints(0,12)), b-vary(ints(1,12))])).

%  10 machine(s); 676 grid points.
grid_plan('{\"kind\":\"decimal_pair\",\"left\":{\"numeral\":\"integer\",\"scale\":\"positive_integer\"},\"right\":{\"numeral\":\"integer\",\"scale\":\"positive_integer\"}}',
          bounds(decimal_pair, 676),
          obj([kind-lit("decimal_pair"), left-obj([numeral-vary(ints(0,12)), scale-vary(members([lit(10), lit(100)]))]), right-obj([numeral-vary(ints(0,12)), scale-vary(members([lit(10), lit(100)]))])])).

%  7 machine(s); 4 grid points.
grid_plan('{\"kind\":\"numeric_data_with_unit\",\"values\":[\"integer\"],\"unit\":\"atom\"}',
          bounds(numeric_data_with_unit, 4),
          obj([kind-lit("numeric_data_with_unit"), values-vary(members([arr([lit(2), lit(4), lit(5), lit(7), lit(9)]), arr([lit(3), lit(5), lit(6), lit(8), lit(10)]), arr([lit(2), lit(2), lit(2), lit(2), lit(2)]), arr([lit(9), lit(7), lit(5), lit(4), lit(2)])])), unit-vary(members([lit("minutes")]))])).

%  6 machine(s); 144 grid points.
grid_plan('{\"a\":\"positive_integer\",\"b\":\"positive_integer\"}',
          bounds(a_b, 144),
          obj([a-vary(ints(1,12)), b-vary(ints(1,12))])).

%  4 machine(s); 144 grid points.
grid_plan('{\"kind\":\"measure_with_unit\",\"interval_count\":\"positive_integer\",\"subdivisions\":\"positive_integer\",\"unit\":\"atom\"}',
          bounds(measure_with_unit, 144),
          obj([kind-lit("measure_with_unit"), interval_count-vary(ints(1,12)), subdivisions-vary(ints(1,12)), unit-vary(members([lit("inch")]))])).

%  3 machine(s); 144 grid points.
grid_plan('{\"kind\":\"rectangle_with_unit\",\"length\":\"positive_integer\",\"width\":\"positive_integer\",\"unit\":\"atom\"}',
          bounds(rectangle_with_unit, 144),
          obj([kind-lit("rectangle_with_unit"), length-vary(ints(1,12)), width-vary(ints(1,12)), unit-vary(members([lit("centimeter")]))])).

%  3 machine(s); 169 grid points.
grid_plan('{\"kind\":\"signed_subtraction\",\"minuend\":\"integer\",\"subtrahend\":\"integer\"}',
          bounds(signed_subtraction, 169),
          obj([kind-lit("signed_subtraction"), minuend-vary(ints(-6,6)), subtrahend-vary(ints(-6,6))])).

%  2 machine(s); 156 grid points.
grid_plan('{\"base\":\"positive_integer\",\"count\":\"integer\",\"kind\":\"cardinality\"}',
          bounds(cardinality, 156),
          obj([base-vary(ints(1,12)), count-vary(ints(0,12)), kind-lit("cardinality")])).

%  2 machine(s); 144 grid points.
grid_plan('{\"base\":\"positive_integer\",\"count\":\"positive_integer\",\"kind\":\"cardinality\"}',
          bounds(cardinality, 144),
          obj([base-vary(ints(1,12)), count-vary(ints(1,12)), kind-lit("cardinality")])).

%  2 machine(s); 1000 grid points.
grid_plan('{\"base\":\"positive_integer\",\"kind\":\"count_pair\",\"left\":\"integer\",\"right\":\"integer\"}',
          bounds(count_pair, 1000),
          obj([base-vary(ints(1,10)), kind-lit("count_pair"), left-vary(ints(0,9)), right-vary(ints(0,9))])).

%  2 machine(s); 12 grid points.
grid_plan('{\"kind\":\"angle_measure\",\"degrees\":\"positive_integer\"}',
          bounds(angle_measure, 12),
          obj([kind-lit("angle_measure"), degrees-vary(ints(1,12))])).

%  2 machine(s); 144 grid points.
grid_plan('{\"kind\":\"area_known_side\",\"area\":\"positive_integer\",\"known_side\":\"positive_integer\"}',
          bounds(area_known_side, 144),
          obj([kind-lit("area_known_side"), area-vary(ints(1,12)), known_side-vary(ints(1,12))])).

%  2 machine(s); 4 grid points.
grid_plan('{\"kind\":\"area_unit_candidates\",\"extent\":\"atom\",\"candidates\":[{\"unit\":\"atom\",\"extent\":\"atom\"}]}',
          bounds(area_unit_candidates, 4),
          obj([kind-lit("area_unit_candidates"), extent-vary(members([lit("medium")])), candidates-vary(members([arr([obj([unit-lit("square_inch"), extent-lit("small")]), obj([unit-lit("square_foot"), extent-lit("medium")]), obj([unit-lit("square_meter"), extent-lit("large")])]), arr([obj([unit-lit("square_inch"), extent-lit("small")]), obj([unit-lit("square_foot"), extent-lit("medium")])]), arr([obj([unit-lit("square_inch"), extent-lit("small")])]), arr([obj([unit-lit("square_meter"), extent-lit("large")]), obj([unit-lit("square_foot"), extent-lit("medium")]), obj([unit-lit("square_inch"), extent-lit("small")])])]))])).

%  2 machine(s); 1000 grid points.
grid_plan('{\"kind\":\"circle_co_measurement\",\"given_measure\":\"atom\",\"value\":\"positive_number\",\"unit\":\"atom\",\"requested_measure\":\"atom\",\"pi\":{\"n\":\"positive_integer\",\"d\":\"positive_integer\"}}',
          bounds(circle_co_measurement, 1000),
          obj([kind-lit("circle_co_measurement"), given_measure-vary(members([lit("diameter")])), value-vary(ints(1,10)), unit-vary(members([lit("cm")])), requested_measure-vary(members([lit("circumference")])), pi-obj([n-vary(ints(1,10)), d-vary(ints(1,10))])])).

%  2 machine(s); 625 grid points.
grid_plan('{\"kind\":\"collection_pair\",\"left\":\"positive_integer\",\"left_extent\":\"positive_integer\",\"right\":\"positive_integer\",\"right_extent\":\"positive_integer\"}',
          bounds(collection_pair, 625),
          obj([kind-lit("collection_pair"), left-vary(ints(1,5)), left_extent-vary(ints(1,5)), right-vary(ints(1,5)), right_extent-vary(ints(1,5))])).

%  2 machine(s); 625 grid points.
grid_plan('{\"kind\":\"coordinate_point_pair\",\"first\":{\"x\":\"number\",\"y\":\"number\"},\"second\":{\"x\":\"number\",\"y\":\"number\"},\"unit\":\"atom\"}',
          bounds(coordinate_point_pair, 625),
          obj([kind-lit("coordinate_point_pair"), first-obj([x-vary(ints(0,4)), y-vary(ints(0,4))]), second-obj([x-vary(ints(0,4)), y-vary(ints(0,4))]), unit-vary(members([lit("centimeter")]))])).

%  2 machine(s); 117 grid points.
grid_plan('{\"kind\":\"decimal_unit_conversion\",\"count\":\"integer\",\"from_scale\":\"positive_integer\",\"to_scale\":\"positive_integer\"}',
          bounds(decimal_unit_conversion, 117),
          obj([kind-lit("decimal_unit_conversion"), count-vary(ints(0,12)), from_scale-vary(members([lit(1), lit(10), lit(100)])), to_scale-vary(members([lit(1), lit(10), lit(100)]))])).

%  2 machine(s); 1000 grid points.
grid_plan('{\"kind\":\"diagram_relation\",\"representation\":\"atom\",\"groups\":\"positive_integer\",\"group_expression\":{\"node\":\"var\",\"name\":\"atom\"},\"additional\":\"number\",\"total\":\"number\",\"equation_form\":\"atom\"}',
          bounds(diagram_relation, 1000),
          obj([kind-lit("diagram_relation"), representation-vary(members([lit("tape")])), groups-vary(ints(1,10)), group_expression-obj([node-lit("var"), name-vary(members([lit("x")]))]), additional-vary(ints(0,9)), total-vary(ints(0,9)), equation_form-vary(members([lit("px_plus_q_equals_r")]))])).

%  2 machine(s); 13 grid points.
grid_plan('{\"kind\":\"dimensional_measure\",\"dimension\":\"atom\",\"value\":\"number\",\"unit\":\"atom\"}',
          bounds(dimensional_measure, 13),
          obj([kind-lit("dimensional_measure"), dimension-vary(members([lit("two_dimensional")])), value-vary(ints(0,12)), unit-vary(members([lit("centimeter")]))])).

%  2 machine(s); 169 grid points.
grid_plan('{\"kind\":\"equation_assignment\",\"left\":{\"node\":\"add\",\"left\":{\"node\":\"var\",\"name\":\"atom\"},\"right\":{\"node\":\"int\",\"value\":\"integer\"}},\"right\":{\"node\":\"int\",\"value\":\"integer\"},\"assignments\":[{\"variable\":\"atom\",\"value\":\"integer\"}]}',
          bounds(equation_assignment, 169),
          obj([kind-lit("equation_assignment"), left-obj([node-lit("add"), left-obj([node-lit("var"), name-vary(members([lit("x")]))]), right-obj([node-lit("int"), value-vary(ints(0,12))])]), right-obj([node-lit("int"), value-vary(ints(0,12))]), assignments-vary(members([arr([obj([variable-lit("x"), value-lit(5)])])]))])).

%  2 machine(s); 169 grid points.
grid_plan('{\"kind\":\"expression_rewrite\",\"expression\":{\"node\":\"mult\",\"left\":{\"node\":\"int\",\"value\":\"integer\"},\"right\":{\"node\":\"add\",\"left\":{\"node\":\"var\",\"name\":\"atom\"},\"right\":{\"node\":\"int\",\"value\":\"integer\"}}},\"direction\":\"atom\"}',
          bounds(expression_rewrite, 169),
          obj([kind-lit("expression_rewrite"), expression-obj([node-lit("mult"), left-obj([node-lit("int"), value-vary(ints(0,12))]), right-obj([node-lit("add"), left-obj([node-lit("var"), name-vary(members([lit("x")]))]), right-obj([node-lit("int"), value-vary(ints(0,12))])])]), direction-vary(members([lit("expand")]))])).

%  2 machine(s); 625 grid points.
grid_plan('{\"kind\":\"fraction_addend_pair\",\"left\":{\"n\":\"integer\",\"d\":\"positive_integer\"},\"right\":{\"n\":\"integer\",\"d\":\"positive_integer\"}}',
          bounds(fraction_addend_pair, 625),
          obj([kind-lit("fraction_addend_pair"), left-obj([n-vary(ints(0,4)), d-vary(ints(1,5))]), right-obj([n-vary(ints(0,4)), d-vary(ints(1,5))])])).

%  2 machine(s); 1000 grid points.
grid_plan('{\"kind\":\"fraction_solve\",\"coefficient\":{\"n\":\"positive_integer\",\"d\":\"positive_integer\"},\"total\":\"positive_integer\"}',
          bounds(fraction_solve, 1000),
          obj([kind-lit("fraction_solve"), coefficient-obj([n-vary(ints(1,10)), d-vary(ints(1,10))]), total-vary(ints(1,10))])).

%  2 machine(s); 156 grid points.
grid_plan('{\"kind\":\"frequency_record\",\"event\":\"atom\",\"successes\":\"integer\",\"trials\":\"positive_integer\",\"context\":\"repeated_experiment\"}',
          bounds(frequency_record, 156),
          obj([kind-lit("frequency_record"), event-vary(members([lit("win")])), successes-vary(ints(0,12)), trials-vary(ints(1,12)), context-lit("repeated_experiment")])).

%  2 machine(s); 13 grid points.
grid_plan('{\"kind\":\"inequality\",\"variable\":\"atom\",\"relation\":\"atom\",\"bound\":\"integer\"}',
          bounds(inequality, 13),
          obj([kind-lit("inequality"), variable-vary(members([lit("x")])), relation-vary(members([lit("lt")])), bound-vary(ints(0,12))])).

%  2 machine(s); 1000 grid points.
grid_plan('{\"kind\":\"linear_equation\",\"a\":\"integer\",\"b\":\"integer\",\"c\":\"integer\"}',
          bounds(linear_equation, 1000),
          obj([kind-lit("linear_equation"), a-vary(ints(0,9)), b-vary(ints(0,9)), c-vary(ints(0,9))])).

%  2 machine(s); 169 grid points.
grid_plan('{\"kind\":\"measured_change\",\"operation\":\"atom\",\"a\":\"integer\",\"b\":\"integer\",\"unit\":\"atom\"}',
          bounds(measured_change, 169),
          obj([kind-lit("measured_change"), operation-vary(members([lit("add")])), a-vary(ints(0,12)), b-vary(ints(0,12)), unit-vary(members([lit("centimeter")]))])).

%  2 machine(s); 625 grid points.
grid_plan('{\"kind\":\"parallelogram_with_unit\",\"base\":\"positive_integer\",\"height\":\"positive_integer\",\"slanted_side\":\"positive_integer\",\"offset\":\"integer\",\"unit\":\"atom\"}',
          bounds(parallelogram_with_unit, 625),
          obj([kind-lit("parallelogram_with_unit"), base-vary(ints(1,5)), height-vary(ints(1,5)), slanted_side-vary(ints(1,5)), offset-vary(ints(0,4)), unit-vary(members([lit("centimeter")]))])).

%  2 machine(s); 5 grid points.
grid_plan('{\"kind\":\"polygon_sides_with_unit\",\"sides\":[\"positive_number\"],\"unit\":\"atom\"}',
          bounds(polygon_sides_with_unit, 5),
          obj([kind-lit("polygon_sides_with_unit"), sides-vary(members([arr([lit(5), lit(7), lit(4), lit(6)]), arr([lit(6), lit(8), lit(5), lit(7)]), arr([lit(4), lit(5), lit(6), lit(7)]), arr([lit(5), lit(5), lit(5), lit(5)]), arr([lit(6), lit(4), lit(7), lit(5)])])), unit-vary(members([lit("centimeter")]))])).

%  2 machine(s); 169 grid points.
grid_plan('{\"kind\":\"power_notation\",\"base\":{\"node\":\"int\",\"value\":\"integer\"},\"exponent\":\"integer\"}',
          bounds(power_notation, 169),
          obj([kind-lit("power_notation"), base-obj([node-lit("int"), value-vary(ints(0,12))]), exponent-vary(ints(0,12))])).

%  2 machine(s); 156 grid points.
grid_plan('{\"kind\":\"quantity_conversion\",\"count\":\"integer\",\"from_unit\":\"atom\",\"to_unit\":\"atom\",\"factor\":\"positive_integer\"}',
          bounds(quantity_conversion, 156),
          obj([kind-lit("quantity_conversion"), count-vary(ints(0,12)), from_unit-vary(members([lit("yard")])), to_unit-vary(members([lit("foot")])), factor-vary(ints(1,12))])).

%  2 machine(s); 144 grid points.
grid_plan('{\"kind\":\"ratio_pair_unit_rate\",\"first\":\"positive_number\",\"second\":\"positive_number\",\"referent\":\"atom\"}',
          bounds(ratio_pair_unit_rate, 144),
          obj([kind-lit("ratio_pair_unit_rate"), first-vary(ints(1,12)), second-vary(ints(1,12)), referent-vary(members([lit("first_per_second")]))])).

%  2 machine(s); 208 grid points.
grid_plan('{\"kind\":\"rational_limit\",\"numerator\":{\"coefficients\":[\"integer\"]},\"denominator\":{\"coefficients\":[\"integer\"]},\"at\":\"integer\"}',
          bounds(rational_limit, 208),
          obj([kind-lit("rational_limit"), numerator-obj([coefficients-vary(members([arr([lit(-2), lit(1), lit(1)]), arr([lit(-1), lit(2), lit(2)]), arr([lit(-2), lit(-2), lit(-2)]), arr([lit(1), lit(1), lit(-2)])]))]), denominator-obj([coefficients-vary(members([arr([lit(-1), lit(1)]), arr([lit(0), lit(2)]), arr([lit(-1), lit(-1)]), arr([lit(1), lit(-1)])]))]), at-vary(ints(0,12))])).

%  2 machine(s); 144 grid points.
grid_plan('{\"kind\":\"rectangle_constraints\",\"area\":\"positive_integer\",\"perimeter\":\"positive_integer\"}',
          bounds(rectangle_constraints, 144),
          obj([kind-lit("rectangle_constraints"), area-vary(ints(1,12)), perimeter-vary(ints(1,12))])).

%  2 machine(s); 144 grid points.
grid_plan('{\"kind\":\"referent_pair\",\"first\":{\"label\":\"atom\",\"count\":\"positive_integer\"},\"second\":{\"label\":\"atom\",\"count\":\"positive_integer\"}}',
          bounds(referent_pair, 144),
          obj([kind-lit("referent_pair"), first-obj([label-vary(members([lit("red_tiles")])), count-vary(ints(1,12))]), second-obj([label-vary(members([lit("blue_tiles")])), count-vary(ints(1,12))])])).

%  2 machine(s); 52 grid points.
grid_plan('{\"kind\":\"shape_attributes\",\"shape\":\"atom\",\"attributes\":[{\"name\":\"atom\",\"value\":\"integer\"}],\"quarter_turns\":\"integer\"}',
          bounds(shape_attributes, 52),
          obj([kind-lit("shape_attributes"), shape-vary(members([lit("square")])), attributes-vary(members([arr([obj([name-lit("straight_sides"), value-lit(4)]), obj([name-lit("vertices"), value-lit(4)]), obj([name-lit("right_angles"), value-lit(4)]), obj([name-lit("equal_sides"), value-lit(4)])]), arr([obj([name-lit("straight_sides"), value-lit(4)]), obj([name-lit("vertices"), value-lit(4)]), obj([name-lit("right_angles"), value-lit(4)])]), arr([obj([name-lit("straight_sides"), value-lit(4)])]), arr([obj([name-lit("equal_sides"), value-lit(4)]), obj([name-lit("right_angles"), value-lit(4)]), obj([name-lit("vertices"), value-lit(4)]), obj([name-lit("straight_sides"), value-lit(4)])])])), quarter_turns-vary(ints(0,12))])).

%  2 machine(s); 169 grid points.
grid_plan('{\"kind\":\"signed_division\",\"dividend\":\"integer\",\"divisor\":\"integer\"}',
          bounds(signed_division, 169),
          obj([kind-lit("signed_division"), dividend-vary(ints(-6,6)), divisor-vary(ints(-6,6))])).

%  2 machine(s); 9 grid points.
grid_plan('{\"kind\":\"signed_linear_expression\",\"variable_terms\":[{\"operation\":\"atom\",\"coefficient\":\"number\",\"variable\":\"atom\"}],\"constant_terms\":[{\"operation\":\"atom\",\"value\":\"number\"}],\"direction\":\"combine_like_terms\"}',
          bounds(signed_linear_expression, 9),
          obj([kind-lit("signed_linear_expression"), variable_terms-vary(members([arr([obj([operation-lit("add"), coefficient-lit(7), variable-lit("x")]), obj([operation-lit("subtract"), coefficient-lit(2), variable-lit("x")])]), arr([obj([operation-lit("add"), coefficient-lit(7), variable-lit("x")])]), arr([obj([operation-lit("subtract"), coefficient-lit(2), variable-lit("x")]), obj([operation-lit("add"), coefficient-lit(7), variable-lit("x")])])])), constant_terms-vary(members([arr([obj([operation-lit("add"), value-lit(8)]), obj([operation-lit("subtract"), value-lit(3)])]), arr([obj([operation-lit("add"), value-lit(8)])]), arr([obj([operation-lit("subtract"), value-lit(3)]), obj([operation-lit("add"), value-lit(8)])])])), direction-lit("combine_like_terms")])).

%  2 machine(s); 169 grid points.
grid_plan('{\"kind\":\"signed_multiplication\",\"multiplier\":\"integer\",\"multiplicand\":\"integer\"}',
          bounds(signed_multiplication, 169),
          obj([kind-lit("signed_multiplication"), multiplier-vary(ints(-6,6)), multiplicand-vary(ints(-6,6))])).

%  2 machine(s); 5 grid points.
grid_plan('{\"kind\":\"signed_number_list\",\"values\":[\"integer\"]}',
          bounds(signed_number_list, 5),
          obj([kind-lit("signed_number_list"), values-vary(members([arr([lit(-7), lit(3), lit(-2), lit(5)]), arr([lit(-6), lit(4), lit(-1), lit(6)]), arr([lit(-7), lit(-2), lit(3), lit(5)]), arr([lit(-7), lit(-7), lit(-7), lit(-7)]), arr([lit(5), lit(-2), lit(3), lit(-7)])]))])).

%  2 machine(s); 4 grid points.
grid_plan('{\"kind\":\"solid_net\",\"solid\":\"atom\",\"face_areas\":[\"positive_integer\"],\"unit\":\"atom\"}',
          bounds(solid_net, 4),
          obj([kind-lit("solid_net"), solid-vary(members([lit("cube")])), face_areas-vary(members([arr([lit(12), lit(12), lit(8), lit(8), lit(6), lit(6)]), arr([lit(13), lit(13), lit(9), lit(9), lit(7), lit(7)]), arr([lit(6), lit(6), lit(8), lit(8), lit(12), lit(12)]), arr([lit(12), lit(12), lit(12), lit(12), lit(12), lit(12)])])), unit-vary(members([lit("centimeter")]))])).

%  2 machine(s); 625 grid points.
grid_plan('{\"kind\":\"solid_volume_comparison\",\"count_a\":\"positive_integer\",\"count_b\":\"positive_integer\",\"extent_a\":\"positive_number\",\"extent_b\":\"positive_number\"}',
          bounds(solid_volume_comparison, 625),
          obj([kind-lit("solid_volume_comparison"), count_a-vary(ints(1,5)), count_b-vary(ints(1,5)), extent_a-vary(ints(1,5)), extent_b-vary(ints(1,5))])).

%  2 machine(s); 1 grid points.
grid_plan('{\"kind\":\"statistical_question\",\"variable\":\"atom\",\"population\":\"atom\"}',
          bounds(statistical_question, 1),
          obj([kind-lit("statistical_question"), variable-vary(members([lit("commute_time")])), population-vary(members([lit("students")]))])).

%  2 machine(s); 144 grid points.
grid_plan('{\"kind\":\"symmetry_side_orbits\",\"known_orbits\":[{\"copies\":\"positive_integer\",\"length\":\"positive_integer\"}],\"unknown_orbit\":{\"copies\":\"positive_integer\",\"name\":\"atom\"},\"perimeter\":\"positive_integer\",\"unit\":\"atom\"}',
          bounds(symmetry_side_orbits, 144),
          obj([kind-lit("symmetry_side_orbits"), known_orbits-vary(members([arr([obj([copies-lit(2), length-lit(5)])])])), unknown_orbit-obj([copies-vary(ints(1,12)), name-vary(members([lit("slanted_side")]))]), perimeter-vary(ints(1,12)), unit-vary(members([lit("centimeter")]))])).

%  2 machine(s); 144 grid points.
grid_plan('{\"kind\":\"triangle_with_unit\",\"base\":\"positive_integer\",\"height\":\"positive_integer\",\"unit\":\"atom\"}',
          bounds(triangle_with_unit, 144),
          obj([kind-lit("triangle_with_unit"), base-vary(ints(1,12)), height-vary(ints(1,12)), unit-vary(members([lit("centimeter")]))])).

%  2 machine(s); 1000 grid points.
grid_plan('{\"kind\":\"volume_known_base\",\"volume\":\"positive_integer\",\"length\":\"positive_integer\",\"width\":\"positive_integer\"}',
          bounds(volume_known_base, 1000),
          obj([kind-lit("volume_known_base"), volume-vary(ints(1,10)), length-vary(ints(1,10)), width-vary(ints(1,10))])).

%  1 machine(s); 60 grid points.
grid_plan('{\"kind\":\"angle_parts\",\"parts\":[\"positive_integer\"],\"whole\":\"positive_integer\"}',
          bounds(angle_parts, 60),
          obj([kind-lit("angle_parts"), parts-vary(members([arr([lit(35), lit(50), lit(45)]), arr([lit(36), lit(51), lit(46)]), arr([lit(35), lit(45), lit(50)]), arr([lit(35), lit(35), lit(35)]), arr([lit(45), lit(50), lit(35)])])), whole-vary(ints(1,12))])).

%  1 machine(s); 48 grid points.
grid_plan('{\"kind\":\"angle_relation\",\"whole\":\"positive_number\",\"known_parts\":[\"positive_number\"],\"unknown\":\"atom\"}',
          bounds(angle_relation, 48),
          obj([kind-lit("angle_relation"), whole-vary(ints(1,12)), known_parts-vary(members([arr([lit(110), lit(30)]), arr([lit(111), lit(31)]), arr([lit(30), lit(110)]), arr([lit(110), lit(110)])])), unknown-vary(members([lit("x")]))])).

%  1 machine(s); 12 grid points.
grid_plan('{\"kind\":\"area_scope\",\"area\":\"positive_integer\",\"scope\":\"atom\"}',
          bounds(area_scope, 12),
          obj([kind-lit("area_scope"), area-vary(ints(1,12)), scope-vary(members([lit("all")]))])).

%  1 machine(s); 12 grid points.
grid_plan('{\"kind\":\"bounded_sequence_limit\",\"numerator\":\"atom\",\"bound\":\"positive_integer\",\"denominator\":\"atom\"}',
          bounds(bounded_sequence_limit, 12),
          obj([kind-lit("bounded_sequence_limit"), numerator-vary(members([lit("cosine_of_n_x")])), bound-vary(ints(1,12)), denominator-vary(members([lit("linear_in_n")]))])).

%  1 machine(s); 4 grid points.
grid_plan('{\"kind\":\"box_plot_data\",\"values\":[\"integer\"],\"display\":\"box_plot\"}',
          bounds(box_plot_data, 4),
          obj([kind-lit("box_plot_data"), values-vary(members([arr([lit(2), lit(4), lit(5), lit(7), lit(9)]), arr([lit(3), lit(5), lit(6), lit(8), lit(10)]), arr([lit(2), lit(2), lit(2), lit(2), lit(2)]), arr([lit(9), lit(7), lit(5), lit(4), lit(2)])])), display-lit("box_plot")])).

%  1 machine(s); 3 grid points.
grid_plan('{\"kind\":\"categorical_frequencies\",\"pairs\":[{\"category\":\"atom\",\"count\":\"integer\"}],\"display\":\"bar_chart\"}',
          bounds(categorical_frequencies, 3),
          obj([kind-lit("categorical_frequencies"), pairs-vary(members([arr([obj([category-lit("red"), count-lit(4)]), obj([category-lit("blue"), count-lit(6)])]), arr([obj([category-lit("red"), count-lit(4)])]), arr([obj([category-lit("blue"), count-lit(6)]), obj([category-lit("red"), count-lit(4)])])])), display-lit("bar_chart")])).

%  1 machine(s); 4 grid points.
grid_plan('{\"kind\":\"coordinate_points\",\"points\":[{\"x\":\"number\",\"y\":\"number\"}]}',
          bounds(coordinate_points, 4),
          obj([kind-lit("coordinate_points"), points-vary(members([arr([obj([x-lit(-3), y-lit(2)]), obj([x-lit(1), y-lit(4)]), obj([x-lit(5), y-lit(-1)])]), arr([obj([x-lit(-3), y-lit(2)]), obj([x-lit(1), y-lit(4)])]), arr([obj([x-lit(-3), y-lit(2)])]), arr([obj([x-lit(5), y-lit(-1)]), obj([x-lit(1), y-lit(4)]), obj([x-lit(-3), y-lit(2)])])]))])).

%  1 machine(s); 4 grid points.
grid_plan('{\"kind\":\"covered_cells\",\"cells\":[{\"x\":\"integer\",\"y\":\"integer\"}],\"unit\":\"atom\"}',
          bounds(covered_cells, 4),
          obj([kind-lit("covered_cells"), cells-vary(members([arr([obj([x-lit(0), y-lit(0)]), obj([x-lit(1), y-lit(0)]), obj([x-lit(0), y-lit(1)])]), arr([obj([x-lit(0), y-lit(0)]), obj([x-lit(1), y-lit(0)])]), arr([obj([x-lit(0), y-lit(0)])]), arr([obj([x-lit(0), y-lit(1)]), obj([x-lit(1), y-lit(0)]), obj([x-lit(0), y-lit(0)])])])), unit-vary(members([lit("centimeter")]))])).

%  1 machine(s); 624 grid points.
grid_plan('{\"kind\":\"decimal_pair\",\"left\":{\"numeral\":\"integer\",\"scale\":\"positive_integer\"},\"right\":{\"numeral\":\"positive_integer\",\"scale\":\"positive_integer\"}}',
          bounds(decimal_pair, 624),
          obj([kind-lit("decimal_pair"), left-obj([numeral-vary(ints(0,12)), scale-vary(members([lit(10), lit(100)]))]), right-obj([numeral-vary(ints(1,12)), scale-vary(members([lit(10), lit(100)]))])])).

%  1 machine(s); 144 grid points.
grid_plan('{\"kind\":\"decimal_pair\",\"left\":{\"numeral\":\"positive_integer\",\"scale\":1},\"right\":{\"numeral\":\"positive_integer\",\"scale\":1}}',
          bounds(decimal_pair, 144),
          obj([kind-lit("decimal_pair"), left-obj([numeral-vary(ints(1,12)), scale-lit(1)]), right-obj([numeral-vary(ints(1,12)), scale-lit(1)])])).

%  1 machine(s); 3 grid points.
grid_plan('{\"kind\":\"disjoint_prisms\",\"prisms\":[{\"length\":\"positive_integer\",\"width\":\"positive_integer\",\"height\":\"positive_integer\"}],\"unit\":\"atom\"}',
          bounds(disjoint_prisms, 3),
          obj([kind-lit("disjoint_prisms"), prisms-vary(members([arr([obj([length-lit(2), width-lit(3), height-lit(4)]), obj([length-lit(1), width-lit(2), height-lit(5)])]), arr([obj([length-lit(2), width-lit(3), height-lit(4)])]), arr([obj([length-lit(1), width-lit(2), height-lit(5)]), obj([length-lit(2), width-lit(3), height-lit(4)])])])), unit-vary(members([lit("centimeter")]))])).

%  1 machine(s); 4 grid points.
grid_plan('{\"kind\":\"distribution_data\",\"values\":[\"integer\"],\"profile\":\"atom\"}',
          bounds(distribution_data, 4),
          obj([kind-lit("distribution_data"), values-vary(members([arr([lit(2), lit(4), lit(6), lit(8)]), arr([lit(3), lit(5), lit(7), lit(9)]), arr([lit(2), lit(2), lit(2), lit(2)]), arr([lit(8), lit(6), lit(4), lit(2)])])), profile-vary(members([lit("symmetric_without_outliers")]))])).

%  1 machine(s); 169 grid points.
grid_plan('{\"kind\":\"expression_assignment\",\"expression\":{\"node\":\"add\",\"left\":{\"node\":\"mult\",\"left\":{\"node\":\"var\",\"name\":\"atom\"},\"right\":{\"node\":\"int\",\"value\":\"integer\"}},\"right\":{\"node\":\"int\",\"value\":\"integer\"}},\"assignments\":[{\"variable\":\"atom\",\"value\":\"integer\"}]}',
          bounds(expression_assignment, 169),
          obj([kind-lit("expression_assignment"), expression-obj([node-lit("add"), left-obj([node-lit("mult"), left-obj([node-lit("var"), name-vary(members([lit("x")]))]), right-obj([node-lit("int"), value-vary(ints(0,12))])]), right-obj([node-lit("int"), value-vary(ints(0,12))])]), assignments-vary(members([arr([obj([variable-lit("x"), value-lit(4)])])]))])).

%  1 machine(s); 243 grid points.
grid_plan('{\"kind\":\"expression_pair\",\"left\":{\"node\":\"power\",\"base\":{\"node\":\"int\",\"value\":\"integer\"},\"exponent\":\"integer\"},\"right\":{\"node\":\"mult\",\"left\":{\"node\":\"int\",\"value\":\"integer\"},\"right\":{\"node\":\"mult\",\"left\":{\"node\":\"int\",\"value\":\"integer\"},\"right\":{\"node\":\"int\",\"value\":\"integer\"}}}}',
          bounds(expression_pair, 243),
          obj([kind-lit("expression_pair"), left-obj([node-lit("power"), base-obj([node-lit("int"), value-vary(ints(0,2))]), exponent-vary(ints(0,2))]), right-obj([node-lit("mult"), left-obj([node-lit("int"), value-vary(ints(0,2))]), right-obj([node-lit("mult"), left-obj([node-lit("int"), value-vary(ints(0,2))]), right-obj([node-lit("int"), value-vary(ints(0,2))])])])])).

%  1 machine(s); 625 grid points.
grid_plan('{\"kind\":\"fraction_minuend_subtrahend\",\"left\":{\"n\":\"integer\",\"d\":\"positive_integer\"},\"right\":{\"n\":\"integer\",\"d\":\"positive_integer\"}}',
          bounds(fraction_minuend_subtrahend, 625),
          obj([kind-lit("fraction_minuend_subtrahend"), left-obj([n-vary(ints(0,4)), d-vary(ints(1,5))]), right-obj([n-vary(ints(0,4)), d-vary(ints(1,5))])])).

%  1 machine(s); 48 grid points.
grid_plan('{\"kind\":\"histogram_data\",\"values\":[\"integer\"],\"bin_width\":\"positive_integer\"}',
          bounds(histogram_data, 48),
          obj([kind-lit("histogram_data"), values-vary(members([arr([lit(2), lit(3), lit(5), lit(7), lit(8), lit(9)]), arr([lit(3), lit(4), lit(6), lit(8), lit(9), lit(10)]), arr([lit(2), lit(2), lit(2), lit(2), lit(2), lit(2)]), arr([lit(9), lit(8), lit(7), lit(5), lit(3), lit(2)])])), bin_width-vary(ints(1,12))])).

%  1 machine(s); 864 grid points.
grid_plan('{\"kind\":\"linear_context\",\"unknown\":\"atom\",\"coefficient\":\"number\",\"offset\":\"number\",\"total\":\"number\",\"referent_roles\":[\"atom\"]}',
          bounds(linear_context, 864),
          obj([kind-lit("linear_context"), unknown-vary(members([lit("x")])), coefficient-vary(ints(0,5)), offset-vary(ints(0,5)), total-vary(ints(0,5)), referent_roles-vary(members([arr([lit("groups"), lit("loose_items"), lit("total")]), arr([lit("groups"), lit("loose_items")]), arr([lit("groups")]), arr([lit("total"), lit("loose_items"), lit("groups")])]))])).

%  1 machine(s); 1000 grid points.
grid_plan('{\"kind\":\"linear_pattern_context\",\"first\":\"integer\",\"change\":\"integer\",\"row\":\"positive_integer\",\"context\":\"atom\"}',
          bounds(linear_pattern_context, 1000),
          obj([kind-lit("linear_pattern_context"), first-vary(ints(0,9)), change-vary(ints(0,9)), row-vary(ints(1,10)), context-vary(members([lit("tile_pattern")]))])).

%  1 machine(s); 729 grid points.
grid_plan('{\"kind\":\"linear_pattern_empirical_rule\",\"first\":\"integer\",\"change\":\"integer\",\"row\":\"positive_integer\",\"multiplier\":\"integer\",\"constant\":\"integer\",\"checked_rows\":[\"integer\"]}',
          bounds(linear_pattern_empirical_rule, 729),
          obj([kind-lit("linear_pattern_empirical_rule"), first-vary(ints(0,2)), change-vary(ints(0,2)), row-vary(ints(1,3)), multiplier-vary(ints(0,2)), constant-vary(ints(0,2)), checked_rows-vary(members([arr([lit(1), lit(2), lit(3)]), arr([lit(2), lit(3), lit(4)]), arr([lit(1), lit(1), lit(1)])]))])).

%  1 machine(s); 4 grid points.
grid_plan('{\"kind\":\"numeric_data_display\",\"values\":[\"integer\"],\"display\":\"dot_plot\"}',
          bounds(numeric_data_display, 4),
          obj([kind-lit("numeric_data_display"), values-vary(members([arr([lit(2), lit(3), lit(3), lit(5)]), arr([lit(3), lit(4), lit(4), lit(6)]), arr([lit(2), lit(2), lit(2), lit(2)]), arr([lit(5), lit(3), lit(3), lit(2)])])), display-lit("dot_plot")])).

%  1 machine(s); 36 grid points.
grid_plan('{\"kind\":\"overlapping_prisms\",\"prisms\":[{\"length\":\"positive_integer\",\"width\":\"positive_integer\",\"height\":\"positive_integer\"}],\"overlap_volume\":\"positive_integer\",\"unit\":\"atom\"}',
          bounds(overlapping_prisms, 36),
          obj([kind-lit("overlapping_prisms"), prisms-vary(members([arr([obj([length-lit(2), width-lit(3), height-lit(4)]), obj([length-lit(1), width-lit(2), height-lit(5)])]), arr([obj([length-lit(2), width-lit(3), height-lit(4)])]), arr([obj([length-lit(1), width-lit(2), height-lit(5)]), obj([length-lit(2), width-lit(3), height-lit(4)])])])), overlap_volume-vary(ints(1,12)), unit-vary(members([lit("centimeter")]))])).

%  1 machine(s); 169 grid points.
grid_plan('{\"kind\":\"percent_change\",\"amount_role\":\"atom\",\"amount\":\"number\",\"rate_percent\":\"number\",\"direction\":\"atom\",\"target\":\"atom\"}',
          bounds(percent_change, 169),
          obj([kind-lit("percent_change"), amount_role-vary(members([lit("original_amount")])), amount-vary(ints(0,12)), rate_percent-vary(ints(0,12)), direction-vary(members([lit("increase")])), target-vary(members([lit("new_amount")]))])).

%  1 machine(s); 144 grid points.
grid_plan('{\"kind\":\"perimeter_known_side\",\"perimeter\":\"positive_integer\",\"known_side\":\"positive_integer\"}',
          bounds(perimeter_known_side, 144),
          obj([kind-lit("perimeter_known_side"), perimeter-vary(ints(1,12)), known_side-vary(ints(1,12))])).

%  1 machine(s); 12 grid points.
grid_plan('{\"kind\":\"perimeter_scope\",\"perimeter\":\"positive_integer\",\"scope\":\"atom\"}',
          bounds(perimeter_scope, 12),
          obj([kind-lit("perimeter_scope"), perimeter-vary(ints(1,12)), scope-vary(members([lit("all")]))])).

%  1 machine(s); 3 grid points.
grid_plan('{\"kind\":\"placed_tiles\",\"cells\":[{\"x\":\"integer\",\"y\":\"integer\"}],\"unit\":\"atom\"}',
          bounds(placed_tiles, 3),
          obj([kind-lit("placed_tiles"), cells-vary(members([arr([obj([x-lit(0), y-lit(0)]), obj([x-lit(1), y-lit(0)]), obj([x-lit(0), y-lit(0)])]), arr([obj([x-lit(0), y-lit(0)]), obj([x-lit(1), y-lit(0)])]), arr([obj([x-lit(0), y-lit(0)])])])), unit-vary(members([lit("centimeter")]))])).

%  1 machine(s); 52 grid points.
grid_plan('{\"kind\":\"polynomial_limit\",\"coefficients\":[\"integer\"],\"at\":\"integer\"}',
          bounds(polynomial_limit, 52),
          obj([kind-lit("polynomial_limit"), coefficients-vary(members([arr([lit(1), lit(2), lit(3)]), arr([lit(2), lit(3), lit(4)]), arr([lit(1), lit(1), lit(1)]), arr([lit(3), lit(2), lit(1)])])), at-vary(ints(0,12))])).

%  1 machine(s); 39 grid points.
grid_plan('{\"kind\":\"quantity_relation\",\"operator\":\"atom\",\"left\":{\"node\":\"var\",\"name\":\"atom\"},\"right\":{\"node\":\"int\",\"value\":\"integer\"},\"referent_roles\":[\"atom\"],\"declared_variables\":[\"atom\"]}',
          bounds(quantity_relation, 39),
          obj([kind-lit("quantity_relation"), operator-vary(members([lit("add")])), left-obj([node-lit("var"), name-vary(members([lit("x")]))]), right-obj([node-lit("int"), value-vary(ints(0,12))]), referent_roles-vary(members([arr([lit("unknown_quantity"), lit("constant_offset")]), arr([lit("unknown_quantity")]), arr([lit("constant_offset"), lit("unknown_quantity")])])), declared_variables-vary(members([arr([lit("x")])]))])).

%  1 machine(s); 1000 grid points.
grid_plan('{\"kind\":\"ratio_pair_solve_at_x\",\"first\":\"positive_number\",\"second\":\"positive_number\",\"target_x\":\"number\"}',
          bounds(ratio_pair_solve_at_x, 1000),
          obj([kind-lit("ratio_pair_solve_at_x"), first-vary(ints(1,10)), second-vary(ints(1,10)), target_x-vary(ints(0,9))])).

%  1 machine(s); 4 grid points.
grid_plan('{\"kind\":\"ratio_pairs_proportionality_test\",\"pairs\":[{\"first\":\"positive_number\",\"second\":\"positive_number\"}],\"test\":\"proportionality_test\"}',
          bounds(ratio_pairs_proportionality_test, 4),
          obj([kind-lit("ratio_pairs_proportionality_test"), pairs-vary(members([arr([obj([first-lit(1), second-lit(3)]), obj([first-lit(2), second-lit(6)]), obj([first-lit(4), second-lit(12)])]), arr([obj([first-lit(1), second-lit(3)]), obj([first-lit(2), second-lit(6)])]), arr([obj([first-lit(1), second-lit(3)])]), arr([obj([first-lit(4), second-lit(12)]), obj([first-lit(2), second-lit(6)]), obj([first-lit(1), second-lit(3)])])])), test-lit("proportionality_test")])).

%  1 machine(s); 1000 grid points.
grid_plan('{\"kind\":\"rectangular_prism\",\"length\":\"positive_integer\",\"width\":\"positive_integer\",\"height\":\"positive_integer\"}',
          bounds(rectangular_prism, 1000),
          obj([kind-lit("rectangular_prism"), length-vary(ints(1,10)), width-vary(ints(1,10)), height-vary(ints(1,10))])).

%  1 machine(s); 784 grid points.
grid_plan('{\"kind\":\"sample_population_distribution\",\"sample\":{\"values\":[\"integer\"],\"shape\":\"atom\"},\"population\":{\"values\":[\"integer\"],\"shape\":\"atom\"},\"tolerances\":{\"center\":\"number\",\"spread\":\"number\"}}',
          bounds(sample_population_distribution, 784),
          obj([kind-lit("sample_population_distribution"), sample-obj([values-vary(members([arr([lit(1), lit(2), lit(3), lit(4), lit(5)]), arr([lit(2), lit(3), lit(4), lit(5), lit(6)]), arr([lit(1), lit(1), lit(1), lit(1), lit(1)]), arr([lit(5), lit(4), lit(3), lit(2), lit(1)])])), shape-vary(members([lit("symmetric")]))]), population-obj([values-vary(members([arr([lit(1), lit(2), lit(3), lit(4), lit(5), lit(6)]), arr([lit(2), lit(3), lit(4), lit(5), lit(6), lit(7)]), arr([lit(1), lit(1), lit(1), lit(1), lit(1), lit(1)]), arr([lit(6), lit(5), lit(4), lit(3), lit(2), lit(1)])])), shape-vary(members([lit("symmetric")]))]), tolerances-obj([center-vary(ints(0,6)), spread-vary(ints(0,6))])])).

%  1 machine(s); 4 grid points.
grid_plan('{\"kind\":\"triangle_conditions\",\"condition\":\"atom\",\"measures\":[\"positive_number\"]}',
          bounds(triangle_conditions, 4),
          obj([kind-lit("triangle_conditions"), condition-vary(members([lit("sss")])), measures-vary(members([arr([lit(3), lit(4), lit(5)]), arr([lit(4), lit(5), lit(6)]), arr([lit(3), lit(3), lit(3)]), arr([lit(5), lit(4), lit(3)])]))])).

% ---- schemas with no plan (grid_input/3 fails; caller records uninstantiated(schema)) ----
%   polygon_partition  (2 machine(s))
%   terminal_path_tree  (2 machine(s))
%   rigid_shape_composition  (1 machine(s))

% totals: plans=80 covered_machines=241 skipped_machines=5


%!  grid_input(+SchemaString, ?Bounds, -Input) is nondet.
%
%   Input is a JSON-shaped dict conforming to SchemaString, drawn from the
%   authored grid for that schema. Bounds names the grid and its authored
%   point count; passing it bound filters, leaving it unbound reports the
%   grid actually used. FAILS when the schema carries no plan — the caller
%   records uninstantiated(schema) rather than inventing a domain.
grid_input(Schema, Bounds, Input) :-
    grid_plan(Schema, Bounds, Template),
    expand_template(Template, Input).

expand_template(obj(Pairs0), Dict) :-
    expand_pairs(Pairs0, Pairs),
    dict_pairs(Dict, _, Pairs).
expand_template(arr(Templates), List) :-
    expand_list(Templates, List).
expand_template(lit(Value), Value).
expand_template(vary(ints(Lo, Hi)), Value) :-
    between(Lo, Hi, Value).
expand_template(vary(members(Alternatives)), Value) :-
    member(Alternative, Alternatives),
    expand_template(Alternative, Value).

expand_pairs([], []).
expand_pairs([Key-Template|Rest0], [Key-Value|Rest]) :-
    expand_template(Template, Value),
    expand_pairs(Rest0, Rest).

expand_list([], []).
expand_list([Template|Rest0], [Value|Rest]) :-
    expand_template(Template, Value),
    expand_list(Rest0, Rest).

%!  grid_point_count(+SchemaString, -Points) is semidet.
%
%   The authored point count. fixture_checks.py compares it against the
%   count grid_input/3 actually enumerates; an authored number nobody
%   re-counts is a claim, not a measurement.
grid_point_count(Schema, Points) :-
    grid_plan(Schema, bounds(_, Points), _).

%!  grid_status(+SchemaString, -Status) is det.
%
%   Status is instantiated(bounds(Name, Points)) or uninstantiated(schema).
grid_status(Schema, Status) :-
    (   grid_plan(Schema, Bounds, _)
    ->  Status = instantiated(Bounds)
    ;   Status = uninstantiated(schema)
    ).


% ==========================================================================
% 3. aa_run/4 — one machine, one input
% ==========================================================================

%!  aa_run(+Family, +Kind, +Input, -Outcome) is det.
%
%   Outcome is one of:
%     result(ResultTerm, Expected, Validity)  the machine computed
%     refused(domain(Family, Kind))           the machine declined this input
%     error(Formal)                           the substrate faulted
%
%   ResultTerm is copied clear of the run's bindings so that comparison is
%   by ==/2 on whole terms. Never compare results with =:=: two machines
%   agreeing numerically while disagreeing in what they built is exactly the
%   distinction these runs exist to record.
aa_run(Family, Kind, Input, Outcome) :-
    (   catch(hermes_encyclopedia:trace_inputs(Input, Left, Right),
              DecodeError, true)
    ->  (   var(DecodeError)
        ->  run_decoded(Family, Kind, Left, Right, Outcome)
        ;   Outcome = error(input_decode_raised(DecodeError))
        )
    ;   Outcome = error(input_decode_failed(Family, Kind))
    ),
    !.

run_decoded(Family, Kind, Left, Right, Outcome) :-
    (   catch(action_automata_registry:run_action_automaton(
                  Family, Kind, Left, Right, action_outcome(_, Fields), _),
              RunError, true)
    ->  (   var(RunError)
        ->  outcome_from_fields(Family, Kind, Fields, Outcome)
        ;   Outcome = error(RunError)
        )
    ;   Outcome = refused(domain(Family, Kind))
    ).

outcome_from_fields(Family, Kind, Fields, Outcome) :-
    (   memberchk(result(Result0), Fields)
    ->  copy_term(Result0, Result),
        (   memberchk(expected(Expected0), Fields)
        ->  copy_term(Expected0, Expected)
        ;   Expected = none
        ),
        (   memberchk(validity(Validity), Fields) -> true ; Validity = none ),
        Outcome = result(Result, Expected, Validity)
    ;   Outcome = error(no_result_field(Family, Kind))
    ).

%!  same_result(+OutcomeA, +OutcomeB) is semidet.
%
%   Both computed, and their result terms are the same term.
same_result(result(ResultA, _, _), result(ResultB, _, _)) :-
    ResultA == ResultB.


% ==========================================================================
% 4. The pair filters
%
% same_schema/2 is measured: it reads the contract rows directly.
%
% family_probe_archetype/2 is NOT measured, and the difference matters. The
% design asks same_archetype/2 to require that two machines' families "share
% a crosswalk probe archetype (the blessed 7-archetype enum)". This checkout
% carries the enum (cw_driver:archetype/1, seven values) and carries edge/6
% rows that give an archetype to a crosswalk family's probe of an owner
% predicate — but it carries no relation from an automaton family (addition,
% fraction, geometry, ...) to an archetype. The rows below are the closest
% derivation the tree admits: for each automaton family, the archetype on the
% cw_misconception_hook edge that probes that family's own action-pair
% module. Every row cites its source line.
%
% WHAT THE DERIVATION COSTS, measured on this checkout:
%   - four families (counting, geometry, measurement, statistics) own no
%     crosswalk edge at all, so 83 of 246 machines get no archetype and drop
%     out of every pair;
%   - ten of the eleven mapped families collapse to call_bind_out, so the
%     "7-archetype" filter is really a two-way split;
%   - addition alone is registry_projection, which severs all 18 addition
%     machines from subtraction, multiplication, and division on the shared
%     69-machine integer-pair schema — the exact comparisons R1 exists to
%     make;
%   - unordered pairs fall 2,696 to 1,625, and cross-family pairs — the ones
%     the design calls "a connection nobody authored" — fall 1,905 to 889.
%
% So the second conjunct removes most of what R1 is for. The report for this
% task carries the block; nothing here picks a winner, and step0_manifests.py
% refuses to write a manifest until the choice is ruled.
% ==========================================================================

%!  same_schema(+MachineA, +MachineB) is semidet.
same_schema(MachineA, MachineB) :-
    machine_schema(MachineA, Schema),
    machine_schema(MachineB, Schema).

%!  family_probe_archetype(?Family, ?Archetype) is nondet.
%
%   Derived from knowledge/crosswalk/families/cw_edges.pl; the fixture check
%   re-derives it from that file and fails on drift. Four families are absent
%   on purpose: the tree gives them no edge, and a guessed archetype would be
%   worse than a hole.
family_probe_archetype(addition,       registry_projection).  % cw_edges.pl:492
family_probe_archetype(subtraction,    call_bind_out).        % cw_edges.pl:493
family_probe_archetype(multiplication, call_bind_out).        % cw_edges.pl:494
family_probe_archetype(division,       call_bind_out).        % cw_edges.pl:495
family_probe_archetype(fraction,       call_bind_out).        % cw_edges.pl:496
family_probe_archetype(decimal,        call_bind_out).        % cw_edges.pl:497
family_probe_archetype(integer,        call_bind_out).        % cw_edges.pl:498
family_probe_archetype(ratio,          call_bind_out).        % cw_edges.pl:499
family_probe_archetype(diagnostic,     call_bind_out).        % cw_edges.pl:500
family_probe_archetype(calculus,       call_bind_out).        % cw_edges.pl:501
family_probe_archetype(algebraic,      call_bind_out).        % cw_edges.pl:502
family_probe_archetype(probability,    call_bind_out).        % cw_edges.pl:503

%!  same_archetype(+MachineA, +MachineB) is semidet.
%
%   The design's pair filter, both conjuncts. See the block comment above.
same_archetype(machine(FamilyA, KindA), machine(FamilyB, KindB)) :-
    same_schema(machine(FamilyA, KindA), machine(FamilyB, KindB)),
    family_probe_archetype(FamilyA, Archetype),
    family_probe_archetype(FamilyB, Archetype).

%!  pair(+Filter, -MachineA, -MachineB) is nondet.
%
%   Canonical unordered pairs under a named filter. Filter is schema_only or
%   schema_and_archetype; there is no default, because the two answer
%   different questions and the difference is the open ruling.
pair(schema_only, MachineA, MachineB) :-
    contracted_machine(MachineA),
    contracted_machine(MachineB),
    MachineA @< MachineB,
    same_schema(MachineA, MachineB).
pair(schema_and_archetype, MachineA, MachineB) :-
    contracted_machine(MachineA),
    contracted_machine(MachineB),
    MachineA @< MachineB,
    same_archetype(MachineA, MachineB).


% ==========================================================================
% 5. main_item/0 — one manifest item in, one output row out
%
% run_loop_array.py writes a single JSON item on stdin and reads a single
% JSON row from stdout. Keeping the item on stdin rather than in argv means
% no shell quoting stands between the manifest and the run.
%
% Every attempted item produces a row. A refusal, a timeout, an exhausted
% budget, and a schema with no grid are all retained rows carrying their
% reason: an empty result is a claim, and it needs its evidence like any
% other.
% ==========================================================================

main_item :-
    json_read_dict(current_input, Item, [value_string_as(string)]),
    item_rows(Item, Rows),
    forall(member(Row, Rows),
           ( json_write_dict(current_output, Row, [width(0)]), nl )).

%!  item_rows(+Item, -Rows) is det.
%
%   One item yields one row for R1 and TWO for R2: R2 walks an unordered
%   pair once and reports both directions from that single walk, because the
%   refusal asymmetry is what it is measuring and running the grid twice to
%   get it would double the cost for nothing.
item_rows(Item, Rows) :-
    get_dict(run, Item, RunString),
    atom_string(Run, RunString),
    (   Run == r1
    ->  r1_row(Item, Row), Rows = [Row]
    ;   Run == r2
    ->  r2_rows(Item, Rows)
    ;   throw(error(domain_error(supported_run, Run),
                    context(loop_driver:item_rows/2,
                            'r1 and r2 items run; see the wave-1 report \c
                             for why r5 has no manifest')))
    ).


% -------------------------------------------------------------------------
% R1 — the equalizer atlas row for one machine pair
% -------------------------------------------------------------------------

r1_row(Item, Row) :-
    item_machine(Item, source, machine(FamilyA, KindA)),
    item_machine(Item, target, machine(FamilyB, KindB)),
    item_number(Item, pair_budget_s, 600, Budget),
    item_number(Item, input_timeout_s, 30, InputTimeout),
    item_number(Item, max_witnesses, 0, MaxWitnesses),
    get_time(Started),
    (   \+ same_schema(machine(FamilyA, KindA), machine(FamilyB, KindB))
    ->  Outcome = uninstantiated,
        Evidence = _{kind: "separating_input",
                     source_outcome: "schema_mismatch",
                     target_outcome: "schema_mismatch",
                     elapsed_ms: 0},
        InputField = _{schema: null, bounds: null, points: 0},
        CandidateType = "pair_rejected"
    ;   machine_schema(machine(FamilyA, KindA), Schema),
        (   grid_plan(Schema, Bounds, _)
        ->  r1_walk(Schema, FamilyA, KindA, FamilyB, KindB,
                    Started, Budget, InputTimeout, MaxWitnesses,
                    Accumulator),
            r1_evidence(Accumulator, Started, Evidence),
            r1_verdict(Accumulator, Outcome, CandidateType),
            grid_point_count(Schema, Points),
            term_string(Bounds, BoundsString),
            InputField = _{schema: Schema, bounds: BoundsString,
                           points: Points}
        ;   Outcome = uninstantiated,
            Evidence = _{kind: "separating_input",
                         source_outcome: "no_grid_plan",
                         target_outcome: "no_grid_plan",
                         elapsed_ms: 0},
            InputField = _{schema: Schema, bounds: null, points: 0},
            CandidateType = "uninstantiated_schema"
        )
    ),
    outcome_atom_string(Outcome, OutcomeString),
    Row = _{run: "r1",
            candidate_type: CandidateType,
            source: _{family: FamilyA, kind: KindA},
            target: _{family: FamilyB, kind: KindB},
            input: InputField,
            evidence: Evidence,
            outcome: OutcomeString,
            consumer: "scripts/research/build_automata_compendium.py:read_r1_atlas_rows \c
                       + scripts/research/separation_coverage_audit.py"}.

%   acc(Ran, Coincide, Separate, Refused, Errored, Witnesses, WitnessCount,
%       Truncated, FirstWitness, Stopped)
r1_walk(Schema, FamilyA, KindA, FamilyB, KindB, Started, Budget,
        InputTimeout, MaxWitnesses, Accumulator) :-
    findall(Input, grid_input(Schema, _, Input), Inputs),
    Empty = acc(0, 0, 0, 0, 0, [], 0, false, none, completed),
    walk_inputs(Inputs, FamilyA, KindA, FamilyB, KindB, Started, Budget,
                InputTimeout, MaxWitnesses, Empty, Accumulator).

walk_inputs([], _, _, _, _, _, _, _, _, Accumulator, Accumulator).
walk_inputs([Input|Rest], FamilyA, KindA, FamilyB, KindB, Started, Budget,
            InputTimeout, MaxWitnesses, Accumulator0, Accumulator) :-
    get_time(Now),
    Elapsed is Now - Started,
    (   Elapsed >= Budget
    ->  set_stopped(Accumulator0, pair_budget, Accumulator)
    ;   run_one_input(Input, FamilyA, KindA, FamilyB, KindB, InputTimeout,
                      MaxWitnesses, Accumulator0, Accumulator1),
        walk_inputs(Rest, FamilyA, KindA, FamilyB, KindB, Started, Budget,
                    InputTimeout, MaxWitnesses, Accumulator1, Accumulator)
    ).

run_one_input(Input, FamilyA, KindA, FamilyB, KindB, InputTimeout,
              MaxWitnesses, Accumulator0, Accumulator) :-
    (   catch(call_with_time_limit(
                  InputTimeout,
                  ( aa_run(FamilyA, KindA, Input, OutcomeA0),
                    aa_run(FamilyB, KindB, Input, OutcomeB0) )),
              _TimeLimit, fail)
    ->  OutcomeA = OutcomeA0, OutcomeB = OutcomeB0
    ;   OutcomeA = error(input_time_limit), OutcomeB = error(input_time_limit)
    ),
    tally(Input, OutcomeA, OutcomeB, MaxWitnesses, Accumulator0, Accumulator).

tally(Input, OutcomeA, OutcomeB, MaxWitnesses,
      acc(Ran0, Co0, Sep0, Ref0, Err0, Wits0, WitN0, Trunc0, First0, Stop),
      Accumulator) :-
    (   OutcomeA = result(_, _, _), OutcomeB = result(_, _, _)
    ->  Ran is Ran0 + 1, Ref = Ref0, Err = Err0,
        (   same_result(OutcomeA, OutcomeB)
        ->  Co is Co0 + 1, Sep = Sep0,
            Wits = Wits0, WitN = WitN0, Trunc = Trunc0,
            first_seen(First0, Input, OutcomeA, OutcomeB, coincide, First)
        ;   Sep is Sep0 + 1, Co = Co0,
            WitN is WitN0 + 1,
            (   ( MaxWitnesses =:= 0 ; WitN =< MaxWitnesses )
            ->  Wits = [Input|Wits0], Trunc = Trunc0
            ;   Wits = Wits0, Trunc = true
            ),
            first_separating(First0, Input, OutcomeA, OutcomeB, First)
        )
    ;   ( OutcomeA = refused(_) ; OutcomeB = refused(_) )
    ->  Ref is Ref0 + 1, Ran = Ran0, Co = Co0, Sep = Sep0, Err = Err0,
        Wits = Wits0, WitN = WitN0, Trunc = Trunc0,
        first_seen(First0, Input, OutcomeA, OutcomeB, refused, First)
    ;   Err is Err0 + 1, Ran = Ran0, Co = Co0, Sep = Sep0, Ref = Ref0,
        Wits = Wits0, WitN = WitN0, Trunc = Trunc0,
        first_seen(First0, Input, OutcomeA, OutcomeB, error, First)
    ),
    Accumulator = acc(Ran, Co, Sep, Ref, Err, Wits, WitN, Trunc, First, Stop).

% The reported outcome pair comes from a separating input when one exists,
% because that is the input a reader has to check; otherwise from whatever
% the grid met first.
first_separating(witness(separating, I, A, B), _, _, _,
                 witness(separating, I, A, B)) :- !.
first_separating(_, Input, OutcomeA, OutcomeB,
                 witness(separating, Input, OutcomeA, OutcomeB)).

first_seen(none, Input, OutcomeA, OutcomeB, Class,
           witness(Class, Input, OutcomeA, OutcomeB)) :- !.
first_seen(witness(separating, I, A, B), _, _, _, _,
           witness(separating, I, A, B)) :- !.
first_seen(Existing, _, _, _, _, Existing).

set_stopped(acc(Ran, Co, Sep, Ref, Err, Wits, WitN, Trunc, First, _), Reason,
            acc(Ran, Co, Sep, Ref, Err, Wits, WitN, Trunc, First, Reason)).

r1_evidence(acc(Ran, Co, Sep, Ref, Err, Wits, WitN, Trunc, First, Stopped),
            Started, Evidence) :-
    get_time(Now),
    ElapsedMs is round((Now - Started) * 1000),
    (   Co > 0 -> Kind = "coincidence_region" ; Kind = "separating_input" ),
    witness_strings(First, SourceString, TargetString),
    reverse(Wits, Witnesses),
    ( Trunc == true -> Truncated = true ; Truncated = false ),
    ( Ran > 0, Co =:= Ran -> FullAgreement = true ; FullAgreement = false ),
    atom_string(Stopped, StoppedString),
    Evidence = _{kind: Kind,
                 source_outcome: SourceString,
                 target_outcome: TargetString,
                 elapsed_ms: ElapsedMs,
                 ran: Ran,
                 coincide: Co,
                 separate: Sep,
                 refused: Ref,
                 errored: Err,
                 full_agreement: FullAgreement,
                 separating_input_count: WitN,
                 separating_inputs: Witnesses,
                 witnesses_truncated: Truncated,
                 walk: StoppedString}.

witness_strings(none, "no_input_ran", "no_input_ran") :- !.
witness_strings(witness(_, _, OutcomeA, OutcomeB), SourceString, TargetString) :-
    term_string(OutcomeA, SourceString),
    term_string(OutcomeB, TargetString).

%   A candidate is a pair that agreed on every input the grid ran. Everything
%   else the walk measured is a product — a separation map, a refusal
%   boundary — but it is not a candidate, and the ceremony is only asked
%   about candidates.
r1_verdict(acc(_, _, _, _, _, _, _, _, _, pair_budget),
           resource_error, "pair_budget_spent") :- !.
r1_verdict(acc(0, _, _, Ref, _, _, _, _, _, _), refused, "no_input_ran") :-
    Ref > 0, !.
r1_verdict(acc(0, _, _, _, _, _, _, _, _, _), no_candidate, "no_input_ran") :- !.
r1_verdict(acc(Ran, Co, _, _, _, _, _, _, _, _),
           certified_candidate, "behavioural_equivalence") :-
    Co =:= Ran, !.
r1_verdict(acc(_, Co, _, _, _, _, _, _, _, _),
           no_candidate, "partial_coincidence") :-
    Co > 0, !.
r1_verdict(_, no_candidate, "full_separation").


% -------------------------------------------------------------------------
% Item field readers
% -------------------------------------------------------------------------

item_machine(Item, Key, machine(Family, Kind)) :-
    get_dict(Key, Item, Sub),
    get_dict(family, Sub, FamilyString),
    get_dict(kind, Sub, KindString),
    atom_string(Family, FamilyString),
    atom_string(Kind, KindString).

item_number(Item, Key, Default, Value) :-
    (   get_dict(Key, Item, Given), number(Given)
    ->  Value = Given
    ;   Value = Default
    ).

outcome_atom_string(Outcome, String) :-
    (   atom(Outcome) -> atom_string(Outcome, String)
    ;   term_string(Outcome, String)
    ).


% ==========================================================================
% 6. R2 — refusal-genesis sweep as a DIRECTED REPLAY
%
% Amendment 2026-08-08-B, ruling 1. R1's rows count refusals jointly: a point
% where either machine declined added one to `refused`, with no record of
% WHICH declined. The asymmetry R2 needs was never retained, so it cannot be
% recovered from the collection and the grids are walked again. One walk over
% an unordered pair yields both directed censuses.
%
% For directed (Refuser -> Receiver):
%   released points = { I : Refuser refused I, Receiver computed I },
%   each carrying the receiver's validity at I.
%
% A release whose every point is `incorrect` or `accidentally_correct` is
% recorded and is NOT a candidate. Isolated-point coincidence is skating, and
% the validity carve already ruled that it keeps rust.
% ==========================================================================

%!  registered_deformation(+Family, +Kind) is semidet.
%
%   The receiver is a deformation the repo has registered as one: either the
%   deformation member of an action_automaton_pair/4 row, or the subject of
%   deformation_validity/8 rows (whose tags are objective_invalid and
%   context_sensitive_or_inefficient — neither is a clean bill).
registered_deformation(Family, Kind) :-
    action_automata_registry:action_automaton_pair(Family, _, Kind, _),
    !.
registered_deformation(Family, Kind) :-
    deformation_validity(Family, Kind, _, _, _, _, _, _),
    !.

%!  machine_canonical_actions(+Family, +Kind, -Actions) is det.
machine_canonical_actions(Family, Kind, Actions) :-
    (   setof(Canonical,
              L^A^B^C^action_maps(Family, Kind, L, Canonical, A, B, C),
              Actions0)
    ->  Actions = Actions0
    ;   Actions = []
    ).

%!  family_alphabet(+Family, -Actions) is det.
%
%   Every canonical action any machine of this family performs.
family_alphabet(Family, Actions) :-
    (   setof(Canonical,
              K^L^A^B^C^action_maps(Family, K, L, Canonical, A, B, C),
              Actions0)
    ->  Actions = Actions0
    ;   Actions = []
    ).

%   L3's alphabet half: the receiver performs canonical actions that also
%   belong to the REFUSING machine's family alphabet, and the two families
%   differ — the release crosses a family boundary through shared doing.
%   L3's other half (the receiver computes through a kernel that also serves
%   a machine of the refusing family) needs the kernel_dependency overlay R3
%   produces, and R3 has not run; the row records that half as unavailable
%   rather than as absent.
crossing_actions(RefuserFamily, ReceiverFamily, ReceiverKind, Shared) :-
    RefuserFamily \== ReceiverFamily,
    machine_canonical_actions(ReceiverFamily, ReceiverKind, Actions),
    family_alphabet(RefuserFamily, Alphabet),
    intersection(Actions, Alphabet, Shared),
    Shared \== [].


% -------------------------------------------------------------------------
% The walk
% -------------------------------------------------------------------------

%   Each grid point becomes pt(Input, OutcomeA, OutcomeB). Collecting the
%   points and reading them afterwards keeps the two directed censuses
%   honestly derived from ONE walk instead of two accumulators that could
%   drift apart.
r2_walk(Schema, FamilyA, KindA, FamilyB, KindB, Started, Budget,
        InputTimeout, Points, Stopped) :-
    findall(Input, grid_input(Schema, _, Input), Inputs),
    r2_points(Inputs, FamilyA, KindA, FamilyB, KindB, Started, Budget,
              InputTimeout, [], Reversed, completed, Stopped),
    reverse(Reversed, Points).

r2_points([], _, _, _, _, _, _, _, Points, Points, Stopped, Stopped).
r2_points([Input|Rest], FamilyA, KindA, FamilyB, KindB, Started, Budget,
          InputTimeout, Points0, Points, Stopped0, Stopped) :-
    get_time(Now),
    Elapsed is Now - Started,
    (   Elapsed >= Budget
    ->  Points = Points0, Stopped = pair_budget
    ;   (   catch(call_with_time_limit(
                      InputTimeout,
                      ( aa_run(FamilyA, KindA, Input, OutcomeA0),
                        aa_run(FamilyB, KindB, Input, OutcomeB0) )),
                  _TimeLimit, fail)
        ->  OutcomeA = OutcomeA0, OutcomeB = OutcomeB0
        ;   OutcomeA = error(input_time_limit),
            OutcomeB = error(input_time_limit)
        ),
        r2_points(Rest, FamilyA, KindA, FamilyB, KindB, Started, Budget,
                  InputTimeout, [pt(Input, OutcomeA, OutcomeB)|Points0],
                  Points, Stopped0, Stopped)
    ).

%   released(+Points, +Side, -Released, -OutRegionIncorrect)
%
%   Side is ab (A refuses, B receives) or ba. Released is a list of
%   released(Input, Validity, ReceiverOutcome) in grid order, which is
%   lexicographic by construction of the template expander. OutRegion is the
%   receiver's incorrect points OUTSIDE the released region — the evidence
%   that its viability is regional rather than general.
released_region([], _, [], []).
released_region([pt(Input, OutcomeA, OutcomeB)|Rest], Side,
                Released, OutRegion) :-
    ( Side == ab -> Refuser = OutcomeA, Receiver = OutcomeB
    ;               Refuser = OutcomeB, Receiver = OutcomeA ),
    released_region(Rest, Side, Released0, OutRegion0),
    (   Refuser = refused(_), Receiver = result(_, _, Validity)
    ->  Released = [released(Input, Validity, Receiver)|Released0],
        OutRegion = OutRegion0
    ;   Receiver = result(_, _, incorrect), \+ Refuser = refused(_)
    ->  Released = Released0,
        OutRegion = [Input|OutRegion0]
    ;   Released = Released0, OutRegion = OutRegion0
    ).

%   Witness retention: exact counts always; the witness LIST is capped, and
%   the cap keeps the lexicographically first and last released points so
%   every region stays reconstructible from its endpoints. The 200 MB lesson
%   from R1 is why the list is capped at all.
sample_witnesses(Released, Cap, Sampled, Truncated) :-
    length(Released, Total),
    (   ( Cap =:= 0 ; Total =< Cap )
    ->  Sampled = Released, Truncated = false
    ;   last(Released, Last),
        Released = [First|_],
        Interior is Cap - 2,
        (   Interior =< 0
        ->  Middle = []
        ;   Stride is max(1, Total // Interior),
            findall(Item,
                    ( nth0(Index, Released, Item),
                      Index > 0, Index < Total - 1,
                      0 =:= Index mod Stride ),
                    Middle0),
            length(Middle1, Interior),
            ( append(Middle1, _, Middle0) -> Middle = Middle1 ; Middle = Middle0 )
        ),
        append([[First], Middle, [Last]], Sampled),
        Truncated = true
    ).

validity_counts(Released, Counts) :-
    findall(V, member(released(_, V, _), Released), Validities),
    msort(Validities, Sorted),
    clumped(Sorted, Pairs),
    dict_pairs(Counts, _, Pairs).

%   The release is a candidate when the receiver does something the repo
%   would stand behind on at least one released point. Inefficiency is not
%   error (the PUSU ruling), so correct_but_inefficient counts;
%   accidentally_correct alone does not.
release_quality(Released, Quality) :-
    (   member(released(_, Validity, _), Released),
        memberchk(Validity, [correct, correct_but_inefficient,
                             contextually_correct])
    ->  Quality = licensed
    ;   Released == []
    ->  Quality = empty
    ;   Quality = unlicensed
    ).


% -------------------------------------------------------------------------
% The rows
% -------------------------------------------------------------------------

r2_rows(Item, Rows) :-
    (   get_dict(no_receiver, Item, true)
    ->  r2_no_receiver_row(Item, Row), Rows = [Row]
    ;   item_machine(Item, source, machine(FamilyA, KindA)),
        item_machine(Item, target, machine(FamilyB, KindB)),
        item_number(Item, pair_budget_s, 600, Budget),
        item_number(Item, input_timeout_s, 30, InputTimeout),
        item_number(Item, max_witnesses, 200, Cap),
        get_time(Started),
        (   \+ same_schema(machine(FamilyA, KindA), machine(FamilyB, KindB))
        ->  throw(error(domain_error(shared_schema_pair,
                                     FamilyA/KindA-FamilyB/KindB),
                        context(loop_driver:r2_rows/2,
                                'R2 receivers share the exact schema string')))
        ;   true
        ),
        machine_schema(machine(FamilyA, KindA), Schema),
        (   grid_plan(Schema, Bounds, _)
        ->  r2_walk(Schema, FamilyA, KindA, FamilyB, KindB, Started, Budget,
                    InputTimeout, Points, Stopped),
            grid_point_count(Schema, GridPoints),
            term_string(Bounds, BoundsString),
            r2_directed_row(ab, machine(FamilyA, KindA), machine(FamilyB, KindB),
                            Points, Stopped, Schema, BoundsString, GridPoints,
                            Cap, Started, RowAB),
            r2_directed_row(ba, machine(FamilyB, KindB), machine(FamilyA, KindA),
                            Points, Stopped, Schema, BoundsString, GridPoints,
                            Cap, Started, RowBA),
            Rows = [RowAB, RowBA]
        ;   r2_uninstantiated_row(machine(FamilyA, KindA), machine(FamilyB, KindB),
                                  Schema, RowAB),
            r2_uninstantiated_row(machine(FamilyB, KindB), machine(FamilyA, KindA),
                                  Schema, RowBA),
            Rows = [RowAB, RowBA]
        )
    ).

r2_directed_row(Side, machine(RefuserF, RefuserK), machine(ReceiverF, ReceiverK),
                Points, Stopped, Schema, BoundsString, GridPoints, Cap,
                Started, Row) :-
    released_region(Points, Side, Released, OutRegion),
    length(Released, ReleasedCount),
    length(OutRegion, OutRegionCount),
    length(Points, Walked),
    sample_witnesses(Released, Cap, Sampled, Truncated),
    validity_counts(Released, ValidityCounts),
    release_quality(Released, Quality),
    r2_lens(machine(RefuserF, RefuserK), machine(ReceiverF, ReceiverK),
            Released, OutRegionCount, Quality, Lens, LensFlags, Crossing),
    r2_verdict(Quality, Stopped, Outcome, CandidateType),
    witness_dicts(Sampled, WitnessDicts),
    ( OutRegion = [OutWitness|_] -> OutWitnessField = OutWitness
    ; OutWitnessField = null ),
    first_release_strings(Released, RefusalString, ReceiverString),
    receiver_license(ReceiverF, ReceiverK, License),
    get_time(Now),
    ElapsedMs is round((Now - Started) * 1000),
    atom_string(Stopped, StoppedString),
    atom_string(Quality, QualityString),
    atom_string(Lens, LensString),
    Row = _{run: "r2",
            candidate_type: CandidateType,
            source: _{family: RefuserF, kind: RefuserK},
            target: _{family: ReceiverF, kind: ReceiverK},
            input: _{schema: Schema, bounds: BoundsString,
                     points: GridPoints},
            evidence: _{kind: "failed_derivation",
                        source_outcome: RefusalString,
                        target_outcome: ReceiverString,
                        elapsed_ms: ElapsedMs,
                        walked_points: Walked,
                        released_count: ReleasedCount,
                        released_witnesses: WitnessDicts,
                        witnesses_truncated: Truncated,
                        released_validity_counts: ValidityCounts,
                        release_quality: QualityString,
                        receiver_incorrect_out_of_region: OutRegionCount,
                        out_of_region_incorrect_witness: OutWitnessField,
                        license: License,
                        lens_flags: LensFlags,
                        crossing_actions: Crossing,
                        walk: StoppedString},
            outcome: Outcome,
            candidate_lens: LensString,
            consumer: "the G_walk crisis_release candidate queue (admission \c
                       ceremony, L2 and L3 first) + the rung-map seam report \c
                       + the stage-2 gap report"}.

%   L1/L2 are mechanical here. L3's alphabet half is mechanical too and is
%   computed; its kernel half waits on R3 and says so rather than reading as
%   a negative.
r2_lens(machine(RefuserF, _), machine(ReceiverF, ReceiverK), Released,
        OutRegionCount, Quality, Lens, Flags, Crossing) :-
    ( registered_deformation(ReceiverF, ReceiverK) -> Deformation = true
    ; Deformation = false ),
    findall(V, ( member(released(_, V, _), Released),
                 memberchk(V, [correct, contextually_correct]) ), Strong),
    length(Strong, StrongCount),
    findall(V, ( member(released(_, V, _), Released),
                 memberchk(V, [correct, correct_but_inefficient]) ), Clean),
    length(Clean, CleanCount),
    (   Quality == licensed, Deformation == true,
        StrongCount >= 10, OutRegionCount >= 1
    ->  L2 = true ; L2 = false ),
    (   Quality == licensed, Deformation == false, CleanCount >= 1
    ->  L1 = true ; L1 = false ),
    (   Quality == licensed,
        crossing_actions(RefuserF, ReceiverF, ReceiverK, Shared)
    ->  L3 = true, Crossing = Shared
    ;   L3 = false, Crossing = [] ),
    % L2 is the hunted class, so it names the row when it fires; L3 is
    % orthogonal and both stay readable in lens_flags.
    (   L2 == true -> Lens = l2
    ;   L3 == true -> Lens = l3
    ;   L1 == true -> Lens = l1
    ;   Lens = unlensed ),
    Flags = _{l1: L1, l2: L2, l3: L3,
              receiver_is_registered_deformation: Deformation,
              strong_released_points: StrongCount,
              clean_released_points: CleanCount,
              l3_kernel_half: "unavailable until R3 produces the \c
                               kernel_dependency overlay"}.

r2_verdict(_, pair_budget, "resource_error", "pair_budget_spent") :- !.
r2_verdict(licensed, _, "certified_candidate", "crisis_release") :- !.
r2_verdict(unlicensed, _, "no_candidate", "release_without_licence") :- !.
r2_verdict(empty, _, "no_candidate", "no_release").

witness_dicts(Sampled, Dicts) :-
    findall(_{input: Input, validity: ValidityString},
            ( member(released(Input, Validity, _), Sampled),
              atom_string(Validity, ValidityString) ),
            Dicts).

first_release_strings([], "no_release", "no_release").
first_release_strings([released(_, _, Receiver)|_], RefusalString,
                      ReceiverString) :-
    RefusalString = "refused(domain)",
    term_string(Receiver, ReceiverString).

%   The license citation the amendment asks for: the receiver's own contract
%   row, which is what says this input was admissible for it.
receiver_license(Family, Kind, License) :-
    (   automaton_input_contract(Family, Kind, Schema, Example, Verified)
    ->  term_string(Verified, VerifiedString),
        License = _{schema: Schema, verified_example: Example,
                    status: VerifiedString}
    ;   License = _{schema: null, verified_example: null,
                    status: "no contract row"}
    ).

r2_no_receiver_row(Item, Row) :-
    item_machine(Item, source, machine(Family, Kind)),
    machine_schema(machine(Family, Kind), Schema),
    Row = _{run: "r2",
            candidate_type: "no_receiver",
            source: _{family: Family, kind: Kind},
            target: _{family: null, kind: null},
            input: _{schema: Schema, bounds: null, points: 0},
            evidence: _{kind: "failed_derivation",
                        source_outcome: "no receiver shares this schema string",
                        target_outcome: "none",
                        elapsed_ms: 0,
                        released_count: 0,
                        released_witnesses: [],
                        witnesses_truncated: false},
            outcome: "uninstantiated",
            candidate_lens: "unlensed",
            consumer: "the stage-2 gap report (schemas with a single machine \c
                       name a missing receiver, not a missing run)"}.

r2_uninstantiated_row(machine(RefuserF, RefuserK), machine(ReceiverF, ReceiverK),
                      Schema, Row) :-
    Row = _{run: "r2",
            candidate_type: "uninstantiated_schema",
            source: _{family: RefuserF, kind: RefuserK},
            target: _{family: ReceiverF, kind: ReceiverK},
            input: _{schema: Schema, bounds: null, points: 0},
            evidence: _{kind: "failed_derivation",
                        source_outcome: "no_grid_plan",
                        target_outcome: "no_grid_plan",
                        elapsed_ms: 0,
                        released_count: 0,
                        released_witnesses: [],
                        witnesses_truncated: false},
            outcome: "uninstantiated",
            candidate_lens: "unlensed",
            consumer: "the stage-2 gap report (a schema with no authored grid \c
                       is a contract gap, not a compute gap)"}.
