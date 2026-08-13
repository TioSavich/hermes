:- encoding(utf8).
/** <module> K-7 pilot: fractions combined over a common unit, drawn on a partitioned line
 *
 * WHAT THIS IS. A quarantined scene-emission sibling for the K-7 doing that
 * combines two fractions by first finding a unit both can be counted in. It
 * runs the EXISTING machines through
 * `action_automata_registry:run_action_automaton/6`, modifies none of them,
 * and adds a scene in the coordinate-plane grapher's own JSON genre
 * (`hermes/web/coordinate-plane`, schema version 1): a line partitioned into
 * that common unit, with each addend laid off along it as a hop.
 *
 * WHY IT EXISTS. Grade 4's own rows ask for the picture — IM-G4-U3-L16 reads
 * "Find the value of each sum. Show your reasoning. Use number lines if you
 * find them helpful" — and the machine those rows route to returns a fraction
 * and nothing else. The partition is not decoration on the sum: the whole
 * content of `co_measure(unit_fraction(1,6), 4, 3)` is that two fractions
 * stated in thirds and halves became four sixths and three sixths, and the
 * drawing that carries it is the line cut into sixths.
 *
 * WHY BOTH DRAWINGS. `add_numerator_denominator_sum` adds the numerators and
 * adds the denominators, reaching the mediant. Drawn, the mediant lands
 * BETWEEN the two addends while the sum lands beyond both of them, and that
 * one picture says why the reading cannot be a sum without anyone being told
 * it is wrong. The existing machine already computes the betweenness fact;
 * this pilot draws it and checks it exactly on rationals.
 *
 * WHERE THE PARTITION IS NOT DRAWN. A common unit of one hundredth would put
 * two hundred ticks on a line. Past 40 ticks this pilot draws the landings and
 * records `partition_ticks_omitted` with the count it declined to draw,
 * rather than emitting a picture nobody can count. The mediant reading
 * constructs no common unit at all — its own trace says
 * `no_common_unit_constructed` — so no partition is drawn there either, and
 * for the same reason: there is none.
 *
 * EXACT, NOT PLOTTED. Every landing is an exact rational. Comparisons that
 * decide anything — betweenness, the final landing against the machine's own
 * result — run on rationals. Floats appear only in the emitted scene.
 *
 * QUARANTINE. Nothing imports this module. It modifies no machine, no
 * transition table, no input contract, and no state-vocabulary row.
 * Check: `check_k7_fraction_number_line/0`.
 */

:- module(k7_fraction_number_line,
          [ run_k7_fraction_number_line/4,
            k7_fraction_line_from_json/2,
            k7_fraction_line_states/1,
            k7_fraction_line_state_label/4,
            k7_fraction_line_summary/1,
            k7_fraction_line_receipt/6,
            k7_fraction_line_scene/2,
            check_k7_fraction_number_line/0
          ]).

:- use_module(strategies('math/action_automata_registry'),
              [ run_action_automaton/6 ]).
:- use_module(strategies('abstraction/k7_scene_common'),
              [ k7_scene_json/2, k7_render_scenes/1, k7_colour/2,
                k7_rational_text/2, k7_point/4, k7_labelled_point/5,
                k7_segment/6, k7_labelled_segment/7 ]).

% ==========================================================================
% 1. INPUT CONTRACT
%
%   {"kind":"fraction_number_line",
%    "doing":"common_denominator_fraction_addition",
%    "left":{"n":2,"d":3},"right":{"n":1,"d":2}}
%
%   Plain fractions only. Whole and mixed numbers reach the same machines and
%   are refused here, because this pilot has not settled how to draw a mixed
%   number's whole part without inventing a convention the curriculum did not
%   ask for.
% ==========================================================================

k7_fraction_line_input_contract(
    '{\"kind\":\"fraction_number_line\",\"doing\":\"string\",\"left\":{\"n\":\"integer\",\"d\":\"integer\"},\"right\":{\"n\":\"integer\",\"d\":\"integer\"}}',
    '{\"kind\":\"fraction_number_line\",\"doing\":\"common_denominator_fraction_addition\",\"left\":{\"n\":2,\"d\":3},\"right\":{\"n\":1,\"d\":2}}').

