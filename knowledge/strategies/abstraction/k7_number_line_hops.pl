:- encoding(utf8).
/** <module> K-7 pilot: what runs along a line, drawn as hops
 *
 * WHAT THIS IS. A quarantined scene-emission sibling for the K-7 doings whose
 * enactment is a run along a number line: counting on from an addend, counting
 * all from zero, counting up to a target, taking a subtrahend away in chunks,
 * and removing a group size until nothing is left. It runs the EXISTING
 * machines through `action_automata_registry:run_action_automaton/6`, modifies
 * none of them, and adds one thing they do not carry: a scene in the
 * coordinate-plane grapher's own JSON genre (`hermes/web/coordinate-plane`,
 * schema version 1) that draws the run as hops over a line.
 *
 * WHY IT EXISTS. Of the 1,811 usable K-7 rows in the defrag pool, 1,781 come
 * back from the row map with the same note: "number-line jump trace is not
 * available for this strategy's step shape". The rows run to a correct result
 * and draw nothing. The existing extractor reads a running value out of a
 * history's state term; these machines instead publish their doing in named
 * TRACE terms — `count_up_by_ones([16,17,18,19,20])` says where every hop
 * lands — and a scene read off those terms needs no state-shape guessing.
 *
 * WHY BOTH DRAWINGS. A teacher works with a student's thinking, which arrived
 * in some spatial form of its own. So a deformation draws too, and it draws
 * beside the productive run rather than instead of it: the student's hops sit
 * above the line, the run the machine certifies sits below it, and the line is
 * shared. `count_all_when_count_on_available` therefore shows seven hops from
 * zero above two hops from five below, which is the whole difference between
 * the two readings in one picture.
 *
 * EXACT, NOT PLOTTED. Every landing is the integer the machine itself named.
 * The scene carries floats only because the renderer's schema takes numbers,
 * and they are built from the integers at the last step. Nothing in the
 * verification consults a float.
 *
 * WHAT THE CHECK PROVES. For every receipt: (1) the hops compose — the first
 * starts where the machine started, each lands where the next begins, the last
 * lands where the machine ended; (2) a named quantity of the doing equals a
 * quantity summed off the scene, which differs per doing and is recorded as
 * the doing's hop invariant; (3) every hop segment in the scene has the exact
 * endpoints of its trace step, so the drawing carries no hop the machine did
 * not take; (4) the scene renders through `grapher.js` under Node.
 *
 * REFUSALS, NAMED. Two of them. A run of more than 40 hops is refused rather
 * than drawn: a hundred tick marks is not a drawing a teacher uses, and
 * pretending otherwise would put a picture where a refusal belongs. A run that
 * moves nowhere — kindergarten's "3 + 0" — is refused for the opposite
 * reason: the machine is right and there is no hop to draw.
 *
 * QUARANTINE. Nothing imports this module. It modifies no machine, no
 * transition table, no input contract, and no state-vocabulary row.
 * Check: `check_k7_number_line_hops/0`.
 */

:- module(k7_number_line_hops,
          [ run_k7_number_line_hops/4,
            k7_hops_from_json/2,
            k7_hops_states/1,
            k7_hops_state_label/4,
            k7_hops_summary/1,
            k7_hops_receipt/6,
            k7_hops_scene/2,
            check_k7_number_line_hops/0
          ]).

:- use_module(strategies('math/action_automata_registry'),
              [ run_action_automaton/6 ]).
:- use_module(strategies('abstraction/k7_scene_common'),
              [ k7_scene_json/2, k7_render_scenes/1, k7_colour/2,
                k7_labelled_point/5, k7_labelled_segment/7, k7_segment/6 ]).
:- use_module(library(lists), [nth1/3, max_list/2, min_list/2, sum_list/2]).

% ==========================================================================
% 1. INPUT CONTRACT
%
%   {"kind":"number_line_hops","doing":"count_on_from_larger","a":5,"b":2}
%
%   `doing` names an EXISTING registry automaton. `a` and `b` are the row's
%   own two numbers in that automaton's own order.
% ==========================================================================

k7_hops_input_contract(
    '{\"kind\":\"number_line_hops\",\"doing\":\"string\",\"a\":\"integer\",\"b\":\"integer\"}',
    '{\"kind\":\"number_line_hops\",\"doing\":\"count_on_from_larger\",\"a\":5,\"b\":2}').

%!  k7_hops_from_json(+Dict, -Task) is semidet.
k7_hops_from_json(Dict, hop_task(Doing, Operation, A, B)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "number_line_hops"),
    get_dict(doing, Dict, DoingText),
    atom_string(Doing, DoingText),
    k7_hop_doing(Doing, Operation, _),
    get_dict(a, Dict, A), integer(A),
    get_dict(b, Dict, B), integer(B).

