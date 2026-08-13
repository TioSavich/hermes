:- encoding(utf8).
/** <module> Grade 8 pilot: polygon angles and what tiles the plane
 *
 * WHAT THIS IS. A quarantined pilot automaton for the doing IM grade 8 unit 1
 * closes with and unit 9 opens with: find the interior angle of a regular
 * polygon, count how many copies fit around a single vertex without gap or
 * overlap, decide whether a regular polygon tessellates the plane, and find an
 * unknown angle from a stated whole.
 *
 * WHY IT IS NEW. `geometry/angle_relation_unknown_measure` subtracts known
 * parts from a stated whole and `geometry/angle_additive_composition` sums
 * parts into one. Neither knows that a regular n-gon's interior angle is
 * (n - 2) * 180 / n, and neither can decide whether copies of a shape close
 * around a vertex, which is the whole question of unit 9. This pilot supplies
 * that and leaves both machines untouched.
 *
 * THE TEST IS DIVISIBILITY, NOT DRAWING. A regular polygon tessellates exactly
 * when 360 divided by its interior angle is a whole number. The angle is kept
 * as an exact rational, so the pentagon's 108 degrees gives 360/108 = 10/3 and
 * the automaton reports a non-whole count rather than rounding to 3 and
 * claiming a tessellation that leaves a gap. That gap is the point of the
 * lesson, and a float would hide it.
 *
 * SELF-VERIFICATION. Every interior angle is checked against the triangulation
 * count: an n-gon splits into n - 2 triangles, so n times the interior angle
 * must equal (n - 2) times 180 exactly. Every vertex count is checked by
 * multiplying back: copies times angle must equal 360 exactly when the count
 * is whole.
 *
 * REFUSALS. Fewer than three sides is not a polygon and refuses by name. Angle
 * parts that already exceed their whole refuse rather than returning a
 * negative remainder, which is what IM-G8-U1-L15's three right angles asks
 * about.
 *
 * NO DEFORMATION PARTNER. The research corpus carries no row attesting a
 * student error at the interior-angle or tessellation locus. Shipping without
 * one is the honest choice rather than inventing a twin for symmetry.
 *
 * QUARANTINE. Nothing imports this module; it renames nothing; its rows are
 * authored and vetoable one by one.
 * Check: `check_g8_polygon_angle_and_tessellation/0`.
 */

:- module(g8_polygon_angle_and_tessellation,
          [ run_g8_polygon_angle/4,
            g8_polygon_angle_from_json/2,
            g8_polygon_angle_states/1,
            g8_polygon_angle_state_label/4,
            g8_polygon_angle_summary/1,
            g8_polygon_angle_receipt/5,
            check_g8_polygon_angle_and_tessellation/0
          ]).

:- use_module(strategies('abstraction/g8_quantity_input'),
              [ g8_quantity/2, g8_rational_text/2 ]).

% ==========================================================================
% 1. INPUT CONTRACT
%
%   {"kind":"regular_polygon","sides":6,"name":"hexagon"}
%   {"kind":"angle_parts","whole":180,"known":[90,90,90]}
% ==========================================================================

g8_polygon_angle_input_contract(
    '{\"kind\":\"regular_polygon\",\"sides\":\"integer\",\"name\":\"string\"}',
    '{\"kind\":\"regular_polygon\",\"sides\":6,\"name\":\"hexagon\"}').

g8_polygon_angle_from_json(Dict, regular_polygon(Sides, Name)) :-
    is_dict(Dict), get_dict(kind, Dict, "regular_polygon"), !,
    get_dict(sides, Dict, Sides), integer(Sides), Sides >= 3,
    ( get_dict(name, Dict, N), string(N) -> Name = N ; Name = "polygon" ).
g8_polygon_angle_from_json(Dict, angle_parts(Whole, Known)) :-
    is_dict(Dict), get_dict(kind, Dict, "angle_parts"),
    get_dict(whole, Dict, W0), get_dict(known, Dict, Raw),
    is_list(Raw), Raw \== [],
    g8_quantity(W0, Whole), Whole > 0,
    maplist(g8_quantity, Raw, Known),
    forall(member(K, Known), K > 0).

% ==========================================================================
% 2. STATES
% ==========================================================================