k7_fraction_line_from_json(Dict, fraction_line_task(Doing, Left, Right)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "fraction_number_line"),
    get_dict(doing, Dict, DoingText),
    atom_string(Doing, DoingText),
    k7_fraction_line_doing(Doing, _, _),
    get_dict(left, Dict, L), fraction_of(L, Left),
    get_dict(right, Dict, R), fraction_of(R, Right).

fraction_of(Dict, frac(N, D)) :-
    % A whole part is refused here rather than dropped: a mixed number that
    % quietly became a proper fraction would draw a line that answers a
    % different task.
    \+ get_dict(whole, Dict, _),
    get_dict(n, Dict, N), integer(N), N >= 0,
    get_dict(d, Dict, D), integer(D), D > 0.

%!  k7_fraction_line_doing(?Doing, ?Direction, ?Classification) is nondet.
k7_fraction_line_doing(common_denominator_fraction_addition, forward,
                       productive).
k7_fraction_line_doing(common_denominator_fraction_subtraction, backward,
                       productive).
k7_fraction_line_doing(add_numerator_denominator_sum, no_common_unit,
                       deformation).

doing_argument(common_denominator_fraction_addition, L, R,
               fraction_addend_pair(L, R)).
doing_argument(add_numerator_denominator_sum, L, R,
               fraction_addend_pair(L, R)).
doing_argument(common_denominator_fraction_subtraction, L, R,
               fraction_minuend_subtrahend(L, R)).

% ==========================================================================
% 2. STATES
% ==========================================================================

k7_fraction_line_states(
    [ q_read_the_two_fractions,
      q_run_the_existing_machine,
      q_read_the_common_unit_off_the_trace,
      q_check_the_landings_are_counts_of_that_unit,
      q_partition_the_line_into_the_common_unit,
      q_lay_each_fraction_off_as_a_hop,
      q_draw_the_student_reading_beside_it,
      q_accept_the_drawing,
      q_omit_a_partition_too_fine_to_draw ]).

k7_fraction_line_state_label(q_read_the_two_fractions,
    illustrative_mathematics,
    "the two fractions in the expression",
    "IM Grade 5 Unit 6 Lesson 8, Add and Subtract Fractions with Unlike Denominators").
k7_fraction_line_state_label(q_run_the_existing_machine, provisional,
    "run the machine that already enacts this doing",
    "provisional; names this pilot's own wrapping step, not a community term").
k7_fraction_line_state_label(q_read_the_common_unit_off_the_trace, steffe,
    "the common partition both fractions can be counted in",
    "Steffe & Olive 2010, Children's Fractional Knowledge, commensurate fractions; via knowledge/strategies/math/state_vocabulary.pl").
k7_fraction_line_state_label(q_check_the_landings_are_counts_of_that_unit,
    provisional,
    "check every landing is a whole count of the common unit",
    "provisional; no community label sourced for this checking step").
k7_fraction_line_state_label(q_partition_the_line_into_the_common_unit,
    illustrative_mathematics,
    "partition the number line into equal parts",
    "IM Grade 3 Unit 5 Lesson 9, Fractions on the Number Line").
k7_fraction_line_state_label(q_lay_each_fraction_off_as_a_hop,
    van_de_walle,
    "iterating the unit fraction along the line",
    "Van de Walle, ch. 15, Developing Fraction Concepts, iteration").
k7_fraction_line_state_label(q_draw_the_student_reading_beside_it,
    van_de_walle,
    "the student's own representation of the sum",
    "Van de Walle, ch. 15, Developing Fraction Concepts").
k7_fraction_line_state_label(q_accept_the_drawing, provisional,
    "the drawing the machine's own run produced",
    "provisional; names this pilot's output, not a community term").
k7_fraction_line_state_label(q_omit_a_partition_too_fine_to_draw, provisional,
    "record a partition too fine to draw rather than drawing it",
    "provisional; names this pilot's own drawable bound").

% ==========================================================================
% 3. TRANSITIONS
% ==========================================================================

k7_fraction_line_transition(draw_the_combination_on_a_partitioned_line,
    q_read_the_two_fractions, run_the_existing_machine,
    q_run_the_existing_machine).
k7_fraction_line_transition(draw_the_combination_on_a_partitioned_line,
    q_run_the_existing_machine, read_the_common_unit_off_the_trace,
    q_read_the_common_unit_off_the_trace).
k7_fraction_line_transition(draw_the_combination_on_a_partitioned_line,
    q_read_the_common_unit_off_the_trace,
    check_the_landings_are_counts_of_that_unit,
    q_check_the_landings_are_counts_of_that_unit).
