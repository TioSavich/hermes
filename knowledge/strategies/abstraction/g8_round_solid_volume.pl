:- encoding(utf8).
/** <module> Grade 8 pilot: volume of cylinders, cones, spheres, and hemispheres
 *
 * WHAT THIS IS. A quarantined pilot automaton for the doing IM grade 8 unit 5
 * asks for: read a round solid's radius (halving a diameter when that is what
 * the task gives), build the circular base, and carry it through the height by
 * the relation the unit establishes — a cylinder fills its base times its
 * height, a cone fills a third of the cylinder that contains it, a sphere
 * fills two thirds of the cylinder that circumscribes it.
 *
 * WHY IT IS NEW. The geometry registry's volume machines iterate unit cubes:
 * `rectangular_prism_volume_layer_iteration` counts layers of unit cubes, and
 * that representation has no circular base and no π. Its reach also runs out
 * well before grade 8 magnitudes — probed headless, a 50-by-50-by-50 prism
 * returns 125,000 correctly and a 100-by-100-by-100 prism returns a run
 * failure. This pilot computes with an exact rational coefficient of π instead
 * of iterating, so it reaches grade 8 solids and reports exact answers. It
 * leaves the layer-iteration machine untouched.
 *
 * PI IS CARRIED, NEVER EVALUATED. A volume is reported as a rational
 * coefficient of π — 100π, 18π, 250/3 π — which is the form IM's own answers
 * take. A rounded decimal sits beside it, labelled an approximation. Exact
 * comparisons (does the cone hold the cylinder's water? is Tyler's paperweight
 * eight times Mai's?) are decided on the coefficients, never on floats.
 *
 * SELF-VERIFICATION. Every run recomputes its coefficient a second way and
 * reports whether the two agree: the cone against a third of its containing
 * cylinder, the sphere against two thirds of its circumscribing cylinder, the
 * hemisphere against half its sphere, the cylinder against its base area times
 * its height. A run whose two computations disagree is reported unvindicated.
 *
 * DEFORMATION PARTNER. One, attested in this repository's research corpus:
 * `scale_volume_linearly_with_radius` reproduces db_row 38050 (Kittel,
 * Beckmann, Hole & Ladel 2005, ZDM, p. 382) — linear proportional reasoning
 * carried onto a non-linear measure, so doubling the radius is taken to double
 * the volume. IM grade 8 unit 5 lesson 19 asks exactly this comparison about
 * Tyler's box and Mai's.
 *
 * QUARANTINE. Nothing imports this module; it renames nothing; its rows are
 * authored and vetoable one by one. Check: `check_g8_round_solid_volume/0`.
 */

:- module(g8_round_solid_volume,
          [ run_g8_round_solid_volume/4,
            g8_round_solid_from_json/2,
            g8_round_solid_states/1,
            g8_round_solid_state_label/4,
            g8_round_solid_summary/1,
            g8_round_solid_receipt/5,
            check_g8_round_solid_volume/0
          ]).

:- use_module(strategies('abstraction/g8_quantity_input'),
              [ g8_quantity/2, g8_rational_text/2,
                g8_decimal_approximation/3 ]).

% ==========================================================================
% 1. INPUT CONTRACT
%
%   {"kind":"round_solid","solid":"cylinder","radius":5,"height":4,
%    "unit":"unit"}
%   {"kind":"round_solid","solid":"cone","diameter":6,"height":8,"unit":"cm"}
%   {"kind":"round_solid","solid":"sphere","radius":9,"unit":"cm"}
%   {"kind":"round_solid","solid":"hemisphere","radius":5,"unit":"unit"}
%   {"kind":"round_solid","solid":"rectangular_prism","base_area":16,
%    "height":3,"unit":"unit"}
%
% A solid may name its radius or its diameter; naming both is refused rather
% than silently preferring one.
% ==========================================================================

g8_round_solid_input_contract(
    '{\"kind\":\"round_solid\",\"solid\":\"string\",\"radius\":\"number\",\"diameter\":\"number\",\"base_area\":\"number\",\"height\":\"number\",\"unit\":\"string\"}',
    '{\"kind\":\"round_solid\",\"solid\":\"cylinder\",\"radius\":5,\"height\":4,\"unit\":\"unit\"}').

