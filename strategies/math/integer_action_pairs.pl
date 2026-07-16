/** <module> Integer/signed-number action/deformation pairs
 *
 * Signed-number actions coordinate signs, magnitudes, locations, and sets of
 * values. Addition preserves the sign relation; ordering locates values on a
 * two-sided number line; inequalities preserve every satisfying value rather
 * than reducing a relation to its boundary point.
 */

:- module(integer_action_pairs,
          [ run_integer_action/5,
            integer_action_cluster/2,
            integer_action_vocabulary/2,
            productive_integer_deformation/3,
            integer_action_misconception_hook/3
          ]).

:- use_module(render(signed_number_line_scene),
              [signed_number_line_render_json/2]).


%!  run_integer_action(+Kind, +A, +B, -Outcome, -Trace) is semidet.
%
%   Execute a productive or deformed signed-integer addition. A and B are
%   ordinary Prolog integers; either may be negative. The deformation only
%   diverges from the productive automaton when at least one addend is
%   negative.
run_integer_action(signed_addition_with_sign_relation, A, B, Outcome, Trace) :-
    signed_components(A, B, Components),
    Components = signed_components(SignA, SignB, MagnitudeA, MagnitudeB,
                                   SignRelation, ResultSign, ResultMagnitude, Result),
    Outcome = action_outcome(
                  signed_addition_with_sign_relation,
                  [ classification(productive),
                    cluster(signed_number_combination),
                    automaton_state(signed_addition_sign_coordination),
                    vocabulary([signed_addend, sign, magnitude, sign_relation,
                                same_sign_combination, opposite_sign_cancellation,
                                signed_sum]),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    components(Components)
                  ]),
    Trace = [ identify_signs(sign_a(SignA), sign_b(SignB)),
              identify_magnitudes(magnitude_a(MagnitudeA), magnitude_b(MagnitudeB)),
              determine_sign_relation(SignRelation),
              combine_magnitudes_by_sign_relation(SignRelation,
                                                  MagnitudeA, MagnitudeB,
                                                  ResultMagnitude),
              assign_result_sign(ResultSign, ResultMagnitude, Result),
              preserve_sign_relation(Result)
            ].