%!  k7_hop_doing(?Doing, ?Operation, ?Classification) is nondet.
%
%   The registry automata this pilot draws, with the registry domain each one
%   answers to. Every one of them exists already; this pilot authored none of
%   them and changed none of them.
k7_hop_doing(count_on_from_larger, addition, productive).
k7_hop_doing(count_all_when_count_on_available, addition, deformation).
k7_hop_doing(count_up_missing_addend, subtraction, productive).
k7_hop_doing(answer_as_endpoint_count_up, subtraction, deformation).
k7_hop_doing(take_away_base_ones, subtraction, productive).
k7_hop_doing(measure_groups_of_size, division, productive).

% ==========================================================================
% 2. STATES
% ==========================================================================

k7_hops_states(
    [ q_read_the_two_numbers,
      q_run_the_existing_machine,
      q_read_the_landings_off_the_trace,
      q_check_the_hops_compose,
      q_draw_the_line_and_the_hops,
      q_draw_the_student_run_beside_it,
      q_accept_the_drawing,
      q_refuse_too_many_hops ]).

% k7_hops_state_label(State, Tradition, Label, Citation).
k7_hops_state_label(q_read_the_two_numbers, illustrative_mathematics,
    "the numbers in the story",
    "IM Grade 1 Unit 2 Lesson 1, Add To and Put Together").
k7_hops_state_label(q_run_the_existing_machine, provisional,
    "run the machine that already enacts this doing",
    "provisional; names this pilot's own wrapping step, not a community term").
k7_hops_state_label(q_read_the_landings_off_the_trace, steffe,
    "the sequence of counting acts",
    "Steffe & Cobb 1988, Construction of Arithmetical Meanings and Strategies, counting sequences; via knowledge/strategies/math/state_vocabulary.pl").
k7_hops_state_label(q_check_the_hops_compose, provisional,
    "check the hops end where the machine ended",
    "provisional; no community label sourced for this checking step").
k7_hops_state_label(q_draw_the_line_and_the_hops, illustrative_mathematics,
    "show your thinking on a number line",
    "IM Grade 2 Unit 3, Measuring Length; number line diagrams").
k7_hops_state_label(q_draw_the_student_run_beside_it, van_de_walle,
    "the student's own representation of the count",
    "Van de Walle, ch. 8, Developing Early Number Concepts").
k7_hops_state_label(q_accept_the_drawing, provisional,
    "the drawing the machine's own run produced",
    "provisional; names this pilot's output, not a community term").
k7_hops_state_label(q_refuse_too_many_hops, provisional,
    "refuse a run too long to draw as hops",
    "provisional; names this pilot's own drawable bound").

% ==========================================================================
% 3. TRANSITIONS
% ==========================================================================

k7_hops_transition(draw_the_run_as_hops,
    q_read_the_two_numbers, run_the_existing_machine,
    q_run_the_existing_machine).
k7_hops_transition(draw_the_run_as_hops,
    q_run_the_existing_machine, read_the_landings_off_the_trace,
    q_read_the_landings_off_the_trace).
k7_hops_transition(draw_the_run_as_hops,
    q_read_the_landings_off_the_trace, check_the_hops_compose,
    q_check_the_hops_compose).
k7_hops_transition(draw_the_run_as_hops,
    q_check_the_hops_compose, draw_the_line_and_the_hops,
    q_draw_the_line_and_the_hops).
k7_hops_transition(draw_the_run_as_hops,
    q_draw_the_line_and_the_hops, accept_the_drawing, q_accept_the_drawing).
k7_hops_transition(draw_the_run_as_hops,
    q_draw_the_line_and_the_hops, draw_the_student_run_beside_it,
    q_draw_the_student_run_beside_it).
k7_hops_transition(draw_the_run_as_hops,
    q_read_the_landings_off_the_trace, refuse_too_many_hops,
    q_refuse_too_many_hops).

% ==========================================================================
% 4. THE RUN
% ==========================================================================

%   A run of more than this many hops is refused rather than drawn.
k7_drawable_hop_bound(40).