k7_fraction_line_transition(draw_the_combination_on_a_partitioned_line,
    q_check_the_landings_are_counts_of_that_unit,
    partition_the_line_into_the_common_unit,
    q_partition_the_line_into_the_common_unit).
k7_fraction_line_transition(draw_the_combination_on_a_partitioned_line,
    q_partition_the_line_into_the_common_unit, lay_each_fraction_off_as_a_hop,
    q_lay_each_fraction_off_as_a_hop).
k7_fraction_line_transition(draw_the_combination_on_a_partitioned_line,
    q_lay_each_fraction_off_as_a_hop, accept_the_drawing, q_accept_the_drawing).
k7_fraction_line_transition(draw_the_combination_on_a_partitioned_line,
    q_read_the_common_unit_off_the_trace, draw_the_student_reading_beside_it,
    q_draw_the_student_reading_beside_it).
k7_fraction_line_transition(draw_the_combination_on_a_partitioned_line,
    q_partition_the_line_into_the_common_unit,
    omit_a_partition_too_fine_to_draw, q_omit_a_partition_too_fine_to_draw).

% ==========================================================================
% 4. THE RUN
% ==========================================================================

k7_drawable_tick_bound(40).

run_k7_fraction_number_line(draw_the_combination_on_a_partitioned_line,
                            fraction_line_task(Doing, Left, Right),
                            Outcome, Trace) :-
    k7_fraction_line_doing(Doing, Direction, Classification),
    doing_argument(Doing, Left, Right, Argument),
    run_action_automaton(fraction, Doing, Argument, unit(whole), Inner,
                         InnerTrace),
    Inner = action_outcome(Doing, Properties),
    memberchk(result(Result), Properties),
    line_reading(Doing, InnerTrace, Properties, Reading),
    landings_check(Reading, Result, CheckName, Verdict),
    ( Verdict == holds -> Validity0 = certified ; Validity0 = unvindicated ),
    memberchk(validity(MachineValidity), Properties),
    drawing_validity(Validity0, MachineValidity, Validity),
    partition_plan(Reading, Ticks, TickNote),
    scene(Doing, Classification, Reading, Ticks, Scene),
    reading_landings(Reading, LandingTexts),
    deformation_fields(Doing, Properties, Extra),
    Outcome = action_outcome(
        draw_the_combination_on_a_partitioned_line,
        [ classification(Classification),
          cluster(k7_fraction_number_line),
          automaton_state(q_accept_the_drawing),
          vocabulary([fraction, common_unit, unit_fraction, partition,
                      number_line, hop, landing, mediant]),
          input(fraction_line_task(Doing, Left, Right)),
          drawn_doing(Doing),
          wrapped_machine(fraction/Doing),
          direction(Direction),
          reading(Reading),
          landings(LandingTexts),
          partition(TickNote),
          landings_check(CheckName, Verdict),
          result(Result),
          scene(Scene),
          validity(Validity)
        | Extra ]),
    Trace = [ read_the_two_fractions(Left, Right),
              run_the_existing_machine(fraction/Doing),
              read_the_common_unit_off_the_trace(TickNote),
              check_the_landings_are_counts_of_that_unit(CheckName, Verdict),
              partition_the_line_into_the_common_unit(TickNote),
              lay_each_fraction_off_as_a_hop(LandingTexts),
              accept_the_drawing(Result) ].

drawing_validity(certified, MachineValidity, MachineValidity).
drawing_validity(unvindicated, _, unvindicated).

deformation_fields(Doing, Properties, Extra) :-
    memberchk(classification(deformation), Properties),
    !,
    memberchk(deformation_of(Productive), Properties),
    memberchk(expected(Expected), Properties),
    memberchk(misconception_family(Family), Properties),
    memberchk(violated_invariant(Invariant), Properties),
    attested_as(Doing, Row, Source),
    Extra = [ expected(Expected),
              deformation_of(Productive),
              misconception_family(Family),
              violated_invariant(Invariant),
              productive_partner(fraction/Productive),
              attested_as(Row, Source) ].
deformation_fields(_, _, []).

attested_as(add_numerator_denominator_sum,
    misconception_family(add_numerator_and_denominator),
    "Carried by knowledge/strategies/math/fraction_action_pairs.pl as the deformation partner of common_denominator_fraction_addition, with the betweenness of the mediant recorded per input.").

