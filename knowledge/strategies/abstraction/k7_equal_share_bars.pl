:- encoding(utf8).
/** <module> K-7 pilot: fair shares, drawn as one bar per group
 *
 * WHAT THIS IS. A quarantined scene-emission sibling for the partitive
 * division doing: a total dealt out one at a time until every group holds the
 * same amount. It runs the EXISTING machines through
 * `action_automata_registry:run_action_automaton/6`, modifies none of them,
 * and adds a scene in the grapher's bar-chart genre
 * (`hermes/web/coordinate-plane`, schema version 1).
 *
 * WHY BARS AND NOT HOPS. Measurement division — "42 apples, 6 in each bag,
 * how many bags" — runs along a line and is drawn as hops by
 * `k7_number_line_hops`. Partitive division — "20 apples into 4 boxes, the
 * same number in each" — is not a run along anything. Its answer is a HEIGHT
 * repeated across groups, and the picture that carries the equality is one bar
 * per group standing at the same height. Every bar is a group and every unit
 * of height is one dealing round, so the drawing holds exactly what the
 * machine's `deal_one_to_each_group_by_rounds` step reports.
 *
 * WHY BOTH DRAWINGS. `name_group_count_as_share_size` answers with the number
 * of groups where the share size was asked for. Drawn, that is bars at the
 * wrong height, and the total they hold falls short of the amount there was
 * to deal — a shortfall this pilot computes exactly and reports. The student's
 * chart and the machine's chart are separate scenes, because a bar chart
 * carries one value per category and stacking a second reading into the same
 * bars would hide the disagreement rather than show it.
 *
 * WHERE THE TWO READINGS COINCIDE. At 36 into 6 groups the share size IS 6,
 * so the deformation and the machine agree, and the existing machine says so
 * itself: it returns `contextually_correct` rather than `incorrect` at that
 * input. This pilot carries that through — it draws one chart, records
 * `readings_coincide`, and does not manufacture a disagreement where the
 * numbers do not have one.
 *
 * EXACT, NOT PLOTTED. Every height is an integer the machine named. Floats
 * appear only in the emitted scene, because the renderer's schema takes
 * numbers.
 *
 * WHAT THE CHECK PROVES. For every receipt: (1) the number of bars equals the
 * number of groups the machine set; (2) every bar stands at the share the
 * machine named; (3) the bars together hold the amount there was to deal, and
 * where they do not, the shortfall is reported exactly and equals the
 * machine's own divergence; (4) the scene renders through `grapher.js` under
 * Node.
 *
 * QUARANTINE. Nothing imports this module. It modifies no machine, no
 * transition table, no input contract, and no state-vocabulary row.
 * Check: `check_k7_equal_share_bars/0`.
 */

:- module(k7_equal_share_bars,
          [ run_k7_equal_share_bars/4,
            k7_bars_from_json/2,
            k7_bars_states/1,
            k7_bars_state_label/4,
            k7_bars_summary/1,
            k7_bars_receipt/6,
            k7_bars_scene/2,
            k7_bars_partner_scene/2,
            check_k7_equal_share_bars/0
          ]).

:- use_module(strategies('math/action_automata_registry'),
              [ run_action_automaton/6 ]).
:- use_module(strategies('abstraction/k7_scene_common'),
              [ k7_scene_json/2, k7_render_scenes/1, k7_colour/2 ]).
:- use_module(library(lists), [sum_list/2]).

% ==========================================================================
% 1. INPUT CONTRACT
%
%   {"kind":"equal_share_bars","doing":"fair_share_equal_groups",
%    "total":20,"groups":4}
% ==========================================================================

k7_bars_input_contract(
    '{\"kind\":\"equal_share_bars\",\"doing\":\"string\",\"total\":\"integer\",\"groups\":\"integer\"}',
    '{\"kind\":\"equal_share_bars\",\"doing\":\"fair_share_equal_groups\",\"total\":20,\"groups\":4}').

