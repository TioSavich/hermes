:- encoding(utf8).
/** <module> Grade 8 draft: reading a dimension back out of a volume, and the circle underneath
 *
 * WHAT THIS IS. A draft automaton for the inverse of the published pilot
 * `g8_round_solid_volume`. That pilot computes a volume from a radius and a
 * height. Grade 8 unit 5 spends three lessons going the other way, and the
 * round-two corrections recovered them: correction 2 gives a cylinder of
 * radius 5 and volume 50π and asks for the height; correction 6 gives a cone
 * of height 3 and volume 64π and asks for the radius; correction 9 gives a
 * graphed cone with height 10 and volume 2355 and asks for the radius with
 * 3.14 standing in for π. Correction 3 asks only for the ratio: the cylinder
 * holds 90 cm³, what does the cone hold.
 *
 * AND THE CIRCLE. Correction 49 asks for the area of a circle of radius 4 and
 * then for the radius of a circle of area 49π, and correction 4 asks for the
 * area of a cone's base. Nothing published computes a circle's area on its
 * own: the round-solid pilot uses one inside its volume and never returns it.
 * Two doings here supply it, because the corrected tasks ask for it by name.
 *
 * PI STAYS SYMBOLIC UNTIL A TASK SAYS OTHERWISE. A volume given as a multiple
 * of π keeps π as a symbol and cancels it against the formula's own π, so
 * correction 2's height is exactly 2 rather than a decimal that rounds to it.
 * Where the task prints "use 3.14 as an approximation" the approximation
 * enters as an exact rational 157/50, and the trace names it as the task's
 * choice rather than the automaton's.
 *
 * SCALING. `volume_under_scaled_dimensions` is the productive counterpart of
 * the published pilot's deformation `scale_volume_linearly_with_radius`:
 * halving a cylinder's height halves the volume, halving its radius quarters
 * it, and halving both the height and the radius, as correction 12 asks,
 * leaves an eighth. The deformation is not repeated here; it already exists
 * one module over.
 *
 * QUARANTINE. Nothing imports this module; it is a draft under
 * `.superpowers/sdd/g8-round2/`. Check:
 * `check_g8_circle_and_solid_dimensions/0`.
 */

:- module(g8_circle_and_solid_dimensions,
          [ run_g8_solid_dimension/4,
            g8_solid_dimension_from_json/2,
            g8_solid_dimension_states/1,
            g8_solid_dimension_state_label/4,
            g8_solid_dimension_summary/1,
            g8_solid_dimension_receipt/5,
            check_g8_circle_and_solid_dimensions/0
          ]).

:- use_module(strategies('abstraction/g8_quantity_input'),
              [ g8_quantity/2, g8_rational_text/2, g8_exact_root_text/2 ]).

% ==========================================================================
% 1. INPUT CONTRACT
%
%   {"kind":"solid_dimension","solid":"cylinder","unknown":"height",
%    "volume":{"pi_multiple":50},"radius":5,"unit":"unit"}
%   {"kind":"solid_dimension","solid":"cone","unknown":"radius",
%    "volume":{"value":2355,"pi_as":3.14},"height":10,"unit":"unit"}
%   {"kind":"circle_measure","radius":4,"unit":"unit"}
%   {"kind":"circle_measure","area":{"pi_multiple":49},"unit":"unit"}
%   {"kind":"solid_volume_ratio","given":"cylinder","wanted":"cone",
%    "volume":{"value":90},"unit":"cm^3"}
%   {"kind":"scaled_solid","solid":"cylinder",
%    "factors":{"radius":{"n":1,"d":2},"height":{"n":1,"d":2}}}
% ==========================================================================

g8_solid_dimension_input_contract(
    '{\"kind\":\"solid_dimension\",\"solid\":\"string\",\"unknown\":\"string\",\"volume\":{\"pi_multiple\":\"number\",\"value\":\"number\",\"pi_as\":\"number\"},\"radius\":\"number\",\"height\":\"number\",\"unit\":\"string\"}',
    '{\"kind\":\"solid_dimension\",\"solid\":\"cylinder\",\"unknown\":\"height\",\"volume\":{\"pi_multiple\":50},\"radius\":5,\"unit\":\"unit\"}').