g8_polygon_angle_states(
    [ q_count_the_sides,
      q_split_into_triangles,
      q_share_the_triangle_sum_among_the_vertices,
      q_verify_against_the_triangulation,
      q_accept_interior_angle,
      q_divide_the_full_turn_by_the_angle,
      q_accept_tessellation,
      q_reject_tessellation,
      q_accumulate_known_parts,
      q_take_the_remaining_part,
      q_refuse_parts_exceeding_the_whole ]).

% g8_polygon_angle_state_label(State, Tradition, Label, Citation).
g8_polygon_angle_state_label(q_split_into_triangles, illustrative_mathematics,
    "the polygon split into triangles from one vertex",
    "IM Grade 8 Unit 9 Lesson 2, Tessellating Polygons").
g8_polygon_angle_state_label(q_split_into_triangles, van_de_walle,
    "decomposing a polygon into triangles",
    "Van de Walle, ch. 17, Angle Sums of Polygons").
g8_polygon_angle_state_label(q_share_the_triangle_sum_among_the_vertices,
    ccss, "the angle sum of a triangle is 180 degrees",
    "CCSS 8.G.A.5, via IM Grade 8 Unit 1 Lesson 16").
g8_polygon_angle_state_label(q_divide_the_full_turn_by_the_angle,
    illustrative_mathematics,
    "how many copies fit around a single vertex with no gaps or overlaps",
    "IM Grade 8 Unit 1 Lesson 17, Rotation Patterns; Unit 9 Lesson 2").
g8_polygon_angle_state_label(q_accept_tessellation, illustrative_mathematics,
    "a regular tessellation of the plane",
    "IM Grade 8 Unit 9 Lesson 2, Tessellating Polygons").
g8_polygon_angle_state_label(q_reject_tessellation, illustrative_mathematics,
    "the copies leave a gap or overlap at the vertex",
    "IM Grade 8 Unit 9 Lesson 2, Tessellating Polygons").
g8_polygon_angle_state_label(q_accumulate_known_parts, van_de_walle,
    "the known angle measures",
    "Van de Walle, ch. 17, Angle Relationships").
g8_polygon_angle_state_label(q_refuse_parts_exceeding_the_whole,
    illustrative_mathematics,
    "three right angles do not make a triangle",
    "IM Grade 8 Unit 1 Lesson 15, Adding the Angles in a Triangle").

% ==========================================================================
% 3. TRANSITIONS
% ==========================================================================

g8_polygon_angle_transition(regular_polygon_interior_angle,
    q_count_the_sides, split_into_triangles, q_split_into_triangles).
g8_polygon_angle_transition(regular_polygon_interior_angle,
    q_split_into_triangles, share_the_triangle_sum_among_the_vertices,
    q_share_the_triangle_sum_among_the_vertices).
g8_polygon_angle_transition(regular_polygon_interior_angle,
    q_share_the_triangle_sum_among_the_vertices, verify_against_the_triangulation,
    q_verify_against_the_triangulation).
g8_polygon_angle_transition(regular_polygon_interior_angle,
    q_verify_against_the_triangulation, report_interior_angle,
    q_accept_interior_angle).
g8_polygon_angle_transition(copies_around_a_vertex,
    q_accept_interior_angle, divide_the_full_turn_by_the_angle,
    q_divide_the_full_turn_by_the_angle).
g8_polygon_angle_transition(regular_tessellation_test,
    q_divide_the_full_turn_by_the_angle, accept_tessellation,
    q_accept_tessellation).
g8_polygon_angle_transition(regular_tessellation_test,
    q_divide_the_full_turn_by_the_angle, reject_tessellation,
    q_reject_tessellation).
g8_polygon_angle_transition(unknown_angle_from_a_whole,
    q_count_the_sides, accumulate_known_parts, q_accumulate_known_parts).
g8_polygon_angle_transition(unknown_angle_from_a_whole,
    q_accumulate_known_parts, take_the_remaining_part, q_take_the_remaining_part).
g8_polygon_angle_transition(unknown_angle_from_a_whole,
    q_accumulate_known_parts, refuse_parts_exceeding_the_whole,
    q_refuse_parts_exceeding_the_whole).

% ==========================================================================
% 4. THE RUN
% ==========================================================================