g8_round_solid_from_json(Dict, solid(Solid, Radius, Height, Unit)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "round_solid"),
    get_dict(solid, Dict, SolidText),
    memberchk(SolidText, ["cylinder", "cone", "sphere", "hemisphere"]),
    atom_string(Solid, SolidText),
    radius_of(Dict, Radius),
    ( memberchk(SolidText, ["sphere", "hemisphere"])
    -> Height = none
    ;  get_dict(height, Dict, H0), g8_quantity(H0, Height), Height > 0
    ),
    solid_unit(Dict, Unit).
g8_round_solid_from_json(Dict, prism(BaseArea, Height, Unit)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "round_solid"),
    get_dict(solid, Dict, "rectangular_prism"),
    get_dict(base_area, Dict, A0), get_dict(height, Dict, H0),
    g8_quantity(A0, BaseArea), g8_quantity(H0, Height),
    BaseArea > 0, Height > 0,
    solid_unit(Dict, Unit).

radius_of(Dict, Radius) :-
    ( get_dict(radius, Dict, R0) -> HasR = true ; HasR = false ),
    ( get_dict(diameter, Dict, D0) -> HasD = true ; HasD = false ),
    (   HasR == true, HasD == false
    ->  g8_quantity(R0, Radius)
    ;   HasR == false, HasD == true
    ->  g8_quantity(D0, Diameter), Radius is Diameter rdiv 2
    ),
    Radius > 0.

solid_unit(Dict, Unit) :-
    ( get_dict(unit, Dict, U), string(U) -> Unit = U ; Unit = "unit" ).

% ==========================================================================
% 2. STATES
% ==========================================================================

g8_round_solid_states(
    [ q_identify_solid,
      q_read_radius_from_diameter,
      q_build_circular_base,
      q_carry_base_through_height,
      q_take_third_of_containing_cylinder,
      q_take_two_thirds_of_circumscribing_cylinder,
      q_halve_the_sphere,
      q_verify_by_second_route,
      q_accept_volume,
      q_scale_volume_by_the_length_factor ]).

% g8_round_solid_state_label(State, Tradition, Label, Citation).
g8_round_solid_state_label(q_read_radius_from_diameter, illustrative_mathematics,
    "the radius is half the diameter",
    "IM Grade 8 Unit 5 Lesson 14, Volumes of Cylinders").
g8_round_solid_state_label(q_build_circular_base, illustrative_mathematics,
    "the area of the base",
    "IM Grade 8 Unit 5 Lesson 13, The Volume of a Cylinder").
g8_round_solid_state_label(q_build_circular_base, van_de_walle,
    "the area of the base of the solid",
    "Van de Walle, ch. 19, Volume and Capacity").
g8_round_solid_state_label(q_carry_base_through_height, van_de_walle,
    "the base area times the height",
    "Van de Walle, ch. 19, Developing Volume Formulas").
g8_round_solid_state_label(q_take_third_of_containing_cylinder,
    illustrative_mathematics,
    "a cone holds one third of the cylinder with the same base and height",
    "IM Grade 8 Unit 5 Lesson 16, Finding Cone Dimensions").
g8_round_solid_state_label(q_take_two_thirds_of_circumscribing_cylinder,
    illustrative_mathematics,
    "a sphere holds two thirds of the cylinder that fits around it",
    "IM Grade 8 Unit 5 Lesson 21, Cylinders, Cones, and Spheres").
g8_round_solid_state_label(q_halve_the_sphere, illustrative_mathematics,
    "a hemisphere is half a sphere",
    "IM Grade 8 Unit 5 Lesson 19, Estimating a Hemisphere").
g8_round_solid_state_label(q_verify_by_second_route, provisional,
    "recompute the volume a second way",
    "provisional; no community label sourced for this checking step").
g8_round_solid_state_label(q_scale_volume_by_the_length_factor, kittel,
    "doubling the radius taken to double the measure",
    "db_row 38050; Kittel, Beckmann, Hole & Ladel 2005, ZDM, p. 382").