g8_solid_dimension_from_json(Dict, unknown_dimension(Solid, Unknown, Volume,
                                                     Known, Unit)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "solid_dimension"), !,
    get_dict(solid, Dict, SolidText),
    memberchk(SolidText, ["cylinder", "cone"]),
    atom_string(Solid, SolidText),
    get_dict(unknown, Dict, UnknownText),
    memberchk(UnknownText, ["height", "radius"]),
    atom_string(Unknown, UnknownText),
    get_dict(volume, Dict, V), volume_of(V, Volume),
    (   Unknown == height
    ->  get_dict(radius, Dict, K0)
    ;   get_dict(height, Dict, K0)
    ),
    g8_quantity(K0, Known), Known > 0,
    unit_of(Dict, Unit).
g8_solid_dimension_from_json(Dict, circle_from_radius(Radius, Unit)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "circle_measure"),
    get_dict(radius, Dict, R0), !,
    g8_quantity(R0, Radius), Radius > 0,
    unit_of(Dict, Unit).
g8_solid_dimension_from_json(Dict, circle_from_area(Area, Unit)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "circle_measure"),
    get_dict(area, Dict, A), !,
    volume_of(A, Area),
    unit_of(Dict, Unit).
g8_solid_dimension_from_json(Dict, volume_ratio(Given, Wanted, Volume, Unit)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "solid_volume_ratio"), !,
    get_dict(given, Dict, GivenText), get_dict(wanted, Dict, WantedText),
    memberchk(GivenText, ["cylinder", "cone"]),
    memberchk(WantedText, ["cylinder", "cone"]),
    GivenText \== WantedText,
    atom_string(Given, GivenText), atom_string(Wanted, WantedText),
    get_dict(volume, Dict, V), volume_of(V, Volume),
    unit_of(Dict, Unit).
g8_solid_dimension_from_json(Dict, scaled(Solid, RadiusFactor, HeightFactor)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "scaled_solid"),
    get_dict(solid, Dict, SolidText),
    memberchk(SolidText, ["cylinder", "cone"]),
    atom_string(Solid, SolidText),
    get_dict(factors, Dict, Factors),
    ( get_dict(radius, Factors, R0), g8_quantity(R0, RadiusFactor)
    -> true ; RadiusFactor = 1 ),
    ( get_dict(height, Factors, H0), g8_quantity(H0, HeightFactor)
    -> true ; HeightFactor = 1 ),
    RadiusFactor > 0, HeightFactor > 0.

%!  volume_of(+Dict, -Volume) is semidet.
%
%   symbolic_pi(Q) means the volume is Q multiples of π and π is never
%   evaluated. approximated(Q, Pi) means the task printed a value and named
%   its own stand-in for π.
volume_of(Dict, symbolic_pi(Q)) :-
    get_dict(pi_multiple, Dict, Q0), !, g8_quantity(Q0, Q), Q > 0.
volume_of(Dict, approximated(Q, Pi)) :-
    get_dict(value, Dict, Q0), g8_quantity(Q0, Q), Q > 0,
    ( get_dict(pi_as, Dict, P0) -> g8_quantity(P0, Pi) ; Pi = none ).

unit_of(Dict, Unit) :-
    ( get_dict(unit, Dict, U), string(U) -> Unit = U ; Unit = "unit" ).

% ==========================================================================
% 2. STATES
% ==========================================================================

g8_solid_dimension_states(
    [ q_read_the_solid_and_its_volume,
      q_write_the_volume_formula_with_the_unknown_in_it,
      q_divide_by_everything_except_the_unknown,
      q_undo_the_square_on_the_radius,
      q_report_the_dimension,
      q_refuse_an_inexact_radius,
      q_multiply_the_radius_by_itself_and_by_pi,
      q_report_the_circle_area,
      q_take_a_third_of_the_cylinder,
      q_take_three_times_the_cone,
      q_multiply_the_factors_as_the_formula_uses_them ]).

% g8_solid_dimension_state_label(State, Tradition, Label, Citation).
g8_solid_dimension_state_label(
    q_write_the_volume_formula_with_the_unknown_in_it,
    illustrative_mathematics,
    "the volume formula written as an equation with one unknown",
    "IM Grade 8 Unit 5 Lesson 14, Finding Cylinder Dimensions").