run_g8_polygon_angle(regular_polygon_interior_angle,
                     regular_polygon(Sides, Name), Outcome, Trace) :-
    Triangles is Sides - 2,
    TotalSum is Triangles * 180,
    Angle is TotalSum rdiv Sides,
    Rebuilt is Angle * Sides,
    ( Rebuilt =:= TotalSum -> Validity = correct ; Validity = unvindicated ),
    g8_rational_text(Angle, AngleText),
    Outcome = action_outcome(
        regular_polygon_interior_angle,
        [ classification(productive),
          cluster(g8_polygon_angles_and_tessellation),
          automaton_state(q_accept_interior_angle),
          vocabulary([regular_polygon, interior_angle, vertex, triangle,
                      angle_sum, degrees]),
          input(regular_polygon(Sides, Name)),
          result(interior_angle(AngleText)),
          expected(interior_angle(AngleText)),
          angle(Angle),
          triangulation(Triangles, TotalSum),
          invariant(sides_times_angle_equals_the_triangulated_sum),
          validity(Validity) ]),
    Trace = [ count_the_sides(Sides, Name),
              split_into_triangles(Triangles),
              share_the_triangle_sum_among_the_vertices(TotalSum, Sides),
              verify_against_the_triangulation(Rebuilt),
              report_interior_angle(AngleText) ].
run_g8_polygon_angle(copies_around_a_vertex, regular_polygon(Sides, Name),
                     Outcome, Trace) :-
    run_g8_polygon_angle(regular_polygon_interior_angle,
                         regular_polygon(Sides, Name),
                         action_outcome(_, Properties), _),
    memberchk(angle(Angle), Properties),
    Copies is 360 rdiv Angle,
    (   integer(Copies)
    ->  Closed is Copies * Angle,
        ( Closed =:= 360 -> Validity = correct ; Validity = unvindicated ),
        Answer = copies(Copies)
    ;   Validity = correct,
        g8_rational_text(Copies, CopiesText),
        Answer = no_whole_number_of_copies(CopiesText)
    ),
    g8_rational_text(Angle, AngleText),
    Outcome = action_outcome(
        copies_around_a_vertex,
        [ classification(productive),
          cluster(g8_polygon_angles_and_tessellation),
          automaton_state(q_divide_the_full_turn_by_the_angle),
          vocabulary([regular_polygon, interior_angle, vertex, full_turn,
                      gap, overlap]),
          input(regular_polygon(Sides, Name)),
          result(Answer),
          expected(Answer),
          interior_angle(AngleText),
          quotient(Copies),
          invariant(copies_times_angle_closes_the_full_turn),
          validity(Validity) ]),
    Trace = [ count_the_sides(Sides, Name),
              divide_the_full_turn_by_the_angle(AngleText, Copies) ].
run_g8_polygon_angle(regular_tessellation_test, regular_polygon(Sides, Name),
                     Outcome, Trace) :-
    run_g8_polygon_angle(copies_around_a_vertex, regular_polygon(Sides, Name),
                         action_outcome(_, Properties), _),
    memberchk(quotient(Copies), Properties),
    memberchk(interior_angle(AngleText), Properties),
    (   integer(Copies)
    ->  State = q_accept_tessellation, Answer = tessellates(Copies),
        Step = accept_tessellation(Copies)
    ;   State = q_reject_tessellation,
        g8_rational_text(Copies, CopiesText),
        Answer = does_not_tessellate(CopiesText),
        Step = reject_tessellation(CopiesText)
    ),
    Outcome = action_outcome(
        regular_tessellation_test,
        [ classification(productive),
          cluster(g8_polygon_angles_and_tessellation),
          automaton_state(State),
          vocabulary([regular_tessellation, plane, vertex, gap, overlap,
                      interior_angle]),
          input(regular_polygon(Sides, Name)),
          result(Answer),
          expected(Answer),
          interior_angle(AngleText),
          invariant(copies_times_angle_closes_the_full_turn),
          validity(correct) ]),
    Trace = [ count_the_sides(Sides, Name),
              divide_the_full_turn_by_the_angle(AngleText, Copies),
              Step ].