k7_bars_from_json(Dict, bars_task(Doing, Total, Groups)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "equal_share_bars"),
    get_dict(doing, Dict, DoingText),
    atom_string(Doing, DoingText),
    k7_bars_doing(Doing, _),
    get_dict(total, Dict, Total), integer(Total), Total > 0,
    get_dict(groups, Dict, Groups), integer(Groups), Groups > 0,
    % A deal that does not come out even is not this doing; the extant machine
    % refuses it, and so does the decode.
    0 =:= Total mod Groups.

k7_bars_doing(fair_share_equal_groups, productive).
k7_bars_doing(name_group_count_as_share_size, deformation).

% ==========================================================================
% 2. STATES
% ==========================================================================

k7_bars_states(
    [ q_read_the_total_and_the_groups,
      q_run_the_existing_machine,
      q_read_the_share_off_the_trace,
      q_check_the_bars_hold_the_total,
      q_draw_one_bar_for_each_group,
      q_draw_the_student_shares_beside_them,
      q_accept_the_drawing,
      q_record_that_the_readings_coincide ]).

k7_bars_state_label(q_read_the_total_and_the_groups, illustrative_mathematics,
    "how many in all and how many groups",
    "IM Grade 3 Unit 4 Lesson 2, Represent Division").
k7_bars_state_label(q_run_the_existing_machine, provisional,
    "run the machine that already enacts this doing",
    "provisional; names this pilot's own wrapping step, not a community term").
k7_bars_state_label(q_read_the_share_off_the_trace, van_de_walle,
    "partition division: how many in each group",
    "Van de Walle, ch. 9, Developing Meanings for the Operations, partition division").
k7_bars_state_label(q_check_the_bars_hold_the_total, provisional,
    "check the bars together hold the amount there was to deal",
    "provisional; no community label sourced for this checking step").
k7_bars_state_label(q_draw_one_bar_for_each_group, illustrative_mathematics,
    "the same number in each group",
    "IM Grade 3 Unit 4 Lesson 3, Equal Groups").
k7_bars_state_label(q_draw_the_student_shares_beside_them, van_de_walle,
    "the student's own representation of the share",
    "Van de Walle, ch. 9, Developing Meanings for the Operations").
k7_bars_state_label(q_accept_the_drawing, provisional,
    "the drawing the machine's own run produced",
    "provisional; names this pilot's output, not a community term").
k7_bars_state_label(q_record_that_the_readings_coincide, hackenberg,
    "the deformation is contextually correct at this input",
    "the viability vocabulary of knowledge/strategies/math/state_vocabulary.pl; the extant machine returns contextually_correct where group count equals share size").

% ==========================================================================
% 3. TRANSITIONS
% ==========================================================================

k7_bars_transition(draw_the_shares_as_bars,
    q_read_the_total_and_the_groups, run_the_existing_machine,
    q_run_the_existing_machine).
k7_bars_transition(draw_the_shares_as_bars,
    q_run_the_existing_machine, read_the_share_off_the_trace,
    q_read_the_share_off_the_trace).
k7_bars_transition(draw_the_shares_as_bars,
    q_read_the_share_off_the_trace, check_the_bars_hold_the_total,
    q_check_the_bars_hold_the_total).
k7_bars_transition(draw_the_shares_as_bars,
    q_check_the_bars_hold_the_total, draw_one_bar_for_each_group,
    q_draw_one_bar_for_each_group).
k7_bars_transition(draw_the_shares_as_bars,
    q_draw_one_bar_for_each_group, accept_the_drawing, q_accept_the_drawing).
k7_bars_transition(draw_the_shares_as_bars,
    q_draw_one_bar_for_each_group, draw_the_student_shares_beside_them,
    q_draw_the_student_shares_beside_them).
k7_bars_transition(draw_the_shares_as_bars,
    q_read_the_share_off_the_trace, record_that_the_readings_coincide,
    q_record_that_the_readings_coincide).