g8_solid_dimension_state_label(q_undo_the_square_on_the_radius,
    illustrative_mathematics,
    "the radius squared, then the square undone",
    "IM Grade 8 Unit 5 Lesson 16, Finding Cone Dimensions").
g8_solid_dimension_state_label(q_undo_the_square_on_the_radius, ccss,
    "use square root symbols to represent solutions to equations of the form x squared equals p",
    "CCSS 8.EE.A.2, via IM Grade 8 Unit 5 Lesson 16").
g8_solid_dimension_state_label(q_multiply_the_radius_by_itself_and_by_pi,
    illustrative_mathematics,
    "the area of a circle from its radius",
    "IM Grade 7 Unit 3 Lesson 8, carried into Grade 8 Unit 5 Lesson 13").
g8_solid_dimension_state_label(q_take_a_third_of_the_cylinder,
    illustrative_mathematics,
    "a cone holds a third of the cylinder on the same base and height",
    "IM Grade 8 Unit 5 Lesson 15, From Cylinders to Cones").
g8_solid_dimension_state_label(q_multiply_the_factors_as_the_formula_uses_them,
    illustrative_mathematics,
    "a length scaled once scales the volume as many times as the formula uses it",
    "IM Grade 8 Unit 5 Lesson 18, Scaling One Dimension").
g8_solid_dimension_state_label(q_refuse_an_inexact_radius, provisional,
    "the squared radius is not a square of a rational",
    "provisional; no community label sourced for this refusal").

% ==========================================================================
% 3. TRANSITIONS
% ==========================================================================

g8_solid_dimension_transition(dimension_from_volume,
    q_read_the_solid_and_its_volume,
    write_the_volume_formula_with_the_unknown_in_it,
    q_write_the_volume_formula_with_the_unknown_in_it).
g8_solid_dimension_transition(dimension_from_volume,
    q_write_the_volume_formula_with_the_unknown_in_it,
    divide_by_everything_except_the_unknown,
    q_divide_by_everything_except_the_unknown).
g8_solid_dimension_transition(dimension_from_volume,
    q_divide_by_everything_except_the_unknown, report_the_dimension,
    q_report_the_dimension).
g8_solid_dimension_transition(dimension_from_volume,
    q_divide_by_everything_except_the_unknown, undo_the_square_on_the_radius,
    q_undo_the_square_on_the_radius).
g8_solid_dimension_transition(dimension_from_volume,
    q_undo_the_square_on_the_radius, report_the_dimension,
    q_report_the_dimension).
g8_solid_dimension_transition(dimension_from_volume,
    q_undo_the_square_on_the_radius, refuse_an_inexact_radius,
    q_refuse_an_inexact_radius).
g8_solid_dimension_transition(circle_area_from_radius,
    q_read_the_solid_and_its_volume, multiply_the_radius_by_itself_and_by_pi,
    q_multiply_the_radius_by_itself_and_by_pi).
g8_solid_dimension_transition(circle_area_from_radius,
    q_multiply_the_radius_by_itself_and_by_pi, report_the_circle_area,
    q_report_the_circle_area).
g8_solid_dimension_transition(radius_from_circle_area,
    q_read_the_solid_and_its_volume, undo_the_square_on_the_radius,
    q_undo_the_square_on_the_radius).
g8_solid_dimension_transition(volume_between_cone_and_cylinder,
    q_read_the_solid_and_its_volume, take_a_third_of_the_cylinder,
    q_take_a_third_of_the_cylinder).
g8_solid_dimension_transition(volume_between_cone_and_cylinder,
    q_read_the_solid_and_its_volume, take_three_times_the_cone,
    q_take_three_times_the_cone).
g8_solid_dimension_transition(volume_under_scaled_dimensions,
    q_read_the_solid_and_its_volume,
    multiply_the_factors_as_the_formula_uses_them,
    q_multiply_the_factors_as_the_formula_uses_them).

% ==========================================================================
% 4. THE RUN
% ==========================================================================