%!  run_k7_number_line_hops(+Doing, +Task, -Outcome, -Trace) is semidet.
run_k7_number_line_hops(draw_the_run_as_hops, hop_task(Doing, Operation, A, B),
                        Outcome, Trace) :-
    k7_hop_doing(Doing, Operation, Classification),
    run_action_automaton(Operation, Doing, A, B, Inner, InnerTrace),
    Inner = action_outcome(Doing, Properties),
    memberchk(result(Result), Properties),
    hop_reading(Doing, InnerTrace, Reading),
    Reading = reading(Hops, Zeros, Invariant),
    length(Hops, HopCount),
    k7_drawable_hop_bound(Bound),
    (   Hops == []
    ->  % Kindergarten's "3 + 0" runs correctly and moves nowhere. A picture
        %   of no hop is not a picture of the count, so this refuses by name
        %   rather than emitting a line with nothing on it.
        empty_run_refusal(Doing, A, B, Outcome, Trace)
    ;   HopCount > Bound
    ->  refusal_outcome(Doing, A, B, HopCount, Bound, Outcome, Trace)
    ;   hops_compose(Hops, Start, End, Composes),
        invariant_holds(Invariant, Hops, Result, InvariantName, InvariantVerdict),
        (   Composes == holds, InvariantVerdict == holds
        ->  Validity = correct
        ;   Validity = unvindicated
        ),
        partner_hops(Doing, Operation, A, B, PartnerHops, PartnerLabel),
        scene(Doing, Classification, Hops, PartnerHops, PartnerLabel, Scene),
        hop_texts(Hops, HopTexts),
        deformation_fields(Doing, Operation, A, B, Properties, Extra),
        Outcome = action_outcome(
            draw_the_run_as_hops,
            [ classification(Classification),
              cluster(k7_number_line_hops),
              automaton_state(q_accept_the_drawing),
              vocabulary([number_line, hop, landing, start_number, count,
                          distance, chunk, group_size]),
              input(hop_task(Doing, Operation, A, B)),
              drawn_doing(Doing),
              wrapped_machine(Operation/Doing),
              result(Result),
              hops(Hops),
              hop_texts(HopTexts),
              omitted_zero_hops(Zeros),
              hop_chain(from(Start), to(End), Composes),
              hop_invariant(InvariantName, InvariantVerdict),
              scene(Scene),
              validity(Validity)
            | Extra ]),
        Trace = [ read_the_two_numbers(A, B),
                  run_the_existing_machine(Operation/Doing),
                  read_the_landings_off_the_trace(HopTexts),
                  check_the_hops_compose(Start, End, Composes),
                  draw_the_line_and_the_hops(Scene),
                  accept_the_drawing(Result) ]
    ).

empty_run_refusal(Doing, A, B, Outcome, Trace) :-
    Outcome = action_outcome(
        draw_the_run_as_hops,
        [ classification(refusal),
          cluster(k7_number_line_hops),
          automaton_state(q_refuse_too_many_hops),
          vocabulary([number_line, hop, zero]),
          input(hop_task(Doing, _, A, B)),
          result(refused(the_run_moves_nowhere)),
          refusal(refusal{kind: "no_hop_to_draw_because_the_count_is_zero",
                          a: A, b: B}),
          validity(refused) ]),
    Trace = [ read_the_two_numbers(A, B),
              refuse_a_run_that_moves_nowhere(A, B) ].

refusal_outcome(Doing, A, B, HopCount, Bound, Outcome, Trace) :-
    Outcome = action_outcome(
        draw_the_run_as_hops,
        [ classification(refusal),
          cluster(k7_number_line_hops),
          automaton_state(q_refuse_too_many_hops),
          vocabulary([number_line, hop, drawable_bound]),
          input(hop_task(Doing, _, A, B)),
          result(refused(run_too_long_to_draw_as_hops)),
          refusal(refusal{kind: "hop_count_exceeds_drawable_bound",
                          hops: HopCount, bound: Bound}),
          validity(refused) ]),
    Trace = [ read_the_two_numbers(A, B),
              refuse_too_many_hops(HopCount, Bound) ].

% --- deformation bookkeeping ---------------------------------------------

deformation_fields(Doing, Operation, _A, _B, Properties, Extra) :-
    memberchk(classification(deformation), Properties),
    !,
    memberchk(deformation_of(Productive), Properties),
    memberchk(expected(Expected), Properties),
    memberchk(misconception_family(Family), Properties),
    attested_as(Doing, Row, Source),
    Extra = [ expected(Expected),
              deformation_of(Productive),
              misconception_family(Family),
              productive_partner(Operation/Productive),
              attested_as(Row, Source) ].
deformation_fields(_, _, _, _, _, []).