run_g8_polygon_angle(unknown_angle_from_a_whole, angle_parts(Whole, Known),
                     Outcome, Trace) :-
    sum_list(Known, Used),
    (   Used >= Whole
    ->  g8_rational_text(Used, UsedText),
        Outcome = action_outcome(
            unknown_angle_from_a_whole,
            [ classification(refusal),
              cluster(g8_polygon_angles_and_tessellation),
              automaton_state(q_refuse_parts_exceeding_the_whole),
              vocabulary([angle, whole, part, degrees]),
              input(angle_parts(Whole, Known)),
              result(refused(known_parts_fill_or_exceed_the_whole)),
              refusal(refusal{kind: "angle_parts_exceed_whole",
                              whole: Whole, used: UsedText}),
              validity(refused) ]),
        Trace = [ accumulate_known_parts(UsedText),
                  refuse_parts_exceeding_the_whole(Whole, UsedText) ]
    ;   Remaining is Whole - Used,
        Rebuilt is Used + Remaining,
        ( Rebuilt =:= Whole -> Validity = correct ; Validity = unvindicated ),
        g8_rational_text(Remaining, RemainingText),
        Outcome = action_outcome(
            unknown_angle_from_a_whole,
            [ classification(productive),
              cluster(g8_polygon_angles_and_tessellation),
              automaton_state(q_take_the_remaining_part),
              vocabulary([angle, whole, part, remaining_angle, degrees]),
              input(angle_parts(Whole, Known)),
              result(remaining_angle(RemainingText)),
              expected(remaining_angle(RemainingText)),
              rebuilt(Rebuilt),
              invariant(the_parts_and_the_remainder_make_the_whole),
              validity(Validity) ]),
        Trace = [ accumulate_known_parts(Used),
                  take_the_remaining_part(RemainingText) ]
    ).

% ==========================================================================
% 5. SELF-SUMMARY
% ==========================================================================

g8_polygon_angle_summary(
    summary{ module: g8_polygon_angle_and_tessellation,
             status: authored_pilot,
             generated: false,
             grade: 8,
             cluster: g8_polygon_angles_and_tessellation,
             doings: [ regular_polygon_interior_angle,
                       copies_around_a_vertex,
                       regular_tessellation_test,
                       unknown_angle_from_a_whole ],
             verification: triangulation_count_and_closing_the_full_turn,
             arithmetic: exact_rational,
             deformation_partners: none_attested_at_this_locus,
             imported_by: none,
             extant_machines_left_untouched:
                 [ 'geometry/angle_relation_unknown_measure',
                   'geometry/angle_additive_composition' ] }).

% ==========================================================================
% 6. RECEIPTS
% ==========================================================================

g8_polygon_angle_receipt(
    'im_defrag_3913dad6a61e4ef04084edb9_1', 'IM-G8-U9-L2',
    regular_polygon_interior_angle,
    _{kind: "regular_polygon", sides: 3, name: "equilateral triangle"},
    interior_angle("60")).
g8_polygon_angle_receipt(
    'im_defrag_3913dad6a61e4ef04084edb9_1', 'IM-G8-U9-L2',
    copies_around_a_vertex,
    _{kind: "regular_polygon", sides: 3, name: "equilateral triangle"},
    copies(6)).
g8_polygon_angle_receipt(
    'im_defrag_a1e0e7a998c9687f5845880c_1', 'IM-G8-U9-L2',
    regular_tessellation_test,
    _{kind: "regular_polygon", sides: 4, name: "square"},
    tessellates(4)).
g8_polygon_angle_receipt(
    'im_defrag_a1e0e7a998c9687f5845880c_1', 'IM-G8-U9-L2',
    regular_tessellation_test,
    _{kind: "regular_polygon", sides: 5, name: "pentagon"},
    does_not_tessellate("10/3")).
g8_polygon_angle_receipt(
    'im_defrag_a1e0e7a998c9687f5845880c_1', 'IM-G8-U9-L2',
    regular_tessellation_test,
    _{kind: "regular_polygon", sides: 6, name: "hexagon"},
    tessellates(3)).
g8_polygon_angle_receipt(
    'im_defrag_a1e0e7a998c9687f5845880c_1', 'IM-G8-U9-L2',
    regular_tessellation_test,
    _{kind: "regular_polygon", sides: 8, name: "octagon"},
    does_not_tessellate("8/3")).
g8_polygon_angle_receipt(
    'im_defrag_051ee5df066e75d23420b95c_1', 'IM-G8-U9-L2',
    regular_tessellation_test,
    _{kind: "regular_polygon", sides: 7, name: "heptagon"},
    does_not_tessellate("14/5")).
g8_polygon_angle_receipt(
    'im_defrag_051ee5df066e75d23420b95c_1', 'IM-G8-U9-L2',
    regular_tessellation_test,
    _{kind: "regular_polygon", sides: 9, name: "nonagon"},
    does_not_tessellate("18/7")).
g8_polygon_angle_receipt(
    'im_defrag_051ee5df066e75d23420b95c_1', 'IM-G8-U9-L2',
    regular_tessellation_test,
    _{kind: "regular_polygon", sides: 12, name: "dodecagon"},
    does_not_tessellate("12/5")).