% --- reading the line off each machine's own trace ------------------------

%!  line_reading(+Doing, +Trace, +Properties, -Reading) is semidet.
line_reading(common_denominator_fraction_addition, Trace, _,
             common_unit_run(Unit, [hop(Zero, First, First),
                                    hop(First, Total, Second)],
                             counts(0, LeftCount, SumCount))) :-
    memberchk(hist(q_measure_with_co_unit,
                   co_measure(unit_fraction(1, Unit), LeftCount, RightCount)),
              Trace),
    memberchk(hist(q_combine_counts, combined(LeftCount, RightCount, SumCount)),
              Trace),
    Zero = 0,
    First is LeftCount rdiv Unit,
    Second is RightCount rdiv Unit,
    Total is SumCount rdiv Unit.
line_reading(common_denominator_fraction_subtraction, Trace, _,
             common_unit_run(Unit, [hop(Zero, Minuend, Minuend),
                                    hop(Minuend, Difference, Back)],
                             counts(0, MinuendCount, DiffCount))) :-
    memberchk(hist(q_measure_with_co_unit,
                   co_measure(unit_fraction(1, Unit), MinuendCount,
                              SubtrahendCount)),
              Trace),
    memberchk(hist(q_remove_counts,
                   removed(MinuendCount, SubtrahendCount, DiffCount)),
              Trace),
    Zero = 0,
    Minuend is MinuendCount rdiv Unit,
    Difference is DiffCount rdiv Unit,
    Back is -(SubtrahendCount rdiv Unit).
line_reading(add_numerator_denominator_sum, Trace, Properties,
             mediant_placement(LeftValue, RightValue, MediantValue, SumValue)) :-
    memberchk(hist(q_between_check,
                   record_betweenness(
                       mediant_lies_between(fraction(LN, LD), fraction(RN, RD),
                                            fraction(MN, MD)))),
              Trace),
    memberchk(expected(fraction(SN, SD)), Properties),
    LeftValue is LN rdiv LD,
    RightValue is RN rdiv RD,
    MediantValue is MN rdiv MD,
    SumValue is SN rdiv SD.

reading_landings(common_unit_run(_, Hops, _), Texts) :-
    findall(Text,
            ( member(hop(_, To, _), Hops), k7_rational_text(To, Text) ),
            Texts).
reading_landings(mediant_placement(L, R, M, S), [LT, RT, MT, ST]) :-
    k7_rational_text(L, LT), k7_rational_text(R, RT),
    k7_rational_text(M, MT), k7_rational_text(S, ST).

% --- the checks ----------------------------------------------------------

%!  landings_check(+Reading, +Result, -Name, -Verdict) is det.
%
%   For a run over a common unit: every landing is a whole count of that unit,
%   and the last landing is exactly the fraction the machine emitted. For the
%   mediant: it lies strictly between the two addends and the sum does not,
%   which is the fact the existing machine records and the drawing shows.
landings_check(common_unit_run(Unit, Hops, counts(_, _, LastCount)),
               fraction(N, D),
               every_landing_is_a_whole_count_of_the_common_unit, Verdict) :-
    Emitted is N rdiv D,
    last(Hops, hop(_, Last, _)),
    (   forall(member(hop(From, To, _), Hops),
               ( FromCount is From * Unit, integer(FromCount),
                 ToCount is To * Unit, integer(ToCount) )),
        Last =:= Emitted,
        LastCount =:= Last * Unit
    ->  Verdict = holds
    ;   Verdict = fails
    ).
landings_check(mediant_placement(Left, Right, Mediant, Sum), fraction(MN, MD),
               the_mediant_lands_between_the_addends_and_the_sum_beyond_them,
               Verdict) :-
    MediantValue is MN rdiv MD,
    Low is min(Left, Right), High is max(Left, Right),
    (   MediantValue =:= Mediant,
        Low < Mediant, Mediant < High,
        \+ ( Low < Sum, Sum < High )
    ->  Verdict = holds
    ;   Verdict = fails
    ).

% --- what partition to draw ----------------------------------------------