run_g8_solid_dimension(dimension_from_volume,
                       unknown_dimension(Solid, height, Volume, Radius, Unit),
                       Outcome, Trace) :-
    solid_factor(Solid, Factor),
    volume_over_pi(Volume, OverPi),
    Height is OverPi rdiv (Factor * Radius * Radius),
    % substitution receipt: the formula rebuilt from the answer
    Rebuilt is Factor * Radius * Radius * Height,
    ( Rebuilt =:= OverPi -> Validity = correct ; Validity = unvindicated ),
    g8_rational_text(Height, Text),
    Outcome = action_outcome(
        dimension_from_volume,
        [ classification(productive),
          cluster(g8_round_solid_volume),
          automaton_state(q_report_the_dimension),
          vocabulary([volume, cylinder, cone, radius, height, formula, pi]),
          input(unknown_dimension(Solid, height, Volume, Radius, Unit)),
          result(height(Text, Unit)),
          expected(height(Text, Unit)),
          substitution(Rebuilt =:= OverPi),
          invariant(the_formula_rebuilds_the_volume_from_the_answer),
          validity(Validity) ]),
    Trace = [ write_the_volume_formula_with_the_unknown_in_it(Solid),
              divide_by_everything_except_the_unknown(Radius),
              report_the_dimension(Text) ].
run_g8_solid_dimension(dimension_from_volume,
                       unknown_dimension(Solid, radius, Volume, Height, Unit),
                       Outcome, Trace) :-
    solid_factor(Solid, Factor),
    volume_over_pi(Volume, OverPi),
    Squared is OverPi rdiv (Factor * Height),
    g8_exact_root_text(Squared, Text),
    (   exact_rational_root(Squared, Root)
    ->  Rebuilt is Factor * Root * Root * Height,
        ( Rebuilt =:= OverPi -> Validity = correct ; Validity = unvindicated ),
        State = q_report_the_dimension,
        Answer = radius(Text, Unit),
        Step = report_the_dimension(Text)
    ;   Validity = refused,
        State = q_refuse_an_inexact_radius,
        Answer = refused(the_squared_radius_is_not_a_square),
        Step = refuse_an_inexact_radius(Text)
    ),
    g8_rational_text(Squared, SquaredText),
    Outcome = action_outcome(
        dimension_from_volume,
        [ classification(productive),
          cluster(g8_round_solid_volume),
          automaton_state(State),
          vocabulary([volume, cylinder, cone, radius, height, square_root, pi]),
          input(unknown_dimension(Solid, radius, Volume, Height, Unit)),
          result(Answer),
          expected(Answer),
          radius_squared(SquaredText),
          invariant(the_formula_rebuilds_the_volume_from_the_answer),
          validity(Validity) ]),
    Trace = [ write_the_volume_formula_with_the_unknown_in_it(Solid),
              divide_by_everything_except_the_unknown(Height),
              undo_the_square_on_the_radius(SquaredText),
              Step ].
run_g8_solid_dimension(circle_area_from_radius, circle_from_radius(Radius, Unit),
                       Outcome, Trace) :-
    Squared is Radius * Radius,
    g8_rational_text(Squared, SquaredText),
    format(atom(A), '~w pi', [SquaredText]), atom_string(A, Text),
    Outcome = action_outcome(
        circle_area_from_radius,
        [ classification(productive),
          cluster(g8_round_solid_volume),
          automaton_state(q_report_the_circle_area),
          vocabulary([circle, radius, area, pi]),
          input(circle_from_radius(Radius, Unit)),
          result(area(Text, Unit)),
          expected(area(Text, Unit)),
          invariant(pi_stays_a_symbol_until_a_task_replaces_it),
          validity(correct) ]),
    Trace = [ multiply_the_radius_by_itself_and_by_pi(SquaredText),
              report_the_circle_area(Text) ].
run_g8_solid_dimension(radius_from_circle_area, circle_from_area(Area, Unit),
                       Outcome, Trace) :-
    volume_over_pi(Area, Squared),
    g8_exact_root_text(Squared, Text),
    (   exact_rational_root(Squared, Root)
    ->  Rebuilt is Root * Root,
        ( Rebuilt =:= Squared -> Validity = correct ; Validity = unvindicated ),
        Answer = radius(Text, Unit),
        State = q_report_the_dimension
    ;   Validity = refused,
        Answer = refused(the_squared_radius_is_not_a_square),
        State = q_refuse_an_inexact_radius
    ),
    Outcome = action_outcome(
        radius_from_circle_area,
        [ classification(productive),
          cluster(g8_round_solid_volume),
          automaton_state(State),
          vocabulary([circle, area, radius, square_root, pi]),
          input(circle_from_area(Area, Unit)),
          result(Answer),
          expected(Answer),
          invariant(the_area_rebuilds_from_the_radius),
          validity(Validity) ]),
    Trace = [ undo_the_square_on_the_radius(Text) ].