% ==========================================================================
% 3. TRANSITIONS
% ==========================================================================

g8_round_solid_transition(cylinder_volume_from_base_and_height,
    q_identify_solid, halve_the_diameter, q_read_radius_from_diameter).
g8_round_solid_transition(cylinder_volume_from_base_and_height,
    q_read_radius_from_diameter, square_the_radius_for_the_base,
    q_build_circular_base).
g8_round_solid_transition(cylinder_volume_from_base_and_height,
    q_build_circular_base, multiply_the_base_by_the_height,
    q_carry_base_through_height).
g8_round_solid_transition(cylinder_volume_from_base_and_height,
    q_carry_base_through_height, recompute_a_second_way,
    q_verify_by_second_route).
g8_round_solid_transition(cylinder_volume_from_base_and_height,
    q_verify_by_second_route, report_volume_in_terms_of_pi, q_accept_volume).
g8_round_solid_transition(cone_volume_as_third_of_cylinder,
    q_build_circular_base, take_a_third_of_the_containing_cylinder,
    q_take_third_of_containing_cylinder).
g8_round_solid_transition(cone_volume_as_third_of_cylinder,
    q_take_third_of_containing_cylinder, recompute_a_second_way,
    q_verify_by_second_route).
g8_round_solid_transition(sphere_volume_from_radius,
    q_build_circular_base, take_two_thirds_of_the_circumscribing_cylinder,
    q_take_two_thirds_of_circumscribing_cylinder).
g8_round_solid_transition(sphere_volume_from_radius,
    q_take_two_thirds_of_circumscribing_cylinder, recompute_a_second_way,
    q_verify_by_second_route).
g8_round_solid_transition(hemisphere_volume_as_half_sphere,
    q_take_two_thirds_of_circumscribing_cylinder, halve_the_sphere,
    q_halve_the_sphere).
g8_round_solid_transition(hemisphere_volume_as_half_sphere,
    q_halve_the_sphere, recompute_a_second_way, q_verify_by_second_route).
g8_round_solid_transition(prism_volume_from_base_area_and_height,
    q_build_circular_base, multiply_the_base_by_the_height,
    q_carry_base_through_height).
g8_round_solid_transition(scale_volume_linearly_with_radius,
    q_read_radius_from_diameter, multiply_the_volume_by_the_length_factor,
    q_scale_volume_by_the_length_factor).

% ==========================================================================
% 4. THE RUN
%
% A volume is the pair pi_multiple(Coefficient) or cubic_units(Value), with
% Coefficient and Value exact rationals.
% ==========================================================================

run_g8_round_solid_volume(cylinder_volume_from_base_and_height,
                          solid(cylinder, R, H, Unit), Outcome, Trace) :-
    BaseArea is R * R,
    Coefficient is BaseArea * H,
    SecondRoute is (R * H) * R,
    volume_outcome(cylinder_volume_from_base_and_height, q_accept_volume,
                   solid(cylinder, R, H, Unit), Coefficient, SecondRoute,
                   pi_multiple, Unit,
                   [cylinder, radius, diameter, base_area, height,
                    cubic_units, pi],
                   base_area_times_height, Outcome),
    volume_text(Coefficient, pi_multiple, Text),
    Trace = [ identify_solid(cylinder),
              square_the_radius_for_the_base(BaseArea),
              multiply_the_base_by_the_height(Coefficient),
              recompute_a_second_way(SecondRoute),
              report_volume_in_terms_of_pi(Text, Unit) ].
run_g8_round_solid_volume(cone_volume_as_third_of_cylinder,
                          solid(cone, R, H, Unit), Outcome, Trace) :-
    CylinderCoefficient is R * R * H,
    Coefficient is CylinderCoefficient rdiv 3,
    SecondRoute is (R * R * H) rdiv 3,
    volume_outcome(cone_volume_as_third_of_cylinder,
                   q_take_third_of_containing_cylinder,
                   solid(cone, R, H, Unit), Coefficient, SecondRoute,
                   pi_multiple, Unit,
                   [cone, radius, base_area, height, cubic_units, pi,
                    one_third],
                   cone_is_a_third_of_its_cylinder, Outcome),
    volume_text(Coefficient, pi_multiple, Text),
    Trace = [ identify_solid(cone),
              square_the_radius_for_the_base(CylinderCoefficient),
              take_a_third_of_the_containing_cylinder(Coefficient),
              recompute_a_second_way(SecondRoute),
              report_volume_in_terms_of_pi(Text, Unit) ].