% ==========================================================================
% 4. THE RUN
% ==========================================================================

k7_drawable_bar_bound(24).

run_k7_equal_share_bars(draw_the_shares_as_bars, bars_task(Doing, Total, Groups),
                        Outcome, Trace) :-
    k7_bars_doing(Doing, Classification),
    run_action_automaton(division, Doing, Total, Groups, Inner, InnerTrace),
    Inner = action_outcome(Doing, Properties),
    bars_reading(Doing, InnerTrace, Properties, Groups, Share, Named),
    k7_drawable_bar_bound(Bound),
    (   Groups > Bound
    ->  refusal_outcome(Doing, Total, Groups, Bound, Outcome, Trace)
    ;   Held is Groups * Named,
        Shortfall is Total - Held,
        k7_colour(productive, ProductiveColour),
        ( Classification == deformation
        -> k7_colour(student, BarColour) ; BarColour = ProductiveColour ),
        share_scene(Doing, Classification, Groups, Named, Total, BarColour,
                    Scene),
        partner_scene(Classification, Named, Share, Groups, Total,
                      ProductiveColour, PartnerFields),
        bars_check(Total, Groups, Named, Scene, CheckName, Verdict),
        ( Verdict == holds -> Validity0 = certified ; Validity0 = unvindicated ),
        memberchk(validity(MachineValidity), Properties),
        drawing_validity(Validity0, MachineValidity, Validity),
        coincidence(Named, Share, Coincidence),
        deformation_fields(Doing, Properties, Extra),
        append(PartnerFields, Extra, Tail),
        Outcome = action_outcome(
            draw_the_shares_as_bars,
            [ classification(Classification),
              cluster(k7_equal_share_bars),
              automaton_state(q_accept_the_drawing),
              vocabulary([total, number_of_groups, share_size, dealing_round,
                          equality, bar]),
              input(bars_task(Doing, Total, Groups)),
              drawn_doing(Doing),
              wrapped_machine(division/Doing),
              groups(Groups),
              share_the_machine_named(Named),
              share_the_deal_produces(Share),
              bars_hold(Held),
              amount_to_deal(Total),
              shortfall(Shortfall),
              readings(Coincidence),
              bars_check(CheckName, Verdict),
              scene(Scene),
              validity(Validity)
            | Tail ]),
        Trace = [ read_the_total_and_the_groups(Total, Groups),
                  run_the_existing_machine(division/Doing),
                  read_the_share_off_the_trace(Named),
                  check_the_bars_hold_the_total(Held, Total),
                  draw_one_bar_for_each_group(Scene),
                  accept_the_drawing(Named) ]
    ).

refusal_outcome(Doing, Total, Groups, Bound, Outcome, Trace) :-
    Outcome = action_outcome(
        draw_the_shares_as_bars,
        [ classification(refusal),
          cluster(k7_equal_share_bars),
          automaton_state(q_read_the_share_off_the_trace),
          vocabulary([number_of_groups, bar, drawable_bound]),
          input(bars_task(Doing, Total, Groups)),
          result(refused(too_many_groups_to_draw_as_bars)),
          refusal(refusal{kind: "group_count_exceeds_drawable_bound",
                          groups: Groups, bound: Bound}),
          validity(refused) ]),
    Trace = [ read_the_total_and_the_groups(Total, Groups),
              refuse_too_many_bars(Groups, Bound) ].

%   A drawing that checks out does not overturn the machine's own verdict on
%   the reading it drew; the machine's verdict is carried through.
drawing_validity(certified, MachineValidity, MachineValidity).
drawing_validity(unvindicated, _, unvindicated).

coincidence(Named, Share, readings_coincide) :- Named =:= Share, !.
coincidence(_, _, readings_part_company).

deformation_fields(Doing, Properties, Extra) :-
    memberchk(classification(deformation), Properties),
    !,
    memberchk(deformation_of(Productive), Properties),
    memberchk(misconception_family(Family), Properties),
    attested_as(Doing, Row, Source),
    Extra = [ deformation_of(Productive),
              misconception_family(Family),
              productive_partner(division/Productive),
              attested_as(Row, Source) ].