run_g8_solid_dimension(volume_between_cone_and_cylinder,
                       volume_ratio(Given, Wanted, Volume, Unit), Outcome,
                       Trace) :-
    volume_over_pi(Volume, Value),
    (   Given == cylinder
    ->  Wanted == cone, Answer is Value rdiv 3,
        State = q_take_a_third_of_the_cylinder,
        Step = take_a_third_of_the_cylinder
    ;   Answer is Value * 3,
        State = q_take_three_times_the_cone,
        Step = take_three_times_the_cone
    ),
    (   Given == cylinder
    ->  Rebuilt is Answer * 3
    ;   Rebuilt is Answer rdiv 3
    ),
    ( Rebuilt =:= Value -> Validity = correct ; Validity = unvindicated ),
    g8_rational_text(Answer, Text),
    Outcome = action_outcome(
        volume_between_cone_and_cylinder,
        [ classification(productive),
          cluster(g8_round_solid_volume),
          automaton_state(State),
          vocabulary([cone, cylinder, volume, third, same_base_and_height]),
          input(volume_ratio(Given, Wanted, Volume, Unit)),
          result(volume(Text, Unit)),
          expected(volume(Text, Unit)),
          invariant(three_cones_fill_the_cylinder),
          validity(Validity) ]),
    Trace = [ Step, report_the_dimension(Text) ].
run_g8_solid_dimension(volume_under_scaled_dimensions,
                       scaled(Solid, RadiusFactor, HeightFactor), Outcome,
                       Trace) :-
    % The formula uses the radius twice and the height once, for both solids.
    Factor is RadiusFactor * RadiusFactor * HeightFactor,
    g8_rational_text(Factor, Text),
    g8_rational_text(RadiusFactor, RadiusText),
    g8_rational_text(HeightFactor, HeightText),
    Outcome = action_outcome(
        volume_under_scaled_dimensions,
        [ classification(productive),
          cluster(g8_round_solid_volume),
          automaton_state(q_multiply_the_factors_as_the_formula_uses_them),
          vocabulary([volume, scale_factor, radius, height, formula]),
          input(scaled(Solid, RadiusFactor, HeightFactor)),
          result(volume_factor(Text)),
          expected(volume_factor(Text)),
          radius_factor(RadiusText),
          height_factor(HeightText),
          invariant(the_radius_enters_twice_and_the_height_once),
          validity(correct) ]),
    Trace = [ multiply_the_factors_as_the_formula_uses_them(RadiusText,
                                                            HeightText, Text) ].

solid_factor(cylinder, 1).
solid_factor(cone, 1 rdiv 3).

%!  volume_over_pi(+Volume, -Value) is det.
%
%   A volume of Q multiples of π divided by π is Q. A volume printed as a
%   value with its own stand-in for π is divided by that stand-in, and the
%   stand-in is the task's, not this module's.
volume_over_pi(symbolic_pi(Q), Q).
volume_over_pi(approximated(Q, none), Q).
volume_over_pi(approximated(Q, Pi), Value) :-
    Pi \== none,
    Value is Q rdiv Pi.

exact_rational_root(Squared, Root) :-
    Squared >= 0,
    N is numerator(Squared), D is denominator(Squared),
    RN is truncate(sqrt(N)), RN * RN =:= N,
    RD is truncate(sqrt(D)), RD * RD =:= D,
    Root is RN rdiv RD.

% ==========================================================================
% 5. SELF-SUMMARY
% ==========================================================================