%!  attested_as(?Deformation, ?Row, ?Source) is nondet.
%
%   Where the corpus attests the reading this pilot draws. Nothing here is
%   invented: each row is the citation the existing deformation machine
%   already carries in the misconception registry, repeated so a reader of
%   this file can find it without leaving it.
attested_as(count_all_when_count_on_available,
    misconception_family(count_all_when_count_on_available),
    "Carried by knowledge/strategies/math/sar_add_action_pairs.pl as the deformation partner of count_on_from_larger; IM Grade 1 Unit 2 Lesson 2 names both readings in the task itself.").
attested_as(answer_as_endpoint_count_up,
    misconception_family(endpoint_as_difference),
    "Carried by knowledge/strategies/math/sar_sub_action_pairs.pl as the deformation partner of count_up_missing_addend.").

% --- reading the hops off each machine's own trace ------------------------

%!  hop_reading(+Doing, +Trace, -Reading) is semidet.
%
%   One clause per wrapped machine, each reading that machine's OWN named
%   trace terms. Nothing is inferred from a state shape; if a machine's trace
%   changes, this fails rather than guessing.
hop_reading(count_on_from_larger, Trace,
            reading(Hops, Zeros, counted_addend_equals_hop_total(Count))) :-
    memberchk(choose_larger_addend_as_start(Start), Trace),
    memberchk(hold_other_addend_as_count(Count), Trace),
    memberchk(iterate_successor_ticks(Ticks), Trace),
    chain_hops(Start, Ticks, Hops0),
    drop_zero_hops(Hops0, Hops, Zeros).
hop_reading(count_all_when_count_on_available, Trace,
            reading(Hops, Zeros, whole_sum_equals_hop_total(Sum))) :-
    memberchk(count_first_addend_from_zero(_, FirstTicks), Trace),
    memberchk(count_second_addend_from_first_total(_, SecondTicks), Trace),
    memberchk(preserve_result_but_lose_count_on_efficiency(Sum), Trace),
    append(FirstTicks, SecondTicks, Ticks),
    chain_hops(0, Ticks, Hops0),
    drop_zero_hops(Hops0, Hops, Zeros).
hop_reading(count_up_missing_addend, Trace,
            reading(Hops, Zeros, distance_equals_hop_total(Distance))) :-
    memberchk(start_at_subtrahend(Start), Trace),
    memberchk(count_up_by_bases(_, BaseTicks), Trace),
    memberchk(count_up_by_ones(OneTicks), Trace),
    memberchk(name_distance_not_endpoint(Distance, endpoint(_)), Trace),
    append(BaseTicks, OneTicks, Ticks),
    chain_hops(Start, Ticks, Hops0),
    drop_zero_hops(Hops0, Hops, Zeros).
hop_reading(answer_as_endpoint_count_up, Trace,
            reading(Hops, Zeros, endpoint_equals_last_landing(Endpoint))) :-
    memberchk(start_at_subtrahend(Start), Trace),
    memberchk(count_up_by_bases(_, BaseTicks), Trace),
    memberchk(count_up_by_ones(OneTicks), Trace),
    memberchk(name_endpoint_as_answer(Endpoint), Trace),
    append(BaseTicks, OneTicks, Ticks),
    chain_hops(Start, Ticks, Hops0),
    drop_zero_hops(Hops0, Hops, Zeros).
hop_reading(take_away_base_ones, Trace,
            reading(Hops, Zeros, subtrahend_equals_hop_total(Subtrahend))) :-
    memberchk(decompose_subtrahend(Subtrahend, _, base_chunk(_), ones_chunk(_)),
              Trace),
    memberchk(count_back_by_base_chunk(Minuend, _, Middle), Trace),
    memberchk(count_back_by_ones(Middle, _, Difference), Trace),
    chain_hops(Minuend, [Middle, Difference], Hops0),
    drop_zero_hops(Hops0, Hops, Zeros).
hop_reading(measure_groups_of_size, Trace,
            reading(Hops, Zeros, quotient_equals_hop_count(Quotient))) :-
    memberchk(repeatedly_remove_group_size(Total, _, Landings), Trace),
    memberchk(count_measured_groups(Quotient), Trace),
    chain_hops(Total, Landings, Hops0),
    drop_zero_hops(Hops0, Hops, Zeros).

%!  chain_hops(+Start, +Landings, -Hops) is det.
chain_hops(_, [], []).
chain_hops(From, [To|Rest], [hop(From, To, Delta)|Hops]) :-
    Delta is To - From,
    chain_hops(To, Rest, Hops).

drop_zero_hops([], [], 0).
drop_zero_hops([hop(_, _, 0)|T], Hops, Zeros) :-
    !,
    drop_zero_hops(T, Hops, Zeros0),
    Zeros is Zeros0 + 1.
drop_zero_hops([H|T], [H|Hops], Zeros) :-
    drop_zero_hops(T, Hops, Zeros).