deformation_fields(_, _, []).

attested_as(name_group_count_as_share_size,
    misconception_family(group_count_as_share_size),
    "Carried by knowledge/strategies/math/smr_div_action_pairs.pl as the deformation partner of fair_share_equal_groups, with its own viability context per input.").

% --- reading the share off each machine's own trace -----------------------

%!  bars_reading(+Doing, +Trace, +Properties, +Groups, -Share, -Named) is semidet.
%
%   `Share` is what the deal produces; `Named` is what the run being drawn
%   answers with. They differ exactly where a deformation parts company from
%   the deal.
bars_reading(fair_share_equal_groups, Trace, Properties, Groups, Share, Share) :-
    memberchk(set_number_of_groups(Groups), Trace),
    memberchk(name_items_per_group(Share), Trace),
    memberchk(preserve_equal_shares(Groups, Share), Trace),
    memberchk(result(Share), Properties).
bars_reading(name_group_count_as_share_size, Trace, Properties, Groups, Share,
             Named) :-
    memberchk(set_number_of_groups(Groups), Trace),
    memberchk(name_group_count_as_answer(Named), Trace),
    memberchk(lose_items_per_group(expected(Share), produced(Named)), Trace),
    memberchk(result(Named), Properties).

% --- the check on the drawing --------------------------------------------

%!  bars_check(+Total, +Groups, +Named, +Scene, -Name, -Verdict) is det.
%
%   Counted off the emitted scene, not off the numbers that built it.
bars_check(Total, Groups, Named, Scene,
           every_bar_is_a_group_standing_at_the_share_the_machine_named,
           Verdict) :-
    get_dict(categories, Scene, Categories),
    length(Categories, BarCount),
    findall(V, ( member(C, Categories), get_dict(value, C, V) ), Values),
    sum_list(Values, Held0),
    Held is round(Held0),
    Expected is Groups * Named,
    (   BarCount =:= Groups,
        forall(member(V, Values), V =:= Named),
        Held =:= Expected,
        ( Named * Groups =:= Total -> true ; Held =\= Total )
    ->  Verdict = holds
    ;   Verdict = fails
    ).

% ==========================================================================
% 5. THE DRAWING
% ==========================================================================

%!  share_scene(+Doing, +Classification, +Groups, +Share, +Total, +Colour, -Scene)
share_scene(Doing, Classification, Groups, Share, Total, Colour, Scene) :-
    findall(Category,
            ( between(1, Groups, N),
              format(string(Label), "Group ~w", [N]),
              Value is float(Share),
              Category = category{label: Label, value: Value, color: Colour} ),
            Categories),
    format(string(Id), "k7-shares-~w-~w-~w", [Doing, Total, Groups]),
    Held is Groups * Share,
    scene_words(Classification, Groups, Share, Total, Held, Title, Description),
    Scene = scene{version: 1, id: Id, kind: "bar-chart",
                  title: Title, description: Description,
                  categories: Categories,
                  axes: axes{yLabel: "amount in each group"}}.

scene_words(deformation, Groups, Share, Total, Held, Title, Description) :-
    !,
    format(string(Title), "~w in each of ~w groups", [Share, Groups]),
    format(string(Description),
           "~w groups standing at ~w hold ~w of the ~w there were to deal.",
           [Groups, Share, Held, Total]).
scene_words(_, Groups, Share, Total, _, Title, Description) :-
    format(string(Title), "~w dealt into ~w equal groups", [Total, Groups]),
    format(string(Description),
           "~w groups, ~w in each, ~w in all.", [Groups, Share, Total]).