run_g8_round_solid_volume(sphere_volume_from_radius,
                          solid(sphere, R, none, Unit), Outcome, Trace) :-
    CylinderCoefficient is R * R * (2 * R),
    Coefficient is (2 rdiv 3) * CylinderCoefficient,
    SecondRoute is (4 rdiv 3) * R * R * R,
    volume_outcome(sphere_volume_from_radius,
                   q_take_two_thirds_of_circumscribing_cylinder,
                   solid(sphere, R, none, Unit), Coefficient, SecondRoute,
                   pi_multiple, Unit,
                   [sphere, radius, circumscribing_cylinder, cubic_units, pi,
                    two_thirds],
                   sphere_is_two_thirds_of_its_cylinder, Outcome),
    volume_text(Coefficient, pi_multiple, Text),
    Trace = [ identify_solid(sphere),
              name_the_circumscribing_cylinder(CylinderCoefficient),
              take_two_thirds_of_the_circumscribing_cylinder(Coefficient),
              recompute_a_second_way(SecondRoute),
              report_volume_in_terms_of_pi(Text, Unit) ].
run_g8_round_solid_volume(hemisphere_volume_as_half_sphere,
                          solid(hemisphere, R, none, Unit), Outcome, Trace) :-
    SphereCoefficient is (4 rdiv 3) * R * R * R,
    Coefficient is SphereCoefficient rdiv 2,
    SecondRoute is (2 rdiv 3) * R * R * R,
    volume_outcome(hemisphere_volume_as_half_sphere, q_halve_the_sphere,
                   solid(hemisphere, R, none, Unit), Coefficient, SecondRoute,
                   pi_multiple, Unit,
                   [hemisphere, sphere, radius, cubic_units, pi, half],
                   hemisphere_is_half_its_sphere, Outcome),
    volume_text(Coefficient, pi_multiple, Text),
    Trace = [ identify_solid(hemisphere),
              name_the_whole_sphere(SphereCoefficient),
              halve_the_sphere(Coefficient),
              recompute_a_second_way(SecondRoute),
              report_volume_in_terms_of_pi(Text, Unit) ].
run_g8_round_solid_volume(prism_volume_from_base_area_and_height,
                          prism(BaseArea, H, Unit), Outcome, Trace) :-
    Coefficient is BaseArea * H,
    SecondRoute is H * BaseArea,
    volume_outcome(prism_volume_from_base_area_and_height, q_accept_volume,
                   prism(BaseArea, H, Unit), Coefficient, SecondRoute,
                   cubic_units, Unit,
                   [rectangular_prism, base_area, height, cubic_units],
                   base_area_times_height, Outcome),
    volume_text(Coefficient, cubic_units, Text),
    Trace = [ identify_solid(rectangular_prism),
              read_the_base_area(BaseArea),
              multiply_the_base_by_the_height(Coefficient),
              recompute_a_second_way(SecondRoute),
              report_volume(Text, Unit) ].
run_g8_round_solid_volume(scale_volume_linearly_with_radius,
                          scaling(Solid, R, H, Factor, Unit), Outcome, Trace) :-
    Factor > 1,
    productive_scaling(Solid, R, H, Unit, Small),
    ScaledR is R * Factor,
    ( H == none -> ScaledH = none ; ScaledH is H * Factor ),
    productive_scaling(Solid, ScaledR, ScaledH, Unit, Large),
    TrueRatio is Large rdiv Small,
    g8_rational_text(TrueRatio, TrueText),
    g8_rational_text(Factor, FactorText),
    ( TrueRatio =\= Factor -> Validity = incorrect ; Validity = unvindicated ),
    Outcome = action_outcome(
        scale_volume_linearly_with_radius,
        [ classification(deformation),
          cluster(g8_round_solid_volume),
          automaton_state(q_scale_volume_by_the_length_factor),
          vocabulary([radius, length_factor, volume, cubic_units,
                      proportional_reasoning]),
          input(scaling(Solid, R, H, Factor, Unit)),
          expected(volume_ratio(TrueText)),
          result(volume_ratio(FactorText)),
          deformation_of(sphere_volume_from_radius),
          violated_invariant(volume_scales_by_the_cube_of_the_length_factor),
          attested_as(db_row(38050),
                      "Kittel, Beckmann, Hole & Ladel 2005, ZDM, p. 382"),
          validity(Validity) ]),
    Trace = [ identify_solid(Solid),
              multiply_the_length_by_the_factor(Factor),
              multiply_the_volume_by_the_length_factor(FactorText) ].