% --- the two checks ------------------------------------------------------

%!  hops_compose(+Hops, -Start, -End, -Verdict) is det.
%
%   The chain is drawable as one run exactly when each hop lands where the
%   next one starts.
hops_compose([], 0, 0, fails) :- !.
hops_compose([hop(Start, To, _)|Rest], Start, End, Verdict) :-
    (   walk(Rest, To, End)
    ->  Verdict = holds
    ;   Verdict = fails, End = To
    ).

walk([], End, End).
walk([hop(From, To, _)|Rest], From, End) :-
    walk(Rest, To, End).

%!  invariant_holds(+Invariant, +Hops, +Result, -Name, -Verdict) is det.
%
%   Each doing names one quantity of its own that the scene must reproduce.
%   These are not restatements: an arithmetic slip anywhere in the landings
%   breaks them.
invariant_holds(counted_addend_equals_hop_total(Count), Hops, _,
                counted_addend_equals_hop_total, Verdict) :-
    hop_total(Hops, Total),
    ( Total =:= Count -> Verdict = holds ; Verdict = fails ).
invariant_holds(whole_sum_equals_hop_total(Sum), Hops, _,
                whole_sum_equals_hop_total, Verdict) :-
    hop_total(Hops, Total),
    ( Total =:= Sum -> Verdict = holds ; Verdict = fails ).
invariant_holds(distance_equals_hop_total(Distance), Hops, Result,
                distance_equals_hop_total, Verdict) :-
    hop_total(Hops, Total),
    ( Total =:= Distance, Result =:= Distance -> Verdict = holds
    ; Verdict = fails ).
invariant_holds(endpoint_equals_last_landing(Endpoint), Hops, Result,
                endpoint_equals_last_landing, Verdict) :-
    last(Hops, hop(_, Landing, _)),
    ( Landing =:= Endpoint, Result =:= Endpoint -> Verdict = holds
    ; Verdict = fails ).
invariant_holds(subtrahend_equals_hop_total(Subtrahend), Hops, _,
                subtrahend_equals_hop_total, Verdict) :-
    hop_total(Hops, Total),
    ( Total + Subtrahend =:= 0 -> Verdict = holds ; Verdict = fails ).
invariant_holds(quotient_equals_hop_count(Quotient), Hops, Result,
                quotient_equals_hop_count, Verdict) :-
    length(Hops, Count),
    (   Count =:= Quotient,
        Result = quotient_remainder(Quotient, _)
    ->  Verdict = holds
    ;   Verdict = fails
    ).

hop_total(Hops, Total) :-
    findall(D, member(hop(_, _, D), Hops), Deltas),
    sum_list(Deltas, Total).

% --- the partner run a deformation is drawn against ----------------------

%!  partner_hops(+Doing, +Operation, +A, +B, -Hops, -Label) is det.
%
%   A deformation is drawn beside the run the machine certifies, never alone.
%   The partner is the productive machine the deformation already declares as
%   its own; this pilot picks nothing.
partner_hops(Doing, Operation, A, B, Hops, Label) :-
    k7_hop_doing(Doing, Operation, deformation),
    run_action_automaton(Operation, Doing, A, B,
                         action_outcome(Doing, Properties), _),
    memberchk(deformation_of(Productive), Properties),
    k7_hop_doing(Productive, Operation, productive),
    run_action_automaton(Operation, Productive, A, B, _, PartnerTrace),
    hop_reading(Productive, PartnerTrace, reading(Hops, _, _)),
    !,
    format(string(Label), "~w", [Productive]).
partner_hops(_, _, _, _, [], "").

% ==========================================================================
% 5. THE DRAWING
% ==========================================================================

%!  scene(+Doing, +Classification, +Hops, +PartnerHops, +PartnerLabel, -Scene)
%
%   A coordinate-plane specification in the grapher's genre. The line itself
%   is one segment at y = 0 with a labelled point at every landing. Hop k is
%   one segment at height k, running from the value it left to the value it
%   reached — so the number of hop segments above the line is the number of
%   steps the machine took, and hop k's endpoints are step k's own numbers.
%   Where a partner run is drawn, its hops go below the line at height -k.
scene(Doing, Classification, Hops, PartnerHops, PartnerLabel, Scene) :-
    all_landings(Hops, PartnerHops, Landings),
    min_list(Landings, Low), max_list(Landings, High),
    k7_colour(structure, LineColour),
    k7_segment(Low, 0, High, 0, LineColour, Baseline),
    landing_points(Landings, Points),
    ( Classification == deformation
    -> k7_colour(student, HopColour) ; k7_colour(productive, HopColour) ),
    hop_segments(Hops, 1, HopColour, above, HopLines),
    k7_colour(productive, PartnerColour),
    hop_segments(PartnerHops, 1, PartnerColour, below, PartnerLines),
    append([[Baseline], HopLines, PartnerLines], Lines),
    format(string(Id), "k7-hops-~w", [Doing]),
    scene_title(Doing, Classification, PartnerLabel, Title, Description),
    Scene = scene{version: 1, id: Id, kind: "coordinate-plane",
                  title: Title, description: Description,
                  points: Points, lines: Lines}.