g8_solid_dimension_summary(
    summary{ module: g8_circle_and_solid_dimensions,
             status: draft_for_quarantine,
             generated: false,
             grade: 8,
             cluster: g8_round_solid_volume,
             doings: [ dimension_from_volume,
                       circle_area_from_radius,
                       radius_from_circle_area,
                       volume_between_cone_and_cylinder,
                       volume_under_scaled_dimensions ],
             verification: [the_formula_rebuilds_the_volume_from_the_answer,
                            three_cones_fill_the_cylinder],
             arithmetic: exact_rational_with_symbolic_pi,
             beside: g8_round_solid_volume,
             deformation_partners:
                 'none authored here; scale_volume_linearly_with_radius already stands beside volume_under_scaled_dimensions in the published pilot',
             imported_by: none }).

% ==========================================================================
% 6. RECEIPTS
%
% g8_solid_dimension_receipt(Correction, Lesson, Doing, Json, Expected).
% ==========================================================================

% correction 2, IM-G8-U5-L14: 50 pi = 5^2 pi h, what is h
g8_solid_dimension_receipt(2, 'IM-G8-U5-L14', dimension_from_volume,
    _{kind: "solid_dimension", solid: "cylinder", unknown: "height",
      volume: _{pi_multiple: 50}, radius: 5, unit: "unit"},
    height("2", "unit")).
% correction 2: 36 pi = r^2 pi 4, what is r
g8_solid_dimension_receipt(2, 'IM-G8-U5-L14', dimension_from_volume,
    _{kind: "solid_dimension", solid: "cylinder", unknown: "radius",
      volume: _{pi_multiple: 36}, height: 4, unit: "unit"},
    radius("3", "unit")).
% correction 6, IM-G8-U5-L16: 64 pi = (1/3) pi r^2 3, what is r
g8_solid_dimension_receipt(6, 'IM-G8-U5-L16', dimension_from_volume,
    _{kind: "solid_dimension", solid: "cone", unknown: "radius",
      volume: _{pi_multiple: 64}, height: 3, unit: "unit"},
    radius("8", "unit")).
% correction 9, IM-G8-U5-L17: the graphed cone, height 10 and volume 2355,
% with the task's own 3.14 for pi
g8_solid_dimension_receipt(9, 'IM-G8-U5-L17', dimension_from_volume,
    _{kind: "solid_dimension", solid: "cone", unknown: "radius",
      volume: _{value: 2355, pi_as: 3.14}, height: 10, unit: "unit"},
    radius("15", "unit")).
% correction 3, IM-G8-U5-L15: the cylinder holds 90 cm^3, what does the cone hold
g8_solid_dimension_receipt(3, 'IM-G8-U5-L15', volume_between_cone_and_cylinder,
    _{kind: "solid_volume_ratio", given: "cylinder", wanted: "cone",
      volume: _{value: 90}, unit: "cm^3"},
    volume("30", "cm^3")).
% correction 3: the cone holds 120 cm^3, what does the cylinder hold
g8_solid_dimension_receipt(3, 'IM-G8-U5-L15', volume_between_cone_and_cylinder,
    _{kind: "solid_volume_ratio", given: "cone", wanted: "cylinder",
      volume: _{value: 120}, unit: "cm^3"},
    volume("360", "cm^3")).
% correction 49, IM-G8-U5-L13: the circle with radius 4
g8_solid_dimension_receipt(49, 'IM-G8-U5-L13', circle_area_from_radius,
    _{kind: "circle_measure", radius: 4, unit: "square units"},
    area("16 pi", "square units")).
% correction 49: a circle of area 49 pi, what is its radius
g8_solid_dimension_receipt(49, 'IM-G8-U5-L13', radius_from_circle_area,
    _{kind: "circle_measure", area: _{pi_multiple: 49}, unit: "units"},
    radius("7", "units")).
% correction 4, IM-G8-U5-L15: the base of the cone of diameter 6
g8_solid_dimension_receipt(4, 'IM-G8-U5-L15', circle_area_from_radius,
    _{kind: "circle_measure", radius: 3, unit: "square units"},
    area("9 pi", "square units")).
% correction 12, IM-G8-U5-L18: the cylinder whose height and radius are both
% c, with c halved
g8_solid_dimension_receipt(12, 'IM-G8-U5-L18', volume_under_scaled_dimensions,
    _{kind: "scaled_solid", solid: "cylinder",
      factors: _{radius: _{n: 1, d: 2}, height: _{n: 1, d: 2}}},
    volume_factor("1/8")).