%!  partition_plan(+Reading, -Ticks, -Note) is det.
partition_plan(common_unit_run(Unit, Hops, _), Ticks, Note) :-
    findall(V, ( member(hop(F, T, _), Hops), member(V, [F, T]) ), Values),
    max_list(Values, High),
    Whole is max(1, ceiling(High)),
    Count is Whole * Unit,
    k7_drawable_tick_bound(Bound),
    (   Count + 1 =< Bound
    ->  findall(Value, ( between(0, Count, K), Value is K rdiv Unit ), Ticks),
        Total is Count + 1,
        Note = partition_drawn(unit_fraction(1, Unit), ticks(Total))
    ;   Ticks = [],
        Total is Count + 1,
        Note = partition_ticks_omitted(unit_fraction(1, Unit),
                                       ticks_declined(Total))
    ).
partition_plan(mediant_placement(_, _, _, _), [],
               no_partition_because_no_common_unit_was_constructed).

% ==========================================================================
% 5. THE DRAWING
% ==========================================================================

scene(Doing, Classification, common_unit_run(Unit, Hops, _), Ticks, Scene) :-
    findall(V, ( member(hop(F, T, _), Hops), member(V, [F, T]) ), Values),
    append(Values, Ticks, All),
    min_list(All, Low), max_list(All, High),
    k7_colour(structure, LineColour),
    k7_segment(Low, 0, High, 0, LineColour, Baseline),
    tick_points(Ticks, TickPoints),
    landing_points(Hops, LandingPoints),
    append(TickPoints, LandingPoints, Points),
    ( Classification == deformation
    -> k7_colour(student, HopColour) ; k7_colour(productive, HopColour) ),
    hop_segments(Hops, 1, HopColour, HopLines),
    Lines = [Baseline|HopLines],
    format(string(Id), "k7-fraction-line-~w", [Doing]),
    format(string(Title), "~w on a line cut into ~w equal parts",
           [Doing, Unit]),
    format(string(Description),
           "The line partitioned into unit fractions of one over ~w, with each fraction laid off along it as a hop.",
           [Unit]),
    Scene = scene{version: 1, id: Id, kind: "coordinate-plane",
                  title: Title, description: Description,
                  points: Points, lines: Lines}.
scene(Doing, _, mediant_placement(Left, Right, Mediant, Sum), _, Scene) :-
    Values = [0, Left, Right, Mediant, Sum],
    min_list(Values, Low), max_list(Values, High),
    k7_colour(structure, LineColour),
    k7_colour(productive, ProductiveColour),
    k7_colour(student, StudentColour),
    k7_segment(Low, 0, High, 0, LineColour, Baseline),
    named_point(Left, "first fraction", ProductiveColour, LeftPoint),
    named_point(Right, "second fraction", ProductiveColour, RightPoint),
    named_point(Mediant, "the reading that adds both parts", StudentColour,
                MediantPoint),
    named_point(Sum, "the sum", ProductiveColour, SumPoint),
    format(string(Id), "k7-fraction-line-~w", [Doing]),
    Title = "The mediant lands between the two fractions; the sum lands beyond them",
    Description = "No common unit was constructed, so the line carries no partition. Each fraction is placed where its exact value falls.",
    Scene = scene{version: 1, id: Id, kind: "coordinate-plane",
                  title: Title, description: Description,
                  points: [LeftPoint, RightPoint, MediantPoint, SumPoint],
                  lines: [Baseline]}.

named_point(Value, What, Colour, Point) :-
    k7_rational_text(Value, Text),
    format(string(Label), "~w (~w)", [Text, What]),
    k7_labelled_point(Value, 0, Label, Colour, Point).

tick_points([], []).
tick_points([V|T], [P|R]) :-
    k7_colour(structure, Colour),
    (   integer(V)
    ->  k7_rational_text(V, Label),
        k7_labelled_point(V, 0, Label, Colour, P)
    ;   k7_point(V, 0, Colour, P)
    ),
    tick_points(T, R).

landing_points([], []).
landing_points([hop(_, To, _)|T], [P|R]) :-
    k7_colour(landmark, Colour),
    k7_rational_text(To, Label),
    k7_labelled_point(To, 0, Label, Colour, P),
    landing_points(T, R).

hop_segments([], _, _, []).
hop_segments([hop(From, To, Delta)|T], Index, Colour, [Line|R]) :-
    k7_rational_text(Delta, DeltaText),
    ( Delta >= 0 -> format(string(Label), "+~w", [DeltaText])
    ; format(string(Label), "~w", [DeltaText]) ),
    k7_labelled_segment(From, Index, To, Index, Label, Colour, Line),
    Next is Index + 1,
    hop_segments(T, Next, Colour, R).