all_landings(Hops, PartnerHops, Landings) :-
    append(Hops, PartnerHops, All),
    findall(V, ( member(hop(F, T, _), All), member(V, [F, T]) ), Raw),
    sort(Raw, Landings).

landing_points([], []).
landing_points([V|T], [P|R]) :-
    k7_colour(landmark, Colour),
    format(string(Label), "~w", [V]),
    k7_labelled_point(V, 0, Label, Colour, P),
    landing_points(T, R).

hop_segments([], _, _, _, []).
hop_segments([hop(From, To, Delta)|T], Index, Colour, Side, [Line|R]) :-
    ( Side == above -> Height = Index ; Height is -Index ),
    delta_label(Delta, Label),
    k7_labelled_segment(From, Height, To, Height, Label, Colour, Line),
    Next is Index + 1,
    hop_segments(T, Next, Colour, Side, R).

delta_label(Delta, Label) :-
    ( Delta >= 0 -> format(string(Label), "+~w", [Delta])
    ; format(string(Label), "~w", [Delta]) ).

scene_title(Doing, deformation, Partner, Title, Description) :-
    !,
    format(string(Title), "~w, drawn beside ~w", [Doing, Partner]),
    format(string(Description),
           "Hops above the line are the run ~w takes. Hops below the line are the run ~w takes on the same two numbers.",
           [Doing, Partner]).
scene_title(Doing, _, _, Title, Description) :-
    format(string(Title), "~w on a number line", [Doing]),
    format(string(Description),
           "Each hop above the line is one step of ~w, drawn from the value it left to the value it reached.",
           [Doing]).

%!  k7_hops_scene(+Outcome, -JSON) is semidet.
k7_hops_scene(action_outcome(_, Properties), JSON) :-
    memberchk(scene(Scene), Properties),
    k7_scene_json(Scene, JSON).

hop_texts([], []).
hop_texts([hop(From, To, Delta)|T], [Text|R]) :-
    format(string(Text), "~w -> ~w (~w)", [From, To, Delta]),
    hop_texts(T, R).

% ==========================================================================
% 6. SELF-SUMMARY
% ==========================================================================

k7_hops_summary(
    summary{ module: k7_number_line_hops,
             status: authored_pilot,
             generated: false,
             grades: 'K-7',
             cluster: k7_number_line_hops,
             doings: [draw_the_run_as_hops],
             wraps: [ addition/count_on_from_larger,
                      addition/count_all_when_count_on_available,
                      subtraction/count_up_missing_addend,
                      subtraction/answer_as_endpoint_count_up,
                      subtraction/take_away_base_ones,
                      division/measure_groups_of_size ],
             modifies_wrapped_machines: false,
             verification: [ hops_compose_into_one_run,
                             named_quantity_equals_scene_total,
                             every_scene_hop_is_a_trace_step,
                             scene_renders_through_the_coordinate_plane_grapher ],
             arithmetic: exact_integer,
             renderer: 'hermes/web/coordinate-plane/grapher.js (schema version 1)',
             deformation_draws_too: true,
             drawable_hop_bound: 40,
             refuses: [run_longer_than_the_drawable_bound,
                       run_that_moves_nowhere],
             imported_by: none }).

% ==========================================================================
% 7. RECEIPTS
%
%   Every receipt is a usable K-7 row of
%   curriculum/im/generated/compiled_defragged_task_instances.pl, and both
%   numbers are the row's own.
% ==========================================================================

% k7_hops_receipt(Row, Lesson, Doing, InputJSONDict, ExpectedResult, Note).
k7_hops_receipt(
    'im_defrag_bf0427bcde79e25d5f18baa7_1', 'IM-G1-U2-L1',
    count_on_from_larger,
    _{kind: "number_line_hops", doing: "count_on_from_larger", a: 5, b: 2},
    7, row_numbers).
k7_hops_receipt(
    'im_defrag_402ec3f9f0e69e1126186afd_1', 'IM-G1-U3-L11',
    count_on_from_larger,
    _{kind: "number_line_hops", doing: "count_on_from_larger", a: 14, b: 3},
    17, row_numbers).