g8_polygon_angle_receipt(
    'im_defrag_051ee5df066e75d23420b95c_1', 'IM-G8-U9-L2',
    regular_polygon_interior_angle,
    _{kind: "regular_polygon", sides: 8, name: "octagon"},
    interior_angle("135")).
g8_polygon_angle_receipt(
    'im_defrag_b48dfab53db48450ee2efe85_1', 'IM-G8-U1-L17',
    copies_around_a_vertex,
    _{kind: "regular_polygon", sides: 3, name: "equilateral triangle"},
    copies(6)).
g8_polygon_angle_receipt(
    'im_defrag_b48dfab53db48450ee2efe85_1', 'IM-G8-U1-L17',
    regular_polygon_interior_angle,
    _{kind: "regular_polygon", sides: 6, name: "hexagon"},
    interior_angle("120")).
g8_polygon_angle_receipt(
    'im_defrag_46877d20c6ac4383d03a11d6_1', 'IM-G8-U9-L3',
    % The pentagon rotated 120 and 240 degrees about one vertex: three
    % copies close the full turn.
    unknown_angle_from_a_whole,
    _{kind: "angle_parts", whole: 360, known: [120, 120]},
    remaining_angle("120")).
g8_polygon_angle_receipt(
    'im_defrag_dd662bdd6d087a65973b6dee_1', 'IM-G8-U1-L15',
    % Tyler's three right angles against a triangle's 180 degrees.
    unknown_angle_from_a_whole,
    _{kind: "angle_parts", whole: 180, known: [90, 90, 90]},
    refused(known_parts_fill_or_exceed_the_whole)).

% ==========================================================================
% 7. CHECK
% ==========================================================================

check_g8_polygon_angle_and_tessellation :-
    check_receipts,
    check_tessellation_boundary,
    check_negative,
    format('g8_polygon_angle_and_tessellation: all checks ok~n').

check_receipts :-
    findall(Lesson-Row-Doing-Result,
            ( g8_polygon_angle_receipt(Row, Lesson, Doing, Json, Expected),
              g8_polygon_angle_from_json(Json, Figure),
              run_g8_polygon_angle(Doing, Figure, Outcome, _),
              outcome_property(Outcome, result(Result)),
              Result = Expected,
              outcome_property(Outcome, validity(V)),
              memberchk(V, [correct, refused])
            ), Rows),
    findall(R-L, g8_polygon_angle_receipt(R, L, _, _, _), All),
    length(All, Total), length(Rows, Passed),
    Total =:= Passed,
    format('  receipts: ~w/~w real grade 8 rows run, each closing its triangulation or its full turn~n',
           [Passed, Total]),
    forall(member(Lesson-Row-Doing-Result, Rows),
           format('    ~w  ~w  ~w -> ~q~n', [Lesson, Row, Doing, Result])).

check_tessellation_boundary :-
    % Exactly three regular polygons tile the plane, and the pilot finds
    % those three and no others between 3 and 20 sides.
    findall(N, ( between(3, 20, N),
                 g8_polygon_angle_from_json(
                     _{kind: "regular_polygon", sides: N}, F),
                 run_g8_polygon_angle(regular_tessellation_test, F, O, _),
                 outcome_property(O, result(tessellates(_)))
               ), Tiling),
    Tiling == [3, 4, 6],
    format('  tessellation boundary: between 3 and 20 sides only 3, 4, and 6 tile the plane~n').

check_negative :-
    % Two sides is not a polygon and refuses by contract.
    \+ g8_polygon_angle_from_json(_{kind: "regular_polygon", sides: 2}, _),
    % The pentagon's quotient is 10/3, and it is never rounded to 3: a
    % rounded count would claim a closure that leaves a gap of 36 degrees.
    g8_polygon_angle_from_json(
        _{kind: "regular_polygon", sides: 5, name: "pentagon"}, P),
    run_g8_polygon_angle(copies_around_a_vertex, P, O, _),
    outcome_property(O, result(no_whole_number_of_copies("10/3"))),
    outcome_property(O, interior_angle("108")),
    Gap is 360 - 3 * 108, Gap =:= 36,
    format('  negative tests: two sides refuse; the pentagon reports 10/3 copies rather than 3, and the gap it names is 36 degrees~n').

outcome_property(action_outcome(_, Props), Property) :-
    memberchk(Property, Props).