%!  k7_fraction_line_scene(+Outcome, -JSON) is semidet.
k7_fraction_line_scene(action_outcome(_, Properties), JSON) :-
    memberchk(scene(Scene), Properties),
    k7_scene_json(Scene, JSON).

:- use_module(library(lists), [max_list/2, min_list/2, last/2]).

% ==========================================================================
% 6. SELF-SUMMARY
% ==========================================================================

k7_fraction_line_summary(
    summary{ module: k7_fraction_number_line,
             status: authored_pilot,
             generated: false,
             grades: 'K-7',
             cluster: k7_fraction_number_line,
             doings: [draw_the_combination_on_a_partitioned_line],
             wraps: [ fraction/common_denominator_fraction_addition,
                      fraction/common_denominator_fraction_subtraction,
                      fraction/add_numerator_denominator_sum ],
             modifies_wrapped_machines: false,
             verification: [ every_landing_is_a_whole_count_of_the_common_unit,
                             the_last_landing_equals_the_emitted_fraction_exactly,
                             the_mediant_lands_between_the_addends_and_the_sum_beyond,
                             scene_renders_through_the_coordinate_plane_grapher ],
             arithmetic: exact_rational,
             renderer: 'hermes/web/coordinate-plane/grapher.js (schema version 1)',
             deformation_draws_too: true,
             drawable_tick_bound: 40,
             takes: plain_fractions_only,
             imported_by: none }).

% ==========================================================================
% 7. RECEIPTS
% ==========================================================================

% k7_fraction_line_receipt(Row, Lesson, Doing, InputJSONDict, Result, Note).
k7_fraction_line_receipt(
    'im_defrag_23f12955ada40f6b81b04ea6_1', 'IM-G5-U6-L8',
    common_denominator_fraction_addition,
    _{kind: "fraction_number_line",
      doing: "common_denominator_fraction_addition",
      left: _{n: 2, d: 3}, right: _{n: 1, d: 2}},
    fraction(7, 6), row_numbers).
k7_fraction_line_receipt(
    'im_defrag_c104cf4da30c3fa8ab306077_1', 'IM-G5-U6-L8',
    common_denominator_fraction_addition,
    _{kind: "fraction_number_line",
      doing: "common_denominator_fraction_addition",
      left: _{n: 3, d: 4}, right: _{n: 1, d: 2}},
    fraction(5, 4), row_numbers).
k7_fraction_line_receipt(
    'im_defrag_511e4b9a6d00ee4ab500386d_1', 'IM-G5-U6-L13',
    common_denominator_fraction_addition,
    _{kind: "fraction_number_line",
      doing: "common_denominator_fraction_addition",
      left: _{n: 1, d: 8}, right: _{n: 5, d: 8}},
    fraction(6, 8), row_numbers).
k7_fraction_line_receipt(
    'im_defrag_38ca67cc9064abfdeeb8005b_1', 'IM-G5-U8-L10',
    common_denominator_fraction_addition,
    _{kind: "fraction_number_line",
      doing: "common_denominator_fraction_addition",
      left: _{n: 2, d: 12}, right: _{n: 1, d: 6}},
    fraction(4, 12), row_numbers).
k7_fraction_line_receipt(
    'im_defrag_d7f8509b72a2ee85f695273d_1', 'IM-G5-U8-L10',
    common_denominator_fraction_addition,
    _{kind: "fraction_number_line",
      doing: "common_denominator_fraction_addition",
      left: _{n: 1, d: 3}, right: _{n: 1, d: 2}},
    fraction(5, 6), row_numbers).
% IM-G4-U3-L16 asks for the number line in its own words: "Use number lines
% if you find them helpful." Its common unit is one hundredth, so the
% partition is recorded rather than drawn.
k7_fraction_line_receipt(
    'im_defrag_75b2abcf7a5b2d68479143ba_1', 'IM-G4-U3-L16',
    common_denominator_fraction_addition,
    _{kind: "fraction_number_line",
      doing: "common_denominator_fraction_addition",
      left: _{n: 1, d: 10}, right: _{n: 50, d: 100}},
    fraction(60, 100), row_asks_for_the_number_line).