k7_hops_receipt(
    'im_defrag_53f8f9373add60adcd3f12c6_1', 'IM-G1-U2-L1',
    count_all_when_count_on_available,
    _{kind: "number_line_hops", doing: "count_all_when_count_on_available",
      a: 5, b: 2},
    7, row_is_itself_a_deformation_row).
k7_hops_receipt(
    'im_defrag_613727bd71ea0bd6f078183d_1', 'IM-G1-U2-L6',
    count_all_when_count_on_available,
    _{kind: "number_line_hops", doing: "count_all_when_count_on_available",
      a: 4, b: 5},
    9, row_is_itself_a_deformation_row).
k7_hops_receipt(
    'im_defrag_b099096220789cb705a8b867_1', 'IM-G1-U2-L2',
    count_all_when_count_on_available,
    _{kind: "number_line_hops", doing: "count_all_when_count_on_available",
      a: 6, b: 3},
    9, row_is_itself_a_deformation_row).
k7_hops_receipt(
    'im_defrag_c3b19ea158a97a0489308d4e_1', 'IM-G1-U1-L13',
    count_up_missing_addend,
    _{kind: "number_line_hops", doing: "count_up_missing_addend", a: 9, b: 2},
    7, row_numbers).
k7_hops_receipt(
    'im_defrag_167156ae0164a70f239f085e_1', 'IM-G1-U3-L24',
    count_up_missing_addend,
    _{kind: "number_line_hops", doing: "count_up_missing_addend", a: 20, b: 15},
    5, row_numbers).
k7_hops_receipt(
    'im_defrag_68000cf9e15d663af2cd6816_1', 'IM-G1-U2-L3',
    answer_as_endpoint_count_up,
    _{kind: "number_line_hops", doing: "answer_as_endpoint_count_up",
      a: 8, b: 6},
    8, row_is_itself_a_deformation_row).
k7_hops_receipt(
    'im_defrag_3b96c41762f6c6c518f631b2_1', 'IM-G1-U4-L12',
    take_away_base_ones,
    _{kind: "number_line_hops", doing: "take_away_base_ones", a: 39, b: 10},
    29, row_numbers).
k7_hops_receipt(
    'im_defrag_15f79d30806148c0693e9229_1', 'IM-G1-U4-L18',
    take_away_base_ones,
    _{kind: "number_line_hops", doing: "take_away_base_ones", a: 32, b: 20},
    12, row_numbers).
k7_hops_receipt(
    'im_defrag_affa8e52e5c9cd398ea73b0d_1', 'IM-G3-U4-L1',
    measure_groups_of_size,
    _{kind: "number_line_hops", doing: "measure_groups_of_size", a: 24, b: 8},
    quotient_remainder(3, 0), row_numbers).
k7_hops_receipt(
    'im_defrag_f8066b4c0286480b4ea69193_1', 'IM-G3-U4-L1',
    measure_groups_of_size,
    _{kind: "number_line_hops", doing: "measure_groups_of_size", a: 42, b: 6},
    quotient_remainder(7, 0), row_numbers).

% ==========================================================================
% 8. CHECK
% ==========================================================================

check_k7_number_line_hops :-
    check_receipts,
    check_scenes_render,
    check_scene_hops_are_trace_steps,
    check_deformations_draw_beside_the_productive_run,
    check_negative,
    format('k7_number_line_hops: all checks ok~n').

check_receipts :-
    findall(Lesson-Row-Result,
            ( k7_hops_receipt(Row, Lesson, Doing, Json, Result, _),
              k7_hops_from_json(Json, Task),
              Task = hop_task(Doing, _, _, _),
              run_k7_number_line_hops(draw_the_run_as_hops, Task, Outcome, _),
              outcome_property(Outcome, drawn_doing(Doing)),
              outcome_property(Outcome, result(Result)),
              outcome_property(Outcome, hop_chain(_, _, holds)),
              outcome_property(Outcome, hop_invariant(_, holds)),
              outcome_property(Outcome, validity(correct))
            ), Passed),
    findall(R, k7_hops_receipt(R, _, _, _, _, _), All),
    length(All, Total), length(Passed, Count),
    Total =:= Count,
    format('  receipts: ~w/~w runs drawn, every hop chain composing and every hop invariant holding~n',
           [Count, Total]),
    forall(member(Lesson-Row-Result, Passed),
           format('    ~w  ~w  ~q~n', [Lesson, Row, Result])).