%!  partner_scene(+Classification, +Named, +Share, +Groups, +Total, +Colour, -Fields)
%
%   A deformation is drawn beside the deal the machine certifies, as a second
%   chart. Where the two readings coincide there is one chart and this says so.
partner_scene(deformation, Named, Share, Groups, Total, Colour,
              [ partner_scene(Scene) ]) :-
    Named =\= Share,
    !,
    share_scene(fair_share_equal_groups, productive, Groups, Share, Total,
                Colour, Scene).
partner_scene(_, _, _, _, _, _, []).

%!  k7_bars_scene(+Outcome, -JSON) is semidet.
k7_bars_scene(action_outcome(_, Properties), JSON) :-
    memberchk(scene(Scene), Properties),
    k7_scene_json(Scene, JSON).

%!  k7_bars_partner_scene(+Outcome, -JSON) is semidet.
k7_bars_partner_scene(action_outcome(_, Properties), JSON) :-
    memberchk(partner_scene(Scene), Properties),
    k7_scene_json(Scene, JSON).

% ==========================================================================
% 6. SELF-SUMMARY
% ==========================================================================

k7_bars_summary(
    summary{ module: k7_equal_share_bars,
             status: authored_pilot,
             generated: false,
             grades: 'K-7',
             cluster: k7_equal_share_bars,
             doings: [draw_the_shares_as_bars],
             wraps: [ division/fair_share_equal_groups,
                      division/name_group_count_as_share_size ],
             modifies_wrapped_machines: false,
             verification: [ one_bar_per_group_at_the_share_the_machine_named,
                             the_bars_together_hold_the_amount_to_deal,
                             the_shortfall_is_computed_where_they_do_not,
                             scene_renders_through_the_coordinate_plane_grapher ],
             arithmetic: exact_integer,
             renderer: 'hermes/web/coordinate-plane/grapher.js (schema version 1)',
             deformation_draws_too: true,
             carries_viability_per_input: true,
             drawable_bar_bound: 24,
             imported_by: none }).

% ==========================================================================
% 7. RECEIPTS
% ==========================================================================

% k7_bars_receipt(Row, Lesson, Doing, InputJSONDict, NamedShare, Note).
k7_bars_receipt(
    'im_defrag_2fc2a68f1e98314ee9459ff5_1', 'IM-G3-U4-L2',
    fair_share_equal_groups,
    _{kind: "equal_share_bars", doing: "fair_share_equal_groups",
      total: 20, groups: 4},
    5, row_states_the_same_number_in_each_group).
k7_bars_receipt(
    'im_defrag_8f5afd57712b1126f12ad1fa_1', 'IM-G3-U4-L2',
    fair_share_equal_groups,
    _{kind: "equal_share_bars", doing: "fair_share_equal_groups",
      total: 36, groups: 6},
    6, row_states_the_same_number_in_each_group).
k7_bars_receipt(
    'im_defrag_72fd335fe8103546d09f8eed_1', 'IM-G3-U4-L2',
    fair_share_equal_groups,
    _{kind: "equal_share_bars", doing: "fair_share_equal_groups",
      total: 45, groups: 9},
    5, row_states_the_same_number_in_each_group).
k7_bars_receipt(
    'im_defrag_95e6836c2e770aa507544dfc_1', 'IM-G3-U4-L3',
    fair_share_equal_groups,
    _{kind: "equal_share_bars", doing: "fair_share_equal_groups",
      total: 12, groups: 2},
    6, row_states_the_same_number_in_each_group).
k7_bars_receipt(
    'im_defrag_b65d1522a5b2c2bf0684bdf6_1', 'IM-G4-U1-L7',
    fair_share_equal_groups,
    _{kind: "equal_share_bars", doing: "fair_share_equal_groups",
      total: 12, groups: 3},
    4, bare_expression_row_drawn_as_a_fair_share).
k7_bars_receipt(
    'im_defrag_4f3d9c1cdc04c642c6b670fa_1', 'IM-G3-U5-L8',
    fair_share_equal_groups,
    _{kind: "equal_share_bars", doing: "fair_share_equal_groups",
      total: 12, groups: 4},
    3, bare_expression_row_drawn_as_a_fair_share).