k7_fraction_line_receipt(
    'im_defrag_8cfebfc29a68b17e433c4e06_1', 'IM-G5-U8-L11',
    common_denominator_fraction_subtraction,
    _{kind: "fraction_number_line",
      doing: "common_denominator_fraction_subtraction",
      left: _{n: 2, d: 3}, right: _{n: 1, d: 6}},
    fraction(3, 6), row_numbers).
k7_fraction_line_receipt(
    'im_defrag_b4385fc3222ef8e202583213_1', 'IM-G5-U6-L8',
    common_denominator_fraction_subtraction,
    _{kind: "fraction_number_line",
      doing: "common_denominator_fraction_subtraction",
      left: _{n: 5, d: 6}, right: _{n: 1, d: 3}},
    fraction(3, 6), row_numbers).
k7_fraction_line_receipt(
    'im_defrag_ec48ac51ade1641d39510a6f_1', 'IM-G5-U6-L8',
    common_denominator_fraction_subtraction,
    _{kind: "fraction_number_line",
      doing: "common_denominator_fraction_subtraction",
      left: _{n: 2, d: 3}, right: _{n: 1, d: 6}},
    fraction(3, 6), row_numbers).
k7_fraction_line_receipt(
    'im_defrag_1702e20a054962d488e96e8b_1', 'IM-G5-U6-L10',
    common_denominator_fraction_subtraction,
    _{kind: "fraction_number_line",
      doing: "common_denominator_fraction_subtraction",
      left: _{n: 3, d: 4}, right: _{n: 2, d: 5}},
    fraction(7, 20), row_numbers).
% The mediant reading is a machine that already exists; these rows supply its
% numbers. The rows do not attest that a student made this reading.
k7_fraction_line_receipt(
    'im_defrag_23f12955ada40f6b81b04ea6_1', 'IM-G5-U6-L8',
    add_numerator_denominator_sum,
    _{kind: "fraction_number_line",
      doing: "add_numerator_denominator_sum",
      left: _{n: 2, d: 3}, right: _{n: 1, d: 2}},
    fraction(3, 5), machine_exists_row_supplies_numbers).
k7_fraction_line_receipt(
    'im_defrag_c104cf4da30c3fa8ab306077_1', 'IM-G5-U6-L8',
    add_numerator_denominator_sum,
    _{kind: "fraction_number_line",
      doing: "add_numerator_denominator_sum",
      left: _{n: 3, d: 4}, right: _{n: 1, d: 2}},
    fraction(4, 6), machine_exists_row_supplies_numbers).

% ==========================================================================
% 8. CHECK
% ==========================================================================

check_k7_fraction_number_line :-
    check_receipts,
    check_scenes_render,
    check_partition_counted_off_the_scene,
    check_the_mediant_draws_too,
    check_negative,
    format('k7_fraction_number_line: all checks ok~n').

check_receipts :-
    findall(Lesson-Row-Result,
            ( k7_fraction_line_receipt(Row, Lesson, Doing, Json, Result, _),
              k7_fraction_line_from_json(Json, Task),
              Task = fraction_line_task(Doing, _, _),
              run_k7_fraction_number_line(
                  draw_the_combination_on_a_partitioned_line, Task, Outcome, _),
              outcome_property(Outcome, drawn_doing(Doing)),
              outcome_property(Outcome, result(Result)),
              outcome_property(Outcome, landings_check(_, holds))
            ), Passed),
    findall(R, k7_fraction_line_receipt(R, _, _, _, _, _), All),
    length(All, Total), length(Passed, Count),
    Total =:= Count,
    format('  receipts: ~w/~w combinations drawn, every landing a whole count of the common unit~n',
           [Count, Total]),
    forall(member(Lesson-Row-Result, Passed),
           format('    ~w  ~w  ~q~n', [Lesson, Row, Result])).

check_scenes_render :-
    findall(JSON,
            ( k7_fraction_line_receipt(_, _, _, Json, _, _),
              k7_fraction_line_from_json(Json, Task),
              run_k7_fraction_number_line(
                  draw_the_combination_on_a_partitioned_line, Task, Outcome, _),
              k7_fraction_line_scene(Outcome, JSON)
            ), Scenes),
    length(Scenes, Count),
    k7_render_scenes(Scenes),
    format('  drawings: ~w scenes rendered through hermes/web/coordinate-plane without error~n',
           [Count]).