check_scenes_render :-
    findall(JSON,
            ( k7_hops_receipt(_, _, _, Json, _, _),
              k7_hops_from_json(Json, Task),
              run_k7_number_line_hops(draw_the_run_as_hops, Task, Outcome, _),
              k7_hops_scene(Outcome, JSON)
            ), Scenes),
    length(Scenes, Count),
    k7_render_scenes(Scenes),
    format('  drawings: ~w scenes rendered through hermes/web/coordinate-plane without error~n',
           [Count]).

check_scene_hops_are_trace_steps :-
    % Every hop segment above the line carries the exact endpoints of its own
    % trace step, and there is exactly one such segment per step. A drawing
    % that added a hop, dropped one, or moved one would fail here.
    forall(( k7_hops_receipt(_, _, _, Json, _, _),
             k7_hops_from_json(Json, Task) ),
           ( run_k7_number_line_hops(draw_the_run_as_hops, Task, Outcome, _),
             outcome_property(Outcome, hops(Hops)),
             outcome_property(Outcome, scene(Scene)),
             get_dict(lines, Scene, Lines),
             length(Hops, HopCount),
             findall(F-T,
                     ( nth1(I, Hops, hop(_, _, _)),
                       nth1(N, Lines, Line), N =:= I + 1,
                       get_dict(from, Line, point{x: F, y: _}),
                       get_dict(to, Line, point{x: T, y: _}) ),
                     Drawn),
             length(Drawn, HopCount),
             forall(nth1(I, Hops, hop(From, To, _)),
                    ( nth1(I, Drawn, DF-DT),
                      DF =:= From, DT =:= To ))
           )),
    format('  every hop drawn is a step the machine took: endpoints matched one for one across all receipts~n').

check_deformations_draw_beside_the_productive_run :-
    % A deformation scene carries both runs: the student's hops above the
    % line and the machine's own below it. This is what lets a teacher put one
    % beside the other rather than replacing one with the other.
    k7_hops_from_json(
        _{kind: "number_line_hops", doing: "count_all_when_count_on_available",
          a: 5, b: 2}, Task),
    run_k7_number_line_hops(draw_the_run_as_hops, Task, Outcome, _),
    outcome_property(Outcome, classification(deformation)),
    outcome_property(Outcome, hops(StudentHops)),
    length(StudentHops, 7),
    outcome_property(Outcome, productive_partner(addition/count_on_from_larger)),
    outcome_property(Outcome, scene(Scene)),
    get_dict(lines, Scene, Lines),
    % one baseline, seven hops above, two hops below
    length(Lines, 10),
    findall(Y, ( member(L, Lines), get_dict(from, L, point{x: _, y: Y}), Y < 0 ),
            Below),
    length(Below, 2),
    outcome_property(Outcome, attested_as(_, _)),
    format('  the deformation draws too: seven hops from zero above the line, the two hops from five below it, one line shared~n').

check_negative :-
    % A run longer than the drawable bound refuses by name rather than
    % producing a picture nobody would use.
    k7_hops_from_json(
        _{kind: "number_line_hops", doing: "count_on_from_larger",
          a: 50, b: 45}, Long),
    run_k7_number_line_hops(draw_the_run_as_hops, Long, LongOutcome, _),
    outcome_property(LongOutcome, validity(refused)),
    outcome_property(LongOutcome, refusal(_)),
    % Kindergarten's "3 + 0" runs correctly and moves nowhere; a drawing of
    % no hop refuses by name.
    k7_hops_from_json(
        _{kind: "number_line_hops", doing: "count_on_from_larger",
          a: 3, b: 0}, Still),
    run_k7_number_line_hops(draw_the_run_as_hops, Still, StillOutcome, _),
    outcome_property(StillOutcome, validity(refused)),
    outcome_property(StillOutcome,
        refusal(refusal{kind: "no_hop_to_draw_because_the_count_is_zero",
                        a: 3, b: 0})),
    % A doing this pilot does not wrap is refused at decode, not guessed at.
    \+ k7_hops_from_json(
           _{kind: "number_line_hops", doing: "long_division", a: 24, b: 8}, _),
    % The hop chain check discriminates: a chain whose middle hop was moved
    % does not compose.
    \+ hops_compose([hop(5, 6, 1), hop(7, 8, 1)], _, _, holds),
    hops_compose([hop(5, 6, 1), hop(6, 7, 1)], 5, 7, holds),
    format('  negative tests: a 45-hop run and a run that moves nowhere refuse by name; an unwrapped doing refuses at decode; a broken chain does not compose~n').

outcome_property(action_outcome(_, Props), Property) :-
    memberchk(Property, Props).