k7_bars_receipt(
    'im_defrag_9be3ed229fcdd24c74518ab9_1', 'IM-G3-U8-L11',
    fair_share_equal_groups,
    _{kind: "equal_share_bars", doing: "fair_share_equal_groups",
      total: 48, groups: 6},
    8, bare_expression_row_drawn_as_a_fair_share).
% The deformation on the same rows. 20 into 4 and 45 into 9 part company from
% the deal; 36 into 6 does not, and the extant machine says so itself.
k7_bars_receipt(
    'im_defrag_2fc2a68f1e98314ee9459ff5_1', 'IM-G3-U4-L2',
    name_group_count_as_share_size,
    _{kind: "equal_share_bars", doing: "name_group_count_as_share_size",
      total: 20, groups: 4},
    4, machine_exists_row_supplies_numbers).
k7_bars_receipt(
    'im_defrag_72fd335fe8103546d09f8eed_1', 'IM-G3-U4-L2',
    name_group_count_as_share_size,
    _{kind: "equal_share_bars", doing: "name_group_count_as_share_size",
      total: 45, groups: 9},
    9, machine_exists_row_supplies_numbers).
k7_bars_receipt(
    'im_defrag_95e6836c2e770aa507544dfc_1', 'IM-G3-U4-L3',
    name_group_count_as_share_size,
    _{kind: "equal_share_bars", doing: "name_group_count_as_share_size",
      total: 12, groups: 2},
    2, machine_exists_row_supplies_numbers).
k7_bars_receipt(
    'im_defrag_8f5afd57712b1126f12ad1fa_1', 'IM-G3-U4-L2',
    name_group_count_as_share_size,
    _{kind: "equal_share_bars", doing: "name_group_count_as_share_size",
      total: 36, groups: 6},
    6, readings_coincide_at_this_input).

% ==========================================================================
% 8. CHECK
% ==========================================================================

check_k7_equal_share_bars :-
    check_receipts,
    check_scenes_render,
    check_bars_counted_off_the_scene,
    check_deformation_draws_beside_the_deal,
    check_coincidence_is_carried_not_manufactured,
    check_negative,
    format('k7_equal_share_bars: all checks ok~n').

check_receipts :-
    findall(Lesson-Row-Named,
            ( k7_bars_receipt(Row, Lesson, Doing, Json, Named, _),
              k7_bars_from_json(Json, Task),
              Task = bars_task(Doing, _, _),
              run_k7_equal_share_bars(draw_the_shares_as_bars, Task, Outcome, _),
              outcome_property(Outcome, drawn_doing(Doing)),
              outcome_property(Outcome, share_the_machine_named(Named)),
              outcome_property(Outcome, bars_check(_, holds))
            ), Passed),
    findall(R, k7_bars_receipt(R, _, _, _, _, _), All),
    length(All, Total), length(Passed, Count),
    Total =:= Count,
    format('  receipts: ~w/~w deals drawn, every bar count and height re-tallied off the emitted scene~n',
           [Count, Total]),
    forall(member(Lesson-Row-Named, Passed),
           format('    ~w  ~w  ~w in each group~n', [Lesson, Row, Named])).

check_scenes_render :-
    findall(JSON,
            ( k7_bars_receipt(_, _, _, Json, _, _),
              k7_bars_from_json(Json, Task),
              run_k7_equal_share_bars(draw_the_shares_as_bars, Task, Outcome, _),
              ( k7_bars_scene(Outcome, JSON)
              ; k7_bars_partner_scene(Outcome, JSON) )
            ), Scenes),
    length(Scenes, Count),
    k7_render_scenes(Scenes),
    format('  drawings: ~w scenes rendered through hermes/web/coordinate-plane without error~n',
           [Count]).