check_partition_counted_off_the_scene :-
    % Two thirds and one half meet in sixths, and the sum passes one, so the
    % line runs to two and carries thirteen ticks. Counted off the dict.
    k7_fraction_line_from_json(
        _{kind: "fraction_number_line",
          doing: "common_denominator_fraction_addition",
          left: _{n: 2, d: 3}, right: _{n: 1, d: 2}}, T),
    run_k7_fraction_number_line(draw_the_combination_on_a_partitioned_line, T,
                                O, _),
    outcome_property(O, partition(partition_drawn(unit_fraction(1, 6),
                                                  ticks(13)))),
    outcome_property(O, scene(Scene)),
    get_dict(points, Scene, Points), length(Points, 15),
    get_dict(lines, Scene, Lines), length(Lines, 3),
    outcome_property(O, landings(["2/3", "7/6"])),
    % One hundredth is too fine to draw, and the pilot says so with the count
    % it declined rather than emitting two hundred ticks.
    k7_fraction_line_from_json(
        _{kind: "fraction_number_line",
          doing: "common_denominator_fraction_addition",
          left: _{n: 1, d: 10}, right: _{n: 50, d: 100}}, F),
    run_k7_fraction_number_line(draw_the_combination_on_a_partitioned_line, F,
                                FO, _),
    outcome_property(FO, partition(partition_ticks_omitted(
                                       unit_fraction(1, 100),
                                       ticks_declined(101)))),
    format('  the partition is countable where it is drawn: thirteen sixths ticks for 2/3 + 1/2, and one hundred and one declined for 1/10 + 50/100~n').

check_the_mediant_draws_too :-
    % Adding both parts of 2/3 and 1/2 reaches 3/5, which lands BETWEEN them,
    % while the sum 7/6 lands beyond both. Both facts are checked on exact
    % rationals and both are drawn.
    k7_fraction_line_from_json(
        _{kind: "fraction_number_line",
          doing: "add_numerator_denominator_sum",
          left: _{n: 2, d: 3}, right: _{n: 1, d: 2}}, T),
    run_k7_fraction_number_line(draw_the_combination_on_a_partitioned_line, T,
                                O, _),
    outcome_property(O, classification(deformation)),
    outcome_property(O, result(fraction(3, 5))),
    outcome_property(O, expected(fraction(7, 6))),
    outcome_property(O, validity(incorrect)),
    outcome_property(O, landings_check(_, holds)),
    outcome_property(O, partition(
        no_partition_because_no_common_unit_was_constructed)),
    outcome_property(O, productive_partner(
        fraction/common_denominator_fraction_addition)),
    outcome_property(O, attested_as(_, _)),
    outcome_property(O, scene(Scene)),
    get_dict(points, Scene, Points), length(Points, 4),
    format('  the deformation draws too: 3/5 placed between 1/2 and 2/3, with the sum 7/6 beyond both, and no partition drawn because none was built~n').

check_negative :-
    % A mixed number reaches the same machine and is refused here, because
    % this pilot has no drawing convention for the whole part.
    \+ k7_fraction_line_from_json(
           _{kind: "fraction_number_line",
             doing: "common_denominator_fraction_addition",
             left: _{whole: 1, n: 5, d: 8}, right: _{n: 6, d: 8}}, _),
    % A zero denominator refuses at decode.
    \+ k7_fraction_line_from_json(
           _{kind: "fraction_number_line",
             doing: "common_denominator_fraction_addition",
             left: _{n: 1, d: 0}, right: _{n: 1, d: 2}}, _),
    % A doing this pilot does not wrap refuses at decode.
    \+ k7_fraction_line_from_json(
           _{kind: "fraction_number_line", doing: "long_division",
             left: _{n: 1, d: 2}, right: _{n: 1, d: 2}}, _),
    % The landings check discriminates: a landing that is not a whole count of
    % the common unit fails it.
    landings_check(common_unit_run(6, [hop(0, 2 rdiv 3, 2 rdiv 3),
                                       hop(2 rdiv 3, 5 rdiv 4, 7 rdiv 12)],
                                   counts(0, 4, 7)),
                   fraction(7, 6), _, fails),
    format('  negative tests: a mixed number, a zero denominator and an unwrapped doing refuse at decode; a landing off the common unit fails the landings check~n').

outcome_property(action_outcome(_, Props), Property) :-
    memberchk(Property, Props).