% correction 8, IM-G8-U5-L17: the radius stays 5 and the height is halved
g8_solid_dimension_receipt(8, 'IM-G8-U5-L17', volume_under_scaled_dimensions,
    _{kind: "scaled_solid", solid: "cylinder",
      factors: _{height: _{n: 1, d: 2}}},
    volume_factor("1/2")).
% correction 5, IM-G8-U5-L15: the cone on the same base, three times taller
g8_solid_dimension_receipt(5, 'IM-G8-U5-L15', volume_under_scaled_dimensions,
    _{kind: "scaled_solid", solid: "cone", factors: _{height: 3}},
    volume_factor("3")).

% ==========================================================================
% 7. CHECK
% ==========================================================================

check_g8_circle_and_solid_dimensions :-
    check_receipts,
    check_the_symbolic_and_approximated_paths_agree,
    check_negative,
    format('g8_circle_and_solid_dimensions: all checks ok~n').

check_receipts :-
    findall(Correction-Doing-Result,
            ( g8_solid_dimension_receipt(Correction, _, Doing, Json, Expected),
              g8_solid_dimension_from_json(Json, Figure),
              run_g8_solid_dimension(Doing, Figure, Outcome, _),
              outcome_property(Outcome, result(Result)),
              Result = Expected
            ), Rows),
    findall(C, g8_solid_dimension_receipt(C, _, _, _, _), All),
    length(All, Total), length(Rows, Passed),
    Total =:= Passed,
    format('  receipts: ~w/~w printed rows run~n', [Passed, Total]),
    forall(member(Correction-Doing-Result, Rows),
           format('    correction ~w  ~w -> ~q~n',
                  [Correction, Doing, Result])).

check_the_symbolic_and_approximated_paths_agree :-
    % Correction 4's popcorn cup is 75 pi cubic centimetres by the published
    % pilot. Asking this module for the radius back, once with pi symbolic and
    % once with the task's 3.14, returns 5 both ways.
    g8_solid_dimension_from_json(
        _{kind: "solid_dimension", solid: "cone", unknown: "radius",
          volume: _{pi_multiple: 75}, height: 9, unit: "cm"}, Symbolic),
    run_g8_solid_dimension(dimension_from_volume, Symbolic, First, _),
    outcome_property(First, result(radius("5", "cm"))),
    g8_solid_dimension_from_json(
        _{kind: "solid_dimension", solid: "cone", unknown: "radius",
          volume: _{value: 235.5, pi_as: 3.14}, height: 9, unit: "cm"},
        Approximated),
    run_g8_solid_dimension(dimension_from_volume, Approximated, Second, _),
    outcome_property(Second, result(radius("5", "cm"))),
    format('  the popcorn cup: radius 5 cm whether pi stays a symbol or the task substitutes 3.14~n').

check_negative :-
    % A cylinder of volume 50 pi and height 4 has radius sqrt(12.5), which is
    % not a rational; the run refuses rather than rounding.
    g8_solid_dimension_from_json(
        _{kind: "solid_dimension", solid: "cylinder", unknown: "radius",
          volume: _{pi_multiple: 50}, height: 4, unit: "unit"}, Inexact),
    run_g8_solid_dimension(dimension_from_volume, Inexact, Outcome, _),
    outcome_property(Outcome, result(refused(the_squared_radius_is_not_a_square))),
    outcome_property(Outcome, validity(refused)),
    % A sphere is outside this module's contract and refuses at decode.
    \+ g8_solid_dimension_from_json(
           _{kind: "solid_dimension", solid: "sphere", unknown: "radius",
             volume: _{pi_multiple: 36}, height: 1, unit: "unit"}, _),
    % A volume of zero is refused at decode.
    \+ g8_solid_dimension_from_json(
           _{kind: "solid_dimension", solid: "cylinder", unknown: "height",
             volume: _{pi_multiple: 0}, radius: 5, unit: "unit"}, _),
    format('  negative tests: an inexact radius refuses by name, a sphere and a zero volume refuse at decode~n').

outcome_property(action_outcome(_, Props), Property) :-
    memberchk(Property, Props).