productive_scaling(Solid, R, _Height, Unit, Coefficient) :-
    ( Solid == sphere ; Solid == hemisphere ),
    !,
    Figure = solid(Solid, R, none, Unit),
    ( Solid == sphere -> Doing = sphere_volume_from_radius
    ; Doing = hemisphere_volume_as_half_sphere ),
    run_g8_round_solid_volume(Doing, Figure, Outcome, _),
    outcome_property(Outcome, volume(pi_multiple(Coefficient))).
productive_scaling(Solid, R, H, Unit, Coefficient) :-
    ( Solid == cylinder -> Doing = cylinder_volume_from_base_and_height
    ; Solid == cone -> Doing = cone_volume_as_third_of_cylinder ),
    run_g8_round_solid_volume(Doing, solid(Solid, R, H, Unit), Outcome, _),
    outcome_property(Outcome, volume(pi_multiple(Coefficient))).

volume_outcome(Doing, State, Input, Coefficient, SecondRoute, Genre, Unit,
               Vocabulary, Invariant, Outcome) :-
    ( Coefficient =:= SecondRoute -> Validity = correct
    ; Validity = unvindicated ),
    volume_text(Coefficient, Genre, Text),
    Volume =.. [Genre, Coefficient],
    approximate_volume(Coefficient, Genre, Approximation),
    Outcome = action_outcome(
        Doing,
        [ classification(productive),
          cluster(g8_round_solid_volume),
          automaton_state(State),
          vocabulary(Vocabulary),
          input(Input),
          result(volume_text(Text, Unit)),
          expected(volume_text(Text, Unit)),
          volume(Volume),
          second_route(SecondRoute),
          decimal_approximation(Approximation),
          invariant(Invariant),
          validity(Validity) ]).

volume_text(Coefficient, pi_multiple, Text) :- !,
    g8_rational_text(Coefficient, Number),
    format(string(Text), "~w pi", [Number]).
volume_text(Coefficient, cubic_units, Text) :-
    g8_rational_text(Coefficient, Text).

approximate_volume(Coefficient, pi_multiple, Approximation) :- !,
    Scaled is Coefficient * rationalize(3.14159265358979),
    g8_decimal_approximation(Scaled, 2, Approximation).
approximate_volume(Coefficient, cubic_units, Approximation) :-
    g8_decimal_approximation(Coefficient, 2, Approximation).

% ==========================================================================
% 5. SELF-SUMMARY
% ==========================================================================

g8_round_solid_summary(
    summary{ module: g8_round_solid_volume,
             status: authored_pilot,
             generated: false,
             grade: 8,
             cluster: g8_round_solid_volume,
             doings: [ cylinder_volume_from_base_and_height,
                       cone_volume_as_third_of_cylinder,
                       sphere_volume_from_radius,
                       hemisphere_volume_as_half_sphere,
                       prism_volume_from_base_area_and_height,
                       scale_volume_linearly_with_radius ],
             verification: recompute_the_coefficient_by_a_second_route,
             arithmetic: exact_rational_coefficient_of_pi,
             imported_by: none,
             extant_machine_left_untouched:
                 'geometry/rectangular_prism_volume_layer_iteration' }).

% ==========================================================================
% 6. RECEIPTS
% ==========================================================================