check_bars_counted_off_the_scene :-
    % 20 dealt into 4 groups: four bars, each at 5, holding 20 together.
    k7_bars_from_json(
        _{kind: "equal_share_bars", doing: "fair_share_equal_groups",
          total: 20, groups: 4}, T),
    run_k7_equal_share_bars(draw_the_shares_as_bars, T, O, _),
    outcome_property(O, scene(Scene)),
    get_dict(categories, Scene, Categories), length(Categories, 4),
    findall(V, ( member(C, Categories), get_dict(value, C, V) ), Values),
    sum_list(Values, Held), Held =:= 20.0,
    forall(member(V, Values), V =:= 5.0),
    outcome_property(O, shortfall(0)),
    outcome_property(O, validity(correct)),
    format('  the deal is countable: four bars at five, holding twenty together~n').

check_deformation_draws_beside_the_deal :-
    % Naming the group count as the share leaves 20 - 16 = 4 undealt, and the
    % chart the machine certifies is drawn beside it as a second scene.
    k7_bars_from_json(
        _{kind: "equal_share_bars", doing: "name_group_count_as_share_size",
          total: 20, groups: 4}, T),
    run_k7_equal_share_bars(draw_the_shares_as_bars, T, O, _),
    outcome_property(O, classification(deformation)),
    outcome_property(O, share_the_machine_named(4)),
    outcome_property(O, share_the_deal_produces(5)),
    outcome_property(O, bars_hold(16)),
    outcome_property(O, shortfall(4)),
    outcome_property(O, readings(readings_part_company)),
    outcome_property(O, validity(incorrect)),
    outcome_property(O, productive_partner(division/fair_share_equal_groups)),
    outcome_property(O, attested_as(_, _)),
    k7_bars_partner_scene(O, _),
    format('  the deformation draws too: four bars at four holding sixteen, with the deal at five drawn beside them and four left over~n').

check_coincidence_is_carried_not_manufactured :-
    % 36 into 6 groups gives 6 in each, so the two readings agree and the
    % extant machine returns contextually_correct. No second chart is drawn,
    % because there is no disagreement to draw.
    k7_bars_from_json(
        _{kind: "equal_share_bars", doing: "name_group_count_as_share_size",
          total: 36, groups: 6}, T),
    run_k7_equal_share_bars(draw_the_shares_as_bars, T, O, _),
    outcome_property(O, readings(readings_coincide)),
    outcome_property(O, shortfall(0)),
    outcome_property(O, validity(contextually_correct)),
    \+ k7_bars_partner_scene(O, _),
    format('  where the two readings coincide the pilot says so: 36 into 6 gives 6 either way, one chart, contextually_correct carried through~n').

check_negative :-
    % A deal that does not come out even is not this doing.
    \+ k7_bars_from_json(
           _{kind: "equal_share_bars", doing: "fair_share_equal_groups",
             total: 20, groups: 3}, _),
    % A doing this pilot does not wrap refuses at decode.
    \+ k7_bars_from_json(
           _{kind: "equal_share_bars", doing: "long_division",
             total: 20, groups: 4}, _),
    % Too many groups to draw refuses by name.
    k7_bars_from_json(
        _{kind: "equal_share_bars", doing: "fair_share_equal_groups",
          total: 60, groups: 30}, Many),
    run_k7_equal_share_bars(draw_the_shares_as_bars, Many, ManyOutcome, _),
    outcome_property(ManyOutcome, validity(refused)),
    % The bar check discriminates: a chart claiming a share it does not stand
    % at fails.
    k7_bars_from_json(
        _{kind: "equal_share_bars", doing: "fair_share_equal_groups",
          total: 20, groups: 4}, T),
    run_k7_equal_share_bars(draw_the_shares_as_bars, T, O, _),
    outcome_property(O, scene(S)),
    bars_check(20, 4, 6, S, _, fails),
    format('  negative tests: an uneven deal and an unwrapped doing refuse at decode; thirty groups refuse by name; a mis-stated share fails the bar check~n').

outcome_property(action_outcome(_, Props), Property) :-
    memberchk(Property, Props).