run_integer_action(drop_sign_use_magnitude_sum, A, B, Outcome, Trace) :-
    signed_components(A, B, Components),
    Components = signed_components(SignA, SignB, MagnitudeA, MagnitudeB,
                                   _SignRelation, _ResultSign, _ResultMagnitude, Expected),
    (   SignA == negative
    ;   SignB == negative
    ),
    MagnitudeSum is MagnitudeA + MagnitudeB,
    Result = MagnitudeSum,
    Outcome = action_outcome(
                  drop_sign_use_magnitude_sum,
                  [ classification(deformation),
                    cluster(signed_number_combination),
                    automaton_state(signed_addition_sign_coordination),
                    vocabulary([signed_addend, sign, magnitude,
                                magnitude_only_combination, sign_loss, signed_sum]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    components(Components),
                    deformation_of(signed_addition_with_sign_relation),
                    misconception_family(magnitude_only_combination)
                  ]),
    Trace = [ identify_signs(sign_a(SignA), sign_b(SignB)),
              identify_magnitudes(magnitude_a(MagnitudeA), magnitude_b(MagnitudeB)),
              drop_signs(sign_a(SignA), sign_b(SignB)),
              sum_magnitudes_only(MagnitudeA, MagnitudeB, MagnitudeSum),
              name_magnitude_sum_as_answer(Result),
              lose_sign_relation(expected(Expected), produced(Result))
            ].
run_integer_action(signed_number_location_and_order, Values, number_line,
                   Outcome, Trace) :-
    signed_value_list(Values),
    msort(Values, Ordered),
    signed_number_line_render_json(signed_locations(Values), Scene),
    successful_scene(Scene),
    Outcome = action_outcome(
                  signed_number_location_and_order,
                  [ classification(productive),
                    cluster(signed_number_location_order),
                    automaton_state(locate_relative_to_zero_then_read_left_to_right),
                    vocabulary([positive_number, negative_number, zero, sign,
                                magnitude, opposite, number_line, location,
                                numerical_order]),
                    input(Values), result(ordered_values(Ordered)),
                    expected(ordered_values(Ordered)), representation(Scene),
                    invariant(left_position_is_less_value), validity(correct)
                  ]),
    Trace = [ establish_zero_as_origin,
              locate_each_signed_value(Values),
              preserve_direction_from_zero,
              read_locations_left_to_right(Ordered)
            ].
run_integer_action(order_by_magnitude_ignore_sign, Values, number_line,
                   Outcome, Trace) :-
    signed_value_list(Values),
    msort(Values, Expected),
    magnitude_order(Values, MagnitudeOrder),
    MagnitudeOrder \== Expected,
    signed_number_line_render_json(signed_locations(Values), Scene),
    successful_scene(Scene),
    Outcome = action_outcome(
                  order_by_magnitude_ignore_sign,
                  [ classification(deformation),
                    cluster(signed_number_location_order),
                    automaton_state(order_distances_from_zero_without_direction),
                    vocabulary([sign, magnitude, absolute_value, number_line,
                                numerical_order, sign_loss]),
                    input(Values), result(ordered_values(MagnitudeOrder)),
                    expected(ordered_values(Expected)), representation(Scene),
                    deformation_of(signed_number_location_and_order),
                    misconception_family(magnitude_only_signed_order),
                    violated_invariant(left_position_is_less_value),
                    validity(incorrect)
                  ]),
    Trace = [ establish_zero_as_origin,
              replace_signed_locations_with_distances,
              order_magnitudes_only(MagnitudeOrder),
              lose_directional_order(Expected)
            ].
run_integer_action(inequality_solution_set_representation,
                   inequality(Variable, Relation, Bound), number_line,
                   Outcome, Trace) :-
    atom(Variable),
    inequality_relation(Relation),
    integer(Bound),
    inequality_solution_description(Relation, Bound, Solution),
    signed_number_line_render_json(inequality_solution(Relation, Bound), Scene),
    successful_scene(Scene),
    Outcome = action_outcome(
                  inequality_solution_set_representation,
                  [ classification(productive),
                    cluster(signed_inequality_solution_set),
                    automaton_state(mark_boundary_then_extend_over_all_solutions),
                    vocabulary([inequality, variable, boundary, less_than,
                                greater_than, open_endpoint, closed_endpoint,
                                solution_set, number_line, ray]),
                    input(inequality(Variable, Relation, Bound)),
                    result(Solution), expected(Solution), representation(Scene),
                    invariant(every_represented_value_satisfies_relation),
                    validity(correct)
                  ]),
    Trace = [ identify_boundary(Bound),
              interpret_relation_direction(Relation),
              choose_endpoint_inclusion(Relation),
              extend_ray_over_all_solutions(Solution)
            ].
run_integer_action(inequality_as_boundary_point,
                   inequality(Variable, Relation, Bound), number_line,
                   Outcome, Trace) :-
    atom(Variable),
    inequality_relation(Relation),
    integer(Bound),
    inequality_solution_description(Relation, Bound, Expected),
    signed_number_line_render_json(inequality_solution(Relation, Bound), Scene),
    successful_scene(Scene),
    Outcome = action_outcome(
                  inequality_as_boundary_point,
                  [ classification(deformation),
                    cluster(signed_inequality_solution_set),
                    automaton_state(mark_boundary_without_extending_solution_ray),
                    vocabulary([inequality, variable, boundary, single_value,
                                solution_set, number_line]),
                    input(inequality(Variable, Relation, Bound)),
                    result(single_value(Bound)), expected(Expected),
                    representation(Scene),
                    deformation_of(inequality_solution_set_representation),
                    misconception_family(inequality_reduced_to_boundary_point),
                    violated_invariant(every_satisfying_value_is_represented),
                    validity(incorrect)
                  ]),
    Trace = [ identify_boundary(Bound), ignore_relation_direction(Relation),
              omit_solution_ray, report_boundary_as_only_solution(Bound) ].


%!  integer_action_cluster(+Kind, -Cluster) is det.
integer_action_cluster(signed_addition_with_sign_relation, signed_number_combination).
integer_action_cluster(drop_sign_use_magnitude_sum, signed_number_combination).
integer_action_cluster(signed_number_location_and_order,
                       signed_number_location_order).
integer_action_cluster(order_by_magnitude_ignore_sign,
                       signed_number_location_order).
integer_action_cluster(inequality_solution_set_representation,
                       signed_inequality_solution_set).
integer_action_cluster(inequality_as_boundary_point,
                       signed_inequality_solution_set).


%!  integer_action_vocabulary(+Kind, -Vocabulary) is det.
integer_action_vocabulary(signed_addition_with_sign_relation,
                          [signed_addend, sign, magnitude, sign_relation,
                           same_sign_combination, opposite_sign_cancellation,
                           signed_sum]).
integer_action_vocabulary(drop_sign_use_magnitude_sum,
                          [signed_addend, sign, magnitude,
                           magnitude_only_combination, sign_loss, signed_sum]).
integer_action_vocabulary(signed_number_location_and_order,
                          [positive_number, negative_number, zero, sign,
                           magnitude, opposite, number_line, location,
                           numerical_order]).
integer_action_vocabulary(order_by_magnitude_ignore_sign,
                          [sign, magnitude, absolute_value, number_line,
                           numerical_order, sign_loss]).
integer_action_vocabulary(inequality_solution_set_representation,
                          [inequality, variable, boundary, less_than,
                           greater_than, open_endpoint, closed_endpoint,
                           solution_set, number_line, ray]).
integer_action_vocabulary(inequality_as_boundary_point,
                          [inequality, variable, boundary, single_value,
                           solution_set, number_line]).


%!  productive_integer_deformation(+ProductiveKind, +DeformationKind, -Family) is det.
productive_integer_deformation(signed_addition_with_sign_relation,
                               drop_sign_use_magnitude_sum,
                               magnitude_only_combination).
productive_integer_deformation(signed_number_location_and_order,
                               order_by_magnitude_ignore_sign,
                               magnitude_only_signed_order).
productive_integer_deformation(inequality_solution_set_representation,
                               inequality_as_boundary_point,
                               inequality_reduced_to_boundary_point).


%!  integer_action_misconception_hook(+Outcome, -Family, -Hook) is semidet.
integer_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
    member(classification(deformation), Fields),
    member(misconception_family(Family), Fields),
    member(deformation_of(ProductiveKind), Fields),
    member(vocabulary(Vocabulary), Fields),
    Hook = action_misconception_hook(
               [ deformation(Kind),
                 deformation_of(ProductiveKind),
                 family(Family),
                 vocabulary(Vocabulary),
                 repair(recover_productive_action(ProductiveKind)),
                 evidence(Fields)
               ]).
integer_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
    member(classification(productive), Fields),
    productive_integer_deformation(Kind, DeformationKind, Family),
    member(vocabulary(Vocabulary), Fields),
    Hook = action_misconception_hook(
               [ productive_action(Kind),
                 nearby_deformation(DeformationKind),
                 family(Family),
                 vocabulary(Vocabulary),
                 monitoring_focus(preserve_sign_relation(Kind)),
                 evidence(Fields)
               ]).


signed_components(A, B,
                  signed_components(SignA, SignB, MagnitudeA, MagnitudeB,
                                    SignRelation, ResultSign, ResultMagnitude, Result)) :-
    integer(A),
    integer(B),
    sign_of(A, SignA),
    sign_of(B, SignB),
    MagnitudeA is abs(A),
    MagnitudeB is abs(B),
    sign_relation(SignA, SignB, SignRelation),
    combine_signed(SignRelation, SignA, SignB, MagnitudeA, MagnitudeB,
                   ResultSign, ResultMagnitude),
    Result is A + B,
    result_consistency(ResultSign, ResultMagnitude, Result).


sign_of(N, positive) :- N > 0, !.
sign_of(N, negative) :- N < 0, !.
sign_of(0, zero).


sign_relation(positive, positive, same_sign_positive) :- !.
sign_relation(negative, negative, same_sign_negative) :- !.
sign_relation(zero, _, zero_addend) :- !.
sign_relation(_, zero, zero_addend) :- !.
sign_relation(_, _, opposite_signs).


combine_signed(same_sign_positive, _, _, MagA, MagB, positive, Magnitude) :-
    Magnitude is MagA + MagB.
combine_signed(same_sign_negative, _, _, MagA, MagB, negative, Magnitude) :-
    Magnitude is MagA + MagB.
combine_signed(zero_addend, SignA, SignB, MagA, MagB, ResultSign, Magnitude) :-
    (   MagA >= MagB
    ->  ResultSign = SignA,
        Magnitude = MagA
    ;   ResultSign = SignB,
        Magnitude = MagB
    ).
combine_signed(opposite_signs, SignA, SignB, MagA, MagB, ResultSign, Magnitude) :-
    (   MagA > MagB
    ->  ResultSign = SignA,
        Magnitude is MagA - MagB
    ;   MagA < MagB
    ->  ResultSign = SignB,
        Magnitude is MagB - MagA
    ;   ResultSign = zero,
        Magnitude = 0
    ).


result_consistency(zero, 0, 0) :- !.
result_consistency(positive, Magnitude, Result) :-
    Result =:= Magnitude,
    Result > 0,
    !.
result_consistency(negative, Magnitude, Result) :-
    Result =:= -Magnitude,
    Result < 0.

signed_value_list([Value|Values]) :-
    integer(Value),
    maplist(integer, Values).

magnitude_order(Values, Ordered) :-
    findall(Magnitude-Value,
            ( member(Value, Values), Magnitude is abs(Value) ),
            Pairs),
    keysort(Pairs, SortedPairs),
    findall(Value, member(_-Value, SortedPairs), Ordered).

inequality_relation(lt).
inequality_relation(lte).
inequality_relation(gt).
inequality_relation(gte).

inequality_solution_description(lt, Bound,
                                solution_set(ray(left, open, Bound))).
inequality_solution_description(lte, Bound,
                                solution_set(ray(left, closed, Bound))).
inequality_solution_description(gt, Bound,
                                solution_set(ray(right, open, Bound))).
inequality_solution_description(gte, Bound,
                                solution_set(ray(right, closed, Bound))).

successful_scene(Scene) :-
    is_dict(Scene),
    \+ get_dict(error, Scene, _),
    get_dict(frames, Scene, [_|_]).