g8_round_solid_receipt(
    'im_defrag_a4cc8c31eb22994bbec5f1e4_1', 'IM-G8-U5-L13',
    cylinder_volume_from_base_and_height,
    _{kind: "round_solid", solid: "cylinder", diameter: 10, height: 4,
      unit: "unit"},
    volume_text("100 pi", "unit")).
g8_round_solid_receipt(
    'im_defrag_8464ee69687fff17d9ca2e1f_1', 'IM-G8-U5-L21',
    cylinder_volume_from_base_and_height,
    _{kind: "round_solid", solid: "cylinder", diameter: 3, height: 8,
      unit: "cm"},
    volume_text("18 pi", "cm")).
g8_round_solid_receipt(
    'im_defrag_8464ee69687fff17d9ca2e1f_1', 'IM-G8-U5-L21',
    cone_volume_as_third_of_cylinder,
    _{kind: "round_solid", solid: "cone", radius: 3, height: 8, unit: "cm"},
    volume_text("24 pi", "cm")).
g8_round_solid_receipt(
    'im_defrag_5933c47e5e26b87ec5187d4e_1', 'IM-G8-U5-L21',
    sphere_volume_from_radius,
    _{kind: "round_solid", solid: "sphere", radius: 9, unit: "cm"},
    volume_text("972 pi", "cm")).
g8_round_solid_receipt(
    'im_defrag_705e2ad479bf8cb41fcc1dcb_1', 'IM-G8-U5-L19',
    hemisphere_volume_as_half_sphere,
    _{kind: "round_solid", solid: "hemisphere", radius: 5, unit: "unit"},
    volume_text("250/3 pi", "unit")).
g8_round_solid_receipt(
    'im_defrag_705e2ad479bf8cb41fcc1dcb_1', 'IM-G8-U5-L19',
    cylinder_volume_from_base_and_height,
    _{kind: "round_solid", solid: "cylinder", radius: 5, height: 5,
      unit: "unit"},
    volume_text("125 pi", "unit")).
g8_round_solid_receipt(
    'im_defrag_1e44fea48a27e31352698b15_1', 'IM-G8-U5-L19',
    hemisphere_volume_as_half_sphere,
    _{kind: "round_solid", solid: "hemisphere", radius: 5, unit: "inch"},
    volume_text("250/3 pi", "inch")).
g8_round_solid_receipt(
    'im_defrag_5326c4e9cce57e33ffd2252f_1', 'IM-G8-U5-L19',
    hemisphere_volume_as_half_sphere,
    _{kind: "round_solid", solid: "hemisphere", radius: 3, unit: "cm"},
    volume_text("18 pi", "cm")).
g8_round_solid_receipt(
    'im_defrag_1201650ec0a9449941a862a8_1', 'IM-G8-U5-L13',
    prism_volume_from_base_area_and_height,
    _{kind: "round_solid", solid: "rectangular_prism", base_area: 16,
      height: 3, unit: "unit"},
    volume_text("48", "unit")).
g8_round_solid_receipt(
    'im_defrag_fb9e6f61e11fd071c4943528_1', 'IM-G8-U5-L14',
    cylinder_volume_from_base_and_height,
    _{kind: "round_solid", solid: "cylinder", radius: 3, height: 4,
      unit: "unit"},
    volume_text("36 pi", "unit")).
g8_round_solid_receipt(
    'im_defrag_da9401d9e55b12a5b9ae7659_1', 'IM-G8-U5-L16',
    cone_volume_as_third_of_cylinder,
    _{kind: "round_solid", solid: "cone", radius: 4, height: 3, unit: "unit"},
    volume_text("16 pi", "unit")).

% ==========================================================================
% 7. CHECK
% ==========================================================================

check_g8_round_solid_volume :-
    check_receipts,
    check_containment_comparison,
    check_attested_deformation,
    check_negative,
    format('g8_round_solid_volume: all checks ok~n').

check_receipts :-
    findall(Lesson-Row-Doing-Result,
            ( g8_round_solid_receipt(Row, Lesson, Doing, Json, Expected),
              g8_round_solid_from_json(Json, Figure),
              run_g8_round_solid_volume(Doing, Figure, Outcome, _),
              outcome_property(Outcome, result(Result)),
              Result = Expected,
              outcome_property(Outcome, validity(correct))
            ), Rows),
    findall(R-L-D, g8_round_solid_receipt(R, L, D, _, _), All),
    length(All, Total), length(Rows, Passed),
    Total =:= Passed,
    format('  receipts: ~w/~w real grade 8 rows run, each agreeing with its second route~n',
           [Passed, Total]),
    forall(member(Lesson-Row-Doing-Result, Rows),
           format('    ~w  ~w  ~w -> ~q~n', [Lesson, Row, Doing, Result])).

check_containment_comparison :-
    % IM-G8-U5-L21 section(4): can each figure hold the cylinder's water?
    % The cylinder is 18 pi. Comparison is exact, on coefficients.
    g8_round_solid_from_json(
        _{kind: "round_solid", solid: "cylinder", diameter: 3, height: 8,
          unit: "cm"}, Water),
    run_g8_round_solid_volume(cylinder_volume_from_base_and_height, Water,
                              WaterOutcome, _),
    outcome_property(WaterOutcome, volume(pi_multiple(WaterCoefficient))),
    g8_round_solid_from_json(
        _{kind: "round_solid", solid: "cone", radius: 3, height: 8,
          unit: "cm"}, Cone),
    run_g8_round_solid_volume(cone_volume_as_third_of_cylinder, Cone,
                              ConeOutcome, _),
    outcome_property(ConeOutcome, volume(pi_multiple(ConeCoefficient))),
    ConeCoefficient > WaterCoefficient,
    g8_round_solid_from_json(
        _{kind: "round_solid", solid: "sphere", radius: 2, unit: "cm"}, Ball),
    run_g8_round_solid_volume(sphere_volume_from_radius, Ball, BallOutcome, _),
    outcome_property(BallOutcome, volume(pi_multiple(BallCoefficient))),
    BallCoefficient < WaterCoefficient,
    format('  containment: the 18 pi cylinder fits inside the 24 pi cone and not inside the 32/3 pi sphere, decided on exact coefficients~n').

check_attested_deformation :-
    % IM-G8-U5-L19 section(2): Tyler's box has sides twice Mai's. Under
    % db_row 38050 the volume ratio is read as 2; it is 8.
    run_g8_round_solid_volume(scale_volume_linearly_with_radius,
                              scaling(hemisphere, 3, none, 2, "cm"), O, _),
    outcome_property(O, result(volume_ratio("2"))),
    outcome_property(O, expected(volume_ratio("8"))),
    outcome_property(O, validity(incorrect)),
    format('  attested deformation: db_row 38050 reads the doubled radius as a doubled volume where the ratio is 8~n').

check_negative :-
    % Naming both a radius and a diameter is refused rather than resolved.
    \+ g8_round_solid_from_json(
           _{kind: "round_solid", solid: "cylinder", radius: 5, diameter: 10,
             height: 4, unit: "unit"}, _),
    % A zero height is outside the contract.
    \+ g8_round_solid_from_json(
           _{kind: "round_solid", solid: "cylinder", radius: 5, height: 0,
             unit: "unit"}, _),
    % A cone is a third of its cylinder, never equal to it.
    g8_round_solid_from_json(
        _{kind: "round_solid", solid: "cylinder", radius: 5, height: 5,
          unit: "unit"}, Cyl),
    run_g8_round_solid_volume(cylinder_volume_from_base_and_height, Cyl, OC, _),
    outcome_property(OC, volume(pi_multiple(CylCoefficient))),
    g8_round_solid_from_json(
        _{kind: "round_solid", solid: "cone", radius: 5, height: 5,
          unit: "unit"}, Cone),
    run_g8_round_solid_volume(cone_volume_as_third_of_cylinder, Cone, OK, _),
    outcome_property(OK, volume(pi_multiple(ConeCoefficient))),
    CylCoefficient =:= 3 * ConeCoefficient,
    format('  negative tests: a doubly named radius refuses, a zero height refuses, and the cone stays a third of its cylinder~n').

outcome_property(action_outcome(_, Props), Property) :-
    memberchk(Property, Props).
